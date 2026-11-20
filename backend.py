"""Member 2 billing API for the V1.4 charging platform demo."""
from contextlib import contextmanager, asynccontextmanager
import asyncio
import logging
from datetime import datetime, timedelta, timezone
from decimal import Decimal, ROUND_HALF_UP, InvalidOperation
from contextvars import ContextVar
from functools import wraps
import secrets
import re
import os
import hashlib
import json

from fastapi import FastAPI, HTTPException, Header, Request, Query
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from fastapi.openapi.docs import get_swagger_ui_html
from fastapi.staticfiles import StaticFiles
from pathlib import Path
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, ConfigDict, Field, ValidationError
from typing import Literal
import pymysql

from db_connection import connect
from fleet_quota import (FleetQuotaError, reserve_fleet_quota, release_fleet_quota,
                         settle_fleet_quota, refund_fleet_quota)

async def expire_unpaid_loop():
    """Run the installed SQL procedure until the API stops."""
    while True:
        try:
            expired = await asyncio.to_thread(run_expire_unpaid)
            if expired:
                logging.info("订单到期释放任务已取消 %s 笔未支付订单", expired)
        except Exception:
            logging.exception("订单到期释放任务失败")
        await asyncio.sleep(60)


def run_expire_unpaid():
    """Run the database-owned expiry workflow and return its affected-order count."""
    with transaction() as cur:
        cur.execute("CALL sp_billing_expire_unpaid(UTC_TIMESTAMP(3), @billing_expired_count)")
        while cur.nextset():
            pass
        cur.execute("SELECT @billing_expired_count AS expired_count")
        expired = cur.fetchone()["expired_count"]
        cur.execute("DELETE FROM request_dedup WHERE expires_at < UTC_TIMESTAMP(3)")
        return int(expired or 0)


def verify_billing_runtime():
    """Fail at startup when the module SQL was not installed into this database."""
    required = {
        "procedure": {"sp_billing_expire_unpaid"},
        "trigger": {"trg_billing_meter_reading_validate"},
        "view": {"v_billing_order_balance", "v_billing_pending_collection", "v_billing_period_revenue"},
    }
    db = connect()
    try:
        with db.cursor() as cur:
            cur.execute("SELECT routine_name AS object_name FROM information_schema.routines "
                        "WHERE routine_schema=DATABASE() AND routine_name=%s", ("sp_billing_expire_unpaid",))
            found_procedure = {row["object_name"] for row in cur.fetchall()}
            cur.execute("SELECT trigger_name AS object_name FROM information_schema.triggers "
                        "WHERE trigger_schema=DATABASE() AND trigger_name=%s", ("trg_billing_meter_reading_validate",))
            found_trigger = {row["object_name"] for row in cur.fetchall()}
            cur.execute("SELECT table_name AS object_name FROM information_schema.views "
                        "WHERE table_schema=DATABASE() AND table_name LIKE 'v_billing_%'")
            found_view = {row["object_name"] for row in cur.fetchall()}
    finally:
        db.close()
    found = {"procedure": found_procedure, "trigger": found_trigger, "view": found_view}
    missing = [name for kind, names in required.items() for name in names - found[kind]]
    if missing:
        raise RuntimeError("计费模块数据库对象缺失：" + "、".join(sorted(missing))
                           + "。请先运行 install_billing_sql.py。")
    return {kind: sorted(found[kind] & names) for kind, names in required.items()}


@asynccontextmanager
async def billing_lifespan(application):
    await asyncio.to_thread(verify_billing_runtime)
    worker = asyncio.create_task(expire_unpaid_loop())
    try:
        yield
    finally:
        worker.cancel()
        try:
            await worker
        except asyncio.CancelledError:
            pass


app = FastAPI(title="新能源充电平台 · 订单计费", version="1.4", docs_url=None, lifespan=billing_lifespan)
app.add_middleware(CORSMiddleware, allow_origins=["http://localhost:5173"], allow_methods=["*"], allow_headers=["*"])
app.mount("/static", StaticFiles(directory=Path(__file__).resolve().parent / "static"), name="static")


def api_error(status, message, errors=None):
    body={"code":f"HTTP_{status}","message":message,"request_id":secrets.token_hex(8)}
    if errors is not None:
        body["errors"]=errors
    return JSONResponse(body,status_code=status)


@app.exception_handler(HTTPException)
async def handle_http_exception(request, exc):
    return api_error(exc.status_code,str(exc.detail))


@app.exception_handler(RequestValidationError)
async def handle_validation_exception(request, exc):
    errors=[{"field":".".join(map(str,error["loc"])),"message":error["msg"]}
            for error in exc.errors()]
    return api_error(422,"请求参数无效",errors)


@app.get("/docs", include_in_schema=False)
def local_swagger_docs():
    return get_swagger_ui_html(
        openapi_url=app.openapi_url,
        title=f"{app.title} - API 文档",
        swagger_js_url="/static/swagger/swagger-ui-bundle.js",
        swagger_css_url="/static/swagger/swagger-ui.css",
        swagger_favicon_url="/static/swagger/favicon-32x32.png",
    )
current_actor = ContextVar("current_actor", default=None)
idempotency_request = ContextVar("idempotency_request", default=None)
active_transaction_cursor = ContextVar("active_transaction_cursor", default=None)


def billing_permission(path, method):
    if "/price-reviews" in path:
        if method=="GET": return "billing.price_review.read"
        return "billing.price_review.decide" if path.endswith("/decisions") else "billing.price_review.create"
    if "/pricing-rules" in path:
        if method=="GET": return "billing.pricing_rule.read"
        return "billing.pricing_rule.disable" if path.endswith("/status") else "billing.pricing_rule.create"
    if path.endswith("/readings"):
        return "billing.meter_reading.create" if method=="POST" else "billing.order.read"
    if path.endswith("/payments"):
        return "billing.payment.create" if method=="POST" else "billing.payment.read"
    if "/refunds" in path:
        return "billing.refund.create" if method=="POST" else "billing.refund.read"
    if path.endswith("/reviews"):
        return "billing.order_review.create"
    if path.endswith("/finish"):
        return "billing.order.finish"
    if path.endswith("/cancel"):
        return "billing.order.cancel"
    if "/orders" in path:
        return "billing.order.create" if method=="POST" else "billing.order.read"
    return None


def password_hash(password, salt=None):
    salt = salt or secrets.token_bytes(16)
    digest = hashlib.scrypt(password.encode(), salt=salt, n=16384, r=8, p=1)
    return f"scrypt${salt.hex()}${digest.hex()}"


def verify_password(password, stored):
    try:
        _, salt, expected = stored.split("$")
        return secrets.compare_digest(password_hash(password, bytes.fromhex(salt)), stored)
    except (ValueError, TypeError):
        return False


@app.post("/api/v1/auth/login")
def login(body:dict):
    with transaction() as cur:
        cur.execute("SELECT * FROM sys_account WHERE username=%s FOR UPDATE",(body.get("username"),))
        account=cur.fetchone()
        if not account or account["status"]!="active" or (account["locked_until"] and account["locked_until"]>now()):
            fail(401,"账号或密码错误")
        if not verify_password(body.get("password",""),account["password_hash"]):
            attempts=account["failed_attempts"]+1
            cur.execute("UPDATE sys_account SET failed_attempts=%s,locked_until=%s WHERE account_id=%s",(attempts,now()+timedelta(minutes=15) if attempts>=5 else None,account["account_id"]))
            # Persist the failed-attempt counter before returning 401.
            cur.connection.commit()
            fail(401,"账号或密码错误")
        token=secrets.token_urlsafe(32)
        cur.execute("UPDATE sys_account SET failed_attempts=0,locked_until=NULL,last_login_at=%s WHERE account_id=%s",(now(),account["account_id"]))
        cur.execute("INSERT INTO sys_session(account_id,jti_hash,expires_at) VALUES (%s,%s,%s)",(account["account_id"],hashlib.sha256(token.encode()).digest(),now()+timedelta(hours=8)))
        return {"access_token":token,"token_type":"bearer","account_id":account["account_id"]}


