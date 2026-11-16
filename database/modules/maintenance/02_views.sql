-- =============================================================
-- maintenance 模块 · 3 个业务视图
-- 对应任务书 3.4「每条业务线至少 3 个实用视图」的设备监控与故障工单业务线
-- 依赖：charging_pile / charging_gun / station / device_alert / work_order /
--       work_order_event / sys_account / device_reading
-- 可重复执行：使用 create or replace view
-- 时区：库内全部 UTC，展示层自行加 8 小时；视图中不做时区换算
-- =============================================================

set names utf8mb4;

-- -------------------------------------------------------------
-- V1 场站设备实时状态视图
-- 用途：值班大屏 / 场站详情页。一行 = 一把枪（桩无枪时仍保留一行，gun_* 为 NULL）。
--       heartbeat_silence_seconds 供前端判断"超时未心跳"，阈值由 alarm_rule.metric='heartbeat' 给出。
-- 口径：在线只看心跳（is_online），不看枪是否占用；告警数只统计未恢复告警。
-- -------------------------------------------------------------
create or replace view v_device_realtime as
select
  p.pile_id,
  p.station_id,
  s.station_name,
  p.serial_no,
  p.model_name,
  p.rated_power_kw,
  p.lifecycle_status,
  p.status                                   as pile_status,
  p.is_online,
  p.has_fault,
  p.last_heartbeat_at,
  timestampdiff(second, p.last_heartbeat_at, utc_timestamp())  as heartbeat_silence_seconds,
  g.gun_id,
  g.gun_no,
  g.gun_type,
  g.connector_standard,
  g.max_power_kw                             as gun_max_power_kw,
  g.status                                   as gun_status,
  coalesce(a.open_alert_count, 0)            as open_alert_count,
  coalesce(a.worst_severity, 'none')         as worst_open_severity,
  r.power_kw                                 as last_power_kw,
  r.module_temperature_c                     as last_temperature_c,
  r.sampled_at                               as last_sampled_at
from charging_pile p
join station s
  on s.station_id = p.station_id
left join charging_gun g
  on g.pile_id = p.pile_id
left join (
  -- 每个桩未恢复告警的数量与最严重等级
  select pile_id,
         count(*) as open_alert_count,
         case min(case severity
                    when 'critical' then 1
                    when 'high'     then 2
                    when 'medium'   then 3
                    else 4
                  end)
              when 1 then 'critical'
              when 2 then 'high'
              when 3 then 'medium'
              else 'low'
         end as worst_severity
  from device_alert
  where status <> 'recovered'
  group by pile_id
) a on a.pile_id = p.pile_id
left join (
  -- 每桩最近一条采样：以自增 sample_id 代表"最后入库"，避免同毫秒多条采样产生重复行
  select dr.pile_id, dr.power_kw, dr.module_temperature_c, dr.sampled_at
  from device_reading dr
  join (
    select pile_id, max(sample_id) as last_sample_id
    from device_reading
    group by pile_id
  ) m on m.last_sample_id = dr.sample_id
) r on r.pile_id = p.pile_id;

-- -------------------------------------------------------------
-- V2 告警响应超时明细视图
-- 用途：客服/管理员核查"哪条告警超时、超了多久、谁在处理"。
-- 粒度：一行 = 一条告警 × 一次派单；一条告警多次派单会出现多行（C02 的 1:N）。
--      未派单的告警也会保留一行，work_order_* 为 NULL。
-- 判定：首次接单时间为 accepted 事件的最早时间；
--      超时 = 接单时间晚于 response_due_at，或未接单且当前时间已过截止。
-- -------------------------------------------------------------
create or replace view v_alert_response_detail as
select
  a.alert_id,
  a.pile_id,
  p.serial_no,
  p.station_id,
  s.station_name,
  a.gun_id,
  a.alert_code,
  a.severity,
  a.occurred_at,
  a.status                                    as alert_status,
  a.response_seconds_snapshot,
  w.work_order_id,
  w.assigned_to,
  acc.username                                as assignee_username,
  w.assigned_at,
  w.response_due_at,
  w.status                                    as work_order_status,
  w.escalation_level,
  e.first_accepted_at,
  timestampdiff(second, a.occurred_at,
                coalesce(e.first_accepted_at, utc_timestamp()))  as response_seconds_actual,
  case
    when w.work_order_id is null then 0
    when e.first_accepted_at is null and utc_timestamp() > w.response_due_at then 1
    when e.first_accepted_at > w.response_due_at then 1
    else 0
  end                                         as is_overdue,
  a.normal_since_at,
  a.recovered_at,
  timestampdiff(second, a.occurred_at, a.recovered_at)  as total_seconds
