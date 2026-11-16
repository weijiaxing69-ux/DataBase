-- =============================================================
-- 维护模块 · 高温预警与计量异常规则（可重复执行）
-- 现实问题：
--   1) 夏天模块温度爬到 65℃ 以上，设备还没报故障码，但已经在降额甚至准备停机；
--   2) 订单已结束，采样却仍有输出电流——继电器粘连或计量漂移，属安全隐患；
--   3) 车充满后不走，桩被占着，后面排队。
-- 前两个用规则生成告警；第三个只发运营提醒（不涉及计费）。
-- =============================================================

set names utf8mb4;

insert into `alarm_rule`
  (`rule_code`, `fault_code`, `metric`, `threshold_value`, `severity`,
   `response_seconds`, `recovery_seconds`, `enabled`)
select 'TEMP-065', 'TEMP01', 'temperature', 65.000, 'high', 1800, 300, 1
where not exists (select 1 from `alarm_rule` where `rule_code` = 'TEMP-065');

insert into `alarm_rule`
  (`rule_code`, `fault_code`, `metric`, `threshold_value`, `severity`,
   `response_seconds`, `recovery_seconds`, `enabled`)
select 'MET-001', 'MET01', 'fault_code', null, 'critical', 600, 120, 1
where not exists (select 1 from `alarm_rule` where `rule_code` = 'MET-001');

select 'temperature and metering rules ready' as status;
