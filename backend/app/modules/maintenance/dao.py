"""DAO 层：只做数据访问，不含业务判断，不提交事务。"""

from __future__ import annotations

from datetime import datetime
from typing import Optional, Sequence

from sqlalchemy import case, func, select, text
from sqlalchemy.dialects.mysql import insert as mysql_insert
from sqlalchemy.orm import Session

from app.modules.maintenance import models as m
from app.modules.maintenance import schemas as s


SCOPE_ALERT = text(
    """exists (
         select 1 from charging_pile p
           join station st on st.station_id = p.station_id
          where p.pile_id = device_alert.pile_id
            and (st.station_id in (select station_id from sys_account_station where account_id = :aid)
                 or st.operator_id in (select operator_id from sys_account_operator where account_id = :aid))
       )"""
)

SCOPE_WORK_ORDER = text(
    """exists (
         select 1 from device_alert da
           join charging_pile p on p.pile_id = da.pile_id
           join station st on st.station_id = p.station_id
          where da.alert_id = work_order.alert_id
            and (st.station_id in (select station_id from sys_account_station where account_id = :aid)
                 or st.operator_id in (select operator_id from sys_account_operator where account_id = :aid))
       )"""
)


SCOPE_FAULT_REPORT = text(
    """exists (
         select 1 from charging_gun g
           join charging_pile p on p.pile_id = g.pile_id
           join station st on st.station_id = p.station_id
          where g.gun_id = fault_report.gun_id
            and (st.station_id in (select station_id from sys_account_station where account_id = :aid)
                 or st.operator_id in (select operator_id from sys_account_operator where account_id = :aid))
       )"""
)

SCOPE_INSPECTION = text(
    """exists (
         select 1 from charging_pile p
           join station st on st.station_id = p.station_id
          where p.pile_id = inspection_record.pile_id
            and (st.station_id in (select station_id from sys_account_station where account_id = :aid)
                 or st.operator_id in (select operator_id from sys_account_operator where account_id = :aid))
       )"""
)


def _page(db: Session, stmt, page: int, page_size: int):
    total = db.execute(select(func.count()).select_from(stmt.subquery())).scalar_one()
    rows = db.execute(stmt.limit(page_size).offset((page - 1) * page_size)).scalars().all()
    return list(rows), int(total)


# ---------------------------------------------------------------------------
# 告警规则
# ---------------------------------------------------------------------------
def get_alarm_rule(db: Session, rule_id: int, *, for_update: bool = False):
    stmt = select(m.AlarmRule).where(m.AlarmRule.alarm_rule_id == rule_id)
    if for_update:
        stmt = stmt.with_for_update()
    return db.execute(stmt).scalar_one_or_none()


def list_alarm_rules(db: Session, q: s.AlarmRuleQuery):
    stmt = select(m.AlarmRule).order_by(m.AlarmRule.alarm_rule_id)
    if q.severity:
        stmt = stmt.where(m.AlarmRule.severity == q.severity)
    if q.enabled is not None:
        stmt = stmt.where(m.AlarmRule.enabled == q.enabled)
    if q.keyword:
        like = f"%{q.keyword}%"
        stmt = stmt.where(m.AlarmRule.rule_code.like(like) | m.AlarmRule.fault_code.like(like))
    return _page(db, stmt, q.page, q.page_size)


def create_alarm_rule(db: Session, payload: s.CreateAlarmRuleRequest) -> m.AlarmRule:
    row = m.AlarmRule(**payload.model_dump())
    db.add(row)
    db.flush()
    return row


# ---------------------------------------------------------------------------
# 告警
# ---------------------------------------------------------------------------
def get_alert(db: Session, alert_id: int, *, for_update: bool = False):
    stmt = select(m.DeviceAlert).where(m.DeviceAlert.alert_id == alert_id)
    if for_update:
        stmt = stmt.with_for_update()
    return db.execute(stmt).scalar_one_or_none()


