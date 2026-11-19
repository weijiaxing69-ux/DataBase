# Membership 数据库模块

本目录是从 V1.4 统一 DDL 拆出的成员4数据库对象。字段、主键、索引、CHECK 和列注释从统一 DDL 原样抽取；本目录只维护 membership 本地表与本模块规则。

## 导入顺序

1. 在空库执行全项目 `database/bootstrap/00_测试库建表.sql`（该脚本创建所有模块表和统一外键）。
2. 导入 `database/bootstrap/04_seed_V1.4.sql`；不要再重复导入 membership 子集。
3. 执行本目录 `06_permissions.sql` 补齐接口使用的权限码并映射到固定角色。
4. 执行 `database/migrations/20261119_member4_self_service.sql` 创建余额退款申请和服务申诉扩展表。
5. 执行本目录 `03_views.sql`、`04_procedures.sql`、`05_triggers.sql`。
6. 执行 `08_queries.sql` 并在 MySQL 8.0.18+ 使用 `EXPLAIN ANALYZE` 记录计划。

当前文件 `01_tables.sql` 仅含本模块 24 张表，因此本身不是全项目空库初始化入口。`02_foreign_keys.sql` 适用于分阶段装载；若已执行本仓库完整 DDL，不要重复执行外键脚本。绝不在非空共享库运行初始化。

## 数据对象

- `01_tables.sql`：24 张 membership 表，直接来自 V1.4 统一 DDL。
- `02_foreign_keys.sql`：membership 作为引用方的外键；依赖全项目相关目标表已创建。
- `03_views.sql`：会员、优惠券和车队额度汇总视图，不投影手机号/车牌明文。
- `04_procedures.sql`：活动发券过程，检查状态、有效期、活动总量、每用户上限并保存发放快照。由 Service 的事务包住调用。
- `05_triggers.sql`：余额流水不可变保护。
- `06_permissions.sql`：V1.4 固定角色的权限码补充和角色授权。
- `database/migrations/20261119_member4_self_service.sql`：新增会员余额退款申请、服务申诉及申诉处理时间线三张扩展表；退款状态包括待审核、处理中、已完成和已拒绝，基础 V1.4 的 24 张表保持不变。
- `08_queries.sql`：3 个多表查询，每题提供 JOIN/预聚合或 CTE 两种写法。

## 对照源

- `database/bootstrap/00_测试库建表.sql`
- `database/bootstrap/04_seed_V1.4.sql`
- `database/bootstrap/90_验收查询.sql`
- `docs/新能源汽车充电桩运营服务平台_统一数据字典与接口函数规范_V1.4.json`

会员 DDL、对象、查询和关键函数已在隔离 MySQL 8.4 实例进行验证；成员4阶段报告记录了测试结果和组内联调边界。
新扩展表必须先运行对应 migration；旧数据库升级时同时重跑 `06_permissions.sql`，以注册会员自助和客服处理权限。
