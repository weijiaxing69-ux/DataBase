"""HTTP 验证：测试替身仅在测试中使用，所有业务数据写入 SQLite 内存库。"""

import asyncio
import json
import unittest
from unittest.mock import DEFAULT, patch

from fastapi import FastAPI

from app.core.database import get_db, engine as mysql_engine
from app.modules.assets import router as routes, service
import test_operator_local


class AssetsHttpTests(test_operator_local.OperatorLocalTests):
    def setUp(self):
        super().setUp()
        # 禁止连接真正的 MySQL；测试一旦误用生产数据库依赖就直接失败。
        self.mysql_guard = patch.object(
            mysql_engine, "connect", side_effect=AssertionError("HTTP测试禁止访问MySQL")
        )
        self.mysql_guard.start()
        self.app = FastAPI()
        self.app.include_router(routes.router, prefix="/api/v1/assets")
        self.app.dependency_overrides[get_db] = lambda: self.db

    def tearDown(self):
        self.app.dependency_overrides.clear()
        self.mysql_guard.stop()
        super().tearDown()

    def _request(self, method, path, body=None, query="", token=False):
        # 直接调用 ASGI，验证真实 FastAPI 参数解析和响应，不依赖额外 HTTP 客户端。
        messages = []
        headers = [(b"content-type", b"application/json")]
        if token:
            headers.append((b"authorization", b"Bearer test-only"))

        async def receive():
            return {"type":"http.request", "body":json.dumps(body).encode()
                    if body is not None else b"", "more_body":False}

        async def send(message):
            messages.append(message)

        scope = dict(type="http", asgi={"version":"3.0"}, http_version="1.1",
                     method=method, scheme="http", path=path, raw_path=path.encode(),
                     query_string=query.encode(), root_path="", headers=headers,
                     client=("test", 1), server=("test", 80))
        asyncio.run(self.app(scope, receive, send))
        status = next(m["status"] for m in messages if m["type"] == "http.response.start")
        content = b"".join(m.get("body", b"") for m in messages
                           if m["type"] == "http.response.body")
        return status, json.loads(content)

    def _enable_test_identity(self):
        self.app.dependency_overrides[routes._require_scope_integration] = lambda: None
        self.app.dependency_overrides[routes._get_request_actor] = lambda: self.actor

    def test_http_authentication_and_scope_gate(self):
        path = "/api/v1/assets/operators"
        # 公共安全函数已接入：未登录返回401；函数被移除时仍返回503。
        self.assertEqual(self._request("GET", path)[0], 401)
        with patch.object(service.security, "assert_resource_scope", None):
            self.assertEqual(self._request("GET", path)[0], 503)
        self.app.dependency_overrides[routes._require_scope_integration] = lambda: None
        self.assertEqual(self._request("GET", path)[0], 401)
        # 测试缺少公共认证函数的情况，不将 token 当成真实登录身份。
        with patch.object(service.security, "get_current_actor", None, create=True):
            self.assertEqual(self._request("GET", path, token=True)[0], 503)

    def test_http_operator_create_list_detail_update(self):
        self._enable_test_identity()
        root = "/api/v1/assets/operators"
        status, created = self._request("POST", root, dict(
            operator_name="HTTP测试运营商", credit_code="HTTP001",
            contact_name="测试联系人", contact_phone="13812345678",
        ))
        self.assertEqual(status, 200)
        self.assertIsInstance(created["operator_id"], str)
        self.assertTrue(created["created_at"].endswith("Z"))
        self.assertNotIn("contact_phone_cipher", created)
        status, page = self._request("GET", root, query="page=1&page_size=1")
        self.assertEqual(status, 200)
        self.assertEqual(page["total"], 1)
        detail_path = root + "/" + created["operator_id"]
        # 只替换尚未实现的公共权限，Router/Service/DAO/数据库读取均实际执行。
        with patch.object(service.security, "require_permission", create=True) as permission, \
                patch.object(service.security, "assert_resource_scope", create=True) as scope:
            status, detail = self._request("GET", detail_path)
            self.assertEqual(status, 200)
            self.assertEqual(detail["operator_name"], "HTTP测试运营商")
            permission.assert_called_once()
            scope.assert_called_once()
        status, updated = self._request("PATCH", detail_path, {"operator_name":"更新名称"})
        self.assertEqual(status, 200)
        self.assertEqual(updated["operator_name"], "更新名称")
        self.assertEqual(updated["contact_name"], "测试联系人")

    def test_http_invalid_parameters(self):
        self._enable_test_identity()
        root = "/api/v1/assets/operators"
        for query in ("page=0", "page_size=101", "page=abc",
                      "start_at=2026-01-02T00:00:00Z&end_at=2026-01-01T00:00:00Z"):
            self.assertEqual(self._request("GET", root, query=query)[0], 422)
        self.assertEqual(self._request("GET", root+"/0")[0], 422)
        self.assertEqual(self._request("POST", root, {})[0], 422)
        for body in ({}, {"status":None}, {"status":"draft"}, {"credit_code":"NEW"}):
            self.assertEqual(self._request("PATCH", root+"/1", body)[0], 422)


    def test_http_pile_routes_forward_parameters(self):
        # 只替换 Service，验证四条路由的参数传递及真实响应序列化。
        self._enable_test_identity()
        from datetime import datetime
        from app.modules.assets.schemas import PileDetail
        from app.shared.contracts import PageResult

        detail = PileDetail(
            pile_id=1, station_id=2, serial_no="P001", model_name="DC",
            rated_power_kw="120.000", protocol="test", commissioned_on=None,
            warranty_until=None, lifecycle_status="draft", status="offline",
            has_fault=False, is_online=False, last_heartbeat_at=None,
            created_at=datetime(2026, 1, 1), updated_at=datetime(2026, 1, 1),
        )
        base = "/api/v1/assets/piles"
        with patch.object(service, "list_piles", return_value=PageResult[PileDetail](
            items=[detail], total=1, page=2, page_size=5
        )) as call:
            status, data = self._request("GET", base, query="page=2&page_size=5&station_id=2&status=offline")
            self.assertEqual(status, 200)
            self.assertEqual(data["items"][0]["pile_id"], "1")
            query = call.call_args.kwargs["query"]
            self.assertEqual((query.page, query.page_size, query.station_id, query.status), (2, 5, 2, "offline"))
        with patch.object(service, "get_pile", return_value=detail) as call:
            status, data = self._request("GET", base + "/1")
            self.assertEqual(status, 200)
            self.assertEqual(data["created_at"], "2026-01-01T00:00:00.000Z")
            call.assert_called_once_with(self.db, actor=self.actor, pile_id=1)
        with patch.object(service, "create_pile", return_value=detail) as call:
            status, _ = self._request("POST", base, body=dict(
                station_id=2, serial_no="P001", model_name="DC", rated_power_kw="120.000", protocol="test"
            ))
            self.assertEqual(status, 200)
            self.assertEqual(call.call_args.kwargs["request"].serial_no, "P001")
        with patch.object(service, "update_pile", return_value=detail) as call:
            status, _ = self._request("PATCH", base + "/1", body={"warranty_until": None})
            self.assertEqual(status, 200)
            self.assertEqual(call.call_args.kwargs["request"].model_dump(exclude_unset=True), {"warranty_until": None})

    def test_http_pile_invalid_parameters(self):
        self._enable_test_identity()
        base = "/api/v1/assets/piles"
        with patch.multiple(service, list_piles=DEFAULT, get_pile=DEFAULT,
                            create_pile=DEFAULT, update_pile=DEFAULT) as calls:
            cases = [
                ("GET", base, None, "page=0"),
                ("GET", base, None, "status=wrong"),
                ("GET", base, None, "start_at=2026-02-01T00:00:00Z&end_at=2026-01-01T00:00:00Z"),
                ("GET", base + "/0", None, ""),
                ("POST", base, {}, ""),
                ("PATCH", base + "/1", {}, ""),
                ("PATCH", base + "/1", {"model_name": None}, ""),
                ("PATCH", base + "/1", {"status": "idle"}, ""),
            ]
            for method, path, body, query in cases:
                with self.subTest(method=method, path=path, body=body, query=query):
                    self.assertEqual(self._request(method, path, body=body, query=query)[0], 422)
            for call in calls.values():
                call.assert_not_called()


if __name__ == "__main__":
    unittest.main()
