// 页面字段配置集中管理，字段名与后端 Schema 一致；中文标签供表格、表单、详情复用。
const field = (key, label, type = 'text', extra = {}) => ({ key, label, type, ...extra })
const optional = { required: false }
export const resources = [
  { key: 'operators', title: '运营商', id: 'operator_id', editable: true,
    columns: ['operator_id', 'operator_name', 'contact_name', 'phone_masked', 'status'],
    fields: [field('operator_name', '运营商名称'), field('credit_code', '信用代码'), field('contact_name', '联系人'), field('contact_phone', '联系电话')],
    updateFields: [field('operator_name', '运营商名称'), field('contact_name', '联系人'), field('contact_phone', '联系电话', 'text', optional), field('status', '状态', 'select', { options: ['active', 'disabled'] })] },
  { key: 'stations', title: '场站', id: 'station_id', editable: true,
    columns: ['station_id', 'station_name', 'operator_id', 'address', 'status'],
    fields: [field('operator_id', '运营商编号', 'number'), field('station_name', '场站名称'), field('address', '地址'), field('longitude', '经度', 'number'), field('latitude', '纬度', 'number'), field('parking_spaces', '停车位数量', 'number', { default: 0 }), field('business_hours', '营业时间', 'text', { default: '00:00-24:00' }), field('parking_fee_standard', '停车费说明', 'text', { default: '按场站公示标准' })],
    updateExclude: ['operator_id'], status: ['draft', 'active', 'suspended', 'retired'] },
  { key: 'piles', title: '充电桩', id: 'pile_id', editable: true,
    columns: ['pile_id', 'serial_no', 'station_id', 'model_name', 'rated_power_kw', 'lifecycle_status', 'status'],
    fields: [field('station_id', '场站编号', 'number'), field('serial_no', '铭牌序列号'), field('model_name', '设备型号'), field('rated_power_kw', '额定功率（kW）', 'number'), field('protocol', '接入协议'), field('warranty_until', '质保截止日期', 'date', optional)],
    updateExclude: ['station_id', 'serial_no'], status: ['idle', 'occupied', 'fault', 'offline'] },
  { key: 'guns', title: '充电枪', id: 'gun_id', editable: true,
    columns: ['gun_id', 'pile_id', 'gun_no', 'gun_type', 'max_power_kw', 'status', 'has_fault'],
    fields: [field('pile_id', '充电桩编号', 'number'), field('gun_no', '桩内枪序号', 'number'), field('gun_type', '充电类型', 'select', { options: ['dc', 'ac'], default: 'dc' }), field('connector_standard', '接口标准', 'text', { default: 'GB' }), field('max_power_kw', '最大功率（kW）', 'number')],
    updateExclude: ['pile_id', 'gun_no'], status: ['idle', 'occupied', 'fault', 'offline'] },
  { key: 'change-requests', title: '变更申请', id: 'request_id',
    columns: ['request_id', 'pile_id', 'gun_id', 'change_type', 'reason', 'status', 'requested_by'],
    fields: [field('pile_id', '目标桩编号（桩或枪选填一个）', 'number', optional), field('gun_id', '目标枪编号', 'number', optional), field('change_type', '变更类型', 'select', { options: ['archive', 'retrofit', 'relocate', 'retire'], default: 'archive' }), field('proposed_data', '拟修改内容（JSON对象）', 'textarea', { default: '{"model_name":"DC-120"}' }), field('reason', '申请理由', 'textarea')],
    status: ['pending', 'approved', 'rejected'] },
  { key: 'acceptances', title: '设备验收', id: 'acceptance_id',
    columns: ['acceptance_id', 'pile_id', 'result', 'accepted_by', 'accepted_at'],
    fields: [field('pile_id', '充电桩编号', 'number'), field('protocol_test_passed', '协议联调通过', 'checkbox'), field('nameplate_checked', '铭牌核对通过', 'checkbox'), field('start_stop_passed', '启停测试通过', 'checkbox'), field('heartbeat_passed', '心跳测试通过', 'checkbox'), field('note', '验收备注', 'textarea', optional)] },
  { key: 'device-commands', title: '设备命令', id: 'command_id', columns: ['command_id', 'pile_id', 'gun_id', 'order_id', 'command_type', 'status', 'attempt_count'], status: ['pending', 'sent', 'succeeded', 'failed'] },
  { key: 'status-logs', title: '状态历史', id: 'status_log_id', columns: ['status_log_id', 'pile_id', 'gun_id', 'old_status', 'new_status', 'reason', 'occurred_at'] },
]
export const labels = {
  operator_id: '运营商编号', operator_name: '运营商名称', credit_code: '信用代码', contact_name: '联系人', phone_masked: '联系电话',
  station_id: '场站编号', station_name: '场站名称', address: '地址', pile_id: '桩编号', gun_id: '枪编号', gun_no: '枪序号',
  serial_no: '铭牌序列号', model_name: '设备型号', rated_power_kw: '额定功率（kW）', protocol: '协议', max_power_kw: '最大功率（kW）',
  gun_type: '充电类型', connector_standard: '接口标准', status: '状态', lifecycle_status: '生命周期', has_fault: '故障标记', is_online: '通信在线',
  request_id: '申请编号', change_type: '变更类型', reason: '原因', requested_by: '申请人', reviewed_by: '审批人', reviewed_at: '审批时间', review_note: '审批意见',
  acceptance_id: '验收编号', result: '结论', accepted_by: '验收人', accepted_at: '验收时间', note: '备注',
  protocol_test_passed: '协议测试', nameplate_checked: '铭牌核对', start_stop_passed: '启停测试', heartbeat_passed: '心跳测试',
  command_id: '命令编号', order_id: '订单编号', command_type: '命令类型', attempt_count: '发送次数', sent_at: '发送时间', acknowledged_at: '确认时间', error_message: '失败说明',
  status_log_id: '历史编号', old_status: '原状态', new_status: '新状态', occurred_at: '发生时间', actor_account_id: '操作账号',
  created_at: '创建时间', updated_at: '更新时间', last_heartbeat_at: '最后心跳', commissioned_on: '投运日期', warranty_until: '质保截止',
  longitude: '经度', latitude: '纬度', parking_spaces: '停车位', business_hours: '营业时间', parking_fee_standard: '停车费说明',
}
export const values = { draft: '草稿', active: '启用 / 已投运', disabled: '停用', suspended: '暂停', retired: '退役', pending_acceptance: '待验收', idle: '空闲', occupied: '占用', fault: '故障', offline: '离线', pending: '待处理', approved: '已批准', rejected: '已驳回', passed: '通过', failed: '失败', sent: '已发送', succeeded: '成功', start: '启动', stop: '停止', archive: '档案修改', retrofit: '改造', relocate: '迁移', retire: '退役', dc: '直流', ac: '交流' }
export const display = value => value === null || value === undefined ? '—' : typeof value === 'boolean' ? (value ? '是' : '否') : values[value] || value
