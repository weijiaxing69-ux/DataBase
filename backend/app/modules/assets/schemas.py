"""场站设施模块的请求与响应数据结构。"""

from datetime import date, datetime, timezone
from decimal import Decimal
from typing import Literal

from pydantic import (
    AwareDatetime,
    BaseModel,
    ConfigDict,
    Field,
    JsonValue,
    field_serializer,
    model_validator,
)


class StationDetail(BaseModel):
    # 允许从 SQLAlchemy 模型对象中读取字段
    model_config = ConfigDict(from_attributes=True)
    # 场站编号
    station_id: int
    # 运营商编号
    operator_id: int
    # 场站名称
    station_name: str
    # 场站地址
    address: str
    # 经度
    longitude: Decimal
    # 纬度
    latitude: Decimal
    # 停车位数量
    parking_spaces: int
    # 营业时间
    business_hours: str
    # 停车收费标准
    parking_fee_standard: str
    # 场站状态：草稿、运营中、暂停、退役
    status: Literal["draft", "active", "suspended", "retired"]
    # 创建时间
    created_at: datetime
    # 更新时间
    updated_at: datetime

    @field_serializer("station_id", "operator_id", when_used="json")
    def _serialize_id(self, value: int) -> str:
        # V1.4：JSON 编号使用十进制字符串，防止 JavaScript 丢失精度。
        return str(value)

    @field_serializer("created_at", "updated_at", when_used="json")
    def _serialize_time(self, value: datetime) -> str:
        # 数据库 datetime 存储 UTC，但驱动返回的值可能没有时区信息。
        if value.tzinfo is None:
            value = value.replace(tzinfo=timezone.utc)
        return value.astimezone(timezone.utc).isoformat(timespec="milliseconds").replace("+00:00", "Z")

class StationQuery(BaseModel):
    # 页码，从第 1 页开始
    page:int = Field(default=1, ge=1)
    # 每页数量，范围为 1～100
    page_size:int = Field(default=20, ge=1, le=100)
    # 查询关键词，不传则不按关键词筛选
    keyword:str | None = None
    # 运营商编号，不传则不按运营商筛选
    operator_id:int | None = Field(default=None, gt=0)
    # 场站状态，不传则不按状态筛选
    status:Literal["draft", "active", "suspended", "retired"] | None = None
    # 开始时间，包含该时刻，使用 UTC
    start_at:datetime | None = None
    # 结束时间，不包含该时刻，使用 UTC
    end_at:datetime | None = None

class CreateStationRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")
    #所属运营商
    operator_id: int = Field(gt=0)
    #场站名称
    station_name: str = Field(min_length=1, max_length=100)
    #地址
    address: str = Field(min_length=1, max_length=255)
    #经度
    longitude: Decimal = Field(ge=-180, le=180, max_digits=10, decimal_places=7)
    #纬度
    latitude: Decimal = Field(ge=-90, le=90, max_digits=10, decimal_places=7)
    #车位数量
    parking_spaces: int = Field(default=0, ge=0, le=4294967295)
    #营业时间展示
    business_hours: str = Field(default="00:00-24:00", max_length=100)
    #停车费说明
    parking_fee_standard: str = Field(default="按场站公示标准", max_length=255)