@app.get("/api/v1/auth/me")
def auth_me(authorization: str = Header(...)):
    if not authorization.startswith("Bearer "):
        fail(401, "会话无效")
    digest = hashlib.sha256(authorization[7:].encode()).digest()
    with transaction() as cur:
        cur.execute("SELECT a.account_id,a.username FROM sys_session s JOIN sys_account a ON a.account_id=s.account_id WHERE s.jti_hash=%s AND s.revoked_at IS NULL AND s.expires_at>%s AND a.status='active'", (digest,now()))
        account=cur.fetchone()
        if not account: fail(401,"会话无效")
        cur.execute("SELECT r.role_code FROM sys_account_role ar JOIN sys_role r ON r.role_id=ar.role_id WHERE ar.account_id=%s",(account["account_id"],))
        account["roles"]=[row["role_code"] for row in cur.fetchall()]
        cur.execute("SELECT user_id FROM app_user WHERE account_id=%s",(account["account_id"],))
        user=cur.fetchone()
        account["user_id"]=user["user_id"] if user else None
        return account


@app.post("/api/v1/auth/logout", status_code=204)
def auth_logout(authorization: str = Header(...)):
    if not authorization.startswith("Bearer "): fail(401,"会话无效")
    digest=hashlib.sha256(authorization[7:].encode()).digest()
    with transaction() as cur:
        cur.execute("UPDATE sys_session SET revoked_at=%s WHERE jti_hash=%s AND revoked_at IS NULL",(now(),digest))
    return None


@app.middleware("http")
async def enforce_billing_auth(request:Request,call_next):
    if not request.url.path.startswith("/api/v1/billing/"):
        return await call_next(request)
    authorization=request.headers.get("authorization","")
    if not authorization.startswith("Bearer "):
        return api_error(401,"缺少登录会话")
    digest=hashlib.sha256(authorization[7:].encode()).digest()
    db=connect()
    try:
        with db.cursor() as cur:
            path=request.url.path
            method=request.method
            match=re.search(r"/orders/(\d+)",path)
            device_action=method=="POST" and match and (path.endswith("/readings") or path.endswith("/finish"))
            if device_action:
                cur.execute("SELECT 1 FROM device_credential dc JOIN charging_gun g ON g.pile_id=dc.pile_id "
                            "JOIN charging_order o ON o.gun_id=g.gun_id WHERE o.order_id=%s AND dc.token_hash=%s "
                            "AND dc.revoked_at IS NULL AND dc.expires_at>%s",(int(match.group(1)),digest,now()))
                if cur.fetchone():
                    marker=current_actor.set({"id":None,"roles":{"device"}})
                    return await call_next(request)
            cur.execute("SELECT a.account_id,a.status FROM sys_session s JOIN sys_account a ON a.account_id=s.account_id WHERE s.jti_hash=%s AND s.revoked_at IS NULL AND s.expires_at>%s",(digest,now()))
            account=cur.fetchone()
            if not account or account["status"]!="active":
                return api_error(401,"会话无效")
            cur.execute("SELECT r.role_code FROM sys_account_role ar JOIN sys_role r ON r.role_id=ar.role_id WHERE ar.account_id=%s",(account["account_id"],))
            roles={row["role_code"] for row in cur.fetchall()}
            if not roles:
                return api_error(403,"无业务权限")
            actor_id=account["account_id"]
            permission=billing_permission(path,method)
            if permission:
                cur.execute("SELECT 1 FROM sys_account_role ar JOIN sys_role_permission rp ON rp.role_id=ar.role_id "
                            "JOIN sys_permission p ON p.permission_id=rp.permission_id "
                            "WHERE ar.account_id=%s AND p.permission_code=%s LIMIT 1",(actor_id,permission))
                if not cur.fetchone():
                    return api_error(403,"无此操作权限")
            header_id=request.headers.get("x-actor-id")
            if header_id and header_id!=str(actor_id):
                return api_error(403,"身份不匹配")
            privileged=bool(roles & {"platform_admin","customer_service"})
            if method=="POST" and path.endswith("/readings") and not roles & {"platform_admin","maintenance_engineer"}:
                return api_error(403,"无设备采样权限")
            if method=="POST" and path.endswith("/finish") and not roles & {"platform_admin","maintenance_engineer"}:
                return api_error(403,"无结束充电权限")
            if "price-reviews" in path and method=="GET" and "platform_admin" not in roles:
                return api_error(403,"无审批查询权限")
            if method!="GET" and ("pricing-rules" in path or "price-reviews" in path) and "platform_admin" not in roles:
                return api_error(403,"无价格管理权限")
            if method=="POST" and path.endswith("/reviews") and not privileged:
                return api_error(403,"无订单复核权限")
            if "refunds" in path and method=="POST" and not privileged:
                return api_error(403,"无退款管理权限")
            if match and "customer_service" in roles and "platform_admin" not in roles:
                cur.execute("SELECT 1 FROM charging_order o JOIN sys_account_station ast ON ast.station_id=o.station_id WHERE o.order_id=%s AND ast.account_id=%s",(int(match.group(1)),actor_id))
                if not cur.fetchone():
                    return api_error(403,"无该场站的数据权限")
            refund_match=re.search(r"/refunds/(\d+)",path)
            if refund_match and "customer_service" in roles and "platform_admin" not in roles:
                cur.execute("SELECT 1 FROM refund_record r JOIN payment_record p ON p.payment_id=r.payment_id JOIN charging_order o ON o.order_id=p.order_id JOIN sys_account_station ast ON ast.station_id=o.station_id WHERE r.refund_id=%s AND ast.account_id=%s",(int(refund_match.group(1)),actor_id))
                if not cur.fetchone():
                    return api_error(403,"无该场站的数据权限")
            if match and "operator_manager" in roles and not privileged:
                cur.execute("SELECT 1 FROM charging_order o JOIN sys_account_operator ao ON ao.operator_id=o.operator_id "
                            "WHERE o.order_id=%s AND ao.account_id=%s",(int(match.group(1)),actor_id))
                if not cur.fetchone():
                    return api_error(403,"无该运营商的数据权限")
            if match and "fleet_admin" in roles and not privileged and "operator_manager" not in roles:
                cur.execute("SELECT 1 FROM charging_order o JOIN sys_account_fleet af ON af.fleet_id=o.fleet_id WHERE o.order_id=%s AND af.account_id=%s",(int(match.group(1)),actor_id))
                if not cur.fetchone():
                    return api_error(403,"无权访问该车队订单")
            if match and device_action and "maintenance_engineer" in roles and not privileged:
                cur.execute("SELECT 1 FROM charging_order o JOIN sys_account_station ast ON ast.station_id=o.station_id "
                            "WHERE o.order_id=%s AND ast.account_id=%s",(int(match.group(1)),actor_id))
                if not cur.fetchone():
                    return api_error(403,"无该设备的数据权限")
            if match and not privileged and "fleet_admin" not in roles and "operator_manager" not in roles and not (device_action and "maintenance_engineer" in roles):
                cur.execute("SELECT u.account_id FROM charging_order o JOIN app_user u ON u.user_id=o.user_id WHERE o.order_id=%s",(int(match.group(1)),))
                owner=cur.fetchone()
                if owner and owner["account_id"]!=actor_id:
                    return api_error(403,"无权访问该订单")
            marker=current_actor.set({"id":actor_id,"roles":roles})
        dedup_marker = None
        if request.method == "POST" and request.headers.get("Idempotency-Key") is not None:
            key = request.headers["Idempotency-Key"]
            if not key or len(key) > 64:
                return api_error(422,"Idempotency-Key 长度必须为 1 至 64")
            body = await request.body()
            try:
                canonical = json.dumps(json.loads(body or b"{}"),sort_keys=True,separators=(",",":"),ensure_ascii=False)
            except (ValueError,UnicodeDecodeError):
                canonical = body.decode("utf-8",errors="replace")
            digest = hashlib.sha256((path+"\n"+canonical).encode()).digest()
            dedup_marker = idempotency_request.set({"key":key,"hash":digest})
        try:
            return await call_next(request)
        finally:
            if dedup_marker is not None:
                idempotency_request.reset(dedup_marker)
    finally:
        if 'marker' in locals(): current_actor.reset(marker)
        db.close()


def now():
    return datetime.now(timezone.utc).replace(tzinfo=None)


def money(value):
    return Decimal(str(value)).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)


def request_money(value, name):
    try:
        amount=money(value)
        if not amount.is_finite(): raise InvalidOperation
        return amount
    except (InvalidOperation,ValueError,TypeError):
        fail(422,f"{name}必须是有效金额")


def output(value):
    return json.loads(json.dumps(value, default=str, ensure_ascii=False))


def fail(status, message):
    raise HTTPException(status_code=status, detail=message)


