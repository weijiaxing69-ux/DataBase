"""assets 模块：业务逻辑及事务边界，按 V1.4 契约逐步实现。"""
# 阅读提示：Router 接收 HTTP 参数后调用本文件；本文件检查业务规则，再通过 DAO 访问数据库。
# db：本次操作使用的数据库会话，不是某张表，也不是查询结果。
# actor：服务端认证得到的当前账号，account_id 是账号编号，roles 是角色，permissions 是权限码。
# query：列表查询条件（页码、关键词等）；request：新增、修改、审批时提交的数据。
# pile_id / gun_id / request_id 等：要操作的具体记录编号；函数参数中的 * 要求后续参数按名称传递。
# _ 开头的函数供内部复用；Detail 是响应结构，数据库模型是实际被查询或修改的对象。
# flush 发送 SQL 但不提交；commit 提交事务；rollback 撤销未提交修改；refresh 重新读取数据库记录。
# 普通写入入口自己提交或回滚；下方供订单等模块调用的函数不提交，由调用方统一管理事务。
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError
from cryptography.fernet import Fernet

from app.core import security
from app.core.config import settings
from app.core.errors import BusinessError
from app.shared.contracts import PageResult,Actor
from . import dao
from .schemas import *
from .models import *


def list_stations(db: Session, *, actor: Actor, query: StationQuery) -> PageResult[StationDetail]:
    # 查询场站列表：先检查查询权限，再把当前页记录转换成 StationDetail。
    if not security.has_permission(actor, "assets.station.read"):
        raise PermissionError("该用户没有权限查看场站列表")
    # 检查时间范围
    if (
        query.start_at is not None
        and query.end_at is not None
        and query.start_at >= query.end_at
    ): #TODO 不符合条件直接抛出异常
        raise ValueError("开始时间必须早于结束时间")

    # 查询当前页的场站
    # 授权范围必须在分页和计数之前应用，避免越权记录或错误的总数。
    scope = Station.station_id.in_(_visible_stations(db, actor))
    stmt = dao._apply_station_filters(select(Station).where(scope), query=query)
    stations = list(db.scalars(stmt.order_by(Station.station_id)
        .offset((query.page - 1) * query.page_size).limit(query.page_size)))

    # 统计符合条件的场站总数
    total = db.scalar(dao._apply_station_filters(
        select(dao.func.count()).select_from(Station).where(scope), query=query)) or 0

    # 将数据库模型对象转换成响应数据
    items = [
        StationDetail.model_validate(station)
        for station in stations
    ]

    # 返回分页结果
    return PageResult[StationDetail](
        items=items,
        total=total,
        page=query.page,
        page_size=query.page_size,
    )
#TODO 查找用户能看的场站
def get_station(db, *, actor: Actor, station_id: int):
    # 查询一个场站：station_id 指定查询谁，actor 表示当前操作账号。
    station=dao.get_station_by_id(db=db,station_id=station_id)
    #TODO 判断是否找到
    if station is None:
        raise ValueError(f"场站{station_id}不存在")

    #TODO 根据actor检查是否有权限
    if not security.has_permission(actor, 'assets.station.read'):
        raise PermissionError("该用户没有权限查看场站信息")
    security.assert_resource_scope(db, actor, resource_type="station", resource_id=station_id)
    return StationDetail.model_validate(station)

def get_operator(db, *, actor: Actor, operator_id: int) -> OperatorDetail:
    """查询运营商详情，只返回白名单字段，不提交或关闭数据库会话。"""
    # 公共函数由认证模块提供；未接入时禁止跳过权限和资源范围检查。
    # 查询运营商详情，并将电话转换为脱敏信息后返回。
    require_permission = getattr(security, "require_permission", None)
    assert_resource_scope = getattr(security, "assert_resource_scope", None)
    if not callable(require_permission) or not callable(assert_resource_scope):
        raise NotImplementedError("请先接入公共权限和资源范围检查函数")

    require_permission(actor, "assets.operator.read")

    # model 传数据库模型 Operator，不是登录身份 Actor 或响应 Schema。
    operator = dao.get_by_id(db, Operator, operator_id)
    if operator is None:
        # TODO 公共 BusinessError 提供后，替换为团队统一的不存在异常。
        raise BusinessError("运营商不存在", status_code=404, code="not_found")

    # operator 对应资源类型的取值需与公共权限模块联调确认。
    assert_resource_scope(
        db, actor, resource_type="operator", resource_id=operator.operator_id
    )

    # 当前没有统一的解密工具，因此全量隐藏电话，不能对密文截取后几位。
    # TODO 接入团队的解密及脱敏工具后，按统一展示规则生成 phone_masked。
    return OperatorDetail(
        operator_id=operator.operator_id,
        operator_name=operator.operator_name,
        credit_code=operator.credit_code,
        contact_name=operator.contact_name,
        status=operator.status,
        created_at=operator.created_at,
        updated_at=operator.updated_at,
        phone_masked="********",
    )

#TODO 新增场站
def create_station(db,*,actor:Actor,request:CreateStationRequest):
    #TODO 判断是否有权限
    # 新增场站：request 是前端提交的数据，先检查运营商，再保存场站。
    if not security.has_permission(actor, 'assets.station.manage'):
        raise PermissionError("该用户没有权限创建场馆")

    #TODO 检查运行商是否存在
    if not dao.get_by_id(db=db,model=Operator,resource_id=request.operator_id):
        raise BusinessError("运营商不存在", status_code=404, code="not_found")
    # 新场站还没有编号，按请求中的所属运营商检查范围。
    security.assert_resource_scope(db, actor, resource_type="operator", resource_id=request.operator_id)
    #TODO 创建场站
    station= Station(
        operator_id=request.operator_id,
        station_name=request.station_name,
        address=request.address,
        longitude=request.longitude,
        latitude=request.latitude,
        parking_spaces=request.parking_spaces,
        business_hours=request.business_hours,
        parking_fee_standard=request.parking_fee_standard,
        status="draft",
    )
    #TODO 尝试在这里面将场站写入数据库中
    try:
        dao.add_station(db=db,station=station)
        db.refresh(station)

        res=StationDetail.model_validate(station)
        #TODO 现在提交
        db.commit()
    except Exception:
        #如果有异常直接回滚 并且抛出异常
        db.rollback()
        raise
    #TODO 返回结果
    return res

#TODO 更新场站
def update_station(db,*,actor: Actor,station_id: int,request: UpdateStationRequest):
    # 临时权限判断，正式接入时调用公共 require_permission
    # 修改已存在的场站；只应用 request 中实际提交的字段。
    if not security.has_permission(actor, "assets.station.manage"):
        raise PermissionError("该用户没有权限修改场站信息")
    # 查询已有场站
    station = dao.get_station_by_id(
        db=db,
        station_id=station_id,
    )
    if station is None:
        raise BusinessError("场站不存在", status_code=404, code="not_found")
    security.assert_resource_scope(db, actor, resource_type="station", resource_id=station_id)

    # 只提取本次实际提交的字段
    changes = request.model_dump(exclude_unset=True)
    if not changes:
        raise ValueError("至少提供一个修改字段")
    # 文档中这些可修改字段均不允许为空
    if any(value is None for value in changes.values()):
        raise ValueError("修改字段不能为 null")
    try:
        # 修改查询得到的对象，会话会跟踪这些变化
        for field, value in changes.items():
            setattr(station, field, value)
        # 将修改发送到数据库
        db.flush()
        # 重新读取数据库生成的更新时间
        db.refresh(station)
        result = StationDetail.model_validate(station)
        db.commit()
    except Exception:
        db.rollback()
        raise
    #TODO 返回结果
    return result

#TODO 在这里实现运营商列表查询
def list_operators(db, *, actor: Actor, query: OperatorQuery):
    #TODO 先判断有没有权限进行查询
    # 查询运营商列表，返回 items、total、page、page_size 四部分。
    if not security.has_permission(actor, 'assets.operator.read'):
        raise PermissionError("该用户没有权限查找运营商")

    # 列表和总数使用相同的授权及筛选条件。
    conditions = [Operator.operator_id.in_(_visible_operators(db, actor))]
    if query.keyword:
        conditions.append(Operator.operator_name.contains(query.keyword, autoescape=True))
    if query.start_at is not None:
        conditions.append(Operator.created_at >= _utc(query.start_at))
    if query.end_at is not None:
        conditions.append(Operator.created_at < _utc(query.end_at))
    rows = db.scalars(select(Operator).where(*conditions).order_by(Operator.operator_id)
        .offset((query.page - 1) * query.page_size).limit(query.page_size)).all()
    items=[]
    #TODO 得到operator，并转换为OperatorDetail
    for operator in rows:
        items.append(OperatorDetail(
            operator_id=operator.operator_id,
            operator_name=operator.operator_name,
            credit_code=operator.credit_code,
            contact_name=operator.contact_name,
            status=operator.status,
            created_at=operator.created_at,
            updated_at=operator.updated_at,
            #TODO 暂时全部隐藏，后续接入统一电话脱敏工具
            phone_masked="********"
        ))

    #TODO 统计符合条件的运营商总数
    total=db.scalar(select(dao.func.count()).select_from(Operator).where(*conditions)) or 0

    return PageResult[OperatorDetail](
        items=items,
        total=total,
        page=query.page,
        page_size=query.page_size,
    )
