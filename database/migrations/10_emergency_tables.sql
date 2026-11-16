-- =============================================================
-- maintenance 模块 · V1.5 应急响应增强（增量表）
-- 定位：在任务书 2.1.3 原有"告警→工单"链条之上，补一层"事件级"处置能力。
-- 原则：**不修改已定稿的 65 张表**，全部为新增表，可单独启用/停用。
-- 依赖：operator / station / charging_pile / charging_gun / device_alert /
--       work_order / sys_account（均已存在）
-- 执行顺序：10 → 11（对象）→ 12（场景数据）→ 13（验收）
-- 编码：UTF-8；时区 UTC；金额 decimal(14,2)；时间 datetime(3)
-- =============================================================

set names utf8mb4;
set time_zone = '+00:00';

-- -------------------------------------------------------------
-- 1. 应急事件主表
--    把"同一场站/同一运营商、同一类根因"的多条告警收敛成一个事件，
--    事件有独立生命周期与指挥人，与单条告警的处置粒度分开。
-- -------------------------------------------------------------
create table `incident` (
  `incident_id` bigint unsigned not null auto_increment comment '主键',
  `incident_no` varchar(32) not null comment '事件编号 INC-YYYYMMDD-NNNN',
  `operator_id` bigint unsigned not null comment '所属运营商',
  `station_id` bigint unsigned null default null comment '场站级事件；跨场站事件留空',
  `category` varchar(32) not null comment '根因类别',
  `severity` varchar(8) not null comment '事件级别 P1-P4',
  `title` varchar(200) not null comment '事件标题',
  `status` varchar(32) not null default 'detected' comment '事件状态',
  `detected_at` datetime(3) not null comment '最早发现时间',
  `declared_at` datetime(3) null default null comment '宣布事件时间',
  `contained_at` datetime(3) null default null comment '影响受控时间',
  `restored_at` datetime(3) null default null comment '业务恢复时间',
  `closed_at` datetime(3) null default null comment '事件关闭时间',
  `commander_account_id` bigint unsigned null default null comment '现场指挥账号',
  `impact_pile_count` int unsigned not null default 0 comment '影响桩数快照',
  `impact_order_count` int unsigned not null default 0 comment '影响订单数快照',
  `estimated_loss_amount` decimal(14,2) not null default 0.00 comment '预估损失金额',
  `escalation_level` int unsigned not null default 0 comment '已达到的最高通知层级 L1=1 L2=2 L3=3',
  `summary` varchar(1000) null default null comment '事件概述/关闭说明',
  `created_at` datetime(3) not null default current_timestamp(3) comment 'UTC创建时间',
  `updated_at` datetime(3) not null default current_timestamp(3) on update current_timestamp(3) comment 'UTC最后修改时间',
  `active_key` varchar(96) generated always as (
      case when `status` in ('detected', 'declared', 'contained')
           then concat(`operator_id`, ':', coalesce(`station_id`, 0), ':', `category`)
           else null end) stored comment '进行中事件唯一键：同运营商同场站同类别不并行两个事件',
  primary key (`incident_id`),
  unique key `uq_incident_no` (`incident_no`),
  unique key `uq_incident_active_key` (`active_key`),
  key `ix_incident_status_severity_detected` (`status`, `severity`, `detected_at`),
  key `ix_incident_station_detected` (`station_id`, `detected_at`),
  key `ix_incident_operator_detected` (`operator_id`, `detected_at`),
  constraint `ck_incident_1` check (`severity` in ('P1', 'P2', 'P3', 'P4')),
  constraint `ck_incident_2` check (`category` in ('power', 'communication', 'hardware', 'software', 'security', 'other')),
  constraint `ck_incident_3` check (`status` in ('detected', 'declared', 'contained', 'restored', 'reviewed', 'closed', 'cancelled')),
  constraint `ck_incident_4` check (`declared_at` is null or `declared_at` >= `detected_at`),
  constraint `ck_incident_5` check (`contained_at` is null or `declared_at` is null or `contained_at` >= `declared_at`),
  constraint `ck_incident_6` check (`restored_at` is null or `contained_at` is null or `restored_at` >= `contained_at`),
  constraint `ck_incident_7` check (`closed_at` is null or `restored_at` is null or `closed_at` >= `restored_at`)
) engine=InnoDB default charset=utf8mb4 collate=utf8mb4_0900_ai_ci comment='应急事件';