def list_alerts(db: Session, q: s.AlertQuery, *, account_id: Optional[int] = None):
    stmt = select(m.DeviceAlert).order_by(m.DeviceAlert.occurred_at.desc())
    if account_id is not None:
        stmt = stmt.where(SCOPE_ALERT.bindparams(aid=account_id))
    if q.pile_id:
        stmt = stmt.where(m.DeviceAlert.pile_id == q.pile_id)
    if q.status:
        stmt = stmt.where(m.DeviceAlert.status == q.status)
    if q.severity:
        stmt = stmt.where(m.DeviceAlert.severity == q.severity)
    if q.occurred_from:
        stmt = stmt.where(m.DeviceAlert.occurred_at >= q.occurred_from)
    if q.occurred_to:
        stmt = stmt.where(m.DeviceAlert.occurred_at <= q.occurred_to)
    return _page(db, stmt, q.page, q.page_size)


# ---------------------------------------------------------------------------
# 工单
# ---------------------------------------------------------------------------
def get_work_order(db: Session, work_order_id: int, *, for_update: bool = False):
    stmt = select(m.WorkOrder).where(m.WorkOrder.work_order_id == work_order_id)
    if for_update:
        stmt = stmt.with_for_update()
    return db.execute(stmt).scalar_one_or_none()


def list_work_orders(db: Session, q: s.WorkOrderQuery, *, account_id: Optional[int] = None):
    stmt = select(m.WorkOrder).order_by(m.WorkOrder.assigned_at.desc())
    if account_id is not None:
        stmt = stmt.where(SCOPE_WORK_ORDER.bindparams(aid=account_id))
    if q.status:
        stmt = stmt.where(m.WorkOrder.status == q.status)
    if q.assigned_to:
        stmt = stmt.where(m.WorkOrder.assigned_to == q.assigned_to)
    if q.alert_id:
        stmt = stmt.where(m.WorkOrder.alert_id == q.alert_id)
    if q.assigned_from:
        stmt = stmt.where(m.WorkOrder.assigned_at >= q.assigned_from)
    return _page(db, stmt, q.page, q.page_size)


def create_work_order(
    db: Session, *, alert_id: int, assigned_to: int, assigned_by: int,
    assigned_at: datetime, response_due_at: datetime,
) -> m.WorkOrder:
    row = m.WorkOrder(
        alert_id=alert_id,
        assigned_to=assigned_to,
        assigned_by=assigned_by,
        assigned_at=assigned_at,
        response_due_at=response_due_at,
        status="assigned",
        escalation_level=0,
    )
    db.add(row)
    db.flush()
    return row


def add_event(
    db: Session, *, work_order_id: int, event_type: str, event_at: datetime,
    old_status: str, new_status: str, actor_account_id: Optional[int],
    note: Optional[str] = None, review_result: Optional[str] = None,
) -> m.WorkOrderEvent:
    row = m.WorkOrderEvent(
        work_order_id=work_order_id,
        event_type=event_type,
        event_at=event_at,
        old_status=old_status,
        new_status=new_status,
        actor_account_id=actor_account_id,
        note=note,
        review_result=review_result,
    )
    db.add(row)
    db.flush()
    return row


def event_summaries(db: Session, work_order_ids: Sequence[int]) -> dict[int, tuple]:
    """一次查询取回一页工单的「首次接单」与「首次闭环」时间。"""
    if not work_order_ids:
        return {}
    rows = db.execute(
        select(
            m.WorkOrderEvent.work_order_id,
            func.min(case((m.WorkOrderEvent.event_type == "accepted", m.WorkOrderEvent.event_at))),
            func.min(case((m.WorkOrderEvent.event_type == "closed", m.WorkOrderEvent.event_at))),
        )
        .where(m.WorkOrderEvent.work_order_id.in_(list(work_order_ids)))
        .group_by(m.WorkOrderEvent.work_order_id)
    ).all()
    return {row[0]: (row[1], row[2]) for row in rows}


def first_event_at(db: Session, work_order_id: int, event_type: str):
    return db.execute(
        select(func.min(m.WorkOrderEvent.event_at)).where(
            m.WorkOrderEvent.work_order_id == work_order_id,
            m.WorkOrderEvent.event_type == event_type,
        )
    ).scalar()


