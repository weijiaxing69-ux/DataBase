"""统一 HTTP 业务错误；Service 仍可直接抛出 Python 业务异常。"""
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from sqlalchemy.exc import IntegrityError


class BusinessError(ValueError):
    def __init__(self, message: str | int, *args, status_code: int = 400, code: str = "business_error"):
        # Accept the existing shared signature and membership's (status, code, message) form.
        if isinstance(message, int):
            if len(args) != 2:
                raise TypeError("BusinessError(status, code, message) requires three positional arguments")
            status_code, code, message = message, str(args[0]), str(args[1])
        elif args:
            raise TypeError("BusinessError(message) accepts status_code and code as keywords")
        super().__init__(message)
        self.status_code = status_code
        self.code = code


def bad_request(code: str, message: str) -> BusinessError:
    return BusinessError(message, status_code=400, code=code)


def unauthorized(code: str = "unauthorized", message: str = "认证失败") -> BusinessError:
    return BusinessError(message, status_code=401, code=code)


def forbidden(code: str = "forbidden", message: str = "无权执行此操作") -> BusinessError:
    return BusinessError(message, status_code=403, code=code)


def not_found(code: str = "not_found", message: str = "记录不存在") -> BusinessError:
    return BusinessError(message, status_code=404, code=code)


def conflict(code: str, message: str) -> BusinessError:
    return BusinessError(message, status_code=409, code=code)


def install_error_handlers(app: FastAPI) -> None:
    # 映射现有 Service 的异常，不把 SQL、密码或内部堆栈返回给前端。
    async def business(_request: Request, exc: ValueError):
        return JSONResponse(status_code=getattr(exc, "status_code", 400),
                            content={"detail": str(exc), "code": getattr(exc, "code", "business_error")})

    async def forbidden(_request: Request, exc: PermissionError):
        return JSONResponse(status_code=403, content={"detail": str(exc), "code": "forbidden"})

    async def unavailable(_request: Request, exc: NotImplementedError):
        return JSONResponse(status_code=503, content={"detail": str(exc), "code": "integration_unavailable"})

    async def conflict(_request: Request, exc: IntegrityError):
        return JSONResponse(status_code=409, content={"detail": "数据约束冲突，请检查编号或重复记录", "code": "conflict"})

    app.add_exception_handler(ValueError, business)
    app.add_exception_handler(PermissionError, forbidden)
    app.add_exception_handler(NotImplementedError, unavailable)
    app.add_exception_handler(IntegrityError, conflict)
