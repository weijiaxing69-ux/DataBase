from decimal import Decimal
from uuid import uuid4

import pytest
from sqlalchemy import text


def actors(client):
    result = {}
    for role in ("platform_admin", "customer_service", "operator_manager", "fleet_admin", "vehicle_owner"):
        r = client.post("/api/v1/auth/login", json={"username": role+"_demo", "password": "ChargeDemo-2026!"})
        assert r.status_code == 200, r.text
        result[role] = {"Authorization": "Bearer "+r.json()["access_token"]}
    return result


def post(client, headers, path, data, status=200):
    r = client.post("/api/v1/settlement"+path, headers={**headers, "Idempotency-Key": uuid4().hex}, json=data)
    assert r.status_code == status, (path, r.status_code, r.text)
    return r.json()


def test_credit_consumes_old_orders_before_carry(api_client):
    client = api_client
    staff = actors(client)["customer_service"]
    engine = client.app.state.engine
    # Three cases: more credit than order, exactly enough, less than the order.
    for fleet, refund, expected_due in ((1, 20, -10), (2, 10, 0), (3, 2, 8)):
        with engine.begin() as db:
            def order(month, amount, status):
                result = db.execute(text("""INSERT INTO charging_order(user_id,gun_id,vehicle_id,authorization_id,
                    rule_id,operator_id,station_id,fleet_id,order_mode,status,started_at,finished_at,energy_kwh,
                    electricity_amount,service_amount,payable_amount)
                    SELECT user_id,gun_id,vehicle_id,authorization_id,rule_id,operator_id,station_id,
                    fleet_id,'fleet',:status,:start,:finish,10,:amount,0,:amount
                    FROM charging_order WHERE order_id=:template"""),
                    dict(template=100+fleet, status=status, start=f"2026-{month}-15 00:00:00",
                         finish=f"2026-{month}-15 01:00:00", amount=amount))
                return result.lastrowid
            original = order("10", 30, "paid")
            pid = db.execute(text("""INSERT INTO payment_record(order_id,channel,external_trade_no,amount,status,paid_at)
                VALUES(:oid,'mock',:number,30,'succeeded','2026-10-15 02:00:00')"""),
                dict(oid=original, number=f"reg-original-{fleet}")).lastrowid
            db.execute(text("""INSERT INTO refund_record(payment_id,external_refund_no,amount,status,refunded_at,
                reason,requested_by,settlement_method) VALUES(:pid,:number,:amount,'succeeded','2026-11-05',
                'credit regression',103,'fleet_credit')"""), dict(pid=pid, number=f"reg-refund-{fleet}", amount=refund))
            old_order = order("11", 10, "awaiting_payment")
            next_order = order("12", 30, "awaiting_payment")
        bill = post(client, staff, "/fleet-bills", dict(fleet_id=str(fleet), bill_month="2026-11-01"), 201)
        assert Decimal(bill["payable_amount"]) == expected_due
        if expected_due > 0:
            post(client, staff, f"/fleet-bills/{bill['bill_id']}/payments",
                 dict(external_trade_no=f"reg-cash-{fleet}", amount=str(expected_due)), 201)
        with engine.connect() as db:
            assert db.execute(text("SELECT status FROM charging_order WHERE order_id=:id"), dict(id=old_order)).scalar_one() == "paid"
            paid, credit = db.execute(text("""SELECT SUM(amount),SUM(fleet_credit_amount)
                FROM payment_record WHERE order_id=:id"""), dict(id=old_order)).one()
            assert paid == 10 and credit == min(refund, 10)
        # Reusing the zero-cash receipt cannot consume credit twice.
        if expected_due <= 0:
            post(client, staff, f"/fleet-bills/{bill['bill_id']}/payments",
                 dict(external_trade_no=f"credit-only:{bill['bill_id']}", amount="0"), 201)
        later = post(client, staff, "/fleet-bills", dict(fleet_id=str(fleet), bill_month="2026-12-01"), 201)
        cash = 30-max(refund-10, 0)
        assert Decimal(later["payable_amount"]) == cash
        post(client, staff, f"/fleet-bills/{later['bill_id']}/payments",
             dict(external_trade_no=f"reg-later-{fleet}", amount=str(cash)), 201)
        with engine.connect() as db:
            assert db.execute(text("SELECT status FROM charging_order WHERE order_id=:id"), dict(id=next_order)).scalar_one() == "paid"
            old_paid = db.execute(text("SELECT SUM(amount) FROM payment_record WHERE order_id=:id"), dict(id=old_order)).scalar_one()
            assert old_paid == 10
            if expected_due < 0:
                assert db.execute(text("SELECT status FROM fleet_monthly_bill WHERE bill_id=:id"),
                                  dict(id=bill["bill_id"])).scalar_one() == "closed"


