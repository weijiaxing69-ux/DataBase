# 整合工作区说明（成员三维护模块）

更新时间：2026-11-20

## 当前分支

- 成员三分支：`member3-v2.0`
- 维护模块目录：`backend/app/modules/maintenance/`
- 前端入口：`frontend/src/views/maintenance/`

## 数据库初始化顺序

在干净测试库上按以下顺序执行，不要跳过迁移：

1. `database/bootstrap/00_测试库建表.sql`
2. `database/bootstrap/04_seed_V1.4.sql`
3. `database/modules/maintenance/02_views.sql`
4. `database/modules/maintenance/03_procedures.sql`
5. `database/modules/maintenance/04_triggers.sql`
6. `database/modules/maintenance/05_seed_scenarios.sql`
7. `database/migrations/16_indexes.sql`
8. `database/migrations/17_security_hardening.sql`
9. `database/migrations/18_charging_anomaly_rule.sql`
10. `database/migrations/20_temperature_metering_rules.sql`
11. `database/migrations/23_station_overload_rule.sql`
12. `database/migrations/24_voltage_duration_rules.sql`
13. `database/migrations/10_emergency_tables.sql`
14. `database/migrations/11_emergency_objects.sql`
15. `database/migrations/12_emergency_seed.sql`
16. `database/migrations/19_part_stock_movement.sql`
17. `database/migrations/21_emergency_seed_extended.sql`
18. `database/migrations/22_emergency_extended_checks.sql`

推荐直接使用：

```bash
python scripts/rebuild_demo_db.py --with-emergency --yes
```

脚本会重建 `charging_platform_test`，并输出表、视图、过程、触发器和种子数量。

## 后台任务调度

维护模块的后台任务不再只有手动入口，新增独立调度进程：

```bash
cd backend
python -m app.modules.maintenance.scheduler
```

- 每 30 秒轮询一次，不同任务按各自间隔执行；
- 用 MySQL `GET_LOCK` 防止多实例重复执行；
- 单任务失败只记录日志，不阻断其他任务；
- 不修改共享 `main.py`，避免与组员合并冲突。

## 干净环境验收

```bash
python scripts/rebuild_demo_db.py --with-emergency --yes
cd backend
python -m pytest tests -q
```

当前干净测试库结果：`145 passed, 13 warnings, 52 subtests passed`。

如果测试失败，先确认是否执行了最新迁移，尤其是 `23_station_overload_rule.sql` 和 `24_voltage_duration_rules.sql`；不要用旧库直接跑新版测试。
