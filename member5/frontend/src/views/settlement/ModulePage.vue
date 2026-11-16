<script setup>
import { computed, inject, onMounted, ref } from 'vue'
import { useRoute } from 'vue-router'
import { billItems, pages } from './pages'

const route = useRoute()
const page = pages[route.meta.section]
const { token, has, mutate, clear } = inject('settlementSession')
const allowed = computed(() => has(...page.roles))
const filters = ref({})
const results = ref({ items: [], total: 0, page: 1, page_size: 20 })
const details = ref(null)
const action = ref(null)
const data = ref({})
const busy = ref(false)
const error = ref('')
const notice = ref('')
const labels = { draft: '草稿', active: '已启用', disabled: '已停用', issued: '已开具',
  requested: '待办理', red_issued: '已红冲', rejected: '已拒绝或有异议', open: '待处理',
  pending_confirmation: '待确认', effective: '已生效', partially_paid: '部分收款', paid: '已结清',
  closed: '已关闭', energy: '电量', price: '价格', payment: '支付', blue: '蓝票', red: '红票',
  order: '订单', refund: '退款', credit_carry: '负额结转', adjustment: '调整' }
const display = value => labels[value] || (value ?? '—')
const addAllocation = () => data.value.items.push({ order_id: '', allocated_amount: '' })
const mainFields = computed(() => [
  { name: 'keyword', label: '关键词', type: 'text' }, ...page.filters,
  { name: 'start_at', label: '起始时间（北京时间）', type: 'datetime-local' },
  { name: 'end_at', label: '截止时间（北京时间）', type: 'datetime-local' },
])
function convert(values, fields) {
  return Object.fromEntries(fields.filter(f => values[f.name] !== '' && values[f.name] != null)
    .map(({ name, type }) => [name, type === 'month' ? values[name] + '-01' :
      type === 'datetime-local' ? values[name] + ':00+08:00' : values[name]]))
}
async function run(callback) {
  busy.value = true
  error.value = ''
  notice.value = ''
  try { await callback() }
  catch (e) { error.value = e.message; if (e.status === 401) clear() }
  finally { busy.value = false }
}
async function load(number = results.value.page) {
  results.value = await page.list(token.value, { ...convert(filters.value, mainFields.value), page: number })
}
function select(next, row = null) {
  action.value = { ...next, row }
  data.value = Object.fromEntries(next.fields.map(f => [f.name, f.type === 'allocations'
    ? [{ order_id: '', allocated_amount: '' }] : (f.type === 'select' ? Object.keys(f.values)[0] : '')]))
}
async function submit() {
  const task = action.value
  const values = convert(data.value, task.fields)
  const result = await mutate(task.path(task.row ?? values), task.payload(values, task.row))
  action.value = null
  if (route.params.billId) details.value = await page.detail(token.value, route.params.billId)
  else {
    await load()
    if (details.value) details.value = await page.detail(token.value, details.value[page.key])
  }
  notice.value = result.adjustment_id ? `调整申请 #${result.adjustment_id} 已提交，请交由另一账号审批。` : '操作成功。'
}
onMounted(() => {
  if (allowed.value) run(async () => {
    if (route.params.billId) details.value = await page.detail(token.value, route.params.billId)
    else await load(1)
  })
})
</script>

