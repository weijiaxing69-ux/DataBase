-- Query 1A: vehicles and currently available coupons per user (aggregate subqueries avoid fan-out).
SELECT u.user_id, u.display_name, u.member_level,
       COALESCE(v.vehicle_count, 0) AS active_vehicle_count,
       COALESCE(c.available_count, 0) AS available_coupon_count
FROM app_user AS u
LEFT JOIN (
    SELECT user_id, COUNT(*) AS vehicle_count
    FROM vehicle_binding
    WHERE unbound_at IS NULL
    GROUP BY user_id
) AS v ON v.user_id = u.user_id
LEFT JOIN (
    SELECT user_id, COUNT(*) AS available_count
    FROM user_coupon
    WHERE status = 'available'
    GROUP BY user_id
) AS c ON c.user_id = u.user_id
WHERE u.status = 'active'
ORDER BY u.user_id;

-- Query 1B: equivalent CTE form.
WITH active_vehicles AS (
    SELECT user_id, COUNT(*) AS vehicle_count
    FROM vehicle_binding WHERE unbound_at IS NULL GROUP BY user_id
), available_coupons AS (
    SELECT user_id, COUNT(*) AS available_count
    FROM user_coupon WHERE status = 'available' GROUP BY user_id
)
SELECT u.user_id, u.display_name, u.member_level,
       COALESCE(v.vehicle_count, 0) AS active_vehicle_count,
       COALESCE(c.available_count, 0) AS available_coupon_count
FROM app_user AS u
LEFT JOIN active_vehicles AS v ON v.user_id = u.user_id
LEFT JOIN available_coupons AS c ON c.user_id = u.user_id
WHERE u.status = 'active'
ORDER BY u.user_id;

-- Query 2A: promotion issue and redemption summary.
SELECT p.promotion_id, p.promotion_name, p.issue_limit, p.issued_count,
       COUNT(DISTINCT uc.coupon_id) AS coupon_rows,
       COUNT(DISTINCT CASE WHEN cu.status = 'redeemed' THEN cu.usage_id END) AS redeemed_count,
       COALESCE(SUM(CASE WHEN cu.status = 'redeemed' THEN cu.discount_amount ELSE 0 END), 0.00) AS redeemed_amount
FROM promotion AS p
LEFT JOIN user_coupon AS uc ON uc.promotion_id = p.promotion_id
LEFT JOIN coupon_usage AS cu ON cu.coupon_id = uc.coupon_id
GROUP BY p.promotion_id, p.promotion_name, p.issue_limit, p.issued_count
ORDER BY p.promotion_id;

-- Query 2B: equivalent pre-aggregated CTE form.
WITH coupon_counts AS (
    SELECT promotion_id, COUNT(*) AS coupon_rows
    FROM user_coupon GROUP BY promotion_id
), redemption AS (
    SELECT uc.promotion_id,
           SUM(cu.status = 'redeemed') AS redeemed_count,
           SUM(CASE WHEN cu.status = 'redeemed' THEN cu.discount_amount ELSE 0 END) AS redeemed_amount
    FROM user_coupon AS uc
    JOIN coupon_usage AS cu ON cu.coupon_id = uc.coupon_id
    GROUP BY uc.promotion_id
)
SELECT p.promotion_id, p.promotion_name, p.issue_limit, p.issued_count,
       COALESCE(cc.coupon_rows, 0) AS coupon_rows,
       COALESCE(r.redeemed_count, 0) AS redeemed_count,
       COALESCE(r.redeemed_amount, 0.00) AS redeemed_amount
FROM promotion AS p
LEFT JOIN coupon_counts AS cc ON cc.promotion_id = p.promotion_id
LEFT JOIN redemption AS r ON r.promotion_id = p.promotion_id
ORDER BY p.promotion_id;

-- Query 3A: fleet authorization quota by billing month.
SELECT f.fleet_id, f.company_name, fa.authorization_id, fa.user_id, fa.vehicle_id,
       qm.bill_month, qm.limit_amount, qm.reserved_amount, qm.used_amount,
       qm.limit_amount - qm.reserved_amount - qm.used_amount AS remaining_amount
FROM fleet AS f
JOIN fleet_card AS fc ON fc.fleet_id = f.fleet_id
JOIN fleet_authorization AS fa ON fa.card_id = fc.card_id
JOIN fleet_quota_month AS qm ON qm.authorization_id = fa.authorization_id
ORDER BY f.fleet_id, fa.authorization_id, qm.bill_month;

-- Query 3B: equivalent CTE form.
WITH authorization_quota AS (
    SELECT fa.authorization_id, fa.card_id, fa.user_id, fa.vehicle_id,
           qm.bill_month, qm.limit_amount, qm.reserved_amount, qm.used_amount
    FROM fleet_authorization AS fa
    JOIN fleet_quota_month AS qm ON qm.authorization_id = fa.authorization_id
)
SELECT f.fleet_id, f.company_name, aq.authorization_id, aq.user_id, aq.vehicle_id,
       aq.bill_month, aq.limit_amount, aq.reserved_amount, aq.used_amount,
       aq.limit_amount - aq.reserved_amount - aq.used_amount AS remaining_amount
FROM fleet AS f
JOIN fleet_card AS fc ON fc.fleet_id = f.fleet_id
JOIN authorization_quota AS aq ON aq.card_id = fc.card_id
ORDER BY f.fleet_id, aq.authorization_id, aq.bill_month;

-- Run EXPLAIN ANALYZE on each pair on MySQL 8.0.18+ with representative data.
