"""请求与返回 DTO。

字段命名与《统一数据字典与接口函数规范 V1.4》第 7 章一致；
请求体统一 `extra='forbid'`，未登记字段直接 422（规范第 5 章要求）。
"""

from __future__ import annotations

from datetime import datetime
from decimal import Decimal
from typing import Optional

from pydantic import BaseModel, ConfigDict, Field


class StrictModel(BaseModel):
    model_config = ConfigDict(extra="forbid", from_attributes=True)


class PageQuery(StrictModel):
    page: int = Field(default=1, ge=1)
    page_size: int = Field(default=20, ge=1, le=100)


# ---------------------------------------------------------------------------
# 查询条件
# ---------------------------------------------------------------------------
class AlarmRuleQuery(PageQuery):
    severity: Optional[str] = None
    enabled: Optional[int] = None
    keyword: Optional[str] = None


class AlertQuery(PageQuery):
    pile_id: Optional[int] = None
    status: Optional[str] = None
    severity: Optional[str] = None
    occurred_from: Optional[datetime] = None
    occurred_to: Optional[datetime] = None


class WorkOrderQuery(PageQuery):
    status: Optional[str] = None
    assigned_to: Optional[int] = None
    alert_id: Optional[int] = None
    assigned_from: Optional[datetime] = None


class FaultReportQuery(PageQuery):
    status: Optional[str] = None
    gun_id: Optional[int] = None


class InspectionQuery(PageQuery):
    pile_id: Optional[int] = None
    result: Optional[str] = None


# ---------------------------------------------------------------------------
# 写入请求
# ---------------------------------------------------------------------------
class CreateAlarmRuleRequest(StrictModel):
    """新增告警规则。"""

    rule_code: str = Field(max_length=50, description="规则码，全局唯一，例如 DEMO-E101")
    fault_code: Optional[str] = Field(default=None, max_length=32, description="匹配的设备故障码；温度/心跳规则留空")
    metric: str = Field(pattern="^(fault_code|temperature|heartbeat)$", description="判断指标：故障码 / 温度阈值 / 心跳秒数")
    threshold_value: Optional[Decimal] = Field(default=None, description="温度阈值（℃）或心跳超时秒数")
    severity: str = Field(pattern="^(low|medium|high|critical)$", description="告警等级，决定响应时限")
    response_seconds: int = Field(gt=0, description="响应时限（秒），派单后据此计算接单截止")
    recovery_seconds: int = Field(gt=0, description="闭环后需连续正常的观察时长（秒）")
    enabled: int = Field(default=1, ge=0, le=1, description="是否启用：1 启用 / 0 停用")


class UpdateAlarmRuleRequest(StrictModel):
    """修改告警规则，只传需要改的字段。"""

    fault_code: Optional[str] = Field(default=None, description="匹配的设备故障码")
    metric: Optional[str] = Field(default=None, pattern="^(fault_code|temperature|heartbeat)$", description="判断指标")
    threshold_value: Optional[Decimal] = Field(default=None, description="阈值")
    severity: Optional[str] = Field(default=None, pattern="^(low|medium|high|critical)$", description="告警等级")
    response_seconds: Optional[int] = Field(default=None, gt=0, description="响应时限（秒）")
    recovery_seconds: Optional[int] = Field(default=None, gt=0, description="恢复观察时长（秒）")
    enabled: Optional[int] = Field(default=None, ge=0, le=1, description="是否启用")


class HeartbeatRequest(StrictModel):
    """设备心跳。"""

    pile_id: int = Field(description="桩编号")
    reported_at: Optional[datetime] = Field(default=None, description="设备侧上报时间（UTC）；不传取服务器时间")
    offline_seconds: int = Field(default=0, ge=0, description="设备自报的离线时长（秒）")


class DeviceReadingRequest(StrictModel):
    """运行采样，一分钟一条。"""

    pile_id: int = Field(description="桩编号")
    sampled_at: datetime = Field(description="采样时刻（UTC）")
    output_voltage_v: Decimal = Field(description="输出电压（V）")
    output_current_a: Decimal = Field(description="输出电流（A）")
    power_kw: Decimal = Field(description="输出功率（kW）")
    module_temperature_c: Decimal = Field(description="模块温度（℃）")
    offline_seconds: int = Field(default=0, ge=0, description="本次上报携带的离线时长（秒）")
    fault_code: str = Field(default="NONE", max_length=32, description="故障码；正常为 NONE")


