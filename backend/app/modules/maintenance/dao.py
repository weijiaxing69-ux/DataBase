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
    db.execute(stmt.prefix_with("IGNORE"))


# ---------------------------------------------------------------------------
# 报障 / 巡检
# ---------------------------------------------------------------------------
def get_fault_report(db: Session, report_id: int):
    return db.execute(
        select(m.FaultReport).where(m.FaultReport.report_id == report_id)
    ).scalar_one_or_none()


def list_fault_reports(db: Session, q: s.FaultReportQuery):
    stmt = select(m.FaultReport).order_by(m.FaultReport.created_at.desc())
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


def list_inspections(db: Session, q: s.InspectionQuery):
    stmt = select(m.InspectionRecord).order_by(m.InspectionRecord.inspected_at.desc())
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


def kpi_counts(db: Session) -> dict:
    from sqlalchemy import text

    row = db.execute(
        text(
            """select
                 (select count(*) from device_alert where status <> 'recovered')            as open_alerts,
                 (select count(*) from work_order
                   where status = 'assigned' and response_due_at < utc_timestamp())         as overdue_orders,
                 (select count(*) from work_order where status <> 'closed')                 as open_orders,
                 (select count(*) from incident
                   where status in ('detected','declared','contained'))                     as active_incidents,
                 (select count(*) from work_order_event
                   where event_type = 'closed' and event_at >= utc_timestamp() - interval 1 day) as closed_today
            """
        )
    ).mappings().one()
    return dict(row)


def alert_trend(db: Session, days: int = 30) -> list[dict]:
    from sqlalchemy import text

    rows = db.execute(
        text(
            f"""select date(occurred_at) as d, count(*) as c
                  from device_alert
                 where occurred_at >= utc_timestamp() - interval {int(days)} day
                 group by date(occurred_at)
                 order by d"""
        )
    ).mappings().all()
    return [{"date": str(r["d"]), "count": int(r["c"])} for r in rows]


def severity_distribution(db: Session) -> list[dict]:
    from sqlalchemy import text

    rows = db.execute(
        text(
            """select severity, count(*) as c
                 from device_alert
                where status <> 'recovered'
                group by severity"""
        )
    ).mappings().all()
    return [{"severity": r["severity"], "count": int(r["c"])} for r in rows]


def station_ranking(db: Session, limit: int = 5) -> list[dict]:
    from sqlalchemy import text

    rows = db.execute(
        text(
            """select s.station_id, s.station_name, count(*) as open_alerts
                 from device_alert a
                 join charging_pile p on p.pile_id = a.pile_id
                 join station s on s.station_id = p.station_id
                where a.status <> 'recovered'
                group by s.station_id, s.station_name
                order by open_alerts desc, s.station_id
                limit :lim"""
        ),
        {"lim": limit},
    ).mappings().all()
    return [dict(r) for r in rows]