from device_alert a
join charging_pile p
  on p.pile_id = a.pile_id
join station s
  on s.station_id = p.station_id
left join work_order w
  on w.alert_id = a.alert_id
left join sys_account acc
  on acc.account_id = w.assigned_to
left join (
  select work_order_id,
         min(case when event_type = 'accepted' then event_at end) as first_accepted_at
  from work_order_event
  group by work_order_id
) e on e.work_order_id = w.work_order_id;

-- -------------------------------------------------------------
-- V3 工单全流程进度视图
-- 用途：工单列表/详情的耗时看板，也是 C03「逐项回填各时间节点」的投影。
-- 口径：首次到场取最早 arrived；本轮最后修复取 max(repaired)（review_failed 后的再次修复会刷新）；
--      闭环取 max(closed)；各段耗时单位为秒，未发生的节点为 NULL。
-- -------------------------------------------------------------
create or replace view v_work_order_progress as
select
  w.work_order_id,
  w.alert_id,
  a.alert_code,
  a.severity,
  a.pile_id,
  p.serial_no,
  s.station_name,
  w.assigned_to,
  w.assigned_by,
  w.assigned_at,
  w.response_due_at,
  w.status                                    as work_order_status,
  w.escalation_level,
  w.parts_used,
  w.result,
  e.first_accepted_at,
  e.first_arrived_at,
  e.last_repaired_at,
  e.first_review_passed_at,
  e.closed_at,
  e.review_failed_count,
  e.escalated_count,
  timestampdiff(second, w.assigned_at,      e.first_accepted_at)  as accept_seconds,
  timestampdiff(second, e.first_accepted_at, e.first_arrived_at)   as arrive_seconds,
  timestampdiff(second, e.first_arrived_at,  e.last_repaired_at)   as repair_seconds,
  timestampdiff(second, e.last_repaired_at,  e.closed_at)          as review_seconds,
  timestampdiff(second, w.assigned_at,       e.closed_at)          as total_seconds,
  case
    when e.first_accepted_at is null then
         case when utc_timestamp() > w.response_due_at then 1 else 0 end
    when e.first_accepted_at > w.response_due_at then 1
    else 0
  end                                         as accept_overdue
from work_order w
join device_alert a
  on a.alert_id = w.alert_id
join charging_pile p
  on p.pile_id = a.pile_id
join station s
  on s.station_id = p.station_id
left join (
  select work_order_id,
         min(case when event_type = 'accepted'      then event_at end) as first_accepted_at,
         min(case when event_type = 'arrived'       then event_at end) as first_arrived_at,
         max(case when event_type = 'repaired'      then event_at end) as last_repaired_at,
         min(case when event_type = 'review_passed' then event_at end) as first_review_passed_at,
         max(case when event_type = 'closed'        then event_at end) as closed_at,
         sum(case when event_type = 'review_failed' then 1 else 0 end) as review_failed_count,
         sum(case when event_type = 'escalated'     then 1 else 0 end) as escalated_count
  from work_order_event
  group by work_order_id
) e on e.work_order_id = w.work_order_id;
