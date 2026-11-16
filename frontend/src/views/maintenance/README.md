# 维护模块前端

- `MaintenanceBoard.vue`：设备运维看板（KPI、告警列表、工单处置、时间线、应急事件）。
  数据来自 `src/api/maintenance.js`，不依赖 App.vue 的资源表格壳。

## 接入方式（二选一）

**方式 A：加一个导航项（推荐）**

在 `src/resources.js` 里加一条只读资源占位：

```js
{ key: 'maintenance', title: '设备运维', columns: [] }
```

在 `App.vue` 的 `<script setup>` 中导入组件：

```js
import MaintenanceBoard from './views/maintenance/MaintenanceBoard.vue'
```

在 `<template>` 的内容区顶部加分支：

```vue
<MaintenanceBoard v-if="pageKey === 'maintenance'" />
<template v-else-if="resource"> ... 原有资源表格 ... </template>
```

**方式 B：单独入口**

在 `src/main.js` 里把 `App` 换成 `MaintenanceBoard` 单独跑一版，用于验收演示。

## 注意

- 所有请求都经过 `api/http.js`，自动带 `Authorization: Bearer <token>`。
- 权限码：告警读取用 `maintenance.alert.read`，派单用 `maintenance.work_order.assign`，
  处置用 `maintenance.work_order.handle`。种子只登记了这 4 个 maintenance 权限码。
