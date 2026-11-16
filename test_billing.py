"""Two distinct checks: pure pricing validation and live MySQL API transactions."""
from uuid import uuid4
from datetime import datetime, timedelta
from decimal import Decimal
import hashlib
import secrets

import pytest
from fastapi.testclient import TestClient

from backend import app, money, validate_periods, calculate_segments, password_hash, expire_unpaid_orders
from db_connection import connect
from fleet_billing import apply_fleet_bill_payment, FleetBillingError


def auth_headers(account_id, role_code="vehicle_owner"):
    token=secrets.token_urlsafe(32)
    db=connect()
    with db.cursor() as cur:
        cur.execute("SELECT role_id FROM sys_role WHERE role_code=%s",(role_code,))
        role=cur.fetchone()
        if not role:
            cur.execute("INSERT INTO sys_role(role_code,role_name) VALUES (%s,%s)",(role_code,role_code))
            role_id=cur.lastrowid
        else: role_id=role['role_id']
        cur.execute("INSERT IGNORE INTO sys_account_role(account_id,role_id) VALUES (%s,%s)",(account_id,role_id))
        if role_code=="customer_service":
            cur.execute("INSERT IGNORE INTO sys_account_station(account_id,station_id) VALUES (%s,19)",(account_id,))
        cur.execute("INSERT INTO sys_session(account_id,jti_hash,expires_at) VALUES (%s,%s,DATE_ADD(UTC_TIMESTAMP(), INTERVAL 1 HOUR))",(account_id,hashlib.sha256(token.encode()).digest()))
    db.commit(); db.close()
    return {"x-actor-id":str(account_id),"authorization":"Bearer "+token}


def test_unit_pricing_rounding_and_period_validation():
    assert str(money("1.005")) == "1.01"
    periods = [dict(period_type="peak", start_minute=0, end_minute=720, electricity_rate="1.2", service_rate="0.3"),
               dict(period_type="valley", start_minute=720, end_minute=1440, electricity_rate="0.5", service_rate="0.2")]
    assert len(validate_periods(periods)) == 2
    with pytest.raises(Exception):
        validate_periods([dict(period_type="peak", start_minute=0, end_minute=700, electricity_rate="1", service_rate="0")])


def test_unit_split_tariff_and_free_service_boundary():
    start=datetime(2026,11,13,11,59)
    boundary=datetime(2026,11,13,12,0)
    end=datetime(2026,11,13,12,1)
    periods=[dict(period_id=1,start_minute=0,end_minute=720,electricity_rate=Decimal("0.50"),service_rate=Decimal("0.20")),
             dict(period_id=2,start_minute=720,end_minute=1440,electricity_rate=Decimal("1.00"),service_rate=Decimal("0.20"))]
    samples=[dict(sampled_at=start,cumulative_energy_kwh=Decimal("0")),dict(sampled_at=boundary,cumulative_energy_kwh=Decimal("1")),dict(sampled_at=end,cumulative_energy_kwh=Decimal("2"))]
    result=calculate_segments(samples,periods,start,end,1)
    assert [str(x[4]) for x in result]==["0.50","1.00"]
    assert [str(x[5]) for x in result]==["0.00","0.20"]
    with pytest.raises(Exception):
        calculate_segments([samples[0],samples[2]],periods,start,end,1)


def test_unit_price_rule_effective_boundary_requires_meter_sample():
    start=datetime(2026,11,13,11,59)
    boundary=datetime(2026,11,13,12,0)
    end=datetime(2026,11,13,12,1)
    periods=[dict(period_id=1,start_minute=0,end_minute=1440,electricity_rate=Decimal("0.5"),
                  service_rate=Decimal("0.1"),valid_from=start-timedelta(days=1),valid_until=boundary),
             dict(period_id=2,start_minute=0,end_minute=1440,electricity_rate=Decimal("1.0"),
                  service_rate=Decimal("0.2"),valid_from=boundary,valid_until=end+timedelta(days=1))]
    samples=[dict(sampled_at=start,cumulative_energy_kwh=Decimal("0")),
             dict(sampled_at=boundary,cumulative_energy_kwh=Decimal("1")),
             dict(sampled_at=end,cumulative_energy_kwh=Decimal("2"))]
    result=calculate_segments(samples,periods,start,end,0)
    assert [row[0]["period_id"] for row in result]==[1,2]
    assert [row[4] for row in result]==[Decimal("0.50"),Decimal("1.00")]
    with pytest.raises(Exception):
        calculate_segments([samples[0],samples[2]],periods,start,end,0)


