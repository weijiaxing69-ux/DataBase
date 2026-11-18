"""成员4联调实现：JWT + 数据库会话、角色权限和设备资源范围检查。

表名及公开签名遵循 V1.4；HS256、PBKDF2、5次失败锁定15分钟为本次自定义约定。
不自动创建表或账号；角色与权限每次从数据库读取，不信任 JWT 内的权限声明。
"""
import base64
import hashlib
import hmac
import json
import secrets
import time
from datetime import datetime, timedelta, timezone

from fastapi import HTTPException
from cryptography.exceptions import InvalidKey
from cryptography.hazmat.primitives.kdf.argon2 import Argon2id
from sqlalchemy import BigInteger, Column, DateTime, Integer, LargeBinary, MetaData, String, Table, select, text

from app.core.config import settings
from app.core.database import SessionLocal
from app.shared.contracts import Actor


# 这里只描述现有表，不会 create_all；演示库会单独创建这些表。
metadata = MetaData()
accounts = Table("sys_account", metadata,
    Column("account_id", BigInteger, primary_key=True), Column("username", String(64)),
    Column("password_hash", String(255)), Column("status", String(32)),
    Column("failed_attempts", Integer), Column("locked_until", DateTime), Column("last_login_at", DateTime))
roles = Table("sys_role", metadata, Column("role_id", BigInteger, primary_key=True), Column("role_code", String(50)))
permissions = Table("sys_permission", metadata, Column("permission_id", BigInteger, primary_key=True), Column("permission_code", String(100)))
account_roles = Table("sys_account_role", metadata, Column("account_id", BigInteger), Column("role_id", BigInteger))
role_permissions = Table("sys_role_permission", metadata, Column("role_id", BigInteger), Column("permission_id", BigInteger))
account_stations = Table("sys_account_station", metadata, Column("account_id", BigInteger), Column("station_id", BigInteger))
account_operators = Table("sys_account_operator", metadata, Column("account_id", BigInteger), Column("operator_id", BigInteger))
sessions = Table("sys_session", metadata,
    Column("session_id", BigInteger().with_variant(Integer, "sqlite"), primary_key=True, autoincrement=True),
    Column("account_id", BigInteger), Column("jti_hash", LargeBinary(32)),
    Column("expires_at", DateTime), Column("revoked_at", DateTime))


def _now():
    return datetime.now(timezone.utc).replace(tzinfo=None)


def _b64(value: bytes) -> str:
    return base64.urlsafe_b64encode(value).rstrip(b"=").decode("ascii")


def _unb64(value: str) -> bytes:
    return base64.urlsafe_b64decode(value + "=" * (-len(value) % 4))


def _key() -> bytes:
    if len(settings.auth_signing_key) < 32:
        raise HTTPException(503, "请配置至少32字符的 AUTH_SIGNING_KEY")
    return settings.auth_signing_key.encode()


def hash_password(password: str) -> str:
    # 随机盐使两个相同密码也产生不同摘要；不保存密码原文。
    salt = secrets.token_bytes(16)
    digest = hashlib.pbkdf2_hmac("sha256", password.encode(), salt, 260000)
    return f"pbkdf2_sha256$260000${_b64(salt)}${_b64(digest)}"


def verify_password(password: str, encoded: str) -> bool:
    try:
        # 统一 V1.4 种子脚本使用 Argon2id；新演示账号的 PBKDF2 也是自定义支持格式。
        if encoded.startswith("$argon2id$"):
            Argon2id.verify_phc_encoded(password.encode(), encoded)
            return True
        algorithm, rounds, salt, expected = encoded.split("$")
        if algorithm != "pbkdf2_sha256" or not 100000 <= int(rounds) <= 1000000:
            return False
        actual = hashlib.pbkdf2_hmac("sha256", password.encode(), _unb64(salt), int(rounds))
        return hmac.compare_digest(actual, _unb64(expected))
    except (ValueError, TypeError, InvalidKey):
        return False


