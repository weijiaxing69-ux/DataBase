<script setup>
// 设备运维看板：独立的维护模块页面，不依赖 App.vue 的资源表格壳。
// 配色沿用 style.css 的墨绿体系（#17654c / #bdd997 / #f4f7f5），保证与场站页面一致。
import { computed, onMounted, onUnmounted, ref } from 'vue'
import {
  getOverview, listAlerts, listWorkOrders, listWorkOrderEvents,
  appendWorkOrderEvent, listIncidents, runTask, listSpareParts,
} from '../../api/maintenance'
import MaintenanceConsole from './MaintenanceConsole.vue'

const overview = ref(null)
const alerts = ref([])
const incidents = ref([])
const lowParts = ref([])
const selected = ref(null)
const orders = ref([])
const events = ref({})
const loading = ref(false)
const busy = ref(false)
const error = ref('')
const toast = ref(null)
const page = ref(1)
const pageSize = 8
const total = ref(0)
const updatedAt = ref('')
const taskName = ref('offline')
const showConsole = ref(false)
let timer = null
let toastTimer = null

const LEVEL = { critical: '严重', high: '高', medium: '中', low: '低' }
const LEVEL_COLOR = { critical: '#b3452f', high: '#b9762a', medium: '#9a8124', low: '#6d7d74' }
const ALERT_STATUS = { open: '未处理', processing: '处理中', recovering: '恢复观察', recovered: '已恢复' }
const ALERT_CODE = { CHG01: '充电中断', TEMP01: '高温预警', MET01: '计量异常', CAP01: '场站功率过载', VLT01: '电压越限', E101: '绝缘故障' }
const codeName = code => ALERT_CODE[code]
  || (/^SCN-TEMP/.test(code) ? '温度超限' : /^E\d/.test(code) ? '设备故障' : code)

// 现场处置 SOP：按告警类型给出现场可执行动作，避免值班人员只看到码不知道下一步。
const ALERT_SOP = {
  CHG01: ['核实车辆 BMS 是否中断、订单是否仍在计费。', '检查枪头连接、枪锁与线缆是否松脱。', '必要时联系车主重新插枪，或按中断流程处理订单。'],
  TEMP01: ['检查散热风扇、进出风口与环境温度。', '确认模块温度是否持续上升，必要时降功率或停机。', '温度回落后按恢复观察流程闭环。'],
  MET01: ['先断电隔离，防止继电器粘连造成持续输出。', '检查电表读数、继电器与计量回路。', '修复后现场复核，再恢复服务。'],
  CAP01: ['查看场站内正在充电的桩与功率分布。', '必要时限制部分桩功率或引导车主错峰充电。', '复核台区容量，确认未超出配电能力。'],
  VLT01: ['检查电网电压是否波动、三相是否平衡。', '检查枪头接触、整流模块与接线端子。', '确认电压恢复后再恢复充电。'],
  E101: ['立即核实绝缘检测与枪头接地。', '人员未撤离前不要继续充电。', '必要时停机并通知运维到场。'],
}
const DEFAULT_SOP = ['按告警等级与响应时限到场核实。', '先确认人员与设备安全，再排查故障现象。', '处置完成后按工单闭环流程复核。']
const sopOf = alert => ALERT_SOP[alert?.alert_code]
  || (/^SCN-TEMP/.test(alert?.alert_code || '') ? ['确认温度探头与环境温度。', '必要时降功率或停机散热。'] : DEFAULT_SOP)
const WO_STATUS = { assigned: '待接单', accepted: '已接单', arrived: '已到场', repaired: '已修复', closed: '已闭环' }
const INC_STATUS = { detected: '已发现', declared: '已宣布', contained: '已受控', restored: '已恢复', reviewed: '已复盘', closed: '已关闭', cancelled: '已取消' }
const EVT = { accepted: '接单', arrived: '到场', repaired: '修复', review_passed: '复核通过', review_failed: '复核未通过', closed: '闭环', escalated: '超时升级' }

const kpi = computed(() => overview.value?.kpi || {})
const alertFilter = ref('all')
const openAlerts = computed(() => alerts.value.filter(a => a.status !== 'recovered'))
const overdueCount = computed(() => alerts.value.filter(a => a.is_overdue).length)
const visibleAlerts = computed(() => {
  if (alertFilter.value === 'open') return openAlerts.value
  if (alertFilter.value === 'overdue') return alerts.value.filter(a => a.is_overdue)
  return alerts.value
})
const pageCount = computed(() => Math.max(1, Math.ceil(total.value / pageSize)))

// 30 天趋势：折线 + 面积 + 网格
const trend = computed(() => {
  const points = overview.value?.trend || []
  if (points.length < 2) return null
  const w = 560, h = 150, padX = 28, padTop = 18, padBottom = 24
  const max = Math.max(1, ...points.map(p => p.count))
  const step = (w - padX * 2) / (points.length - 1)
  const coords = points.map((p, i) => [
    padX + i * step,
    h - padBottom - (p.count / max) * (h - padTop - padBottom),
  ])
  const line = coords.map((c, i) => (i ? 'L' : 'M') + c[0].toFixed(1) + ',' + c[1].toFixed(1)).join(' ')
  const area = `${line} L${coords[coords.length - 1][0].toFixed(1)},${h - padBottom} L${coords[0][0].toFixed(1)},${h - padBottom} Z`
  return {
    w, h, padX, padBottom, line, area, max,
    dots: coords.map((c, i) => ({ x: c[0], y: c[1], count: points[i].count })),
    labels: coords.map((c, i) => ({ x: c[0], text: points[i].date.slice(5) })),
    total: points.reduce((sum, p) => sum + p.count, 0),
  }
})

