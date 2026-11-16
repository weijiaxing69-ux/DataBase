<script setup>
// 设备运维看板：独立的维护模块页面，不依赖 App.vue 的资源表格壳。
// 数据全部走后端 /api/v1/maintenance/*，身份沿用 http.js 里的 Bearer 令牌。
import { computed, onMounted, onUnmounted, ref } from 'vue'
import {
  getOverview, listAlerts, listWorkOrders, listWorkOrderEvents,
  appendWorkOrderEvent, listIncidents, runTask,
} from '../../api/maintenance'

const overview = ref(null)
const alerts = ref([])
const incidents = ref([])
const selected = ref(null)
const orders = ref([])
const events = ref({})
const loading = ref(false)
const busy = ref(false)
const error = ref('')
const notice = ref('')
const page = ref(1)
const pageSize = 8
const total = ref(0)
let timer = null

const LEVEL = { critical: '严重', high: '高', medium: '中', low: '低' }
const ALERT_STATUS = { open: '未处理', processing: '处理中', recovering: '恢复观察', recovered: '已恢复' }
const WO_STATUS = { assigned: '待接单', accepted: '已接单', arrived: '已到场', repaired: '已修复', closed: '已闭环' }
const INC_STATUS = { detected: '已发现', declared: '已宣布', contained: '已受控', restored: '已恢复', reviewed: '已复盘', closed: '已关闭', cancelled: '已取消' }
const EVT = { accepted: '接单', arrived: '到场', repaired: '修复', review_passed: '复核通过', review_failed: '复核未通过', closed: '闭环', escalated: '超时升级' }

const kpi = computed(() => overview.value?.kpi || {})
const openAlerts = computed(() => alerts.value.filter(a => a.status !== 'recovered'))
const pageCount = computed(() => Math.max(1, Math.ceil(total.value / pageSize)))

// 30 天趋势缩略图：把每天的数量映射成一条折线
const spark = computed(() => {
  const points = overview.value?.trend || []
  if (points.length < 2) return null
  const w = 120, h = 30, pad = 3
  const max = Math.max(1, ...points.map(p => p.count))
  const step = (w - pad * 2) / (points.length - 1)
  const coords = points.map((p, i) => [pad + i * step, h - pad - (p.count / max) * (h - pad * 2)])
  return { w, h, line: coords.map((c, i) => (i ? 'L' : 'M') + c[0].toFixed(1) + ',' + c[1].toFixed(1)).join(' ') }
})

function hm(value) {
  if (!value) return '—'
  const date = new Date(value.endsWith('Z') || value.includes('+') ? value : value + 'Z')
  return date.toLocaleString('zh-CN', { hour12: false, month: '2-digit', day: '2-digit', hour: '2-digit', minute: '2-digit' })
}

function duration(value) {
  if (!value) return '—'
  const date = new Date(value.endsWith('Z') || value.includes('+') ? value : value + 'Z')
  const seconds = Math.max(0, (Date.now() - date.getTime()) / 1000)
  if (seconds < 3600) return Math.floor(seconds / 60) + ' 分'
  if (seconds < 86400) return (seconds / 3600).toFixed(1) + ' 时'
  return Math.floor(seconds / 86400) + ' 天'
}

async function loadAlerts() {
  const result = await listAlerts({ page: page.value, page_size: pageSize })
  alerts.value = result.items || []
  total.value = result.total || 0
}

async function load() {
  loading.value = true
  error.value = ''
  try {
    const [overviewData, incidentList] = await Promise.all([
      getOverview(),
      listIncidents(),
      loadAlerts(),
    ])
    overview.value = overviewData
    incidents.value = incidentList || []
  } catch (e) {
    error.value = e.message
  } finally {
    loading.value = false
  }
}

async function goto(nextPage) {
  if (nextPage < 1 || nextPage > pageCount.value) return
  page.value = nextPage
  loading.value = true
  try {
    await loadAlerts()
  } catch (e) {
    error.value = e.message
  } finally {
    loading.value = false
  }
}

async function openAlert(alert) {
  selected.value = alert
  orders.value = []
  events.value = {}
  try {
    const result = await listWorkOrders({ alert_id: alert.alert_id, page: 1, page_size: 20 })
    orders.value = result.items || []
  } catch (e) {
    error.value = e.message
  }
}

function actionsOf(order) {
  if (order.status === 'assigned') return [['accepted', '接单']]
  if (order.status === 'accepted') return [['arrived', '到场']]
  if (order.status === 'arrived') return [['repaired', '修复']]
  if (order.status === 'repaired') return [['review_passed', '复核通过'], ['review_failed', '复核未通过'], ['closed', '闭环']]
  return []
}

async function advance(order, eventType) {
  if (busy.value) return
  busy.value = true
  error.value = ''
  try {
    await appendWorkOrderEvent(order.work_order_id, { event_type: eventType })
    notice.value = `工单 #${order.work_order_id} 已${EVT[eventType] || eventType}`
    await load()
    if (selected.value) await openAlert(selected.value)
  } catch (e) {
    error.value = e.message
  } finally {
    busy.value = false
  }
}

