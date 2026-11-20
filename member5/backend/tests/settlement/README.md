# 成员五结算持久层验收

本目录提供标准 pytest 验收和兼容的直接运行脚本。测试启动隔离 MySQL，装载 V1.4 与 10_audit.sql，不修改网页所连接的开发库。需要本机 MySQL Server/客户端、backend/requirements-test.txt 依赖及原目录中的 V1.4 测试包。

在项目根目录执行：

```powershell
.\.venv\Scripts\python.exe -u .\backend\tests\settlement\run_acceptance.py
```

脚本运行 pytest，结果保存在 `results/时间戳/`，包含原始日志、JUnit XML 和 summary.txt。也可直接执行 `python -m pytest -q backend/tests/settlement`。合并后必须复跑，独立模块日志不代替小组联调。

| 文件 | 验证内容 |
| --- | --- |
| database/modules/settlement/test_settlement_sql.py | 视图、等价复杂查询、开票过程、双方确认约束、红冲和事务回滚 |
| test_flow.py | 身份及运营商范围、分页、生成、双方确认、开票、幂等与红冲 |
| test_v14_contract.py | V1.4 接口和函数签名、页面入口、差异处理、调整升版、消费发票、车队现金与抵扣、退款及补缴 |
| test_concurrency.py | 五组真实 MySQL 并发或历史验证，见下表 |
| test_regressions.py | 负余额先结清旧订单、零现金纯抵扣、正常抵扣、操作审计与回滚、调整查询、角色拒绝矩阵 |
| test_acceptance.py、conftest.py | 统一 pytest 入口与隔离库共用夹具 |

| 编号 | 场景 | 成功标准 |
| --- | --- | --- |
| C01 | 两个连接同时生成同运营商、场站、账期 | 一笔成功、一笔 SETTLEMENT_EXISTS；仅一张账单、一个原订单明细；订单归集引用正确 |
| C02 | 两个连接各开 3 元，应结只有 4.07 元 | 只能一笔成功，另一笔超限回滚；实际只保存一张 3 元蓝票 |
| C03 | 对同一张 3 元蓝票同时红冲两笔 2 元 | 只能一笔成功；另一笔超限回滚；只保存一张 2 元红票 |
| C04 | 差异结论由版本 2 修订到版本 3 | 旧版确认及意见保留；旧版操作被拒绝；新版需要双方重新确认 |
| C05 | 版本 1 的运营商确认与调整审批同时发生 | 确认要么先完成，要么因版本过期被拒绝；最终版本 2、金额正确、双方待确认；旧确认仍保存，但不能开新版发票 |

并发测试使用两个不同的 MySQL CONNECTION_ID、独立事务和同步屏障。普通 Service 在首个 FOR UPDATE 前同步；底层游标执行的开票过程在调用前同步，不为测试添加生产代码没有的锁。失败后从新连接读取数据库，核对实际记录数量和金额。

10_audit.sql 的追加审计记录补足差异结论修订、审批依据、办理说明和红冲原因；test_regressions.py 检查修改前后值、对象权限、审计写失败时业务回滚。历史种子不补造记录。

真实网页测试：先安装前端依赖与 Chromium，再执行 `npm.cmd --prefix frontend run test:e2e`。它自动启动隔离数据库和后端，覆盖结算/差异/调整/重确认/开票/红冲、车主发票、车队分次收款及角色切换。原始输出归档于 results/browser，HTML 报告在 frontend/playwright-report。