def count_open_work_orders(db: Session, alert_id: int) -> int:
    return int(
        db.execute(
            select(func.count()).select_from(m.WorkOrder).where(
                m.WorkOrder.alert_id == alert_id, m.WorkOrder.status != "closed"
            )
        ).scalar_one()
    )


def latest_closed_at(db: Session, alert_id: int):
    return db.execute(
        select(func.max(m.WorkOrderEvent.event_at))
        .join(m.WorkOrder, m.WorkOrder.work_order_id == m.WorkOrderEvent.work_order_id)
        .where(m.WorkOrder.alert_id == alert_id, m.WorkOrderEvent.event_type == "closed")
    ).scalar()


def count_bad_samples(db: Session, pile_id: int, since: datetime, until: datetime) -> int:
    return int(
        db.execute(
            select(func.count()).select_from(m.DeviceReading).where(
                m.DeviceReading.pile_id == pile_id,
                m.DeviceReading.sampled_at >= since,
                m.DeviceReading.sampled_at <= until,
                m.DeviceReading.fault_code != "NONE",
            )
        ).scalar_one()
    )


# ---------------------------------------------------------------------------
# 设备与采样
# ---------------------------------------------------------------------------
def get_pile(db: Session, pile_id: int, *, for_update: bool = False):
    stmt = select(m.ChargingPile).where(m.ChargingPile.pile_id == pile_id)
    if for_update:
        stmt = stmt.with_for_update()
    return db.execute(stmt).scalar_one_or_none()


def get_station(db: Session, station_id: int):
    return db.execute(select(m.Station).where(m.Station.station_id == station_id)).scalar_one_or_none()


def insert_reading(db: Session, payload: s.DeviceReadingRequest) -> m.DeviceReading:
    row = m.DeviceReading(**payload.model_dump())
    db.add(row)
    db.flush()  # 生成 sample_id；库内触发器会按规则自动生成告警
    return row


def count_alerts_since(db: Session, pile_id: int, since: datetime) -> int:
    return int(
        db.execute(
            select(func.count()).select_from(m.DeviceAlert).where(
                m.DeviceAlert.pile_id == pile_id, m.DeviceAlert.occurred_at >= since
            )
        ).scalar_one()
    )


def list_offline_candidates(db: Session, threshold_before: datetime, limit: int):
    return list(
        db.execute(
            select(m.ChargingPile)
            .where(
                m.ChargingPile.is_online == 1,
                (m.ChargingPile.last_heartbeat_at.is_(None))
                | (m.ChargingPile.last_heartbeat_at < threshold_before),
            )
            .order_by(m.ChargingPile.last_heartbeat_at)
            .limit(limit)
            .with_for_update(skip_locked=True)
        ).scalars()
    )


def list_overdue_work_orders(db: Session, now: datetime, limit: int):
    return list(
        db.execute(
            select(m.WorkOrder)
            .where(
                m.WorkOrder.status == "assigned",
                m.WorkOrder.response_due_at < now,
                m.WorkOrder.escalation_level == 0,
            )
            .order_by(m.WorkOrder.response_due_at)
            .limit(limit)
            .with_for_update(skip_locked=True)
        ).scalars()
    )


def log_status(
    db: Session, *, pile_id: int, old_status: Optional[str], new_status: str,
    occurred_at: datetime, reason: str, actor_account_id: Optional[int] = None,
) -> None:
    db.add(
        m.DeviceStatusLog(
            pile_id=pile_id,
            old_status=old_status,
            new_status=new_status,
            occurred_at=occurred_at,
            reason=reason,
            actor_account_id=actor_account_id,
        )
    )


def notify(
    db: Session, *, account_id: int, notification_type: str, business_key: str,
    title: str, content: str, target_path: str,
) -> None:
    """站内待办。同一账号同一业务键只保留一条（库内唯一索引兜底）。"""
    stmt = mysql_insert(m.Notification).values(
        account_id=account_id,
        notification_type=notification_type,
        business_key=business_key,
        title=title,
        content=content,
        target_path=target_path,
    )
    result = db.execute(stmt.prefix_with("IGNORE"))
    return result.rowcount > 0


# ---------------------------------------------------------------------------
# 报障 / 巡检
# ---------------------------------------------------------------------------
def get_fault_report(db: Session, report_id: int):
    return db.execute(
        select(m.FaultReport).where(m.FaultReport.report_id == report_id)
    ).scalar_one_or_none()


