# 设备管理前端

Vue 3 + Vite + Axios。包含运营商、场站、桩、枪、变更审批、验收、命令、状态历史，以及设备联调页面。

## 本机运行

先在项目根目录打开 PowerShell，启动独立演示后端：

```powershell
cd backend
../.venv/Scripts/python.exe -m uvicorn app.demo:create_app --factory --host 127.0.0.1 --port 8001
```

另开一个终端，从项目根目录启动前端：

```powershell
cd frontend
npm.cmd install
npm.cmd run dev -- --port 5173
```

浏览器访问 http://127.0.0.1:5173 。管理员 `platform_admin`，工程师 `maintenance_engineer`，演示密码均为 `Demo123!`。工程师仅授权场站1，可提交设备变更；管理员负责审批。演示使用独立 SQLite 内存，重启后重置，不会读写用户 MySQL。

## 页面代码

- `src/App.vue`：登录、列表、表单、详情、审批和模拟控制台；主要函数附中文说明。
- `src/resources.js`：八类页面的字段配置与中文名称。
- `src/api/http.js`：统一请求、Bearer 登录凭据、错误处理。
- `src/api/assets.js`：设备资源接口；`membership.js`：登录接口。
- `src/style.css`：桌面与手机布局。

## 自动验证

```powershell
npm.cmd run build
npx.cmd playwright install chromium
npm.cmd run test:e2e
```

浏览器测试自动启动和关闭8001、5173服务，运行前应先关闭这两个端口的手动服务。测试覆盖页面登录、增改查、授权范围、变更审批、验收、心跳恢复、模拟订单和命令确认，并生成 `artifacts/desktop.png` 与 `artifacts/mobile.png`。恢复窗口按真实时间等待32秒，不绕过业务规则。

2026-11-16 本机验证：后端66项测试通过；前端生产构建通过；2条浏览器流程测试通过（42.1秒）。已查看桌面和390px手机截图；完整流程未捕获浏览器脚本异常。测试后服务自动关闭，手动查看页面请按上方步骤重新启动。

联调入口中的订单、采样、设备回执属于模拟适配器，方便检查成员1流程；真实计费支付、告警工单流程和硬件协议仍需要对应成员接入。默认代理指向8001演示后端；接正式后端时调整 `vite.config.js`，并完成相应鉴权、数据库和设备适配配置。
