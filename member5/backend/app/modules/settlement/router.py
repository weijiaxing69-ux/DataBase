from hashlib import sha256
import json
from typing import Annotated

from fastapi import APIRouter, Depends, Header, Query

from ...core.auth import current_actor
from ...core.database import execute, get_db, one
from ...core.errors import require
from ...core.serialization import wire
from . import schemas, service

router = APIRouter(prefix="/api/v1/settlement", tags=["结算与对账"])
DB = Annotated[object, Depends(get_db)]
Actor = Annotated[dict, Depends(current_actor)]
IdempotencyKey = Annotated[str, Header(alias="Idempotency-Key", min_length=1, max_length=64)]


def write_once(db, actor, key, operation, target, body, status, action):
    request_hash = sha256(json.dumps([target, body.model_dump(mode="json")],
                                     sort_keys=True, ensure_ascii=False).encode()).digest()
    args = dict(actor=actor["account_id"], op=operation, key=key)
    with db.begin():
        execute(db, """INSERT INTO request_dedup(account_id,operation,idempotency_key,request_hash,expires_at)
            VALUES(:actor,:op,:key,:hash,UTC_TIMESTAMP(3)+INTERVAL 1 DAY)
            ON DUPLICATE KEY UPDATE dedup_id=dedup_id""", **args, hash=request_hash)
        record = one(db, """SELECT dedup_id,request_hash,status,response_body FROM request_dedup
            WHERE account_id=:actor AND operation=:op AND idempotency_key=:key FOR UPDATE""", **args)
        require(record["request_hash"] == request_hash, 409, "IDEMPOTENCY_CONFLICT", "同一请求键对应了不同内容。")
        if record["status"] == "completed":
            return json.loads(record["response_body"])
        result = wire(action())
        execute(db, """UPDATE request_dedup SET status='completed',response_status=:status,response_body=:body
            WHERE dedup_id=:id""", status=status, body=json.dumps(result, ensure_ascii=False), id=record["dedup_id"])
        return result


@router.get("/settlements")
def list_settlements(query: Annotated[schemas.SettlementQuery, Query()], db: DB, actor: Actor):
    return wire(service.list_settlements(db, actor=actor, query=query))


@router.get("/settlements/{settlement_id}")
def get_settlement(settlement_id: schemas.Id, db: DB, actor: Actor):
    return wire(service.get_settlement(db, actor=actor, settlement_id=settlement_id))


@router.get("/differences")
def list_differences(query: Annotated[schemas.DifferenceQuery, Query()], db: DB, actor: Actor):
    return wire(service.list_differences(db, actor=actor, query=query))


@router.get("/differences/{difference_id}")
def get_difference(difference_id: schemas.Id, db: DB, actor: Actor):
    return wire(service.get_difference(db, actor=actor, difference_id=difference_id))


@router.post("/differences", status_code=201)
def create_difference(body: schemas.CreateDifferenceRequest, db: DB, actor: Actor, key: IdempotencyKey):
    return write_once(db, actor, key, "create_difference", None, body, 201,
                      lambda: service.create_difference(db, actor=actor, request=body))


@router.get("/operator-invoices")
def list_operator_invoices(query: Annotated[schemas.OperatorInvoiceQuery, Query()], db: DB, actor: Actor):
    return wire(service.list_operator_invoices(db, actor=actor, query=query))


@router.get("/operator-invoices/{invoice_id}")
def get_operator_invoice(invoice_id: schemas.Id, db: DB, actor: Actor):
    return wire(service.get_operator_invoice(db, actor=actor, invoice_id=invoice_id))


@router.get("/user-invoices")
def list_user_invoices(query: Annotated[schemas.UserInvoiceQuery, Query()], db: DB, actor: Actor):
    return wire(service.list_user_invoices(db, actor=actor, query=query))


@router.get("/user-invoices/{user_invoice_id}")
def get_user_invoice(user_invoice_id: schemas.Id, db: DB, actor: Actor):
    return wire(service.get_user_invoice(db, actor=actor, user_invoice_id=user_invoice_id))


@router.get("/fleet-bills")
def list_fleet_bills(query: Annotated[schemas.FleetBillQuery, Query()], db: DB, actor: Actor):
    return wire(service.list_fleet_bills(db, actor=actor, query=query))


@router.get("/fleet-bills/{bill_id}")
def get_fleet_bill(bill_id: schemas.Id, db: DB, actor: Actor):
    return wire(service.get_fleet_bill(db, actor=actor, bill_id=bill_id))


@router.get("/fleet-prices")
def list_fleet_prices(query: Annotated[schemas.FleetPriceQuery, Query()], db: DB, actor: Actor):
    return wire(service.list_fleet_prices(db, actor=actor, query=query))


@router.get("/fleet-prices/{price_id}")
def get_fleet_price(price_id: schemas.Id, db: DB, actor: Actor):
    return wire(service.get_fleet_price(db, actor=actor, price_id=price_id))


@router.post("/fleet-prices", status_code=201)
def create_fleet_price(body: schemas.CreateFleetPriceRequest, db: DB, actor: Actor, key: IdempotencyKey):
    return write_once(db, actor, key, "create_fleet_price", None, body, 201,
                      lambda: service.create_fleet_price(db, actor=actor, request=body))


@router.get("/policies")
def list_settlement_policies(query: Annotated[schemas.SettlementPolicyQuery, Query()], db: DB, actor: Actor):
    return wire(service.list_settlement_policies(db, actor=actor, query=query))


@router.get("/policies/{policy_id}")
def get_settlement_policy(policy_id: schemas.Id, db: DB, actor: Actor):
    return wire(service.get_settlement_policy(db, actor=actor, policy_id=policy_id))


