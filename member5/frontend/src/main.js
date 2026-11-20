import { createApp } from 'vue'
import { createRouter, createWebHistory } from 'vue-router'
import App from './App.vue'
import SettlementList from './views/settlement/SettlementList.vue'
import ModulePage from './views/settlement/ModulePage.vue'
import './style.css'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    { path: '/', redirect: { name: 'SettlementList' } },
    { path: '/settlement/settlements', name: 'SettlementList', component: SettlementList },
    { path: '/settlement/settlements/:settlementId(\\d+)', name: 'SettlementDetail', component: SettlementList,
      meta: { section: 'SettlementList' } },
    ...[
      ['differences', 'DifferenceList'], ['invoices', 'InvoiceList'], ['user-invoices', 'UserInvoiceList'],
      ['fleet-bills', 'FleetBillList'], ['fleet-bills/:billId(\\d+)', 'FleetBillDetail'],
      ['fleet-prices', 'FleetPriceList'], ['policies', 'SettlementPolicyList'],
      ['adjustments', 'AdjustmentList'],
    ].map(([path, name]) => ({
      path: '/settlement/' + path, name, component: ModulePage,
      meta: { section: name === 'FleetBillDetail' ? 'FleetBillList' : name },
    })),
  ],
})
createApp(App).use(router).mount('#app')
