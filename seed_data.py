"""Reproducible demonstration seed: twenty linked rows in every V1.4 table."""
from datetime import datetime, date, timedelta
from decimal import Decimal
from pathlib import Path
import hashlib
import json

from db_connection import connect

MODEL = json.loads((Path(__file__).resolve().parent / "database" / "reference" / "model_v1.4.json").read_text(encoding="utf-8-sig"))
START = datetime(2026, 11, 1, 8)
BASE_DATE = date(2026, 11, 1)


def value(table, field, i):
    name, typ = field["name"], field["type"].lower()
    if field.get("generated"):
        return None
    if field["default"] == "AUTO_INCREMENT":
        return i
    if name in ("pile_id", "gun_id") and table in ("device_status_log", "equipment_change_request"):
        return i if name == "pile_id" else None
    if name in ("rule_id", "price_id") and table == "pricing_review":
        return i if name == "rule_id" else None
    if table == "pricing_review" and name in ("reviewed_by", "reviewed_at"):
        return None
    if name in ("settlement_id", "difference_id") and table == "reconciliation_confirmation":
        return i if name == "settlement_id" else None
    if name in ("authorization_id", "fleet_id", "vehicle_id") and table == "charging_order":
        return None
    if name == "status" and table == "charging_order":
        return "paid"
    if name in ("refund_id", "source_bill_id", "original_invoice_id", "original_user_invoice_id"):
        return None
    if name == "price_id" and table == "billing_detail":
        return None
    if name == "fleet_credit_amount":
        return Decimal("0.00")
    if table == "fleet_quota_month" and name in ("reserved_amount", "used_amount"):
        return Decimal("0.00")
    if table == "fleet_quota_reservation" and name == "actual_amount":
        return Decimal("0.00")
    if table == "fleet_quota_reservation" and name == "status":
        return "released"
    if field.get("ref"):
        return i
    if field.get("enum"):
        preferred = {"order_mode": "personal", "price_source": "ordinary", "item_type": "order",
                     "invoice_type": "blue", "decision": "pending", "status": "draft",
                     "channel": "mock", "side": "platform", "source": "device"}
        choice = preferred.get(name)
        return choice if choice in field["enum"] else field["enum"][0]
    if name in ("valid_from", "started_at", "segment_start_at", "bound_at", "occurred_at", "sampled_at", "requested_at", "accepted_at", "issued_at", "inspected_at", "locked_at", "reserved_at", "confirmed_at", "event_at"):
        return START + timedelta(minutes=i)
    if name in ("valid_until", "expires_at", "lock_expires_at", "segment_end_at", "response_due_at"):
        return START + timedelta(days=365, minutes=i)
    if name == "bill_month":
        return BASE_DATE
    if typ == "date":
        return BASE_DATE + timedelta(days=i)
    if "datetime" in typ or "timestamp" in typ:
        return START + timedelta(minutes=i)
    if typ == "json":
        return json.dumps({"seed": i})
    if "binary" in typ or "blob" in typ:
        return hashlib.sha256(f"{table}:{name}:{i}".encode()).digest() if "hash" in name else f"demo-{i}".encode()
    if typ.startswith(("decimal", "numeric", "float", "double")):
        if "latitude" in name: return Decimal("39.9000000") + Decimal(i) / 10000
        if "longitude" in name: return Decimal("116.4000000") + Decimal(i) / 10000
        if "rate" in name and "share" in name or "fee_rate" in name and table == "settlement_policy": return Decimal("0.10")
        if "energy" in name: return Decimal("5.000")
        if "power" in name: return Decimal("60.000")
        if "amount" in name or "balance" in name or "limit" in name: return Decimal("100.00")
        if "rate" in name: return Decimal("0.8000")
        return Decimal("10.00")
    if typ.startswith(("bigint", "int", "smallint", "tinyint")):
        if name == "rating": return (i - 1) % 5 + 1
        if typ.startswith("tinyint") and str(field["default"]) in ("0", "1"):
            return int(field["default"])
        if name in ("protocol_test_passed", "nameplate_checked", "start_stop_passed", "heartbeat_passed"): return 1
        if name in ("start_minute",): return 0
        if name in ("end_minute",): return 1440
        if name in ("version", "object_version"): return 1
        if name.endswith("_seconds"): return 300
        if name.endswith("_count") or name == "issued_count": return 0
        if name.startswith("is_") or name.startswith("has_") or name.endswith("_required"): return 0
        return i
    if name == "credit_code": return f"91110000DEMO{i:06d}"
    if name == "tax_no": return f"TAX{i:015d}"[:18]
    if name == "business_key": return f"{table}-{i}"
    if name in ("username", "role_code", "permission_code", "rule_code", "external_trade_no", "external_refund_no", "invoice_no", "card_no", "serial_no", "plate_hash", "phone_hash", "jti_hash", "token_hash"):
        return f"{table[:8]}-{name[:8]}-{i:03d}"
    if name.endswith("_hash"):
        return hashlib.sha256(f"{table}:{name}:{i}".encode()).hexdigest()
    if name == "content_hash" or name == "request_hash":
        return hashlib.sha256(f"{table}:{i}".encode()).digest()
    if name == "password_hash": return "$2b$12$demonstration.hash.not.for.login"
    if name == "target_path": return "/billing/orders"
    return f"演示{name}-{i}"


