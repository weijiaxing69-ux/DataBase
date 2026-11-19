from __future__ import annotations

from datetime import UTC, date, datetime
from decimal import Decimal
from typing import Any, Generic, TypeVar

from pydantic import BaseModel, ConfigDict, Field, field_validator

T = TypeVar("T")


def _utc_naive(value: datetime) -> datetime:
    if value.tzinfo is None:
        value = value.replace(tzinfo=UTC)
    return value.astimezone(UTC).replace(tzinfo=None)


class APIModel(BaseModel):
    model_config = ConfigDict(from_attributes=True, extra="forbid")


class PageQuery(APIModel):
    page: int = Field(default=1, ge=1)
    page_size: int = Field(default=20, ge=1, le=100)
    keyword: str | None = None
    start_at: datetime | None = None
    end_at: datetime | None = None


class PageResult(BaseModel, Generic[T]):
    items: list[T]
    total: int
    page: int
    page_size: int


class EmptyRequest(APIModel):
    pass


class LoginRequest(APIModel):
    username: str = Field(min_length=1, max_length=64)
    password: str = Field(min_length=1, max_length=256)


class RegisterUserRequest(APIModel):
    username: str = Field(min_length=3, max_length=64)
    password: str = Field(min_length=10, max_length=256)
    display_name: str = Field(min_length=1, max_length=50)
    phone: str = Field(min_length=7, max_length=20)


class UpdateProfileRequest(APIModel):
    display_name: str | None = Field(default=None, min_length=1, max_length=50)
    phone: str | None = Field(default=None, min_length=7, max_length=20)


class VerifyUserRequest(APIModel):
    real_name_status: str = Field(pattern="^(verified|rejected)$")
    note: str = Field(min_length=1, max_length=500)


class VehicleQuery(PageQuery):
    user_id: int | None = None
    fleet_id: int | None = None


class BindVehicleRequest(APIModel):
    vehicle_id: int | None = None
    plate: str | None = None
    model_name: str | None = Field(default=None, max_length=100)
    battery_capacity_kwh: Decimal | None = Field(default=None, gt=0)
    max_charging_power_kw: Decimal | None = Field(default=None, gt=0)
    supports_fast_charge: bool = False


class PromotionQuery(PageQuery):
    status: str | None = None


class CreatePromotionRequest(APIModel):
    promotion_name: str = Field(min_length=1, max_length=100)
    face_amount: Decimal = Field(gt=0)
    minimum_spend: Decimal = Field(default=Decimal("0.00"), ge=0)
    valid_from: datetime
    valid_until: datetime
    issue_limit: int = Field(gt=0)
    per_user_limit: int = Field(default=1, gt=0)
    all_stations: bool = False
    redemption_rule: str = Field(default="个人订单满额抵扣", max_length=500)
    station_ids: list[int] = Field(default_factory=list)

    @field_validator("valid_until")
    @classmethod
    def until_after_from(cls, value: datetime, info):
        start = info.data.get("valid_from")
        if start and _utc_naive(value) <= _utc_naive(start):
            raise ValueError("valid_until must be later than valid_from")
        return value


class UpdatePromotionRequest(APIModel):
    promotion_name: str | None = Field(default=None, min_length=1, max_length=100)
    redemption_rule: str | None = Field(default=None, max_length=500)


class ReviewPromotionRequest(APIModel):
    decision: str = Field(pattern="^(approved|rejected)$")
    note: str | None = Field(default=None, max_length=500)


class IssueCouponsRequest(APIModel):
    user_ids: list[int] = Field(min_length=1, max_length=500)
    reason: str = Field(min_length=1, max_length=500)


class FleetQuery(PageQuery):
    pass


class CreateFleetRequest(APIModel):
    company_name: str = Field(min_length=1, max_length=100)
    credit_code: str = Field(min_length=1, max_length=18)
    contact_name: str = Field(min_length=1, max_length=50)
    contact_phone: str = Field(min_length=7, max_length=20)


class UpdateFleetRequest(APIModel):
    company_name: str | None = Field(default=None, min_length=1, max_length=100)
    contact_name: str | None = Field(default=None, min_length=1, max_length=50)
    contact_phone: str | None = Field(default=None, min_length=7, max_length=20)
    status: str | None = Field(default=None, pattern="^(active|disabled)$")


class FleetCardQuery(PageQuery):
    fleet_id: int | None = None
    status: str | None = None


class CreateFleetCardRequest(APIModel):
    fleet_id: int
    card_no: str = Field(min_length=1, max_length=64)
    valid_from: datetime
    valid_until: datetime


class UpdateFleetCardRequest(APIModel):
    status: str | None = Field(default=None, pattern="^(active|suspended|expired)$")
    valid_until: datetime | None = None


class FleetAuthorizationQuery(PageQuery):
    fleet_id: int | None = None
    user_id: int | None = None
    status: str | None = None


class CreateFleetAuthorizationRequest(APIModel):
    card_id: int
    user_id: int
    vehicle_id: int
    default_monthly_limit: Decimal = Field(ge=0)
    valid_from: datetime
    valid_until: datetime


class UpdateFleetAuthorizationRequest(APIModel):
    status: str | None = Field(default=None, pattern="^(active|suspended|expired)$")
    valid_until: datetime | None = None
    default_monthly_limit: Decimal | None = Field(default=None, ge=0)