def test_live_mysql_order_payment_refund_and_duplicate_start():
    client = TestClient(app)
    db = connect()
    with db.cursor() as cur:
        cur.execute("UPDATE charging_order SET status='paid' WHERE gun_id=19 AND status='charging'")
        cur.execute("UPDATE charging_pile SET status='idle',lifecycle_status='active' WHERE pile_id=19")
        cur.execute("UPDATE charging_gun SET status='idle' WHERE gun_id=19")
        cur.execute("UPDATE pricing_rule SET status='active' WHERE rule_id=19")
        cur.execute("UPDATE app_user SET balance=100 WHERE user_id=19")
    db.commit(); db.close()
    headers = auth_headers(19)
    device_headers=auth_headers(16,"platform_admin")
    start_headers={**headers,"Idempotency-Key":str(uuid4())}
    created = client.post("/api/v1/billing/orders", json={"user_id": 19, "gun_id": 19}, headers=start_headers)
    assert created.status_code == 201, created.text
    order_id = created.json()["order_id"]
    replay = client.post("/api/v1/billing/orders", json={"gun_id": 19, "user_id": 19}, headers=start_headers)
    assert replay.status_code == 201 and replay.json()["order_id"] == order_id
    conflict = client.post("/api/v1/billing/orders", json={"user_id": 18, "gun_id": 19}, headers=start_headers)
    assert conflict.status_code == 409
    duplicate = client.post("/api/v1/billing/orders", json={"user_id": 19, "gun_id": 19}, headers=headers)
    assert duplicate.status_code == 409
    failed_key=str(uuid4())
    assert client.post("/api/v1/billing/orders",json={"user_id":19,"gun_id":19},
                       headers={**headers,"Idempotency-Key":failed_key}).status_code==409
    db=connect()
    with db.cursor() as cur:
        cur.execute("SELECT COUNT(*) AS n FROM request_dedup WHERE account_id=19 AND operation='start_order' AND idempotency_key=%s",(failed_key,))
        assert cur.fetchone()["n"]==0
    db.close()
    for amount in ("0", "5"):
        response = client.post(f"/api/v1/billing/orders/{order_id}/readings", json={"cumulative_energy_kwh": amount}, headers=device_headers)
        assert response.status_code == 201, response.text
    finished = client.post(f"/api/v1/billing/orders/{order_id}/finish", headers=device_headers)
    assert finished.status_code == 200, finished.text
    assert finished.json()["review_required"] is False
    payable = finished.json()["payable_amount"]
    trade = "test-pay-" + uuid4().hex
    payment_headers={**headers,"Idempotency-Key":str(uuid4())}
    payment = client.post(f"/api/v1/billing/orders/{order_id}/payments", json={"amount": payable, "external_trade_no": trade}, headers=payment_headers)
    assert payment.status_code == 201, payment.text
    payment_replay = client.post(f"/api/v1/billing/orders/{order_id}/payments", json={"external_trade_no": trade,"amount": payable}, headers=payment_headers)
    assert payment_replay.status_code == 201 and payment_replay.json() == payment.json()
    repeated = client.post(f"/api/v1/billing/orders/{order_id}/payments", json={"amount": payable, "external_trade_no": trade}, headers=headers)
    assert repeated.json()["payment_id"] == payment.json()["payment_id"]
    refund = client.post(f"/api/v1/billing/orders/{order_id}/refunds", json={"payment_id": payment.json()["payment_id"], "amount": payable, "external_refund_no": "test-ref-"+uuid4().hex}, headers=auth_headers(17,"customer_service"))
    assert refund.status_code == 201, refund.text
    order = client.get(f"/api/v1/billing/orders/{order_id}", headers=headers)
    assert order.json()["status"] == "paid"


