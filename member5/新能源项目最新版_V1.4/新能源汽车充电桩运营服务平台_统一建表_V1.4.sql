-- 新能源平台统一建表 V1.4 2026-11-13
-- 与同名规范及JSON同源生成。仅创建开发库结构，不包含种子数据和完整业务过程。
-- 尚未连接MySQL执行验证；须由组长先在空库执行，再运行各模块规则和并发测试。
-- 不含drop；非空旧库请先备份并单独编写迁移，不能覆盖已有表。
set names utf8mb4 collate utf8mb4_0900_ai_ci;
set time_zone = '+00:00';
create database if not exists charging_platform character set utf8mb4 collate utf8mb4_0900_ai_ci;
use charging_platform;
-- 建表阶段：先创建全部表，最后统一添加跨模块外键。

-- assets / 运营商
create table `operator` (
  `operator_id` bigint unsigned not null auto_increment comment '主键',
  `operator_name` varchar(100) not null comment '运营商名称',
  `credit_code` varchar(18) not null comment '统一社会信用代码',
  `contact_name` varchar(50) not null comment '联系人',
  `contact_phone_cipher` varbinary(512) not null comment '联系电话密文',
  `status` varchar(32) not null default 'active' comment '启用状态',
  `created_at` datetime(3) not null default current_timestamp(3) comment 'UTC创建时间',
  `updated_at` datetime(3) not null default current_timestamp(3) on update current_timestamp(3) comment 'UTC最后修改时间',
  primary key (`operator_id`),
  unique key `uq_operator_credit_code` (`credit_code`),
  constraint `ck_operator_1` check (`status` in ('active', 'disabled'))
) engine=InnoDB default charset=utf8mb4 collate=utf8mb4_0900_ai_ci;

-- assets / 场站
create table `station` (
  `station_id` bigint unsigned not null auto_increment comment '主键',
  `operator_id` bigint unsigned not null comment '所属运营商',
  `station_name` varchar(100) not null comment '场站名称',
  `address` varchar(255) not null comment '地址',
  `longitude` decimal(10,7) not null comment '经度',
  `latitude` decimal(10,7) not null comment '纬度',
  `parking_spaces` int unsigned not null default 0 comment '车位数量',
  `business_hours` varchar(100) not null default '00:00-24:00' comment '营业时间展示文本',
  `parking_fee_standard` varchar(255) not null default '按场站公示标准' comment '停车费说明 不并入充电费',
  `status` varchar(32) not null default 'draft' comment '场站生命周期',
  `created_at` datetime(3) not null default current_timestamp(3) comment 'UTC创建时间',
  `updated_at` datetime(3) not null default current_timestamp(3) on update current_timestamp(3) comment 'UTC最后修改时间',
  primary key (`station_id`),
  key `ix_station_operator_id_status` (`operator_id`, `status`),
  constraint `ck_station_1` check (longitude between -180 and 180),
  constraint `ck_station_2` check (latitude between -90 and 90),
  constraint `ck_station_3` check (`status` in ('draft', 'active', 'suspended', 'retired'))
) engine=InnoDB default charset=utf8mb4 collate=utf8mb4_0900_ai_ci;

-- assets / 充电桩
create table `charging_pile` (
  `pile_id` bigint unsigned not null auto_increment comment '主键',
  `station_id` bigint unsigned not null comment '所属场站',
  `serial_no` varchar(64) not null comment '铭牌设备序列号',
  `model_name` varchar(100) not null comment '设备型号',
  `rated_power_kw` decimal(10,3) not null comment '整桩额定功率kW',
  `protocol` varchar(50) not null comment '模拟或接入协议名称',
  `commissioned_on` date null default null comment '投运日期',
  `warranty_until` date null default null comment '质保截止',
  `lifecycle_status` varchar(32) not null default 'draft' comment '投运验收状态',
  `status` varchar(32) not null default 'offline' comment '当前设备状态',
  `has_fault` tinyint unsigned not null default 0 comment '保留故障事实 不因离线清除',
  `is_online` tinyint unsigned not null default 0 comment '通信在线事实',
  `last_heartbeat_at` datetime(3) null default null comment '最后收到有效心跳',
  `created_at` datetime(3) not null default current_timestamp(3) comment 'UTC创建时间',
  `updated_at` datetime(3) not null default current_timestamp(3) on update current_timestamp(3) comment 'UTC最后修改时间',
  primary key (`pile_id`),
  unique key `uq_charging_pile_serial_no` (`serial_no`),
  key `ix_charging_pile_station_id_status` (`station_id`, `status`),
  key `ix_charging_pile_last_heartbeat_at` (`last_heartbeat_at`),
  constraint `ck_charging_pile_1` check (rated_power_kw > 0),
  constraint `ck_charging_pile_2` check (`lifecycle_status` in ('draft', 'pending_acceptance', 'active', 'retired')),
  constraint `ck_charging_pile_3` check (`status` in ('idle', 'occupied', 'fault', 'offline')),
  constraint `ck_charging_pile_4` check (`has_fault` in (0, 1)),
  constraint `ck_charging_pile_5` check (`is_online` in (0, 1))
) engine=InnoDB default charset=utf8mb4 collate=utf8mb4_0900_ai_ci;

-- assets / 充电枪
create table `charging_gun` (
  `gun_id` bigint unsigned not null auto_increment comment '主键',
  `pile_id` bigint unsigned not null comment '所属桩',
  `gun_no` smallint unsigned not null comment '桩内枪序号',
  `gun_type` varchar(32) not null comment '直流快充或交流慢充',
  `connector_standard` varchar(50) not null comment '接口标准',
  `max_power_kw` decimal(10,3) not null comment '最大功率kW',
  `status` varchar(32) not null default 'offline' comment '当前状态',
  `has_fault` tinyint unsigned not null default 0 comment '故障标记 与在线事实分开',
  `created_at` datetime(3) not null default current_timestamp(3) comment 'UTC创建时间',
  `updated_at` datetime(3) not null default current_timestamp(3) on update current_timestamp(3) comment 'UTC最后修改时间',
  primary key (`gun_id`),
  unique key `uq_charging_gun_pile_id_gun_no` (`pile_id`, `gun_no`),
  constraint `ck_charging_gun_1` check (gun_no > 0),
  constraint `ck_charging_gun_2` check (max_power_kw > 0),
  constraint `ck_charging_gun_3` check (`gun_type` in ('dc', 'ac')),
  constraint `ck_charging_gun_4` check (`status` in ('idle', 'occupied', 'fault', 'offline')),
  constraint `ck_charging_gun_5` check (`has_fault` in (0, 1))
) engine=InnoDB default charset=utf8mb4 collate=utf8mb4_0900_ai_ci;

-- assets / 设备状态历史
create table `device_status_log` (
  `status_log_id` bigint unsigned not null auto_increment comment '主键',
  `pile_id` bigint unsigned null default null comment '目标桩 与gun_id二选一',
  `gun_id` bigint unsigned null default null comment '目标枪 与pile_id二选一',
  `old_status` varchar(32) null default null comment '原状态 首条可空',
  `new_status` varchar(32) not null comment '新状态',
  `occurred_at` datetime(3) not null comment '变化时间',
  `reason` varchar(255) not null comment '变更原因',
  `actor_account_id` bigint unsigned null default null comment '系统任务为空',
  `created_at` datetime(3) not null default current_timestamp(3) comment 'UTC创建时间',
  `updated_at` datetime(3) not null default current_timestamp(3) on update current_timestamp(3) comment 'UTC最后修改时间',
  primary key (`status_log_id`),
  key `ix_device_status_log_pile_id_occurred_at` (`pile_id`, `occurred_at`),
  key `ix_device_status_log_gun_id_occurred_at` (`gun_id`, `occurred_at`),
  constraint `ck_device_status_log_1` check ((pile_id is not null) + (gun_id is not null) = 1),
  constraint `ck_device_status_log_2` check (`old_status` in ('idle', 'occupied', 'fault', 'offline')),
  constraint `ck_device_status_log_3` check (`new_status` in ('idle', 'occupied', 'fault', 'offline'))
) engine=InnoDB default charset=utf8mb4 collate=utf8mb4_0900_ai_ci;

-- assets / 设备档案变更申请
create table `equipment_change_request` (
  `request_id` bigint unsigned not null auto_increment comment '主键',
  `pile_id` bigint unsigned null default null comment '桩目标',
  `gun_id` bigint unsigned null default null comment '枪目标',
  `change_type` varchar(32) not null comment '变更种类',
  `before_data` json not null comment '原档案快照',
  `proposed_data` json not null comment '允许字段的新值',
  `reason` varchar(500) not null comment '申请理由',
  `requested_by` bigint unsigned not null comment '申请账号',
  `status` varchar(32) not null default 'pending' comment '审批状态',
  `reviewed_by` bigint unsigned null default null comment '审批人',
  `reviewed_at` datetime(3) null default null comment '审批时间',
  `review_note` varchar(500) null default null comment '审批意见',
  `created_at` datetime(3) not null default current_timestamp(3) comment 'UTC创建时间',
  `updated_at` datetime(3) not null default current_timestamp(3) on update current_timestamp(3) comment 'UTC最后修改时间',
  primary key (`request_id`),
  constraint `ck_equipment_change_request_1` check ((pile_id is not null) + (gun_id is not null) = 1),
  constraint `ck_equipment_change_request_2` check (`change_type` in ('archive', 'relocate', 'retrofit', 'retire')),
  constraint `ck_equipment_change_request_3` check (`status` in ('pending', 'approved', 'rejected'))
) engine=InnoDB default charset=utf8mb4 collate=utf8mb4_0900_ai_ci;

-- assets / 设备联调验收
create table `device_acceptance` (
  `acceptance_id` bigint unsigned not null auto_increment comment '主键',
  `pile_id` bigint unsigned not null comment '验收桩',
  `protocol_test_passed` tinyint unsigned not null default 0 comment '模拟协议联调是否通过',
  `nameplate_checked` tinyint unsigned not null default 0 comment '铭牌是否核对',
  `start_stop_passed` tinyint unsigned not null default 0 comment '启停测试结果',
  `heartbeat_passed` tinyint unsigned not null default 0 comment '心跳测试结果',
  `result` varchar(32) not null comment '验收结论',
  `accepted_by` bigint unsigned not null comment '验收账号',
  `accepted_at` datetime(3) not null comment '验收时间',
  `note` varchar(500) null default null comment '验收说明',
  `created_at` datetime(3) not null default current_timestamp(3) comment 'UTC创建时间',
  `updated_at` datetime(3) not null default current_timestamp(3) on update current_timestamp(3) comment 'UTC最后修改时间',
  primary key (`acceptance_id`),
  constraint `ck_device_acceptance_1` check (`protocol_test_passed` in (0, 1)),
  constraint `ck_device_acceptance_2` check (`nameplate_checked` in (0, 1)),
  constraint `ck_device_acceptance_3` check (`start_stop_passed` in (0, 1)),
  constraint `ck_device_acceptance_4` check (`heartbeat_passed` in (0, 1)),
  constraint `ck_device_acceptance_5` check (`result` in ('passed', 'failed'))
) engine=InnoDB default charset=utf8mb4 collate=utf8mb4_0900_ai_ci;

-- assets / 设备模拟命令
create table `device_command` (
  `command_id` bigint unsigned not null auto_increment comment '主键',
  `pile_id` bigint unsigned not null comment '目标桩',
  `gun_id` bigint unsigned not null comment '目标枪',
  `order_id` bigint unsigned not null comment '关联订单',
  `command_type` varchar(32) not null comment '启停命令',
  `status` varchar(32) not null default 'pending' comment '命令状态',
  `attempt_count` int unsigned not null default 0 comment '发送次数',
  `sent_at` datetime(3) null default null comment '发送时间',
  `acknowledged_at` datetime(3) null default null comment '确认时间',
  `error_message` varchar(500) null default null comment '失败说明',
  `created_at` datetime(3) not null default current_timestamp(3) comment 'UTC创建时间',
  `updated_at` datetime(3) not null default current_timestamp(3) on update current_timestamp(3) comment 'UTC最后修改时间',
  primary key (`command_id`),
  unique key `uq_device_command_order_id_command_type` (`order_id`, `command_type`),
  constraint `ck_device_command_1` check (`command_type` in ('start', 'stop')),
  constraint `ck_device_command_2` check (`status` in ('pending', 'sent', 'succeeded', 'failed'))
) engine=InnoDB default charset=utf8mb4 collate=utf8mb4_0900_ai_ci;

-- billing / 普通计费规则
create table `pricing_rule` (
  `rule_id` bigint unsigned not null auto_increment comment '主键',
  `station_id` bigint unsigned not null comment '场站',
  `rule_name` varchar(100) not null comment '规则名称',
  `free_service_minutes` int unsigned not null default 0 comment '免服务费分钟数',
  `minimum_amount` decimal(14,2) not null default 0.00 comment '起步金额',
  `valid_from` datetime(3) not null comment '生效UTC时间',
  `valid_until` datetime(3) not null comment '失效UTC时间',
  `status` varchar(32) not null default 'draft' comment '规则状态',
  `created_at` datetime(3) not null default current_timestamp(3) comment 'UTC创建时间',
  `updated_at` datetime(3) not null default current_timestamp(3) on update current_timestamp(3) comment 'UTC最后修改时间',
  primary key (`rule_id`),
  key `ix_pricing_rule_station_id_valid_from` (`station_id`, `valid_from`),
  constraint `ck_pricing_rule_1` check (valid_until > valid_from),
  constraint `ck_pricing_rule_2` check (minimum_amount >= 0),
  constraint `ck_pricing_rule_3` check (`status` in ('draft', 'active', 'disabled'))
) engine=InnoDB default charset=utf8mb4 collate=utf8mb4_0900_ai_ci;

