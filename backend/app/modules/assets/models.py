"""成员1：场站与设施的数据库表映射。"""

from sqlalchemy import CheckConstraint, Column, Date, Numeric, String, UniqueConstraint, text
from sqlalchemy.dialects.mysql import *

from app.core.database import Base

#将数据库中的内容转变为python的对象，方便操作
class Station(Base):
    # TODO 对应数据库中已存在的场站表，不重新建表。
    __tablename__ = "station"
    #这个是加电站编号
    station_id = Column(BIGINT(unsigned=True), primary_key=True, autoincrement=True)
    # TODO 所属运营商的外键约束已由数据库统一建表脚本建立。
       # 运营商编号
    operator_id = Column(BIGINT(unsigned=True), nullable=False)
    # 场站名称
    station_name = Column(String(100), nullable=False)
    # 场站地址
    address = Column(String(255), nullable=False)
    # 经度
    longitude = Column(Numeric(10, 7), nullable=False)
    # 纬度
    latitude = Column(Numeric(10, 7), nullable=False)
    # 停车位数量
    parking_spaces = Column(INTEGER(unsigned=True), nullable=False, server_default=text("0"))
    # 营业时间
    business_hours = Column(String(100), nullable=False, server_default=text("'00:00-24:00'"))
    # 停车收费标准
    parking_fee_standard = Column(String(255), nullable=False, server_default=text("'按场站公示标准'"))
    # 场站状态
    status = Column(String(32), nullable=False, server_default=text("'draft'"))
    # 创建时间
    created_at = Column(DATETIME(fsp=3), nullable=False, server_default=text("current_timestamp(3)"))
    # 更新时间
    updated_at = Column(
        DATETIME(fsp=3), nullable=False,
        server_default=text("current_timestamp(3)"), server_onupdate=text("current_timestamp(3)"),
    )
#TODO 定义Operator
class ChargingPile(Base):
    """充电桩表映射；表和数据库约束由统一 SQL 脚本创建。"""

    __tablename__ = "charging_pile"

    # 充电桩编号，数据库自动生成
    pile_id = Column(BIGINT(unsigned=True), primary_key=True, autoincrement=True)
    # 所属场站编号
    station_id = Column(BIGINT(unsigned=True), nullable=False)
    # 铭牌设备序列号，不能重复
    serial_no = Column(String(64), nullable=False, unique=True)
    # 设备型号
    model_name = Column(String(100), nullable=False)
    # 整桩额定功率，单位 kW，保留三位小数
    rated_power_kw = Column(Numeric(10, 3), nullable=False)
    # 模拟或接入协议名称
    protocol = Column(String(50), nullable=False)
    # 投运日期，尚未投运时可以为空
    commissioned_on = Column(Date, nullable=True)
    # 质保截止日期，可以为空
    warranty_until = Column(Date, nullable=True)
    # 生命周期：draft、pending_acceptance、active、retired；投运需走验收流程
    lifecycle_status = Column(String(32), nullable=False, server_default=text("'draft'"))
    # 运行状态：idle、occupied、fault、offline，与生命周期分别记录
    status = Column(String(32), nullable=False, server_default=text("'offline'"))
    # 故障事实标记，0 或 1；离线不代表故障已经消失
    has_fault = Column(TINYINT(unsigned=True), nullable=False, server_default=text("0"))
    # 通信在线标记，0 或 1
    is_online = Column(TINYINT(unsigned=True), nullable=False, server_default=text("0"))
    # 最后收到有效心跳的 UTC 时间
    last_heartbeat_at = Column(DATETIME(fsp=3), nullable=True)
    # UTC 创建时间，由数据库生成
    created_at = Column(DATETIME(fsp=3), nullable=False, server_default=text("current_timestamp(3)"))
    # UTC 更新时间，自动更新规则由数据库表定义负责
    updated_at = Column(
        DATETIME(fsp=3), nullable=False,
        server_default=text("current_timestamp(3)"),
        server_onupdate=text("current_timestamp(3)"),
    )


