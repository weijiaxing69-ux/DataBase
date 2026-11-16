-- =============================================================
-- maintenance 模块 · 关键业务查询（3 题 × 2 种写法）
-- 任务书 3.2：5 条连接 3 个及以上关系的 SQL；报告模板：每业务 3 条、每题 2 种实现并对比差异
-- 数据集：V1.4 种子 20 桩 + 本模块场景数据 5 条告警 / 6 条工单
-- 观察方法：在语句前加 explain / explain analyze 对比 type、rows、filtered 与 Extra
-- 说明：当前数据量小（每表 20 行级），优化器可能选择相同计划；
--       报告里应写清"数据量放大到 10 万行时的差异"，而不是只贴小表结果。
-- =============================================================

set names utf8mb4;

-- -------------------------------------------------------------
-- Q1 统计各场站近 30 天告警量、派单量、超时派单数与平均响应时长
--    涉及：station、charging_pile、device_alert、work_order、work_order_event（5 个关系）
-- -------------------------------------------------------------

-- Q1-A 相关子查询写法：每行工单执行一次事件子查询，语义直观，工单多时子查询次数线性增长
select
  s.station_id,
  s.station_name,
  count(distinct a.alert_id)                                   as alert_count,
  count(w.work_order_id)                                       as dispatch_count,
  sum(case
        when w.work_order_id is not null
         and coalesce((select min(ev.event_at)
                         from work_order_event ev
                        where ev.work_order_id = w.work_order_id
                          and ev.event_type = 'accepted'),
                      utc_timestamp()) > w.response_due_at
        then 1 else 0
      end)                                                     as overdue_dispatch,
  round(avg(timestampdiff(second, a.occurred_at,
        (select min(ev.event_at)
           from work_order_event ev
          where ev.work_order_id = w.work_order_id
            and ev.event_type = 'accepted'))), 1)               as avg_response_seconds
from station s
join charging_pile p   on p.station_id = s.station_id
join device_alert a    on a.pile_id = p.pile_id
left join work_order w on w.alert_id = a.alert_id
where a.occurred_at >= utc_timestamp() - interval 30 day
group by s.station_id, s.station_name
order by alert_count desc, s.station_id;

-- Q1-B 预聚合写法：先把事件按工单聚合成"首次接单时间"，只扫一次事件表，再与告警关联汇总
--       事件表放大后优势明显：A 为 N 次索引查找，B 为 1 次分组扫描 + 哈希连接
with first_accept as (
  select work_order_id,
         min(event_at) as first_accepted_at
  from work_order_event
  where event_type = 'accepted'
  group by work_order_id
),
dispatch as (
  select w.work_order_id,
         w.alert_id,
         w.response_due_at,
         fa.first_accepted_at
  from work_order w
  left join first_accept fa on fa.work_order_id = w.work_order_id
)
select
  s.station_id,
  s.station_name,
  count(distinct a.alert_id)                                   as alert_count,
  count(d.work_order_id)                                       as dispatch_count,
  sum(case
        when d.work_order_id is not null
         and coalesce(d.first_accepted_at, utc_timestamp()) > d.response_due_at
        then 1 else 0
      end)                                                     as overdue_dispatch,
  round(avg(timestampdiff(second, a.occurred_at, d.first_accepted_at)), 1) as avg_response_seconds
from station s
join charging_pile p   on p.station_id = s.station_id
join device_alert a    on a.pile_id = p.pile_id
left join dispatch d   on d.alert_id = a.alert_id
where a.occurred_at >= utc_timestamp() - interval 30 day
group by s.station_id, s.station_name
order by alert_count desc, s.station_id;

-- -------------------------------------------------------------
-- Q2 超时未接单工单明细（含超时时长、升级次数、责任人）
--    涉及：work_order、device_alert、charging_pile、station、sys_account、work_order_event（6 个关系）
-- -------------------------------------------------------------

-- Q2-A 依赖工单状态字段：status 仍为 assigned 即视为未接单
--       风险：状态被误改或漏改时查不出问题单，这也是 B 存在的理由
select
  w.work_order_id,
  a.alert_id,
  a.alert_code,
  a.severity,
  p.serial_no,
  s.station_name,
  acc.username                                                as assignee,
  w.assigned_at,
  w.response_due_at,
  w.escalation_level,
  timestampdiff(second, w.response_due_at, utc_timestamp())    as overdue_seconds
from work_order w
join device_alert a   on a.alert_id = w.alert_id
join charging_pile p  on p.pile_id = a.pile_id
join station s        on s.station_id = p.station_id
join sys_account acc  on acc.account_id = w.assigned_to
where w.status = 'assigned'
  and w.response_due_at < utc_timestamp()