-- billing / 规则内价格时段
create table `pricing_period` (
  `period_id` bigint unsigned not null auto_increment comment '主键',
  `rule_id` bigint unsigned not null comment '所属规则',
  `period_type` varchar(32) not null comment '峰平谷',
  `start_minute` smallint unsigned not null comment '上海当天起始分钟 0至1439',
  `end_minute` smallint unsigned not null comment '上海当天结束分钟 1至1440',
  `electricity_rate` decimal(12,4) not null comment '电价 元每kWh',
  `service_rate` decimal(12,4) not null comment '服务费单价 元每kWh',
  `created_at` datetime(3) not null default current_timestamp(3) comment 'UTC创建时间',
  `updated_at` datetime(3) not null default current_timestamp(3) on update current_timestamp(3) comment 'UTC最后修改时间',
  primary key (`period_id`),
  unique key `uq_pricing_period_rule_id_start_minute` (`rule_id`, `start_minute`),
  constraint `ck_pricing_period_1` check (start_minute < end_minute),
  constraint `ck_pricing_period_2` check (end_minute <= 1440),
  constraint `ck_pricing_period_3` check (electricity_rate >= 0),
  constraint `ck_pricing_period_4` check (service_rate >= 0),
  constraint `ck_pricing_period_5` check (`period_type` in ('peak', 'flat', 'valley'))
) engine=InnoDB default charset=utf8mb4 collate=utf8mb4_0900_ai_ci;

-- billing / 充电订单
create table `charging_order` (
  `order_id` bigint unsigned not null auto_increment comment '主键',
  `user_id` bigint unsigned not null comment '发起车主',
  `gun_id` bigint unsigned not null comment '充电枪',
  `vehicle_id` bigint unsigned null default null comment '个人可空 车队由授权确定',
  `authorization_id` bigint unsigned null default null comment '车队授权 个人为空',
  `rule_id` bigint unsigned not null comment '启动时普通规则',
  `operator_id` bigint unsigned not null comment '启动归属快照',
  `station_id` bigint unsigned not null comment '启动场站快照',
  `fleet_id` bigint unsigned null default null comment '车队归属快照',
  `settlement_id` bigint unsigned null default null comment '运营商结算归集',
  `order_mode` varchar(32) not null comment '订单模式',
  `status` varchar(32) not null default 'charging' comment '订单状态 退款另表',
  `started_at` datetime(3) not null comment '实际开始时间',
  `finished_at` datetime(3) null default null comment '实际结束时间',
  `start_soc` decimal(5,2) null default null comment '车辆开始电量百分比',
  `end_soc` decimal(5,2) null default null comment '车辆结束电量百分比',
  `energy_kwh` decimal(14,3) not null default 0.000 comment '累计实际充电电量',
  `electricity_amount` decimal(14,2) not null default 0.00 comment '核定电费',
  `service_amount` decimal(14,2) not null default 0.00 comment '核定服务费',
  `minimum_topup_amount` decimal(14,2) not null default 0.00 comment '起步补差',
  `discount_amount` decimal(14,2) not null default 0.00 comment '券抵扣',
  `payable_amount` decimal(14,2) not null default 0.00 comment '最终应付',
  `free_service_minutes_snapshot` int unsigned not null default 0 comment '启动规则免费分钟快照',
  `minimum_amount_snapshot` decimal(14,2) not null default 0.00 comment '启动规则起步金额快照',
  `review_required` tinyint unsigned not null default 0 comment '核价或额度需人工复核',
  `review_reason` varchar(500) null default null comment '复核原因',
  `payment_due_at` datetime(3) null default null comment '付款截止 不由网页倒计时决定',
  `created_at` datetime(3) not null default current_timestamp(3) comment 'UTC创建时间',
  `updated_at` datetime(3) not null default current_timestamp(3) on update current_timestamp(3) comment 'UTC最后修改时间',
  `active_gun_id` bigint unsigned generated always as (case when status = 'charging' then gun_id else null end) stored comment '唯一进行中枪 生成列禁止客户端赋值',
  primary key (`order_id`),
  unique key `uq_charging_order_active_gun_id` (`active_gun_id`),
  key `ix_charging_order_user_id_started_at` (`user_id`, `started_at`),
  key `ix_charging_order_station_id_finished_at` (`station_id`, `finished_at`),
  key `ix_charging_order_fleet_id_finished_at` (`fleet_id`, `finished_at`),
  constraint `ck_charging_order_1` check ((order_mode='personal' and authorization_id is null and fleet_id is null) or (order_mode='fleet' and authorization_id is not null and fleet_id is not null and vehicle_id is not null)),
  constraint `ck_charging_order_2` check (finished_at is null or finished_at >= started_at),
  constraint `ck_charging_order_3` check (start_soc is null or start_soc between 0 and 100),
  constraint `ck_charging_order_4` check (end_soc is null or end_soc between 0 and 100),
  constraint `ck_charging_order_5` check (energy_kwh >= 0),
  constraint `ck_charging_order_6` check (payable_amount >= 0),
  constraint `ck_charging_order_7` check (`order_mode` in ('personal', 'fleet')),
  constraint `ck_charging_order_8` check (`status` in ('charging', 'awaiting_payment', 'paid', 'cancelled')),
  constraint `ck_charging_order_9` check (`review_required` in (0, 1))
) engine=InnoDB default charset=utf8mb4 collate=utf8mb4_0900_ai_ci;

-- billing / 订单电量采样
create table `meter_reading` (
  `reading_id` bigint unsigned not null auto_increment comment '主键',
  `order_id` bigint unsigned not null comment '订单',
  `sampled_at` datetime(3) not null comment '采样时刻',
  `cumulative_energy_kwh` decimal(14,3) not null comment '累计电表读数 非本单新增电量',
  `soc` decimal(5,2) null default null comment '车辆当前SOC 可空',
  `source` varchar(32) not null comment '数据来源',
  `created_at` datetime(3) not null default current_timestamp(3) comment 'UTC创建时间',
  `updated_at` datetime(3) not null default current_timestamp(3) on update current_timestamp(3) comment 'UTC最后修改时间',
  primary key (`reading_id`),
  unique key `uq_meter_reading_order_id_sampled_at` (`order_id`, `sampled_at`),
  constraint `ck_meter_reading_1` check (cumulative_energy_kwh >= 0),
  constraint `ck_meter_reading_2` check (soc is null or soc between 0 and 100),
  constraint `ck_meter_reading_3` check (`source` in ('simulator', 'device', 'manual'))
) engine=InnoDB default charset=utf8mb4 collate=utf8mb4_0900_ai_ci;

-- billing / 分段核价明细
create table `billing_detail` (
  `detail_id` bigint unsigned not null auto_increment comment '主键',
  `order_id` bigint unsigned not null comment '订单',
  `period_id` bigint unsigned not null comment '普通时段依据',
  `price_id` bigint unsigned null default null comment '车队专价 可空',
  `segment_start_at` datetime(3) not null comment '分段开始',
  `segment_end_at` datetime(3) not null comment '分段结束',
  `energy_kwh` decimal(14,3) not null comment '本段电量',
  `electricity_rate` decimal(12,4) not null comment '实际电价快照',
  `service_rate` decimal(12,4) not null comment '实际服务单价快照 免费时为0',
  `electricity_amount` decimal(14,2) not null comment '本段电费',
  `service_amount` decimal(14,2) not null comment '本段服务费',
  `price_source` varchar(32) not null comment '采用来源',
  `created_at` datetime(3) not null default current_timestamp(3) comment 'UTC创建时间',
  `updated_at` datetime(3) not null default current_timestamp(3) on update current_timestamp(3) comment 'UTC最后修改时间',
  primary key (`detail_id`),
  unique key `uq_billing_detail_order_id_segment_start_at_segment_end_at` (`order_id`, `segment_start_at`, `segment_end_at`),
  constraint `ck_billing_detail_1` check (segment_end_at > segment_start_at),
  constraint `ck_billing_detail_2` check (energy_kwh >= 0),
  constraint `ck_billing_detail_3` check ((price_source='fleet' and price_id is not null) or (price_source='ordinary' and price_id is null)),
  constraint `ck_billing_detail_4` check (`price_source` in ('ordinary', 'fleet'))
) engine=InnoDB default charset=utf8mb4 collate=utf8mb4_0900_ai_ci;

-- billing / 支付记录
create table `payment_record` (
  `payment_id` bigint unsigned not null auto_increment comment '主键',
  `order_id` bigint unsigned not null comment '订单',
  `channel` varchar(32) not null comment '模拟渠道或余额',
  `external_trade_no` varchar(80) not null comment '渠道交易流水号',
  `amount` decimal(14,2) not null comment '本次支付金额',
  `status` varchar(32) not null default 'pending' comment '支付结果',
  `paid_at` datetime(3) null default null comment '成功支付时间',
  `bill_payment_id` bigint unsigned null default null comment '企业月结收款来源 个人支付为空',
  `fleet_credit_amount` decimal(14,2) not null default 0.00 comment '本次支付内车队账单抵扣额 非新增现金 实收分配=amount减本列',
  `created_at` datetime(3) not null default current_timestamp(3) comment 'UTC创建时间',
  `updated_at` datetime(3) not null default current_timestamp(3) on update current_timestamp(3) comment 'UTC最后修改时间',
  primary key (`payment_id`),
  unique key `uq_payment_record_channel_external_trade_no` (`channel`, `external_trade_no`),
  unique key `uq_payment_record_bill_payment_id_order_id` (`bill_payment_id`, `order_id`),
  constraint `ck_payment_record_1` check (amount > 0),
  constraint `ck_payment_record_2` check (fleet_credit_amount >= 0),
  constraint `ck_payment_record_3` check (fleet_credit_amount <= amount),
  constraint `ck_payment_record_4` check (channel = 'fleet_monthly' or fleet_credit_amount = 0),
  constraint `ck_payment_record_5` check (`channel` in ('mock', 'wallet', 'fleet_monthly')),
  constraint `ck_payment_record_6` check (`status` in ('pending', 'succeeded', 'failed'))
) engine=InnoDB default charset=utf8mb4 collate=utf8mb4_0900_ai_ci;

-- billing / 退款记录
create table `refund_record` (
  `refund_id` bigint unsigned not null auto_increment comment '主键',
  `payment_id` bigint unsigned not null comment '原支付流水',
  `external_refund_no` varchar(80) not null comment '本系统全局唯一退款流水',
  `amount` decimal(14,2) not null comment '退款金额',
  `status` varchar(32) not null default 'pending' comment '退款结果',
  `refunded_at` datetime(3) null default null comment '退款成功时间',
  `reason` varchar(500) not null comment '退款原因',
  `requested_by` bigint unsigned not null comment '办理账号',
  `settlement_method` varchar(32) not null default 'original' comment 'original原路模拟退款；fleet_credit只抵后续账单，不再现金退',
  `created_at` datetime(3) not null default current_timestamp(3) comment 'UTC创建时间',
  `updated_at` datetime(3) not null default current_timestamp(3) on update current_timestamp(3) comment 'UTC最后修改时间',
  primary key (`refund_id`),
  unique key `uq_refund_record_external_refund_no` (`external_refund_no`),
  constraint `ck_refund_record_1` check (amount > 0),
  constraint `ck_refund_record_2` check (`status` in ('pending', 'succeeded', 'failed')),
  constraint `ck_refund_record_3` check (`settlement_method` in ('original', 'fleet_credit'))
) engine=InnoDB default charset=utf8mb4 collate=utf8mb4_0900_ai_ci;

-- billing / 异常订单复核记录
create table `order_review` (
  `review_id` bigint unsigned not null auto_increment comment '主键',
  `order_id` bigint unsigned not null comment '复核订单',
  `review_type` varchar(32) not null comment '复核类型',
  `decision` varchar(32) not null comment '结论',
  `evidence` json not null comment '复核依据和调整明细',
  `note` varchar(500) not null comment '说明',
  `reviewed_by` bigint unsigned not null comment '复核账号',
  `reviewed_at` datetime(3) not null comment '复核时间',
  `created_at` datetime(3) not null default current_timestamp(3) comment 'UTC创建时间',
  `updated_at` datetime(3) not null default current_timestamp(3) on update current_timestamp(3) comment 'UTC最后修改时间',
  primary key (`review_id`),
  constraint `ck_order_review_1` check (`review_type` in ('meter', 'quota', 'payment')),
  constraint `ck_order_review_2` check (`decision` in ('approved', 'rejected'))
) engine=InnoDB default charset=utf8mb4 collate=utf8mb4_0900_ai_ci;

-- maintenance / 分区运行数据
create table `device_reading` (
  `sample_id` bigint unsigned not null auto_increment comment '主键',
  `pile_id` bigint unsigned not null comment '逻辑引用桩 不建物理FK',
  `sampled_at` datetime(3) not null comment '设备采样UTC时间',
  `output_voltage_v` decimal(10,3) not null comment '输出电压V',
  `output_current_a` decimal(10,3) not null comment '输出电流A',
  `power_kw` decimal(10,3) not null comment '功率kW',
  `module_temperature_c` decimal(6,2) not null comment '模块温度摄氏度',
  `offline_seconds` int unsigned not null default 0 comment '上报的离线时长秒',
  `fault_code` varchar(32) not null default 'NONE' comment '故障码',
  `created_at` datetime(3) not null default current_timestamp(3) comment 'UTC创建时间',
  `updated_at` datetime(3) not null default current_timestamp(3) on update current_timestamp(3) comment 'UTC最后修改时间',
  primary key (`sample_id`, `pile_id`, `sampled_at`),
  key `ix_device_reading_pile_id_sampled_at` (`pile_id`, `sampled_at`)
) engine=InnoDB default charset=utf8mb4 collate=utf8mb4_0900_ai_ci
partition by range columns(sampled_at)
subpartition by hash(pile_id) subpartitions 4 (
  partition p_before_202611 values less than ('2026-11-01'),
  partition p202611 values less than ('2026-12-01'),
  partition p202612 values less than ('2027-01-01'),
  partition p_future values less than (maxvalue)
);

