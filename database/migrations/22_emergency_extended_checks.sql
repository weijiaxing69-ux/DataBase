-- 应急场景扩充后的抽检：逐表行数 + 关键一致性
set names utf8mb4;

select 'incident' as tbl, count(*) as rows_now from `incident`
union all select 'incident_alert', count(*) from `incident_alert`
union all select 'incident_action', count(*) from `incident_action`
union all select 'on_call_shift', count(*) from `on_call_shift`
union all select 'escalation_policy', count(*) from `escalation_policy`
union all select 'incident_escalation', count(*) from `incident_escalation`
union all select 'postmortem', count(*) from `postmortem`
union all select 'action_item', count(*) from `action_item`
union all select 'spare_part', count(*) from `spare_part`
union all select 'part_usage', count(*) from `part_usage`
union all select 'part_stock_movement', count(*) from `part_stock_movement`;

-- 事件时间线顺序、复盘覆盖、库存不为负，均应返回 0
select
  (select count(*) from `incident`
    where `declared_at` < `detected_at`
       or `contained_at` < `declared_at`
       or `restored_at` < `contained_at`
       or `closed_at` < `restored_at`) as bad_timeline,
  (select count(*) from `incident` i
    where i.`status` = 'closed'
      and not exists (select 1 from `postmortem` p where p.`incident_id` = i.`incident_id`)) as closed_without_review,
  (select count(*) from `spare_part` where `stock_qty` < `safety_stock`) as below_safety_stock;

-- 演练备件的最后一笔流水余额应等于当前库存，防止重复执行种子脚本后账实不符
select count(*) as stock_movement_mismatch
  from `spare_part` sp
  join (
    select part_id, max(movement_id) as last_movement_id
      from `part_stock_movement`
     group by part_id
  ) m on m.part_id = sp.part_id
  join `part_stock_movement` mv on mv.movement_id = m.last_movement_id
 where sp.part_id between 904 and 921
   and mv.balance_after <> sp.stock_qty;
