"""设备监控与故障工单 HTTP 接口：接收参数、获取身份，再调用 Service。

路径与《统一数据字典与接口函数规范 V1.4》第 5 章 maintenance 段一致；
main.py 注册时统一加前缀 `/api/v1/maintenance` 与标签「设备运维」。
"""

from typing import Annotated, Optional

from fastapi import APIRouter, Depends, Header, HTTPException, Path, Query
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.orm import Session

from app.core import security
from app.core.database import SessionLocal, get_db
from app.shared.contracts import Actor, PageResult

from . import emergency, schemas as s, service
from .device import DeviceActor, authenticate_device

router = APIRouter()
_bearer = HTTPBearer(auto_error=False)


def _get_request_actor(
    credentials: Annotated[HTTPAuthorizationCredentials | None, Depends(_bearer)],
) -> Actor:
    """从 Authorization: Bearer <token> 解析当前账号；角色与权限每次从库读取。"""
    if credentials is None:
        raise HTTPException(401, "请提供 Bearer 登录凭证", headers={"WWW-Authenticate": "Bearer"})
    authenticate = getattr(security, "get_current_actor", None)
    if not callable(authenticate):
        raise HTTPException(503, "登录认证尚未接入")
    return authenticate(credentials.credentials)


Database = Annotated[Session, Depends(get_db)]
CurrentActor = Annotated[Actor, Depends(_get_request_actor)]


def _device_token(x_device_token: Annotated[str | None, Header()] = None) -> str:
    if not x_device_token:
        raise HTTPException(401, "缺少设备凭据：X-Device-Token", headers={"WWW-Authenticate": "Device"})
    return x_device_token


def _device_actor(token: Annotated[str, Depends(_device_token)]) -> DeviceActor:
    # 用独立会话校验凭据，避免给业务会话留下未结束的事务
    with SessionLocal() as db:
        return authenticate_device(db, token)


Device = Annotated[DeviceActor, Depends(_device_actor)]


# ---------------------------------------------------------------- 告警规则
@router.get(
    "/alarm-rules",
    summary="查询告警规则列表",
    description="按等级、启用状态、规则码关键字过滤。规则改动不影响在途告警——告警保存了发生时的等级与时限快照。",
    response_model=PageResult[s.AlarmRuleDetail],
)
def list_alarm_rules(db: Database, actor: CurrentActor, query: Annotated[s.AlarmRuleQuery, Depends()]):
    return service.list_alarm_rules(db, actor=actor, query=query)


@router.get(
    "/alarm-rules/{alarm_rule_id}",
    summary="查询单条告警规则",
    response_model=s.AlarmRuleDetail,
)
def get_alarm_rule(
    db: Database, actor: CurrentActor, alarm_rule_id: Annotated[int, Path(gt=0)]
):
    return service.get_alarm_rule(db, actor=actor, alarm_rule_id=alarm_rule_id)


@router.post(
    "/alarm-rules",
    summary="新增告警规则",
    description="metric 取 fault_code / temperature / heartbeat；response_seconds 决定派单后的接单截止，recovery_seconds 决定闭环后的连续正常观察期。",
    status_code=201,
    response_model=s.AlarmRuleDetail,
)
def create_alarm_rule(db: Database, actor: CurrentActor, request: s.CreateAlarmRuleRequest):
    return service.create_alarm_rule(db, actor=actor, request=request)


@router.patch(
    "/alarm-rules/{alarm_rule_id}",
    summary="修改告警规则",
    description="只传需要改的字段，省略的保持不变。",
    response_model=s.AlarmRuleDetail,
)
def update_alarm_rule(
    db: Database,
    actor: CurrentActor,
    alarm_rule_id: Annotated[int, Path(gt=0)],
    request: s.UpdateAlarmRuleRequest,
):
    return service.update_alarm_rule(db, actor=actor, alarm_rule_id=alarm_rule_id, request=request)


# ---------------------------------------------------------------- 告警
@router.get(
    "/alerts",
    summary="查询设备告警列表",
    description="按桩、状态、等级、发生时间过滤。未恢复告警按「桩:枪:告警码」唯一，恢复后同一故障可再次上报。",
    response_model=PageResult[s.AlertDetail],
)
def list_alerts(db: Database, actor: CurrentActor, query: Annotated[s.AlertQuery, Depends()]):
    return service.list_alerts(db, actor=actor, query=query)


