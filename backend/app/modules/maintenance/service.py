"""maintenance 业务逻辑与事务边界。

权限用 security.has_permission，范围用 assert_resource_scope；
业务错误抛 BusinessError(status_code=...)，权限不足抛 PermissionError。
"""

from __future__ import annotations

import logging
import time
from contextlib import contextmanager
from datetime import datetime, timedelta, timezone
from typing import Optional

from sqlalchemy import select, text
from sqlalchemy.exc import DBAPIError, IntegrityError
from sqlalchemy.orm import Session

from app.core import security
from app.core.errors import BusinessError
from app.modules.maintenance import dao
from app.modules.maintenance import models as m
from app.modules.maintenance import schemas as s
from app.modules.maintenance.device import DeviceActor
from app.shared.contracts import Actor, PageResult

# 事件类型 -> (允许的当前状态, 迁移后的状态)
EVENT_TRANSITIONS: dict[str, tuple[str, str]] = {
    "accepted": ("assigned", "accepted"),
    "arrived": ("accepted", "arrived"),
    "repaired": ("arrived", "repaired"),
    "review_passed": ("repaired", "repaired"),
    "review_failed": ("repaired", "arrived"),
    "closed": ("repaired", "closed"),
}

logger = logging.getLogger("maintenance.task")

OFFLINE_RULE_METRIC = "heartbeat"
DEFAULT_OFFLINE_SECONDS = 180
BATCH_SIZE = 500

# 权限码：种子里 maintenance 只登记了 4 个，缺失的用等价码兜底
PERM_ALERT_READ = "maintenance.alert.read"
PERM_READING = "maintenance.device_reading.read"
PERM_ASSIGN = "maintenance.work_order.assign"
PERM_HANDLE = "maintenance.work_order.handle"
# 17_security_hardening.sql 补齐的细粒度码；未执行时用上面的旧码兜底
PERM_RULE_MANAGE = "maintenance.rule.manage"
PERM_INSPECT_READ = "maintenance.inspection.read"
PERM_INSPECT_WRITE = "maintenance.inspection.create"
PERM_REPORT_READ = "maintenance.fault_report.read"
PERM_REPORT_HANDLE = "maintenance.fault_report.handle"
PERM_INCIDENT = "maintenance.incident.manage"


def utcnow() -> datetime:
    """库内统一 UTC 的 naive datetime。"""
    return datetime.now(timezone.utc).replace(tzinfo=None)


def _isolate(db: Session, label: str, action) -> bool:
    """单条失败只回滚该条，不影响整批任务。"""
    try:
        with db.begin_nested():
            action()
        return True
    except Exception:
        logger.exception("task item failed: %s", label)
        return False


@contextmanager
def _tx(db: Session):
    """事务边界：最外层提交，嵌套只参与。

    不能用 db.in_transaction() 判断——autobegin 会让它恒为真，写入永远不提交。
    """
    depth = getattr(db, "_mt_tx_depth", 0)
    if depth:
        db._mt_tx_depth = depth + 1
        try:
            yield db
        finally:
            db._mt_tx_depth = depth - 1
        return

    db._mt_tx_depth = 1
    try:
        yield db
        db.commit()
    except Exception:
        db.rollback()
        raise
    finally:
        db._mt_tx_depth = 0


def _require(actor: Actor, *permissions: str) -> None:
    """具备任一权限码即通过；平台管理员天然通过。"""
    if any(security.has_permission(actor, code) for code in permissions):
        return
    raise PermissionError("缺少权限：" + " / ".join(permissions))


def _is_engineer(actor: Actor) -> bool:
    return "maintenance_engineer" in actor.roles and "platform_admin" not in actor.roles


def _scope_account(actor: Actor) -> Optional[int]:
    """返回需要做数据范围过滤的账号；平台管理员返回 None（不限）。"""
    return None if "platform_admin" in actor.roles else actor.account_id


def _scope_pile(db: Session, actor: Actor, pile_id: int) -> None:
    security.assert_resource_scope(db, actor, resource_type="pile", resource_id=pile_id)


def _station_of_alert(db: Session, alert: m.DeviceAlert) -> Optional[int]:
    pile = dao.get_pile(db, alert.pile_id)
    return pile.station_id if pile else None


def _station_of_work_order(db: Session, wo: m.WorkOrder) -> Optional[int]:
    alert = dao.get_alert(db, wo.alert_id)
    return _station_of_alert(db, alert) if alert else None


def _work_order_detail(db: Session, wo: m.WorkOrder) -> s.WorkOrderDetail:
    accepted = dao.first_event_at(db, wo.work_order_id, "accepted")
    closed = dao.first_event_at(db, wo.work_order_id, "closed")
    detail = s.WorkOrderDetail.model_validate(wo)
    if accepted:
        detail.accept_seconds = int((accepted - wo.assigned_at).total_seconds())
    if closed:
        detail.total_seconds = int((closed - wo.assigned_at).total_seconds())
    return detail