def _encrypt_operator_phone(phone: str) -> bytes:
    # 文档要求加密存储；Fernet 为本次实现选择，后续与团队统一密钥管理。
    # 把电话明文加密成可存储的密文，避免直接保存明文电话。
    if not settings.phone_encryption_key:
        raise RuntimeError("请先配置 phone_encryption_key 电话加密密钥")
    try:
        cipher = Fernet(settings.phone_encryption_key.encode("ascii"))
    except (ValueError, UnicodeError):
        raise RuntimeError("电话加密密钥格式无效") from None
    encrypted = cipher.encrypt(phone.encode("utf-8"))
    if len(encrypted) > 512:
        raise ValueError("联系电话加密后超出存储长度")
    return encrypted


#TODO 新增运营商
def create_operator(db,*,actor:Actor,request:CreateOperatorRequest) -> OperatorDetail:
    #TODO 判断是否有权限
    # 新增运营商：检查角色、信用代码重复情况，加密电话后保存。
    if 'platform_admin' not in actor.roles:
        # TODO 接入团队统一 BusinessError，对应 403。
        raise PermissionError("该用户没有权限新增运营商")
    try:
        # 信用代码具有唯一约束，先检查，数据库约束还会防止并发重复写入。
        existing = dao.get_by_unique(
            db, Operator, filters={"credit_code":request.credit_code}
        )
        if existing is not None:
            # TODO 接入团队统一 BusinessError，对应 409。
            raise BusinessError("统一社会信用代码已存在", status_code=409, code="conflict")

        operator=Operator(
            operator_name=request.operator_name,
            contact_name=request.contact_name,
            contact_phone_cipher=_encrypt_operator_phone(request.contact_phone),
            credit_code=request.credit_code
        )
        #TODO 添加并且上传给数据库
        dao.add(db,operator)
        dao.flush(db)
        db.refresh(operator)

        result=OperatorDetail(
            operator_id=operator.operator_id,
            operator_name=operator.operator_name,
            credit_code=operator.credit_code,
            contact_name=operator.contact_name,
            status=operator.status,
            created_at=operator.created_at,
            updated_at=operator.updated_at,
            phone_masked="********"
        )
        #TODO 提交事务
        db.commit()
    except IntegrityError as exc:
        db.rollback()
        # MySQL 1062 / SQLite 唯一约束冲突；不将数据库参数或密文暴露给调用者。
        code = getattr(exc.orig, "args", (None,))[0]
        sqlite_code = getattr(exc.orig, "sqlite_errorname", "")
        if code == 1062 or sqlite_code == "SQLITE_CONSTRAINT_UNIQUE":
            raise BusinessError("统一社会信用代码已存在", status_code=409, code="conflict") from None
        raise
    except Exception:
        db.rollback()
        raise
    #TODO 返回结果
    return result

#TODO 这里实现更新运营商
def update_operator(db, *, actor: Actor, operator_id: int, request: UpdateOperatorRequest) -> OperatorDetail:
    #TODO 判断权限
    # 修改运营商档案；电话只有实际提交时才重新加密。
    if 'platform_admin' not in actor.roles:
        raise PermissionError("该用户没有权限更新运营商")

    #TODO 只取本次提交的字段，省略的字段不修改
    changes=request.model_dump(exclude_unset=True)
    #判断有没有内容要修改
    if not changes:
        raise ValueError("至少提供一个修改字段")

    if any(value is None for value in changes.values()):
        raise ValueError("修改字段不能为null")

    try:
        # 加锁查询也属于本次事务；查询或后续处理失败时统一回滚。
        operator=dao.get_by_id(
            db=db,model=Operator,resource_id=operator_id,for_update=True
        )
        if operator is None:
            # TODO 公共异常接入后替换为统一 BusinessError。
            raise BusinessError("运营商不存在", status_code=404, code="not_found")

        #TODO 电话需要加密后再保存，不能直接赋给模型
        if 'contact_phone' in changes:
            phone=changes.pop('contact_phone')
            operator.contact_phone_cipher=_encrypt_operator_phone(phone)

        #TODO 更新名称、联系人或状态
        for field,value in changes.items():
            setattr(operator,field,value)

        dao.flush(db)
        db.refresh(operator)

        #TODO 构建返回数据
        result=OperatorDetail(
            operator_id=operator.operator_id,
            operator_name=operator.operator_name,
            credit_code=operator.credit_code,
            contact_name=operator.contact_name,
            status=operator.status,
            created_at=operator.created_at,
            updated_at=operator.updated_at,
            phone_masked="********"
        )

        db.commit()
    except Exception:
        db.rollback()
        raise
    #返回结果
    return result

#TODO 充电桩列表查询
# TODO 充电桩列表查询
def list_piles(db, *, actor: Actor, query: PileQuery):
    # 查询充电桩列表：权限检查 → 可见场站 → 筛选条件 → 分页 → 响应。
    if not security.has_permission(actor, 'assets.pile.read'):
        raise PermissionError("该用户没有权限访问充电桩")
    # 先确定账号可见范围，再应用筛选、分页和总数统计。
    if query.station_id is not None:
        _device_scope(db, actor, query.station_id)
    # in_ 限制结果只能来自授权场站；关键词中的 or_ 是“序列号或型号匹配”。
    conditions = [ChargingPile.station_id.in_(_visible_stations(db, actor))]
    if query.station_id is not None:
        conditions.append(ChargingPile.station_id == query.station_id)
    if query.status is not None:
        conditions.append(ChargingPile.status == query.status)
    if query.keyword:
        conditions.append(or_(ChargingPile.serial_no.contains(query.keyword, autoescape=True),
                              ChargingPile.model_name.contains(query.keyword, autoescape=True)))
    if query.start_at is not None:
        conditions.append(ChargingPile.created_at >= _utc(query.start_at))
    if query.end_at is not None:
        conditions.append(ChargingPile.created_at < _utc(query.end_at))
    # DAO 同时返回当前页数据库对象和满足条件的总数。
    rows, total = dao._device_page(db, ChargingPile, conditions=conditions,
                                    page=query.page, page_size=query.page_size)
    # 列表推导式逐个转换响应对象；total 是全部匹配条数，不是当前页条数。
    return PageResult[PileDetail](items=[PileDetail.model_validate(p) for p in rows], total=total,
                                  page=query.page, page_size=query.page_size)

#TODO 单个充电桩信息
def get_pile(db, *, actor: Actor, pile_id: int) -> PileDetail:
    # 先做权限判断；权限码仍需与团队统一种子表核对
    # 查看单个桩：既要有查看权限，也要能访问该桩所属场站。
    if not security.has_permission(actor, 'assets.pile.read'):
        raise PermissionError("该用户没有权限访问充电桩")
    # 根据充电桩编号查询数据库模型
    pile = dao.get_pile_by_id(db=db, pile_id=pile_id)
    if pile is None:
        # TODO 接入团队统一 BusinessError 后替换
        raise BusinessError("充电桩不存在", status_code=404, code="not_found")

    # 公共权限模块未实现时，不能跳过所属场站的资源范围检查
    assert_resource_scope = getattr(security, "assert_resource_scope", None)
    if not callable(assert_resource_scope):
        raise NotImplementedError("请先接入公共资源范围检查函数")
    # station 资源类型需与成员4确认，编号传充电桩所属场站编号
    assert_resource_scope(
        db, actor, resource_type="station", resource_id=pile.station_id
    )

    # 将数据库对象转换为详情响应，不提交事务
    return PileDetail.model_validate(pile)

#TODO 新建充电桩
def create_pile(db, *, actor: Actor, request: CreatePileRequest) -> PileDetail:
    # 1. 检查新增权限；具体权限码需要与团队统一种子表确认
    # 新增桩：校验所属场站和序列号，初始设为草稿且离线，之后再验收。
    if not security.has_permission(actor, 'assets.pile.create'):
        raise PermissionError("该用户没有权限创建充电桩")

    try:
        # 2. 检查所属场站是否存在
        station = dao.get_station_by_id(db=db, station_id=request.station_id)
        if station is None:
            raise BusinessError("所属场站不存在", status_code=404, code="not_found")

        # 3. 检查账号能否操作这个场站；公共函数尚未接入时禁止跳过
        assert_resource_scope = getattr(security, "assert_resource_scope", None)
        if not callable(assert_resource_scope):
            raise NotImplementedError("请先接入公共资源范围检查函数")
        # station 资源类型需要与成员4确认
        assert_resource_scope(
            db, actor, resource_type="station", resource_id=request.station_id
        )

        # 4. 检查铭牌序列号是否重复
        existing = dao.get_by_unique(
            db, ChargingPile, filters={"serial_no": request.serial_no}
        )
        if existing is not None:
            raise BusinessError("充电桩序列号已存在", status_code=409, code="conflict")

        # 5. 构建数据库模型；新增设备尚未验收、未上线
        pile = ChargingPile(
            station_id=request.station_id,
            serial_no=request.serial_no,
            model_name=request.model_name,
            rated_power_kw=request.rated_power_kw,
            protocol=request.protocol,
            warranty_until=request.warranty_until,
            lifecycle_status="draft",
            status="offline",
            has_fault=0,
            is_online=0,
        )

        # 6. 加入会话并发送 INSERT；flush 不等于提交事务
        dao.add(db, pile)
        dao.flush(db)
        # 读取数据库生成的主键、创建时间和更新时间
        db.refresh(pile)

        # 7. 先校验响应，成功后才提交，避免响应构建失败却已经写入
        result = PileDetail.model_validate(pile)
        db.commit()
    except IntegrityError as exc:
        db.rollback()
        # 数据库唯一约束兜底，防止并发请求使用相同序列号
        code = getattr(exc.orig, "args", (None,))[0]
        sqlite_code = getattr(exc.orig, "sqlite_errorname", "")
        if code == 1062 or sqlite_code == "SQLITE_CONSTRAINT_UNIQUE":
            raise BusinessError("充电桩序列号已存在", status_code=409, code="conflict") from None
        raise
    except Exception:
        # 查询、权限、写入或提交失败，都回滚本次事务
        db.rollback()
        raise

    # TODO 上面的 ValueError 后续替换为团队统一 BusinessError
    return result

