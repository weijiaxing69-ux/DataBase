from datetime import datetime

from ...core.database import all_rows
from ...core.errors import require
from .catalog import utc


def get_fleet_price(db, *, fleet_id: int, period_id: int, at: datetime) -> dict | None:
    rows = all_rows(db, """SELECT * FROM fleet_price WHERE fleet_id=:fleet AND period_id=:period
        AND status='active' AND valid_from<=:at AND valid_until>:at LIMIT 2""",
        fleet=fleet_id, period=period_id, at=utc(at))
    require(len(rows) <= 1, 409, "FLEET_PRICE_OVERLAP", "计费时点命中多条车队专价。")
    return rows[0] if rows else None
