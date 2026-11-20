import * as api from '../../api/settlement'

const staff = ['customer_service']
const admin = ['platform_admin']
const platform = [...admin, ...staff]
const parties = [...admin, 'operator_manager']
const field = (name, label, type = 'text', extra = {}) => ({ name, label, type, ...extra })
const id = (name, label, extra) => field(name, label, 'id', extra)
const money = (name = 'amount', label = '金额（元）') => field(name, label, 'money')
const options = (name, label, values) => field(name, label, 'select', { values })
const note = (name, label, optional = false) => field(name, label, 'text', { optional })
const red = [money(), note('reason', '红冲原因')]
const period = [field('valid_from', '生效时间（北京时间）', 'datetime-local'),
  field('valid_until', '失效时间（北京时间）', 'datetime-local')]
const confirm = [options('decision', '确认结果', { confirmed: '同意', disputed: '有异议' }), note('note', '意见', true)]
const columns = {
  difference: { difference_id: '差异单', settlement_id: '结算单', order_id: '订单',
    difference_type: '类型', amount: '金额', resolution: '处理结论', version: '版本', status: '状态' },
  invoice: { invoice_id: '发票', settlement_id: '结算单', invoice_no: '票号', invoice_type: '票种',
    title: '抬头', amount: '金额', issued_at: '开票时间' },
  user: { user_invoice_id: '发票', user_id: '车主', invoice_no: '票号', invoice_type: '票种',
    title: '抬头', amount: '金额', status: '状态' },
  bill: { bill_id: '月结单', fleet_id: '车队', bill_month: '账期', order_amount: '订单金额',
    adjustment_amount: '抵扣或调整', payable_amount: '应收', paid_amount: '现金实收', status: '状态' },
  price: { price_id: '专价', fleet_id: '车队', period_id: '时段', electricity_rate: '电费单价',
    service_rate: '服务费单价', valid_from: '生效时间', valid_until: '失效时间', status: '状态' },
  policy: { policy_id: '政策', operator_id: '运营商', station_id: '场站',
    electricity_share_rate: '电费分成', service_share_rate: '服务费分成',
    platform_fee_rate: '平台费率', valid_from: '生效时间', valid_until: '失效时间' },
}
const action = (label, roles, path, fields, when = () => true, payload = body => body) =>
  ({ label, roles, path, fields, when, payload })
const month = field('bill_month', '账期', 'month')
const fleet = id('fleet_id', '车队编号')
const operator = id('operator_id', '运营商编号')
const station = id('station_id', '场站编号')
const invoiceHeader = [note('title', '发票抬头'), note('tax_no', '税号', true)]
const receive = action('登记收款', staff, row => `/fleet-bills/${row.bill_id}/payments`,
  [note('external_trade_no', '外部流水号'), money()], row => ['issued', 'partially_paid'].includes(row.status))
const statuses = values => options('status', '状态', values)
const redOn = (base, key) => action('红冲', base === 'user-invoices' ? staff : platform,
  row => `/${base}/${row[key]}/red-issues`, red, row => row.invoice_type === 'blue' && row.status === 'issued')
const fleetRoles = [...staff, 'fleet_admin']

