-- =============================================================
-- maintenance 模块 · V1.5 应急响应对象
-- 4 视图 + 3 存储过程 + 3 触发器
-- 依赖：10_emergency_tables.sql 已执行
-- =============================================================

set names utf8mb4;
set time_zone = '+00:00';

-- -------------------------------------------------------------
-- V1 事件看板：级别、持续时长、影响面、SLA 是否破线
--    一行 = 一个事件；未关闭事件的耗时按"当前时刻"实时计算
-- -------------------------------------------------------------
create or replace view v_incident_board as
select
  i.incident_id,
  i.incident_no,
  i.operator_id,
  o.operator_name,
  i.station_id,
  s.station_name,
  i.category,
  i.severity,
  i.title,
  i.status,
  i.detected_at,
  i.declared_at,
  i.contained_at,
  i.restored_at,
  i.closed_at,
  i.commander_account_id,
  c.username                                   as commander_username,
  i.impact_pile_count,
  i.impact_order_count,
  i.estimated_loss_amount,
  i.escalation_level,
  coalesce(al.alert_count, 0)                  as alert_count,
  coalesce(wo.open_work_orders, 0)             as open_work_orders,
  sla.ack_seconds                              as ack_limit_seconds,
  sla.restore_seconds                          as restore_limit_seconds,
  timestampdiff(second, i.detected_at,
                coalesce(i.declared_at, utc_timestamp()))        as ack_seconds,
  timestampdiff(second, i.detected_at,
                coalesce(i.restored_at, utc_timestamp()))        as restore_seconds,
  case when timestampdiff(second, i.detected_at,
                coalesce(i.declared_at, utc_timestamp())) > sla.ack_seconds
       then 1 else 0 end                       as ack_breached,
  case when timestampdiff(second, i.detected_at,
                coalesce(i.restored_at, utc_timestamp())) > sla.restore_seconds
       then 1 else 0 end                       as restore_breached
from incident i
join operator o
  on o.operator_id = i.operator_id
left join station s
  on s.station_id = i.station_id
left join sys_account c
  on c.account_id = i.commander_account_id
join incident_sla sla
  on sla.severity = i.severity
left join (
  select incident_id, count(*) as alert_count
  from incident_alert
  group by incident_id
) al on al.incident_id = i.incident_id
left join (
  select ia.incident_id, count(*) as open_work_orders
  from incident_alert ia
  join work_order w on w.alert_id = ia.alert_id
  where w.status <> 'closed'
  group by ia.incident_id
) wo on wo.incident_id = i.incident_id;

-- -------------------------------------------------------------
-- V2 当前及未来 24 小时值班
-- -------------------------------------------------------------
create or replace view v_on_call_now as
select
  sc.shift_id,
  sc.scope_type,
  sc.scope_id,
  case sc.scope_type
    when 'station'  then (select station_name  from station  where station_id  = sc.scope_id)
    else                 (select operator_name from operator where operator_id = sc.scope_id)
  end                                            as scope_name,
  sc.shift_start,
  sc.shift_end,
  sc.status,
  p.username                                     as primary_username,
  b.username                                     as backup_username,
  sp.username                                    as supervisor_username,
  case when utc_timestamp() >= sc.shift_start and utc_timestamp() < sc.shift_end
       then 1 else 0 end                         as is_current
from on_call_shift sc
left join sys_account p  on p.account_id  = sc.primary_account_id
left join sys_account b  on b.account_id  = sc.backup_account_id
left join sys_account sp on sp.account_id = sc.supervisor_account_id
where sc.shift_end >= utc_timestamp()
  and sc.shift_start <= utc_timestamp() + interval 1 day;

-- -------------------------------------------------------------
-- V3 应急指标：按月按级别统计 MTTA / MTTR / 破线次数
--    用途：报告"运维管理"章节的量化指标，答辩可直接截图
-- -------------------------------------------------------------
create or replace view v_emergency_metrics as
select
  date_format(detected_at, '%Y-%m')            as bill_month,
  severity,
  count(*)                                     as incident_count,
  sum(case when ack_breached = 0 then 1 else 0 end)      as ack_ok_count,
  sum(ack_breached)                            as ack_breach_count,
  sum(restore_breached)                        as restore_breach_count,
  round(avg(ack_seconds), 0)                   as avg_ack_seconds,
  round(avg(restore_seconds), 0)               as avg_restore_seconds
from v_incident_board
where status in ('restored', 'reviewed', 'closed')
group by date_format(detected_at, '%Y-%m'), severity;

-- -------------------------------------------------------------
-- V4 备件低库存预警（低于安全库存或已断货）
-- -------------------------------------------------------------
create or replace view v_part_stock_alert as
select
  p.part_id,
  p.part_code,
  p.part_name,
  p.model,
  p.station_id,
  s.station_name,
  p.stock_qty,
  p.safety_stock,
  (cast(p.stock_qty as signed) - cast(p.safety_stock as signed)) as gap,
  case when p.stock_qty = 0 then 'out_of_stock'
       when p.stock_qty < p.safety_stock then 'low'
       else 'at_safety' end                     as stock_status