// 未恢复告警的等级分布：横向堆叠条 + 图例
const severity = computed(() => {
  const rows = overview.value?.severity || []
  const order = ['critical', 'high', 'medium', 'low']
  const totalCount = rows.reduce((sum, r) => sum + r.count, 0) || 1
  return order
    .map(key => {
      const hit = rows.find(r => r.severity === key)
      return hit ? { key, label: LEVEL[key], count: hit.count, color: LEVEL_COLOR[key],
        width: (hit.count / totalCount) * 100 } : null
    })
    .filter(Boolean)
})

const stations = computed(() => {
  const rows = overview.value?.stations || []
  const max = Math.max(1, ...rows.map(r => r.open_alerts))
  return rows.map(r => ({ ...r, width: (r.open_alerts / max) * 100 }))
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

function showToast(message, isError = false) {
  toast.value = { message, isError }
  clearTimeout(toastTimer)
  toastTimer = setTimeout(() => { toast.value = null }, 2800)
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
    const [overviewData, incidentList, , parts] = await Promise.all([
      getOverview(), listIncidents(), loadAlerts(), listSpareParts({ only_low: true, page_size: 5 }),
    ])
    overview.value = overviewData
    incidents.value = incidentList || []
    lowParts.value = parts.items || []
    updatedAt.value = new Date().toLocaleTimeString('zh-CN', { hour12: false })
  } catch (e) {
    error.value = e.message
  } finally {
    loading.value = false
  }
}

async function goto(next) {
  if (next < 1 || next > pageCount.value || next === page.value) return
  page.value = next
  loading.value = true
  try { await loadAlerts() } catch (e) { error.value = e.message } finally { loading.value = false }
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

function closeDrawer() { selected.value = null }

function actionsOf(order) {
  if (order.status === 'assigned') return [['accepted', '接单']]
  if (order.status === 'accepted') return [['arrived', '到场']]
  if (order.status === 'arrived') return [['repaired', '修复']]
  if (order.status === 'repaired') {
    const actions = [['review_passed', '复核通过'], ['review_failed', '复核未通过']]
    if (order.review_passed) actions.push(['closed', '闭环'])
    return actions
  }
  return []
}

async function advance(order, eventType) {
  if (busy.value) return
  busy.value = true
  error.value = ''
  try {
    await appendWorkOrderEvent(order.work_order_id, { event_type: eventType })
    showToast(`工单 #${order.work_order_id} 已${EVT[eventType] || eventType}`)
    await load()
    if (selected.value) await openAlert(selected.value)
  } catch (e) {
    error.value = e.message
    showToast(e.message, true)
  } finally {
    busy.value = false
  }
}

async function toggleTimeline(order) {
  if (events.value[order.work_order_id]) { delete events.value[order.work_order_id]; return }
  try {
    events.value[order.work_order_id] = await listWorkOrderEvents(order.work_order_id)
  } catch (e) { error.value = e.message }
}

async function triggerTask(name) {
  if (busy.value) return
  busy.value = true
  try {
    const result = await runTask(name)
    const label = { offline: '离线扫描', overdue: '超时升级', recovery: '恢复推进',
                    charging: '充电中断', safety: '安全停机', recurring: '复发升级',
                    inspection: '巡检到期', temperature: '高温预警',
                    metering: '计量异常', occupied: '占用检查', overload: '场站过载',
                    duration: '充电超时', voltage: '电压越限',
                    gun_mismatch: '枪订单不一致',
                    fault_state_mismatch: '故障标记未复位',
                    sampling_gap: '采样断流' }[name] || name
    showToast(`${label}完成，影响 ${result.affected} 条`)
    await load()
  } catch (e) {
    error.value = e.message
    showToast(e.message, true)
  } finally { busy.value = false }
}

function onKeydown(e) {
  if (e.key !== 'Escape') return
  if (showConsole.value) showConsole.value = false
  else closeDrawer()
}

onMounted(() => {
  load()
  timer = setInterval(load, 30000)
  document.addEventListener('keydown', onKeydown)
})
onUnmounted(() => {
  clearInterval(timer)
  document.removeEventListener('keydown', onKeydown)
})
</script>

<template>
  <div class="mt">
    <header class="mt-head">
      <div class="mt-title">
        <p class="eyebrow">DEVICE OPERATIONS</p>
        <h1>设备运维看板</h1>
        <p class="muted">告警处置 · 工单进度 · 应急事件<span v-if="updatedAt"> · 更新于 {{ updatedAt }}</span></p>
      </div>
      <div class="mt-actions">
        <span class="mt-live"><i></i>数据已连接</span>
        <button class="mt-ghost" @click="showConsole = true">运维工作台</button>
        <select v-model="taskName" class="mt-select" aria-label="选择扫描任务">
          <optgroup label="基础巡检">
            <option value="offline">离线扫描</option>
            <option value="overdue">超时升级</option>
            <option value="recovery">恢复推进</option>
            <option value="inspection">巡检到期</option>
          </optgroup>
          <optgroup label="现场识别">
            <option value="charging">充电中断</option>
            <option value="safety">安全停机派单</option>
            <option value="recurring">复发故障升级</option>
            <option value="temperature">高温预警</option>
            <option value="metering">计量异常</option>
            <option value="occupied">充满占位</option>
            <option value="gun_mismatch">枪状态与订单不一致</option>
          </optgroup>
          <optgroup label="状态一致性">
            <option value="gun_mismatch">枪状态与订单不一致</option>
            <option value="fault_state_mismatch">故障标记未复位</option>
            <option value="sampling_gap">充电订单采样断流</option>
          </optgroup>
          <optgroup label="用电与时长">
            <option value="overload">场站功率过载</option>
            <option value="duration">充电超时占位</option>
            <option value="voltage">电压越限</option>
          </optgroup>
        </select>
        <button class="mt-ghost" :disabled="busy" @click="triggerTask(taskName)">
          <svg viewBox="0 0 16 16" width="14" height="14" aria-hidden="true"><path d="M3 8h10M9 4l4 4-4 4" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/></svg>
          执行扫描
        </button>
        <button class="primary" :disabled="loading" @click="load">
          <svg viewBox="0 0 16 16" width="14" height="14" aria-hidden="true"><path d="M13 8a5 5 0 1 1-1.5-3.5M13 2v3h-3" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/></svg>
          刷新
        </button>
      </div>
    </header>

    <p v-if="error" class="error banner" role="alert">{{ error }}</p>

    <section class="mt-kpis">
      <article class="mt-kpi is-red">
        <header><span>未恢复告警</span><b>{{ kpi.open_alerts ?? '—' }}</b></header>
        <p>需要处置的设备异常</p>
        <div class="mt-bar"><span :style="{ width: Math.min(100, (kpi.open_alerts || 0) * 8) + '%' }"></span></div>
      </article>
      <article class="mt-kpi is-amber">
        <header><span>超时未接单</span><b>{{ kpi.overdue_orders ?? '—' }}</b></header>
        <p>已超过响应时限</p>
        <div class="mt-bar"><span :style="{ width: Math.min(100, (kpi.overdue_orders || 0) * 25) + '%' }"></span></div>
      </article>
      <article class="mt-kpi">
        <header><span>进行中工单</span><b>{{ kpi.open_orders ?? '—' }}</b></header>
        <p>尚未闭环</p>
        <div class="mt-bar"><span :style="{ width: Math.min(100, (kpi.open_orders || 0) * 20) + '%' }"></span></div>
      </article>
      <article class="mt-kpi is-blue">
        <header><span>进行中事件</span><b>{{ kpi.active_incidents ?? '—' }}</b></header>
        <p>应急事件未关闭</p>
        <div class="mt-bar"><span :style="{ width: Math.min(100, (kpi.active_incidents || 0) * 30) + '%' }"></span></div>
      </article>
      <article class="mt-kpi is-grey">
        <header><span>近 24 小时闭环</span><b>{{ kpi.closed_today ?? '—' }}</b></header>
        <p>完成的维修工单</p>
        <div class="mt-bar"><span :style="{ width: Math.min(100, (kpi.closed_today || 0) * 20) + '%' }"></span></div>
      </article>
    </section>

    <div class="mt-row">
      <section class="panel mt-chart">
        <header class="mt-card-head">
          <div><h2>近 30 天告警趋势</h2><p class="muted">按告警发生日期统计，共 {{ trend?.total ?? 0 }} 条</p></div>
          <span class="mt-tag">30D</span>
        </header>
        <svg v-if="trend" class="mt-trend" :viewBox="`0 0 ${trend.w} ${trend.h}`" role="img" aria-label="告警趋势">
          <defs>
            <linearGradient id="mtFill" x1="0" y1="0" x2="0" y2="1">
              <stop offset="0%" stop-color="#17654c" stop-opacity=".18" />
              <stop offset="100%" stop-color="#17654c" stop-opacity="0" />
            </linearGradient>
          </defs>
          <line v-for="i in 3" :key="i" :x1="trend.padX" :x2="trend.w - trend.padX"
                :y1="trend.h - trend.padBottom - ((trend.h - 42) / 3) * i"
                :y2="trend.h - trend.padBottom - ((trend.h - 42) / 3) * i"
                stroke="#eef3ef" stroke-width="1" />
          <path :d="trend.area" fill="url(#mtFill)" />
          <path :d="trend.line" fill="none" stroke="#17654c" stroke-width="2" stroke-linejoin="round" stroke-linecap="round" />
          <g v-for="(dot, i) in trend.dots" :key="i">
            <circle :cx="dot.x" :cy="dot.y" r="3.2" fill="#fff" stroke="#17654c" stroke-width="1.8" />
            <text :x="dot.x" :y="dot.y - 9" text-anchor="middle" font-size="10" fill="#5b6b62">{{ dot.count }}</text>
          </g>
          <text v-for="(label, i) in trend.labels" :key="'l' + i" :x="label.x" :y="trend.h - 6"
                text-anchor="middle" font-size="10" fill="#93a199">{{ label.text }}</text>
        </svg>
        <div v-else class="mt-skeleton mt-skeleton-chart"></div>
      </section>

      <section class="panel mt-side">
        <header class="mt-card-head"><h2>未恢复告警等级</h2></header>
        <div v-if="severity.length" class="mt-stack">
          <div class="mt-stack-bar">
            <span v-for="row in severity" :key="row.key" :style="{ width: row.width + '%', background: row.color }" :title="`${row.label} ${row.count}`"></span>
          </div>
          <ul class="mt-legend">
            <li v-for="row in severity" :key="row.key">
              <i :style="{ background: row.color }"></i>{{ row.label }}<b>{{ row.count }}</b>
            </li>
          </ul>
        </div>
        <p v-else class="mt-empty">当前没有未恢复告警</p>

        <header class="mt-card-head mt-gap"><h2>场站告警排行</h2></header>
        <ul v-if="stations.length" class="mt-rank">
          <li v-for="(row, i) in stations" :key="row.station_id">
            <span class="mt-rank-no">{{ i + 1 }}</span>
            <div class="mt-rank-main">
              <div class="mt-rank-label"><span>{{ row.station_name }}</span><b>{{ row.open_alerts }}</b></div>
              <div class="mt-rank-bar"><span :style="{ width: row.width + '%' }"></span></div>
            </div>
          </li>
        </ul>
        <p v-else class="mt-empty">暂无数据</p>
      </section>
    </div>

    <div class="mt-row">
      <section class="panel mt-table-card">
        <header class="mt-card-head">
          <div>
            <h2>最近告警</h2>
            <p class="muted">共 {{ total }} 条 · 本页未恢复 {{ openAlerts.length }} · 超时 {{ overdueCount }}</p>
          </div>
          <div class="mt-tabs">
            <button :class="{ on: alertFilter === 'all' }" @click="alertFilter = 'all'">全部</button>
            <button :class="{ on: alertFilter === 'open' }" @click="alertFilter = 'open'">未恢复</button>
            <button :class="{ on: alertFilter === 'overdue' }" @click="alertFilter = 'overdue'">已超时</button>
          </div>
        </header>
        <div class="table-scroll">
          <table class="mt-table">
            <thead><tr><th>等级</th><th>桩 / 枪</th><th>告警码</th><th>状态</th><th>发生时间</th><th>已持续</th></tr></thead>
            <tbody>
              <template v-if="loading">
                <tr v-for="i in 5" :key="'sk' + i"><td colspan="6"><div class="mt-skeleton mt-skeleton-row"></div></td></tr>
              </template>
              <tr v-else-if="!visibleAlerts.length"><td colspan="6" class="mt-empty">
                {{ alertFilter === 'overdue' ? '当前页没有超时告警' : alertFilter === 'open' ? '当前页告警都已恢复' : '暂无告警，设备运行正常' }}
              </td></tr>
              <tr v-for="alert in visibleAlerts" v-else :key="alert.alert_id" class="mt-click" @click="openAlert(alert)">
                <td>
                  <span class="mt-level" :class="alert.severity">
                    <i></i>{{ LEVEL[alert.severity] || alert.severity }}
                  </span>
                </td>
                <td class="mt-mono">#{{ alert.pile_id }}<span v-if="alert.gun_id" class="mt-sub"> / 枪 {{ alert.gun_id }}</span></td>
                <td>
                  <span class="mt-code">{{ codeName(alert.alert_code) }}</span>
                  <span class="mt-code-sub">{{ alert.alert_code }}</span>
                </td>
                <td>
                  <span class="mt-status" :class="alert.status">{{ ALERT_STATUS[alert.status] || alert.status }}</span>
                  <span v-if="alert.is_overdue" class="mt-overdue">超时</span>
                </td>
                <td class="mt-time">{{ hm(alert.occurred_at) }}</td>
                <td class="mt-time">{{ alert.status === 'recovered' ? '—' : duration(alert.occurred_at) }}</td>
              </tr>
            </tbody>
          </table>
        </div>
        <footer class="mt-pager">
          <span>第 {{ page }} / {{ pageCount }} 页</span>
          <div>
            <button class="mt-ghost" :disabled="page <= 1 || loading" @click="goto(page - 1)">上一页</button>
            <button class="mt-ghost" :disabled="page >= pageCount || loading" @click="goto(page + 1)">下一页</button>
          </div>
        </footer>
      </section>

      <section class="panel mt-incidents">
        <header class="mt-card-head"><h2>备件紧张</h2><span class="mt-tag">低于安全库存</span></header>
        <p v-if="!lowParts.length" class="mt-empty" style="padding:18px 20px">库存充足</p>
        <article v-for="part in lowParts" :key="part.part_id" class="mt-part">
          <div>
            <strong>{{ part.part_name }}</strong>
            <small>{{ part.part_code }}<span v-if="part.station_id"> · 场站 {{ part.station_id }}</span></small>
          </div>
          <span class="mt-part-qty">{{ part.stock_qty }}<em>/{{ part.safety_stock }}</em></span>
        </article>

        <header class="mt-card-head"><h2>应急事件</h2><span class="mt-tag">按时间倒序</span></header>
        <p v-if="!incidents.length" class="mt-empty">暂无事件</p>
        <article v-for="item in incidents.slice(0, 5)" :key="item.incident_id" class="mt-incident">
          <div class="mt-incident-top">
            <span class="mt-pill" :class="item.severity.toLowerCase()">{{ item.severity }}</span>
            <span class="mt-status" :class="item.status">{{ INC_STATUS[item.status] || item.status }}</span>
          </div>
          <h3>{{ item.title || item.incident_no }}</h3>
          <p class="mt-meta">
            <span>{{ item.incident_no }}</span>
            <span>告警 {{ item.alert_count }} 条</span>
            <span>未闭环 {{ item.open_work_orders }} 单</span>
            <span>{{ duration(item.detected_at) }}</span>
          </p>
        </article>
      </section>
    </div>

    <!-- 抽屉：告警详情与现场处置 -->
    <transition name="mt-fade">
      <div v-if="selected" class="mt-mask" @click.self="closeDrawer"></div>
    </transition>
    <transition name="mt-slide">
      <aside v-if="selected" class="mt-drawer" role="dialog" aria-modal="true" aria-label="告警详情">
        <header class="mt-drawer-head">
          <div>
            <p class="eyebrow">ALERT #{{ selected.alert_id }}</p>
            <h2>{{ selected.alert_code }}
              <span class="mt-status" :class="selected.status">{{ ALERT_STATUS[selected.status] }}</span>
            </h2>
            <p class="muted">桩 #{{ selected.pile_id }}<span v-if="selected.gun_id"> · 枪 {{ selected.gun_id }}</span>
              · 发生 {{ hm(selected.occurred_at) }} · 响应时限 {{ selected.response_seconds_snapshot }} 秒</p>
          </div>
          <button class="mt-close" aria-label="关闭" @click="closeDrawer">×</button>
        </header>

        <div class="mt-drawer-body">
          <div class="mt-facts">
            <div><span>已持续</span><b>{{ selected.status === 'recovered' ? '—' : duration(selected.occurred_at) }}</b></div>
            <div><span>恢复时间</span><b>{{ selected.recovered_at ? hm(selected.recovered_at) : '未恢复' }}</b></div>
            <div><span>处置工单</span><b>{{ orders.length }}</b></div>
          </div>

          <section class="mt-sop">
            <header>
              <strong>{{ codeName(selected.alert_code) }} · 现场处置提示</strong>
              <span>按告警类型生成</span>
            </header>
            <ol>
              <li v-for="(step, i) in sopOf(selected)" :key="i">{{ step }}</li>
            </ol>
          </section>

          <p v-if="!orders.length" class="mt-empty">该告警还没有派单</p>
          <article v-for="order in orders" :key="order.work_order_id" class="mt-order">
            <header>
              <strong>工单 #{{ order.work_order_id }}</strong>
              <span class="mt-status" :class="order.status">{{ WO_STATUS[order.status] || order.status }}</span>
            </header>
            <p class="mt-meta">
              <span>处理人 {{ order.assigned_to }}</span>
              <span>派单 {{ hm(order.assigned_at) }}</span>
              <span>截止 {{ hm(order.response_due_at) }}</span>
              <span v-if="order.accept_seconds !== null">接单 {{ Math.round(order.accept_seconds / 60) }} 分</span>
              <span v-if="order.escalation_level">已升级 L{{ order.escalation_level }}</span>
            </p>
            <div class="mt-order-actions">
              <button v-for="[type, label] in actionsOf(order)" :key="type"
                      :class="{ primary: type === 'closed' }" :disabled="busy" @click="advance(order, type)">
                {{ label }}
              </button>
              <button class="mt-link" :disabled="busy" @click="toggleTimeline(order)">
                {{ events[order.work_order_id] ? '收起时间线' : '查看时间线' }}
              </button>
            </div>

            <ol v-if="events[order.work_order_id]" class="mt-timeline">
              <li v-for="event in events[order.work_order_id]" :key="event.event_id">
                <i></i>
                <div>
                  <strong>{{ EVT[event.event_type] || event.event_type }}</strong>
                  <span class="mt-status" :class="event.new_status">{{ WO_STATUS[event.new_status] || event.new_status }}</span>
                  <small>{{ hm(event.event_at) }} · {{ event.actor_account_id ? '账号 ' + event.actor_account_id : '系统' }}<span v-if="event.note"> · {{ event.note }}</span></small>
                </div>
              </li>
            </ol>
          </article>
        </div>
      </aside>
    </transition>

    <transition name="mt-fade">
      <div v-if="showConsole" class="mt-console-mask" @click.self="showConsole = false"></div>
    </transition>
    <transition name="mt-console-slide">
      <section v-if="showConsole" class="mt-console-panel" role="dialog" aria-modal="true" aria-label="运维工作台">
        <header class="mt-console-head">
          <div><p class="eyebrow">FULL OPERATIONS</p><h2>运维工作台</h2></div>
          <button class="mt-close" aria-label="关闭" @click="showConsole = false">×</button>
        </header>
        <div class="mt-console-body"><MaintenanceConsole /></div>
      </section>
    </transition>

    <transition name="mt-fade">
      <div v-if="toast" class="mt-toast" :class="{ err: toast.isError }">{{ toast.message }}</div>
    </transition>
  </div>
</template>

<style scoped>
.mt { display: grid; gap: 18px; color: #263632; }
.mt-head { display: flex; justify-content: space-between; align-items: flex-end; gap: 18px; flex-wrap: wrap; }
.mt-head h1 { margin: 4px 0 6px; }
.mt-actions { display: flex; align-items: center; gap: 10px; flex-wrap: wrap; }
.mt-live { display: inline-flex; align-items: center; gap: 7px; font-size: 12px; color: #2c6a50;
  background: #eaf4ed; border: 1px solid #cfe6d6; padding: 7px 12px; border-radius: 999px; }
.mt-select { font-size: 13px; padding: 7px 10px; border: 1px solid #d8e2dc; border-radius: 8px;
  background: #fff; color: #344e41; }
.mt-select:focus-visible { outline: 3px solid #9acaaf; outline-offset: 2px; }
.mt-live i { width: 6px; height: 6px; border-radius: 50%; background: #4f9c72; box-shadow: 0 0 0 3px #d9ecdf; }
.mt-ghost { display: inline-flex; align-items: center; gap: 6px; background: #fff; border: 1px solid #d8e2dc; color: #344e41; }
.mt-ghost:hover { background: #f3f8f4; border-color: #bcd4c4; }
.primary { display: inline-flex; align-items: center; gap: 6px; }

.mt-kpis { display: grid; grid-template-columns: repeat(5, 1fr); gap: 14px; }
.mt-kpi { background: #fff; border: 1px solid #dfe7e1; border-radius: 10px; padding: 16px 18px 14px;
  position: relative; overflow: hidden; transition: transform .15s, box-shadow .15s; }
.mt-kpi:hover { transform: translateY(-1px); box-shadow: 0 8px 22px rgba(23, 101, 76, .08); }
.mt-kpi header { display: flex; align-items: baseline; justify-content: space-between; gap: 8px; }
.mt-kpi header span { font-size: 12.5px; color: #728078; }
.mt-kpi header b { font-size: 28px; font-weight: 650; letter-spacing: -.5px; color: #1d3b31; }
.mt-kpi p { font-size: 11.5px; color: #93a199; margin: 6px 0 12px; }
.mt-bar { height: 3px; border-radius: 2px; background: #eef3ef; overflow: hidden; }
.mt-bar span { display: block; height: 100%; border-radius: 2px; background: #4f9c72; transition: width .4s; }
.mt-kpi.is-red .mt-bar span { background: #b3452f; }
.mt-kpi.is-amber .mt-bar span { background: #b9762a; }
.mt-kpi.is-blue .mt-bar span { background: #3d6b9e; }
.mt-kpi.is-grey .mt-bar span { background: #8a9a91; }

.mt-row { display: grid; grid-template-columns: 1.55fr 1fr; gap: 16px; align-items: start; }
.mt-card-head { display: flex; justify-content: space-between; align-items: flex-start; gap: 10px;
  padding: 18px 20px 0; }
.mt-card-head h2 { font-size: 15px; margin: 0 0 4px; }
.mt-card-head .muted { margin: 0; font-size: 12px; }
.mt-gap { margin-top: 20px; }
.mt-tag { font-size: 10.5px; letter-spacing: 1px; color: #6c8375; background: #f1f5f1;
  border-radius: 4px; padding: 4px 8px; }
.mt-chart { padding-bottom: 14px; }
.mt-trend { width: 100%; height: 170px; display: block; padding: 0 6px; }
.mt-side { padding-bottom: 16px; }

.mt-stack { padding: 16px 20px 0; }
.mt-stack-bar { display: flex; height: 10px; border-radius: 6px; overflow: hidden; background: #f1f5f1; }
.mt-stack-bar span { display: block; height: 100%; }
.mt-legend { list-style: none; margin: 12px 0 0; padding: 0; display: grid; gap: 7px; }
.mt-legend li { display: flex; align-items: center; gap: 8px; font-size: 12.5px; color: #5b6b62; }
.mt-legend i { width: 8px; height: 8px; border-radius: 2px; }
.mt-legend b { margin-left: auto; color: #1d3b31; }
.mt-rank { list-style: none; margin: 12px 0 0; padding: 0 20px; display: grid; gap: 12px; }
.mt-rank li { display: flex; gap: 10px; align-items: flex-start; }
.mt-rank-no { width: 18px; height: 18px; border-radius: 5px; background: #f1f5f1; color: #6c8375;
  font-size: 11px; display: grid; place-items: center; }
.mt-rank-main { flex: 1; }
.mt-rank-label { display: flex; justify-content: space-between; font-size: 12.5px; color: #5b6b62; margin-bottom: 5px; }
.mt-rank-label b { color: #1d3b31; }
.mt-rank-bar { height: 5px; background: #f1f5f1; border-radius: 3px; overflow: hidden; }
.mt-rank-bar span { display: block; height: 100%; background: #7fb494; border-radius: 3px; }

.mt-tabs { display: flex; gap: 6px; }
.mt-tabs button { font-size: 12px; padding: 5px 12px; border-radius: 999px;
  border: 1px solid #dfe7e1; background: #fff; color: #6c7d73; }
.mt-tabs button.on { background: #17654c; border-color: #17654c; color: #fff; }
.mt-code { display: block; font-size: 13px; color: #2b3f37; }
.mt-code-sub { display: block; font-family: Consolas, monospace; font-size: 11px; color: #9aa8b5;
  max-width: 130px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.mt-overdue { display: inline-block; margin-left: 6px; font-size: 11px; color: #a13c28;
  background: #fbeae6; border-radius: 4px; padding: 2px 6px; }
.mt-table-card { padding-bottom: 8px; }
.mt-table { width: 100%; }
.mt-table th { background: #f8faf8; }
.mt-table td { vertical-align: middle; }
.mt-click { cursor: pointer; transition: background .12s; }
.mt-click:hover td { background: #f6faf7; }
.mt-mono { font-family: "SFMono-Regular", Consolas, monospace; font-size: 12.5px; color: #34504a; }
.mt-sub { color: #93a199; }
.mt-time { font-variant-numeric: tabular-nums; color: #5b6b62; font-size: 12.5px; }
.mt-level { display: inline-flex; align-items: center; gap: 6px; font-size: 12px; }
.mt-level i { width: 7px; height: 7px; border-radius: 50%; background: #8a9a91; }
.mt-level.critical i { background: #b3452f; } .mt-level.high i { background: #b9762a; }
.mt-level.medium i { background: #9a8124; } .mt-level.low i { background: #8a9a91; }
.mt-status { display: inline-block; font-size: 11.5px; padding: 3px 8px; border-radius: 5px;
  background: #f1f5f1; color: #6c7d73; white-space: nowrap; }
.mt-status.open { background: #fbeae6; color: #a13c28; }
.mt-status.processing, .mt-status.accepted { background: #eaf0fa; color: #3264a3; }
.mt-status.recovering, .mt-status.repaired, .mt-status.active { background: #e9f3eb; color: #2c6a50; }
.mt-status.recovered, .mt-status.closed, .mt-status.arrived { background: #f1f3f1; color: #7b8780; }
.mt-status.assigned, .mt-status.declared { background: #fdf3e3; color: #9a6b18; }
.mt-pager { display: flex; justify-content: space-between; align-items: center; padding: 14px 20px 12px;
  font-size: 12px; color: #7c8780; }
.mt-pager div { display: flex; gap: 8px; }
.mt-pager button { font-size: 12px; padding: 6px 12px; }

.mt-incidents { padding-bottom: 8px; }
.mt-incident { padding: 14px 20px; border-top: 1px solid #eef2ee; }
.mt-incident-top { display: flex; justify-content: space-between; align-items: center; gap: 10px; }
.mt-pill { font-size: 11px; font-weight: 600; padding: 3px 8px; border-radius: 4px; letter-spacing: .5px; }
.mt-pill.p1 { background: #fbeae6; color: #a13c28; }
.mt-pill.p2 { background: #fdf3e3; color: #9a6b18; }
.mt-pill.p3, .mt-pill.p4 { background: #eef2f0; color: #6c7d73; }
.mt-incident h3 { font-size: 13px; font-weight: 500; line-height: 1.6; margin: 8px 0 6px; color: #2b3f37; }
.mt-meta { display: flex; flex-wrap: wrap; gap: 4px 12px; font-size: 11.5px; color: #8b978f; margin: 0; }
.mt-empty { text-align: center; color: #93a199; font-size: 12.5px; padding: 34px 20px; }

/* 骨架屏 */
.mt-skeleton { background: linear-gradient(90deg, #f2f5f2 25%, #e9efea 37%, #f2f5f2 63%);
  background-size: 400% 100%; animation: mtShine 1.4s ease infinite; border-radius: 6px; }
.mt-skeleton-chart { height: 150px; margin: 16px 20px; }
.mt-skeleton-row { height: 16px; }
@keyframes mtShine { 0% { background-position: 100% 50%; } 100% { background-position: 0 50%; } }

/* 抽屉 */
.mt-mask { position: fixed; inset: 0; background: rgba(18, 44, 34, .38); z-index: 30; }
.mt-drawer { position: fixed; top: 0; right: 0; height: 100vh; width: 470px; max-width: 94vw;
  background: #fff; z-index: 31; display: flex; flex-direction: column;
  box-shadow: -16px 0 48px rgba(16, 42, 34, .18); }
.mt-drawer-head { padding: 22px 24px 18px; border-bottom: 1px solid #e8ede9; display: flex;
  justify-content: space-between; align-items: flex-start; gap: 12px; }
.mt-drawer-head h2 { font-size: 19px; display: flex; align-items: center; gap: 10px; margin: 2px 0 6px; }
.mt-close { border: 0; background: transparent; font-size: 24px; line-height: 1; color: #8b978f; padding: 0 4px; }
.mt-close:hover { background: transparent; color: #2b3f37; }
.mt-drawer-body { padding: 20px 24px 32px; overflow-y: auto; }
.mt-facts { display: grid; grid-template-columns: repeat(3, 1fr); gap: 10px; margin-bottom: 16px; }
.mt-facts div { background: #f7faf8; border: 1px solid #e8ede9; border-radius: 8px; padding: 10px 12px; }
.mt-facts span { display: block; font-size: 11px; color: #8b978f; margin-bottom: 4px; }
.mt-facts b { font-size: 14px; color: #1d3b31; }

.mt-sop { background: #f4f8f5; border: 1px solid #dbe9df; border-radius: 10px; padding: 12px 14px; margin-bottom: 16px; }
.mt-sop header { display: flex; align-items: baseline; justify-content: space-between; gap: 8px; margin-bottom: 8px; }
.mt-sop strong { font-size: 13px; color: #2c6a50; }
.mt-sop header span { font-size: 11px; color: #8b978f; }
.mt-sop ol { margin: 0; padding-left: 18px; display: grid; gap: 6px; }
.mt-sop li { font-size: 12.5px; line-height: 1.55; color: #41544a; }
.mt-order { border: 1px solid #e4ebe6; border-radius: 10px; padding: 13px 14px; margin-bottom: 12px; }
.mt-order header { display: flex; justify-content: space-between; align-items: center; gap: 10px; margin-bottom: 7px; }
.mt-order header strong { font-size: 13px; }
.mt-order .mt-meta { margin-bottom: 0; }
.mt-order-actions { display: flex; gap: 8px; flex-wrap: wrap; margin-top: 11px; }
.mt-order-actions button { font-size: 12px; padding: 7px 12px; }
.mt-link { border: 0; background: transparent; color: #2a7559; padding: 7px 4px; }
.mt-link:hover { background: transparent; text-decoration: underline; }
.mt-timeline { list-style: none; margin: 14px 0 0; padding: 0 0 0 4px; }
.mt-timeline li { position: relative; padding: 0 0 14px 18px; border-left: 2px solid #e8efe9; }
.mt-timeline li:last-child { border-left-color: transparent; padding-bottom: 0; }
.mt-timeline li > i { position: absolute; left: -5px; top: 3px; width: 8px; height: 8px;
  border-radius: 50%; background: #4f9c72; box-shadow: 0 0 0 3px #eef5f0; }
.mt-timeline strong { font-size: 12.5px; margin-right: 7px; }
.mt-timeline small { display: block; color: #8b978f; font-size: 11.5px; margin-top: 4px; }

.mt-console-mask { position: fixed; inset: 0; background: rgba(18, 44, 34, .42); z-index: 44; }
.mt-console-panel { position: fixed; inset: 4vh 3vw; max-width: 1180px; margin: 0 auto; background: #f7faf8;
  border-radius: 12px; box-shadow: 0 24px 70px rgba(16, 42, 34, .28); z-index: 45;
  display: flex; flex-direction: column; overflow: hidden; }
.mt-console-head { display: flex; align-items: flex-start; justify-content: space-between; gap: 12px;
  padding: 16px 22px; background: #fff; border-bottom: 1px solid #e2e9e4; }
.mt-console-head h2 { margin: 2px 0 0; font-size: 18px; }
.mt-console-body { padding: 18px 22px 24px; overflow-y: auto; }
.mt-console-slide-enter-active, .mt-console-slide-leave-active { transition: opacity .18s, transform .18s; }
.mt-console-slide-enter-from, .mt-console-slide-leave-to { opacity: 0; transform: translateY(12px); }

.mt-toast { position: fixed; left: 50%; bottom: 36px; transform: translateX(-50%); z-index: 60;
  background: #123f32; color: #e7f3ea; font-size: 13px; padding: 11px 20px; border-radius: 8px;
  box-shadow: 0 10px 30px rgba(16, 42, 34, .28); }
.mt-toast.err { background: #7a2f24; color: #ffe9e4; }

.mt-fade-enter-active, .mt-fade-leave-active { transition: opacity .18s; }
.mt-fade-enter-from, .mt-fade-leave-to { opacity: 0; }
.mt-slide-enter-active, .mt-slide-leave-active { transition: transform .22s ease; }
.mt-slide-enter-from, .mt-slide-leave-to { transform: translateX(100%); }

@media (max-width: 1200px) {
  .mt-kpis { grid-template-columns: repeat(3, 1fr); }
  .mt-row { grid-template-columns: 1fr; }
}
@media (max-width: 720px) {
  .mt-kpis { grid-template-columns: repeat(2, 1fr); }
  .mt-actions { width: 100%; }
  .mt-facts { grid-template-columns: 1fr; }
}
</style>