class SetFleetQuotaRequest(APIModel):
    limit_amount: Decimal = Field(ge=0)


class TopupRequest(APIModel):
    amount: Decimal = Field(gt=0, max_digits=14, decimal_places=2)


class WalletBalanceRefundRequest(APIModel):
    amount: Decimal = Field(gt=0, max_digits=14, decimal_places=2)
    reason: str = Field(min_length=3, max_length=500)
    request_key: str = Field(min_length=12, max_length=80, pattern=r"^[A-Za-z0-9_-]+$")


class ReviewWalletBalanceRefundRequest(APIModel):
    decision: str = Field(pattern="^(processing|approved|rejected)$")
    note: str | None = Field(default=None, max_length=500)


class WalletBalanceRefundQuery(PageQuery):
    status: str | None = Field(default=None, pattern="^(pending_review|processing|completed|rejected)$")


class FeedbackQuery(PageQuery):
    order_id: int | None = None


class CreateFeedbackRequest(APIModel):
    order_id: int
    rating: int = Field(ge=1, le=5)
    content: str | None = Field(default=None, max_length=1000)


class AppealQuery(PageQuery):
    status: str | None = Field(default=None, pattern="^(submitted|processing|resolved|rejected)$")
    category: str | None = Field(default=None, pattern="^(billing_dispute|charging_service|account_coupon|other)$")


class CreateAppealRequest(APIModel):
    category: str = Field(pattern="^(billing_dispute|charging_service|account_coupon|other)$")
    order_id: int | None = Field(default=None, gt=0)
    subject: str = Field(min_length=3, max_length=120)
    description: str = Field(min_length=5, max_length=2000)
    request_key: str = Field(min_length=12, max_length=80, pattern=r"^[A-Za-z0-9_-]+$")


class HandleAppealRequest(APIModel):
    status: str = Field(pattern="^(processing|resolved|rejected)$")
    message: str = Field(min_length=2, max_length=1000)


class AccountQuery(PageQuery):
    pass


class CreateAccountRequest(APIModel):
    username: str = Field(min_length=3, max_length=64)
    password: str = Field(min_length=10, max_length=256)
    role_codes: list[str] = Field(min_length=1)


class AccountStatusRequest(APIModel):
    status: str = Field(pattern="^(active|disabled)$")


class AssignRolesRequest(APIModel):
    role_codes: list[str] = Field(min_length=1)


class AssignScopesRequest(APIModel):
    operator_ids: list[int] = Field(default_factory=list)
    station_ids: list[int] = Field(default_factory=list)
    fleet_ids: list[int] = Field(default_factory=list)


class RoleQuery(PageQuery):
    pass


class PermissionQuery(PageQuery):
    pass


class AccountContext(BaseModel):
    account_id: int
    user_id: int | None = None
    roles: list[str]
    permissions: list[str]
    home_path: str


class LoginResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    expires_in: int
    account: AccountContext


class UserDetail(BaseModel):
    user_id: int
    account_id: int | None = None
    display_name: str
    real_name_status: str
    registration_channel: str
    registered_at: datetime
    member_level: str
    balance: Decimal
    status: str
    phone_masked: str


class VehicleDetail(BaseModel):
    vehicle_id: int
    model_name: str
    battery_capacity_kwh: Decimal
    max_charging_power_kw: Decimal
    supports_fast_charge: bool
    status: str
    plate_masked: str


class PromotionDetail(BaseModel):
    promotion_id: int
    promotion_name: str
    face_amount: Decimal
    minimum_spend: Decimal
    valid_from: datetime
    valid_until: datetime
    issue_limit: int
    issued_count: int
    per_user_limit: int
    all_stations: bool
    redemption_rule: str
    status: str


class CouponDetail(BaseModel):
    coupon_id: int
    promotion_id: int
    user_id: int
    received_at: datetime
    expires_at: datetime
    face_amount_snapshot: Decimal
    minimum_spend_snapshot: Decimal
    status: str


class FleetDetail(BaseModel):
    fleet_id: int
    company_name: str
    credit_code: str
    contact_name: str
    phone_masked: str
    status: str


class FleetAuthorizationDetail(BaseModel):
    authorization_id: int
    card_id: int
    user_id: int
    vehicle_id: int
    default_monthly_limit: Decimal
    valid_from: datetime
    valid_until: datetime
    status: str


class WalletTransactionDetail(BaseModel):
    wallet_transaction_id: int
    user_id: int
    transaction_type: str
    amount: Decimal
    balance_after: Decimal
    business_key: str
    occurred_at: datetime


class FeedbackDetail(BaseModel):
    feedback_id: int
    order_id: int
    user_id: int
    rating: int
    content: str | None = None
    created_at: datetime


class AccountDetail(BaseModel):
    account_id: int
    username: str
    status: str
    failed_attempts: int
    locked_until: datetime | None = None
    last_login_at: datetime | None = None


class RoleDetail(BaseModel):
    role_id: int
    role_code: str
    role_name: str


class PermissionDetail(BaseModel):
    permission_id: int
    permission_code: str
    permission_name: str


class GenericDetail(BaseModel):
    data: dict[str, Any]


class FleetMonthQuotaDetail(BaseModel):
    quota_month_id: int
    authorization_id: int
    bill_month: date
    limit_amount: Decimal
    reserved_amount: Decimal
    used_amount: Decimal
