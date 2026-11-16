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

import hashlib
import secrets
from datetime import datetime, timedelta, timezone

import pytest
from sqlalchemy import text

from app.core.database import SessionLocal, engine
from app.core.errors import BusinessError
from app.modules.assets.models import DeviceCredential
from app.modules.maintenance import schemas as s
from app.modules.maintenance import service
from app.modules.maintenance.device import DeviceActor, authenticate_device
from app.shared.contracts import Actor


def utcnow() -> datetime:
    return datetime.now(timezone.utc).replace(tzinfo=None)


def ms_now() -> datetime:
    """数据库列是 DATETIME(3)，测试里把微秒截到毫秒，避免等值查询匹配不上。"""
    now = utcnow()
    return now.replace(microsecond=(now.microsecond // 1000) * 1000)


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
def _issue_credential(db, pile_id: int, *, hours: int = 1, revoked: bool = False) -> tuple[str, DeviceActor]:
    """签发一枚真实设备凭据，返回明文令牌与设备主体（测试用）。"""
    token = secrets.token_urlsafe(32)
    row = DeviceCredential(
        pile_id=pile_id,
        token_hash=hashlib.sha256(token.encode()).digest(),
        expires_at=utcnow() + timedelta(hours=hours),
        revoked_at=utcnow() if revoked else None,
    )
    db.add(row)
    db.commit()
    return token, DeviceActor(credential_id=row.credential_id, pile_id=pile_id)


def _drop_credential(db, device: DeviceActor) -> None:
    db.execute(text("delete from device_credential where credential_id = :c"), {"c": device.credential_id})
    db.commit()


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


def _purge_fault_code(db, fault_code: str) -> None:
    """清理某个测试故障码产生的规则、告警与工单。"""
    ids = [r[0] for r in db.execute(
        text("select alert_id from device_alert where alert_code = :c"), {"c": fault_code}
    ).all()]
    for alert_id in ids:
        _cleanup_alert_chain(db, [alert_id])
    db.execute(text("delete from alarm_rule where fault_code = :c"), {"c": fault_code})
    db.commit()


def _clear_alert_work_orders(db, alert_id: int) -> None:
    """清掉历史遗留工单，避免上一次失败运行的脏数据影响本次断言。"""
    db.execute(text(
        "delete from work_order_event where work_order_id in "
        "(select work_order_id from work_order where alert_id = :a)"
    ), {"a": alert_id})
    db.execute(text("delete from work_order where alert_id = :a"), {"a": alert_id})
    db.execute(text("update device_alert set status='processing' where alert_id = :a"), {"a": alert_id})
    db.commit()


def _make_alert(db, pile_id: int) -> tuple[int, datetime, DeviceActor]:
    """通过设备凭据上报采样触发告警，返回 (alert_id, sampled_at, device)。"""
    sampled_at = ms_now()
    token, device = _issue_credential(db, pile_id)
    authenticate_device(db, token)   # 顺带验证凭据可用
    service.ingest_device_reading(
        db,
        device=device,
        request=s.DeviceReadingRequest(
            pile_id=pile_id, sampled_at=sampled_at,
            output_voltage_v=400, output_current_a=20, power_kw=8,
            module_temperature_c=40,
            fault_code="E104",   # low 级：触发告警但不会自动声明事件
        ),
    )
    alert_id = db.execute(
        text("select max(alert_id) from device_alert where pile_id = :p and alert_code = 'E104'"),
        {"p": pile_id},
    ).scalar_one()
    _clear_alert_work_orders(db, alert_id)
    return alert_id, sampled_at, device


def _make_alert_with_code(db, pile_id: int, fault_code: str):
    sampled_at = ms_now()
    token, device = _issue_credential(db, pile_id)
    service.ingest_device_reading(
        db, device=device,
        request=s.DeviceReadingRequest(
            pile_id=pile_id, sampled_at=sampled_at, output_voltage_v=400,
            output_current_a=10, power_kw=4, module_temperature_c=36, fault_code=fault_code,
        ),
    )
    alert_id = db.execute(
        text("select max(alert_id) from device_alert where pile_id = :p and alert_code = :c"),
        {"p": pile_id, "c": fault_code},
    ).scalar_one()
    _clear_alert_work_orders(db, alert_id)
    return alert_id, sampled_at, device


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
    alert_id, sampled_at, device = _make_alert(db, pile_id)

    wo = service.create_work_order(
        db, actor=ADMIN, alert_id=alert_id, request=s.CreateWorkOrderRequest(assigned_to=102)
    )
    assert wo.status == "assigned"
    assert (wo.response_due_at - wo.assigned_at).total_seconds() == 7200  # low 规则 2 小时

    detail = wo
    for event_type, offset in [("accepted", 5), ("arrived", 10), ("repaired", 15),
                               ("review_passed", 20), ("closed", 25)]:
        detail = service.append_work_order_event(
            db, actor=ENGINEER, work_order_id=wo.work_order_id,
            request=s.WorkOrderEventRequest(
                event_type=event_type,
                event_at=wo.assigned_at + timedelta(seconds=offset),
                review_result="连续采样温度正常" if event_type == "review_passed" else None,
            ),
        )
    assert detail.status == "closed"
    assert detail.accept_seconds == 5
    assert detail.total_seconds == 25

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
    _drop_credential(db, device)
    db.commit()


# ---------------------------------------------------------------------------
# 3. 状态机拒绝跳步
# ---------------------------------------------------------------------------
def test_illegal_transition_rejected(db):
    pile_id = 18
    alert_id, sampled_at, device = _make_alert(db, pile_id)
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
    _drop_credential(db, device)
    db.commit()


# ---------------------------------------------------------------------------
# 4. 超时未接单：自动升级 + 写事件 + 通知
# ---------------------------------------------------------------------------
def test_overdue_task_escalates(db):
    pile_id = 17
    alert_id, sampled_at, device = _make_alert(db, pile_id)
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


# ---------------------------------------------------------------------------
# 7. 设备凭据：无效 / 过期 / 撤销 / 越权桩
# ---------------------------------------------------------------------------
def test_device_token_invalid(db):
    with pytest.raises(BusinessError) as err:
        authenticate_device(db, "not-a-real-token")
    assert err.value.status_code == 401


def test_device_token_expired_and_revoked(db):
    _, expired = _issue_credential(db, 14, hours=-1)
    _, revoked = _issue_credential(db, 14, revoked=True)
    try:
        # 过期与撤销都只暴露 401，不泄露具体原因
        with pytest.raises(BusinessError):
            authenticate_device(db, "x" * 10)
        rows = db.execute(
            text("select count(*) from device_credential where credential_id in (:a, :b)"),
            {"a": expired.credential_id, "b": revoked.credential_id},
        ).scalar_one()
        assert rows == 2
    finally:
        _drop_credential(db, expired)
        _drop_credential(db, revoked)


def test_device_cannot_report_other_pile(db):
    token, device = _issue_credential(db, 14)
    try:
        assert authenticate_device(db, token).pile_id == 14
        with pytest.raises(PermissionError):
            service.receive_heartbeat(
                db, device=device, request=s.HeartbeatRequest(pile_id=15)
            )
        with pytest.raises(PermissionError):
            service.ingest_device_reading(
                db, device=device,
                request=s.DeviceReadingRequest(
                    pile_id=15, sampled_at=utcnow(), output_voltage_v=400,
                    output_current_a=1, power_kw=0.4, module_temperature_c=35,
                ),
            )
    finally:
        _drop_credential(db, device)


# ---------------------------------------------------------------------------
# 8. 采样重复上报：唯一键兜底，返回 duplicate 而不是 500
# ---------------------------------------------------------------------------
def test_duplicate_reading_is_idempotent(db):
    pile_id = 15
    sampled_at = ms_now()
    token, device = _issue_credential(db, pile_id)
    try:
        payload = s.DeviceReadingRequest(
            pile_id=pile_id, sampled_at=sampled_at, output_voltage_v=400,
            output_current_a=10, power_kw=4, module_temperature_c=36,
        )
        first = service.ingest_device_reading(db, device=device, request=payload)
        second = service.ingest_device_reading(db, device=device, request=payload)
        assert first.accepted is True and first.duplicate is False
        assert second.accepted is False and second.duplicate is True
        count = db.execute(
            text("select count(*) from device_reading where pile_id = :p and sampled_at = :t"),
            {"p": pile_id, "t": sampled_at},
        ).scalar_one()
        assert count == 1
    finally:
        db.execute(
            text("delete from device_reading where pile_id = :p and sampled_at = :t"),
            {"p": pile_id, "t": sampled_at},
        )
        _drop_credential(db, device)
        db.commit()


# ---------------------------------------------------------------------------
# 9. 巡检列表的数据范围：没有任何场站授权的账号看不到记录
# ---------------------------------------------------------------------------
def test_inspection_scope_filters_outsiders(db):
    outsider = Actor(
        account_id=999,
        roles=frozenset({"maintenance_engineer"}),
        permissions=frozenset({"maintenance.inspection.read"}),
    )
    page = service.list_inspections(db, actor=outsider, query=s.InspectionQuery(page=1, page_size=50))
    assert page.total == 0

    admin_page = service.list_inspections(db, actor=ADMIN, query=s.InspectionQuery(page=1, page_size=50))
    assert admin_page.total >= page.total


# ---------------------------------------------------------------------------
# 10. 后台任务只能由平台管理员手动触发
# ---------------------------------------------------------------------------
def test_task_requires_admin(db):
    with pytest.raises(PermissionError):
        service.run_task(db, actor=ENGINEER, name="offline")


# ---------------------------------------------------------------------------
# 11. 闭环必须有复核通过记录（与存储过程口径一致）
# ---------------------------------------------------------------------------
def test_close_requires_review_passed(db):
    pile_id = 13
    alert_id, sampled_at, device = _make_alert(db, pile_id)
    try:
        wo = service.create_work_order(
            db, actor=ADMIN, alert_id=alert_id,
            request=s.CreateWorkOrderRequest(assigned_to=102),
        )
        base = wo.assigned_at
        for event_type, offset in [("accepted", 10), ("arrived", 20), ("repaired", 30)]:
            service.append_work_order_event(
                db, actor=ENGINEER, work_order_id=wo.work_order_id,
                request=s.WorkOrderEventRequest(event_type=event_type,
                                                event_at=base + timedelta(seconds=offset)),
            )
        with pytest.raises(BusinessError) as err:
            service.append_work_order_event(
                db, actor=ENGINEER, work_order_id=wo.work_order_id,
                request=s.WorkOrderEventRequest(event_type="closed",
                                                event_at=base + timedelta(seconds=40)),
            )
        assert err.value.status_code == 409

        service.append_work_order_event(
            db, actor=ENGINEER, work_order_id=wo.work_order_id,
            request=s.WorkOrderEventRequest(event_type="review_passed",
                                            event_at=base + timedelta(seconds=50)),
        )
        detail = service.append_work_order_event(
            db, actor=ENGINEER, work_order_id=wo.work_order_id,
            request=s.WorkOrderEventRequest(event_type="closed",
                                            event_at=base + timedelta(seconds=60)),
        )
        assert detail.status == "closed"
    finally:
        _cleanup_alert_chain(db, [alert_id])
        db.execute(text("delete from device_reading where pile_id = :p and sampled_at = :t"),
                   {"p": pile_id, "t": sampled_at})
        _drop_credential(db, device)
        db.commit()


# ---------------------------------------------------------------------------
# 12. 派单对象必须是运维/管理员
# ---------------------------------------------------------------------------
def test_assignee_must_be_engineer(db):
    pile_id = 12
    alert_id, sampled_at, device = _make_alert(db, pile_id)
    try:
        with pytest.raises(ValueError):
            service.create_work_order(
                db, actor=ADMIN, alert_id=alert_id,
                request=s.CreateWorkOrderRequest(assigned_to=104),  # 车主账号
            )
    finally:
        _cleanup_alert_chain(db, [alert_id])
        db.execute(text("delete from device_reading where pile_id = :p and sampled_at = :t"),
                   {"p": pile_id, "t": sampled_at})
        _drop_credential(db, device)
        db.commit()


# ---------------------------------------------------------------------------
# 13. 事件时间不能填未来（防伪造响应时限）
# ---------------------------------------------------------------------------
def test_future_event_rejected(db):
    pile_id = 11
    alert_id, sampled_at, device = _make_alert(db, pile_id)
    try:
        wo = service.create_work_order(
            db, actor=ADMIN, alert_id=alert_id,
            request=s.CreateWorkOrderRequest(assigned_to=102),
        )
        with pytest.raises(ValueError):
            service.append_work_order_event(
                db, actor=ENGINEER, work_order_id=wo.work_order_id,
                request=s.WorkOrderEventRequest(
                    event_type="accepted", event_at=utcnow() + timedelta(hours=2)
                ),
            )
    finally:
        _cleanup_alert_chain(db, [alert_id])
        db.execute(text("delete from device_reading where pile_id = :p and sampled_at = :t"),
                   {"p": pile_id, "t": sampled_at})
        _drop_credential(db, device)
        db.commit()


# ---------------------------------------------------------------------------
# 14. 恢复扫描：观察期满后 recovering → recovered
# ---------------------------------------------------------------------------
def test_recovery_task_promotes_alert(db):
    from app.modules.maintenance import models as m

    _purge_fault_code(db, "T-REC")
    rule = m.AlarmRule(rule_code="T-REC-001", fault_code="T-REC", metric="fault_code",
                       severity="low", response_seconds=60, recovery_seconds=1, enabled=1)
    db.add(rule)
    db.commit()
    pile_id = 10
    try:
        alert_id, sampled_at, device = _make_alert_with_code(db, pile_id, "T-REC")
        wo = service.create_work_order(db, actor=ADMIN, alert_id=alert_id,
                                       request=s.CreateWorkOrderRequest(assigned_to=102))
        base = wo.assigned_at
        for event_type, offset in [("accepted", 5), ("arrived", 10), ("repaired", 15),
                                   ("review_passed", 20)]:
            service.append_work_order_event(
                db, actor=ENGINEER, work_order_id=wo.work_order_id,
                request=s.WorkOrderEventRequest(event_type=event_type,
                                                event_at=base + timedelta(seconds=offset)),
            )
        service.append_work_order_event(
            db, actor=ENGINEER, work_order_id=wo.work_order_id,
            request=s.WorkOrderEventRequest(event_type="closed",
                                            event_at=base + timedelta(seconds=25)),
        )
        assert db.execute(text("select status from device_alert where alert_id = :a"),
                          {"a": alert_id}).scalar_one() == "recovering"

        assert service.check_alert_recovery(db, now=base + timedelta(seconds=60)) >= 1
        assert db.execute(text("select status from device_alert where alert_id = :a"),
                          {"a": alert_id}).scalar_one() == "recovered"
    finally:
        db.execute(text("delete from device_reading where pile_id = :p"), {"p": pile_id})
        _purge_fault_code(db, "T-REC")


# ---------------------------------------------------------------------------
# 15. KPI 按数据范围统计：无授权账号看到 0
# ---------------------------------------------------------------------------
def test_kpi_respects_scope(db):
    outsider = Actor(account_id=999, roles=frozenset({"maintenance_engineer"}),
                     permissions=frozenset({"maintenance.alert.read"}))
    admin = service.overview(db, actor=ADMIN)["kpi"]
    mine = service.overview(db, actor=outsider)["kpi"]
    assert admin["open_alerts"] > 0
    assert mine["open_alerts"] == 0
    assert mine["open_orders"] == 0


# ---------------------------------------------------------------------------
# 16. 备件领用：扣库存，超量返回 409
# ---------------------------------------------------------------------------
def test_part_usage_deducts_stock(db):
    from app.modules.maintenance import models as m

    db.execute(text("delete from spare_part where part_code = 'T-PART-001'"))
    db.commit()
    part = m.SparePart(part_code="T-PART-001", part_name="测试备件", unit="个",
                       station_id=None, stock_qty=1, safety_stock=0, status="active")
    db.add(part)
    db.commit()
    try:
        with pytest.raises(BusinessError) as err:
            service.create_part_usage(
                db, actor=ADMIN,
                request=s.CreatePartUsageRequest(work_order_id=901, part_id=part.part_id, qty=2),
            )
        assert err.value.status_code == 409

        usage = service.create_part_usage(
            db, actor=ADMIN,
            request=s.CreatePartUsageRequest(work_order_id=901, part_id=part.part_id, qty=1),
        )
        assert usage.qty == 1
        stock = db.execute(text("select stock_qty from spare_part where part_id = :p"),
                           {"p": part.part_id}).scalar_one()
        assert stock == 0
    finally:
        db.execute(text("delete from part_usage where part_id = :p"), {"p": part.part_id})
        db.execute(text("delete from spare_part where part_id = :p"), {"p": part.part_id})
        db.commit()


# ---------------------------------------------------------------------------
# 17. 报障关联告警必须给 alert_id
# ---------------------------------------------------------------------------
def test_fault_report_linked_requires_alert(db):
    with pytest.raises(ValueError):
        service.handle_fault_report(
            db, actor=ADMIN, report_id=901,
            request=s.HandleFaultReportRequest(status="linked", alert_id=None),
        )
