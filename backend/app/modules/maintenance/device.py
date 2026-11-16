"""设备身份：把「设备凭据」换成可校验的设备主体。

背景：心跳与采样接口如果沿用人工账号令牌，任何有权限的账号都能替任意桩上报，
等于把设备侧的数据入口开放给了人。这里按 V1.4 的 `device_credential` 表做真正的设备鉴权：

- 客户端持有签发时返回的明文令牌，请求头 `X-Device-Token` 携带；
- 服务端只存 SHA-256 摘要，比对摘要而不是明文；
- 校验到期时间与撤销状态；
- 返回的 `DeviceActor` 绑定桩编号，服务层再校验请求里的 pile_id 必须一致。

令牌只在此处计算摘要，不写日志、不进异常信息。
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
