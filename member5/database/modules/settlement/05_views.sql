-- V1.4 settlement. Execute with the target schema selected.
CREATE OR REPLACE SQL SECURITY INVOKER VIEW v_settlement_summary AS
SELECT s.settlement_id, s.operator_id, o.operator_name, s.station_id,
       st.station_name, s.bill_month, s.status, s.version, s.energy_kwh,
       s.electricity_share_amount, s.service_share_amount, s.platform_fee_amount,
       s.adjustment_amount, s.payable_amount,
       COALESCE(i.net_issued_amount, 0) AS net_issued_amount
FROM operator_settlement AS s
JOIN `operator` AS o ON o.operator_id = s.operator_id
JOIN station AS st ON st.station_id = s.station_id
LEFT JOIN (
    SELECT settlement_id,
           SUM(CASE WHEN invoice_type = 'blue' THEN amount ELSE -amount END) AS net_issued_amount
    FROM operator_invoice
    GROUP BY settlement_id
) AS i ON i.settlement_id = s.settlement_id;

CREATE OR REPLACE SQL SECURITY INVOKER VIEW v_reconciliation_difference_status AS
SELECT d.difference_id, d.settlement_id, s.operator_id, s.station_id, s.bill_month,
       d.order_id, d.difference_type, d.amount, d.resolution, d.status, d.version,
       p.decision AS platform_decision, p.confirmed_at AS platform_confirmed_at,
       o.decision AS operator_decision, o.confirmed_at AS operator_confirmed_at
FROM reconciliation_difference AS d
JOIN operator_settlement AS s ON s.settlement_id = d.settlement_id
LEFT JOIN reconciliation_confirmation AS p
    ON p.difference_id = d.difference_id AND p.object_version = d.version
   AND p.side = 'platform' AND p.is_current = 1
LEFT JOIN reconciliation_confirmation AS o
    ON o.difference_id = d.difference_id AND o.object_version = d.version
   AND o.side = 'operator' AND o.is_current = 1;

CREATE OR REPLACE SQL SECURITY INVOKER VIEW v_fleet_bill_receipts AS
SELECT b.bill_id, b.fleet_id, f.company_name, b.bill_month, b.status,
       b.order_amount, b.adjustment_amount, b.payable_amount, b.paid_amount,
       COALESCE(p.cash_received, 0) AS cash_received
FROM fleet_monthly_bill AS b
JOIN fleet AS f ON f.fleet_id = b.fleet_id
LEFT JOIN (
    SELECT bill_id, SUM(amount) AS cash_received
    FROM fleet_bill_payment
    WHERE status = 'succeeded'
    GROUP BY bill_id
) AS p ON p.bill_id = b.bill_id;
