"""Independent live-MySQL checks for fleet quotas and settlement query boundaries."""
from datetime import datetime, timedelta
from decimal import Decimal
import hashlib
import secrets
from uuid import uuid4

import pytest
from fastapi.testclient import TestClient

from billing_queries import list_billable_orders, list_refunds_for_period
from db_connection import connect
from fleet_quota import (FleetQuotaError, reserve_fleet_quota, settle_fleet_quota,
                         release_fleet_quota)
import backend
from test_billing import auth_headers
from fleet_billing import apply_fleet_bill_payment


@pytest.fixture
def rollback_cursor():
    db = connect()
    try:
        with db.cursor() as cur:
            yield cur
    finally:
        db.rollback()
        db.close()


def insert_fleet_order(cur, auth, at):
    cur.execute("SELECT g.gun_id,s.station_id,s.operator_id,r.rule_id FROM charging_gun g "
                "JOIN charging_pile p ON p.pile_id=g.pile_id JOIN station s ON s.station_id=p.station_id "
                "JOIN pricing_rule r ON r.station_id=s.station_id "
                "WHERE NOT EXISTS (SELECT 1 FROM charging_order o WHERE o.gun_id=g.gun_id AND o.status='charging') "
                "LIMIT 1")
    asset = cur.fetchone()
    cur.execute("INSERT INTO charging_order(user_id,gun_id,vehicle_id,authorization_id,rule_id,operator_id,station_id,"
                "fleet_id,order_mode,status,started_at) VALUES (%s,%s,%s,%s,%s,%s,%s,%s,'fleet','awaiting_payment',%s)",
                (auth["user_id"],asset["gun_id"],auth["vehicle_id"],auth["authorization_id"],
                 asset["rule_id"],asset["operator_id"],asset["station_id"],auth["fleet_id"],at))
    return cur.lastrowid


def test_fleet_reservation_cross_month_overage_and_release(rollback_cursor):
    cur = rollback_cursor
    cur.execute("SELECT a.*,c.fleet_id FROM fleet_authorization a JOIN fleet_card c ON c.card_id=a.card_id "
                "WHERE a.authorization_id=1 FOR UPDATE")
    auth = cur.fetchone()
    started = datetime(2030, 1, 15, 0, 0)
    ended = datetime(2030, 2, 15, 0, 0)
    order_id = insert_fleet_order(cur, auth, started)
    reserve_fleet_quota(cur, authorization=auth, order_id=order_id, at=started)
    cur.execute("SELECT q.bill_month,q.reserved_amount FROM fleet_quota_reservation r "
                "JOIN fleet_quota_month q ON q.quota_month_id=r.quota_month_id WHERE r.order_id=%s",(order_id,))
    row=cur.fetchone()
    assert str(row["bill_month"])=="2030-01-01" and row["reserved_amount"]==Decimal("50.00")
    assert settle_fleet_quota(cur, authorization=auth, order_id=order_id, amount=Decimal("120.00"), at=ended) is False
    cur.execute("UPDATE fleet_quota_month SET limit_amount=150 WHERE authorization_id=%s AND bill_month='2030-02-01'",
                (auth["authorization_id"],))
    assert settle_fleet_quota(cur, authorization=auth, order_id=order_id, amount=Decimal("120.00"), at=ended) is True
    cur.execute("SELECT q.bill_month,q.reserved_amount,q.used_amount,r.status FROM fleet_quota_reservation r "
                "JOIN fleet_quota_month q ON q.quota_month_id=r.quota_month_id WHERE r.order_id=%s",(order_id,))
    row=cur.fetchone()
    assert str(row["bill_month"])=="2030-02-01"
    assert row["reserved_amount"]==0 and row["used_amount"]==Decimal("120.00") and row["status"]=="settled"
    cur.execute("SELECT reserved_amount FROM fleet_quota_month WHERE authorization_id=%s AND bill_month='2030-01-01'",
                (auth["authorization_id"],))
    assert cur.fetchone()["reserved_amount"]==0
    another = insert_fleet_order(cur, auth, datetime(2030, 3, 15))
    reserve_fleet_quota(cur, authorization=auth, order_id=another, at=datetime(2030, 3, 15))
    release_fleet_quota(cur, order_id=another, at=datetime(2030, 3, 15, 1))
    cur.execute("SELECT status FROM fleet_quota_reservation WHERE order_id=%s",(another,))
    assert cur.fetchone()["status"]=="released"
    with pytest.raises(FleetQuotaError):
        release_fleet_quota(cur,order_id=order_id,at=ended)