def _work_order_details(db: Session, rows) -> list:
    """一页工单只查一次事件摘要，避免逐行两条 SQL 的 N+1。"""
    summary = dao.event_summaries(db, [r.work_order_id for r in rows])
    details = []
    for row in rows:
        detail = s.WorkOrderDetail.model_validate(row)
        accepted, closed = summary.get(row.work_order_id, (None, None))
        if accepted:
            detail.accept_seconds = int((accepted - row.assigned_at).total_seconds())
        if closed:
            detail.total_seconds = int((closed - row.assigned_at).total_seconds())
        details.append(detail)
    return details


def _list_page(rows, total: int, query) -> PageResult:
    return PageResult(items=rows, total=total, page=query.page, page_size=query.page_size)


def _maybe_recover_alert(db: Session, alert: m.DeviceAlert, now: datetime) -> None:
    """C05：工单全闭环、观察窗无故障采样、满 recovery_seconds 才恢复。"""
    if dao.count_open_work_orders(db, alert.alert_id) > 0:
        return

    normal_since = dao.latest_closed_at(db, alert.alert_id)
    if normal_since is None:
        return

    if alert.status != "recovering":
        alert.status = "recovering"
        alert.normal_since_at = normal_since

    rule = dao.get_alarm_rule(db, alert.alarm_rule_id)
    if rule is None:
        return

    if (now - normal_since).total_seconds() < rule.recovery_seconds:
        return
    if dao.count_bad_samples(db, alert.pile_id, normal_since, now) > 0:
        return

    alert.status = "recovered"
    alert.recovered_at = now


# ---------------------------------------------------------------------------
# 告警规则
# ---------------------------------------------------------------------------
def list_alarm_rules(db: Session, *, actor: Actor, query: s.AlarmRuleQuery) -> PageResult[s.AlarmRuleDetail]:
    _require(actor, PERM_RULE_MANAGE, PERM_ALERT_READ, PERM_ASSIGN)
    rows, total = dao.list_alarm_rules(db, query)
    return _list_page([s.AlarmRuleDetail.model_validate(r) for r in rows], total, query)


def get_alarm_rule(db: Session, *, actor: Actor, alarm_rule_id: int) -> s.AlarmRuleDetail:
    _require(actor, PERM_RULE_MANAGE, PERM_ALERT_READ, PERM_ASSIGN)
    row = dao.get_alarm_rule(db, alarm_rule_id)
    if row is None:
        raise BusinessError("告警规则不存在", status_code=404)
    return s.AlarmRuleDetail.model_validate(row)


def create_alarm_rule(db: Session, *, actor: Actor, request: s.CreateAlarmRuleRequest) -> s.AlarmRuleDetail:
    _require(actor, PERM_RULE_MANAGE, PERM_ASSIGN)
    with _tx(db):
        row = dao.create_alarm_rule(db, request)
        return s.AlarmRuleDetail.model_validate(row)


def update_alarm_rule(
    db: Session, *, actor: Actor, alarm_rule_id: int, request: s.UpdateAlarmRuleRequest
) -> s.AlarmRuleDetail:
    _require(actor, PERM_RULE_MANAGE, PERM_ASSIGN)
    with _tx(db):
        row = dao.get_alarm_rule(db, alarm_rule_id, for_update=True)
        if row is None:
            raise BusinessError("告警规则不存在", status_code=404)
        for key, value in request.model_dump(exclude_unset=True).items():
            setattr(row, key, value)
        db.flush()
        return s.AlarmRuleDetail.model_validate(row)


# ---------------------------------------------------------------------------
# 告警
# ---------------------------------------------------------------------------
def list_alerts(db: Session, *, actor: Actor, query: s.AlertQuery) -> PageResult[s.AlertDetail]:
    _require(actor, PERM_ALERT_READ, PERM_HANDLE)
    rows, total = dao.list_alerts(db, query, account_id=_scope_account(actor))
    return _list_page([s.AlertDetail.model_validate(r) for r in rows], total, query)


def get_alert(db: Session, *, actor: Actor, alert_id: int) -> s.AlertDetail:
    _require(actor, PERM_ALERT_READ, PERM_HANDLE)
    row = dao.get_alert(db, alert_id)
    if row is None:
        raise BusinessError("告警不存在", status_code=404)
    _scope_pile(db, actor, row.pile_id)
    detail = s.AlertDetail.model_validate(row)
    due = row.occurred_at + timedelta(seconds=row.response_seconds_snapshot)
    detail.is_overdue = row.status != "recovered" and utcnow() > due
    return detail


