-- =============================================================
-- 维护模块 · 备件库存流水（可重复执行）
-- 背景：spare_part.stock_qty 只有领用（触发器扣减），没有入库，
-- 库存只减不增，演示几天就归零。这里加一张流水表，入库与领用都记账。
-- =============================================================

set names utf8mb4;

create table if not exists `part_stock_movement` (
  `movement_id`         bigint unsigned not null auto_increment comment '主键',
  `part_id`             bigint unsigned not null comment '备件编号',
  `movement_type`       varchar(8) not null comment 'in 入库 / out 领用',
  `qty`                 int unsigned not null comment '变动数量',
  `balance_after`       int unsigned not null comment '变动后库存',
  `occurred_at`         datetime(3) not null comment '发生时间',
  `operator_account_id` bigint unsigned null default null comment '操作账号；系统补录为空',
  `note`                varchar(255) null default null comment '说明',
  `created_at`          datetime(3) not null default current_timestamp(3),
  `updated_at`          datetime(3) not null default current_timestamp(3) on update current_timestamp(3),
  primary key (`movement_id`),
  key `ix_part_movement_part_time` (`part_id`, `occurred_at`),
  constraint `fk_part_movement_part` foreign key (`part_id`) references `spare_part` (`part_id`),
  constraint `ck_part_movement_type` check (`movement_type` in ('in', 'out'))
) engine = InnoDB default charset = utf8mb4 comment = '备件库存流水';

-- 历史领用补一份出库流水（只在流水表为空时执行，避免重复）
insert into `part_stock_movement`
  (`part_id`, `movement_type`, `qty`, `balance_after`, `occurred_at`, `operator_account_id`, `note`)
select pu.`part_id`, 'out', pu.`qty`, sp.`stock_qty`, pu.`used_at`, pu.`used_by`, '历史领用补录'
  from `part_usage` pu
  join `spare_part` sp on sp.`part_id` = pu.`part_id`
 where not exists (select 1 from `part_stock_movement` m where m.`part_id` = pu.`part_id`);

select 'part stock movement ready' as status;