from spare_part p
left join station s on s.station_id = p.station_id
where p.status = 'active'
  and p.stock_qty <= p.safety_stock;

delimiter $$

drop procedure if exists sp_escalate_incidents$$
-- -------------------------------------------------------------
-- 升级扫描：按"级别 × 持续时长 × 影响桩数"匹配策略，同一事件同一策略只触发一次。
-- 生产实现应由调度器每分钟调用；事务由调用方控制。
-- -------------------------------------------------------------
create procedure sp_escalate_incidents(
  in p_now datetime(3)
)
begin
  declare v_done int default 0;
  declare v_incident_id bigint unsigned;
  declare v_severity varchar(8);
  declare v_impact int unsigned;
  declare v_elapsed int;
  declare v_policy_id bigint unsigned;
  declare v_level varchar(8);
  declare v_action varchar(32);
  declare v_notify bigint unsigned;
  declare v_level_num int;

  declare cur_incident cursor for
    select i.incident_id, i.severity, i.impact_pile_count
      from incident i
     where i.status in ('detected', 'declared', 'contained');
  declare continue handler for not found set v_done = 1;

  open cur_incident;
  read_loop: loop
    fetch cur_incident into v_incident_id, v_severity, v_impact;
    if v_done = 1 then
      leave read_loop;
    end if;

    -- 用标量子查询而不是 select ... into，避免"没有行"触发 NOT FOUND 处理器导致循环提前结束
    set v_elapsed = (select timestampdiff(second, coalesce(i.declared_at, i.detected_at), p_now)
                       from incident i where i.incident_id = v_incident_id);

    set v_policy_id = (
      select p.policy_id
        from escalation_policy p
       where p.enabled = 1
         and (p.applies_severity = v_severity or p.applies_severity = 'ANY')
         and v_elapsed >= p.min_duration_seconds
         and v_impact  >= p.min_impact_piles
         and not exists (
               select 1 from incident_escalation e
                where e.incident_id = v_incident_id
                  and e.policy_id = p.policy_id
             )
       order by field(p.notify_level, 'L3', 'L2', 'L1'), p.min_duration_seconds desc
       limit 1);

    if v_policy_id is not null then
      select p.notify_level, p.action_code
        into v_level, v_action
        from escalation_policy p
       where p.policy_id = v_policy_id;

      set v_level_num = case v_level when 'L3' then 3 when 'L2' then 2 else 1 end;

      set v_notify = (
        select coalesce(sco.supervisor_account_id, sco.primary_account_id)
          from on_call_shift sco
          join incident i
            on (i.station_id is not null and sco.scope_type = 'station'  and sco.scope_id = i.station_id)
            or (i.station_id is null     and sco.scope_type = 'operator' and sco.scope_id = i.operator_id)
         where i.incident_id = v_incident_id
           and sco.shift_start <= p_now
           and sco.shift_end   >  p_now
         limit 1);

      if v_notify is null then
        set v_notify = (select commander_account_id from incident where incident_id = v_incident_id);
      end if;

      insert into incident_escalation
        (incident_id, policy_id, notify_level, triggered_at, notified_account_id, note)
      values
        (v_incident_id, v_policy_id, v_level, p_now, v_notify,
         concat('持续 ', v_elapsed, ' 秒，影响 ', v_impact, ' 桩，动作 ', v_action));

      update incident
         set escalation_level = greatest(escalation_level, v_level_num)
       where incident_id = v_incident_id;

      insert into incident_action
        (incident_id, action_type, target_type, action_at, reason)
      values
        (v_incident_id, 'escalate', 'none', p_now,
         concat('自动升级到 ', v_level, '，策略 ', v_policy_id));
    end if;
  end loop;
  close cur_incident;
end$$

