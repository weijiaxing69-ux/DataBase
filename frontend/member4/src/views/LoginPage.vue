<script setup>
import { ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { api, saveSession } from '../api'

const router = useRouter()
const route = useRoute()
const username = ref('')
const password = ref('')
const loading = ref(false)
const error = ref('')

async function submit() {
  error.value = ''
  loading.value = true
  try {
    const session = await api.post('/api/v1/auth/login', { username: username.value, password: password.value })
    saveSession(session)
    await router.replace(typeof route.query.next === 'string' ? route.query.next : session.account.home_path)
  } catch (err) {
    error.value = err.response?.data?.error?.message || '登录失败，请检查账号和密码。'
  } finally { loading.value = false }
}
</script>

<template>
  <main class="auth-screen">
    <section class="auth-visual"><div class="visual-orb orb-a"></div><div class="visual-orb orb-b"></div><div class="visual-copy"><span class="eyebrow">NEW ENERGY · ONE PLATFORM</span><h1>让每一次<br />充电都更简单。</h1><p>统一管理会员、车队授权与服务体验。</p><div class="visual-line"></div><small>新能源充电桩运营服务平台 · 课程设计 V1.4</small></div></section>
    <section class="auth-panel"><div class="auth-card"><div class="auth-icon">⚡</div><p class="eyebrow">WELCOME BACK</p><h2>登录工作台</h2><p class="muted">使用平台账号继续管理会员服务</p>
      <form @submit.prevent="submit"><label>登录账号<input v-model.trim="username" autocomplete="username" placeholder="请输入登录账号" required /></label><label>密码<input v-model="password" autocomplete="current-password" type="password" placeholder="请输入密码" required /></label><p v-if="error" class="form-error">{{ error }}</p><button class="button button-primary button-wide" :disabled="loading">{{ loading ? '正在登录…' : '登录' }} <span>→</span></button></form>
      <p class="auth-switch">还没有车主账号？ <RouterLink to="/register">立即注册</RouterLink></p>
    </div><div class="auth-foot">安全提示 · 密码经过哈希保护，登录状态由服务端会话校验</div></section>
  </main>
</template>