def update_pile(db, *, actor: Actor, pile_id: int, request: UpdatePileRequest) -> PileDetail:
    # 1. 检查修改权限；权限码需要与团队统一种子表确认
    # 修改桩档案：锁定原记录，校验功率，修改成功后提交；失败回滚。
    if not security.has_permission(actor, 'assets.pile.update'):
        raise PermissionError("该用户没有权限修改充电桩")

    try:
        # 2. 查询已有充电桩并加更新锁，防止并发修改相互覆盖
        pile = dao.get_by_id(db, ChargingPile, pile_id, for_update=True)
        if pile is None:
            # TODO 后续替换为团队统一 BusinessError
            raise BusinessError("充电桩不存在", status_code=404, code="not_found")

        # 3. 检查账号是否能操作充电桩所属场站
        assert_resource_scope = getattr(security, "assert_resource_scope", None)
        if not callable(assert_resource_scope):
            raise NotImplementedError("请先接入公共资源范围检查函数")
        # station 资源类型需要与成员4确认
        assert_resource_scope(
            db, actor, resource_type="station", resource_id=pile.station_id
        )

        # 4. 只修改请求实际传入的字段，省略的字段保持原值
        # 不过滤 None：质保日期显式传 null 时需要清空
        changes = request.model_dump(exclude_unset=True)
        if pile.lifecycle_status == "retired":
            raise ValueError("退役设备不能修改档案")
        # 持有桩锁时再锁枪，避免与新增枪并发，导致单枪功率超过整桩功率。
        if "rated_power_kw" in changes:
            if any(g.max_power_kw > changes["rated_power_kw"]
                   for g in _pile_guns(db, pile_id, lock=True)):
                raise ValueError("整桩额定功率不能低于现有单枪最大功率")
        for field, value in changes.items():
            setattr(pile, field, value)

        # 5. 将修改发送到数据库，并读取数据库生成的更新时间
        dao.flush(db)
        db.refresh(pile)

        # 6. 先构建响应并校验，再提交事务
        result = PileDetail.model_validate(pile)
        db.commit()
    except Exception:
        # 查询、权限、写入或提交失败时回滚，释放本次事务的锁
        db.rollback()
        raise

    return result


#TODO 在这里面实现查找充电枪
def list_guns(db, *, actor: Actor, query: GunQuery):
    # 查询枪列表：先通过所属桩确定可见范围，再筛选、分页和计数。
    if not security.has_permission(actor, 'assets.gun.read'):
        raise PermissionError("该用户没有权限访问充电枪")
    if query.station_id is not None:
        _device_scope(db, actor, query.station_id)
    if query.pile_id is not None:
        _, pile = _device_target(db, pile_id=query.pile_id)
        _device_scope(db, actor, pile.station_id)
    # 先构建“授权场站下有哪些桩”的子查询，再用它限制可以返回哪些枪。
    piles = select(ChargingPile.pile_id).where(ChargingPile.station_id.in_(_visible_stations(db, actor)))
    if query.station_id is not None:
        piles = piles.where(ChargingPile.station_id == query.station_id)
    # 只允许返回所属桩在上述子查询中的枪；后续条件与此条件是并且关系。
    conditions = [ChargingGun.pile_id.in_(piles)]
    if query.pile_id is not None:
        conditions.append(ChargingGun.pile_id == query.pile_id)
    if query.status is not None:
        conditions.append(ChargingGun.status == query.status)
    if query.keyword:
        conditions.append(or_(ChargingGun.connector_standard.contains(query.keyword, autoescape=True),
                              ChargingGun.gun_type.contains(query.keyword, autoescape=True)))
    if query.start_at is not None:
        conditions.append(ChargingGun.created_at >= _utc(query.start_at))
    if query.end_at is not None:
        conditions.append(ChargingGun.created_at < _utc(query.end_at))
    rows, total = dao._device_page(db, ChargingGun, conditions=conditions,
                                    page=query.page, page_size=query.page_size)
    return PageResult[GunDetail](items=[GunDetail.model_validate(g) for g in rows], total=total,
                                 page=query.page, page_size=query.page_size)


def get_gun_detail(db, *, actor: Actor, gun_id: int) -> GunDetail:
    # 1. 检查查看权限；权限码需要与团队统一种子表确认
    # HTTP 详情入口：返回完整 GunDetail，区别于跨模块使用的 get_gun 快照。
    if not security.has_permission(actor, 'assets.gun.read'):
        raise PermissionError("该用户没有权限查看充电枪")

    # 2. 复用文档规定的通用 DAO，根据主键查找充电枪
    gun = dao.get_by_id(db, ChargingGun, gun_id)
    if gun is None:
        # TODO 后续替换为团队统一 BusinessError
        raise BusinessError("充电枪不存在", status_code=404, code="not_found")

    # 3. 枪表只有所属桩编号，通过所属桩取得场站编号
    pile = dao.get_by_id(db, ChargingPile, gun.pile_id)
    if pile is None:
        raise BusinessError("所属充电桩不存在", status_code=404, code="not_found")

    # 4. 检查账号对所属场站的访问范围；未接入公共函数时不能跳过
    assert_resource_scope = getattr(security, "assert_resource_scope", None)
    if not callable(assert_resource_scope):
        raise NotImplementedError("请先接入公共资源范围检查函数")
    # station 资源类型需要与成员4确认
    assert_resource_scope(
        db, actor, resource_type="station", resource_id=pile.station_id
    )

    # 5. 转换为详情响应，查询操作不提交或关闭会话
    return GunDetail.model_validate(gun)

#TODO 在这里开始新建充电枪
def create_gun(db, *, actor: Actor, request: CreateGunRequest) -> GunDetail:
    # 1. 检查新增权限；权限码需要与团队统一种子表确认
    # 新增枪：锁住所属桩，检查功率及桩内枪序号，保存后返回详情。
    if not security.has_permission(actor, 'assets.gun.create'):
        raise PermissionError("该用户没有权限新增充电枪")

    try:
        # 2. 查询并锁定所属桩，功率检查与保存放在同一事务中
        pile = dao.get_by_id(db, ChargingPile, request.pile_id, for_update=True)
        if pile is None:
            raise BusinessError("所属充电桩不存在", status_code=404, code="not_found")

        if pile.lifecycle_status == "retired":
            raise ValueError("退役设备不能新增充电枪")

        # 3. 检查账号对所属场站的访问范围，未接入公共函数时禁止跳过
        assert_resource_scope = getattr(security, "assert_resource_scope", None)
        if not callable(assert_resource_scope):
            raise NotImplementedError("请先接入公共资源范围检查函数")
        # station 资源类型需要与成员4确认
        assert_resource_scope(
            db, actor, resource_type="station", resource_id=pile.station_id
        )

        # 4. 单枪最大功率不能超过整桩额定功率，相等时允许新增
        if request.max_power_kw > pile.rated_power_kw:
            raise ValueError("充电枪最大功率不能超过所属充电桩额定功率")

        # 5. 同一桩内枪序号不能重复，不同桩可以使用相同枪序号
        existing = dao.get_by_unique(
            db, ChargingGun,
            filters={"pile_id": request.pile_id, "gun_no": request.gun_no},
        )
        if existing is not None:
            raise BusinessError("该充电桩下的枪序号已存在", status_code=409, code="conflict")

        # 6. 构建数据库对象，新增枪默认离线且没有故障标记
        gun = ChargingGun(
            pile_id=request.pile_id,
            gun_no=request.gun_no,
            gun_type=request.gun_type,
            connector_standard=request.connector_standard,
            max_power_kw=request.max_power_kw,
            status="offline",
            has_fault=0,
        )
        dao.add(db, gun)
        dao.flush(db)
        # 读取自动生成的主键、创建时间和更新时间
        db.refresh(gun)

        # 7. 响应校验通过后再提交事务
        result = GunDetail.model_validate(gun)
        db.commit()
    except IntegrityError as exc:
        db.rollback()
        # 数据库联合唯一约束兜底，防止并发请求创建重复枪序号
        code = getattr(exc.orig, "args", (None,))[0]
        sqlite_code = getattr(exc.orig, "sqlite_errorname", "")
        if code == 1062 or sqlite_code == "SQLITE_CONSTRAINT_UNIQUE":
            raise BusinessError("该充电桩下的枪序号已存在", status_code=409, code="conflict") from None
        raise
    except Exception:
        # 查询、范围检查、写入或提交失败都回滚，释放本次事务的锁
        db.rollback()
        raise

    # TODO ValueError 后续替换为团队统一 BusinessError
    return result


def update_gun(db, *, actor: Actor, gun_id: int, request: UpdateGunRequest) -> GunDetail:
    # 权限码需要与团队统一种子表确认
    # 修改枪档案：始终先锁桩再锁枪，检查退役状态、资源范围和功率。
    if not security.has_permission(actor, 'assets.gun.update'):
        raise PermissionError("该用户没有权限修改充电枪")

    try:
        # 修改数据库已有对象，不新建充电枪；锁在提交或回滚时释放
        gun, pile = _device_target(db, gun_id=gun_id, lock=True)

        if pile.lifecycle_status == "retired":
            raise ValueError("退役设备不能修改充电枪档案")

        # 修改前检查所属场站范围，未接入时禁止跳过
        assert_resource_scope = getattr(security, "assert_resource_scope", None)
        if not callable(assert_resource_scope):
            raise NotImplementedError("请先接入公共资源范围检查函数")
        assert_resource_scope(
            db, actor, resource_type="station", resource_id=pile.station_id
        )

        # 仅更新实际提交的字段，状态与故障事实不属于普通档案修改字段
        changes = request.model_dump(exclude_unset=True)
        power = changes.get("max_power_kw", gun.max_power_kw)
        if power > pile.rated_power_kw:
            raise ValueError("充电枪最大功率不能超过所属充电桩额定功率")
        for field, value in changes.items():
            setattr(gun, field, value)

        dao.flush(db)
        db.refresh(gun)
        result = GunDetail.model_validate(gun)
        db.commit()
    except Exception:
        db.rollback()
        raise

    # TODO ValueError 后续替换为团队统一 BusinessError
    return result