@contextmanager
def transaction():
    shared = active_transaction_cursor.get()
    if shared is not None:
        yield shared
        return
    db = connect()
    try:
        with db.cursor() as cur:
            yield cur
        db.commit()
    except HTTPException:
        db.rollback()
        raise
    except pymysql.IntegrityError as exc:
        db.rollback()
        fail(409, str(exc.args[1]))
    except pymysql.OperationalError as exc:
        db.rollback()
        if exc.args and exc.args[0]==1644:
            fail(409,str(exc.args[1]))
        raise
    except Exception:
        db.rollback()
        raise
    finally:
        db.close()


def idempotent(operation):
    """Store the result and the business mutation in one MySQL transaction."""
    def decorate(fn):
        @wraps(fn)
        def wrapped(*args, **kwargs):
            request = idempotency_request.get()
            actor = current_actor.get()
            if request is None or actor is None or actor["id"] is None:
                return fn(*args, **kwargs)
            with transaction() as cur:
                cur.execute("INSERT INTO request_dedup(account_id,operation,idempotency_key,request_hash,expires_at) "
                            "VALUES (%s,%s,%s,%s,%s) ON DUPLICATE KEY UPDATE dedup_id=LAST_INSERT_ID(dedup_id)",
                            (actor["id"],operation,request["key"],request["hash"],now()+timedelta(days=1)))
                dedup_id = cur.lastrowid
                cur.execute("SELECT request_hash,response_body,status FROM request_dedup WHERE dedup_id=%s FOR UPDATE",(dedup_id,))
                row = cur.fetchone()
                if row["request_hash"] != request["hash"]:
                    fail(409,"相同 Idempotency-Key 的请求内容不同")
                if row["status"] == "completed":
                    return json.loads(row["response_body"])
                marker = active_transaction_cursor.set(cur)
                try:
                    result = fn(*args, **kwargs)
                finally:
                    active_transaction_cursor.reset(marker)
                result = output(result)
                cur.execute("UPDATE request_dedup SET response_status=%s,response_body=%s,status='completed' "
                            "WHERE dedup_id=%s",(201 if operation in {"create_pricing_rule","submit_price_review","start_order","submit_meter_reading","create_payment","create_refund","review_order"} else 200,
                            json.dumps(result,ensure_ascii=False),dedup_id))
                return result
        return wrapped
    return decorate


def one(cur, sql, args=(), lock=False):
    cur.execute(sql + (" FOR UPDATE" if lock else ""), args)
    row = cur.fetchone()
    if not row:
        fail(404, "记录不存在")
    return row


def rows(table, *, where="1=1", args=()):
    with transaction() as cur:
        cur.execute(f"SELECT * FROM `{table}` WHERE {where} ORDER BY 1 DESC LIMIT 100", args)
        return output(cur.fetchall())


def page_rows(table, *, where, args, page, page_size, order_col):
    with transaction() as cur:
        cur.execute(f"SELECT COUNT(*) AS total FROM `{table}` WHERE {where}",args)
        total=cur.fetchone()["total"]
        cur.execute(f"SELECT * FROM `{table}` WHERE {where} ORDER BY `{order_col}` DESC LIMIT %s OFFSET %s",
                    (*args,page_size,(page-1)*page_size))
        items=cur.fetchall()
        if table=="charging_order":
            for item in items: item.pop("active_gun_id",None)
        return output({"items":items,"total":total,"page":page,"page_size":page_size})


def require_interval(start_at,end_at):
    if start_at and end_at and end_at<=start_at: fail(422,"结束时间必须晚于开始时间")


def query_where(filters, *, keyword=None, status=None, start_at=None, end_at=None,
                time_col="created_at", keyword_col=None, extra=None):
    clauses=[filters[0]]
    args=list(filters[1])
    if status:
        clauses.append("status=%s");args.append(status)
    if keyword and keyword_col:
        clauses.append(f"CAST(`{keyword_col}` AS CHAR) LIKE %s");args.append(f"%{keyword}%")
    if start_at:
        clauses.append(f"`{time_col}` >= %s");args.append(start_at)
    if end_at:
        clauses.append(f"`{time_col}` < %s");args.append(end_at)
    for col,value in (extra or {}).items():
        if value is not None:
            clauses.append(f"`{col}`=%s");args.append(value)
    return " AND ".join(clauses),tuple(args)


def can_read_station(cur, actor, station_id):
    if "platform_admin" in actor["roles"]:
        return True
    if "customer_service" in actor["roles"]:
        cur.execute("SELECT 1 FROM sys_account_station WHERE account_id=%s AND station_id=%s",(actor["id"],station_id))
    elif "fleet_admin" in actor["roles"]:
        cur.execute("SELECT 1 FROM charging_order o JOIN sys_account_fleet af ON af.fleet_id=o.fleet_id "
                    "WHERE af.account_id=%s AND o.station_id=%s LIMIT 1",(actor["id"],station_id))
    elif "operator_manager" in actor["roles"]:
        cur.execute("SELECT 1 FROM station s JOIN sys_account_operator ao ON ao.operator_id=s.operator_id "
                    "WHERE ao.account_id=%s AND s.station_id=%s LIMIT 1",(actor["id"],station_id))
    else:
        cur.execute("SELECT 1 FROM charging_order o JOIN app_user u ON u.user_id=o.user_id "
                    "WHERE u.account_id=%s AND o.station_id=%s LIMIT 1",(actor["id"],station_id))
    return bool(cur.fetchone())


class PricingPeriodIn(BaseModel):
    model_config = ConfigDict(extra="forbid")
    period_type: Literal["peak", "flat", "valley"]
    start_minute: int = Field(ge=0, lt=1440)
    end_minute: int = Field(gt=0, le=1440)
    electricity_rate: Decimal = Field(ge=0, allow_inf_nan=False)
    service_rate: Decimal = Field(ge=0, allow_inf_nan=False)


class RuleIn(BaseModel):
    model_config = ConfigDict(extra="forbid")
    station_id: int
    rule_name: str
    free_service_minutes: int = Field(default=0, ge=0)
    minimum_amount: Decimal = Field(default=Decimal("0.00"), ge=0, allow_inf_nan=False)
    valid_from: datetime
    valid_until: datetime
    periods: list[PricingPeriodIn]


class ReadingIn(BaseModel):
    model_config = ConfigDict(extra="forbid")
    sampled_at: datetime | None = None
    cumulative_energy_kwh: Decimal = Field(ge=0, allow_inf_nan=False)
    soc: Decimal | None = Field(default=None, ge=0, le=100, allow_inf_nan=False)


def require_body_fields(body, allowed):
    unknown = set(body) - set(allowed)
    if unknown:
        fail(422, "未登记的请求字段：" + ", ".join(sorted(unknown)))


def validate_periods(periods):
    if not periods:
        fail(422, "必须配置价格时段")
    ordered = sorted(periods, key=lambda p: int(p["start_minute"]))
    end = 0
    for p in ordered:
        start, stop = int(p["start_minute"]), int(p["end_minute"])
        if start != end or stop <= start or stop > 1440 or p["period_type"] not in ("peak", "flat", "valley"):
            fail(422, "价格时段须无缝覆盖全天且不重叠")
        if Decimal(str(p["electricity_rate"])) < 0 or Decimal(str(p["service_rate"])) < 0:
            fail(422, "价格不得为负")
        end = stop
    if end != 1440:
        fail(422, "价格时段须覆盖全天")
    return ordered


def calculate_segments(samples, periods, started_at, finished_at, free_minutes):
    """Price measured intervals; reject any interval crossing an unmeasured tariff boundary."""
    if len(samples) < 2 or samples[0]["sampled_at"] > started_at + timedelta(seconds=5):
        fail(409, "缺少开始边界读数")
    if samples[-1]["sampled_at"] < finished_at - timedelta(seconds=5):
        fail(409, "缺少结束边界读数")
    free_end = started_at + timedelta(minutes=free_minutes)
    result = []
    for left, right in zip(samples, samples[1:]):
        a, b = left["sampled_at"], right["sampled_at"]
        delta = right["cumulative_energy_kwh"] - left["cumulative_energy_kwh"]
        if b <= a or delta < 0:
            fail(409, "读数时间或电量回退")
        minute = a.hour * 60 + a.minute
        eligible = [p for p in periods if p["start_minute"] <= minute < p["end_minute"]
                    and p.get("valid_from", datetime.min) <= a < p.get("valid_until", datetime.max)]
        period = max(eligible, key=lambda p: p.get("valid_from", datetime.min), default=None)
        if not period:
            fail(409, "价格时段缺失")
        boundary = a.replace(hour=0, minute=0, second=0, microsecond=0) + timedelta(minutes=period["end_minute"])
        boundary = min(boundary, period.get("valid_until", datetime.max))
        next_rule_boundary = any(a < p.get("valid_from", datetime.min) < b for p in periods)
        if b > boundary or next_rule_boundary or (a < free_end < b):
            fail(409, "跨价格或免费时长边界缺少读数")
        service_rate = Decimal("0") if b <= free_end else period["service_rate"]
        result.append((period, a, b, delta, money(delta * period["electricity_rate"]), money(delta * service_rate)))
    return result