def main():
    db = connect()
    with db.cursor() as cur:
        cur.execute("SET FOREIGN_KEY_CHECKS=0")
        for table in MODEL["tables"]:
            name = table["name"]
            # Fixed security dictionaries have six real roles and the permissions
            # actually implemented; they must never be inflated to twenty rows.
            if name in ("sys_role","sys_permission","sys_role_permission","sys_account_role"):
                continue
            cur.execute(f"SELECT COUNT(*) AS n FROM `{name}`")
            if cur.fetchone()["n"]:
                continue
            fields = [f for f in table["fields"] if not f.get("generated")]
            cols = ",".join(f"`{f['name']}`" for f in fields)
            placeholders = ",".join(["%s"] * len(fields))
            sql = f"INSERT INTO `{name}` ({cols}) VALUES ({placeholders})"
            for i in range(1, 21):
                row = [value(name, f, i) for f in fields]
                try:
                    cur.execute(sql, row)
                except Exception as exc:
                    db.rollback()
                    raise RuntimeError(f"{name} row {i}: {exc}") from exc
            db.commit()
            print(name, 20)
        cur.execute("SET FOREIGN_KEY_CHECKS=1")
    db.close()
    normalize_demo_quota()
    from seed_security import main as seed_security
    seed_security()


def normalize_demo_quota():
    """Repair the original 20 placeholder reservations only when they still match the seed.

    Those reservations refer to personal orders and must not consume fleet credit.
    A real reservation, including any later demo activity, is left untouched.
    """
    db = connect()
    try:
        with db.cursor() as cur:
            cur.execute("SELECT COUNT(*) AS n FROM fleet_quota_reservation r "
                        "JOIN charging_order o ON o.order_id=r.order_id "
                        "JOIN fleet_quota_month q ON q.quota_month_id=r.quota_month_id "
                        "WHERE r.reservation_id BETWEEN 1 AND 20 AND o.order_mode='personal' "
                        "AND r.status='reserved' AND r.reserved_amount=100 "
                        "AND r.actual_amount=100 AND q.reserved_amount=100 AND q.used_amount=100")
            if cur.fetchone()["n"] != 20:
                return
            cur.execute("UPDATE fleet_quota_reservation SET status='released',actual_amount=0,"
                        "released_at=reserved_at WHERE reservation_id BETWEEN 1 AND 20")
            cur.execute("UPDATE fleet_quota_month q JOIN fleet_quota_reservation r "
                        "ON r.quota_month_id=q.quota_month_id "
                        "SET q.reserved_amount=0,q.used_amount=0 "
                        "WHERE r.reservation_id BETWEEN 1 AND 20")
        db.commit()
    finally:
        db.close()


if __name__ == "__main__":
    main()
