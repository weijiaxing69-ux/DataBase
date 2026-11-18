from __future__ import annotations

import hashlib
import uuid
from datetime import UTC, date, datetime, timedelta
from decimal import Decimal

from sqlalchemy.exc import IntegrityError, OperationalError
from sqlalchemy.orm import Session

from app.core import security
from app.core.config import settings
from app.core.errors import BusinessError, conflict, forbidden, not_found, unauthorized
from app.core.permissions import require_permission, require_role
from app.core.pii import (
    decrypt_text,
    encrypt_text,
    keyed_digest,
    mask_plate,
    mask_phone,
    normalize_phone,
    normalize_plate,
)
from app.modules.membership.dao import (
    inserted_id,
    many,
    one,
    page_result,
    run,
    transaction,
    to_utc_naive,
    utc_now_naive,
)
from app.modules.membership.schemas import (
    AccountContext,
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
    FeedbackQuery,
    FleetAuthorizationQuery,
    FleetCardQuery,
    FleetQuery,
    IssueCouponsRequest,
    LoginRequest,
    LoginResponse,
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
from app.shared.contracts import Actor, FleetAuthorizationSnapshot, FleetQuotaSnapshot


def _safe_phone(value: str) -> str:
    try:
        return normalize_phone(value)
    except ValueError as exc:
        raise BusinessError(422, "invalid_phone", "手机号格式不正确") from exc


def _safe_plate(value: str) -> str:
    try:
        return normalize_plate(value)
    except ValueError as exc:
        raise BusinessError(422, "invalid_plate", "车牌格式不正确") from exc


def _account_context(db: Session, account_id: int, user_id: int | None) -> AccountContext:
    roles = many(
        db,
        """SELECT r.role_code FROM sys_account_role ar
             JOIN sys_role r ON r.role_id = ar.role_id
            WHERE ar.account_id = :account_id ORDER BY r.role_code""",
        {"account_id": account_id},
    )
    permissions = many(
        db,
        """SELECT DISTINCT p.permission_code
             FROM sys_account_role ar
             JOIN sys_role_permission rp ON rp.role_id = ar.role_id
             JOIN sys_permission p ON p.permission_id = rp.permission_id
            WHERE ar.account_id = :account_id ORDER BY p.permission_code""",
        {"account_id": account_id},
    )
    role_codes = [row["role_code"] for row in roles]
    home_path = "/membership/profile"
    if "platform_admin" in role_codes:
        home_path = "/auth/accounts"
    elif "fleet_admin" in role_codes:
        home_path = "/membership/fleets"
    return AccountContext(
        account_id=account_id,
        user_id=user_id,
        roles=role_codes,
        permissions=[row["permission_code"] for row in permissions],
        home_path=home_path,
    )


def _user_id(actor: Actor) -> int:
    if actor.user_id is None:
        raise forbidden("user_profile_required", "账号没有关联车主档案")
    return actor.user_id


def _user_detail(row: dict) -> dict:
    raw = row.get("phone_cipher")
    phone = decrypt_text(bytes(raw), settings.phone_fernet_key) if raw else ""
    return {
        "user_id": int(row["user_id"]),
        "account_id": int(row["account_id"]) if row.get("account_id") is not None else None,
        "display_name": row["display_name"],
        "real_name_status": row["real_name_status"],
        "registration_channel": row["registration_channel"],
        "registered_at": row["registered_at"],
        "member_level": row["member_level"],
        "balance": row["balance"],
        "status": row["status"],
        "phone_masked": mask_phone(phone),
    }


def _vehicle_detail(row: dict) -> dict:
    raw = row.get("plate_cipher")
    plate = decrypt_text(bytes(raw), settings.plate_fernet_key) if raw else ""
    return {
        "vehicle_id": int(row["vehicle_id"]),
        "model_name": row["model_name"],
        "battery_capacity_kwh": row["battery_capacity_kwh"],
        "max_charging_power_kw": row["max_charging_power_kw"],
        "supports_fast_charge": bool(row["supports_fast_charge"]),
        "status": row["status"],
        "plate_masked": mask_plate(plate),
    }


def _fleet_detail(row: dict) -> dict:
    raw = row.get("contact_phone_cipher")
    phone = decrypt_text(bytes(raw), settings.phone_fernet_key) if raw else ""
    return {
        "fleet_id": int(row["fleet_id"]),
        "company_name": row["company_name"],
        "credit_code": row["credit_code"],
        "contact_name": row["contact_name"],
        "phone_masked": mask_phone(phone),
        "status": row["status"],
    }


def _require_self_or_permission(actor: Actor, user_id: int, permission: str) -> None:
    if actor.user_id == user_id:
        return
    require_permission(actor, permission)


def _fleet_in_scope(db: Session, actor: Actor, fleet_id: int) -> bool:
    if "platform_admin" in actor.roles:
        return True
    if "fleet_admin" not in actor.roles:
        return False
    return one(
        db,
        "SELECT 1 AS ok FROM sys_account_fleet WHERE account_id = :account_id AND fleet_id = :fleet_id",
        {"account_id": actor.account_id, "fleet_id": fleet_id},
    ) is not None


def _assert_fleet_scope(db: Session, actor: Actor, fleet_id: int, permission: str) -> None:
    if "fleet_admin" in actor.roles and "platform_admin" not in actor.roles:
        if _fleet_in_scope(db, actor, fleet_id):
            return
        raise forbidden("fleet_out_of_scope", "当前账号未获该车队的数据范围")
    require_permission(actor, permission)


def _role_rows_for_codes(db: Session, role_codes: list[str]) -> list[dict]:
    codes = sorted(set(role_codes))
    placeholders = ", ".join(f":role_{index}" for index in range(len(codes)))
    params = {f"role_{index}": code for index, code in enumerate(codes)}
    return many(db, f"SELECT role_id, role_code FROM sys_role WHERE role_code IN ({placeholders})", params)


def login(db: Session, *, actor: Actor | None, request: LoginRequest) -> LoginResponse:
    # Keep JWT, lockout, Argon2 seed compatibility and session ownership in the shared auth layer.
    token, lifetime, current = security.login_with_password(db, request.username, request.password)
    return LoginResponse(
        access_token=token,
        token_type="bearer",
        expires_in=lifetime,
        account=_account_context(db, current.account_id, current.user_id),
    )


def get_current_user(db: Session, *, actor: Actor) -> AccountContext:
    return _account_context(db, actor.account_id, actor.user_id)


def logout(db: Session, *, actor: Actor, request, jti: str | None = None) -> None:
    if not jti:
        raise unauthorized()
    with transaction(db):
        run(
            db,
            "UPDATE sys_session SET revoked_at = UTC_TIMESTAMP(3) WHERE account_id = :account_id AND jti_hash = :jti_hash AND revoked_at IS NULL",
            {"account_id": actor.account_id, "jti_hash": hashlib.sha256(jti.encode("ascii")).digest()},
        )


def register_user(db: Session, *, actor: Actor | None, request: RegisterUserRequest) -> dict:
    now = utc_now_naive()
    try:
        normalized_phone = _safe_phone(request.phone)
        with transaction(db):
            account_id = inserted_id(run(
                db,
                "INSERT INTO sys_account (username, password_hash) VALUES (:username, :password_hash)",
                {"username": request.username, "password_hash": security.hash_password(request.password)},
            ))
            user_id = inserted_id(run(
                db,
                """INSERT INTO app_user
                    (account_id, display_name, phone_cipher, phone_hash, registered_at)
                    VALUES (:account_id, :display_name, :phone_cipher, :phone_hash, :registered_at)""",
                {"account_id": account_id, "display_name": request.display_name.strip(),
                 "phone_cipher": encrypt_text(normalized_phone, settings.phone_fernet_key),
                 "phone_hash": keyed_digest(normalized_phone, settings.phone_hmac_key),
                 "registered_at": now},
            ))
            role = one(db, "SELECT role_id FROM sys_role WHERE role_code = 'vehicle_owner'")
            if role is None:
                raise RuntimeError("vehicle_owner role is missing from the fixed role registry")
            run(db, "INSERT INTO sys_account_role (account_id, role_id) VALUES (:account_id, :role_id)",
                {"account_id": account_id, "role_id": role["role_id"]})
            row = one(db, "SELECT * FROM app_user WHERE user_id = :user_id", {"user_id": user_id})
            result = _user_detail(row)
    except IntegrityError as exc:
        raise conflict("duplicate_user", "登录名或手机号已被注册") from exc
    return result


def get_profile(db: Session, *, actor: Actor) -> dict:
    user_id = _user_id(actor)
    require_permission(actor, "membership.profile.read")
    row = one(db, "SELECT * FROM app_user WHERE user_id = :user_id", {"user_id": user_id})
    if row is None:
        raise not_found("user_not_found", "车主档案不存在")
    return _user_detail(row)


def update_profile(db: Session, *, actor: Actor, request: UpdateProfileRequest) -> dict:
    user_id = _user_id(actor)
    require_permission(actor, "membership.profile.update")
    changes = request.model_dump(exclude_unset=True)
    if not changes:
        return get_profile(db, actor=actor)
    values: dict[str, object] = {"user_id": user_id}
    assignments: list[str] = []
    if "display_name" in changes and changes["display_name"] is not None:
        assignments.append("display_name = :display_name")
        values["display_name"] = changes["display_name"].strip()
    if "phone" in changes and changes["phone"] is not None:
        normalized = _safe_phone(changes["phone"])
        assignments.extend(["phone_cipher = :phone_cipher", "phone_hash = :phone_hash"])
        values["phone_cipher"] = encrypt_text(normalized, settings.phone_fernet_key)
        values["phone_hash"] = keyed_digest(normalized, settings.phone_hmac_key)
    if not assignments:
        return get_profile(db, actor=actor)
    try:
        with transaction(db):
            run(db, f"UPDATE app_user SET {', '.join(assignments)} WHERE user_id = :user_id", values)
            row = one(db, "SELECT * FROM app_user WHERE user_id = :user_id", {"user_id": user_id})
            if row is None:
                raise not_found("user_not_found", "车主档案不存在")
            result = _user_detail(row)
    except IntegrityError as exc:
        raise conflict("duplicate_phone", "手机号已绑定其他账号") from exc
    return result


def verify_user(db: Session, *, actor: Actor, user_id: int, request: VerifyUserRequest) -> dict:
    require_permission(actor, "membership.user.verify")
    with transaction(db):
        row = one(db, "SELECT * FROM app_user WHERE user_id = :user_id FOR UPDATE", {"user_id": user_id})
        if row is None:
            raise not_found("user_not_found", "车主档案不存在")
        run(db, "UPDATE app_user SET real_name_status = :status WHERE user_id = :user_id",
            {"status": request.real_name_status, "user_id": user_id})
        updated = one(db, "SELECT * FROM app_user WHERE user_id = :user_id", {"user_id": user_id})
        return _user_detail(updated)


def _vehicle_access_predicate(actor: Actor, alias: str = "v") -> tuple[str, dict[str, object]]:
    if actor.user_id is not None and "vehicle_owner" in actor.roles:
        return (
            f"EXISTS (SELECT 1 FROM vehicle_binding vb WHERE vb.vehicle_id = {alias}.vehicle_id AND vb.user_id = :owner_user_id AND vb.unbound_at IS NULL)",
            {"owner_user_id": actor.user_id},
        )
    if "fleet_admin" in actor.roles and "platform_admin" not in actor.roles:
        return (
            f"EXISTS (SELECT 1 FROM fleet_authorization fa JOIN fleet_card fc ON fc.card_id = fa.card_id JOIN fleet f ON f.fleet_id=fc.fleet_id JOIN sys_account_fleet af ON af.fleet_id = fc.fleet_id WHERE fa.vehicle_id = {alias}.vehicle_id AND af.account_id = :account_id AND fa.status = 'active' AND fc.status = 'active' AND f.status='active' AND fa.valid_from<=UTC_TIMESTAMP(3) AND fa.valid_until>UTC_TIMESTAMP(3) AND fc.valid_from<=UTC_TIMESTAMP(3) AND fc.valid_until>UTC_TIMESTAMP(3))",
            {"account_id": actor.account_id},
        )
    require_permission(actor, "membership.vehicle.read")
    return "1 = 1", {}


def list_vehicles(db: Session, *, actor: Actor, query: VehicleQuery) -> dict:
    require_permission(actor, "membership.vehicle.read")
    access, access_params = _vehicle_access_predicate(actor)
    filters = [access]
    params: dict[str, object] = dict(access_params)
    if query.user_id is not None and "vehicle_owner" in actor.roles and query.user_id != actor.user_id:
        raise forbidden()
    if query.user_id is not None and "vehicle_owner" not in actor.roles:
        _require_self_or_permission(actor, query.user_id, "membership.user.read")
        filters.append("EXISTS (SELECT 1 FROM vehicle_binding vb2 WHERE vb2.vehicle_id=v.vehicle_id AND vb2.user_id=:user_id AND vb2.unbound_at IS NULL)")
        params["user_id"] = query.user_id
    if query.keyword:
        filters.append("v.model_name LIKE :keyword")
        params["keyword"] = f"%{query.keyword.strip()}%"
    where = " AND ".join(filters)
    result = page_result(
        db,
        count_sql=f"SELECT COUNT(*) AS total FROM vehicle v WHERE {where}",
        rows_sql=f"SELECT v.* FROM vehicle v WHERE {where} ORDER BY v.vehicle_id DESC LIMIT :limit OFFSET :offset",
        params=params,
        page=query.page,
        page_size=query.page_size,
    )
    result["items"] = [_vehicle_detail(row) for row in result["items"]]
    return result


def get_vehicle(db: Session, *, actor: Actor, vehicle_id: int) -> dict:
    require_permission(actor, "membership.vehicle.read")
    access, params = _vehicle_access_predicate(actor)
    row = one(db, f"SELECT v.* FROM vehicle v WHERE v.vehicle_id = :vehicle_id AND {access}",
              {**params, "vehicle_id": vehicle_id})
    if row is None:
        raise not_found("vehicle_not_found", "车辆不存在或无权查看")
    return _vehicle_detail(row)


def bind_vehicle(db: Session, *, actor: Actor, request: BindVehicleRequest) -> dict:
    require_permission(actor, "membership.vehicle.manage")
    user_id = _user_id(actor)
    now = utc_now_naive()
    try:
        with transaction(db):
            if request.vehicle_id is None:
                if not all([request.plate, request.model_name, request.battery_capacity_kwh, request.max_charging_power_kw]):
                    raise BusinessError(422, "vehicle_fields_required", "新车辆需要车牌、车型、电池容量和最大充电功率")
                plate = _safe_plate(request.plate or "")
                vehicle_id = inserted_id(run(
                    db,
                    """INSERT INTO vehicle
                        (plate_cipher, plate_hash, model_name, battery_capacity_kwh,
                         max_charging_power_kw, supports_fast_charge)
                        VALUES (:plate_cipher, :plate_hash, :model_name, :battery_capacity_kwh,
                                :max_charging_power_kw, :supports_fast_charge)""",
                    {"plate_cipher": encrypt_text(plate, settings.plate_fernet_key),
                     "plate_hash": keyed_digest(plate, settings.plate_hmac_key),
                     "model_name": request.model_name.strip(),
                     "battery_capacity_kwh": request.battery_capacity_kwh,
                     "max_charging_power_kw": request.max_charging_power_kw,
                     "supports_fast_charge": int(request.supports_fast_charge)},
                ))
            else:
                vehicle_id = request.vehicle_id
                if one(db, "SELECT vehicle_id FROM vehicle WHERE vehicle_id = :vehicle_id AND status = 'active' FOR UPDATE",
                       {"vehicle_id": vehicle_id}) is None:
                    raise not_found("vehicle_not_found", "车辆不存在或不可用")
            if one(db, "SELECT binding_id FROM vehicle_binding WHERE vehicle_id=:vehicle_id AND unbound_at IS NULL FOR UPDATE",
                   {"vehicle_id": vehicle_id}):
                raise conflict("vehicle_already_bound", "车辆已归属其他用户")
            binding_id = inserted_id(run(
                db,
                "INSERT INTO vehicle_binding (user_id, vehicle_id, bound_at) VALUES (:user_id, :vehicle_id, :bound_at)",
                {"user_id": user_id, "vehicle_id": vehicle_id, "bound_at": now},
            ))
            result = one(db, "SELECT * FROM vehicle_binding WHERE binding_id = :binding_id", {"binding_id": binding_id})
    except IntegrityError as exc:
        raise conflict("vehicle_already_bound", "车辆已绑定或车牌已登记") from exc
    return result


def unbind_vehicle(db: Session, *, actor: Actor, binding_id: int, request) -> dict:
    require_permission(actor, "membership.vehicle.manage")
    user_id = _user_id(actor)
    with transaction(db):
        binding = one(
            db,
            "SELECT * FROM vehicle_binding WHERE binding_id = :binding_id AND user_id = :user_id AND unbound_at IS NULL FOR UPDATE",
            {"binding_id": binding_id, "user_id": user_id},
        )
        if binding is None:
            raise not_found("binding_not_found", "有效车辆绑定不存在")
        order = one(
            db,
            "SELECT order_id FROM charging_order WHERE vehicle_id = :vehicle_id AND status = 'charging' LIMIT 1 FOR UPDATE",
            {"vehicle_id": binding["vehicle_id"]},
        )
        if order is not None:
            raise conflict("vehicle_in_active_order", "车辆存在进行中的充电订单，暂不能解绑")
        run(db, "UPDATE vehicle_binding SET unbound_at = :now WHERE binding_id = :binding_id",
            {"now": utc_now_naive(), "binding_id": binding_id})
        return one(db, "SELECT * FROM vehicle_binding WHERE binding_id = :binding_id", {"binding_id": binding_id})


def _coupon_proc(db: Session, promotion_id: int, user_id: int, quantity: int, now: datetime) -> None:
    raw_connection = db.connection().connection
    cursor = raw_connection.cursor()
    try:
        cursor.callproc("sp_issue_promotion_coupons", [promotion_id, user_id, quantity, now])
        while cursor.nextset():
            pass
    except Exception as exc:
        error_no = exc.args[0] if getattr(exc, "args", None) else None
        if error_no == 1644:
            raise conflict("coupon_not_claimable", str(exc.args[1])) from exc
        raise
    finally:
        cursor.close()


def _promotion_detail(row: dict) -> dict:
    return {
        "promotion_id": int(row["promotion_id"]),
        "promotion_name": row["promotion_name"],
        "face_amount": row["face_amount"],
        "minimum_spend": row["minimum_spend"],
        "valid_from": row["valid_from"],
        "valid_until": row["valid_until"],
        "issue_limit": int(row["issue_limit"]),
        "issued_count": int(row["issued_count"]),
        "per_user_limit": int(row["per_user_limit"]),
        "all_stations": bool(row["all_stations"]),
        "redemption_rule": row["redemption_rule"],
        "status": row["status"],
    }


def _coupon_detail(row: dict) -> dict:
    return {key: row[key] for key in (
        "coupon_id", "promotion_id", "user_id", "received_at", "expires_at",
        "face_amount_snapshot", "minimum_spend_snapshot", "status",
    )}


def list_promotions(db: Session, *, actor: Actor, query: PromotionQuery) -> dict:
    owner_view = "vehicle_owner" in actor.roles
    if owner_view:
        require_permission(actor, "membership.promotion.read")
    else:
        require_permission(actor, "membership.promotion.read")
    filters = ["1=1"]
    params: dict[str, object] = {}
    if owner_view:
        filters.extend(["p.status = 'active'", "p.valid_from <= UTC_TIMESTAMP(3)", "p.valid_until > UTC_TIMESTAMP(3)"])
    elif query.status:
        filters.append("p.status = :status")
        params["status"] = query.status
    if query.keyword:
        filters.append("p.promotion_name LIKE :keyword")
        params["keyword"] = f"%{query.keyword.strip()}%"
    where = " AND ".join(filters)
    result = page_result(
        db,
        count_sql=f"SELECT COUNT(*) AS total FROM promotion p WHERE {where}",
        rows_sql=f"SELECT p.* FROM promotion p WHERE {where} ORDER BY p.promotion_id DESC LIMIT :limit OFFSET :offset",
        params=params, page=query.page, page_size=query.page_size,
    )
    result["items"] = [_promotion_detail(row) for row in result["items"]]
    return result


def get_promotion(db: Session, *, actor: Actor, promotion_id: int) -> dict:
    require_permission(actor, "membership.promotion.read")
    row = one(db, "SELECT * FROM promotion WHERE promotion_id = :promotion_id", {"promotion_id": promotion_id})
    if row is None or ("vehicle_owner" in actor.roles and row["status"] != "active"):
        raise not_found("promotion_not_found", "活动不存在或当前不可见")
    return _promotion_detail(row)


def create_promotion(db: Session, *, actor: Actor, request: CreatePromotionRequest) -> dict:
    require_permission(actor, "membership.promotion.manage")
    station_ids = sorted(set(request.station_ids))
    if not request.all_stations and not station_ids:
        raise BusinessError(422, "promotion_stations_required", "非全场站活动至少需要指定一个适用场站")
    now = utc_now_naive()
    with transaction(db):
        promotion_id = inserted_id(run(
            db,
            """INSERT INTO promotion
                (promotion_name, face_amount, minimum_spend, valid_from, valid_until,
                 issue_limit, per_user_limit, all_stations, redemption_rule, status, created_by)
                VALUES (:name, :face, :minimum, :valid_from, :valid_until,
                        :issue_limit, :per_user, :all_stations, :rule, 'pending_review', :created_by)""",
            {"name": request.promotion_name.strip(), "face": request.face_amount,
             "minimum": request.minimum_spend, "valid_from": to_utc_naive(request.valid_from),
             "valid_until": to_utc_naive(request.valid_until), "issue_limit": request.issue_limit,
             "per_user": request.per_user_limit, "all_stations": int(request.all_stations),
             "rule": request.redemption_rule, "created_by": actor.account_id},
        ))
        if not request.all_stations:
            for station_id in station_ids:
                run(db, "INSERT INTO promotion_station (promotion_id, station_id) VALUES (:promotion_id, :station_id)",
                    {"promotion_id": promotion_id, "station_id": station_id})
        row = one(db, "SELECT * FROM promotion WHERE promotion_id = :promotion_id", {"promotion_id": promotion_id})
        return _promotion_detail(row)


def update_promotion(db: Session, *, actor: Actor, promotion_id: int, request: UpdatePromotionRequest) -> dict:
    require_permission(actor, "membership.promotion.manage")
    changes = request.model_dump(exclude_unset=True)
    allowed = {k: v for k, v in changes.items() if v is not None}
    with transaction(db):
        row = one(db, "SELECT * FROM promotion WHERE promotion_id = :promotion_id FOR UPDATE", {"promotion_id": promotion_id})
        if row is None:
            raise not_found("promotion_not_found", "活动不存在")
        if row["status"] not in {"draft", "pending_review", "rejected"}:
            raise conflict("promotion_immutable", "已审核启用的活动不能原地修改，请创建新活动版本")
        if row["created_by"] != actor.account_id and "platform_admin" not in actor.roles:
            raise forbidden()
        if allowed:
            assignments = ", ".join(f"{field} = :{field}" for field in allowed)
            run(db, f"UPDATE promotion SET {assignments}, status='pending_review' WHERE promotion_id=:promotion_id",
                {**allowed, "promotion_id": promotion_id})
        updated = one(db, "SELECT * FROM promotion WHERE promotion_id = :promotion_id", {"promotion_id": promotion_id})
        return _promotion_detail(updated)


def review_promotion(db: Session, *, actor: Actor, promotion_id: int, request: ReviewPromotionRequest) -> dict:
    require_permission(actor, "membership.promotion.review")
    with transaction(db):
        row = one(db, "SELECT * FROM promotion WHERE promotion_id = :promotion_id FOR UPDATE", {"promotion_id": promotion_id})
        if row is None:
            raise not_found("promotion_not_found", "活动不存在")
        if row["status"] != "pending_review":
            raise conflict("promotion_not_pending", "只有待审核活动可以审核")
        if int(row["created_by"]) == actor.account_id:
            raise forbidden("self_review", "活动创建人不能审核自己的活动")
        status = "active" if request.decision == "approved" else "rejected"
        run(db,
            """UPDATE promotion SET status=:status, reviewed_by=:reviewed_by,
                      reviewed_at=UTC_TIMESTAMP(3), review_note=:note
                WHERE promotion_id=:promotion_id""",
            {"status": status, "reviewed_by": actor.account_id, "note": request.note,
             "promotion_id": promotion_id})
        return _promotion_detail(one(db, "SELECT * FROM promotion WHERE promotion_id=:promotion_id",
                                     {"promotion_id": promotion_id}))


def list_coupons(db: Session, *, actor: Actor, query: PageQuery) -> dict:
    if "vehicle_owner" in actor.roles:
        require_permission(actor, "membership.coupon.read")
        filters = ["uc.user_id=:user_id"]
        params: dict[str, object] = {"user_id": _user_id(actor)}
    else:
        require_permission(actor, "membership.coupon.read")
        filters, params = ["1=1"], {}
    if query.keyword:
        filters.append("p.promotion_name LIKE :keyword")
        params["keyword"] = f"%{query.keyword.strip()}%"
    where = " AND ".join(filters)
    result = page_result(
        db,
        count_sql=f"SELECT COUNT(*) AS total FROM user_coupon uc JOIN promotion p ON p.promotion_id=uc.promotion_id WHERE {where}",
        rows_sql=f"SELECT uc.* FROM user_coupon uc JOIN promotion p ON p.promotion_id=uc.promotion_id WHERE {where} ORDER BY uc.coupon_id DESC LIMIT :limit OFFSET :offset",
        params=params, page=query.page, page_size=query.page_size,
    )
    result["items"] = [_coupon_detail(row) for row in result["items"]]
    return result


def claim_coupon(db: Session, *, actor: Actor, promotion_id: int, request) -> dict:
    require_permission(actor, "membership.coupon.claim")
    user_id = _user_id(actor)
    now = utc_now_naive()
    try:
        with transaction(db):
            _coupon_proc(db, promotion_id, user_id, 1, now)
            row = one(db,
                "SELECT * FROM user_coupon WHERE promotion_id=:promotion_id AND user_id=:user_id ORDER BY coupon_id DESC LIMIT 1 FOR UPDATE",
                {"promotion_id": promotion_id, "user_id": user_id})
            if row is None:
                raise RuntimeError("coupon issue procedure returned without inserting a coupon")
            return _coupon_detail(row)
    except IntegrityError as exc:
        raise conflict("coupon_limit", "优惠券已领取或活动库存不足") from exc


def issue_coupons(db: Session, *, actor: Actor, promotion_id: int, request: IssueCouponsRequest) -> list[dict]:
    require_permission(actor, "membership.coupon.issue")
    now = utc_now_naive()
    issued: list[dict] = []
    with transaction(db):
        for user_id in sorted(set(request.user_ids)):
            _coupon_proc(db, promotion_id, user_id, 1, now)
            row = one(db,
                "SELECT * FROM user_coupon WHERE promotion_id=:promotion_id AND user_id=:user_id ORDER BY coupon_id DESC LIMIT 1 FOR UPDATE",
                {"promotion_id": promotion_id, "user_id": user_id})
            if row:
                issued.append(_coupon_detail(row))
    return issued


def _fleet_table_row(db: Session, fleet_id: int, *, lock: bool = False) -> dict:
    row = one(db, f"SELECT * FROM fleet WHERE fleet_id=:fleet_id{' FOR UPDATE' if lock else ''}",
              {"fleet_id": fleet_id})
    if row is None:
        raise not_found("fleet_not_found", "车队不存在")
    return row


def list_fleets(db: Session, *, actor: Actor, query: FleetQuery) -> dict:
    require_permission(actor, "membership.fleet.read")
    filters = ["1=1"]
    params: dict[str, object] = {}
    join = ""
    if "fleet_admin" in actor.roles and "platform_admin" not in actor.roles:
        join = "JOIN sys_account_fleet af ON af.fleet_id=f.fleet_id"
        filters.append("af.account_id=:account_id")
        params["account_id"] = actor.account_id
    if query.keyword:
        filters.append("(f.company_name LIKE :keyword OR f.credit_code LIKE :keyword)")
        params["keyword"] = f"%{query.keyword.strip()}%"
    where = " AND ".join(filters)
    result = page_result(
        db,
        count_sql=f"SELECT COUNT(DISTINCT f.fleet_id) AS total FROM fleet f {join} WHERE {where}",
        rows_sql=f"SELECT DISTINCT f.* FROM fleet f {join} WHERE {where} ORDER BY f.fleet_id DESC LIMIT :limit OFFSET :offset",
        params=params, page=query.page, page_size=query.page_size,
    )
    result["items"] = [_fleet_detail(row) for row in result["items"]]
    return result


def get_fleet(db: Session, *, actor: Actor, fleet_id: int) -> dict:
    _assert_fleet_scope(db, actor, fleet_id, "membership.fleet.read")
    return _fleet_detail(_fleet_table_row(db, fleet_id))


def create_fleet(db: Session, *, actor: Actor, request: CreateFleetRequest) -> dict:
    require_permission(actor, "membership.fleet.manage")
    phone = _safe_phone(request.contact_phone)
    try:
        with transaction(db):
            fleet_id = inserted_id(run(
                db,
                """INSERT INTO fleet (company_name, credit_code, contact_name, contact_phone_cipher)
                    VALUES (:company_name, :credit_code, :contact_name, :phone_cipher)""",
                {"company_name": request.company_name.strip(), "credit_code": request.credit_code.strip().upper(),
                 "contact_name": request.contact_name.strip(),
                 "phone_cipher": encrypt_text(phone, settings.phone_fernet_key)},
            ))
            if "fleet_admin" in actor.roles and "platform_admin" not in actor.roles:
                run(db, "INSERT INTO sys_account_fleet (account_id, fleet_id) VALUES (:account_id, :fleet_id)",
                    {"account_id": actor.account_id, "fleet_id": fleet_id})
            return _fleet_detail(_fleet_table_row(db, fleet_id))
    except IntegrityError as exc:
        raise conflict("duplicate_fleet", "统一社会信用代码已登记") from exc


def update_fleet(db: Session, *, actor: Actor, fleet_id: int, request: UpdateFleetRequest) -> dict:
    _assert_fleet_scope(db, actor, fleet_id, "membership.fleet.manage")
    changes = request.model_dump(exclude_unset=True)
    values: dict[str, object] = {"fleet_id": fleet_id}
    assignments: list[str] = []
    for key in ("company_name", "contact_name", "status"):
        if changes.get(key) is not None:
            assignments.append(f"{key} = :{key}")
            values[key] = changes[key]
    if changes.get("contact_phone"):
        phone = _safe_phone(changes["contact_phone"])
        assignments.append("contact_phone_cipher = :phone_cipher")
        values["phone_cipher"] = encrypt_text(phone, settings.phone_fernet_key)
    with transaction(db):
        _fleet_table_row(db, fleet_id, lock=True)
        if assignments:
            run(db, f"UPDATE fleet SET {', '.join(assignments)} WHERE fleet_id=:fleet_id", values)
        return _fleet_detail(_fleet_table_row(db, fleet_id))


def _card_fleet_id(db: Session, card_id: int) -> int:
    row = one(db, "SELECT fleet_id FROM fleet_card WHERE card_id=:card_id", {"card_id": card_id})
    if row is None:
        raise not_found("fleet_card_not_found", "车队卡不存在")
    return int(row["fleet_id"])


def list_fleet_cards(db: Session, *, actor: Actor, query: FleetCardQuery) -> dict:
    require_permission(actor, "membership.fleet_card.read")
    filters = ["1=1"]
    params: dict[str, object] = {}
    join = ""
    if "fleet_admin" in actor.roles and "platform_admin" not in actor.roles:
        join = "JOIN sys_account_fleet af ON af.fleet_id=fc.fleet_id"
        filters.append("af.account_id=:account_id")
        params["account_id"] = actor.account_id
    if query.fleet_id is not None:
        _assert_fleet_scope(db, actor, query.fleet_id, "membership.fleet_card.read")
        filters.append("fc.fleet_id=:fleet_id")
        params["fleet_id"] = query.fleet_id
    if query.status:
        filters.append("fc.status=:status")
        params["status"] = query.status
    if query.keyword:
        filters.append("fc.card_no LIKE :keyword")
        params["keyword"] = f"%{query.keyword.strip()}%"
    where = " AND ".join(filters)
    return page_result(
        db,
        count_sql=f"SELECT COUNT(DISTINCT fc.card_id) AS total FROM fleet_card fc {join} WHERE {where}",
        rows_sql=f"SELECT DISTINCT fc.* FROM fleet_card fc {join} WHERE {where} ORDER BY fc.card_id DESC LIMIT :limit OFFSET :offset",
        params=params, page=query.page, page_size=query.page_size,
    )


def get_fleet_card(db: Session, *, actor: Actor, card_id: int) -> dict:
    fleet_id = _card_fleet_id(db, card_id)
    _assert_fleet_scope(db, actor, fleet_id, "membership.fleet_card.read")
    row = one(db, "SELECT * FROM fleet_card WHERE card_id=:card_id", {"card_id": card_id})
    return row


def create_fleet_card(db: Session, *, actor: Actor, request: CreateFleetCardRequest) -> dict:
    _assert_fleet_scope(db, actor, request.fleet_id, "membership.fleet_card.manage")
    if to_utc_naive(request.valid_until) <= to_utc_naive(request.valid_from):
        raise BusinessError(422, "invalid_card_period", "车队卡有效期必须结束于开始时间之后")
    try:
        with transaction(db):
            _fleet_table_row(db, request.fleet_id, lock=True)
            card_id = inserted_id(run(
                db,
                """INSERT INTO fleet_card (fleet_id, card_no, issued_at, valid_from, valid_until)
                    VALUES (:fleet_id, :card_no, :issued_at, :valid_from, :valid_until)""",
                {"fleet_id": request.fleet_id, "card_no": request.card_no.strip(),
                 "issued_at": utc_now_naive(), "valid_from": to_utc_naive(request.valid_from),
                 "valid_until": to_utc_naive(request.valid_until)},
            ))
            return one(db, "SELECT * FROM fleet_card WHERE card_id=:card_id", {"card_id": card_id})
    except IntegrityError as exc:
        raise conflict("duplicate_card_no", "车队卡号已存在") from exc


def update_fleet_card(db: Session, *, actor: Actor, card_id: int, request: UpdateFleetCardRequest) -> dict:
    fleet_id = _card_fleet_id(db, card_id)
    _assert_fleet_scope(db, actor, fleet_id, "membership.fleet_card.manage")
    changes = request.model_dump(exclude_unset=True)
    assignments: list[str] = []
    values: dict[str, object] = {"card_id": card_id}
    for key in ("status", "valid_until"):
        if changes.get(key) is not None:
            assignments.append(f"{key} = :{key}")
            values[key] = to_utc_naive(changes[key]) if key == "valid_until" else changes[key]
    with transaction(db):
        card = one(db, "SELECT * FROM fleet_card WHERE card_id=:card_id FOR UPDATE", {"card_id": card_id})
        if card is None:
            raise not_found("fleet_card_not_found", "车队卡不存在")
        effective_until = to_utc_naive(changes["valid_until"]) if changes.get("valid_until") else card["valid_until"]
        if effective_until <= card["valid_from"]:
            raise BusinessError(422, "invalid_card_period", "车队卡有效期必须结束于开始时间之后")
        if assignments:
            run(db, f"UPDATE fleet_card SET {', '.join(assignments)} WHERE card_id=:card_id", values)
        return one(db, "SELECT * FROM fleet_card WHERE card_id=:card_id", {"card_id": card_id})


def list_fleet_authorizations(db: Session, *, actor: Actor, query: FleetAuthorizationQuery) -> dict:
    filters = ["1=1"]
    params: dict[str, object] = {}
    join = "JOIN fleet_card fc ON fc.card_id=fa.card_id"
    owner_view = "vehicle_owner" in actor.roles and actor.user_id is not None
    if owner_view:
        if query.user_id is not None and query.user_id != actor.user_id:
            raise forbidden()
        filters.append("fa.user_id=:owner_user_id")
        params["owner_user_id"] = actor.user_id
    else:
        require_permission(actor, "membership.fleet_authorization.read")
    if "fleet_admin" in actor.roles and "platform_admin" not in actor.roles:
        join += " JOIN sys_account_fleet af ON af.fleet_id=fc.fleet_id"
        filters.append("af.account_id=:account_id")
        params["account_id"] = actor.account_id
    if query.fleet_id is not None:
        _assert_fleet_scope(db, actor, query.fleet_id, "membership.fleet_authorization.read")
        filters.append("fc.fleet_id=:fleet_id")
        params["fleet_id"] = query.fleet_id
    if query.user_id is not None and not owner_view:
        _require_self_or_permission(actor, query.user_id, "membership.user.read")
        filters.append("fa.user_id=:user_id")
        params["user_id"] = query.user_id
    if query.status:
        filters.append("fa.status=:status")
        params["status"] = query.status
    if query.keyword:
        filters.append("CAST(fa.authorization_id AS CHAR) LIKE :keyword")
        params["keyword"] = f"%{query.keyword.strip()}%"
    where = " AND ".join(filters)
    return page_result(
        db,
        count_sql=f"SELECT COUNT(DISTINCT fa.authorization_id) AS total FROM fleet_authorization fa {join} WHERE {where}",
        rows_sql=f"SELECT DISTINCT fa.* FROM fleet_authorization fa {join} WHERE {where} ORDER BY fa.authorization_id DESC LIMIT :limit OFFSET :offset",
        params=params, page=query.page, page_size=query.page_size,
    )


def get_fleet_authorization(db: Session, *, actor: Actor, authorization_id: int) -> dict:
    row = one(db, "SELECT fa.*, fc.fleet_id FROM fleet_authorization fa JOIN fleet_card fc ON fc.card_id=fa.card_id WHERE fa.authorization_id=:id",
              {"id": authorization_id})
    if row is None:
        raise not_found("authorization_not_found", "车队授权不存在")
    if actor.user_id != int(row["user_id"]):
        _assert_fleet_scope(db, actor, int(row["fleet_id"]), "membership.fleet_authorization.read")
    return {k: v for k, v in row.items() if k != "fleet_id"}


def create_fleet_authorization(db: Session, *, actor: Actor, request: CreateFleetAuthorizationRequest) -> dict:
    card = one(db, "SELECT * FROM fleet_card WHERE card_id=:card_id", {"card_id": request.card_id})
    if card is None:
        raise not_found("fleet_card_not_found", "车队卡不存在")
    _assert_fleet_scope(db, actor, int(card["fleet_id"]), "membership.fleet_authorization.manage")
    valid_from = to_utc_naive(request.valid_from)
    valid_until = to_utc_naive(request.valid_until)
    if valid_until <= valid_from:
        raise BusinessError(422, "invalid_authorization_period", "授权有效期必须结束于开始时间之后")
    try:
        with transaction(db):
            card = one(db, "SELECT * FROM fleet_card WHERE card_id=:card_id FOR UPDATE", {"card_id": request.card_id})
            fleet = one(db, "SELECT status FROM fleet WHERE fleet_id=:fleet_id FOR UPDATE", {"fleet_id": card["fleet_id"]})
            if card["status"] != "active" or fleet is None or fleet["status"] != "active":
                raise conflict("card_inactive", "车队卡未启用")
            if valid_from < card["valid_from"] or valid_until > card["valid_until"]:
                raise conflict("authorization_outside_card_period", "授权有效期必须落在车队卡有效期内")
            user = one(db, "SELECT status FROM app_user WHERE user_id=:id FOR UPDATE", {"id": request.user_id})
            vehicle = one(db, "SELECT status FROM vehicle WHERE vehicle_id=:id FOR UPDATE", {"id": request.vehicle_id})
            if user is None or user["status"] != "active" or vehicle is None or vehicle["status"] != "active":
                raise conflict("fleet_subject_inactive", "用车人或车辆不存在或不可用")
            binding = one(db, "SELECT binding_id FROM vehicle_binding WHERE vehicle_id=:vehicle_id AND user_id=:user_id AND unbound_at IS NULL FOR UPDATE",
                          {"vehicle_id": request.vehicle_id, "user_id": request.user_id})
            if binding is None:
                raise conflict("vehicle_user_mismatch", "授权车辆当前未绑定给该用车人")
            authorization_id = inserted_id(run(
                db,
                """INSERT INTO fleet_authorization
                    (card_id, user_id, vehicle_id, default_monthly_limit, valid_from, valid_until)
                    VALUES (:card_id, :user_id, :vehicle_id, :limit_amount, :valid_from, :valid_until)""",
                {"card_id": request.card_id, "user_id": request.user_id, "vehicle_id": request.vehicle_id,
                 "limit_amount": request.default_monthly_limit, "valid_from": valid_from,
                 "valid_until": valid_until},
            ))
            return one(db, "SELECT * FROM fleet_authorization WHERE authorization_id=:id", {"id": authorization_id})
    except IntegrityError as exc:
        raise conflict("authorization_conflict", "相同授权记录已存在或输入违反唯一约束") from exc


def update_fleet_authorization(db: Session, *, actor: Actor, authorization_id: int,
                               request: UpdateFleetAuthorizationRequest) -> dict:
    row = get_fleet_authorization(db, actor=actor, authorization_id=authorization_id)
    card = one(db, "SELECT fleet_id FROM fleet_card WHERE card_id=:card_id", {"card_id": row["card_id"]})
    _assert_fleet_scope(db, actor, int(card["fleet_id"]), "membership.fleet_authorization.manage")
    changes = request.model_dump(exclude_unset=True)
    assignments: list[str] = []
    values: dict[str, object] = {"authorization_id": authorization_id}
    for key in ("status", "valid_until", "default_monthly_limit"):
        if changes.get(key) is not None:
            assignments.append(f"{key} = :{key}")
            value = changes[key]
            values[key] = to_utc_naive(value) if key == "valid_until" else value
    with transaction(db):
        current = one(db, "SELECT * FROM fleet_authorization WHERE authorization_id=:id FOR UPDATE", {"id": authorization_id})
        if current is None:
            raise not_found("authorization_not_found", "车队授权不存在")
        valid_until = to_utc_naive(changes["valid_until"]) if changes.get("valid_until") else current["valid_until"]
        if valid_until <= current["valid_from"]:
            raise BusinessError(422, "invalid_authorization_period", "授权有效期必须结束于开始时间之后")
        card_period = one(db, "SELECT valid_from, valid_until FROM fleet_card WHERE card_id=:id FOR UPDATE",
                          {"id": current["card_id"]})
        if current["valid_from"] < card_period["valid_from"] or valid_until > card_period["valid_until"]:
            raise conflict("authorization_outside_card_period", "授权有效期必须落在车队卡有效期内")
        if assignments:
            run(db, f"UPDATE fleet_authorization SET {', '.join(assignments)} WHERE authorization_id=:authorization_id", values)
        return one(db, "SELECT * FROM fleet_authorization WHERE authorization_id=:id", {"id": authorization_id})


def set_fleet_quota(db: Session, *, actor: Actor, authorization_id: int, bill_month: date,
                    request: SetFleetQuotaRequest) -> dict:
    if bill_month.day != 1:
        raise BusinessError(422, "invalid_bill_month", "账期必须使用当月首日")
    authorization = get_fleet_authorization(db, actor=actor, authorization_id=authorization_id)
    card = one(db, "SELECT fleet_id FROM fleet_card WHERE card_id=:card_id", {"card_id": authorization["card_id"]})
    _assert_fleet_scope(db, actor, int(card["fleet_id"]), "membership.fleet_quota.manage")
    with transaction(db):
        row = _ensure_quota_month(db, authorization_id, bill_month)
        quota_id = int(row["quota_month_id"])
        if request.limit_amount < Decimal(row["reserved_amount"]) + Decimal(row["used_amount"]):
            raise conflict("quota_below_committed", "额度不能调低到已预占与已使用金额之和以下")
        change_amount = request.limit_amount - Decimal(row["limit_amount"])
        if change_amount != 0:
            run(db, "UPDATE fleet_quota_month SET limit_amount=:limit_amount WHERE quota_month_id=:id",
                {"limit_amount": request.limit_amount, "id": quota_id})
        if change_amount != 0:
            run(db,
                """INSERT INTO fleet_quota_adjustment
                    (quota_month_id, change_type, amount, business_key, reason, actor_account_id)
                    VALUES (:quota_id, 'limit_change', :amount, :business_key, :reason, :actor)""",
                {"quota_id": quota_id, "amount": change_amount,
                 "business_key": f"limit:{authorization_id}:{bill_month.isoformat()}:{uuid.uuid4().hex}",
                 "reason": "月额度设置或调整", "actor": actor.account_id},
            )
        return one(db, "SELECT * FROM fleet_quota_month WHERE quota_month_id=:id", {"id": quota_id})


def list_fleet_quotas(db: Session, *, actor: Actor, authorization_id: int, query: PageQuery) -> dict:
    authorization = get_fleet_authorization(db, actor=actor, authorization_id=authorization_id)
    card = one(db, "SELECT fleet_id FROM fleet_card WHERE card_id=:card_id", {"card_id": authorization["card_id"]})
    _assert_fleet_scope(db, actor, int(card["fleet_id"]), "membership.fleet_authorization.read")
    return page_result(
        db,
        count_sql="SELECT COUNT(*) AS total FROM fleet_quota_month WHERE authorization_id=:authorization_id",
        rows_sql="SELECT * FROM fleet_quota_month WHERE authorization_id=:authorization_id ORDER BY bill_month DESC LIMIT :limit OFFSET :offset",
        params={"authorization_id": authorization_id}, page=query.page, page_size=query.page_size,
    )


def mock_topup_wallet(db: Session, *, actor: Actor, request: TopupRequest) -> dict:
    require_permission(actor, "membership.wallet.topup")
    if settings.app_env != "development":
        raise forbidden("mock_topup_disabled", "模拟充值只允许在开发环境使用")
    user_id = _user_id(actor)
    with transaction(db):
        user = one(db, "SELECT balance, status FROM app_user WHERE user_id=:user_id FOR UPDATE", {"user_id": user_id})
        if user is None or user["status"] != "active":
            raise not_found("user_not_found", "车主档案不存在或已停用")
        new_balance = Decimal(user["balance"]) + request.amount
        business_key = f"mock_topup:{user_id}:{uuid.uuid4().hex}"
        run(db, "UPDATE app_user SET balance=:balance WHERE user_id=:user_id",
            {"balance": new_balance, "user_id": user_id})
        transaction_id = inserted_id(run(
            db,
            """INSERT INTO wallet_transaction
                (user_id, transaction_type, amount, balance_after, business_key, occurred_at)
                VALUES (:user_id, 'mock_topup', :amount, :balance_after, :business_key, :occurred_at)""",
            {"user_id": user_id, "amount": request.amount, "balance_after": new_balance,
             "business_key": business_key, "occurred_at": utc_now_naive()},
        ))
        return one(db, "SELECT * FROM wallet_transaction WHERE wallet_transaction_id=:id", {"id": transaction_id})


def list_wallet_transactions(db: Session, *, actor: Actor, query: PageQuery) -> dict:
    if actor.user_id is not None and "vehicle_owner" in actor.roles:
        require_permission(actor, "membership.wallet.read")
        filters, params = ["user_id=:user_id"], {"user_id": actor.user_id}
    else:
        require_permission(actor, "membership.user.read")
        filters, params = ["1=1"], {}
    if query.keyword:
        filters.append("business_key LIKE :keyword")
        params["keyword"] = f"%{query.keyword.strip()}%"
    if query.start_at:
        filters.append("occurred_at >= :start_at")
        params["start_at"] = to_utc_naive(query.start_at)
    if query.end_at:
        filters.append("occurred_at < :end_at")
        params["end_at"] = to_utc_naive(query.end_at)
    where = " AND ".join(filters)
    return page_result(
        db,
        count_sql=f"SELECT COUNT(*) AS total FROM wallet_transaction WHERE {where}",
        rows_sql=f"SELECT * FROM wallet_transaction WHERE {where} ORDER BY occurred_at DESC, wallet_transaction_id DESC LIMIT :limit OFFSET :offset",
        params=params, page=query.page, page_size=query.page_size,
    )


def list_feedbacks(db: Session, *, actor: Actor, query: FeedbackQuery) -> dict:
    if actor.user_id is not None and "vehicle_owner" in actor.roles:
        require_permission(actor, "membership.feedback.read")
        filters, params = ["user_id=:user_id"], {"user_id": actor.user_id}
    else:
        require_permission(actor, "membership.feedback.read")
        filters, params = ["1=1"], {}
    if query.order_id is not None:
        filters.append("order_id=:order_id")
        params["order_id"] = query.order_id
    if query.start_at:
        filters.append("created_at >= :start_at")
        params["start_at"] = to_utc_naive(query.start_at)
    if query.end_at:
        filters.append("created_at < :end_at")
        params["end_at"] = to_utc_naive(query.end_at)
    where = " AND ".join(filters)
    return page_result(
        db,
        count_sql=f"SELECT COUNT(*) AS total FROM service_feedback WHERE {where}",
        rows_sql=f"SELECT * FROM service_feedback WHERE {where} ORDER BY created_at DESC, feedback_id DESC LIMIT :limit OFFSET :offset",
        params=params, page=query.page, page_size=query.page_size,
    )


def get_feedback(db: Session, *, actor: Actor, feedback_id: int) -> dict:
    row = one(db, "SELECT * FROM service_feedback WHERE feedback_id=:feedback_id", {"feedback_id": feedback_id})
    if row is None:
        raise not_found("feedback_not_found", "评价不存在")
    if actor.user_id != int(row["user_id"]):
        require_permission(actor, "membership.feedback.read")
    return row


def create_feedback(db: Session, *, actor: Actor, request: CreateFeedbackRequest) -> dict:
    require_permission(actor, "membership.feedback.create")
    user_id = _user_id(actor)
    try:
        with transaction(db):
            order = one(db, "SELECT order_id, user_id, status FROM charging_order WHERE order_id=:order_id FOR UPDATE",
                        {"order_id": request.order_id})
            if order is None or int(order["user_id"]) != user_id:
                raise not_found("order_not_found", "订单不存在或无权评价")
            if order["status"] != "paid":
                raise conflict("order_not_completed", "只有已付清的订单可以评价")
            feedback_id = inserted_id(run(
                db,
                "INSERT INTO service_feedback (order_id, user_id, rating, content) VALUES (:order_id, :user_id, :rating, :content)",
                {"order_id": request.order_id, "user_id": user_id, "rating": request.rating, "content": request.content},
            ))
            return one(db, "SELECT * FROM service_feedback WHERE feedback_id=:id", {"id": feedback_id})
    except IntegrityError as exc:
        raise conflict("feedback_exists", "每个订单只能评价一次") from exc


def list_accounts(db: Session, *, actor: Actor, query) -> dict:
    require_permission(actor, "auth.account.read")
    filters, params = ["1=1"], {}
    if query.keyword:
        filters.append("username LIKE :keyword")
        params["keyword"] = f"%{query.keyword.strip()}%"
    if query.start_at:
        filters.append("created_at >= :start_at")
        params["start_at"] = to_utc_naive(query.start_at)
    if query.end_at:
        filters.append("created_at < :end_at")
        params["end_at"] = to_utc_naive(query.end_at)
    where = " AND ".join(filters)
    return page_result(
        db,
        count_sql=f"SELECT COUNT(*) AS total FROM sys_account WHERE {where}",
        rows_sql=f"SELECT account_id, username, status, failed_attempts, locked_until, last_login_at, created_at FROM sys_account WHERE {where} ORDER BY account_id DESC LIMIT :limit OFFSET :offset",
        params=params, page=query.page, page_size=query.page_size,
    )


def get_account(db: Session, *, actor: Actor, account_id: int) -> dict:
    require_permission(actor, "auth.account.read")
    row = one(db,
        "SELECT account_id, username, status, failed_attempts, locked_until, last_login_at, created_at FROM sys_account WHERE account_id=:account_id",
        {"account_id": account_id})
    if row is None:
        raise not_found("account_not_found", "账号不存在")
    row["roles"] = [r["role_code"] for r in many(db,
        "SELECT r.role_code FROM sys_account_role ar JOIN sys_role r ON r.role_id=ar.role_id WHERE ar.account_id=:id",
        {"id": account_id})]
    return row


def create_account(db: Session, *, actor: Actor, request: CreateAccountRequest) -> dict:
    require_permission(actor, "auth.account.manage")
    try:
        with transaction(db):
            roles = _role_rows_for_codes(db, request.role_codes)
            found_codes = {r["role_code"] for r in roles}
            if found_codes != set(request.role_codes):
                raise BusinessError(422, "unknown_role", "角色代码包含未登记项")
            account_id = inserted_id(run(db,
                "INSERT INTO sys_account (username, password_hash) VALUES (:username, :password_hash)",
                {"username": request.username, "password_hash": security.hash_password(request.password)}))
            for role in roles:
                run(db, "INSERT INTO sys_account_role (account_id, role_id) VALUES (:account_id, :role_id)",
                    {"account_id": account_id, "role_id": role["role_id"]})
            result = get_account(db, actor=actor, account_id=account_id)
    except IntegrityError as exc:
        raise conflict("duplicate_username", "登录名已存在") from exc
    return result


def change_account_status(db: Session, *, actor: Actor, account_id: int, request: AccountStatusRequest) -> dict:
    require_permission(actor, "auth.account.manage")
    if actor.account_id == account_id and request.status == "disabled":
        raise conflict("cannot_disable_self", "不能禁用当前登录账号")
    with transaction(db):
        account = one(db, "SELECT account_id FROM sys_account WHERE account_id=:id FOR UPDATE", {"id": account_id})
        if account is None:
            raise not_found("account_not_found", "账号不存在")
        run(db,
            "UPDATE sys_account SET status=:status, failed_attempts=0, locked_until=NULL WHERE account_id=:id",
            {"status": request.status, "id": account_id})
        if request.status == "disabled":
            run(db, "UPDATE sys_session SET revoked_at=UTC_TIMESTAMP(3) WHERE account_id=:id AND revoked_at IS NULL",
                {"id": account_id})
        return get_account(db, actor=actor, account_id=account_id)


def assign_roles(db: Session, *, actor: Actor, account_id: int, request: AssignRolesRequest) -> AccountContext:
    require_permission(actor, "auth.account.manage")
    if actor.account_id == account_id and "platform_admin" not in request.role_codes:
        raise conflict("prevent_admin_lockout", "不能移除当前账号的平台管理员角色")
    with transaction(db):
        account = one(db, "SELECT account_id FROM sys_account WHERE account_id=:id FOR UPDATE", {"id": account_id})
        if account is None:
            raise not_found("account_not_found", "账号不存在")
        role_rows = _role_rows_for_codes(db, request.role_codes)
        if {r["role_code"] for r in role_rows} != set(request.role_codes):
            raise BusinessError(422, "unknown_role", "角色代码包含未登记项")
        run(db, "DELETE FROM sys_account_role WHERE account_id=:id", {"id": account_id})
        for role in role_rows:
            run(db, "INSERT INTO sys_account_role (account_id, role_id) VALUES (:account_id, :role_id)",
                {"account_id": account_id, "role_id": role["role_id"]})
        run(db, "UPDATE sys_session SET revoked_at=UTC_TIMESTAMP(3) WHERE account_id=:id AND revoked_at IS NULL",
            {"id": account_id})
        user = one(db, "SELECT user_id FROM app_user WHERE account_id=:id", {"id": account_id})
        return _account_context(db, account_id, int(user["user_id"]) if user else None)


def assign_resource_scopes(db: Session, *, actor: Actor, account_id: int,
                           request: AssignScopesRequest) -> AccountContext:
    require_permission(actor, "auth.account.manage")
    table_specs = (
        ("sys_account_operator", "operator_id", sorted(set(request.operator_ids))),
        ("sys_account_station", "station_id", sorted(set(request.station_ids))),
        ("sys_account_fleet", "fleet_id", sorted(set(request.fleet_ids))),
    )
    try:
        with transaction(db):
            if one(db, "SELECT account_id FROM sys_account WHERE account_id=:id FOR UPDATE", {"id": account_id}) is None:
                raise not_found("account_not_found", "账号不存在")
            for table_name, resource_column, resource_ids in table_specs:
                run(db, f"DELETE FROM {table_name} WHERE account_id=:account_id", {"account_id": account_id})
                for resource_id in resource_ids:
                    run(db,
                        f"INSERT INTO {table_name} (account_id, {resource_column}) VALUES (:account_id, :resource_id)",
                        {"account_id": account_id, "resource_id": resource_id})
            run(db, "UPDATE sys_session SET revoked_at=UTC_TIMESTAMP(3) WHERE account_id=:id AND revoked_at IS NULL",
                {"id": account_id})
            user = one(db, "SELECT user_id FROM app_user WHERE account_id=:id", {"id": account_id})
            return _account_context(db, account_id, int(user["user_id"]) if user else None)
    except IntegrityError as exc:
        raise BusinessError(422, "unknown_resource_scope", "资源范围包含不存在的运营商、场站或车队编号") from exc


def list_roles(db: Session, *, actor: Actor, query: RoleQuery) -> dict:
    require_permission(actor, "auth.role.read")
    where, params = "1=1", {}
    if query.keyword:
        where = "(role_code LIKE :keyword OR role_name LIKE :keyword)"
        params["keyword"] = f"%{query.keyword.strip()}%"
    return page_result(
        db, count_sql=f"SELECT COUNT(*) AS total FROM sys_role WHERE {where}",
        rows_sql=f"SELECT role_id, role_code, role_name, created_at FROM sys_role WHERE {where} ORDER BY role_id LIMIT :limit OFFSET :offset",
        params=params, page=query.page, page_size=query.page_size)


def get_role(db: Session, *, actor: Actor, role_id: int) -> dict:
    require_permission(actor, "auth.role.read")
    row = one(db, "SELECT role_id, role_code, role_name, created_at FROM sys_role WHERE role_id=:id", {"id": role_id})
    if row is None:
        raise not_found("role_not_found", "角色不存在")
    row["permissions"] = [r["permission_code"] for r in many(db,
        "SELECT p.permission_code FROM sys_role_permission rp JOIN sys_permission p ON p.permission_id=rp.permission_id WHERE rp.role_id=:id ORDER BY p.permission_code",
        {"id": role_id})]
    return row


def list_permissions(db: Session, *, actor: Actor, query: PermissionQuery) -> dict:
    require_permission(actor, "auth.permission.read")
    where, params = "1=1", {}
    if query.keyword:
        where = "(permission_code LIKE :keyword OR permission_name LIKE :keyword)"
        params["keyword"] = f"%{query.keyword.strip()}%"
    return page_result(
        db, count_sql=f"SELECT COUNT(*) AS total FROM sys_permission WHERE {where}",
        rows_sql=f"SELECT permission_id, permission_code, permission_name, created_at FROM sys_permission WHERE {where} ORDER BY permission_id LIMIT :limit OFFSET :offset",
        params=params, page=query.page, page_size=query.page_size)


def get_permission(db: Session, *, actor: Actor, permission_id: int) -> dict:
    require_permission(actor, "auth.permission.read")
    row = one(db, "SELECT permission_id, permission_code, permission_name, created_at FROM sys_permission WHERE permission_id=:id",
              {"id": permission_id})
    if row is None:
        raise not_found("permission_not_found", "权限不存在")
    return row


# Cross-module helpers below intentionally do not start or commit transactions.
# Callers own the transaction so order, payment and membership updates are atomic.
def _quota_snapshot(db: Session, quota_month_id: int, order_id: int) -> FleetQuotaSnapshot:
    quota = one(db, "SELECT * FROM fleet_quota_month WHERE quota_month_id=:id", {"id": quota_month_id})
    if quota is None:
        raise not_found("quota_month_not_found", "车队额度账期不存在")
    limit_amount = Decimal(quota["limit_amount"])
    reserved_amount = Decimal(quota["reserved_amount"])
    used_amount = Decimal(quota["used_amount"])
    return FleetQuotaSnapshot(
        authorization_id=int(quota["authorization_id"]),
        order_id=order_id,
        bill_month=quota["bill_month"].isoformat(),
        limit_amount=f"{limit_amount:.2f}",
        reserved_amount=f"{reserved_amount:.2f}",
        used_amount=f"{used_amount:.2f}",
        remaining_amount=f"{limit_amount - reserved_amount - used_amount:.2f}",
    )


def _ensure_quota_month(db: Session, authorization_id: int, bill_month: date) -> dict:
    if bill_month.day != 1:
        raise BusinessError(422, "invalid_bill_month", "账期必须使用当月首日")
    authorization = one(
        db,
        "SELECT authorization_id, default_monthly_limit FROM fleet_authorization WHERE authorization_id=:id",
        {"id": authorization_id},
    )
    if authorization is None:
        raise not_found("authorization_not_found", "车队授权不存在")
    run(
        db,
        """INSERT INTO fleet_quota_month (authorization_id, bill_month, limit_amount)
           VALUES (:authorization_id, :bill_month, :limit_amount)
           ON DUPLICATE KEY UPDATE quota_month_id=LAST_INSERT_ID(quota_month_id)""",
        {"authorization_id": authorization_id, "bill_month": bill_month,
         "limit_amount": authorization["default_monthly_limit"]},
    )
    quota = one(
        db,
        "SELECT * FROM fleet_quota_month WHERE authorization_id=:authorization_id AND bill_month=:bill_month FOR UPDATE",
        {"authorization_id": authorization_id, "bill_month": bill_month},
    )
    assert quota is not None
    return quota


def validate_fleet_authorization(db: Session, *, authorization_id: int, user_id: int) -> FleetAuthorizationSnapshot:
    row = one(
        db,
        """SELECT fa.authorization_id, fa.user_id, fa.vehicle_id, fa.valid_from, fa.valid_until,
                  fa.status,
                  fc.card_id, fc.fleet_id, fc.status AS card_status, fc.valid_from AS card_valid_from,
                  fc.valid_until AS card_valid_until, f.status AS fleet_status,
                  u.status AS user_status, v.status AS vehicle_status,
                  vb.binding_id
             FROM fleet_authorization fa
             JOIN fleet_card fc ON fc.card_id=fa.card_id
             JOIN fleet f ON f.fleet_id=fc.fleet_id
             JOIN app_user u ON u.user_id=fa.user_id
             JOIN vehicle v ON v.vehicle_id=fa.vehicle_id
             JOIN vehicle_binding vb ON vb.vehicle_id=fa.vehicle_id AND vb.user_id=fa.user_id
                                      AND vb.unbound_at IS NULL
            WHERE fa.authorization_id=:authorization_id AND fa.user_id=:user_id FOR UPDATE""",
        {"authorization_id": authorization_id, "user_id": user_id},
    )
    if row is None:
        raise forbidden("fleet_authorization_mismatch", "车队授权、用车人、车辆绑定信息不匹配")
    now = utc_now_naive()
    if row["status"] != "active":
        raise forbidden("fleet_authorization_inactive", "车队授权不可用")
    if row["card_status"] != "active" or row["fleet_status"] != "active":
        raise forbidden("fleet_card_inactive", "车队或车队卡不可用")
    if row["user_status"] != "active" or row["vehicle_status"] != "active":
        raise forbidden("fleet_subject_inactive", "用车人或车辆不可用")
    if not (row["valid_from"] <= now < row["valid_until"] and
            row["card_valid_from"] <= now < row["card_valid_until"]):
        raise forbidden("fleet_authorization_expired", "车队授权或卡片不在有效期内")
    return FleetAuthorizationSnapshot(
        authorization_id=int(row["authorization_id"]),
        fleet_id=int(row["fleet_id"]),
        user_id=int(row["user_id"]),
        vehicle_id=int(row["vehicle_id"]),
        card_id=int(row["card_id"]),
        valid_from=row["valid_from"].isoformat(),
        valid_until=row["valid_until"].isoformat(),
    )


def reserve_fleet_quota(db: Session, *, authorization_id: int, order_id: int,
                        bill_month: date, amount: Decimal) -> FleetQuotaSnapshot:
    if amount <= 0:
        raise BusinessError(422, "invalid_reservation_amount", "车队额度预占金额必须大于零")
    existing = one(db, "SELECT * FROM fleet_quota_reservation WHERE order_id=:order_id",
                   {"order_id": order_id})
    if existing is not None:
        existing = one(db, "SELECT * FROM fleet_quota_reservation WHERE order_id=:order_id FOR UPDATE",
                       {"order_id": order_id})
        quota = one(db, "SELECT * FROM fleet_quota_month WHERE quota_month_id=:id",
                    {"id": existing["quota_month_id"]})
        if (int(quota["authorization_id"]) != authorization_id or
                Decimal(existing["reserved_amount"]) != amount):
            raise conflict("quota_reservation_conflict", "该订单已存在不同的车队额度预占")
        if existing["status"] in ("reserved", "settled", "review_required"):
            return _quota_snapshot(db, int(existing["quota_month_id"]), order_id)
        raise conflict("quota_reservation_released", "该订单额度预占已释放，不能重复创建")

    order = one(db, "SELECT order_mode, authorization_id, user_id, vehicle_id, fleet_id, status FROM charging_order WHERE order_id=:id FOR UPDATE",
                {"id": order_id})
    if order is None:
        raise not_found("order_not_found", "充电订单不存在")
    if (order["order_mode"] != "fleet" or int(order["authorization_id"] or 0) != authorization_id or
            order["status"] != "charging"):
        raise conflict("order_not_reservable", "该订单当前不允许预占车队额度")
    authorization = validate_fleet_authorization(
        db, authorization_id=authorization_id, user_id=int(order["user_id"])
    )
    if (int(order["vehicle_id"] or 0) != authorization.vehicle_id or
            int(order["fleet_id"] or 0) != authorization.fleet_id):
        raise conflict("fleet_order_scope_mismatch", "订单关联的车队或车辆与车队授权不匹配")
    # A concurrent retry may have inserted the reservation while this call waited for the order lock.
    existing = one(db, "SELECT * FROM fleet_quota_reservation WHERE order_id=:order_id FOR UPDATE",
                   {"order_id": order_id})
    if existing is not None:
        quota = one(db, "SELECT * FROM fleet_quota_month WHERE quota_month_id=:id",
                    {"id": existing["quota_month_id"]})
        if (int(quota["authorization_id"]) != authorization_id or
                Decimal(existing["reserved_amount"]) != amount):
            raise conflict("quota_reservation_conflict", "该订单已存在不同的车队额度预占")
        if existing["status"] in ("reserved", "settled", "review_required"):
            return _quota_snapshot(db, int(existing["quota_month_id"]), order_id)
        raise conflict("quota_reservation_released", "该订单额度预占已释放，不能重复创建")

    quota = _ensure_quota_month(db, authorization_id, bill_month)
    committed = Decimal(quota["reserved_amount"]) + Decimal(quota["used_amount"])
    limit_amount = Decimal(quota["limit_amount"])
    if committed + amount > limit_amount:
        raise conflict("fleet_quota_exceeded", "车队月额度不足")
    run(db, "UPDATE fleet_quota_month SET reserved_amount=reserved_amount+:amount WHERE quota_month_id=:id",
        {"amount": amount, "id": quota["quota_month_id"]})
    run(
        db,
        """INSERT INTO fleet_quota_reservation
            (order_id, quota_month_id, reserved_amount, actual_amount, status, reserved_at)
           VALUES (:order_id, :quota_month_id, :amount, 0, 'reserved', UTC_TIMESTAMP(3))""",
        {"order_id": order_id, "quota_month_id": quota["quota_month_id"], "amount": amount},
    )
    return _quota_snapshot(db, int(quota["quota_month_id"]), order_id)


def settle_fleet_quota(db: Session, *, order_id: int, bill_month: date,
                       actual_amount: Decimal) -> FleetQuotaSnapshot:
    if actual_amount < 0:
        raise BusinessError(422, "invalid_actual_amount", "车队实际扣额不能为负")
    reservation = one(db, "SELECT * FROM fleet_quota_reservation WHERE order_id=:order_id FOR UPDATE",
                      {"order_id": order_id})
    if reservation is None:
        raise not_found("quota_reservation_not_found", "订单没有车队额度预占")
    old_quota = one(db, "SELECT * FROM fleet_quota_month WHERE quota_month_id=:id",
                    {"id": reservation["quota_month_id"]})
    if old_quota is None:
        raise not_found("quota_month_not_found", "原车队额度账期不存在")
    if reservation["status"] in ("settled", "review_required"):
        if Decimal(reservation["actual_amount"]) != actual_amount:
            raise conflict("quota_already_settled", "订单额度已按其他金额结算")
        return _quota_snapshot(db, int(reservation["quota_month_id"]), order_id)
    if reservation["status"] != "reserved":
        raise conflict("quota_reservation_released", "订单额度预占已释放，不能结算")

    authorization_id = int(old_quota["authorization_id"])
    old_month = old_quota["bill_month"]
    if bill_month.day != 1:
        raise BusinessError(422, "invalid_bill_month", "账期必须使用当月首日")
    if bill_month == old_month:
        quota = one(db, "SELECT * FROM fleet_quota_month WHERE quota_month_id=:id FOR UPDATE",
                    {"id": old_quota["quota_month_id"]})
        reserved_amount = Decimal(reservation["reserved_amount"])
        if Decimal(quota["reserved_amount"]) < reserved_amount:
            raise conflict("quota_reservation_corrupt", "额度预占汇总小于订单预占")
        new_used = Decimal(quota["used_amount"]) + actual_amount
        review_required = new_used + Decimal(quota["reserved_amount"]) - reserved_amount > Decimal(quota["limit_amount"])
        run(db,
            "UPDATE fleet_quota_month SET reserved_amount=reserved_amount-:reserved, used_amount=used_amount+:actual WHERE quota_month_id=:id",
            {"reserved": reserved_amount, "actual": actual_amount, "id": quota["quota_month_id"]})
        target_quota_id = int(quota["quota_month_id"])
    else:
        target = _ensure_quota_month(db, authorization_id, bill_month)
        quotas = many(
            db,
            "SELECT * FROM fleet_quota_month WHERE quota_month_id IN (:old_id, :new_id) ORDER BY bill_month FOR UPDATE",
            {"old_id": old_quota["quota_month_id"], "new_id": target["quota_month_id"]},
        )
        quotas_by_id = {int(row["quota_month_id"]): row for row in quotas}
        old_locked = quotas_by_id[int(old_quota["quota_month_id"])]
        target_locked = quotas_by_id[int(target["quota_month_id"])]
        reserved_amount = Decimal(reservation["reserved_amount"])
        if Decimal(old_locked["reserved_amount"]) < reserved_amount:
            raise conflict("quota_reservation_corrupt", "额度预占汇总小于订单预占")
        target_used = Decimal(target_locked["used_amount"]) + actual_amount
        review_required = target_used + Decimal(target_locked["reserved_amount"]) > Decimal(target_locked["limit_amount"])
        run(db, "UPDATE fleet_quota_month SET reserved_amount=reserved_amount-:amount WHERE quota_month_id=:id",
            {"amount": reserved_amount, "id": old_locked["quota_month_id"]})
        run(db, "UPDATE fleet_quota_month SET used_amount=used_amount+:amount WHERE quota_month_id=:id",
            {"amount": actual_amount, "id": target_locked["quota_month_id"]})
        target_quota_id = int(target_locked["quota_month_id"])
        run(db,
            """INSERT INTO fleet_quota_adjustment
                (quota_month_id, order_id, change_type, amount, business_key, reason)
               VALUES (:quota_id, :order_id, 'month_transfer', :amount, :business_key, :reason)""",
            {"quota_id": old_locked["quota_month_id"], "order_id": order_id,
             "amount": -reserved_amount,
             "business_key": f"month_transfer:{order_id}:{old_month.isoformat()}:release",
             "reason": f"订单结算账期由 {old_month.isoformat()} 迁移至 {bill_month.isoformat()}，释放原账期预占"},
        )
        run(db,
            """INSERT INTO fleet_quota_adjustment
                (quota_month_id, order_id, change_type, amount, business_key, reason)
               VALUES (:quota_id, :order_id, 'month_transfer', :amount, :business_key, :reason)""",
            {"quota_id": target_locked["quota_month_id"], "order_id": order_id,
             "amount": actual_amount,
             "business_key": f"month_transfer:{order_id}:{bill_month.isoformat()}:settle",
             "reason": f"订单结算账期由 {old_month.isoformat()} 迁移至 {bill_month.isoformat()}，计入实际使用"},
        )

    status = "review_required" if review_required else "settled"
    run(db,
        """UPDATE fleet_quota_reservation SET quota_month_id=:quota_id, actual_amount=:actual,
                  status=:status, settled_at=UTC_TIMESTAMP(3) WHERE reservation_id=:reservation_id""",
        {"quota_id": target_quota_id, "actual": actual_amount, "status": status,
         "reservation_id": reservation["reservation_id"]},
    )
    if review_required:
        run(db, "UPDATE charging_order SET review_required=1, review_reason=:reason WHERE order_id=:order_id",
            {"reason": "车队实际结算金额超过目标账期可用额度，需人工复核", "order_id": order_id})
    return _quota_snapshot(db, target_quota_id, order_id)


def release_fleet_quota(db: Session, *, order_id: int) -> None:
    reservation = one(db, "SELECT * FROM fleet_quota_reservation WHERE order_id=:order_id FOR UPDATE",
                      {"order_id": order_id})
    if reservation is None or reservation["status"] == "released":
        return
    if reservation["status"] != "reserved":
        return
    quota = one(db, "SELECT * FROM fleet_quota_month WHERE quota_month_id=:id FOR UPDATE",
                {"id": reservation["quota_month_id"]})
    amount = Decimal(reservation["reserved_amount"])
    if quota is None or Decimal(quota["reserved_amount"]) < amount:
        raise conflict("quota_reservation_corrupt", "额度预占汇总小于订单预占")
    run(db, "UPDATE fleet_quota_month SET reserved_amount=reserved_amount-:amount WHERE quota_month_id=:id",
        {"amount": amount, "id": quota["quota_month_id"]})
    run(db,
        "UPDATE fleet_quota_reservation SET status='released', released_at=UTC_TIMESTAMP(3) WHERE reservation_id=:id",
        {"id": reservation["reservation_id"]},
    )


def adjust_fleet_quota_after_refund(db: Session, *, refund_id: int) -> FleetQuotaSnapshot | None:
    business_key = f"fleet_refund:{refund_id}"
    prior = one(db, "SELECT quota_month_id, order_id FROM fleet_quota_adjustment WHERE business_key=:key",
                {"key": business_key})
    if prior is not None:
        return _quota_snapshot(db, int(prior["quota_month_id"]), int(prior["order_id"]))
    refund = one(
        db,
        """SELECT rr.refund_id, rr.amount, rr.status, rr.settlement_method, pr.order_id,
                  o.authorization_id
             FROM refund_record rr
             JOIN payment_record pr ON pr.payment_id=rr.payment_id
             JOIN charging_order o ON o.order_id=pr.order_id
            WHERE rr.refund_id=:refund_id FOR UPDATE""",
        {"refund_id": refund_id},
    )
    if refund is None:
        raise not_found("refund_not_found", "退款记录不存在")
    prior = one(db, "SELECT quota_month_id, order_id FROM fleet_quota_adjustment WHERE business_key=:key",
                {"key": business_key})
    if prior is not None:
        return _quota_snapshot(db, int(prior["quota_month_id"]), int(prior["order_id"]))
    if refund["status"] != "succeeded" or refund["authorization_id"] is None:
        return None
    reservation = one(db, "SELECT * FROM fleet_quota_reservation WHERE order_id=:id FOR UPDATE",
                      {"id": refund["order_id"]})
    if reservation is None or reservation["status"] not in ("settled", "review_required"):
        return None
    quota = one(db, "SELECT * FROM fleet_quota_month WHERE quota_month_id=:id FOR UPDATE",
                {"id": reservation["quota_month_id"]})
    amount = Decimal(refund["amount"])
    if quota is None:
        raise not_found("quota_month_not_found", "订单车队额度账期不存在")
    if amount > Decimal(reservation["actual_amount"]) or amount > Decimal(quota["used_amount"]):
        raise conflict("refund_exceeds_fleet_usage", "退款金额超过订单车队已结算额度")
    run(db, "UPDATE fleet_quota_month SET used_amount=used_amount-:amount WHERE quota_month_id=:id",
        {"amount": amount, "id": quota["quota_month_id"]})
    run(db, "UPDATE fleet_quota_reservation SET actual_amount=actual_amount-:amount WHERE reservation_id=:id",
        {"amount": amount, "id": reservation["reservation_id"]})
    run(
        db,
        """INSERT INTO fleet_quota_adjustment
            (quota_month_id, order_id, refund_id, change_type, amount, business_key, reason)
           VALUES (:quota_id, :order_id, :refund_id, 'refund', :amount, :business_key, :reason)""",
        {"quota_id": quota["quota_month_id"], "order_id": refund["order_id"],
         "refund_id": refund_id, "amount": -amount, "business_key": business_key,
         "reason": f"退款 {refund_id} 冲减车队额度使用"},
    )
    return _quota_snapshot(db, int(quota["quota_month_id"]), int(refund["order_id"]))


def lock_coupon_for_order(db: Session, *, coupon_id: int, user_id: int, order_id: int,
                          station_id: int, original_amount: Decimal) -> Decimal:
    if original_amount < 0:
        raise BusinessError(422, "invalid_original_amount", "优惠前金额不能为负")
    order = one(db, "SELECT * FROM charging_order WHERE order_id=:id FOR UPDATE", {"id": order_id})
    if order is None:
        raise not_found("order_not_found", "充电订单不存在")
    if (order["order_mode"] != "personal" or int(order["user_id"]) != user_id or
            int(order["station_id"]) != station_id or order["status"] not in ("charging", "awaiting_payment")):
        raise conflict("coupon_order_mismatch", "个人优惠券仅能用于本人当前个人订单")

    existing = one(db, "SELECT * FROM coupon_usage WHERE order_id=:order_id AND status IN ('locked','redeemed') FOR UPDATE",
                   {"order_id": order_id})
    if existing is not None:
        if int(existing["coupon_id"]) != coupon_id:
            raise conflict("order_coupon_already_selected", "该订单已使用其他优惠券")
        return Decimal(existing["discount_amount"])

    coupon = one(db, "SELECT * FROM user_coupon WHERE coupon_id=:coupon_id FOR UPDATE", {"coupon_id": coupon_id})
    if coupon is None or int(coupon["user_id"]) != user_id:
        raise not_found("coupon_not_found", "优惠券不存在或不属于当前用户")
    if coupon["status"] != "available" or coupon["expires_at"] <= utc_now_naive():
        raise conflict("coupon_unavailable", "优惠券已使用、已锁定或已过期")
    promotion = one(db, "SELECT * FROM promotion WHERE promotion_id=:id", {"id": coupon["promotion_id"]})
    if promotion is None:
        raise conflict("promotion_missing", "优惠券来源活动不存在")
    if not bool(promotion["all_stations"]):
        applicable = one(db, "SELECT promotion_id FROM promotion_station WHERE promotion_id=:promotion_id AND station_id=:station_id",
                         {"promotion_id": coupon["promotion_id"], "station_id": station_id})
        if applicable is None:
            raise conflict("coupon_station_ineligible", "该优惠券不适用于当前场站")
    minimum = Decimal(coupon["minimum_spend_snapshot"])
    if original_amount < minimum:
        raise conflict("coupon_minimum_spend", "订单金额未达到优惠券使用门槛")
    discount = min(Decimal(coupon["face_amount_snapshot"]), original_amount)
    now = utc_now_naive()
    run(
        db,
        """INSERT INTO coupon_usage
            (coupon_id, order_id, original_amount, discount_amount, locked_at, lock_expires_at, status)
           VALUES (:coupon_id, :order_id, :original_amount, :discount_amount, :locked_at, :expires_at, 'locked')""",
        {"coupon_id": coupon_id, "order_id": order_id, "original_amount": original_amount,
         "discount_amount": discount, "locked_at": now, "expires_at": now + timedelta(minutes=15)},
    )
    run(db, "UPDATE user_coupon SET status='locked' WHERE coupon_id=:id", {"id": coupon_id})
    return discount


def redeem_coupon_for_order(db: Session, *, order_id: int) -> None:
    order = one(db, "SELECT status FROM charging_order WHERE order_id=:id FOR UPDATE", {"id": order_id})
    if order is None:
        raise not_found("order_not_found", "充电订单不存在")
    if order["status"] != "paid":
        raise conflict("order_not_fully_paid", "订单全部付清后才能核销优惠券")
    usage = one(db, "SELECT * FROM coupon_usage WHERE order_id=:order_id FOR UPDATE", {"order_id": order_id})
    if usage is None or usage["status"] == "released":
        return
    if usage["status"] == "redeemed":
        return
    run(db, "UPDATE coupon_usage SET status='redeemed', redeemed_at=UTC_TIMESTAMP(3) WHERE usage_id=:id",
        {"id": usage["usage_id"]})
    run(db, "UPDATE user_coupon SET status='redeemed' WHERE coupon_id=:id AND status='locked'",
        {"id": usage["coupon_id"]})


def release_coupon_for_order(db: Session, *, order_id: int) -> None:
    usage = one(db, "SELECT * FROM coupon_usage WHERE order_id=:order_id FOR UPDATE", {"order_id": order_id})
    if usage is None or usage["status"] != "locked":
        return
    coupon = one(db, "SELECT * FROM user_coupon WHERE coupon_id=:id FOR UPDATE", {"id": usage["coupon_id"]})
    if coupon is None:
        raise not_found("coupon_not_found", "锁定的优惠券已不存在")
    next_status = "expired" if coupon["expires_at"] <= utc_now_naive() else "available"
    run(db, "UPDATE coupon_usage SET status='released', released_at=UTC_TIMESTAMP(3) WHERE usage_id=:id",
        {"id": usage["usage_id"]})
    run(db, "UPDATE user_coupon SET status=:status WHERE coupon_id=:id AND status='locked'",
        {"status": next_status, "id": coupon["coupon_id"]})


def reissue_coupon_after_full_refund(db: Session, *, order_id: int) -> int | None:
    order = one(db, "SELECT order_id FROM charging_order WHERE order_id=:order_id FOR UPDATE",
                {"order_id": order_id})
    if order is None:
        raise not_found("order_not_found", "充电订单不存在")
    existing = one(db, "SELECT coupon_id FROM user_coupon WHERE reissue_source_order_id=:order_id",
                   {"order_id": order_id})
    if existing is not None:
        return int(existing["coupon_id"])
    usage = one(db, "SELECT * FROM coupon_usage WHERE order_id=:order_id AND status='redeemed' FOR UPDATE",
                {"order_id": order_id})
    if usage is None:
        return None
    totals = one(
        db,
        """SELECT
              (SELECT COALESCE(SUM(amount), 0) FROM payment_record WHERE order_id=:order_id AND status='succeeded') AS paid_total,
              (SELECT COALESCE(SUM(rr.amount), 0) FROM refund_record rr JOIN payment_record pr ON pr.payment_id=rr.payment_id
                WHERE pr.order_id=:order_id AND rr.status='succeeded' AND rr.settlement_method='original') AS refunded_total""",
        {"order_id": order_id},
    )
    paid_total = Decimal(totals["paid_total"] or 0)
    refunded_total = Decimal(totals["refunded_total"] or 0)
    if paid_total <= 0 or refunded_total < paid_total:
        return None
    coupon = one(db, "SELECT * FROM user_coupon WHERE coupon_id=:id FOR UPDATE", {"id": usage["coupon_id"]})
    if coupon is None or coupon["expires_at"] <= utc_now_naive():
        return None
    result = run(
        db,
        """INSERT INTO user_coupon
            (promotion_id, user_id, received_at, expires_at, face_amount_snapshot,
             minimum_spend_snapshot, status, reissue_source_order_id)
           VALUES (:promotion_id, :user_id, UTC_TIMESTAMP(3), :expires_at, :face_amount,
                   :minimum_spend, 'available', :order_id)""",
        {"promotion_id": coupon["promotion_id"], "user_id": coupon["user_id"],
         "expires_at": coupon["expires_at"], "face_amount": coupon["face_amount_snapshot"],
         "minimum_spend": coupon["minimum_spend_snapshot"], "order_id": order_id},
    )
    return inserted_id(result)


def debit_wallet_for_payment(db: Session, *, user_id: int, payment_id: int,
                             amount: Decimal) -> dict:
    if amount <= 0:
        raise BusinessError(422, "invalid_payment_amount", "钱包扣款金额必须大于零")
    business_key = f"wallet_payment:{payment_id}"
    existing = one(db, "SELECT * FROM wallet_transaction WHERE business_key=:key",
                   {"key": business_key})
    if existing is not None:
        if int(existing["user_id"]) != user_id or Decimal(existing["amount"]) != -amount:
            raise conflict("wallet_payment_conflict", "该支付流水已按其他用户或金额记账")
        return existing
    payment = one(
        db,
        """SELECT pr.payment_id, pr.order_id, pr.channel, pr.amount, pr.status, o.user_id
             FROM payment_record pr JOIN charging_order o ON o.order_id=pr.order_id
            WHERE pr.payment_id=:payment_id FOR UPDATE""",
        {"payment_id": payment_id},
    )
    if payment is None or int(payment["user_id"]) != user_id:
        raise not_found("payment_not_found", "钱包支付记录不存在或用户不匹配")
    if payment["channel"] != "wallet" or payment["status"] != "succeeded" or Decimal(payment["amount"]) != amount:
        raise conflict("payment_not_wallet", "只有金额匹配且成功的余额支付可以扣款")
    existing = one(db, "SELECT * FROM wallet_transaction WHERE business_key=:key",
                   {"key": business_key})
    if existing is not None:
        if int(existing["user_id"]) != user_id or Decimal(existing["amount"]) != -amount:
            raise conflict("wallet_payment_conflict", "该支付流水已按其他用户或金额记账")
        return existing
    user = one(db, "SELECT balance, status FROM app_user WHERE user_id=:id FOR UPDATE", {"id": user_id})
    if user is None or user["status"] != "active":
        raise not_found("user_not_found", "车主档案不存在或已停用")
    balance = Decimal(user["balance"])
    if balance < amount:
        raise conflict("wallet_insufficient", "余额不足")
    new_balance = balance - amount
    run(db, "UPDATE app_user SET balance=:balance WHERE user_id=:id", {"balance": new_balance, "id": user_id})
    result = run(
        db,
        """INSERT INTO wallet_transaction
            (user_id, payment_id, transaction_type, amount, balance_after, business_key, occurred_at)
           VALUES (:user_id, :payment_id, 'payment', :amount, :balance_after, :business_key, UTC_TIMESTAMP(3))""",
        {"user_id": user_id, "payment_id": payment_id, "amount": -amount,
         "balance_after": new_balance, "business_key": business_key},
    )
    return one(db, "SELECT * FROM wallet_transaction WHERE wallet_transaction_id=:id",
               {"id": inserted_id(result)})


def credit_wallet_for_refund(db: Session, *, user_id: int, refund_id: int,
                             amount: Decimal) -> dict:
    if amount <= 0:
        raise BusinessError(422, "invalid_refund_amount", "钱包退款金额必须大于零")
    business_key = f"wallet_refund:{refund_id}"
    existing = one(db, "SELECT * FROM wallet_transaction WHERE business_key=:key",
                   {"key": business_key})
    if existing is not None:
        if int(existing["user_id"]) != user_id or Decimal(existing["amount"]) != amount:
            raise conflict("wallet_refund_conflict", "该退款流水已按其他用户或金额记账")
        return existing
    refund = one(
        db,
        """SELECT rr.refund_id, rr.amount, rr.status, pr.channel, o.user_id
             FROM refund_record rr JOIN payment_record pr ON pr.payment_id=rr.payment_id
             JOIN charging_order o ON o.order_id=pr.order_id
            WHERE rr.refund_id=:refund_id FOR UPDATE""",
        {"refund_id": refund_id},
    )
    if refund is None or int(refund["user_id"]) != user_id:
        raise not_found("refund_not_found", "钱包退款记录不存在或用户不匹配")
    if refund["channel"] != "wallet" or refund["status"] != "succeeded" or Decimal(refund["amount"]) != amount:
        raise conflict("refund_not_wallet", "只有金额匹配且成功的余额支付退款可以入账")
    existing = one(db, "SELECT * FROM wallet_transaction WHERE business_key=:key FOR UPDATE",
                   {"key": business_key})
    if existing is not None:
        if int(existing["user_id"]) != user_id or Decimal(existing["amount"]) != amount:
            raise conflict("wallet_refund_conflict", "该退款流水已按其他用户或金额记账")
        return existing
    user = one(db, "SELECT balance, status FROM app_user WHERE user_id=:id FOR UPDATE", {"id": user_id})
    if user is None or user["status"] != "active":
        raise not_found("user_not_found", "车主档案不存在或已停用")
    new_balance = Decimal(user["balance"]) + amount
    run(db, "UPDATE app_user SET balance=:balance WHERE user_id=:id", {"balance": new_balance, "id": user_id})
    result = run(
        db,
        """INSERT INTO wallet_transaction
            (user_id, refund_id, transaction_type, amount, balance_after, business_key, occurred_at)
           VALUES (:user_id, :refund_id, 'refund', :amount, :balance_after, :business_key, UTC_TIMESTAMP(3))""",
        {"user_id": user_id, "refund_id": refund_id, "amount": amount,
         "balance_after": new_balance, "business_key": business_key},
    )
    return one(db, "SELECT * FROM wallet_transaction WHERE wallet_transaction_id=:id",
               {"id": inserted_id(result)})