@app.get("/api/v1/billing/pricing-rules")
def list_pricing_rules(page:int=Query(1,ge=1),page_size:int=Query(20,ge=1,le=100),
                       keyword:str|None=None,station_id:int|None=None,status:str|None=None,
                       start_at:datetime|None=None,end_at:datetime|None=None):
    require_interval(start_at,end_at)
    actor=current_actor.get()
    if "platform_admin" in actor["roles"]: scope=("1=1",())
    elif "customer_service" in actor["roles"]:
        scope=("station_id IN (SELECT station_id FROM sys_account_station WHERE account_id=%s)",(actor["id"],))
    elif "fleet_admin" in actor["roles"]:
        scope=("station_id IN (SELECT o.station_id FROM charging_order o JOIN sys_account_fleet af ON af.fleet_id=o.fleet_id WHERE af.account_id=%s)",(actor["id"],))
    elif "operator_manager" in actor["roles"]:
        scope=("station_id IN (SELECT s.station_id FROM station s JOIN sys_account_operator ao ON ao.operator_id=s.operator_id WHERE ao.account_id=%s)",(actor["id"],))
    else:
        scope=("station_id IN (SELECT o.station_id FROM charging_order o JOIN app_user u ON u.user_id=o.user_id WHERE u.account_id=%s)",(actor["id"],))
    where,args=query_where(scope,keyword=keyword,status=status,start_at=start_at,end_at=end_at,
                           time_col="created_at",keyword_col="rule_name",extra={"station_id":station_id})
    return page_rows("pricing_rule",where=where,args=args,page=page,page_size=page_size,order_col="rule_id")


@app.get("/api/v1/billing/pricing-rules/{rule_id}")
def get_pricing_rule(rule_id: int):
    with transaction() as cur:
        rule = one(cur, "SELECT * FROM pricing_rule WHERE rule_id=%s", (rule_id,))
        if not can_read_station(cur,current_actor.get(),rule["station_id"]): fail(403,"无该场站的数据权限")
        cur.execute("SELECT * FROM pricing_period WHERE rule_id=%s ORDER BY start_minute", (rule_id,))
        rule["periods"] = cur.fetchall()
        return output(rule)


@app.post("/api/v1/billing/pricing-rules", status_code=201)
@idempotent("create_pricing_rule")
def create_pricing_rule(body: RuleIn):
    if body.valid_until <= body.valid_from: fail(422, "生效区间无效")
    periods = validate_periods([period.model_dump() for period in body.periods])
    with transaction() as cur:
        one(cur, "SELECT station_id FROM station WHERE station_id=%s", (body.station_id,))
        cur.execute("INSERT INTO pricing_rule(station_id,rule_name,free_service_minutes,minimum_amount,valid_from,valid_until,status) VALUES (%s,%s,%s,%s,%s,%s,'draft')", (body.station_id, body.rule_name, body.free_service_minutes, body.minimum_amount, body.valid_from, body.valid_until))
        rule_id = cur.lastrowid
        for p in periods:
            cur.execute("INSERT INTO pricing_period(rule_id,period_type,start_minute,end_minute,electricity_rate,service_rate) VALUES (%s,%s,%s,%s,%s,%s)", (rule_id,p["period_type"],p["start_minute"],p["end_minute"],p["electricity_rate"],p["service_rate"]))
        return {"rule_id": rule_id, "status": "draft"}


@app.post("/api/v1/billing/pricing-rules/{rule_id}/status")
@idempotent("change_pricing_rule_status")
def change_pricing_rule_status(rule_id: int, body: dict):
    require_body_fields(body,("status",))
    status = body.get("status")
    if status != "disabled": fail(409, "启用价格须通过审批")
    with transaction() as cur:
        rule = one(cur, "SELECT * FROM pricing_rule WHERE rule_id=%s", (rule_id,), True)
        if rule["status"] != "active": fail(409, "只可停用已启用规则")
        cur.execute("UPDATE pricing_rule SET status='disabled' WHERE rule_id=%s", (rule_id,))
        return {"rule_id": rule_id, "status": "disabled"}


@app.get("/api/v1/billing/price-reviews")
def list_price_reviews(page:int=Query(1,ge=1),page_size:int=Query(20,ge=1,le=100)):
    return page_rows("pricing_review",where="1=1",args=(),page=page,page_size=page_size,order_col="review_id")


@app.get("/api/v1/billing/price-reviews/{review_id}")
def get_price_review(review_id: int):
    with transaction() as cur: return output(one(cur,"SELECT * FROM pricing_review WHERE review_id=%s",(review_id,)))


@app.post("/api/v1/billing/price-reviews", status_code=201)
@idempotent("submit_price_review")
def submit_price_review(body: dict, x_actor_id: int = Header(...)):
    require_body_fields(body,("rule_id","price_id"))
    rule_id, price_id = body.get("rule_id"), body.get("price_id")
    if (rule_id is None) == (price_id is None): fail(422, "普通规则或车队专价二选一")
    with transaction() as cur:
        if rule_id:
            target = one(cur,"SELECT * FROM pricing_rule WHERE rule_id=%s",(rule_id,),True)
            if target["status"] != "draft": fail(409,"只可提交草稿")
            cur.execute("SELECT * FROM pricing_period WHERE rule_id=%s ORDER BY start_minute",(rule_id,))
            target["periods"] = cur.fetchall()
        else:
            target = one(cur,"SELECT * FROM fleet_price WHERE price_id=%s",(price_id,),True)
            if target["status"] != "draft": fail(409,"只可提交草稿")
        snapshot = json.dumps(output(target),sort_keys=True,ensure_ascii=False)
        digest = hashlib.sha256(snapshot.encode()).digest()
        cur.execute("INSERT INTO pricing_review(rule_id,price_id,requested_by,requested_at,content_hash,target_snapshot) VALUES (%s,%s,%s,%s,%s,%s)",(rule_id,price_id,x_actor_id,now(),digest,snapshot))
        return {"review_id":cur.lastrowid,"decision":"pending"}


@app.post("/api/v1/billing/price-reviews/{review_id}/decisions")
@idempotent("review_price_change")
def review_price_change(review_id:int,body:dict,x_actor_id:int=Header(...)):
    require_body_fields(body,("decision","note"))
    decision = body.get("decision")
    if decision not in ("approved","rejected"): fail(422,"审批结果无效")
    with transaction() as cur:
        review=one(cur,"SELECT * FROM pricing_review WHERE review_id=%s",(review_id,),True)
        if review["decision"]!="pending" or review["requested_by"]==x_actor_id: fail(409,"不能重复审批或自批")
        table,key,target_id=("pricing_rule","rule_id",review["rule_id"]) if review["rule_id"] else ("fleet_price","price_id",review["price_id"])
        target=one(cur,f"SELECT * FROM `{table}` WHERE `{key}`=%s",(target_id,),True)
        if table=="pricing_rule":
            cur.execute("SELECT * FROM pricing_period WHERE rule_id=%s ORDER BY start_minute",(target_id,))
            target["periods"]=cur.fetchall()
        snapshot=json.dumps(output(target),sort_keys=True,ensure_ascii=False)
        if hashlib.sha256(snapshot.encode()).digest()!=review["content_hash"]: fail(409,"草稿已变更，请重新提交审批")
        if decision=="approved":
            if table=="pricing_rule":
                cur.execute("SELECT 1 FROM pricing_rule WHERE station_id=%s AND rule_id<>%s AND status='active' "
                            "AND valid_from<%s AND valid_until>%s LIMIT 1",
                            (target["station_id"],target_id,target["valid_until"],target["valid_from"]))
            else:
                cur.execute("SELECT 1 FROM fleet_price WHERE fleet_id=%s AND period_id=%s AND price_id<>%s "
                            "AND status='active' AND valid_from<%s AND valid_until>%s LIMIT 1",
                            (target["fleet_id"],target["period_id"],target_id,target["valid_until"],target["valid_from"]))
            if cur.fetchone(): fail(409,"生效区间与已启用价格重叠")
        cur.execute("UPDATE pricing_review SET decision=%s,reviewed_by=%s,reviewed_at=%s,review_note=%s WHERE review_id=%s",(decision,x_actor_id,now(),body.get("note"),review_id))
        if decision=="approved": cur.execute(f"UPDATE `{table}` SET status='active' WHERE `{key}`=%s",(target_id,))
        return {"review_id":review_id,"decision":decision}


