import { request } from './http'

const base = '/settlement'
const read = (token, path, filters = {}) => request(base + path + '?' + new URLSearchParams(filters), { token })
export const submitSettlement = (token, path, body, key) =>
  request(base + path, { token, method: 'POST', body, key })

export const listSettlements = (token, query) =>
  read(token, "/settlements", query)
export const getSettlement = (token, id) =>
  read(token, `/settlements/${encodeURIComponent(id)}`)
export const listDifferences = (token, query) =>
  read(token, "/differences", query)
export const getDifference = (token, id) =>
  read(token, `/differences/${encodeURIComponent(id)}`)
export const createDifference = (token, body, key) =>
  submitSettlement(token, "/differences", body, key)
export const listOperatorInvoices = (token, query) =>
  read(token, "/operator-invoices", query)
export const getOperatorInvoice = (token, id) =>
  read(token, `/operator-invoices/${encodeURIComponent(id)}`)
export const listUserInvoices = (token, query) =>
  read(token, "/user-invoices", query)
export const getUserInvoice = (token, id) =>
  read(token, `/user-invoices/${encodeURIComponent(id)}`)
export const listFleetBills = (token, query) =>
  read(token, "/fleet-bills", query)
export const getFleetBill = (token, id) =>
  read(token, `/fleet-bills/${encodeURIComponent(id)}`)
export const listFleetPrices = (token, query) =>
  read(token, "/fleet-prices", query)
export const getFleetPrice = (token, id) =>
  read(token, `/fleet-prices/${encodeURIComponent(id)}`)
export const createFleetPrice = (token, body, key) =>
  submitSettlement(token, "/fleet-prices", body, key)
export const listSettlementPolicies = (token, query) =>
  read(token, "/policies", query)
export const getSettlementPolicy = (token, id) =>
  read(token, `/policies/${encodeURIComponent(id)}`)
export const createSettlementPolicy = (token, body, key) =>
  submitSettlement(token, "/policies", body, key)
export const generateSettlement = (token, body, key) =>
  submitSettlement(token, "/settlements", body, key)
export const confirmSettlement = (token, id, body, key) =>
  submitSettlement(token, `/settlements/${encodeURIComponent(id)}/confirmations`, body, key)
export const adjustSettlement = (token, id, body, key) =>
  submitSettlement(token, `/settlements/${encodeURIComponent(id)}/adjustments`, body, key)
export const reviewSettlementAdjustment = (token, id, body, key) =>
  submitSettlement(token, `/adjustments/${encodeURIComponent(id)}/reviews`, body, key)
export const resolveDifference = (token, id, body, key) =>
  submitSettlement(token, `/differences/${encodeURIComponent(id)}/resolutions`, body, key)
export const confirmDifference = (token, id, body, key) =>
  submitSettlement(token, `/differences/${encodeURIComponent(id)}/confirmations`, body, key)
export const issueOperatorInvoice = (token, id, body, key) =>
  submitSettlement(token, `/settlements/${encodeURIComponent(id)}/invoices`, body, key)
export const redIssueOperatorInvoice = (token, id, body, key) =>
  submitSettlement(token, `/operator-invoices/${encodeURIComponent(id)}/red-issues`, body, key)
export const requestUserInvoice = (token, body, key) =>
  submitSettlement(token, "/user-invoices", body, key)
export const processUserInvoice = (token, id, body, key) =>
  submitSettlement(token, `/user-invoices/${encodeURIComponent(id)}/processing`, body, key)
export const redIssueUserInvoice = (token, id, body, key) =>
  submitSettlement(token, `/user-invoices/${encodeURIComponent(id)}/red-issues`, body, key)
export const generateFleetBill = (token, body, key) =>
  submitSettlement(token, "/fleet-bills", body, key)
export const recordFleetBillPayment = (token, id, body, key) =>
  submitSettlement(token, `/fleet-bills/${encodeURIComponent(id)}/payments`, body, key)
