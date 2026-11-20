# 成员五结算工作台

当前可演示运营商结算、对账差异与调整、车主消费发票、车队月结与分次收款、车队专价草稿和分成政策。使用 V1.4 DDL、测试数据与结算模块 05–07 SQL。

## 本地运行

已有虚拟环境、`backend/.env` 和前端构建产物时，可在 VS Code 打开项目根目录的
`start_server.py`，点击「运行 Python 文件」。也可在项目根目录运行：

```powershell
.\.venv\Scripts\python.exe .\start_server.py
```

看到 Uvicorn 启动后，打开 http://127.0.0.1:8001/settlement/settlements。
如需换端口，运行时加 `--port 8002`。MySQL 仍需运行。

从项目根目录安装 Python 依赖：

```powershell
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r backend/requirements.txt
```

复制 `backend/.env.example` 到 `backend/.env` 并填入开发库连接和随机签名密钥。配置文件不提交。开发时分别在两个终端运行：

```powershell
.\.venv\Scripts\python.exe -m uvicorn app.main:app --app-dir backend --host 127.0.0.1 --port 8000
npm.cmd --prefix frontend ci
npm.cmd --prefix frontend run dev
```

Vue 默认在 http://127.0.0.1:5173，Swagger 在 http://127.0.0.1:8000/docs。也可以构建前端后，将 `FRONTEND_DIST` 环境变量设为 `frontend/dist` 的绝对路径，由同一个 FastAPI 服务提供页面。

```powershell
npm.cmd --prefix frontend run build
$env:FRONTEND_DIST = (Resolve-Path './frontend/dist').Path
.\.venv\Scripts\python.exe -m uvicorn app.main:app --app-dir backend --host 127.0.0.1 --port 8000
```

单服务入口为 http://127.0.0.1:8000/settlement/settlements。本地已配置专用 MySQL 开发账号与签名密钥。

登录使用 V1.4 测试包里的 `platform_admin_demo`、`operator_manager_demo`、`customer_service_demo`、`fleet_admin_demo`，车主发票可使用已关联车主档案的 `owner_01` 等账号，密码见测试包 README。历史十月结算单可直接查看详情。生成新结算单需要已付订单、退款或待核对订单；归集正单时须匹配有效分成政策。

已有库先执行 `database/modules/settlement/10_audit.sql` 追加审计表。原本地开发账号再由管理员执行 `09_local_grants.sql` 补充权限，顺序是 10 后 09；不重建已有业务表。

## 联调约定

结算持久层完整复验（包含并发与历史记录）：

```powershell
.\.venv\Scripts\python.exe -u .\backend\tests\settlement\run_acceptance.py
```

覆盖范围和结果日志位置见 `backend/tests/settlement/README.md`。

- 本地登录使用 V1.4 账号和会话表，合并时换成成员四的公共登录与 Actor 依赖。当前平台管理员和客服拥有结算列表及开票入口，运营商按账号关联范围查看，并需确认权限才能代表运营商确认。
- `app/modules/billing/queries.py` 与 `service.py` 中的车队收款分配是成员二接口的本地实现。合并时要联调成功退款写入、原账单抵扣回调、月结收款分配、额度和车队专价审批。专价在本模块仅创建草稿，启用归成员二的价格审批。
- 账期按北京时间划分。归集正单保留原订单结束时刻，退款按成功时刻独立冲减；调整由另一名管理员审批，审批通过后升版并重新确认。
- 已通过追加审计记录保存处理结论历史、审批依据、发票办理说明及红冲原因。新增结算调整列表和操作记录入口。扩展接口、角色矩阵及迁移见 `backend/tests/settlement/CHANGES_2026-11-20.md`。
- 测试依赖安装：`python -m pip install -r backend/requirements-test.txt`。标准入口 `python -m pytest -q backend/tests/settlement`；归档仍使用 run_acceptance.py。前端真实写流程：`npm.cmd --prefix frontend run test:e2e`，首次需安装 Playwright Chromium。