@app.get("/api/v1/billing/orders")
def list_orders(page:int=Query(1,ge=1),page_size:int=Query(20,ge=1,le=100),keyword:str|None=None,
                user_id:int|None=None,station_id:int|None=None,fleet_id:int|None=None,status:str|None=None,
                start_at:datetime|None=None,end_at:datetime|None=None):
    require_interval(start_at,end_at)
    actor=current_actor.get()
    if "platform_admin" in actor["roles"]:
        scope=("1=1",())
    elif "customer_service" in actor["roles"]:
        scope=("station_id IN (SELECT station_id FROM sys_account_station WHERE account_id=%s)",(actor["id"],))
    elif "fleet_admin" in actor["roles"]:
        scope=("fleet_id IN (SELECT fleet_id FROM sys_account_fleet WHERE account_id=%s)",(actor["id"],))
    elif "operator_manager" in actor["roles"]:
        scope=("operator_id IN (SELECT operator_id FROM sys_account_operator WHERE account_id=%s)",(actor["id"],))
    else:
        scope=("user_id IN (SELECT user_id FROM app_user WHERE account_id=%s)",(actor["id"],))
    where,args=query_where(scope,keyword=keyword,status=status,start_at=start_at,end_at=end_at,
                           time_col="started_at",keyword_col="order_id",
                           extra={"user_id":user_id,"station_id":station_id,"fleet_id":fleet_id})
    return page_rows("charging_order",where=where,args=args,page=page,page_size=page_size,order_col="order_id")


@app.get("/api/v1/billing/orders/{order_id}")
def get_order(order_id:int):
    with transaction() as cur:
        order=one(cur,"SELECT * FROM charging_order WHERE order_id=%s",(order_id,))
        for table in ("meter_reading","billing_detail","payment_record"):
            cur.execute(f"SELECT * FROM `{table}` WHERE order_id=%s ORDER BY 1",(order_id,))
            order[table]=cur.fetchall()
        order["billing_details"]=order["billing_detail"]
        cur.execute("SELECT COALESCE(SUM(amount),0) AS amount FROM payment_record WHERE order_id=%s AND status='succeeded'",(order_id,))
        order["paid_amount"]=cur.fetchone()["amount"]
        cur.execute("SELECT COALESCE(SUM(r.amount),0) AS amount FROM refund_record r JOIN payment_record p ON p.payment_id=r.payment_id WHERE p.order_id=%s AND r.status='succeeded'",(order_id,))
        order["refunded_amount"]=cur.fetchone()["amount"]
        cur.execute("SELECT * FROM refund_record WHERE payment_id IN (SELECT payment_id FROM payment_record WHERE order_id=%s) ORDER BY refund_id",(order_id,))
        order["refund_record"]=cur.fetchall()
        cur.execute("SELECT * FROM coupon_usage WHERE order_id=%s ORDER BY usage_id",(order_id,))
        order["coupon_usage"]=cur.fetchall()
        cur.execute("SELECT * FROM order_review WHERE order_id=%s ORDER BY review_id",(order_id,))
        order["order_review"]=cur.fetchall()
        order.pop("active_gun_id",None)
        return output(order)


@app.post("/api/v1/billing/orders",status_code=201)
@idempotent("start_order")
def start_order(body:dict,x_actor_id:int=Header(...)):
    require_body_fields(body,("user_id","gun_id","vehicle_id","authorization_id","order_mode"))
    try: user_id,gun_id=int(body.get("user_id",0)),int(body.get("gun_id",0))
    except (ValueError,TypeError): fail(422,"用户和充电枪编号无效")
    if not user_id or not gun_id: fail(422,"需指定用户和充电枪")
    mode=body.get("order_mode","personal")
    if mode not in ("personal","fleet"): fail(422,"订单模式无效")
    with transaction() as cur:
        user=one(cur,"SELECT * FROM app_user WHERE user_id=%s",(user_id,),True)
        if user["status"]!="active": fail(409,"用户账号不可用")
        actor=current_actor.get()
        authorization=None
        fleet_id=None
        if mode=="fleet":
            authorization=one(cur,"SELECT a.*,c.fleet_id,c.status AS card_status,c.valid_from AS card_from,c.valid_until AS card_until "
                              "FROM fleet_authorization a JOIN fleet_card c ON c.card_id=a.card_id "
                              "WHERE a.authorization_id=%s",(body.get("authorization_id"),),True)
            fleet_id=authorization["fleet_id"]
            if authorization["user_id"]!=user_id or (body.get("vehicle_id") and int(body["vehicle_id"])!=authorization["vehicle_id"]):
                fail(403,"车队授权与用户或车辆不匹配")
            if ("platform_admin" not in actor["roles"] and user["account_id"]!=actor["id"]):
                cur.execute("SELECT 1 FROM sys_account_fleet WHERE account_id=%s AND fleet_id=%s",(actor["id"],fleet_id))
                if "fleet_admin" not in actor["roles"] or not cur.fetchone(): fail(403,"无该车队的启动权限")
            instant=now()
            if (authorization["status"]!="active" or authorization["card_status"]!="active" or
                not authorization["valid_from"]<=instant<authorization["valid_until"] or
                not authorization["card_from"]<=instant<authorization["card_until"]):
                fail(409,"车队授权或卡不在有效期")
            vehicle=one(cur,"SELECT status FROM vehicle WHERE vehicle_id=%s",(authorization["vehicle_id"],))
            if vehicle["status"]!="active": fail(409,"授权车辆不可用")
        elif "platform_admin" not in actor["roles"] and user["account_id"]!=actor["id"]:
            fail(403,"只能为本人启动充电")
        gun=one(cur,"SELECT * FROM charging_gun WHERE gun_id=%s",(gun_id,),True)
        pile=one(cur,"SELECT * FROM charging_pile WHERE pile_id=%s",(gun["pile_id"],),True)
        if (gun["status"]!="idle" or gun["has_fault"] or pile["has_fault"] or
            pile["status"] in ("fault","offline") or pile["lifecycle_status"]!="active"):
            fail(409,"充电枪当前不可用")
        station=one(cur,"SELECT * FROM station WHERE station_id=%s",(pile["station_id"],))
        cur.execute("SELECT * FROM pricing_rule WHERE station_id=%s AND status='active' AND valid_from<=%s AND valid_until>%s ORDER BY valid_from DESC LIMIT 1",(station["station_id"],now(),now()))
        rule=cur.fetchone()
        if not rule: fail(409,"没有有效计费规则")
        started=now()
        cur.execute("INSERT INTO charging_order(user_id,gun_id,vehicle_id,authorization_id,rule_id,operator_id,station_id,fleet_id,order_mode,status,started_at,free_service_minutes_snapshot,minimum_amount_snapshot) VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,'charging',%s,%s,%s)",(user_id,gun_id,authorization["vehicle_id"] if authorization else body.get("vehicle_id"),authorization["authorization_id"] if authorization else None,rule["rule_id"],station["operator_id"],station["station_id"],fleet_id,mode,started,rule["free_service_minutes"],rule["minimum_amount"]))
        order_id=cur.lastrowid
        if authorization:
            try: reserve_fleet_quota(cur,authorization=authorization,order_id=order_id,at=started)
            except FleetQuotaError as exc: fail(409,str(exc))
        cur.execute("UPDATE charging_gun SET status='occupied' WHERE gun_id=%s",(gun_id,))
        cur.execute("INSERT INTO device_command(pile_id,gun_id,order_id,command_type) VALUES (%s,%s,%s,'start')",(pile["pile_id"],gun_id,order_id))
        return {"order_id":order_id,"status":"charging"}


