-- membership module tables extracted verbatim from V1.4 unified DDL.
-- Load after all project tables are created; apply 02_foreign_keys.sql afterward.
set names utf8mb4 collate utf8mb4_0900_ai_ci;
set time_zone = '+00:00';

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