def test_live_mysql_incomplete_meter_reading_blocks_collection():
    client = TestClient(app)
    db = connect()
    with db.cursor() as cur:
        cur.execute("UPDATE charging_order SET status='paid' WHERE gun_id=18 AND status='charging'")
        cur.execute("UPDATE charging_pile SET status='idle',lifecycle_status='active' WHERE pile_id=18")
        cur.execute("UPDATE charging_gun SET status='idle' WHERE gun_id=18")
        cur.execute("UPDATE pricing_rule SET status='active' WHERE rule_id=18")
        cur.execute("UPDATE app_user SET balance=100 WHERE user_id=18")
    db.commit(); db.close()
    headers = auth_headers(18)
    device_headers=auth_headers(16,"platform_admin")
    created = client.post("/api/v1/billing/orders", json={"user_id":18,"gun_id":18}, headers=headers)
    assert created.status_code == 201, created.text
    order_id = created.json()["order_id"]
    assert client.post(f"/api/v1/billing/orders/{order_id}/readings",json={"cumulative_energy_kwh":"5"},headers=device_headers).status_code == 201
    finished = client.post(f"/api/v1/billing/orders/{order_id}/finish",headers=device_headers)
    assert finished.json()["review_required"] is True
    payment = client.post(f"/api/v1/billing/orders/{order_id}/payments",json={"amount":"1","external_trade_no":"blocked-"+uuid4().hex},headers=headers)
    assert payment.status_code == 409
    review = client.post(f"/api/v1/billing/orders/{order_id}/reviews",json={"decision":"approved"},headers=device_headers)
    assert review.status_code == 409
    rejected = client.post(f"/api/v1/billing/orders/{order_id}/reviews",json={"decision":"rejected","note":"读数缺失"},headers=device_headers)
    assert rejected.status_code == 201 and rejected.json()["review_id"] > 0
    assert client.get(f"/api/v1/billing/orders/{order_id}",headers=headers).json()["status"] == "cancelled"


def test_live_mysql_fleet_cash_and_credit_allocation():
    db=connect()
    with db.cursor() as cur:
        cur.execute("SELECT a.authorization_id,a.vehicle_id,c.fleet_id FROM fleet_authorization a JOIN fleet_card c ON c.card_id=a.card_id LIMIT 1")
        auth=cur.fetchone()
        cur.execute("SELECT g.gun_id,p.station_id,s.operator_id FROM charging_gun g JOIN charging_pile p ON p.pile_id=g.pile_id JOIN station s ON s.station_id=p.station_id LIMIT 1")
        asset=cur.fetchone()
        cur.execute("SELECT rule_id FROM pricing_rule WHERE station_id=%s LIMIT 1",(asset["station_id"],))
        rule=cur.fetchone()
        cur.execute("INSERT INTO charging_order(user_id,gun_id,vehicle_id,authorization_id,rule_id,operator_id,station_id,fleet_id,order_mode,status,started_at,finished_at,payable_amount) VALUES (1,%s,%s,%s,%s,%s,%s,%s,'fleet','awaiting_payment',UTC_TIMESTAMP(),UTC_TIMESTAMP(),50)",(asset["gun_id"],auth["vehicle_id"],auth["authorization_id"],rule["rule_id"],asset["operator_id"],asset["station_id"],auth["fleet_id"]))
        order_id=cur.lastrowid
        cur.execute("SELECT COALESCE(DATE_ADD(MAX(bill_month),INTERVAL 1 MONTH),'2028-01-01') AS next_month FROM fleet_monthly_bill WHERE fleet_id=%s",(auth["fleet_id"],))
        month=cur.fetchone()["next_month"]
        cur.execute("INSERT INTO fleet_monthly_bill(fleet_id,bill_month,order_amount,adjustment_amount,payable_amount,status) VALUES (%s,%s,50,-20,30,'issued')",(auth["fleet_id"],month))
        bill_id=cur.lastrowid
        cur.execute("INSERT INTO fleet_monthly_bill_item(bill_id,order_id,item_type,occurred_at,amount,original_order_finished_at,business_key) VALUES (%s,%s,'order',UTC_TIMESTAMP(),50,UTC_TIMESTAMP(),%s)",(bill_id,order_id,"test-order-"+uuid4().hex))
        cur.execute("INSERT INTO fleet_monthly_bill_item(bill_id,order_id,item_type,occurred_at,amount,original_order_finished_at,business_key,source_bill_id) VALUES (%s,%s,'credit_carry',UTC_TIMESTAMP(),-20,UTC_TIMESTAMP(),%s,19)",(bill_id,order_id,"test-credit-"+uuid4().hex))
        cur.execute("INSERT INTO fleet_bill_payment(bill_id,external_trade_no,amount,status,paid_at,recorded_by) VALUES (%s,%s,30,'succeeded',UTC_TIMESTAMP(),17)",(bill_id,"test-fleet-"+uuid4().hex))
        payment_id=cur.lastrowid
        result=apply_fleet_bill_payment(cur,payment_id)
        assert result["allocations"]==1
        cur.execute("SELECT amount,fleet_credit_amount FROM payment_record WHERE bill_payment_id=%s",(payment_id,))
        record=cur.fetchone()
        assert record["amount"]==Decimal("50.00")
        assert record["fleet_credit_amount"]==Decimal("20.00")
        assert apply_fleet_bill_payment(cur,payment_id)["already_applied"] is True
        cur.execute("INSERT INTO fleet_bill_payment(bill_id,external_trade_no,amount,status,paid_at,recorded_by) VALUES (%s,%s,1,'succeeded',UTC_TIMESTAMP(),17)",(bill_id,"test-overpay-"+uuid4().hex))
        overpay_id=cur.lastrowid
        with pytest.raises(FleetBillingError):
            apply_fleet_bill_payment(cur,overpay_id)
        cur.execute("DELETE FROM fleet_bill_payment WHERE bill_payment_id=%s",(overpay_id,))
    db.commit();db.close()