@app.post("/api/v1/billing/orders/{order_id}/readings",status_code=201)
@idempotent("submit_meter_reading")
def submit_meter_reading(order_id:int,body:ReadingIn):
    if isinstance(body,dict):
        try:
            body=ReadingIn.model_validate(body)
        except ValidationError:
            fail(422,"采样请求参数无效")
    energy=body.cumulative_energy_kwh
    with transaction() as cur:
        order=one(cur,"SELECT * FROM charging_order WHERE order_id=%s",(order_id,),True)
        if order["status"]!="charging": fail(409,"订单已结束")
        cur.execute("SELECT cumulative_energy_kwh FROM meter_reading WHERE order_id=%s ORDER BY sampled_at DESC,reading_id DESC LIMIT 1",(order_id,))
        previous=cur.fetchone()
        if previous and energy<previous["cumulative_energy_kwh"]: fail(409,"累计电量不可回退")
        stamp=body.sampled_at or now()
        actor=current_actor.get()
        source="device" if actor and "device" in actor["roles"] else "simulator"
        cur.execute("INSERT INTO meter_reading(order_id,sampled_at,cumulative_energy_kwh,soc,source) VALUES (%s,%s,%s,%s,%s)",(order_id,stamp,energy,body.soc,source))
        return {"reading_id":cur.lastrowid}


@app.get("/api/v1/billing/orders/{order_id}/readings")
def list_meter_readings(order_id:int,page:int=Query(1,ge=1),page_size:int=Query(20,ge=1,le=100)):
    return page_rows("meter_reading",where="order_id=%s",args=(order_id,),page=page,page_size=page_size,order_col="reading_id")


@app.post("/api/v1/billing/orders/{order_id}/finish")
@idempotent("finish_order")
def finish_order(order_id:int,body:dict|None=None):
    require_body_fields(body or {},("coupon_id",))
    with transaction() as cur:
        order=one(cur,"SELECT * FROM charging_order WHERE order_id=%s",(order_id,),True)
        if order["status"]!="charging": fail(409,"订单不在充电中")
        queue_stop_command(cur,order)
        cur.execute("SELECT * FROM meter_reading WHERE order_id=%s ORDER BY sampled_at,reading_id",(order_id,))
        samples=cur.fetchall()
        finished=now()
        if len(samples)<2 or samples[-1]["cumulative_energy_kwh"]<samples[0]["cumulative_energy_kwh"]:
            cur.execute("UPDATE charging_order SET status='awaiting_payment',finished_at=%s,review_required=1,review_reason='缺少有效边界读数' WHERE order_id=%s",(finished,order_id))
            cur.execute("UPDATE charging_gun SET status='idle' WHERE gun_id=%s AND status='occupied'",(order["gun_id"],))
            return {"order_id":order_id,"review_required":True}
        cur.execute("SELECT p.period_id,p.rule_id,p.period_type,p.start_minute,p.end_minute,"
                    "p.electricity_rate,p.service_rate,r.valid_from,r.valid_until "
                    "FROM pricing_rule r JOIN pricing_period p ON p.rule_id=r.rule_id "
                    "WHERE r.station_id=%s AND (r.status='active' OR r.rule_id=%s) "
                    "AND r.valid_from<%s AND r.valid_until>%s ORDER BY r.valid_from,p.start_minute",
                    (order["station_id"],order["rule_id"],finished,order["started_at"]))
        periods=cur.fetchall()
        energy=samples[-1]["cumulative_energy_kwh"]-samples[0]["cumulative_energy_kwh"]
        try:
            segments=calculate_segments(samples,periods,order["started_at"],finished,order["free_service_minutes_snapshot"])
        except HTTPException:
            cur.execute("UPDATE charging_order SET status='awaiting_payment',finished_at=%s,energy_kwh=%s,review_required=1,review_reason='计费边界缺少有效读数' WHERE order_id=%s",(finished,energy,order_id))
            cur.execute("UPDATE charging_gun SET status='idle' WHERE gun_id=%s AND status='occupied'",(order["gun_id"],))
            return {"order_id":order_id,"review_required":True}
        priced=[]
        try:
            for period,a,b,segment_energy,electricity_part,service_part in segments:
                price=None
                electricity_rate=period["electricity_rate"]
                service_rate=Decimal("0") if b<=order["started_at"]+timedelta(minutes=order["free_service_minutes_snapshot"]) else period["service_rate"]
                if order["order_mode"]=="fleet":
                    cur.execute("SELECT 1 FROM fleet_price WHERE fleet_id=%s AND period_id=%s AND status='active' "
                                "AND ((valid_from>%s AND valid_from<%s) OR (valid_until>%s AND valid_until<%s)) LIMIT 1",
                                (order["fleet_id"],period["period_id"],a,b,a,b))
                    if cur.fetchone(): fail(409,"车队专价边界缺少读数")
                    cur.execute("SELECT * FROM fleet_price WHERE fleet_id=%s AND period_id=%s AND status='active' "
                                "AND valid_from<=%s AND valid_until>=%s ORDER BY valid_from DESC LIMIT 1",
                                (order["fleet_id"],period["period_id"],a,b))
                    price=cur.fetchone()
                    if price:
                        electricity_rate=price["electricity_rate"]
                        service_rate=Decimal("0") if service_rate==0 else price["service_rate"]
                        electricity_part=money(segment_energy*electricity_rate)
                        service_part=money(segment_energy*service_rate)
                priced.append((period,a,b,segment_energy,electricity_rate,service_rate,electricity_part,service_part,price))
        except HTTPException:
            cur.execute("UPDATE charging_order SET status='awaiting_payment',finished_at=%s,energy_kwh=%s,review_required=1,review_reason='车队专价边界缺少有效读数' WHERE order_id=%s",(finished,energy,order_id))
            cur.execute("UPDATE charging_gun SET status='idle' WHERE gun_id=%s AND status='occupied'",(order["gun_id"],))
            return {"order_id":order_id,"review_required":True}
        segments=priced
        electricity=sum((s[6] for s in segments),Decimal("0"))
        service=sum((s[7] for s in segments),Decimal("0"))
        topup=max(money(0),money(order["minimum_amount_snapshot"]-electricity-service))
        payable=money(electricity+service+topup)
        coupon_id=(body or {}).get("coupon_id")
        if coupon_id is not None and order["order_mode"]!="personal": fail(409,"车队订单不可使用个人优惠券")
        discount=money(0)
        if coupon_id is not None:
            coupon=one(cur,"SELECT * FROM user_coupon WHERE coupon_id=%s",(coupon_id,),True)
            if coupon["user_id"]!=order["user_id"] or coupon["status"]!="available" or coupon["expires_at"]<=finished:
                fail(409,"优惠券不可用")
            eligible=money(electricity+service)
            if eligible<coupon["minimum_spend_snapshot"]: fail(409,"未达到优惠券门槛")
            discount=min(eligible,coupon["face_amount_snapshot"])
            cur.execute("INSERT INTO coupon_usage(coupon_id,order_id,original_amount,discount_amount,locked_at,lock_expires_at,status) VALUES (%s,%s,%s,%s,%s,%s,'locked')",(coupon_id,order_id,eligible,discount,finished,finished+timedelta(hours=2)))
            cur.execute("UPDATE user_coupon SET status='locked' WHERE coupon_id=%s",(coupon_id,))
            payable=money(payable-discount)
        for period,a,b,segment_energy,electricity_rate,service_rate,electricity_part,service_part,price in segments:
            cur.execute("INSERT INTO billing_detail(order_id,period_id,price_id,segment_start_at,segment_end_at,energy_kwh,electricity_rate,service_rate,electricity_amount,service_amount,price_source) VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)",(order_id,period["period_id"],price["price_id"] if price else None,a,b,segment_energy,electricity_rate,service_rate,electricity_part,service_part,"fleet" if price else "ordinary"))
        quota_ok=True
        if order["order_mode"]=="fleet":
            authorization=one(cur,"SELECT * FROM fleet_authorization WHERE authorization_id=%s",(order["authorization_id"],),True)
            try: quota_ok=settle_fleet_quota(cur,authorization=authorization,order_id=order_id,amount=payable,at=finished)
            except FleetQuotaError as exc: fail(409,str(exc))
        cur.execute("UPDATE charging_order SET status=%s,finished_at=%s,energy_kwh=%s,electricity_amount=%s,service_amount=%s,minimum_topup_amount=%s,discount_amount=%s,payable_amount=%s,payment_due_at=%s,review_required=%s,review_reason=%s WHERE order_id=%s",("paid" if payable==0 and quota_ok else "awaiting_payment",finished,energy,electricity,service,topup,discount,payable,finished+timedelta(hours=2) if order["order_mode"]=="personal" else None,0 if quota_ok else 1,None if quota_ok else "车队额度不足，等待人工处理",order_id))
        if payable==0 and coupon_id is not None:
            cur.execute("UPDATE coupon_usage SET status='redeemed',redeemed_at=%s WHERE order_id=%s AND status='locked'",(finished,order_id))
            cur.execute("UPDATE user_coupon SET status='redeemed' WHERE coupon_id=%s",(coupon_id,))
        gun=one(cur,"SELECT * FROM charging_gun WHERE gun_id=%s",(order["gun_id"],),True)
        if gun["status"]=="occupied": cur.execute("UPDATE charging_gun SET status='idle' WHERE gun_id=%s",(order["gun_id"],))
        return output({"order_id":order_id,"payable_amount":payable,"review_required":not quota_ok})