# 设备生命周期与跨模块函数
# 入口拥有事务；内部辅助及跨模块函数不提交事务。
# 权限码仍需与成员4统一种子表核对。
from datetime import datetime, timezone, timedelta
from decimal import Decimal
import hashlib
import secrets
from sqlalchemy import select, or_, and_
from app.shared.contracts import GunSnapshot, DeviceCredentialIssue


def _utc(value):
    """将时间转为数据库使用的无时区 UTC。"""
    # 统一时间的比较方式：带时区时间先换成 UTC，再去掉时区用于数据库比较。
    if value.tzinfo is not None:
        value = value.astimezone(timezone.utc).replace(tzinfo=None)
    return value


def _now():
    # 取得当前 UTC 时间；去掉时区标记以匹配数据库 DATETIME 的存储形式。
    return datetime.now(timezone.utc).replace(tzinfo=None)


def _device_permission(actor, permission, *, roles=()):
    # 检查操作资格：roles 非空时先检查角色，再检查具体权限码。
    # intersection 求两个角色集合的交集；为空表示账号不属于任何允许的角色。
    if roles and not actor.roles.intersection(roles):
        raise PermissionError("当前角色无权执行此设备操作")
    # 本辅助函数允许管理员通过权限码检查；其他账号必须持有指定权限，仍需资源范围校验。
    if not security.has_permission(actor, permission):
        raise PermissionError("缺少权限：" + permission)


def _device_scope(db, actor, station_id):
    # 检查账号能否操作指定场站；有操作权限不代表可以访问所有场站。
    # getattr 尝试从公共安全模块取得函数；未接入时得到 None，不能静默放行。
    check = getattr(security, "assert_resource_scope", None)
    if not callable(check):
        raise NotImplementedError("请先接入公共资源范围检查函数")
    check(db, actor, resource_type="station", resource_id=station_id)


def _visible_stations(db, actor):
    """由公共权限函数确认可见场站，再应用 SQL 范围条件。"""
    # 收集该账号有权访问的场站编号，供列表查询添加 SQL 范围条件。
    if not callable(getattr(security, "assert_resource_scope", None)):
        raise NotImplementedError("请先接入公共资源范围检查函数")
    result = []
    for station_id in db.scalars(select(Station.station_id).order_by(Station.station_id)):
        try:
            _device_scope(db, actor, station_id)
        # 这个场站无权访问就跳过；其他异常继续向外抛，避免把系统错误当成无权限。
        except PermissionError:
            continue
        result.append(station_id)
    return result


def _visible_operators(db, actor):
    # 与场站列表相同，先得到授权编号；不会用分页后过滤的方式漏算记录。
    result = []
    for operator_id in db.scalars(select(Operator.operator_id)):
        try:
            security.assert_resource_scope(db, actor, resource_type="operator", resource_id=operator_id)
        except PermissionError:
            continue
        result.append(operator_id)
    return result


def _device_target(db, *, pile_id=None, gun_id=None, lock=False):
    """涉及桩时先锁桩，再按统一顺序锁枪。"""
    # 统一查找桩或枪；返回 (目标对象, 所属桩)，查桩时两者是同一个对象。
    # 两个编号都不传或同时传都不合法，必须明确操作一个目标。
    if (pile_id is None) == (gun_id is None):
        raise ValueError("桩和枪目标必须二选一")
    if gun_id is not None:
        # 先查枪所属桩编号，才能遵循先桩后枪的加锁顺序，减少并发死锁。
        parent_id = db.scalar(select(ChargingGun.pile_id).where(ChargingGun.gun_id == gun_id))
        if parent_id is None:
            raise BusinessError("充电枪不存在", status_code=404, code="not_found")
        pile = dao.get_by_id(db, ChargingPile, parent_id, for_update=lock)
        if pile is None:
            raise BusinessError("所属充电桩不存在", status_code=404, code="not_found")
        gun = dao.get_by_id(db, ChargingGun, gun_id, for_update=lock)
        # 等待锁期间枪可能被迁移，所以拿到锁后还要再次核对归属。
        if gun is None or gun.pile_id != parent_id:
            raise ValueError("设备归属已变化，请重试整个请求")
        # 调用方用 target 操作目标，用 pile 取得场站编号或检查整桩状态。
        return gun, pile
    pile = dao.get_by_id(db, ChargingPile, pile_id, for_update=lock)
    if pile is None:
        raise BusinessError("充电桩不存在", status_code=404, code="not_found")
    return pile, pile


def _pile_guns(db, pile_id, *, lock=False):
    # 查询指定桩下的全部枪；lock=True 时加行锁，并统一按枪编号加锁。
    stmt = select(ChargingGun).where(ChargingGun.pile_id == pile_id).order_by(ChargingGun.gun_id)
    if lock:
        # FOR UPDATE 会锁住查到的行，直到整个事务提交或回滚。
        stmt = stmt.with_for_update()
    return list(db.scalars(stmt).all())


def _record_status(db, target, new_status, reason, *, occurred_at=None, actor_id=None):
    # 同时修改设备当前状态和新增状态历史；此函数不负责提交事务。
    if new_status not in ("idle", "occupied", "fault", "offline"):
        raise ValueError("设备状态不合法")
    if not reason or len(reason) > 255:
        raise ValueError("状态变更原因必须为1到255字")
    # 状态没有变化时不重复追加历史，避免重试产生相同的状态日志。
    if target.status == new_status:
        return
    # isinstance 判断目标是桩还是枪；历史中只填写对应的一种目标编号。
    log = DeviceStatusLog(
        pile_id=target.pile_id if isinstance(target, ChargingPile) else None,
        gun_id=target.gun_id if isinstance(target, ChargingGun) else None,
        old_status=target.status, new_status=new_status,
        occurred_at=occurred_at or _now(), reason=reason, actor_account_id=actor_id,
    )
    # add 只是把新历史加入会话，随后由上层 flush/commit；当前设备对象也一起修改。
    db.add(log)
    target.status = new_status
    target.updated_at = occurred_at or _now()


def _snapshot(target):
    # 把设备当前档案转换成 JSON 可保存的字典，用于记录申请前的原始信息。
    schema = PileDetail if isinstance(target, ChargingPile) else GunDetail
    # model_validate 从 ORM 对象读取字段；model_dump(mode="json") 转为可存 JSON 的字典。
    return schema.model_validate(target).model_dump(mode="json")


def _archive_fingerprint(target):
    # 快照比较忽略实时状态和心跳；只要档案变化就要求重新申请。
    # 提取参与审批比较的档案字段；实时心跳、状态变化不算档案修改。
    data = _snapshot(target)
    for key in ("status", "has_fault", "is_online", "last_heartbeat_at", "updated_at"):
        # pop 删除不参与比较的字段；字段不存在时返回 None，不报错。
        data.pop(key, None)
    return data


def _assert_no_charging(db, guns):
    # 逐把枪检查充电订单；任何一把正在充电，就禁止设备变更或验收。
    for gun in guns:
        if dao._active_order_id(db, gun.gun_id) is not None:
            raise ValueError("设备存在充电中的订单，不能执行此变更")


def _validate_change(db, target, pile, change_type, proposed, *, actor):
    """校验 JSON 白名单，禁止绕过关联、状态和主键规则。"""
    # 按变更类型检查 proposed 字典，只允许白名单字段；返回校验后的拟修改值。
    if pile.lifecycle_status == "retired":
        raise ValueError("退役设备不能再申请档案变更")
    # 目标可能是桩或枪，接下来选择不同的请求 Schema 和校验规则。
    is_pile = isinstance(target, ChargingPile)
    if change_type in ("archive", "retrofit"):
        schema = UpdatePileRequest if is_pile else UpdateGunRequest
        # 复用 Schema 校验类型、取值范围和额外字段，避免 JSON 任意修改主键或运行状态。
        changes = schema.model_validate(proposed)
        # exclude_unset=True 只保留申请中实际填写的字段，没填写的字段不覆盖原值。
        values = changes.model_dump(exclude_unset=True)
        if is_pile and "rated_power_kw" in values:
            # any 表示只要有一把枪超过新整桩功率，就拒绝这次修改。
            if any(g.max_power_kw > values["rated_power_kw"] for g in _pile_guns(db, pile.pile_id, lock=True)):
                raise ValueError("整桩额定功率不能低于现有单枪最大功率")
        if not is_pile and values.get("max_power_kw", target.max_power_kw) > pile.rated_power_kw:
            raise ValueError("充电枪最大功率不能超过所属桩额定功率")
        # mode="json" 将 Decimal、日期等转为 JSON 可存储值；审批时再还原成对应类型。
        return changes.model_dump(mode="json", exclude_unset=True)
    if change_type == "relocate":
        # 迁移白名单：桩迁场站；枪迁桩并明确枪序号。
        keys = {"station_id"} if is_pile else {"pile_id", "gun_no"}
        # 字段名必须刚好符合迁移白名单，且编号必须是正整数，不能多传或漏传。
        if set(proposed) != keys or any(type(proposed[k]) is not int or proposed[k] <= 0 for k in keys):
            raise ValueError("迁移申请必须提供正整数目标字段：" + ", ".join(sorted(keys)))
        if is_pile:
            station = dao.get_by_id(db, Station, proposed["station_id"])
            if station is None:
                raise BusinessError("目标场站不存在", status_code=404, code="not_found")
            if station.station_id == pile.station_id:
                raise ValueError("目标场站与原场站相同")
            _device_scope(db, actor, station.station_id)
        else:
            if proposed["gun_no"] > 65535:
                raise ValueError("枪序号超出范围")
            destination = dao.get_by_id(db, ChargingPile, proposed["pile_id"])
            if destination is None or destination.lifecycle_status == "retired":
                raise ValueError("目标充电桩不存在或已退役")
            _device_scope(db, actor, destination.station_id)
            if target.max_power_kw > destination.rated_power_kw:
                raise ValueError("充电枪功率超过目标桩额定功率")
            # 目标桩内不能有其他枪占用相同序号；排除目标枪自身，避免误判重复。
            existing = db.scalar(select(ChargingGun.gun_id).where(
                ChargingGun.pile_id == destination.pile_id,
                ChargingGun.gun_no == proposed["gun_no"], ChargingGun.gun_id != target.gun_id))
            if existing is not None:
                raise BusinessError("目标桩内枪序号已存在", status_code=409, code="conflict")
        return dict(proposed)
    if change_type == "retire":
        # 枪表没有退役生命周期，不伪造运行状态。
        if not is_pile:
            raise ValueError("枪没有独立退役状态，请对所属充电桩申请退役")
        if proposed:
            raise ValueError("退役由后端设置生命周期，proposed_data 应为空对象")
        return {}
    raise ValueError("变更类型不合法")


