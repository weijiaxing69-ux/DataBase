-- 电压越限识别规则（电网波动、枪头接触不良、整流异常）
-- 规则 fault_code=VLT01，high 级，10 分钟响应，恢复观察 120 秒
-- metric 取 fault_code 以符合 ck_alarm_rule_1；电压阈值由后台任务参数控制
insert ignore into `alarm_rule`
  (`rule_code`, `fault_code`, `metric`, `threshold_value`, `severity`,
   `response_seconds`, `recovery_seconds`, `enabled`)
values
  ('VLT-RANGE-300-1000', 'VLT01', 'fault_code', null, 'high', 600, 120, 1);

select 'voltage anomaly rule ready' as status;