order by overdue_seconds desc;

-- Q2-B 事件投影写法：以"不存在 accepted 事件"判定未接单，不信任状态字段
--       口径更严格：即使状态被误改为 accepted，只要没有事件记录仍会出现在清单里
select
  w.work_order_id,
  a.alert_id,
  a.alert_code,
  a.severity,
  p.serial_no,
  s.station_name,
  acc.username                                                as assignee,
  w.assigned_at,
  w.response_due_at,
  (select count(*)
     from work_order_event ev
    where ev.work_order_id = w.work_order_id
      and ev.event_type = 'escalated')                        as escalated_count,
  timestampdiff(second, w.response_due_at, utc_timestamp())    as overdue_seconds
from work_order w
join device_alert a   on a.alert_id = w.alert_id
join charging_pile p  on p.pile_id = a.pile_id
join station s        on s.station_id = p.station_id
join sys_account acc  on acc.account_id = w.assigned_to
where w.response_due_at < utc_timestamp()
  and not exists (
        select 1
          from work_order_event ev
         where ev.work_order_id = w.work_order_id
           and ev.event_type in ('accepted', 'closed')
      )
order by overdue_seconds desc;

-- -------------------------------------------------------------
-- Q3 各桩近 30 天健康度：采样量、平均功率、最高温度、告警数、工单数
--    涉及：device_reading（分区表）、device_alert、work_order、charging_pile、station（5 个关系）
-- -------------------------------------------------------------

-- Q3-A 三次分组后连接：结构清晰，但采样表会被扫描一次、告警与工单各再扫一次
select
  p.pile_id,
  p.serial_no,
  s.station_name,
  coalesce(r.sample_count, 0)          as sample_count,
  coalesce(r.avg_power_kw, 0)          as avg_power_kw,
  r.max_temperature_c,
  coalesce(al.alert_count, 0)          as alert_count,
  coalesce(wo.work_order_count, 0)     as work_order_count
from charging_pile p
join station s on s.station_id = p.station_id
left join (
  select pile_id,
         count(*)                     as sample_count,
         round(avg(power_kw), 3)      as avg_power_kw,
         max(module_temperature_c)    as max_temperature_c
  from device_reading
  where sampled_at >= utc_timestamp() - interval 30 day
  group by pile_id
) r on r.pile_id = p.pile_id
left join (
  select pile_id, count(*) as alert_count
  from device_alert
  where occurred_at >= utc_timestamp() - interval 30 day
  group by pile_id
) al on al.pile_id = p.pile_id
left join (
  select a.pile_id, count(*) as work_order_count
  from work_order w
  join device_alert a on a.alert_id = w.alert_id
  where w.assigned_at >= utc_timestamp() - interval 30 day
  group by a.pile_id
) wo on wo.pile_id = p.pile_id
order by p.pile_id;

-- Q3-B 窗口函数写法：采样明细一次扫描同时算出三个指标，再 distinct 去重
--       注意：窗口函数不能减少扫描量，它省的是"多次分组"和中间结果集，别在报告里说它更快
with reading_metric as (
  select
    pile_id,
    count(*) over (partition by pile_id)                as sample_count,
    avg(power_kw) over (partition by pile_id)           as avg_power_kw,
    max(module_temperature_c) over (partition by pile_id) as max_temperature_c
  from device_reading
  where sampled_at >= utc_timestamp() - interval 30 day
),
reading_agg as (
  select distinct pile_id, sample_count,
         round(avg_power_kw, 3) as avg_power_kw,
         max_temperature_c
  from reading_metric
)
select
  p.pile_id,
  p.serial_no,
  s.station_name,
  coalesce(r.sample_count, 0)          as sample_count,
  coalesce(r.avg_power_kw, 0)          as avg_power_kw,
  r.max_temperature_c,
  coalesce(al.alert_count, 0)          as alert_count,
  coalesce(wo.work_order_count, 0)     as work_order_count
from charging_pile p
join station s on s.station_id = p.station_id
left join reading_agg r on r.pile_id = p.pile_id
left join (
  select pile_id, count(*) as alert_count
  from device_alert
  where occurred_at >= utc_timestamp() - interval 30 day
  group by pile_id
) al on al.pile_id = p.pile_id
left join (
  select a.pile_id, count(*) as work_order_count
  from work_order w
  join device_alert a on a.alert_id = w.alert_id
  where w.assigned_at >= utc_timestamp() - interval 30 day
  group by a.pile_id
) wo on wo.pile_id = p.pile_id
order by p.pile_id;