@router.post("/policies", status_code=201)
def create_settlement_policy(body: schemas.CreateSettlementPolicyRequest, db: DB, actor: Actor, key: IdempotencyKey):
    return write_once(db, actor, key, "create_settlement_policy", None, body, 201,
                      lambda: service.create_settlement_policy(db, actor=actor, request=body))


@router.post("/settlements", status_code=201)
def generate_settlement(body: schemas.GenerateSettlementRequest, db: DB, actor: Actor, key: IdempotencyKey):
    return write_once(db, actor, key, "generate_settlement", None, body, 201,
                      lambda: service.generate_settlement(db, actor=actor, request=body))


@router.post("/settlements/{settlement_id}/confirmations")
def confirm_settlement(settlement_id: schemas.Id, body: schemas.ConfirmationRequest, db: DB, actor: Actor, key: IdempotencyKey):
    return write_once(db, actor, key, "confirm_settlement", settlement_id, body, 200,
                      lambda: service.confirm_settlement(db, actor=actor, settlement_id=settlement_id, request=body))


@router.post("/settlements/{settlement_id}/adjustments", status_code=201)
def adjust_settlement(settlement_id: schemas.Id, body: schemas.AdjustSettlementRequest, db: DB, actor: Actor, key: IdempotencyKey):
    return write_once(db, actor, key, "adjust_settlement", settlement_id, body, 201,
                      lambda: service.adjust_settlement(db, actor=actor, settlement_id=settlement_id, request=body))


@router.post("/adjustments/{adjustment_id}/reviews")
def review_settlement_adjustment(adjustment_id: schemas.Id, body: schemas.AdjustmentReviewRequest, db: DB, actor: Actor, key: IdempotencyKey):
    return write_once(db, actor, key, "review_settlement_adjustment", adjustment_id, body, 200,
                      lambda: service.review_settlement_adjustment(db, actor=actor, adjustment_id=adjustment_id, request=body))


@router.post("/differences/{difference_id}/resolutions")
def resolve_difference(difference_id: schemas.Id, body: schemas.ResolveDifferenceRequest, db: DB, actor: Actor, key: IdempotencyKey):
    return write_once(db, actor, key, "resolve_difference", difference_id, body, 200,
                      lambda: service.resolve_difference(db, actor=actor, difference_id=difference_id, request=body))


@router.post("/differences/{difference_id}/confirmations")
def confirm_difference(difference_id: schemas.Id, body: schemas.ConfirmationRequest, db: DB, actor: Actor, key: IdempotencyKey):
    return write_once(db, actor, key, "confirm_difference", difference_id, body, 200,
                      lambda: service.confirm_difference(db, actor=actor, difference_id=difference_id, request=body))


@router.post("/settlements/{settlement_id}/invoices", status_code=201)
def issue_operator_invoice(settlement_id: schemas.Id, body: schemas.IssueOperatorInvoiceRequest, db: DB, actor: Actor, key: IdempotencyKey):
    return write_once(db, actor, key, "issue_operator_invoice", settlement_id, body, 201,
                      lambda: service.issue_operator_invoice(db, actor=actor, settlement_id=settlement_id, request=body))


@router.post("/operator-invoices/{invoice_id}/red-issues")
def red_issue_operator_invoice(invoice_id: schemas.Id, body: schemas.RedIssueInvoiceRequest, db: DB, actor: Actor, key: IdempotencyKey):
    return write_once(db, actor, key, "red_issue_operator_invoice", invoice_id, body, 200,
                      lambda: service.red_issue_operator_invoice(db, actor=actor, invoice_id=invoice_id, request=body))


@router.post("/user-invoices", status_code=201)
def request_user_invoice(body: schemas.RequestUserInvoiceRequest, db: DB, actor: Actor, key: IdempotencyKey):
    return write_once(db, actor, key, "request_user_invoice", None, body, 201,
                      lambda: service.request_user_invoice(db, actor=actor, request=body))


@router.post("/user-invoices/{user_invoice_id}/processing")
def process_user_invoice(user_invoice_id: schemas.Id, body: schemas.ProcessUserInvoiceRequest, db: DB, actor: Actor, key: IdempotencyKey):
    return write_once(db, actor, key, "process_user_invoice", user_invoice_id, body, 200,
                      lambda: service.process_user_invoice(db, actor=actor, user_invoice_id=user_invoice_id, request=body))


@router.post("/user-invoices/{user_invoice_id}/red-issues")
def red_issue_user_invoice(user_invoice_id: schemas.Id, body: schemas.RedIssueInvoiceRequest, db: DB, actor: Actor, key: IdempotencyKey):
    return write_once(db, actor, key, "red_issue_user_invoice", user_invoice_id, body, 200,
                      lambda: service.red_issue_user_invoice(db, actor=actor, user_invoice_id=user_invoice_id, request=body))


@router.post("/fleet-bills", status_code=201)
def generate_fleet_bill(body: schemas.GenerateFleetBillRequest, db: DB, actor: Actor, key: IdempotencyKey):
    return write_once(db, actor, key, "generate_fleet_bill", None, body, 201,
                      lambda: service.generate_fleet_bill(db, actor=actor, request=body))


@router.post("/fleet-bills/{bill_id}/payments", status_code=201)
def record_fleet_bill_payment(bill_id: schemas.Id, body: schemas.FleetBillPaymentRequest, db: DB, actor: Actor, key: IdempotencyKey):
    return write_once(db, actor, key, "record_fleet_bill_payment", bill_id, body, 201,
                      lambda: service.record_fleet_bill_payment(db, actor=actor, bill_id=bill_id, request=body))
