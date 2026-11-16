<script setup>
import { computed, inject, onMounted, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { getSettlement, listOperatorInvoices, listSettlements } from '../../api/settlement'

const states = { draft: '草稿', pending_confirmation: '待确认', confirmed: '已确认', invoiced: '已开票', closed: '已关闭' }
const { token, has, mutate, clear } = inject('settlementSession')
const route = useRoute()
const router = useRouter()
const error = ref('')
const notice = ref('')
const busy = ref(false)
const query = ref({ keyword: '', bill_month: '', status: '' })
const page = ref(1)
const result = ref({ items: [], total: 0, page_size: 20 })
const selected = ref(null)
const detailDialog = ref(null)
const invoices = ref([])
const invoicePage = ref(1)
const invoiceTotal = ref(0)
const generation = ref(null)
const confirmation = ref({ decision: 'confirmed', note: '' })
const invoice = ref({ title: '', tax_no: '', amount: '' })
const red = ref(null)
const canWrite = computed(() => has('platform_admin', 'customer_service'))
const canConfirm = computed(() => has('platform_admin', 'operator_manager')
  && ['pending_confirmation', 'confirmed'].includes(selected.value?.status))

watch(detailDialog, dialog => {
  if (dialog && !dialog.open) dialog.showModal()
}, { flush: 'post' })

function closeDetail() {
  selected.value = null
  if (route.name === 'SettlementDetail') router.push({ name: 'SettlementList' })
  error.value = ''
  notice.value = ''
}

async function run(action) {
  busy.value = true
  error.value = ''
  notice.value = ''
  try { await action() }
  catch (e) {
    error.value = e.message
    if (e.status === 401) clear()
  } finally { busy.value = false }
}

async function load(nextPage = page.value) {
  const filters = Object.fromEntries(Object.entries(query.value).filter(([, value]) => value))
  if (filters.bill_month) filters.bill_month += '-01'
  result.value = await listSettlements(token.value, { ...filters, page: nextPage })
  page.value = nextPage
}

async function open(id, nextInvoicePage = 1) {
  const [detail, receipts] = await Promise.all([getSettlement(token.value, id),
    listOperatorInvoices(token.value, { settlement_id: id, page: nextInvoicePage })])
  selected.value = detail
  invoices.value = receipts.items
  invoiceTotal.value = receipts.total
  invoicePage.value = nextInvoicePage
  invoice.value = { title: detail.operator_name, tax_no: '', amount: '' }
  confirmation.value = { decision: 'confirmed', note: '' }
  red.value = null
}

async function generate() {
  const created = await mutate('/settlements', { ...generation.value, bill_month: generation.value.bill_month + '-01' })
  generation.value = null
  await load(1)
  await open(created.settlement_id)
  notice.value = '结算单已生成，等待双方确认。'
}

async function confirm() {
  const id = selected.value.settlement_id
  await mutate('/settlements/' + id + '/confirmations', {
    ...confirmation.value, object_version: selected.value.version,
  })
  await open(id)
  await load()
  notice.value = '确认结果已记录。'
}

async function issue() {
  const id = selected.value.settlement_id
  await mutate('/settlements/' + id + '/invoices', invoice.value)
  await open(id)
  await load()
  notice.value = '蓝票已开具。'
}

async function redIssue() {
  const { id, amount, reason } = red.value
  await mutate('/operator-invoices/' + id + '/red-issues', { amount, reason })
  await open(selected.value.settlement_id)
  notice.value = '红票已开具。'
}
onMounted(() => run(async () => {
  await load(1)
  if (route.params.settlementId) await open(route.params.settlementId)
}))
</script>

<template>
  <section>
    <div v-if="error && !selected" class="error" role="alert">{{ error }}</div>
    <div v-if="notice && !selected" class="notice" role="status">{{ notice }}</div>
    <template v-if="has('platform_admin','customer_service','operator_manager')">
      <div class="page-title"><h1>运营商结算</h1>
        <button v-if="canWrite" :disabled="busy" @click="generation = { operator_id: '', station_id: '', bill_month: '' }">生成结算单</button>
      </div>
      <form v-if="generation" class="card toolbar" @submit.prevent="run(generate)">
        <label>运营商编号<input v-model="generation.operator_id" required inputmode="numeric" pattern="[1-9][0-9]*"></label>
        <label>场站编号<input v-model="generation.station_id" required inputmode="numeric" pattern="[1-9][0-9]*"></label>
        <label>账期<input v-model="generation.bill_month" type="month" required></label>
        <button :disabled="busy">生成</button><button type="button" class="secondary" @click="generation = null">取消</button>
      </form>
      <section class="card">
        <form class="toolbar" @submit.prevent="run(() => load(1))">
          <label>运营商或场站<input v-model="query.keyword" placeholder="输入名称"></label>
          <label>账期<input v-model="query.bill_month" type="month"></label>
          <label>状态<select v-model="query.status"><option value="">全部</option><option v-for="(label, key) in states" :key="key" :value="key">{{ label }}</option></select></label>
          <button :disabled="busy">查询</button>
        </form>
        <div class="table-scroll"><table>
          <thead><tr><th>结算单</th><th>运营商</th><th>场站</th><th>账期</th><th>应结金额</th><th>开票净额</th><th>状态</th><th>操作</th></tr></thead>
          <tbody><tr v-for="row in result.items" :key="row.settlement_id">
            <td>#{{ row.settlement_id }}</td><td>{{ row.operator_name }}</td><td>{{ row.station_name }}</td><td>{{ row.bill_month.slice(0, 7) }}</td>
            <td>¥{{ row.payable_amount }}</td><td>¥{{ row.net_issued_amount }}</td><td><span class="status">{{ states[row.status] }}</span></td>
            <td><button class="link" :disabled="busy" aria-haspopup="dialog" @click="router.push({ name: 'SettlementDetail', params: { settlementId: row.settlement_id } })">查看</button></td>
          </tr><tr v-if="!result.items.length"><td colspan="8">暂无匹配的结算单</td></tr></tbody>
        </table></div>
        <div class="pager">共 {{ result.total }} 条 · 第 {{ page }} 页
          <button class="secondary" :disabled="busy || page <= 1" @click="run(() => load(page - 1))">上一页</button>
          <button class="secondary" :disabled="busy || page * result.page_size >= result.total" @click="run(() => load(page + 1))">下一页</button>
        </div>
      </section>
      <dialog v-if="selected" ref="detailDialog" class="card detail" aria-labelledby="settlement-detail-title"
              @close="closeDetail" @cancel="busy && $event.preventDefault()">
        <div class="page-title"><h2 id="settlement-detail-title">结算单 #{{ selected.settlement_id }}</h2><button class="secondary" :disabled="busy" @click="detailDialog.close()">关闭详情</button></div>
        <div v-if="error" class="error" role="alert">{{ error }}</div>
        <div v-if="notice" class="notice" role="status">{{ notice }}</div>
        <p>{{ selected.station_name }} · 版本 {{ selected.version }} · {{ states[selected.status] }}</p>
        <p>平台：{{ selected.platform_confirmation ? (selected.platform_confirmation.decision === 'confirmed' ? '已确认' : '有异议') : '待确认' }}　
           运营商：{{ selected.operator_confirmation ? (selected.operator_confirmation.decision === 'confirmed' ? '已确认' : '有异议') : '待确认' }}</p>
        <form v-if="canConfirm" class="toolbar" @submit.prevent="run(confirm)">
          <label>确认结果<select v-model="confirmation.decision"><option value="confirmed">同意</option><option value="disputed">有异议</option></select></label>
          <label>意见<input v-model="confirmation.note" maxlength="1000"></label>
          <button :disabled="busy">提交确认</button>
        </form>
        <h3>归集明细</h3>
        <div class="table-scroll"><table><thead><tr><th>订单</th><th>净额</th><th>电费分成</th><th>服务费分成</th><th>平台费</th><th>应结</th></tr></thead>
          <tbody><tr v-for="item in selected.items" :key="item.settlement_item_id"><td>#{{ item.order_id }}</td><td>{{ item.net_amount }}</td><td>{{ item.electricity_share_amount }}</td><td>{{ item.service_share_amount }}</td><td>{{ item.platform_fee_amount }}</td><td>{{ item.payable_amount }}</td></tr></tbody>
        </table></div>
        <h3>发票</h3>
        <form v-if="canWrite && ['confirmed', 'invoiced'].includes(selected.status)" class="toolbar" @submit.prevent="run(issue)">
          <label>抬头<input v-model="invoice.title" required maxlength="100"></label>
          <label>税号<input v-model="invoice.tax_no" required maxlength="30"></label>
          <label>金额（元）<input v-model="invoice.amount" required inputmode="decimal" pattern="[0-9]+([.][0-9]{1,2})?"></label>
          <button :disabled="busy">开蓝票</button>
        </form>
        <div class="table-scroll"><table><thead><tr><th>票号</th><th>票种</th><th>金额</th><th>操作</th></tr></thead>
          <tbody><tr v-for="row in invoices" :key="row.invoice_id"><td>{{ row.invoice_no }}</td><td>{{ row.invoice_type === 'blue' ? '蓝票' : '红票' }}</td><td>¥{{ row.amount }}</td>
            <td><button v-if="canWrite && row.invoice_type === 'blue'" class="link" :disabled="busy" @click="red = { id: row.invoice_id, amount: '', reason: '' }">红冲</button></td></tr>
            <tr v-if="!invoices.length"><td colspan="4">暂无发票</td></tr>
          </tbody>
        </table></div>
        <div v-if="invoiceTotal > 20" class="pager">
          <button class="secondary" :disabled="busy || invoicePage <= 1" @click="run(() => open(selected.settlement_id, invoicePage - 1))">上一页</button>
          <button class="secondary" :disabled="busy || invoicePage * 20 >= invoiceTotal" @click="run(() => open(selected.settlement_id, invoicePage + 1))">下一页</button>
        </div>
        <form v-if="red" class="toolbar" @submit.prevent="run(redIssue)">
          <label>原票 #{{ red.id }} 红冲金额<input v-model="red.amount" required inputmode="decimal" pattern="[0-9]+([.][0-9]{1,2})?"></label>
          <label>原因<input v-model="red.reason" required maxlength="500"></label>
          <button :disabled="busy">确认红冲</button><button type="button" class="secondary" @click="red = null">取消</button>
        </form>
      </dialog>
    </template>
  </section>
</template>
