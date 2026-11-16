本模块 SQL 放在此处，遵循统一表结构，不重复建立已有表。

## 文件与执行顺序

前提：已按 `database/README.md` 导入 `bootstrap/`（65 表 + 种子数据）。

| 顺序 | 文件 | 内容 | 可重复执行 |
|---|---|---|---|
| 1 | `02_views.sql` | 3 个视图：设备实时状态、告警响应明细、工单进度 | 是 |
| 2 | `03_procedures.sql` | 2 个过程：工单闭环、告警恢复判定 | 是 |
| 3 | `04_triggers.sql` | 2 个触发器：采样自动生成告警、工单状态机 | 是 |
| 4 | `05_seed_scenarios.sql` | 演示数据：四档时限规则、告警 1:N、超时、L03 时间线 | 否 |
| 5 | `06_queries.sql` | 3 题查询 × 2 种写法 | 是 |
| 6 | `07_checks.sql` | 正向验收（C01–C05） | 是 |
| 7 | `08_negative_cases.sql` | 负向用例，逐条执行 | — |

```bash
mysql -u root -h 127.0.0.1 charging_platform_test < 02_views.sql
mysql -u root -h 127.0.0.1 charging_platform_test < 03_procedures.sql
mysql -u root -h 127.0.0.1 charging_platform_test < 04_triggers.sql
mysql -u root -h 127.0.0.1 charging_platform_test < 05_seed_scenarios.sql
```

## 迁移脚本（database/migrations）

| 文件 | 内容 |
|---|---|
| `10~15` | V1.5 应急增强：11 张增量表、视图、过程、触发器、场景数据 |
| `16_indexes.sql` | 列表排序索引（告警时间、工单派单时间、巡检时间） |
| `17_security_hardening.sql` | 补齐 6 个 maintenance 权限码并授权；采样表加 (pile_id, sampled_at) 唯一键 |

## V1.5 应急增强（增量）

放在 `database/migrations/`，按 10 → 15 顺序执行；**不动 bootstrap 的 65 张表**，
新增 11 张表（incident 系列 + 备件）。详见 `docs/应急响应增强方案_V1.5.md`（在成员3 本地工作区）。

> 注意：V1.5 的 11 张表目前**不在** `bootstrap/00_测试库建表.sql` 里。
> 若要纳入统一建库脚本，需和组长确认后单独提交，不要直接改 bootstrap。
