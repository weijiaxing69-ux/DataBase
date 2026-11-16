-- =============================================================
-- maintenance 模块 · 场景种子数据（补齐 V1.4 种子缺失的四类演示场景）
-- 前置：已导入 00_测试库建表.sql + 04_seed_V1.4.sql（桩 1-20、枪 1-20、账号 101-106、用户 1-20）
-- 目的：现有种子 20 条规则全为 high/600s/60s，20 条告警全 recovered，20 条工单全 closed，
--       无法演示 C04 等级差异、C05 未恢复状态、告警 1:N 与 L03 工单闭环。
-- ID 段：alarm_rule 901+，device_alert 901+，work_order 901+，event 9001+，不覆盖原种子。
-- 时区：库内存 UTC。括号内为上海时间，与 README 的 L03 用例对应。
-- =============================================================

set names utf8mb4;
set time_zone = '+00:00';

-- -------------------------------------------------------------
-- 1. 四档响应时限规则 + 温度/心跳阈值规则（C04）
--    critical 5 分钟、high 10 分钟、medium 30 分钟、low 2 小时
-- -------------------------------------------------------------
insert into `alarm_rule`
  (`alarm_rule_id`, `rule_code`, `fault_code`, `metric`, `threshold_value`, `severity`, `response_seconds`, `recovery_seconds`, `enabled`)
values
  (901, 'SCN-CRIT-E101', 'E101', 'fault_code',  null,    'critical', 300,  120, 1),
  (902, 'SCN-HIGH-E102', 'E102', 'fault_code',  null,    'high',     600,  60,  1),
  (903, 'SCN-MED-E103',  'E103', 'fault_code',  null,    'medium',   1800, 300, 1),
  (904, 'SCN-LOW-E104',  'E104', 'fault_code',  null,    'low',      7200, 600, 1),
  (905, 'SCN-TEMP-70',   null,   'temperature', 70.000,  'high',     600,  60,  1),
  (906, 'SCN-HB-180',    null,   'heartbeat',   180.000, 'high',     600,  60,  1);

-- -------------------------------------------------------------
-- 2. 告警：一条 1:N（901）、一条超时（902）、L03 恢复观察中（903）、一条复核回退（904）
-- -------------------------------------------------------------
insert into `device_alert`
  (`alert_id`, `pile_id`, `gun_id`, `alarm_rule_id`, `alert_code`, `severity`, `occurred_at`,
   `recovered_at`, `status`, `response_seconds_snapshot`, `normal_since_at`)
values
  -- 901 桩4：先派一次已闭环，随后再次派单并超时未接 → C02 告警可多次派单（09:35 CST 发生）
  (901, 4, 4, 901, 'E101', 'critical', '2026-11-13 09:35:00', null, 'processing', 300,  null),
  -- 902 桩5：先派单一次已闭环，二次派单后仍未接单，告警不得恢复 → C05（09:20 CST 发生）
  (902, 5, 5, 902, 'E102', 'high',     '2026-11-13 09:20:00', null, 'processing', 600,  null),
  -- 903 桩3：L03 用例，09:35 闭环后进入 recovering，尚未满 60 秒观察期 (09:35 CST = 01:35 UTC)
  (903, 3, 3, 3,   'E003', 'high',     '2026-11-14 01:00:00', null, 'recovering', 600,
   '2026-11-14 01:35:00'),
  -- 904 桩6：复核未通过，回 arrived 继续维修
  (904, 6, 6, 904, 'E104', 'low',      '2026-11-13 02:00:00', null, 'processing', 7200, null);

-- -------------------------------------------------------------
-- 3. 工单
-- -------------------------------------------------------------
insert into `work_order`
  (`work_order_id`, `alert_id`, `assigned_to`, `assigned_by`, `assigned_at`, `response_due_at`,
   `status`, `escalation_level`, `parts_used`, `result`)
values
  -- L03：09:01 派单、09:11 截止、09:35 闭环（UTC 01:01 / 01:11 / 01:35）
  (901, 903, 102, 101, '2026-11-14 01:01:00', '2026-11-14 01:11:00', 'closed',   0, '温度探头', '复核通过'),
  -- 告警 901 的第二次派单：10:10 派单、10:15 截止（critical 300 秒），至今未接单 → 超时
  (902, 901, 102, 101, '2026-11-13 10:10:00', '2026-11-13 10:15:00', 'assigned', 0, null, null),
  -- 告警 902 的第二次派单，仍未接单
  (903, 902, 102, 101, '2026-11-13 09:41:00', '2026-11-13 09:51:00', 'assigned', 0, null, null),
  -- 告警 902 的第一次派单，已闭环（但告警不能因它单独恢复）
  (904, 902, 102, 101, '2026-11-13 09:30:00', '2026-11-13 09:40:00', 'closed',   0, '散热风扇', '复核通过'),
  -- 告警 901 的第一条工单，已闭环
  (905, 901, 102, 101, '2026-11-13 09:40:00', '2026-11-13 09:45:00', 'closed',   0, '熔断器', '复核通过'),
  -- 复核未通过回退：修复后复检不合格，回到 arrived
  (906, 904, 102, 101, '2026-11-13 02:01:00', '2026-11-13 04:01:00', 'arrived',  0, '接触器', null);

