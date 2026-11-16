-- =============================================================
-- maintenance 模块 · 验收脚本（正向用例，可整文件顺序执行）
-- 对应任务书 C01–C05 与 L03 联调用例，输出可直接截图进报告
-- 负向用例（预期报错）在 08_negative_cases.sql，必须逐条单独执行
-- =============================================================

set names utf8mb4;
set time_zone = '+00:00';

-- -------------------------------------------------------------
-- 0. 对象清单：应看到 3 视图、2 过程、2 触发器
-- -------------------------------------------------------------
select table_name as view_name
from information_schema.views
where table_schema = database() and table_name like 'v\_%';

select routine_type, routine_name
from information_schema.routines
where routine_schema = database() and routine_name like 'sp\_%';

select trigger_name, event_manipulation, event_object_table, action_timing
from information_schema.triggers
where trigger_schema = database();

-- -------------------------------------------------------------
-- 1. C01 分区与裁剪
--    预期：p_before_202611 / p202611 / p202612 / p_future，各含 4 个子分区；
--          explain 的 partitions 列只出现 p202611 的 4 个子分区
-- -------------------------------------------------------------
select partition_name, subpartition_name, partition_method, table_rows
from information_schema.partitions
where table_schema = database()
  and table_name = 'device_reading'
order by partition_ordinal_position, subpartition_ordinal_position;

explain
select *
from device_reading
where pile_id = 3
  and sampled_at >= '2026-11-14 01:00:00'
  and sampled_at <  '2026-11-15 00:00:00';

-- -------------------------------------------------------------
-- 2. C02 告警与工单 1:N；未恢复告警去重
--    预期：alert 901 返回 2 行（一张超时未接单、一张已闭环）
-- -------------------------------------------------------------
select a.alert_id, a.alert_code, a.status, count(w.work_order_id) as order_count
from device_alert a
left join work_order w on w.alert_id = a.alert_id
where a.alert_id in (901, 902)
group by a.alert_id, a.alert_code, a.status;

-- 重复上报同一未恢复告警：预期 0 行受影响，而不是插入第二条
insert ignore into device_alert
  (pile_id, gun_id, alarm_rule_id, alert_code, severity, occurred_at, status, response_seconds_snapshot)
values
  (4, 4, 901, 'E101', 'critical', '2026-11-13 10:05:00', 'open', 300);

select row_count() as duplicated_insert_affected_rows;   -- 预期 0

select count(*) as active_e101_on_pile4
from device_alert
where pile_id = 4 and alert_code = 'E101' and status <> 'recovered';  -- 预期 1

-- -------------------------------------------------------------
-- 3. C03 各时间节点与耗时（复核未通过的工单保留历史）
--    预期：906 的 repair_seconds 有值、closed_at 为空、review_failed_count = 1
-- -------------------------------------------------------------
select work_order_id, work_order_status, accept_seconds, arrive_seconds,
       repair_seconds, review_seconds, total_seconds,
       review_failed_count, escalated_count, accept_overdue
from v_work_order_progress
where work_order_id in (901, 906)
order by work_order_id;

-- -------------------------------------------------------------
-- 4. C04 等级决定时限：超时明细
--    预期：alert 901 的 902 号工单超时；alert 902 的 903 号工单超时；
--          904 号已按 10 分钟时限内接单，不超时
-- -------------------------------------------------------------
select alert_id, alert_code, severity, response_seconds_snapshot,
       work_order_id, work_order_status, assigned_at, response_due_at,
       first_accepted_at, response_seconds_actual, is_overdue, escalation_level
from v_alert_response_detail
where work_order_id in (902, 903, 904)
order by work_order_id;

-- -------------------------------------------------------------
-- 5. C05 L03 时间线回放
--    09:35（UTC 01:35）闭环后进入 recovering；
--    09:36（UTC 01:36）连续正常满 60 秒才记 recovered，恢复时间 01:36:00
-- -------------------------------------------------------------

-- 5.1 闭环后初始状态
select alert_id, status, normal_since_at, recovered_at
from device_alert where alert_id = 903;

