from datetime import date, datetime
from decimal import Decimal
from typing import Annotated, Literal

from pydantic import BaseModel, ConfigDict, Field


class RequestBody(BaseModel):
    model_config = ConfigDict(extra="forbid", str_strip_whitespace=True)


class GenerateSettlementRequest(RequestBody):
    operator_id: int = Field(gt=0, le=2**64-1)
    station_id: int = Field(gt=0, le=2**64-1)
    bill_month: date


class ConfirmationRequest(RequestBody):
    object_version: int = Field(gt=0, le=2**32-1)
    decision: Literal["confirmed", "disputed"]
    note: str | None = Field(default=None, max_length=1000)


class IssueOperatorInvoiceRequest(RequestBody):
    title: str = Field(min_length=1, max_length=100)
    tax_no: str = Field(min_length=1, max_length=30)
    amount: Decimal = Field(gt=0, max_digits=14, decimal_places=2)


class RedIssueInvoiceRequest(RequestBody):
    amount: Decimal = Field(gt=0, max_digits=14, decimal_places=2)
    reason: str = Field(min_length=1, max_length=500)


Id = Annotated[int, Field(gt=0, le=2**64-1)]
Money = Annotated[Decimal, Field(max_digits=14, decimal_places=2)]
PositiveMoney = Annotated[Money, Field(gt=0)]
Rate = Annotated[Decimal, Field(ge=0, le=1, max_digits=7, decimal_places=6)]
Price = Annotated[Decimal, Field(ge=0, max_digits=12, decimal_places=4)]
Note = Annotated[str, Field(min_length=1, max_length=1000)]


class PageQuery(BaseModel):
    page: int = Field(1, ge=1, le=1000000)
    page_size: int = Field(20, ge=1, le=100)
    keyword: str | None = Field(None, max_length=100)
    start_at: datetime | None = None
    end_at: datetime | None = None


class SettlementPolicyQuery(PageQuery):
    operator_id: Id | None = None
    station_id: Id | None = None


class SettlementQuery(SettlementPolicyQuery):
    bill_month: date | None = None
    status: str | None = None


class OperatorInvoiceQuery(PageQuery):
    settlement_id: Id | None = None


class DifferenceQuery(OperatorInvoiceQuery):
    status: str | None = None


class AdjustmentQuery(DifferenceQuery):
    pass


class AuditQuery(PageQuery):
    object_type: Literal["settlement", "difference", "adjustment", "operator_invoice", "user_invoice"]
    object_id: Id


class UserInvoiceQuery(PageQuery):
    user_id: Id | None = None
    status: str | None = None


class FleetBillQuery(PageQuery):
    fleet_id: Id | None = None
    bill_month: date | None = None
    status: str | None = None


class FleetPriceQuery(PageQuery):
    fleet_id: Id | None = None
    period_id: Id | None = None


class CreateDifferenceRequest(RequestBody):
    settlement_id: Id
    order_id: Id
    difference_type: Literal["energy", "price", "payment"]
    amount: Money


class ResolveDifferenceRequest(RequestBody):
    object_version: int = Field(gt=0, le=2**32-1)
    resolution: Note | None = None


class AdjustSettlementRequest(RequestBody):
    difference_id: Id | None = None
    amount: Money
    reason: Note


class AdjustmentReviewRequest(RequestBody):
    decision: Literal["approved", "rejected"]
    note: Note


class CreateSettlementPolicyRequest(RequestBody):
    operator_id: Id
    station_id: Id
    electricity_share_rate: Rate
    service_share_rate: Rate
    platform_fee_rate: Rate
    payment_basis: Literal["paid_only"]
    valid_from: datetime
    valid_until: datetime


class UserInvoiceAllocation(RequestBody):
    order_id: Id
    allocated_amount: PositiveMoney


class RequestUserInvoiceRequest(RequestBody):
    title: Annotated[str, Field(min_length=1, max_length=100)]
    tax_no: Annotated[str, Field(min_length=1, max_length=30)] | None = None
    items: list[UserInvoiceAllocation] = Field(min_length=1, max_length=100)


class ProcessUserInvoiceRequest(RequestBody):
    decision: Literal["issued", "rejected"]
    note: Note | None = None


class GenerateFleetBillRequest(RequestBody):
    fleet_id: Id
    bill_month: date


class FleetBillPaymentRequest(RequestBody):
    external_trade_no: Annotated[str, Field(min_length=1, max_length=80)]
    amount: Annotated[Money, Field(ge=0)]


class CreateFleetPriceRequest(RequestBody):
    fleet_id: Id
    period_id: Id
    electricity_rate: Price
    service_rate: Price
    valid_from: datetime
    valid_until: datetime
