from contextlib import asynccontextmanager
from fastapi import FastAPI
from app.core.database import engine
from app.modules.assets.router import router as assets_router
from app.modules.membership.router import router as membership_router
from app.core.errors import install_error_handlers

@asynccontextmanager
async def lifespan(app: FastAPI):
    yield
    engine.dispose()

app = FastAPI(title="新能源汽车充电平台", version="0.1.0", lifespan=lifespan)
install_error_handlers(app)
app.include_router(membership_router, prefix="/api/v1")
app.include_router(assets_router, prefix="/api/v1/assets", tags=["场站与设施"])

@app.get("/health", tags=["运行检查"])
def health():
    return {"status": "ok"}
