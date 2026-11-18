import axios from 'axios'
import router from './router'

export const api = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL || '',
  timeout: 15000,
})

api.interceptors.request.use((config) => {
  const token = localStorage.getItem('member4.access_token')
  if (token) config.headers.Authorization = `Bearer ${token}`
  return config
})

api.interceptors.response.use(
  (response) => response.data,
  async (error) => {
    if (error.response?.status === 401 && router.currentRoute.value.name !== 'login') {
      localStorage.removeItem('member4.access_token')
      localStorage.removeItem('member4.account')
      await router.push('/login')
    }
    return Promise.reject(error)
  },
)

export function saveSession(session) {
  localStorage.setItem('member4.access_token', session.access_token)
  localStorage.setItem('member4.account', JSON.stringify(session.account))
}

export function clearSession() {
  localStorage.removeItem('member4.access_token')
  localStorage.removeItem('member4.account')
}

export function currentAccount() {
  try { return JSON.parse(localStorage.getItem('member4.account') || 'null') }
  catch { return null }
}
