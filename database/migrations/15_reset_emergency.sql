-- =============================================================
-- maintenance 模块 · V1.5 演示数据重置
-- 用途：13 号验收脚本会修改数据；重复演示前先执行本脚本，再执行 12、13。
-- 顺序按外键依赖：子表 → 父表 → 演示场站
-- 注意：只清理 V1.5 演示数据（ID 901+），不动 V1.4 的 20 条历史样例
-- =============================================================

set names utf8mb4;
set time_zone = '+00:00';

delete from `action_item`        where `postmortem_id` >= 901;
delete from `postmortem`         where `postmortem_id` >= 901;
delete from `incident_escalation` where `incident_id` >= 901;
delete from `incident_action`    where `incident_id` >= 901;
delete from `incident_alert`     where `incident_id` >= 901;
delete from `incident`           where `incident_id` >= 901;

delete from `part_usage`         where `usage_id` >= 901;
delete from `spare_part`         where `part_id` >= 901;

delete from `on_call_shift`      where `shift_id` >= 901;
delete from `escalation_policy`  where `policy_id` >= 901;
delete from `incident_sla`       where `severity` in ('P1', 'P2', 'P3', 'P4');

-- 告警：V1.5 场景与验收用例产生的全部在 911 以上
delete from `device_alert`       where `alert_id` >= 911;

-- 演示场站（枪 → 桩 → 场站）
delete from `charging_gun`       where `gun_id` >= 901;
delete from `charging_pile`      where `pile_id` >= 901;
delete from `station`            where `station_id` >= 901;

select 'emergency demo data cleared' as status;
