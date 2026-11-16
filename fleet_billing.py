"""Member 2 settlement bridge. Caller owns the MySQL transaction."""
from decimal import Decimal


class FleetBillingError(ValueError):
    pass


def apply_fleet_bill_payment(cur, bill_payment_id: int):
    """Allocate a confirmed fleet payment and one-time refund credits to bill orders."""
    cur.execute("SELECT p.*,b.fleet_id,b.status AS bill_status FROM fleet_bill_payment p JOIN fleet_monthly_bill b ON b.bill_id=p.bill_id WHERE p.bill_payment_id=%s FOR UPDATE",(bill_payment_id,))
    payment=cur.fetchone()
    if not payment or payment["status"]!="succeeded":
        raise FleetBillingError("车队收款不存在或未成功")
    bill_id=payment["bill_id"]
    cur.execute("SELECT * FROM fleet_monthly_bill WHERE bill_id=%s FOR UPDATE",(bill_id,))
    bill=cur.fetchone()
    if bill["status"] not in ("issued","partially_paid","paid"):
        raise FleetBillingError("账单尚未出具")
    cur.execute("SELECT COUNT(*) AS n FROM payment_record WHERE bill_payment_id=%s",(bill_payment_id,))
    if cur.fetchone()["n"]:
        return {"bill_payment_id":bill_payment_id,"already_applied":True}
    cur.execute("SELECT i.order_id,i.amount,i.item_type FROM fleet_monthly_bill_item i WHERE i.bill_id=%s ORDER BY i.bill_item_id FOR UPDATE",(bill_id,))
    items=cur.fetchall()
    orders=[]
    credit=Decimal("0.00")
    for item in items:
        if item["item_type"]=="order":
            cur.execute("SELECT order_id,payable_amount,status,review_required,fleet_id FROM charging_order WHERE order_id=%s FOR UPDATE",(item["order_id"],))
            order=cur.fetchone()
            if not order or order["fleet_id"]!=bill["fleet_id"] or order["review_required"]:
                raise FleetBillingError("账单包含不可收款的车队订单")
            orders.append(order)
        elif item["item_type"] in ("refund","credit_carry"):
            credit+=abs(item["amount"])
    cur.execute("SELECT COALESCE(SUM(p.fleet_credit_amount),0) AS used_credit FROM payment_record p JOIN fleet_bill_payment bp ON bp.bill_payment_id=p.bill_payment_id WHERE bp.bill_id=%s AND p.status='succeeded'",(bill_id,))
    credit-=cur.fetchone()["used_credit"]
    if credit<0:
        raise FleetBillingError("账单抵扣额已经超用")
    cash=payment["amount"]
    if cash<0:
        raise FleetBillingError("现金收款不可为负")
    allocations=[]
    for order in orders:
        cur.execute("SELECT COALESCE(SUM(amount),0) AS paid FROM payment_record WHERE order_id=%s AND status='succeeded'",(order["order_id"],))
        remaining=order["payable_amount"]-cur.fetchone()["paid"]
        if remaining<=0: continue
        credit_part=min(credit,remaining)
        credit-=credit_part
        cash_part=min(cash,remaining-credit_part)
        cash-=cash_part
        amount=credit_part+cash_part
        if amount:
            allocations.append((order["order_id"],amount,credit_part,remaining))
    if cash!=0:
        raise FleetBillingError("实收金额超过账单待付额")
    for order_id,amount,credit_part,remaining in allocations:
        cur.execute("INSERT INTO payment_record(order_id,channel,external_trade_no,amount,status,paid_at,bill_payment_id,fleet_credit_amount) VALUES (%s,'fleet_monthly',%s,%s,'succeeded',%s,%s,%s)",(order_id,f"fleet:{bill_payment_id}:{order_id}",amount,payment["paid_at"],bill_payment_id,credit_part))
        if amount==remaining:
            cur.execute("UPDATE charging_order SET status='paid' WHERE order_id=%s",(order_id,))
    cur.execute("UPDATE fleet_monthly_bill SET paid_amount=paid_amount+%s,status=CASE WHEN paid_amount+%s>=payable_amount THEN 'paid' ELSE 'partially_paid' END WHERE bill_id=%s",(payment["amount"],payment["amount"],bill_id))
    return {"bill_payment_id":bill_payment_id,"allocations":len(allocations),"cash_amount":str(payment["amount"])}
