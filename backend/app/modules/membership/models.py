"""Membership model registry.

The physical column definitions live in database/modules/membership/01_tables.sql.
The application reflects the pre-created schema instead of calling create_all,
so cross-module foreign keys remain owned by the full project loader.
"""

from __future__ import annotations

from functools import lru_cache

from sqlalchemy import MetaData
from sqlalchemy.engine import Engine

TABLE_NAMES = frozenset(
    {
        "sys_account", "app_user", "vehicle", "vehicle_binding", "promotion",
        "user_coupon", "coupon_usage", "fleet", "fleet_card", "fleet_authorization",
        "fleet_quota_month", "fleet_quota_reservation", "sys_role", "sys_permission",
        "sys_account_role", "sys_role_permission", "sys_account_operator",
        "sys_account_station", "sys_account_fleet", "promotion_station", "sys_session",
        "wallet_transaction", "fleet_quota_adjustment", "service_feedback",
    }
)


@lru_cache(maxsize=4)
def reflected_membership_metadata(engine: Engine) -> MetaData:
    metadata = MetaData()
    metadata.reflect(bind=engine, only=sorted(TABLE_NAMES), resolve_fks=False)
    return metadata


def table(engine: Engine, table_name: str):
    if table_name not in TABLE_NAMES:
        raise ValueError(f"unregistered membership table: {table_name}")
    metadata = reflected_membership_metadata(engine)
    return metadata.tables[table_name]
