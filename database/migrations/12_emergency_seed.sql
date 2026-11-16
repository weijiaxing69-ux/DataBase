-- =============================================================
-- maintenance 模块 · V1.5 应急增强场景数据
-- 前置：10_emergency_tables.sql、11_emergency_objects.sql 已执行
-- ID 段：station/pile/gun 901+，alert 911+，incident 901+，其余 901+
-- 时区：库内 UTC，注释里给上海时间
-- 说明：V1.4 种子里"1 个场站只有 1 根桩"，无法演示场站级连锁故障，
--       因此新增一个 3 桩的演示场站（901）。这是演示夹具，不属于业务数据。
-- =============================================================

set names utf8mb4;
set time_zone = '+00:00';

-- -------------------------------------------------------------
-- 1. 演示场站（3 桩，用于"市电中断导致整站离线"）
-- -------------------------------------------------------------
insert into `station`
  (`station_id`, `operator_id`, `station_name`, `address`, `longitude`, `latitude`,
   `parking_spaces`, `business_hours`, `parking_fee_standard`, `status`)
values
  (901, 3, '演示场站·应急园区', '演示地址 901 号', 116.3000000, 40.0000000,
   60, '00:00-24:00', '按场站公示标准', 'active');

insert into `charging_pile`
  (`pile_id`, `station_id`, `serial_no`, `model_name`, `rated_power_kw`, `protocol`,
   `commissioned_on`, `warranty_until`, `lifecycle_status`, `status`, `is_online`, `last_heartbeat_at`)
values
  (901, 901, 'PILE-901', 'DEMO-DC-120', 120, 'OCPP', '2026-09-20', '2028-09-20', 'active', 'offline', 0, '2026-11-13 11:58:00'),
  (902, 901, 'PILE-902', 'DEMO-DC-120', 120, 'OCPP', '2026-09-20', '2028-09-20', 'active', 'offline', 0, '2026-11-13 11:58:00'),
  (903, 901, 'PILE-903', 'DEMO-DC-120', 120, 'OCPP', '2026-09-20', '2028-09-20', 'active', 'fault',   1, '2026-11-13 12:24:00');

insert into `charging_gun`
  (`gun_id`, `pile_id`, `gun_no`, `gun_type`, `connector_standard`, `max_power_kw`, `status`)
values
  (901, 901, 1, 'dc', 'GB/T', 60, 'offline'),
  (902, 902, 1, 'dc', 'GB/T', 60, 'offline'),
  (903, 903, 1, 'dc', 'GB/T', 60, 'fault');

-- -------------------------------------------------------------
-- 2. 三条告警（间隔 12 分钟，不触发"10 分钟 2 条"的自动声明，留给 13 号脚本单独演示）
-- -------------------------------------------------------------
insert into `device_alert`
  (`alert_id`, `pile_id`, `gun_id`, `alarm_rule_id`, `alert_code`, `severity`, `occurred_at`,
   `recovered_at`, `status`, `response_seconds_snapshot`, `normal_since_at`)
values
  (911, 901, 901, 901, 'E101', 'critical', '2026-11-13 12:00:00', null, 'processing', 300,  null),
  (912, 902, 902, 902, 'E102', 'high',     '2026-11-13 12:12:00', null, 'processing', 600,  null),
  (913, 903, 903, 904, 'E104', 'low',      '2026-11-13 12:24:00', null, 'processing', 7200, null);

-- -------------------------------------------------------------
-- 3. 事件：901 为进行中 P1（市电中断），902 为已恢复 P2（模块过温）
-- -------------------------------------------------------------
insert into `incident`
  (`incident_id`, `incident_no`, `operator_id`, `station_id`, `category`, `severity`, `title`,
   `status`, `detected_at`, `declared_at`, `contained_at`, `restored_at`, `closed_at`,
   `commander_account_id`, `impact_pile_count`, `impact_order_count`,
   `estimated_loss_amount`, `escalation_level`, `summary`)
values
  (901, 'INC-20261113-0001', 3, 901, 'power', 'P1',
   '应急园区市电中断导致 3 桩离线',
   'contained', '2026-11-13 12:00:00', '2026-11-13 12:05:00', '2026-11-13 12:30:00', null, null,
   101, 3, 12, 1860.00, 3, '已隔离场站并暂停接单，等待市电恢复'),
  (902, 'INC-20261113-0002', 6, 6, 'hardware', 'P2',
   '6 号场站充电模块过温批量告警',
   'restored', '2026-11-13 02:00:00', '2026-11-13 02:10:00', '2026-11-13 03:00:00',
   '2026-11-13 03:30:00', null,
   101, 1, 4, 420.00, 2, '更换散热风扇后恢复');

insert into `incident_alert` (`incident_id`, `alert_id`, `linked_at`, `linked_by`, `is_root_cause`)
values
  (901, 911, '2026-11-13 12:05:00', 101, 1),
  (901, 912, '2026-11-13 12:12:00', null, 0),
  (901, 913, '2026-11-13 12:24:00', null, 0),
  (902, 904, '2026-11-13 02:10:00', 101, 1);

-- -------------------------------------------------------------
-- 4. 值班班次（当前班：主值班 102，备班 103，主管 101）
-- -------------------------------------------------------------
insert into `on_call_shift`
  (`shift_id`, `scope_type`, `scope_id`, `shift_start`, `shift_end`,
   `primary_account_id`, `backup_account_id`, `supervisor_account_id`, `status`, `note`)