def test_audit_and_adjustment_queries(api_client, monkeypatch):
    client = api_client
    who = actors(client)
    staff, admin, operator = (who[x] for x in ("customer_service", "platform_admin", "operator_manager"))
    engine = client.app.state.engine
    diff = post(client, staff, "/differences",
        dict(settlement_id="1", order_id="1", difference_type="price", amount="0.50"), 201)
    did = diff["difference_id"]
    for version, resolution in ((1, "original conclusion"), (2, "corrected conclusion")):
        post(client, staff, f"/differences/{did}/resolutions",
             dict(object_version=version, resolution=resolution))
    def history(kind, target, actor=admin):
        r = client.get("/api/v1/settlement/audit-events",
            params=dict(object_type=kind, object_id=target), headers=actor)
        assert r.status_code == 200, r.text
        return r.json()["items"]
    items = history("difference", did)
    assert items[0]["before_state"]["resolution"] == "original conclusion"
    assert items[0]["after_state"]["resolution"] == "corrected conclusion"
    assert items[0]["actor_id"] == "103"
    # Audit failure must roll back the business change and request-dedup result too.
    from app.modules.settlement import audit
    original = audit.execute
    def fail(*args, **kwargs):
        raise RuntimeError("simulated audit failure")
    monkeypatch.setattr(audit, "execute", fail)
    with pytest.raises(RuntimeError, match="simulated audit failure"):
        post(client, staff, f"/differences/{did}/resolutions",
             dict(object_version=3, resolution="must roll back"))
    monkeypatch.setattr(audit, "execute", original)
    row = client.get(f"/api/v1/settlement/differences/{did}", headers=admin).json()
    assert row["version"] == 3 and row["resolution"] == "corrected conclusion"
    assert len(history("difference", did)) == 2
    adjustment = post(client, staff, "/settlements/1/adjustments",
        dict(amount="0.50", reason="audit regression"), 201)
    aid = adjustment["adjustment_id"]
    rows = client.get("/api/v1/settlement/adjustments?settlement_id=1&status=pending", headers=admin).json()
    assert any(r["adjustment_id"] == aid for r in rows["items"])
    post(client, staff, f"/adjustments/{aid}/reviews", dict(decision="approved", note="forbidden"), 403)
    post(client, admin, f"/adjustments/{aid}/reviews", dict(decision="approved", note="checked original evidence"))
    assert history("adjustment", aid)[0]["note"] == "checked original evidence"
    assert client.get(f"/api/v1/settlement/adjustments/{aid}", headers=operator).status_code == 200
    post(client, admin, "/operator-invoices/1/red-issues", dict(amount="0.10", reason="operator red evidence"))
    assert history("operator_invoice", "1")[0]["note"] == "operator red evidence"
    # Existing issued personal invoice can be red-issued with a retained reason.
    post(client, staff, "/user-invoices/1/red-issues", dict(amount="0.10", reason="user red evidence"))
    assert history("user_invoice", "1", staff)[0]["note"] == "user red evidence"
    with engine.begin() as db:
        db.execute(text("DELETE FROM sys_account_operator WHERE account_id=106 AND operator_id<>1"))
    bad = client.get("/api/v1/settlement/audit-events?object_type=settlement&object_id=2", headers=operator)
    assert bad.status_code == 403
    for role in ("vehicle_owner", "fleet_admin"):
        assert client.get("/api/v1/settlement/adjustments", headers=who[role]).status_code == 403


def test_write_role_matrix(api_client):
    client = api_client
    who = actors(client)
    # Rejections are checked at service permission boundaries with valid request shapes.
    cases = [
        ("/settlements", dict(operator_id=1, station_id=1, bill_month="2026-12-01"),
         {"platform_admin", "customer_service"}),
        ("/policies", dict(operator_id=1, station_id=1, electricity_share_rate="0.7",
         service_share_rate="0.8", platform_fee_rate="0.05", payment_basis="paid_only",
         valid_from="2031-01-01", valid_until="2032-01-01"), {"platform_admin"}),
        ("/fleet-prices", dict(fleet_id=1, period_id=11, electricity_rate="0.4", service_rate="0.1",
         valid_from="2031-01-01", valid_until="2032-01-01"), {"platform_admin", "customer_service"}),
        ("/differences", dict(settlement_id=1, order_id=1, difference_type="price", amount="0.1"),
         {"customer_service"}),
        ("/settlements/1/adjustments", dict(amount="0.1", reason="role test"), {"platform_admin", "customer_service"}),
        ("/settlements/1/invoices", dict(title="Demo", tax_no="DEMO", amount="0.1"),
         {"platform_admin", "customer_service"}),
        ("/operator-invoices/1/red-issues", dict(amount="0.01", reason="role test"),
         {"platform_admin", "customer_service"}),
        ("/fleet-bills", dict(fleet_id=1, bill_month="2026-12-01"), {"customer_service"}),
        ("/fleet-bills/1/payments", dict(external_trade_no="role-test", amount="1"), {"customer_service"}),
        ("/user-invoices/1/processing", dict(decision="issued", note="role test"), {"customer_service"}),
        ("/user-invoices/1/red-issues", dict(amount="0.01", reason="role test"), {"customer_service"}),
    ]
    for path, body, allowed in cases:
        for role, headers in who.items():
            if role not in allowed:
                post(client, headers, path, body, 403)
