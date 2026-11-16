from decimal import Decimal

from ...core.database import all_rows, execute, one
from ...core.errors import require
from ..billing.service import apply_fleet_bill_payment
from ..billing.queries import list_refunds_for_period
from .catalog import page, utc
from .user_invoices import lock_orders


def fleet_scope(actor, *, write=False, prices=False):
    roles = set(actor["roles"])
    if "customer_service" in roles or (prices and "platform_admin" in roles):
        return None
    require(not write and "fleet_admin" in roles, 403, "FORBIDDEN", "当前角色无权办理车队业务。")
    return ("EXISTS(SELECT 1 FROM sys_account_fleet f WHERE f.account_id=:account AND f.fleet_id=v.fleet_id)",
            {"account": actor["account_id"]})


def check_scope(db, actor, fleet_id, *, prices=False):
    if fleet_scope(actor, prices=prices):
        require(one(db, "SELECT 1 FROM sys_account_fleet WHERE fleet_id=:id AND account_id=:account",
                    id=fleet_id, account=actor["account_id"]), 403, "OUT_OF_SCOPE", "只能访问本车队。")


def lock_fleet(db, fid):
    require(one(db, "SELECT fleet_id FROM fleet WHERE fleet_id=:id FOR UPDATE", id=fid),
            404, "FLEET_NOT_FOUND", "车队不存在。")


def list_fleet_prices(db, *, actor, query):
    return page(db, query, "fleet_price v JOIN fleet f USING(fleet_id)", "price_id",
                ("fleet_id", "period_id"), ("v.price_id", "f.company_name"), "valid_from",
                fleet_scope(actor, prices=True))


def get_fleet_price(db, *, actor, price_id):
    row = one(db, "SELECT * FROM fleet_price WHERE price_id=:id", id=price_id)
    require(row, 404, "FLEET_PRICE_NOT_FOUND", "车队专价不存在。")
    check_scope(db, actor, row["fleet_id"], prices=True)
    return row


def create_fleet_price(db, *, actor, request):
    fleet_scope(actor, write=True, prices=True)
    args = request.model_dump()
    for name in ("valid_from", "valid_until"):
        args[name] = utc(args[name])
    require(args["valid_from"] < args["valid_until"], 422, "INVALID_PERIOD", "有效期不正确。")
    lock_fleet(db, request.fleet_id)
    require(one(db, "SELECT 1 FROM pricing_period WHERE period_id=:period_id", **args),
            422, "PRICING_PERIOD_NOT_FOUND", "计费时段不存在。")
    result = execute(db, """INSERT INTO fleet_price(fleet_id,period_id,electricity_rate,service_rate,
        valid_from,valid_until,status)
        VALUES(:fleet_id,:period_id,:electricity_rate,:service_rate,:valid_from,:valid_until,'draft')""", **args)
    return get_fleet_price(db, actor=actor, price_id=result.lastrowid)


def bill_row(db, bid, lock=False):
    row = one(db, "SELECT * FROM fleet_monthly_bill WHERE bill_id=:id" +
              (" FOR UPDATE" if lock else ""), id=bid)
    require(row, 404, "FLEET_BILL_NOT_FOUND", "车队月结单不存在。")
    return row


def add_items(db, row):
    row["items"] = all_rows(db, """SELECT * FROM fleet_monthly_bill_item
        WHERE bill_id=:id ORDER BY bill_item_id""", id=row["bill_id"])
    return row


def get_fleet_bill(db, *, actor, bill_id):
    row = bill_row(db, bill_id)
    check_scope(db, actor, row["fleet_id"])
    return add_items(db, row)


def list_fleet_bills(db, *, actor, query):
    result = page(db, query, "fleet_monthly_bill v JOIN fleet f USING(fleet_id)", "bill_id",
                  ("fleet_id", "bill_month", "status"), ("v.bill_id", "f.company_name"),
                  scope=fleet_scope(actor))
    result["items"] = [add_items(db, row) for row in result["items"]]
    return result


