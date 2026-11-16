from ...core.database import execute, one
from ...core.errors import require


def apply_fleet_bill_payment(db, *, bill_payment_id: int, allocations: list):
    """Apply already locked order allocations in the caller's billing transaction."""
    result = []
    for item in allocations:
        item = item.model_dump() if hasattr(item, "model_dump") else item
        oid, amount, credit = item["order_id"], item["amount"], item.get("credit_amount", 0)
        order = one(db, "SELECT * FROM charging_order WHERE order_id=:id FOR UPDATE", id=oid)
        require(order and order["order_mode"] == "fleet" and order["status"] in {"awaiting_payment", "paid"}
                and not order["review_required"], 409, "ORDER_NOT_PAYABLE", "车队订单当前不可结清。")
        paid = one(db, """SELECT COALESCE(SUM(amount),0) AS n FROM payment_record
            WHERE order_id=:id AND status='succeeded' FOR UPDATE""", id=oid)["n"]
        require(0 < amount <= order["payable_amount"]-paid and 0 <= credit <= amount,
                409, "INVALID_FLEET_ALLOCATION", "订单分配金额不正确。")
        created = execute(db, """INSERT INTO payment_record(order_id,channel,external_trade_no,
            amount,status,paid_at,bill_payment_id,fleet_credit_amount)
            VALUES(:oid,'fleet_monthly',:number,:amount,'succeeded',UTC_TIMESTAMP(3),:pid,:credit)""",
            oid=oid, number=f"fleet:{bill_payment_id}:{oid}", amount=amount,
            pid=bill_payment_id, credit=credit)
        if paid+amount == order["payable_amount"]:
            execute(db, "UPDATE charging_order SET status='paid' WHERE order_id=:id", id=oid)
        result.append(one(db, "SELECT * FROM payment_record WHERE payment_id=:id", id=created.lastrowid))
    return result
