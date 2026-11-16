from sqlalchemy import text
from app.core.database import engine

if __name__ == "__main__":
    try:
        with engine.connect() as connection:
            print("当前数据库：", connection.scalar(text("select database()")))
            print("表数量：", connection.scalar(text(
                "select count(*) from information_schema.tables "
                "where table_schema=database() and table_type='BASE TABLE'"
            )))
            for table in ("operator", "station", "charging_pile", "charging_gun"):
                # TODO 表名来自固定列表；业务查询参数必须绑定传递。
                count = connection.scalar(text(f"select count(*) from `{table}`"))
                print(f"{table}：{count} 条记录")
    finally:
        engine.dispose()