def generate_fleet_bill(db, *, actor, request):
    from .service import month_bounds
    fleet_scope(actor, write=True)
    start, end = month_bounds(request.bill_month)
    fid = request.fleet_id
    lock_fleet(db, fid)
    require(not one(db, "SELECT 1 FROM fleet_monthly_bill WHERE fleet_id=:fid AND bill_month=:month",
                    fid=fid, month=request.bill_month), 409, "FLEET_BILL_EXISTS", "该账期已有月结单。")
    orders = all_rows(db, """SELECT o.* FROM charging_order o WHERE fleet_id=:fid AND order_mode='fleet'
        AND status='awaiting_payment' AND review_required=0 AND finished_at>=:start AND finished_at<:end
        AND NOT EXISTS(SELECT 1 FROM fleet_monthly_bill_item i WHERE i.business_key=CONCAT('order:',o.order_id))
        ORDER BY o.order_id""", fid=fid, start=start, end=end)
    locked = lock_orders(db, [o["order_id"] for o in orders])
    orders = [locked[o["order_id"]] for o in orders]
    require(all(o["fleet_id"] == fid and o["order_mode"] == "fleet" and o["status"] == "awaiting_payment"
                and not o["review_required"] and o["finished_at"] and start <= o["finished_at"] < end
                for o in orders), 409, "FLEET_ORDER_CHANGED", "订单状态已变化，请刷新后重新生成账单。")
    lines = [dict(oid=o["order_id"], refund=None, kind="order", at=o["finished_at"],
                  original=o["finished_at"], amount=o["payable_amount"], source=None,
                  key=f"order:{o['order_id']}") for o in orders]
    for r in list_refunds_for_period(db, start_at=start.replace(year=1970, month=1, day=1),
                                    end_at=end, fleet_id=fid):
        original = one(db, """SELECT o.finished_at FROM charging_order o JOIN refund_record r
            ON r.refund_id=:rid WHERE o.order_id=:oid AND r.settlement_method='fleet_credit'
            AND NOT EXISTS(SELECT 1 FROM fleet_monthly_bill_item i WHERE i.refund_id=r.refund_id)""",
            rid=r["refund_id"], oid=r["order_id"])
        if original:
            lines.append(dict(oid=r["order_id"], refund=r["refund_id"], kind="refund", at=r["refunded_at"],
                              original=original["finished_at"], amount=-r["amount"], source=None,
                              key=f"refund:{r['refund_id']}"))
    # Transfer each negative balance once, retaining the original order references.
    for old in all_rows(db, """SELECT * FROM fleet_monthly_bill b WHERE fleet_id=:fid AND bill_month<:month
        AND payable_amount<0 AND status='issued' AND NOT EXISTS(SELECT 1 FROM fleet_monthly_bill_item i
        WHERE i.source_bill_id=b.bill_id) ORDER BY bill_month FOR UPDATE""", fid=fid, month=request.bill_month):
        remaining = -old["payable_amount"]
        for i in add_items(db, old)["items"]:
            amount = min(remaining, -i["amount"])
            if amount > 0:
                lines.append(dict(oid=i["order_id"], refund=None, kind="credit_carry", at=start,
                                  original=i["original_order_finished_at"], amount=-amount,
                                  source=old["bill_id"], key=f"carry:{i['bill_item_id']}"))
                remaining -= amount
        require(remaining == 0, 409, "INVALID_CREDIT_BALANCE", "原账单负余额与明细不一致。")
        execute(db, "UPDATE fleet_monthly_bill SET status='closed' WHERE bill_id=:id", id=old["bill_id"])
    require(lines, 409, "NO_FLEET_BILL_ITEMS", "该账期没有可归集的车队明细。")
    base = sum(i["amount"] for i in lines if i["kind"] == "order")
    due = sum(i["amount"] for i in lines)
    result = execute(db, """INSERT INTO fleet_monthly_bill
        (fleet_id,bill_month,order_amount,adjustment_amount,payable_amount,status)
        VALUES(:fid,:month,:base,:adjustment,:due,'issued')""", fid=fid, month=request.bill_month,
        base=base, adjustment=due-base, due=due)
    for i in lines:
        execute(db, """INSERT INTO fleet_monthly_bill_item(bill_id,order_id,refund_id,item_type,
            occurred_at,amount,original_order_finished_at,business_key,source_bill_id)
            VALUES(:id,:oid,:refund,:kind,:at,:amount,:original,:key,:source)""", id=result.lastrowid, **i)
    return add_items(db, bill_row(db, result.lastrowid))


