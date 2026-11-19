<script setup>
import { onMounted, reactive, ref } from 'vue'
import * as api from '../../api/maintenance'

const tab = ref('rules')
const busy = ref(false)
const error = ref('')
const notice = ref('')

const rules = ref([])
const alerts = ref([])
const reports = ref([])
const inspections = ref([])
const parts = ref([])
const incidents = ref([])
const movements = ref([])
const usages = ref([])
const performance = ref(null)
const result = ref('')
const detail = ref(null)
const detailOrder = ref('')

const ruleForm = reactive({
  rule_code: '', fault_code: '', metric: 'fault_code', threshold_value: '',
  severity: 'low', response_seconds: 600, recovery_seconds: 120, enabled: 1,
})
const editingRule = ref(null)
const dispatchForm = reactive({ alert_id: '', assigned_to: '', note: '' })
const reportForm = reactive({ gun_id: '', order_id: '', description: '' })
const reportHandleForm = reactive({ report_id: '', status: 'linked', alert_id: '', note: '' })
const inspectionForm = reactive({ pile_id: '', result: 'normal', inspected_at: '', parts_used: '', note: '' })
const usageForm = reactive({ work_order_id: '', part_id: '', qty: 1, note: '' })
const stockForm = reactive({ part_id: '', qty: 1, note: '' })
const movementPart = ref('')
const usageOrder = ref('')
const incidentForm = reactive({ operator_id: '', station_id: '', alert_id: '', category: 'hardware', severity: 'P2', title: '' })
const closeForm = reactive({ incident_id: '', summary: '' })
const device = reactive({
  token: '', pile_id: '', reported_at: '', sampled_at: '', offline_seconds: 0,
  voltage: 400, current: 10, power: 4, temperature: 35, fault_code: 'NONE',
})

const num = value => (value === '' || value === null || value === undefined ? null : Number(value))

async function act(action, message = '') {
  if (busy.value) return
  busy.value = true
  error.value = ''
  notice.value = ''
  try {
    await action()
    if (message) notice.value = message
  } catch (e) {
    error.value = e.message
  } finally {
    busy.value = false
  }
}

async function fetchDetail(kind, id) {
  const loaders = {
    rule: api.getAlarmRule,
    alert: api.getAlert,
    order: api.getWorkOrder,
    report: api.getFaultReport,
    inspection: api.getInspection,
  }
  await act(async () => {
    detail.value = await loaders[kind](Number(id))
  }, '详情已加载')
}

async function loadAll() {
  const [r, a, f, i, p, inc] = await Promise.all([
    api.listAlarmRules({ page_size: 20 }),
    api.listAlerts({ page_size: 20 }),
    api.listFaultReports({ page_size: 20 }),
    api.listInspections({ page_size: 20 }),
    api.listSpareParts({ page_size: 20 }),
    api.listIncidents(),
  ])
  rules.value = r.items || []
  alerts.value = a.items || []
  reports.value = f.items || []
  inspections.value = i.items || []
  parts.value = p.items || []
  incidents.value = inc || []
}

async function refreshAll() {
  await act(loadAll, '数据已刷新')
}

function editRule(row) {
  editingRule.value = row.alarm_rule_id
  Object.assign(ruleForm, {
    rule_code: row.rule_code, fault_code: row.fault_code || '', metric: row.metric,
    threshold_value: row.threshold_value ?? '', severity: row.severity,
    response_seconds: row.response_seconds, recovery_seconds: row.recovery_seconds,
    enabled: row.enabled,
  })
}

function resetRule() {
  editingRule.value = null
  Object.assign(ruleForm, {
    rule_code: '', fault_code: '', metric: 'fault_code', threshold_value: '',
    severity: 'low', response_seconds: 600, recovery_seconds: 120, enabled: 1,
  })
}

function rulePayload(includeCode) {
  const payload = {
    metric: ruleForm.metric, severity: ruleForm.severity,
    response_seconds: Number(ruleForm.response_seconds),
    recovery_seconds: Number(ruleForm.recovery_seconds),
    enabled: Number(ruleForm.enabled),
  }
  if (includeCode) payload.rule_code = ruleForm.rule_code.trim()
  if (ruleForm.fault_code) payload.fault_code = ruleForm.fault_code
  if (ruleForm.threshold_value !== '') payload.threshold_value = String(ruleForm.threshold_value)
  return payload
}

