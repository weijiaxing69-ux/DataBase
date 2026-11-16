"""assets 模块：数据库访问，按 V1.4 契约逐步实现。"""
from .models import *
from sqlalchemy import select, func, inspect, or_, table, column
from sqlalchemy.orm import Session
from .schemas import *

#TODO 在这里实现查找场站列表  会话以及查询的条件信息
def _apply_station_filters(stmt, *, query: StationQuery):
    #如果有关键字传进来
    if query.keyword:
        stmt = stmt.where(
            Station.station_name.contains(query.keyword, autoescape=True)
        )
    #如果有运营商编号
    if query.operator_id is not None:
        stmt=stmt.where(Station.operator_id==query.operator_id)
    #如果有状态
    if query.status is not None:
        stmt=stmt.where(Station.status==query.status)
    #这里进行时间筛选
    if query.start_at is not None:
        stmt=stmt.where(Station.created_at>=query.start_at)

    if query.end_at is not None:
        stmt=stmt.where(Station.created_at<query.end_at)

    return stmt

#查询场站
def query_station(db: Session, *, query: StationQuery) -> list[Station]:
    # 列表与计数共用筛选条件
    stmt = _apply_station_filters(select(Station), query=query)

    #如果分页 计算记录数
    offset=(query.page-1)*query.page_size
    stmt=stmt.order_by(Station.station_id).offset(offset).limit(query.page_size)

    #最后返回结果
    return list(db.scalars(stmt).all())
#TODO 在这里计算符合筛选条件的场站总数，不受分页影响
def count_stations(db:Session,*,query:StationQuery) -> int:
    stmt = _apply_station_filters(
        select(func.count()).select_from(Station), query=query
    )
    return db.execute(stmt).scalar_one()
#TODO 根据编号查询
def get_station_by_id(db:Session,*,station_id:int):
    #TODO 先查询所有的场站
    stmt=select(Station)
    #TODO 根据编号进行筛选
    stmt=stmt.where(Station.station_id==station_id)
    #TODO 返回结果
    return db.scalar(stmt)
#TODO 在这里面添加场地
def add_station(db:Session,*,station:Station):
    db.add(station)
    # 将对象写入数据库，事务由 Service 提交
    db.flush()
    return station

#TODO 在这里面更新场地的数据 将已经修改的内容同步到数据库
def update_station(db:Session,*,station_id:int,station:Station):
    # 更新语句
    stmt=db.get(Station,station_id)
    if stmt is not None:
        stmt.station_name=station.station_name
        stmt.address=station.address
        stmt.longitude=station.longitude
        stmt.latitude=station.latitude
        stmt.parking_spaces=station.parking_spaces
        stmt.business_hours=station.business_hours
        stmt.parking_fee_standard=station.parking_fee_standard
        stmt.status=station.status
        # 接收完整场站数据；部分更新需单独处理未传字段。事务由 Service 提交
        db.flush()
    #TODO 返回更新之后的对象
    return stmt
#model指的是查询哪一张表 for_update表示是否加锁 resource_id表示查询的资源编号
def get_by_id(db, model, resource_id, *, for_update=False):
    # 获取模型的主键列；此实现仅支持单列主键
    primary_keys = inspect(model).primary_key
    if len(primary_keys) != 1:
        raise ValueError("此查询仅支持单列主键")
    # 根据实际主键构造查询
    stmt = select(model).where(primary_keys[0] == resource_id)
    # 需要时添加更新锁
    if for_update:
        stmt = stmt.with_for_update().execution_options(populate_existing=True)
    # 查到返回模型对象，查不到返回 None
    return db.scalar(stmt)

# 根据关键词、时间范围筛选，再排序和分页
def get_by_unique(db, model, *, filters, for_update=False):
    # 仅允许本模块登记的模型与字段，不接受任意 SQL 或表名。
    if model not in (Operator, Station, ChargingPile, ChargingGun, EquipmentChangeRequest,
                     DeviceAcceptance, DeviceCommand, DeviceStatusLog, DeviceCredential):
        raise ValueError("不支持的数据库模型")
    columns = inspect(model).column_attrs
    if not isinstance(filters, dict) or not filters:
        raise ValueError("必须提供查询条件")
    stmt = select(model)
    for name, value in filters.items():
        if name not in columns:
            raise ValueError("不支持的查询字段")
        stmt = stmt.where(getattr(model, name) == value)
    if for_update:
        stmt = stmt.with_for_update()
    return db.execute(stmt).scalar_one_or_none()


