from sqlalchemy import URL, create_engine, event
from sqlalchemy.orm import DeclarativeBase, sessionmaker
from app.core.config import settings

url = URL.create(
    "mysql+pymysql", username=settings.db_user, password=settings.db_password,
    host=settings.db_host, port=settings.db_port, database=settings.db_name,
    query={"charset": "utf8mb4"},
)
engine = create_engine(url, pool_pre_ping=True, pool_size=5, max_overflow=5)

@event.listens_for(engine, "connect")
def set_connection_timezone(dbapi_connection, connection_record):
    with dbapi_connection.cursor() as cursor:
        cursor.execute("set time_zone = '+00:00'")

SessionLocal = sessionmaker(bind=engine, autoflush=False, expire_on_commit=False)

class Base(DeclarativeBase):
    pass

def get_db():
    # TODO 只负责提供和关闭会话；业务事务由 Service 统一管理。
    with SessionLocal() as db:
        yield db