-- -------------------------------------------------------------
-- 2. 事件—告警关联
--    一条告警最多归属一个事件（业务上不应同时出现在两个事件里），
--    一个事件可聚合多条告警，并标记根因告警。
-- -------------------------------------------------------------
create table `incident_alert` (
  `incident_id` bigint unsigned not null comment '事件',
  `alert_id` bigint unsigned not null comment '告警',
  `linked_at` datetime(3) not null comment '关联时间',
  `linked_by` bigint unsigned null default null comment '手工关联账号；系统聚合为空',
  `is_root_cause` tinyint unsigned not null default 0 comment '是否根因告警',
  `created_at` datetime(3) not null default current_timestamp(3) comment 'UTC创建时间',
  `updated_at` datetime(3) not null default current_timestamp(3) on update current_timestamp(3) comment 'UTC最后修改时间',
  primary key (`incident_id`, `alert_id`),
  unique key `uq_incident_alert_alert_id` (`alert_id`),
  constraint `ck_incident_alert_1` check (`is_root_cause` in (0, 1))
) engine=InnoDB default charset=utf8mb4 collate=utf8mb4_0900_ai_ci comment='事件告警关联';

-- -------------------------------------------------------------
-- 3. 处置动作流水（隔离、切枪、派单、通知、恢复、关闭全部留痕）
--    target_id 是多态引用，不建物理外键，由 action_type 决定指向哪张表。
-- -------------------------------------------------------------
create table `incident_action` (
  `action_id` bigint unsigned not null auto_increment comment '主键',
  `incident_id` bigint unsigned not null comment '事件',
  `action_type` varchar(32) not null comment '动作类型',
  `target_type` varchar(16) not null default 'none' comment '动作对象类型',
  `target_id` bigint unsigned null default null comment '动作对象编号；多态引用不建外键',
  `action_at` datetime(3) not null comment '动作时间',
  `actor_account_id` bigint unsigned null default null comment '执行账号；系统为空',
  `approved_by` bigint unsigned null default null comment '审批账号；高危动作必填',
  `reason` varchar(500) null default null comment '动作依据',
  `result` varchar(500) null default null comment '执行结果',
  `created_at` datetime(3) not null default current_timestamp(3) comment 'UTC创建时间',
  `updated_at` datetime(3) not null default current_timestamp(3) on update current_timestamp(3) comment 'UTC最后修改时间',
  primary key (`action_id`),
  key `ix_incident_action_incident_at` (`incident_id`, `action_at`),
  constraint `ck_incident_action_1` check (`action_type` in ('declare','link_alert','notify','dispatch','isolate_station','isolate_pile','switch_gun','pause_orders','resume_orders','restore','review','close','cancel','escalate')),
  constraint `ck_incident_action_2` check (`target_type` in ('none', 'station', 'pile', 'gun', 'order', 'account')),
  constraint `ck_incident_action_3` check (`target_type` = 'none' or `target_id` is not null)
) engine=InnoDB default charset=utf8mb4 collate=utf8mb4_0900_ai_ci comment='事件处置动作';

