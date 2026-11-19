#!/usr/bin/env python3
"""一键重建演示库。

按固定顺序执行 bootstrap 与各模块脚本，用于答辩前重置数据：
    00 建表 → 04 种子 → 维护模块 02~05 → 迁移 16/17/18/20 →（可选）应急 10/11/12/19/21/22

用法：
    python scripts/rebuild_demo_db.py                # 交互确认后重建
    python scripts/rebuild_demo_db.py --yes          # 无人值守
    python scripts/rebuild_demo_db.py --with-emergency
    python scripts/rebuild_demo_db.py --db other_db --user root --password 123456

依赖：本机 MySQL 客户端（mysql 命令），不在 PATH 时用 --mysql-bin 指定。
"""

from __future__ import annotations

import argparse
import glob
import os
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DB_DIR = ROOT / "database"

BOOTSTRAP = ["bootstrap/00_测试库建表.sql", "bootstrap/04_seed_V1.4.sql"]
MODULE_SQL = [
    "modules/maintenance/02_views.sql",
    "modules/maintenance/03_procedures.sql",
    "modules/maintenance/04_triggers.sql",
    "modules/maintenance/05_seed_scenarios.sql",
]
MIGRATIONS = [
    "migrations/16_indexes.sql",
    "migrations/17_security_hardening.sql",
    "migrations/18_charging_anomaly_rule.sql",
    "migrations/20_temperature_metering_rules.sql",
    "migrations/23_station_overload_rule.sql",
    "migrations/24_voltage_duration_rules.sql",
]
EMERGENCY = [
    "migrations/10_emergency_tables.sql",
    "migrations/11_emergency_objects.sql",
    "migrations/12_emergency_seed.sql",
    "migrations/19_part_stock_movement.sql",
    "migrations/21_emergency_seed_extended.sql",
    "migrations/22_emergency_extended_checks.sql",
]


def find_mysql(explicit: str | None) -> str:
    if explicit:
        return explicit
    found = glob.glob(r"C:\Program Files\MySQL\**\bin\mysql.exe", recursive=True)
    candidates = found + glob.glob(r"C:\Users\*\AppData\Local\Programs\MySQL\**\bin\mysql.exe", recursive=True)
    for path in candidates:
        if os.path.exists(path):
            return path
    return "mysql"


def run(mysql: str, args: dict, sql_file: Path | None = None, statement: str | None = None,
        use_db: bool = True) -> None:
    cmd = [mysql, f"--host={args['host']}", f"--port={args['port']}", f"--user={args['user']}",
           "--default-character-set=utf8mb4", "--protocol=TCP"]
    if args["password"] is not None:
        cmd.append(f"--password={args['password']}")
    if statement is not None:
        cmd += ["-e", statement]
        subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL)
        return
    if use_db:
        cmd.append(args["db"])
    with open(sql_file, "rb") as handle:
        subprocess.run(cmd, stdin=handle, check=True)


def scalar(mysql: str, args: dict, sql: str) -> str:
    cmd = [mysql, f"--host={args['host']}", f"--port={args['port']}", f"--user={args['user']}",
           "--protocol=TCP", "-N", "-B", args["db"], "-e", sql]
    if args["password"] is not None:
        cmd.append(f"--password={args['password']}")
    result = subprocess.run(cmd, check=True, capture_output=True, text=True)
    return result.stdout.strip()


def main() -> int:
    parser = argparse.ArgumentParser(description="重建充电平台演示库")
    parser.add_argument("--host", default=os.getenv("MYSQL_HOST", "127.0.0.1"))
    parser.add_argument("--port", default=os.getenv("MYSQL_PORT", "3306"))
    parser.add_argument("--user", default=os.getenv("MYSQL_USER", "root"))
    parser.add_argument("--password", default=os.getenv("MYSQL_PASSWORD", ""))
    parser.add_argument("--db", default=os.getenv("MYSQL_DB", "charging_platform_test"))
    parser.add_argument("--mysql-bin", default=None, help="mysql 可执行文件路径")
    parser.add_argument("--with-emergency", action="store_true", help="同时导入 V1.5 应急增强")
    parser.add_argument("--yes", action="store_true", help="跳过确认")
    args = vars(parser.parse_args())

    mysql = find_mysql(args["mysql_bin"])
    print(f"客户端: {mysql}")
    print(f"目标库: {args['db']} @ {args['host']}:{args['port']}")

    if not args["yes"]:
        answer = input(f"这会删除并重建 {args['db']}，输入 YES 继续: ").strip()
        if answer != "YES":
            print("已取消")
            return 1

    try:
        print("[1/4] 删除旧库 …")
        run(mysql, args, statement=f"drop database if exists `{args['db']}`")

        files = BOOTSTRAP + MODULE_SQL + MIGRATIONS + (EMERGENCY if args["with_emergency"] else [])
        print(f"[2/4] 执行 {len(files)} 个脚本 …")
        for index, relative in enumerate(files, start=1):
            path = DB_DIR / relative
            if not path.exists():
                print(f"  缺少脚本: {relative}", file=sys.stderr)
                return 2
            print(f"  {index:>2}. {relative}")
            run(mysql, args, sql_file=path, use_db=index > 1)

        print("[3/4] 校验对象数量 …")
        counts = {
            "表": scalar(mysql, args, "select count(*) from information_schema.tables where table_schema=database()"),
            "视图": scalar(mysql, args, "select count(*) from information_schema.views where table_schema=database()"),
            "过程": scalar(mysql, args, "select count(*) from information_schema.routines where routine_schema=database()"),
            "触发器": scalar(mysql, args, "select count(*) from information_schema.triggers where trigger_schema=database()"),
            "账号": scalar(mysql, args, "select count(*) from sys_account"),
            "桩": scalar(mysql, args, "select count(*) from charging_pile"),
            "告警": scalar(mysql, args, "select count(*) from device_alert"),
        }
        for name, value in counts.items():
            print(f"  {name}: {value}")

        print("[4/4] 完成。下一步：")
        print("  cd backend && python -m pytest tests -q")
        return 0
    except subprocess.CalledProcessError as exc:
        print(f"执行失败（退出码 {exc.returncode}），请检查上方 MySQL 报错", file=sys.stderr)
        return exc.returncode or 1


if __name__ == "__main__":
    raise SystemExit(main())
