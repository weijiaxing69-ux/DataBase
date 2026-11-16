import os
from pathlib import Path

from dotenv import load_dotenv
from fastapi import Request
from sqlalchemy import create_engine, text
from sqlalchemy.orm import Session

load_dotenv(Path(__file__).resolve().parents[2] / ".env")


def configure_database(url=None):
    return create_engine(
        url or os.environ["DATABASE_URL"],
        pool_pre_ping=True,
        isolation_level="READ COMMITTED",
        connect_args={"init_command": "SET time_zone = '+00:00'"},
    )


def get_db(request: Request):
    with Session(request.app.state.engine) as db:
        yield db


def all_rows(db, sql, **params):
    return [dict(row) for row in db.execute(text(sql), params).mappings()]


def one(db, sql, **params):
    row = db.execute(text(sql), params).mappings().one_or_none()
    return dict(row) if row is not None else None


def execute(db, sql, **params):
    return db.execute(text(sql), params)