-- 5.2 观察期不足（仅 30 秒）：预期仍为 recovering
call sp_recover_alert(903, '2026-11-14 01:35:30');
select alert_id, status, recovered_at from device_alert where alert_id = 903;

-- 5.3 满 60 秒：预期 recovered，recovered_at = 2026-11-14 01:36:00
call sp_recover_alert(903, '2026-11-14 01:36:00');
select alert_id, status, normal_since_at, recovered_at from device_alert where alert_id = 903;

-- 5.4 观察期内存在故障采样时不得恢复：预期保持 recovering
update device_alert
   set status = 'recovering', recovered_at = null
 where alert_id = 903;

update device_reading
   set fault_code = 'E003'
 where pile_id = 3 and sampled_at = '2026-11-14 01:36:00';

call sp_recover_alert(903, '2026-11-14 01:37:00');
select alert_id, status from device_alert where alert_id = 903;   -- 预期 recovering

-- 复原采样，供后续演示
update device_reading
   set fault_code = 'NONE'
 where pile_id = 3 and sampled_at = '2026-11-14 01:36:00';

-- -------------------------------------------------------------
-- 6. 触发器：采样入库自动生成告警（故障码规则 + 温度规则）
--    预期：桩 7 最终只有 2 条告警（E101 一条、SCN-TEMP-70 一条），重复上报不重复生成
-- -------------------------------------------------------------
insert into device_reading
  (pile_id, sampled_at, output_voltage_v, output_current_a, power_kw,
   module_temperature_c, offline_seconds, fault_code)
values
  (7, '2026-11-13 11:00:00', 398.000, 12.000, 4.776, 41.50, 0, 'E101');

select alert_id, pile_id, alert_code, severity, status, response_seconds_snapshot, occurred_at
from device_alert where pile_id = 7 and alert_id > 900;

insert into device_reading
  (pile_id, sampled_at, output_voltage_v, output_current_a, power_kw,
   module_temperature_c, offline_seconds, fault_code)
values
  (7, '2026-11-13 11:01:00', 398.000, 12.000, 4.776, 41.60, 0, 'E101');

insert into device_reading
  (pile_id, sampled_at, output_voltage_v, output_current_a, power_kw,
   module_temperature_c, offline_seconds, fault_code)
values
  (7, '2026-11-13 11:02:00', 398.000, 12.000, 4.776, 72.30, 0, 'NONE');

select count(*) as alert_count_pile7 from device_alert where pile_id = 7 and alert_id > 900;   -- 预期 2

-- -------------------------------------------------------------
-- 7. 后台任务动作（等价于 Service 的 check_overdue_work_orders）
--    生产实现：按 status='assigned' + response_due_at < now 分批扫描、加租约防重复；
--    这里用一条 UPDATE + 一条事件演示效果
-- -------------------------------------------------------------
update work_order
   set escalation_level = escalation_level + 1
 where work_order_id = 902
   and status = 'assigned'
   and response_due_at < utc_timestamp()
   and escalation_level = 0;   -- 重复执行不会叠加，便于多次演示

insert into work_order_event
  (work_order_id, event_type, event_at, old_status, new_status, actor_account_id, note)
select 902, 'escalated', utc_timestamp(), 'assigned', 'assigned', null, '超时未接单，自动升级至上级'
  from dual
 where exists (select 1 from work_order where work_order_id = 902 and escalation_level = 1);

select w.work_order_id, w.status, w.escalation_level,
       (select count(*) from work_order_event e
         where e.work_order_id = w.work_order_id and e.event_type = 'escalated') as escalated_events
from work_order w
where w.work_order_id = 902;

-- -------------------------------------------------------------
-- 8. 演示后回滚（重复演示前执行）
-- -------------------------------------------------------------
-- delete from device_alert where pile_id = 7;
-- delete from device_reading where pile_id = 7 and sampled_at >= '2026-11-13 11:00:00';
-- delete from work_order_event where work_order_id = 902 and event_type = 'escalated';
-- update work_order set escalation_level = 0 where work_order_id = 902;
-- update device_alert set status = 'recovering', normal_since_at = '2026-11-14 01:35:00',
--        recovered_at = null where alert_id = 903;
