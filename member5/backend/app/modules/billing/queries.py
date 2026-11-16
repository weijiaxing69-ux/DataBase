"""Local implementation of the V1.4 read contract for settlement."""

from datetime import datetime

from ...core.database import all_rows


def list_billable_orders(db, *, start_at: datetime, end_at: datetime,
                         station_id: int | None = None, fleet_id: int | None = None):
    return all_rows(db, """
        SELECT o.order_id, o.user_id, o.station_id, o.operator_id, o.rule_id, o.fleet_id,
               o.finished_at, o.energy_kwh, o.electricity_amount, o.service_amount,
               o.discount_amount, o.minimum_topup_amount, o.payable_amount,
               COALESCE(p.paid, 0) AS paid_amount, COALESCE(r.refunded, 0) AS refunded_amount,
               o.status AS order_status
        FROM charging_order o
        LEFT JOIN (SELECT order_id, SUM(amount) AS paid FROM payment_record
                   WHERE status='succeeded' GROUP BY order_id) p USING(order_id)
        LEFT JOIN (SELECT p.order_id, SUM(r.amount) AS refunded FROM refund_record r
                   JOIN payment_record p USING(payment_id) WHERE r.status='succeeded'
                   AND p.status='succeeded' GROUP BY p.order_id) r USING(order_id)
        WHERE o.finished_at >= :start AND o.finished_at < :end
          AND (:station IS NULL OR o.station_id=:station)
          AND (:fleet IS NULL OR o.fleet_id=:fleet)
          AND o.review_required=0 AND o.status IN ('paid','awaiting_payment')
        ORDER BY o.finished_at,o.order_id
    """, start=start_at, end=end_at, station=station_id, fleet=fleet_id)


def list_refunds_for_period(db, *, start_at: datetime, end_at: datetime,
                            station_id: int | None = None, fleet_id: int | None = None):
    return all_rows(db, """SELECT r.refund_id,r.payment_id,r.refunded_at,r.amount,o.order_id,
        o.station_id,o.fleet_id FROM refund_record r JOIN payment_record p USING(payment_id)
        JOIN charging_order o USING(order_id)
        WHERE r.status='succeeded' AND p.status='succeeded'
          AND r.refunded_at>=:start AND r.refunded_at<:end
          AND (:station IS NULL OR o.station_id=:station)
          AND (:fleet IS NULL OR o.fleet_id=:fleet)
        ORDER BY r.refunded_at,r.refund_id""", start=start_at, end=end_at,
        station=station_id, fleet=fleet_id)
