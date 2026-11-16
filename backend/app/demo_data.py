"""独立 SQLite 内存演示数据；不会连接 MySQL 或运行生产建表脚本。"""
from cryptography.fernet import Fernet
from sqlalchemy import Integer, MetaData, create_engine, text
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool
from app.core import security
from app.modules.assets import models

DEMO_PASSWORD = "Demo123!"
ROLE_CODES = ("platform_admin", "maintenance_engineer", "customer_service", "vehicle_owner", "fleet_admin", "operator_manager")
DEVICE_PERMISSIONS = (
    "assets.operator.read", "assets.station.read", "assets.station.manage",
    "assets.pile.read", "assets.pile.create", "assets.pile.update",
    "assets.gun.read", "assets.gun.create", "assets.gun.update",
    "assets.change_request.read", "assets.acceptance.create", "assets.acceptance.read",
    "assets.device_command.read", "assets.status_log.read",
)


def create_demo_database():
    engine = create_engine("sqlite:///:memory:", connect_args={"check_same_thread": False}, poolclass=StaticPool)
    metadata = MetaData()
    # 只复制表描述，不能修改生产 ORM 上的 MySQL 类型和默认值。
    for original in [*models.Base.metadata.tables.values(), *security.metadata.tables.values()]:
        table = original.to_metadata(metadata)
        for col in table.columns:
            col.type = Integer() if col.primary_key else col.type.as_generic()
            if col.server_default and "current_timestamp" in str(col.server_default.arg):
                col.server_default.arg = text("CURRENT_TIMESTAMP")
    metadata.create_all(engine)
    # 以下是其他成员业务的最小模拟数据表，只存在演示内存库。
    with engine.begin() as conn:
        for sql in (
            "CREATE TABLE charging_order (order_id INTEGER PRIMARY KEY AUTOINCREMENT, gun_id INTEGER NOT NULL, status TEXT NOT NULL)",
            "CREATE UNIQUE INDEX one_charging_order ON charging_order(gun_id) WHERE status='charging'",
            "CREATE TABLE alarm_rule (alarm_rule_id INTEGER PRIMARY KEY, metric TEXT, threshold_value NUMERIC, recovery_seconds INTEGER, enabled INTEGER, fault_code TEXT)",
            "CREATE TABLE device_alert (alert_id INTEGER PRIMARY KEY, pile_id INTEGER, gun_id INTEGER, alarm_rule_id INTEGER, status TEXT, normal_since_at DATETIME, recovered_at DATETIME)",
            "CREATE TABLE work_order (work_order_id INTEGER PRIMARY KEY, alert_id INTEGER, status TEXT)",
            "CREATE TABLE device_reading (sample_id INTEGER PRIMARY KEY, pile_id INTEGER, sampled_at DATETIME, module_temperature_c NUMERIC, offline_seconds INTEGER, fault_code TEXT)",
            "INSERT INTO alarm_rule VALUES (1,'heartbeat',60,30,1,NULL)",
        ):
            conn.exec_driver_sql(sql)
    factory = sessionmaker(engine, autoflush=False, expire_on_commit=False)
    phone_key = Fernet.generate_key().decode()
    password_hash = security.hash_password(DEMO_PASSWORD)
    with factory() as db:
        for i, role in enumerate(ROLE_CODES, 1):
            db.execute(security.roles.insert().values(role_id=i, role_code=role))
            db.execute(security.accounts.insert().values(account_id=i, username=role,
                password_hash=password_hash, status="active", failed_attempts=0))
            db.execute(security.account_roles.insert().values(account_id=i, role_id=i))
        for i, code in enumerate(DEVICE_PERMISSIONS, 1):
            db.execute(security.permissions.insert().values(permission_id=i, permission_code=code))
            # 平台管理员全部权限；运维有设备读、验收权限，档案变更走申请审批。
            # 运营商负责人有读权限，其余三个角色本次没有设备操作权限。
            readers = (1, 2, 6) if code.endswith(".read") else (1, 2) if code.startswith("assets.acceptance.") else (1,)
            for role_id in readers:
                db.execute(security.role_permissions.insert().values(role_id=role_id, permission_id=i))
        db.add_all([models.Operator(operator_id=i, operator_name=f"演示运营商{i}", credit_code=f"DEMO{i:014d}",
            contact_name="演示联系人", contact_phone_cipher=Fernet(phone_key.encode()).encrypt(b"13812345678")) for i in (1, 2)])
        db.add_all([models.Station(station_id=i, operator_id=i, station_name=f"演示场站{i}", address="演示地址",
            longitude=120, latitude=30, status="active") for i in (1, 2)])
        db.add_all([models.ChargingPile(pile_id=i, station_id=i, serial_no=f"DEMO-P{i}", model_name="DC120",
            rated_power_kw=120, protocol="demo", lifecycle_status="draft", status="offline", has_fault=0, is_online=0) for i in (1, 2)])
        db.add_all([models.ChargingGun(gun_id=i, pile_id=i, gun_no=1, gun_type="dc", connector_standard="GB",
            max_power_kw=60, status="offline", has_fault=0) for i in (1, 2)])
        db.execute(security.account_stations.insert().values(account_id=2, station_id=1))
        db.execute(security.account_operators.insert().values(account_id=6, operator_id=1))
        db.commit()
    return engine, factory, phone_key