async function toggleTimeline(order) {
  if (events.value[order.work_order_id]) {
    delete events.value[order.work_order_id]
    return
  }
  try {
    events.value[order.work_order_id] = await listWorkOrderEvents(order.work_order_id)
  } catch (e) {
    error.value = e.message
  }
}

async function triggerTask(name) {
  if (busy.value) return
  busy.value = true
  try {
    const result = await runTask(name)
    notice.value = `${name === 'offline' ? '离线扫描' : '超时升级'}完成，影响 ${result.affected} 条`
    await load()
  } catch (e) {
    error.value = e.message
  } finally {
    busy.value = false
  }
}

onMounted(() => {
  load()
  timer = setInterval(load, 30000)
})
onUnmounted(() => clearInterval(timer))
</script>

<template>
  <div class="mt-board">
    <div class="mt-head">
      <div>
        <p class="eyebrow">DEVICE OPERATIONS</p>
        <h1>设备运维看板</h1>
        <p class="muted">告警处置 · 工单进度 · 应急事件</p>
      </div>
      <div class="mt-actions">
        <button :disabled="busy" @click="triggerTask('offline')">离线扫描</button>
        <button :disabled="busy" @click="triggerTask('overdue')">超时升级</button>
        <button class="primary" :disabled="loading" @click="load">刷新</button>
      </div>
    </div>

    <p v-if="error" class="error banner" role="alert">{{ error }}</p>
    <p v-if="notice" class="success banner" role="status">{{ notice }}</p>

    <div class="mt-kpis">
      <div class="mt-kpi red"><span>未恢复告警</span><b>{{ kpi.open_alerts ?? '—' }}</b></div>
      <div class="mt-kpi amber"><span>超时未接单</span><b>{{ kpi.overdue_orders ?? '—' }}</b></div>
      <div class="mt-kpi"><span>进行中工单</span><b>{{ kpi.open_orders ?? '—' }}</b></div>
      <div class="mt-kpi blue"><span>进行中事件</span><b>{{ kpi.active_incidents ?? '—' }}</b></div>
      <div class="mt-kpi grey"><span>近 24 小时闭环</span><b>{{ kpi.closed_today ?? '—' }}</b></div>
    </div>

    <div class="mt-grid">
      <section class="panel">
        <h2>
          最近告警
          <small>共 {{ total }} 条，未恢复 {{ openAlerts.length }} 条</small>
          <svg v-if="spark" class="mt-spark" :viewBox="`0 0 ${spark.w} ${spark.h}`" aria-label="30 天告警趋势">
            <path :d="spark.line" fill="none" stroke="#10a37f" stroke-width="1.6" stroke-linejoin="round" />
          </svg>
        </h2>
        <div class="table-scroll">
          <table>
            <thead><tr><th>等级</th><th>桩 / 枪</th><th>告警码</th><th>状态</th><th>发生时间</th><th>已持续</th></tr></thead>
            <tbody>
              <tr v-if="loading"><td colspan="6" class="empty">正在加载…</td></tr>
              <tr v-else-if="!alerts.length"><td colspan="6" class="empty">暂无告警</td></tr>
              <tr v-for="alert in alerts" :key="alert.alert_id" class="clickable" @click="openAlert(alert)">
                <td><span class="badge mt-level" :class="alert.severity">{{ LEVEL[alert.severity] || alert.severity }}</span></td>
                <td>#{{ alert.pile_id }}<span v-if="alert.gun_id"> / 枪 {{ alert.gun_id }}</span></td>
                <td>{{ alert.alert_code }}</td>
                <td><span class="badge" :class="alert.status">{{ ALERT_STATUS[alert.status] || alert.status }}</span></td>
                <td>{{ hm(alert.occurred_at) }}</td>
                <td>{{ alert.status === 'recovered' ? '—' : duration(alert.occurred_at) }}</td>
              </tr>
            </tbody>
          </table>
        </div>
        <div class="mt-pager">
          <button :disabled="page <= 1 || loading" @click="goto(page - 1)">上一页</button>
          <span>第 {{ page }} / {{ pageCount }} 页</span>
          <button :disabled="page >= pageCount || loading" @click="goto(page + 1)">下一页</button>
        </div>
      </section>

      <section class="panel">
        <h2>应急事件 <small>按发生时间倒序</small></h2>
        <p v-if="!incidents.length" class="empty">暂无事件</p>
        <div v-for="item in incidents.slice(0, 5)" :key="item.incident_id" class="mt-incident">
          <div class="mt-row"><span class="badge mt-level" :class="item.severity === 'P1' ? 'critical' : item.severity === 'P2' ? 'high' : 'medium'">{{ item.severity }}</span>
            <span class="badge">{{ INC_STATUS[item.status] || item.status }}</span></div>
          <p class="mt-title">{{ item.title || item.incident_no }}</p>
          <p class="mt-meta">{{ item.incident_no }} · 告警 {{ item.alert_count }} 条 · 未闭环 {{ item.open_work_orders }} 单 · {{ duration(item.detected_at) }}</p>
        </div>
      </section>
    </div>

    <section v-if="selected" class="panel mt-detail">
      <div class="mt-row">
        <h2>告警 #{{ selected.alert_id }} · {{ selected.alert_code }} <small>{{ ALERT_STATUS[selected.status] }}</small></h2>
        <button @click="selected = null">关闭</button>
      </div>
      <p class="muted">桩 #{{ selected.pile_id }}<span v-if="selected.gun_id"> · 枪 {{ selected.gun_id }}</span>
        · 发生 {{ hm(selected.occurred_at) }} · 响应时限 {{ selected.response_seconds_snapshot }} 秒</p>

      <div v-for="order in orders" :key="order.work_order_id" class="mt-order">
        <div class="mt-row">
          <strong>工单 #{{ order.work_order_id }}</strong>
          <span class="badge">{{ WO_STATUS[order.status] || order.status }}</span>
        </div>
        <p class="mt-meta">处理人 {{ order.assigned_to }} · 派单 {{ hm(order.assigned_at) }} · 截止 {{ hm(order.response_due_at) }}
          <span v-if="order.accept_seconds !== null"> · 接单耗时 {{ Math.round(order.accept_seconds / 60) }} 分</span></p>
        <div class="mt-row-actions">
          <button v-for="[type, label] in actionsOf(order)" :key="type" :disabled="busy" @click="advance(order, type)">{{ label }}</button>
          <button :disabled="busy" @click="toggleTimeline(order)">{{ events[order.work_order_id] ? '收起时间线' : '时间线' }}</button>
        </div>
        <ul v-if="events[order.work_order_id]" class="mt-timeline">
          <li v-for="event in events[order.work_order_id]" :key="event.event_id">
            <strong>{{ EVT[event.event_type] || event.event_type }}</strong>
            <span class="badge">{{ WO_STATUS[event.new_status] || event.new_status }}</span>
            <small>{{ hm(event.event_at) }} · {{ event.actor_account_id ? '账号 ' + event.actor_account_id : '系统' }}<span v-if="event.note"> · {{ event.note }}</span></small>
          </li>
        </ul>
      </div>
      <p v-if="!orders.length" class="empty">该告警还没有派单</p>
    </section>
  </div>