def test_settlement_queries_use_half_open_periods(rollback_cursor):
    cur = rollback_cursor
    start=datetime(2031,1,1)
    end=datetime(2031,2,1)
    cur.execute("SELECT g.gun_id,s.station_id,s.operator_id,r.rule_id FROM charging_gun g "
                "JOIN charging_pile p ON p.pile_id=g.pile_id JOIN station s ON s.station_id=p.station_id "
                "JOIN pricing_rule r ON r.station_id=s.station_id LIMIT 1")
    asset=cur.fetchone()
    cur.execute("INSERT INTO charging_order(user_id,gun_id,rule_id,operator_id,station_id,order_mode,status,"
                "started_at,finished_at,payable_amount) VALUES (1,%s,%s,%s,%s,'personal','paid',%s,%s,10)",
                (asset["gun_id"],asset["rule_id"],asset["operator_id"],asset["station_id"],
                 start,start+timedelta(days=1)))
    order_id=cur.lastrowid
    cur.execute("INSERT INTO payment_record(order_id,channel,external_trade_no,amount,status,paid_at) "
                "VALUES (%s,'mock',%s,10,'succeeded',%s)",(order_id,f"query-test-{order_id}",start))
    payment_id=cur.lastrowid
    cur.execute("INSERT INTO refund_record(payment_id,external_refund_no,amount,status,refunded_at,reason,requested_by) "
                "VALUES (%s,%s,5,'succeeded',%s,'test',16)",(payment_id,f"query-refund-{payment_id}",end))
    billable=list_billable_orders(cur,start_at=start,end_at=end,station_id=asset["station_id"])
    assert any(row["order_id"]==order_id for row in billable)
    assert all(row["order_id"]!=order_id for row in list_billable_orders(cur,start_at=end,end_at=end+timedelta(days=1)))
    assert all(row["payment_id"]!=payment_id for row in list_refunds_for_period(cur,start_at=start,end_at=end))
    assert any(row["payment_id"]==payment_id for row in list_refunds_for_period(cur,start_at=end,end_at=end+timedelta(days=1)))
    with pytest.raises(ValueError):
        list_billable_orders(cur,start_at=end,end_at=start)


