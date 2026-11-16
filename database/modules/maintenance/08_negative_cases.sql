-- =============================================================
-- maintenance 模块 · 负向用例（预期报错，必须逐条单独执行）
-- 不要整文件顺序执行：mysql 客户端遇到错误会中断后续语句，
-- 这是刻意设计的，便于截图"系统确实拒绝了非法操作"。
-- 每条用例给 setup → 执行 → 预期错误 → cleanup。
-- =============================================================

set names utf8mb4;
set time_zone = '+00:00';

-- -------------------------------------------------------------
-- N1 没有复核通过事件，不允许闭环（C05）
-- 预期：ERROR 1644 (45000) 闭环前必须存在复核通过(review_passed)事件
-- -------------------------------------------------------------
insert into work_order
  (work_order_id, alert_id, assigned_to, assigned_by, assigned_at, response_due_at,
   status, escalation_level, parts_used, result)
values
  (907, 904, 102, 101, '2026-11-13 02:20:00', '2026-11-13 04:20:00', 'repaired', 0, '接触器', '待复核');

call sp_close_work_order(907, 102, '复检合格', '尝试跳过复核');

-- cleanup（报错后单独执行）
-- delete from work_order where work_order_id = 907;

-- -------------------------------------------------------------
-- N2 状态跳步：assigned 直接改 closed，被状态机触发器拒绝（C03）
-- 预期：ERROR 1644 (45000) 非法的工单状态迁移...
-- -------------------------------------------------------------
update work_order set status = 'closed' where work_order_id = 902;

-- -------------------------------------------------------------
-- N3 回退到更早状态：arrived → accepted 非法（只允许 repaired → arrived 这一条回退路径）
-- 906 当前处于 arrived（复核未通过后回退），预期：ERROR 1644 (45000) 非法的工单状态迁移...
-- -------------------------------------------------------------
update work_order
   set status = 'accepted'
 where work_order_id = 906;

-- -------------------------------------------------------------
-- N4 已闭环工单不可再变更（终态）
-- 预期：ERROR 1644 (45000) 非法的工单状态迁移...
-- -------------------------------------------------------------
update work_order set status = 'repaired' where work_order_id = 901;

-- -------------------------------------------------------------
-- N5 同一桩、同一告警码、未恢复时重复插入，被唯一键拒绝（C02 去重兜底）
-- 预期：ERROR 1062 (23000) Duplicate entry '4:4:E101' for key 'uq_device_alert_active_key'
-- 注意：正常上报走 INSERT IGNORE 或触发器的 insert ignore，不会报错；
--       这里不加 IGNORE 是为了证明唯一约束真实存在。
-- -------------------------------------------------------------
insert into device_alert
  (pile_id, gun_id, alarm_rule_id, alert_code, severity, occurred_at, status, response_seconds_snapshot)
values
  (4, 4, 901, 'E101', 'critical', '2026-11-13 10:10:00', 'open', 300);

-- -------------------------------------------------------------
-- N6 告警恢复后同码再报，应允许（active_key 置 NULL 的设计目的）
-- 预期：插入成功，桩 4 出现第二条 E101 告警（旧的一条为 recovered）
-- 这是正向用例，放在负向文件里是为了与 N5 对照，执行前先把 901 改为 recovered。
-- -------------------------------------------------------------
update device_alert set status = 'recovered', recovered_at = utc_timestamp()
 where alert_id = 901;

insert into device_alert
  (pile_id, gun_id, alarm_rule_id, alert_code, severity, occurred_at, status, response_seconds_snapshot)
values
  (4, 4, 901, 'E101', 'critical', '2026-11-13 12:00:00', 'open', 300);

select alert_id, alert_code, status, recovered_at
from device_alert where pile_id = 4 order by alert_id;

-- cleanup
-- delete from device_alert where pile_id = 4 and alert_id > 901;
-- update device_alert set status = 'processing', recovered_at = null where alert_id = 901;
