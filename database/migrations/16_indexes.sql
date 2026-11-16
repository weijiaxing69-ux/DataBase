-- =============================================================
-- 维护模块 · 列表查询索引补充（在 EXPLAIN 实测后添加）
-- 背景：告警/工单列表按时间倒序分页，原表只有业务维度索引，走全表 + filesort。
-- 只加索引，不改任何字段与约束；可重复执行（先判断是否存在）。
-- =============================================================

set names utf8mb4;

-- 告警列表：order by occurred_at desc；看板趋势也按时间范围扫描
set @exists := (
  select count(*) from information_schema.statistics
   where table_schema = database() and table_name = 'device_alert'
     and index_name = 'ix_device_alert_occurred_at'
);
set @sql := if(@exists = 0,
  'create index ix_device_alert_occurred_at on device_alert (occurred_at)',
  'select ''ix_device_alert_occurred_at already exists'' as skipped');
prepare stmt from @sql; execute stmt; deallocate prepare stmt;

-- 工单列表：order by assigned_at desc
set @exists := (
  select count(*) from information_schema.statistics
   where table_schema = database() and table_name = 'work_order'
     and index_name = 'ix_work_order_assigned_at'
);
set @sql := if(@exists = 0,
  'create index ix_work_order_assigned_at on work_order (assigned_at)',
  'select ''ix_work_order_assigned_at already exists'' as skipped');
prepare stmt from @sql; execute stmt; deallocate prepare stmt;

-- 巡检列表：order by inspected_at desc
set @exists := (
  select count(*) from information_schema.statistics
   where table_schema = database() and table_name = 'inspection_record'
     and index_name = 'ix_inspection_record_inspected_at'
);
set @sql := if(@exists = 0,
  'create index ix_inspection_record_inspected_at on inspection_record (inspected_at)',
  'select ''ix_inspection_record_inspected_at already exists'' as skipped');
prepare stmt from @sql; execute stmt; deallocate prepare stmt;
