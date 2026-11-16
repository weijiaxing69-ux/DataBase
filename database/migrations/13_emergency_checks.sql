-- =============================================================
-- maintenance 模块 · V1.5 应急增强验收（正向，可整文件顺序执行）
-- 覆盖：事件看板 / 值班 / 告警自动归并 / 超时升级 / 恢复 / 复盘 / 关闭 / 自动声明 / 备件
-- 前置：10、11、12 已执行
-- 注意：本脚本会修改数据，重复演示前先按文件末尾的回滚段恢复
-- =============================================================

set names utf8mb4;
set time_zone = '+00:00';

-- -------------------------------------------------------------
-- 0. 对象清单：11 表 / 4 视图 / 4 过程 / 6 触发器（含 V1.4 的 3 个）
-- -------------------------------------------------------------
select table_name
from information_schema.tables
where table_schema = database()
  and table_name in ('incident','incident_alert','incident_action','on_call_shift',
                     'incident_sla','escalation_policy','incident_escalation',
                     'postmortem','action_item','spare_part','part_usage')
order by table_name;

select table_name as view_name
from information_schema.views
where table_schema = database() and table_name like 'v\_%'
order by table_name;

select routine_name
from information_schema.routines
where routine_schema = database() and routine_name like 'sp\_%'
order by routine_name;

select trigger_name, event_object_table, action_timing
from information_schema.triggers
where trigger_schema = database()
order by trigger_name;

-- -------------------------------------------------------------
-- 1. 事件看板：SLA 是否破线一目了然
--    预期：901 为 P1/contained，3 条告警，0 未闭环工单；902 为 P2/restored
-- -------------------------------------------------------------
select incident_no, severity, status, alert_count, open_work_orders,
       ack_seconds, ack_limit_seconds, ack_breached,
       restore_seconds, restore_limit_seconds, restore_breached,
       commander_username, escalation_level
from v_incident_board
where incident_id in (901, 902)
order by incident_id;

-- -------------------------------------------------------------
-- 2. 当前值班：三条班次均在班
-- -------------------------------------------------------------
select scope_type, scope_name, primary_username, backup_username,
       supervisor_username, is_current
from v_on_call_now
where scope_id in (901, 6, 3)
order by shift_id;

-- -------------------------------------------------------------
-- 3. 告警自动归并：场站 901 已在进行中事件，新告警直接并入而不是新建
--    预期：插入 914 后，事件 901 的告警数从 3 变为 4
-- -------------------------------------------------------------
insert into device_alert
  (alert_id, pile_id, gun_id, alarm_rule_id, alert_code, severity, occurred_at,
   status, response_seconds_snapshot)
values
  (914, 901, 901, 903, 'E103', 'medium', '2026-11-13 12:35:00', 'open', 1800);

select ia.incident_id, count(*) as linked_alerts,
       sum(case when ia.is_root_cause = 1 then 1 else 0 end) as root_cause_alerts
from incident_alert ia
where ia.incident_id = 901
group by ia.incident_id;

-- -------------------------------------------------------------
-- 4. 超时升级：12:05 宣布，12:45 时已持续 40 分钟 → 命中 P1 30 分钟 L2 策略
--    预期：新增一条 L2 升级记录，事件最高层级仍为 L3
-- -------------------------------------------------------------
call sp_escalate_incidents('2026-11-13 12:45:00');

select incident_id, policy_id, notify_level, triggered_at, notified_account_id
from incident_escalation
where incident_id = 901
order by escalation_id;

select incident_no, escalation_level, status from incident where incident_id = 901;

-- -------------------------------------------------------------
-- 5. 恢复：告警全部恢复 + 事件置 restored
--    预期：恢复耗时 = 13:10 - 12:00 = 4200 秒，未超过 P1 的 4 小时
-- -------------------------------------------------------------
update device_alert
   set status = 'recovered', recovered_at = '2026-11-13 13:00:00'
 where alert_id in (911, 912, 913, 914);

update incident
   set status = 'restored', restored_at = '2026-11-13 13:10:00'
 where incident_id = 901;