drop procedure if exists sp_declare_incident$$
-- -------------------------------------------------------------
-- 宣布事件：编号生成、指挥人选定、影响面统计、绑定告警、写动作、立即做一次升级扫描。
-- p_station_id 为空表示跨场站/运营商级事件。
-- p_actor_account_id 为空表示系统自动声明（触发器调用）。
-- -------------------------------------------------------------
create procedure sp_declare_incident(
  in p_operator_id bigint unsigned,
  in p_station_id bigint unsigned,
  in p_category varchar(32),
  in p_severity varchar(8),
  in p_title varchar(200),
  in p_actor_account_id bigint unsigned,
  in p_alert_id bigint unsigned,
  out p_incident_id bigint unsigned
)
begin
  declare v_operator_of_station bigint unsigned;
  declare v_day varchar(8);
  declare v_seq int;
  declare v_no varchar(32);
  declare v_detected datetime(3);
  declare v_commander bigint unsigned;
  declare v_impact int default 0;
  declare v_id bigint unsigned;

  if p_station_id is not null then
    select operator_id into v_operator_of_station
      from station where station_id = p_station_id;
    if v_operator_of_station is null then
      signal sqlstate '45000' set message_text = '场站不存在';
    end if;
    if v_operator_of_station <> p_operator_id then
      signal sqlstate '45000' set message_text = '场站不属于该运营商，拒绝声明事件';
    end if;
  end if;

  -- 发现时间：以告警发生时间为准，没有告警则取当前时刻
  set v_detected = null;
  if p_alert_id is not null then
    select occurred_at into v_detected from device_alert where alert_id = p_alert_id;
  end if;
  if v_detected is null then
    set v_detected = utc_timestamp(3);
  end if;

  -- 事件编号：INC-YYYYMMDD-NNNN，当天流水；并发由唯一索引兜底
  set v_day = date_format(v_detected, '%Y%m%d');
  select coalesce(max(cast(substring_index(incident_no, '-', -1) as unsigned)), 0) + 1
    into v_seq
    from incident
   where incident_no like concat('INC-', v_day, '-%');
  set v_no = concat('INC-', v_day, '-', lpad(v_seq, 4, '0'));

  -- 指挥人：优先场站值班主管，其次运营商值班主管
  set v_commander = null;
  if p_station_id is not null then
    select coalesce(supervisor_account_id, primary_account_id) into v_commander
      from on_call_shift
     where scope_type = 'station' and scope_id = p_station_id
       and shift_start <= utc_timestamp(3) and shift_end > utc_timestamp(3)
     limit 1;
  end if;
  if v_commander is null then
    select coalesce(supervisor_account_id, primary_account_id) into v_commander
      from on_call_shift
     where scope_type = 'operator' and scope_id = p_operator_id
       and shift_start <= utc_timestamp(3) and shift_end > utc_timestamp(3)
     limit 1;
  end if;

  -- 影响桩数：同场站（或同运营商）未恢复告警涉及的桩
  if p_station_id is not null then
    select count(distinct a.pile_id) into v_impact
      from device_alert a
      join charging_pile p on p.pile_id = a.pile_id
     where p.station_id = p_station_id
       and a.status <> 'recovered';
  else
    select count(distinct a.pile_id) into v_impact
      from device_alert a
      join charging_pile p on p.pile_id = a.pile_id
      join station s on s.station_id = p.station_id
     where s.operator_id = p_operator_id
       and a.status <> 'recovered';
  end if;

  insert into incident
    (incident_no, operator_id, station_id, category, severity, title, status,
     detected_at, declared_at, commander_account_id, impact_pile_count, impact_order_count)
  values
    (v_no, p_operator_id, p_station_id, p_category, p_severity, p_title, 'declared',
     v_detected, utc_timestamp(3), v_commander, v_impact, 0);

  set v_id = last_insert_id();
  set p_incident_id = v_id;

  if p_alert_id is not null then
    insert ignore into incident_alert
      (incident_id, alert_id, linked_at, linked_by, is_root_cause)
    values
      (v_id, p_alert_id, utc_timestamp(3), p_actor_account_id, 1);
  end if;

  insert into incident_action
    (incident_id, action_type, target_type, target_id, action_at, actor_account_id, reason)
  values
    (v_id, 'declare', 'none', null, utc_timestamp(3), p_actor_account_id,
     concat('声明 ', p_severity, ' 事件：', p_title));

  call sp_escalate_incidents(utc_timestamp(3));
end$$

