"""真实认证和资源范围的完整 HTTP 联调；唯一替换的是数据库连接，禁止连接 MySQL。"""
import asyncio
import hashlib
import json
import unittest
from datetime import datetime, timedelta, timezone
from unittest.mock import patch
from sqlalchemy import select, text
from app.core import security
from app.core.config import settings
from app.core.database import engine as mysql_engine
from app.demo import build_demo_app
from app.demo_data import create_demo_database, DEMO_PASSWORD
from app.modules.assets import dao, models, service
from app.modules.assets.worker import dispatch_next


class AuthDeviceIntegrationTests(unittest.TestCase):
    def setUp(self):
        guard = patch.object(mysql_engine, "connect", side_effect=AssertionError("禁止连接MySQL"))
        guard.start()
        self.addCleanup(guard.stop)
        self.engine, self.factory, phone_key = create_demo_database()
        self.addCleanup(self.engine.dispose)
        for obj, name, value in ((security, "SessionLocal", self.factory),
            (settings, "auth_signing_key", "integration-only-key-0123456789abcdef"),
            (settings, "phone_encryption_key", phone_key)):
            replacement = patch.object(obj, name, value)
            replacement.start()
            self.addCleanup(replacement.stop)
        self.app = build_demo_app(self.factory)

    def request(self, method, path, body=None, token=None, query=""):
        messages = []
        headers = [(b"content-type", b"application/json")]
        if token:
            headers.append((b"authorization", ("Bearer " + token).encode()))
        async def receive():
            return {"type": "http.request", "body": json.dumps(body).encode() if body is not None else b"", "more_body": False}
        async def send(message):
            messages.append(message)
        scope = dict(type="http", asgi={"version": "3.0"}, http_version="1.1", method=method,
            scheme="http", path=path, raw_path=path.encode(), query_string=query.encode(),
            root_path="", headers=headers, client=("test", 1), server=("test", 80))
        asyncio.run(self.app(scope, receive, send))
        status = next(m["status"] for m in messages if m["type"] == "http.response.start")
        raw = b"".join(m.get("body", b"") for m in messages if m["type"] == "http.response.body")
        return status, json.loads(raw) if raw else None

    def login(self, username="platform_admin"):
        status, response = self.request("POST", "/api/v1/auth/login", {"username": username, "password": DEMO_PASSWORD})
        self.assertEqual(status, 200, response)
        return response["access_token"]

    def test_real_login_me_tamper_and_current_session_logout(self):
        self.assertEqual(self.request("GET", "/api/v1/assets/piles")[0], 401)
        token, another = self.login(), self.login()
        self.assertEqual(self.request("GET", "/api/v1/auth/me", token=token)[1]["roles"], ["platform_admin"])
        self.assertEqual(self.request("GET", "/api/v1/assets/piles", token=token)[0], 200)
        self.assertEqual(self.request("GET", "/api/v1/assets/piles", token=token + "x")[0], 401)
        self.assertEqual(self.request("POST", "/api/v1/auth/logout", {}, token=token)[0], 204)
        self.assertEqual(self.request("GET", "/api/v1/auth/me", token=token)[0], 401)
        self.assertEqual(self.request("GET", "/api/v1/auth/me", token=another)[0], 200)

    def test_wrong_password_lock_and_disabled_or_expired_session(self):
        for _ in range(5):
            self.assertEqual(self.request("POST", "/api/v1/auth/login", {"username": "maintenance_engineer", "password": "wrong"})[0], 401)
        self.assertEqual(self.request("POST", "/api/v1/auth/login", {"username": "maintenance_engineer", "password": DEMO_PASSWORD})[0], 401)
        token = self.login()
        with self.factory() as db:
            db.execute(security.accounts.update().where(security.accounts.c.account_id == 1).values(status="disabled"))
            db.commit()
        self.assertEqual(self.request("GET", "/api/v1/auth/me", token=token)[0], 401)
        with self.factory() as db:
            db.execute(security.accounts.update().where(security.accounts.c.account_id == 1).values(status="active"))
            db.execute(security.sessions.update().values(expires_at=service._now() - timedelta(seconds=1)))
            db.commit()
        self.assertEqual(self.request("GET", "/api/v1/auth/me", token=token)[0], 401)

    def test_signed_but_unregistered_and_expired_tokens_rejected(self):
        import hmac
        token = self.login()
        header, payload, _ = token.split(".")
        claims = json.loads(security._unb64(payload))
        for updates in ({"jti": "not-a-session"}, {"exp": 1}):
            changed = claims | updates
            message = header + "." + security._b64(json.dumps(changed).encode())
            forged = message + "." + security._b64(hmac.new(settings.auth_signing_key.encode(), message.encode(), hashlib.sha256).digest())
            self.assertEqual(self.request("GET", "/api/v1/auth/me", token=forged)[0], 401)

    def test_station_and_operator_scope_before_page_and_count(self):
        engineer, manager = self.login("maintenance_engineer"), self.login("operator_manager")
        for resource in ("stations", "piles", "guns"):
            status, page = self.request("GET", "/api/v1/assets/" + resource, token=engineer, query="page_size=1&page=2")
            self.assertEqual((status, page["total"], page["items"]), (200, 1, []))
            self.assertEqual(self.request("GET", f"/api/v1/assets/{resource}/2", token=engineer)[0], 403)
        self.assertEqual(self.request("GET", "/api/v1/assets/operators", token=engineer)[1]["total"], 0)
        self.assertEqual(self.request("GET", "/api/v1/assets/operators", token=manager)[1]["total"], 1)
        # 修改数据库授权后，已登录账号下一次请求立刻按新范围判断。
        with self.factory() as db:
            db.execute(security.account_stations.delete().where(security.account_stations.c.account_id == 2))
            db.commit()
        self.assertEqual(self.request("GET", "/api/v1/assets/piles/1", token=engineer)[0], 403)

    def test_permissions_are_reloaded_and_other_roles_cannot_manage_devices(self):
        for role in ("customer_service", "vehicle_owner", "fleet_admin"):
            self.assertEqual(self.request("GET", "/api/v1/assets/piles", token=self.login(role))[0], 403)
        token = self.login("maintenance_engineer")
        with self.factory() as db:
            # 同时撤销细分权限与旧种子的兼容权限，保留任一有效授权时都应允许读取。
            pids = select(security.permissions.c.permission_id).where(
                security.permissions.c.permission_code.in_(("assets.pile.read", "assets.gun.read")))
            db.execute(security.role_permissions.delete().where(security.role_permissions.c.role_id == 2,
                security.role_permissions.c.permission_id.in_(pids)))
            db.commit()
        self.assertEqual(self.request("GET", "/api/v1/assets/piles", token=token)[0], 403)

    def test_change_approval_uses_real_roles_and_scope(self):
        engineer, admin = self.login("maintenance_engineer"), self.login()
        base = "/api/v1/assets/change-requests"
        body = {"pile_id": 1, "change_type": "archive", "proposed_data": {"model_name": "NEW"}, "reason": "修改型号"}
        status, row = self.request("POST", base, body, token=engineer)
        self.assertEqual(status, 200, row)
        self.assertEqual(self.request("POST", base, body | {"pile_id": 2}, token=engineer)[0], 403)
        review = base + "/" + row["request_id"] + "/reviews"
        self.assertEqual(self.request("POST", review, {"decision": "approved"}, token=engineer)[0], 403)
        self.assertEqual(self.request("POST", review, {"decision": "approved"}, token=admin)[0], 200)
        self.assertEqual(self.request("GET", "/api/v1/assets/piles/1", token=admin)[1]["model_name"], "NEW")

    def _ready_device(self, admin):
        tests = {name: True for name in ("protocol_test_passed", "nameplate_checked", "start_stop_passed", "heartbeat_passed")}
        status, result = self.request("POST", "/api/v1/assets/acceptances", {"pile_id": 1, **tests}, token=admin)
        self.assertEqual(status, 200, result)
        status, issued = self.request("POST", "/api/v1/assets/piles/1/credentials",
            {"expires_at": (datetime.now(timezone.utc) + timedelta(hours=1)).isoformat()}, token=admin)
        self.assertEqual(status, 200, issued)
        self.assertEqual(self.request("POST", "/api/v1/demo/heartbeat", token=issued["secret_token"])[0], 200)
        # 不等待30秒：仅在测试库补入窗口起点采样，验证真实恢复函数。
        with self.factory() as db:
            db.execute(text("INSERT INTO device_reading VALUES (99,1,:normal,30,0,NULL)"),
                       {"normal": service._now() - timedelta(seconds=40)})
            db.commit()
        status, result = self.request("POST", "/api/v1/demo/piles/1/recover", token=admin)
        self.assertEqual(status, 200, result)
        return issued["secret_token"]

    def test_accept_credential_heartbeat_recovery_order_dispatch_and_release(self):
        admin = self.login()
        device_token = self._ready_device(admin)
        self.assertEqual(self.request("POST", "/api/v1/demo/heartbeat", token="bad-device-token")[0], 401)
        status, order = self.request("POST", "/api/v1/demo/orders", {"gun_id": 1}, token=admin)
        self.assertEqual(status, 200, order)
        self.assertEqual(self.request("GET", "/api/v1/assets/guns/1", token=admin)[1]["status"], "occupied")
        self.assertEqual(self.request("POST", "/api/v1/demo/orders", {"gun_id": 1}, token=admin)[0], 409)
        self.assertEqual(self.request("POST", "/api/v1/demo/dispatch", token=admin), (200, {"processed": True}))
        command = self.request("GET", "/api/v1/assets/device-commands/" + order["command_id"], token=admin)[1]
        self.assertEqual((command["status"], command["attempt_count"]), ("succeeded", 1))
        status, finished = self.request("POST", "/api/v1/demo/orders/" + order["order_id"] + "/finish", token=admin)
        self.assertEqual(status, 200, finished)
        self.assertEqual(self.request("POST", "/api/v1/demo/dispatch", token=admin)[0], 200)
        self.assertEqual(self.request("GET", "/api/v1/assets/guns/1", token=admin)[1]["status"], "idle")
        self.assertEqual(self.request("GET", "/api/v1/assets/status-logs", token=admin)[1]["total"], 4)
        self.assertEqual(self.request("POST", "/api/v1/demo/dispatch", token=admin)[1], {"processed": False})
        with self.factory() as db:
            db.execute(models.DeviceCredential.__table__.update().values(revoked_at=service._now()))
            db.commit()
        self.assertEqual(self.request("POST", "/api/v1/demo/heartbeat", token=device_token)[0], 401)

    def test_worker_retry_failure_and_expired_lease(self):
        self._ready_device(self.login())
        with self.factory() as db:
            db.execute(dao._orders.insert().values(order_id=1, gun_id=1, status="charging"))
            service.claim_gun_for_order(db, gun_id=1, order_id=1)
            service.enqueue_device_command(db, gun_id=1, order_id=1, command_type="start")
            db.commit()
            def disconnected(message):
                raise ConnectionError("private detail must not be saved")
            self.assertTrue(dispatch_next(db, send=disconnected))
            event = db.scalar(select(models.OutboxEvent))
            self.assertEqual((event.status, event.attempt_count), ("pending", 1))
            self.assertNotIn("private", event.last_error)
            self.assertFalse(dispatch_next(db, send=lambda message: True))
            event.status = "processing"
            event.locked_until = service._now() - timedelta(seconds=1)
            event.available_at = service._now() - timedelta(seconds=1)
            db.commit()
            self.assertTrue(dispatch_next(db, send=lambda message: False))
            self.assertEqual(db.scalar(select(models.DeviceCommand)).status, "failed")
            self.assertEqual(event.status, "failed")

    def test_http_errors_and_station_operator_crud(self):
        admin = self.login()
        self.assertEqual(self.request("GET", "/api/v1/assets/piles/999", token=admin)[0], 404)
        self.assertEqual(self.request("GET", "/api/v1/assets/piles", token=admin, query="page=0")[0], 422)
        status, op = self.request("POST", "/api/v1/assets/operators", {"operator_name": "联调运营商",
            "credit_code": "INTEGRATION001", "contact_name": "测试", "contact_phone": "13812345678"}, token=admin)
        self.assertEqual(status, 200, op)
        station = {"operator_id": int(op["operator_id"]), "station_name": "联调站", "address": "测试地址", "longitude": "120", "latitude": "30"}
        status, created = self.request("POST", "/api/v1/assets/stations", station, token=admin)
        self.assertEqual(status, 200, created)
        status, updated = self.request("PATCH", "/api/v1/assets/stations/" + created["station_id"], {"station_name": "新名称"}, token=admin)
        self.assertEqual((status, updated["station_name"]), (200, "新名称"))

    def test_seed_password_and_permission_compatibility(self):
        from cryptography.hazmat.primitives.kdf.argon2 import Argon2id
        encoded = Argon2id(salt=b"test-salt-123456", length=32, iterations=1,
                           lanes=1, memory_cost=8192).derive_phc_encoded(DEMO_PASSWORD.encode())
        self.assertTrue(security.verify_password(DEMO_PASSWORD, encoded))
        self.assertFalse(security.verify_password("wrong", encoded))
        with self.factory() as db:
            db.execute(security.accounts.update().where(security.accounts.c.account_id == 2).values(password_hash=encoded))
            # 删除细分读权限，仅保留种子中的 gun.read，仍能查看授权范围内的桩。
            pid = db.scalar(select(security.permissions.c.permission_id).where(security.permissions.c.permission_code == "assets.pile.read"))
            db.execute(security.role_permissions.delete().where(security.role_permissions.c.role_id == 2,
                security.role_permissions.c.permission_id == pid))
            db.commit()
        token = self.login("maintenance_engineer")
        self.assertEqual(self.request("GET", "/api/v1/assets/piles/1", token=token)[0], 200)
        self.assertEqual(self.request("GET", "/api/v1/assets/piles/2", token=token)[0], 403)

    def test_worker_retries_stop_after_limit_and_cancels_stale_start(self):
        self._ready_device(self.login())
        with self.factory() as db:
            db.execute(dao._orders.insert().values(order_id=1, gun_id=1, status="charging"))
            service.claim_gun_for_order(db, gun_id=1, order_id=1)
            service.enqueue_device_command(db, gun_id=1, order_id=1, command_type="start")
            db.commit()
            db.execute(dao._orders.update().values(status="awaiting_payment"))
            db.commit()
            sent = []
            self.assertTrue(dispatch_next(db, send=lambda message: sent.append(message)))
            self.assertEqual(sent, [])
            self.assertEqual(db.scalar(select(models.DeviceCommand)).status, "failed")
            service.enqueue_device_command(db, gun_id=1, order_id=1, command_type="stop")
            db.commit()
            def disconnected(message):
                raise TimeoutError()
            for attempt in range(1, 6):
                self.assertTrue(dispatch_next(db, send=disconnected))
                event = db.scalar(select(models.OutboxEvent).where(models.OutboxEvent.status != "failed")) if attempt < 5 else None
                if event:
                    event.available_at = service._now() - timedelta(seconds=1)
                    db.commit()
            command = db.scalar(select(models.DeviceCommand).where(models.DeviceCommand.command_type == "stop"))
            self.assertEqual((command.status, command.attempt_count), ("failed", 5))


if __name__ == "__main__":
    unittest.main()
