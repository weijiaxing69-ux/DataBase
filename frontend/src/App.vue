<script setup>
import { computed, onMounted, onUnmounted, reactive, ref } from 'vue'
import http from './api/http'
import { login, logout, getCurrentUser } from './api/membership'
import { listResource, getResource, createResource, updateResource, reviewChangeRequest, issueDeviceCredential } from './api/assets'
import { resources, labels, values, display } from './resources'

// 当前账号来自后端 /auth/me；隐藏按钮只是交互提示，真正权限仍由后端检查。
const account = ref(null)
const credentials = reactive({ username: 'platform_admin', password: '' })
const pageKey = ref('piles')
const resource = computed(() => resources.find(item => item.key === pageKey.value))
const admin = computed(() => account.value?.roles.includes('platform_admin'))
const engineer = computed(() => account.value?.roles.includes('maintenance_engineer'))
const canCreate = computed(() => resource.value?.fields && (admin.value && pageKey.value !== 'change-requests' || engineer.value && ['change-requests', 'acceptances'].includes(pageKey.value)))
const rows = ref([]), total = ref(0), loading = ref(false), busy = ref(false)
const error = ref(''), notice = ref(''), dialog = ref(null), selected = ref(null)
const form = reactive({}), filters = reactive({ keyword: '', status: '', page: 1, page_size: 10 })
const formFields = computed(() => {
  const item = resource.value
  if (!item) return []
  if (dialog.value !== 'edit') return item.fields || []
  return item.updateFields || [...item.fields.filter(f => !item.updateExclude?.includes(f.key)),
    ...(item.key === 'stations' ? [{ key: 'status', label: '状态', type: 'select', options: item.status }] : [])]
})
let loadVersion = 0
function expired() {
  account.value = null
  dialog.value = null
  device.token = ''
  error.value = '登录已过期，请重新登录'
}
async function act(action, message) {
  if (busy.value) return
  error.value = ''; notice.value = ''; busy.value = true
  try { await action(); if (message) notice.value = message }
  catch (e) { error.value = e.message }
  finally { busy.value = false }
}
async function signIn() {
  await act(async () => {
    const response = await login(credentials)
    sessionStorage.setItem('access_token', response.access_token)
    account.value = response.account
    credentials.password = ''
    await load()
  })
}
async function signOut() {
  await act(async () => {
    await logout()
    sessionStorage.removeItem('access_token')
    account.value = null; dialog.value = null; rows.value = []; device.token = ''
  })
}
async function load() {
  if (account.value && pageKey.value === 'demo' && !admin.value) {
    pageKey.value = 'piles'; window.location.hash = 'piles'
  }
  if (!resource.value || !account.value) return
  const version = ++loadVersion
  loading.value = true; error.value = ''
  try {
    const params = { page: filters.page, page_size: filters.page_size }
    if (filters.keyword) params.keyword = filters.keyword
    if (filters.status) params.status = filters.status
    const response = await listResource(pageKey.value, params)
    if (version === loadVersion) { rows.value = response.items; total.value = response.total }
  } catch (e) {
    if (version === loadVersion) { error.value = e.message; rows.value = []; total.value = 0 }
  } finally { if (version === loadVersion) loading.value = false }
}
async function navigate(key) {
  ++loadVersion
  pageKey.value = key; filters.page = 1; filters.keyword = ''; filters.status = ''
  rows.value = []; dialog.value = null; error.value = ''; notice.value = ''
  window.location.hash = key
  await load()
}
// 浏览器后退、前进时，让页面跟随地址栏中的资源名称变化。
function followHash() {
  const key = window.location.hash.slice(1)
  if (key !== pageKey.value && (resources.some(item => item.key === key) || key === 'demo' && admin.value)) navigate(key)
}
function openForm(row = null) {
  selected.value = row
  dialog.value = row ? 'edit' : 'create'
  Object.keys(form).forEach(key => delete form[key])
  for (const f of formFields.value) form[f.key] = row?.[f.key] ?? f.default ?? (f.type === 'checkbox' ? false : '')
}
async function view(row) {
  await act(async () => { selected.value = await getResource(pageKey.value, row[resource.value.id]); dialog.value = 'detail' })
}
async function save() {
  await act(async () => {
    const payload = {}
    for (const f of formFields.value) {
      let value = form[f.key]
      if (value === '') {
        if (dialog.value === 'edit' && f.key === 'warranty_until') payload[f.key] = null
        continue
      }
      if (f.key === 'proposed_data') {
        try { value = JSON.parse(value) } catch { throw new Error('拟修改内容必须是合法的 JSON 对象') }
        if (!value || Array.isArray(value) || typeof value !== 'object') throw new Error('拟修改内容必须是 JSON 对象')
      }
      // 金额、功率、经纬度保留原始字符串，由后端 Decimal 校验，编号也避免浮点转换。
      payload[f.key] = value
    }
    if (dialog.value === 'edit') await updateResource(pageKey.value, selected.value[resource.value.id], payload)
    else await createResource(pageKey.value, payload)
    dialog.value = null
    await load()
  }, '保存成功')
}
const decision = reactive({ decision: 'approved', note: '' })
function openReview(row) { selected.value = row; decision.decision = 'approved'; decision.note = ''; dialog.value = 'review' }
async function review() {
  await act(async () => {
    await reviewChangeRequest(selected.value.request_id, decision)
    dialog.value = null; await load()
  }, '审批已保存')
}

