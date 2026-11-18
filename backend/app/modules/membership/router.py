from __future__ import annotations

from datetime import date

from fastapi import APIRouter, Depends, Path
from fastapi.security import HTTPAuthorizationCredentials
from sqlalchemy.orm import Session

from app.core import security
from app.core.database import get_db
from app.modules.assets.router import _bearer, _get_request_actor
from app.modules.membership import service
from app.modules.membership.schemas import (
    AccountQuery,
    AccountStatusRequest,
    AssignRolesRequest,
    AssignScopesRequest,
    BindVehicleRequest,
    CreateAccountRequest,
    CreateFeedbackRequest,
    CreateFleetAuthorizationRequest,
    CreateFleetCardRequest,
    CreateFleetRequest,
    CreatePromotionRequest,
    EmptyRequest,
    FeedbackQuery,
    FleetAuthorizationQuery,
    FleetCardQuery,
    FleetQuery,
    IssueCouponsRequest,
    LoginRequest,
    PageQuery,
    PermissionQuery,
    PromotionQuery,
    RegisterUserRequest,
    ReviewPromotionRequest,
    RoleQuery,
    SetFleetQuotaRequest,
    TopupRequest,
    UpdateFleetAuthorizationRequest,
    UpdateFleetCardRequest,
    UpdateFleetRequest,
    UpdateProfileRequest,
    UpdatePromotionRequest,
    VehicleQuery,
    VerifyUserRequest,
)
from app.shared.contracts import Actor

router = APIRouter()
get_current_actor = _get_request_actor


@router.post("/auth/login", tags=["auth"])
def login(request: LoginRequest, db: Session = Depends(get_db)):
    return service.login(db, actor=None, request=request)


@router.get("/auth/me", tags=["auth"])
def get_current_user(db: Session = Depends(get_db), actor: Actor = Depends(get_current_actor)):
    return service.get_current_user(db, actor=actor)


@router.post("/auth/logout", tags=["auth"])
def logout(request: EmptyRequest, db: Session = Depends(get_db), actor: Actor = Depends(get_current_actor),
           credentials: HTTPAuthorizationCredentials = Depends(_bearer)):
    claims = security._claims(credentials.credentials)
    service.logout(db, actor=actor, request=request, jti=claims["jti"])
    return {"success": True}


@router.post("/membership/users", tags=["membership"])
def register_user(request: RegisterUserRequest, db: Session = Depends(get_db)):
    return service.register_user(db, actor=None, request=request)


@router.get("/membership/profile", tags=["membership"])
def get_profile(db: Session = Depends(get_db), actor: Actor = Depends(get_current_actor)):
    return service.get_profile(db, actor=actor)


@router.patch("/membership/profile", tags=["membership"])
def update_profile(request: UpdateProfileRequest, db: Session = Depends(get_db), actor: Actor = Depends(get_current_actor)):
    return service.update_profile(db, actor=actor, request=request)


@router.post("/membership/users/{user_id}/verifications", tags=["membership"])
def verify_user(user_id: int, request: VerifyUserRequest, db: Session = Depends(get_db), actor: Actor = Depends(get_current_actor)):
    return service.verify_user(db, actor=actor, user_id=user_id, request=request)


@router.get("/membership/vehicles", tags=["membership"])
def list_vehicles(query: VehicleQuery = Depends(), db: Session = Depends(get_db), actor: Actor = Depends(get_current_actor)):
    return service.list_vehicles(db, actor=actor, query=query)


@router.get("/membership/vehicles/{vehicle_id}", tags=["membership"])
def get_vehicle(vehicle_id: int, db: Session = Depends(get_db), actor: Actor = Depends(get_current_actor)):
    return service.get_vehicle(db, actor=actor, vehicle_id=vehicle_id)


@router.post("/membership/vehicle-bindings", tags=["membership"])
def bind_vehicle(request: BindVehicleRequest, db: Session = Depends(get_db), actor: Actor = Depends(get_current_actor)):
    return service.bind_vehicle(db, actor=actor, request=request)


@router.post("/membership/vehicle-bindings/{binding_id}/unbind", tags=["membership"])
def unbind_vehicle(binding_id: int, request: EmptyRequest, db: Session = Depends(get_db), actor: Actor = Depends(get_current_actor)):
    return service.unbind_vehicle(db, actor=actor, binding_id=binding_id, request=request)


@router.get("/membership/promotions", tags=["membership"])
def list_promotions(query: PromotionQuery = Depends(), db: Session = Depends(get_db), actor: Actor = Depends(get_current_actor)):
    return service.list_promotions(db, actor=actor, query=query)


@router.get("/membership/promotions/{promotion_id}", tags=["membership"])
def get_promotion(promotion_id: int, db: Session = Depends(get_db), actor: Actor = Depends(get_current_actor)):
    return service.get_promotion(db, actor=actor, promotion_id=promotion_id)


@router.post("/membership/promotions", tags=["membership"])
def create_promotion(request: CreatePromotionRequest, db: Session = Depends(get_db), actor: Actor = Depends(get_current_actor)):
    return service.create_promotion(db, actor=actor, request=request)


