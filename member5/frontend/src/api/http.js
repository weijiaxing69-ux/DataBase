export async function request(path, { token, body, method = 'GET', key } = {}) {
  const headers = { Accept: 'application/json' }
  if (token) headers.Authorization = 'Bearer ' + token
  if (body !== undefined) headers['Content-Type'] = 'application/json'
  if (key) headers['Idempotency-Key'] = key
  const response = await fetch('/api/v1' + path, {
    method, headers, body: body === undefined ? undefined : JSON.stringify(body),
  })
  if (response.status === 204) return null
  const result = await response.json().catch(() => null)
  if (!response.ok) {
    throw Object.assign(new Error(result?.message || '请求失败，请检查后端服务。'), { status: response.status })
  }
  return result
}