def test_live_mysql_coupon_full_refund_reissues_once_and_scope():
    client=TestClient(app)
    db=connect()
    with db.cursor() as cur:
        cur.execute("UPDATE charging_order SET status='paid' WHERE gun_id=19 AND status='charging'")
        cur.execute("UPDATE charging_pile SET status='idle',lifecycle_status='active' WHERE pile_id=19")
        cur.execute("UPDATE charging_gun SET status='idle' WHERE gun_id=19")
        cur.execute("UPDATE pricing_rule SET status='active',minimum_amount=10,free_service_minutes=0 WHERE rule_id=19")
        cur.execute("UPDATE app_user SET balance=100 WHERE user_id=19")
        cur.execute("INSERT INTO user_coupon(promotion_id,user_id,received_at,expires_at,face_amount_snapshot,minimum_spend_snapshot,status) VALUES (19,19,UTC_TIMESTAMP(),DATE_ADD(UTC_TIMESTAMP(),INTERVAL 30 DAY),2,0,'available')")
        coupon_id=cur.lastrowid
    db.commit();db.close()
    owner=auth_headers(19)
    device_headers=auth_headers(16,"platform_admin")
    created=client.post('/api/v1/billing/orders',json={"user_id":19,"gun_id":19},headers=owner)
    assert created.status_code==201,created.text
    order_id=created.json()['order_id']
    assert client.get(f'/api/v1/billing/orders/{order_id}').status_code==401
    other=auth_headers(18)
    assert client.get(f'/api/v1/billing/orders/{order_id}',headers=other).status_code==403
    assert all(row['order_id']!=order_id for row in client.get('/api/v1/billing/orders',headers=other).json()['items'])
    assert client.get('/api/v1/billing/price-reviews',headers=other).status_code==403
    for energy in ('0','5'):
        assert client.post(f'/api/v1/billing/orders/{order_id}/readings',json={"cumulative_energy_kwh":energy},headers=device_headers).status_code==201
    finished=client.post(f'/api/v1/billing/orders/{order_id}/finish',json={"coupon_id":coupon_id},headers=device_headers)
    assert finished.status_code==200,finished.text
    amount=finished.json()['payable_amount']
    paid=client.post(f'/api/v1/billing/orders/{order_id}/payments',json={"amount":amount,"external_trade_no":"coupon-pay-"+uuid4().hex},headers=owner)
    assert paid.status_code==201,paid.text
    service=auth_headers(17,'customer_service')
    payload={"payment_id":paid.json()['payment_id'],"amount":amount,"external_refund_no":"coupon-ref-"+uuid4().hex}
    refunded=client.post(f'/api/v1/billing/orders/{order_id}/refunds',json=payload,headers=service)
    assert refunded.status_code==201,refunded.text
    assert client.post(f'/api/v1/billing/orders/{order_id}/refunds',json=payload,headers=service).json()['refund_id']==refunded.json()['refund_id']
    assert client.get(f'/api/v1/billing/refunds/{refunded.json()["refund_id"]}',headers=owner).status_code==200
    assert client.get(f'/api/v1/billing/refunds/{refunded.json()["refund_id"]}',headers=other).status_code==403
    assert client.post(f'/api/v1/billing/orders/{order_id}/refunds',json=payload,headers=owner).status_code==403
    assert client.post(f'/api/v1/billing/orders/{order_id}/reviews',json={"decision":"approved"},headers=owner).status_code==403
    db=connect()
    with db.cursor() as cur:
        cur.execute('SELECT COUNT(*) n FROM user_coupon WHERE reissue_source_order_id=%s',(order_id,))
        assert cur.fetchone()['n']==1
    db.close()


