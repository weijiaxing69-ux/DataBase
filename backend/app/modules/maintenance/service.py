"""maintenance 模块：业务逻辑与事务边界。

与骨架对齐的约定：
- 权限用 `security.has_permission(actor, "模块.资源.动作")`，范围用 `security.assert_resource_scope`。
- 业务错误抛 `BusinessError(message, status_code=...)`；权限不足抛 `PermissionError`；
  参数问题抛 `ValueError`（由 core.errors 统一映射为 400/403/404）。
- 写入口自己提交事务，失败回滚；被其他模块调用的函数只 flush。

对应 V1.4 契约第 6 章 maintenance 段：19 个入口 + 2 个后台任务。
"""

from __future__ import annotations

from contextlib import contextmanager
from datetime import datetime, timedelta, timezone
from typing import Optional

from sqlalchemy import select, text
from sqlalchemy.orm import Session

from app.core import security
from app.core.errors import BusinessError
from app.modules.maintenance import dao
from app.modules.maintenance import models as m
from app.modules.maintenance import schemas as s
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

OFFLINE_RULE_METRIC = "heartbeat"
DEFAULT_OFFLINE_SECONDS = 180
BATCH_SIZE = 500

# 权限码：种子里 maintenance 只登记了 4 个，缺失的用等价码兜底
PERM_ALERT_READ = "maintenance.alert.read"
PERM_READING = "maintenance.device_reading.read"
PERM_ASSIGN = "maintenance.work_order.assign"
PERM_HANDLE = "maintenance.work_order.handle"


def utcnow() -> datetime:
    """库内统一 UTC 的 naive datetime。"""
    return datetime.now(timezone.utc).replace(tzinfo=None)


@contextmanager
def _tx(db: Session):
    """最外层开启事务并提交；嵌套调用复用当前事务。"""
    if db.in_transaction():
        yield db
        return
    try:
        yield db
        db.commit()
    except Exception:
        db.rollback()
        raise


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
    """C05：全部工单闭环 + 观察窗内无故障采样 + 满 recovery_seconds 才恢复。"""
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
    _require(actor, PERM_ALERT_READ, PERM_ASSIGN)
    rows, total = dao.list_alarm_rules(db, query)
    return _list_page([s.AlarmRuleDetail.model_validate(r) for r in rows], total, query)


def get_alarm_rule(db: Session, *, actor: Actor, alarm_rule_id: int) -> s.AlarmRuleDetail:
    _require(actor, PERM_ALERT_READ, PERM_ASSIGN)
    row = dao.get_alarm_rule(db, alarm_rule_id)
    if row is None:
        raise BusinessError("告警规则不存在", status_code=404)
    return s.AlarmRuleDetail.model_validate(row)


def create_alarm_rule(db: Session, *, actor: Actor, request: s.CreateAlarmRuleRequest) -> s.AlarmRuleDetail:
    _require(actor, PERM_ASSIGN)
    with _tx(db):
        row = dao.create_alarm_rule(db, request)
        return s.AlarmRuleDetail.model_validate(row)


def update_alarm_rule(
    db: Session, *, actor: Actor, alarm_rule_id: int, request: s.UpdateAlarmRuleRequest
) -> s.AlarmRuleDetail:
    _require(actor, PERM_ASSIGN)
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
        query.assigned_to = actor.account_id
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
        # 契约的事件枚举里没有「派单」事件，派单信息落在 work_order.assigned_at
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

        # 先落库再判定恢复：Session 关闭了 autoflush，不 flush 会读到旧状态
        db.flush()

        if request.event_type == "closed":
            current = dao.get_alert(db, wo.alert_id, for_update=True)
            if current is not None:
                _maybe_recover_alert(db, current, event_at)

        db.flush()
        return _work_order_detail(db, wo)


# ---------------------------------------------------------------------------
# 设备上报
# ---------------------------------------------------------------------------
def receive_heartbeat(db: Session, *, actor: Actor, request: s.HeartbeatRequest) -> s.HeartbeatAck:
    # TODO 设备身份：待成员1 提供「凭据换身份」的依赖后替换为设备鉴权。
    # 当前按持有设备上报权限的账号放行，仅用于联调。
    _require(actor, PERM_READING, PERM_HANDLE)
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
            new_status = "fault" if pile.has_fault else "idle"
            pile.status = new_status
            dao.log_status(
                db, pile_id=pile.pile_id, old_status=old_status, new_status=new_status,
                occurred_at=now, reason="heartbeat recovered",
            )
        db.flush()
        return s.HeartbeatAck(pile_id=pile.pile_id, is_online=1, server_time=utcnow())


