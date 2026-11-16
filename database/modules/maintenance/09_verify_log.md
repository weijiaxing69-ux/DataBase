# maintenance 模块 · 实机验收记录

执行时间：2026-11-13 19:41–20:0x（GMT+8）
执行人：成员3（脚本由 AI 助手编写并代跑）

## 一、环境

| 项目 | 值 |
|---|---|
| 操作系统 | Windows（本机） |
| 数据库 | MySQL Community Server 8.0.29（ZIP 免安装版） |
| 安装路径 | `C:\Users\zhangxinhao\AppData\Local\Programs\MySQL\mysql-8.0.29-winx64` |
| 数据目录 | `C:\Users\zhangxinhao\AppData\Local\Programs\MySQL\data` |
| 端口 | 3306 |
| 字符集 | utf8mb4 / utf8mb4_0900_ai_ci |
| 时区 | `+00:00`（库内 UTC，与项目约定一致） |
| 账号 | `root`，空密码（仅本机演示用） |
| 库 | `charging_platform_test`（65 表 + 1900 行种子）、`charging_platform`（65 表空库） |

启动方式：双击 `C:\Users\zhangxinhao\AppData\Local\Programs\MySQL\start-mysql.bat`，关闭窗口即停止。
`bin` 目录已加入用户 PATH，新开终端可直接用 `mysql`。

## 二、导入结果

| 步骤 | 脚本 | 结果 |
|---|---|---|
| 1 | `00_测试库建表.sql` | 成功，65 张表 |
| 2 | `04_seed_V1.4.sql` | 成功，事务提交，无报错 |
| 3 | `02_views.sql` | 成功，3 个视图 |
| 4 | `03_procedures.sql` | 成功，2 个过程 |
| 5 | `04_triggers.sql` | 成功，2 个触发器（库内另有统一脚本自带的 1 个，合计 3） |
| 6 | `05_seed_scenarios.sql` | 成功，4 告警 / 6 工单 / 19 事件 |
| 7 | `06_queries.sql` | 6 条查询全部返回，A/B 两种写法结果一致 |
| 8 | `07_checks.sql` | 全部通过，无报错 |

对象统计：`65 表 / 3 视图 / 2 过程 / 3 触发器`。

## 三、验收结果（07_checks.sql 实际输出）

| 条款 | 检查项 | 预期 | 实际 |
|---|---|---|---|
| C01 | 分区结构 | 4 个月分区 × 4 个子分区 | 16 个子分区，`RANGE COLUMNS` |
| C01 | 分区裁剪 | `partitions` 只出现当月 | `p202611_p202611sp3`，`type=range`，`rows=3` |
| C02 | 告警—工单 1:N | alert 901 有 2 条工单 | 901=2、902=2 |
| C02 | 未恢复告警去重 | 重复插入影响 0 行 | `0`，且 `active_e101_on_pile4 = 1` |
| C03 | 全流程耗时 | 901：接单 240s、到场 420s、修复 780s、复核 600s、合计 2040s | 完全一致 |
| C03 | 复核未通过保留历史 | 906：`review_failed_count=1`、`closed_at` 为空 | `240 / NULL / 1`，符合 |
| C04 | 等级时限 | critical 300s、high 600s 快照正确 | 901=300、902=600 |
| C04 | 超时判定 | 902、903 判超时，904 不超时 | `is_overdue = 1,1,0` |
| C05 | 观察期不足 | 30 秒时仍 `recovering` | `recovering` |
| C05 | 满 60 秒 | `recovered`，恢复时间 01:36:00 | `recovered / 2026-11-14 01:36:00` |
| C05 | 观察期有故障采样 | 不得恢复 | 仍 `recovering` |
| 触发器 | 采样自动生成告警 | E101 生成 1 条，重复上报不重复 | 桩 7 最终 2 条（E101 + SCN-TEMP-70） |
| 后台任务 | 超时升级 | 升级次数 +1、写 escalated 事件 | `escalation_level=1, escalated_events=1` |

## 四、负向用例（08_negative_cases.sql）

| 编号 | 操作 | 实际返回 |
|---|---|---|
| N1 | 无 `review_passed` 直接闭环 | `ERROR 1644 (45000) 闭环前必须存在复核通过(review_passed)事件` |
| N2 | `assigned → closed` 跳步 | `ERROR 1644 (45000) 非法的工单状态迁移…` |
| N3 | `arrived → accepted` 回退 | `ERROR 1644 (45000) 非法的工单状态迁移…` |
| N5 | 重复插入未恢复告警 | `ERROR 1062 (23000) Duplicate entry '4:4:E101' for key 'device_alert.uq_device_alert_active_key'` |

## 五、执行中发现并修正的问题

1. **场景数据时间倒挂**（已修正）：首版场景数据里，告警 `occurred_at` 晚于工单 `assigned_at`，导致视图算出负的响应时长（-540 秒）。已把 alert 901 改为 09:35、alert 902 改为 09:20，工单派单时间随之后移，现全部为正值。
2. **对统一脚本的认知修正**：`00_测试库建表.sql` 第 1344 行已自带 `trg_maintenance_reading_pile_exists`（分区表插入前校验桩存在），不是"零触发器"。README 已更正，答辩时这也正好能解释"分区表为什么不建物理外键"。

## 六、仍未覆盖（不能写进报告说已通过）

- 持久层并发：同枪抢单、后台任务双实例、重复采样去重，需要应用侧或两个客户端实测。
- HTTP 接口与前端页面：尚未实现。
- 3NF 证明：需要独立撰写函数依赖分析。
- 备份恢复演练：方案已写，未实际做一次全量+binlog 还原。