# ---------------------------------------------------------------------------
# 工单
# ---------------------------------------------------------------------------
def list_work_orders(db: Session, *, actor: Actor, query: s.WorkOrderQuery) -> PageResult[s.WorkOrderDetail]:
    _require(actor, PERM_HANDLE, PERM_ASSIGN)
    if _is_engineer(actor):
        if query.assigned_to not in (None, actor.account_id):
            raise PermissionError("运维只能查询指派给自己的工单")
        query = query.model_copy(update={"assigned_to": actor.account_id})
    rows, total = dao.list_work_orders(db, query, account_id=_scope_account(actor))
    return _list_page(_work_order_details(db, rows), total, query)


def get_work_order(db: Session, *, actor: Actor, work_order_id: int) -> s.WorkOrderDetail:
    _require(actor, PERM_HANDLE, PERM_ASSIGN)
    row = dao.get_work_order(db, work_order_id)
    if row is None:
        raise BusinessError("工单不存在", status_code=404)
    alert = dao.get_alert(db, row.alert_id)
    if alert is not None:
        _scope_pile(db, actor, alert.pile_id)
    if _is_engineer(actor) and row.assigned_to != actor.account_id:
        raise PermissionError("只能查看指派给自己的工单")
    return _work_order_detail(db, row)


def create_work_order(
    db: Session, *, actor: Actor, alert_id: int, request: s.CreateWorkOrderRequest
) -> s.WorkOrderDetail:
    _require(actor, PERM_ASSIGN)
    with _tx(db):
        alert = dao.get_alert(db, alert_id, for_update=True)
        if alert is None:
            raise BusinessError("告警不存在", status_code=404)
        _scope_pile(db, actor, alert.pile_id)
        if alert.status == "recovered":
            raise BusinessError("告警已恢复，不能派单", status_code=409)
        if not dao.account_roles(db, request.assigned_to) & {"maintenance_engineer", "platform_admin"}:
            raise ValueError("被指派人不是运维人员")

        now = utcnow()
        due = now + timedelta(seconds=alert.response_seconds_snapshot)
        wo = dao.create_work_order(
            db,
            alert_id=alert_id,
            assigned_to=request.assigned_to,
            assigned_by=actor.account_id,
            assigned_at=now,
            response_due_at=due,
        )
        alert.status = "processing"
        db.flush()
        return _work_order_detail(db, wo)


def append_work_order_event(
    db: Session, *, actor: Actor, work_order_id: int, request: s.WorkOrderEventRequest
) -> s.WorkOrderDetail:
    _require(actor, PERM_HANDLE)
    with _tx(db):
        wo = dao.get_work_order(db, work_order_id, for_update=True)
        if wo is None:
            raise BusinessError("工单不存在", status_code=404)
        alert = dao.get_alert(db, wo.alert_id)
        if alert is not None:
            _scope_pile(db, actor, alert.pile_id)
        if _is_engineer(actor) and wo.assigned_to != actor.account_id:
            raise PermissionError("只能处理指派给自己的工单")

        expect_from, expect_to = EVENT_TRANSITIONS[request.event_type]
        if wo.status != expect_from:
            raise BusinessError(
                f"工单当前状态为 {wo.status}，不能执行 {request.event_type}", status_code=409
            )

        event_at = request.event_at or utcnow()
        if event_at < wo.assigned_at:
            raise ValueError("事件时间不能早于派单时间")
        if event_at > utcnow() + timedelta(minutes=5):
            raise ValueError("事件时间不能晚于当前时间")
        if request.event_type == "closed" and not dao.has_event(db, work_order_id, "review_passed"):
            raise BusinessError("闭环前必须有复核通过记录", status_code=409)

        dao.add_event(
            db,
            work_order_id=work_order_id,
            event_type=request.event_type,
            event_at=event_at,
            old_status=wo.status,
            new_status=expect_to,
            actor_account_id=actor.account_id,
            note=request.note,
            review_result=request.review_result,
        )
        wo.status = expect_to
        if request.parts_used:
            wo.parts_used = request.parts_used
        if request.result:
            wo.result = request.result

        db.flush()   # 先落库，否则恢复判定会读到旧状态

        if request.event_type == "closed":
            current = dao.get_alert(db, wo.alert_id, for_update=True)
            if current is not None:
                _maybe_recover_alert(db, current, event_at)

        db.flush()
        return _work_order_detail(db, wo)


# ---------------------------------------------------------------------------
# 设备上报
# ---------------------------------------------------------------------------
def receive_heartbeat(db: Session, *, device: DeviceActor, request: s.HeartbeatRequest) -> s.HeartbeatAck:
    """心跳：设备身份只能给自己绑定的桩上报。"""
    if request.pile_id != device.pile_id:
        raise PermissionError("设备凭据与上报的桩不一致")
    with _tx(db):
        pile = dao.get_pile(db, request.pile_id, for_update=True)
        if pile is None:
            raise BusinessError("充电桩不存在", status_code=404)

        now = request.reported_at or utcnow()
        if pile.last_heartbeat_at is not None and now <= pile.last_heartbeat_at:
            return s.HeartbeatAck(
                pile_id=pile.pile_id, is_online=pile.is_online, server_time=utcnow(), duplicate=True
            )

        old_status = pile.status
        pile.last_heartbeat_at = now
        pile.is_online = 1
        if old_status == "offline":
            if pile.has_fault:
                new_status = "fault"
            elif dao.pile_has_active_order(db, pile.pile_id):
                new_status = "occupied"   # 离线期间订单仍在进行，恢复后不能置空闲
            else:
                new_status = "idle"
            pile.status = new_status
            dao.log_status(
                db, pile_id=pile.pile_id, old_status=old_status, new_status=new_status,
                occurred_at=now, reason="heartbeat recovered",
            )
        db.flush()
        return s.HeartbeatAck(pile_id=pile.pile_id, is_online=1, server_time=utcnow())


