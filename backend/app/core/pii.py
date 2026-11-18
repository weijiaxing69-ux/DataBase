"""Membership PII utilities; credentials and JWT remain in the shared auth module."""
from __future__ import annotations

import hashlib
import hmac
import re

from cryptography.fernet import Fernet, InvalidToken


def encrypt_text(value: str, key: str) -> bytes:
    if not key:
        raise RuntimeError("encryption key is not configured")
    return Fernet(key.encode("ascii")).encrypt(value.encode("utf-8"))


def decrypt_text(value: bytes, key: str) -> str:
    if not key:
        raise RuntimeError("decryption key is not configured")
    try:
        return Fernet(key.encode("ascii")).decrypt(value).decode("utf-8")
    except InvalidToken as exc:
        raise ValueError("encrypted value cannot be decrypted with the configured key") from exc


def keyed_digest(value: str, key: str) -> bytes:
    if not key:
        raise RuntimeError("HMAC key is not configured")
    return hmac.new(key.encode("utf-8"), value.encode("utf-8"), hashlib.sha256).digest()


def normalize_phone(value: str) -> str:
    normalized = re.sub(r"[\s()-]", "", value)
    if not re.fullmatch(r"\+?[0-9]{7,15}", normalized):
        raise ValueError("phone format is invalid")
    return normalized


def normalize_plate(value: str) -> str:
    normalized = re.sub(r"\s+", "", value).upper()
    if not re.fullmatch(r"[\u4e00-\u9fff][A-Z][A-Z0-9]{5,6}", normalized):
        raise ValueError("plate format is invalid")
    return normalized


def mask_phone(value: str) -> str:
    digits = re.sub(r"\D", "", value)
    if len(digits) < 7:
        return "***"
    return f"{digits[:3]}****{digits[-4:]}"


def mask_plate(value: str) -> str:
    if len(value) < 5:
        return "***"
    return f"{value[:2]}***{value[-2:]}"