def test_fleet_endpoint_pricing_quota_and_cancel_in_one_rollback(rollback_cursor, monkeypatch):
    cur=rollback_cursor
    cur.execute("UPDATE charging_pile SET status='idle',lifecycle_status='active' WHERE pile_id=19")
    cur.execute("UPDATE charging_gun SET status='idle' WHERE gun_id=19")
    cur.execute("UPDATE charging_order SET status='paid' WHERE gun_id=19 AND status='charging'")
    cur.execute("UPDATE pricing_rule SET status='active',free_service_minutes=0,minimum_amount=0 WHERE rule_id=19")
    cur.execute("UPDATE fleet_price SET status='active',electricity_rate=0.5,service_rate=0.2 WHERE price_id=19")
    cur.execute("UPDATE fleet_quota_month SET limit_amount=1000 WHERE authorization_id=19 AND bill_month='2026-11-01'")

    from contextlib import contextmanager
    @contextmanager
    def same_transaction():
        yield cur
    monkeypatch.setattr(backend,"transaction",same_transaction)
    marker=backend.current_actor.set({"id":16,"roles":{"platform_admin"}})
    try:
        created=backend.start_order({"user_id":19,"gun_id":19,"authorization_id":19,"order_mode":"fleet"},16)
        order_id=created["order_id"]
        cur.execute("SELECT fleet_id,authorization_id,vehicle_id,order_mode FROM charging_order WHERE order_id=%s",(order_id,))
        order=cur.fetchone()
        assert (order["fleet_id"],order["authorization_id"],order["vehicle_id"],order["order_mode"])==(19,19,19,"fleet")
        with pytest.raises(Exception):
            backend.create_payment(order_id,{"amount":"1","external_trade_no":f"fleet-personal-{order_id}"})
        backend.submit_meter_reading(order_id,{"cumulative_energy_kwh":"0"})
        backend.submit_meter_reading(order_id,{"cumulative_energy_kwh":"5"})
        result=backend.finish_order(order_id)
        assert result["review_required"] is False
        cur.execute("SELECT price_source,price_id,electricity_rate FROM billing_detail WHERE order_id=%s",(order_id,))
        detail=cur.fetchone()
        assert detail["price_source"]=="fleet" and detail["price_id"]==19 and detail["electricity_rate"]==Decimal("0.5000")
        cur.execute("SELECT status,actual_amount FROM fleet_quota_reservation WHERE order_id=%s",(order_id,))
        assert cur.fetchone()["status"]=="settled"
        cur.execute("SELECT bill_id FROM fleet_monthly_bill WHERE fleet_id=19 AND bill_month='2026-11-01' FOR UPDATE")
        bill_id=cur.fetchone()["bill_id"]
        cur.execute("DELETE FROM fleet_monthly_bill_item WHERE bill_id=%s",(bill_id,))
        cur.execute("UPDATE fleet_monthly_bill SET order_amount=%s,adjustment_amount=0,payable_amount=%s,paid_amount=0,status='issued' WHERE bill_id=%s",
                    (result["payable_amount"],result["payable_amount"],bill_id))
        cur.execute("INSERT INTO fleet_monthly_bill_item(bill_id,order_id,item_type,occurred_at,amount,original_order_finished_at,business_key) "
                    "VALUES (%s,%s,'order',UTC_TIMESTAMP(3),%s,UTC_TIMESTAMP(3),%s)",
                    (bill_id,order_id,result["payable_amount"],f"flow-order:{order_id}"))
        cur.execute("INSERT INTO fleet_bill_payment(bill_id,external_trade_no,amount,status,paid_at,recorded_by) "
                    "VALUES (%s,%s,%s,'succeeded',UTC_TIMESTAMP(3),17)",
                    (bill_id,f"flow-bill:{order_id}",result["payable_amount"]))
        bill_payment_id=cur.lastrowid
        assert apply_fleet_bill_payment(cur,bill_payment_id)["allocations"]==1
        cur.execute("SELECT payment_id FROM payment_record WHERE bill_payment_id=%s AND order_id=%s",(bill_payment_id,order_id))
        payment_id=cur.fetchone()["payment_id"]
        refunded=backend.create_refund(order_id,{"payment_id":payment_id,"amount":result["payable_amount"],
                                                "external_refund_no":f"flow-refund:{order_id}"},17)
        cur.execute("SELECT settlement_method FROM refund_record WHERE refund_id=%s",(refunded["refund_id"],))
        assert cur.fetchone()["settlement_method"]=="fleet_credit"
        cur.execute("SELECT amount FROM fleet_quota_adjustment WHERE refund_id=%s",(refunded["refund_id"],))
        assert cur.fetchone()["amount"]==-Decimal(result["payable_amount"])
        another=backend.start_order({"user_id":19,"gun_id":19,"authorization_id":19,"order_mode":"fleet"},16)
        assert backend.cancel_order(another["order_id"])["status"]=="cancelled"
        cur.execute("SELECT status FROM fleet_quota_reservation WHERE order_id=%s",(another["order_id"],))
        assert cur.fetchone()["status"]=="released"
    finally:
        backend.current_actor.reset(marker)


