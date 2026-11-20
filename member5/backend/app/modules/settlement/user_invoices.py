from decimal import Decimal
from uuid import uuid4

from ...core.database import all_rows, execute, one
from ...core.errors import require
from .catalog import page
from .audit import record


def access(actor, user_id=None, *, staff=False):
    roles = set(actor["roles"])
    if "customer_service" in roles:
        return None
    uid = actor.get("user_id")
    require(not staff and "vehicle_owner" in roles and uid is not None and
            (user_id is None or user_id == uid), 403, "OUT_OF_SCOPE", "只能访问自己的消费发票。")
    return uid


def invoice_row(db, uid, lock=False):
    row = one(db, "SELECT * FROM user_invoice WHERE user_invoice_id=:id" +
              (" FOR UPDATE" if lock else ""), id=uid)
    require(row, 404, "USER_INVOICE_NOT_FOUND", "消费发票不存在。")
    return row


def list_user_invoices(db, *, actor, query):
    uid = access(actor, query.user_id)
    return page(db, query, "user_invoice v", "user_invoice_id", ("user_id", "status"),
                ("v.invoice_no", "v.title"), "requested_at",
                ("v.user_id=:actor_user", {"actor_user": uid}) if uid is not None else None)


def get_user_invoice(db, *, actor, user_invoice_id):
    row = invoice_row(db, user_invoice_id)
    access(actor, row["user_id"])
    return row


def order_balances(db, order_id):
    paid = one(db, """SELECT COALESCE(SUM(amount),0) AS amount FROM payment_record
        WHERE order_id=:id AND status='succeeded' FOR UPDATE""", id=order_id)["amount"]
    refunded = one(db, """SELECT COALESCE(SUM(r.amount),0) AS amount FROM refund_record r
        JOIN payment_record p USING(payment_id) WHERE p.order_id=:id
        AND p.status='succeeded' AND r.status='succeeded' FOR UPDATE""", id=order_id)["amount"]
    return paid - refunded


def lock_orders(db, ids):
    guns = []
    for oid in ids:
        row = one(db, "SELECT gun_id FROM charging_order WHERE order_id=:id", id=oid)
        require(row, 404, "ORDER_NOT_FOUND", "订单不存在。")
        guns.append((row["gun_id"], oid))
    for gun in sorted({x[0] for x in guns}):
        one(db, "SELECT gun_id FROM charging_gun WHERE gun_id=:id FOR UPDATE", id=gun)
    return {oid: one(db, "SELECT * FROM charging_order WHERE order_id=:id FOR UPDATE", id=oid)
            for _, oid in sorted(guns)}


def allocated(db, order_id):
    return one(db, """SELECT COALESCE(SUM(IF(i.invoice_type='blue',a.allocated_amount,
        -a.allocated_amount)),0) AS n FROM user_invoice_item a JOIN user_invoice i USING(user_invoice_id)
        WHERE a.order_id=:id AND a.status IN ('reserved','effective') FOR UPDATE""", id=order_id)["n"]


def assert_order_invoice_refundable(db, *, order_id: int, refund_amount: Decimal) -> None:
    # Billing calls this after locking the gun and order, before writing a refund.
    balance = order_balances(db, order_id)
    require(0 < refund_amount <= balance, 409, "REFUND_EXCEEDS_PAYMENT", "退款超过可退余额。")
    require(allocated(db, order_id) <= balance-refund_amount, 409,
            "USER_INVOICE_RED_ISSUE_REQUIRED", "退款会使订单开票超额，请先红冲或拒绝待办理发票。")


def request_user_invoice(db, *, actor, request):
    uid = actor.get("user_id")
    require(uid and "vehicle_owner" in actor["roles"], 403, "FORBIDDEN", "仅车主可申请本人发票。")
    items = {i.order_id: i.allocated_amount for i in request.items}
    require(len(items) == len(request.items), 422, "DUPLICATE_ORDER", "每笔订单只能填写一次。")
    for oid, order in lock_orders(db, items).items():
        require(order["user_id"] == uid, 403, "OUT_OF_SCOPE", "只能为本人订单申请。")
        require(order["order_mode"] == "personal" and order["status"] == "paid"
                and not order["review_required"], 409, "ORDER_NOT_INVOICEABLE", "订单不可开消费发票。")
        require(allocated(db, oid) + items[oid] <= order_balances(db, oid),
                409, "USER_INVOICE_EXCEEDS_PAYMENT", "订单剩余可开金额不足。")
    result = execute(db, """INSERT INTO user_invoice(user_id,title,tax_no,amount,requested_at)
        VALUES(:uid,:title,:tax,:amount,UTC_TIMESTAMP(3))""",
        uid=uid, title=request.title, tax=request.tax_no, amount=sum(items.values()))
    for oid, amount in items.items():
        execute(db, """INSERT INTO user_invoice_item(user_invoice_id,order_id,allocated_amount)
            VALUES(:id,:order,:amount)""", id=result.lastrowid, order=oid, amount=amount)
    return invoice_row(db, result.lastrowid)


