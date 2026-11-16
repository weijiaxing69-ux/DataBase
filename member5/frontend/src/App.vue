<script setup>
import { computed, provide, ref } from 'vue'
import { useRouter } from 'vue-router'
import { request } from './api/http'
import { submitSettlement } from './api/settlement'

const router = useRouter()
const account = ref(null)
const token = ref('')
const error = ref('')
const busy = ref(false)
const login = ref({ username: '', password: '' })
const retries = new Map()
const roleNames = { platform_admin: '平台管理员', operator_manager: '运营商负责人', customer_service: '客服',
  fleet_admin: '车队管理员', vehicle_owner: '车主' }
const links = [
  ['SettlementList', '运营商结算', ['platform_admin', 'operator_manager', 'customer_service']],
  ['DifferenceList', '对账差异', ['platform_admin', 'operator_manager', 'customer_service']],
  ['InvoiceList', '运营商发票', ['platform_admin', 'operator_manager', 'customer_service']],
  ['UserInvoiceList', '车主发票', ['vehicle_owner', 'customer_service']],
  ['FleetBillList', '车队月结', ['fleet_admin', 'customer_service']],
  ['FleetPriceList', '车队专价', ['fleet_admin', 'platform_admin', 'customer_service']],
  ['SettlementPolicyList', '分成政策', ['platform_admin']],
]
const has = (...roles) => roles.some(role => account.value?.roles.includes(role))
const visible = computed(() => links.filter(link => has(...link[2])))
function clear() {
  account.value = null
  token.value = ''
  retries.clear()
}
async function signIn() {
  busy.value = true
  error.value = ''
  try {
    const session = await request('/auth/login', { method: 'POST', body: login.value })
    token.value = session.access_token
    account.value = session.account
    const current = router.currentRoute.value.meta.section || router.currentRoute.value.name
    if (!visible.value.length) {
      await request('/auth/logout', { token: token.value, method: 'POST' })
      clear()
      throw new Error('此账号没有结算模块权限。')
    }
    if (!visible.value.some(([name]) => name === current)) await router.replace({ name: visible.value[0][0] })
  } catch (e) { error.value = e.message }
  finally { busy.value = false; login.value.password = '' }
}
async function signOut() {
  try { await request('/auth/logout', { token: token.value, method: 'POST' }) }
  finally { clear() }
}
async function mutate(path, body) {
  const fingerprint = JSON.stringify([path, body])
  if (!retries.has(fingerprint)) retries.set(fingerprint, crypto.randomUUID())
  try {
    const result = await submitSettlement(token.value, path, body, retries.get(fingerprint))
    retries.delete(fingerprint)
    return result
  } catch (e) {
    if (e.status && e.status < 500) retries.delete(fingerprint)
    if (e.status === 401) clear()
    throw e
  }
}
provide('settlementSession', { account, token, has, mutate, clear })
</script>

<template>
  <header class="topbar">
    <div class="brand"><span class="brand-icon" aria-hidden="true">ϟ</span> 充电运营服务平台</div>
    <div v-if="account" class="account">
      {{ account.roles.map(role => roleNames[role] || role).join(' · ') }}
      <button class="secondary" @click="signOut">退出</button>
    </div>
  </header>
  <main>
    <nav v-if="account" class="module-nav" aria-label="结算模块">
      <RouterLink v-for="[name, label] in visible" :key="name" :to="{ name }">{{ label }}</RouterLink>
    </nav>
    <div v-if="error" class="error" role="alert">{{ error }}</div>
    <section v-if="!account" class="card signin">
      <h1>结算工作台</h1>
      <form @submit.prevent="signIn">
        <label>账号<input v-model="login.username" autocomplete="username" required></label>
        <label>密码<input v-model="login.password" type="password" autocomplete="current-password" required></label>
        <button :disabled="busy">登录</button>
      </form>
    </section>
    <RouterView v-else :key="$route.path" />
  </main>
</template>
