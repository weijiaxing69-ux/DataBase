"""设备身份：用 device_credential 的摘要换设备主体。

请求头 X-Device-Token 携带明文令牌；服务端只比对 SHA-256 摘要，
校验到期与撤销，返回绑定桩号的 DeviceActor。
"""

from __future__ import annotations

import hashlib
from dataclasses import dataclass
from datetime import datetime, timezone

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.errors import BusinessError
from app.modules.assets.models import DeviceCredential

MAX_TOKEN_LENGTH = 256


@dataclass(frozen=True)
class DeviceActor:
    """已通过凭据校验的设备主体。"""

    credential_id: int
    pile_id: int


def _now() -> datetime:
    return datetime.now(timezone.utc).replace(tzinfo=None)


def authenticate_device(db: Session, token: str | None) -> DeviceActor:
    """凭据换取设备身份；失败抛 401/403，不区分「不存在」与「摘要不匹配」。"""
    if not token or not token.strip():
        raise BusinessError("缺少设备凭据，请在 X-Device-Token 中提供", status_code=401)
    if len(token) > MAX_TOKEN_LENGTH:
        raise BusinessError("设备凭据格式不正确", status_code=401)

    digest = hashlib.sha256(token.encode("utf-8")).digest()
    row = db.scalar(select(DeviceCredential).where(DeviceCredential.token_hash == digest))
    if row is None:
        raise BusinessError("设备凭据无效", status_code=401)
    if row.revoked_at is not None:
        raise BusinessError("设备凭据已撤销", status_code=401)
    if row.expires_at <= _now():
        raise BusinessError("设备凭据已过期", status_code=401)

    return DeviceActor(credential_id=row.credential_id, pile_id=row.pile_id)
