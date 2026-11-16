"""充电枪真实 HTTP 业务链测试：数据仅存在 SQLite 内存库。"""

from unittest.mock import patch

from sqlalchemy import text

from app.modules.assets import dao, service
from app.modules.assets.models import ChargingGun
from app.shared.contracts import Actor
import test_pile_http_flow


class GunHttpFlowTests(test_pile_http_flow.PileHttpFlowTests):
    def setUp(self):
        super().setUp()
        # 继承的回归测试保留原有数据环境，枪测试才增加额外夹具。
        if not self._testMethodName.startswith("test_gun_"):
            return
        self.actor = self.actor.model_copy(update={"permissions": self.actor.permissions | {
            "assets.gun.read", "assets.gun.create", "assets.gun.update",
        }})
        # 只在内存中建等价表；父测试已禁止 MySQL engine.connect。
        with self.engine.begin() as conn:
            conn.exec_driver_sql("""INSERT INTO charging_pile
                (pile_id, station_id, serial_no, model_name, rated_power_kw, protocol)
                VALUES (101, 1, 'GUN-PILE1', 'DC', 120, 'test'),
                       (102, 2, 'GUN-PILE2', 'DC', 120, 'test')""")

    def _gun_body(self, **changes):
        body = dict(pile_id=101, gun_no=1, gun_type="dc",
                    connector_standard="GB", max_power_kw="60.125")
        body.update(changes)
        return body

    def _gun_post(self, **changes):
        return self._request("POST", "/api/v1/assets/guns", body=self._gun_body(**changes))

    def test_gun_complete_http_flow(self):
        self._enable_test_identity()
        base = "/api/v1/assets/guns"
        with patch.object(service.security, "assert_resource_scope", create=True) as scope:
            status, first = self._gun_post()
            self.assertEqual(status, 200)
            self.assertEqual((first["status"], first["has_fault"]), ("offline", False))
            self.assertEqual((first["pile_id"], first["gun_no"], first["max_power_kw"]), ("101", 1, "60.125"))
            self.assertIsInstance(first["gun_id"], str)
            self.assertTrue(first["created_at"].endswith("Z"))
            self.assertNotIn("active_order_id", first)
            path = base + "/" + first["gun_id"]
            self.assertEqual(self._request("GET", path), (200, first))
            # 相等功率允许新增；不同桩允许使用相同枪序号。
            self.assertEqual(self._gun_post(gun_no=2, max_power_kw="120")[0], 200)
            self.assertEqual(self._gun_post(pile_id=102)[0], 200)
            status, page = self._request("GET", base,
                query="station_id=1&pile_id=101&status=offline&keyword=GB&page=2&page_size=1")
            self.assertEqual(status, 200)
            self.assertEqual((page["total"], len(page["items"]), page["page"]), (2, 1, 2))
            self.assertEqual(page["items"][0]["gun_no"], 2)
            self.assertEqual(self._request("GET", base, query="station_id=1&keyword=%25")[1]["total"], 0)
            # 精确验证时间范围左闭右开，排除别的场站。
            self.db.execute(text("UPDATE charging_gun SET created_at = '2026-01-01 00:00:00.000000' WHERE gun_no=1"))
            self.db.execute(text("UPDATE charging_gun SET created_at = '2026-01-02 00:00:00.000000' WHERE gun_no=2"))
            self.db.commit()
            status, page = self._request("GET", base, query=
                "station_id=1&start_at=2026-01-01T00:00:00Z&end_at=2026-01-02T00:00:00Z")
            self.assertEqual((status, page["total"]), (200, 1))
            status, updated = self._request("PATCH", path, body={"max_power_kw": "120", "connector_standard": "NEW"})
            self.assertEqual(status, 200)
            self.assertEqual((updated["max_power_kw"], updated["connector_standard"]), ("120.000", "NEW"))
            for field in ("pile_id", "gun_no", "gun_type", "status", "has_fault"):
                self.assertEqual(updated[field], first[field])
            scope.assert_any_call(self.db, self.actor, resource_type="station", resource_id=1)
            self.assertEqual(self._request("GET", path)[1]["connector_standard"], "NEW")

    def test_gun_business_rejections_and_rollback(self):
        self._enable_test_identity()
        base = "/api/v1/assets/guns"
        with patch.object(service.security, "assert_resource_scope", create=True):
            _, first = self._gun_post()
            path = base + "/" + first["gun_id"]
            # 统一业务异常到 HTTP 状态码的映射尚未接入，当前验证异常传播。
            with self.assertRaisesRegex(ValueError, "枪序号已存在"):
                self._gun_post()
            with self.assertRaisesRegex(ValueError, "所属充电桩不存在"):
                self._gun_post(pile_id=999)
            with self.assertRaisesRegex(ValueError, "不能超过"):
                self._gun_post(gun_no=3, max_power_kw="120.001")
            with self.assertRaisesRegex(ValueError, "不能超过"):
                self._request("PATCH", path, body={"max_power_kw": "120.001"})
            for method, body in (("GET", None), ("PATCH", {"gun_type": "ac"})):
                with self.assertRaisesRegex(ValueError, "充电枪不存在"):
                    self._request(method, base + "/999", body=body)
            # 跳过预查，验证数据库联合唯一约束仍能阻止重复。
            with patch.object(dao, "get_by_unique", return_value=None):
                with self.assertRaisesRegex(ValueError, "枪序号已存在"):
                    self._gun_post()
            # flush 已执行，但提交失败时 INSERT 和 UPDATE 都应被撤销。
            with patch.object(self.db, "commit", side_effect=RuntimeError("模拟提交失败")):
                with self.assertRaises(RuntimeError):
                    self._gun_post(gun_no=3)
                with self.assertRaises(RuntimeError):
                    self._request("PATCH", path, body={"connector_standard": "ROLLBACK"})
            self.assertEqual(self.db.scalar(text("SELECT count(*) FROM charging_gun")), 1)
            row = dao.get_by_id(self.db, ChargingGun, int(first["gun_id"]))
            self.assertEqual(row.connector_standard, "GB")
            self.assertEqual(str(row.max_power_kw), "60.125")

    def test_gun_scope_and_permissions(self):
        self._enable_test_identity()
        base = "/api/v1/assets/guns"
        with patch.object(service.security, "assert_resource_scope", create=True) as scope:
            _, first = self._gun_post()
            path = base + "/" + first["gun_id"]
            scope.side_effect = PermissionError("场站范围拒绝")
            cases = [("GET", base, None, "station_id=1"), ("GET", path, None, ""),
                     ("POST", base, self._gun_body(gun_no=2), ""),
                     ("PATCH", path, {"gun_type": "ac"}, "")]
            for method, url, body, query in cases:
                with self.subTest(method=method, scope=True):
                    with self.assertRaises(PermissionError):
                        self._request(method, url, body=body, query=query)
            scope.side_effect = None
            self.actor = Actor(account_id=2, roles=set(), permissions=set())
            for method, url, body, query in cases:
                with self.subTest(method=method, permission=True):
                    with self.assertRaises(PermissionError):
                        self._request(method, url, body=body, query=query)
            self.actor = Actor(account_id=1, roles=set(), permissions={"assets.gun.read"})
            # 已接入按公共范围检查筛选的列表，不指定桩也只返回可见记录。
            self.assertEqual(self._request("GET", base)[0], 200)
        # 公共函数尚未提供时不能绕过范围校验。
        with patch.object(service.security, "assert_resource_scope", None), self.assertRaises(NotImplementedError):
            self._request("GET", path)

    def test_gun_http_validation(self):
        self._enable_test_identity()
        base = "/api/v1/assets/guns"
        cases = [
            ("GET", base + "/0", None, ""),
            ("GET", base, None, "station_id=1&page_size=101"),
            ("GET", base, None, "station_id=1&status=bad"),
            ("GET", base, None, "station_id=1&start_at=2026-01-02T00:00:00Z&end_at=2026-01-01T00:00:00Z"),
            ("POST", base, {}, ""),
            ("POST", base, self._gun_body(gun_no=0), ""),
            ("POST", base, self._gun_body(max_power_kw="1.0001"), ""),
            ("PATCH", base + "/1", {}, ""),
            ("PATCH", base + "/1", {"gun_type": None}, ""),
            ("PATCH", base + "/1", {"status": "idle"}, ""),
            ("PATCH", base + "/1", {"has_fault": 0}, ""),
            ("PATCH", base + "/1", {"pile_id": 102}, ""),
        ]
        for method, path, body, query in cases:
            with self.subTest(method=method, body=body, query=query):
                self.assertEqual(self._request(method, path, body=body, query=query)[0], 422)