def invoice_items(db, invoice_id):
    return all_rows(db, """SELECT order_id,allocated_amount FROM user_invoice_item
        WHERE user_invoice_id=:id ORDER BY order_id""", id=invoice_id)


def process_user_invoice(db, *, actor, user_invoice_id, request):
    access(actor, staff=True)
    items = invoice_items(db, user_invoice_id)
    lock_orders(db, [i["order_id"] for i in items])
    row = invoice_row(db, user_invoice_id, lock=True)
    require(row["status"] == "requested", 409, "INVALID_STATUS", "该申请已办理。")
    issue = request.decision == "issued"
    if issue:
        for item in items:
            oid = item["order_id"]
            require(allocated(db, oid) <= order_balances(db, oid), 409,
                    "USER_INVOICE_EXCEEDS_PAYMENT", "支付净额已变化，请核对后办理。")
    execute(db, """UPDATE user_invoice SET status=:status,invoice_no=:number,handled_by=:actor,
        issued_at=IF(:issue,UTC_TIMESTAMP(3),NULL) WHERE user_invoice_id=:id""",
        id=user_invoice_id, status=request.decision, issue=issue,
        number="USER-BLUE-"+uuid4().hex if issue else None, actor=actor["account_id"])
    execute(db, "UPDATE user_invoice_item SET status=:status WHERE user_invoice_id=:id",
            status="effective" if issue else "released", id=user_invoice_id)
    record(db, actor, "user_invoice", user_invoice_id, "process",
           before={"status": row["status"]}, after={"status": request.decision}, note=request.note)
    return invoice_row(db, user_invoice_id)


def red_issue_user_invoice(db, *, actor, user_invoice_id, request):
    access(actor, staff=True)
    items = invoice_items(db, user_invoice_id)
    lock_orders(db, [i["order_id"] for i in items])
    row = invoice_row(db, user_invoice_id, lock=True)
    require(row["status"] == "issued" and row["invoice_type"] == "blue", 409,
            "RED_INVOICE_INVALID_ORIGINAL", "原票须为已开具的蓝票。")
    red = {x["order_id"]: x["amount"] for x in all_rows(db, """SELECT a.order_id,
        SUM(a.allocated_amount) AS amount FROM user_invoice i JOIN user_invoice_item a USING(user_invoice_id)
        WHERE i.original_user_invoice_id=:id AND i.status='red_issued'
        GROUP BY a.order_id FOR UPDATE""", id=user_invoice_id)}
    remaining = request.amount
    allocations = []
    for item in items:
        oid = item["order_id"]
        amount = min(remaining, item["allocated_amount"] - red.get(oid, 0))
        if amount > 0:
            allocations.append((oid, amount))
            remaining -= amount
    require(remaining == 0, 409, "RED_INVOICE_EXCEEDS_ORIGINAL", "超过原票剩余可冲额度。")
    result = execute(db, """INSERT INTO user_invoice(user_id,original_user_invoice_id,invoice_no,
        invoice_type,title,tax_no,amount,status,requested_at,issued_at,handled_by)
        VALUES(:uid,:original,:number,'red',:title,:tax,:amount,'red_issued',
        UTC_TIMESTAMP(3),UTC_TIMESTAMP(3),:actor)""", uid=row["user_id"], original=user_invoice_id,
        number="USER-RED-"+uuid4().hex, title=row["title"], tax=row["tax_no"], amount=request.amount,
        actor=actor["account_id"])
    for oid, amount in allocations:
        execute(db, """INSERT INTO user_invoice_item(user_invoice_id,order_id,allocated_amount,status)
            VALUES(:id,:order,:amount,'effective')""", id=result.lastrowid, order=oid, amount=amount)
    record(db, actor, "user_invoice", user_invoice_id, "red_issue",
           after={"red_invoice_id": result.lastrowid, "amount": request.amount}, note=request.reason)
    return invoice_row(db, result.lastrowid)