def ingest_device_reading(db: Session, *, device: DeviceActor, request: s.DeviceReadingRequest) -> s.ReadingAck:
    """采样：同桩同时刻只保留一条，重复上报返回 duplicate=true。"""
    if request.pile_id != device.pile_id:
        raise PermissionError("设备凭据与上报的桩不一致")
    with _tx(db):
        pile = dao.get_pile(db, request.pile_id)
        if pile is None:
            raise BusinessError("充电桩不存在", status_code=404)
        try:
            row = dao.insert_reading(db, request)
        except IntegrityError:
            # 唯一键 (pile_id, sampled_at) 兜住并发重复上报
            db.rollback()
            return s.ReadingAck(sample_id=0, accepted=False, duplicate=True)
        generated = dao.count_alerts_since(
            db, request.pile_id, request.sampled_at - timedelta(seconds=1)
        ) > 0
        return s.ReadingAck(sample_id=row.sample_id, accepted=True, alert_generated=generated)


# ---------------------------------------------------------------------------
# 报障 / 巡检
# ---------------------------------------------------------------------------
def list_fault_reports(db: Session, *, actor: Actor, query: s.FaultReportQuery) -> PageResult[s.FaultReportDetail]:
    _require(actor, PERM_REPORT_READ, PERM_HANDLE, PERM_ALERT_READ)
    rows, total = dao.list_fault_reports(db, query, account_id=_scope_account(actor))
    return _list_page([s.FaultReportDetail.model_validate(r) for r in rows], total, query)


def get_fault_report(db: Session, *, actor: Actor, report_id: int) -> s.FaultReportDetail:
    _require(actor, PERM_REPORT_READ, PERM_HANDLE, PERM_ALERT_READ)
    row = dao.get_fault_report(db, report_id)
    if row is None:
        raise BusinessError("报障记录不存在", status_code=404)
    security.assert_resource_scope(db, actor, resource_type="gun", resource_id=row.gun_id)
    return s.FaultReportDetail.model_validate(row)


def create_fault_report(db: Session, *, actor: Actor, request: s.CreateFaultReportRequest) -> s.FaultReportDetail:
    """车主提交报障；user_id 取当前账号绑定的车主档案（Actor.user_id）。"""
    if not actor.user_id:
        raise ValueError("当前账号未绑定车主档案，不能提交报障")
    with _tx(db):
        row = dao.create_fault_report(db, user_id=actor.user_id, payload=request)
        return s.FaultReportDetail.model_validate(row)


def handle_fault_report(
    db: Session, *, actor: Actor, report_id: int, request: s.HandleFaultReportRequest
) -> s.FaultReportDetail:
    _require(actor, PERM_REPORT_HANDLE, PERM_HANDLE)
    with _tx(db):
        row = dao.get_fault_report(db, report_id)
        if row is None:
            raise BusinessError("报障记录不存在", status_code=404)
        if row.status == "resolved":
            raise BusinessError("报障已处理完毕", status_code=409)
        if request.status == "linked" and request.alert_id is None:
            raise ValueError("关联告警时必须提供 alert_id")
        row.status = request.status
        row.handled_by = actor.account_id
        row.handled_at = utcnow()
        if request.alert_id is not None:
            row.alert_id = request.alert_id
        db.flush()
        return s.FaultReportDetail.model_validate(row)


def list_inspections(db: Session, *, actor: Actor, query: s.InspectionQuery) -> PageResult[s.InspectionDetail]:
    _require(actor, PERM_INSPECT_READ, PERM_HANDLE, PERM_ALERT_READ)
    rows, total = dao.list_inspections(db, query, account_id=_scope_account(actor))
    return _list_page([s.InspectionDetail.model_validate(r) for r in rows], total, query)


def get_inspection(db: Session, *, actor: Actor, inspection_id: int) -> s.InspectionDetail:
    _require(actor, PERM_INSPECT_READ, PERM_HANDLE, PERM_ALERT_READ)
    row = dao.get_inspection(db, inspection_id)
    if row is None:
        raise BusinessError("巡检记录不存在", status_code=404)
    _scope_pile(db, actor, row.pile_id)
    return s.InspectionDetail.model_validate(row)