-- -------------------------------------------------------------
-- 4. 值班班次（派单兜底与自动改派的基础）
--    scope_id 多态：scope_type='station' 指场站，'operator' 指运营商。
--    班次重叠由 Service 校验，DB 只保证同一对象同一开始时刻唯一。
-- -------------------------------------------------------------
create table `on_call_shift` (
  `shift_id` bigint unsigned not null auto_increment comment '主键',
  `scope_type` varchar(16) not null comment '值班范围类型',
  `scope_id` bigint unsigned not null comment '场站或运营商编号；多态引用',
  `shift_start` datetime(3) not null comment '班次开始',
  `shift_end` datetime(3) not null comment '班次结束',
  `primary_account_id` bigint unsigned not null comment '主值班',
  `backup_account_id` bigint unsigned null default null comment '备班',
  `supervisor_account_id` bigint unsigned null default null comment '值班主管',
  `status` varchar(16) not null default 'planned' comment '班次状态',
  `note` varchar(500) null default null comment '交接说明',
  `created_at` datetime(3) not null default current_timestamp(3) comment 'UTC创建时间',
  `updated_at` datetime(3) not null default current_timestamp(3) on update current_timestamp(3) comment 'UTC最后修改时间',
  primary key (`shift_id`),
  unique key `uq_on_call_shift_scope_start` (`scope_type`, `scope_id`, `shift_start`),
  key `ix_on_call_shift_window` (`shift_start`, `shift_end`),
  constraint `ck_on_call_shift_1` check (`scope_type` in ('station', 'operator')),
  constraint `ck_on_call_shift_2` check (`status` in ('planned', 'active', 'ended')),
  constraint `ck_on_call_shift_3` check (`shift_end` > `shift_start`),
  constraint `ck_on_call_shift_4` check (`backup_account_id` is null or `backup_account_id` <> `primary_account_id`)
) engine=InnoDB default charset=utf8mb4 collate=utf8mb4_0900_ai_ci comment='值班班次';

-- -------------------------------------------------------------
-- 5. 事件 SLA 基线（按级别固定，不随事件变化，避免把标准写死在视图里）
-- -------------------------------------------------------------
create table `incident_sla` (
  `severity` varchar(8) not null comment '事件级别',
  `ack_seconds` int unsigned not null comment '宣布事件的时限秒',
  `restore_seconds` int unsigned not null comment '业务恢复时限秒',
  `description` varchar(200) null default null comment '说明',
  `created_at` datetime(3) not null default current_timestamp(3) comment 'UTC创建时间',
  `updated_at` datetime(3) not null default current_timestamp(3) on update current_timestamp(3) comment 'UTC最后修改时间',
  primary key (`severity`),
  constraint `ck_incident_sla_1` check (`severity` in ('P1', 'P2', 'P3', 'P4')),
  constraint `ck_incident_sla_2` check (`ack_seconds` > 0),
  constraint `ck_incident_sla_3` check (`restore_seconds` >= `ack_seconds`)
) engine=InnoDB default charset=utf8mb4 collate=utf8mb4_0900_ai_ci comment='事件SLA基线';

-- -------------------------------------------------------------
-- 6. 升级策略矩阵（级别 × 持续时长 × 影响面 → 通知层级与动作）
--    applies_severity='ANY' 表示不限级别；同一事件同一策略只触发一次。
-- -------------------------------------------------------------
create table `escalation_policy` (
  `policy_id` bigint unsigned not null auto_increment comment '主键',
  `policy_code` varchar(50) not null comment '策略码',
  `applies_severity` varchar(8) not null default 'ANY' comment '适用级别',
  `min_duration_seconds` int unsigned not null default 0 comment '持续时长门槛',
  `min_impact_piles` int unsigned not null default 0 comment '影响桩数门槛',
  `notify_level` varchar(8) not null comment '通知层级',
  `action_code` varchar(32) not null comment '建议动作',
  `enabled` tinyint unsigned not null default 1 comment '是否启用',
  `created_at` datetime(3) not null default current_timestamp(3) comment 'UTC创建时间',
  `updated_at` datetime(3) not null default current_timestamp(3) on update current_timestamp(3) comment 'UTC最后修改时间',
  primary key (`policy_id`),
  unique key `uq_escalation_policy_code` (`policy_code`),
  constraint `ck_escalation_policy_1` check (`applies_severity` in ('P1','P2','P3','P4','ANY')),
  constraint `ck_escalation_policy_2` check (`notify_level` in ('L1','L2','L3')),
  constraint `ck_escalation_policy_3` check (`action_code` in ('notify_supervisor','notify_operator','dispatch_backup','suggest_isolate','pause_orders','declare_incident')),
  constraint `ck_escalation_policy_4` check (`enabled` in (0,1))
) engine=InnoDB default charset=utf8mb4 collate=utf8mb4_0900_ai_ci comment='升级策略矩阵';