class CreateWorkOrderRequest(StrictModel):
    """派单。"""

    assigned_to: int = Field(description="维修人员账号编号")
    note: Optional[str] = Field(default=None, max_length=500, description="派单备注")


class WorkOrderEventRequest(StrictModel):
    """回填工单事件。"""

    event_type: str = Field(
        pattern="^(accepted|arrived|repaired|review_passed|review_failed|closed)$",
        description="事件类型：接单 / 到场 / 修复 / 复核通过 / 复核未通过 / 闭环",
    )
    event_at: Optional[datetime] = Field(default=None, description="事件发生时间（UTC）；不传取服务器时间")
    note: Optional[str] = Field(default=None, max_length=500, description="处理说明")
    review_result: Optional[str] = Field(default=None, max_length=255, description="复核依据，复核类事件必填")
    parts_used: Optional[str] = Field(default=None, max_length=500, description="更换备件")
    result: Optional[str] = Field(default=None, max_length=500, description="处理结果")


class CreateFaultReportRequest(StrictModel):
    """车主报障。"""

    gun_id: int = Field(description="出问题的枪编号")
    order_id: Optional[int] = Field(default=None, description="关联订单编号（可选）")
    description: str = Field(min_length=5, max_length=1000, description="问题描述")


class HandleFaultReportRequest(StrictModel):
    """客服/运维处理报障。"""

    status: str = Field(pattern="^(linked|resolved)$", description="linked 已关联告警 / resolved 已办结")
    alert_id: Optional[int] = Field(default=None, description="关联的告警编号；status=linked 时必填")
    note: Optional[str] = Field(default=None, max_length=500, description="处理意见")


class CreateInspectionRequest(StrictModel):
    """新增巡检记录。"""

    pile_id: int = Field(description="巡检的桩编号")
    inspected_at: Optional[datetime] = Field(default=None, description="巡检时间（UTC）；不传取服务器时间")
    result: str = Field(pattern="^(normal|abnormal)$", description="检查结论：正常 / 异常")
    parts_used: Optional[str] = Field(default=None, max_length=500, description="更换的备件")
    note: Optional[str] = Field(default=None, max_length=1000, description="检查说明")


# ---------------------------------------------------------------------------
# 返回 DTO
# ---------------------------------------------------------------------------
class AlarmRuleDetail(StrictModel):
    alarm_rule_id: int
    rule_code: str
    fault_code: Optional[str]
    metric: str
    threshold_value: Optional[Decimal]
    severity: str
    response_seconds: int
    recovery_seconds: int
    enabled: int


class AlertDetail(StrictModel):
    alert_id: int
    pile_id: int
    gun_id: Optional[int]
    alarm_rule_id: int
    alert_code: str
    severity: str
    occurred_at: datetime
    recovered_at: Optional[datetime]
    status: str
    response_seconds_snapshot: int
    normal_since_at: Optional[datetime]
    is_overdue: bool = False


class WorkOrderDetail(StrictModel):
    work_order_id: int
    alert_id: int
    assigned_to: int
    assigned_by: int
    assigned_at: datetime
    response_due_at: datetime
    status: str
    escalation_level: int
    parts_used: Optional[str]
    result: Optional[str]
    accept_seconds: Optional[int] = None
    total_seconds: Optional[int] = None


class WorkOrderEventDetail(StrictModel):
    event_id: int
    work_order_id: int
    event_type: str
    event_at: datetime
    old_status: str
    new_status: str
    actor_account_id: Optional[int]
    note: Optional[str]
    review_result: Optional[str]


class FaultReportDetail(StrictModel):
    report_id: int
    user_id: int
    gun_id: int
    order_id: Optional[int]
    description: str
    status: str
    alert_id: Optional[int]
    handled_by: Optional[int]
    handled_at: Optional[datetime]


class InspectionDetail(StrictModel):
    inspection_id: int
    pile_id: int
    inspected_by: int
    inspected_at: datetime
    result: str
    parts_used: Optional[str]
    note: Optional[str]


class HeartbeatAck(StrictModel):
    pile_id: int
    is_online: int
    server_time: datetime
    duplicate: bool = False


class ReadingAck(StrictModel):
    sample_id: int
    accepted: bool = True
    alert_generated: bool = False