-- maintenance / 告警与响应配置
create table `alarm_rule` (
  `alarm_rule_id` bigint unsigned not null auto_increment comment '主键',
  `rule_code` varchar(50) not null comment '唯一规则码',
  `fault_code` varchar(32) null default null comment '匹配设备故障码',
  `metric` varchar(32) not null comment '判断指标',
  `threshold_value` decimal(12,3) null default null comment '温度阈值或心跳秒数',
  `severity` varchar(32) not null comment '告警等级',
  `response_seconds` int unsigned not null comment '响应时限秒',
  `recovery_seconds` int unsigned not null comment '连续正常观察秒',
  `enabled` tinyint unsigned not null default 1 comment '是否启用',
  `created_at` datetime(3) not null default current_timestamp(3) comment 'UTC创建时间',
  `updated_at` datetime(3) not null default current_timestamp(3) on update current_timestamp(3) comment 'UTC最后修改时间',
  primary key (`alarm_rule_id`),
  unique key `uq_alarm_rule_rule_code` (`rule_code`),
  constraint `ck_alarm_rule_1` check (`metric` in ('fault_code', 'temperature', 'heartbeat')),
  constraint `ck_alarm_rule_2` check (`severity` in ('low', 'medium', 'high', 'critical')),
  constraint `ck_alarm_rule_3` check (`enabled` in (0, 1))
) engine=InnoDB default charset=utf8mb4 collate=utf8mb4_0900_ai_ci;

-- maintenance / 设备告警
create table `device_alert` (
  `alert_id` bigint unsigned not null auto_increment comment '主键',
  `pile_id` bigint unsigned not null comment '所属桩',
  `gun_id` bigint unsigned null default null comment '枪级故障才填',
  `alarm_rule_id` bigint unsigned not null comment '命中规则',
  `alert_code` varchar(32) not null comment '告警码快照',
  `severity` varchar(32) not null comment '等级快照',
  `occurred_at` datetime(3) not null comment '首次发生',
  `recovered_at` datetime(3) null default null comment '完成复核后的恢复时间',
  `status` varchar(32) not null default 'open' comment '告警状态',
  `response_seconds_snapshot` int unsigned not null comment '响应时限快照',
  `normal_since_at` datetime(3) null default null comment '连续正常起始',
  `created_at` datetime(3) not null default current_timestamp(3) comment 'UTC创建时间',
  `updated_at` datetime(3) not null default current_timestamp(3) on update current_timestamp(3) comment 'UTC最后修改时间',
  `active_key` varchar(160) generated always as (case when status <> 'recovered' then concat(pile_id, ':', coalesce(gun_id, 0), ':', alert_code) else null end) stored comment '未恢复告警唯一键',
  primary key (`alert_id`),
  unique key `uq_device_alert_active_key` (`active_key`),
  key `ix_device_alert_pile_id_status` (`pile_id`, `status`),
  constraint `ck_device_alert_1` check (`severity` in ('low', 'medium', 'high', 'critical')),
  constraint `ck_device_alert_2` check (`status` in ('open', 'processing', 'recovering', 'recovered'))
) engine=InnoDB default charset=utf8mb4 collate=utf8mb4_0900_ai_ci;

-- maintenance / 维修工单
create table `work_order` (
  `work_order_id` bigint unsigned not null auto_increment comment '主键',
  `alert_id` bigint unsigned not null comment '关联告警',
  `assigned_to` bigint unsigned not null comment '维修人员账号',
  `assigned_by` bigint unsigned not null comment '派单账号',
  `assigned_at` datetime(3) not null comment '派单时间',
  `response_due_at` datetime(3) not null comment '首次接单截止',
  `status` varchar(32) not null default 'assigned' comment '当前状态',
  `escalation_level` int unsigned not null default 0 comment '超时升级次数',
  `parts_used` varchar(500) null default null comment '更换备件说明',
  `result` varchar(500) null default null comment '处理结果',
  `created_at` datetime(3) not null default current_timestamp(3) comment 'UTC创建时间',
  `updated_at` datetime(3) not null default current_timestamp(3) on update current_timestamp(3) comment 'UTC最后修改时间',
  primary key (`work_order_id`),
  key `ix_work_order_assigned_to_status` (`assigned_to`, `status`),
  key `ix_work_order_status_response_due_at` (`status`, `response_due_at`),
  constraint `ck_work_order_1` check (`status` in ('assigned', 'accepted', 'arrived', 'repaired', 'closed'))
) engine=InnoDB default charset=utf8mb4 collate=utf8mb4_0900_ai_ci;

-- maintenance / 工单流转历史
create table `work_order_event` (
  `event_id` bigint unsigned not null auto_increment comment '主键',
  `work_order_id` bigint unsigned not null comment '工单',
  `event_type` varchar(32) not null comment '事件类型',
  `event_at` datetime(3) not null comment '事件时间',
  `old_status` varchar(32) not null comment '原状态',
  `new_status` varchar(32) not null comment '新状态',
  `actor_account_id` bigint unsigned null default null comment '系统任务为空',
  `note` varchar(500) null default null comment '处理说明',
  `review_result` varchar(255) null default null comment '复核依据',
  `created_at` datetime(3) not null default current_timestamp(3) comment 'UTC创建时间',
  `updated_at` datetime(3) not null default current_timestamp(3) on update current_timestamp(3) comment 'UTC最后修改时间',
  primary key (`event_id`),
  key `ix_work_order_event_work_order_id_event_at` (`work_order_id`, `event_at`),
  constraint `ck_work_order_event_1` check (`event_type` in ('accepted', 'arrived', 'repaired', 'review_passed', 'review_failed', 'closed', 'escalated'))
) engine=InnoDB default charset=utf8mb4 collate=utf8mb4_0900_ai_ci;

-- maintenance / 用户报障
create table `fault_report` (
  `report_id` bigint unsigned not null auto_increment comment '主键',
  `user_id` bigint unsigned not null comment '报障用户',
  `gun_id` bigint unsigned not null comment '目标枪',
  `order_id` bigint unsigned null default null comment '相关订单',
  `description` varchar(1000) not null comment '问题描述',
  `status` varchar(32) not null default 'submitted' comment '处理状态',
  `alert_id` bigint unsigned null default null comment '核查后关联告警',
  `handled_by` bigint unsigned null default null comment '处理账号',
  `handled_at` datetime(3) null default null comment '处理时间',
  `created_at` datetime(3) not null default current_timestamp(3) comment 'UTC创建时间',
  `updated_at` datetime(3) not null default current_timestamp(3) on update current_timestamp(3) comment 'UTC最后修改时间',
  primary key (`report_id`),
  constraint `ck_fault_report_1` check (`status` in ('submitted', 'linked', 'resolved'))
) engine=InnoDB default charset=utf8mb4 collate=utf8mb4_0900_ai_ci;

-- maintenance / 巡检记录
create table `inspection_record` (
  `inspection_id` bigint unsigned not null auto_increment comment '主键',
  `pile_id` bigint unsigned not null comment '巡检桩',
  `inspected_by` bigint unsigned not null comment '巡检账号',
  `inspected_at` datetime(3) not null comment '巡检时间',
  `result` varchar(32) not null comment '检查结论',
  `parts_used` varchar(500) null default null comment '备件更换说明',
  `note` varchar(1000) null default null comment '检查说明',
  `created_at` datetime(3) not null default current_timestamp(3) comment 'UTC创建时间',
  `updated_at` datetime(3) not null default current_timestamp(3) on update current_timestamp(3) comment 'UTC最后修改时间',
  primary key (`inspection_id`),
  constraint `ck_inspection_record_1` check (`result` in ('normal', 'abnormal'))
) engine=InnoDB default charset=utf8mb4 collate=utf8mb4_0900_ai_ci;

-- membership / 登录账号
create table `sys_account` (
  `account_id` bigint unsigned not null auto_increment comment '主键',
  `username` varchar(64) not null comment '登录名',
  `password_hash` varchar(255) not null comment 'Argon2id或bcrypt哈希 非明文',
  `status` varchar(32) not null default 'active' comment '账号状态',
  `failed_attempts` int unsigned not null default 0 comment '连续失败次数',
  `locked_until` datetime(3) null default null comment '锁定截止',
  `last_login_at` datetime(3) null default null comment '最后登录',
  `created_at` datetime(3) not null default current_timestamp(3) comment 'UTC创建时间',
  `updated_at` datetime(3) not null default current_timestamp(3) on update current_timestamp(3) comment 'UTC最后修改时间',
  primary key (`account_id`),
  unique key `uq_sys_account_username` (`username`),
  constraint `ck_sys_account_1` check (`status` in ('active', 'disabled'))
) engine=InnoDB default charset=utf8mb4 collate=utf8mb4_0900_ai_ci;

-- membership / 车主档案
create table `app_user` (
  `user_id` bigint unsigned not null auto_increment comment '主键',
  `account_id` bigint unsigned null default null comment '可选一对一账号',
  `display_name` varchar(50) not null comment '显示姓名',
  `phone_cipher` varbinary(512) not null comment '手机号密文',
  `phone_hash` binary(32) not null comment '带密钥HMAC检索摘要',
  `real_name_status` varchar(32) not null default 'unverified' comment '实名状态',
  `registration_channel` varchar(32) not null default 'web' comment '注册渠道',
  `registered_at` datetime(3) not null comment '注册时间',
  `member_level` varchar(32) not null default 'normal' comment '会员等级',
  `balance` decimal(14,2) not null default 0.00 comment '余额缓存 与流水一致',
  `status` varchar(32) not null default 'active' comment '档案状态',
  `created_at` datetime(3) not null default current_timestamp(3) comment 'UTC创建时间',
  `updated_at` datetime(3) not null default current_timestamp(3) on update current_timestamp(3) comment 'UTC最后修改时间',
  primary key (`user_id`),
  unique key `uq_app_user_account_id` (`account_id`),
  unique key `uq_app_user_phone_hash` (`phone_hash`),
  constraint `ck_app_user_1` check (balance >= 0),
  constraint `ck_app_user_2` check (`real_name_status` in ('unverified', 'verified', 'rejected')),
  constraint `ck_app_user_3` check (`member_level` in ('normal', 'silver', 'gold')),
  constraint `ck_app_user_4` check (`status` in ('active', 'disabled'))
) engine=InnoDB default charset=utf8mb4 collate=utf8mb4_0900_ai_ci;

-- membership / 车辆
create table `vehicle` (
  `vehicle_id` bigint unsigned not null auto_increment comment '主键',
  `plate_cipher` varbinary(512) not null comment '车牌密文',
  `plate_hash` binary(32) not null comment '标准化车牌HMAC',
  `model_name` varchar(100) not null comment '车型',
  `battery_capacity_kwh` decimal(14,3) not null comment '电池容量',
  `max_charging_power_kw` decimal(10,3) not null comment '最大充电功率',
  `supports_fast_charge` tinyint unsigned not null default 0 comment '支持快充',
  `status` varchar(32) not null default 'active' comment '车辆状态',
  `created_at` datetime(3) not null default current_timestamp(3) comment 'UTC创建时间',
  `updated_at` datetime(3) not null default current_timestamp(3) on update current_timestamp(3) comment 'UTC最后修改时间',
  primary key (`vehicle_id`),
  unique key `uq_vehicle_plate_hash` (`plate_hash`),
  constraint `ck_vehicle_1` check (battery_capacity_kwh > 0),
  constraint `ck_vehicle_2` check (max_charging_power_kw > 0),
  constraint `ck_vehicle_3` check (`supports_fast_charge` in (0, 1)),
  constraint `ck_vehicle_4` check (`status` in ('active', 'disabled'))
) engine=InnoDB default charset=utf8mb4 collate=utf8mb4_0900_ai_ci;

-- membership / 车辆绑定历史
create table `vehicle_binding` (
  `binding_id` bigint unsigned not null auto_increment comment '主键',
  `user_id` bigint unsigned not null comment '绑定用户',
  `vehicle_id` bigint unsigned not null comment '车辆',
  `bound_at` datetime(3) not null comment '绑定开始',
  `unbound_at` datetime(3) null default null comment '解绑时间',
  `created_at` datetime(3) not null default current_timestamp(3) comment 'UTC创建时间',
  `updated_at` datetime(3) not null default current_timestamp(3) on update current_timestamp(3) comment 'UTC最后修改时间',
  `active_vehicle_id` bigint unsigned generated always as (case when unbound_at is null then vehicle_id else null end) stored comment '一车同一时刻只归一用户',
  primary key (`binding_id`),
  unique key `uq_vehicle_binding_active_vehicle_id` (`active_vehicle_id`),
  constraint `ck_vehicle_binding_1` check (unbound_at is null or unbound_at >= bound_at)
) engine=InnoDB default charset=utf8mb4 collate=utf8mb4_0900_ai_ci;

