import axios from 'axios'

// 通过 Vite 代理访问后端，浏览器保持同源；会话令牌仅保存在当前标签页。
const http = axios.create({ baseURL: '/api/v1', timeout: 15000 })
http.interceptors.request.use(config => {
  if (!config.headers.Authorization) {
    const token = sessionStorage.getItem('access_token')
    if (token) config.headers.Authorization = `Bearer ${token}`
  }
  return config
})
http.interceptors.response.use(response => response.data, error => {
  const detail = error.response?.data?.detail
  const message = Array.isArray(detail)
    ? detail.map(item => `${item.loc?.slice(1).join('.')}: ${item.msg}`).join('；')
    : detail || (error.code === 'ECONNABORTED' ? '请求超时，请稍后重试' : '无法连接后端，请确认演示服务已启动')
  if (error.response?.status === 401 && !error.config.url.includes('/auth/login') && !error.config.url.includes('/demo/heartbeat')) {
    sessionStorage.removeItem('access_token')
    window.dispatchEvent(new Event('session-expired'))
  }
  return Promise.reject(new Error(message))
})
export default http
