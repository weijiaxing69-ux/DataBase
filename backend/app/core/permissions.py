from app.core import security
from app.core.errors import forbidden
from app.shared.contracts import Actor


def require_permission(actor: Actor, permission_code: str) -> None:
    security.require_permission(actor, permission_code)


def require_role(actor: Actor, *role_codes: str) -> None:
    if "platform_admin" in actor.roles:
        return
    if actor.roles.isdisjoint(role_codes):
        raise forbidden("role_denied", "账号角色不允许执行此操作")