-- membership / 优惠活动
create table `promotion` (
  `promotion_id` bigint unsigned not null auto_increment comment '主键',
  `promotion_name` varchar(100) not null comment '活动名称',
  `face_amount` decimal(14,2) not null comment '券面额',
  `minimum_spend` decimal(14,2) not null default 0.00 comment '使用门槛',
  `valid_from` datetime(3) not null comment '有效起始',
  `valid_until` datetime(3) not null comment '有效截止',
  `issue_limit` int unsigned not null comment '发放上限',
  `issued_count` int unsigned not null default 0 comment '已发数量 持锁更新',
  `per_user_limit` int unsigned not null default 1 comment '每用户领取上限',
  `all_stations` tinyint unsigned not null default 0 comment '1适用全场站 0读关联表',
  `redemption_rule` varchar(500) not null default '个人订单满额抵扣' comment '核销说明',
  `status` varchar(32) not null default 'draft' comment '活动审核状态',
  `created_by` bigint unsigned not null comment '创建账号',
  `reviewed_by` bigint unsigned null default null comment '审核账号',
  `reviewed_at` datetime(3) null default null comment '审核时间',
  `review_note` varchar(500) null default null comment '审核意见',
  `created_at` datetime(3) not null default current_timestamp(3) comment 'UTC创建时间',
  `updated_at` datetime(3) not null default current_timestamp(3) on update current_timestamp(3) comment 'UTC最后修改时间',
  primary key (`promotion_id`),
  constraint `ck_promotion_1` check (face_amount > 0),
  constraint `ck_promotion_2` check (minimum_spend >= 0),
  constraint `ck_promotion_3` check (issued_count <= issue_limit),
  constraint `ck_promotion_4` check (valid_until > valid_from),
  constraint `ck_promotion_5` check (`all_stations` in (0, 1)),
  constraint `ck_promotion_6` check (`status` in ('draft', 'pending_review', 'active', 'rejected', 'disabled'))
) engine=InnoDB default charset=utf8mb4 collate=utf8mb4_0900_ai_ci;

-- membership / 发放到用户的优惠券
create table `user_coupon` (
  `coupon_id` bigint unsigned not null auto_increment comment '主键',
  `promotion_id` bigint unsigned not null comment '活动来源',
  `user_id` bigint unsigned not null comment '持券用户',
  `received_at` datetime(3) not null comment '领取时间',
  `expires_at` datetime(3) not null comment '到期时间',
  `face_amount_snapshot` decimal(14,2) not null comment '发放时面额',
  `minimum_spend_snapshot` decimal(14,2) not null comment '发放时门槛',
  `status` varchar(32) not null default 'available' comment '券状态',
  `reissue_source_order_id` bigint unsigned null default null comment '退款补发来源订单',
  `created_at` datetime(3) not null default current_timestamp(3) comment 'UTC创建时间',
  `updated_at` datetime(3) not null default current_timestamp(3) on update current_timestamp(3) comment 'UTC最后修改时间',
  primary key (`coupon_id`),
  unique key `uq_user_coupon_reissue_source_order_id` (`reissue_source_order_id`),
  key `ix_user_coupon_user_id_status` (`user_id`, `status`),
  constraint `ck_user_coupon_1` check (`status` in ('available', 'locked', 'redeemed', 'expired', 'void'))
) engine=InnoDB default charset=utf8mb4 collate=utf8mb4_0900_ai_ci;

-- membership / 券使用过程
create table `coupon_usage` (
  `usage_id` bigint unsigned not null auto_increment comment '主键',
  `coupon_id` bigint unsigned not null comment '用户券',
  `order_id` bigint unsigned not null comment '订单',
  `original_amount` decimal(14,2) not null comment '优惠前电费服务费合计',
  `discount_amount` decimal(14,2) not null comment '本次抵扣',
  `locked_at` datetime(3) not null comment '锁定时间',
  `lock_expires_at` datetime(3) not null comment '锁定截止',
  `redeemed_at` datetime(3) null default null comment '核销时间',
  `released_at` datetime(3) null default null comment '释放时间',
  `status` varchar(32) not null default 'locked' comment '本次使用状态',
  `created_at` datetime(3) not null default current_timestamp(3) comment 'UTC创建时间',
  `updated_at` datetime(3) not null default current_timestamp(3) on update current_timestamp(3) comment 'UTC最后修改时间',
  `active_coupon_id` bigint unsigned generated always as (case when status in ('locked','redeemed') then coupon_id else null end) stored comment '有效锁定或核销唯一',
  `active_order_id` bigint unsigned generated always as (case when status in ('locked','redeemed') then order_id else null end) stored comment '有效锁定或核销唯一',
  primary key (`usage_id`),
  unique key `uq_coupon_usage_active_coupon_id` (`active_coupon_id`),
  unique key `uq_coupon_usage_active_order_id` (`active_order_id`),
  constraint `ck_coupon_usage_1` check (discount_amount >= 0),
  constraint `ck_coupon_usage_2` check (discount_amount <= original_amount),
  constraint `ck_coupon_usage_3` check (`status` in ('locked', 'redeemed', 'released'))
) engine=InnoDB default charset=utf8mb4 collate=utf8mb4_0900_ai_ci;

-- membership / 企业车队
create table `fleet` (
  `fleet_id` bigint unsigned not null auto_increment comment '主键',
  `company_name` varchar(100) not null comment '企业名称',
  `credit_code` varchar(18) not null comment '统一信用代码',
  `contact_name` varchar(50) not null comment '联系人',
  `contact_phone_cipher` varbinary(512) not null comment '电话密文',
  `status` varchar(32) not null default 'active' comment '车队状态',
  `created_at` datetime(3) not null default current_timestamp(3) comment 'UTC创建时间',
  `updated_at` datetime(3) not null default current_timestamp(3) on update current_timestamp(3) comment 'UTC最后修改时间',
  primary key (`fleet_id`),
  unique key `uq_fleet_credit_code` (`credit_code`),
  constraint `ck_fleet_1` check (`status` in ('active', 'disabled'))
) engine=InnoDB default charset=utf8mb4 collate=utf8mb4_0900_ai_ci;

-- membership / 车队卡
create table `fleet_card` (
  `card_id` bigint unsigned not null auto_increment comment '主键',
  `fleet_id` bigint unsigned not null comment '所属车队',
  `card_no` varchar(64) not null comment '卡号',
  `issued_at` datetime(3) not null comment '发卡时间',
  `valid_from` datetime(3) not null comment '生效',
  `valid_until` datetime(3) not null comment '失效',
  `status` varchar(32) not null default 'active' comment '卡状态',
  `created_at` datetime(3) not null default current_timestamp(3) comment 'UTC创建时间',
  `updated_at` datetime(3) not null default current_timestamp(3) on update current_timestamp(3) comment 'UTC最后修改时间',
  primary key (`card_id`),
  unique key `uq_fleet_card_card_no` (`card_no`),
  constraint `ck_fleet_card_1` check (valid_until > valid_from),
  constraint `ck_fleet_card_2` check (`status` in ('active', 'suspended', 'expired'))
) engine=InnoDB default charset=utf8mb4 collate=utf8mb4_0900_ai_ci;

-- membership / 车队用车授权
create table `fleet_authorization` (
  `authorization_id` bigint unsigned not null auto_increment comment '主键',
  `card_id` bigint unsigned not null comment '车队卡',
  `user_id` bigint unsigned not null comment '用车人',
  `vehicle_id` bigint unsigned not null comment '授权车辆',
  `default_monthly_limit` decimal(14,2) not null comment '新月份默认额度',
  `valid_from` datetime(3) not null comment '生效',
  `valid_until` datetime(3) not null comment '失效',
  `status` varchar(32) not null default 'active' comment '授权状态',
  `created_at` datetime(3) not null default current_timestamp(3) comment 'UTC创建时间',
  `updated_at` datetime(3) not null default current_timestamp(3) on update current_timestamp(3) comment 'UTC最后修改时间',
  primary key (`authorization_id`),
  constraint `ck_fleet_authorization_1` check (default_monthly_limit >= 0),
  constraint `ck_fleet_authorization_2` check (valid_until > valid_from),
  constraint `ck_fleet_authorization_3` check (`status` in ('active', 'suspended', 'expired'))
) engine=InnoDB default charset=utf8mb4 collate=utf8mb4_0900_ai_ci;

-- membership / 授权月额度
create table `fleet_quota_month` (
  `quota_month_id` bigint unsigned not null auto_increment comment '主键',
  `authorization_id` bigint unsigned not null comment '授权',
  `bill_month` date not null comment '上海月份首日',
  `limit_amount` decimal(14,2) not null comment '月额度',
  `reserved_amount` decimal(14,2) not null default 0.00 comment '未结算预占总额',
  `used_amount` decimal(14,2) not null default 0.00 comment '已结算净使用额',
  `created_at` datetime(3) not null default current_timestamp(3) comment 'UTC创建时间',
  `updated_at` datetime(3) not null default current_timestamp(3) on update current_timestamp(3) comment 'UTC最后修改时间',
  primary key (`quota_month_id`),
  unique key `uq_fleet_quota_month_authorization_id_bill_month` (`authorization_id`, `bill_month`),
  constraint `ck_fleet_quota_month_1` check (day(bill_month) = 1),
  constraint `ck_fleet_quota_month_2` check (limit_amount >= 0),
  constraint `ck_fleet_quota_month_3` check (reserved_amount >= 0),
  constraint `ck_fleet_quota_month_4` check (used_amount >= 0)
) engine=InnoDB default charset=utf8mb4 collate=utf8mb4_0900_ai_ci;

-- membership / 订单额度占用
create table `fleet_quota_reservation` (
  `reservation_id` bigint unsigned not null auto_increment comment '主键',
  `order_id` bigint unsigned not null comment '订单唯一',
  `quota_month_id` bigint unsigned not null comment '当前归属月额度',
  `reserved_amount` decimal(14,2) not null comment '本单原预占金额',
  `actual_amount` decimal(14,2) not null default 0.00 comment '最终实际扣额',
  `status` varchar(32) not null default 'reserved' comment '占用状态',
  `reserved_at` datetime(3) not null comment '预占时间',
  `settled_at` datetime(3) null default null comment '结算时间',
  `released_at` datetime(3) null default null comment '释放时间',
  `created_at` datetime(3) not null default current_timestamp(3) comment 'UTC创建时间',
  `updated_at` datetime(3) not null default current_timestamp(3) on update current_timestamp(3) comment 'UTC最后修改时间',
  primary key (`reservation_id`),
  unique key `uq_fleet_quota_reservation_order_id` (`order_id`),
  constraint `ck_fleet_quota_reservation_1` check (reserved_amount > 0),
  constraint `ck_fleet_quota_reservation_2` check (actual_amount >= 0),
  constraint `ck_fleet_quota_reservation_3` check (`status` in ('reserved', 'settled', 'released', 'review_required'))
) engine=InnoDB default charset=utf8mb4 collate=utf8mb4_0900_ai_ci;

-- membership / 角色
create table `sys_role` (
  `role_id` bigint unsigned not null auto_increment comment '主键',
  `role_code` varchar(50) not null comment '固定角色代码',
  `role_name` varchar(50) not null comment '中文名称',
  `created_at` datetime(3) not null default current_timestamp(3) comment 'UTC创建时间',
  `updated_at` datetime(3) not null default current_timestamp(3) on update current_timestamp(3) comment 'UTC最后修改时间',
  primary key (`role_id`),
  unique key `uq_sys_role_role_code` (`role_code`)
) engine=InnoDB default charset=utf8mb4 collate=utf8mb4_0900_ai_ci;

-- membership / 操作权限
create table `sys_permission` (
  `permission_id` bigint unsigned not null auto_increment comment '主键',
  `permission_code` varchar(100) not null comment '模块.资源.动作',
  `permission_name` varchar(100) not null comment '中文说明',
  `created_at` datetime(3) not null default current_timestamp(3) comment 'UTC创建时间',
  `updated_at` datetime(3) not null default current_timestamp(3) on update current_timestamp(3) comment 'UTC最后修改时间',
  primary key (`permission_id`),
  unique key `uq_sys_permission_permission_code` (`permission_code`)
) engine=InnoDB default charset=utf8mb4 collate=utf8mb4_0900_ai_ci;

-- membership / 账号角色
create table `sys_account_role` (
  `account_id` bigint unsigned not null comment '关联编号',
  `role_id` bigint unsigned not null comment '关联编号',
  `created_at` datetime(3) not null default current_timestamp(3) comment 'UTC创建时间',
  `updated_at` datetime(3) not null default current_timestamp(3) on update current_timestamp(3) comment 'UTC最后修改时间',
  primary key (`account_id`, `role_id`)
) engine=InnoDB default charset=utf8mb4 collate=utf8mb4_0900_ai_ci;

-- membership / 角色权限
create table `sys_role_permission` (
  `role_id` bigint unsigned not null comment '关联编号',
  `permission_id` bigint unsigned not null comment '关联编号',
  `created_at` datetime(3) not null default current_timestamp(3) comment 'UTC创建时间',
  `updated_at` datetime(3) not null default current_timestamp(3) on update current_timestamp(3) comment 'UTC最后修改时间',
  primary key (`role_id`, `permission_id`)
) engine=InnoDB default charset=utf8mb4 collate=utf8mb4_0900_ai_ci;

-- membership / 账号运营商范围
create table `sys_account_operator` (
  `account_id` bigint unsigned not null comment '关联编号',
  `operator_id` bigint unsigned not null comment '关联编号',
  `created_at` datetime(3) not null default current_timestamp(3) comment 'UTC创建时间',
  `updated_at` datetime(3) not null default current_timestamp(3) on update current_timestamp(3) comment 'UTC最后修改时间',
  primary key (`account_id`, `operator_id`)
) engine=InnoDB default charset=utf8mb4 collate=utf8mb4_0900_ai_ci;

-- membership / 账号场站范围
create table `sys_account_station` (
  `account_id` bigint unsigned not null comment '关联编号',
  `station_id` bigint unsigned not null comment '关联编号',
  `created_at` datetime(3) not null default current_timestamp(3) comment 'UTC创建时间',
  `updated_at` datetime(3) not null default current_timestamp(3) on update current_timestamp(3) comment 'UTC最后修改时间',
  primary key (`account_id`, `station_id`)
) engine=InnoDB default charset=utf8mb4 collate=utf8mb4_0900_ai_ci;

