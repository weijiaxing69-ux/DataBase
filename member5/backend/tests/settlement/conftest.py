"""Shared isolated MySQL fixtures for both pytest and the script-based acceptance."""
from pathlib import Path
from secrets import token_urlsafe
import sys

import pytest

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
from support import Instance, TestClient as ApiClient, create_app, find_bin, install_settlement_sql


@pytest.fixture
def mysql_instance(tmp_path):
    work = tmp_path / "mysql"
    work.mkdir()
    instance = Instance(find_bin(None), work)
    try:
        instance.start()
        install_settlement_sql(instance)
        yield instance
    finally:
        instance.close()


@pytest.fixture
def api_client(mysql_instance, tmp_path):
    frontend = tmp_path / "dist"
    frontend.mkdir()
    (frontend / "index.html").write_text("<main>test</main>", encoding="utf-8")
    app = create_app(f"mysql+pymysql://root@127.0.0.1:{mysql_instance.port}/charging_platform_test?charset=utf8mb4",
                     token_urlsafe(48), frontend)
    with ApiClient(app) as client:
        yield client
