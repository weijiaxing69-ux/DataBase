-- =============================================================
-- maintenance 模块 · 触发器
-- T1 trg_device_reading_ai_alert   采样入库后按规则自动生成告警（任务书 2.1.3「系统按告警码规则生成告警」）
-- T2 trg_work_order_bu_state_guard 工单状态机兜底，拒绝跳步与回退到非法状态（C03）
-- 说明：
--   * 超时未响应自动升级不能用触发器实现（触发器只随 DML 触发，不会定时执行），
--     由后台任务 check_overdue_work_orders 完成，见 README 的任务设计。
--   * 告警去重由 uq_device_alert_active_key 兜底，重复上报用 insert ignore 静默去重。
-- =============================================================

set names utf8mb4;
delimiter $$

drop trigger if exists trg_device_reading_ai_alert$$
-- -------------------------------------------------------------
-- 采样入库 → 命中规则 → 生成告警
-- 匹配两类规则：
--   1) metric='fault_code'：故障码精确匹配；
--   2) metric='temperature'：模块温度 >= threshold_value，取最严重的一条。
-- 生成时固化 severity 与 response_seconds_snapshot，后续改规则不影响在途告警。
-- 同一桩同码未恢复告警只保留一条（active_key 唯一），恢复后可再次生成。
-- -------------------------------------------------------------
create trigger trg_device_reading_ai_alert
after insert on device_reading
for each row
begin
  declare v_rule_id bigint unsigned;
  declare v_code varchar(32);
  declare v_severity varchar(32);
  declare v_response int unsigned;

  -- 1) 故障码规则
  if new.fault_code is not null and new.fault_code <> 'NONE' then
    set v_rule_id = null, v_code = null, v_severity = null, v_response = null;

    select alarm_rule_id,
           left(coalesce(fault_code, rule_code), 32),
           severity,
           response_seconds
      into v_rule_id, v_code, v_severity, v_response
      from alarm_rule
     where enabled = 1
       and metric = 'fault_code'
       and fault_code = new.fault_code
     limit 1;

    if v_rule_id is not null then
      insert ignore into device_alert
        (pile_id, gun_id, alarm_rule_id, alert_code, severity, occurred_at,
         status, response_seconds_snapshot, normal_since_at)
      values
        (new.pile_id, null, v_rule_id, v_code, v_severity, new.sampled_at,
         'open', v_response, null);
    end if;
  end if;

  -- 2) 温度阈值规则
  set v_rule_id = null, v_code = null, v_severity = null, v_response = null;

  select alarm_rule_id,
         left(rule_code, 32),
         severity,
         response_seconds
    into v_rule_id, v_code, v_severity, v_response
    from alarm_rule
   where enabled = 1
     and metric = 'temperature'
     and threshold_value is not null
     and new.module_temperature_c >= threshold_value
   order by case severity
              when 'critical' then 1
              when 'high'     then 2
              when 'medium'   then 3
              else 4
            end,
            threshold_value desc
   limit 1;

  if v_rule_id is not null then
    insert ignore into device_alert
      (pile_id, gun_id, alarm_rule_id, alert_code, severity, occurred_at,
       status, response_seconds_snapshot, normal_since_at)
    values
      (new.pile_id, null, v_rule_id, v_code, v_severity, new.sampled_at,
       'open', v_response, null);
  end if;
end$$

drop trigger if exists trg_work_order_bu_state_guard$$
-- -------------------------------------------------------------
-- 工单状态机：assigned → accepted → arrived → repaired → closed
-- 允许 repaired → arrived（复核未通过，继续维修）与同状态更新（如升级次数 +1）。
-- 关闭为终态，不允许再变更。非法迁移直接报错，避免 Service 层漏判。
-- -------------------------------------------------------------
create trigger trg_work_order_bu_state_guard
before update on work_order
for each row
begin
  if new.status <> old.status then
    if not (
         (old.status = 'assigned' and new.status = 'accepted')
      or (old.status = 'accepted' and new.status = 'arrived')
      or (old.status = 'arrived'  and new.status = 'repaired')
      or (old.status = 'repaired' and new.status = 'arrived')
      or (old.status = 'repaired' and new.status = 'closed')
    ) then
      signal sqlstate '45000'
        set message_text = '非法的工单状态迁移：只允许 assigned→accepted→arrived→repaired→closed，或 repaired→arrived（复核未通过）';
    end if;
  end if;
end$$

delimiter ;
