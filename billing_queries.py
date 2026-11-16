"""Read-only billing facts for settlement and reconciliation.

The caller owns the MySQL transaction and passes its PyMySQL dictionary cursor.
Both intervals are left-closed and right-open in UTC.
"""


def list_billable_orders(cur, *, start_at, end_at, station_id=None, fleet_id=None):
    if end_at <= start_at:
        raise ValueError("账期结束时间必须晚于开始时间")
    filters = ["o.finished_at >= %s", "o.finished_at < %s",
               "o.status IN ('awaiting_payment','paid')", "o.review_required = 0"]
    args = [start_at, end_at]
    if station_id is not None:
        filters.append("o.station_id = %s")
        args.append(station_id)
    if fleet_id is not None:
        filters.append("o.fleet_id = %s")
        args.append(fleet_id)
    cur.execute(
        "SELECT o.order_id,o.user_id,o.station_id,o.fleet_id,o.order_mode,"
        "o.finished_at,o.payable_amount,o.status FROM charging_order o WHERE "
        + " AND ".join(filters) + " ORDER BY o.finished_at,o.order_id", args)
    return cur.fetchall()


def list_refunds_for_period(cur, *, start_at, end_at, station_id=None, fleet_id=None):
    if end_at <= start_at:
        raise ValueError("账期结束时间必须晚于开始时间")
    filters = ["r.status = 'succeeded'", "r.refunded_at >= %s", "r.refunded_at < %s"]
    args = [start_at, end_at]
    if station_id is not None:
        filters.append("o.station_id = %s")
        args.append(station_id)
    if fleet_id is not None:
        filters.append("o.fleet_id = %s")
        args.append(fleet_id)
    cur.execute(
        "SELECT r.refund_id,r.payment_id,p.order_id,o.station_id,o.fleet_id,"
        "r.refunded_at,r.amount,r.settlement_method FROM refund_record r "
        "JOIN payment_record p ON p.payment_id=r.payment_id "
        "JOIN charging_order o ON o.order_id=p.order_id WHERE "
        + " AND ".join(filters) + " ORDER BY r.refunded_at,r.refund_id", args)
    return cur.fetchall()
