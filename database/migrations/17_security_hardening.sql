-- =============================================================
-- 维护模块 · 安全加固（可重复执行）
-- 1) 补齐 maintenance 的细粒度权限码，并按角色授权
-- 2) 采样表加 (pile_id, sampled_at) 唯一键，挡住并发重复上报
-- 说明：不修改任何已有列；权限用 INSERT ... WHERE NOT EXISTS，索引先判断是否存在。
-- =============================================================

set names utf8mb4;

-- -------------------------------------------------------------
-- 1. 权限码
-- -------------------------------------------------------------
insert into `sys_permission` (`permission_code`, `permission_name`)
select v.code, v.name from (
  select 'maintenance.rule.manage'        as code, '配置告警规则与响应时限'   as name union all
  select 'maintenance.inspection.read',            '查看巡检记录'            union all
  select 'maintenance.inspection.create',          '新增巡检记录'            union all
  select 'maintenance.fault_report.read',          '查看用户报障'            union all
  select 'maintenance.fault_report.handle',        '处理用户报障'            union all
  select 'maintenance.incident.manage',            '声明与关闭应急事件'
) v
where not exists (select 1 from `sys_permission` p where p.permission_code = v.code);

-- -------------------------------------------------------------
-- 2. 角色授权（同一角色同一权限只插一次）
-- -------------------------------------------------------------
insert ignore into `sys_role_permission` (`role_id`, `permission_id`)
select r.role_id, p.permission_id
  from `sys_role` r
  join `sys_permission` p
    on (r.role_code = 'platform_admin'
        and p.permission_code in ('maintenance.rule.manage','maintenance.inspection.read',
                                  'maintenance.inspection.create','maintenance.fault_report.read',
                                  'maintenance.fault_report.handle','maintenance.incident.manage'))
    or (r.role_code = 'maintenance_engineer'
        and p.permission_code in ('maintenance.inspection.read','maintenance.inspection.create',
                                  'maintenance.fault_report.read'))
    or (r.role_code = 'customer_service'
        and p.permission_code in ('maintenance.fault_report.read','maintenance.fault_report.handle'));

-- -------------------------------------------------------------
-- 3. 采样唯一键：同一桩同一采样时刻只允许一条
--    分区表要求唯一键包含全部分区列，这里 (pile_id, sampled_at) 正好覆盖。
-- -------------------------------------------------------------
set @exists := (
  select count(*) from information_schema.statistics
   where table_schema = database() and table_name = 'device_reading'
     and index_name = 'uq_device_reading_pile_sampled'
);
set @sql := if(@exists = 0,
  'alter table device_reading add unique key uq_device_reading_pile_sampled (pile_id, sampled_at)',
  'select ''uq_device_reading_pile_sampled already exists'' as skipped');
prepare stmt from @sql; execute stmt; deallocate prepare stmt;

select 'security hardening applied' as status;
