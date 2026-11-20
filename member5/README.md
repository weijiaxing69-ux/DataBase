# 成员五：结算与对账

本目录提供可独立运行的 V1.4 结算工作台，包含运营商结算、对账调整、开票和红冲、车主消费发票、车队月结与分次收款、分成政策及车队专价草稿。

从本目录开始，按 [运行说明](backend/README.md) 配置 Python、MySQL 和前端。[数据库说明](database/modules/settlement/README.md) 列出初始化和验收顺序。V1.4 测试数据 ZIP、接口规范 JSON 和隔离测试辅助脚本一并保留，以便复验。

合并时将结算后端、结算页面、结算 API、模块 SQL 和测试接入仓库对应目录。参照本目录的路由注册、导航和依赖配置接入团队入口；成员二的计费服务与成员四的身份验证应使用全组实现。本目录内的同类代码用于独立演示。09_local_grants.sql 仅针对原本地演示账号，组内按各自环境配置。

## 2026 年 11 月 20 日补充

已修复负余额结转前原订单未结清的问题；新增追加式审计和调整申请列表。已有库先执行 database/modules/settlement/10_audit.sql，再按本机账号情况执行 09_local_grants.sql。原业务表和数据不重建。

公共测试夹具独立于 test_flow.py，支持 pytest。安装 backend/requirements-test.txt 后执行 python -m pytest -q backend/tests/settlement；一键归档使用 backend/tests/settlement/run_acceptance.py。真实浏览器测试执行 npm --prefix frontend run test:e2e，首次需要安装 Playwright Chromium。测试使用隔离 MySQL，验收结果为 7 项 pytest、3 条浏览器流程通过。

扩展接口、页面、角色矩阵、迁移和联调边界见 backend/tests/settlement/CHANGES_2026-11-20.md。