def create_inspection(db: Session, *, actor: Actor, request: s.CreateInspectionRequest) -> s.InspectionDetail:
    _require(actor, PERM_INSPECT_WRITE, PERM_HANDLE)
    with _tx(db):
        pile = dao.get_pile(db, request.pile_id)
        if pile is None:
            raise BusinessError("充电桩不存在", status_code=404)
        _scope_pile(db, actor, pile.pile_id)
        row = dao.create_inspection(db, actor_id=actor.account_id, payload=request)
        return s.InspectionDetail.model_validate(row)


# ---------------------------------------------------------------------------
# 后台任务
# ---------------------------------------------------------------------------
def _offline_threshold(db: Session) -> int:
    value = db.execute(
        select(m.AlarmRule.threshold_value)
        .where(m.AlarmRule.metric == OFFLINE_RULE_METRIC, m.AlarmRule.enabled == 1)
        .order_by(m.AlarmRule.alarm_rule_id)
        .limit(1)
    ).scalar()
    return int(value) if value is not None else DEFAULT_OFFLINE_SECONDS


def check_offline_devices(db: Session, *, now: Optional[datetime] = None, batch: int = BATCH_SIZE) -> int:
    """心跳超阈值置离线并写状态日志；只处理 is_online=1 的桩。"""
    now = now or utcnow()
    threshold = _offline_threshold(db)
    count = 0
    with _tx(db):
        def mark(pile):
            old = pile.status
            pile.is_online = 0
            pile.status = "offline"          # fault 事实保留在 has_fault
            dao.log_status(
                db, pile_id=pile.pile_id, old_status=old, new_status="offline",
                occurred_at=now, reason=f"heartbeat timeout > {threshold}s",
            )

        for pile in dao.list_offline_candidates(db, now - timedelta(seconds=threshold), batch):
            count += _isolate(db, f"offline:{pile.pile_id}", lambda p=pile: mark(p))
        db.flush()
    return count


def _supervisor_of_station(db: Session, station_id: int, now: datetime):
    return db.execute(
        text(
            """select coalesce(supervisor_account_id, primary_account_id)
                 from on_call_shift
                where scope_type = 'station' and scope_id = :sid
                  and shift_start <= :now and shift_end > :now
                limit 1"""
        ),
        {"sid": station_id, "now": now},
    ).scalar()


def check_overdue_work_orders(db: Session, *, now: Optional[datetime] = None, batch: int = BATCH_SIZE) -> int:
    """超时未接单：级别 +1、写 escalated 事件、通知值班主管。"""
    now = now or utcnow()
    count = 0
    with _tx(db):
        def escalate(wo):
            wo.escalation_level += 1
            dao.add_event(
                db, work_order_id=wo.work_order_id, event_type="escalated", event_at=now,
                old_status="assigned", new_status="assigned", actor_account_id=None,
                note=f"超时未接单，自动升级到 L{wo.escalation_level}",
            )
            station_id = _station_of_work_order(db, wo)
            target = _supervisor_of_station(db, station_id, now) if station_id else None
            target = target or wo.assigned_by
            dao.notify(
                db, account_id=target, notification_type="work_order_overdue",
                business_key=f"wo_overdue:{wo.work_order_id}:{wo.escalation_level}",
                title="工单超时未接单",
                content=f"工单 {wo.work_order_id} 已超过响应时限，已升级到 L{wo.escalation_level}",
                target_path=f"/maintenance/work-orders/{wo.work_order_id}",
            )

        for wo in dao.list_overdue_work_orders(db, now, batch):
            count += _isolate(db, f"overdue:{wo.work_order_id}", lambda o=wo: escalate(o))
        db.flush()
    return count


# ---------------------------------------------------------------------------
# 拓展能力：时间线、总览统计、手动触发任务
# ---------------------------------------------------------------------------
def list_work_order_events(db: Session, *, actor: Actor, work_order_id: int) -> list[s.WorkOrderEventDetail]:
    _require(actor, PERM_HANDLE, PERM_ALERT_READ)
    wo = dao.get_work_order(db, work_order_id)
    if wo is None:
        raise BusinessError("工单不存在", status_code=404)
    alert = dao.get_alert(db, wo.alert_id)
    if alert is not None:
        _scope_pile(db, actor, alert.pile_id)
    if _is_engineer(actor) and wo.assigned_to != actor.account_id:
        raise PermissionError("只能查看指派给自己的工单")
    return [s.WorkOrderEventDetail.model_validate(e) for e in dao.list_events(db, work_order_id)]


def overview(db: Session, *, actor: Actor) -> dict:
    """看板聚合：KPI + 近 30 天趋势 + 等级分布 + 场站排行。"""
    _require(actor, PERM_ALERT_READ, PERM_HANDLE)
    account_id = _scope_account(actor)
    return {
        "kpi": dao.kpi_counts(db, account_id),
        "trend": dao.alert_trend(db, 30, account_id),
        "severity": dao.severity_distribution(db, account_id),
        "stations": dao.station_ranking(db, 5, account_id),
        "generated_at": utcnow().isoformat(timespec="seconds"),
    }