async function saveRule() {
  await act(async () => {
    if (editingRule.value) await api.updateAlarmRule(editingRule.value, rulePayload(false))
    else await api.createAlarmRule(rulePayload(true))
    resetRule()
    await loadAll()
  }, '告警规则已保存')
}

async function dispatch() {
  await act(async () => {
    await api.createWorkOrder(Number(dispatchForm.alert_id), {
      assigned_to: Number(dispatchForm.assigned_to),
      ...(dispatchForm.note ? { note: dispatchForm.note } : {}),
    })
    dispatchForm.note = ''
    await loadAll()
  }, '派单成功')
}

async function submitReport() {
  await act(async () => {
    await api.createFaultReport({
      gun_id: Number(reportForm.gun_id),
      ...(reportForm.order_id ? { order_id: Number(reportForm.order_id) } : {}),
      description: reportForm.description,
    })
    reportForm.gun_id = ''
    reportForm.order_id = ''
    reportForm.description = ''
    await loadAll()
  }, '报障已提交')
}

async function handleReport() {
  await act(async () => {
    const payload = { status: reportHandleForm.status }
    if (reportHandleForm.status === 'linked') payload.alert_id = Number(reportHandleForm.alert_id)
    if (reportHandleForm.note) payload.note = reportHandleForm.note
    await api.handleFaultReport(Number(reportHandleForm.report_id), payload)
    await loadAll()
  }, '报障已处理')
}

async function createInspection() {
  await act(async () => {
    const payload = {
      pile_id: Number(inspectionForm.pile_id), result: inspectionForm.result,
    }
    if (inspectionForm.inspected_at) payload.inspected_at = inspectionForm.inspected_at
    if (inspectionForm.parts_used) payload.parts_used = inspectionForm.parts_used
    if (inspectionForm.note) payload.note = inspectionForm.note
    await api.createInspection(payload)
    inspectionForm.pile_id = ''
    inspectionForm.parts_used = ''
    inspectionForm.note = ''
    await loadAll()
  }, '巡检记录已新增')
}

async function usePart() {
  await act(async () => {
    await api.createPartUsage({
      work_order_id: Number(usageForm.work_order_id),
      part_id: Number(usageForm.part_id),
      qty: Number(usageForm.qty),
      ...(usageForm.note ? { note: usageForm.note } : {}),
    })
    usageForm.note = ''
    await loadAll()
    await loadDetails()
  }, '备件领用成功')
}

async function stockIn() {
  await act(async () => {
    await api.stockInPart({
      part_id: Number(stockForm.part_id), qty: Number(stockForm.qty),
      ...(stockForm.note ? { note: stockForm.note } : {}),
    })
    stockForm.note = ''
    await loadAll()
    await loadDetails()
  }, '备件入库成功')
}

async function loadDetails() {
  if (movementPart.value) movements.value = await api.listPartMovements(Number(movementPart.value))
  if (usageOrder.value) usages.value = await api.listPartUsages(Number(usageOrder.value))
}

async function loadPartDetails() {
  await act(loadDetails, '明细已加载')
}

async function declareIncident() {
  await act(async () => {
    const params = {
      operator_id: Number(incidentForm.operator_id),
      category: incidentForm.category,
      severity: incidentForm.severity,
      title: incidentForm.title,
    }
    if (incidentForm.station_id) params.station_id = Number(incidentForm.station_id)
    if (incidentForm.alert_id) params.alert_id = Number(incidentForm.alert_id)
    const created = await api.declareIncident(params)
    incidentForm.title = ''
    notice.value = `事件已声明：#${created.incident_id}`
    await loadAll()
  })
}

async function escalateIncidents() {
  await act(async () => {
    const data = await api.escalateIncidents()
    result.value = JSON.stringify(data, null, 2)
    await loadAll()
    notice.value = `升级扫描完成：${data.escalated ?? 0} 条`
  })
}

async function closeIncident() {
  await act(async () => {
    await api.closeIncident(Number(closeForm.incident_id), closeForm.summary)
    closeForm.incident_id = ''
    closeForm.summary = ''
    await loadAll()
  }, '事件已关闭')
}

async function loadPerformance() {
  await act(async () => {
    performance.value = await api.getPerformance()
  }, '绩效数据已加载')
}