def list_fault_reports(db: Session, q: s.FaultReportQuery, *, account_id: Optional[int] = None):
    stmt = select(m.FaultReport).order_by(m.FaultReport.created_at.desc())
    if account_id is not None:
        stmt = stmt.where(SCOPE_FAULT_REPORT.bindparams(aid=account_id))
    if q.status:
        stmt = stmt.where(m.FaultReport.status == q.status)
    if q.gun_id:
        stmt = stmt.where(m.FaultReport.gun_id == q.gun_id)
    return _page(db, stmt, q.page, q.page_size)


def create_fault_report(db: Session, *, user_id: int, payload: s.CreateFaultReportRequest):
    row = m.FaultReport(
        user_id=user_id,
        gun_id=payload.gun_id,
        order_id=payload.order_id,
        description=payload.description,
        status="submitted",
    )
    db.add(row)
    db.flush()
    return row


def get_inspection(db: Session, inspection_id: int):
    return db.execute(
        select(m.InspectionRecord).where(m.InspectionRecord.inspection_id == inspection_id)
    ).scalar_one_or_none()


def list_inspections(db: Session, q: s.InspectionQuery, *, account_id: Optional[int] = None):
    stmt = select(m.InspectionRecord).order_by(m.InspectionRecord.inspected_at.desc())
    if account_id is not None:
        stmt = stmt.where(SCOPE_INSPECTION.bindparams(aid=account_id))
    if q.pile_id:
        stmt = stmt.where(m.InspectionRecord.pile_id == q.pile_id)
    if q.result:
        stmt = stmt.where(m.InspectionRecord.result == q.result)
    return _page(db, stmt, q.page, q.page_size)


def create_inspection(db: Session, *, actor_id: int, payload: s.CreateInspectionRequest):
    row = m.InspectionRecord(
        pile_id=payload.pile_id,
        inspected_by=actor_id,
        inspected_at=payload.inspected_at or datetime.utcnow(),
        result=payload.result,
        parts_used=payload.parts_used,
        note=payload.note,
    )
    db.add(row)
    db.flush()
    return row


# ---------------------------------------------------------------------------
# 详情与统计（拓展能力，非契约内接口）
# ---------------------------------------------------------------------------
def list_events(db: Session, work_order_id: int):
    return list(
        db.execute(
            select(m.WorkOrderEvent)
            .where(m.WorkOrderEvent.work_order_id == work_order_id)
            .order_by(m.WorkOrderEvent.event_at)
        ).scalars()
    )


def _scope(pile_expr: str, account_id: Optional[int]) -> str:
    """按账号授权场站拼 SQL 条件；account_id 为空表示不限。"""
    if account_id is None:
        return "1=1"
    return (
        "exists (select 1 from charging_pile p join station st on st.station_id = p.station_id "
        f"where p.pile_id = {pile_expr} and ("
        "st.station_id in (select station_id from sys_account_station where account_id = :aid) "
        "or st.operator_id in (select operator_id from sys_account_operator where account_id = :aid)))"
    )


def kpi_counts(db: Session, account_id: Optional[int] = None) -> dict:
    alert_scope = _scope("a.pile_id", account_id)
    order_scope = _scope("(select da.pile_id from device_alert da where da.alert_id = w.alert_id)", account_id)
    incident_scope = "1=1" if account_id is None else (
        "(exists (select 1 from station st where st.station_id = i.station_id and ("
        "st.station_id in (select station_id from sys_account_station where account_id = :aid) "
        "or st.operator_id in (select operator_id from sys_account_operator where account_id = :aid))) "
        "or (i.station_id is null and i.operator_id in "
        "(select operator_id from sys_account_operator where account_id = :aid)))"
    )
    row = db.execute(
        text(
            f"""select
                 (select count(*) from device_alert a
                   where a.status <> 'recovered' and {alert_scope})                        as open_alerts,
                 (select count(*) from work_order w
                   where w.status = 'assigned' and w.response_due_at < utc_timestamp()
                     and {order_scope})                                                    as overdue_orders,
                 (select count(*) from work_order w
                   where w.status <> 'closed' and {order_scope})                           as open_orders,
                 (select count(*) from incident i
                   where i.status in ('detected','declared','contained') and {incident_scope}) as active_incidents,
                 (select count(*) from work_order_event e
                   join work_order w2 on w2.work_order_id = e.work_order_id
                   where e.event_type = 'closed'
                     and e.event_at >= utc_timestamp() - interval 1 day
                     and {_scope('(select da.pile_id from device_alert da where da.alert_id = w2.alert_id)', account_id)}) as closed_today
            """
        ),
        {"aid": account_id},
    ).mappings().one()
    return dict(row)