def check_alert_recovery(db: Session, *, now: Optional[datetime] = None, batch: int = 200) -> int:
    """推进 recovering 告警：观察期满且无采样故障则恢复。"""
    now = now or utcnow()
    changed = 0
    with _tx(db):
        for alert in dao.list_recovering_alerts(db, batch):
            before = alert.status
            _maybe_recover_alert(db, alert, now)
            if alert.status != before:
                changed += 1
        db.flush()
    return changed


def run_task(db: Session, *, actor: Actor, name: str) -> dict:
    """手动触发一次后台任务，用于演示与排查；生产由调度器调用。"""
    if "platform_admin" not in actor.roles:
        raise PermissionError("只有平台管理员可以手动触发后台任务")
    fn = TASKS.get(name)
    if fn is None:
        raise ValueError(f"未知任务：{name}，可选 offline / overdue")
    now = utcnow()
    started = time.perf_counter()
    affected = fn(db, now=now)
    logger.info(
        "task=%s affected=%s cost=%.0fms", name, affected, (time.perf_counter() - started) * 1000
    )
    return {"task": name, "affected": affected, "ran_at": now.isoformat(timespec="seconds")}


# ---------------------------------------------------------------------------
# 备件领用（V1.5）
# ---------------------------------------------------------------------------
def list_spare_parts(db: Session, *, actor: Actor, query: s.PartQuery):
    _require(actor, PERM_HANDLE, PERM_INSPECT_READ, PERM_ASSIGN)
    rows, total = dao.list_spare_parts(db, query, account_id=_scope_account(actor))
    items = []
    for row in rows:
        detail = s.SparePartDetail.model_validate(row)
        detail.low_stock = row.stock_qty <= row.safety_stock
        items.append(detail)
    return _list_page(items, total, query)


def create_part_usage(db: Session, *, actor: Actor, request: s.CreatePartUsageRequest):
    """领用备件：库存由触发器扣减，不足返回 409。"""
    _require(actor, PERM_HANDLE)
    if actor.account_id is None:
        raise PermissionError("未登录")
    with _tx(db):
        wo = dao.get_work_order(db, request.work_order_id, for_update=True)
        if wo is None:
            raise BusinessError("工单不存在", status_code=404)
        alert = dao.get_alert(db, wo.alert_id)
        if alert is not None:
            _scope_pile(db, actor, alert.pile_id)
        if wo.status == "closed":
            raise BusinessError("工单已闭环，不能再领用备件", status_code=409)
        part = dao.get_spare_part(db, request.part_id, for_update=True)
        if part is None:
            raise BusinessError("备件不存在", status_code=404)
        if part.station_id is not None:
            security.assert_resource_scope(db, actor, resource_type="station", resource_id=part.station_id)
            wo_station = _station_of_work_order(db, wo)
            if wo_station is not None and part.station_id != wo_station:
                raise BusinessError("备件所属场站与工单不一致，不能跨站领用", status_code=409)
        try:
            row = dao.create_part_usage(
                db,
                work_order_id=request.work_order_id,
                part_id=request.part_id,
                qty=request.qty,
                used_at=utcnow(),
                used_by=actor.account_id,
                note=request.note,
            )
        except DBAPIError as exc:
            db.rollback()
            raise BusinessError("备件库存不足，领用失败", status_code=409) from exc
        return s.PartUsageDetail.model_validate(row)


def list_part_usages(db: Session, *, actor: Actor, work_order_id: int):
    _require(actor, PERM_HANDLE, PERM_INSPECT_READ)
    wo = dao.get_work_order(db, work_order_id)
    if wo is None:
        raise BusinessError("工单不存在", status_code=404)
    alert = dao.get_alert(db, wo.alert_id)
    if alert is not None:
        _scope_pile(db, actor, alert.pile_id)
    return [s.PartUsageDetail.model_validate(r) for r in dao.list_part_usages(db, work_order_id)]


# ---------------------------------------------------------------------------
# 现场问题识别（对应真实充电场景）
# ---------------------------------------------------------------------------
def check_charging_anomaly(
    db: Session, *, now: Optional[datetime] = None,
    window_minutes: int = 6, threshold_kw: float = 1.0, min_samples: int = 2,
) -> int:
    """订单在充电中但桩输出功率持续接近 0（跳枪、枪锁松脱、BMS 中断）。"""
    now = now or utcnow()
    rule = dao.rule_by_fault_code(db, "CHG01")
    if rule is None:
        return 0
    created = 0
    with _tx(db):
        rows = dao.list_charging_anomalies(
            db, now - timedelta(minutes=window_minutes), threshold_kw, min_samples
        )
        for row in rows:
            if dao.insert_alert(
                db, pile_id=row["pile_id"], gun_id=row["gun_id"],
                rule=rule, alert_code="CHG01", occurred_at=now,
            ):
                created += 1
        db.flush()
    return created