async function heartbeat() {
  await act(async () => {
    const payload = { pile_id: Number(device.pile_id), offline_seconds: Number(device.offline_seconds) }
    if (device.reported_at) payload.reported_at = device.reported_at
    result.value = JSON.stringify(await api.sendHeartbeat(payload, device.token.trim()), null, 2)
  }, '心跳上报成功')
}

async function uploadReading() {
  await act(async () => {
    const payload = {
      pile_id: Number(device.pile_id), sampled_at: device.sampled_at,
      output_voltage_v: String(device.voltage), output_current_a: String(device.current),
      power_kw: String(device.power), module_temperature_c: String(device.temperature),
      offline_seconds: Number(device.offline_seconds), fault_code: device.fault_code,
    }
    result.value = JSON.stringify(await api.uploadDeviceReading(payload, device.token.trim()), null, 2)
    await loadAll()
  }, '采样上报成功')
}

onMounted(refreshAll)
</script>

<template>
  <div class="ops">
    <div class="ops-head">
      <div><p class="eyebrow">MAINTENANCE OPERATIONS</p><h2>运维工作台</h2></div>
      <button class="primary" :disabled="busy" @click="refreshAll">刷新全部</button>
    </div>
    <p v-if="error" class="ops-error">{{ error }}</p>
    <p v-if="notice" class="ops-notice">{{ notice }}</p>

    <div class="ops-tabs">
      <button v-for="item in [
        ['rules', '告警规则'], ['dispatch', '派单与报障'], ['inspection', '巡检'],
        ['parts', '备件'], ['incident', '应急与绩效'], ['device', '设备上报']
      ]" :key="item[0]" :class="{ on: tab === item[0] }" @click="tab = item[0]">{{ item[1] }}</button>
    </div>

    <section v-if="tab === 'rules'" class="ops-grid">
      <form class="ops-card" @submit.prevent="saveRule">
        <h3>{{ editingRule ? '修改告警规则' : '新增告警规则' }}</h3>
        <label>规则码<input v-model="ruleForm.rule_code" :disabled="!!editingRule" required maxlength="50"></label>
        <label>故障码<input v-model="ruleForm.fault_code" maxlength="32" placeholder="温度/心跳规则可留空"></label>
        <label>指标<select v-model="ruleForm.metric"><option value="fault_code">故障码</option><option value="temperature">温度阈值</option><option value="heartbeat">心跳超时</option></select></label>
        <label>阈值<input v-model="ruleForm.threshold_value" type="number" step="any"></label>
        <label>等级<select v-model="ruleForm.severity"><option value="low">低</option><option value="medium">中</option><option value="high">高</option><option value="critical">严重</option></select></label>
        <label>响应秒数<input v-model="ruleForm.response_seconds" type="number" min="1" required></label>
        <label>恢复秒数<input v-model="ruleForm.recovery_seconds" type="number" min="1" required></label>
        <label>启用<select v-model.number="ruleForm.enabled"><option :value="1">是</option><option :value="0">否</option></select></label>
        <div class="ops-actions"><button type="submit" class="primary" :disabled="busy">保存</button><button type="button" :disabled="busy" @click="resetRule">重置</button></div>
      </form>
      <div class="ops-card ops-table">
        <h3>规则列表（{{ rules.length }}）</h3>
        <table><thead><tr><th>规则码</th><th>指标</th><th>等级</th><th>响应/恢复</th><th>操作</th></tr></thead>
          <tbody><tr v-for="row in rules" :key="row.alarm_rule_id"><td>{{ row.rule_code }}</td><td>{{ row.metric }}</td><td>{{ row.severity }}</td><td>{{ row.response_seconds }}/{{ row.recovery_seconds }}</td><td><button :disabled="busy" @click="fetchDetail('rule', row.alarm_rule_id)">详情</button> <button :disabled="busy" @click="editRule(row)">修改</button></td></tr></tbody>
        </table>
      </div>
    </section>

    <section v-if="tab === 'dispatch'" class="ops-grid">
      <form class="ops-card" @submit.prevent="dispatch">
        <h3>派单</h3>
        <label>告警<select v-model="dispatchForm.alert_id" required><option value="">请选择</option><option v-for="a in alerts" :key="a.alert_id" :value="a.alert_id">#{{ a.alert_id }} {{ a.alert_code }} / 桩{{ a.pile_id }}</option></select></label>
        <label>维修人员账号<input v-model="dispatchForm.assigned_to" type="number" min="1" required></label>
        <label>备注<input v-model="dispatchForm.note" maxlength="500"></label>
        <button class="primary" :disabled="busy">创建工单</button>
      </form>
      <div class="ops-card">
        <h3>单条详情查询</h3>
        <label>告警编号<input v-model="dispatchForm.alert_id" type="number" min="1"></label>
        <button :disabled="busy || !dispatchForm.alert_id" @click="fetchDetail('alert', dispatchForm.alert_id)">查看告警详情</button>
        <label>工单编号<input v-model="detailOrder" type="number" min="1"></label>
        <button :disabled="busy || !detailOrder" @click="fetchDetail('order', detailOrder)">查看工单详情</button>
      </div>
      <form class="ops-card" @submit.prevent="submitReport">
        <h3>提交报障</h3>
        <label>枪编号<input v-model="reportForm.gun_id" type="number" min="1" required></label>
        <label>订单编号（可选）<input v-model="reportForm.order_id" type="number" min="1"></label>
        <label>问题描述<textarea v-model="reportForm.description" minlength="5" maxlength="1000" rows="3" required></textarea></label>
        <button class="primary" :disabled="busy">提交报障</button>
      </form>
      <form class="ops-card" @submit.prevent="handleReport">
        <h3>处理报障</h3>
        <label>报障编号<input v-model="reportHandleForm.report_id" type="number" min="1" required></label>
        <label>处理结果<select v-model="reportHandleForm.status"><option value="linked">关联告警</option><option value="resolved">办结</option></select></label>
        <label v-if="reportHandleForm.status === 'linked'">告警编号<input v-model="reportHandleForm.alert_id" type="number" min="1" required></label>
        <label>处理意见<input v-model="reportHandleForm.note" maxlength="500"></label>
        <button class="primary" :disabled="busy">提交处理</button>
      </form>
      <div class="ops-card ops-table">
        <h3>最近报障</h3>
        <table><thead><tr><th>编号</th><th>枪</th><th>状态</th><th>描述</th><th>操作</th></tr></thead>
          <tbody><tr v-for="row in reports" :key="row.report_id"><td>#{{ row.report_id }}</td><td>{{ row.gun_id }}</td><td>{{ row.status }}</td><td>{{ row.description }}</td><td><button :disabled="busy" @click="fetchDetail('report', row.report_id)">详情</button></td></tr></tbody>
        </table>
      </div>
    </section>

    <section v-if="tab === 'inspection'" class="ops-grid">
      <form class="ops-card" @submit.prevent="createInspection">
        <h3>新增巡检</h3>
        <label>桩编号<input v-model="inspectionForm.pile_id" type="number" min="1" required></label>
        <label>结论<select v-model="inspectionForm.result"><option value="normal">正常</option><option value="abnormal">异常</option></select></label>
        <label>巡检时间（UTC，可选）<input v-model="inspectionForm.inspected_at" placeholder="2026-11-19T10:00:00"></label>
        <label>更换备件<input v-model="inspectionForm.parts_used" maxlength="500"></label>
        <label>说明<textarea v-model="inspectionForm.note" maxlength="1000" rows="3"></textarea></label>
        <button class="primary" :disabled="busy">保存巡检</button>
      </form>
      <div class="ops-card ops-table">
        <h3>最近巡检</h3>
        <table><thead><tr><th>编号</th><th>桩</th><th>结论</th><th>时间</th><th>操作</th></tr></thead>
          <tbody><tr v-for="row in inspections" :key="row.inspection_id"><td>#{{ row.inspection_id }}</td><td>{{ row.pile_id }}</td><td>{{ row.result }}</td><td>{{ row.inspected_at }}</td><td><button :disabled="busy" @click="fetchDetail('inspection', row.inspection_id)">详情</button></td></tr></tbody>
        </table>
      </div>
    </section>

    <section v-if="tab === 'parts'" class="ops-grid">
      <form class="ops-card" @submit.prevent="usePart">
        <h3>备件领用</h3>
        <label>工单编号<input v-model="usageForm.work_order_id" type="number" min="1" required></label>
        <label>备件<select v-model="usageForm.part_id" required><option value="">请选择</option><option v-for="p in parts" :key="p.part_id" :value="p.part_id">{{ p.part_name }}（库存 {{ p.stock_qty }}）</option></select></label>
        <label>数量<input v-model="usageForm.qty" type="number" min="1" max="999" required></label>
        <label>备注<input v-model="usageForm.note" maxlength="500"></label>
        <button class="primary" :disabled="busy">领用</button>
      </form>
      <form class="ops-card" @submit.prevent="stockIn">
        <h3>备件入库</h3>
        <label>备件<select v-model="stockForm.part_id" required><option value="">请选择</option><option v-for="p in parts" :key="p.part_id" :value="p.part_id">{{ p.part_name }}</option></select></label>
        <label>数量<input v-model="stockForm.qty" type="number" min="1" max="9999" required></label>
        <label>备注<input v-model="stockForm.note" maxlength="255"></label>
        <button class="primary" :disabled="busy">入库</button>
      </form>
      <form class="ops-card" @submit.prevent="loadPartDetails">
        <h3>出入库明细</h3>
        <label>按备件查流水<select v-model="movementPart"><option value="">请选择</option><option v-for="p in parts" :key="p.part_id" :value="p.part_id">{{ p.part_name }}</option></select></label>
        <label>按工单查领用<input v-model="usageOrder" type="number" min="1"></label>
        <button :disabled="busy">查询明细</button>
        <pre class="ops-result">{{ JSON.stringify({ movements, usages }, null, 2) }}</pre>
      </form>
      <div class="ops-card ops-table">
        <h3>备件库存</h3>
        <table><thead><tr><th>编号</th><th>名称</th><th>库存</th><th>安全线</th></tr></thead>
          <tbody><tr v-for="row in parts" :key="row.part_id"><td>#{{ row.part_id }}</td><td>{{ row.part_name }}</td><td>{{ row.stock_qty }}</td><td>{{ row.safety_stock }}</td></tr></tbody>
        </table>
      </div>
    </section>

    <section v-if="tab === 'incident'" class="ops-grid">
      <form class="ops-card" @submit.prevent="declareIncident">
        <h3>声明应急事件</h3>
        <label>运营商编号<input v-model="incidentForm.operator_id" type="number" min="1" required></label>
        <label>场站编号（跨场站留空）<input v-model="incidentForm.station_id" type="number" min="1"></label>
        <label>根因告警编号（可选）<input v-model="incidentForm.alert_id" type="number" min="1"></label>
        <label>类别<select v-model="incidentForm.category"><option v-for="c in ['power','communication','hardware','software','security','other']" :key="c" :value="c">{{ c }}</option></select></label>
        <label>级别<select v-model="incidentForm.severity"><option v-for="v in ['P1','P2','P3','P4']" :key="v" :value="v">{{ v }}</option></select></label>
        <label>标题<input v-model="incidentForm.title" minlength="2" maxlength="200" required></label>
        <button class="primary" :disabled="busy">声明事件</button>
      </form>
      <form class="ops-card" @submit.prevent="closeIncident">
        <h3>关闭应急事件</h3>
        <label>事件编号<input v-model="closeForm.incident_id" type="number" min="1" required></label>
        <label>关闭说明<textarea v-model="closeForm.summary" minlength="2" maxlength="1000" rows="3" required></textarea></label>
        <button class="primary" :disabled="busy">关闭事件</button>
        <button type="button" :disabled="busy" @click="escalateIncidents">执行升级扫描</button>
      </form>
      <div class="ops-card ops-table">
        <h3>事件看板</h3>
        <table><thead><tr><th>编号</th><th>级别</th><th>状态</th><th>场站</th><th>未闭环</th></tr></thead>
          <tbody><tr v-for="row in incidents" :key="row.incident_id"><td>{{ row.incident_no }}</td><td>{{ row.severity }}</td><td>{{ row.status }}</td><td>{{ row.station_name || '跨场站' }}</td><td>{{ row.open_work_orders }}</td></tr></tbody>
        </table>
      </div>
      <div class="ops-card">
        <h3>运维绩效</h3>
        <button :disabled="busy" @click="loadPerformance">加载绩效</button>
        <pre class="ops-result">{{ performance ? JSON.stringify(performance, null, 2) : '尚未加载' }}</pre>
      </div>
    </section>

    <section v-if="tab === 'device'" class="ops-grid">
      <form class="ops-card" @submit.prevent="heartbeat">
        <h3>设备心跳</h3>
        <label>设备凭据<input v-model="device.token" type="password" autocomplete="off" required></label>
        <label>桩编号<input v-model="device.pile_id" type="number" min="1" required></label>
        <label>上报时间（UTC，可选）<input v-model="device.reported_at" placeholder="2026-11-19T10:00:00"></label>
        <label>离线秒数<input v-model="device.offline_seconds" type="number" min="0" max="2678400"></label>
        <button class="primary" :disabled="busy">发送心跳</button>
      </form>
      <form class="ops-card" @submit.prevent="uploadReading">
        <h3>运行采样</h3>
        <label>设备凭据<input v-model="device.token" type="password" autocomplete="off" required></label>
        <label>桩编号<input v-model="device.pile_id" type="number" min="1" required></label>
        <label>采样时间（UTC）<input v-model="device.sampled_at" placeholder="2026-11-19T10:00:00" required></label>
        <label>电压 V<input v-model="device.voltage" type="number" step="any"></label>
        <label>电流 A<input v-model="device.current" type="number" step="any"></label>
        <label>功率 kW<input v-model="device.power" type="number" step="any"></label>
        <label>模块温度 ℃<input v-model="device.temperature" type="number" step="any"></label>
        <label>故障码<input v-model="device.fault_code" maxlength="32"></label>
        <button class="primary" :disabled="busy">上报采样</button>
      </form>
      <div class="ops-card ops-wide">
        <h3>最近返回结果</h3>
        <pre class="ops-result">{{ result || '尚未执行设备上报' }}</pre>
      </div>
    </section>

    <section class="ops-card ops-wide">
      <h3>单条详情</h3>
      <pre class="ops-result">{{ detail ? JSON.stringify(detail, null, 2) : '点击列表中的「详情」查看单条记录' }}</pre>
    </section>
  </div>