def create_change_request(db, *, actor: Actor, request: CreateChangeRequest) -> ChangeRequestDetail:
    # 运维提交申请，设备档案在审批前保持原样。
    # 运维提交变更申请：检查目标与范围，保存原档案和拟修改内容，等待审批。
    if "maintenance_engineer" not in actor.roles:
        raise PermissionError("只有运维人员可以提交设备变更申请")
    try:
        target, pile = _device_target(db, pile_id=request.pile_id, gun_id=request.gun_id, lock=True)
        # 检查账号是否能访问这个具体场站；与上面的操作权限检查是两件事。
        _device_scope(db, actor, pile.station_id)
        # 先校验拟修改内容，再保存申请；此时不把新值写入设备对象。
        proposed = _validate_change(db, target, pile, request.change_type, request.proposed_data, actor=actor)
        # before_data 存旧档案，proposed_data 存新值；requested_by 必须取当前账号。
        row = EquipmentChangeRequest(
            pile_id=request.pile_id, gun_id=request.gun_id, change_type=request.change_type,
            before_data=_snapshot(target), proposed_data=proposed, reason=request.reason,
            requested_by=actor.account_id, status="pending",
        )
        # 把新记录加入会话；此时尚未提交，后续出错仍能整体撤销。
        db.add(row)
        # 把会话内待保存的修改发给数据库，以便后续查询及取得主键；flush 不等于 commit。
        db.flush()
        # 重新读取数据库生成的编号、创建时间等默认字段。
        db.refresh(row)
        result = ChangeRequestDetail.model_validate(row)
        # 前面的校验及响应构建已成功，提交整个事务，使修改生效并释放锁。
        db.commit()
        return result
    except Exception:
        # 撤销本次事务中尚未提交的全部修改并释放锁；后面的 raise 将异常继续交给上层。
        db.rollback()
        raise


def get_change_request(db, *, actor: Actor, request_id: int) -> ChangeRequestDetail:
    # 按申请编号查询详情，检查目标设备所属场站范围后返回响应模型。
    _device_permission(actor, "assets.change_request.read", roles=("platform_admin", "maintenance_engineer"))
    row = dao.get_by_id(db, EquipmentChangeRequest, request_id)
    if row is None:
        raise BusinessError("设备变更申请不存在", status_code=404, code="not_found")
    _, pile = _device_target(db, pile_id=row.pile_id, gun_id=row.gun_id)
    # 检查账号是否能访问这个具体场站；与上面的操作权限检查是两件事。
    _device_scope(db, actor, pile.station_id)
    # 把数据库记录转为响应 Schema，供 Router 返回；查询函数不自行提交事务。
    return ChangeRequestDetail.model_validate(row)


def _target_scope_condition(model, allowed):
    # 生成资源范围 SQL 条件：通过场站找到桩，再通过桩找到枪。
    # 这是子查询，此处只构建语句；主查询执行时由数据库查出授权场站下的桩。
    piles = select(ChargingPile.pile_id).where(ChargingPile.station_id.in_(allowed))
    guns = select(ChargingGun.gun_id).where(ChargingGun.pile_id.in_(piles))
    if model in (EquipmentChangeRequest, DeviceStatusLog):
        # 桩申请/日志或枪申请/日志都可能存在，满足任一授权目标即可。
        return or_(model.pile_id.in_(piles), model.gun_id.in_(guns))
    return model.pile_id.in_(piles)


def _query_devices(db, actor, query, model, detail, *, time_field, keyword_field):
    # 范围和筛选条件先应用，再执行分页与总数统计。
    # 通用设备分页入口：model 是数据库模型，detail 是对应的响应 Schema。
    conditions = [_target_scope_condition(model, _visible_stations(db, actor))]
    # 复用不同 Query：getattr 默认 None，当前 Query 没有该字段时就不添加该条件。
    for name in ("pile_id", "gun_id", "order_id", "status"):
        value = getattr(query, name, None)
        if value is not None:
            # 按字符串字段名取得模型列，例如 getattr(model, "pile_id")，再添加等值条件。
            conditions.append(getattr(model, name) == value)
    if query.keyword:
        conditions.append(keyword_field.contains(query.keyword, autoescape=True))
    if query.start_at is not None:
        conditions.append(time_field >= _utc(query.start_at))
    if query.end_at is not None:
        conditions.append(time_field < _utc(query.end_at))
    # 同一组 conditions 同时用于列表和总数，先限制范围再分页，避免返回越权记录。
    rows, total = dao._device_page(db, model, conditions=conditions, page=query.page, page_size=query.page_size)
    # 逐条把 ORM 对象转为 detail，连同总数和页码一起返回给 Router。
    return PageResult[detail](items=[detail.model_validate(r) for r in rows], total=total,
                              page=query.page, page_size=query.page_size)


def list_change_requests(db, *, actor: Actor, query: ChangeRequestQuery) -> PageResult[ChangeRequestDetail]:
    # 查询变更申请列表；关键词匹配申请理由，时间过滤使用申请创建时间。
    _device_permission(actor, "assets.change_request.read", roles=("platform_admin", "maintenance_engineer"))
    return _query_devices(db, actor, query, EquipmentChangeRequest, ChangeRequestDetail,
                          time_field=EquipmentChangeRequest.created_at, keyword_field=EquipmentChangeRequest.reason)


