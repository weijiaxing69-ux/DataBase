"""场站、运营商与充电桩 HTTP 接口：接收参数，获取身份，再调用 Service。"""

# Annotated[类型, 附加说明]：同时告诉 FastAPI 参数的类型和获取方式。
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Path, Query
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.core import security
from app.shared.contracts import Actor, PageResult
from . import service
from .schemas import (
    CreateStationRequest,
    StationDetail,
    StationQuery,
    UpdateStationRequest,
    CreateOperatorRequest,
    OperatorDetail,
    OperatorQuery,
    UpdateOperatorRequest,
    CreatePileRequest,
    PileDetail,
    PileQuery,
    UpdatePileRequest,
    CreateGunRequest,
    GunDetail,
    GunQuery,
    UpdateGunRequest,
)


def _require_scope_integration() -> None:
    # 公共检查已实现，移除原先无条件503；具体权限和范围仍由每个 Service 检查。
    # 保留依赖名称方便原有隔离测试使用，也检查后续集成时有没有误移除公共函数。
    if not callable(getattr(security, "assert_resource_scope", None)):
        raise HTTPException(status_code=503, detail="场站设施模块资源范围检查尚未接入")


# APIRouter 将本模块的接口集中管理；main.py 再把它注册到应用中。
# dependencies 中的函数会在该路由组的请求处理过程中执行。
router = APIRouter(dependencies=[Depends(_require_scope_integration)])
# 读取请求头 Authorization: Bearer <token>。
# auto_error=False 表示缺少凭证时先返回 None，由我们在下面给出 401 错误。
# HTTPBearer 只提取凭证，不负责验证 token 是否有效。
_bearer = HTTPBearer(auto_error=False)


