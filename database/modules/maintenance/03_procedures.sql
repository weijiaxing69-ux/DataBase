-- =============================================================
-- maintenance 模块 · 存储过程
-- 主过程：sp_close_work_order   工单闭环 + 告警恢复判定（任务书 3.4 要求每业务 1 个）
-- 辅助过程：sp_recover_alert   把 recovering 告警推进到 recovered，供闭环过程和后台任务共用
-- 事务约定：过程内部不 commit / rollback，由调用方控制事务边界；
--           失败用 SIGNAL 抛出，最外层统一回滚。
-- 时区：入参与库内时间均为 UTC。
-- =============================================================

set names utf8mb4;
delimiter $$

drop procedure if exists sp_recover_alert$$
-- -------------------------------------------------------------
-- 恢复判定：C05 的落地实现
-- 四个条件同时满足才允许 recovered：
--   1) 告警处于 recovering（已被闭环流程置位）；
--   2) 该告警下不存在未闭环工单（一张修好不算数）；
--   3) 从 normal_since_at 到 p_now 之间没有故障采样（连续正常，而非"某一刻正常"）；
--   4) 观察时长 >= alarm_rule.recovery_seconds。
-- 恢复时间取 p_now（可传参回放 L03 时间线），不取工单闭环时间。
-- -------------------------------------------------------------
create procedure sp_recover_alert(
  in p_alert_id bigint unsigned,
  in p_now datetime(3)
)
begin
  declare v_status varchar(32);
  declare v_normal_since datetime(3);
  declare v_pile_id bigint unsigned;
  declare v_recovery_seconds int unsigned;
  declare v_pending_orders int default 0;
  declare v_bad_samples int default 0;

  select a.status, a.normal_since_at, a.pile_id, r.recovery_seconds
    into v_status, v_normal_since, v_pile_id, v_recovery_seconds
    from device_alert a
    join alarm_rule r on r.alarm_rule_id = a.alarm_rule_id
   where a.alert_id = p_alert_id
   for update;

  if v_status is null then
    signal sqlstate '45000' set message_text = '告警不存在';
  end if;

  if v_status = 'recovering' and v_normal_since is not null then
    select count(*)
      into v_pending_orders
      from work_order
     where alert_id = p_alert_id
       and status <> 'closed';

    -- 只统计观察窗口内的采样；分区裁剪按 sampled_at 生效
    select count(*)
      into v_bad_samples
      from device_reading
     where pile_id = v_pile_id
       and sampled_at >= v_normal_since
       and sampled_at <= p_now
       and fault_code <> 'NONE';

    if v_pending_orders = 0
       and v_bad_samples = 0
       and timestampdiff(second, v_normal_since, p_now) >= v_recovery_seconds then
      update device_alert
         set status = 'recovered',
             recovered_at = p_now
       where alert_id = p_alert_id;
    end if;
  end if;
end$$

drop procedure if exists sp_close_work_order$$
-- -------------------------------------------------------------
-- 工单闭环：C03 + C05
-- 前置：工单已 repaired，且存在复核通过事件（review_passed），避免"修完直接关单"。
-- 步骤：锁工单 → 写 closed 事件 → 更新状态 → 若该告警全部工单闭环，
--       把 normal_since_at 置为最后一个闭环时间 → 调用恢复判定。
-- 注意：闭环后告警通常是 recovering 而不是 recovered（L03 的预期），
--       必须累计连续正常达 recovery_seconds 才恢复。
-- -------------------------------------------------------------
create procedure sp_close_work_order(
  in p_work_order_id bigint unsigned,
  in p_actor_account_id bigint unsigned,
  in p_review_result varchar(255),
  in p_note varchar(500)
)
begin
  declare v_status varchar(32);
  declare v_alert_id bigint unsigned;
  declare v_pending_orders int default 0;
  declare v_normal_since datetime(3);
  declare v_last_repaired datetime(3);
  declare v_last_reviewed datetime(3);

  select status, alert_id
    into v_status, v_alert_id
    from work_order
   where work_order_id = p_work_order_id
   for update;

  if v_status is null then
    signal sqlstate '45000' set message_text = '工单不存在';
  end if;

  if v_status <> 'repaired' then
    signal sqlstate '45000' set message_text = '只有已修复(repaired)的工单可以闭环';
  end if;

  -- 必须复核的是本轮修复：复核失败后重修，旧复核记录不能用于再次闭环
  select max(case when event_type = 'repaired' then event_at end),
         max(case when event_type = 'review_passed' then event_at end)
    into v_last_repaired, v_last_reviewed
    from work_order_event
   where work_order_id = p_work_order_id;

  if v_last_repaired is null or v_last_reviewed is null or v_last_reviewed < v_last_repaired then
    signal sqlstate '45000' set message_text = '闭环前必须有本轮修复的复核通过(review_passed)事件';
  end if;

  insert into work_order_event
    (work_order_id, event_type, event_at, old_status, new_status,
     actor_account_id, note, review_result)
  values
    (p_work_order_id, 'closed', utc_timestamp(3), 'repaired', 'closed',
     p_actor_account_id, p_note, p_review_result);

  update work_order
     set status = 'closed'
   where work_order_id = p_work_order_id;

  select count(*)
    into v_pending_orders
    from work_order
   where alert_id = v_alert_id
     and status <> 'closed';

  if v_pending_orders = 0 then
    -- 连续正常起点 = 本轮所有工单的最后闭环时间
    select max(ev.event_at)
      into v_normal_since
      from work_order_event ev
      join work_order w on w.work_order_id = ev.work_order_id
     where w.alert_id = v_alert_id
       and ev.event_type = 'closed';

    update device_alert
       set status = 'recovering',
           normal_since_at = v_normal_since
     where alert_id = v_alert_id
       and status <> 'recovered';

    call sp_recover_alert(v_alert_id, utc_timestamp(3));
  end if;
end$$

delimiter ;
