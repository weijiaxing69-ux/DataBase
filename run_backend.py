"""PyCharm one-click launcher for the local billing API."""

import uvicorn
import subprocess
import time

from db_connection import connect


def ensure_mysql_running():
    status = subprocess.run(
        ["docker", "inspect", "--format", "{{.State.Running}}", "mysql8"],
        capture_output=True, text=True,
    )
    if status.returncode:
        raise RuntimeError("无法连接 Docker。请先启动 Docker Desktop，并确认 mysql8 容器存在。")
    if status.stdout.strip() != "true":
        subprocess.run(["docker", "start", "mysql8"], check=True)
    for _ in range(20):
        try:
            connection = connect()
            connection.close()
            return
        except Exception:
            time.sleep(1)
    raise RuntimeError("MySQL 已启动，但 charging_platform 数据库尚未就绪。")


if __name__ == "__main__":
    ensure_mysql_running()
    uvicorn.run("backend:app", host="127.0.0.1", port=8000, reload=True)