select incident_no, status, alert_count, restore_seconds, restore_breached
from v_incident_board where incident_id = 901;

-- -------------------------------------------------------------
-- 6. 复盘 + 关闭：没有复盘不能关，有复盘才能关
--    预期：插入复盘后关闭成功，状态变 closed
-- -------------------------------------------------------------
insert into postmortem
  (postmortem_id, incident_id, root_cause_category, root_cause,
   detection_seconds, response_seconds, recovery_seconds,
   prevention, reviewer_account_id, reviewed_at, status)
values
  (902, 901, 'power', '园区配电柜进线开关跳闸，备用回路未自动投入',
   300, 300, 4200,
   '加装备用回路自动切换装置；把配电柜巡检纳入周检；停电台账与运营商共享',
   101, '2026-11-13 14:00:00', 'approved');

call sp_close_incident(901, 101, '市电恢复，场站已复电并完成复测');

select incident_no, status, closed_at, summary
from incident where incident_id = 901;

-- -------------------------------------------------------------
-- 7. 自动声明：同一场站 10 分钟内 2 条严重告警 → 自动形成 P2 事件
--    预期：插入 921 时无事件；插入 922 后自动生成 INC-20261113-0003
-- -------------------------------------------------------------
insert into device_alert
  (alert_id, pile_id, gun_id, alarm_rule_id, alert_code, severity, occurred_at,
   status, response_seconds_snapshot)
values
  (921, 901, 901, 901, 'E101', 'critical', '2026-11-13 13:20:00', 'open', 300);

select count(*) as active_incidents_after_921
from incident
where station_id = 901 and status in ('detected', 'declared', 'contained');   -- 预期 0

insert into device_alert
  (alert_id, pile_id, gun_id, alarm_rule_id, alert_code, severity, occurred_at,
   status, response_seconds_snapshot)
values
  (922, 902, 902, 902, 'E102', 'high', '2026-11-13 13:21:00', 'open', 600);

select incident_id, incident_no, severity, status, impact_pile_count, title
from incident
where station_id = 901
order by incident_id;

select ia.incident_id, ia.alert_id, ia.is_root_cause
from incident_alert ia
where ia.alert_id in (921, 922)
order by ia.alert_id;

-- -------------------------------------------------------------
-- 8. 抢修备件：低库存预警（风扇 4-1=3 低于安全库存 5）
-- -------------------------------------------------------------
select part_code, part_name, station_name, stock_qty, safety_stock, gap, stock_status
from v_part_stock_alert
order by part_id;

-- -------------------------------------------------------------
-- 9. 应急指标：按月按级别统计 MTTA / MTTR 与破线次数
-- -------------------------------------------------------------
select * from v_emergency_metrics order by bill_month, severity;

-- -------------------------------------------------------------
-- 10. 处置流水（证据链）
-- -------------------------------------------------------------
select action_id, incident_id, action_type, target_type, target_id,
       action_at, actor_account_id, approved_by, result
from incident_action
where incident_id in (901, 902)
order by action_id;

-- -------------------------------------------------------------
-- 11. 演示后回滚（重复演示前执行）
-- -------------------------------------------------------------
-- delete from incident_alert where alert_id in (914, 921, 922);
-- delete from incident_alert where incident_id in (select incident_id from incident where incident_no = 'INC-20261113-0003');
-- delete from incident_action where incident_id in (select incident_id from incident where incident_no = 'INC-20261113-0003');
-- delete from incident_escalation where incident_id in (select incident_id from incident where incident_no = 'INC-20261113-0003');
-- delete from incident where incident_no = 'INC-20261113-0003';
-- delete from device_alert where alert_id in (914, 921, 922);
-- delete from postmortem where postmortem_id = 902;
-- update incident set status = 'contained', contained_at = '2026-11-13 12:30:00',
--        restored_at = null, closed_at = null, summary = '已隔离场站并暂停接单，等待市电恢复'
--  where incident_id = 901;
-- update device_alert set status = 'processing', recovered_at = null where alert_id in (911, 912, 913);