// 模拟控制台使用独立后端 demo 接口，不在浏览器直接伪造设备运行状态。
const device = reactive({ pileId: '1', gunId: '1', orderId: '', token: '', result: '', expires: '' })
async function issue() {
  await act(async () => {
    const result = await issueDeviceCredential(device.pileId, new Date(Date.now() + 3600000).toISOString())
    device.token = result.secret_token; device.expires = result.expires_at
    device.result = '凭据已签发。原文仅本次返回，离开或刷新页面后需要重新签发。'
  })
}
async function demoAction(kind) {
  await act(async () => {
    let result
    if (kind === 'heartbeat') {
      if (!device.token.trim()) throw new Error('请先签发设备凭据')
      result = await http.post('/demo/heartbeat', null, { headers: { Authorization: `Bearer ${device.token}` } })
    } else if (kind === 'recover') result = await http.post(`/demo/piles/${device.pileId}/recover`)
    else if (kind === 'start') {
      result = await http.post('/demo/orders', { gun_id: device.gunId })
      device.orderId = result.order_id
    } else if (kind === 'finish') {
      if (!device.orderId) throw new Error('请先创建模拟订单或填写订单编号')
      result = await http.post(`/demo/orders/${device.orderId}/finish`)
    } else result = await http.post(`/demo/${kind}`)
    device.result = JSON.stringify(result, null, 2)
  }, '操作完成')
}
onMounted(async () => {
  window.addEventListener('session-expired', expired)
  window.addEventListener('hashchange', followHash)
  const initial = window.location.hash.slice(1)
  if (resources.some(item => item.key === initial) || initial === 'demo') pageKey.value = initial
  if (sessionStorage.getItem('access_token')) {
    await act(async () => { account.value = await getCurrentUser(); await load() })
  }
})
onUnmounted(() => {
  window.removeEventListener('session-expired', expired)
  window.removeEventListener('hashchange', followHash)
})
</script>

