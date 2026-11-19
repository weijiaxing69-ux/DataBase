-- 场站级功率过载识别规则（台区容量预警）
-- 规则 fault_code=CAP01，阈值 300kW，high 级，10 分钟响应
-- metric 取 fault_code 以符合 ck_alarm_rule_1；station_power 语义由 rule_code 与文档说明
insert ignore into `alarm_rule`
  (`rule_code`, `fault_code`, `metric`, `threshold_value`, `severity`,
   `response_seconds`, `recovery_seconds`, `enabled`)
values
  ('CAP-STATION-300', 'CAP01', 'fault_code', 300.000, 'high', 600, 120, 1);

select 'station overload rule ready' as status;
