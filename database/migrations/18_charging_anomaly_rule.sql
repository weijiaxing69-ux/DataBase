-- =============================================================
-- 维护模块 · 充电过程异常规则（可重复执行）
-- 现实问题：订单还在"充电中"，但桩输出功率持续接近 0（跳枪、枪锁松脱、
-- BMS 中断），用户以为在充、实际没充，平台也看不到故障码。
-- 这类异常不属于设备自报故障，需要用采样数据反推，所以单独建一条规则。
-- =============================================================

set names utf8mb4;

insert into `alarm_rule`
  (`rule_code`, `fault_code`, `metric`, `threshold_value`, `severity`,
   `response_seconds`, `recovery_seconds`, `enabled`)
select 'CHG-INTERRUPT', 'CHG01', 'fault_code', null, 'high', 1800, 300, 1
where not exists (select 1 from `alarm_rule` where `rule_code` = 'CHG-INTERRUPT');

select 'charging anomaly rule ready' as status;