-- membership / 账号车队范围
create table `sys_account_fleet` (
  `account_id` bigint unsigned not null comment '关联编号',
  `fleet_id` bigint unsigned not null comment '关联编号',
  `created_at` datetime(3) not null default current_timestamp(3) comment 'UTC创建时间',
  `updated_at` datetime(3) not null default current_timestamp(3) on update current_timestamp(3) comment 'UTC最后修改时间',
  primary key (`account_id`, `fleet_id`)
) engine=InnoDB default charset=utf8mb4 collate=utf8mb4_0900_ai_ci;

-- membership / 活动适用场站
create table `promotion_station` (
  `promotion_id` bigint unsigned not null comment '关联编号',
  `station_id` bigint unsigned not null comment '关联编号',
  `created_at` datetime(3) not null default current_timestamp(3) comment 'UTC创建时间',
  `updated_at` datetime(3) not null default current_timestamp(3) on update current_timestamp(3) comment 'UTC最后修改时间',
  primary key (`promotion_id`, `station_id`)
) engine=InnoDB default charset=utf8mb4 collate=utf8mb4_0900_ai_ci;

-- membership / 登录会话
create table `sys_session` (
  `session_id` bigint unsigned not null auto_increment comment '主键',
  `account_id` bigint unsigned not null comment '账号',
  `jti_hash` binary(32) not null comment 'JWT会话标识摘要',
  `expires_at` datetime(3) not null comment '会话到期',
  `revoked_at` datetime(3) null default null comment '退出或禁用时撤销',
  `created_at` datetime(3) not null default current_timestamp(3) comment 'UTC创建时间',
  `updated_at` datetime(3) not null default current_timestamp(3) on update current_timestamp(3) comment 'UTC最后修改时间',
  primary key (`session_id`),
  unique key `uq_sys_session_jti_hash` (`jti_hash`)
) engine=InnoDB default charset=utf8mb4 collate=utf8mb4_0900_ai_ci;

-- membership / 余额流水
create table `wallet_transaction` (
  `wallet_transaction_id` bigint unsigned not null auto_increment comment '主键',
  `user_id` bigint unsigned not null comment '余额用户',
  `payment_id` bigint unsigned null default null comment '余额支付来源',
  `refund_id` bigint unsigned null default null comment '余额退款来源',
  `transaction_type` varchar(32) not null comment '变动种类',
  `amount` decimal(14,2) not null comment '有符号金额 支出为负',
  `balance_after` decimal(14,2) not null comment '交易后余额',
  `business_key` varchar(100) not null comment '业务幂等键',
  `occurred_at` datetime(3) not null comment '发生时间',
  `created_at` datetime(3) not null default current_timestamp(3) comment 'UTC创建时间',
  `updated_at` datetime(3) not null default current_timestamp(3) on update current_timestamp(3) comment 'UTC最后修改时间',
  primary key (`wallet_transaction_id`),
  unique key `uq_wallet_transaction_business_key` (`business_key`),
  constraint `ck_wallet_transaction_1` check (amount <> 0),
  constraint `ck_wallet_transaction_2` check (balance_after >= 0),
  constraint `ck_wallet_transaction_3` check (`transaction_type` in ('mock_topup', 'payment', 'refund'))
) engine=InnoDB default charset=utf8mb4 collate=utf8mb4_0900_ai_ci;

-- membership / 额度变动留痕
create table `fleet_quota_adjustment` (
  `quota_adjustment_id` bigint unsigned not null auto_increment comment '主键',
  `quota_month_id` bigint unsigned not null comment '被影响月份',
  `order_id` bigint unsigned null default null comment '相关订单',
  `refund_id` bigint unsigned null default null comment '退款来源',
  `change_type` varchar(32) not null comment '变化类型',
  `amount` decimal(14,2) not null comment '有符号调整',
  `business_key` varchar(100) not null comment '业务唯一键',
  `reason` varchar(500) not null comment '依据',
  `actor_account_id` bigint unsigned null default null comment '系统任务为空',
  `created_at` datetime(3) not null default current_timestamp(3) comment 'UTC创建时间',
  `updated_at` datetime(3) not null default current_timestamp(3) on update current_timestamp(3) comment 'UTC最后修改时间',
  primary key (`quota_adjustment_id`),
  unique key `uq_fleet_quota_adjustment_business_key` (`business_key`),
  constraint `ck_fleet_quota_adjustment_1` check (`change_type` in ('limit_change', 'month_transfer', 'refund'))
) engine=InnoDB default charset=utf8mb4 collate=utf8mb4_0900_ai_ci;

-- membership / 订单评价
create table `service_feedback` (
  `feedback_id` bigint unsigned not null auto_increment comment '主键',
  `order_id` bigint unsigned not null comment '被评价订单',
  `user_id` bigint unsigned not null comment '评价人',
  `rating` tinyint unsigned not null comment '1至5分',
  `content` varchar(1000) null default null comment '评价内容',
  `created_at` datetime(3) not null default current_timestamp(3) comment 'UTC创建时间',
  `updated_at` datetime(3) not null default current_timestamp(3) on update current_timestamp(3) comment 'UTC最后修改时间',
  primary key (`feedback_id`),
  unique key `uq_service_feedback_order_id` (`order_id`),
  constraint `ck_service_feedback_1` check (rating between 1 and 5)
) engine=InnoDB default charset=utf8mb4 collate=utf8mb4_0900_ai_ci;

-- settlement / 结算分成政策
create table `settlement_policy` (
  `policy_id` bigint unsigned not null auto_increment comment '主键',
  `operator_id` bigint unsigned not null comment '运营商',
  `station_id` bigint unsigned not null comment '场站',
  `electricity_share_rate` decimal(7,6) not null comment '运营商电费分成比例0至1',
  `service_share_rate` decimal(7,6) not null comment '运营商服务费分成比例',
  `platform_fee_rate` decimal(7,6) not null comment '平台收费比例 基数另说明',
  `payment_basis` varchar(32) not null comment '首版仅已付清订单',
  `valid_from` datetime(3) not null comment '生效',
  `valid_until` datetime(3) not null comment '失效',
  `created_at` datetime(3) not null default current_timestamp(3) comment 'UTC创建时间',
  `updated_at` datetime(3) not null default current_timestamp(3) on update current_timestamp(3) comment 'UTC最后修改时间',
  primary key (`policy_id`),
  constraint `ck_settlement_policy_1` check (electricity_share_rate between 0 and 1),
  constraint `ck_settlement_policy_2` check (service_share_rate between 0 and 1),
  constraint `ck_settlement_policy_3` check (platform_fee_rate between 0 and 1),
  constraint `ck_settlement_policy_4` check (valid_until > valid_from),
  constraint `ck_settlement_policy_5` check (`payment_basis` in ('paid_only'))
) engine=InnoDB default charset=utf8mb4 collate=utf8mb4_0900_ai_ci;

-- settlement / 运营商结算单
create table `operator_settlement` (
  `settlement_id` bigint unsigned not null auto_increment comment '主键',
  `operator_id` bigint unsigned not null comment '运营商',
  `station_id` bigint unsigned not null comment '场站',
  `bill_month` date not null comment '账期首日',
  `energy_kwh` decimal(14,3) not null default 0.000 comment '归集电量',
  `electricity_share_amount` decimal(14,2) not null default 0.00 comment '运营商电费分成',
  `service_share_amount` decimal(14,2) not null default 0.00 comment '运营商服务费分成',
  `platform_fee_amount` decimal(14,2) not null default 0.00 comment '平台费用',
  `adjustment_amount` decimal(14,2) not null default 0.00 comment '已生效调整合计 可正负',
  `payable_amount` decimal(14,2) not null default 0.00 comment '应结金额',
  `status` varchar(32) not null default 'draft' comment '结算状态',
  `version` int unsigned not null default 1 comment '对象版本',
  `created_at` datetime(3) not null default current_timestamp(3) comment 'UTC创建时间',
  `updated_at` datetime(3) not null default current_timestamp(3) on update current_timestamp(3) comment 'UTC最后修改时间',
  primary key (`settlement_id`),
  unique key `uq_operator_settlement_operator_id_station_id_bill_month` (`operator_id`, `station_id`, `bill_month`),
  constraint `ck_operator_settlement_1` check (day(bill_month) = 1),
  constraint `ck_operator_settlement_2` check (version > 0),
  constraint `ck_operator_settlement_3` check (`status` in ('draft', 'pending_confirmation', 'confirmed', 'invoiced', 'closed'))
) engine=InnoDB default charset=utf8mb4 collate=utf8mb4_0900_ai_ci;

-- settlement / 运营商结算明细
create table `settlement_item` (
  `settlement_item_id` bigint unsigned not null auto_increment comment '主键',
  `settlement_id` bigint unsigned not null comment '结算单',
  `order_id` bigint unsigned not null comment '来源订单',
  `refund_id` bigint unsigned null default null comment '退款冲减来源',
  `policy_id` bigint unsigned not null comment '计算使用的政策版本',
  `item_type` varchar(32) not null comment '条目类型',
  `occurred_at` datetime(3) not null comment '归集事实时间',
  `net_amount` decimal(14,2) not null comment '优惠退款后净额 可负',
  `electricity_share_amount` decimal(14,2) not null comment '本条分成 可负',
  `service_share_amount` decimal(14,2) not null comment '本条服务分成 可负',
  `platform_fee_amount` decimal(14,2) not null comment '本条平台费 可负',
  `payable_amount` decimal(14,2) not null comment '本条应结 可负',
  `business_key` varchar(100) not null comment 'order或refund来源唯一键',
  `created_at` datetime(3) not null default current_timestamp(3) comment 'UTC创建时间',
  `updated_at` datetime(3) not null default current_timestamp(3) on update current_timestamp(3) comment 'UTC最后修改时间',
  primary key (`settlement_item_id`),
  unique key `uq_settlement_item_business_key` (`business_key`),
  constraint `ck_settlement_item_1` check ((item_type='order' and refund_id is null) or (item_type='refund' and refund_id is not null)),
  constraint `ck_settlement_item_2` check (`item_type` in ('order', 'refund'))
) engine=InnoDB default charset=utf8mb4 collate=utf8mb4_0900_ai_ci;

-- settlement / 对账差异
create table `reconciliation_difference` (
  `difference_id` bigint unsigned not null auto_increment comment '主键',
  `settlement_id` bigint unsigned not null comment '所属结算单',
  `order_id` bigint unsigned not null comment '具体订单',
  `difference_type` varchar(32) not null comment '电量不符 价格不符 支付问题',
  `amount` decimal(14,2) not null comment '差异金额 可正负',
  `resolution` varchar(1000) null default null comment '处理结论',
  `status` varchar(32) not null default 'open' comment '生效状态',
  `version` int unsigned not null default 1 comment '结论版本',
  `created_at` datetime(3) not null default current_timestamp(3) comment 'UTC创建时间',
  `updated_at` datetime(3) not null default current_timestamp(3) on update current_timestamp(3) comment 'UTC最后修改时间',
  primary key (`difference_id`),
  constraint `ck_reconciliation_difference_1` check (version > 0),
  constraint `ck_reconciliation_difference_2` check (`difference_type` in ('energy', 'price', 'payment')),
  constraint `ck_reconciliation_difference_3` check (`status` in ('open', 'pending_confirmation', 'effective', 'rejected'))
) engine=InnoDB default charset=utf8mb4 collate=utf8mb4_0900_ai_ci;

-- settlement / 双方确认历史
create table `reconciliation_confirmation` (
  `confirmation_id` bigint unsigned not null auto_increment comment '主键',
  `settlement_id` bigint unsigned null default null comment '确认结算单',
  `difference_id` bigint unsigned null default null comment '确认差异',
  `object_version` int unsigned not null comment '对象版本',
  `side` varchar(32) not null comment '后端推导确认方',
  `decision` varchar(32) not null comment '同意或异议',
  `confirmed_by` bigint unsigned not null comment '操作账号',
  `confirmed_at` datetime(3) not null comment '确认时间',
  `note` varchar(1000) null default null comment '意见',
  `is_current` tinyint unsigned not null default 1 comment '本版本本方当前有效结果',
  `created_at` datetime(3) not null default current_timestamp(3) comment 'UTC创建时间',
  `updated_at` datetime(3) not null default current_timestamp(3) on update current_timestamp(3) comment 'UTC最后修改时间',
  `current_key` varchar(120) generated always as (case when is_current = 1 then concat(if(settlement_id is not null,'S','D'), ':', coalesce(settlement_id,difference_id), ':', object_version, ':', side) else null end) stored comment '当前对象版本确认方唯一',
  primary key (`confirmation_id`),
  unique key `uq_reconciliation_confirmation_current_key` (`current_key`),
  constraint `ck_reconciliation_confirmation_1` check ((settlement_id is not null) + (difference_id is not null) = 1),
  constraint `ck_reconciliation_confirmation_2` check (object_version > 0),
  constraint `ck_reconciliation_confirmation_3` check (`side` in ('platform', 'operator')),
  constraint `ck_reconciliation_confirmation_4` check (`decision` in ('confirmed', 'disputed')),
  constraint `ck_reconciliation_confirmation_5` check (`is_current` in (0, 1))
) engine=InnoDB default charset=utf8mb4 collate=utf8mb4_0900_ai_ci;