def apply_fleet_refund_credit(db, *, refund_id: int):
    """Prefer the original unpaid bill when the refund is recorded by billing."""
    row = one(db, """SELECT r.refund_id,r.amount,r.refunded_at,o.order_id,o.finished_at,
        o.fleet_id,i.bill_id FROM refund_record r JOIN payment_record p USING(payment_id)
        JOIN charging_order o USING(order_id) LEFT JOIN fleet_monthly_bill_item i
        ON i.order_id=o.order_id AND i.item_type='order'
        WHERE r.refund_id=:id AND r.status='succeeded' AND r.settlement_method='fleet_credit'""", id=refund_id)
    if not row or not row["bill_id"]:
        return
    bill = bill_row(db, row["bill_id"], lock=True)
    if bill["status"] not in ("issued", "partially_paid"):
        return
    if bill["payable_amount"]-row["amount"] < bill["paid_amount"]:
        return
    if one(db, "SELECT 1 FROM fleet_monthly_bill_item WHERE business_key=:key",
           key=f"refund:{refund_id}"):
        return
    execute(db, """INSERT INTO fleet_monthly_bill_item(bill_id,order_id,refund_id,item_type,
        occurred_at,amount,original_order_finished_at,business_key)
        VALUES(:bill_id,:order_id,:refund_id,'refund',:refunded_at,-:amount,:finished_at,:key)""",
        **row, key=f"refund:{refund_id}")
    execute(db, """UPDATE fleet_monthly_bill SET adjustment_amount=adjustment_amount-:amount,
        payable_amount=payable_amount-:amount WHERE bill_id=:bill_id""", **row)


def record_fleet_bill_payment(db, *, actor, bill_id, request):
    fleet_scope(actor, write=True)
    bill = bill_row(db, bill_id)
    lock_fleet(db, bill["fleet_id"])
    bill = bill_row(db, bill_id, lock=True)
    args = dict(id=bill_id, number=request.external_trade_no, amount=request.amount, actor=actor["account_id"])
    old = one(db, "SELECT * FROM fleet_bill_payment WHERE external_trade_no=:number FOR UPDATE", **args)
    if old:
        require(old["bill_id"] == bill_id and old["amount"] == request.amount and old["status"] == "succeeded",
                409, "FLEET_PAYMENT_CONFLICT", "该流水号已用于其他收款。")
        return old
    require(bill["status"] in ("issued", "partially_paid") and
            request.amount <= bill["payable_amount"]-bill["paid_amount"]
            and (request.amount > 0 or (bill["payable_amount"] == bill["paid_amount"]
                 and bill["order_amount"] > 0 and bill["adjustment_amount"] < 0)), 409,
            "INVALID_FLEET_PAYMENT", "金额超过应收余额，或账单当前不可收款。")
    ids = [i["order_id"] for i in add_items(db, bill)["items"] if i["item_type"] == "order"]
    orders = lock_orders(db, ids)
    result = execute(db, """INSERT INTO fleet_bill_payment(bill_id,external_trade_no,amount,
        status,paid_at,recorded_by) VALUES(:id,:number,:amount,'succeeded',UTC_TIMESTAMP(3),:actor)""", **args)
    pid = result.lastrowid
    cash = request.amount
    credit = Decimal(0)
    if bill["paid_amount"] + cash == bill["payable_amount"]:
        credit = max(-bill["adjustment_amount"], Decimal(0))
    allocations = []
    for oid in ids:
        order = orders[oid]
        paid = one(db, """SELECT COALESCE(SUM(amount),0) AS n FROM payment_record
            WHERE order_id=:id AND status='succeeded' FOR UPDATE""", id=oid)["n"]
        remaining = max(order["payable_amount"]-paid, Decimal(0))
        cash_part = min(cash, remaining)
        credit_part = min(credit, remaining-cash_part)
        amount = cash_part + credit_part
        if not amount:
            continue
        allocations.append(dict(order_id=oid, amount=amount, credit_amount=credit_part))
        cash -= cash_part
        credit -= credit_part
    require(cash == 0 and credit == 0, 409, "FLEET_ALLOCATION_MISMATCH", "收款与订单待结清金额不一致。")
    apply_fleet_bill_payment(db, bill_payment_id=pid, allocations=allocations)
    total = bill["paid_amount"] + request.amount
    execute(db, "UPDATE fleet_monthly_bill SET paid_amount=:total,status=:status WHERE bill_id=:id",
            id=bill_id, total=total, status="paid" if total == bill["payable_amount"] else "partially_paid")
    return one(db, "SELECT * FROM fleet_bill_payment WHERE bill_payment_id=:id", id=pid)
