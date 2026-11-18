-- Membership reporting views. Sensitive phone/plate fields are deliberately omitted.

CREATE OR REPLACE VIEW v_membership_user_overview AS
SELECT
    u.user_id,
    u.display_name,
    u.real_name_status,
    u.member_level,
    u.status AS user_status,
    u.registered_at,
    COUNT(DISTINCT CASE WHEN vb.unbound_at IS NULL THEN vb.vehicle_id END) AS active_vehicle_count
FROM app_user AS u
LEFT JOIN vehicle_binding AS vb ON vb.user_id = u.user_id
GROUP BY
    u.user_id, u.display_name, u.real_name_status, u.member_level, u.status, u.registered_at;

CREATE OR REPLACE VIEW v_membership_coupon_summary AS
SELECT
    p.promotion_id,
    p.promotion_name,
    p.status AS promotion_status,
    p.issue_limit,
    p.issued_count,
    COALESCE(coupon_stats.available_count, 0) AS available_count,
    COALESCE(coupon_stats.locked_count, 0) AS locked_count,
    COALESCE(coupon_stats.redeemed_count, 0) AS redeemed_count,
    COALESCE(coupon_stats.expired_count, 0) AS expired_count,
    COALESCE(usage_stats.total_discount_amount, 0.00) AS total_discount_amount
FROM promotion AS p
LEFT JOIN (
    SELECT
        promotion_id,
        SUM(status = 'available') AS available_count,
        SUM(status = 'locked') AS locked_count,
        SUM(status = 'redeemed') AS redeemed_count,
        SUM(status = 'expired') AS expired_count
    FROM user_coupon
    GROUP BY promotion_id
) AS coupon_stats ON coupon_stats.promotion_id = p.promotion_id
LEFT JOIN (
    SELECT uc.promotion_id, SUM(cu.discount_amount) AS total_discount_amount
    FROM user_coupon AS uc
    JOIN coupon_usage AS cu ON cu.coupon_id = uc.coupon_id
    WHERE cu.status = 'redeemed'
    GROUP BY uc.promotion_id
) AS usage_stats ON usage_stats.promotion_id = p.promotion_id;

CREATE OR REPLACE VIEW v_membership_fleet_quota_summary AS
SELECT
    f.fleet_id,
    f.company_name,
    fa.authorization_id,
    fa.user_id,
    fa.vehicle_id,
    fa.status AS authorization_status,
    qm.bill_month,
    qm.limit_amount,
    qm.reserved_amount,
    qm.used_amount,
    qm.limit_amount - qm.reserved_amount - qm.used_amount AS remaining_amount
FROM fleet AS f
JOIN fleet_card AS fc ON fc.fleet_id = f.fleet_id
JOIN fleet_authorization AS fa ON fa.card_id = fc.card_id
LEFT JOIN fleet_quota_month AS qm ON qm.authorization_id = fa.authorization_id;
