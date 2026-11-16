"""维护模块服务层集成测试（连真实 MySQL）。

运行：
    cd backend
    python -m pytest tests/maintenance -v

前置：
    - MySQL 已启动，且已导入 database/bootstrap（65 表 + 种子）
    - 已执行 database/modules/maintenance/02~05（视图、过程、触发器、场景数据）
数据库连不上时整组跳过，不会误报失败；不使用 SQLite，因为本模块依赖
分区表、生成列与触发器，SQLite 无法覆盖。
"""

from __future__ import annotations

from datetime import datetime, timedelta, timezone

import pytest
from sqlalchemy import text

from app.core.database import SessionLocal, engine
from app.core.errors import BusinessError
from app.modules.maintenance import schemas as s
from app.modules.maintenance import service
from app.shared.contracts import Actor


def utcnow() -> datetime:
    return datetime.now(timezone.utc).replace(tzinfo=None)


def _db_ready() -> bool:
    try:
        with engine.connect() as conn:
            conn.execute(text("select 1"))
        return True
    except Exception:  # noqa: BLE001
        return False


pytestmark = pytest.mark.skipif(
    not _db_ready(),
    reason="MySQL 未启动或库不存在，跳过集成测试",
)

ADMIN = Actor(account_id=101, roles=frozenset({"platform_admin"}), permissions=frozenset())
ENGINEER = Actor(
    account_id=102,
    roles=frozenset({"maintenance_engineer"}),
    permissions=frozenset({"maintenance.work_order.handle"}),
)
# 设备上报：骨架尚未提供「凭据换身份」，这里用持有上报权限的账号代替，见 service 中 TODO
DEVICE = Actor(
    account_id=101,
    roles=frozenset({"platform_admin"}),
    permissions=frozenset({"maintenance.device_reading.read"}),
)


@pytest.fixture()
def db():
    session = SessionLocal()
    try:
        yield session
    finally:
        session.close()


def _cleanup_alert_chain(db, alert_ids: list[int]) -> None:
    if not alert_ids:
        return
    ids = ",".join(str(i) for i in alert_ids)
    db.execute(text(f"delete from incident_alert where alert_id in ({ids})"))
    db.execute(text(
        "delete from work_order_event where work_order_id in "
        f"(select work_order_id from work_order where alert_id in ({ids}))"
    ))
    db.execute(text(f"delete from work_order where alert_id in ({ids})"))
    db.execute(text(f"delete from device_alert where alert_id in ({ids})"))
    db.commit()


def _make_alert(db, pile_id: int) -> tuple[int, datetime]:
    """通过上报采样触发库内触发器生成告警，返回 (alert_id, sampled_at)。"""
    sampled_at = utcnow()
    service.ingest_device_reading(
        db,
        actor=DEVICE,
        request=s.DeviceReadingRequest(
            pile_id=pile_id, sampled_at=sampled_at,
            output_voltage_v=400, output_current_a=20, power_kw=8,
            module_temperature_c=40,
            fault_code="E104",   # low 级：触发告警但不会自动声明事件
        ),
    )
    alert_id = db.execute(
        text(
            "select alert_id from device_alert where pile_id = :p and alert_code = 'E104' "
            "and status <> 'recovered' order by alert_id desc limit 1"
        ),
        {"p": pile_id},
    ).scalar_one()
    return alert_id, sampled_at


# ---------------------------------------------------------------------------
# 1. 告警规则 CRUD
# ---------------------------------------------------------------------------
def test_alarm_rule_crud(db):
    created = service.create_alarm_rule(
        db,
        actor=ADMIN,
        request=s.CreateAlarmRuleRequest(
            rule_code="T-UNIT-001", fault_code="T001", metric="fault_code",
            severity="medium", response_seconds=1200, recovery_seconds=120,
        ),
    )
    try:
        assert created.rule_code == "T-UNIT-001"
        detail = service.get_alarm_rule(db, actor=ADMIN, alarm_rule_id=created.alarm_rule_id)
        assert detail.severity == "medium"
        updated = service.update_alarm_rule(
            db, actor=ADMIN, alarm_rule_id=created.alarm_rule_id,
            request=s.UpdateAlarmRuleRequest(response_seconds=600),
        )
        assert updated.response_seconds == 600
    finally:
        db.execute(text("delete from alarm_rule where rule_code = 'T-UNIT-001'"))
        db.commit()