def _actor(db, account_id: int) -> Actor:
    # 两个 JOIN 分别得到角色、角色对应的权限；distinct 去除多角色带来的重复权限。
    role_codes = db.scalars(select(roles.c.role_code).join(account_roles,
        roles.c.role_id == account_roles.c.role_id).where(account_roles.c.account_id == account_id)).all()
    permission_codes = db.scalars(select(permissions.c.permission_code).distinct()
        .join(role_permissions, permissions.c.permission_id == role_permissions.c.permission_id)
        .join(account_roles, account_roles.c.role_id == role_permissions.c.role_id)
        .where(account_roles.c.account_id == account_id)).all()
    # The standalone device demo has no app_user table; the MySQL project does.
    user_id = None
    if db.get_bind().dialect.name == "mysql":
        user_id = db.execute(text("SELECT user_id FROM app_user WHERE account_id=:id"),
                             {"id": account_id}).scalar_one_or_none()
    return Actor(account_id=account_id, user_id=user_id,
                 roles=frozenset(role_codes), permissions=frozenset(permission_codes))


def login_with_password(db, username: str, password: str):
    """登录成功返回 (JWT, 有效秒数, Actor)，失败计数和会话都保存在数据库。"""
    key = _key()
    if not 1 <= settings.auth_token_seconds <= 86400:
        raise HTTPException(503, "AUTH_TOKEN_SECONDS 必须在1至86400之间")
    try:
        account = db.execute(select(accounts).where(accounts.c.username == username).with_for_update()).mappings().one_or_none()
        now = _now()
        if account is None:
            # 不暴露账号是否存在。
            raise HTTPException(401, "账号或密码错误", headers={"WWW-Authenticate": "Bearer"})
        if account["status"] != "active":
            raise HTTPException(401, "账号已停用")
        if account["locked_until"] and account["locked_until"] > now:
            raise HTTPException(401, "账号暂时锁定，请稍后再试")
        if not verify_password(password, account["password_hash"]):
            failed = 1 if account["locked_until"] else (account["failed_attempts"] or 0) + 1
            db.execute(accounts.update().where(accounts.c.account_id == account["account_id"]).values(
                failed_attempts=failed, locked_until=now + timedelta(minutes=15) if failed >= 5 else None))
            db.commit()  # 失败计数也需要保存，不能随错误响应回滚掉。
            raise HTTPException(401, "账号或密码错误", headers={"WWW-Authenticate": "Bearer"})
        actor = _actor(db, account["account_id"])
        expires = int(time.time()) + settings.auth_token_seconds
        jti = secrets.token_urlsafe(32)
        header = _b64(json.dumps({"alg": "HS256", "typ": "JWT"}, separators=(",", ":")).encode())
        payload = _b64(json.dumps({"sub": str(actor.account_id), "jti": jti,
            "iat": int(time.time()), "exp": expires}, separators=(",", ":")).encode())
        message = header + "." + payload
        token = message + "." + _b64(hmac.new(key, message.encode(), hashlib.sha256).digest())
        db.execute(sessions.insert().values(account_id=actor.account_id,
            jti_hash=hashlib.sha256(jti.encode()).digest(),
            expires_at=datetime.fromtimestamp(expires, timezone.utc).replace(tzinfo=None)))
        db.execute(accounts.update().where(accounts.c.account_id == actor.account_id).values(
            failed_attempts=0, locked_until=None, last_login_at=now))
        db.commit()
        return token, settings.auth_token_seconds, actor
    except Exception:
        db.rollback()
        raise


def _claims(token: str):
    key = _key()
    try:
        if len(token) > 8192:
            raise ValueError()
        header, payload, signature = token.split(".")
        actual = hmac.new(key, (header + "." + payload).encode(), hashlib.sha256).digest()
        if not hmac.compare_digest(actual, _unb64(signature)):
            raise ValueError()
        if json.loads(_unb64(header)) != {"alg": "HS256", "typ": "JWT"}:
            raise ValueError()
        claims = json.loads(_unb64(payload))
        if (type(claims["exp"]) is not int or claims["exp"] <= time.time()
                or not isinstance(claims["jti"], str) or not claims["jti"]
                or int(claims["sub"]) <= 0):
            raise ValueError()
        return claims
    except (ValueError, KeyError, TypeError, UnicodeError):
        raise HTTPException(401, "登录凭证无效或已过期", headers={"WWW-Authenticate": "Bearer"}) from None