def alert_trend(db: Session, days: int = 30, account_id: Optional[int] = None) -> list[dict]:
    rows = db.execute(
        text(
            f"""select date(a.occurred_at) as d, count(*) as c
                  from device_alert a
                 where a.occurred_at >= utc_timestamp() - interval {int(days)} day
                   and {_scope('a.pile_id', account_id)}
                 group by date(a.occurred_at)
                 order by d"""
        ),
        {"aid": account_id},
    ).mappings().all()
    return [{"date": str(r["d"]), "count": int(r["c"])} for r in rows]


def severity_distribution(db: Session, account_id: Optional[int] = None) -> list[dict]:
    rows = db.execute(
        text(
            f"""select a.severity, count(*) as c
                  from device_alert a
                 where a.status <> 'recovered' and {_scope('a.pile_id', account_id)}
                 group by a.severity"""
        ),
        {"aid": account_id},
    ).mappings().all()
    return [{"severity": r["severity"], "count": int(r["c"])} for r in rows]


def station_ranking(db: Session, limit: int = 5, account_id: Optional[int] = None) -> list[dict]:
    rows = db.execute(
        text(
            f"""select s.station_id, s.station_name, count(*) as open_alerts
                  from device_alert a
                  join charging_pile p on p.pile_id = a.pile_id
                  join station s on s.station_id = p.station_id
                 where a.status <> 'recovered' and {_scope('a.pile_id', account_id)}
                 group by s.station_id, s.station_name
                 order by open_alerts desc, s.station_id
                 limit :lim"""
        ),
        {"lim": limit, "aid": account_id},
    ).mappings().all()
    return [dict(r) for r in rows]


# ---------------------------------------------------------------------------
# 备件与校验辅助
# ---------------------------------------------------------------------------
def list_spare_parts(db: Session, q: s.PartQuery, *, account_id: Optional[int] = None):
    stmt = select(m.SparePart).where(m.SparePart.status == "active")
    if q.station_id is not None:
        stmt = stmt.where(m.SparePart.station_id == q.station_id)
    if q.only_low:
        stmt = stmt.where(m.SparePart.stock_qty <= m.SparePart.safety_stock)
    if account_id is not None:
        # 中心库（station_id 为空）对所有账号可见，场站库按授权过滤
        stmt = stmt.where(
            m.SparePart.station_id.is_(None)
            | m.SparePart.station_id.in_(
                text(
                    """select station_id from sys_account_station where account_id = :aid
                       union
                       select s.station_id from station s
                         join sys_account_operator ao on ao.operator_id = s.operator_id
                        where ao.account_id = :aid"""
                ).bindparams(aid=account_id)
            )
        )
    stmt = stmt.order_by(m.SparePart.part_id)
    return _page(db, stmt, q.page, q.page_size)


def get_spare_part(db: Session, part_id: int, *, for_update: bool = False):
    stmt = select(m.SparePart).where(m.SparePart.part_id == part_id)
    if for_update:
        stmt = stmt.with_for_update()
    return db.execute(stmt).scalar_one_or_none()


def create_part_usage(
    db: Session, *, work_order_id: int, part_id: int, qty: int,
    used_at, used_by: int, note: Optional[str],
) -> m.PartUsage:
    row = m.PartUsage(
        work_order_id=work_order_id, part_id=part_id, qty=qty,
        used_at=used_at, used_by=used_by, note=note,
    )
    db.add(row)
    db.flush()
    return row