class ChargingGun(Base):
    """充电枪表映射；实际建表及外键约束由统一 SQL 脚本负责。"""

    __tablename__ = "charging_gun"
    __table_args__ = (
        # 同一充电桩下的枪序号不能重复，不同桩可以使用相同序号
        UniqueConstraint("pile_id", "gun_no"),
        CheckConstraint("gun_no > 0"),
        CheckConstraint("max_power_kw > 0"),
    )

    # 充电枪编号，数据库自动生成
    gun_id = Column(BIGINT(unsigned=True), primary_key=True, autoincrement=True)
    # 所属充电桩编号
    pile_id = Column(BIGINT(unsigned=True), nullable=False)
    # 桩内枪序号，从 1 开始
    gun_no = Column(SMALLINT(unsigned=True), nullable=False)
    # 充电类型：dc 为直流快充，ac 为交流慢充
    gun_type = Column(String(32), nullable=False)
    # 接口标准
    connector_standard = Column(String(50), nullable=False)
    # 最大功率，单位 kW；不能超过所属充电桩额定功率，由 Service 校验
    max_power_kw = Column(Numeric(10, 3), nullable=False)
    # 当前运行状态：idle、occupied、fault、offline；新增时默认离线
    status = Column(String(32), nullable=False, server_default=text("'offline'"))
    # 故障事实标记，与通信在线事实分开；离线不能自动清除故障
    has_fault = Column(TINYINT(unsigned=True), nullable=False, server_default=text("0"))
    # UTC 创建时间
    created_at = Column(DATETIME(fsp=3), nullable=False, server_default=text("current_timestamp(3)"))
    # UTC 更新时间，实际自动更新规则由数据库表定义负责
    updated_at = Column(
        DATETIME(fsp=3), nullable=False,
        server_default=text("current_timestamp(3)"),
        server_onupdate=text("current_timestamp(3)"),
    )
    # 不存 active_order_id，当前充电订单通过订单表查询


class EquipmentChangeRequest(Base):
    """设备档案变更申请；实际建表和外键由统一 SQL 脚本负责。"""

    __tablename__ = "equipment_change_request"
    __table_args__ = (
        # 一份申请只能针对一个桩或者一把枪
        CheckConstraint("(pile_id IS NOT NULL) + (gun_id IS NOT NULL) = 1"),
    )

    # 申请编号
    request_id = Column(BIGINT(unsigned=True), primary_key=True, autoincrement=True)
    # 桩目标，与 gun_id 二选一
    pile_id = Column(BIGINT(unsigned=True), nullable=True)
    # 枪目标，与 pile_id 二选一
    gun_id = Column(BIGINT(unsigned=True), nullable=True)
    # 变更类型：archive、relocate、retrofit、retire
    change_type = Column(String(32), nullable=False)
    # 原始档案快照，必须由服务端读取，不接受前端指定
    before_data = Column(JSON, nullable=False)
    # 拟修改字段的新值，Service 必须按白名单校验后才能生效
    proposed_data = Column(JSON, nullable=False)
    # 申请理由
    reason = Column(String(500), nullable=False)
    # 申请账号，从 Actor 中取得
    requested_by = Column(BIGINT(unsigned=True), nullable=False)
    # 审批状态：pending、approved、rejected
    status = Column(String(32), nullable=False, server_default=text("'pending'"))
    # 审批账号，禁止申请人自批
    reviewed_by = Column(BIGINT(unsigned=True), nullable=True)
    # UTC 审批时间，待审批时为空
    reviewed_at = Column(DATETIME(fsp=3), nullable=True)
    # 审批意见
    review_note = Column(String(500), nullable=True)
    # UTC 创建时间
    created_at = Column(DATETIME(fsp=3), nullable=False, server_default=text("current_timestamp(3)"))
    # UTC 最后修改时间
    updated_at = Column(
        DATETIME(fsp=3), nullable=False,
        server_default=text("current_timestamp(3)"),
        server_onupdate=text("current_timestamp(3)"),
    )