</template>

<style scoped>
.mt-board { display: grid; gap: 16px; }
.mt-head { display: flex; justify-content: space-between; align-items: flex-end; gap: 16px; }
.mt-head h1 { font-size: 24px; margin: 4px 0; }
.mt-actions { display: flex; gap: 8px; }
.mt-kpis { display: grid; grid-template-columns: repeat(5, 1fr); gap: 12px; }
.mt-kpi { background: #fff; border: 1px solid #e6ebf0; border-left: 4px solid #10a37f; border-radius: 12px; padding: 14px 16px; }
.mt-kpi.red { border-left-color: #d64545; } .mt-kpi.amber { border-left-color: #d6a02e; }
.mt-kpi.blue { border-left-color: #2f6fed; } .mt-kpi.grey { border-left-color: #9aa8b5; }
.mt-kpi span { font-size: 12.5px; color: #6b7c8c; } .mt-kpi b { display: block; font-size: 26px; margin-top: 4px; }
.mt-grid { display: grid; grid-template-columns: 1.6fr 1fr; gap: 16px; align-items: start; }
.mt-grid h2 { display: flex; align-items: center; gap: 8px; }
.mt-grid h2 small { color: #6b7c8c; font-weight: 400; }
.mt-spark { margin-left: auto; width: 120px; height: 30px; }
.clickable { cursor: pointer; }
.clickable:hover { background: #f7fbfa; }
.mt-level.critical { background: #fdeaea; color: #d64545; }
.mt-level.high { background: #fdf0e5; color: #e07a2f; }
.mt-level.medium { background: #fdf7e3; color: #a97e12; }
.mt-level.low { background: #eef2f6; color: #7b8b9a; }
.mt-incident { padding: 10px 0; border-bottom: 1px dashed #eef2f6; }
.mt-incident:last-child { border-bottom: none; }
.mt-row { display: flex; justify-content: space-between; align-items: center; gap: 10px; }
.mt-title { font-size: 13px; margin-top: 4px; }
.mt-meta { font-size: 12px; color: #6b7c8c; margin-top: 4px; }
.mt-pager { display: flex; justify-content: flex-end; align-items: center; gap: 10px; margin-top: 12px; font-size: 12.5px; color: #6b7c8c; }
.mt-detail h2 { font-size: 16px; }
.mt-order { border: 1px solid #e6ebf0; border-radius: 10px; padding: 12px; margin-top: 12px; }
.mt-row-actions { display: flex; gap: 8px; margin-top: 10px; flex-wrap: wrap; }
.mt-timeline { list-style: none; margin-top: 10px; padding-left: 12px; border-left: 2px solid #e8eef3; }
.mt-timeline li { padding: 4px 0 8px 8px; font-size: 12.5px; }
.mt-timeline small { display: block; color: #8a99a6; margin-top: 2px; }
@media (max-width: 1100px) { .mt-kpis { grid-template-columns: repeat(3, 1fr); } .mt-grid { grid-template-columns: 1fr; } }
</style>
