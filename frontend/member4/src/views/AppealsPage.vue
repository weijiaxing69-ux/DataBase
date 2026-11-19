<script setup>
import { computed, onMounted, ref } from 'vue'
import { api, currentAccount } from '../api'

const account = currentAccount()
const permissions = new Set(account?.permissions || [])
const canCreate = computed(() => permissions.has('membership.appeal.create'))
const canHandle = computed(() => permissions.has('membership.appeal.manage'))
const items = ref([])
const selected = ref(null)
const detail = ref(null)
const form = ref({ category: 'billing_dispute', order_id: '', subject: '', description: '' })
const handleForm = ref({ status: 'processing', message: '' })
const loading = ref(false)
const busy = ref(false)
const error = ref('')
const toast = ref('')

function makeRequestKey() {
  return globalThis.crypto?.randomUUID?.() || `appeal_${Date.now()}_${Math.random().toString(36).slice(2)}`
}

const categoryLabels = { billing_dispute: '费用争议', charging_service: '充电服务', account_coupon: '账号或优惠券', other: '其他问题' }
const statusLabels = { submitted: '待受理', processing: '处理中', resolved: '已解决', rejected: '已驳回' }

async function load() {
  loading.value = true
  error.value = ''
  try {
    const result = await api.get('/api/v1/membership/appeals', { params: { page: 1, page_size: 50 } })
    items.value = result.items || []
    if (selected.value && items.value.some((item) => item.appeal_id === selected.value)) await openDetail(selected.value)
  } catch (err) { error.value = err.response?.data?.detail || '读取申诉记录失败。' }
  finally { loading.value = false }
}

async function submit() {
  error.value = ''
  toast.value = ''
  busy.value = true
  try {
    await api.post('/api/v1/membership/appeals', {
      category: form.value.category,
      order_id: form.value.order_id ? Number(form.value.order_id) : null,
      subject: form.value.subject.trim(),
      description: form.value.description.trim(),
      request_key: makeRequestKey(),
    })
    form.value = { category: 'billing_dispute', order_id: '', subject: '', description: '' }
    toast.value = '申诉已提交，可在列表中查看处理进度。'
    await load()
  } catch (err) { error.value = err.response?.data?.detail || '提交申诉失败。' }
  finally { busy.value = false }
}

async function openDetail(id) {
  selected.value = id
  error.value = ''
  try { detail.value = await api.get(`/api/v1/membership/appeals/${id}`) }
  catch (err) { error.value = err.response?.data?.detail || '读取申诉详情失败。' }
}

async function handle() {
  if (!selected.value || !handleForm.value.message.trim()) return
  error.value = ''
  busy.value = true
  try {
    await api.post(`/api/v1/membership/appeals/${selected.value}/actions`, {
      status: handleForm.value.status, message: handleForm.value.message.trim(),
    })
    handleForm.value = { status: 'processing', message: '' }
    toast.value = '处理记录已保存。'
    await load()
  } catch (err) { error.value = err.response?.data?.detail || '保存处理记录失败。' }
  finally { busy.value = false }
}

onMounted(load)
</script>

<template>
  <div class="page-heading"><div><p class="eyebrow">MEMBERSHIP · SUPPORT</p><h1>服务申诉跟踪</h1><p class="page-description">会员可提交费用或服务问题；客服记录受理状态和回复，处理过程会保留时间线。</p></div><button class="button button-quiet" :disabled="loading" @click="load">刷新</button></div>
  <section v-if="canCreate" class="action-card"><div class="action-heading"><div><span class="mini-label">会员自助</span><h2>提交服务申诉</h2></div><span class="action-symbol">✉</span></div><form class="form-grid" @submit.prevent="submit"><label>问题类型<select v-model="form.category"><option value="billing_dispute">费用争议</option><option value="charging_service">充电服务</option><option value="account_coupon">账号或优惠券</option><option value="other">其他问题</option></select></label><label>关联订单编号（选填）<input v-model="form.order_id" type="number" min="1" placeholder="只填写本人订单" /></label><label>问题标题<input v-model.trim="form.subject" minlength="3" maxlength="120" required placeholder="例如：对本次服务费有疑问" /></label><label class="wide-field">问题说明<textarea v-model.trim="form.description" minlength="5" maxlength="2000" rows="3" required placeholder="请描述遇到的问题及希望平台协助的事项" /></label><div class="form-submit"><button class="button button-primary" :disabled="busy">{{ busy ? '处理中…' : '提交申诉' }} <span>→</span></button></div></form></section>
  <div v-if="toast" class="notice notice-success">{{ toast }}</div><div v-if="error" class="notice notice-error"><strong>请求未完成</strong><span>{{ error }}</span></div>
  <section class="data-card"><div class="data-toolbar"><div><span class="mini-label">申诉记录</span><p>共 {{ items.length }} 条记录</p></div></div>
    <div v-if="loading" class="empty-state"><div class="loading-ring"></div><p>正在加载…</p></div>
    <div v-else-if="items.length" class="table-scroll"><table><thead><tr><th>编号</th><th v-if="canHandle">会员编号</th><th>类型</th><th>标题</th><th>关联订单</th><th>状态</th><th>最近回复</th><th>提交时间</th><th>详情</th></tr></thead><tbody><tr v-for="row in items" :key="row.appeal_id"><td>#{{ row.appeal_id }}</td><td v-if="canHandle">#{{ row.user_id }}</td><td>{{ categoryLabels[row.category] || row.category }}</td><td class="wrap-cell">{{ row.subject }}</td><td>{{ row.order_id ? `#${row.order_id}` : '—' }}</td><td><span class="status-pill" :class="`status-${row.status}`">{{ statusLabels[row.status] || row.status }}</span></td><td class="wrap-cell">{{ row.last_response || '—' }}</td><td>{{ row.created_at }}</td><td><button class="text-button" @click="openDetail(row.appeal_id)">{{ selected === row.appeal_id ? '已打开' : '查看处理记录' }}</button></td></tr></tbody></table></div>
    <div v-else class="empty-state"><span class="empty-icon">⌕</span><p>还没有申诉记录</p><small>提交后可在这里跟踪进度。</small></div>
  </section>
  <section v-if="detail" class="action-card appeal-detail"><div class="action-heading"><div><span class="mini-label">申诉 #{{ detail.appeal.appeal_id }}</span><h2>{{ detail.appeal.subject }}</h2></div><button class="button button-quiet" @click="detail = null; selected = null">收起</button></div><p class="appeal-description">{{ detail.appeal.description }}</p><div class="appeal-timeline"><div v-for="event in detail.events" :key="event.appeal_event_id" class="appeal-event"><span class="timeline-dot"></span><div><strong>{{ statusLabels[event.to_status] || event.to_status }}</strong><p>{{ event.message }}</p><small>{{ event.created_at }} · 账号 #{{ event.actor_account_id }}</small></div></div></div><form v-if="canHandle && !['resolved', 'rejected'].includes(detail.appeal.status)" class="form-grid appeal-handler" @submit.prevent="handle"><label>更新状态<select v-model="handleForm.status"><option value="processing">处理中</option><option value="resolved">已解决</option><option value="rejected">已驳回</option></select></label><label class="wide-field">客服回复<textarea v-model.trim="handleForm.message" minlength="2" maxlength="1000" rows="2" required placeholder="记录处理进展或给会员的答复" /></label><div class="form-submit"><button class="button button-primary" :disabled="busy">保存处理记录</button></div></form></section>
</template>