def list_part_usages(db: Session, work_order_id: int):
    return list(
        db.execute(
            select(m.PartUsage).where(m.PartUsage.work_order_id == work_order_id)
            .order_by(m.PartUsage.used_at)
        ).scalars()
    )


def has_event(db: Session, work_order_id: int, event_type: str) -> bool:
    return db.execute(
        select(func.count()).select_from(m.WorkOrderEvent).where(
            m.WorkOrderEvent.work_order_id == work_order_id,
            m.WorkOrderEvent.event_type == event_type,
        )
    ).scalar_one() > 0


def account_roles(db: Session, account_id: int) -> set[str]:
    return set(
        db.execute(
            text(
                """select r.role_code from sys_account_role ar
                     join sys_role r on r.role_id = ar.role_id
                    where ar.account_id = :aid"""
            ),
            {"aid": account_id},
        ).scalars().all()
    )


def list_recovering_alerts(db: Session, limit: int):
    return list(
        db.execute(
            select(m.DeviceAlert)
            .where(m.DeviceAlert.status == "recovering", m.DeviceAlert.normal_since_at.is_not(None))
            .order_by(m.DeviceAlert.normal_since_at)
            .limit(limit)
            .with_for_update(skip_locked=True)
        ).scalars()
    )


def pile_has_active_order(db: Session, pile_id: int) -> bool:
    return db.execute(
        text(
            """select count(*) from charging_order o
                 join charging_gun g on g.gun_id = o.gun_id
                where g.pile_id = :p and o.status = 'charging'"""
        ),
        {"p": pile_id},
    ).scalar_one() > 0


def account_operators(db: Session, account_id: int) -> set[int]:
    return set(
        db.execute(
            text("select operator_id from sys_account_operator where account_id = :aid"),
            {"aid": account_id},
        ).scalars().all()
    )


# ---------------------------------------------------------------------------
# 现场问题识别（充电异常、安全停机、复发故障）
# ---------------------------------------------------------------------------
def rule_by_fault_code(db: Session, fault_code: str):
    return db.execute(
        select(m.AlarmRule).where(
            m.AlarmRule.fault_code == fault_code, m.AlarmRule.enabled == 1
        ).order_by(m.AlarmRule.alarm_rule_id).limit(1)
    ).scalar_one_or_none()


def insert_alert(
    db: Session, *, pile_id: int, gun_id: Optional[int], rule,
    alert_code: str, occurred_at,
) -> bool:
    """插入告警；同桩同码已有未恢复记录时靠唯一键跳过，返回是否真的插入。"""
    result = db.execute(
        text(
            """insert ignore into device_alert
                 (pile_id, gun_id, alarm_rule_id, alert_code, severity,
                  occurred_at, status, response_seconds_snapshot)
               values (:pile, :gun, :rule, :code, :sev, :at, 'open', :snap)"""
        ),
        {
            "pile": pile_id, "gun": gun_id, "rule": rule.alarm_rule_id,
            "code": alert_code, "sev": rule.severity, "at": occurred_at,
            "snap": rule.response_seconds,
        },
    )
    return result.rowcount > 0


def list_charging_anomalies(db: Session, since, threshold_kw: float, min_samples: int):
    rows = db.execute(
        text(
            """select o.order_id, o.gun_id, g.pile_id,
                      count(r.sample_id) as samples, max(r.power_kw) as max_power
                 from charging_order o
                 join charging_gun g on g.gun_id = o.gun_id
                 join device_reading r on r.pile_id = g.pile_id and r.sampled_at >= :since
                where o.status = 'charging'
                group by o.order_id, o.gun_id, g.pile_id
               having count(r.sample_id) >= :min_samples and max(r.power_kw) < :threshold"""
        ),
        {"since": since, "threshold": threshold_kw, "min_samples": min_samples},
    ).mappings().all()
    return [dict(r) for r in rows]


def list_critical_alerts_without_order(db: Session, limit: int):
    return list(
        db.execute(
            select(m.DeviceAlert)
            .join(m.AlarmRule, m.AlarmRule.alarm_rule_id == m.DeviceAlert.alarm_rule_id)
            .where(
                m.AlarmRule.severity == "critical",
                m.DeviceAlert.status.in_(("open", "processing")),
                ~select(m.WorkOrder.work_order_id)
                .where(m.WorkOrder.alert_id == m.DeviceAlert.alert_id)
                .exists(),
            )
            .order_by(m.DeviceAlert.occurred_at)
            .limit(limit)
            .with_for_update(skip_locked=True)
        ).scalars()
    )


