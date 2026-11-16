// maintenance 模块 API，函数名遵循 V1.4 第 5/6 章 camelCase 命名。
// 后端前缀 /api/v1 已由 http.js 统一拼接，这里只写模块内路径。
import http from './http'

// ---------------- 告警规则 ----------------
export const listAlarmRules = params => http.get('/maintenance/alarm-rules', { params })
export const getAlarmRule = id => http.get(`/maintenance/alarm-rules/${id}`)
export const createAlarmRule = data => http.post('/maintenance/alarm-rules', data)
export const updateAlarmRule = (id, data) => http.patch(`/maintenance/alarm-rules/${id}`, data)

// ---------------- 告警 ----------------
export const listAlerts = params => http.get('/maintenance/alerts', { params })
export const getAlert = id => http.get(`/maintenance/alerts/${id}`)

// ---------------- 工单 ----------------
export const listWorkOrders = params => http.get('/maintenance/work-orders', { params })
export const getWorkOrder = id => http.get(`/maintenance/work-orders/${id}`)
export const listWorkOrderEvents = id => http.get(`/maintenance/work-orders/${id}/events`)
export const createWorkOrder = (alertId, data) => http.post(`/maintenance/alerts/${alertId}/work-orders`, data)
export const appendWorkOrderEvent = (id, data) => http.post(`/maintenance/work-orders/${id}/events`, data)

// ---------------- 设备上报 ----------------
// 设备身份尚未接入时，这两个接口需要持有 maintenance.device_reading.read 的账号令牌。
export const sendHeartbeat = data => http.post('/maintenance/heartbeats', data)
export const uploadDeviceReading = data => http.post('/maintenance/readings', data)

// ---------------- 报障 ----------------
export const listFaultReports = params => http.get('/maintenance/fault-reports', { params })
export const getFaultReport = id => http.get(`/maintenance/fault-reports/${id}`)
export const createFaultReport = data => http.post('/maintenance/fault-reports', data)
export const handleFaultReport = (id, data) => http.post(`/maintenance/fault-reports/${id}/handling`, data)

// ---------------- 巡检 ----------------
export const listInspections = params => http.get('/maintenance/inspections', { params })
export const getInspection = id => http.get(`/maintenance/inspections/${id}`)
export const createInspection = data => http.post('/maintenance/inspections', data)

// ---------------- 应急事件（V1.5） ----------------
export const listIncidents = () => http.get('/maintenance/incidents')
export const declareIncident = params => http.post('/maintenance/incidents', null, { params })
export const escalateIncidents = () => http.post('/maintenance/incidents/escalate')

// ---------------- 统计与运维任务（拓展） ----------------
export const getOverview = () => http.get('/maintenance/stats/overview')
export const runTask = name => http.post(`/maintenance/tasks/${name}/run`)
