import http from './http'
export const login = data => http.post('/auth/login', data)
export const getCurrentUser = () => http.get('/auth/me')
export const logout = () => http.post('/auth/logout', {})