-- settlement / 结算调整
create table `settlement_adjustment` (
  `adjustment_id` bigint unsigned not null auto_increment comment '主键',
  `settlement_id` bigint unsigned not null comment '结算单',
  `difference_id` bigint unsigned null default null comment '来源差异',
  `amount` decimal(14,2) not null comment '调整金额 可正负',
  `reason` varchar(1000) not null comment '依据',
  `status` varchar(32) not null default 'pending' comment '审批状态',
  `requested_by` bigint unsigned not null comment '发起人',
  `approved_by` bigint unsigned null default null comment '审批人',
  `approved_at` datetime(3) null default null comment '生效审批时间',
  `created_at` datetime(3) not null default current_timestamp(3) comment 'UTC创建时间',
  `updated_at` datetime(3) not null default current_timestamp(3) on update current_timestamp(3) comment 'UTC最后修改时间',
  primary key (`adjustment_id`),
  constraint `ck_settlement_adjustment_1` check (amount <> 0),
  constraint `ck_settlement_adjustment_2` check (`status` in ('pending', 'approved', 'rejected'))
) engine=InnoDB default charset=utf8mb4 collate=utf8mb4_0900_ai_ci;

-- settlement / 运营商结算发票
create table `operator_invoice` (
  `invoice_id` bigint unsigned not null auto_increment comment '主键',
  `settlement_id` bigint unsigned not null comment '结算单',
  `original_invoice_id` bigint unsigned null default null comment '红冲关联原票',
  `invoice_no` varchar(64) not null comment '模拟票号',
  `invoice_type` varchar(32) not null comment '正票或红票',
  `title` varchar(100) not null comment '抬头',
  `tax_no` varchar(30) not null comment '税号',
  `amount` decimal(14,2) not null comment '正数票面额 红票由类型表达冲减',
  `status` varchar(32) not null comment '开票结果',
  `issued_at` datetime(3) not null comment '开具时间',
  `issued_by` bigint unsigned not null comment '办理账号',
  `created_at` datetime(3) not null default current_timestamp(3) comment 'UTC创建时间',
  `updated_at` datetime(3) not null default current_timestamp(3) on update current_timestamp(3) comment 'UTC最后修改时间',
  primary key (`invoice_id`),
  unique key `uq_operator_invoice_invoice_no` (`invoice_no`),
  constraint `ck_operator_invoice_1` check (amount > 0),
  constraint `ck_operator_invoice_2` check ((invoice_type='blue' and original_invoice_id is null) or (invoice_type='red' and original_invoice_id is not null)),
  constraint `ck_operator_invoice_3` check (`invoice_type` in ('blue', 'red')),
  constraint `ck_operator_invoice_4` check (`status` in ('issued', 'red_issued'))
) engine=InnoDB default charset=utf8mb4 collate=utf8mb4_0900_ai_ci;

-- settlement / 车主消费发票
create table `user_invoice` (
  `user_invoice_id` bigint unsigned not null auto_increment comment '主键',
  `user_id` bigint unsigned not null comment '申请人',
  `original_user_invoice_id` bigint unsigned null default null comment '红冲原票',
  `invoice_no` varchar(64) null default null comment '开票后唯一',
  `invoice_type` varchar(32) not null default 'blue' comment '票种',
  `title` varchar(100) not null comment '抬头',
  `tax_no` varchar(30) null default null comment '企业税号 可空',
  `amount` decimal(14,2) not null comment '总额',
  `status` varchar(32) not null default 'requested' comment '办理状态',
  `requested_at` datetime(3) not null comment '申请时间',
  `issued_at` datetime(3) null default null comment '开具时间',
  `handled_by` bigint unsigned null default null comment '办理人员',
  `created_at` datetime(3) not null default current_timestamp(3) comment 'UTC创建时间',
  `updated_at` datetime(3) not null default current_timestamp(3) on update current_timestamp(3) comment 'UTC最后修改时间',
  primary key (`user_invoice_id`),
  unique key `uq_user_invoice_invoice_no` (`invoice_no`),
  constraint `ck_user_invoice_1` check (amount > 0),
  constraint `ck_user_invoice_2` check ((invoice_type='blue' and original_user_invoice_id is null) or (invoice_type='red' and original_user_invoice_id is not null)),
  constraint `ck_user_invoice_3` check (`invoice_type` in ('blue', 'red')),
  constraint `ck_user_invoice_4` check (`status` in ('requested', 'issued', 'rejected', 'red_issued'))
) engine=InnoDB default charset=utf8mb4 collate=utf8mb4_0900_ai_ci;

-- settlement / 消费发票订单分配
create table `user_invoice_item` (
  `user_invoice_item_id` bigint unsigned not null auto_increment comment '主键',
  `user_invoice_id` bigint unsigned not null comment '发票',
  `order_id` bigint unsigned not null comment '订单',
  `allocated_amount` decimal(14,2) not null comment '本订单分配金额',
  `status` varchar(32) not null default 'reserved' comment '占用开票额度状态',
  `created_at` datetime(3) not null default current_timestamp(3) comment 'UTC创建时间',
  `updated_at` datetime(3) not null default current_timestamp(3) on update current_timestamp(3) comment 'UTC最后修改时间',
  primary key (`user_invoice_item_id`),
  unique key `uq_user_invoice_item_user_invoice_id_order_id` (`user_invoice_id`, `order_id`),
  constraint `ck_user_invoice_item_1` check (allocated_amount > 0),
  constraint `ck_user_invoice_item_2` check (`status` in ('reserved', 'effective', 'released'))
) engine=InnoDB default charset=utf8mb4 collate=utf8mb4_0900_ai_ci;

-- settlement / 车队月结单
create table `fleet_monthly_bill` (
  `bill_id` bigint unsigned not null auto_increment comment '主键',
  `fleet_id` bigint unsigned not null comment '所属车队',
  `bill_month` date not null comment '账期首日',
  `order_amount` decimal(14,2) not null default 0.00 comment '原订单费用合计',
  `adjustment_amount` decimal(14,2) not null default 0.00 comment '退款等调整 可负',
  `payable_amount` decimal(14,2) not null default 0.00 comment '应付净额 可负余额结转',
  `paid_amount` decimal(14,2) not null default 0.00 comment '已确认企业结算收款',
  `status` varchar(32) not null default 'draft' comment '账单状态',
  `created_at` datetime(3) not null default current_timestamp(3) comment 'UTC创建时间',
  `updated_at` datetime(3) not null default current_timestamp(3) on update current_timestamp(3) comment 'UTC最后修改时间',
  primary key (`bill_id`),
  unique key `uq_fleet_monthly_bill_fleet_id_bill_month` (`fleet_id`, `bill_month`),
  constraint `ck_fleet_monthly_bill_1` check (day(bill_month) = 1),
  constraint `ck_fleet_monthly_bill_2` check (paid_amount >= 0),
  constraint `ck_fleet_monthly_bill_3` check (`status` in ('draft', 'issued', 'partially_paid', 'paid', 'closed'))
) engine=InnoDB default charset=utf8mb4 collate=utf8mb4_0900_ai_ci;

-- settlement / 车队月结明细
create table `fleet_monthly_bill_item` (
  `bill_item_id` bigint unsigned not null auto_increment comment '主键',
  `bill_id` bigint unsigned not null comment '月结单',
  `order_id` bigint unsigned not null comment '原订单',
  `refund_id` bigint unsigned null default null comment '退款来源',
  `item_type` varchar(32) not null comment '订单 退款或负额结转',
  `occurred_at` datetime(3) not null comment '条目发生时间',
  `amount` decimal(14,2) not null comment '订单为正 退款为负',
  `original_order_finished_at` datetime(3) not null comment '原订单结束快照',
  `business_key` varchar(100) not null comment '来源唯一键',
  `source_bill_id` bigint unsigned null default null comment 'credit_carry原账单；其他条目为空',
  `created_at` datetime(3) not null default current_timestamp(3) comment 'UTC创建时间',
  `updated_at` datetime(3) not null default current_timestamp(3) on update current_timestamp(3) comment 'UTC最后修改时间',
  primary key (`bill_item_id`),
  unique key `uq_fleet_monthly_bill_item_business_key` (`business_key`),
  constraint `ck_fleet_monthly_bill_item_1` check ((item_type='refund' and refund_id is not null) or (item_type<>'refund' and refund_id is null)),
  constraint `ck_fleet_monthly_bill_item_2` check ((item_type='credit_carry' and source_bill_id is not null) or (item_type<>'credit_carry' and source_bill_id is null)),
  constraint `ck_fleet_monthly_bill_item_3` check (`item_type` in ('order', 'refund', 'credit_carry', 'adjustment'))
) engine=InnoDB default charset=utf8mb4 collate=utf8mb4_0900_ai_ci;

-- settlement / 车队专价
create table `fleet_price` (
  `price_id` bigint unsigned not null auto_increment comment '主键',
  `fleet_id` bigint unsigned not null comment '车队',
  `period_id` bigint unsigned not null comment '时段 由此确定场站',
  `electricity_rate` decimal(12,4) not null comment '专属电价',
  `service_rate` decimal(12,4) not null comment '专属服务费单价',
  `valid_from` datetime(3) not null comment '生效',
  `valid_until` datetime(3) not null comment '失效',
  `status` varchar(32) not null default 'draft' comment '启用状态',
  `created_at` datetime(3) not null default current_timestamp(3) comment 'UTC创建时间',
  `updated_at` datetime(3) not null default current_timestamp(3) on update current_timestamp(3) comment 'UTC最后修改时间',
  primary key (`price_id`),
  key `ix_fleet_price_fleet_id_period_id_valid_from` (`fleet_id`, `period_id`, `valid_from`),
  constraint `ck_fleet_price_1` check (valid_until > valid_from),
  constraint `ck_fleet_price_2` check (electricity_rate >= 0),
  constraint `ck_fleet_price_3` check (service_rate >= 0),
  constraint `ck_fleet_price_4` check (`status` in ('draft', 'active', 'disabled'))
) engine=InnoDB default charset=utf8mb4 collate=utf8mb4_0900_ai_ci;

-- settlement / 企业月结收款
create table `fleet_bill_payment` (
  `bill_payment_id` bigint unsigned not null auto_increment comment '主键',
  `bill_id` bigint unsigned not null comment '账单',
  `external_trade_no` varchar(80) not null comment '企业模拟结算流水',
  `amount` decimal(14,2) not null comment '实际企业收款 纯账单抵扣允许0',
  `status` varchar(32) not null default 'pending' comment '支付状态',
  `paid_at` datetime(3) null default null comment '成功时间',
  `recorded_by` bigint unsigned not null comment '办理账号',
  `created_at` datetime(3) not null default current_timestamp(3) comment 'UTC创建时间',
  `updated_at` datetime(3) not null default current_timestamp(3) on update current_timestamp(3) comment 'UTC最后修改时间',
  primary key (`bill_payment_id`),
  unique key `uq_fleet_bill_payment_external_trade_no` (`external_trade_no`),
  constraint `ck_fleet_bill_payment_1` check (amount >= 0),
  constraint `ck_fleet_bill_payment_2` check (`status` in ('pending', 'succeeded', 'failed'))
) engine=InnoDB default charset=utf8mb4 collate=utf8mb4_0900_ai_ci;

-- common / 请求幂等记录
create table `request_dedup` (
  `dedup_id` bigint unsigned not null auto_increment comment '主键',
  `account_id` bigint unsigned not null comment '调用账号',
  `operation` varchar(100) not null comment '模块函数名',
  `idempotency_key` varchar(64) not null comment '客户端重试键',
  `request_hash` binary(32) not null comment '规范化请求摘要',
  `response_status` smallint unsigned null default null comment '已完成HTTP状态',
  `response_body` json null default null comment '可重放脱敏结果',
  `status` varchar(32) not null default 'processing' comment '处理状态',
  `expires_at` datetime(3) not null comment '过期清理时间',
  `created_at` datetime(3) not null default current_timestamp(3) comment 'UTC创建时间',
  `updated_at` datetime(3) not null default current_timestamp(3) on update current_timestamp(3) comment 'UTC最后修改时间',
  primary key (`dedup_id`),
  unique key `uq_request_dedup_account_id_operation_idempotency_key` (`account_id`, `operation`, `idempotency_key`),
  constraint `ck_request_dedup_1` check (`status` in ('processing', 'completed'))
) engine=InnoDB default charset=utf8mb4 collate=utf8mb4_0900_ai_ci;

-- common / 站内通知待办
create table `notification` (
  `notification_id` bigint unsigned not null auto_increment comment '主键',
  `account_id` bigint unsigned not null comment '接收账号',
  `notification_type` varchar(50) not null comment 'offline work_order settlement等',
  `business_key` varchar(120) not null comment '业务事件唯一键',
  `title` varchar(100) not null comment '标题',
  `content` varchar(1000) not null comment '脱敏内容',
  `target_path` varchar(255) not null comment '允许的前端相对路径',
  `read_at` datetime(3) null default null comment '已读时间',
  `created_at` datetime(3) not null default current_timestamp(3) comment 'UTC创建时间',
  `updated_at` datetime(3) not null default current_timestamp(3) on update current_timestamp(3) comment 'UTC最后修改时间',
  primary key (`notification_id`),
  unique key `uq_notification_account_id_business_key` (`account_id`, `business_key`)
) engine=InnoDB default charset=utf8mb4 collate=utf8mb4_0900_ai_ci;