class Operator(Base):
    __tablename__ = "operator"
    # 主键
    operator_id = Column(
        BIGINT(unsigned=True),
        primary_key=True,
        autoincrement=True,
    )
    # 运营商名称
    operator_name = Column(String(100), nullable=False)
    # 统一社会信用代码
    credit_code = Column(String(18), nullable=False, unique=True)
    # 联系人
    contact_name = Column(String(50), nullable=False)
    # 联系电话密文
    contact_phone_cipher = Column(VARBINARY(512), nullable=False)
    # 启用状态：active、disabled，默认启用
    status = Column(
        String(32),
        nullable=False,
        server_default=text("'active'"),
    )
    # UTC创建时间
    created_at = Column(
        DATETIME(fsp=3),
        nullable=False,
        server_default=text("current_timestamp(3)"),
    )
    # UTC最后修改时间
    updated_at = Column(
        DATETIME(fsp=3),
        nullable=False,
        server_default=text("current_timestamp(3)"),
        server_onupdate=text("current_timestamp(3)"),
    )


class DeviceStatusLog(Base):
    """设备状态历史映射；实际建表由统一 SQL 脚本负责。"""
    __tablename__ = "device_status_log"
    __table_args__ = (
        CheckConstraint('(pile_id is not null) + (gun_id is not null) = 1'),
    )
    # 主键
    status_log_id = Column(BIGINT(unsigned=True), primary_key=True, autoincrement=True)
    # 目标桩 与gun_id二选一
    pile_id = Column(BIGINT(unsigned=True), nullable=True)
    # 目标枪 与pile_id二选一
    gun_id = Column(BIGINT(unsigned=True), nullable=True)
    # 原状态 首条可空；idle, occupied, fault, offline
    old_status = Column(String(32), nullable=True)
    # 新状态；idle, occupied, fault, offline
    new_status = Column(String(32), nullable=False)
    # 变化时间
    occurred_at = Column(DATETIME(fsp=3), nullable=False)
    # 变更原因
    reason = Column(String(255), nullable=False)
    # 系统任务为空
    actor_account_id = Column(BIGINT(unsigned=True), nullable=True)
    # UTC创建时间
    created_at = Column(DATETIME(fsp=3), nullable=False, server_default=text('current_timestamp(3)'))
    # UTC最后修改时间
    updated_at = Column(DATETIME(fsp=3), nullable=False, server_default=text('current_timestamp(3)'), server_onupdate=text("current_timestamp(3)"))


class DeviceAcceptance(Base):
    """设备联调验收记录；每次验收新增一条，保留历史结论。"""
    __tablename__ = "device_acceptance"
    # 主键
    acceptance_id = Column(BIGINT(unsigned=True), primary_key=True, autoincrement=True)
    # 验收桩
    pile_id = Column(BIGINT(unsigned=True), nullable=False)
    # 模拟协议联调是否通过
    protocol_test_passed = Column(TINYINT(unsigned=True), nullable=False, server_default=text('0'))
    # 铭牌是否核对
    nameplate_checked = Column(TINYINT(unsigned=True), nullable=False, server_default=text('0'))
    # 启停测试结果
    start_stop_passed = Column(TINYINT(unsigned=True), nullable=False, server_default=text('0'))
    # 心跳测试结果
    heartbeat_passed = Column(TINYINT(unsigned=True), nullable=False, server_default=text('0'))
    # 验收结论；passed, failed
    result = Column(String(32), nullable=False)
    # 验收账号
    accepted_by = Column(BIGINT(unsigned=True), nullable=False)
    # 验收时间
    accepted_at = Column(DATETIME(fsp=3), nullable=False)
    # 验收说明
    note = Column(String(500), nullable=True)
    # UTC创建时间
    created_at = Column(DATETIME(fsp=3), nullable=False, server_default=text('current_timestamp(3)'))
    # UTC最后修改时间
    updated_at = Column(DATETIME(fsp=3), nullable=False, server_default=text('current_timestamp(3)'), server_onupdate=text("current_timestamp(3)"))