-- 7. 升级触发记录（证据链：谁在什么时候被通知、是否确认）
create table `incident_escalation` (
  `escalation_id` bigint unsigned not null auto_increment comment '主键',
  `incident_id` bigint unsigned not null comment '事件',
  `policy_id` bigint unsigned not null comment '命中的策略',
  `notify_level` varchar(8) not null comment '通知层级快照',
  `triggered_at` datetime(3) not null comment '触发时间',
  `notified_account_id` bigint unsigned null default null comment '被通知账号',
  `ack_at` datetime(3) null default null comment '确认时间',
  `note` varchar(500) null default null comment '备注',
  `created_at` datetime(3) not null default current_timestamp(3) comment 'UTC创建时间',
  `updated_at` datetime(3) not null default current_timestamp(3) on update current_timestamp(3) comment 'UTC最后修改时间',
  primary key (`escalation_id`),
  unique key `uq_incident_escalation_once` (`incident_id`, `policy_id`),
  key `ix_incident_escalation_time` (`triggered_at`),
  constraint `ck_incident_escalation_1` check (`notify_level` in ('L1','L2','L3'))
) engine=InnoDB default charset=utf8mb4 collate=utf8mb4_0900_ai_ci comment='事件升级记录';

-- -------------------------------------------------------------
-- 8. 复盘报告（一个事件一份；关闭事件的前置条件）
--    detection/response/recovery_seconds 是从事件时间线固化下来的审计快照，
--    允许保留冗余，理由见 3NF 说明文档。
-- -------------------------------------------------------------
create table `postmortem` (
  `postmortem_id` bigint unsigned not null auto_increment comment '主键',
  `incident_id` bigint unsigned not null comment '事件，一对一',
  `root_cause_category` varchar(32) not null comment '根因类别',
  `root_cause` varchar(1000) not null comment '根因描述',
  `detection_seconds` int unsigned null default null comment '发现耗时快照',
  `response_seconds` int unsigned null default null comment '响应耗时快照',
  `recovery_seconds` int unsigned null default null comment '恢复耗时快照',
  `prevention` varchar(1000) null default null comment '预防措施',
  `reviewer_account_id` bigint unsigned null default null comment '审核账号',
  `reviewed_at` datetime(3) null default null comment '审核时间',
  `status` varchar(16) not null default 'draft' comment '复盘状态',
  `created_at` datetime(3) not null default current_timestamp(3) comment 'UTC创建时间',
  `updated_at` datetime(3) not null default current_timestamp(3) on update current_timestamp(3) comment 'UTC最后修改时间',
  primary key (`postmortem_id`),
  unique key `uq_postmortem_incident_id` (`incident_id`),
  constraint `ck_postmortem_1` check (`root_cause_category` in ('configuration','hardware','power','network','software','process','external','unknown')),
  constraint `ck_postmortem_2` check (`status` in ('draft','reviewed','approved')),
  constraint `ck_postmortem_3` check (`status` = 'draft' or `reviewer_account_id` is not null)
) engine=InnoDB default charset=utf8mb4 collate=utf8mb4_0900_ai_ci comment='事件复盘';

