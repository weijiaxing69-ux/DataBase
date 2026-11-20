from datetime import datetime, time, timedelta, timezone
from decimal import Decimal, ROUND_HALF_UP
from uuid import uuid4

from ...core.database import all_rows, execute, one
from ...core.errors import require
from ..billing.queries import list_billable_orders
from . import dao
from .audit import record
from .catalog import (create_settlement_policy, get_operator_invoice, get_settlement_policy,
                      list_differences, list_operator_invoices, list_settlement_policies, list_settlements,
                      list_adjustments, get_adjustment, list_audit_events)
from .reconciliation import (add_confirmation, adjust_settlement, confirmation_side, confirm_difference,
                             create_difference, get_difference, insert_difference,
                             resolve_difference, review_settlement_adjustment)
from .fleet_bills import (apply_fleet_refund_credit, create_fleet_price, generate_fleet_bill, get_fleet_bill,
                          get_fleet_price, list_fleet_bills, list_fleet_prices, record_fleet_bill_payment)
from .user_invoices import (assert_order_invoice_refundable, get_user_invoice, list_user_invoices, process_user_invoice,
                            red_issue_user_invoice, request_user_invoice)

PLATFORM = "platform_admin"
CUSTOMER = "customer_service"
OPERATOR = "operator_manager"
SHANGHAI = timezone(timedelta(hours=8))


def scope(db, actor, operator_id=None, *, write=False):
    roles = set(actor["roles"])
    if roles & {PLATFORM, CUSTOMER}:
        return None
    require(OPERATOR in roles and not write, 403, "FORBIDDEN", "当前角色无权执行此操作。")
    allowed = {r["operator_id"] for r in all_rows(db,
        "SELECT operator_id FROM sys_account_operator WHERE account_id=:id", id=actor["account_id"])}
    require(operator_id is None or operator_id in allowed, 403, "OUT_OF_SCOPE", "该结算单不在你的运营商范围内。")
    return allowed


def get_settlement(db, *, actor, settlement_id):
    row = dao.settlement_detail(db, settlement_id)
    require(row is not None, 404, "SETTLEMENT_NOT_FOUND", "结算单不存在。")
    scope(db, actor, row["operator_id"])
    return row


def locked_settlement(db, settlement_id):
    row = one(db, "SELECT * FROM operator_settlement WHERE settlement_id=:id FOR UPDATE", id=settlement_id)
    require(row is not None, 404, "SETTLEMENT_NOT_FOUND", "结算单不存在。")
    return row


def confirm_settlement(db, *, actor, settlement_id, request):
    row = locked_settlement(db, settlement_id)
    side = confirmation_side(db, actor, row["operator_id"])
    require(row["version"] == request.object_version, 409, "STALE_VERSION", "结算单版本已变化，请刷新。")
    require(row["status"] in {"pending_confirmation", "confirmed"},
            409, "INVALID_STATUS", "当前状态不能确认。")
    detail, accepted = add_confirmation(db, actor, side, "settlement", settlement_id, request)
    execute(db, "UPDATE operator_settlement SET status=:status WHERE settlement_id=:id",
            id=settlement_id, status="confirmed" if accepted else "pending_confirmation")
    return detail


def issue_operator_invoice(db, *, actor, settlement_id, request):
    scope(db, actor, write=True)
    return dao.invoice_procedure(db, settlement_id, "BLUE-" + uuid4().hex, None,
                                 request.title, request.tax_no, request.amount, actor["account_id"])


def red_issue_operator_invoice(db, *, actor, invoice_id, request):
    scope(db, actor, write=True)
    original = one(db, "SELECT * FROM operator_invoice WHERE invoice_id=:id", id=invoice_id)
    require(original is not None, 404, "INVOICE_NOT_FOUND", "原票不存在。")
    result = dao.invoice_procedure(db, original["settlement_id"],
                                 "RED-" + uuid4().hex, invoice_id,
                                 original["title"], original["tax_no"], request.amount, actor["account_id"])
    record(db, actor, "operator_invoice", invoice_id, "red_issue",
           after={"red_invoice_id": result["invoice_id"], "amount": request.amount}, note=request.reason)
    return result


