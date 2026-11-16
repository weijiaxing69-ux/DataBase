"""设备业务验收：真实 Service/DAO/HTTP + SQLite 内存库，禁止访问 MySQL。"""

from dataclasses import FrozenInstanceError
from datetime import datetime, timedelta, timezone
import hashlib
import inspect
import json
from pathlib import Path
import unittest
from urllib.parse import urlencode
from unittest.mock import patch

from fastapi import FastAPI
from sqlalchemy import Column, Integer, MetaData, Table, create_engine, select, text
from sqlalchemy.pool import StaticPool
from sqlalchemy.orm import Session

from app.core.database import engine as mysql_engine, get_db
from app.modules.assets import dao, models, router as routes, schemas, service
from app.shared.contracts import Actor
import test_assets_http


class DeviceLifecycleTests(unittest.TestCase):
    _request = test_assets_http.AssetsHttpTests._request

    def setUp(self):
        self.guard = patch.object(mysql_engine, "connect", side_effect=AssertionError("禁止连接 MySQL"))
        self.guard.start()
        self.addCleanup(self.guard.stop)
        self.engine = create_engine("sqlite:///:memory:", connect_args={"check_same_thread": False}, poolclass=StaticPool)
        self.addCleanup(self.engine.dispose)
        # 不使用生产建表脚本。把测试所需的 MySQL 类型转换成 SQLite 等价类型。
        metadata = MetaData()
        for cls in (models.Station, models.ChargingPile, models.ChargingGun,
                    models.EquipmentChangeRequest, models.DeviceAcceptance, models.DeviceStatusLog,
                    models.DeviceCommand, models.DeviceCredential, models.OutboxEvent):
            table = cls.__table__.to_metadata(metadata)
            for column in table.columns:
                column.type = Integer() if column.primary_key else column.type.as_generic()
                if column.server_default and "current_timestamp" in str(column.server_default.arg):
                    column.server_default.arg = text("CURRENT_TIMESTAMP")
        # 其他成员表只有测试夹具，本任务没有修改其生产模型。
        Table("charging_order", metadata, Column("order_id", Integer, primary_key=True),
              Column("gun_id", Integer), Column("status", models.String(32)))
        metadata.create_all(self.engine)
        with self.engine.begin() as conn:
            conn.exec_driver_sql("CREATE UNIQUE INDEX active_order_per_gun ON charging_order(gun_id) WHERE status='charging'")
            conn.exec_driver_sql("CREATE TABLE alarm_rule (alarm_rule_id INTEGER PRIMARY KEY, metric TEXT, threshold_value NUMERIC, recovery_seconds INTEGER, enabled INTEGER, fault_code TEXT)")
            conn.exec_driver_sql("INSERT INTO alarm_rule VALUES (1,'heartbeat',60,30,1,NULL)")
            conn.exec_driver_sql("CREATE TABLE device_alert (alert_id INTEGER PRIMARY KEY, pile_id INTEGER, gun_id INTEGER, alarm_rule_id INTEGER, status TEXT, normal_since_at DATETIME, recovered_at DATETIME)")
            conn.exec_driver_sql("CREATE TABLE work_order (work_order_id INTEGER PRIMARY KEY, alert_id INTEGER, status TEXT)")
            conn.exec_driver_sql("CREATE TABLE device_reading (sample_id INTEGER PRIMARY KEY, pile_id INTEGER, sampled_at DATETIME, module_temperature_c NUMERIC, offline_seconds INTEGER, fault_code TEXT)")
        self.db = Session(self.engine, expire_on_commit=False, autoflush=False)
        self.addCleanup(self.db.close)
        self.now = service._now()
        self.db.add_all([
            models.Station(station_id=i, operator_id=1, station_name=f"S{i}", address="test", longitude=120, latitude=30)
            for i in (1, 2)
        ])
        self.db.add_all([
            models.ChargingPile(pile_id=i, station_id=i, serial_no=f"P{i}", model_name="old", rated_power_kw=120,
                                protocol="test", lifecycle_status="draft", status="offline", is_online=0, has_fault=0)
            for i in (1, 2)
        ])
        self.db.add_all([
            models.ChargingGun(gun_id=i, pile_id=i, gun_no=1, gun_type="dc", connector_standard="GB", max_power_kw=60,
                               status="offline", has_fault=0) for i in (1, 2)
        ])
        self.db.commit()
        self.admin = Actor(account_id=1, roles={"platform_admin"}, permissions=set())
        self.engineer = Actor(account_id=2, roles={"maintenance_engineer"}, permissions={
            "assets.change_request.read", "assets.acceptance.create", "assets.acceptance.read",
            "assets.device_command.read", "assets.status_log.read",
        })
        self.actor = self.admin
        self.scope = patch.object(service.security, "assert_resource_scope", create=True).start()
        self.addCleanup(patch.stopall)
        self.app = FastAPI()
        self.app.include_router(routes.router, prefix="/api/v1/assets")
        self.app.dependency_overrides[get_db] = lambda: self.db
        self.app.dependency_overrides[routes._get_request_actor] = lambda: self.actor
        self.app.dependency_overrides[routes._require_scope_integration] = lambda: None

    def _change(self, **changes):
        body = dict(pile_id=1, change_type="archive", proposed_data={"model_name": "new"}, reason="修正铭牌")
        body.update(changes)
        self.actor = self.engineer
        status, result = self._request("POST", "/api/v1/assets/change-requests", body=body)
        self.assertEqual(status, 200)
        return result

    def _review(self, request_id, decision="approved"):
        self.actor = self.admin
        return self._request("POST", f"/api/v1/assets/change-requests/{request_id}/reviews",
                             body={"decision": decision, "note": "已核对"})

    def _online(self):
        pile = dao.get_by_id(self.db, models.ChargingPile, 1)
        gun = dao.get_by_id(self.db, models.ChargingGun, 1)
        pile.lifecycle_status = "active"
        pile.is_online = 1
        pile.status = gun.status = "idle"
        pile.last_heartbeat_at = self.now
        self.db.commit()
        return pile, gun

    def test_contracts_match_v14(self):
        spec = json.loads(next(Path("../docs").glob("*V1.4.json")).read_text(encoding="utf-8"))
        for item in spec["functions"]:
            if item.get("module") == "assets" and item.get("file") == "service.py":
                function = getattr(service, item["name"])
                expected = [a.split(":")[0].split("=")[0].strip() for a in item["args"] if a != "*"]
                self.assertEqual(list(inspect.signature(function).parameters), expected, item["name"])
        for name in ("AcceptanceDetail", "AcceptanceQuery", "CreateAcceptanceRequest", "DeviceCommandDetail",
                     "DeviceCommandQuery", "DeviceStatusLogDetail", "DeviceStatusLogQuery", "IssueDeviceCredentialRequest", "DeviceCredentialIssue"):
            self.assertEqual(set(getattr(schemas, name).model_fields), {f["name"] for f in spec["schemas"][name]["fields"]})
        for name in ("equipment_change_request", "device_acceptance", "device_command", "device_credential", "device_status_log", "outbox_event"):
            definition = next(t for t in spec["tables"] if t["name"] == name)
            self.assertEqual(set(models.Base.metadata.tables[name].columns.keys()), {f["name"] for f in definition["fields"]})
        paths = self.app.openapi()["paths"]
        for route in spec["api"]:
            if route["module"] == "assets":
                self.assertIn(route["method"].lower(), paths[route["path"]])

    def test_change_http_approval_and_snapshot(self):
        row = self._change()
        self.assertEqual(row["status"], "pending")
        self.assertEqual(dao.get_by_id(self.db, models.ChargingPile, 1).model_name, "old")
        self.assertNotIn("proposed_data", row)
        self.assertNotIn("before_data", row)
        self.assertEqual(self._request("GET", f"/api/v1/assets/change-requests/{row['request_id']}")[0], 200)
        self.assertEqual(self._request("GET", "/api/v1/assets/change-requests", query=urlencode({"status": "pending", "keyword": "铭牌"}))[1]["total"], 1)
        status, approved = self._review(row["request_id"])
        self.assertEqual((status, approved["status"], approved["reviewed_by"]), (200, "approved", "1"))
        self.assertTrue(approved["reviewed_at"].endswith("Z"))
        self.assertEqual(dao.get_by_id(self.db, models.ChargingPile, 1).model_name, "new")
        with self.assertRaisesRegex(ValueError, "已经审批"):
            self._review(row["request_id"])

    def test_change_rejection_self_review_and_stale(self):
        row = self._change()
        self.actor = Actor(account_id=2, roles={"platform_admin"}, permissions=set())
        with self.assertRaises(PermissionError):
            self._request("POST", f"/api/v1/assets/change-requests/{row['request_id']}/reviews", body={"decision": "approved"})
        self.assertEqual(self._review(row["request_id"], "rejected")[1]["status"], "rejected")
        self.assertEqual(dao.get_by_id(self.db, models.ChargingPile, 1).model_name, "old")
        row = self._change()
        dao.get_by_id(self.db, models.ChargingPile, 1).model_name = "other"
        self.db.commit()
        with self.assertRaisesRegex(ValueError, "档案在申请后发生变化"):
            self._review(row["request_id"])

    def test_change_types_and_injection(self):
        # 桩迁场站，需重新验收；保留原申请记录。
        row = self._change(change_type="relocate", proposed_data={"station_id": 2})
        self._review(row["request_id"])
        pile = dao.get_by_id(self.db, models.ChargingPile, 1)
        self.assertEqual((pile.station_id, pile.lifecycle_status), (2, "pending_acceptance"))
        row = self._change(change_type="retrofit", proposed_data={"rated_power_kw": "80"})
        self._review(row["request_id"])
        self.assertEqual(pile.rated_power_kw, 80)
        with self.assertRaises(ValueError):
            self._change(proposed_data={"status": "idle"})
        with self.assertRaises(ValueError):
            self._change(proposed_data={"rated_power_kw": "30"})
        row = self._change(change_type="retire", proposed_data={})
        self._review(row["request_id"])
        self.assertEqual(pile.lifecycle_status, "retired")
        self.assertEqual(dao.get_by_id(self.db, models.ChargingGun, 1).status, "offline")

    def test_acceptance_http_and_history(self):
        base = "/api/v1/assets/acceptances"
        self.assertEqual(self._request("POST", base, body={"pile_id": 1})[1]["result"], "failed")
        body = dict(pile_id=1, protocol_test_passed=True, nameplate_checked=True, start_stop_passed=True, heartbeat_passed=True)
        status, row = self._request("POST", base, body=body)
        self.assertEqual((status, row["result"], row["accepted_by"]), (200, "passed", "1"))
        pile = dao.get_by_id(self.db, models.ChargingPile, 1)
        self.assertEqual((pile.lifecycle_status, pile.status), ("active", "offline"))
        self.assertIsNotNone(pile.commissioned_on)
        self.assertEqual(self._request("GET", base, query="pile_id=1")[1]["total"], 2)
        self.assertEqual(self._request("GET", base + "/" + row["acceptance_id"])[0], 200)
        with self.assertRaises(ValueError):
            self._request("POST", base, body=body)
        self.assertEqual(self.db.scalar(select(text("count(*)")).select_from(models.DeviceAcceptance)), 2)

    def test_credentials_once_hash_only(self):
        base = "/api/v1/assets/piles/1/credentials"
        expiry = (datetime.now(timezone.utc) + timedelta(hours=1)).isoformat()
        status, result = self._request("POST", base, body={"expires_at": expiry})
        self.assertEqual(status, 200)
        row = dao.get_by_id(self.db, models.DeviceCredential, int(result["credential_id"]))
        self.assertEqual(row.token_hash, hashlib.sha256(result["secret_token"].encode()).digest())
        self.assertNotIn("token_hash", result)
        self.assertEqual(self._request("GET", base)[0], 405)
        issued = service.issue_device_credential(self.db, actor=self.admin, pile_id=1,
            request=schemas.IssueDeviceCredentialRequest(expires_at=datetime.now(timezone.utc) + timedelta(hours=1)))
        self.assertNotIn(issued.secret_token, repr(issued))
        with self.assertRaises(FrozenInstanceError):
            issued.pile_id = 2
        self.actor = self.engineer
        with self.assertRaises(PermissionError):
            self._request("POST", base, body={"expires_at": expiry})

    def test_order_claim_release_command_and_outbox(self):
        pile, gun = self._online()
        self.db.execute(text("INSERT INTO charging_order VALUES (1,1,'charging')"))
        with patch.object(self.db, "commit", wraps=self.db.commit) as commit:
            snap = service.claim_gun_for_order(self.db, gun_id=1, order_id=1)
            self.assertEqual((snap.status, snap.active_order_id), ("occupied", 1))
            with self.assertRaises(FrozenInstanceError):
                snap.status = "idle"
            command = service.enqueue_device_command(self.db, gun_id=1, order_id=1, command_type="start")
            self.assertEqual(service.enqueue_device_command(self.db, gun_id=1, order_id=1, command_type="start"), command)
            commit.assert_not_called()
        self.assertEqual(self.db.scalar(select(text("count(*)")).select_from(models.OutboxEvent)), 1)
        self.db.commit()
        base = "/api/v1/assets/device-commands"
        self.assertEqual(self._request("GET", base, query="pile_id=1&order_id=1&status=pending")[1]["total"], 1)
        self.assertEqual(self._request("GET", base + "/" + str(command))[1]["command_type"], "start")
        with self.assertRaises(ValueError):
            service.release_gun_for_order(self.db, gun_id=1, order_id=1, reason="结束")
        self.db.execute(text("UPDATE charging_order SET status='awaiting_payment' WHERE order_id=1"))
        self.assertEqual(service.release_gun_for_order(self.db, gun_id=1, order_id=1, reason="结束").status, "idle")
        self.db.commit()
        logs = self._request("GET", "/api/v1/assets/status-logs", query="gun_id=1")[1]
        self.assertEqual(logs["total"], 2)
        self.assertEqual(self._request("GET", "/api/v1/assets/status-logs/" + logs["items"][0]["status_log_id"])[0], 200)

    def test_offline_heartbeat_preserves_order_and_fault(self):
        pile, gun = self._online()
        gun.has_fault = 1
        self.db.execute(text("INSERT INTO charging_order VALUES (1,1,'charging')"))
        self.db.commit()
        with patch.object(self.db, "commit", wraps=self.db.commit) as commit:
            service.mark_pile_offline(self.db, pile_id=1, detected_at=self.now + timedelta(seconds=10), reason="检测")
            self.assertEqual(pile.status, "idle")
            service.mark_pile_offline(self.db, pile_id=1, detected_at=self.now + timedelta(seconds=61), reason="超时")
            self.assertEqual((pile.status, gun.status, gun.has_fault), ("offline", "offline", 1))
            service.touch_pile_heartbeat(self.db, pile_id=1, received_at=self.now + timedelta(seconds=62))
            service.touch_pile_heartbeat(self.db, pile_id=1, received_at=self.now)
            self.assertEqual(pile.last_heartbeat_at, self.now + timedelta(seconds=62))
            self.assertEqual(gun.status, "offline")
            commit.assert_not_called()
        self.assertEqual(dao._active_order_id(self.db, 1), 1)
        self.db.rollback()

    def test_recovery_requires_normal_observation_and_closed_work(self):
        pile, gun = self._online()
        pile.status = gun.status = "offline"
        gun.has_fault = pile.has_fault = 1
        normal = self.now - timedelta(seconds=40)
        self.db.execute(text("INSERT INTO device_alert VALUES (1,1,1,1,'recovered',:normal,:now)"), {"normal": normal, "now": self.now})
        self.db.execute(text("INSERT INTO work_order VALUES (1,1,'repaired')"))
        self.db.execute(text("INSERT INTO device_reading VALUES (1,1,:now,30,0,NULL)"), {"now": self.now})
        self.db.execute(text("INSERT INTO device_reading VALUES (2,1,:normal,30,0,NULL)"), {"normal": normal})
        self.db.commit()
        with self.assertRaisesRegex(ValueError, "闭环"):
            service.recover_pile_status(self.db, pile_id=1, verified_at=self.now)
        self.db.execute(text("UPDATE work_order SET status='closed'"))
        self.db.execute(text("UPDATE device_alert SET normal_since_at=:normal"), {"normal": self.now})
        with self.assertRaisesRegex(ValueError, "观察时间不足"):
            service.recover_pile_status(self.db, pile_id=1, verified_at=self.now)
        self.db.execute(text("UPDATE device_alert SET normal_since_at=:normal"), {"normal": normal})
        self.db.execute(text("INSERT INTO charging_order VALUES (1,1,'charging')"))
        with patch.object(self.db, "commit", wraps=self.db.commit) as commit:
            service.recover_pile_status(self.db, pile_id=1, verified_at=self.now)
            commit.assert_not_called()
        self.assertEqual((pile.status, gun.status, gun.has_fault), ("occupied", "occupied", 0))
        self.db.rollback()

    def test_scope_applied_before_pagination_and_count(self):
        self._change()
        self._change(pile_id=2)
        def check(db, actor, *, resource_type, resource_id):
            if resource_id != 1:
                raise PermissionError("范围拒绝")
        self.scope.side_effect = check
        status, page = self._request("GET", "/api/v1/assets/change-requests", query="page_size=1")
        self.assertEqual((status, page["total"], page["items"][0]["pile_id"]), (200, 1, "1"))
        with self.assertRaises(PermissionError):
            self._request("GET", "/api/v1/assets/change-requests/2")

    def test_gun_relocation_checks_both_piles_and_rolls_back(self):
        row = self._change(pile_id=None, gun_id=1, change_type="relocate",
                           proposed_data={"pile_id": 2, "gun_no": 2})
        # 目标桩正在充电时，即使迁入的是另一把枪，也不能让整桩进入待验收。
        self.db.execute(text("INSERT INTO charging_order VALUES (1,2,'charging')"))
        self.db.commit()
        with self.assertRaisesRegex(ValueError, "充电中的订单"):
            self._review(row["request_id"])
        self.assertEqual(dao.get_by_id(self.db, models.ChargingGun, 1).pile_id, 1)
        self.assertEqual(dao.get_by_id(self.db, models.EquipmentChangeRequest, int(row["request_id"])).status, "pending")
        self.db.execute(text("UPDATE charging_order SET status='completed'"))
        self.db.commit()
        self._review(row["request_id"])
        gun = dao.get_by_id(self.db, models.ChargingGun, 1)
        self.assertEqual((gun.pile_id, gun.gun_no, gun.status), (2, 2, "offline"))
        self.assertEqual(dao.get_by_id(self.db, models.ChargingPile, 2).lifecycle_status, "pending_acceptance")

    def test_updates_preserve_power_and_retirement_rules(self):
        editor = Actor(account_id=1, roles={"platform_admin"}, permissions={"assets.pile.update", "assets.gun.update", "assets.gun.create"})
        with self.assertRaisesRegex(ValueError, "单枪最大功率"):
            service.update_pile(self.db, actor=editor, pile_id=1,
                                request=schemas.UpdatePileRequest(rated_power_kw="30"))
        pile = dao.get_by_id(self.db, models.ChargingPile, 1)
        self.assertEqual(pile.rated_power_kw, 120)
        pile.lifecycle_status = "retired"
        self.db.commit()
        with self.assertRaisesRegex(ValueError, "退役"):
            service.update_gun(self.db, actor=editor, gun_id=1,
                               request=schemas.UpdateGunRequest(connector_standard="other"))
        with self.assertRaisesRegex(ValueError, "退役"):
            service.create_gun(self.db, actor=editor,
                               request=schemas.CreateGunRequest(pile_id=1, gun_no=3, gun_type="dc", connector_standard="GB", max_power_kw="60"))

    def test_status_helpers_cannot_bypass_recovery(self):
        pile, gun = self._online()
        gun.status = "offline"
        self.db.execute(text("INSERT INTO charging_order VALUES (1,1,'charging')"))
        self.db.commit()
        self.assertEqual(service.get_gun(self.db, 1).active_order_id, 1)
        self.assertEqual(service.lock_gun(self.db, 1).pile_id, 1)
        with self.assertRaisesRegex(ValueError, "恢复复核"):
            service.change_gun_status(self.db, 1, expected_status="offline", new_status="occupied", reason="订单")
        with self.assertRaises(ValueError):
            service.release_gun_for_order(self.db, gun_id=1, order_id=999, reason="结束")
        self.assertEqual(gun.status, "offline")

    def test_command_and_outbox_share_caller_transaction(self):
        self._online()
        self.db.execute(text("INSERT INTO charging_order VALUES (1,1,'charging')"))
        self.db.commit()
        service.claim_gun_for_order(self.db, gun_id=1, order_id=1)
        service.enqueue_device_command(self.db, gun_id=1, order_id=1, command_type="start")
        self.db.rollback()
        for model in (models.DeviceCommand, models.OutboxEvent, models.DeviceStatusLog):
            self.assertEqual(self.db.scalar(select(text("count(*)")).select_from(model)), 0)
        self.assertEqual(service.get_gun(self.db, 1).status, "idle")

    def test_device_workflow_requires_permission_and_scope(self):
        outsider = Actor(account_id=3, roles=set(), permissions=set())
        with self.assertRaises(PermissionError):
            service.list_acceptances(self.db, actor=outsider, query=schemas.AcceptanceQuery())
        self.scope.side_effect = PermissionError("场站超出授权范围")
        with self.assertRaises(PermissionError):
            service.create_acceptance(self.db, actor=self.admin, request=schemas.CreateAcceptanceRequest(pile_id=1))

    def test_validation_and_write_rollback(self):
        self.actor = self.engineer
        self.assertEqual(self._request("POST", "/api/v1/assets/change-requests", body={
            "pile_id": 1, "gun_id": 1, "change_type": "archive", "proposed_data": {}, "reason": "test"})[0], 422)
        self.assertEqual(self._request("POST", "/api/v1/assets/acceptances", body={"pile_id": 1, "result": "passed"})[0], 422)
        self.actor = self.admin
        self.assertEqual(self._request("POST", "/api/v1/assets/piles/1/credentials", body={"expires_at": "2020-01-01T00:00:00Z"})[0], 422)
        row = self._change()
        with patch.object(self.db, "commit", side_effect=RuntimeError("模拟提交失败")):
            with self.assertRaises(RuntimeError):
                self._review(row["request_id"])
        self.assertEqual(dao.get_by_id(self.db, models.ChargingPile, 1).model_name, "old")
        self.assertEqual(dao.get_by_id(self.db, models.EquipmentChangeRequest, int(row["request_id"])).status, "pending")


if __name__ == "__main__":
    unittest.main()
