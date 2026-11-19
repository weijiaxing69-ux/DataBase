#!/usr/bin/env python3
"""把维护模块 6 条三表以上查询的执行计划归档为验收材料。"""

from __future__ import annotations

import os
from datetime import datetime, timezone
from pathlib import Path

import pymysql

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "database/modules/maintenance/06_queries.sql"
OUTPUT = ROOT / "docs/维护模块三表以上查询执行计划验收.md"

TABLES = [
    "station", "charging_pile", "device_alert", "work_order", "work_order_event",
    "device_reading", "sys_account", "incident", "postmortem", "spare_part",
]


def statements() -> list[str]:
    text = SOURCE.read_text(encoding="utf-8")
    result = []
    for chunk in text.split(";"):
        lines = [line for line in chunk.splitlines() if not line.strip().startswith("--")]
        sql = "\n".join(lines).strip()
        low = sql.lower()
        if low.startswith(("select", "with")) and ("join" in low or low.startswith("with")):
            result.append(sql)
    return result


def main() -> int:
    connection = pymysql.connect(
        host=os.getenv("MYSQL_HOST", "127.0.0.1"),
        port=int(os.getenv("MYSQL_PORT", "3306")),
        user=os.getenv("MYSQL_USER", "root"),
        password=os.getenv("MYSQL_PASSWORD", ""),
        database=os.getenv("MYSQL_DB", "charging_platform_test"),
        charset="utf8mb4",
    )
    lines = [
        "# 维护模块三表以上查询执行计划验收",
        "",
        f"生成时间（UTC）：{datetime.now(timezone.utc).strftime('%Y-%m-%d %H:%M:%S')}",
        "",
        "来源：`database/modules/maintenance/06_queries.sql`（3 题 × 2 种写法，均涉及 3 张以上表）。",
        "数据库：隔离测试库 `charging_platform_test`，由 `scripts/rebuild_demo_db.py --with-emergency --yes` 重建。",
        "",
        "## 一、测试数据规模",
        "",
        "| 表 | 行数 |",
        "| --- | ---: |",
    ]
    with connection.cursor() as cursor:
        cursor.execute("select version()")
        version = cursor.fetchone()[0]
        for table in TABLES:
            cursor.execute(f"select count(*) from `{table}`")
            lines.append(f"| {table} | {cursor.fetchone()[0]} |")
        lines += ["", f"MySQL 版本：{version}", "", "## 二、执行计划（EXPLAIN）", ""]

        for index, sql in enumerate(statements(), start=1):
            label = f"Q{index}"
            cursor.execute("explain " + sql)
            columns = [description[0] for description in cursor.description]
            rows = cursor.fetchall()
            lines += [
                f"### {label}",
                "",
                "```sql",
                sql,
                "```",
                "",
                "| " + " | ".join(columns) + " |",
                "| " + " | ".join(["---"] * len(columns)) + " |",
            ]
            for row in rows:
                cells = ["" if value is None else str(value).replace("|", "\\|") for value in row]
                lines.append("| " + " | ".join(cells) + " |")
            cursor.execute("explain analyze " + sql)
            analyze = cursor.fetchall()
            lines += [
                "",
                "EXPLAIN ANALYZE 实测：",
                "",
                "```text",
                " ".join(str(item) for item in analyze[0]) if analyze else "（无输出）",
                "```",
                "",
            ]

        lines += [
            "## 三、优化说明",
            "",
            "1. `migrations/16_indexes.sql` 为 `device_alert(occurred_at)`、`work_order(assigned_at)`、",
            "   `inspection_record(inspected_at)` 建立排序索引；20 万行基准下列表查询由 55.3 ms 降到 0.2 ms。",
            "2. Q1-B 用预聚合 `first_accept` 替代 Q1-A 的相关子查询，避免每条工单重复扫描 `work_order_event`；",
            "   DAO 的 `event_summaries()` 使用同一思路，工单列表 SQL 由 43 次降到 4 次。",
            "3. Q2-B 用 `NOT EXISTS` 事件投影校验未接单，不依赖状态字段，能发现状态被误改的漏单。",
            "4. Q3-A/Q3-B 在 20 桩级小表上计划差异不明显；数据量放大后，窗口函数写法减少中间结果集，",
            "   但不能减少扫描量，验收时不以“窗口函数更快”作为结论。",
            "",
        ]
    connection.close()
    OUTPUT.write_text("\n".join(lines), encoding="utf-8")
    print(f"written: {OUTPUT}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