def auto_dispatch_safety_alerts(db: Session, *, now: Optional[datetime] = None, batch: int = 50) -> int:
    """严重级告警自动停机并派单：现场标准处置，先停用再派人。"""
    now = now or utcnow()
    count = 0
    with _tx(db):
        def dispatch(alert):
            pile = dao.get_pile(db, alert.pile_id, for_update=True)
            if pile is None:
                return
            if pile.status != "fault":
                dao.log_status(
                    db, pile_id=pile.pile_id, old_status=pile.status, new_status="fault",
                    occurred_at=now, reason=f"critical alert {alert.alert_code}",
                )
                pile.status = "fault"
            pile.has_fault = 1
            if alert.gun_id:
                dao.set_gun_status(db, alert.gun_id, "fault")

            primary, supervisor = dao.on_call_accounts(db, pile.station_id, now)
            dao.create_work_order(
                db,
                alert_id=alert.alert_id,
                assigned_to=primary,
                assigned_by=supervisor,
                assigned_at=now,
                response_due_at=now + timedelta(seconds=alert.response_seconds_snapshot),
            )
            alert.status = "processing"

        for alert in dao.list_critical_alerts_without_order(db, batch):
            count += _isolate(db, f"safety:{alert.alert_id}", lambda a=alert: dispatch(a))
        db.flush()
    return count


def escalate_recurring_faults(
    db: Session, *, now: Optional[datetime] = None, days: int = 30, threshold: int = 3
) -> int:
    """同一根桩同一故障码反复发生，把在办工单升一级（修不好要换件/换桩）。"""
    now = now or utcnow()
    changed = 0
    with _tx(db):
        for row in dao.list_recurring_faults(db, now - timedelta(days=days), threshold):
            latest = db.execute(
                select(m.DeviceAlert)
                .where(m.DeviceAlert.pile_id == row["pile_id"],
                       m.DeviceAlert.alert_code == row["alert_code"])
                .order_by(m.DeviceAlert.occurred_at.desc())
                .limit(1)
            ).scalar_one_or_none()
            if latest is None:
                continue
            wo = dao.open_work_order_for_alert(db, latest.alert_id)
            if wo is None or wo.escalation_level >= 3:
                continue

            marker = f"复发第{row['times']}次"
            exists = db.execute(
                text("select count(*) from work_order_event where work_order_id = :w and note like :p"),
                {"w": wo.work_order_id, "p": f"%{marker}%"},
            ).scalar_one()
            if exists:
                continue

            wo.escalation_level += 1
            dao.add_event(
                db, work_order_id=wo.work_order_id, event_type="escalated", event_at=now,
                old_status=wo.status, new_status=wo.status, actor_account_id=None,
                note=f"{marker}（{days} 天内同码告警），自动升级到 L{wo.escalation_level}",
            )
            changed += 1
        db.flush()
    return changed


# 调度入口：任务名 -> 函数（放在文件末尾，避免前向引用）
TASKS = {
    "offline": check_offline_devices,
    "overdue": check_overdue_work_orders,
    "recovery": check_alert_recovery,
    "charging": check_charging_anomaly,
    "safety": auto_dispatch_safety_alerts,
    "recurring": escalate_recurring_faults,
}


# ---------------------------------------------------------------------------
# 备件入库、巡检到期、绩效统计
# ---------------------------------------------------------------------------
def stock_in_part(db: Session, *, actor: Actor, request: s.StockInRequest):
    """备件入库：库存增加并记一条流水。"""
    _require(actor, PERM_HANDLE, PERM_ASSIGN)
    with _tx(db):
        part = dao.get_spare_part(db, request.part_id, for_update=True)
        if part is None:
            raise BusinessError("备件不存在", status_code=404)
        if part.station_id is not None:
            security.assert_resource_scope(db, actor, resource_type="station", resource_id=part.station_id)
        part.stock_qty += request.qty
        row = dao.add_movement(
            db, part_id=part.part_id, movement_type="in", qty=request.qty,
            balance_after=part.stock_qty, occurred_at=utcnow(),
            operator_account_id=actor.account_id, note=request.note,
        )
        return s.PartMovementDetail.model_validate(row)


def list_part_movements(db: Session, *, actor: Actor, part_id: int):
    _require(actor, PERM_HANDLE, PERM_INSPECT_READ, PERM_ASSIGN)
    part = dao.get_spare_part(db, part_id)
    if part is None:
        raise BusinessError("备件不存在", status_code=404)
    if part.station_id is not None:
        security.assert_resource_scope(db, actor, resource_type="station", resource_id=part.station_id)
    return [s.PartMovementDetail.model_validate(r) for r in dao.list_part_movements(db, part_id)]


