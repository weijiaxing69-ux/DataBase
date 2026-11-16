-- Run as the local administrator only when the existing development account
-- and V1.4 database use these exact names. This does not create an account.
GRANT SELECT ON charging_platform.charging_gun TO 'charging_settlement_dev'@'127.0.0.1';
GRANT SELECT, INSERT ON charging_platform.payment_record TO 'charging_settlement_dev'@'127.0.0.1';
GRANT SELECT, INSERT ON charging_platform.settlement_policy TO 'charging_settlement_dev'@'127.0.0.1';
GRANT SELECT, INSERT, UPDATE ON charging_platform.reconciliation_difference TO 'charging_settlement_dev'@'127.0.0.1';
GRANT SELECT, INSERT, UPDATE ON charging_platform.settlement_adjustment TO 'charging_settlement_dev'@'127.0.0.1';
GRANT SELECT, INSERT, UPDATE ON charging_platform.user_invoice TO 'charging_settlement_dev'@'127.0.0.1';
GRANT SELECT, INSERT, UPDATE ON charging_platform.user_invoice_item TO 'charging_settlement_dev'@'127.0.0.1';
GRANT SELECT (fleet_id, company_name) ON charging_platform.fleet TO 'charging_settlement_dev'@'127.0.0.1';
GRANT SELECT ON charging_platform.sys_account_fleet TO 'charging_settlement_dev'@'127.0.0.1';
GRANT SELECT ON charging_platform.pricing_period TO 'charging_settlement_dev'@'127.0.0.1';
GRANT SELECT, INSERT ON charging_platform.fleet_price TO 'charging_settlement_dev'@'127.0.0.1';
GRANT SELECT, INSERT, UPDATE ON charging_platform.fleet_monthly_bill TO 'charging_settlement_dev'@'127.0.0.1';
GRANT SELECT, INSERT ON charging_platform.fleet_monthly_bill_item TO 'charging_settlement_dev'@'127.0.0.1';
GRANT SELECT, INSERT ON charging_platform.fleet_bill_payment TO 'charging_settlement_dev'@'127.0.0.1';
GRANT INSERT ON charging_platform.notification TO 'charging_settlement_dev'@'127.0.0.1';
-- MySQL requires an additional privilege for locking reads (SELECT FOR UPDATE).
GRANT UPDATE (gun_id) ON charging_platform.charging_gun TO 'charging_settlement_dev'@'127.0.0.1';
GRANT UPDATE (fleet_id) ON charging_platform.fleet TO 'charging_settlement_dev'@'127.0.0.1';
GRANT UPDATE (station_id) ON charging_platform.station TO 'charging_settlement_dev'@'127.0.0.1';
GRANT UPDATE (payment_id) ON charging_platform.payment_record TO 'charging_settlement_dev'@'127.0.0.1';
GRANT UPDATE (refund_id) ON charging_platform.refund_record TO 'charging_settlement_dev'@'127.0.0.1';
GRANT UPDATE (policy_id) ON charging_platform.settlement_policy TO 'charging_settlement_dev'@'127.0.0.1';
GRANT UPDATE (bill_payment_id) ON charging_platform.fleet_bill_payment TO 'charging_settlement_dev'@'127.0.0.1';
GRANT UPDATE (invoice_id) ON charging_platform.operator_invoice TO 'charging_settlement_dev'@'127.0.0.1';