class OperatorDetail(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    # 主键
    operator_id: int
    # 运营商名称
    operator_name: str
    # 统一社会信用代码
    credit_code: str
    # 联系人
    contact_name: str
    # 启用状态
    status: Literal["active", "disabled"]
    # 创建时间
    created_at: datetime
    # 最后修改时间
    updated_at: datetime
    # 脱敏电话
    phone_masked: str

    @field_serializer("operator_id", when_used="json")
    def _serialize_id(self, value: int) -> str:
        # V1.4：JSON 编号使用十进制字符串。
        return str(value)

    @field_serializer("created_at", "updated_at", when_used="json")
    def _serialize_time(self, value: datetime) -> str:
        # 数据库 datetime 存储 UTC，驱动可能返回不带时区的值。
        if value.tzinfo is None:
            value = value.replace(tzinfo=timezone.utc)
        return (
            value.astimezone(timezone.utc)
            .isoformat(timespec="milliseconds")
            .replace("+00:00", "Z")
        )


class OperatorQuery(BaseModel):
    """运营商列表查询条件，字段按 V1.4 OperatorQuery 契约定义。"""

    # 页码，从第 1 页开始
    page: int = Field(default=1, ge=1)

    # 每页数量，默认 20，最大 100
    page_size: int = Field(default=20, ge=1, le=100)

    # 查询关键词，省略时不按关键词筛选
    keyword: str | None = None

    # 开始时间，包含该时刻；API 输入必须带时区
    start_at: AwareDatetime | None = None

    # 结束时间，不包含该时刻；API 输入必须带时区
    end_at: AwareDatetime | None = None

    @model_validator(mode="after")
    def _validate_time_range(self):
        # 将带时区的输入统一转换为 UTC。
        if self.start_at is not None:
            self.start_at = self.start_at.astimezone(timezone.utc)
        if self.end_at is not None:
            self.end_at = self.end_at.astimezone(timezone.utc)
        if (
            self.start_at is not None
            and self.end_at is not None
            and self.start_at >= self.end_at
        ):
            raise ValueError("开始时间必须早于结束时间")
        return self


class UpdateStationRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    # PATCH 中省略表示不修改；显式 null 由下面的校验器拒绝。
    # 场站名称
    station_name: str | None = Field(default=None, min_length=1, max_length=100)
    # 地址
    address: str | None = Field(default=None, min_length=1, max_length=255)
    # 经度
    longitude: Decimal | None = Field(default=None, ge=-180, le=180, max_digits=10, decimal_places=7)
    # 纬度
    latitude: Decimal | None = Field(default=None, ge=-90, le=90, max_digits=10, decimal_places=7)
    # 车位数量
    parking_spaces: int | None = Field(default=None, ge=0, le=4294967295)
    # 营业时间展示文本
    business_hours: str | None = Field(default=None, max_length=100)
    # 停车费说明 不并入充电费
    parking_fee_standard: str | None = Field(default=None, max_length=255)
    # 场站生命周期；值：draft,active,suspended,retired
    status: Literal['draft', 'active', 'suspended', 'retired'] | None = None

    @model_validator(mode="after")
    def _validate_changes(self):
        if not self.model_fields_set:
            raise ValueError("至少提供一个修改字段")
        if any(getattr(self, field) is None for field in self.model_fields_set):
            raise ValueError("修改字段不能为 null")
        return self

class CreateOperatorRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")
    #运营商名称
    operator_name:str = Field(min_length=1,max_length=100)
    #统一社会信用代码
    credit_code:str = Field(min_length=1,max_length=18)
    #联系人
    contact_name:str = Field(min_length=1,max_length=50)
    #联系电话，接收明文，后端加密存储，不记录日志
    # 限制输入长度，确保 Fernet 密文可放入 VARBINARY(512)；不显示在 repr 中。
    contact_phone:str = Field(min_length=1,max_length=100,repr=False)

class UpdateOperatorRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")
    # 运营商名称
    operator_name:str | None =Field(default=None,min_length=1,max_length=100)
    # 联系人
    contact_name:str | None =Field(default=None,min_length=1,max_length=50)
    # 启用状态；值：active,disabled
    status:Literal['active','disabled'] | None =None
    # 更新电话，非空
    contact_phone:str | None =Field(default=None,min_length=1,max_length=100,repr=False)

    @model_validator(mode="after")
    def _validate_changes(self):
        if not self.model_fields_set:
            raise ValueError("至少提供一个修改字段")
        if any(getattr(self,field) is None for field in self.model_fields_set):
            raise ValueError("修改字段不能为null")
        return self

class PileDetail(BaseModel):
    # 允许从数据库模型对象读取属性
    model_config = ConfigDict(from_attributes=True)

    # 主键
    pile_id: int
    # 所属场站编号
    station_id: int
    # 铭牌设备序列号
    serial_no: str
    # 设备型号
    model_name: str
    # 整桩额定功率，单位 kW
    rated_power_kw: Decimal
    # 模拟或接入协议名称
    protocol: str
    # 投运日期，未投运时可以为空
    commissioned_on: date | None
    # 质保截止日期，可以为空
    warranty_until: date | None
    # 投运验收状态
    lifecycle_status: Literal[
        "draft", "pending_acceptance", "active", "retired"
    ]
    # 当前设备状态
    status: Literal["idle", "occupied", "fault", "offline"]
    # 是否存在故障，不因离线而清除
    has_fault: bool
    # 通信是否在线
    is_online: bool
    # 最后收到有效心跳的时间，可以为空
    last_heartbeat_at: datetime | None
    # 创建时间
    created_at: datetime
    # 最后修改时间
    updated_at: datetime

    @field_serializer("pile_id", "station_id", when_used="json")
    def _serialize_id(self, value: int) -> str:
        # V1.4：JSON 编号使用字符串，防止前端丢失大整数精度。
        return str(value)

    @field_serializer("last_heartbeat_at", "created_at", "updated_at", when_used="json")
    def _serialize_time(self, value: datetime | None) -> str | None:
        # 尚未收到心跳时保留 null。
        if value is None:
            return None
        # 数据库存储 UTC，驱动返回无时区时间时补上 UTC。
        if value.tzinfo is None:
            value = value.replace(tzinfo=timezone.utc)
        return value.astimezone(timezone.utc).isoformat(timespec="milliseconds").replace("+00:00", "Z")



class PileQuery(BaseModel):
    # 页码，默认 1，最小为 1
    page: int = Field(default=1, ge=1)
    # 每页数量，默认 20，最大 100
    page_size: int = Field(default=20, ge=1, le=100)
    # 可选关键词
    keyword: str | None = None
    # 所属场站编号；资源范围权限由 Service 层检查
    station_id: int | None = Field(default=None, gt=0)
    # 可选设备运行状态
    status: Literal["idle", "occupied", "fault", "offline"] | None = None
    # 开始时间，包含该时刻；输入必须带时区
    start_at: AwareDatetime | None = None
    # 结束时间，不包含该时刻；输入必须带时区
    end_at: AwareDatetime | None = None

    @model_validator(mode="after")
    def _validate_time_range(self):
        # 将带时区的时间统一转换为 UTC
        if self.start_at is not None:
            self.start_at = self.start_at.astimezone(timezone.utc)

        if self.end_at is not None:
            self.end_at = self.end_at.astimezone(timezone.utc)

        # 同时传入起止时间时，开始时间必须早于结束时间
        if self.start_at is not None and self.end_at is not None:
            if self.start_at >= self.end_at:
                raise ValueError("开始时间必须早于结束时间")

        return self
class CreatePileRequest(BaseModel):
    # 拒绝文档规定以外的请求字段
    model_config = ConfigDict(extra="forbid")

    # 所属场站编号；场站存在性和资源范围由 Service 层检查
    station_id: int = Field(gt=0, le=18446744073709551615)
    # 铭牌设备序列号；唯一性由 Service 层和数据库检查
    serial_no: str = Field(min_length=1, max_length=64)
    # 设备型号
    model_name: str = Field(min_length=1, max_length=100)
    # 整桩额定功率，单位 kW；必须大于 0，最多三位小数
    rated_power_kw: Decimal = Field(gt=0, max_digits=10, decimal_places=3)
    # 模拟或接入协议名称
    protocol: str = Field(min_length=1, max_length=50)
    # 质保截止日期，可以不填
    warranty_until: date | None = None


class UpdatePileRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    # 以下字段省略表示不修改；前三项不能显式传 null
    # 设备型号
    model_name: str | None = Field(default=None, min_length=1, max_length=100)
    # 整桩额定功率，单位 kW
    rated_power_kw: Decimal | None = Field(default=None, gt=0, max_digits=10, decimal_places=3)
    # 模拟或接入协议名称
    protocol: str | None = Field(default=None, min_length=1, max_length=50)
    # 质保截止日期；显式传 null 表示清空日期
    warranty_until: date | None = None

    @model_validator(mode="after")
    def _validate_changes(self):
        # model_fields_set 只包含请求中实际传入的字段
        if not self.model_fields_set:
            raise ValueError("至少提供一个需要修改的字段")
        for field in self.model_fields_set:
            if field != "warranty_until" and getattr(self, field) is None:
                raise ValueError(f"{field} 不能为 null")
        return self

class GunDetail(BaseModel):
    # 允许读取数据库模型的同名属性
    model_config = ConfigDict(from_attributes=True)

    # 充电枪编号
    gun_id: int
    # 所属充电桩编号
    pile_id: int
    # 桩内枪序号
    gun_no: int
    # 充电类型：dc 直流快充，ac 交流慢充
    gun_type: Literal["dc", "ac"]
    # 接口标准
    connector_standard: str
    # 最大功率，单位 kW
    max_power_kw: Decimal
    # 当前运行状态
    status: Literal["idle", "occupied", "fault", "offline"]
    # 故障事实标记，不因离线而清除
    has_fault: bool
    # UTC 创建时间
    created_at: datetime
    # UTC 最后修改时间
    updated_at: datetime

    @field_serializer("gun_id", "pile_id", when_used="json")
    def _serialize_id(self, value: int) -> str:
        # 编号以字符串输出，避免前端大整数精度丢失
        return str(value)

    @field_serializer("created_at", "updated_at", when_used="json")
    def _serialize_time(self, value: datetime) -> str:
        # 数据库存储 UTC，驱动返回无时区时间时补上 UTC
        if value.tzinfo is None:
            value = value.replace(tzinfo=timezone.utc)
        return value.astimezone(timezone.utc).isoformat(timespec="milliseconds").replace("+00:00", "Z")


class GunQuery(BaseModel):
    # 页码，默认第 1 页
    page: int = Field(default=1, ge=1)
    # 每页数量，默认 20，最大 100
    page_size: int = Field(default=20, ge=1, le=100)
    # 可选查询关键词
    keyword: str | None = None
    # 可选场站筛选；资源范围由 Service 层检查
    station_id: int | None = Field(default=None, gt=0, le=18446744073709551615)
    # 可选充电桩筛选；资源范围由 Service 层检查
    pile_id: int | None = Field(default=None, gt=0, le=18446744073709551615)
    # 可选运行状态
    status: Literal["idle", "occupied", "fault", "offline"] | None = None
    # 开始时间，包含该时刻；输入必须带时区
    start_at: AwareDatetime | None = None
    # 结束时间，不包含该时刻；输入必须带时区
    end_at: AwareDatetime | None = None

    @model_validator(mode="after")
    def _validate_time_range(self):
        # 统一转换为 UTC，并检查起止时间顺序
        if self.start_at is not None:
            self.start_at = self.start_at.astimezone(timezone.utc)
        if self.end_at is not None:
            self.end_at = self.end_at.astimezone(timezone.utc)
        if self.start_at is not None and self.end_at is not None:
            if self.start_at >= self.end_at:
                raise ValueError("开始时间必须早于结束时间")
        return self


class CreateGunRequest(BaseModel):
    # 拒绝多传字段；运行状态和故障事实不在此指定
    model_config = ConfigDict(extra="forbid")

    # 所属充电桩编号；存在性与资源范围由 Service 层检查
    pile_id: int = Field(gt=0, le=18446744073709551615)
    # 桩内枪序号，同一桩内不能重复，由 Service 和数据库检查
    gun_no: int = Field(ge=1, le=65535)
    # 充电类型
    gun_type: Literal["dc", "ac"]
    # 接口标准
    connector_standard: str = Field(min_length=1, max_length=50)
    # 最大功率，最多三位小数；Service 还需检查不超过所属桩额定功率
    max_power_kw: Decimal = Field(gt=0, max_digits=10, decimal_places=3)


class UpdateGunRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    # 字段省略表示不修改，显式 null 不允许
    # 充电类型
    gun_type: Literal["dc", "ac"] | None = None
    # 接口标准
    connector_standard: str | None = Field(default=None, min_length=1, max_length=50)
    # 最大功率，单位 kW；更新时仍需检查所属桩额定功率
    max_power_kw: Decimal | None = Field(default=None, gt=0, max_digits=10, decimal_places=3)

    @model_validator(mode="after")
    def _validate_changes(self):
        # 至少传入一个字段，且所有实际传入的字段都不能为 null
        if not self.model_fields_set:
            raise ValueError("至少提供一个需要修改的字段")
        for field in self.model_fields_set:
            if getattr(self, field) is None:
                raise ValueError(f"{field} 不能为 null")
        return self


class ChangeRequestDetail(BaseModel):
    # 响应白名单不含 before_data、proposed_data 等内部载荷
    model_config = ConfigDict(from_attributes=True)

    # 变更申请编号
    request_id: int
    # 变更目标：桩或者枪，另一个字段为空
    pile_id: int | None
    gun_id: int | None
    # 变更类型
    change_type: Literal["archive", "relocate", "retrofit", "retire"]
    # 申请理由
    reason: str
    # 申请账号
    requested_by: int
    # 审批状态
    status: Literal["pending", "approved", "rejected"]
    # 审批账号、时间和意见，待审批时可为空
    reviewed_by: int | None
    reviewed_at: datetime | None
    review_note: str | None
    # 创建时间和最后修改时间
    created_at: datetime
    updated_at: datetime

    @field_serializer("request_id", "pile_id", "gun_id", "requested_by", "reviewed_by", when_used="json")
    def _serialize_id(self, value: int | None) -> str | None:
        # JSON 中编号使用字符串，可空编号保留 null
        return str(value) if value is not None else None

    @field_serializer("reviewed_at", "created_at", "updated_at", when_used="json")
    def _serialize_time(self, value: datetime | None) -> str | None:
        if value is None:
            return None
        if value.tzinfo is None:
            value = value.replace(tzinfo=timezone.utc)
        return value.astimezone(timezone.utc).isoformat(timespec="milliseconds").replace("+00:00", "Z")


class ChangeRequestQuery(BaseModel):
    # 分页参数
    page: int = Field(default=1, ge=1)
    page_size: int = Field(default=20, ge=1, le=100)
    # 可选关键词和审批状态
    keyword: str | None = None
    status: Literal["pending", "approved", "rejected"] | None = None
    # 时间范围左闭右开，输入必须带时区
    start_at: AwareDatetime | None = None
    end_at: AwareDatetime | None = None

    @model_validator(mode="after")
    def _validate_time_range(self):
        if self.start_at is not None:
            self.start_at = self.start_at.astimezone(timezone.utc)
        if self.end_at is not None:
            self.end_at = self.end_at.astimezone(timezone.utc)
        if self.start_at is not None and self.end_at is not None:
            if self.start_at >= self.end_at:
                raise ValueError("开始时间必须早于结束时间")
        return self


class CreateChangeRequest(BaseModel):
    # 申请人、原始快照和审批结果由服务端生成，拒绝前端多传
    model_config = ConfigDict(extra="forbid")

    # 目标编号二选一
    pile_id: int | None = Field(default=None, gt=0, le=18446744073709551615)
    gun_id: int | None = Field(default=None, gt=0, le=18446744073709551615)
    # 档案、迁移、改造或退役
    change_type: Literal["archive", "relocate", "retrofit", "retire"]
    # JSON 对象只承载拟修改值；具体允许字段及跨表规则由 Service 检查
    proposed_data: dict[str, JsonValue]
    # 申请理由
    reason: str = Field(min_length=1, max_length=500)

    @model_validator(mode="after")
    def _validate_target(self):
        if (self.pile_id is not None) == (self.gun_id is not None):
            raise ValueError("pile_id 和 gun_id 必须且只能填写一个")
        return self


class ReviewChangeRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    # 只能批准或驳回，审批身份和时间不能由前端传入
    decision: Literal["approved", "rejected"]
    # 可选审批意见
    note: str | None = Field(default=None, max_length=500)


class _DeviceResponse(BaseModel):
    """设备响应：读取 ORM 属性，JSON 编号用字符串，时间统一为 UTC。"""
    # 公共父类：后面的 Detail 类继承它，就能复用配置和序列化规则。
    # from_attributes=True 允许 model_validate(数据库对象) 读取对象的同名属性。
    model_config = ConfigDict(from_attributes=True)

    # Pydantic 的序列化装饰器：把响应转为 JSON 时，对所有字段应用此函数。
    # "*" 表示所有字段；check_fields=False 允许处理子类中才定义的字段。
    @field_serializer("*", when_used="json", check_fields=False)
    def _serialize_value(self, value, info):
        # value 是当前字段的值；info.field_name 是当前字段名。
        # 空值保持为 JSON 的 null，不能变成字符串 "None"。
        if value is None:
            return None
        # 编号用字符串输出，避免浏览器 JavaScript 处理大整数时丢失精度。
        if info.field_name.endswith("_id") or info.field_name == "accepted_by":
            return str(value)
        if isinstance(value, datetime):
            # 无时区的数据库时间按 UTC 解释；有时区的时间先转换为 UTC。
            # isoformat() 生成时间字符串；末尾 Z 表示 UTC，例如 2026-11-15T08:00:00Z。
            return value.replace(tzinfo=timezone.utc).isoformat().replace("+00:00", "Z") if value.tzinfo is None else value.astimezone(timezone.utc).isoformat().replace("+00:00", "Z")
        if isinstance(value, Decimal):
            # 精确小数转成字符串，避免转成浮点数后出现精度误差。
            return str(value)
        # 其余字段，例如普通文本和布尔值，保持原值。
        return value

#TODO 设备的列表查询
class _DeviceQuery(BaseModel):
    # 查询条件公共父类；后面的 Query 类会继承这些字段。
    # 页码：默认第 1 页；ge=1 表示必须大于或等于 1。
    page: int = Field(default=1, ge=1)
    # 每页条数：默认 20；le=100 表示最多 100 条。
    page_size: int = Field(default=20, ge=1, le=100)
    # 可选关键词；str | None 表示可以是字符串或空值，不传时默认 None。
    keyword: str | None = None
    # 开始时间，包含该时刻；AwareDatetime 要求输入带时区。
    start_at: AwareDatetime | None = None
    # 结束时间，不包含该时刻；整体范围为 start_at <= 业务时间 < end_at。
    end_at: AwareDatetime | None = None

    # Pydantic 完成各字段校验后，再检查多个字段之间的关系。
    @model_validator(mode="after")
    def _validate_time_range(self):
        # 只有同时提供起止时间时，才比较它们的先后顺序。
        if self.start_at is not None and self.end_at is not None and self.start_at >= self.end_at:
            raise ValueError("开始时间必须早于结束时间")
        # after 校验器必须返回校验后的模型对象。
        return self

#TODO 返回给前端的验收记录
class AcceptanceDetail(_DeviceResponse):
    # 返回给前端的验收详情，继承公共响应序列化规则。
    # 本次验收记录的唯一编号
    acceptance_id: int
    # 被验收的充电桩编号
    pile_id: int
    # 协议联调是否通过；bool 的 True 表示通过，False 表示未通过。
    protocol_test_passed: bool
    # 设备铭牌信息是否核对通过
    nameplate_checked: bool
    # 启动、停止充电测试是否通过
    start_stop_passed: bool
    # 心跳通信测试是否通过
    heartbeat_passed: bool
    # 后端计算的结论：passed 通过，failed 未通过；Literal 限制可选值。
    result: Literal["passed", "failed"]
    # 执行验收的账号编号，由服务端从 actor 中取得
    accepted_by: int
    # 本次验收发生的时间
    accepted_at: datetime
    # 验收备注，可以为空；响应字段没有默认值时仍需提供该字段。
    note: str | None
    # 验收记录创建时间
    created_at: datetime
    # 验收记录最后更新时间
    updated_at: datetime

#TODO 查询时候的筛选条件
class AcceptanceQuery(_DeviceQuery):
    # 验收列表查询条件：自动继承分页、关键词和起止时间。
    # 所属桩过滤，Service 还会检查资源范围
    pile_id: int | None = Field(default=None, gt=0)

#TODO 前端提交的数据 封装到这里面
class CreateAcceptanceRequest(BaseModel):
    # 新增验收的请求体；extra="forbid" 拒绝未定义的字段。
    # 例如前端额外传 result="passed" 会被拒绝，结论必须由后端计算。
    model_config = ConfigDict(extra="forbid")
    # 被验收桩的编号：gt=0 表示大于 0；le 限制为数据库无符号 BIGINT 范围。
    pile_id: int = Field(gt=0, le=18446744073709551615)
    # 协议联调结果；不传时默认 False，防止漏传项目被当成通过。
    protocol_test_passed: bool = False
    # 铭牌核对结果
    nameplate_checked: bool = False
    # 启停测试结果
    start_stop_passed: bool = False
    # 心跳测试结果
    heartbeat_passed: bool = False
    # 可选备注，最长 500 个字符
    note: str | None = Field(default=None, max_length=500)

#TODO 定义返回给前端的设备命令
class DeviceCommandDetail(_DeviceResponse):
    # 返回给前端的命令详情；查询命令不会重新发送命令。
    # 命令记录编号
    command_id: int
    # 命令对应的充电桩编号
    pile_id: int
    # 命令对应的充电枪编号
    gun_id: int
    # 触发该命令的订单编号
    order_id: int
    # 命令类型：start 启动，stop 停止
    command_type: Literal["start", "stop"]
    # 状态：pending 待发送、sent 已发送、succeeded 成功、failed 失败
    status: Literal["pending", "sent", "succeeded", "failed"]
    # 累计发送尝试次数
    attempt_count: int
    # 发送时间；尚未发送时可以为空
    sent_at: datetime | None
    # 收到设备确认的时间；尚未确认时可以为空
    acknowledged_at: datetime | None
    # 失败说明；没有失败信息时可以为空
    error_message: str | None
    # 命令记录创建时间
    created_at: datetime
    # 命令记录最后更新时间
    updated_at: datetime

#TODO 查询设备命令的筛选条件
class DeviceCommandQuery(_DeviceQuery):
    # 命令列表查询条件；不传的条件不会用于过滤。
    # 按充电桩编号筛选，资源范围由 Service 检查
    pile_id: int | None = Field(default=None, gt=0)
    # 按关联订单编号筛选
    order_id: int | None = Field(default=None, gt=0)
    # 按命令状态筛选，例如 pending
    status: str | None = None

#TODO 定义设备状态变化 返回给前端
class DeviceStatusLogDetail(_DeviceResponse):
    # 返回设备状态变化的历史记录，方便追踪何时、因为什么发生变化。
    # 状态历史记录编号
    status_log_id: int
    # 目标桩编号；记录针对枪时，此字段为空。
    pile_id: int | None
    # 目标枪编号；记录针对桩时，此字段为空，与 pile_id 二选一。
    gun_id: int | None
    # 变化前状态；首条状态记录可以没有旧状态。
    # idle 空闲、occupied 占用、fault 故障、offline 离线。
    old_status: Literal["idle", "occupied", "fault", "offline"] | None
    # 变化后的状态
    new_status: Literal["idle", "occupied", "fault", "offline"]
    # 状态变化实际发生的时间
    occurred_at: datetime
    # 变更原因，例如“心跳超时”或“订单开始充电”
    reason: str
    # 操作账号编号；系统任务自动处理时可以为空。
    actor_account_id: int | None
    # 历史记录写入数据库的时间，可能与实际发生时间不同
    created_at: datetime
    # 记录的更新时间字段；本模块不提供修改历史的接口。
    updated_at: datetime

#TODO 查询设备状态历史
class DeviceStatusLogQuery(_DeviceQuery):
    # 按桩或枪筛选历史；同时继承分页、关键词及起止时间。
    # Service 根据目标设备所属场站检查访问范围。
    pile_id: int | None = Field(default=None, gt=0)
    # 可选的目标充电枪编号
    gun_id: int | None = Field(default=None, gt=0)

#TODO 接收密钥并校验过期时间
class IssueDeviceCredentialRequest(BaseModel):
    # 签发凭据的请求体；拒绝前端额外指定令牌、摘要等内部字段。
    model_config = ConfigDict(extra="forbid")
    # 必须带时区，并且晚于当前时间
    expires_at: AwareDatetime

    @model_validator(mode="after")
    def _validate_expiry(self):
        # datetime.now(timezone.utc) 获取当前 UTC 时间。
        # 过期时间在当前或过去时直接拒绝，Service 写库前还会再次检查。
        if self.expires_at <= datetime.now(timezone.utc):
            raise ValueError("凭据过期时间必须晚于当前时间")
        # 返回通过校验的请求对象
        return self

#TODO 定义密钥成功后 返回给前端
class DeviceCredentialIssue(_DeviceResponse):
    # 签发成功的 HTTP 响应；不是数据库表模型。
    # 新生成的凭据记录编号
    credential_id: int
    # 该凭据所属的充电桩编号
    pile_id: int
    # 原始令牌只在签发响应中返回，数据库只存摘要。
    # repr=False 避免打印模型对象时带出令牌；JSON 响应仍会包含它。
    secret_token: str = Field(repr=False)
    # 凭据过期时间，输出时由父类统一转换为 UTC 时间字符串
    expires_at: datetime