@router.get(
    "/alerts/{alert_id}",
    summary="查询告警详情",
    description="is_overdue 表示是否已超过响应时限（按告警发生时刻 + 响应时限快照计算）。",
    response_model=s.AlertDetail,
)
def get_alert(db: Database, actor: CurrentActor, alert_id: Annotated[int, Path(gt=0)]):
    return service.get_alert(db, actor=actor, alert_id=alert_id)


# ---------------------------------------------------------------- 工单
@router.get(
    "/work-orders",
    summary="查询维修工单列表",
    description="运维工程师只能查询指派给自己的工单；管理员可按状态、处理人、告警过滤。",
    response_model=PageResult[s.WorkOrderDetail],
)
def list_work_orders(
    db: Database, actor: CurrentActor, query: Annotated[s.WorkOrderQuery, Depends()]
):
    return service.list_work_orders(db, actor=actor, query=query)


@router.get(
    "/work-orders/{work_order_id}",
    summary="查询工单详情",
    description="accept_seconds 为接单耗时，total_seconds 为从派单到闭环的总耗时。",
    response_model=s.WorkOrderDetail,
)
def get_work_order(
    db: Database, actor: CurrentActor, work_order_id: Annotated[int, Path(gt=0)]
):
    return service.get_work_order(db, actor=actor, work_order_id=work_order_id)


@router.get(
    "/work-orders/{work_order_id}/events",
    summary="查询工单流转时间线",
    description="按时间顺序返回接单、到场、修复、复核、升级、闭环等事件，用于详情页展示处置轨迹。",
    response_model=list[s.WorkOrderEventDetail],
)
def list_work_order_events(
    db: Database, actor: CurrentActor, work_order_id: Annotated[int, Path(gt=0)]
):
    return service.list_work_order_events(db, actor=actor, work_order_id=work_order_id)


@router.post(
    "/alerts/{alert_id}/work-orders",
    summary="派单（创建工单）",
    description="接单截止 = 派单时刻 + 告警的响应时限快照；同一告警可多次派单。",
    status_code=201,
    response_model=s.WorkOrderDetail,
)
def create_work_order(
    db: Database,
    actor: CurrentActor,
    alert_id: Annotated[int, Path(gt=0)],
    request: s.CreateWorkOrderRequest,
):
    return service.create_work_order(db, actor=actor, alert_id=alert_id, request=request)


@router.post(
    "/work-orders/{work_order_id}/events",
    summary="回填工单事件（接单/到场/修复/复核/闭环）",
    description=(
        "状态机：assigned → accepted → arrived → repaired → closed；"
        "复核未通过用 review_failed 回到 arrived 继续维修。"
        "闭环时若该告警下所有工单都已关闭，会把告警置为 recovering 并开始计算连续正常时长。"
    ),
    response_model=s.WorkOrderDetail,
)
def append_work_order_event(
    db: Database,
    actor: CurrentActor,
    work_order_id: Annotated[int, Path(gt=0)],
    request: s.WorkOrderEventRequest,
):
    return service.append_work_order_event(
        db, actor=actor, work_order_id=work_order_id, request=request
    )


# ---------------------------------------------------------------- 设备上报
@router.post(
    "/heartbeats",
    summary="设备心跳上报（设备凭据）",
    description="需在请求头 X-Device-Token 携带设备凭据；只判断通信在线，不判断枪是否占用。重复上报返回 duplicate=true。",
    response_model=s.HeartbeatAck,
)
def heartbeat(db: Database, device: Device, request: s.HeartbeatRequest):
    return service.receive_heartbeat(db, device=device, request=request)


@router.post(
    "/readings",
    summary="上报运行采样（设备凭据）",
    description="需在请求头 X-Device-Token 携带设备凭据；入库后由触发器自动生成告警，同一桩同一采样时刻重复上报返回 duplicate=true。",
    response_model=s.ReadingAck,
)
def upload_reading(db: Database, device: Device, request: s.DeviceReadingRequest):
    return service.ingest_device_reading(db, device=device, request=request)