# ---------------------------------------------------------------------------
# 2. 完整工单闭环：采样 → 告警 → 派单 → 接单 → 到场 → 修复 → 复核 → 闭环
# ---------------------------------------------------------------------------
def test_work_order_lifecycle(db):
    pile_id = 19
    alert_id, sampled_at = _make_alert(db, pile_id)

    wo = service.create_work_order(
        db, actor=ADMIN, alert_id=alert_id, request=s.CreateWorkOrderRequest(assigned_to=102)
    )
    assert wo.status == "assigned"
    assert (wo.response_due_at - wo.assigned_at).total_seconds() == 7200  # low 规则 2 小时

    detail = wo
    for event_type, offset in [("accepted", 60), ("arrived", 300), ("repaired", 900),
                               ("review_passed", 1200), ("closed", 1500)]:
        detail = service.append_work_order_event(
            db, actor=ENGINEER, work_order_id=wo.work_order_id,
            request=s.WorkOrderEventRequest(
                event_type=event_type,
                event_at=wo.assigned_at + timedelta(seconds=offset),
                review_result="连续采样温度正常" if event_type == "review_passed" else None,
            ),
        )
    assert detail.status == "closed"
    assert detail.accept_seconds == 60
    assert detail.total_seconds == 1500

    # 闭环后告警进入 recovering，观察期未满不直接 recovered
    status = db.execute(
        text("select status from device_alert where alert_id = :a"), {"a": alert_id}
    ).scalar_one()
    assert status == "recovering"

    _cleanup_alert_chain(db, [alert_id])
    db.execute(
        text("delete from device_reading where pile_id = :p and sampled_at = :t"),
        {"p": pile_id, "t": sampled_at},
    )
    db.commit()


# ---------------------------------------------------------------------------
# 3. 状态机拒绝跳步
# ---------------------------------------------------------------------------
def test_illegal_transition_rejected(db):
    pile_id = 18
    alert_id, sampled_at = _make_alert(db, pile_id)
    wo = service.create_work_order(
        db, actor=ADMIN, alert_id=alert_id, request=s.CreateWorkOrderRequest(assigned_to=102)
    )
    with pytest.raises(BusinessError):
        service.append_work_order_event(
            db, actor=ENGINEER, work_order_id=wo.work_order_id,
            request=s.WorkOrderEventRequest(event_type="repaired"),
        )
    _cleanup_alert_chain(db, [alert_id])
    db.execute(
        text("delete from device_reading where pile_id = :p and sampled_at = :t"),
        {"p": pile_id, "t": sampled_at},
    )
    db.commit()


# ---------------------------------------------------------------------------
# 4. 超时未接单：自动升级 + 写事件 + 通知
# ---------------------------------------------------------------------------
def test_overdue_task_escalates(db):
    pile_id = 17
    alert_id, sampled_at = _make_alert(db, pile_id)
    wo = service.create_work_order(
        db, actor=ADMIN, alert_id=alert_id, request=s.CreateWorkOrderRequest(assigned_to=102)
    )
    db.execute(
        text("update work_order set response_due_at = :t where work_order_id = :w"),
        {"t": utcnow() - timedelta(minutes=10), "w": wo.work_order_id},
    )
    db.commit()

    assert service.check_overdue_work_orders(db) >= 1
    assert db.execute(
        text("select escalation_level from work_order where work_order_id = :w"),
        {"w": wo.work_order_id},
    ).scalar_one() == 1
    assert db.execute(
        text("select count(*) from work_order_event where work_order_id = :w and event_type = 'escalated'"),
        {"w": wo.work_order_id},
    ).scalar_one() == 1

    _cleanup_alert_chain(db, [alert_id])
    db.execute(
        text("delete from notification where business_key like :k"),
        {"k": f"wo_overdue:{wo.work_order_id}:%"},
    )
    db.execute(
        text("delete from device_reading where pile_id = :p and sampled_at = :t"),
        {"p": pile_id, "t": sampled_at},
    )
    db.commit()


# ---------------------------------------------------------------------------
# 5. 心跳超时置离线 + 写状态日志
# ---------------------------------------------------------------------------
def test_offline_task(db):
    pile_id = 16
    db.execute(
        text("update charging_pile set is_online = 1, status = 'idle', last_heartbeat_at = :t "
             "where pile_id = :p"),
        {"t": utcnow() - timedelta(hours=1), "p": pile_id},
    )
    db.commit()

    assert service.check_offline_devices(db) >= 1
    row = db.execute(
        text("select is_online, status from charging_pile where pile_id = :p"), {"p": pile_id}
    ).one()
    assert row[0] == 0 and row[1] == "offline"
    assert db.execute(
        text("select count(*) from device_status_log where pile_id = :p "
             "and new_status = 'offline' and reason like 'heartbeat timeout%'"),
        {"p": pile_id},
    ).scalar_one() >= 1

    db.execute(
        text("update charging_pile set is_online = 1, status = 'idle' where pile_id = :p"),
        {"p": pile_id},
    )
    db.commit()


# ---------------------------------------------------------------------------
# 6. 数据范围：运维看不到别人的工单
# ---------------------------------------------------------------------------
def test_engineer_cannot_see_others(db):
    other = Actor(
        account_id=999,
        roles=frozenset({"maintenance_engineer"}),
        permissions=frozenset({"maintenance.work_order.handle"}),
    )
    with pytest.raises(PermissionError):
        service.list_work_orders(db, actor=other, query=s.WorkOrderQuery(assigned_to=102))
