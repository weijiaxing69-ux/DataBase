"""独立设备联调入口：uvicorn app.demo:create_app --factory --host 127.0.0.1 --port 8001。

全部写入 SQLite 内存，重启清空。这里的订单、设备心跳和发送器是模拟适配器，
用于验证设备 Service 与成员4鉴权，不替代其他成员完整的业务模块。
"""
import hashlib
import secrets
from contextlib import asynccontextmanager
from typing import Annotated
from fastapi import APIRouter, Depends, FastAPI, HTTPException
from fastapi.security import HTTPAuthorizationCredentials
from pydantic import BaseModel, ConfigDict, Field
from sqlalchemy import func, select

from app.core import security
from app.core.config import settings
from app.core.database import get_db
from app.core.errors import BusinessError, install_error_handlers
from app.demo_data import create_demo_database
from app.modules.assets import dao, models, service
from app.modules.assets.router import router as assets_router, Database, CurrentActor, _bearer
from app.modules.assets.worker import dispatch_next
from app.modules.membership.router import router as auth_router


class DemoOrderRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")
    gun_id: int = Field(gt=0)


def _admin(actor):
    if "platform_admin" not in actor.roles:
        raise PermissionError("模拟控制台仅供平台管理员使用")


def build_demo_app(factory) -> FastAPI:
    """构建应用；只替换数据库依赖，认证、权限、Service 和 DAO 均执行真实代码。"""
    app = FastAPI(title="设备功能内存联调演示", version="1.0")
    install_error_handlers(app)
    app.include_router(assets_router, prefix="/api/v1/assets", tags=["场站与设备"])
    app.include_router(auth_router, prefix="/api/v1/auth", tags=["登录认证"])

    def demo_db():
        with factory() as db:
            yield db
    app.dependency_overrides[get_db] = demo_db
    router = APIRouter(prefix="/api/v1/demo", tags=["其他成员与设备模拟"])

    @router.post("/heartbeat", summary="用设备凭据模拟心跳及正常采样")
    def heartbeat(db: Database, credentials: Annotated[HTTPAuthorizationCredentials | None, Depends(_bearer)]):
        if credentials is None:
            raise HTTPException(401, "请携带设备凭据")
        now = service._now()
        credential = db.scalar(select(models.DeviceCredential).where(
            models.DeviceCredential.token_hash == hashlib.sha256(credentials.credentials.encode()).digest(),
            models.DeviceCredential.revoked_at.is_(None), models.DeviceCredential.expires_at > now))
        if credential is None:
            raise HTTPException(401, "设备凭据无效或已过期")
        try:
            service.touch_pile_heartbeat(db, pile_id=credential.pile_id, received_at=now)
            # 用正常温度、零离线时长模拟设备上报；复用真正的恢复检查逻辑。
            sample_id = (db.scalar(select(func.max(dao._readings.c.sample_id))) or 0) + 1
            db.execute(dao._readings.insert().values(sample_id=sample_id, pile_id=credential.pile_id,
                sampled_at=now, module_temperature_c=30, offline_seconds=0, fault_code=None))
            db.commit()
            return {"pile_id": str(credential.pile_id), "received": True}
        except Exception:
            db.rollback()
            raise

    @router.post("/piles/{pile_id}/recover", summary="复核模拟设备恢复条件")
    def recover(pile_id: int, db: Database, actor: CurrentActor):
        _admin(actor)
        try:
            service.recover_pile_status(db, pile_id=pile_id, verified_at=service._now())
            db.commit()
            return {"recovered": True}
        except Exception:
            db.rollback()
            raise

    @router.post("/scan-offline", summary="扫描模拟设备心跳超时")
    def scan(db: Database, actor: CurrentActor):
        _admin(actor)
        try:
            for pile_id in db.scalars(select(models.ChargingPile.pile_id)).all():
                service.mark_pile_offline(db, pile_id=pile_id, detected_at=service._now(), reason="模拟任务检测心跳超时")
            db.commit()
            return {"scanned": True}
        except Exception:
            db.rollback()
            raise

    @router.post("/orders", summary="模拟订单创建、占枪和启动命令入队")
    def start_order(request: DemoOrderRequest, db: Database, actor: CurrentActor):
        _admin(actor)
        try:
            snap = service.lock_gun(db, request.gun_id)
            if snap.active_order_id is not None:
                raise BusinessError("充电枪已有充电订单", status_code=409)
            order_id = db.execute(dao._orders.insert().values(gun_id=request.gun_id, status="charging")).lastrowid
            service.claim_gun_for_order(db, gun_id=request.gun_id, order_id=order_id)
            command_id = service.enqueue_device_command(db, gun_id=request.gun_id, order_id=order_id, command_type="start")
            db.commit()
            return {"order_id": str(order_id), "command_id": str(command_id)}
        except Exception:
            db.rollback()
            raise

    @router.post("/orders/{order_id}/finish", summary="模拟订单结束、释放枪和停止命令入队")
    def finish(order_id: int, db: Database, actor: CurrentActor):
        _admin(actor)
        try:
            order = db.execute(select(dao._orders).where(dao._orders.c.order_id == order_id)).mappings().one_or_none()
            if order is None:
                raise BusinessError("订单不存在", status_code=404)
            service.lock_gun(db, order["gun_id"])
            order = db.execute(select(dao._orders).where(dao._orders.c.order_id == order_id).with_for_update()).mappings().one()
            if order["status"] != "charging":
                raise BusinessError("订单已经结束", status_code=409)
            db.execute(dao._orders.update().where(dao._orders.c.order_id == order_id).values(status="awaiting_payment"))
            service.release_gun_for_order(db, gun_id=order["gun_id"], order_id=order_id, reason="模拟订单结束")
            command_id = service.enqueue_device_command(db, gun_id=order["gun_id"], order_id=order_id, command_type="stop")
            db.commit()
            return {"command_id": str(command_id), "status": "awaiting_payment"}
        except Exception:
            db.rollback()
            raise

    @router.post("/dispatch", summary="消费一条Outbox并模拟设备回执")
    def dispatch(db: Database, actor: CurrentActor):
        _admin(actor)
        def simulated_device(message):
            # 模拟设备只在通信在线时接受命令；真实适配器以后替换此函数。
            with factory() as device_db:
                pile = device_db.get(models.ChargingPile, message["pile_id"])
                if not pile or not pile.is_online:
                    raise ConnectionError("模拟设备离线")
                return True
        return {"processed": dispatch_next(db, send=simulated_device)}

    app.include_router(router)
    return app


def create_app():
    # 仅这个显式选择的演示入口改用内存库；app.main 不会导入或初始化演示数据。
    engine, factory, phone_key = create_demo_database()
    old_factory, old_signing, old_phone = security.SessionLocal, settings.auth_signing_key, settings.phone_encryption_key
    security.SessionLocal = factory
    settings.auth_signing_key = secrets.token_urlsafe(48)
    settings.phone_encryption_key = phone_key
    app = build_demo_app(factory)

    @asynccontextmanager
    async def lifespan(_app):
        try:
            yield
        finally:
            security.SessionLocal = old_factory
            settings.auth_signing_key = old_signing
            settings.phone_encryption_key = old_phone
            engine.dispose()
    app.router.lifespan_context = lifespan
    return app