@router.patch("/membership/promotions/{promotion_id}", tags=["membership"])
def update_promotion(promotion_id: int, request: UpdatePromotionRequest, db: Session = Depends(get_db), actor: Actor = Depends(get_current_actor)):
    return service.update_promotion(db, actor=actor, promotion_id=promotion_id, request=request)


@router.post("/membership/promotions/{promotion_id}/reviews", tags=["membership"])
def review_promotion(promotion_id: int, request: ReviewPromotionRequest, db: Session = Depends(get_db), actor: Actor = Depends(get_current_actor)):
    return service.review_promotion(db, actor=actor, promotion_id=promotion_id, request=request)


@router.get("/membership/coupons", tags=["membership"])
def list_coupons(query: PageQuery = Depends(), db: Session = Depends(get_db), actor: Actor = Depends(get_current_actor)):
    return service.list_coupons(db, actor=actor, query=query)


@router.post("/membership/promotions/{promotion_id}/claims", tags=["membership"])
def claim_coupon(promotion_id: int, request: EmptyRequest, db: Session = Depends(get_db), actor: Actor = Depends(get_current_actor)):
    return service.claim_coupon(db, actor=actor, promotion_id=promotion_id, request=request)


@router.post("/membership/promotions/{promotion_id}/issues", tags=["membership"])
def issue_coupons(promotion_id: int, request: IssueCouponsRequest, db: Session = Depends(get_db), actor: Actor = Depends(get_current_actor)):
    return service.issue_coupons(db, actor=actor, promotion_id=promotion_id, request=request)


@router.get("/membership/fleets", tags=["membership"])
def list_fleets(query: FleetQuery = Depends(), db: Session = Depends(get_db), actor: Actor = Depends(get_current_actor)):
    return service.list_fleets(db, actor=actor, query=query)


@router.get("/membership/fleets/{fleet_id}", tags=["membership"])
def get_fleet(fleet_id: int, db: Session = Depends(get_db), actor: Actor = Depends(get_current_actor)):
    return service.get_fleet(db, actor=actor, fleet_id=fleet_id)


@router.post("/membership/fleets", tags=["membership"])
def create_fleet(request: CreateFleetRequest, db: Session = Depends(get_db), actor: Actor = Depends(get_current_actor)):
    return service.create_fleet(db, actor=actor, request=request)


@router.patch("/membership/fleets/{fleet_id}", tags=["membership"])
def update_fleet(fleet_id: int, request: UpdateFleetRequest, db: Session = Depends(get_db), actor: Actor = Depends(get_current_actor)):
    return service.update_fleet(db, actor=actor, fleet_id=fleet_id, request=request)


@router.get("/membership/fleet-cards", tags=["membership"])
def list_fleet_cards(query: FleetCardQuery = Depends(), db: Session = Depends(get_db), actor: Actor = Depends(get_current_actor)):
    return service.list_fleet_cards(db, actor=actor, query=query)


@router.get("/membership/fleet-cards/{card_id}", tags=["membership"])
def get_fleet_card(card_id: int, db: Session = Depends(get_db), actor: Actor = Depends(get_current_actor)):
    return service.get_fleet_card(db, actor=actor, card_id=card_id)


@router.post("/membership/fleet-cards", tags=["membership"])
def create_fleet_card(request: CreateFleetCardRequest, db: Session = Depends(get_db), actor: Actor = Depends(get_current_actor)):
    return service.create_fleet_card(db, actor=actor, request=request)


@router.patch("/membership/fleet-cards/{card_id}", tags=["membership"])
def update_fleet_card(card_id: int, request: UpdateFleetCardRequest, db: Session = Depends(get_db), actor: Actor = Depends(get_current_actor)):
    return service.update_fleet_card(db, actor=actor, card_id=card_id, request=request)


@router.get("/membership/fleet-authorizations", tags=["membership"])
def list_fleet_authorizations(query: FleetAuthorizationQuery = Depends(), db: Session = Depends(get_db), actor: Actor = Depends(get_current_actor)):
    return service.list_fleet_authorizations(db, actor=actor, query=query)


@router.get("/membership/fleet-authorizations/{authorization_id}", tags=["membership"])
def get_fleet_authorization(authorization_id: int, db: Session = Depends(get_db), actor: Actor = Depends(get_current_actor)):
    return service.get_fleet_authorization(db, actor=actor, authorization_id=authorization_id)


@router.post("/membership/fleet-authorizations", tags=["membership"])
def create_fleet_authorization(request: CreateFleetAuthorizationRequest, db: Session = Depends(get_db), actor: Actor = Depends(get_current_actor)):
    return service.create_fleet_authorization(db, actor=actor, request=request)


@router.patch("/membership/fleet-authorizations/{authorization_id}", tags=["membership"])
def update_fleet_authorization(authorization_id: int, request: UpdateFleetAuthorizationRequest, db: Session = Depends(get_db), actor: Actor = Depends(get_current_actor)):
    return service.update_fleet_authorization(db, actor=actor, authorization_id=authorization_id, request=request)


