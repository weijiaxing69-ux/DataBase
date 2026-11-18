"""跨模块 DTO 放在这里；公共签名须遵循 V1.4，不互相导入 Service。"""
from typing import Generic, TypeVar
from dataclasses import dataclass, field
from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class Actor(BaseModel):
    """由服务端认证流程生成的当前用户身份，不作为前端请求数据。"""

    # 身份生成后不可修改，避免业务处理中意外改变权限
    model_config = ConfigDict(frozen=True, extra="forbid")

    # 当前登录账号编号
    account_id: int = Field(gt=0)

    # 关联的车主档案编号；管理账号可以没有车主档案
    user_id: int | None = Field(default=None, gt=0)

    # 角色代码集合，由服务端从数据库加载
    roles: frozenset[str]

    # 权限代码集合，由服务端从数据库加载
    permissions: frozenset[str]

# T 表示列表中每条数据的类型
T = TypeVar("T")


@dataclass(frozen=True)
class GunSnapshot:
    """已鉴权业务之间传递的只读枪快照；active_order_id 来自订单表。"""
    gun_id: int
    pile_id: int
    status: str
    station_id: int
    active_order_id: int | None


@dataclass(frozen=True)
class DeviceCredentialIssue:
    """签发结果只返回一次明文；不在 repr 中显示令牌。"""
    credential_id: int
    pile_id: int
    secret_token: str = field(repr=False)
    expires_at: datetime


@dataclass(frozen=True)
class FleetAuthorizationSnapshot:
    authorization_id: int
    fleet_id: int
    user_id: int
    vehicle_id: int
    card_id: int
    valid_from: str
    valid_until: str


@dataclass(frozen=True)
class FleetQuotaSnapshot:
    authorization_id: int
    order_id: int
    bill_month: str
    limit_amount: str
    reserved_amount: str
    used_amount: str
    remaining_amount: str


class PageResult(BaseModel, Generic[T]):
    # 当前页的数据列表
    items: list[T]

    # 符合条件的总记录数
    total: int

    # 当前页码
    page: int

    # 每页数量
    page_size: int