@app.post("/api/v1/billing/orders/{order_id}/cancel")
@idempotent("cancel_order")
def cancel_order(order_id:int):
    with transaction() as cur:
        order=one(cur,"SELECT * FROM charging_order WHERE order_id=%s",(order_id,),True)
        if order["status"]!="charging": fail(409,"只可取消充电中订单")
        queue_stop_command(cur,order)
        cur.execute("UPDATE charging_order SET status='cancelled',finished_at=%s WHERE order_id=%s",(now(),order_id))
        if order["order_mode"]=="fleet":
            try: release_fleet_quota(cur,order_id=order_id,at=now())
            except FleetQuotaError as exc: fail(409,str(exc))
        cur.execute("UPDATE charging_gun SET status='idle' WHERE gun_id=%s AND status='occupied'",(order["gun_id"],))
        return {"order_id":order_id,"status":"cancelled"}


def queue_stop_command(cur,order):
    cur.execute("INSERT IGNORE INTO device_command(pile_id,gun_id,order_id,command_type) "
                "SELECT g.pile_id,g.gun_id,%s,'stop' FROM charging_gun g WHERE g.gun_id=%s",
                (order["order_id"],order["gun_id"]))


@app.post("/api/v1/billing/orders/{order_id}/payments",status_code=201)
@idempotent("create_payment")
def create_payment(order_id:int,body:dict):
    require_body_fields(body,("amount","external_trade_no","channel"))
    amount=request_money(body.get("amount",0),"支付金额"); trade=body.get("external_trade_no")
    if amount<=0 or not trade: fail(422,"支付金额和流水号必填")
    channel=body.get("channel","mock")
    if channel not in ("mock","wallet"): fail(422,"个人订单仅支持模拟或钱包支付")
    with transaction() as cur:
        cur.execute("SELECT * FROM payment_record WHERE channel=%s AND external_trade_no=%s",(channel,trade))
        old=cur.fetchone()
        if old:
            if old["order_id"]!=order_id or old["amount"]!=amount: fail(409,"流水号冲突")
            return {"payment_id":old["payment_id"],"status":old["status"]}
        order=one(cur,"SELECT * FROM charging_order WHERE order_id=%s",(order_id,),True)
        if order["status"]!="awaiting_payment" or order["review_required"]: fail(409,"订单暂不可支付")
        if order["order_mode"]!="personal": fail(409,"车队订单只能通过月结收款")
        cur.execute("SELECT COALESCE(SUM(amount),0) AS paid FROM payment_record WHERE order_id=%s AND status='succeeded'",(order_id,))
        paid=cur.fetchone()["paid"]
        if order["payment_due_at"] and order["payment_due_at"]<now() and paid==0:
            fail(409,"付款期限已过")
        if amount>order["payable_amount"]-paid: fail(409,"支付金额超过待付额")
        user=None
        if channel=="wallet":
            user=one(cur,"SELECT * FROM app_user WHERE user_id=%s",(order["user_id"],),True)
            if user["balance"]<amount: fail(409,"钱包余额不足")
            cur.execute("UPDATE app_user SET balance=balance-%s WHERE user_id=%s",(amount,order["user_id"]))
        cur.execute("INSERT INTO payment_record(order_id,channel,external_trade_no,amount,status,paid_at) VALUES (%s,%s,%s,%s,'succeeded',%s)",(order_id,channel,trade,amount,now()))
        payment_id=cur.lastrowid
        if user:
            cur.execute("INSERT INTO wallet_transaction(user_id,payment_id,transaction_type,amount,balance_after,business_key,occurred_at) VALUES (%s,%s,'payment',%s,%s,%s,%s)",
                        (user["user_id"],payment_id,-amount,user["balance"]-amount,f"billing-payment:{payment_id}",now()))
        if paid+amount==order["payable_amount"]:
            cur.execute("UPDATE charging_order SET status='paid' WHERE order_id=%s",(order_id,))
            cur.execute("SELECT coupon_id FROM coupon_usage WHERE order_id=%s AND status='locked' FOR UPDATE",(order_id,))
            coupon=cur.fetchone()
            if coupon:
                cur.execute("UPDATE coupon_usage SET status='redeemed',redeemed_at=%s WHERE order_id=%s AND status='locked'",(now(),order_id))
                cur.execute("UPDATE user_coupon SET status='redeemed' WHERE coupon_id=%s",(coupon["coupon_id"],))
        return {"payment_id":payment_id,"status":"succeeded"}


@app.get("/api/v1/billing/orders/{order_id}/payments")
def list_order_payments(order_id:int,page:int=Query(1,ge=1),page_size:int=Query(20,ge=1,le=100)):
    return page_rows("payment_record",where="order_id=%s",args=(order_id,),page=page,page_size=page_size,order_col="payment_id")


@app.post("/api/v1/billing/orders/{order_id}/refunds",status_code=201)
@idempotent("create_refund")
def create_refund(order_id:int,body:dict,x_actor_id:int=Header(...)):
    require_body_fields(body,("payment_id","amount","external_refund_no","reason"))
    amount=request_money(body.get("amount",0),"退款金额"); external=body.get("external_refund_no")
    if amount<=0 or not external: fail(422,"退款金额和流水号必填")
    with transaction() as cur:
        cur.execute("SELECT * FROM refund_record WHERE external_refund_no=%s",(external,))
        old=cur.fetchone()
        if old:
            cur.execute("SELECT order_id FROM payment_record WHERE payment_id=%s",(old["payment_id"],))
            if cur.fetchone()["order_id"]!=order_id or old["amount"]!=amount: fail(409,"退款流水号冲突")
            return {"refund_id":old["refund_id"],"status":old["status"]}
        payment=one(cur,"SELECT * FROM payment_record WHERE payment_id=%s AND order_id=%s AND status='succeeded'",(body.get("payment_id"),order_id),True)
        cur.execute("SELECT COALESCE(SUM(amount),0) AS refunded FROM refund_record WHERE payment_id=%s AND status='succeeded'",(payment["payment_id"],))
        if amount>payment["amount"]-cur.fetchone()["refunded"]: fail(409,"累计退款超过支付额")
        settlement_method="fleet_credit" if payment["channel"]=="fleet_monthly" else "original"
        cur.execute("INSERT INTO refund_record(payment_id,external_refund_no,amount,status,refunded_at,reason,requested_by,settlement_method) VALUES (%s,%s,%s,'succeeded',%s,%s,%s,%s)",(payment["payment_id"],external,amount,now(),body.get("reason") or "用户申请",x_actor_id,settlement_method))
        refund_id=cur.lastrowid
        if payment["channel"]=="wallet":
            order=one(cur,"SELECT user_id FROM charging_order WHERE order_id=%s",(order_id,))
            user=one(cur,"SELECT user_id,balance FROM app_user WHERE user_id=%s",(order["user_id"],),True)
            cur.execute("UPDATE app_user SET balance=balance+%s WHERE user_id=%s",(amount,user["user_id"]))
            cur.execute("INSERT INTO wallet_transaction(user_id,refund_id,transaction_type,amount,balance_after,business_key,occurred_at) VALUES (%s,%s,'refund',%s,%s,%s,%s)",
                        (user["user_id"],refund_id,amount,user["balance"]+amount,f"billing-refund:{refund_id}",now()))
        if payment["channel"]=="fleet_monthly":
            try: refund_fleet_quota(cur,order_id=order_id,refund_id=refund_id,amount=amount)
            except FleetQuotaError as exc: fail(409,str(exc))
        cur.execute("SELECT COALESCE(SUM(p.amount),0) AS paid FROM payment_record p WHERE p.order_id=%s AND p.status='succeeded'",(order_id,))
        paid_total=cur.fetchone()["paid"]
        cur.execute("SELECT COALESCE(SUM(r.amount),0) AS refunded FROM refund_record r JOIN payment_record p ON p.payment_id=r.payment_id WHERE p.order_id=%s AND r.status='succeeded'",(order_id,))
        refunded_total=cur.fetchone()["refunded"]
        if paid_total>0 and refunded_total==paid_total:
            cur.execute("SELECT cu.coupon_id,uc.promotion_id,uc.user_id,uc.expires_at,uc.face_amount_snapshot,uc.minimum_spend_snapshot FROM coupon_usage cu JOIN user_coupon uc ON uc.coupon_id=cu.coupon_id WHERE cu.order_id=%s AND cu.status='redeemed' FOR UPDATE",(order_id,))
            coupon=cur.fetchone()
            if coupon and coupon["expires_at"]>now():
                cur.execute("SELECT coupon_id FROM user_coupon WHERE reissue_source_order_id=%s",(order_id,))
                if not cur.fetchone():
                    cur.execute("INSERT INTO user_coupon(promotion_id,user_id,received_at,expires_at,face_amount_snapshot,minimum_spend_snapshot,status,reissue_source_order_id) VALUES (%s,%s,%s,%s,%s,%s,'available',%s)",(coupon["promotion_id"],coupon["user_id"],now(),coupon["expires_at"],coupon["face_amount_snapshot"],coupon["minimum_spend_snapshot"],order_id))
        return {"refund_id":refund_id,"status":"succeeded"}