def _query_operators(db, *, query: OperatorQuery) -> list[Operator]:
    stmt=select(Operator)
    if query.keyword:
        stmt=stmt.where(
            Operator.operator_name.contains(
                query.keyword,
                autoescape=True
            )
        )
    #TODO 在这里面要根据时间筛选
    if query.start_at is not None:
        stmt=stmt.where(
            Operator.created_at>=query.start_at
        )

    if query.end_at is not None:
        stmt=stmt.where(
            Operator.created_at<query.end_at
        )

    #TODO 计算跳过了多少记录
    offset=(query.page-1)*query.page_size
    stmt=(
        stmt.order_by(Operator.operator_id)
        .offset(offset)
        .limit(query.page_size)
    )
    return list(db.scalars(stmt).all())


# 使用相同筛选条件统计总数，不分页
def _count_operators(db, *, query: OperatorQuery) -> int:
    stmt = select(func.count()).select_from(Operator)
    # 按运营商名称筛选
    if query.keyword:
        stmt = stmt.where(
            Operator.operator_name.contains(
                query.keyword,
                autoescape=True,
            )
        )

    # 3. 筛选创建时间，包含开始时间
    if query.start_at is not None:
        stmt = stmt.where(
            Operator.created_at >= query.start_at
        )

    # 4. 不包含结束时间
    if query.end_at is not None:
        stmt = stmt.where(
            Operator.created_at < query.end_at
        )

    #TODO 返回数值
    return db.execute(stmt).scalar_one()
#TODO 将实体加入数据库对话
def add(db,entity):
    db.add(entity)
#TODO 将修改发送到数据库 但是不提交
def flush(db):
    db.flush()

#TODO 根据编号查询一个充电桩，不存在时返回 None
def get_pile_by_id(db: Session, *, pile_id: int):
    # 查询数据库模型，按充电桩主键筛选
    stmt = select(ChargingPile).where(ChargingPile.pile_id == pile_id)
    # 查到时返回模型对象，查不到时返回 None
    return db.scalar(stmt)

# 根据查询条件获取当前页的充电桩列表
def _apply_pile_filters(stmt, *, query: PileQuery):
    # 关键词匹配序列号或型号；autoescape 将 % 和 _ 作为普通字符处理
    if query.keyword:
        stmt = stmt.where(or_(
            ChargingPile.serial_no.contains(query.keyword, autoescape=True),
            ChargingPile.model_name.contains(query.keyword, autoescape=True),
        ))
    # 不同筛选条件之间是“并且”；没有传入的条件不参与筛选
    if query.station_id is not None:
        stmt = stmt.where(ChargingPile.station_id == query.station_id)
    if query.status is not None:
        stmt = stmt.where(ChargingPile.status == query.status)
    # 当前按创建时间筛选，包含开始时间，不包含结束时间
    if query.start_at is not None:
        stmt = stmt.where(ChargingPile.created_at >= query.start_at)
    if query.end_at is not None:
        stmt = stmt.where(ChargingPile.created_at < query.end_at)
    return stmt


def _query_piles(db: Session, *, query: PileQuery) -> list[ChargingPile]:
    # 先构建查询并添加条件，再交给数据库执行
    stmt = _apply_pile_filters(select(ChargingPile), query=query)
    # 按主键倒序，保证分页顺序稳定
    offset = (query.page - 1) * query.page_size
    stmt = stmt.order_by(ChargingPile.pile_id.desc()).offset(offset).limit(query.page_size)
    return list(db.scalars(stmt).all())


# 根据相同查询条件统计总数，不进行分页
def _count_piles(db: Session, *, query: PileQuery) -> int:
    # 使用相同条件统计全部匹配记录，不添加分页
    stmt = select(func.count()).select_from(ChargingPile)
    stmt = _apply_pile_filters(stmt, query=query)
    return db.scalar(stmt) or 0