def cents(amount):
    return amount.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)


def month_bounds(month):
    require(month.day == 1, 422, "INVALID_BILL_MONTH", "账期必须是月份首日。")
    next_month = (month.replace(day=28) + timedelta(days=4)).replace(day=1)
    return tuple(datetime.combine(d, time(), SHANGHAI).astimezone(timezone.utc).replace(tzinfo=None)
                 for d in (month, next_month))


def net_parts(order):
    e, s, discount = (order[k] for k in ("electricity_amount", "service_amount", "discount_amount"))
    offset = cents(discount * e / (e + s)) if e + s else Decimal(0)
    return e - offset, s - (discount - offset)


def shares(e, s, policy):
    es = cents(e * policy["electricity_share_rate"])
    ss = cents(s * policy["service_share_rate"])
    fee = cents((e + s) * policy["platform_fee_rate"])
    return dict(net=e+s, es=es, ss=ss, fee=fee, due=es+ss-fee)


def generate_settlement(db, *, actor, request):
    scope(db, actor, write=True)
    month = request.bill_month
    start, end = month_bounds(month)
    station = one(db, "SELECT operator_id FROM station WHERE station_id=:id FOR UPDATE", id=request.station_id)
    require(station and station["operator_id"] == request.operator_id,
            422, "INVALID_STATION_OPERATOR", "场站和运营商不匹配。")
    args = dict(operator=request.operator_id, station=request.station_id, month=month)
    previous = one(db, """SELECT settlement_id FROM operator_settlement
        WHERE operator_id=:operator AND station_id=:station AND bill_month=:month""", **args)
    require(previous is None, 409, "SETTLEMENT_EXISTS", "该场站账期已有结算单。")
    from .user_invoices import lock_orders
    from ..billing.queries import list_refunds_for_period
    candidates = list_billable_orders(db, start_at=datetime(1970, 1, 1), end_at=end,
                                     station_id=request.station_id)
    refunds = list_refunds_for_period(db, start_at=start, end_at=end, station_id=request.station_id)
    orders = lock_orders(db, {o["order_id"] for o in candidates} | {r["order_id"] for r in refunds})
    items, unpaid, selected = [], [], {}
    for oid, order in orders.items():
        if (order["operator_id"] != request.operator_id or order["settlement_id"] is not None
                or order["review_required"] or order["status"] not in {"paid", "awaiting_payment"}):
            continue
        paid = one(db, """SELECT COALESCE(SUM(amount),0) AS n FROM payment_record
            WHERE order_id=:id AND status='succeeded' AND paid_at<:end FOR UPDATE""",
            id=oid, end=end)["n"]
        if order["status"] != "paid" or paid != order["payable_amount"]:
            if order["finished_at"] >= start:
                unpaid.append((oid, max(order["payable_amount"]-paid, Decimal(0))))
            continue
        policy = all_rows(db, """SELECT * FROM settlement_policy WHERE operator_id=:operator
            AND station_id=:station AND valid_from<=:at AND valid_until>:at""",
            operator=request.operator_id, station=request.station_id, at=order["finished_at"])
        require(len(policy) == 1, 409, "INVALID_SETTLEMENT_POLICY", "每笔订单必须匹配一条分成政策。")
        p = policy[0]
        selected[oid] = p
        items.append(dict(order=oid, refund=None, kind="order", at=order["finished_at"], policy=p["policy_id"],
                          key=f"order:{oid}", **shares(*net_parts(order), p)))
    for oid in sorted(set(selected) | {r["order_id"] for r in refunds}):
        order = orders[oid]
        if order["operator_id"] != request.operator_id:
            continue
        p = selected.get(oid) or one(db, """SELECT p.* FROM settlement_item i
            JOIN settlement_policy p USING(policy_id) WHERE i.order_id=:id AND i.item_type='order'""", id=oid)
        if not p:
            continue
        # Calculate cumulative rounded amounts so splitting a refund cannot change the final cents.
        e, s = net_parts(order)
        cumulative = Decimal(0)
        for r in all_rows(db, """SELECT r.refund_id,r.amount,r.refunded_at,
            EXISTS(SELECT 1 FROM settlement_item i WHERE i.refund_id=r.refund_id) AS booked
            FROM refund_record r JOIN payment_record p USING(payment_id)
            WHERE p.order_id=:id AND p.status='succeeded' AND r.status='succeeded' AND r.refunded_at<:end
            ORDER BY r.refunded_at,r.refund_id""", id=oid, end=end):
            def remaining(amount):
                net = e+s
                reduction = min(amount, net)
                electric = cents(reduction*e/net) if net else Decimal(0)
                return shares(e-electric, s-(reduction-electric), p)
            before = remaining(cumulative)
            cumulative += r["amount"]
            if r["booked"]:
                continue
            after = remaining(cumulative)
            items.append(dict(order=oid, refund=r["refund_id"], kind="refund", at=r["refunded_at"],
                              policy=p["policy_id"], key=f"refund:{r['refund_id']}",
                              **{k: after[k]-before[k] for k in before}))
    require(items or unpaid, 409, "NO_BILLABLE_ORDERS", "该账期没有待归集订单或对账待办。")
    totals = {key: sum(item[key] for item in items) for key in ("es", "ss", "fee", "due")}
    require(totals["due"] >= 0 or any(i["kind"] == "refund" for i in items),
            409, "NEGATIVE_SETTLEMENT", "当前政策算出的应结金额为负。")
    result = execute(db, """INSERT INTO operator_settlement
        (operator_id,station_id,bill_month,energy_kwh,electricity_share_amount,
         service_share_amount,platform_fee_amount,payable_amount,status)
        VALUES(:operator,:station,:month,:energy,:es,:ss,:fee,:due,'pending_confirmation')""",
        **args, **totals, energy=sum(orders[oid]["energy_kwh"] for oid in selected))
    settlement_id = result.lastrowid
    for item in items:
        if item["kind"] == "order":
            linked = execute(db, """UPDATE charging_order SET settlement_id=:id
                WHERE order_id=:order AND settlement_id IS NULL AND status='paid' AND review_required=0""",
                id=settlement_id, order=item["order"])
            require(linked.rowcount == 1, 409, "ORDER_ALREADY_SETTLED", "订单状态已变化或已归集。")
        execute(db, """INSERT INTO settlement_item(settlement_id,order_id,refund_id,policy_id,item_type,
            occurred_at,net_amount,electricity_share_amount,service_share_amount,platform_fee_amount,
            payable_amount,business_key) VALUES(:id,:order,:refund,:policy,:kind,:at,:net,:es,:ss,:fee,:due,:key)""",
            id=settlement_id, **item)
    for oid, amount in unpaid:
        insert_difference(db, settlement_id, oid, "payment", amount)
    if unpaid:
        execute(db, """INSERT INTO notification(account_id,notification_type,business_key,title,content,target_path)
            SELECT DISTINCT a.account_id,'settlement_payment_pending',:key,'结算存在待核对订单',
                :content,'/settlement/differences'
            FROM sys_account a JOIN sys_account_role ar USING(account_id) JOIN sys_role r USING(role_id)
            WHERE a.status='active' AND r.role_code='customer_service'""",
            key=f"settlement:unpaid:{settlement_id}",
            content=f"结算单 #{settlement_id} 有 {len(unpaid)} 笔未付清订单，请查看对账差异。")
    return get_settlement(db, actor=actor, settlement_id=settlement_id)
