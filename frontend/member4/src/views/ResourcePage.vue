<script setup>
import { computed, onMounted, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { api, currentAccount } from '../api'

const route = useRoute()
const router = useRouter()
const account = currentAccount()
const rows = ref([])
const detail = ref(null)
const roleDetail = ref(null)
const page = ref(1)
const pageSize = 15
const total = ref(0)
const loading = ref(false)
const error = ref('')
const toast = ref('')
const busy = ref(false)
const search = ref('')
const form = ref({ mode: 'create' })

const configs = {
  profile: { endpoint: '/api/v1/membership/profile', object: true, description: '查看并维护当前登录车主的会员信息。敏感联系信息仅以脱敏形式显示。', action: 'profile' },
  vehicles: { endpoint: '/api/v1/membership/vehicles', description: '管理本人名下车辆。车辆绑定记录保留历史，车牌只展示脱敏值。', action: 'vehicle' },
  coupons: { endpoint: '/api/v1/membership/coupons', description: '优惠券状态由服务端维护；锁定、核销和退款补发均与订单事务联动。' },
  promotions: { endpoint: '/api/v1/membership/promotions', description: '管理活动、审核申请、定向发券或领取当前可用的个人优惠券。领取次数和有效期由后端校验。', action: 'promotion-admin' },
  fleets: { endpoint: '/api/v1/membership/fleets', description: '按当前账号权限和车队数据范围查询企业车队。', detail: true, action: 'fleet-admin' },
  'fleet-detail': { object: true, description: '车队基础信息。联系人电话按接口返回值脱敏。' },
  'fleet-cards': { endpoint: '/api/v1/membership/fleet-cards', description: '查看、登记或更新当前车队范围内的车队卡。', action: 'fleet-card-admin' },
  'fleet-authorizations': { endpoint: '/api/v1/membership/fleet-authorizations', description: '创建和维护用车授权，并设置授权人的月额度。', action: 'authorization-admin' },
  wallet: { endpoint: '/api/v1/membership/wallet/transactions', description: '钱包流水只读展示。模拟充值仅在开发环境开放。', action: 'topup' },
  feedbacks: { endpoint: '/api/v1/membership/feedbacks', description: '查看服务评价；仅本人已付清订单可以新增评价。', action: 'feedback' },
  accounts: { endpoint: '/api/v1/auth/accounts', description: '创建平台账号、分配角色与运营商/场站/车队数据范围。', action: 'account-admin' },
  roles: { endpoint: '/api/v1/auth/roles', description: '查看平台固定角色和权限清单。角色和权限的最终检查始终由服务端执行。', action: 'role-details' },
}

const config = computed(() => configs[route.meta.resource] || {})
const title = computed(() => route.meta.title || '会员服务')
const actionTitle = computed(() => ({
  profile: '更新个人资料', vehicle: '绑定车辆', topup: '开发环境模拟充值', feedback: '提交订单评价',
  'account-admin': '账号维护', 'promotion-admin': '创建活动', 'fleet-admin': '车队维护',
  'fleet-card-admin': '车队卡维护', 'authorization-admin': '授权与额度维护',
}[config.value.action] || '快捷操作'))
const pageCount = computed(() => Math.max(1, Math.ceil(total.value / pageSize)))
const columns = computed(() => rows.value.length ? Object.keys(rows.value[0]).filter((key) => !isSensitive(key)) : [])
const allowedActions = computed(() => new Set(account?.permissions || []))
const showAction = computed(() => {
  const required = {
    profile: 'membership.profile.update', vehicle: 'membership.vehicle.manage',
    topup: 'membership.wallet.topup', feedback: 'membership.feedback.create',
    'account-admin': 'auth.account.manage', 'promotion-admin': 'membership.promotion.manage',
    'fleet-admin': 'membership.fleet.manage', 'fleet-card-admin': 'membership.fleet_card.manage',
    'authorization-admin': 'membership.fleet_authorization.manage', 'role-details': 'auth.role.read',
  }[config.value.action]
  return Boolean(required && allowedActions.value.has(required) && config.value.action !== 'role-details')
})

const labels = {
  account_id: '账号编号', username: '登录名', status: '状态', failed_attempts: '失败次数', locked_until: '锁定截止', last_login_at: '最近登录', created_at: '创建时间',
  user_id: '用户编号', display_name: '显示姓名', real_name_status: '实名状态', registration_channel: '注册来源', registered_at: '注册时间', member_level: '会员等级', balance: '余额', phone_masked: '手机号',
  vehicle_id: '车辆编号', model_name: '车型', battery_capacity_kwh: '电池容量 kWh', max_charging_power_kw: '最大功率 kW', supports_fast_charge: '支持快充', plate_masked: '车牌',
  promotion_id: '活动编号', promotion_name: '活动名称', face_amount: '优惠金额', minimum_spend: '使用门槛', valid_from: '开始时间', valid_until: '截止时间', issue_limit: '发放上限', issued_count: '已发数量', per_user_limit: '每人上限', all_stations: '适用全部场站', redemption_rule: '使用规则',
  coupon_id: '优惠券编号', received_at: '领取时间', expires_at: '有效期至', face_amount_snapshot: '券面额', minimum_spend_snapshot: '使用门槛',
  fleet_id: '车队编号', company_name: '企业名称', credit_code: '统一信用代码', contact_name: '联系人', phone_masked: '联系电话',
  card_id: '卡编号', card_no: '卡号', issued_at: '发卡时间',
  authorization_id: '授权编号', default_monthly_limit: '月默认额度',
  wallet_transaction_id: '流水编号', transaction_type: '变动类型', amount: '变动金额', balance_after: '变动后余额', business_key: '业务键', occurred_at: '发生时间',
  feedback_id: '评价编号', order_id: '订单编号', rating: '评分', content: '评价内容',
  role_id: '角色编号', role_code: '角色代码', role_name: '角色名称',
}

function isSensitive(key) {
  return /cipher|_hash|password|jti|token/i.test(key)
}
function fieldLabel(key) { return labels[key] || key }
function display(value) {
  if (value === null || value === undefined || value === '') return '—'
  if (typeof value === 'boolean' || value === 0 || value === 1) {
    if (typeof value === 'boolean') return value ? '是' : '否'
  }
  if (typeof value === 'object') return JSON.stringify(value)
  return String(value)
}
function idOf(row) { return row.fleet_id || row.promotion_id || row.account_id || row.authorization_id }

async function load() {
  loading.value = true
  error.value = ''
  detail.value = null
  try {
    const resource = route.meta.resource
    if (resource === 'fleet-detail') {
      detail.value = await api.get(`/api/v1/membership/fleets/${route.params.fleetId}`)
    } else if (config.value.object) {
      detail.value = await api.get(config.value.endpoint)
    } else {
      const params = { page: page.value, page_size: pageSize }
      if (search.value.trim()) params.keyword = search.value.trim()
      const result = await api.get(config.value.endpoint, { params })
      rows.value = result.items || []
      total.value = result.total || 0
    }
  } catch (err) {
    error.value = err.response?.data?.error?.message || '读取数据失败，请确认服务已启动并检查访问权限。'
  } finally { loading.value = false }
}

async function submitForm() {
  error.value = ''
  toast.value = ''
  busy.value = true
  try {
    let message = '操作已完成。'
    if (config.value.action === 'profile') {
      await api.patch('/api/v1/membership/profile', Object.fromEntries(['display_name', 'phone'].map((key) => [key, form.value[key]]).filter(([, value]) => value !== '' && value != null)))
      message = '个人档案已更新。'
    } else if (config.value.action === 'vehicle') {
      const payload = form.value.vehicle_id
        ? { vehicle_id: Number(form.value.vehicle_id) }
        : { plate: form.value.plate, model_name: form.value.model_name,
            battery_capacity_kwh: Number(form.value.battery_capacity_kwh),
            max_charging_power_kw: Number(form.value.max_charging_power_kw),
            supports_fast_charge: Boolean(form.value.supports_fast_charge) }
      await api.post('/api/v1/membership/vehicle-bindings', payload)
      message = '车辆绑定已创建。'
    } else if (config.value.action === 'topup') {
      await api.post('/api/v1/membership/wallet/topups', { amount: Number(form.value.amount) })
      message = '模拟充值已记入钱包流水。'
    } else if (config.value.action === 'feedback') {
      await api.post('/api/v1/membership/feedbacks', { order_id: Number(form.value.order_id), rating: Number(form.value.rating), content: form.value.content || null })
      message = '服务评价已提交。'
    } else if (config.value.action === 'account-admin') {
      if (form.value.mode === 'roles') {
        await api.put(`/api/v1/auth/accounts/${Number(form.value.account_id)}/roles`, {
          role_codes: form.value.role_codes.split(',').map((role) => role.trim()).filter(Boolean),
        })
        message = '账号角色已更新，旧登录会话已撤销。'
      } else if (form.value.mode === 'scopes') {
        const ids = (value) => (value || '').split(',').map((item) => Number(item.trim())).filter((item) => Number.isInteger(item) && item > 0)
        await api.put(`/api/v1/auth/accounts/${Number(form.value.account_id)}/scopes`, {
          operator_ids: ids(form.value.operator_ids), station_ids: ids(form.value.station_ids), fleet_ids: ids(form.value.fleet_ids),
        })
        message = '账号数据范围已更新，旧登录会话已撤销。'
      } else {
        await api.post('/api/v1/auth/accounts', {
          username: form.value.username,
          password: form.value.password,
          role_codes: form.value.role_codes.split(',').map((role) => role.trim()).filter(Boolean),
        })
        message = '平台账号已创建。'
      }
    } else if (config.value.action === 'promotion-admin') {
      await api.post('/api/v1/membership/promotions', {
        promotion_name: form.value.promotion_name,
        face_amount: Number(form.value.face_amount),
        minimum_spend: Number(form.value.minimum_spend || 0),
        valid_from: form.value.valid_from,
        valid_until: form.value.valid_until,
        issue_limit: Number(form.value.issue_limit),
        per_user_limit: Number(form.value.per_user_limit || 1),
        all_stations: Boolean(form.value.all_stations),
        redemption_rule: form.value.redemption_rule || '个人订单满额抵扣',
        station_ids: (form.value.station_ids || '').split(',').map((item) => Number(item.trim())).filter((item) => Number.isInteger(item) && item > 0),
      })
      message = '活动已提交审核。'
    } else if (config.value.action === 'fleet-admin') {
      const payload = Object.fromEntries(Object.entries({
        company_name: form.value.company_name, credit_code: form.value.credit_code,
        contact_name: form.value.contact_name, contact_phone: form.value.contact_phone,
        status: form.value.status || undefined,
      }).filter(([, value]) => value !== '' && value != null))
      if (form.value.mode === 'update') {
        delete payload.credit_code
        await api.patch(`/api/v1/membership/fleets/${Number(form.value.fleet_id)}`, payload)
        message = '车队信息已更新。'
      } else {
        await api.post('/api/v1/membership/fleets', payload)
        message = '车队已创建。'
      }
    } else if (config.value.action === 'fleet-card-admin') {
      if (form.value.mode === 'update') {
        await api.patch(`/api/v1/membership/fleet-cards/${Number(form.value.card_id)}`, {
          status: form.value.status || undefined, valid_until: form.value.valid_until || undefined,
        })
        message = '车队卡状态已更新。'
      } else {
        await api.post('/api/v1/membership/fleet-cards', {
          fleet_id: Number(form.value.fleet_id), card_no: form.value.card_no,
          valid_from: form.value.valid_from, valid_until: form.value.valid_until,
        })
        message = '车队卡已登记。'
      }
    } else if (config.value.action === 'authorization-admin') {
      if (form.value.mode === 'quota') {
        await api.put(`/api/v1/membership/fleet-authorizations/${Number(form.value.authorization_id)}/quotas/${form.value.bill_month}`, { limit_amount: Number(form.value.limit_amount) })
        message = '月额度已保存。'
      } else if (form.value.mode === 'update') {
        await api.patch(`/api/v1/membership/fleet-authorizations/${Number(form.value.authorization_id)}`, {
          status: form.value.status || undefined,
          valid_until: form.value.valid_until || undefined,
          default_monthly_limit: form.value.default_monthly_limit ? Number(form.value.default_monthly_limit) : undefined,
        })
        message = '车队授权已更新。'
      } else {
        await api.post('/api/v1/membership/fleet-authorizations', {
          card_id: Number(form.value.card_id), user_id: Number(form.value.user_id), vehicle_id: Number(form.value.vehicle_id),
          default_monthly_limit: Number(form.value.default_monthly_limit), valid_from: form.value.valid_from, valid_until: form.value.valid_until,
        })
        message = '用车授权已创建。'
      }
    }
    form.value = { mode: 'create' }
    toast.value = message
    await load()
  } catch (err) {
    error.value = err.response?.data?.error?.message || '操作失败，请检查输入和权限。'
  } finally { busy.value = false }
}

async function claim(row) {
  error.value = ''
  try {
    await api.post(`/api/v1/membership/promotions/${row.promotion_id}/claims`, {})
    toast.value = `已领取「${row.promotion_name}」。`
  } catch (err) {
    error.value = err.response?.data?.error?.message || '领取失败。'
  }
}

async function reviewPromotion(row, decision) {
  error.value = ''
  try {
    await api.post(`/api/v1/membership/promotions/${row.promotion_id}/reviews`, {
      decision, note: decision === 'approved' ? '审核通过' : '审核驳回',
    })
    toast.value = `活动「${row.promotion_name}」已${decision === 'approved' ? '通过审核' : '驳回'}。`
    await load()
  } catch (err) { error.value = err.response?.data?.error?.message || '审核失败。' }
}

async function issueCoupons(row) {
  const raw = window.prompt('输入需要发券的用户编号，多个编号用英文逗号分隔：')
  if (!raw) return
  const user_ids = raw.split(',').map((item) => Number(item.trim())).filter((item) => Number.isInteger(item) && item > 0)
  if (!user_ids.length) { error.value = '请至少输入一个有效用户编号。'; return }
  try {
    await api.post(`/api/v1/membership/promotions/${row.promotion_id}/issues`, { user_ids, reason: '平台定向发券' })
    toast.value = `已向 ${user_ids.length} 个用户提交定向发券。`
  } catch (err) { error.value = err.response?.data?.error?.message || '发券失败。' }
}

async function showRole(row) {
  error.value = ''
  try { roleDetail.value = await api.get(`/api/v1/auth/roles/${row.role_id}`) }
  catch (err) { error.value = err.response?.data?.error?.message || '读取角色权限失败。' }
}

function openFleet(row) { router.push(`/membership/fleets/${row.fleet_id}`) }
function movePage(direction) { page.value = Math.min(pageCount.value, Math.max(1, page.value + direction)); load() }

watch(() => route.fullPath, () => { page.value = 1; load() })
onMounted(load)
</script>

<template>
  <div class="page-heading"><div><p class="eyebrow">MEMBERSHIP · V1.4</p><h1>{{ title }}</h1><p class="page-description">{{ config.description }}</p></div><button v-if="route.name === 'fleet-detail'" class="button button-quiet" @click="router.push('/membership/fleets')">← 返回车队列表</button></div>

  <div v-if="showAction" class="action-card">
    <div class="action-heading"><div><span class="mini-label">快捷操作</span><h2>{{ actionTitle }}</h2></div><span class="action-symbol">✦</span></div>
    <form class="form-grid" @submit.prevent="submitForm">
      <template v-if="config.action === 'profile'">
        <label>显示姓名<input v-model.trim="form.display_name" maxlength="50" placeholder="留空表示不修改" /></label><label>手机号<input v-model.trim="form.phone" maxlength="20" placeholder="留空表示不修改" /></label>
      </template>
      <template v-else-if="config.action === 'vehicle'">
        <label>已登记车辆编号<input v-model="form.vehicle_id" inputmode="numeric" placeholder="已有车辆填编号；新车请填右侧车辆信息" /></label><label>车牌<input v-model.trim="form.plate" placeholder="新车必填" /></label><label>车型<input v-model.trim="form.model_name" placeholder="例如：纯电 SUV" /></label><label>电池容量 kWh<input v-model="form.battery_capacity_kwh" type="number" min="0.1" step="0.001" placeholder="例如：72" /></label><label>最大充电功率 kW<input v-model="form.max_charging_power_kw" type="number" min="0.1" step="0.001" placeholder="例如：120" /></label><label class="check-label"><input v-model="form.supports_fast_charge" type="checkbox" /> 支持快充</label>
      </template>
      <template v-else-if="config.action === 'topup'"><label>充值金额（元）<input v-model="form.amount" type="number" min="0.01" step="0.01" required placeholder="仅开发环境可用" /></label></template>
      <template v-else-if="config.action === 'feedback'"><label>已付清订单编号<input v-model="form.order_id" type="number" min="1" required placeholder="输入订单编号" /></label><label>评分<select v-model="form.rating"><option value="">请选择</option><option v-for="rating in [5,4,3,2,1]" :key="rating" :value="rating">{{ rating }} 分</option></select></label><label class="wide-field">评价内容<textarea v-model.trim="form.content" maxlength="1000" rows="2" placeholder="分享您的服务体验（选填）" /></label></template>
      <template v-else-if="config.action === 'account-admin'">
        <label>操作类型<select v-model="form.mode"><option value="create">创建账号</option><option value="roles">分配角色</option><option value="scopes">分配资源范围</option></select></label>
        <template v-if="form.mode === 'roles'"><label>账号编号<input v-model="form.account_id" type="number" min="1" required /></label><label>角色代码（英文逗号分隔）<input v-model.trim="form.role_codes" placeholder="customer_service" required /></label></template>
        <template v-else-if="form.mode === 'scopes'"><label>账号编号<input v-model="form.account_id" type="number" min="1" required /></label><label>运营商编号（逗号分隔）<input v-model.trim="form.operator_ids" placeholder="留空清除该范围" /></label><label>场站编号（逗号分隔）<input v-model.trim="form.station_ids" placeholder="留空清除该范围" /></label><label>车队编号（逗号分隔）<input v-model.trim="form.fleet_ids" placeholder="留空清除该范围" /></label></template>
        <template v-else><label>登录账号<input v-model.trim="form.username" minlength="3" required /></label><label>初始密码<input v-model="form.password" minlength="10" type="password" required /></label><label>角色代码（逗号分隔）<input v-model.trim="form.role_codes" placeholder="customer_service" required /></label></template>
      </template>
      <template v-else-if="config.action === 'promotion-admin'">
        <label>活动名称<input v-model.trim="form.promotion_name" maxlength="100" required /></label><label>优惠金额（元）<input v-model="form.face_amount" type="number" min="0.01" step="0.01" required /></label><label>最低消费（元）<input v-model="form.minimum_spend" type="number" min="0" step="0.01" value="0" /></label><label>开始时间（UTC）<input v-model="form.valid_from" type="datetime-local" required /></label><label>截止时间（UTC）<input v-model="form.valid_until" type="datetime-local" required /></label><label>发放总量<input v-model="form.issue_limit" type="number" min="1" required /></label><label>每人领取上限<input v-model="form.per_user_limit" type="number" min="1" value="1" required /></label><label>使用规则<input v-model.trim="form.redemption_rule" maxlength="500" placeholder="个人订单满额抵扣" /></label><label class="check-label"><input v-model="form.all_stations" type="checkbox" /> 适用于全部场站</label><label v-if="!form.all_stations">适用场站编号<input v-model.trim="form.station_ids" placeholder="多个编号用逗号分隔" /></label>
      </template>
      <template v-else-if="config.action === 'fleet-admin'">
        <label>操作类型<select v-model="form.mode"><option value="create">创建车队</option><option value="update">更新车队</option></select></label><label v-if="form.mode === 'update'">车队编号<input v-model="form.fleet_id" type="number" min="1" required /></label><label>企业名称<input v-model.trim="form.company_name" maxlength="100" :required="form.mode === 'create'" /></label><label v-if="form.mode === 'create'">统一社会信用代码<input v-model.trim="form.credit_code" maxlength="18" required /></label><label>联系人<input v-model.trim="form.contact_name" maxlength="50" :required="form.mode === 'create'" /></label><label>联系人手机号<input v-model.trim="form.contact_phone" maxlength="20" :required="form.mode === 'create'" /></label><label v-if="form.mode === 'update'">状态<select v-model="form.status"><option value="">不修改</option><option value="active">启用</option><option value="disabled">停用</option></select></label>
      </template>
      <template v-else-if="config.action === 'fleet-card-admin'">
        <label>操作类型<select v-model="form.mode"><option value="create">登记车队卡</option><option value="update">更新车队卡</option></select></label><template v-if="form.mode === 'create'"><label>车队编号<input v-model="form.fleet_id" type="number" min="1" required /></label><label>卡号<input v-model.trim="form.card_no" maxlength="64" required /></label><label>生效时间（UTC）<input v-model="form.valid_from" type="datetime-local" required /></label><label>截止时间（UTC）<input v-model="form.valid_until" type="datetime-local" required /></label></template><template v-else><label>卡编号<input v-model="form.card_id" type="number" min="1" required /></label><label>状态<select v-model="form.status"><option value="">不修改</option><option value="active">启用</option><option value="suspended">暂停</option><option value="expired">过期</option></select></label><label>截止时间（UTC）<input v-model="form.valid_until" type="datetime-local" /></label></template>
      </template>
      <template v-else-if="config.action === 'authorization-admin'">
        <label>操作类型<select v-model="form.mode"><option value="create">创建授权</option><option value="update">更新授权</option><option value="quota">设置月额度</option></select></label>
        <template v-if="form.mode === 'create'"><label>车队卡编号<input v-model="form.card_id" type="number" min="1" required /></label><label>用户编号<input v-model="form.user_id" type="number" min="1" required /></label><label>车辆编号<input v-model="form.vehicle_id" type="number" min="1" required /></label><label>默认月额度（元）<input v-model="form.default_monthly_limit" type="number" min="0" step="0.01" required /></label><label>授权开始（UTC）<input v-model="form.valid_from" type="datetime-local" required /></label><label>授权截止（UTC）<input v-model="form.valid_until" type="datetime-local" required /></label></template>
        <template v-else-if="form.mode === 'update'"><label>授权编号<input v-model="form.authorization_id" type="number" min="1" required /></label><label>状态<select v-model="form.status"><option value="">不修改</option><option value="active">启用</option><option value="suspended">暂停</option><option value="expired">过期</option></select></label><label>有效期至（UTC）<input v-model="form.valid_until" type="datetime-local" /></label><label>默认月额度<input v-model="form.default_monthly_limit" type="number" min="0" step="0.01" /></label></template>
        <template v-else><label>授权编号<input v-model="form.authorization_id" type="number" min="1" required /></label><label>账期（YYYY-MM）<input v-model="form.bill_month" type="month" required /></label><label>月额度（元）<input v-model="form.limit_amount" type="number" min="0" step="0.01" required /></label></template>
      </template>
      <div class="form-submit"><button class="button button-primary" :disabled="busy">{{ busy ? '处理中…' : '提交' }} <span>→</span></button></div>
    </form>
  </div>

  <div v-if="toast" class="notice notice-success">{{ toast }}</div>
  <div v-if="error" class="notice notice-error"><strong>请求未完成</strong><span>{{ error }}</span></div>

  <section class="data-card">
    <div class="data-toolbar"><div><span class="mini-label">数据列表</span><p>{{ config.object ? '当前记录' : `共 ${total} 条记录` }}</p></div><div v-if="!config.object" class="search-box"><input v-model="search" placeholder="关键词筛选" @keyup.enter="page = 1; load()" /><button class="button button-quiet" @click="page = 1; load()">查询</button></div></div>
    <div v-if="roleDetail" class="role-detail"><div><span class="mini-label">角色权限</span><strong>{{ roleDetail.role_name }} · {{ roleDetail.role_code }}</strong></div><button class="button button-quiet" @click="roleDetail = null">关闭</button><div class="permission-chips"><code v-for="permission in roleDetail.permissions" :key="permission">{{ permission }}</code></div></div>
    <div v-if="loading" class="empty-state"><div class="loading-ring"></div><p>正在加载…</p></div>
    <div v-else-if="config.object">
      <div v-if="detail" class="detail-grid"><div v-for="(value, key) in detail" v-show="!isSensitive(key)" :key="key" class="detail-item"><span>{{ fieldLabel(key) }}</span><strong>{{ display(value) }}</strong></div></div>
      <div v-else class="empty-state"><span class="empty-icon">⌕</span><p>暂无可显示的记录。</p></div>
    </div>
    <div v-else-if="rows.length" class="table-scroll"><table><thead><tr><th v-for="column in columns" :key="column">{{ fieldLabel(column) }}</th><th v-if="config.detail || ['promotions', 'roles'].includes(route.meta.resource)">操作</th></tr></thead><tbody><tr v-for="row in rows" :key="row[columns[0]]"><td v-for="column in columns" :key="column">{{ display(row[column]) }}</td><td v-if="config.detail"><button class="text-button" @click="openFleet(row)">查看详情 ↗</button></td><td v-else-if="route.meta.resource === 'promotions'" class="row-actions"><template v-if="row.status === 'active'"><button v-if="allowedActions.has('membership.coupon.claim')" class="text-button" @click="claim(row)">领取优惠券</button><button v-if="allowedActions.has('membership.coupon.issue')" class="text-button" @click="issueCoupons(row)">定向发放</button></template><template v-else-if="row.status === 'pending_review'"><button v-if="allowedActions.has('membership.promotion.review')" class="text-button" @click="reviewPromotion(row, 'approved')">审核通过</button><button v-if="allowedActions.has('membership.promotion.review')" class="text-button text-danger" @click="reviewPromotion(row, 'rejected')">驳回</button></template><span v-if="!allowedActions.has('membership.coupon.claim') && !allowedActions.has('membership.coupon.issue') && !allowedActions.has('membership.promotion.review')" class="muted">—</span></td><td v-else-if="route.meta.resource === 'roles'"><button v-if="allowedActions.has('auth.role.read')" class="text-button" @click="showRole(row)">查看权限 ↗</button></td></tr></tbody></table></div>
    <div v-else class="empty-state"><span class="empty-icon">⌕</span><p>当前条件下没有记录</p><small>清除关键词或调整筛选条件后重试。</small></div>
    <footer v-if="!config.object" class="pagination"><span>第 {{ page }} / {{ pageCount }} 页</span><div><button class="button button-quiet" :disabled="page <= 1" @click="movePage(-1)">上一页</button><button class="button button-quiet" :disabled="page >= pageCount" @click="movePage(1)">下一页</button></div></footer>
  </section>
</template>
