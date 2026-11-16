"""充电桩完整调用链验证：只建 SQLite 内存测试表，不连接 MySQL。"""

from unittest.mock import patch

from sqlalchemy import text

from app.modules.assets import dao, service
from app.shared.contracts import Actor
import test_assets_http


class PileHttpFlowTests(test_assets_http.AssetsHttpTests):
    def setUp(self):
        super().setUp()
        self.actor = Actor(account_id=1, roles={"platform_admin"}, permissions={
            "assets.operator.read", "assets.pile.read", "assets.pile.create", "assets.pile.update",
        })
        # 以下建表和种子数据只存在于本测试的内存数据库中。
        with self.engine.begin() as conn:
            conn.exec_driver_sql("""CREATE TABLE station (
                station_id INTEGER PRIMARY KEY, operator_id INTEGER NOT NULL,
                station_name TEXT NOT NULL, address TEXT NOT NULL,
                longitude NUMERIC NOT NULL, latitude NUMERIC NOT NULL,
                parking_spaces INTEGER DEFAULT 0, business_hours TEXT DEFAULT '00:00-24:00',
                parking_fee_standard TEXT DEFAULT 'test', status TEXT DEFAULT 'draft',
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
            )""")
            conn.exec_driver_sql("""INSERT INTO station
                (station_id, operator_id, station_name, address, longitude, latitude)
                VALUES (1, 1, 'test station', 'test address', 120, 30)""")
            conn.exec_driver_sql("""CREATE TABLE charging_pile (
                pile_id INTEGER PRIMARY KEY AUTOINCREMENT,
                station_id INTEGER NOT NULL, serial_no TEXT NOT NULL UNIQUE,
                model_name TEXT NOT NULL, rated_power_kw NUMERIC NOT NULL CHECK (rated_power_kw > 0),
                protocol TEXT NOT NULL, commissioned_on DATE, warranty_until DATE,
                lifecycle_status TEXT NOT NULL DEFAULT 'draft', status TEXT NOT NULL DEFAULT 'offline',
                has_fault INTEGER NOT NULL DEFAULT 0, is_online INTEGER NOT NULL DEFAULT 0,
                last_heartbeat_at DATETIME,
                created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (station_id) REFERENCES station(station_id)
            )""")
            # 修改整桩功率时还会查询已有枪，因此桩测试也需要枪表。
            conn.exec_driver_sql("""CREATE TABLE charging_gun (
                gun_id INTEGER PRIMARY KEY AUTOINCREMENT,
                pile_id INTEGER NOT NULL, gun_no INTEGER NOT NULL CHECK (gun_no > 0),
                gun_type TEXT NOT NULL, connector_standard TEXT NOT NULL,
                max_power_kw NUMERIC NOT NULL CHECK (max_power_kw > 0),
                status TEXT NOT NULL DEFAULT 'offline', has_fault INTEGER NOT NULL DEFAULT 0,
                created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                UNIQUE(pile_id, gun_no), FOREIGN KEY(pile_id) REFERENCES charging_pile(pile_id)
            )""")

    def _pile_body(self, serial="FLOW001", **changes):
        return dict(station_id=1, serial_no=serial, model_name="DC",
                    rated_power_kw="120.000", protocol="test",
                    warranty_until="2027-01-01", **changes)

    def test_pile_complete_http_flow(self):
        self._enable_test_identity()
        base = "/api/v1/assets/piles"
        # 仅公共资源范围函数使用替身，Router、Service、DAO 均执行真实代码。
        with patch.object(service.security, "assert_resource_scope", create=True) as scope:
            status, first = self._request("POST", base, body=self._pile_body())
            self.assertEqual(status, 200)
            self.assertEqual((first["lifecycle_status"], first["status"]), ("draft", "offline"))
            self.assertFalse(first["has_fault"])
            self.assertFalse(first["is_online"])
            self.assertIsNone(first["commissioned_on"])
            self.assertIsNone(first["last_heartbeat_at"])
            self.assertTrue(first["created_at"].endswith("Z"))
            self.assertIsInstance(first["rated_power_kw"], str)
            pile_id = first["pile_id"]
            self.assertIsInstance(pile_id, str)
            status, detail = self._request("GET", base + "/" + pile_id)
            self.assertEqual((status, detail["serial_no"]), (200, "FLOW001"))
            self.assertEqual(self._request("POST", base, body=self._pile_body("FLOW002"))[0], 200)
            status, page = self._request("GET", base, query="page=2&page_size=1&station_id=1&status=offline&keyword=FLOW")
            self.assertEqual(status, 200)
            self.assertEqual((page["total"], len(page["items"])), (2, 1))
            self.assertEqual(page["items"][0]["pile_id"], pile_id)
            self.assertEqual(self._request("GET", base, query="status=fault")[1]["total"], 0)
            status, updated = self._request("PATCH", base + "/" + pile_id,
                body={"model_name": "DC2", "rated_power_kw": "180.125"})
            self.assertEqual(status, 200)
            self.assertEqual((updated["model_name"], updated["rated_power_kw"]), ("DC2", "180.125"))
            for field in ("serial_no", "protocol", "station_id", "status", "lifecycle_status", "warranty_until"):
                self.assertEqual(updated[field], first[field])
            status, cleared = self._request("PATCH", base + "/" + pile_id, body={"warranty_until": None})
            self.assertEqual(status, 200)
            self.assertIsNone(cleared["warranty_until"])
            scope.assert_any_call(self.db, self.actor, resource_type="station", resource_id=1)

    def test_pile_rejections_and_rollback(self):
        self._enable_test_identity()
        base = "/api/v1/assets/piles"
        with patch.object(service.security, "assert_resource_scope", create=True) as scope:
            _, first = self._request("POST", base, body=self._pile_body())
            # 当前业务异常尚未统一映射 HTTP 状态码，因此检查真实异常的传播。
            with self.assertRaisesRegex(ValueError, "序列号已存在"):
                self._request("POST", base, body=self._pile_body())
            body = self._pile_body("MISSING")
            body["station_id"] = 999
            with self.assertRaisesRegex(ValueError, "所属场站不存在"):
                self._request("POST", base, body=body)
            with self.assertRaisesRegex(ValueError, "充电桩不存在"):
                self._request("GET", base + "/999")
            with self.assertRaisesRegex(ValueError, "充电桩不存在"):
                self._request("PATCH", base + "/999", body={"model_name": "new"})
            scope.side_effect = PermissionError("场站范围拒绝")
            with self.assertRaises(PermissionError):
                self._request("POST", base, body=self._pile_body("DENIED"))
            with self.assertRaises(PermissionError):
                self._request("GET", base + "/" + first["pile_id"])
            with self.assertRaises(PermissionError):
                self._request("PATCH", base + "/" + first["pile_id"], body={"model_name": "denied"})
            scope.side_effect = None
            # 在真正 flush 之后模拟提交失败，检查 INSERT 和 UPDATE 都回滚。
            with patch.object(self.db, "commit", side_effect=RuntimeError("模拟提交失败")):
                with self.assertRaises(RuntimeError):
                    self._request("POST", base, body=self._pile_body("ROLLBACK"))
                with self.assertRaises(RuntimeError):
                    self._request("PATCH", base + "/" + first["pile_id"], body={"model_name": "rollback"})
            self.assertEqual(self.db.scalar(text("SELECT count(*) FROM charging_pile")), 1)
            self.assertEqual(dao.get_pile_by_id(self.db, pile_id=int(first["pile_id"])).model_name, "DC")
            # 权限不足时，四个入口都应拒绝。
            self.actor = Actor(account_id=2, roles=set(), permissions=set())
            for method, path, body in [
                ("GET", base, None), ("GET", base + "/1", None),
                ("POST", base, self._pile_body("NOAUTH")),
                ("PATCH", base + "/1", {"model_name": "noauth"}),
            ]:
                with self.subTest(method=method, path=path):
                    with self.assertRaises(PermissionError):
                        self._request(method, path, body=body)
