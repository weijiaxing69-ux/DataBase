from __future__ import annotations

import inspect
import json
import re
from pathlib import Path
from datetime import date
from decimal import Decimal

from fastapi.testclient import TestClient

from app.main import app
from app.core.database import get_db
from app.modules.membership import service
from app.modules.membership.schemas import CreatePromotionRequest
from app.shared.contracts import Actor, FleetAuthorizationSnapshot
from app.core.errors import BusinessError


PROJECT_ROOT = Path(__file__).resolve().parents[3]
CONTRACT_JSON = PROJECT_ROOT / "docs" / "新能源汽车充电桩运营服务平台_统一数据字典与接口函数规范_V1.4.json"
MEMBERSHIP_SQL = PROJECT_ROOT / "database" / "modules" / "membership"


def test_membership_api_paths_match_v14_contract():
    contract = json.loads(CONTRACT_JSON.read_text(encoding="utf-8"))
    expected = {
        (endpoint["method"].lower(), endpoint["path"])
        for endpoint in contract["api"]
        if endpoint["module"] == "membership"
    }
    schema = app.openapi()
    actual = {
        (method.lower(), path)
        for path, operations in schema["paths"].items()
        for method in operations
        if method.lower() in {"get", "post", "put", "patch", "delete"}
        and path.startswith(("/api/v1/auth/", "/api/v1/membership/"))
    }
    extensions = {
        ("post", "/api/v1/membership/wallet/refund-requests"),
        ("get", "/api/v1/membership/wallet/refund-requests"),
        ("post", "/api/v1/membership/wallet/refund-requests/{refund_request_id}/review"),
        ("post", "/api/v1/membership/appeals"),
        ("get", "/api/v1/membership/appeals"),
        ("get", "/api/v1/membership/appeals/{appeal_id}"),
        ("post", "/api/v1/membership/appeals/{appeal_id}/actions"),
    }
    assert expected <= actual
    assert actual == expected | extensions
    assert len(expected) == 48


def test_frontend_routes_match_v14_page_list():
    contract = json.loads(CONTRACT_JSON.read_text(encoding="utf-8"))
    expected = {page["path"] for page in contract["pages"] if page["module"] == "membership"}
    source = (PROJECT_ROOT / "frontend" / "member4" / "src" / "router.js").read_text(encoding="utf-8")
    declared = re.findall(r"\{ path: '([^']+)', name:", source)
    actual = {path if path.startswith("/") else f"/{path}" for path in declared}
    extensions = {"/membership/wallet/refund-requests", "/membership/appeals"}
    assert expected <= actual
    assert actual == expected | extensions
    assert len(actual) == 16


def test_public_health_and_authenticated_route_response():
    app.dependency_overrides[get_db] = lambda: object()
    client = TestClient(app)
    try:
        health = client.get("/health")
        assert health.status_code == 200
        assert health.json() == {"status": "ok"}
        unauthorized = client.get("/api/v1/auth/me")
        assert unauthorized.status_code == 401
        assert "detail" in unauthorized.json()
    finally:
        app.dependency_overrides.pop(get_db, None)


def test_cross_module_helpers_are_exported_with_contract_parameters():
    expected = {
        "validate_fleet_authorization": ("authorization_id", "user_id"),
        "reserve_fleet_quota": ("authorization_id", "order_id", "bill_month", "amount"),
        "settle_fleet_quota": ("order_id", "bill_month", "actual_amount"),
        "release_fleet_quota": ("order_id",),
        "adjust_fleet_quota_after_refund": ("refund_id",),
        "lock_coupon_for_order": ("coupon_id", "user_id", "order_id", "station_id", "original_amount"),
        "redeem_coupon_for_order": ("order_id",),
        "release_coupon_for_order": ("order_id",),
        "reissue_coupon_after_full_refund": ("order_id",),
        "debit_wallet_for_payment": ("user_id", "payment_id", "amount"),
        "credit_wallet_for_refund": ("user_id", "refund_id", "amount"),
    }
    for name, parameter_names in expected.items():
        function = getattr(service, name)
        actual = tuple(
            name for name, parameter in inspect.signature(function).parameters.items()
            if name not in {"db"} and parameter.kind is not inspect.Parameter.VAR_KEYWORD
        )
        assert actual == parameter_names


def test_membership_database_objects_are_present():
    tables = (MEMBERSHIP_SQL / "01_tables.sql").read_text(encoding="utf-8")
    views = (MEMBERSHIP_SQL / "03_views.sql").read_text(encoding="utf-8")
    procedure = (MEMBERSHIP_SQL / "04_procedures.sql").read_text(encoding="utf-8")
    triggers = (MEMBERSHIP_SQL / "05_triggers.sql").read_text(encoding="utf-8")
    queries = (MEMBERSHIP_SQL / "08_queries.sql").read_text(encoding="utf-8")
    assert len(re.findall(r"(?im)^create table `", tables)) == 24
    assert len(re.findall(r"(?im)^create or replace view ", views)) == 3
    assert len(re.findall(r"(?im)^create procedure ", procedure)) == 1
    assert len(re.findall(r"(?im)^create trigger ", triggers)) == 2
    assert len(re.findall(r"(?im)^-- (?:query|查询)\s*[123]", queries)) >= 3