# ---------------------------------------------------------------- 报障 / 巡检
@router.get(
    "/fault-reports",
    summary="查询报障列表",
    response_model=PageResult[s.FaultReportDetail],
)
def list_fault_reports(
    db: Database, actor: CurrentActor, query: Annotated[s.FaultReportQuery, Depends()]
):
    return service.list_fault_reports(db, actor=actor, query=query)


@router.get(
    "/fault-reports/{report_id}",
    summary="查询报障详情",
    response_model=s.FaultReportDetail,
)
def get_fault_report(db: Database, actor: CurrentActor, report_id: Annotated[int, Path(gt=0)]):
    return service.get_fault_report(db, actor=actor, report_id=report_id)


@router.post(
    "/fault-reports",
    summary="提交报障（车主）",
    description="用当前登录账号关联的车主档案提交；账号未绑定车主档案时返回 400，客服与运维需以车主账号提交。",
    status_code=201,
    response_model=s.FaultReportDetail,
)
def create_fault_report(db: Database, actor: CurrentActor, request: s.CreateFaultReportRequest):
    return service.create_fault_report(db, actor=actor, request=request)


@router.post(
    "/fault-reports/{report_id}/handling",
    summary="处理报障（核实/关联告警/办结）",
    description="status 取 linked（已关联告警）或 resolved（已办结）；linked 时必须给 alert_id。",
    response_model=s.FaultReportDetail,
)
def handle_fault_report(
    db: Database,
    actor: CurrentActor,
    report_id: Annotated[int, Path(gt=0)],
    request: s.HandleFaultReportRequest,
):
    return service.handle_fault_report(db, actor=actor, report_id=report_id, request=request)


@router.get(
    "/inspections",
    summary="查询巡检记录",
    response_model=PageResult[s.InspectionDetail],
)
def list_inspections(
    db: Database, actor: CurrentActor, query: Annotated[s.InspectionQuery, Depends()]
):
    return service.list_inspections(db, actor=actor, query=query)


@router.get(
    "/inspections/{inspection_id}",
    summary="查询巡检详情",
    response_model=s.InspectionDetail,
)
def get_inspection(
    db: Database, actor: CurrentActor, inspection_id: Annotated[int, Path(gt=0)]
):
    return service.get_inspection(db, actor=actor, inspection_id=inspection_id)


@router.post(
    "/inspections",
    summary="新增巡检记录",
    description="result 取 normal / abnormal；备件更换写在 parts_used。",
    status_code=201,
    response_model=s.InspectionDetail,
)
def create_inspection(db: Database, actor: CurrentActor, request: s.CreateInspectionRequest):
    return service.create_inspection(db, actor=actor, request=request)


# ---------------------------------------------------------------- 应急事件（V1.5）
@router.get(
    "/incidents",
    summary="事件看板",
    description="返回事件标题、级别、状态、关联告警数、未闭环工单数、响应与恢复耗时，以及是否突破 SLA。",
    response_model=list[s.IncidentBoardItem],
)
def list_incidents(db: Database, actor: CurrentActor):
    return emergency.list_incident_board(db, actor=actor)


@router.post(
    "/incidents",
    summary="声明应急事件",
    description="同场站同类别只允许一个进行中事件（生成列唯一键兜底）；声明后立即做一次升级扫描。",
    status_code=201,
    response_model=s.IncidentCreated,
)
def declare_incident(
    db: Database,
    actor: CurrentActor,
    operator_id: Annotated[int, Query(gt=0, description="运营商编号")],
    title: Annotated[str, Query(min_length=2, max_length=200, description="事件标题")],
    station_id: Annotated[Optional[int], Query(gt=0, description="场站编号；跨场站事件留空")] = None,
    category: Annotated[str, Query(description="根因类别")] = "hardware",
    severity: Annotated[str, Query(description="事件级别 P1-P4")] = "P2",
    alert_id: Annotated[Optional[int], Query(gt=0, description="根因告警编号")] = None,
):
    incident_id = emergency.declare_incident(
        db, actor=actor, operator_id=operator_id, station_id=station_id,
        category=category, severity=severity, title=title, alert_id=alert_id,
    )
    return {"incident_id": incident_id}