def check_inspection_due(db: Session, *, now: Optional[datetime] = None, days: int = 30) -> int:
    """活跃桩超过 N 天没巡检：给场站值班发待办，按月去重。"""
    now = now or utcnow()
    month = now.strftime("%Y-%m")
    created = 0
    with _tx(db):
        for row in dao.list_piles_due_inspection(db, now - timedelta(days=days)):
            account_id, _ = dao.on_call_accounts(db, row["station_id"], now)
            if dao.notify(
                db,
                account_id=account_id,
                notification_type="inspection_due",
                business_key=f"inspect_due:{row['pile_id']}:{month}",
                title="巡检到期",
                content=f"桩 #{row['pile_id']} 已超过 {days} 天未巡检，请安排现场检查",
                target_path="/maintenance/inspections",
            ):
                created += 1
        db.flush()
    return created


def performance_stats(db: Session, *, actor: Actor):
    """按处理人与场站统计：工单量、接单/闭环耗时、超时单数。"""
    _require(actor, PERM_HANDLE, PERM_ASSIGN, PERM_ALERT_READ)
    account_id = _scope_account(actor)
    operators = [
        s.OperatorPerformance(
            assigned_to=row["assigned_to"],
            orders=int(row["orders"]),
            closed_orders=int(row["closed_orders"] or 0),
            overdue_orders=int(row["overdue_orders"] or 0),
            avg_accept_seconds=float(row["avg_accept"]) if row["avg_accept"] is not None else None,
            avg_close_seconds=float(row["avg_close"]) if row["avg_close"] is not None else None,
        )
        for row in dao.operator_performance(db, account_id)
    ]
    stations = [
        s.StationPerformance(
            station_id=row["station_id"],
            station_name=row["station_name"],
            alerts=int(row["alerts"]),
            avg_recovery_seconds=float(row["avg_recovery"]) if row["avg_recovery"] is not None else None,
        )
        for row in dao.station_performance(db, account_id)
    ]
    return s.PerformanceStats(operators=operators, stations=stations, generated_at=utcnow())


TASKS["inspection"] = check_inspection_due


# ---------------------------------------------------------------------------
# 高温预警、计量异常、充满占位
# ---------------------------------------------------------------------------
def check_temperature_warning(
    db: Session, *, now: Optional[datetime] = None,
    window_minutes: int = 15, threshold_c: float = 65.0, samples: int = 3,
) -> int:
    """连续多条采样温度超阈值，在报故障码之前先预警。"""
    now = now or utcnow()
    rule = dao.rule_by_fault_code(db, "TEMP01")
    if rule is None:
        return 0
    created = 0
    with _tx(db):
        rows = dao.list_high_temperature_piles(
            db, now - timedelta(minutes=window_minutes), threshold_c, samples
        )
        for row in rows:
            if dao.insert_alert(
                db, pile_id=row["pile_id"], gun_id=None, rule=rule,
                alert_code="TEMP01", occurred_at=now,
            ):
                created += 1
        db.flush()
    return created


def check_metering_anomaly(
    db: Session, *, now: Optional[datetime] = None,
    window_minutes: int = 15, amps: float = 1.0,
) -> int:
    """没有进行中订单却仍有输出电流：继电器粘连或计量漂移，按严重级处理。"""
    now = now or utcnow()
    rule = dao.rule_by_fault_code(db, "MET01")
    if rule is None:
        return 0
    created = 0
    with _tx(db):
        rows = dao.list_metering_anomalies(db, now - timedelta(minutes=window_minutes), amps)
        for row in rows:
            if dao.insert_alert(
                db, pile_id=row["pile_id"], gun_id=None, rule=rule,
                alert_code="MET01", occurred_at=now,
            ):
                created += 1
        db.flush()
    return created


def check_idle_occupied(db: Session, *, now: Optional[datetime] = None, minutes: int = 30) -> int:
    """桩显示占用但无进行中订单，且上一单结束已久：提醒场站核实挪车或枪归位。"""
    now = now or utcnow()
    created = 0
    with _tx(db):
        for row in dao.list_occupied_without_order(db, now - timedelta(minutes=minutes)):
            account_id, _ = dao.on_call_accounts(db, row["station_id"], now)
            if dao.notify(
                db,
                account_id=account_id,
                notification_type="occupied_too_long",
                business_key=f"occupy:{row['pile_id']}:{now.strftime('%Y-%m-%d')}",
                title="桩被占用但无进行中订单",
                content=(
                    f"桩 #{row['pile_id']} 显示占用，上一单已结束超过 {minutes} 分钟，"
                    "请核实是否车主未挪车或枪未归位"
                ),
                target_path="/maintenance/alerts",
            ):
                created += 1
        db.flush()
    return created


TASKS["temperature"] = check_temperature_warning
TASKS["metering"] = check_metering_anomaly
TASKS["occupied"] = check_idle_occupied