def _get_request_actor(
    credentials: Annotated[
        HTTPAuthorizationCredentials | None, Depends(_bearer)
    ],
) -> Actor:
    # credentials 是提取出的凭证对象；缺少或不符合 Bearer 格式时可能为 None。
    if credentials is None:
        raise HTTPException(
            status_code=401,
            detail="请提供 Bearer 登录凭证",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # 使用模块导入，成员4尚未提供函数时仍可启动应用、查看接口文档。
    # getattr 获取 security 模块里的函数；找不到时返回 None，避免导入时直接报错。
    authenticate = getattr(security, "get_current_actor", None)
    if not callable(authenticate):
        raise HTTPException(status_code=503, detail="登录认证尚未接入")
    # 外层 credentials 是凭证对象，内层 .credentials 才是 token 字符串。
    # 认证函数验证 token、加载账号角色与权限后，返回 Actor。
    return authenticate(credentials.credentials)


# 以下是可复用的参数类型别名，减少每个接口重复编写 Depends。
# 参数写成 db: Database 时，FastAPI 调用 get_db 提供数据库会话。
Database = Annotated[Session, Depends(get_db)]
# 参数写成 actor: CurrentActor 时，FastAPI 执行认证依赖并注入当前用户身份。
# actor 不是由前端提交的 JSON 字段，也不是网址查询参数。
CurrentActor = Annotated[Actor, Depends(_get_request_actor)]
# Path 表示从路径读取编号；int 要求可转换成整数，gt=0 要求大于 0。
StationId = Annotated[int, Path(gt=0, description="场站编号")]
OperatorId = Annotated[int, Path(gt=0, description="运营商编号")]
PileId = Annotated[int, Path(gt=0, description="充电桩编号")]
GunId = Annotated[int, Path(gt=0, description="充电枪编号")]


# main.py 已添加 /api/v1/assets 前缀，这里只填写后半段地址。
# @router.get/post/patch 把 HTTP 方法和地址绑定到下面的 Python 函数。
# response_model 规定响应字段、校验与序列化格式，summary 显示在 /docs 中。
# Router 负责接收和转发数据，查询、权限规则与事务由 Service 等层负责。
# GET /api/v1/assets/stations?page=1&page_size=20
@router.get("/stations", response_model=PageResult[StationDetail], summary="查询场站列表")
def list_stations(
    db: Database,
    actor: CurrentActor,
    query: Annotated[StationQuery, Depends()],
):
    # Depends 将查询字符串组装为 StationQuery，而不是读取请求体。
    # PageResult[StationDetail] 返回 items、total、page、page_size。
    return service.list_stations(db, actor=actor, query=query)


# GET /api/v1/assets/stations/3：路径中的 3 传给 station_id。
@router.get("/stations/{station_id}", response_model=StationDetail, summary="查询场站详情")
def get_station(station_id: StationId, db: Database, actor: CurrentActor):
    return service.get_station(db, actor=actor, station_id=station_id)


# POST /api/v1/assets/stations：新增内容放在 JSON 请求体，不放在路径中。
@router.post("/stations", response_model=StationDetail, summary="新增场站")
def create_station(request: CreateStationRequest, db: Database, actor: CurrentActor):
    # Pydantic 自动校验 JSON 请求体。
    return service.create_station(db, actor=actor, request=request)


# PATCH /api/v1/assets/stations/3：只提交需要修改的字段。
# 例如请求体 {"station_name":"学校东门站"}，其他字段保持原值。
@router.patch("/stations/{station_id}", response_model=StationDetail, summary="修改场站")
def update_station(
    station_id: StationId,
    request: UpdateStationRequest,
    db: Database,
    actor: CurrentActor,
):
    return service.update_station(
        db, actor=actor, station_id=station_id, request=request
    )


# 查询运营商列表：GET /api/v1/assets/operators?page=2&page_size=10&keyword=新能源
@router.get("/operators", response_model=PageResult[OperatorDetail], summary="查询运营商列表")
def list_operators(
    db: Database,
    actor: CurrentActor,
    query: Annotated[OperatorQuery, Query()],
):
    # Query() 从网址查询参数构造 OperatorQuery，并执行其中的字段和时间校验。
    # db 是数据库工具，actor 表示谁在查，query 表示想怎么查。
    return service.list_operators(db,actor=actor,query=query)


# 查询单个运营商：GET /api/v1/assets/operators/1，operator_id 得到整数 1。
@router.get("/operators/{operator_id}", response_model=OperatorDetail, summary="查询运营商详情")
def get_operator(operator_id: OperatorId, db: Database, actor: CurrentActor):
    # 调用 Service，再将其结果交给 FastAPI 按 OperatorDetail 序列化。
    return service.get_operator(db,actor=actor,operator_id=operator_id)


# 新增运营商：POST /api/v1/assets/operators。
# CreateOperatorRequest 继承 BaseModel，因此 request 自动从 JSON 请求体读取。
# 必填字段缺失或字段格式不正确时，FastAPI 会返回 422 校验错误。
@router.post("/operators", response_model=OperatorDetail, summary="新增运营商")
def create_operator(request: CreateOperatorRequest, db: Database, actor: CurrentActor):
    # Service 负责角色检查、重复校验、电话加密、数据库写入和事务提交。
    return service.create_operator(db,actor=actor,request=request)


# 修改运营商：PATCH /api/v1/assets/operators/1。
# operator_id 确定修改谁，request 指定修改什么，actor 确定谁在操作。
# 例如请求体 {"status":"disabled"}，只申请修改启用状态。
@router.patch("/operators/{operator_id}", response_model=OperatorDetail, summary="修改运营商")
def update_operator(
    operator_id: OperatorId,
    request: UpdateOperatorRequest,
    db: Database,
    actor: CurrentActor,
):
    # Router 不重新创建 Operator，也不在这里调用 commit，统一交给 Service。
    return service.update_operator(
        db,actor=actor,operator_id=operator_id,request=request
    )


# GET /api/v1/assets/piles?page=1&page_size=20&station_id=1
@router.get("/piles", response_model=PageResult[PileDetail], summary="查询充电桩列表")
def list_piles(
    db: Database,
    actor: CurrentActor,
    query: Annotated[PileQuery, Query()],
):
    # 从网址查询字符串组装 PileQuery，并校验分页、状态和时间范围。
    # 权限和资源范围交给 Service；路由组的公共接入检查仍然生效。
    return service.list_piles(db, actor=actor, query=query)


# GET /api/v1/assets/piles/1：路径中的编号传给 pile_id。
@router.get("/piles/{pile_id}", response_model=PileDetail, summary="查询充电桩详情")
def get_pile(pile_id: PileId, db: Database, actor: CurrentActor):
    return service.get_pile(db, actor=actor, pile_id=pile_id)


# POST /api/v1/assets/piles：新增字段放在 JSON 请求体中。
@router.post("/piles", response_model=PileDetail, summary="新增充电桩")
def create_pile(request: CreatePileRequest, db: Database, actor: CurrentActor):
    # FastAPI 校验请求；场站检查、序列号去重和事务处理由 Service 完成。
    return service.create_pile(db, actor=actor, request=request)


# PATCH /api/v1/assets/piles/1：只提交需要修改的字段。
@router.patch("/piles/{pile_id}", response_model=PileDetail, summary="修改充电桩")
def update_pile(
    pile_id: PileId,
    request: UpdatePileRequest,
    db: Database,
    actor: CurrentActor,
):
    # 例如 {"model_name":"新型号"}；{"warranty_until":null} 表示清空质保日期。
    return service.update_pile(db, actor=actor, pile_id=pile_id, request=request)


# GET /api/v1/assets/guns?station_id=1&page=1&page_size=20
@router.get("/guns", response_model=PageResult[GunDetail], summary="查询充电枪列表")
def list_guns(db: Database, actor: CurrentActor, query: Annotated[GunQuery, Query()]):
    # Query 将网址查询参数组装为 GunQuery；范围检查及分页由 Service 完成
    return service.list_guns(db, actor=actor, query=query)


# GET /api/v1/assets/guns/1：gun_id 从路径读取，必须为正整数
@router.get("/guns/{gun_id}", response_model=GunDetail, summary="查询充电枪详情")
def get_gun_detail(gun_id: GunId, db: Database, actor: CurrentActor):
    # 文档中的详情入口是 get_gun_detail，区别于返回 GunSnapshot 的辅助函数
    return service.get_gun_detail(db, actor=actor, gun_id=gun_id)


# POST /api/v1/assets/guns：新增数据从 JSON 请求体读取
@router.post("/guns", response_model=GunDetail, summary="新增充电枪")
def create_gun(request: CreateGunRequest, db: Database, actor: CurrentActor):
    # 参数格式由 Schema 校验，枪序号去重、功率限制与事务由 Service 处理
    return service.create_gun(db, actor=actor, request=request)


# PATCH /api/v1/assets/guns/1：只提交需要修改的档案字段
@router.patch("/guns/{gun_id}", response_model=GunDetail, summary="修改充电枪")
def update_gun(gun_id: GunId, request: UpdateGunRequest, db: Database, actor: CurrentActor):
    # 不能通过此接口修改所属桩、枪序号、运行状态或故障事实
    return service.update_gun(db, actor=actor, gun_id=gun_id, request=request)



# 设备业务接口：参数由 FastAPI 校验，权限与事务交给 Service。
from .schemas import (
    AcceptanceDetail,
    AcceptanceQuery,
    ChangeRequestDetail,
    ChangeRequestQuery,
    CreateAcceptanceRequest,
    CreateChangeRequest,
    DeviceCommandDetail,
    DeviceCommandQuery,
    DeviceCredentialIssue,
    DeviceStatusLogDetail,
    DeviceStatusLogQuery,
    IssueDeviceCredentialRequest,
    ReviewChangeRequest,
)


# 设备业务接口：参数由 FastAPI 校验，权限与事务交给 Service。
@router.get("/change-requests", response_model=PageResult[ChangeRequestDetail], summary="查询设备变更申请列表")
def list_change_requests(db: Database, actor: CurrentActor, query: Annotated[ChangeRequestQuery, Query()]):
    return service.list_change_requests(db, actor=actor , query=query)


# 设备业务接口：参数由 FastAPI 校验，权限与事务交给 Service。
@router.get("/change-requests/{request_id}", response_model=ChangeRequestDetail, summary="查询设备变更申请详情")
def get_change_request(request_id: Annotated[int, Path(gt=0)], db: Database, actor: CurrentActor):
    return service.get_change_request(db, actor=actor , request_id=request_id)


# 设备业务接口：参数由 FastAPI 校验，权限与事务交给 Service。
@router.post("/change-requests", response_model=ChangeRequestDetail, summary="提交设备变更申请")
def create_change_request(db: Database, actor: CurrentActor, request: CreateChangeRequest):
    return service.create_change_request(db, actor=actor , request=request)


# 设备业务接口：参数由 FastAPI 校验，权限与事务交给 Service。
@router.post("/change-requests/{request_id}/reviews", response_model=ChangeRequestDetail, summary="审批设备变更申请")
def review_change_request(request_id: Annotated[int, Path(gt=0)], db: Database, actor: CurrentActor, request: ReviewChangeRequest):
    return service.review_change_request(db, actor=actor, request_id=request_id, request=request)


# 设备业务接口：参数由 FastAPI 校验，权限与事务交给 Service。
@router.get("/acceptances", response_model=PageResult[AcceptanceDetail], summary="查询设备验收记录列表")
def list_acceptances(db: Database, actor: CurrentActor, query: Annotated[AcceptanceQuery, Query()]):
    return service.list_acceptances(db, actor=actor , query=query)


# 设备业务接口：参数由 FastAPI 校验，权限与事务交给 Service。
@router.get("/acceptances/{acceptance_id}", response_model=AcceptanceDetail, summary="查询设备验收详情")
def get_acceptance(acceptance_id: Annotated[int, Path(gt=0)], db: Database, actor: CurrentActor):
    return service.get_acceptance(db, actor=actor , acceptance_id=acceptance_id)


# 设备业务接口：参数由 FastAPI 校验，权限与事务交给 Service。
@router.post("/acceptances", response_model=AcceptanceDetail, summary="新增设备验收记录")
def create_acceptance(db: Database, actor: CurrentActor, request: CreateAcceptanceRequest):
    return service.create_acceptance(db, actor=actor , request=request)


# 设备业务接口：参数由 FastAPI 校验，权限与事务交给 Service。
@router.get("/device-commands", response_model=PageResult[DeviceCommandDetail], summary="查询设备命令列表")
def list_device_commands(db: Database, actor: CurrentActor, query: Annotated[DeviceCommandQuery, Query()]):
    return service.list_device_commands(db, actor=actor , query=query)


# 设备业务接口：参数由 FastAPI 校验，权限与事务交给 Service。
@router.get("/device-commands/{command_id}", response_model=DeviceCommandDetail, summary="查询设备命令详情")
def get_device_command(command_id: Annotated[int, Path(gt=0)], db: Database, actor: CurrentActor):
    return service.get_device_command(db, actor=actor , command_id=command_id)


# 设备业务接口：参数由 FastAPI 校验，权限与事务交给 Service。
@router.get("/status-logs", response_model=PageResult[DeviceStatusLogDetail], summary="查询设备状态历史列表")
def list_device_status_logs(db: Database, actor: CurrentActor, query: Annotated[DeviceStatusLogQuery, Query()]):
    return service.list_device_status_logs(db, actor=actor , query=query)


# 设备业务接口：参数由 FastAPI 校验，权限与事务交给 Service。
@router.get("/status-logs/{status_log_id}", response_model=DeviceStatusLogDetail, summary="查询设备状态历史详情")
def get_device_status_log(status_log_id: Annotated[int, Path(gt=0)], db: Database, actor: CurrentActor):
    return service.get_device_status_log(db, actor=actor , status_log_id=status_log_id)


# 设备业务接口：参数由 FastAPI 校验，权限与事务交给 Service。
@router.post("/piles/{pile_id}/credentials", response_model=DeviceCredentialIssue, summary="签发设备接入凭据")
def issue_device_credential(pile_id: Annotated[int, Path(gt=0)], db: Database, actor: CurrentActor, request: IssueDeviceCredentialRequest):
    return service.issue_device_credential(db, actor=actor , pile_id=pile_id, request=request)