def get_current_actor(token: str) -> Actor:
    """公开契约：只接收 token；验证签名后仍必须查询有效的数据库会话。"""
    claims = _claims(token)
    with SessionLocal() as db:
        account_id = int(claims["sub"])
        session = db.execute(select(sessions.c.session_id).join(accounts,
            accounts.c.account_id == sessions.c.account_id).where(
            sessions.c.account_id == account_id,
            sessions.c.jti_hash == hashlib.sha256(claims["jti"].encode()).digest(),
            sessions.c.revoked_at.is_(None), sessions.c.expires_at > _now(),
            accounts.c.status == "active")).scalar_one_or_none()
        if session is None:
            raise HTTPException(401, "登录会话已失效", headers={"WWW-Authenticate": "Bearer"})
        return _actor(db, account_id)


def has_permission(actor: Actor, permission: str) -> bool:
    # 自定义兼容约定：旧种子只有 gun.read 与 pile.manage，本次细分接口仍接受这两个码。
    # 只映射设备权限，不把运维角色扩大成全平台管理员；范围检查依然必须执行。
    aliases = {
        "assets.pile.read": "assets.gun.read",
        "assets.pile.create": "assets.pile.manage", "assets.pile.update": "assets.pile.manage",
        "assets.gun.create": "assets.pile.manage", "assets.gun.update": "assets.pile.manage",
        "assets.change_request.read": "assets.gun.read",
        "assets.acceptance.read": "assets.gun.read", "assets.acceptance.create": "assets.pile.manage",
        "assets.device_command.read": "assets.gun.read", "assets.status_log.read": "assets.gun.read",
    }
    return ("platform_admin" in actor.roles or permission in actor.permissions
            or aliases.get(permission) in actor.permissions)


def require_permission(actor: Actor, permission: str) -> None:
    # 自定义约定：平台管理员可管理所有设备，其余角色按数据库授予的权限码判断。
    if not has_permission(actor, permission):
        raise PermissionError("缺少权限：" + permission)


def assert_resource_scope(db, actor: Actor, *, resource_type: str, resource_id: int) -> None:
    """数据库核对实际设备归属；支持本次设备联调需要的四种资源。"""
    # 放在函数内部导入，避免 ORM 初始化时循环导入。
    from app.modules.assets.models import Operator, Station, ChargingPile, ChargingGun
    from app.core.errors import BusinessError
    if resource_type == "gun":
        pile_id = db.scalar(select(ChargingGun.pile_id).where(ChargingGun.gun_id == resource_id))
        if pile_id is None:
            raise BusinessError("充电枪不存在", status_code=404)
        return assert_resource_scope(db, actor, resource_type="pile", resource_id=pile_id)
    if resource_type == "pile":
        station_id = db.scalar(select(ChargingPile.station_id).where(ChargingPile.pile_id == resource_id))
        if station_id is None:
            raise BusinessError("充电桩不存在", status_code=404)
        return assert_resource_scope(db, actor, resource_type="station", resource_id=station_id)
    if resource_type == "station":
        operator_id = db.scalar(select(Station.operator_id).where(Station.station_id == resource_id))
        if operator_id is None:
            raise BusinessError("场站不存在", status_code=404)
        if "platform_admin" in actor.roles:
            return
        station_grant = db.scalar(select(account_stations.c.station_id).where(
            account_stations.c.account_id == actor.account_id, account_stations.c.station_id == resource_id))
        operator_grant = db.scalar(select(account_operators.c.operator_id).where(
            account_operators.c.account_id == actor.account_id, account_operators.c.operator_id == operator_id))
        if station_grant is not None or operator_grant is not None:
            return
    elif resource_type == "operator":
        if db.scalar(select(Operator.operator_id).where(Operator.operator_id == resource_id)) is None:
            raise BusinessError("运营商不存在", status_code=404)
        if "platform_admin" in actor.roles:
            return
        grant = db.scalar(select(account_operators.c.operator_id).where(
            account_operators.c.account_id == actor.account_id, account_operators.c.operator_id == resource_id))
        # 仅授权某个场站不等于授权管理它的整个运营商。
        if grant is not None:
            return
    else:
        raise ValueError("不支持的资源类型：" + resource_type)
    raise PermissionError("该资源超出账号授权范围")