def review_change_request(db, *, actor: Actor, request_id: int, request: ReviewChangeRequest) -> ChangeRequestDetail:
    # 审批申请：禁止自批和重复审批；批准时校验快照，再让档案变更生效。
    if "platform_admin" not in actor.roles:
        raise PermissionError("只有平台管理员可以审批")
    try:
        # 先取得目标，按设备顺序加锁后重新锁定并检查申请。
        row = dao.get_by_id(db, EquipmentChangeRequest, request_id)
        if row is None:
            raise BusinessError("设备变更申请不存在", status_code=404, code="not_found")
        # 迁枪会同时涉及两个桩：先按编号锁定全部桩，再锁枪，避免反向迁移死锁。
        source_id = row.pile_id
        if source_id is None:
            source_id = db.scalar(select(ChargingGun.pile_id).where(ChargingGun.gun_id == row.gun_id))
        # 用集合收集涉及的桩编号，自动去重；枪迁移可能同时涉及源桩和目标桩。
        affected_ids = {source_id} if source_id is not None else set()
        if row.change_type == "relocate" and row.gun_id is not None:
            destination_id = row.proposed_data.get("pile_id")
            if type(destination_id) is int:
                affected_ids.add(destination_id)
        # 两个相反方向的迁移也按照相同的编号顺序锁桩，避免彼此交叉等待。
        for affected_id in sorted(affected_ids):
            dao.get_by_id(db, ChargingPile, affected_id, for_update=True)
        target, pile = _device_target(db, pile_id=row.pile_id, gun_id=row.gun_id, lock=True)
        # 重新读取并锁住申请，防止两个管理员同时把同一申请审批生效。
        db.refresh(row, with_for_update=True)
        if row.status != "pending":
            raise ValueError("申请已经审批，不能重复审批")
        if row.requested_by == actor.account_id:
            raise PermissionError("申请人不能审批自己的申请")
        # 检查账号是否能访问这个具体场站；与上面的操作权限检查是两件事。
        _device_scope(db, actor, pile.station_id)
        if request.decision == "approved":
            # 比较当前档案和申请时的旧档案，避免用旧申请覆盖别人后来修改的信息。
            current = _archive_fingerprint(target)
            # 字典推导式：仅保留需要参与档案比较的字段，忽略实时状态字段。
            previous = {k: v for k, v in row.before_data.items() if k in current}
            if current != previous:
                raise ValueError("设备档案在申请后发生变化，请重新申请")
            values = _validate_change(db, target, pile, row.change_type, row.proposed_data, actor=actor)
            guns = []
            # 两个相反方向的迁移也按照相同的编号顺序锁桩，避免彼此交叉等待。
            for affected_id in sorted(affected_ids):
                guns.extend(_pile_guns(db, affected_id, lock=True))
            # 有充电中订单时不允许变更生效。
            _assert_no_charging(db, guns)
            if row.change_type in ("archive", "retrofit"):
                schema = UpdatePileRequest if isinstance(target, ChargingPile) else UpdateGunRequest
                # 把保存于 JSON 的功率字符串、日期字符串等，转换回模型字段需要的 Python 类型。
                values = schema.model_validate(values).model_dump(exclude_unset=True)
            # 遍历白名单字段；setattr(target, field, value) 相当于动态执行 target.字段 = 新值。
            for field, value in values.items():
                setattr(target, field, value)
            # 让迁移后的归属参与随后对目标桩的查询；仍未提交，失败统一回滚。
            # 把会话内待保存的修改发给数据库，以便后续查询及取得主键；flush 不等于 commit。
            db.flush()
            if row.change_type == "retire":
                pile.lifecycle_status = "retired"
                pile.is_online = 0
            elif row.change_type in ("retrofit", "relocate"):
                # 迁移或改造后必须重新验收，不直接上线。
                pile.lifecycle_status = "pending_acceptance"
                if isinstance(target, ChargingGun) and row.change_type == "relocate":
                    destination = dao.get_by_id(db, ChargingPile, target.pile_id, for_update=True)
                    destination.lifecycle_status = "pending_acceptance"
                    destination.is_online = 0
                    for destination_gun in _pile_guns(db, destination.pile_id, lock=True):
                        _record_status(db, destination_gun, "offline", "设备迁移待重新验收", actor_id=actor.account_id)
                    _record_status(db, destination, "offline", "设备迁移待重新验收", actor_id=actor.account_id)
                pile.is_online = 0
            if row.change_type != "archive":
                _record_status(db, pile, "offline", "设备变更审批生效", actor_id=actor.account_id)
                for gun in _pile_guns(db, pile.pile_id, lock=True):
                    _record_status(db, gun, "offline", "设备变更审批生效", actor_id=actor.account_id)
            target.updated_at = _now()
        # 无论批准还是驳回，都记录审批结果；只有 approved 分支会修改设备档案。
        row.status = request.decision
        row.reviewed_by = actor.account_id
        row.reviewed_at = _now()
        row.review_note = request.note
        row.updated_at = _now()
        # 把会话内待保存的修改发给数据库，以便后续查询及取得主键；flush 不等于 commit。
        db.flush()
        # 重新读取数据库生成的编号、创建时间等默认字段。
        db.refresh(row)
        result = ChangeRequestDetail.model_validate(row)
        # 前面的校验及响应构建已成功，提交整个事务，使修改生效并释放锁。
        db.commit()
        return result
    except Exception:
        # 撤销本次事务中尚未提交的全部修改并释放锁；后面的 raise 将异常继续交给上层。
        db.rollback()
        raise


# 验收、状态历史、命令和凭据入口
def list_acceptances(db, *, actor: Actor, query: AcceptanceQuery) -> PageResult[AcceptanceDetail]:
    # 查询验收历史列表；关键词匹配验收备注，时间过滤使用实际验收时间。
    _device_permission(actor, "assets.acceptance.read", roles=("platform_admin", "maintenance_engineer"))
    return _query_devices(db, actor, query, DeviceAcceptance, AcceptanceDetail,
                          time_field=DeviceAcceptance.accepted_at, keyword_field=DeviceAcceptance.note)


def get_acceptance(db, *, actor: Actor, acceptance_id: int) -> AcceptanceDetail:
    # 按验收编号查一条记录；确认可以访问所属桩后返回验收详情。
    _device_permission(actor, "assets.acceptance.read", roles=("platform_admin", "maintenance_engineer"))
    row = dao.get_by_id(db, DeviceAcceptance, acceptance_id)
    if row is None:
        raise BusinessError("验收记录不存在", status_code=404, code="not_found")
    _, pile = _device_target(db, pile_id=row.pile_id)
    # 检查账号是否能访问这个具体场站；与上面的操作权限检查是两件事。
    _device_scope(db, actor, pile.station_id)
    # 把数据库记录转为响应 Schema，供 Router 返回；查询函数不自行提交事务。
    return AcceptanceDetail.model_validate(row)


def create_acceptance(db, *, actor: Actor, request: CreateAcceptanceRequest) -> AcceptanceDetail:
    # 新增一次验收记录：四项全部通过才能投运；每次验收新增记录，保留历史。
    _device_permission(actor, "assets.acceptance.create", roles=("platform_admin", "maintenance_engineer"))
    try:
        pile, _ = _device_target(db, pile_id=request.pile_id, lock=True)
        # 检查账号是否能访问这个具体场站；与上面的操作权限检查是两件事。
        _device_scope(db, actor, pile.station_id)
        if pile.lifecycle_status not in ("draft", "pending_acceptance"):
            raise ValueError("仅草稿或待验收设备可以验收")
        guns = _pile_guns(db, pile.pile_id, lock=True)
        _assert_no_charging(db, guns)
        tests = (request.protocol_test_passed, request.nameplate_checked,
                 request.start_stop_passed, request.heartbeat_passed)
        # all 要求四项都为 True；最终结论由后端计算，前端不能直接传 passed。
        passed = all(tests)
        if passed and not guns:
            raise ValueError("没有配置充电枪，不能投运")
        if any(g.max_power_kw > pile.rated_power_kw for g in guns):
            raise ValueError("存在功率超过整桩额定功率的充电枪")
        now = _now()
        # 验收记录只追加，结论、账号与时间由后端计算。
        # ** 将请求字典展开为构造参数，例如 pile_id=...、heartbeat_passed=...。
        row = DeviceAcceptance(**request.model_dump(), result="passed" if passed else "failed",
                               accepted_by=actor.account_id, accepted_at=now)
        # 把新记录加入会话；此时尚未提交，后续出错仍能整体撤销。
        db.add(row)
        # 通过才进入 active；失败仍待验收。这里的生命周期不同于 idle/offline 运行状态。
        pile.lifecycle_status = "active" if passed else "pending_acceptance"
        # 首次通过时记录投运日期；之后重新验收不覆盖首次投运日期。
        if passed and pile.commissioned_on is None:
            pile.commissioned_on = now.date()
        pile.updated_at = now
        # 通过验收不等于通信正常，不强制设备变为 idle。
        # 把会话内待保存的修改发给数据库，以便后续查询及取得主键；flush 不等于 commit。
        db.flush()
        # 重新读取数据库生成的编号、创建时间等默认字段。
        db.refresh(row)
        result = AcceptanceDetail.model_validate(row)
        # 前面的校验及响应构建已成功，提交整个事务，使修改生效并释放锁。
        db.commit()
        return result
    except Exception:
        # 撤销本次事务中尚未提交的全部修改并释放锁；后面的 raise 将异常继续交给上层。
        db.rollback()
        raise


def list_device_commands(db, *, actor: Actor, query: DeviceCommandQuery) -> PageResult[DeviceCommandDetail]:
    # 查询命令列表；只读取命令记录，不会在这里发送或重发命令。
    _device_permission(actor, "assets.device_command.read", roles=("platform_admin", "maintenance_engineer"))
    return _query_devices(db, actor, query, DeviceCommand, DeviceCommandDetail,
                          time_field=DeviceCommand.created_at, keyword_field=DeviceCommand.command_type)


def get_device_command(db, *, actor: Actor, command_id: int) -> DeviceCommandDetail:
    # 按命令编号查详情，并检查该命令对应桩的场站访问范围。
    _device_permission(actor, "assets.device_command.read", roles=("platform_admin", "maintenance_engineer"))
    row = dao.get_by_id(db, DeviceCommand, command_id)
    if row is None:
        raise BusinessError("设备命令不存在", status_code=404, code="not_found")
    _, pile = _device_target(db, pile_id=row.pile_id)
    # 检查账号是否能访问这个具体场站；与上面的操作权限检查是两件事。
    _device_scope(db, actor, pile.station_id)
    # 把数据库记录转为响应 Schema，供 Router 返回；查询函数不自行提交事务。
    return DeviceCommandDetail.model_validate(row)


def list_device_status_logs(db, *, actor: Actor, query: DeviceStatusLogQuery) -> PageResult[DeviceStatusLogDetail]:
    # 查询状态变化历史；关键词匹配变化原因，时间过滤使用实际变化时间。
    _device_permission(actor, "assets.status_log.read", roles=("platform_admin", "maintenance_engineer"))
    return _query_devices(db, actor, query, DeviceStatusLog, DeviceStatusLogDetail,
                          time_field=DeviceStatusLog.occurred_at, keyword_field=DeviceStatusLog.reason)


def get_device_status_log(db, *, actor: Actor, status_log_id: int) -> DeviceStatusLogDetail:
    # 按历史编号查记录；根据目标桩或枪确定场站，再检查访问范围。
    _device_permission(actor, "assets.status_log.read", roles=("platform_admin", "maintenance_engineer"))
    row = dao.get_by_id(db, DeviceStatusLog, status_log_id)
    if row is None:
        raise BusinessError("设备状态记录不存在", status_code=404, code="not_found")
    _, pile = _device_target(db, pile_id=row.pile_id, gun_id=row.gun_id)
    # 检查账号是否能访问这个具体场站；与上面的操作权限检查是两件事。
    _device_scope(db, actor, pile.station_id)
    # 把数据库记录转为响应 Schema，供 Router 返回；查询函数不自行提交事务。
    return DeviceStatusLogDetail.model_validate(row)