#TODO 实现列表查询
def list_page(db, model, *, filters, page, page_size):
    # 只允许查询本模块的数据库模型
    if model not in (Operator, Station, ChargingPile, ChargingGun):
        raise ValueError("不支持的数据库模型")

    # 检查分页参数
    if page < 1:
        raise ValueError("页码不能小于1")
    if page_size < 1 or page_size > 100:
        raise ValueError("每页数量必须在1到100之间")

    if not isinstance(filters, dict):
        raise ValueError("筛选条件必须是字典")

    # 得到模型对应的数据库字段
    mapper = inspect(model)

    # 当前通用查询只支持单列主键
    if len(mapper.primary_key) != 1:
        raise ValueError("此查询仅支持单列主键")

    # 构建筛选条件，列表和总数共用
    conditions = []
    for field, value in filters.items():
        # 充电枪的扩展筛选约定，仅在此模型上处理这些特殊字段
        if model is ChargingGun:
            if field == "station_id":
                # 枪表没有场站编号，通过所属充电桩筛选；子查询不会重复记录
                conditions.append(ChargingGun.pile_id.in_(
                    select(ChargingPile.pile_id).where(ChargingPile.station_id == value)
                ))
                continue
            if field == "keyword":
                # 当前实现约定关键词匹配接口标准或充电类型
                conditions.append(or_(
                    ChargingGun.connector_standard.contains(value, autoescape=True),
                    ChargingGun.gun_type.contains(value, autoescape=True),
                ))
                continue
            if field == "start_at":
                conditions.append(ChargingGun.created_at >= value)
                continue
            if field == "end_at":
                conditions.append(ChargingGun.created_at < value)
                continue
        if field not in mapper.column_attrs:
            raise ValueError("不支持的查询字段")

        conditions.append(getattr(model, field) == value)

    # 查询符合条件的总数，不加分页
    count_stmt = (
        select(func.count())
        .select_from(model)
        .where(*conditions)
    )
    total = db.scalar(count_stmt) or 0

    # 查询当前页，按主键排序保证顺序稳定
    offset = (page - 1) * page_size
    stmt = (
        select(model)
        .where(*conditions)
        .order_by(mapper.primary_key[0])
        .offset(offset)
        .limit(page_size)
    )
    items = list(db.scalars(stmt).all())

    # 此实现约定返回：当前页模型列表、匹配总数
    return items, total





# 固定跨模块只读查询，不创建其他成员的表，也不提交事务。
_orders = table("charging_order", column("order_id"), column("gun_id"), column("status"))
_alerts = table("device_alert", column("alert_id"), column("pile_id"), column("gun_id"),
                column("alarm_rule_id"), column("status"), column("normal_since_at"), column("recovered_at"))
_work_orders = table("work_order", column("work_order_id"), column("alert_id"), column("status"))
_rules = table("alarm_rule", column("alarm_rule_id"), column("metric"), column("threshold_value"),
               column("recovery_seconds"), column("enabled"), column("fault_code"))
_readings = table("device_reading", column("sample_id"), column("pile_id"), column("sampled_at"),
                  column("module_temperature_c"), column("offline_seconds"), column("fault_code"))


def _active_order_id(db, gun_id):
    # 固定跨模块只读查询，不创建其他成员的表，也不提交事务。
    return db.execute(select(_orders.c.order_id).where(
        _orders.c.gun_id == gun_id, _orders.c.status == "charging"
    )).scalar_one_or_none()


def _order_for_gun(db, order_id, gun_id):
    return db.execute(select(_orders).where(
        _orders.c.order_id == order_id, _orders.c.gun_id == gun_id
    )).mappings().one_or_none()


def _device_page(db, model, *, conditions, page, page_size):
    """共用条件分别用于分页与总数统计。"""
    if page < 1 or not 1 <= page_size <= 100:
        raise ValueError("分页参数不合法")
    total = db.scalar(select(func.count()).select_from(model).where(*conditions)) or 0
    pk = inspect(model).primary_key[0]
    ordering = pk.asc() if model is ChargingGun else pk.desc()
    items = list(db.scalars(select(model).where(*conditions).order_by(ordering)
                           .offset((page - 1) * page_size).limit(page_size)).all())
    return items, total
