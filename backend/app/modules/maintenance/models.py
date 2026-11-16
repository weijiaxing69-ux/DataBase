"""maintenance 模块 ORM 模型：本模块 7 张表 + 站内通知。

约定：
- 统一表结构由 `database/bootstrap/00_测试库建表.sql` 创建，这里只做映射，不 create_all。
- `station`、`charging_pile`、`device_status_log` 已由 assets 模块映射，
  本文件直接复用，**不重复定义**（同一 MetaData 重复定义同名表会启动报错）。
- `device_alert.active_key` 是 STORED 生成列，只读，插入时不赋值。
- `device_reading` 的物理主键是 (sample_id, pile_id, sampled_at)（分区表要求），
  ORM 以 sample_id 标识一行即可。
"""

from __future__ import annotations

from datetime import datetime
from decimal import Decimal
from typing import Optional

from sqlalchemy import FetchedValue, Numeric, String, func
from sqlalchemy.dialects.mysql import BIGINT, DATETIME, INTEGER, SMALLINT
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column

# 独立的 declarative base：本模块的表由统一 SQL 脚本创建，不参与 create_all；
# 与 assets 共用同一个 MetaData 会污染 tests 里的 SQLite 演示库（demo_data 会遍历它）。
class Base(DeclarativeBase):
    pass

# 复用 assets 的映射，避免同名表重复定义
from app.modules.assets.models import (  # noqa: F401  (dao 通过 models 访问)
    ChargingPile,
    DeviceStatusLog,
    Station,
)

PK = BIGINT(unsigned=True)


class AlarmRule(Base):
    """告警与响应配置。"""

    __tablename__ = "alarm_rule"

    alarm_rule_id: Mapped[int] = mapped_column(PK, primary_key=True, autoincrement=True)
    rule_code: Mapped[str] = mapped_column(String(50), nullable=False)
    fault_code: Mapped[Optional[str]] = mapped_column(String(32))
    metric: Mapped[str] = mapped_column(String(32), nullable=False)
    threshold_value: Mapped[Optional[Decimal]] = mapped_column(Numeric(12, 3))
    severity: Mapped[str] = mapped_column(String(32), nullable=False)
    response_seconds: Mapped[int] = mapped_column(INTEGER(unsigned=True), nullable=False)
    recovery_seconds: Mapped[int] = mapped_column(INTEGER(unsigned=True), nullable=False)
    enabled: Mapped[int] = mapped_column(SMALLINT(unsigned=True), nullable=False, default=1)
    created_at: Mapped[datetime] = mapped_column(DATETIME(fsp=3), server_default=func.now(3))
    updated_at: Mapped[datetime] = mapped_column(
        DATETIME(fsp=3), server_default=func.now(3), server_onupdate=FetchedValue()
    )


class DeviceAlert(Base):
    """设备告警。同一告警可多次派单，因此 alert_id 不设唯一。"""

    __tablename__ = "device_alert"

    alert_id: Mapped[int] = mapped_column(PK, primary_key=True, autoincrement=True)
    pile_id: Mapped[int] = mapped_column(PK, nullable=False)
    gun_id: Mapped[Optional[int]] = mapped_column(PK)
    alarm_rule_id: Mapped[int] = mapped_column(PK, nullable=False)
    alert_code: Mapped[str] = mapped_column(String(32), nullable=False)
    severity: Mapped[str] = mapped_column(String(32), nullable=False)
    occurred_at: Mapped[datetime] = mapped_column(DATETIME(fsp=3), nullable=False)
    recovered_at: Mapped[Optional[datetime]] = mapped_column(DATETIME(fsp=3))
    status: Mapped[str] = mapped_column(String(32), nullable=False, default="open")
    response_seconds_snapshot: Mapped[int] = mapped_column(INTEGER(unsigned=True), nullable=False)
    normal_since_at: Mapped[Optional[datetime]] = mapped_column(DATETIME(fsp=3))
    created_at: Mapped[datetime] = mapped_column(DATETIME(fsp=3), server_default=func.now(3))
    updated_at: Mapped[datetime] = mapped_column(
        DATETIME(fsp=3), server_default=func.now(3), server_onupdate=FetchedValue()
    )
    # 生成列：未恢复告警按「桩:枪:告警码」唯一，恢复后置 NULL
    active_key: Mapped[Optional[str]] = mapped_column(String(160), FetchedValue())


class WorkOrder(Base):
    """维修工单。"""

    __tablename__ = "work_order"

    work_order_id: Mapped[int] = mapped_column(PK, primary_key=True, autoincrement=True)
    alert_id: Mapped[int] = mapped_column(PK, nullable=False)
    assigned_to: Mapped[int] = mapped_column(PK, nullable=False)
    assigned_by: Mapped[int] = mapped_column(PK, nullable=False)
    assigned_at: Mapped[datetime] = mapped_column(DATETIME(fsp=3), nullable=False)
    response_due_at: Mapped[datetime] = mapped_column(DATETIME(fsp=3), nullable=False)
    status: Mapped[str] = mapped_column(String(32), nullable=False, default="assigned")
    escalation_level: Mapped[int] = mapped_column(INTEGER(unsigned=True), nullable=False, default=0)
    parts_used: Mapped[Optional[str]] = mapped_column(String(500))
    result: Mapped[Optional[str]] = mapped_column(String(500))
    created_at: Mapped[datetime] = mapped_column(DATETIME(fsp=3), server_default=func.now(3))
    updated_at: Mapped[datetime] = mapped_column(
        DATETIME(fsp=3), server_default=func.now(3), server_onupdate=FetchedValue()
    )