def ingest_device_reading(db: Session, *, actor: Actor, request: s.DeviceReadingRequest) -> s.ReadingAck:
    _require(actor, PERM_READING, PERM_HANDLE)
    with _tx(db):
        pile = dao.get_pile(db, request.pile_id)
        if pile is None:
            raise BusinessError("充电桩不存在", status_code=404)
        row = dao.insert_reading(db, request)
        generated = dao.count_alerts_since(
            db, request.pile_id, request.sampled_at - timedelta(seconds=1)
        ) > 0
        return s.ReadingAck(sample_id=row.sample_id, accepted=True, alert_generated=generated)


# ---------------------------------------------------------------------------
# 报障 / 巡检
# ---------------------------------------------------------------------------
def list_fault_reports(db: Session, *, actor: Actor, query: s.FaultReportQuery) -> PageResult[s.FaultReportDetail]:
    _require(actor, PERM_HANDLE, PERM_ALERT_READ)
    rows, total = dao.list_fault_reports(db, query)
    return _list_page([s.FaultReportDetail.model_validate(r) for r in rows], total, query)


def get_fault_report(db: Session, *, actor: Actor, report_id: int) -> s.FaultReportDetail:
    _require(actor, PERM_HANDLE, PERM_ALERT_READ)
    row = dao.get_fault_report(db, report_id)
    if row is None:
        raise BusinessError("报障记录不存在", status_code=404)
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
    _require(actor, PERM_HANDLE)
    with _tx(db):
        row = dao.get_fault_report(db, report_id)
        if row is None:
            raise BusinessError("报障记录不存在", status_code=404)
        if row.status == "resolved":
            raise BusinessError("报障已处理完毕", status_code=409)
        row.status = request.status
        row.handled_by = actor.account_id
        row.handled_at = utcnow()
        if request.alert_id is not None:
            row.alert_id = request.alert_id
        db.flush()
        return s.FaultReportDetail.model_validate(row)


def list_inspections(db: Session, *, actor: Actor, query: s.InspectionQuery) -> PageResult[s.InspectionDetail]:
    _require(actor, PERM_HANDLE, PERM_ALERT_READ)
    rows, total = dao.list_inspections(db, query)
    return _list_page([s.InspectionDetail.model_validate(r) for r in rows], total, query)


def get_inspection(db: Session, *, actor: Actor, inspection_id: int) -> s.InspectionDetail:
    _require(actor, PERM_HANDLE, PERM_ALERT_READ)
    row = dao.get_inspection(db, inspection_id)
    if row is None:
        raise BusinessError("巡检记录不存在", status_code=404)
    return s.InspectionDetail.model_validate(row)


def create_inspection(db: Session, *, actor: Actor, request: s.CreateInspectionRequest) -> s.InspectionDetail:
    _require(actor, PERM_HANDLE)
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
    """心跳超阈值置离线并写状态日志。幂等：只处理 is_online=1 的桩。"""
    now = now or utcnow()
    threshold = _offline_threshold(db)
    count = 0
    with _tx(db):
        for pile in dao.list_offline_candidates(db, now - timedelta(seconds=threshold), batch):
            old = pile.status
            pile.is_online = 0
            pile.status = "offline"          # fault 事实保留在 has_fault
            dao.log_status(
                db, pile_id=pile.pile_id, old_status=old, new_status="offline",
                occurred_at=now, reason=f"heartbeat timeout > {threshold}s",
            )
            count += 1
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
    """超时未接单自动升级：级别 +1、写 escalated 事件、通知值班主管。"""
    now = now or utcnow()
    count = 0
    with _tx(db):
        for wo in dao.list_overdue_work_orders(db, now, batch):
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
            count += 1
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
    return {
        "kpi": dao.kpi_counts(db),
        "trend": dao.alert_trend(db, 30),
        "severity": dao.severity_distribution(db),
        "stations": dao.station_ranking(db, 5),
        "generated_at": utcnow().isoformat(timespec="seconds"),
    }


TASKS = {"offline": check_offline_devices, "overdue": check_overdue_work_orders}


def run_task(db: Session, *, actor: Actor, name: str) -> dict:
    """手动触发一次后台任务，用于演示与排查；生产由调度器调用。"""
    _require(actor, PERM_ASSIGN)
    fn = TASKS.get(name)
    if fn is None:
        raise ValueError(f"未知任务：{name}，可选 offline / overdue")
    now = utcnow()
    affected = fn(db, now=now)
    return {"task": name, "affected": affected, "ran_at": now.isoformat(timespec="seconds")}
