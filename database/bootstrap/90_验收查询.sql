USE charging_platform_test;
-- 该查询验证历史样例金额及引用，端到端用例另由应用执行。
SELECT COUNT(*) AS table_count FROM information_schema.tables
 WHERE table_schema=DATABASE() AND table_type='BASE TABLE';
SELECT 'history_order_payment_mismatch' AS check_name, COUNT(*) AS violations
FROM charging_order o LEFT JOIN (SELECT order_id,SUM(amount) AS paid FROM payment_record WHERE status='succeeded' GROUP BY order_id) p USING(order_id)
WHERE o.status='paid' AND o.payable_amount<>COALESCE(p.paid,0)
UNION ALL
SELECT 'history_order_billing_mismatch', COUNT(*) FROM charging_order o
 LEFT JOIN (SELECT order_id,SUM(energy_kwh) kwh,SUM(electricity_amount) e,SUM(service_amount) s FROM billing_detail GROUP BY order_id) b USING(order_id)
 WHERE o.energy_kwh<>COALESCE(b.kwh,-1) OR o.electricity_amount<>COALESCE(b.e,-1)
 OR o.service_amount<>COALESCE(b.s,-1) OR o.payable_amount<>o.electricity_amount+o.service_amount+o.minimum_topup_amount-o.discount_amount
UNION ALL
SELECT 'history_settlement_amount_mismatch',COUNT(*) FROM operator_settlement s
 LEFT JOIN (SELECT settlement_id,SUM(payable_amount) AS due FROM settlement_item GROUP BY settlement_id) i USING(settlement_id)
 WHERE s.payable_amount<>COALESCE(i.due,0)+s.adjustment_amount
UNION ALL
SELECT 'history_fleet_payment_mismatch',COUNT(*) FROM fleet_monthly_bill b
 LEFT JOIN (SELECT bill_id,SUM(amount) AS paid FROM fleet_bill_payment WHERE status='succeeded' GROUP BY bill_id) p USING(bill_id)
 WHERE b.paid_amount<>COALESCE(p.paid,0);
SELECT coupon_id,user_id,status FROM user_coupon WHERE coupon_id=21;
SELECT 'L01 expected' AS scenario, ROUND(6*p.electricity_rate,2)+ROUND(4*v.electricity_rate,2) AS electric,
 ROUND(6*p.service_rate,2)+ROUND(4*v.service_rate,2) AS service_fee,
 ROUND(6*p.electricity_rate,2)+ROUND(4*v.electricity_rate,2)+ROUND(6*p.service_rate,2)+ROUND(4*v.service_rate,2)-c.face_amount_snapshot AS payable
FROM pricing_period p JOIN pricing_period v ON v.rule_id=p.rule_id
JOIN user_coupon c ON c.coupon_id=21
WHERE p.period_id=13 AND v.period_id=14;
SELECT 'L02 expected' AS scenario, ROUND(8*electricity_rate,2)+ROUND(8*service_rate,2) AS payable FROM fleet_price WHERE price_id=1;

SELECT (SELECT COUNT(*) FROM `operator`) + (SELECT COUNT(*) FROM `station`) + (SELECT COUNT(*) FROM `charging_pile`) + (SELECT COUNT(*) FROM `charging_gun`) + (SELECT COUNT(*) FROM `device_status_log`) + (SELECT COUNT(*) FROM `equipment_change_request`) + (SELECT COUNT(*) FROM `device_acceptance`) + (SELECT COUNT(*) FROM `device_command`) + (SELECT COUNT(*) FROM `pricing_rule`) + (SELECT COUNT(*) FROM `pricing_period`) + (SELECT COUNT(*) FROM `charging_order`) + (SELECT COUNT(*) FROM `meter_reading`) + (SELECT COUNT(*) FROM `billing_detail`) + (SELECT COUNT(*) FROM `payment_record`) + (SELECT COUNT(*) FROM `refund_record`) + (SELECT COUNT(*) FROM `order_review`) + (SELECT COUNT(*) FROM `device_reading`) + (SELECT COUNT(*) FROM `alarm_rule`) + (SELECT COUNT(*) FROM `device_alert`) + (SELECT COUNT(*) FROM `work_order`) + (SELECT COUNT(*) FROM `work_order_event`) + (SELECT COUNT(*) FROM `fault_report`) + (SELECT COUNT(*) FROM `inspection_record`) + (SELECT COUNT(*) FROM `sys_account`) + (SELECT COUNT(*) FROM `app_user`) + (SELECT COUNT(*) FROM `vehicle`) + (SELECT COUNT(*) FROM `vehicle_binding`) + (SELECT COUNT(*) FROM `promotion`) + (SELECT COUNT(*) FROM `user_coupon`) + (SELECT COUNT(*) FROM `coupon_usage`) + (SELECT COUNT(*) FROM `fleet`) + (SELECT COUNT(*) FROM `fleet_card`) + (SELECT COUNT(*) FROM `fleet_authorization`) + (SELECT COUNT(*) FROM `fleet_quota_month`) + (SELECT COUNT(*) FROM `fleet_quota_reservation`) + (SELECT COUNT(*) FROM `sys_role`) + (SELECT COUNT(*) FROM `sys_permission`) + (SELECT COUNT(*) FROM `sys_account_role`) + (SELECT COUNT(*) FROM `sys_role_permission`) + (SELECT COUNT(*) FROM `sys_account_operator`) + (SELECT COUNT(*) FROM `sys_account_station`) + (SELECT COUNT(*) FROM `sys_account_fleet`) + (SELECT COUNT(*) FROM `promotion_station`) + (SELECT COUNT(*) FROM `sys_session`) + (SELECT COUNT(*) FROM `wallet_transaction`) + (SELECT COUNT(*) FROM `fleet_quota_adjustment`) + (SELECT COUNT(*) FROM `service_feedback`) + (SELECT COUNT(*) FROM `settlement_policy`) + (SELECT COUNT(*) FROM `operator_settlement`) + (SELECT COUNT(*) FROM `settlement_item`) + (SELECT COUNT(*) FROM `reconciliation_difference`) + (SELECT COUNT(*) FROM `reconciliation_confirmation`) + (SELECT COUNT(*) FROM `settlement_adjustment`) + (SELECT COUNT(*) FROM `operator_invoice`) + (SELECT COUNT(*) FROM `user_invoice`) + (SELECT COUNT(*) FROM `user_invoice_item`) + (SELECT COUNT(*) FROM `fleet_monthly_bill`) + (SELECT COUNT(*) FROM `fleet_monthly_bill_item`) + (SELECT COUNT(*) FROM `fleet_price`) + (SELECT COUNT(*) FROM `fleet_bill_payment`) + (SELECT COUNT(*) FROM `request_dedup`) + (SELECT COUNT(*) FROM `notification`) + (SELECT COUNT(*) FROM `outbox_event`) + (SELECT COUNT(*) FROM `device_credential`) + (SELECT COUNT(*) FROM `pricing_review`) AS total_rows;
