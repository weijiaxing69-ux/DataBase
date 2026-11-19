"""两个独立 HTTP 客户端同时接单：验证行锁只放行一方。

与 test_maintenance.py 的线程级测试不同，这里从真实路由进入，
覆盖「两个会话 + 两个 TestClient + 同一工单」的并发场景。
"""

from __future__ import annotations

import hashlib
import hmac
import json
import secrets
import threading
import time
from datetime import datetime, timezone

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import text

from app.core import security
from app.core.config import settings
from app.core.database import SessionLocal, engine
from app.main import app
from app.modules.maintenance import schemas as s
from app.modules.maintenance import service
from app.shared.contracts import Actor


def _db_ready() -> bool:
    try:
        with engine.connect() as conn:
            conn.execute(text("select 1"))
        return True
    except Exception:  # noqa: BLE001
        return False


pytestmark = pytest.mark.skipif(not _db_ready(), reason="MySQL 未启动，跳过并发客户端测试")

ADMIN = Actor(account_id=101, roles=frozenset({"platform_admin"}), permissions=frozenset())


def _mint_token(account_id: int = 102) -> str:
    db = SessionLocal()
    try:
        jti = secrets.token_urlsafe(32)
        expires = int(time.time()) + 3600
        db.execute(
            security.sessions.insert().values(
                account_id=account_id,
                jti_hash=hashlib.sha256(jti.encode()).digest(),
                expires_at=datetime.fromtimestamp(expires, timezone.utc).replace(tzinfo=None),
            )
        )
        db.commit()
    finally:
        db.close()

    b64 = security._b64
    header = b64(json.dumps({"alg": "HS256", "typ": "JWT"}, separators=(",", ":")).encode())
    payload = b64(
        json.dumps(
            {"sub": str(account_id), "jti": jti, "iat": int(time.time()), "exp": expires},
            separators=(",", ":"),
        ).encode()
    )
    message = header + "." + payload
    return message + "." + b64(hmac.new(settings.auth_signing_key.encode(), message.encode(), hashlib.sha256).digest())


@pytest.fixture()
def db():
    session = SessionLocal()
    try:
        yield session
    finally:
        session.close()


def _make_order(db):
    code = "CONC-" + secrets.token_hex(4)
    now = datetime.now(timezone.utc).replace(tzinfo=None, microsecond=0)
    db.execute(
        text(
            "insert into device_alert "
            "(pile_id, gun_id, alarm_rule_id, alert_code, severity, occurred_at, status, response_seconds_snapshot) "
            "values (8, 8, 1, :c, 'low', :t, 'processing', 600)"
        ),
        {"c": code, "t": now},
    )
    db.commit()
    alert_id = db.execute(text("select last_insert_id()")).scalar_one()
    order = service.create_work_order(
        db, actor=ADMIN,
        alert_id=alert_id,
        request=s.CreateWorkOrderRequest(assigned_to=102),
    )
    return alert_id, order.work_order_id


def test_two_clients_accept_one_order(db):
    alert_id, work_order_id = _make_order(db)
    tokens = [_mint_token(), _mint_token()]
    clients = [TestClient(app) for _ in range(2)]
    barrier = threading.Barrier(2)
    statuses: list[int] = []

    def worker(index: int) -> None:
        with clients[index] as client:
            barrier.wait(timeout=8)
            response = client.post(
                f"/api/v1/maintenance/work-orders/{work_order_id}/events",
                headers={"Authorization": f"Bearer {tokens[index]}"},
                json={"event_type": "accepted"},
            )
            statuses.append(response.status_code)

    threads = [threading.Thread(target=worker, args=(i,)) for i in range(2)]
    for thread in threads:
        thread.start()
    for thread in threads:
        thread.join(timeout=20)

    assert all(not thread.is_alive() for thread in threads), "并发请求未在 20 秒内结束"
    assert statuses.count(200) == 1, f"两客户端只能有一方成功，实际 {statuses}"
    assert all(code in (400, 409) for code in statuses if code != 200), f"失败方应返回业务或冲突错误，实际 {statuses}"

    db.execute(
        text("delete from work_order_event where work_order_id = :w"), {"w": work_order_id}
    )
    db.execute(text("delete from work_order where work_order_id = :w"), {"w": work_order_id})
    db.execute(text("delete from device_alert where alert_id = :a"), {"a": alert_id})
    db.commit()
