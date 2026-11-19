"""HTTP 层冒烟测试：验证路由、鉴权与响应结构，不验证业务分支。

业务细节由 test_maintenance.py（服务层 + 真实 MySQL）覆盖；
这里只保证"接口真的能通、字段真的能序列化"，避免出现
服务层测试全绿、但路由忘了注册或 response_model 对不上的情况。
"""

from __future__ import annotations

import hashlib
import hmac
import json
import re
import secrets
import time
from datetime import datetime, timezone
from pathlib import Path

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import text

from app.core import security
from app.core.config import settings
from app.core.database import SessionLocal, engine
from app.main import app


def _db_ready() -> bool:
    try:
        with engine.connect() as conn:
            conn.execute(text("select 1"))
        return True
    except Exception:  # noqa: BLE001
        return False


pytestmark = pytest.mark.skipif(not _db_ready(), reason="MySQL 未启动，跳过接口冒烟测试")


def _mint_token(account_id: int = 101) -> str:
    """签发一枚真实会话令牌（与登录接口生成的格式一致）。"""
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

    key = settings.auth_signing_key.encode()
    b64 = security._b64
    header = b64(json.dumps({"alg": "HS256", "typ": "JWT"}, separators=(",", ":")).encode())
    payload = b64(
        json.dumps(
            {"sub": str(account_id), "jti": jti, "iat": int(time.time()), "exp": expires},
            separators=(",", ":"),
        ).encode()
    )
    message = header + "." + payload
    return message + "." + b64(hmac.new(key, message.encode(), hashlib.sha256).digest())


@pytest.fixture(scope="module")
def client():
    with TestClient(app) as test_client:
        yield test_client


@pytest.fixture(scope="module")
def auth():
    return {"Authorization": f"Bearer {_mint_token()}"}


LIST_ENDPOINTS = [
    "/api/v1/maintenance/alerts?page_size=2",
    "/api/v1/maintenance/work-orders?page_size=2",
    "/api/v1/maintenance/alarm-rules?page_size=2",
    "/api/v1/maintenance/fault-reports?page_size=2",
    "/api/v1/maintenance/inspections?page_size=2",
    "/api/v1/maintenance/spare-parts?page_size=2",
    "/api/v1/maintenance/part-usages?work_order_id=1",
    "/api/v1/maintenance/part-movements?part_id=901",
    "/api/v1/maintenance/incidents",
    "/api/v1/maintenance/stats/overview",
    "/api/v1/maintenance/stats/performance",
]


def test_health(client):
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "ok"


def test_requires_token(client):
    assert client.get("/api/v1/maintenance/alerts").status_code == 401


@pytest.mark.parametrize("path", LIST_ENDPOINTS)
def test_list_endpoints_return_data(client, auth, path):
    response = client.get(path, headers=auth)
    assert response.status_code == 200, response.text
    body = response.json()
    assert body is not None


def test_alerts_page_shape(client, auth):
    body = client.get("/api/v1/maintenance/alerts?page_size=2", headers=auth).json()
    assert set(body) >= {"items", "total", "page", "page_size"}
    assert body["page"] == 1 and body["page_size"] == 2
    assert len(body["items"]) <= 2


def test_overview_shape(client, auth):
    body = client.get("/api/v1/maintenance/stats/overview", headers=auth).json()
    assert set(body["kpi"]) >= {"open_alerts", "overdue_orders", "open_orders", "active_incidents"}


def test_performance_serializes_datetime(client, auth):
    body = client.get("/api/v1/maintenance/stats/performance", headers=auth).json()
    assert isinstance(body["operators"], list)
    assert "generated_at" in body


def test_incident_board_shape(client, auth):
    body = client.get("/api/v1/maintenance/incidents", headers=auth).json()
    assert isinstance(body, list)
    if body:
        assert {"incident_id", "title", "detected_at", "status"} <= set(body[0])


def test_task_rejects_non_admin(client):
    engineer = {"Authorization": f"Bearer {_mint_token(102)}"}
    response = client.post("/api/v1/maintenance/tasks/offline/run", headers=engineer)
    assert response.status_code == 403


def test_task_rejects_unknown_name(client, auth):
    response = client.post("/api/v1/maintenance/tasks/not-a-task/run", headers=auth)
    assert response.status_code == 422


def test_frontend_api_covers_all_routes():
    root = Path(__file__).resolve().parents[3]
    text = (root / "frontend/src/api/maintenance.js").read_text(encoding="utf-8")
    js_paths = {
        re.sub(r"\$\{[^}]+\}", "{}", raw)
        for raw in re.findall(r"['\"`](/maintenance/[^'\"`]+)['\"`]", text)
    }
    api_paths = {
        re.sub(r"\{[^}]+\}", "{}", path.replace("/api/v1", ""))
        for path in app.openapi()["paths"]
        if path.startswith("/api/v1/maintenance")
    }
    assert api_paths <= js_paths, f"前端 API 缺少路径：{sorted(api_paths - js_paths)}"

    console = (root / "frontend/src/views/maintenance/MaintenanceConsole.vue").read_text(encoding="utf-8")
    detail_apis = ["getAlarmRule", "getAlert", "getWorkOrder", "getFaultReport", "getInspection"]
    assert all(f"api.{name}" in console for name in detail_apis), "运维工作台缺少单条详情入口"