-- 9. 整改项（复盘产出的可追踪任务）
create table `action_item` (
  `item_id` bigint unsigned not null auto_increment comment '主键',
  `postmortem_id` bigint unsigned not null comment '来源复盘',
  `description` varchar(500) not null comment '整改内容',
  `owner_account_id` bigint unsigned not null comment '责任人',
  `due_date` date not null comment '期限',
  `status` varchar(16) not null default 'open' comment '整改状态',
  `verified_at` datetime(3) null default null comment '验收时间',
  `verified_by` bigint unsigned null default null comment '验收账号',
  `created_at` datetime(3) not null default current_timestamp(3) comment 'UTC创建时间',
  `updated_at` datetime(3) not null default current_timestamp(3) on update current_timestamp(3) comment 'UTC最后修改时间',
  primary key (`item_id`),
  key `ix_action_item_owner_status_due` (`owner_account_id`, `status`, `due_date`),
  constraint `ck_action_item_1` check (`status` in ('open','done','verified','overdue')),
  constraint `ck_action_item_2` check (`status` <> 'verified' or (`verified_by` is not null and `verified_at` is not null))
) engine=InnoDB default charset=utf8mb4 collate=utf8mb4_0900_ai_ci comment='整改项';

-- -------------------------------------------------------------
-- 10-11. 抢修备件与领用（把原 work_order.parts_used 自由文本结构化）
-- -------------------------------------------------------------
create table `spare_part` (
  `part_id` bigint unsigned not null auto_increment comment '主键',
  `part_code` varchar(50) not null comment '备件编码',
  `part_name` varchar(100) not null comment '备件名称',
  `model` varchar(100) null default null comment '规格型号',
  `unit` varchar(16) not null default '个' comment '计量单位',
  `station_id` bigint unsigned null default null comment '存放场站；空表示中心库',
  `stock_qty` int unsigned not null default 0 comment '当前库存',
  `safety_stock` int unsigned not null default 0 comment '安全库存',
  `status` varchar(16) not null default 'active' comment '启用状态',
  `created_at` datetime(3) not null default current_timestamp(3) comment 'UTC创建时间',
  `updated_at` datetime(3) not null default current_timestamp(3) on update current_timestamp(3) comment 'UTC最后修改时间',
  primary key (`part_id`),
  unique key `uq_spare_part_code_station` (`part_code`, `station_id`),
  key `ix_spare_part_stock` (`station_id`, `stock_qty`),
  constraint `ck_spare_part_1` check (`status` in ('active','disabled')),
  constraint `ck_spare_part_2` check (`stock_qty` >= 0),
  constraint `ck_spare_part_3` check (`safety_stock` >= 0)
) engine=InnoDB default charset=utf8mb4 collate=utf8mb4_0900_ai_ci comment='抢修备件';

create table `part_usage` (
  `usage_id` bigint unsigned not null auto_increment comment '主键',
  `work_order_id` bigint unsigned not null comment '工单',
  `part_id` bigint unsigned not null comment '备件',
  `qty` int unsigned not null comment '领用数量',
  `used_at` datetime(3) not null comment '领用时间',
  `used_by` bigint unsigned not null comment '领用人',
  `note` varchar(500) null default null comment '用途说明',
  `created_at` datetime(3) not null default current_timestamp(3) comment 'UTC创建时间',
  `updated_at` datetime(3) not null default current_timestamp(3) on update current_timestamp(3) comment 'UTC最后修改时间',
  primary key (`usage_id`),
  unique key `uq_part_usage_order_part` (`work_order_id`, `part_id`),
  key `ix_part_usage_part_used_at` (`part_id`, `used_at`),
  constraint `ck_part_usage_1` check (`qty` > 0)
) engine=InnoDB default charset=utf8mb4 collate=utf8mb4_0900_ai_ci comment='备件领用';

