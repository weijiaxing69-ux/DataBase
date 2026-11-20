"""Shared MySQL bootstrap and API helpers, independent of any business test file."""
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[3]
sys.path[:0] = [str(ROOT / "backend"), str(ROOT / "新能源项目最新版_V1.4")]

from fastapi.testclient import TestClient
from app.main import create_app
from test_mysql_v14 import Instance, find_bin


def install_settlement_sql(db):
    folder = ROOT / "database/modules/settlement"
    db.load()
    for name in ("05_views.sql", "06_procedures.sql", "07_triggers.sql", "10_audit.sql"):
        db.query((folder / name).read_text(encoding="utf-8")).check_returncode()