</template>

<style scoped>
.ops { display: grid; gap: 14px; color: #263632; }
.ops-head { display: flex; align-items: flex-end; justify-content: space-between; gap: 12px; }
.ops-head h2 { margin: 2px 0 0; font-size: 19px; }
.eyebrow { margin: 0; font-size: 10px; letter-spacing: 1.4px; color: #8b978f; }
.ops-error, .ops-notice { margin: 0; padding: 8px 12px; border-radius: 6px; font-size: 12px; }
.ops-error { background: #fbeae6; color: #a13c28; }
.ops-notice { background: #eaf4ed; color: #2c6a50; }
.ops-tabs { display: flex; flex-wrap: wrap; gap: 6px; border-bottom: 1px solid #e6ece7; padding-bottom: 8px; }
.ops-tabs button { border: 1px solid #dfe7e1; background: #fff; color: #5b6b62; border-radius: 999px; padding: 6px 12px; font-size: 12px; }
.ops-tabs button.on { background: #17654c; border-color: #17654c; color: #fff; }
.ops-grid { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 14px; align-items: start; }
.ops-card { background: #fff; border: 1px solid #e2e9e4; border-radius: 10px; padding: 16px; display: grid; gap: 10px; }
.ops-card h3 { margin: 0; font-size: 14px; }
.ops-card label { display: grid; gap: 5px; font-size: 12px; color: #5b6b62; }
.ops-card input, .ops-card select, .ops-card textarea { border: 1px solid #d8e2dc; border-radius: 7px; padding: 7px 9px; font-size: 13px; color: #263632; background: #fff; }
.ops-card textarea { resize: vertical; }
.ops-actions, .ops-card > button { display: flex; gap: 8px; }
.ops-card > button { justify-content: center; }
.ops-table { overflow-x: auto; }
.ops-table table { width: 100%; border-collapse: collapse; font-size: 12px; }
.ops-table th, .ops-table td { text-align: left; padding: 7px 8px; border-bottom: 1px solid #eef2ee; }
.ops-table th { background: #f8faf8; color: #6c7d73; }
.ops-result { margin: 0; max-height: 240px; overflow: auto; background: #f7faf8; border-radius: 6px; padding: 10px; font-size: 11px; white-space: pre-wrap; }
.ops-wide { grid-column: 1 / -1; }
@media (max-width: 900px) { .ops-grid { grid-template-columns: 1fr; } }
</style>