def issue_device_credential(db, *, actor: Actor, pile_id: int,
                            request: IssueDeviceCredentialRequest) -> DeviceCredentialIssue:
    # 管理员签发设备密钥：检查过期时间，随机生成原文，只保存摘要。
    if "platform_admin" not in actor.roles:
        raise PermissionError("只有管理员可以签发设备凭据")
    try:
        pile, _ = _device_target(db, pile_id=pile_id, lock=True)
        # 检查账号是否能访问这个具体场站；与上面的操作权限检查是两件事。
        _device_scope(db, actor, pile.station_id)
        now = _now()
        # 请求虽然已被 Schema 校验，但保存前再次检查，避免处理期间已经到期。
        expiry = _utc(request.expires_at)
        if expiry <= now:
            raise ValueError("凭据到期时间必须晚于当前时刻")
        if pile.lifecycle_status == "retired":
            raise ValueError("不能向退役设备签发凭据")
        # 生成安全随机令牌原文；32 是随机字节数，不是最终字符串长度。
        token = secrets.token_urlsafe(32)
        # 只保存 SHA-256 摘要，令牌不记录日志、不写 Outbox。
        # encode 将字符串转字节；sha256 计算不可逆摘要；digest 返回数据库保存的二进制值。
        row = DeviceCredential(pile_id=pile_id, token_hash=hashlib.sha256(token.encode()).digest(),
                               expires_at=expiry)
        # 把新记录加入会话；此时尚未提交，后续出错仍能整体撤销。
        db.add(row)
        # 把会话内待保存的修改发给数据库，以便后续查询及取得主键；flush 不等于 commit。
        db.flush()
        # 原文只放进本次返回的只读 DTO，不放到数据库；HTTP Router 负责响应格式转换。
        result = DeviceCredentialIssue(credential_id=row.credential_id, pile_id=pile_id,
                                      secret_token=token, expires_at=expiry)
        # 前面的校验及响应构建已成功，提交整个事务，使修改生效并释放锁。
        db.commit()
        return result
    except Exception:
        # 撤销本次事务中尚未提交的全部修改并释放锁；后面的 raise 将异常继续交给上层。
        db.rollback()
        raise


# 跨模块辅助函数：调用方先鉴权并管理事务，以下函数不提交
def _gun_snapshot(db, gun, pile):
    # 组合只读枪快照；当前订单编号来自订单表，不是枪表中的存储字段。
    return GunSnapshot(gun_id=gun.gun_id, pile_id=gun.pile_id, status=gun.status,
                       station_id=pile.station_id, active_order_id=dao._active_order_id(db, gun.gun_id))


def get_gun(db, gun_id: int) -> GunSnapshot:
    # 供其他业务读取枪快照；不提交事务，调用方负责鉴权。
    gun, pile = _device_target(db, gun_id=gun_id)
    return _gun_snapshot(db, gun, pile)


def lock_gun(db, gun_id: int) -> GunSnapshot:
    # 供订单等业务锁定桩和枪，再返回快照；锁到调用方提交或回滚时才释放。
    gun, pile = _device_target(db, gun_id=gun_id, lock=True)
    return _gun_snapshot(db, gun, pile)


def change_gun_status(db, gun_id: int, *, expected_status: str, new_status: str, reason: str) -> GunSnapshot:
    # 先核对 expected_status，再按新状态校验；禁止直接跳过离线和故障恢复复核。
    gun, pile = _device_target(db, gun_id=gun_id, lock=True)
    # expected_status 是调用方预期的旧状态；不一致说明状态已变化，必须重新判断。
    if gun.status != expected_status:
        raise ValueError("充电枪状态已变化")
    # 确认实际订单归属后再判断能否设为空闲或占用，不能只看枪表的状态字符串。
    active = dao._active_order_id(db, gun_id)
    if new_status == "occupied":
        if active is None or gun.has_fault or pile.has_fault or not pile.is_online or pile.lifecycle_status != "active":
            raise ValueError("没有有效归属订单或设备不可用，不能设为占用")
        if gun.status in ("fault", "offline"):
            raise ValueError("故障或离线恢复必须经过恢复复核函数")
    if new_status == "idle":
        if active is not None or gun.has_fault or pile.has_fault or not pile.is_online or pile.lifecycle_status != "active":
            raise ValueError("占用、故障、离线或未投运设备不能设为空闲")
        if gun.status in ("fault", "offline"):
            raise ValueError("故障或离线恢复必须经过恢复复核函数")
    if new_status == "fault":
        gun.has_fault = 1
    _record_status(db, gun, new_status, reason)
    # 把会话内待保存的修改发给数据库，以便后续查询及取得主键；flush 不等于 commit。
    db.flush()
    return _gun_snapshot(db, gun, pile)


def claim_gun_for_order(db, *, gun_id: int, order_id: int) -> GunSnapshot:
    # 调用方先锁枪并写入订单，此处验证唯一充电订单归属。
    # 为当前充电订单占枪；核对订单与枪的归属，并保证枪当前可以使用。
    gun, pile = _device_target(db, gun_id=gun_id, lock=True)
    # 把会话内待保存的修改发给数据库，以便后续查询及取得主键；flush 不等于 commit。
    db.flush()
    active = dao._active_order_id(db, gun_id)
    order = dao._order_for_gun(db, order_id, gun_id)
    if order is None or order["status"] != "charging" or active != order_id:
        raise ValueError("订单不存在、归属不符或不是当前充电订单")
    # 同一订单重复调用时返回当前快照，不重复占枪；这叫幂等处理。
    if gun.status == "occupied" and active == order_id:
        return _gun_snapshot(db, gun, pile)
    if gun.status != "idle" or gun.has_fault or pile.has_fault or not pile.is_online or pile.lifecycle_status != "active":
        raise ValueError("充电枪当前不可用于充电")
    _record_status(db, gun, "occupied", "订单开始充电")
    # 把会话内待保存的修改发给数据库，以便后续查询及取得主键；flush 不等于 commit。
    db.flush()
    return _gun_snapshot(db, gun, pile)


def release_gun_for_order(db, *, gun_id: int, order_id: int, reason: str) -> GunSnapshot:
    # 释放已结束订单使用的枪；不允许仍在充电时释放，也不能清除故障或离线。
    gun, pile = _device_target(db, gun_id=gun_id, lock=True)
    # 把会话内待保存的修改发给数据库，以便后续查询及取得主键；flush 不等于 commit。
    db.flush()
    order = dao._order_for_gun(db, order_id, gun_id)
    if order is None:
        raise ValueError("订单不属于这把充电枪")
    active = dao._active_order_id(db, gun_id)
    if active is not None:
        raise ValueError("仍存在充电中的订单，不能释放充电枪")
    # 订单结束不清除离线或故障事实。
    # 按优先顺序判断：离线优先，其次故障，全部正常才回到 idle。
    new_status = ("offline" if gun.status == "offline" or not pile.is_online or pile.lifecycle_status != "active"
                  else "fault" if gun.has_fault or pile.has_fault or gun.status == "fault" else "idle")
    _record_status(db, gun, new_status, reason)
    # 把会话内待保存的修改发给数据库，以便后续查询及取得主键；flush 不等于 commit。
    db.flush()
    return _gun_snapshot(db, gun, pile)


def _heartbeat_timeout(db):
    # 超时阈值读取启用的心跳规则，不硬编码秒数。
    # 从启用的心跳告警规则读取超时秒数；多条规则时取最小阈值。
    values = list(db.scalars(select(dao._rules.c.threshold_value).where(
        dao._rules.c.enabled == 1, dao._rules.c.metric == "heartbeat")))
    if not values or min(Decimal(str(v)) for v in values) <= 0:
        raise ValueError("尚未配置有效的心跳超时规则")
    return float(min(Decimal(str(v)) for v in values))


def mark_pile_offline(db, *, pile_id: int, detected_at: datetime, reason: str) -> None:
    # 检测任务调用：持锁重新检查是否真的超时，再把整桩及其枪设为离线。
    pile, _ = _device_target(db, pile_id=pile_id, lock=True)
    detected = _utc(detected_at)
    timeout = _heartbeat_timeout(db)
    # 持锁重新检查，避免旧检测任务覆盖新心跳。
    if pile.last_heartbeat_at is not None:
        last = _utc(pile.last_heartbeat_at)
        # 检测时间比新心跳还早，或距心跳不足阈值，说明这次检测不能判定离线。
        if detected <= last or (detected - last).total_seconds() < timeout:
            return
    # 从未收到心跳的设备，从创建时间起计算超时，避免新增后立即误判。
    elif (detected - _utc(pile.created_at)).total_seconds() < timeout:
        return
    pile.is_online = 0
    _record_status(db, pile, "offline", reason, occurred_at=detected)
    for gun in _pile_guns(db, pile_id, lock=True):
        _record_status(db, gun, "offline", reason, occurred_at=detected)
    # 不清除充电订单，也不清除故障标记。
    # 把会话内待保存的修改发给数据库，以便后续查询及取得主键；flush 不等于 commit。
    db.flush()


def touch_pile_heartbeat(db, *, pile_id: int, received_at: datetime) -> None:
    # 收到有效心跳后更新通信事实；忽略旧心跳，不直接恢复空闲状态。
    pile, _ = _device_target(db, pile_id=pile_id, lock=True)
    received = _utc(received_at)
    if pile.last_heartbeat_at is not None and received <= _utc(pile.last_heartbeat_at):
        return
    if pile.lifecycle_status == "retired":
        raise ValueError("退役设备不能恢复通信在线状态")
    pile.last_heartbeat_at = received
    pile.is_online = 1
    # 心跳只更新通信事实，恢复运行状态需要另行复核。
    pile.updated_at = received
    # 把会话内待保存的修改发给数据库，以便后续查询及取得主键；flush 不等于 commit。
    db.flush()