def test_wallet_payment_and_refund_have_balanced_ledger(rollback_cursor, monkeypatch):
    cur=rollback_cursor
    cur.execute("UPDATE charging_order SET status='paid' WHERE gun_id=19 AND status='charging'")
    cur.execute("UPDATE charging_pile SET status='idle',lifecycle_status='active' WHERE pile_id=19")
    cur.execute("UPDATE charging_gun SET status='idle' WHERE gun_id=19")
    cur.execute("UPDATE pricing_rule SET status='active',free_service_minutes=0,minimum_amount=10 WHERE rule_id=19")
    cur.execute("UPDATE app_user SET balance=100 WHERE user_id=19")
    from contextlib import contextmanager
    @contextmanager
    def same_transaction():
        yield cur
    monkeypatch.setattr(backend,"transaction",same_transaction)
    marker=backend.current_actor.set({"id":19,"roles":{"vehicle_owner"}})
    try:
        order_id=backend.start_order({"user_id":19,"gun_id":19},19)["order_id"]
        cur.execute("UPDATE pricing_rule SET minimum_amount=100 WHERE rule_id=19")
        backend.submit_meter_reading(order_id,{"cumulative_energy_kwh":"0"})
        backend.submit_meter_reading(order_id,{"cumulative_energy_kwh":"5"})
        amount=Decimal(backend.finish_order(order_id)["payable_amount"])
        assert amount==Decimal("10.00")
        payment=backend.create_payment(order_id,{"amount":str(amount),"channel":"wallet","external_trade_no":f"wallet-check-{order_id}"})
        refund=backend.create_refund(order_id,{"payment_id":payment["payment_id"],"amount":str(amount),
                                               "external_refund_no":f"wallet-refund-check-{order_id}"},17)
        cur.execute("SELECT transaction_type,amount,balance_after FROM wallet_transaction WHERE payment_id=%s OR refund_id=%s ORDER BY wallet_transaction_id",
                    (payment["payment_id"],refund["refund_id"]))
        ledger=cur.fetchall()
        assert [row["transaction_type"] for row in ledger]==["payment","refund"]
        assert sum(row["amount"] for row in ledger)==0
        assert ledger[-1]["balance_after"]==Decimal("100.00")
    finally:
        backend.current_actor.reset(marker)


def test_api_pages_filters_and_actor_scope():
    client=TestClient(backend.app)
    admin=auth_headers(16,"platform_admin")
    owner=auth_headers(18,"vehicle_owner")
    first=client.get("/api/v1/billing/orders?page=1&page_size=2",headers=admin)
    second=client.get("/api/v1/billing/orders?page=2&page_size=2",headers=admin)
    assert first.status_code==200 and second.status_code==200
    assert first.json()["page"]==1 and first.json()["page_size"]==2
    assert first.json()["total"]>=4 and len(first.json()["items"])==2
    assert first.json()["items"][0]["order_id"]!=second.json()["items"][0]["order_id"]
    scoped=client.get("/api/v1/billing/orders?user_id=19",headers=owner)
    assert scoped.status_code==200 and scoped.json()["items"]==[]
    assert client.get("/api/v1/billing/orders?page_size=101",headers=admin).status_code==422
    assert client.get("/api/v1/billing/orders?start_at=2030-02-01T00:00:00&end_at=2030-01-01T00:00:00",headers=admin).status_code==422
    rates=client.get("/api/v1/billing/pricing-rules?page_size=2",headers=admin)
    assert rates.status_code==200 and len(rates.json()["items"])==2
    refunds=client.get("/api/v1/billing/refunds?page_size=2",headers=admin)
    assert refunds.status_code==200 and "total" in refunds.json()
    reviews=client.get("/api/v1/billing/price-reviews?page_size=2",headers=admin)
    assert reviews.status_code==200 and len(reviews.json()["items"])<=2


