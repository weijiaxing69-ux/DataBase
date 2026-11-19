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
// 这两个接口用 X-Device-Token 识别设备身份，不能改用账号令牌。
const deviceHeaders = token => ({ 'X-Device-Token': token })
export const sendHeartbeat = (data, token) => http.post('/maintenance/heartbeats', data, { headers: deviceHeaders(token) })
export const uploadDeviceReading = (data, token) => http.post('/maintenance/readings', data, { headers: deviceHeaders(token) })

// ---------------- 报障 ----------------
export const listFaultReports = params => http.get('/maintenance/fault-reports', { params })
export const getFaultReport = id => http.get(`/maintenance/fault-reports/${id}`)
export const createFaultReport = data => http.post('/maintenance/fault-reports', data)
export const handleFaultReport = (id, data) => http.post(`/maintenance/fault-reports/${id}/handling`, data)

// ---------------- 巡检 ----------------
export const listInspections = params => http.get('/maintenance/inspections', { params })
export const getInspection = id => http.get(`/maintenance/inspections/${id}`)
export const createInspection = data => http.post('/maintenance/inspections', data)

// ---------------- 备件（V1.5） ----------------
export const listSpareParts = params => http.get('/maintenance/spare-parts', { params })
export const createPartUsage = data => http.post('/maintenance/part-usages', data)
export const listPartUsages = workOrderId => http.get('/maintenance/part-usages', { params: { work_order_id: workOrderId } })
export const stockInPart = data => http.post('/maintenance/part-stock-ins', data)
export const listPartMovements = partId => http.get('/maintenance/part-movements', { params: { part_id: partId } })

// ---------------- 绩效统计 ----------------
export const getPerformance = () => http.get('/maintenance/stats/performance')

// ---------------- 应急事件（V1.5） ----------------
export const listIncidents = () => http.get('/maintenance/incidents')
export const declareIncident = params => http.post('/maintenance/incidents', null, { params })
export const escalateIncidents = () => http.post('/maintenance/incidents/escalate')
export const closeIncident = (id, summary) => http.post(`/maintenance/incidents/${id}/close`, null, { params: { summary } })

// ---------------- 统计与运维任务（拓展） ----------------
export const getOverview = () => http.get('/maintenance/stats/overview')
export const runTask = name => http.post(`/maintenance/tasks/${name}/run`)
