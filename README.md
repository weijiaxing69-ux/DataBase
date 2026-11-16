# 新能源充电平台：成员 2 订单计费

本目录实现 V1.4 的订单计费模块。数据库是 Docker 容器 `mysql8` 中的 MySQL 8，宿主端口 3307，库名沿用统一建表 SQL 中的 `charging_platform`。

## PyCharm 一键启动

用 PyCharm 打开整个 `member2-billing` 文件夹，新建 Python 虚拟环境并安装 `requirements.txt`。前端在 `frontend/` 安装 `package-lock.json` 对应的 npm 依赖。随后在右上角依次运行“启动后端”和“启动前端”两个共享配置；首次运行前先打开 Docker Desktop。业务页面为 <http://127.0.0.1:5173/>，本地 Swagger 为 <http://127.0.0.1:8000/docs>。本机演示管理员凭据由 `bootstrap_demo.py` 写入未纳入版本控制的 `demo-login.txt`。

空数据库初始化依次运行 `setup_schema.py`、`seed_data.py`、`bootstrap_demo.py`。`database/reference/` 保存小组 V1.4 统一建表 SQL 和数据模型快照，便于独立检出运行。`setup_schema.py` 执行统一建表 SQL，并安装本模块的 3 个视图、1 个过程、1 个触发器；`seed_data.py` 填充业务演示数据并通过 `seed_security.py` 初始化固定角色和计费权限。固定角色严格为规范中的 6 种，权限码按已实现的操作生成，不为满足“20 条数据”伪造字典项。已有开发库仅需重跑 `install_billing_sql.py` 或 `seed_security.py`，无需重新建表。**不要在已有数据的数据库上重复运行 `setup_schema.py`。**

## 已实现

- 价格规则草稿、审批、防止生效期重叠，峰平谷及免费服务时长分段计费。
- 个人与车队充电订单、设备凭据绑定桩上报、异常读数复核、设备启停待发送命令。
- 个人模拟/钱包支付及钱包流水，优惠券锁定、核销、超时释放和全额退款补发。
- 车队授权与月额度预占、跨月结算、专价、月结收款分配和退款额度调整；向结算模块提供账期订单、跨期退款查询函数。
- 数据库会话认证、角色及权限码核验、车主/车队/客服/运营商数据范围、分页和筛选。
- 计费写操作支持 `Idempotency-Key`：同账号同请求重试返回原结果，修改请求内容会返回冲突；业务写入和去重记录在同一事务提交。
- 价格和采样输入使用严格字段校验，设备采样来源由凭据推导；错误统一返回 `code`、`message`、`request_id`。
- 订单、详情、价格、退款、审批页面；订单列表支持状态、订单编号、场站筛选与翻页。
- 3 个视图、1 个存储过程、1 个触发器及 3 题双写法 SQL，见 `database/modules/billing/`；`查询实现对比.md` 记录真实开发库的执行计划和小样本耗时。

## 测试

在项目目录运行 `python -m pytest -q test_billing.py test_billing_sql.py test_billing_more.py`。测试包括计算边界、真实 MySQL API 事务、车队月结与退款、权限隔离、设备凭据、SQL 双写法结果一致性、过程和触发器。前端运行 `npm run build`。测试输出摘要写在 `test-results.txt`。

`frontend/` 是成员 2 独立开发页面。小组完整联调仍需接入成员 4 的正式账号初始化、成员 5 的账单生成和设备真实回调/命令发送。当前支付与退款是模拟渠道，不连接真实支付机构；演示种子数据也不代表真实业务量或生产性能。
