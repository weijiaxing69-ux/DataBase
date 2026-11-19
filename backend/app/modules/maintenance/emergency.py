"""V1.5 应急能力：对存储过程的薄封装。

事件声明/升级/关闭的跨表规则都在数据库过程里（保证 SQL 直连调用也一致），
应用层只负责权限、参数与返回值，不重复实现一份逻辑。
"""

from __future__ import annotations

from datetime import datetime
from typing import Optional

from sqlalchemy import text
from sqlalchemy.orm import Session

from app.core import security
from app.core.errors import BusinessError
from app.modules.maintenance.service import (
    PERM_ALERT_READ,
    PERM_ASSIGN,
    PERM_INCIDENT,
    _require,
    _tx,
    utcnow,
)
from app.shared.contracts import Actor


def declare_incident(
    db: Session,
    *,
    actor: Actor,
    operator_id: int,
    station_id: Optional[int],
    category: str,
    severity: str,
    title: str,
    alert_id: Optional[int] = None,
) -> int:
    security.require_permission(actor, PERM_INCIDENT)
    if category not in {"power", "communication", "hardware", "software", "security", "other"}:
        raise ValueError("根因类别不合法")
    if severity not in {"P1", "P2", "P3", "P4"}:
        raise ValueError("事件级别不合法")
    # 跨场站事件按运营商授权校验；单场站事件按场站授权校验
    if station_id is not None:
        security.assert_resource_scope(db, actor, resource_type="station", resource_id=station_id)
    elif "platform_admin" not in actor.roles:
        from app.modules.maintenance import dao
        if operator_id not in dao.account_operators(db, actor.account_id):
            raise PermissionError("该运营商超出账号授权范围")

    if alert_id is not None:
        from app.modules.maintenance import dao
        alert = dao.get_alert(db, alert_id)
        if alert is None:
            raise BusinessError("关联的告警不存在", status_code=404)
        pile = dao.get_pile(db, alert.pile_id)
        if pile is None:
            raise BusinessError("关联告警的充电桩不存在", status_code=404)
        if station_id is not None and pile.station_id != station_id:
            raise BusinessError("关联告警不在声明的场站", status_code=409)
        station = dao.get_station(db, pile.station_id)
        if station is None or station.operator_id != operator_id:
            raise BusinessError("关联告警不属于声明的运营商", status_code=409)
        security.assert_resource_scope(db, actor, resource_type="pile", resource_id=alert.pile_id)

    with _tx(db):
        db.execute(
            text(
                """call sp_declare_incident(
                       :operator_id, :station_id, :category, :severity,
                       :title, :actor, :alert_id, @new_incident_id)"""
            ),
            {
                "operator_id": operator_id,
                "station_id": station_id,
                "category": category,
                "severity": severity,
                "title": title,
                "actor": actor.account_id,
                "alert_id": alert_id,
            },
        )
        incident_id = db.execute(text("select @new_incident_id")).scalar_one()
    if incident_id is None:
        raise BusinessError("事件声明失败：存储过程未返回事件编号", status_code=500)
    return int(incident_id)


def escalate_incidents(db: Session, *, actor: Actor, now: Optional[datetime] = None) -> int:
    """升级扫描，返回本轮新增的升级记录数。供调度器每分钟调用。

    这是跨场站的全局写操作，只允许持有事件管理权限的账号触发。
    """
    security.require_permission(actor, PERM_INCIDENT)
    now = now or utcnow()
    with _tx(db):
        before = db.execute(text("select count(*) from incident_escalation")).scalar_one()
        db.execute(text("call sp_escalate_incidents(:now)"), {"now": now})
        after = db.execute(text("select count(*) from incident_escalation")).scalar_one()
    return int(after - before)


def close_incident(db: Session, *, actor: Actor, incident_id: int, summary: str) -> None:
    security.require_permission(actor, PERM_INCIDENT)
    with _tx(db):
        row = db.execute(
            text("select operator_id, station_id from incident where incident_id = :iid"),
            {"iid": incident_id},
        ).first()
        if row is None:
            raise BusinessError("事件不存在", status_code=404)
        operator_id, station_id = row
        if station_id is not None:
            security.assert_resource_scope(db, actor, resource_type="station", resource_id=station_id)
        elif "platform_admin" not in actor.roles:
            from app.modules.maintenance import dao
            if operator_id not in dao.account_operators(db, actor.account_id):
                raise PermissionError("该事件超出账号授权范围")
        db.execute(
            text("call sp_close_incident(:iid, :actor, :summary)"),
            {"iid": incident_id, "actor": actor.account_id, "summary": summary},
        )


def list_incident_board(db: Session, *, actor: Actor, limit: int = 50):
    _require(actor, PERM_ALERT_READ, PERM_INCIDENT, PERM_ASSIGN)
    sql = """select incident_id, incident_no, title, severity, status,
                    station_name, detected_at, alert_count, open_work_orders,
                    ack_seconds, ack_breached, restore_seconds, restore_breached,
                    escalation_level
               from v_incident_board"""
    params: dict = {"limit": limit}
    if "platform_admin" not in actor.roles:
        sql += """
                where operator_id in (select operator_id from sys_account_operator where account_id = :aid)
                   or station_id in (select station_id from sys_account_station where account_id = :aid)"""
        params["aid"] = actor.account_id
    sql += " order by detected_at desc limit :limit"
    rows = db.execute(text(sql), params).mappings().all()
    return [dict(r) for r in rows]
