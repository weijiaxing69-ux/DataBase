"""设备命令 Outbox 消费：领取并提交 → 事务外发送 → 保存回执或安排重试。

send 接收命令字典，成功返回 True，拒绝返回 False，临时异常则抛出异常。
演示中使用模拟设备；真实设备适配器以后只需替换 send。
"""
from datetime import timedelta
from sqlalchemy import or_, select
from .models import ChargingGun, ChargingPile, DeviceCommand, OutboxEvent
from . import dao
from .service import _now


def dispatch_next(db, *, send) -> bool:
    """消费最多一条事件；返回 False 表示目前没有待处理命令。"""
    now = _now()
    try:
        event = db.scalar(select(OutboxEvent).where(
            OutboxEvent.event_type == "device_command", OutboxEvent.available_at <= now,
            or_(OutboxEvent.status == "pending",
                (OutboxEvent.status == "processing") & (OutboxEvent.locked_until <= now))
        ).order_by(OutboxEvent.outbox_id).with_for_update(skip_locked=True))
        if event is None:
            db.rollback()
            return False
        command = db.scalar(select(DeviceCommand).where(
            DeviceCommand.command_id == int(event.payload["command_id"])).with_for_update())
        if command is None:
            event.status, event.last_error = "failed", "关联命令不存在"
            db.commit()
            return True
        if command.status in ("succeeded", "failed"):
            event.status = "done" if command.status == "succeeded" else "failed"
            event.locked_until = None
            db.commit()
            return True
        # 队列可能积压；原订单已经结束或设备已离线时，过期的启动命令不能再发。
        if command.command_type == "start":
            order = dao._order_for_gun(db, command.order_id, command.gun_id)
            gun = db.scalar(select(ChargingGun).where(ChargingGun.gun_id == command.gun_id)
                            .execution_options(populate_existing=True))
            pile = db.scalar(select(ChargingPile).where(ChargingPile.pile_id == command.pile_id)
                             .execution_options(populate_existing=True))
            if (order is None or order["status"] != "charging" or gun is None or pile is None
                    or gun.pile_id != command.pile_id or gun.status != "occupied"
                    or gun.has_fault or pile.has_fault or not pile.is_online or pile.lifecycle_status != "active"):
                event.status, command.status = "failed", "failed"
                event.last_error = command.error_message = "启动条件已失效，取消发送"
                event.locked_until = None
                db.commit()
                return True
        event.status = "processing"
        event.attempt_count += 1
        event.locked_until = now + timedelta(seconds=60)
        command.status = "sent"
        command.attempt_count += 1
        command.sent_at = now
        event_id, command_id, attempt = event.outbox_id, command.command_id, event.attempt_count
        message = {"command_id": command_id, "pile_id": command.pile_id,
                   "gun_id": command.gun_id, "order_id": command.order_id,
                   "command_type": command.command_type}
        # 先保存领取状态再发送，网络等待期间不持有数据库锁。
        db.commit()
    except Exception:
        db.rollback()
        raise
    retry = False
    try:
        succeeded = send(message) is True
        error = None if succeeded else "设备拒绝命令"
    except Exception:
        # 不保存异常原文，以免适配器异常中包含密钥或敏感设备参数。
        succeeded, retry, error = False, True, "设备发送失败，等待重试"
    try:
        event = db.scalar(select(OutboxEvent).where(OutboxEvent.outbox_id == event_id)
                          .with_for_update().execution_options(populate_existing=True))
        command = db.scalar(select(DeviceCommand).where(DeviceCommand.command_id == command_id)
                            .with_for_update().execution_options(populate_existing=True))
        # 租约超时后可能已由别的消费者领取，旧消费者不能覆盖新消费者的结果。
        if event.status != "processing" or event.attempt_count != attempt:
            db.rollback()
            return True
        event.locked_until = None
        event.last_error = error
        command.error_message = error
        if succeeded:
            event.status, command.status = "done", "succeeded"
            command.acknowledged_at = _now()
        elif retry and attempt < 5:
            event.status, command.status = "pending", "pending"
            event.available_at = _now() + timedelta(seconds=min(2 ** attempt, 60))
        else:
            event.status, command.status = "failed", "failed"
        db.commit()
    except Exception:
        db.rollback()
        raise
    return True
