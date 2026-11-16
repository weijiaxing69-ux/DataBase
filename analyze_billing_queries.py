"""Compare the six course-design SQL variants against the live development DB."""
from pathlib import Path
from time import perf_counter
import json
import statistics

from db_connection import connect
from test_billing_sql import queries

OUT = Path(__file__).resolve().parent / "database" / "modules" / "billing" / "查询实现对比.md"


def access_paths(node):
    found = []
    if isinstance(node, dict):
        if "table_name" in node:
            found.append(f"{node['table_name']}:{node.get('access_type', '?')}:{node.get('key') or '无索引'}")
        for value in node.values():
            found.extend(access_paths(value))
    elif isinstance(node, list):
        for value in node:
            found.extend(access_paths(value))
    return found


def main():
    descriptions = {
        "1": "按场站与峰平谷时段汇总电量、电费和服务费。A直接关联三表分组；B使用按日汇总视图二次聚合。",
        "2": "逐单核对成功支付、退款和待付金额。A对流水预聚合后关联；B使用相关子查询。",
        "3": "列出已启用计费规则的时段数量与最低电价。A三表直接分组；B先汇总时段再关联。",
    }
    lines = ["# 订单计费 SQL 双实现与执行计划", "", "数据源：本机 `charging_platform` 演示库。每个语句执行 10 次，记录中位耗时。数据规模很小，耗时仅供展示执行计划，不作为生产环境性能结论。", ""]
    db = connect()
    with db.cursor() as cur:
        for pair, description in descriptions.items():
            lines += [f"## 查询 {pair}", "", description, "", "| 写法 | 返回行数 | 中位耗时 | 执行计划访问路径 |", "| --- | ---: | ---: | --- |"]
            for variant in ("A", "B"):
                sql = queries()[pair + variant]
                durations = []
                for _ in range(10):
                    start = perf_counter()
                    cur.execute(sql)
                    result = cur.fetchall()
                    durations.append((perf_counter() - start) * 1000)
                cur.execute("EXPLAIN FORMAT=JSON " + sql)
                plan = json.loads(cur.fetchone()["EXPLAIN"])
                paths = ", ".join(access_paths(plan)) or "见 JSON 执行计划"
                lines.append(f"| {variant} | {len(result)} | {statistics.median(durations):.3f} ms | {paths} |")
            lines += ["", "两种写法的返回结果由 `test_billing_sql.py` 逐行比较；索引选择需在扩大数据量后重新验证。", ""]
    db.close()
    OUT.write_text("\n".join(lines), encoding="utf-8")
    print(OUT)


if __name__ == "__main__":
    main()