def test_device_credential_only_reports_its_bound_pile():
    token=secrets.token_urlsafe(32)
    db=connect()
    order_id=None
    credential_id=None
    try:
        with db.cursor() as cur:
            cur.execute("SELECT g.gun_id,g.pile_id,s.station_id,s.operator_id,r.rule_id FROM charging_gun g "
                        "JOIN charging_pile p ON p.pile_id=g.pile_id JOIN station s ON s.station_id=p.station_id "
                        "JOIN pricing_rule r ON r.station_id=s.station_id WHERE g.gun_id=19")
            asset=cur.fetchone()
            cur.execute("UPDATE charging_order SET status='paid' WHERE gun_id=19 AND status='charging'")
            cur.execute("INSERT INTO charging_order(user_id,gun_id,rule_id,operator_id,station_id,order_mode,status,started_at) "
                        "VALUES (19,%s,%s,%s,%s,'personal','charging',UTC_TIMESTAMP(3))",
                        (asset["gun_id"],asset["rule_id"],asset["operator_id"],asset["station_id"]))
            order_id=cur.lastrowid
            cur.execute("INSERT INTO device_credential(pile_id,token_hash,expires_at) VALUES (%s,%s,DATE_ADD(UTC_TIMESTAMP(3),INTERVAL 1 HOUR))",
                        (asset["pile_id"],hashlib.sha256(token.encode()).digest()))
            credential_id=cur.lastrowid
        db.commit()
        client=TestClient(backend.app)
        headers={"authorization":"Bearer "+token}
        own=client.post(f"/api/v1/billing/orders/{order_id}/readings",json={"cumulative_energy_kwh":"0"},headers=headers)
        assert own.status_code==201,own.text
        with db.cursor() as cur:
            cur.execute("SELECT source FROM meter_reading WHERE reading_id=%s",(own.json()["reading_id"],))
            assert cur.fetchone()["source"]=="device"
        other=client.post("/api/v1/billing/orders/20/readings",json={"cumulative_energy_kwh":"0"},headers=headers)
        assert other.status_code==401
        owner=auth_headers(19,"vehicle_owner")
        assert client.post(f"/api/v1/billing/orders/{order_id}/readings",json={"cumulative_energy_kwh":"1"},headers=owner).status_code==403
        finished=client.post(f"/api/v1/billing/orders/{order_id}/finish",headers=headers)
        assert finished.status_code==200 and finished.json()["review_required"] is True
    finally:
        with db.cursor() as cur:
            if order_id:
                cur.execute("DELETE FROM meter_reading WHERE order_id=%s",(order_id,))
                cur.execute("DELETE FROM device_command WHERE order_id=%s",(order_id,))
                cur.execute("DELETE FROM charging_order WHERE order_id=%s",(order_id,))
            if credential_id:
                cur.execute("DELETE FROM device_credential WHERE credential_id=%s",(credential_id,))
        db.commit()
        db.close()


def test_invalid_numeric_payloads_return_422():
    client=TestClient(backend.app)
    admin=auth_headers(16,"platform_admin")
    unauthorized=client.get("/api/v1/billing/orders")
    assert unauthorized.status_code==401
    assert {"code","message","request_id"} <= unauthorized.json().keys()
    assert client.post("/api/v1/billing/orders",json={"user_id":"invalid","gun_id":19},headers=admin).status_code==422
    assert client.post("/api/v1/billing/orders/19/readings",json={"cumulative_energy_kwh":"NaN"},headers=admin).status_code==422
    assert client.post("/api/v1/billing/orders/19/payments",json={"amount":"bad","external_trade_no":"bad"},headers=admin).status_code==422
    assert client.post("/api/v1/billing/orders/19/refunds",json={"amount":"Infinity","external_refund_no":"bad"},headers=admin).status_code==422
    assert client.post("/api/v1/billing/orders/19/readings",json={"cumulative_energy_kwh":"1","source":"device"},headers=admin).status_code==422
    bad_rule={"station_id":19,"rule_name":"缺字段测试","valid_from":"2030-01-01T00:00:00",
              "valid_until":"2030-02-01T00:00:00","periods":[{"period_type":"flat","start_minute":0,
              "end_minute":1440,"electricity_rate":"0.8"}]}
    validation=client.post("/api/v1/billing/pricing-rules",json=bad_rule,headers=admin)
    assert validation.status_code==422 and validation.json()["errors"]
    bad_rule["periods"][0]["service_rate"]="0.2"
    bad_rule["unexpected"]="ignored"
    assert client.post("/api/v1/billing/pricing-rules",json=bad_rule,headers=admin).status_code==422