drop procedure if exists sp_close_incident$$
-- -------------------------------------------------------------
-- 关闭事件的前置条件（缺一不可）：
--   1) 状态为 restored 或 reviewed；
--   2) 关联告警全部 recovered；
--   3) 关联工单全部 closed；
--   4) 复盘已审核通过（approved）。
-- 这样"关单不等于恢复、恢复不等于关闭"三个层次不会混在一起。
-- -------------------------------------------------------------
create procedure sp_close_incident(
  in p_incident_id bigint unsigned,
  in p_actor_account_id bigint unsigned,
  in p_summary varchar(1000)
)
begin
  declare v_status varchar(32);
  declare v_pending_orders int default 0;
  declare v_open_alerts int default 0;
  declare v_pm int default 0;

  select status into v_status
    from incident where incident_id = p_incident_id for update;

  if v_status is null then
    signal sqlstate '45000' set message_text = '事件不存在';
  end if;
  if v_status not in ('restored', 'reviewed') then
    signal sqlstate '45000' set message_text = '只有已恢复(restored)或已复盘(reviewed)的事件可以关闭';
  end if;

  select count(*) into v_open_alerts
    from incident_alert ia
    join device_alert a on a.alert_id = ia.alert_id
   where ia.incident_id = p_incident_id
     and a.status <> 'recovered';
  if v_open_alerts > 0 then
    signal sqlstate '45000' set message_text = '仍有未恢复告警，不能关闭事件';
  end if;

  select count(*) into v_pending_orders
    from incident_alert ia
    join work_order w on w.alert_id = ia.alert_id
   where ia.incident_id = p_incident_id
     and w.status <> 'closed';
  if v_pending_orders > 0 then
    signal sqlstate '45000' set message_text = '仍有未闭环工单，不能关闭事件';
  end if;

  select count(*) into v_pm
    from postmortem
   where incident_id = p_incident_id and status = 'approved';
  if v_pm = 0 then
    signal sqlstate '45000' set message_text = '缺少已审核通过的复盘报告，不能关闭事件';
  end if;

  update incident
     set status = 'closed',
         closed_at = utc_timestamp(3),
         summary = p_summary
   where incident_id = p_incident_id;

  insert into incident_action
    (incident_id, action_type, target_type, action_at, actor_account_id, reason)
  values
    (p_incident_id, 'close', 'none', utc_timestamp(3), p_actor_account_id, p_summary);
end$$

drop trigger if exists trg_device_alert_ai_incident$$
-- -------------------------------------------------------------
-- 告警自动归并：新告警进来时
--   1) 同场站已有进行中事件 → 直接并入（不新建事件）；
--   2) 否则若同场站 10 分钟内已累计 ≥2 条 critical/high 未恢复告警 → 自动声明 P2 事件。
-- 这条规则把"一根变压器带崩一个场站"这类连锁故障从"多条工单"变成"一个事件"。
-- -------------------------------------------------------------
create trigger trg_device_alert_ai_incident
after insert on device_alert
for each row
begin
  declare v_station bigint unsigned;
  declare v_operator bigint unsigned;
  declare v_incident bigint unsigned;
  declare v_severe int default 0;
  declare v_new bigint unsigned;

  select p.station_id, s.operator_id
    into v_station, v_operator
    from charging_pile p
    join station s on s.station_id = p.station_id
   where p.pile_id = new.pile_id;

  if v_station is not null then
    select incident_id into v_incident
      from incident
     where station_id = v_station
       and status in ('detected', 'declared', 'contained')
     order by incident_id
     limit 1;

    if v_incident is not null then
      insert ignore into incident_alert
        (incident_id, alert_id, linked_at, linked_by, is_root_cause)
      values
        (v_incident, new.alert_id, utc_timestamp(3), null, 0);
    elseif new.severity in ('critical', 'high') then
      select count(*) into v_severe
        from device_alert a
        join charging_pile p on p.pile_id = a.pile_id
       where p.station_id = v_station
         and a.status <> 'recovered'
         and a.severity in ('critical', 'high')
         and a.occurred_at >= new.occurred_at - interval 10 minute;

      if v_severe >= 2 then
        call sp_declare_incident(
          v_operator, v_station, 'hardware', 'P2',
          concat('自动聚合：场站 ', v_station, ' 10 分钟内 ', v_severe, ' 条严重告警'),
          null, new.alert_id, v_new);
      end if;
    end if;
  end if;
end$$

drop trigger if exists trg_incident_bu_state_guard$$
-- 事件状态机兜底：detected→declared→contained→restored→reviewed→closed，
-- 允许 restored 直接 closed（已完成复盘时），任何阶段可 cancelled（仅前两阶段）。
create trigger trg_incident_bu_state_guard
before update on incident
for each row
begin
  if new.status <> old.status then
    if not (
         (old.status = 'detected'  and new.status = 'declared')
      or (old.status = 'detected'  and new.status = 'cancelled')
      or (old.status = 'declared'  and new.status = 'contained')
      or (old.status = 'declared'  and new.status = 'cancelled')
      or (old.status = 'contained' and new.status = 'restored')
      or (old.status = 'restored'  and new.status = 'reviewed')
      or (old.status = 'restored'  and new.status = 'closed')
      or (old.status = 'reviewed'  and new.status = 'closed')
    ) then
      signal sqlstate '45000'
        set message_text = '非法的事件状态迁移：detected→declared→contained→restored→reviewed→closed，或前两阶段→cancelled';
    end if;
  end if;
end$$

drop trigger if exists trg_part_usage_ai_stock$$
-- 领用即扣库存；库存不足直接报错，避免出现负库存。
create trigger trg_part_usage_ai_stock
after insert on part_usage
for each row
begin
  update spare_part
     set stock_qty = stock_qty - new.qty
   where part_id = new.part_id
     and stock_qty >= new.qty;

  if row_count() = 0 then
    signal sqlstate '45000' set message_text = '备件库存不足，拒绝领用';
  end if;
end$$

delimiter ;