def on_call_accounts(db: Session, station_id: Optional[int], now):
    """当前值班（主/备主管）；过了班次就取最近一次排班的负责人。"""
    sql_current = text(
        """select primary_account_id, coalesce(supervisor_account_id, primary_account_id) as supervisor
             from on_call_shift
            where scope_type = 'station' and scope_id = :sid
              and shift_start <= :now and shift_end > :now
            limit 1"""
    )
    sql_latest = text(
        """select primary_account_id, coalesce(supervisor_account_id, primary_account_id) as supervisor
             from on_call_shift
            where scope_type = 'station' and scope_id = :sid
            order by shift_end desc limit 1"""
    )
    params = {"sid": station_id, "now": now}
    row = db.execute(sql_current, params).one_or_none() if station_id else None
    if row is None and station_id is not None:
        row = db.execute(sql_latest, params).one_or_none()
    if row is None:
        return 101, 101   # 兜底：平台管理员
    return int(row[0]), int(row[1])


def list_recurring_faults(db: Session, since, threshold: int):
    rows = db.execute(
        text(
            """select pile_id, alert_code, count(*) as times
                 from device_alert
                where occurred_at >= :since
                group by pile_id, alert_code
               having count(*) >= :threshold
                order by times desc"""
        ),
        {"since": since, "threshold": threshold},
    ).mappings().all()
    return [dict(r) for r in rows]


def set_gun_status(db: Session, gun_id: int, status: str) -> None:
    db.execute(text("update charging_gun set status = :s where gun_id = :g"),
               {"s": status, "g": gun_id})


def open_work_order_for_alert(db: Session, alert_id: int):
    return db.execute(
        select(m.WorkOrder).where(
            m.WorkOrder.alert_id == alert_id, m.WorkOrder.status != "closed"
        ).order_by(m.WorkOrder.work_order_id.desc()).limit(1)
    ).scalar_one_or_none()


# ---------------------------------------------------------------------------
# 库存流水、巡检到期、绩效统计
# ---------------------------------------------------------------------------
def list_part_movements(db: Session, part_id: int, limit: int = 100):
    return list(
        db.execute(
            select(m.PartStockMovement)
            .where(m.PartStockMovement.part_id == part_id)
            .order_by(m.PartStockMovement.occurred_at.desc())
            .limit(limit)
        ).scalars()
    )


def add_movement(
    db: Session, *, part_id: int, movement_type: str, qty: int,
    balance_after: int, occurred_at, operator_account_id: Optional[int], note: Optional[str],
) -> m.PartStockMovement:
    row = m.PartStockMovement(
        part_id=part_id, movement_type=movement_type, qty=qty,
        balance_after=balance_after, occurred_at=occurred_at,
        operator_account_id=operator_account_id, note=note,
    )
    db.add(row)
    db.flush()
    return row


def list_piles_due_inspection(db: Session, since):
    """活跃桩中，最近一次巡检早于 since 的（含从未巡检的）。"""
    return db.execute(
        text(
            """select p.pile_id, p.station_id,
                      (select max(i.inspected_at) from inspection_record i where i.pile_id = p.pile_id) as last_at
                 from charging_pile p
                where p.lifecycle_status = 'active'
                  and not exists (
                        select 1 from inspection_record i
                         where i.pile_id = p.pile_id and i.inspected_at >= :since)
                order by p.pile_id"""
        ),
        {"since": since},
    ).mappings().all()