-- common / 提交后任务事件
create table `outbox_event` (
  `outbox_id` bigint unsigned not null auto_increment comment '主键',
  `event_type` varchar(50) not null comment '设备命令或通知类型',
  `business_key` varchar(120) not null comment '唯一事件键',
  `payload` json not null comment '必要业务编号 不含密钥',
  `status` varchar(32) not null default 'pending' comment '消费状态',
  `attempt_count` int unsigned not null default 0 comment '重试次数',
  `available_at` datetime(3) not null comment '可执行时间',
  `locked_until` datetime(3) null default null comment '消费者租约',
  `last_error` varchar(500) null default null comment '最近失败说明',
  `created_at` datetime(3) not null default current_timestamp(3) comment 'UTC创建时间',
  `updated_at` datetime(3) not null default current_timestamp(3) on update current_timestamp(3) comment 'UTC最后修改时间',
  primary key (`outbox_id`),
  unique key `uq_outbox_event_business_key` (`business_key`),
  key `ix_outbox_event_status_available_at` (`status`, `available_at`),
  constraint `ck_outbox_event_1` check (`status` in ('pending', 'processing', 'done', 'failed'))
) engine=InnoDB default charset=utf8mb4 collate=utf8mb4_0900_ai_ci;

-- assets / 设备模拟凭据
create table `device_credential` (
  `credential_id` bigint unsigned not null auto_increment comment '主键',
  `pile_id` bigint unsigned not null comment '凭据绑定桩',
  `token_hash` binary(32) not null comment '设备令牌摘要 不存原令牌',
  `expires_at` datetime(3) not null comment '到期时间',
  `revoked_at` datetime(3) null default null comment '撤销时间',
  `created_at` datetime(3) not null default current_timestamp(3) comment 'UTC创建时间',
  `updated_at` datetime(3) not null default current_timestamp(3) on update current_timestamp(3) comment 'UTC最后修改时间',
  primary key (`credential_id`),
  unique key `uq_device_credential_token_hash` (`token_hash`)
) engine=InnoDB default charset=utf8mb4 collate=utf8mb4_0900_ai_ci;

-- 所有表建成后添加物理外键，全部restrict，不级联删除财务或历史。
alter table `station` add constraint `fk_station_operator_id` foreign key (`operator_id`) references `operator` (`operator_id`) on delete restrict on update restrict;
alter table `charging_pile` add constraint `fk_charging_pile_station_id` foreign key (`station_id`) references `station` (`station_id`) on delete restrict on update restrict;
alter table `charging_gun` add constraint `fk_charging_gun_pile_id` foreign key (`pile_id`) references `charging_pile` (`pile_id`) on delete restrict on update restrict;
alter table `device_status_log` add constraint `fk_device_status_log_pile_id` foreign key (`pile_id`) references `charging_pile` (`pile_id`) on delete restrict on update restrict;
alter table `device_status_log` add constraint `fk_device_status_log_gun_id` foreign key (`gun_id`) references `charging_gun` (`gun_id`) on delete restrict on update restrict;
alter table `device_status_log` add constraint `fk_device_status_log_actor_account_id` foreign key (`actor_account_id`) references `sys_account` (`account_id`) on delete restrict on update restrict;
alter table `equipment_change_request` add constraint `fk_equipment_change_request_pile_id` foreign key (`pile_id`) references `charging_pile` (`pile_id`) on delete restrict on update restrict;
alter table `equipment_change_request` add constraint `fk_equipment_change_request_gun_id` foreign key (`gun_id`) references `charging_gun` (`gun_id`) on delete restrict on update restrict;
alter table `equipment_change_request` add constraint `fk_equipment_change_request_requested_by` foreign key (`requested_by`) references `sys_account` (`account_id`) on delete restrict on update restrict;
alter table `equipment_change_request` add constraint `fk_equipment_change_request_reviewed_by` foreign key (`reviewed_by`) references `sys_account` (`account_id`) on delete restrict on update restrict;
alter table `device_acceptance` add constraint `fk_device_acceptance_pile_id` foreign key (`pile_id`) references `charging_pile` (`pile_id`) on delete restrict on update restrict;
alter table `device_acceptance` add constraint `fk_device_acceptance_accepted_by` foreign key (`accepted_by`) references `sys_account` (`account_id`) on delete restrict on update restrict;
alter table `device_command` add constraint `fk_device_command_pile_id` foreign key (`pile_id`) references `charging_pile` (`pile_id`) on delete restrict on update restrict;
alter table `device_command` add constraint `fk_device_command_gun_id` foreign key (`gun_id`) references `charging_gun` (`gun_id`) on delete restrict on update restrict;
alter table `device_command` add constraint `fk_device_command_order_id` foreign key (`order_id`) references `charging_order` (`order_id`) on delete restrict on update restrict;
alter table `pricing_rule` add constraint `fk_pricing_rule_station_id` foreign key (`station_id`) references `station` (`station_id`) on delete restrict on update restrict;
alter table `pricing_period` add constraint `fk_pricing_period_rule_id` foreign key (`rule_id`) references `pricing_rule` (`rule_id`) on delete restrict on update restrict;
alter table `charging_order` add constraint `fk_charging_order_user_id` foreign key (`user_id`) references `app_user` (`user_id`) on delete restrict on update restrict;
alter table `charging_order` add constraint `fk_charging_order_gun_id` foreign key (`gun_id`) references `charging_gun` (`gun_id`) on delete restrict on update restrict;
alter table `charging_order` add constraint `fk_charging_order_vehicle_id` foreign key (`vehicle_id`) references `vehicle` (`vehicle_id`) on delete restrict on update restrict;
alter table `charging_order` add constraint `fk_charging_order_authorization_id` foreign key (`authorization_id`) references `fleet_authorization` (`authorization_id`) on delete restrict on update restrict;
alter table `charging_order` add constraint `fk_charging_order_rule_id` foreign key (`rule_id`) references `pricing_rule` (`rule_id`) on delete restrict on update restrict;
alter table `charging_order` add constraint `fk_charging_order_operator_id` foreign key (`operator_id`) references `operator` (`operator_id`) on delete restrict on update restrict;
alter table `charging_order` add constraint `fk_charging_order_station_id` foreign key (`station_id`) references `station` (`station_id`) on delete restrict on update restrict;
alter table `charging_order` add constraint `fk_charging_order_fleet_id` foreign key (`fleet_id`) references `fleet` (`fleet_id`) on delete restrict on update restrict;
alter table `charging_order` add constraint `fk_charging_order_settlement_id` foreign key (`settlement_id`) references `operator_settlement` (`settlement_id`) on delete restrict on update restrict;
alter table `meter_reading` add constraint `fk_meter_reading_order_id` foreign key (`order_id`) references `charging_order` (`order_id`) on delete restrict on update restrict;
alter table `billing_detail` add constraint `fk_billing_detail_order_id` foreign key (`order_id`) references `charging_order` (`order_id`) on delete restrict on update restrict;
alter table `billing_detail` add constraint `fk_billing_detail_period_id` foreign key (`period_id`) references `pricing_period` (`period_id`) on delete restrict on update restrict;
alter table `billing_detail` add constraint `fk_billing_detail_price_id` foreign key (`price_id`) references `fleet_price` (`price_id`) on delete restrict on update restrict;
alter table `payment_record` add constraint `fk_payment_record_order_id` foreign key (`order_id`) references `charging_order` (`order_id`) on delete restrict on update restrict;
alter table `payment_record` add constraint `fk_payment_record_bill_payment_id` foreign key (`bill_payment_id`) references `fleet_bill_payment` (`bill_payment_id`) on delete restrict on update restrict;
alter table `refund_record` add constraint `fk_refund_record_payment_id` foreign key (`payment_id`) references `payment_record` (`payment_id`) on delete restrict on update restrict;
alter table `refund_record` add constraint `fk_refund_record_requested_by` foreign key (`requested_by`) references `sys_account` (`account_id`) on delete restrict on update restrict;
alter table `order_review` add constraint `fk_order_review_order_id` foreign key (`order_id`) references `charging_order` (`order_id`) on delete restrict on update restrict;
alter table `order_review` add constraint `fk_order_review_reviewed_by` foreign key (`reviewed_by`) references `sys_account` (`account_id`) on delete restrict on update restrict;
alter table `device_alert` add constraint `fk_device_alert_pile_id` foreign key (`pile_id`) references `charging_pile` (`pile_id`) on delete restrict on update restrict;
alter table `device_alert` add constraint `fk_device_alert_gun_id` foreign key (`gun_id`) references `charging_gun` (`gun_id`) on delete restrict on update restrict;
alter table `device_alert` add constraint `fk_device_alert_alarm_rule_id` foreign key (`alarm_rule_id`) references `alarm_rule` (`alarm_rule_id`) on delete restrict on update restrict;
alter table `work_order` add constraint `fk_work_order_alert_id` foreign key (`alert_id`) references `device_alert` (`alert_id`) on delete restrict on update restrict;
alter table `work_order` add constraint `fk_work_order_assigned_to` foreign key (`assigned_to`) references `sys_account` (`account_id`) on delete restrict on update restrict;
alter table `work_order` add constraint `fk_work_order_assigned_by` foreign key (`assigned_by`) references `sys_account` (`account_id`) on delete restrict on update restrict;
alter table `work_order_event` add constraint `fk_work_order_event_work_order_id` foreign key (`work_order_id`) references `work_order` (`work_order_id`) on delete restrict on update restrict;
alter table `work_order_event` add constraint `fk_work_order_event_actor_account_id` foreign key (`actor_account_id`) references `sys_account` (`account_id`) on delete restrict on update restrict;
alter table `fault_report` add constraint `fk_fault_report_user_id` foreign key (`user_id`) references `app_user` (`user_id`) on delete restrict on update restrict;
alter table `fault_report` add constraint `fk_fault_report_gun_id` foreign key (`gun_id`) references `charging_gun` (`gun_id`) on delete restrict on update restrict;
alter table `fault_report` add constraint `fk_fault_report_order_id` foreign key (`order_id`) references `charging_order` (`order_id`) on delete restrict on update restrict;
alter table `fault_report` add constraint `fk_fault_report_alert_id` foreign key (`alert_id`) references `device_alert` (`alert_id`) on delete restrict on update restrict;
alter table `fault_report` add constraint `fk_fault_report_handled_by` foreign key (`handled_by`) references `sys_account` (`account_id`) on delete restrict on update restrict;
alter table `inspection_record` add constraint `fk_inspection_record_pile_id` foreign key (`pile_id`) references `charging_pile` (`pile_id`) on delete restrict on update restrict;
alter table `inspection_record` add constraint `fk_inspection_record_inspected_by` foreign key (`inspected_by`) references `sys_account` (`account_id`) on delete restrict on update restrict;
alter table `app_user` add constraint `fk_app_user_account_id` foreign key (`account_id`) references `sys_account` (`account_id`) on delete restrict on update restrict;
alter table `vehicle_binding` add constraint `fk_vehicle_binding_user_id` foreign key (`user_id`) references `app_user` (`user_id`) on delete restrict on update restrict;
alter table `vehicle_binding` add constraint `fk_vehicle_binding_vehicle_id` foreign key (`vehicle_id`) references `vehicle` (`vehicle_id`) on delete restrict on update restrict;
alter table `promotion` add constraint `fk_promotion_created_by` foreign key (`created_by`) references `sys_account` (`account_id`) on delete restrict on update restrict;
alter table `promotion` add constraint `fk_promotion_reviewed_by` foreign key (`reviewed_by`) references `sys_account` (`account_id`) on delete restrict on update restrict;
alter table `user_coupon` add constraint `fk_user_coupon_promotion_id` foreign key (`promotion_id`) references `promotion` (`promotion_id`) on delete restrict on update restrict;
alter table `user_coupon` add constraint `fk_user_coupon_user_id` foreign key (`user_id`) references `app_user` (`user_id`) on delete restrict on update restrict;
alter table `user_coupon` add constraint `fk_user_coupon_reissue_source_order_id` foreign key (`reissue_source_order_id`) references `charging_order` (`order_id`) on delete restrict on update restrict;
alter table `coupon_usage` add constraint `fk_coupon_usage_coupon_id` foreign key (`coupon_id`) references `user_coupon` (`coupon_id`) on delete restrict on update restrict;
alter table `coupon_usage` add constraint `fk_coupon_usage_order_id` foreign key (`order_id`) references `charging_order` (`order_id`) on delete restrict on update restrict;
alter table `fleet_card` add constraint `fk_fleet_card_fleet_id` foreign key (`fleet_id`) references `fleet` (`fleet_id`) on delete restrict on update restrict;
alter table `fleet_authorization` add constraint `fk_fleet_authorization_card_id` foreign key (`card_id`) references `fleet_card` (`card_id`) on delete restrict on update restrict;
alter table `fleet_authorization` add constraint `fk_fleet_authorization_user_id` foreign key (`user_id`) references `app_user` (`user_id`) on delete restrict on update restrict;
alter table `fleet_authorization` add constraint `fk_fleet_authorization_vehicle_id` foreign key (`vehicle_id`) references `vehicle` (`vehicle_id`) on delete restrict on update restrict;
alter table `fleet_quota_month` add constraint `fk_fleet_quota_month_authorization_id` foreign key (`authorization_id`) references `fleet_authorization` (`authorization_id`) on delete restrict on update restrict;
alter table `fleet_quota_reservation` add constraint `fk_fleet_quota_reservation_order_id` foreign key (`order_id`) references `charging_order` (`order_id`) on delete restrict on update restrict;
alter table `fleet_quota_reservation` add constraint `fk_fleet_quota_reservation_quota_month_id` foreign key (`quota_month_id`) references `fleet_quota_month` (`quota_month_id`) on delete restrict on update restrict;
alter table `sys_account_role` add constraint `fk_sys_account_role_account_id` foreign key (`account_id`) references `sys_account` (`account_id`) on delete restrict on update restrict;
alter table `sys_account_role` add constraint `fk_sys_account_role_role_id` foreign key (`role_id`) references `sys_role` (`role_id`) on delete restrict on update restrict;
alter table `sys_role_permission` add constraint `fk_sys_role_permission_role_id` foreign key (`role_id`) references `sys_role` (`role_id`) on delete restrict on update restrict;
alter table `sys_role_permission` add constraint `fk_sys_role_permission_permission_id` foreign key (`permission_id`) references `sys_permission` (`permission_id`) on delete restrict on update restrict;
alter table `sys_account_operator` add constraint `fk_sys_account_operator_account_id` foreign key (`account_id`) references `sys_account` (`account_id`) on delete restrict on update restrict;
alter table `sys_account_operator` add constraint `fk_sys_account_operator_operator_id` foreign key (`operator_id`) references `operator` (`operator_id`) on delete restrict on update restrict;
alter table `sys_account_station` add constraint `fk_sys_account_station_account_id` foreign key (`account_id`) references `sys_account` (`account_id`) on delete restrict on update restrict;
alter table `sys_account_station` add constraint `fk_sys_account_station_station_id` foreign key (`station_id`) references `station` (`station_id`) on delete restrict on update restrict;
alter table `sys_account_fleet` add constraint `fk_sys_account_fleet_account_id` foreign key (`account_id`) references `sys_account` (`account_id`) on delete restrict on update restrict;
alter table `sys_account_fleet` add constraint `fk_sys_account_fleet_fleet_id` foreign key (`fleet_id`) references `fleet` (`fleet_id`) on delete restrict on update restrict;
alter table `promotion_station` add constraint `fk_promotion_station_promotion_id` foreign key (`promotion_id`) references `promotion` (`promotion_id`) on delete restrict on update restrict;
alter table `promotion_station` add constraint `fk_promotion_station_station_id` foreign key (`station_id`) references `station` (`station_id`) on delete restrict on update restrict;
alter table `sys_session` add constraint `fk_sys_session_account_id` foreign key (`account_id`) references `sys_account` (`account_id`) on delete restrict on update restrict;
alter table `wallet_transaction` add constraint `fk_wallet_transaction_user_id` foreign key (`user_id`) references `app_user` (`user_id`) on delete restrict on update restrict;
alter table `wallet_transaction` add constraint `fk_wallet_transaction_payment_id` foreign key (`payment_id`) references `payment_record` (`payment_id`) on delete restrict on update restrict;
alter table `wallet_transaction` add constraint `fk_wallet_transaction_refund_id` foreign key (`refund_id`) references `refund_record` (`refund_id`) on delete restrict on update restrict;
alter table `fleet_quota_adjustment` add constraint `fk_fleet_quota_adjustment_quota_month_id` foreign key (`quota_month_id`) references `fleet_quota_month` (`quota_month_id`) on delete restrict on update restrict;
alter table `fleet_quota_adjustment` add constraint `fk_fleet_quota_adjustment_order_id` foreign key (`order_id`) references `charging_order` (`order_id`) on delete restrict on update restrict;
alter table `fleet_quota_adjustment` add constraint `fk_fleet_quota_adjustment_refund_id` foreign key (`refund_id`) references `refund_record` (`refund_id`) on delete restrict on update restrict;
alter table `fleet_quota_adjustment` add constraint `fk_fleet_quota_adjustment_actor_account_id` foreign key (`actor_account_id`) references `sys_account` (`account_id`) on delete restrict on update restrict;
alter table `service_feedback` add constraint `fk_service_feedback_order_id` foreign key (`order_id`) references `charging_order` (`order_id`) on delete restrict on update restrict;
alter table `service_feedback` add constraint `fk_service_feedback_user_id` foreign key (`user_id`) references `app_user` (`user_id`) on delete restrict on update restrict;
alter table `settlement_policy` add constraint `fk_settlement_policy_operator_id` foreign key (`operator_id`) references `operator` (`operator_id`) on delete restrict on update restrict;
alter table `settlement_policy` add constraint `fk_settlement_policy_station_id` foreign key (`station_id`) references `station` (`station_id`) on delete restrict on update restrict;
alter table `operator_settlement` add constraint `fk_operator_settlement_operator_id` foreign key (`operator_id`) references `operator` (`operator_id`) on delete restrict on update restrict;
alter table `operator_settlement` add constraint `fk_operator_settlement_station_id` foreign key (`station_id`) references `station` (`station_id`) on delete restrict on update restrict;
alter table `settlement_item` add constraint `fk_settlement_item_settlement_id` foreign key (`settlement_id`) references `operator_settlement` (`settlement_id`) on delete restrict on update restrict;
alter table `settlement_item` add constraint `fk_settlement_item_order_id` foreign key (`order_id`) references `charging_order` (`order_id`) on delete restrict on update restrict;
alter table `settlement_item` add constraint `fk_settlement_item_refund_id` foreign key (`refund_id`) references `refund_record` (`refund_id`) on delete restrict on update restrict;
alter table `settlement_item` add constraint `fk_settlement_item_policy_id` foreign key (`policy_id`) references `settlement_policy` (`policy_id`) on delete restrict on update restrict;
alter table `reconciliation_difference` add constraint `fk_reconciliation_difference_settlement_id` foreign key (`settlement_id`) references `operator_settlement` (`settlement_id`) on delete restrict on update restrict;
alter table `reconciliation_difference` add constraint `fk_reconciliation_difference_order_id` foreign key (`order_id`) references `charging_order` (`order_id`) on delete restrict on update restrict;
alter table `reconciliation_confirmation` add constraint `fk_reconciliation_confirmation_settlement_id` foreign key (`settlement_id`) references `operator_settlement` (`settlement_id`) on delete restrict on update restrict;
alter table `reconciliation_confirmation` add constraint `fk_reconciliation_confirmation_difference_id` foreign key (`difference_id`) references `reconciliation_difference` (`difference_id`) on delete restrict on update restrict;
alter table `reconciliation_confirmation` add constraint `fk_reconciliation_confirmation_confirmed_by` foreign key (`confirmed_by`) references `sys_account` (`account_id`) on delete restrict on update restrict;
alter table `settlement_adjustment` add constraint `fk_settlement_adjustment_settlement_id` foreign key (`settlement_id`) references `operator_settlement` (`settlement_id`) on delete restrict on update restrict;
alter table `settlement_adjustment` add constraint `fk_settlement_adjustment_difference_id` foreign key (`difference_id`) references `reconciliation_difference` (`difference_id`) on delete restrict on update restrict;
alter table `settlement_adjustment` add constraint `fk_settlement_adjustment_requested_by` foreign key (`requested_by`) references `sys_account` (`account_id`) on delete restrict on update restrict;
alter table `settlement_adjustment` add constraint `fk_settlement_adjustment_approved_by` foreign key (`approved_by`) references `sys_account` (`account_id`) on delete restrict on update restrict;
alter table `operator_invoice` add constraint `fk_operator_invoice_settlement_id` foreign key (`settlement_id`) references `operator_settlement` (`settlement_id`) on delete restrict on update restrict;
alter table `operator_invoice` add constraint `fk_operator_invoice_original_invoice_id` foreign key (`original_invoice_id`) references `operator_invoice` (`invoice_id`) on delete restrict on update restrict;
alter table `operator_invoice` add constraint `fk_operator_invoice_issued_by` foreign key (`issued_by`) references `sys_account` (`account_id`) on delete restrict on update restrict;
alter table `user_invoice` add constraint `fk_user_invoice_user_id` foreign key (`user_id`) references `app_user` (`user_id`) on delete restrict on update restrict;
alter table `user_invoice` add constraint `fk_user_invoice_original_user_invoice_id` foreign key (`original_user_invoice_id`) references `user_invoice` (`user_invoice_id`) on delete restrict on update restrict;
alter table `user_invoice` add constraint `fk_user_invoice_handled_by` foreign key (`handled_by`) references `sys_account` (`account_id`) on delete restrict on update restrict;
alter table `user_invoice_item` add constraint `fk_user_invoice_item_user_invoice_id` foreign key (`user_invoice_id`) references `user_invoice` (`user_invoice_id`) on delete restrict on update restrict;
alter table `user_invoice_item` add constraint `fk_user_invoice_item_order_id` foreign key (`order_id`) references `charging_order` (`order_id`) on delete restrict on update restrict;
alter table `fleet_monthly_bill` add constraint `fk_fleet_monthly_bill_fleet_id` foreign key (`fleet_id`) references `fleet` (`fleet_id`) on delete restrict on update restrict;
alter table `fleet_monthly_bill_item` add constraint `fk_fleet_monthly_bill_item_bill_id` foreign key (`bill_id`) references `fleet_monthly_bill` (`bill_id`) on delete restrict on update restrict;
alter table `fleet_monthly_bill_item` add constraint `fk_fleet_monthly_bill_item_order_id` foreign key (`order_id`) references `charging_order` (`order_id`) on delete restrict on update restrict;
alter table `fleet_monthly_bill_item` add constraint `fk_fleet_monthly_bill_item_refund_id` foreign key (`refund_id`) references `refund_record` (`refund_id`) on delete restrict on update restrict;
alter table `fleet_monthly_bill_item` add constraint `fk_fleet_monthly_bill_item_source_bill_id` foreign key (`source_bill_id`) references `fleet_monthly_bill` (`bill_id`) on delete restrict on update restrict;
alter table `fleet_price` add constraint `fk_fleet_price_fleet_id` foreign key (`fleet_id`) references `fleet` (`fleet_id`) on delete restrict on update restrict;
alter table `fleet_price` add constraint `fk_fleet_price_period_id` foreign key (`period_id`) references `pricing_period` (`period_id`) on delete restrict on update restrict;
alter table `fleet_bill_payment` add constraint `fk_fleet_bill_payment_bill_id` foreign key (`bill_id`) references `fleet_monthly_bill` (`bill_id`) on delete restrict on update restrict;
alter table `fleet_bill_payment` add constraint `fk_fleet_bill_payment_recorded_by` foreign key (`recorded_by`) references `sys_account` (`account_id`) on delete restrict on update restrict;
alter table `request_dedup` add constraint `fk_request_dedup_account_id` foreign key (`account_id`) references `sys_account` (`account_id`) on delete restrict on update restrict;
alter table `notification` add constraint `fk_notification_account_id` foreign key (`account_id`) references `sys_account` (`account_id`) on delete restrict on update restrict;
alter table `device_credential` add constraint `fk_device_credential_pile_id` foreign key (`pile_id`) references `charging_pile` (`pile_id`) on delete restrict on update restrict;