def test_live_mysql_login_and_coupon_timeout_release():
    client=TestClient(app)
    db=connect()
    with db.cursor() as cur:
        cur.execute("SELECT password_hash FROM sys_account WHERE account_id=16")
        original_hash=cur.fetchone()['password_hash']
        cur.execute("UPDATE sys_account SET password_hash=%s,failed_attempts=0,locked_until=NULL WHERE account_id=16",(password_hash("local-test-password"),))
        cur.execute("SELECT username FROM sys_account WHERE account_id=16")
        username=cur.fetchone()['username']
    db.commit();db.close()
    wrong=client.post('/api/v1/auth/login',json={"username":username,"password":"wrong"})
    assert wrong.status_code==401
    for _ in range(4):
        assert client.post('/api/v1/auth/login',json={"username":username,"password":"wrong"}).status_code==401
    db=connect()
    with db.cursor() as cur:
        cur.execute("SELECT failed_attempts,locked_until FROM sys_account WHERE account_id=16")
        account=cur.fetchone()
        assert account['failed_attempts']==5 and account['locked_until'] is not None
        cur.execute("UPDATE sys_account SET failed_attempts=0,locked_until=NULL WHERE account_id=16")
    db.commit();db.close()
    good=client.post('/api/v1/auth/login',json={"username":username,"password":"local-test-password"})
    assert good.status_code==200 and good.json()['access_token']
    db=connect()
    with db.cursor() as cur:
        cur.execute("SELECT g.gun_id,p.station_id,s.operator_id FROM charging_gun g JOIN charging_pile p ON p.pile_id=g.pile_id JOIN station s ON s.station_id=p.station_id LIMIT 1")
        asset=cur.fetchone()
        cur.execute("SELECT rule_id FROM pricing_rule WHERE station_id=%s LIMIT 1",(asset['station_id'],))
        rule=cur.fetchone()
        cur.execute("INSERT INTO charging_order(user_id,gun_id,rule_id,operator_id,station_id,order_mode,status,started_at,finished_at,payable_amount,payment_due_at) VALUES (19,%s,%s,%s,%s,'personal','awaiting_payment',UTC_TIMESTAMP(),UTC_TIMESTAMP(),10,DATE_SUB(UTC_TIMESTAMP(),INTERVAL 1 HOUR))",(asset['gun_id'],rule['rule_id'],asset['operator_id'],asset['station_id']))
        order_id=cur.lastrowid
        cur.execute("INSERT INTO user_coupon(promotion_id,user_id,received_at,expires_at,face_amount_snapshot,minimum_spend_snapshot,status) VALUES (19,19,UTC_TIMESTAMP(),DATE_ADD(UTC_TIMESTAMP(),INTERVAL 1 DAY),2,0,'locked')")
        coupon_id=cur.lastrowid
        cur.execute("INSERT INTO coupon_usage(coupon_id,order_id,original_amount,discount_amount,locked_at,lock_expires_at,status) VALUES (%s,%s,10,2,DATE_SUB(UTC_TIMESTAMP(),INTERVAL 3 HOUR),DATE_SUB(UTC_TIMESTAMP(),INTERVAL 1 HOUR),'locked')",(coupon_id,order_id))
        expired=expire_unpaid_orders(cur)
        assert order_id in expired
        cur.execute("SELECT status FROM user_coupon WHERE coupon_id=%s",(coupon_id,))
        assert cur.fetchone()['status']=='available'
        cur.execute("UPDATE sys_account SET password_hash=%s,failed_attempts=0,locked_until=NULL WHERE account_id=16",(original_hash,))
    db.commit();db.close()
