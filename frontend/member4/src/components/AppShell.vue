<script setup>
import { computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { api, clearSession, currentAccount } from '../api'

const route = useRoute()
const router = useRouter()
const account = computed(() => currentAccount())
const navigation = [
  { label: '个人档案', to: '/membership/profile', roles: ['vehicle_owner'] },
  { label: '车辆管理', to: '/membership/vehicles', roles: ['vehicle_owner'] },
  { label: '优惠活动', to: '/membership/promotions', roles: ['vehicle_owner', 'customer_service', 'platform_admin'] },
  { label: '我的优惠券', to: '/membership/coupons', roles: ['vehicle_owner', 'customer_service', 'platform_admin'] },
  { label: '钱包流水', to: '/membership/wallet', roles: ['vehicle_owner'] },
  { label: '余额退款', to: '/membership/wallet/refund-requests', roles: ['vehicle_owner', 'customer_service', 'platform_admin'] },
  { label: '服务评价', to: '/membership/feedbacks', roles: ['vehicle_owner', 'customer_service', 'platform_admin'] },
  { label: '服务申诉', to: '/membership/appeals', roles: ['vehicle_owner', 'customer_service', 'platform_admin'] },
  { label: '车队管理', to: '/membership/fleets', roles: ['platform_admin', 'fleet_admin'] },
  { label: '车队卡', to: '/membership/fleet-cards', roles: ['platform_admin', 'fleet_admin'] },
  { label: '车辆授权与额度', to: '/membership/fleet-authorizations', roles: ['platform_admin', 'fleet_admin'] },
  { label: '账号管理', to: '/auth/accounts', roles: ['platform_admin'] },
  { label: '角色与权限', to: '/auth/roles', roles: ['platform_admin'] },
]
const visibleNavigation = computed(() => navigation.filter((item) => {
  if (!item.roles) return true
  return item.roles.some((role) => account.value?.roles?.includes(role))
}))

async function logout() {
  try { await api.post('/api/v1/auth/logout', {}) } catch { /* session may already be expired */ }
  clearSession()
  await router.push('/login')
}
</script>

<template>
  <div class="app-frame">
    <aside class="sidebar">
      <div class="brand"><span class="brand-mark">⚡</span><div><strong>充电服务平台</strong><small>MEMBERSHIP CONSOLE</small></div></div>
      <div class="nav-caption">工作台</div>
      <nav>
        <RouterLink v-for="item in visibleNavigation" :key="item.to" :to="item.to" class="nav-item" :class="{ active: route.path === item.to || (item.to === '/membership/fleets' && route.name === 'fleet-detail') }">
          <span class="nav-dot"></span>{{ item.label }}
        </RouterLink>
      </nav>
      <div class="sidebar-foot"><span class="status-dot"></span> API · V1.4</div>
    </aside>
    <main class="main-area">
      <header class="topbar">
        <div class="breadcrumb">会员与账号 <span>/</span> {{ route.meta.title }}</div>
        <div class="user-menu"><div class="avatar">{{ account?.roles?.includes('platform_admin') ? '管' : '会' }}</div><div class="user-summary"><strong>{{ account?.roles?.[0] || '已登录' }}</strong><small>账号 #{{ account?.account_id }}</small></div><button class="button button-quiet" @click="logout">退出</button></div>
      </header>
      <section class="page-wrap"><RouterView /></section>
    </main>
  </div>
</template>
