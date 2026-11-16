-- Q1. 2026-10 场站应结和开票净额。两种写法保留没有开票的场站结算。
SELECT s.settlement_id, o.operator_name, st.station_name, s.payable_amount,
       COALESCE(i.net_issued_amount, 0) AS net_issued_amount
FROM operator_settlement AS s
JOIN `operator` AS o ON o.operator_id = s.operator_id
JOIN station AS st ON st.station_id = s.station_id
LEFT JOIN (
    SELECT settlement_id, SUM(IF(invoice_type = 'blue', amount, -amount)) AS net_issued_amount
    FROM operator_invoice GROUP BY settlement_id
) AS i ON i.settlement_id = s.settlement_id
WHERE s.bill_month = '2026-10-01'
ORDER BY s.settlement_id;

SELECT s.settlement_id, o.operator_name, st.station_name, s.payable_amount,
       COALESCE((
           SELECT SUM(IF(i.invoice_type = 'blue', i.amount, -i.amount))
           FROM operator_invoice AS i WHERE i.settlement_id = s.settlement_id
       ), 0) AS net_issued_amount
FROM operator_settlement AS s
JOIN `operator` AS o ON o.operator_id = s.operator_id
JOIN station AS st ON st.station_id = s.station_id
WHERE s.bill_month = '2026-10-01'
ORDER BY s.settlement_id;

-- Q2. 当前版本已获双方确认且已生效的对账差异。
SELECT d.difference_id, d.settlement_id, d.order_id, d.amount
FROM reconciliation_difference AS d
JOIN reconciliation_confirmation AS c
  ON c.difference_id = d.difference_id AND c.object_version = d.version
WHERE d.status = 'effective' AND c.is_current = 1 AND c.decision = 'confirmed'
GROUP BY d.difference_id, d.settlement_id, d.order_id, d.amount
HAVING COUNT(DISTINCT c.side) = 2
ORDER BY d.difference_id;

SELECT d.difference_id, d.settlement_id, d.order_id, d.amount
FROM reconciliation_difference AS d
WHERE d.status = 'effective'
  AND EXISTS (
      SELECT 1 FROM reconciliation_confirmation AS c
      WHERE c.difference_id = d.difference_id AND c.object_version = d.version
        AND c.is_current = 1 AND c.decision = 'confirmed' AND c.side = 'platform'
  )
  AND EXISTS (
      SELECT 1 FROM reconciliation_confirmation AS c
      WHERE c.difference_id = d.difference_id AND c.object_version = d.version
        AND c.is_current = 1 AND c.decision = 'confirmed' AND c.side = 'operator'
  )
ORDER BY d.difference_id;

-- Q3. 2026-10 车队账单应付和企业现金实收。抵扣额不计入实收。
SELECT b.bill_id, f.company_name, b.payable_amount, COALESCE(SUM(p.amount), 0) AS cash_received
FROM fleet_monthly_bill AS b
JOIN fleet AS f ON f.fleet_id = b.fleet_id
LEFT JOIN fleet_bill_payment AS p ON p.bill_id = b.bill_id AND p.status = 'succeeded'
WHERE b.bill_month = '2026-10-01'
GROUP BY b.bill_id, f.company_name, b.payable_amount
ORDER BY b.bill_id;

SELECT b.bill_id, f.company_name, b.payable_amount,
       COALESCE((
           SELECT SUM(p.amount) FROM fleet_bill_payment AS p
           WHERE p.bill_id = b.bill_id AND p.status = 'succeeded'
       ), 0) AS cash_received
FROM fleet_monthly_bill AS b
JOIN fleet AS f ON f.fleet_id = b.fleet_id
WHERE b.bill_month = '2026-10-01'
ORDER BY b.bill_id;
