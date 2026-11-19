from __future__ import annotations

from datetime import UTC, datetime, timedelta, timezone

import pytest

from app.core.errors import BusinessError
from app.core.pii import (
    decrypt_text,
    encrypt_text,
    keyed_digest,
    mask_phone,
    mask_plate,
    normalize_phone,
    normalize_plate,
)
from app.core.security import (
    hash_password,
    verify_password,
)
from app.modules.membership.dao import to_utc_naive
from app.modules.membership.schemas import (
    CreateAppealRequest,
    RegisterUserRequest,
    ReviewWalletBalanceRefundRequest,
    TopupRequest,
    WalletBalanceRefundQuery,
    WalletBalanceRefundRequest,
)
from app.modules.membership.service import _safe_phone, _safe_plate
from cryptography.fernet import Fernet
from decimal import Decimal


def test_phone_and_plate_normalization_and_masking():
    phone = normalize_phone("+86 138-0013-8000")
    assert phone == "+8613800138000"
    assert mask_phone(phone).endswith("8000")
    plate = normalize_plate(" 京a12345 ")
    assert plate == "京A12345"
    assert mask_plate(plate) == "京A***45"


@pytest.mark.parametrize("value", ["", "abc", "123", "京A123"])
def test_invalid_sensitive_values_are_rejected_as_business_errors(value):
    with pytest.raises(BusinessError) as phone_error:
        _safe_phone(value)
    assert phone_error.value.status_code == 422
    with pytest.raises(BusinessError) as plate_error:
        _safe_plate(value)
    assert plate_error.value.status_code == 422


def test_password_hash_and_encryption_are_one_way_or_authenticated():
    password_hash = hash_password("correct horse battery staple")
    assert password_hash != "correct horse battery staple"
    assert verify_password("correct horse battery staple", password_hash)
    assert not verify_password("wrong password", password_hash)

    key = Fernet.generate_key().decode("ascii")
    encrypted = encrypt_text("13800138000", key)
    assert encrypted != b"13800138000"
    assert decrypt_text(encrypted, key) == "13800138000"
    assert keyed_digest("13800138000", "test-key") == keyed_digest("13800138000", "test-key")
    assert keyed_digest("13800138000", "test-key") != keyed_digest("13800138001", "test-key")


def test_request_schemas_enforce_server_side_input_bounds():
    with pytest.raises(ValueError):
        RegisterUserRequest(username="ab", password="short", display_name="A", phone="13800138000")
    with pytest.raises(ValueError):
        TopupRequest(amount=Decimal("0"))
    assert TopupRequest(amount=Decimal("10.25")).amount == Decimal("10.25")


def test_wallet_refund_and_appeal_schemas_require_valid_idempotency_keys():
    refund = WalletBalanceRefundRequest(
        amount=Decimal("12.50"), reason="停止使用平台服务", request_key="refund_12345678",
    )
    assert refund.amount == Decimal("12.50")
    assert ReviewWalletBalanceRefundRequest(decision="processing", note="正在核对退款信息").decision == "processing"
    assert WalletBalanceRefundQuery(status="processing").status == "processing"
    with pytest.raises(ValueError):
        ReviewWalletBalanceRefundRequest(decision="unknown")
    appeal = CreateAppealRequest(
        category="billing_dispute", order_id=None, subject="服务费有疑问",
        description="我想核对这笔订单的服务费", request_key="appeal_12345678",
    )
    assert appeal.order_id is None
    with pytest.raises(ValueError):
        WalletBalanceRefundRequest(amount=Decimal("-1"), reason="退钱", request_key="short")


def test_datetime_conversion_always_stores_utc_without_timezone_marker():
    local = datetime(2026, 11, 13, 21, 30, tzinfo=timezone(timedelta(hours=8)))
    utc_value = to_utc_naive(local)
    assert utc_value == datetime(2026, 11, 13, 13, 30)
    assert utc_value.tzinfo is None
    assert to_utc_naive(datetime(2026, 11, 13, 13, 30, tzinfo=UTC)) == utc_value