@router.put("/membership/fleet-authorizations/{authorization_id}/quotas/{bill_month}", tags=["membership"])
def set_fleet_quota(
    authorization_id: int,
    request: SetFleetQuotaRequest,
    bill_month: str = Path(description="账期，格式 YYYY-MM"),
    db: Session = Depends(get_db),
    actor: Actor = Depends(get_current_actor),
):
    try:
        parsed_month = date.fromisoformat(f"{bill_month}-01")
    except ValueError as exc:
        from app.core.errors import bad_request
        raise bad_request("invalid_bill_month", "账期格式必须为 YYYY-MM") from exc
    return service.set_fleet_quota(db, actor=actor, authorization_id=authorization_id,
                                   bill_month=parsed_month, request=request)


@router.get("/membership/fleet-authorizations/{authorization_id}/quotas", tags=["membership"])
def list_fleet_quotas(authorization_id: int, query: PageQuery = Depends(), db: Session = Depends(get_db), actor: Actor = Depends(get_current_actor)):
    return service.list_fleet_quotas(db, actor=actor, authorization_id=authorization_id, query=query)


@router.post("/membership/wallet/topups", tags=["membership"])
def mock_topup_wallet(request: TopupRequest, db: Session = Depends(get_db), actor: Actor = Depends(get_current_actor)):
    return service.mock_topup_wallet(db, actor=actor, request=request)


@router.get("/membership/wallet/transactions", tags=["membership"])
def list_wallet_transactions(query: PageQuery = Depends(), db: Session = Depends(get_db), actor: Actor = Depends(get_current_actor)):
    return service.list_wallet_transactions(db, actor=actor, query=query)


@router.get("/membership/feedbacks", tags=["membership"])
def list_feedbacks(query: FeedbackQuery = Depends(), db: Session = Depends(get_db), actor: Actor = Depends(get_current_actor)):
    return service.list_feedbacks(db, actor=actor, query=query)


@router.get("/membership/feedbacks/{feedback_id}", tags=["membership"])
def get_feedback(feedback_id: int, db: Session = Depends(get_db), actor: Actor = Depends(get_current_actor)):
    return service.get_feedback(db, actor=actor, feedback_id=feedback_id)


@router.post("/membership/feedbacks", tags=["membership"])
def create_feedback(request: CreateFeedbackRequest, db: Session = Depends(get_db), actor: Actor = Depends(get_current_actor)):
    return service.create_feedback(db, actor=actor, request=request)


@router.get("/auth/accounts", tags=["auth"])
def list_accounts(query: AccountQuery = Depends(), db: Session = Depends(get_db), actor: Actor = Depends(get_current_actor)):
    return service.list_accounts(db, actor=actor, query=query)


@router.get("/auth/accounts/{account_id}", tags=["auth"])
def get_account(account_id: int, db: Session = Depends(get_db), actor: Actor = Depends(get_current_actor)):
    return service.get_account(db, actor=actor, account_id=account_id)


@router.post("/auth/accounts", tags=["auth"])
def create_account(request: CreateAccountRequest, db: Session = Depends(get_db), actor: Actor = Depends(get_current_actor)):
    return service.create_account(db, actor=actor, request=request)


@router.patch("/auth/accounts/{account_id}/status", tags=["auth"])
def change_account_status(account_id: int, request: AccountStatusRequest, db: Session = Depends(get_db), actor: Actor = Depends(get_current_actor)):
    return service.change_account_status(db, actor=actor, account_id=account_id, request=request)


@router.put("/auth/accounts/{account_id}/roles", tags=["auth"])
def assign_roles(account_id: int, request: AssignRolesRequest, db: Session = Depends(get_db), actor: Actor = Depends(get_current_actor)):
    return service.assign_roles(db, actor=actor, account_id=account_id, request=request)


@router.put("/auth/accounts/{account_id}/scopes", tags=["auth"])
def assign_resource_scopes(account_id: int, request: AssignScopesRequest, db: Session = Depends(get_db), actor: Actor = Depends(get_current_actor)):
    return service.assign_resource_scopes(db, actor=actor, account_id=account_id, request=request)


@router.get("/auth/roles", tags=["auth"])
def list_roles(query: RoleQuery = Depends(), db: Session = Depends(get_db), actor: Actor = Depends(get_current_actor)):
    return service.list_roles(db, actor=actor, query=query)


@router.get("/auth/roles/{role_id}", tags=["auth"])
def get_role(role_id: int, db: Session = Depends(get_db), actor: Actor = Depends(get_current_actor)):
    return service.get_role(db, actor=actor, role_id=role_id)


@router.get("/auth/permissions", tags=["auth"])
def list_permissions(query: PermissionQuery = Depends(), db: Session = Depends(get_db), actor: Actor = Depends(get_current_actor)):
    return service.list_permissions(db, actor=actor, query=query)


@router.get("/auth/permissions/{permission_id}", tags=["auth"])
def get_permission(permission_id: int, db: Session = Depends(get_db), actor: Actor = Depends(get_current_actor)):
    return service.get_permission(db, actor=actor, permission_id=permission_id)
