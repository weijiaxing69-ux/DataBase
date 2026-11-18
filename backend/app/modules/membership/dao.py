from __future__ import annotations

from contextlib import contextmanager
from datetime import UTC, datetime
from typing import Any, Iterator

from sqlalchemy import text
from sqlalchemy.orm import Session


@contextmanager
def transaction(db: Session) -> Iterator[None]:
    """Start a transaction at the API boundary, or join the caller's transaction."""
    if db.in_transaction():
        yield
    else:
        with db.begin():
            yield


def utc_now_naive() -> datetime:
    return datetime.now(UTC).replace(tzinfo=None)


def to_utc_naive(value: datetime) -> datetime:
    """Normalize API datetimes to UTC for MySQL DATETIME columns."""
    if value.tzinfo is None:
        value = value.replace(tzinfo=UTC)
    return value.astimezone(UTC).replace(tzinfo=None)


def one(db: Session, sql: str, params: dict[str, Any] | None = None) -> dict[str, Any] | None:
    row = db.execute(text(sql), params or {}).mappings().first()
    return dict(row) if row is not None else None


def many(db: Session, sql: str, params: dict[str, Any] | None = None) -> list[dict[str, Any]]:
    return [dict(row) for row in db.execute(text(sql), params or {}).mappings().all()]


def run(db: Session, sql: str, params: dict[str, Any] | None = None):
    return db.execute(text(sql), params or {})


def inserted_id(result) -> int:
    value = getattr(result, "lastrowid", None)
    if value is None:
        raise RuntimeError("database driver did not return the inserted identifier")
    return int(value)


def page_params(page: int, page_size: int) -> dict[str, int]:
    return {"limit": page_size, "offset": (page - 1) * page_size}


def page_result(db: Session, *, count_sql: str, rows_sql: str,
                params: dict[str, Any], page: int, page_size: int) -> dict[str, Any]:
    total_row = one(db, count_sql, params) or {"total": 0}
    rows = many(db, rows_sql, {**params, **page_params(page, page_size)})
    return {"items": rows, "total": int(total_row["total"]), "page": page, "page_size": page_size}