-- -------------------------------------------------------------
-- 外键（全部指向已存在或被本文件先建的表）
-- -------------------------------------------------------------
alter table `incident` add constraint `fk_incident_operator_id` foreign key (`operator_id`) references `operator` (`operator_id`) on delete restrict on update restrict;
alter table `incident` add constraint `fk_incident_station_id` foreign key (`station_id`) references `station` (`station_id`) on delete restrict on update restrict;
alter table `incident` add constraint `fk_incident_commander` foreign key (`commander_account_id`) references `sys_account` (`account_id`) on delete restrict on update restrict;
alter table `incident_alert` add constraint `fk_incident_alert_incident` foreign key (`incident_id`) references `incident` (`incident_id`) on delete restrict on update restrict;
alter table `incident_alert` add constraint `fk_incident_alert_alert` foreign key (`alert_id`) references `device_alert` (`alert_id`) on delete restrict on update restrict;
alter table `incident_alert` add constraint `fk_incident_alert_linked_by` foreign key (`linked_by`) references `sys_account` (`account_id`) on delete restrict on update restrict;
alter table `incident_action` add constraint `fk_incident_action_incident` foreign key (`incident_id`) references `incident` (`incident_id`) on delete restrict on update restrict;
alter table `incident_action` add constraint `fk_incident_action_actor` foreign key (`actor_account_id`) references `sys_account` (`account_id`) on delete restrict on update restrict;
alter table `incident_action` add constraint `fk_incident_action_approver` foreign key (`approved_by`) references `sys_account` (`account_id`) on delete restrict on update restrict;
alter table `on_call_shift` add constraint `fk_on_call_shift_primary` foreign key (`primary_account_id`) references `sys_account` (`account_id`) on delete restrict on update restrict;
alter table `on_call_shift` add constraint `fk_on_call_shift_backup` foreign key (`backup_account_id`) references `sys_account` (`account_id`) on delete restrict on update restrict;
alter table `on_call_shift` add constraint `fk_on_call_shift_supervisor` foreign key (`supervisor_account_id`) references `sys_account` (`account_id`) on delete restrict on update restrict;
alter table `incident_escalation` add constraint `fk_incident_escalation_incident` foreign key (`incident_id`) references `incident` (`incident_id`) on delete restrict on update restrict;
alter table `incident_escalation` add constraint `fk_incident_escalation_policy` foreign key (`policy_id`) references `escalation_policy` (`policy_id`) on delete restrict on update restrict;
alter table `incident_escalation` add constraint `fk_incident_escalation_account` foreign key (`notified_account_id`) references `sys_account` (`account_id`) on delete restrict on update restrict;
alter table `postmortem` add constraint `fk_postmortem_incident` foreign key (`incident_id`) references `incident` (`incident_id`) on delete restrict on update restrict;
alter table `postmortem` add constraint `fk_postmortem_reviewer` foreign key (`reviewer_account_id`) references `sys_account` (`account_id`) on delete restrict on update restrict;
alter table `action_item` add constraint `fk_action_item_postmortem` foreign key (`postmortem_id`) references `postmortem` (`postmortem_id`) on delete restrict on update restrict;
alter table `action_item` add constraint `fk_action_item_owner` foreign key (`owner_account_id`) references `sys_account` (`account_id`) on delete restrict on update restrict;
alter table `action_item` add constraint `fk_action_item_verifier` foreign key (`verified_by`) references `sys_account` (`account_id`) on delete restrict on update restrict;
alter table `spare_part` add constraint `fk_spare_part_station` foreign key (`station_id`) references `station` (`station_id`) on delete restrict on update restrict;
alter table `part_usage` add constraint `fk_part_usage_work_order` foreign key (`work_order_id`) references `work_order` (`work_order_id`) on delete restrict on update restrict;
alter table `part_usage` add constraint `fk_part_usage_part` foreign key (`part_id`) references `spare_part` (`part_id`) on delete restrict on update restrict;
alter table `part_usage` add constraint `fk_part_usage_user` foreign key (`used_by`) references `sys_account` (`account_id`) on delete restrict on update restrict;
