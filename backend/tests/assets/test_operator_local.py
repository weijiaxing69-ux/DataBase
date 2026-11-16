"""运营商业务的本地验证：只使用内存数据库，不依赖登录接口或 MySQL。"""

import unittest
from unittest.mock import patch

from cryptography.fernet import Fernet
from sqlalchemy import create_engine, text
from sqlalchemy.orm import Session
from sqlalchemy.pool import StaticPool

from app.core.config import settings
from app.modules.assets import dao, service
from app.modules.assets.models import Operator
from app.modules.assets.schemas import (
    CreateOperatorRequest,
    OperatorQuery,
    UpdateOperatorRequest,
)
from app.shared.contracts import Actor


class OperatorLocalTests(unittest.TestCase):
    def setUp(self):
        # 独立的测试身份，只用于直接调用 Service，不会提供给 HTTP 接口。
        self.actor = Actor(
            account_id=1, roles={"platform_admin"},
            permissions={"assets.operator.read"},
        )
        self.old_key = settings.phone_encryption_key
        settings.phone_encryption_key = Fernet.generate_key().decode()
        # HTTP 同步路由在线程池执行，测试连接需跨线程共享同一个内存库。
        self.engine = create_engine(
            "sqlite:///:memory:", connect_args={"check_same_thread":False},
            poolclass=StaticPool,
        )
        # SQLite 不支持项目 MySQL 的全部类型和默认值，单独建立等价测试表。
        with self.engine.begin() as conn:
            conn.execute(text("""CREATE TABLE operator (
                operator_id INTEGER PRIMARY KEY AUTOINCREMENT,
                operator_name VARCHAR(100) NOT NULL,
                credit_code VARCHAR(18) NOT NULL UNIQUE,
                contact_name VARCHAR(50) NOT NULL,
                contact_phone_cipher BLOB NOT NULL,
                status VARCHAR(32) DEFAULT 'active' NOT NULL,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
                updated_at DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL
            )"""))
        self.db = Session(self.engine)

    def tearDown(self):
        self.db.close()
        self.engine.dispose()
        settings.phone_encryption_key = self.old_key

    def _create(self, code="TEST001"):
        return service.create_operator(
            self.db, actor=self.actor,
            request=CreateOperatorRequest(
                operator_name="测试运营商", credit_code=code,
                contact_name="测试联系人", contact_phone="13812345678",
            ),
        )

    def test_create_list_and_partial_update(self):
        created = self._create()
        self._create("TEST002")
        page = service.list_operators(
            self.db, actor=self.actor,
            query=OperatorQuery(keyword="测试", page=2, page_size=1),
        )
        self.assertEqual(page.total, 2)
        self.assertEqual(len(page.items), 1)
        updated = service.update_operator(
            self.db, actor=self.actor, operator_id=created.operator_id,
            request=UpdateOperatorRequest(operator_name="新名称"),
        )
        self.assertEqual(updated.operator_name, "新名称")
        self.assertEqual(updated.credit_code, "TEST001")
        self.assertEqual(updated.contact_name, "测试联系人")
        self.assertEqual(updated.status, "active")

    def test_phone_encryption_and_update(self):
        created = self._create()
        service.update_operator(
            self.db, actor=self.actor, operator_id=created.operator_id,
            request=UpdateOperatorRequest(contact_phone="13912345678"),
        )
        row = dao.get_by_id(self.db, Operator, created.operator_id)
        plain = Fernet(settings.phone_encryption_key.encode()).decrypt(
            row.contact_phone_cipher
        ).decode()
        self.assertEqual(plain, "13912345678")
        self.assertNotIn("13812345678", created.model_dump_json())
        self.assertNotIn("contact_phone_cipher", created.model_dump())

    def test_duplicate_missing_and_permission_denial(self):
        self._create()
        with self.assertRaisesRegex(ValueError, "统一社会信用代码已存在"):
            self._create()
        with self.assertRaisesRegex(ValueError, "运营商不存在"):
            service.update_operator(
                self.db, actor=self.actor, operator_id=999,
                request=UpdateOperatorRequest(status="disabled"),
            )
        self.assertFalse(self.db.in_transaction())
        denied = Actor(account_id=2, roles=set(), permissions=set())
        with self.assertRaises(PermissionError):
            service.update_operator(
                self.db, actor=denied, operator_id=1,
                request=UpdateOperatorRequest(status="disabled"),
            )

    def test_query_failure_and_write_failure_rollback(self):
        created = self._create()
        request = UpdateOperatorRequest(operator_name="不应保存")
        with patch.object(dao, "get_by_id", side_effect=RuntimeError("查询失败")), \
                patch.object(self.db, "rollback", wraps=self.db.rollback) as rollback:
            with self.assertRaises(RuntimeError):
                service.update_operator(
                    self.db, actor=self.actor, operator_id=1, request=request,
                )
            rollback.assert_called_once()
        with patch.object(dao, "flush", side_effect=RuntimeError("写入失败")):
            with self.assertRaises(RuntimeError):
                service.update_operator(
                    self.db, actor=self.actor,
                    operator_id=created.operator_id, request=request,
                )
        row = dao.get_by_id(self.db, Operator, created.operator_id)
        self.assertEqual(row.operator_name, "测试运营商")


if __name__ == "__main__":
    unittest.main()
