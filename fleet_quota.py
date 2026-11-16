"""Fleet monthly authorization reservations, kept in the caller's transaction."""
from datetime import timedelta, timezone
from decimal import Decimal
import os


SHANGHAI = timezone(timedelta(hours=8))
RESERVE_AMOUNT = Decimal(os.getenv("FLEET_RESERVE_AMOUNT", "50.00"))


class FleetQuotaError(ValueError):
    pass


def bill_month(at):
    return at.replace(tzinfo=timezone.utc).astimezone(SHANGHAI).date().replace(day=1)


def quota_row(cur, authorization, month):
    cur.execute("SELECT * FROM fleet_quota_month WHERE authorization_id=%s AND bill_month=%s FOR UPDATE",
                (authorization["authorization_id"], month))
    row = cur.fetchone()
    if row is None:
        cur.execute("INSERT INTO fleet_quota_month(authorization_id,bill_month,limit_amount) VALUES (%s,%s,%s)",
                    (authorization["authorization_id"], month, authorization["default_monthly_limit"]))
        cur.execute("SELECT * FROM fleet_quota_month WHERE quota_month_id=%s FOR UPDATE", (cur.lastrowid,))
        row = cur.fetchone()
    return row


def reserve_fleet_quota(cur, *, authorization, order_id, at):
    if RESERVE_AMOUNT <= 0:
        raise FleetQuotaError("车队预占额必须大于零")
    month = quota_row(cur, authorization, bill_month(at))
    if month["limit_amount"] - month["used_amount"] - month["reserved_amount"] < RESERVE_AMOUNT:
        raise FleetQuotaError("车队本月可用额度不足")
    cur.execute("UPDATE fleet_quota_month SET reserved_amount=reserved_amount+%s WHERE quota_month_id=%s",
                (RESERVE_AMOUNT, month["quota_month_id"]))
    cur.execute("INSERT INTO fleet_quota_reservation(order_id,quota_month_id,reserved_amount,reserved_at) VALUES (%s,%s,%s,%s)",
                (order_id, month["quota_month_id"], RESERVE_AMOUNT, at))


def release_fleet_quota(cur, *, order_id, at):
    cur.execute("SELECT * FROM fleet_quota_reservation WHERE order_id=%s FOR UPDATE", (order_id,))
    reservation = cur.fetchone()
    if not reservation or reservation["status"] == "released":
        return
    if reservation["status"] not in ("reserved", "review_required"):
        raise FleetQuotaError("已结算的额度不能释放")
    cur.execute("UPDATE fleet_quota_month SET reserved_amount=reserved_amount-%s WHERE quota_month_id=%s",
                (reservation["reserved_amount"], reservation["quota_month_id"]))
    cur.execute("UPDATE fleet_quota_reservation SET status='released',released_at=%s WHERE reservation_id=%s",
                (at, reservation["reservation_id"]))


def settle_fleet_quota(cur, *, authorization, order_id, amount, at):
    cur.execute("SELECT * FROM fleet_quota_reservation WHERE order_id=%s FOR UPDATE", (order_id,))
    reservation = cur.fetchone()
    if not reservation or reservation["status"] not in ("reserved", "review_required"):
        raise FleetQuotaError("车队额度预占不存在")
    source_id = reservation["quota_month_id"]
    cur.execute("SELECT * FROM fleet_quota_month WHERE quota_month_id=%s FOR UPDATE", (source_id,))
    source = cur.fetchone()
    target = quota_row(cur, authorization, bill_month(at))
    if source_id == target["quota_month_id"]:
        available = target["limit_amount"] - target["used_amount"] - target["reserved_amount"] + reservation["reserved_amount"]
    else:
        available = target["limit_amount"] - target["used_amount"] - target["reserved_amount"]
    if amount > available:
        cur.execute("UPDATE fleet_quota_reservation SET status='review_required',actual_amount=%s WHERE reservation_id=%s",
                    (amount, reservation["reservation_id"]))
        return False
    cur.execute("UPDATE fleet_quota_month SET reserved_amount=reserved_amount-%s WHERE quota_month_id=%s",
                (reservation["reserved_amount"], source_id))
    cur.execute("UPDATE fleet_quota_month SET used_amount=used_amount+%s WHERE quota_month_id=%s",
                (amount, target["quota_month_id"]))
    if source_id != target["quota_month_id"]:
        cur.execute("INSERT INTO fleet_quota_adjustment(quota_month_id,order_id,change_type,amount,business_key,reason) "
                    "VALUES (%s,%s,'month_transfer',%s,%s,%s)",
                    (target["quota_month_id"], order_id, amount, f"month-transfer:{order_id}", "按结束月份结算额度"))
    cur.execute("UPDATE fleet_quota_reservation SET quota_month_id=%s,status='settled',actual_amount=%s,settled_at=%s "
                "WHERE reservation_id=%s", (target["quota_month_id"], amount, at, reservation["reservation_id"]))
    return True


def refund_fleet_quota(cur, *, order_id, refund_id, amount):
    cur.execute("SELECT r.quota_month_id FROM fleet_quota_reservation r WHERE r.order_id=%s AND r.status='settled' FOR UPDATE",
                (order_id,))
    row = cur.fetchone()
    if not row:
        raise FleetQuotaError("车队额度尚未结算")
    cur.execute("UPDATE fleet_quota_month SET used_amount=used_amount-%s WHERE quota_month_id=%s AND used_amount>=%s",
                (amount, row["quota_month_id"], amount))
    if cur.rowcount != 1:
        raise FleetQuotaError("车队额度退款超过已使用额")
    cur.execute("INSERT INTO fleet_quota_adjustment(quota_month_id,order_id,refund_id,change_type,amount,business_key,reason) "
                "VALUES (%s,%s,%s,'refund',%s,%s,%s)",
                (row["quota_month_id"], order_id, refund_id, -amount, f"refund:{refund_id}", "车队退款退回授权额度"))
