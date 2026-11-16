from datetime import datetime, timedelta, timezone
from hashlib import sha256
from uuid import uuid4

from argon2 import PasswordHasher
from argon2.exceptions import InvalidHashError, VerificationError
from fastapi import APIRouter, Depends, Request, Response
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
import jwt
from pydantic import BaseModel, ConfigDict, Field
from sqlalchemy.orm import Session

from .database import all_rows, execute, one
from .errors import require
from .serialization import wire

router = APIRouter(prefix="/api/v1/auth", tags=["本地联调登录"])
bearer = HTTPBearer(auto_error=False)
password_hasher = PasswordHasher()


class LoginRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")
    username: str = Field(min_length=1, max_length=64)
    password: str = Field(min_length=1, max_length=200)


def account_context(db, account_id):
    roles = all_rows(db, """
        SELECT r.role_code FROM sys_account_role ar JOIN sys_role r USING(role_id)
        WHERE ar.account_id=:id ORDER BY r.role_code
    """, id=account_id)
    permissions = all_rows(db, """
        SELECT DISTINCT p.permission_code FROM sys_account_role ar
        JOIN sys_role_permission rp USING(role_id) JOIN sys_permission p USING(permission_id)
        WHERE ar.account_id=:id ORDER BY p.permission_code
    """, id=account_id)
    user = one(db, "SELECT user_id FROM app_user WHERE account_id=:id", id=account_id)
    return dict(account_id=account_id, user_id=user["user_id"] if user else None,
                roles=[r["role_code"] for r in roles],
                permissions=[p["permission_code"] for p in permissions],
                home_path="/settlement/settlements")


@router.post("/login")
def login(body: LoginRequest, request: Request):
    now = datetime.now(timezone.utc)
    expires = now + timedelta(hours=1)
    with Session(request.app.state.engine) as db, db.begin():
        row = one(db, "SELECT * FROM sys_account WHERE username=:name FOR UPDATE", name=body.username)
        eligible = row and row["status"] == "active" and (
            row["locked_until"] is None or row["locked_until"] <= now.replace(tzinfo=None)
        )
        valid = False
        if eligible:
            try:
                valid = password_hasher.verify(row["password_hash"], body.password)
            except (VerificationError, InvalidHashError):
                failures = (0 if row["locked_until"] else row["failed_attempts"]) + 1
                execute(db, """UPDATE sys_account SET failed_attempts=:count, locked_until=:until
                    WHERE account_id=:id""", count=failures,
                    until=(now + timedelta(minutes=15)).replace(tzinfo=None) if failures >= 5 else None,
                    id=row["account_id"])
        if valid:
            account_id = row["account_id"]
            execute(db, """UPDATE sys_account SET failed_attempts=0, locked_until=NULL,
                last_login_at=UTC_TIMESTAMP(3) WHERE account_id=:id""", id=account_id)
            jti = uuid4().hex
            execute(db, "INSERT INTO sys_session(account_id,jti_hash,expires_at) VALUES(:id,:hash,:expires)",
                    id=account_id, hash=sha256(jti.encode()).digest(), expires=expires.replace(tzinfo=None))
            context = account_context(db, account_id)
    require(valid, 401, "INVALID_LOGIN", "账号、密码或账号状态无效。")
    token = jwt.encode({"sub": str(account_id), "jti": jti, "exp": expires},
                       request.app.state.jwt_secret, algorithm="HS256")
    return dict(access_token=token, token_type="bearer", expires_in=3600, account=wire(context))


def current_actor(request: Request, credentials: HTTPAuthorizationCredentials | None = Depends(bearer)):
    payload = {}
    if credentials:
        try:
            payload = jwt.decode(credentials.credentials, request.app.state.jwt_secret,
                                 algorithms=["HS256"], options={"require": ["exp", "sub", "jti"]})
        except jwt.InvalidTokenError:
            pass
    require(bool(payload), 401, "AUTH_REQUIRED", "请登录。")
    token_hash = sha256(payload["jti"].encode()).digest()
    with Session(request.app.state.engine) as db:
        row = one(db, """SELECT a.account_id FROM sys_account a JOIN sys_session s USING(account_id)
            WHERE a.account_id=:id AND a.status='active' AND s.jti_hash=:hash
              AND s.revoked_at IS NULL AND s.expires_at > UTC_TIMESTAMP(3)""",
            id=payload["sub"], hash=token_hash)
        require(row is not None, 401, "AUTH_REQUIRED", "登录已过期。")
        return {**account_context(db, row["account_id"]), "token_hash": token_hash}


@router.get("/me")
def me(actor=Depends(current_actor)):
    return wire({key: value for key, value in actor.items() if key != "token_hash"})


@router.post("/logout", status_code=204)
def logout(request: Request, actor=Depends(current_actor)):
    with Session(request.app.state.engine) as db, db.begin():
        execute(db, "UPDATE sys_session SET revoked_at=UTC_TIMESTAMP(3) WHERE jti_hash=:hash",
                hash=actor["token_hash"])
    return Response(status_code=204)