class DeviceCommand(Base):
    """设备启停命令映射；发送任务在业务事务提交后执行。"""
    __tablename__ = "device_command"
    __table_args__ = (
        UniqueConstraint('order_id', 'command_type'),
    )
    # 主键
    command_id = Column(BIGINT(unsigned=True), primary_key=True, autoincrement=True)
    # 目标桩
    pile_id = Column(BIGINT(unsigned=True), nullable=False)
    # 目标枪
    gun_id = Column(BIGINT(unsigned=True), nullable=False)
    # 关联订单
    order_id = Column(BIGINT(unsigned=True), nullable=False)
    # 启停命令；start, stop
    command_type = Column(String(32), nullable=False)
    # 命令状态；pending, sent, succeeded, failed
    status = Column(String(32), nullable=False, server_default=text("'pending'"))
    # 发送次数
    attempt_count = Column(INTEGER(unsigned=True), nullable=False, server_default=text('0'))
    # 发送时间
    sent_at = Column(DATETIME(fsp=3), nullable=True)
    # 确认时间
    acknowledged_at = Column(DATETIME(fsp=3), nullable=True)
    # 失败说明
    error_message = Column(String(500), nullable=True)
    # UTC创建时间
    created_at = Column(DATETIME(fsp=3), nullable=False, server_default=text('current_timestamp(3)'))
    # UTC最后修改时间
    updated_at = Column(DATETIME(fsp=3), nullable=False, server_default=text('current_timestamp(3)'), server_onupdate=text("current_timestamp(3)"))


class OutboxEvent(Base):
    """提交后待处理事件；与设备命令在同一事务内入库。"""
    __tablename__ = "outbox_event"
    __table_args__ = (
        UniqueConstraint('business_key'),
    )
    # 主键
    outbox_id = Column(BIGINT(unsigned=True), primary_key=True, autoincrement=True)
    # 设备命令或通知类型
    event_type = Column(String(50), nullable=False)
    # 唯一事件键
    business_key = Column(String(120), nullable=False)
    # 必要业务编号 不含密钥
    payload = Column(JSON, nullable=False)
    # 消费状态；pending, processing, done, failed
    status = Column(String(32), nullable=False, server_default=text("'pending'"))
    # 重试次数
    attempt_count = Column(INTEGER(unsigned=True), nullable=False, server_default=text('0'))
    # 可执行时间
    available_at = Column(DATETIME(fsp=3), nullable=False)
    # 消费者租约
    locked_until = Column(DATETIME(fsp=3), nullable=True)
    # 最近失败说明
    last_error = Column(String(500), nullable=True)
    # UTC创建时间
    created_at = Column(DATETIME(fsp=3), nullable=False, server_default=text('current_timestamp(3)'))
    # UTC最后修改时间
    updated_at = Column(DATETIME(fsp=3), nullable=False, server_default=text('current_timestamp(3)'), server_onupdate=text("current_timestamp(3)"))


class DeviceCredential(Base):
    """设备模拟凭据； SQL ；"""
    __tablename__ = "device_credential"
    __table_args__ = (
        UniqueConstraint('token_hash'),
    )
    # 主键
    credential_id = Column(BIGINT(unsigned=True), primary_key=True, autoincrement=True)
    # 凭据绑定桩
    pile_id = Column(BIGINT(unsigned=True), nullable=False)
    # 设备令牌摘要 不存原令牌
    token_hash = Column(BINARY(32), nullable=False)
    # 到期时间
    expires_at = Column(DATETIME(fsp=3), nullable=False)
    # 撤销时间
    revoked_at = Column(DATETIME(fsp=3), nullable=True)
    # UTC创建时间
    created_at = Column(DATETIME(fsp=3), nullable=False, server_default=text('current_timestamp(3)'))
    # UTC最后修改时间
    updated_at = Column(DATETIME(fsp=3), nullable=False, server_default=text('current_timestamp(3)'), server_onupdate=text("current_timestamp(3)"))
