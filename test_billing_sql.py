"""Live MySQL verification for member 2 database deliverables."""
from pathlib import Path

import pytest
import pymysql

from db_connection import connect

QUERY_FILE = Path(__file__).resolve().parent / "database" / "modules" / "billing" / "08_queries.sql"


def queries():
    chunks = QUERY_FILE.read_text(encoding="utf-8").split("-- Q")
    return {chunk[:2]: chunk.split("\n", 1)[1].strip().rstrip(";") for chunk in chunks[1:]}


def test_views_and_query_pairs_match_with_explain():
    db = connect()
    try:
        with db.cursor() as cur:
            cur.execute("SELECT table_name FROM information_schema.views WHERE table_schema=DATABASE() AND table_name LIKE 'v_billing_%'")
            assert len(cur.fetchall()) == 3
            sql = queries()
            assert set(sql) == {"1A", "1B", "2A", "2B", "3A", "3B"}
            for pair in ("1", "2", "3"):
                results = []
                for variant in ("A", "B"):
                    statement = sql[pair + variant]
                    cur.execute(statement)
                    results.append(sorted(tuple(row.values()) for row in cur.fetchall()))
                    cur.execute("EXPLAIN FORMAT=JSON " + statement)
                    assert "query_block" in cur.fetchone()["EXPLAIN"]
                assert results[0] == results[1], f"Q{pair} pair differs"
    finally:
        db.close()


def insert_order(cur, status, due=None):
    cur.execute("SELECT g.gun_id,p.station_id,s.operator_id FROM charging_gun g JOIN charging_pile p ON p.pile_id=g.pile_id JOIN station s ON s.station_id=p.station_id WHERE NOT EXISTS (SELECT 1 FROM charging_order o WHERE o.active_gun_id=g.gun_id) LIMIT 1")
    asset = cur.fetchone()
    cur.execute("SELECT rule_id FROM pricing_rule WHERE station_id=%s LIMIT 1", (asset["station_id"],))
    rule_id = cur.fetchone()["rule_id"]
    cur.execute("INSERT INTO charging_order(user_id,gun_id,rule_id,operator_id,station_id,order_mode,status,started_at,payable_amount,payment_due_at) VALUES (19,%s,%s,%s,%s,'personal',%s,DATE_SUB(UTC_TIMESTAMP(3),INTERVAL 1 SECOND),10,%s)", (asset["gun_id"], rule_id, asset["operator_id"], asset["station_id"], status, due))
    return cur.lastrowid


def test_trigger_rejects_regression_and_closed_order():
    db = connect()
    try:
        with db.cursor() as cur:
            cur.execute("SELECT trigger_name FROM information_schema.triggers WHERE trigger_schema=DATABASE() AND trigger_name='trg_billing_meter_reading_validate'")
            assert cur.fetchone()
            order_id = insert_order(cur, "charging")
            cur.execute("INSERT INTO meter_reading(order_id,sampled_at,cumulative_energy_kwh,source) VALUES (%s,UTC_TIMESTAMP(3),1,'simulator')", (order_id,))
            with pytest.raises(pymysql.err.OperationalError):
                cur.execute("INSERT INTO meter_reading(order_id,sampled_at,cumulative_energy_kwh,source) VALUES (%s,DATE_ADD(UTC_TIMESTAMP(3),INTERVAL 1 SECOND),0.5,'simulator')", (order_id,))
            cur.execute("UPDATE charging_order SET status='paid' WHERE order_id=%s", (order_id,))
            with pytest.raises(pymysql.err.OperationalError):
                cur.execute("INSERT INTO meter_reading(order_id,sampled_at,cumulative_energy_kwh,source) VALUES (%s,DATE_ADD(UTC_TIMESTAMP(3),INTERVAL 2 SECOND),2,'simulator')", (order_id,))
    finally:
        db.rollback()
        db.close()


def test_procedure_expires_unpaid_and_releases_coupon():
    db = connect()
    try:
        with db.cursor() as cur:
            cur.execute("SELECT routine_name FROM information_schema.routines WHERE routine_schema=DATABASE() AND routine_name='sp_billing_expire_unpaid'")
            assert cur.fetchone()
            order_id = insert_order(cur, "awaiting_payment", "2020-01-01 00:00:00")
            partial_id = insert_order(cur, "awaiting_payment", "2020-01-01 00:00:00")
            cur.execute("INSERT INTO payment_record(order_id,channel,external_trade_no,amount,status,paid_at) VALUES (%s,'mock',%s,1,'succeeded',UTC_TIMESTAMP(3))",
                        (partial_id,f"partial-expiry-{partial_id}"))
            cur.execute("INSERT INTO user_coupon(promotion_id,user_id,received_at,expires_at,face_amount_snapshot,minimum_spend_snapshot,status) VALUES (19,19,UTC_TIMESTAMP(3),DATE_ADD(UTC_TIMESTAMP(3),INTERVAL 1 DAY),2,0,'locked')")
            coupon_id = cur.lastrowid
            cur.execute("INSERT INTO coupon_usage(coupon_id,order_id,original_amount,discount_amount,locked_at,lock_expires_at,status) VALUES (%s,%s,10,2,UTC_TIMESTAMP(3),DATE_ADD(UTC_TIMESTAMP(3),INTERVAL 1 HOUR),'locked')", (coupon_id,order_id))
            cur.execute("CALL sp_billing_expire_unpaid(UTC_TIMESTAMP(3), @expired_count)")
            while cur.nextset():
                pass
            cur.execute("SELECT @expired_count AS n")
            assert cur.fetchone()["n"] >= 1
            cur.execute("SELECT status FROM charging_order WHERE order_id=%s", (order_id,))
            assert cur.fetchone()["status"] == "cancelled"
            cur.execute("SELECT status FROM charging_order WHERE order_id=%s", (partial_id,))
            assert cur.fetchone()["status"] == "awaiting_payment"
            cur.execute("SELECT status FROM user_coupon WHERE coupon_id=%s", (coupon_id,))
            assert cur.fetchone()["status"] == "available"
    finally:
        db.rollback()
        db.close()
