# 新能源汽车充电平台

按 V1.4 开发的充电平台。成员1设备后端、设备管理前端及必要的登录鉴权已实现；其他成员的订单、采样与设备回执提供独立模拟联调入口，完整计费支付等模块仍需对应成员实现。

## 运行设备管理页面

首次克隆后，先在项目根目录准备 Python 环境（建议 Python 3.12 或3.13）：

```powershell
python -m venv .venv
.venv/Scripts/python.exe -m pip install -r backend/requirements.txt
Copy-Item backend/.env.example backend/.env
```

演示入口不连接 MySQL，复制示例配置即可启动；正式后端须另行填写数据库密码和加密、签名密钥。请勿提交本机 `.env`。

打开两个 PowerShell 终端，在项目根目录分别执行：

```powershell
cd backend
../.venv/Scripts/python.exe -m uvicorn app.demo:create_app --factory --host 127.0.0.1 --port 8001
```

```powershell
cd frontend
npm.cmd install
npm.cmd run dev -- --port 5173
```

访问 http://127.0.0.1:5173 。演示账号 `platform_admin` / `maintenance_engineer`，密码 `Demo123!`。此入口使用独立 SQLite 内存，重启清空，不修改本机 MySQL。详细操作和浏览器测试见 [前端说明](frontend/README.md)；后端联调说明见 [设备与成员四联调说明](docs/设备与成员四联调说明.md)。

## 在 PyCharm 运行

1. 打开整个 charging_platform 文件夹。
2. 项目解释器选择 `.venv/Scripts/python.exe`。
3. 运行配置 `Backend`，或右键 `backend/run.py` 运行。
4. 浏览器访问 http://127.0.0.1:8000/docs 和 http://127.0.0.1:8000/health。
5. 右键运行 `backend/check_database.py` 可检查数据库和四张主要表的数据量。

本机使用 Python 3.13.4；原 V1.4 规范为 3.12，团队提交前需统一版本并复测。
依赖安装在项目独立 .venv 内。backend/requirements.lock.txt 记录本次安装版本。
backend/.env 是本机连接配置，已加入 .gitignore，不提交给团队；队友复制 .env.example 自行配置。
项目不会自动建表或导入数据，当前连接 charging_platform_test。

## 目录与职责

- backend/app/core：配置、连接和安全公共代码。
- backend/app/shared：跨模块契约。
- backend/app/modules/assets：成员1的模型、Schema、DAO、Service、路由。
- 其余四个模块目录预留给其他成员。
- backend/tests：设备业务、鉴权、HTTP及跨模块集成测试。
- frontend/src：Vue页面、字段配置、样式与 API；frontend/tests：浏览器流程测试。
- database/bootstrap：原始建表、数据和验收脚本。
- database/modules：各模块 SQL；migrations：升级脚本。
- docs：统一 V1.4 JSON 契约副本。

## 模块接入

设备接口与公共辅助函数已实现，函数签名、分页、权限、ID/金额序列化按 V1.4 契约处理。其他成员接入时用真实订单、告警工单和设备通信替换演示适配器；演示通过不等于真实 MySQL 与硬件已验收。
事务由最外层 Service 控制，DAO 和跨模块辅助函数不自行 commit/rollback/close。
