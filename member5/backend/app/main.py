from contextlib import asynccontextmanager
import os
from pathlib import Path
from uuid import uuid4

from fastapi import FastAPI
from fastapi.exceptions import RequestValidationError
from fastapi.responses import FileResponse, JSONResponse
from fastapi.staticfiles import StaticFiles
from pymysql.err import MySQLError
from sqlalchemy.exc import DBAPIError

from .core import auth
from .core.database import configure_database
from .core.errors import BusinessError
from .modules.settlement.router import router

SQL_MESSAGES = {
    "SETTLEMENT_NOT_FOUND": "结算单不存在。",
    "SETTLEMENT_CONFIRMATION_REQUIRED": "当前版本需平台与运营商双方确认后才能开票。",
    "INVOICE_EXCEEDS_SETTLEMENT": "开票净额不能超过应结金额。",
    "RED_INVOICE_INVALID_ORIGINAL": "原票须为同一结算单下已开具的蓝票。",
    "RED_INVOICE_EXCEEDS_ORIGINAL": "红冲金额超过原票剩余可冲额度。",
    "INVALID_INVOICE_AMOUNT": "发票金额须大于零。",
}


def error_response(status, code, message):
    return JSONResponse(status_code=status, content=dict(code=code, message=message, request_id=uuid4().hex))


def create_app(database_url=None, jwt_secret=None, frontend_dir=None):
    @asynccontextmanager
    async def lifespan(app):
        secret = jwt_secret or os.environ["JWT_SECRET"]
        if len(secret.encode()) < 32:
            raise ValueError("JWT_SECRET must be at least 32 bytes")
        app.state.jwt_secret = secret
        app.state.engine = configure_database(database_url)
        try:
            yield
        finally:
            app.state.engine.dispose()

    app = FastAPI(title="充电运营 · 结算对账", lifespan=lifespan)
    app.include_router(auth.router)
    app.include_router(router)

    @app.exception_handler(BusinessError)
    def business_error(_, exc):
        return error_response(exc.status, exc.code, exc.message)

    @app.exception_handler(RequestValidationError)
    def validation_error(_, exc):
        return error_response(422, "INVALID_INPUT", "请检查必填字段、金额精度及请求格式。")

    @app.exception_handler(MySQLError)
    @app.exception_handler(DBAPIError)
    def mysql_error(_, exc):
        args = getattr(getattr(exc, "orig", exc), "args", ())
        number = args[0] if args else None
        code = args[1] if len(args) > 1 else ""
        if number == 1644 and code in SQL_MESSAGES:
            return error_response(404 if code == "SETTLEMENT_NOT_FOUND" else 409, code, SQL_MESSAGES[code])
        if number in {1062, 1205, 1213}:
            return error_response(409, "DATABASE_CONFLICT", "数据发生冲突，请刷新后重试。")
        return error_response(500, "DATABASE_ERROR", "数据库操作失败，请检查服务日志和安装状态。")

    if frontend_dir is not None:
        def settlement_page():
            return FileResponse(Path(frontend_dir) / "index.html")

        for path in ("/settlement/settlements", "/settlement/settlements/{settlement_id:int}",
                     "/settlement/differences", "/settlement/invoices", "/settlement/user-invoices",
                     "/settlement/fleet-bills", "/settlement/fleet-bills/{bill_id:int}",
                     "/settlement/fleet-prices", "/settlement/policies"):
            app.add_api_route(path, settlement_page, include_in_schema=False)
        app.mount("/", StaticFiles(directory=Path(frontend_dir), html=True))
    return app


app = create_app(frontend_dir=os.getenv("FRONTEND_DIST"))
