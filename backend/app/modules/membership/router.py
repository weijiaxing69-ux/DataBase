"""设备联调使用的登录、当前账号及退出登录接口。"""
import hashlib
from typing import Annotated
from fastapi import APIRouter, Depends, Response
from sqlalchemy.orm import Session
from app.core import security
from app.core.database import get_db
from app.modules.assets.router import _get_request_actor, _bearer
from fastapi.security import HTTPAuthorizationCredentials
from app.shared.contracts import Actor
from . import service
from .schemas import AccountContext, EmptyRequest, LoginRequest, LoginResponse

router = APIRouter()
Database = Annotated[Session, Depends(get_db)]
CurrentActor = Annotated[Actor, Depends(_get_request_actor)]


@router.post("/login", response_model=LoginResponse, summary="账号密码登录")
def login(request: LoginRequest, db: Database):
    return service.login(db, actor=None, request=request)


@router.get("/me", response_model=AccountContext, summary="查询当前登录账号")
def get_current_user(db: Database, actor: CurrentActor):
    return service.get_current_user(db, actor=actor)


@router.post("/logout", status_code=204, summary="退出当前会话")
def logout(db: Database, actor: CurrentActor,
           credentials: Annotated[HTTPAuthorizationCredentials, Depends(_bearer)],
           request: EmptyRequest = EmptyRequest()):
    # 只撤销当前 JWT 对应的会话，不能误踢掉这个账号的其他登录设备。
    claims = security._claims(credentials.credentials)
    try:
        db.execute(security.sessions.update().where(
            security.sessions.c.account_id == actor.account_id,
            security.sessions.c.jti_hash == hashlib.sha256(claims["jti"].encode()).digest()
        ).values(revoked_at=security._now()))
        db.commit()
    except Exception:
        db.rollback()
        raise
    return Response(status_code=204)
