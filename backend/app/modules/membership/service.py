"""membership 模块：业务逻辑及事务边界，按 V1.4 契约逐步实现。"""
from app.core import security
from app.shared.contracts import Actor
from .schemas import AccountContext, LoginRequest, LoginResponse


def get_current_user(db, *, actor: Actor) -> AccountContext:
    return AccountContext(account_id=actor.account_id, user_id=actor.user_id,
                          roles=sorted(actor.roles), permissions=sorted(actor.permissions))


def login(db, *, actor: Actor | None, request: LoginRequest) -> LoginResponse:
    # 登录是匿名入口，actor=None；身份必须通过密码验证生成，不能由前端指定。
    token, lifetime, current = security.login_with_password(db, request.username, request.password)
    return LoginResponse(access_token=token, expires_in=lifetime,
                         account=get_current_user(db, actor=current))
