import { createRouter, createWebHistory } from 'vue-router'
import AppShell from './components/AppShell.vue'
import LoginPage from './views/LoginPage.vue'
import RegisterPage from './views/RegisterPage.vue'
import ResourcePage from './views/ResourcePage.vue'
import WalletRefundPage from './views/WalletRefundPage.vue'
import AppealsPage from './views/AppealsPage.vue'

const routes = [
  { path: '/login', name: 'login', component: LoginPage, meta: { public: true, title: '登录' } },
  { path: '/register', name: 'register', component: RegisterPage, meta: { public: true, title: '注册' } },
  {
    path: '/', component: AppShell, children: [
      { path: '', redirect: '/membership/profile' },
      { path: 'auth/accounts', name: 'accounts', component: ResourcePage, meta: { title: '账号管理', resource: 'accounts' } },
      { path: 'auth/roles', name: 'roles', component: ResourcePage, meta: { title: '角色与权限', resource: 'roles' } },
      { path: 'membership/profile', name: 'profile', component: ResourcePage, meta: { title: '个人档案', resource: 'profile' } },
      { path: 'membership/vehicles', name: 'vehicles', component: ResourcePage, meta: { title: '车辆管理', resource: 'vehicles' } },
      { path: 'membership/coupons', name: 'coupons', component: ResourcePage, meta: { title: '我的优惠券', resource: 'coupons' } },
      { path: 'membership/promotions', name: 'promotions', component: ResourcePage, meta: { title: '优惠活动', resource: 'promotions' } },
      { path: 'membership/fleets', name: 'fleets', component: ResourcePage, meta: { title: '车队管理', resource: 'fleets' } },
      { path: 'membership/fleets/:fleetId', name: 'fleet-detail', component: ResourcePage, meta: { title: '车队详情', resource: 'fleet-detail' } },
      { path: 'membership/fleet-cards', name: 'fleet-cards', component: ResourcePage, meta: { title: '车队卡', resource: 'fleet-cards' } },
      { path: 'membership/fleet-authorizations', name: 'fleet-authorizations', component: ResourcePage, meta: { title: '车辆授权与额度', resource: 'fleet-authorizations' } },
      { path: 'membership/wallet', name: 'wallet', component: ResourcePage, meta: { title: '钱包流水', resource: 'wallet' } },
      { path: 'membership/wallet/refund-requests', name: 'wallet-refunds', component: WalletRefundPage, meta: { title: '余额退款申请' } },
      { path: 'membership/feedbacks', name: 'feedbacks', component: ResourcePage, meta: { title: '服务评价', resource: 'feedbacks' } },
      { path: 'membership/appeals', name: 'appeals', component: AppealsPage, meta: { title: '服务申诉跟踪' } },
    ],
  },
]

const router = createRouter({ history: createWebHistory(), routes })

router.beforeEach((to) => {
  const token = localStorage.getItem('member4.access_token')
  if (!to.meta.public && !token) return { path: '/login', query: { next: to.fullPath } }
  if (to.meta.public && token && to.name === 'login') return '/membership/profile'
  return true
})

export default router