@router.post(
    "/incidents/escalate",
    summary="执行一次升级扫描",
    description="按「级别 × 持续时长 × 影响桩数」匹配策略；同一事件同一策略只触发一次。",
    response_model=s.EscalationResult,
)
def escalate(db: Database, actor: CurrentActor):
    return {"escalated": emergency.escalate_incidents(db, actor=actor)}


# ---------------------------------------------------------------- 统计与运维任务（拓展）
@router.get(
    "/stats/overview",
    summary="看板总览数据",
    description="一次返回 KPI、近 30 天告警趋势、等级分布、场站告警排行。",
)
def stats_overview(db: Database, actor: CurrentActor):
    return service.overview(db, actor=actor)


@router.get(
    "/stats/performance",
    summary="运维绩效统计",
    description="按处理人统计工单量、接单/闭环平均耗时、超时单数；按场站统计告警量与平均恢复时长。",
    response_model=s.PerformanceStats,
)
def stats_performance(db: Database, actor: CurrentActor):
    return service.performance_stats(db, actor=actor)


@router.post(
    "/tasks/{name}/run",
    summary="手动触发一次后台任务",
    description="offline 心跳超时置离线；overdue 超时未接单升级；recovery 推进告警恢复；charging 充电中断；safety 严重告警停机派单；recurring 复发故障升级；inspection 巡检到期；temperature 高温预警；metering 计量异常；occupied 充满占位；overload 场站功率过载；duration 长时间充电占位；voltage 电压越限；gun_mismatch 枪状态与订单不一致；fault_state_mismatch 故障标记未复位；sampling_gap 充电订单采样断流。",
    response_model=s.TaskRunResult,
)
def run_task(
    db: Database,
    actor: CurrentActor,
    name: Annotated[str, Path(pattern="^(offline|overdue|recovery|charging|safety|recurring|inspection|temperature|metering|occupied|overload|duration|voltage|gun_mismatch|fault_state_mismatch|sampling_gap)$")],
):
    return service.run_task(db, actor=actor, name=name)


# ---------------------------------------------------------------- 备件（V1.5）
@router.get(
    "/spare-parts",
    summary="查询备件库存",
    description="only_low=true 只看低于安全库存的备件；中心库对所有账号可见，场站库按授权过滤。",
    response_model=PageResult[s.SparePartDetail],
)
def list_spare_parts(
    db: Database, actor: CurrentActor, query: Annotated[s.PartQuery, Depends()]
):
    return service.list_spare_parts(db, actor=actor, query=query)


@router.post(
    "/part-usages",
    summary="领用备件",
    description="库存由数据库触发器扣减；数量不足返回 409，不会出现负库存。",
    status_code=201,
    response_model=s.PartUsageDetail,
)
def create_part_usage(db: Database, actor: CurrentActor, request: s.CreatePartUsageRequest):
    return service.create_part_usage(db, actor=actor, request=request)


@router.post(
    "/part-stock-ins",
    summary="备件入库",
    description="库存增加并记一条流水；场站仓需有该场站授权。",
    status_code=201,
    response_model=s.PartMovementDetail,
)
def stock_in_part(db: Database, actor: CurrentActor, request: s.StockInRequest):
    return service.stock_in_part(db, actor=actor, request=request)


@router.get(
    "/part-movements",
    summary="查询备件出入库流水",
    response_model=list[s.PartMovementDetail],
)
def list_part_movements(
    db: Database, actor: CurrentActor, part_id: Annotated[int, Query(gt=0)]
):
    return service.list_part_movements(db, actor=actor, part_id=part_id)


@router.get(
    "/part-usages",
    summary="查询工单的备件领用记录",
    response_model=list[s.PartUsageDetail],
)
def list_part_usages(
    db: Database, actor: CurrentActor, work_order_id: Annotated[int, Query(gt=0)]
):
    return service.list_part_usages(db, actor=actor, work_order_id=work_order_id)


@router.post(
    "/incidents/{incident_id}/close",
    summary="关闭应急事件",
    status_code=204,
)
def close_incident(
    db: Database,
    actor: CurrentActor,
    incident_id: Annotated[int, Path(gt=0)],
    summary: Annotated[str, Query(min_length=2, max_length=1000, description="关闭说明")],
):
    emergency.close_incident(db, actor=actor, incident_id=incident_id, summary=summary)