def test_member4_self_service_migration_contains_refund_and_appeal_ledgers():
    migration = (PROJECT_ROOT / "database" / "migrations" / "20261119_member4_self_service.sql").read_text(encoding="utf-8")
    assert "CREATE TABLE IF NOT EXISTS wallet_balance_refund_request" in migration
    assert "UNIQUE KEY uq_wallet_balance_refund_user_key (user_id, request_key)" in migration
    assert "status IN ('pending_review', 'processing', 'completed', 'rejected')" in migration
    assert "CREATE TABLE IF NOT EXISTS membership_service_appeal" in migration
    assert "CREATE TABLE IF NOT EXISTS membership_service_appeal_event" in migration
    assert "FOREIGN KEY (order_id) REFERENCES charging_order (order_id)" in migration


def test_wallet_and_coupon_helpers_do_not_commit_or_start_transactions():
    for name in (
        "reserve_fleet_quota", "settle_fleet_quota", "release_fleet_quota",
        "lock_coupon_for_order", "redeem_coupon_for_order", "release_coupon_for_order",
        "debit_wallet_for_payment", "credit_wallet_for_refund",
    ):
        source = inspect.getsource(getattr(service, name))
        assert "db.commit(" not in source
        assert "transaction(db)" not in source


def test_fleet_admin_cannot_escape_assigned_fleet_scope(monkeypatch):
    actor = Actor(account_id=20, user_id=None, roles=frozenset({"fleet_admin"}),
                  permissions=frozenset({"membership.fleet.manage"}))
    monkeypatch.setattr(service, "_fleet_in_scope", lambda *_args: False)
    try:
        service._assert_fleet_scope(object(), actor, 999, "membership.fleet.manage")
    except BusinessError as exc:
        assert exc.status_code == 403
        assert exc.code == "fleet_out_of_scope"
    else:
        raise AssertionError("fleet admins must be denied access outside their assigned fleet scope")


def test_fleet_quota_reservation_checks_order_vehicle_and_fleet_against_authorization(monkeypatch):
    actor_order = {
        "order_mode": "fleet", "authorization_id": 7, "user_id": 3,
        "vehicle_id": 99, "fleet_id": 5, "status": "charging",
    }

    def fake_one(_db, sql, _params=None):
        if "FROM fleet_quota_reservation WHERE order_id=:order_id" in sql:
            return None
        if "FROM charging_order WHERE order_id=:id FOR UPDATE" in sql:
            return actor_order
        raise AssertionError(f"unexpected query before scope mismatch: {sql}")

    monkeypatch.setattr(service, "one", fake_one)
    monkeypatch.setattr(
        service,
        "validate_fleet_authorization",
        lambda *_args, **_kwargs: FleetAuthorizationSnapshot(
            authorization_id=7, fleet_id=5, user_id=3, vehicle_id=8, card_id=2,
            valid_from="2026-01-01T00:00:00", valid_until="2027-01-01T00:00:00",
        ),
    )
    for field, wrong_value in (("vehicle_id", 99), ("fleet_id", 99)):
        actor_order.update(vehicle_id=8, fleet_id=5)
        actor_order[field] = wrong_value
        try:
            service.reserve_fleet_quota(
                object(), authorization_id=7, order_id=100, bill_month=date(2026, 11, 1),
                amount=Decimal("50.00"),
            )
        except BusinessError as exc:
            assert exc.status_code == 409
            assert exc.code == "fleet_order_scope_mismatch"
        else:
            raise AssertionError(f"quota reservation must reject an order with mismatched {field}")


def test_station_scoped_promotion_requires_at_least_one_station():
    actor = Actor(account_id=1, user_id=None, roles=frozenset({"platform_admin"}),
                  permissions=frozenset({"membership.promotion.manage"}))
    request = CreatePromotionRequest(
        promotion_name="新用户活动", face_amount="3.00", minimum_spend="8.00",
        valid_from="2026-11-20T00:00:00Z", valid_until="2026-12-20T00:00:00Z",
        issue_limit=100, per_user_limit=1, all_stations=False, station_ids=[],
    )
    try:
        service.create_promotion(object(), actor=actor, request=request)
    except BusinessError as exc:
        assert exc.status_code == 422
        assert exc.code == "promotion_stations_required"
    else:
        raise AssertionError("a non-global campaign without station scope must be rejected")