-- -------------------------------------------------------------
-- 4. 工单事件（C03：每个时间节点一条，历史不覆盖）
-- -------------------------------------------------------------
insert into `work_order_event`
  (`event_id`, `work_order_id`, `event_type`, `event_at`, `old_status`, `new_status`,
   `actor_account_id`, `note`, `review_result`)
values
  -- 901 完整闭环链（L03：接单响应 4 分钟，未超 10 分钟）
  (9001, 901, 'accepted',      '2026-11-14 01:05:00', 'assigned', 'accepted', 102, '已接单', null),
  (9002, 901, 'arrived',       '2026-11-14 01:12:00', 'accepted', 'arrived',  102, '到场检查', null),
  (9003, 901, 'repaired',      '2026-11-14 01:25:00', 'arrived',  'repaired', 102, '更换温度探头', null),
  (9004, 901, 'review_passed', '2026-11-14 01:31:00', 'repaired', 'repaired', 102, '复检合格', '连续 6 分钟温度正常'),
  (9005, 901, 'closed',        '2026-11-14 01:35:00', 'repaired', 'closed',   102, '工单闭环', '复检合格'),
  -- 904 已闭环
  (9011, 904, 'accepted',      '2026-11-13 09:31:00', 'assigned', 'accepted', 102, '已接单', null),
  (9012, 904, 'arrived',       '2026-11-13 09:38:00', 'accepted', 'arrived',  102, '到场检查', null),
  (9013, 904, 'repaired',      '2026-11-13 09:52:00', 'arrived',  'repaired', 102, '更换散热风扇', null),
  (9014, 904, 'review_passed', '2026-11-13 09:56:00', 'repaired', 'repaired', 102, '复检合格', '风扇转速正常'),
  (9015, 904, 'closed',        '2026-11-13 09:58:00', 'repaired', 'closed',   102, '工单闭环', '复检合格'),
  -- 905 已闭环
  (9021, 905, 'accepted',      '2026-11-13 09:42:00', 'assigned', 'accepted', 102, '已接单', null),
  (9022, 905, 'arrived',       '2026-11-13 09:47:00', 'accepted', 'arrived',  102, '到场检查', null),
  (9023, 905, 'repaired',      '2026-11-13 09:56:00', 'arrived',  'repaired', 102, '更换熔断器', null),
  (9024, 905, 'review_passed', '2026-11-13 10:00:00', 'repaired', 'repaired', 102, '复检合格', '通断测试正常'),
  (9025, 905, 'closed',        '2026-11-13 10:04:00', 'repaired', 'closed',   102, '工单闭环', '复检合格'),
  -- 906 复核未通过，回 arrived 继续维修（历史保留，不算闭环）
  (9031, 906, 'accepted',      '2026-11-13 02:03:00', 'assigned', 'accepted', 102, '已接单', null),
  (9032, 906, 'arrived',       '2026-11-13 02:06:00', 'accepted', 'arrived',  102, '到场检查', null),
  (9033, 906, 'repaired',      '2026-11-13 02:10:00', 'arrived',  'repaired', 102, '更换接触器', null),
  (9034, 906, 'review_failed', '2026-11-13 02:15:00', 'repaired', 'arrived',  102, '复检仍告警', '绝缘电阻不达标');

-- -------------------------------------------------------------
-- 5. 恢复观察期采样（桩 3，01:35 之后连续正常，供 sp_recover_alert 判定）
--    注意：插入会触发 trg_device_reading_ai_alert，故障码为 NONE 不产生告警
-- -------------------------------------------------------------
insert into `device_reading`
  (`pile_id`, `sampled_at`, `output_voltage_v`, `output_current_a`, `power_kw`,
   `module_temperature_c`, `offline_seconds`, `fault_code`)
values
  (3, '2026-11-14 01:35:30', 400.000, 0.000, 0.000, 38.20, 0, 'NONE'),
  (3, '2026-11-14 01:36:00', 400.000, 0.000, 0.000, 38.10, 0, 'NONE'),
  (3, '2026-11-14 01:36:30', 400.000, 0.000, 0.000, 38.00, 0, 'NONE');

-- -------------------------------------------------------------
-- 6. 巡检与报障（C03 复核依据 / R04 车主报障）
-- -------------------------------------------------------------
insert into `inspection_record`
  (`inspection_id`, `pile_id`, `inspected_by`, `inspected_at`, `result`, `parts_used`, `note`)
values
  (901, 3, 102, '2026-11-14 01:31:00', 'normal', '温度探头', '闭环前复检：连续采样温度正常，枪线无异常'),
  (902, 6, 102, '2026-11-13 02:12:00', 'abnormal', '接触器', '复检绝缘电阻不达标，需继续维修');

insert into `fault_report`
  (`report_id`, `user_id`, `gun_id`, `order_id`, `description`, `status`, `alert_id`, `handled_by`, `handled_at`)
values
  (901, 1, 3, null, '充电中途停止，屏幕提示设备故障', 'linked', 903, 103, '2026-11-14 01:10:00');