def operator_performance(db: Session, account_id: Optional[int]):
    rows = db.execute(
        text(
            f"""select w.assigned_to,
                       count(*) as orders,
                       sum(w.status = 'closed') as closed_orders,
                       sum(w.status = 'assigned' and w.response_due_at < utc_timestamp()) as overdue_orders,
                       avg(case when acc.accepted_at is not null
                                then timestampdiff(second, w.assigned_at, acc.accepted_at) end) as avg_accept,
                       avg(case when clo.closed_at is not null
                                then timestampdiff(second, w.assigned_at, clo.closed_at) end) as avg_close
                  from work_order w
                  left join (select work_order_id, min(event_at) accepted_at
                               from work_order_event where event_type = 'accepted'
                              group by work_order_id) acc on acc.work_order_id = w.work_order_id
                  left join (select work_order_id, min(event_at) closed_at
                               from work_order_event where event_type = 'closed'
                              group by work_order_id) clo on clo.work_order_id = w.work_order_id
                 where {_scope('(select da.pile_id from device_alert da where da.alert_id = w.alert_id)', account_id)}
                 group by w.assigned_to
                 order by orders desc"""
        ),
        {"aid": account_id},
    ).mappings().all()
    return [dict(r) for r in rows]


def station_performance(db: Session, account_id: Optional[int], limit: int = 20):
    rows = db.execute(
        text(
            f"""select s.station_id, s.station_name,
                       count(a.alert_id) as alerts,
                       avg(case when a.recovered_at is not null
                                then timestampdiff(second, a.occurred_at, a.recovered_at) end) as avg_recovery
                  from device_alert a
                  join charging_pile p on p.pile_id = a.pile_id
                  join station s on s.station_id = p.station_id
                 where {_scope('a.pile_id', account_id)}
                 group by s.station_id, s.station_name
                 order by alerts desc
                 limit :lim"""
        ),
        {"aid": account_id, "lim": limit},
    ).mappings().all()
    return [dict(r) for r in rows]


# ---------------------------------------------------------------------------
# 高温预警、计量异常、充满占位
# ---------------------------------------------------------------------------
def list_high_temperature_piles(db: Session, since, threshold: float, samples: int):
    """最近若干条采样温度都超过阈值（连续高温，尚未报故障码）。"""
    rows = db.execute(
        text(
            """select pile_id, min(module_temperature_c) as min_temp, count(*) as n
                 from (
                   select pile_id, module_temperature_c,
                          row_number() over (partition by pile_id order by sampled_at desc) as rn
                     from device_reading
                    where sampled_at >= :since
                 ) t
                where rn <= :samples
                group by pile_id
               having count(*) = :samples and min(module_temperature_c) > :threshold"""
        ),
        {"since": since, "samples": samples, "threshold": threshold},
    ).mappings().all()
    return [dict(r) for r in rows]


def list_metering_anomalies(db: Session, since, amps: float):
    """没有进行中订单，但采样仍有输出电流：继电器粘连或计量漂移。"""
    rows = db.execute(
        text(
            """select r.pile_id, max(r.output_current_a) as max_amps
                 from device_reading r
                where r.sampled_at >= :since and r.output_current_a > :amps
                  and not exists (
                        select 1 from charging_order o
                          join charging_gun g on g.gun_id = o.gun_id
                         where g.pile_id = r.pile_id and o.status = 'charging')
                group by r.pile_id"""
        ),
        {"since": since, "amps": amps},
    ).mappings().all()
    return [dict(r) for r in rows]


def list_occupied_without_order(db: Session, before):
    """桩显示占用，但没有进行中订单，且上一单结束已超过指定时间。"""
    rows = db.execute(
        text(
            """select p.pile_id, p.station_id, max(o.finished_at) as last_finished
                 from charging_pile p
                 join charging_gun g on g.pile_id = p.pile_id
                 left join charging_order o on o.gun_id = g.gun_id
                where p.status = 'occupied'
                  and not exists (select 1 from charging_order o2
                                   join charging_gun g2 on g2.gun_id = o2.gun_id
                                  where g2.pile_id = p.pile_id and o2.status = 'charging')
                group by p.pile_id, p.station_id
               having max(o.finished_at) is not null and max(o.finished_at) <= :before"""
        ),
        {"before": before},
    ).mappings().all()
    return [dict(r) for r in rows]


def gun_pile_id(db: Session, gun_id: int) -> Optional[int]:
    return db.execute(
        text("select pile_id from charging_gun where gun_id = :g"), {"g": gun_id}
    ).scalar_one_or_none()