<template>
  <main v-if="!account" class="login-page">
    <div class="intro"><div class="brand-mark">ϟ</div><p class="eyebrow">CHARGING PLATFORM</p><h1>充电设施<br>运营工作台</h1><p>管理场站与设备，追踪每一次变更。</p><div class="intro-line"></div><p class="intro-small">设备管理 · 验收投运 · 状态追踪</p></div>
    <form class="login-card" @submit.prevent="signIn">
      <p class="eyebrow">欢迎回来</p><h2>登录工作台</h2><p class="muted">使用账号访问已授权的场站和设备。</p>
      <label>账号<input v-model="credentials.username" name="username" autocomplete="username" required placeholder="输入账号"></label>
      <label>密码<input v-model="credentials.password" name="password" type="password" autocomplete="current-password" required placeholder="输入密码"></label>
      <p v-if="error" role="alert" class="error">{{ error }}</p>
      <button class="primary login-button" :disabled="busy">{{ busy ? '登录中…' : '登录' }}</button>
      <div class="demo-hint">演示账号：platform_admin<br>演示密码：Demo123!<br>数据仅用于本机演示，重启服务后清空。</div>
    </form>
  </main>
  <div v-else class="workspace">
    <aside class="sidebar"><div class="wordmark"><span>ϟ</span>充电运营</div><p class="nav-caption">设施管理</p>
      <nav aria-label="主导航"><button v-for="item in resources" :key="item.key" :class="{ active: pageKey === item.key }" @click="navigate(item.key)">{{ item.title }}</button>
        <button v-if="admin" :class="{ active: pageKey === 'demo' }" @click="navigate('demo')">设备联调</button></nav>
      <div class="sidebar-bottom"><span class="online-dot"></span>本机演示环境<p>独立数据 · 重启清空</p></div>
    </aside>
    <section class="main-content"><header class="topbar"><span>场站与设施 / {{ resource?.title || '设备联调' }}</span><div class="account"><span>{{ account.roles.join(' / ') }}</span><button :disabled="busy" @click="signOut">退出登录</button></div></header>
      <div class="content"><div v-if="error" role="alert" class="error banner">{{ error }}</div><div v-if="notice" role="status" class="success banner">{{ notice }}</div>
        <template v-if="resource">
          <div class="page-heading"><div><p class="eyebrow">ASSET OPERATIONS</p><h1>{{ resource.title }}管理</h1><p class="muted">查看并维护授权范围内的{{ resource.title }}信息。</p></div><button v-if="canCreate" class="primary" @click="openForm()">新增{{ resource.title }}</button></div>
          <section class="panel"><form class="filters" @submit.prevent="filters.page = 1; load()"><label class="search-label">关键词<input v-model="filters.keyword" placeholder="输入关键词搜索"></label><label v-if="resource.status">状态<select v-model="filters.status"><option value="">全部状态</option><option v-for="status in resource.status" :key="status" :value="status">{{ display(status) }}</option></select></label><button class="primary" :disabled="loading">查询</button><button type="button" :disabled="loading" @click="load">刷新</button><span class="count">共 {{ total }} 条记录</span></form>
            <div class="table-scroll"><table><thead><tr><th v-for="key in resource.columns" :key="key">{{ labels[key] || key }}</th><th>操作</th></tr></thead><tbody>
              <tr v-if="loading"><td :colspan="resource.columns.length + 1" class="empty">正在加载…</td></tr>
              <tr v-else-if="!rows.length"><td :colspan="resource.columns.length + 1" class="empty">暂无记录，请调整查询条件或新增数据。</td></tr>
              <tr v-for="row in loading ? [] : rows" :key="row[resource.id]"><td v-for="key in resource.columns" :key="key"><span :class="{ badge: ['status', 'lifecycle_status', 'result'].includes(key), positive: ['active', 'idle', 'passed', 'approved', 'succeeded'].includes(row[key]) }">{{ display(row[key]) }}</span></td><td class="row-actions"><button :disabled="busy" @click="view(row)">详情</button><button v-if="admin && resource.editable" :disabled="busy" @click="openForm(row)">修改</button><button v-if="admin && pageKey === 'change-requests' && row.status === 'pending'" :disabled="busy" @click="openReview(row)">审批</button></td></tr>
            </tbody></table></div>
            <div class="pagination"><span>每页 {{ filters.page_size }} 条</span><button :disabled="filters.page <= 1 || loading" @click="filters.page--; load()">上一页</button><span>第 {{ filters.page }} / {{ Math.max(1, Math.ceil(total / filters.page_size)) }} 页</span><button :disabled="filters.page * filters.page_size >= total || loading" @click="filters.page++; load()">下一页</button></div>
          </section>
        </template>
        <template v-else>
          <div class="page-heading"><div><p class="eyebrow">DEVICE LAB</p><h1>设备联调</h1><p class="muted">使用模拟设备和模拟订单，检查完整的运行流程。</p></div></div>
          <div class="lab-grid"><section class="panel lab"><h2>01 / 凭据与通信</h2><p>先在设备验收页面完成四项验收，再签发凭据。首次恢复前，发送一次心跳，约35秒后再发送一次，形成正常采样窗口。</p><label>充电桩编号<input v-model="device.pileId" type="number" min="1"></label><button :disabled="busy" @click="issue">签发一小时凭据</button><label>设备凭据<input v-model="device.token" type="password" autocomplete="off" placeholder="签发后自动填入"></label><small v-if="device.expires">到期：{{ device.expires }}</small><div class="button-row"><button :disabled="busy || !device.token" @click="demoAction('heartbeat')">发送心跳</button><button :disabled="busy" @click="demoAction('recover')">复核恢复</button><button :disabled="busy" @click="demoAction('scan-offline')">扫描离线</button></div></section>
            <section class="panel lab"><h2>02 / 订单与设备命令</h2><p>设备恢复空闲后创建订单并占枪。点击“发送下一条命令”模拟设备接收和确认，之后可在设备命令页面检查结果。</p><label>充电枪编号<input v-model="device.gunId" type="number" min="1"></label><button :disabled="busy" @click="demoAction('start')">创建订单并启动</button><label>订单编号<input v-model="device.orderId" type="number" min="1" placeholder="创建后自动填入"></label><div class="button-row"><button :disabled="busy" @click="demoAction('finish')">结束订单</button><button class="primary" :disabled="busy" @click="demoAction('dispatch')">发送下一条命令</button></div></section></div>
          <section class="panel lab result"><h2>最近操作结果</h2><pre>{{ device.result || '尚未执行操作' }}</pre></section>
        </template>
      </div>
    </section>
    <div v-if="dialog" class="modal-backdrop"><section role="dialog" aria-modal="true" :aria-label="dialog === 'detail' ? '记录详情' : dialog === 'review' ? '审批申请' : dialog === 'edit' ? '修改记录' : '新增记录'" class="modal"><header><h2>{{ dialog === 'detail' ? '记录详情' : dialog === 'review' ? '审批申请' : (dialog === 'edit' ? '修改' : '新增') + resource.title }}</h2><button aria-label="关闭" :disabled="busy" @click="dialog = null">×</button></header>
      <div v-if="error" role="alert" class="error">{{ error }}</div>
      <dl v-if="dialog === 'detail'" class="details"><template v-for="(value, key) in selected" :key="key"><dt>{{ labels[key] || key }}</dt><dd>{{ display(value) }}</dd></template></dl>
      <form v-else-if="dialog === 'review'" @submit.prevent="review"><p class="muted">申请编号：{{ selected.request_id }}。批准后档案变更会立即生效；迁移和改造需要重新验收。</p><label>审批结果<select v-model="decision.decision"><option value="approved">批准</option><option value="rejected">驳回</option></select></label><label>审批意见<textarea v-model="decision.note" maxlength="500"></textarea></label><button class="primary" :disabled="busy">提交审批</button></form>
      <form v-else @submit.prevent="save"><p v-if="pageKey === 'change-requests'" class="form-help">只填写桩或枪中的一个目标编号。档案修改填写字段和新值，如 {"model_name":"DC-120"}；退役填写 {}。</p><div class="form-grid"><label v-for="f in formFields" :key="f.key" :class="{ checkbox: f.type === 'checkbox', wide: f.type === 'textarea' }"><template v-if="f.type !== 'checkbox'">{{ f.label }}</template><select v-if="f.type === 'select'" v-model="form[f.key]" :required="f.required !== false"><option v-for="option in f.options" :key="option" :value="option">{{ values[option] || option }}</option></select><textarea v-else-if="f.type === 'textarea'" v-model="form[f.key]" :required="f.required !== false" rows="3"></textarea><input v-else-if="f.type === 'checkbox'" v-model="form[f.key]" type="checkbox"><input v-else v-model="form[f.key]" :type="f.type" :step="f.type === 'number' ? 'any' : undefined" :required="f.required !== false"><template v-if="f.type === 'checkbox'">{{ f.label }}</template></label></div><div class="modal-footer"><button type="button" :disabled="busy" @click="dialog = null">取消</button><button class="primary" :disabled="busy">{{ busy ? '保存中…' : '保存' }}</button></div></form>
    </section></div>
  </div>
</template>
