import http from './http'

// 对应后端资源路径；调用者只能从页面预定义的资源中选择。
export const listResource = (resource, params) => http.get(`/assets/${resource}`, { params })
export const getResource = (resource, id) => http.get(`/assets/${resource}/${id}`)
export const createResource = (resource, data) => http.post(`/assets/${resource}`, data)
export const updateResource = (resource, id, data) => http.patch(`/assets/${resource}/${id}`, data)
export const reviewChangeRequest = (id, data) => http.post(`/assets/change-requests/${id}/reviews`, data)
export const issueDeviceCredential = (id, expires_at) => http.post(`/assets/piles/${id}/credentials`, { expires_at })
export const listOperators = params => listResource('operators', params)
export const listStations = params => listResource('stations', params)
export const listPiles = params => listResource('piles', params)
export const listGuns = params => listResource('guns', params)
export const listChangeRequests = params => listResource('change-requests', params)
export const listAcceptances = params => listResource('acceptances', params)
export const listDeviceCommands = params => listResource('device-commands', params)
export const listDeviceStatusLogs = params => listResource('status-logs', params)
