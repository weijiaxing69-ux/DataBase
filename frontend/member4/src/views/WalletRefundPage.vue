<script setup>
import { computed, onMounted, ref } from 'vue'
import { api, currentAccount } from '../api'

const account = currentAccount()
const permissions = new Set(account?.permissions || [])
const canRequest = computed(() => permissions.has('membership.wallet.refund.request'))
const canReview = computed(() => permissions.has('membership.wallet.refund.review'))
const items = ref([])
const walletSummary = ref(null)
const form = ref({ amount: '', reason: '' })
const requestKey = ref(makeRequestKey())
const loading = ref(false)
const busy = ref(false)
const error = ref('')
const toast = ref('')

function makeRequestKey() {
  return globalThis.crypto?.randomUUID?.() || `refund_${Date.now()}_${Math.random().toString(36).slice(2)}`
}

const statusLabels = { pending_review: '待审核', processing: '处理中', completed: '已完成', rejected: '已拒绝' }

async function load() {
  loading.value = true
  error.value = ''
  try {
    const result = await api.get('/api/v1/membership/wallet/refund-requests', { params: { page: 1, page_size: 50 } })
    items.value = result.items || []
    walletSummary.value = result.available_balance == null ? null : result
  } catch (err) { error.value = err.response?.data?.detail || '读取退款申请失败。' }
  finally { loading.value = false }
}

async function submit() {
  error.value = ''
  toast.value = ''
  busy.value = true
  try {
    await api.post('/api/v1/membership/wallet/refund-requests', {
      amount: Number(form.value.amount), reason: form.value.reason.trim(), request_key: requestKey.value,
    })
    form.value = { amount: '', reason: '' }
    requestKey.value = makeRequestKey()
    toast.value = '退款申请已提交，审核完成前该金额会暂时占用可用余额。'
    await load()
  } catch (err) { error.value = err.response?.data?.detail || '提交退款申请失败。' }
  finally { busy.value = false }
}

async function review(row, decision) {
  error.value = ''
  toast.value = ''
  const note = decision === 'approved'
    ? '审核通过，模拟退款已完成。'
    : decision === 'processing'
      ? '已受理，正在核对退款信息。'
      : window.prompt('请填写驳回原因：')
  if (decision === 'rejected' && !note?.trim()) return
  busy.value = true
  try {
    await api.post(`/api/v1/membership/wallet/refund-requests/${row.refund_request_id}/review`, { decision, note: note?.trim() || null })
    toast.value = decision === 'approved' ? '申请已通过，退款流水已记入钱包。' : decision === 'processing' ? '申请已受理，预留金额保持不变。' : '申请已驳回，预留余额已释放。'
    await load()
  } catch (err) { error.value = err.response?.data?.detail || '处理退款申请失败。' }
  finally { busy.value = false }
}

onMounted(load)
</script>

<template>
  <div class="page-heading"><div><p class="eyebrow">MEMBERSHIP · WALLET</p><h1>余额退款申请</h1><p class="page-description">申请退还未使用余额，并查看审核进度。课程演示只在开发环境模拟退款。</p></div><button class="button button-quiet" :disabled="loading" @click="load">刷新</button></div>
  <div v-if="walletSummary" class="refund-summary"><div><span>钱包余额</span><strong>¥{{ Number(walletSummary.balance).toFixed(2) }}</strong></div><div><span>待处理金额</span><strong>¥{{ Number(walletSummary.reserved_amount).toFixed(2) }}</strong></div><div><span>可申请余额</span><strong>¥{{ Number(walletSummary.available_balance).toFixed(2) }}</strong></div></div>
  <section v-if="canRequest" class="action-card"><div class="action-heading"><div><span class="mini-label">会员自助</span><h2>提交退款申请</h2></div><span class="action-symbol">↗</span></div><form class="form-grid" @submit.prevent="submit"><label>申请金额（元）<input v-model="form.amount" type="number" min="0.01" step="0.01" :max="walletSummary?.available_balance" required /></label><label class="wide-field">申请原因<textarea v-model.trim="form.reason" rows="2" minlength="3" maxlength="500" required placeholder="请说明申请退还未使用余额的原因" /></label><div class="form-submit"><button class="button button-primary" :disabled="busy">{{ busy ? '处理中…' : '提交申请' }} <span>→</span></button></div></form></section>
  <div v-if="toast" class="notice notice-success">{{ toast }}</div><div v-if="error" class="notice notice-error"><strong>请求未完成</strong><span>{{ error }}</span></div>
  <section class="data-card"><div class="data-toolbar"><div><span class="mini-label">申请记录</span><p>共 {{ items.length }} 条记录</p></div></div>
    <div v-if="loading" class="empty-state"><div class="loading-ring"></div><p>正在加载…</p></div>
    <div v-else-if="items.length" class="table-scroll"><table><thead><tr><th>申请编号</th><th v-if="canReview">会员编号</th><th>金额</th><th>原因</th><th>状态</th><th>提交时间</th><th>审核说明</th><th v-if="canReview">处理</th></tr></thead><tbody><tr v-for="row in items" :key="row.refund_request_id"><td>#{{ row.refund_request_id }}</td><td v-if="canReview">#{{ row.user_id }}</td><td>¥{{ Number(row.amount).toFixed(2) }}</td><td class="wrap-cell">{{ row.reason }}</td><td><span class="status-pill" :class="`status-${row.status}`">{{ statusLabels[row.status] || row.status }}</span></td><td>{{ row.created_at }}</td><td class="wrap-cell">{{ row.review_note || '—' }}</td><td v-if="canReview && ['pending_review', 'processing'].includes(row.status)" class="row-actions"><button v-if="row.status === 'pending_review'" class="text-button" :disabled="busy" @click="review(row, 'processing')">受理处理中</button><button class="text-button" :disabled="busy" @click="review(row, 'approved')">通过并退款</button><button class="text-button text-danger" :disabled="busy" @click="review(row, 'rejected')">拒绝</button></td><td v-else-if="canReview">—</td></tr></tbody></table></div>
    <div v-else class="empty-state"><span class="empty-icon">⌕</span><p>还没有退款申请</p><small>提交后可在这里查看审核进度。</small></div>
  </section>
</template>
