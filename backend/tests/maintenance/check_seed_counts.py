"""校验应急场景表的样例规模，低于任务书要求时返回非 0。"""

from __future__ import annotations

import os
import sys

import pymysql

MIN_ROWS = {
    "incident": 20,
    "incident_alert": 20,
    "incident_action": 20,
    "on_call_shift": 20,
    "escalation_policy": 20,
    "incident_escalation": 20,
    "postmortem": 20,
    "action_item": 20,
    "spare_part": 20,
    "part_usage": 20,
    "part_stock_movement": 20,
}


def main() -> int:
    connection = pymysql.connect(
        host=os.getenv("MYSQL_HOST", "127.0.0.1"),
        port=int(os.getenv("MYSQL_PORT", "3306")),
        user=os.getenv("MYSQL_USER", "root"),
        password=os.getenv("MYSQL_PASSWORD", ""),
        database=os.getenv("MYSQL_DB", "charging_platform_test"),
        charset="utf8mb4",
    )
    failed = False
    try:
        with connection.cursor() as cursor:
            for table, minimum in MIN_ROWS.items():
                cursor.execute(f"select count(*) from `{table}`")
                count = cursor.fetchone()[0]
                mark = "OK" if count >= minimum else "FAIL"
                print(f"{mark:4s} {table:24s} {count:>5d} / >= {minimum}")
                failed |= count < minimum
    finally:
        connection.close()
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