def test_price_rule_accepts_valid_period_and_default_amounts():
    client=TestClient(backend.app)
    admin=auth_headers(16,"platform_admin")
    body={"station_id":19,"rule_name":"价格输入校验-"+uuid4().hex[:8],
          "valid_from":"2035-01-01T00:00:00","valid_until":"2035-02-01T00:00:00",
          "periods":[{"period_type":"flat","start_minute":0,"end_minute":1440,
                      "electricity_rate":"0.80","service_rate":"0.20"}]}
    rule_id=None
    try:
        response=client.post("/api/v1/billing/pricing-rules",json=body,headers=admin)
        assert response.status_code==201,response.text
        rule_id=response.json()["rule_id"]
        db=connect()
        with db.cursor() as cur:
            cur.execute("SELECT free_service_minutes,minimum_amount FROM pricing_rule WHERE rule_id=%s",(rule_id,))
            row=cur.fetchone()
            assert row["free_service_minutes"]==0 and row["minimum_amount"]==0
            cur.execute("SELECT COUNT(*) n FROM pricing_period WHERE rule_id=%s",(rule_id,))
            assert cur.fetchone()["n"]==1
        db.close()
    finally:
        if rule_id:
            db=connect()
            with db.cursor() as cur:
                cur.execute("DELETE FROM pricing_period WHERE rule_id=%s",(rule_id,))
                cur.execute("DELETE FROM pricing_rule WHERE rule_id=%s",(rule_id,))
            db.commit()
            db.close()


def test_fleet_price_boundary_without_reading_requires_review(rollback_cursor,monkeypatch):
    cur=rollback_cursor
    cur.execute("UPDATE charging_order SET status='paid' WHERE gun_id=19 AND status='charging'")
    cur.execute("UPDATE charging_pile SET status='idle',lifecycle_status='active' WHERE pile_id=19")
    cur.execute("UPDATE charging_gun SET status='idle' WHERE gun_id=19")
    cur.execute("UPDATE pricing_rule SET status='active',free_service_minutes=0 WHERE rule_id=19")
    cur.execute("UPDATE fleet_quota_month SET limit_amount=1000 WHERE authorization_id=19 AND bill_month='2026-11-01'")
    from contextlib import contextmanager
    @contextmanager
    def same_transaction(): yield cur
    monkeypatch.setattr(backend,"transaction",same_transaction)
    marker=backend.current_actor.set({"id":16,"roles":{"platform_admin"}})
    try:
        order_id=backend.start_order({"user_id":19,"gun_id":19,"order_mode":"fleet","authorization_id":19},16)["order_id"]
        cur.execute("SELECT started_at FROM charging_order WHERE order_id=%s",(order_id,))
        started=cur.fetchone()["started_at"]
        ended=started+timedelta(minutes=2)
        cur.execute("UPDATE fleet_price SET status='active',valid_from=%s,valid_until=%s WHERE price_id=19",
                    (started+timedelta(minutes=1),started+timedelta(days=1)))
        backend.submit_meter_reading(order_id,{"cumulative_energy_kwh":"0","sampled_at":started})
        backend.submit_meter_reading(order_id,{"cumulative_energy_kwh":"5","sampled_at":ended})
        monkeypatch.setattr(backend,"now",lambda: ended)
        result=backend.finish_order(order_id)
        assert result["review_required"] is True
        cur.execute("SELECT COUNT(*) AS n FROM billing_detail WHERE order_id=%s",(order_id,))
        assert cur.fetchone()["n"]==0
    finally:
        backend.current_actor.reset(marker)


def test_price_approval_rejects_overlapping_active_rule(rollback_cursor,monkeypatch):
    cur=rollback_cursor
    cur.execute("UPDATE pricing_rule SET status='active' WHERE rule_id=19")
    from contextlib import contextmanager
    @contextmanager
    def same_transaction(): yield cur
    monkeypatch.setattr(backend,"transaction",same_transaction)
    request=backend.RuleIn(station_id=19,rule_name="边界重叠测试",free_service_minutes=0,
                           minimum_amount=Decimal("0"),valid_from=datetime(2026,12,1),
                           valid_until=datetime(2027,1,1),periods=[{"period_type":"flat","start_minute":0,
                           "end_minute":1440,"electricity_rate":"0.8","service_rate":"0.2"}])
    rule_id=backend.create_pricing_rule(request)["rule_id"]
    review_id=backend.submit_price_review({"rule_id":rule_id},16)["review_id"]
    with pytest.raises(backend.HTTPException) as error:
        backend.review_price_change(review_id,{"decision":"approved"},17)
    assert error.value.status_code==409
    cur.execute("SELECT status FROM pricing_rule WHERE rule_id=%s",(rule_id,))
    assert cur.fetchone()["status"]=="draft"