values
  (901, 'station',  901, '2026-11-13 00:00:00', '2026-11-14 00:00:00', 102, 103, 101, 'active', '白班：张工；备班：李工'),
  (902, 'station',    6, '2026-11-13 00:00:00', '2026-11-14 00:00:00', 102, 103, 101, 'active', '白班'),
  (903, 'operator',   3, '2026-11-13 00:00:00', '2026-11-14 00:00:00', 102, 103, 101, 'active', '运营商值班');

-- -------------------------------------------------------------
-- 5. SLA 基线与升级矩阵
-- -------------------------------------------------------------
insert into `incident_sla` (`severity`, `ack_seconds`, `restore_seconds`, `description`)
values
  ('P1', 900,   14400,  '重大：整站或多桩失效，15 分钟内宣布，4 小时内恢复'),
  ('P2', 1800,  28800,  '较大：单站部分设备失效，30 分钟内宣布，8 小时内恢复'),
  ('P3', 7200,  86400,  '一般：单桩故障，2 小时内宣布，24 小时内恢复'),
  ('P4', 28800, 259200, '轻微：不影响充电服务，8 小时内宣布，72 小时内恢复');

insert into `escalation_policy`
  (`policy_id`, `policy_code`, `applies_severity`, `min_duration_seconds`, `min_impact_piles`,
   `notify_level`, `action_code`, `enabled`)
values
  (901, 'ESC-P1-L3-IMM', 'P1',  0,    0, 'L3', 'notify_supervisor', 1),
  (902, 'ESC-P1-L2-30M', 'P1',  1800, 0, 'L2', 'notify_operator',   1),
  (903, 'ESC-P2-L3-5P',  'P2',  0,    5, 'L3', 'notify_supervisor', 1),
  (904, 'ESC-P2-L2-60M', 'P2',  3600, 3, 'L2', 'dispatch_backup',   1),
  (905, 'ESC-ANY-L1-24H','ANY', 86400, 0, 'L1', 'notify_operator',  1);

insert into `incident_escalation`
  (`escalation_id`, `incident_id`, `policy_id`, `notify_level`, `triggered_at`,
   `notified_account_id`, `ack_at`, `note`)
values
  (901, 901, 901, 'L3', '2026-11-13 12:05:00', 101, '2026-11-13 12:06:00', 'P1 立即通知值班主管'),
  (902, 902, 902, 'L2', '2026-11-13 02:10:00', 101, '2026-11-13 02:12:00', 'P2 30 分钟未恢复，通知运营商');

-- -------------------------------------------------------------
-- 6. 处置动作流水
-- -------------------------------------------------------------
insert into `incident_action`
  (`action_id`, `incident_id`, `action_type`, `target_type`, `target_id`, `action_at`,
   `actor_account_id`, `approved_by`, `reason`, `result`)
values
  (901, 901, 'declare',         'none',    null, '2026-11-13 12:05:00', 101, null, '3 桩同时掉线，宣布 P1', '已宣布'),
  (902, 901, 'notify',          'account', 101,  '2026-11-13 12:05:00', 101, null, '通知值班主管', '已确认'),
  (903, 901, 'isolate_station', 'station', 901,  '2026-11-13 12:06:00', 101, 101,  '防止带故障合闸', '场站已隔离，暂停接单'),
  (904, 901, 'dispatch',        'account', 102,  '2026-11-13 12:07:00', 101, null, '派抢修班到场', '已出发'),
  (905, 902, 'declare',         'none',    null, '2026-11-13 02:10:00', 101, null, '模块温度持续超阈值', '已宣布'),
  (906, 902, 'restore',         'station', 6,    '2026-11-13 03:30:00', 102, 101,  '更换风扇并复测通过', '业务恢复');

-- -------------------------------------------------------------
-- 7. 复盘与整改（902 已审核通过；901 故意留空，用于演示"无复盘不能关闭"）
-- -------------------------------------------------------------
insert into `postmortem`
  (`postmortem_id`, `incident_id`, `root_cause_category`, `root_cause`,
   `detection_seconds`, `response_seconds`, `recovery_seconds`,
   `prevention`, `reviewer_account_id`, `reviewed_at`, `status`)
values
  (901, 902, 'hardware', '散热风扇轴承磨损导致风量不足，模块温度持续升高触发过温保护',
   600, 600, 5400,
   '把风扇运行时长纳入巡检项；温度连续 10 分钟超 65℃ 提前预警；同型号风扇备件预置到站',
   101, '2026-11-13 03:40:00', 'approved');

insert into `action_item`
  (`item_id`, `postmortem_id`, `description`, `owner_account_id`, `due_date`, `status`)
values
  (901, 901, '为 6 号场站加装模块温度联锁，并将散热风扇纳入季度更换计划', 102, '2026-11-20', 'open');

-- -------------------------------------------------------------
-- 8. 抢修备件与领用（领用会触发库存扣减，见 trg_part_usage_ai_stock）
-- -------------------------------------------------------------
insert into `spare_part`
  (`part_id`, `part_code`, `part_name`, `model`, `unit`, `station_id`, `stock_qty`, `safety_stock`, `status`)
values
  (901, 'SP-TEMP-01', '温度探头', 'NTC-10K',   '个', 901, 8, 6, 'active'),
  (902, 'SP-FAN-01',  '散热风扇', 'FAN-120',   '个', 6,   4, 5, 'active'),
  (903, 'SP-CONT-01', '接触器',   'CJX2-25',   '个', null, 20, 10, 'active');

insert into `part_usage`
  (`usage_id`, `work_order_id`, `part_id`, `qty`, `used_at`, `used_by`, `note`)
values
  (901, 904, 902, 1, '2026-11-13 09:52:00', 102, '更换散热风扇'),
  (902, 901, 901, 2, '2026-11-14 01:25:00', 102, '更换温度探头');