-- 分区表逻辑外键校验示例，只校验桩存在，不代替完整业务触发器。
delimiter $$
create trigger trg_maintenance_reading_pile_exists before insert on device_reading for each row
begin
  if not exists (select 1 from charging_pile where pile_id = new.pile_id) then
    signal sqlstate '45000' set message_text = 'pile not found';
  end if;
end$$
delimiter ;
-- 分区表业务数据按追加写入；应用账号不授予该表update/delete权限。
-- 每月提前将p_future reorganize成下一月份和新的p_future，迁移脚本由成员3提交。
-- 下一步：安装业务视图、过程和其余触发器，再按父表到子表装载固定种子数据。

-- V1.4 任务书2.2.1价格调整审批；父表均已创建。
create table `pricing_review` (
  `review_id` bigint unsigned not null auto_increment comment '审批记录主键',
  `rule_id` bigint unsigned null default NULL comment '普通计费规则草稿；与price_id二选一',
  `price_id` bigint unsigned null default NULL comment '车队专价草稿；与rule_id二选一',
  `requested_by` bigint unsigned not null comment '申请账号',
  `requested_at` datetime(3) not null comment '申请时间',
  `decision` varchar(32) not null default 'pending' comment '审批状态',
  `reviewed_by` bigint unsigned null default NULL comment '审批账号；禁止自批',
  `reviewed_at` datetime(3) null default NULL comment '审批时间',
  `review_note` varchar(1000) null default NULL comment '审批意见',
  `content_hash` binary(32) not null comment '服务器计算方案快照SHA256；审批前再次比对',
  `target_snapshot` json not null comment '服务器生成的普通规则及其时段或专价完整快照，客户端不能自由覆盖',
  `created_at` datetime(3) not null default current_timestamp(3) comment 'UTC创建时间',
  `updated_at` datetime(3) not null default current_timestamp(3) on update current_timestamp(3) comment 'UTC修改时间',
  `pending_target_key` varchar(100) generated always as (case when decision = 'pending' then concat(if(rule_id is not null, 'rule:', 'fleet:'), coalesce(rule_id,price_id)) else null end) stored comment '一个价格目标最多一条待审批记录',
  primary key (`review_id`),
  unique key `uq_pricing_review_pending_target_key` (`pending_target_key`),
  key `ix_pricing_review_requested_by_requested_at` (`requested_by`,`requested_at`),
  constraint `ck_pricing_review_1` check (decision in ('pending','approved','rejected')),
  constraint `ck_pricing_review_2` check ((rule_id is not null) + (price_id is not null) = 1),
  constraint `ck_pricing_review_3` check (reviewed_by is null or reviewed_by <> requested_by),
  constraint `ck_pricing_review_4` check ((decision='pending' and reviewed_by is null and reviewed_at is null) or (decision in ('approved','rejected') and reviewed_by is not null and reviewed_at is not null)),
  constraint `fk_pricing_review_rule_id` foreign key (`rule_id`) references `pricing_rule` (`rule_id`) on delete restrict on update restrict,
  constraint `fk_pricing_review_price_id` foreign key (`price_id`) references `fleet_price` (`price_id`) on delete restrict on update restrict,
  constraint `fk_pricing_review_requested_by` foreign key (`requested_by`) references `sys_account` (`account_id`) on delete restrict on update restrict,
  constraint `fk_pricing_review_reviewed_by` foreign key (`reviewed_by`) references `sys_account` (`account_id`) on delete restrict on update restrict
) engine=InnoDB default charset=utf8mb4 collate=utf8mb4_0900_ai_ci;