export const pages = {
  AdjustmentList: { title: '结算调整', roles: [...platform, 'operator_manager'], key: 'adjustment_id',
    list: api.listAdjustments, detail: api.getAdjustment,
    columns: { adjustment_id: '申请编号', settlement_id: '结算单', difference_id: '差异单', amount: '调整金额',
      reason: '申请原因', requested_by: '申请人', status: '状态', approved_by: '审批人', approved_at: '审批时间' },
    filters: [id('settlement_id', '结算单'), statuses({ pending: '待审批', approved: '已批准', rejected: '已驳回' })],
    actions: [action('审批调整', admin, row => `/adjustments/${row.adjustment_id}/reviews`,
      [options('decision', '审批结果', { approved: '批准', rejected: '驳回' }), note('note', '审批依据')],
      row => row.status === 'pending')] },
  DifferenceList: { title: '对账差异', roles: [...platform, 'operator_manager'], key: 'difference_id',
    list: api.listDifferences, detail: api.getDifference, columns: columns.difference,
    filters: [id('settlement_id', '结算单'), statuses({ open: '待处理', pending_confirmation: '待确认', effective: '已生效', rejected: '有异议' })],
    create: action('创建差异', staff, () => '/differences',
      [id('settlement_id', '结算单编号'), id('order_id', '订单编号'),
        options('difference_type', '差异类型', { energy: '电量', price: '价格', payment: '支付' }), money()]),
    actions: [
      action('提交处理结论', staff, row => `/differences/${row.difference_id}/resolutions`,
        [note('resolution', '处理结论')], row => row.status !== 'effective',
        (body, row) => ({ ...body, object_version: row.version })),
      action('确认差异', parties, row => `/differences/${row.difference_id}/confirmations`, confirm,
        row => row.status === 'pending_confirmation', (body, row) => ({ ...body, object_version: row.version })),
      action('申请调整', platform, row => `/settlements/${row.settlement_id}/adjustments`,
        [money(), note('reason', '调整原因')], row => row.status === 'effective',
        (body, row) => ({ ...body, difference_id: row.difference_id })),
    ],
    },
  InvoiceList: { title: '运营商发票', roles: [...platform, 'operator_manager'], key: 'invoice_id',
    list: api.listOperatorInvoices, detail: api.getOperatorInvoice, columns: columns.invoice,
    filters: [id('settlement_id', '结算单')], actions: [redOn('operator-invoices', 'invoice_id')] },
  UserInvoiceList: { title: '车主发票', roles: [...staff, 'vehicle_owner'], key: 'user_invoice_id',
    list: api.listUserInvoices, detail: api.getUserInvoice, columns: columns.user,
    filters: [statuses({ requested: '待办理', issued: '已开具', rejected: '已拒绝', red_issued: '已红冲' })],
    create: action('申请消费发票', ['vehicle_owner'], () => '/user-invoices',
      [...invoiceHeader, field('items', '订单分配', 'allocations')]),
    actions: [
      action('办理申请', staff, row => `/user-invoices/${row.user_invoice_id}/processing`,
        [options('decision', '办理结果', { issued: '开票', rejected: '拒绝' }), note('note', '办理说明', true)],
        row => row.status === 'requested'),
      redOn('user-invoices', 'user_invoice_id'),
    ] },
  FleetBillList: { title: '车队月结', roles: fleetRoles, key: 'bill_id', list: api.listFleetBills,
    detail: api.getFleetBill, route: 'FleetBillDetail', columns: columns.bill,
    filters: [fleet, month, statuses({ issued: '已出账', partially_paid: '部分收款', paid: '已收款', closed: '已关闭' })],
    create: action('生成月结单', staff, () => '/fleet-bills', [fleet, month]), actions: [receive] },
  FleetPriceList: { title: '车队专价', roles: [...platform, 'fleet_admin'], key: 'price_id', list: api.listFleetPrices,
    detail: api.getFleetPrice, columns: columns.price, filters: [fleet, id('period_id', '计费时段')],
    tip: '新建专价为草稿，接入小组的价格审批后才能启用。',
    create: action('新建专价草稿', platform, () => '/fleet-prices',
      [fleet, id('period_id', '计费时段'), money('electricity_rate', '电费单价'), money('service_rate', '服务费单价'), ...period]) },
  SettlementPolicyList: { title: '结算分成政策', roles: admin, key: 'policy_id', list: api.listSettlementPolicies,
    detail: api.getSettlementPolicy, columns: columns.policy, filters: [operator, station],
    create: action('新建分成政策', admin, () => '/policies',
      [operator, station, money('electricity_share_rate', '电费分成比例'), money('service_share_rate', '服务费分成比例'),
        money('platform_fee_rate', '平台费比例'), ...period], undefined,
      body => ({ ...body, payment_basis: 'paid_only' })) },
}

export const billItems = { bill_item_id: '明细', order_id: '订单', refund_id: '退款', item_type: '类型',
  amount: '金额', original_order_finished_at: '订单结束时间' }