@app.get("/api/v1/billing/refunds")
def list_refunds(page:int=Query(1,ge=1),page_size:int=Query(20,ge=1,le=100),keyword:str|None=None,
                 order_id:int|None=None,status:str|None=None,start_at:datetime|None=None,end_at:datetime|None=None):
    require_interval(start_at,end_at)
    actor=current_actor.get()
    if "platform_admin" in actor["roles"]: where="1=1";args=()
    elif "customer_service" in actor["roles"]:
        where="payment_id IN (SELECT p.payment_id FROM payment_record p JOIN charging_order o ON o.order_id=p.order_id JOIN sys_account_station ast ON ast.station_id=o.station_id WHERE ast.account_id=%s)"
        args=(actor["id"],)
    elif "fleet_admin" in actor["roles"]:
        where="payment_id IN (SELECT p.payment_id FROM payment_record p JOIN charging_order o ON o.order_id=p.order_id JOIN sys_account_fleet af ON af.fleet_id=o.fleet_id WHERE af.account_id=%s)"
        args=(actor["id"],)
    elif "operator_manager" in actor["roles"]:
        where="payment_id IN (SELECT p.payment_id FROM payment_record p JOIN charging_order o ON o.order_id=p.order_id JOIN sys_account_operator ao ON ao.operator_id=o.operator_id WHERE ao.account_id=%s)"
        args=(actor["id"],)
    else:
        where="payment_id IN (SELECT p.payment_id FROM payment_record p JOIN charging_order o ON o.order_id=p.order_id JOIN app_user u ON u.user_id=o.user_id WHERE u.account_id=%s)"
        args=(actor["id"],)
    where,args=query_where((where,args),keyword=keyword,status=status,start_at=start_at,end_at=end_at,
                           time_col="refunded_at",keyword_col="external_refund_no",
                           extra={"payment_id":None})
    if order_id is not None:
        where+=" AND payment_id IN (SELECT payment_id FROM payment_record WHERE order_id=%s)"
        args+= (order_id,)
    return page_rows("refund_record",where=where,args=args,page=page,page_size=page_size,order_col="refund_id")


@app.get("/api/v1/billing/refunds/{refund_id}")
def get_refund(refund_id:int):
    actor=current_actor.get()
    with transaction() as cur:
        refund=one(cur,"SELECT r.*,o.user_id,o.fleet_id,o.station_id FROM refund_record r JOIN payment_record p ON p.payment_id=r.payment_id JOIN charging_order o ON o.order_id=p.order_id WHERE r.refund_id=%s",(refund_id,))
        if "platform_admin" not in actor["roles"]:
            if "customer_service" in actor["roles"]:
                cur.execute("SELECT 1 FROM sys_account_station WHERE account_id=%s AND station_id=%s",(actor["id"],refund["station_id"]))
            elif "fleet_admin" in actor["roles"]:
                cur.execute("SELECT 1 FROM sys_account_fleet WHERE account_id=%s AND fleet_id=%s",(actor["id"],refund["fleet_id"]))
            elif "operator_manager" in actor["roles"]:
                cur.execute("SELECT 1 FROM station s JOIN sys_account_operator ao ON ao.operator_id=s.operator_id WHERE ao.account_id=%s AND s.station_id=%s",(actor["id"],refund["station_id"]))
            else:
                cur.execute("SELECT 1 FROM app_user WHERE account_id=%s AND user_id=%s",(actor["id"],refund["user_id"]))
            if not cur.fetchone(): fail(403,"无该退款的数据权限")
        return output({k:v for k,v in refund.items() if k not in ("user_id","fleet_id","station_id")})


@app.post("/api/v1/billing/orders/{order_id}/reviews",status_code=201)
@idempotent("review_order")
def review_order(order_id:int,body:dict,x_actor_id:int=Header(...)):
    require_body_fields(body,("decision","review_type","note","evidence"))
    decision=body.get("decision")
    if decision not in ("approved","rejected"): fail(422,"复核决定无效")
    with transaction() as cur:
        order=one(cur,"SELECT * FROM charging_order WHERE order_id=%s",(order_id,),True)
        if not order["review_required"]: fail(409,"订单无待复核事项")
        if decision=="approved":
            cur.execute("SELECT COUNT(*) AS n FROM billing_detail WHERE order_id=%s",(order_id,))
            if not cur.fetchone()["n"]:
                fail(409,"尚无可核实的最终计费明细，不能批准收款")
            if order["order_mode"]=="fleet" and order["review_reason"]=="车队额度不足，等待人工处理":
                authorization=one(cur,"SELECT * FROM fleet_authorization WHERE authorization_id=%s",(order["authorization_id"],),True)
                try: settled=settle_fleet_quota(cur,authorization=authorization,order_id=order_id,amount=order["payable_amount"],at=order["finished_at"])
                except FleetQuotaError as exc: fail(409,str(exc))
                if not settled: fail(409,"车队额度仍不足，不能批准")
        cur.execute("INSERT INTO order_review(order_id,review_type,decision,evidence,note,reviewed_by,reviewed_at) VALUES (%s,%s,%s,%s,%s,%s,%s)",(order_id,body.get("review_type","meter"),decision,json.dumps(body.get("evidence",{})),body.get("note","人工复核"),x_actor_id,now()))
        review_id=cur.lastrowid
        if decision=="approved": cur.execute("UPDATE charging_order SET review_required=0,review_reason=NULL WHERE order_id=%s",(order_id,))
        elif decision=="rejected":
            cur.execute("SELECT COUNT(*) AS n FROM billing_detail WHERE order_id=%s",(order_id,))
            if cur.fetchone()["n"]==0:
                cur.execute("UPDATE charging_order SET status='cancelled',review_required=0,review_reason='复核驳回：缺少可核实计费明细' WHERE order_id=%s",(order_id,))
                if order["order_mode"]=="fleet":
                    try: release_fleet_quota(cur,order_id=order_id,at=now())
                    except FleetQuotaError as exc: fail(409,str(exc))
        return {"review_id":review_id,"decision":decision}


def expire_unpaid_orders(cur, at=None):
    """Release only unpaid, unreviewed orders and their coupon locks."""
    at=at or now()
    cur.execute("SELECT order_id FROM charging_order WHERE status='awaiting_payment' AND review_required=0 AND payment_due_at IS NOT NULL AND payment_due_at<%s ORDER BY order_id FOR UPDATE",(at,))
    ids=[row["order_id"] for row in cur.fetchall()]
    expired=[]
    for order_id in ids:
        cur.execute("SELECT COUNT(*) AS n FROM payment_record WHERE order_id=%s AND status='succeeded'",(order_id,))
        if cur.fetchone()["n"]: continue
        cur.execute("SELECT coupon_id FROM coupon_usage WHERE order_id=%s AND status='locked' FOR UPDATE",(order_id,))
        usage=cur.fetchone()
        if usage:
            cur.execute("UPDATE coupon_usage SET status='released',released_at=%s WHERE order_id=%s AND status='locked'",(at,order_id))
            cur.execute("UPDATE user_coupon SET status=CASE WHEN expires_at>%s THEN 'available' ELSE 'expired' END WHERE coupon_id=%s",(at,usage["coupon_id"]))
        cur.execute("UPDATE charging_order SET status='cancelled' WHERE order_id=%s",(order_id,))
        expired.append(order_id)
    return expired