<template>
  <section>
    <p v-if="!allowed" class="error">当前账号无权访问该页面。</p>
    <template v-else>
      <div class="page-title">
        <h1>{{ route.params.billId ? '车队月结单 #' + route.params.billId : page.title }}</h1>
        <RouterLink v-if="route.params.billId" :to="{ name: 'FleetBillList' }">返回月结列表</RouterLink>
        <div v-else class="row-actions">
          <button v-if="page.create && has(...page.create.roles)" :disabled="busy" @click="select(page.create)">{{ page.create.label }}</button>
          <button v-if="page.review && has(...page.review.roles)" :disabled="busy" @click="select(page.review)">{{ page.review.label }}</button>
        </div>
      </div>
      <p v-if="page.tip">{{ page.tip }}</p>
      <div v-if="error" class="error" role="alert">{{ error }}</div>
      <div v-if="notice" class="notice" role="status">{{ notice }}</div>
      <form v-if="action" class="card" @submit.prevent="run(submit)">
        <h2>{{ action.label }}</h2>
        <div class="toolbar">
          <template v-for="f in action.fields" :key="f.name">
            <fieldset v-if="f.type === 'allocations'">
              <legend>{{ f.label }}</legend>
              <div v-for="(line, index) in data.items" :key="index" class="toolbar">
                <label>订单编号<input v-model="line.order_id" inputmode="numeric" pattern="[1-9][0-9]*" required></label>
                <label>分配金额<input v-model="line.allocated_amount" inputmode="decimal" required></label>
                <button v-if="data.items.length > 1" type="button" class="secondary" @click="data.items.splice(index, 1)">移除</button>
              </div>
              <button type="button" class="secondary" @click="addAllocation">添加订单</button>
            </fieldset>
            <label v-else>{{ f.label }}
              <select v-if="f.type === 'select'" v-model="data[f.name]">
                <option v-for="(label, key) in f.values" :key="key" :value="key">{{ label }}</option>
              </select>
              <input v-else v-model="data[f.name]" :type="['month','datetime-local'].includes(f.type) ? f.type : 'text'"
                :inputmode="f.type === 'id' ? 'numeric' : f.type === 'money' ? 'decimal' : undefined"
                :pattern="f.type === 'id' ? '[1-9][0-9]*' : undefined" :required="!f.optional">
            </label>
          </template>
          <button :disabled="busy">提交</button>
          <button type="button" class="secondary" :disabled="busy" @click="action = null">取消</button>
        </div>
      </form>
      <section v-if="!route.params.billId" class="card">
        <form class="toolbar" @submit.prevent="run(() => load(1))">
          <label v-for="f in mainFields" :key="f.name">{{ f.label }}
            <select v-if="f.type === 'select'" v-model="filters[f.name]">
              <option value="">全部</option><option v-for="(label, key) in f.values" :key="key" :value="key">{{ label }}</option>
            </select>
            <input v-else v-model="filters[f.name]" :type="['month','datetime-local'].includes(f.type) ? f.type : 'text'"
              :pattern="f.type === 'id' ? '[1-9][0-9]*' : undefined">
          </label>
          <button :disabled="busy">查询</button>
        </form>
        <div class="table-scroll">
          <table>
            <thead><tr><th v-for="(label, key) in page.columns" :key="key">{{ label }}</th><th>操作</th></tr></thead>
            <tbody>
              <tr v-for="row in results.items" :key="row[page.key]">
                <td v-for="(_, key) in page.columns" :key="key">{{ display(row[key]) }}</td>
                <td class="row-actions">
                  <RouterLink v-if="page.route" :to="{ name: page.route, params: { billId: row.bill_id } }">查看</RouterLink>
                  <button v-else class="link" :disabled="busy" @click="run(async () => { details = await page.detail(token, row[page.key]) })">查看</button>
                  <template v-for="op in page.actions" :key="op.label">
                    <button v-if="has(...op.roles) && op.when(row)" class="link" :disabled="busy" @click="select(op, row)">{{ op.label }}</button>
                  </template>
                </td>
              </tr>
              <tr v-if="!results.items.length"><td :colspan="Object.keys(page.columns).length+1">暂无匹配记录</td></tr>
            </tbody>
          </table>
        </div>
        <div class="pager">共 {{ results.total }} 条 · 第 {{ results.page }} 页
          <button class="secondary" :disabled="busy || results.page <= 1" @click="run(() => load(results.page-1))">上一页</button>
          <button class="secondary" :disabled="busy || results.page * results.page_size >= results.total" @click="run(() => load(results.page+1))">下一页</button>
        </div>
      </section>
      <section v-if="details" class="card">
        <div class="page-title"><h2>详情 #{{ details[page.key] }}</h2>
          <button v-if="!route.params.billId" class="secondary" @click="details = null">关闭详情</button>
          <template v-else v-for="op in page.actions" :key="op.label">
            <button v-if="has(...op.roles) && op.when(details)" @click="select(op, details)">{{ op.label }}</button>
          </template>
        </div>
        <dl class="detail-grid"><template v-for="(label, key) in page.columns" :key="key">
          <dt>{{ label }}</dt><dd>{{ display(details[key]) }}</dd>
        </template></dl>
        <div v-if="details.items" class="table-scroll">
          <h3>月结明细</h3>
          <table>
            <thead><tr><th v-for="(label, key) in billItems" :key="key">{{ label }}</th></tr></thead>
            <tbody><tr v-for="line in details.items" :key="line.bill_item_id">
              <td v-for="(_, key) in billItems" :key="key">{{ display(line[key]) }}</td>
            </tr></tbody>
          </table>
        </div>
      </section>
    </template>
  </section>
</template>