class WorkOrderEvent(Base):
    """工单流转历史。反复维修不覆盖历史。"""

    __tablename__ = "work_order_event"

    event_id: Mapped[int] = mapped_column(PK, primary_key=True, autoincrement=True)
    work_order_id: Mapped[int] = mapped_column(PK, nullable=False)
    event_type: Mapped[str] = mapped_column(String(32), nullable=False)
    event_at: Mapped[datetime] = mapped_column(DATETIME(fsp=3), nullable=False)
    old_status: Mapped[str] = mapped_column(String(32), nullable=False)
    new_status: Mapped[str] = mapped_column(String(32), nullable=False)
    actor_account_id: Mapped[Optional[int]] = mapped_column(PK)
    note: Mapped[Optional[str]] = mapped_column(String(500))
    review_result: Mapped[Optional[str]] = mapped_column(String(255))
    created_at: Mapped[datetime] = mapped_column(DATETIME(fsp=3), server_default=func.now(3))
    updated_at: Mapped[datetime] = mapped_column(
        DATETIME(fsp=3), server_default=func.now(3), server_onupdate=FetchedValue()
    )


class FaultReport(Base):
    """车主报障。"""

    __tablename__ = "fault_report"

    report_id: Mapped[int] = mapped_column(PK, primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(PK, nullable=False)
    gun_id: Mapped[int] = mapped_column(PK, nullable=False)
    order_id: Mapped[Optional[int]] = mapped_column(PK)
    description: Mapped[str] = mapped_column(String(1000), nullable=False)
    status: Mapped[str] = mapped_column(String(32), nullable=False, default="submitted")
    alert_id: Mapped[Optional[int]] = mapped_column(PK)
    handled_by: Mapped[Optional[int]] = mapped_column(PK)
    handled_at: Mapped[Optional[datetime]] = mapped_column(DATETIME(fsp=3))
    created_at: Mapped[datetime] = mapped_column(DATETIME(fsp=3), server_default=func.now(3))
    updated_at: Mapped[datetime] = mapped_column(
        DATETIME(fsp=3), server_default=func.now(3), server_onupdate=FetchedValue()
    )


class InspectionRecord(Base):
    """巡检记录。"""

    __tablename__ = "inspection_record"

    inspection_id: Mapped[int] = mapped_column(PK, primary_key=True, autoincrement=True)
    pile_id: Mapped[int] = mapped_column(PK, nullable=False)
    inspected_by: Mapped[int] = mapped_column(PK, nullable=False)
    inspected_at: Mapped[datetime] = mapped_column(DATETIME(fsp=3), nullable=False)
    result: Mapped[str] = mapped_column(String(32), nullable=False)
    parts_used: Mapped[Optional[str]] = mapped_column(String(500))
    note: Mapped[Optional[str]] = mapped_column(String(1000))
    created_at: Mapped[datetime] = mapped_column(DATETIME(fsp=3), server_default=func.now(3))
    updated_at: Mapped[datetime] = mapped_column(
        DATETIME(fsp=3), server_default=func.now(3), server_onupdate=FetchedValue()
    )


class DeviceReading(Base):
    """运行采样，按月分区 + 按桩哈希子分区。"""

    __tablename__ = "device_reading"

    sample_id: Mapped[int] = mapped_column(PK, primary_key=True, autoincrement=True)
    pile_id: Mapped[int] = mapped_column(PK, nullable=False)
    sampled_at: Mapped[datetime] = mapped_column(DATETIME(fsp=3), nullable=False)
    output_voltage_v: Mapped[Decimal] = mapped_column(Numeric(10, 3), nullable=False)
    output_current_a: Mapped[Decimal] = mapped_column(Numeric(10, 3), nullable=False)
    power_kw: Mapped[Decimal] = mapped_column(Numeric(10, 3), nullable=False)
    module_temperature_c: Mapped[Decimal] = mapped_column(Numeric(6, 2), nullable=False)
    offline_seconds: Mapped[int] = mapped_column(INTEGER(unsigned=True), nullable=False, default=0)
    fault_code: Mapped[str] = mapped_column(String(32), nullable=False, default="NONE")
    created_at: Mapped[datetime] = mapped_column(DATETIME(fsp=3), server_default=func.now(3))
    updated_at: Mapped[datetime] = mapped_column(
        DATETIME(fsp=3), server_default=func.now(3), server_onupdate=FetchedValue()
    )


class Notification(Base):
    """站内待办（common 支撑表）。"""

    __tablename__ = "notification"

    notification_id: Mapped[int] = mapped_column(PK, primary_key=True, autoincrement=True)
    account_id: Mapped[int] = mapped_column(PK, nullable=False)
    notification_type: Mapped[str] = mapped_column(String(50), nullable=False)
    business_key: Mapped[str] = mapped_column(String(120), nullable=False)
    title: Mapped[str] = mapped_column(String(100), nullable=False)
    content: Mapped[str] = mapped_column(String(1000), nullable=False)
    target_path: Mapped[str] = mapped_column(String(255), nullable=False)
    read_at: Mapped[Optional[datetime]] = mapped_column(DATETIME(fsp=3))