def recover_pile_status(db, *, pile_id: int, verified_at: datetime) -> None:
    # 恢复复核：在线且心跳正常 → 采样持续正常 → 告警恢复且工单闭环 → 恢复状态。
    pile, _ = _device_target(db, pile_id=pile_id, lock=True)
    # 恢复可能修改整桩和所有枪，所以先持有相关锁，再统一判断和修改。
    guns = _pile_guns(db, pile_id, lock=True)
    verified = _utc(verified_at)
    if pile.lifecycle_status != "active" or not pile.is_online or pile.last_heartbeat_at is None:
        raise ValueError("设备未投运或通信未恢复")
    timeout = _heartbeat_timeout(db)
    if not 0 <= (verified - _utc(pile.last_heartbeat_at)).total_seconds() < timeout:
        raise ValueError("心跳已超时，不能恢复")
    # 近期有效采样是故障恢复的必要条件。
    # 按采样时间倒序只取最新一条；mappings() 让返回值可以按字段名读取。
    reading = db.execute(select(dao._readings).where(dao._readings.c.pile_id == pile_id)
                         .order_by(dao._readings.c.sampled_at.desc()).limit(1)).mappings().one_or_none()
    if reading is None or not 0 <= (verified - _utc(_parse_db_time(reading["sampled_at"]))).total_seconds() < timeout:
        raise ValueError("缺少近期正常采样")
    # 读取当前启用的规则，后续依规则检查温度和故障码，不把阈值写死在代码中。
    rules = list(db.execute(select(dao._rules).where(dao._rules.c.enabled == 1)).mappings())
    for rule in rules:
        if rule["metric"] == "temperature" and (reading["module_temperature_c"] is None or Decimal(str(reading["module_temperature_c"])) >= Decimal(str(rule["threshold_value"]))):
            raise ValueError("温度采样未恢复正常")
        if rule["metric"] == "fault_code" and reading["fault_code"] == rule["fault_code"]:
            raise ValueError("故障码仍然存在")
    if reading["offline_seconds"] is None or float(reading["offline_seconds"]) >= timeout:
        raise ValueError("采样显示通信仍异常")
    # 外连接保留规则缺失的告警；规则不存在时不能直接假定告警已满足恢复条件。
    alerts = list(db.execute(select(dao._alerts, dao._rules.c.recovery_seconds)
                            .outerjoin(dao._rules, dao._rules.c.alarm_rule_id == dao._alerts.c.alarm_rule_id)
                            .where(dao._alerts.c.pile_id == pile_id)).mappings())
    for alert in alerts:
        # 告警必须复核恢复，连续正常时间足够且工单全部闭环。
        normal_since = alert["normal_since_at"]
        if (alert["status"] != "recovered" or normal_since is None or alert["recovered_at"] is None
                or alert["recovery_seconds"] is None):
            raise ValueError("仍存在未恢复或未复核的告警")
        if (verified - _utc(_parse_db_time(normal_since))).total_seconds() < alert["recovery_seconds"]:
            raise ValueError("连续正常观察时间不足")
        # 查出该告警关联的全部工单状态；只修好但未 closed 的工单仍不算闭环。
        work = list(db.execute(select(dao._work_orders.c.status).where(
            dao._work_orders.c.alert_id == alert["alert_id"])).scalars())
        if not work or any(status != "closed" for status in work):
            raise ValueError("告警关联工单尚未全部闭环")
    if (pile.has_fault or any(g.has_fault for g in guns)) and not alerts:
        raise ValueError("有故障事实但缺少告警复核记录，不能清除故障")
    # 恢复窗口内必须持续有正常采样，单条心跳或单条正常采样不能证明持续正常。
    # 采用规则中最长的恢复观察秒数，确保整桩恢复满足所有启用规则。
    window = max((int(rule["recovery_seconds"]) for rule in rules), default=0)
    readings = list(db.execute(select(dao._readings).where(
        dao._readings.c.pile_id == pile_id).order_by(dao._readings.c.sampled_at)).mappings())
    # 从复核时刻往前推观察时长；例如复核 12:00、窗口 30 秒，起点为 11:59:30。
    cutoff = verified - timedelta(seconds=window)
    # 找出窗口起点及之前的采样，才能证明从窗口开始就有正常数据。
    before = [r for r in readings if _utc(_parse_db_time(r["sampled_at"])) <= cutoff]
    if window and not before:
        raise ValueError("连续正常观察时间不足，缺少窗口起点采样")
    start = _utc(_parse_db_time(before[-1]["sampled_at"])) if before else cutoff
    # 新发生的离线/故障不能用发生之前的采样直接恢复。
    # 查整桩或任意枪最近一次进入离线/故障的时间，不能拿异常发生前的数据证明已恢复。
    last_bad = db.scalar(select(DeviceStatusLog.occurred_at).where(
        or_(DeviceStatusLog.pile_id == pile_id,
            DeviceStatusLog.gun_id.in_([g.gun_id for g in guns])),
        DeviceStatusLog.new_status.in_(("offline", "fault")))
        .order_by(DeviceStatusLog.occurred_at.desc()).limit(1))
    if last_bad is not None and start < _utc(last_bad):
        raise ValueError("最新离线或故障后尚未完成连续正常观察")
    # 只检查从选定起点到本次复核时刻的采样；后续还要逐条核对采样间隔和指标。
    samples = [r for r in readings if start <= _utc(_parse_db_time(r["sampled_at"])) <= verified]
    # 记住上一条采样时间，用来发现观察期间是否长时间没有数据。
    previous = start
    for sample in samples:
        sampled = _utc(_parse_db_time(sample["sampled_at"]))
        if (sampled - previous).total_seconds() >= timeout:
            raise ValueError("正常观察期间采样中断")
        if sample["offline_seconds"] is None or float(sample["offline_seconds"]) >= timeout:
            raise ValueError("正常观察期间存在离线采样")
        for rule in rules:
            if rule["metric"] == "temperature" and (sample["module_temperature_c"] is None or
                    Decimal(str(sample["module_temperature_c"])) >= Decimal(str(rule["threshold_value"]))):
                raise ValueError("正常观察期间存在温度异常")
            if rule["metric"] == "fault_code" and sample["fault_code"] == rule["fault_code"]:
                raise ValueError("正常观察期间存在故障码")
        previous = sampled
    if (verified - previous).total_seconds() >= timeout:
        raise ValueError("正常观察期间采样中断")
    # 所有检查都通过后才清除故障事实；前面的任何失败都不会执行到这里。
    pile.has_fault = 0
    occupied = False
    for gun in guns:
        gun.has_fault = 0
        # 订单仍在充电时恢复为 occupied，否则恢复为 idle，不误释放订单占用。
        status = "occupied" if dao._active_order_id(db, gun.gun_id) is not None else "idle"
        # 累积判断：只要有一把枪被占用，整桩状态就显示 occupied。
        occupied |= status == "occupied"
        _record_status(db, gun, status, "通信及故障恢复复核通过", occurred_at=verified)
    _record_status(db, pile, "occupied" if occupied else "idle", "通信及故障恢复复核通过", occurred_at=verified)
    # 把会话内待保存的修改发给数据库，以便后续查询及取得主键；flush 不等于 commit。
    db.flush()


def _parse_db_time(value):
    # 跨模块 Core 查询在 SQLite 返回字符串，MySQL 返回 datetime。
    # 兼容查询结果：时间已经是 datetime 就原样返回，字符串则解析为 datetime。
    return datetime.fromisoformat(value) if isinstance(value, str) else value


def enqueue_device_command(db, *, gun_id: int, order_id: int, command_type: str) -> int:
    # 校验订单归属后，把命令和 Outbox 事件一起入库，实际网络发送留给后台任务。
    if command_type not in ("start", "stop"):
        raise ValueError("仅支持 start 或 stop 命令")
    gun, pile = _device_target(db, gun_id=gun_id, lock=True)
    # 把会话内待保存的修改发给数据库，以便后续查询及取得主键；flush 不等于 commit。
    db.flush()
    order = dao._order_for_gun(db, order_id, gun_id)
    if order is None:
        raise ValueError("命令订单与充电枪归属不符")
    # 相同订单和相同命令类型使用同一业务键；重试时先查已有命令，不重复创建。
    existing = dao.get_by_unique(db, DeviceCommand, filters={"order_id": order_id, "command_type": command_type})
    if existing is not None:
        if existing.gun_id != gun_id:
            raise ValueError("命令业务键已关联其他充电枪")
        return existing.command_id
    if command_type == "start" and (order["status"] != "charging" or gun.status != "occupied"
                                    or not pile.is_online or pile.lifecycle_status != "active" or gun.has_fault or pile.has_fault):
        raise ValueError("设备或订单不满足启动条件")
    # 先创建待发送命令；此处没有任何设备网络调用。
    command = DeviceCommand(pile_id=pile.pile_id, gun_id=gun_id, order_id=order_id,
                            command_type=command_type, status="pending", attempt_count=0)
    db.add(command)
    # 把会话内待保存的修改发给数据库，以便后续查询及取得主键；flush 不等于 commit。
    db.flush()
    # Outbox 事件只含必要业务编号，网络发送由提交后的任务负责。
    # Outbox 是待处理任务记录，后台在事务提交后发送；命令和事件要同时成功或同时回滚。
    db.add(OutboxEvent(event_type="device_command", business_key=f"device_command:{command.command_id}",
                       payload={"command_id": str(command.command_id)}, status="pending",
                       attempt_count=0, available_at=_now()))
    # 把会话内待保存的修改发给数据库，以便后续查询及取得主键；flush 不等于 commit。
    db.flush()
    # 仅返回命令编号，让调用方继续自己的业务事务，最终统一 commit。
    return command.command_id
