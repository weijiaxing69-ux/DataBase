<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { api } from '../api'

const router = useRouter()
const form = ref({ username: '', password: '', display_name: '', phone: '' })
const loading = ref(false)
const message = ref('')
const error = ref('')

async function submit() {
  error.value = ''
  message.value = ''
  loading.value = true
  try {
    await api.post('/api/v1/membership/users', form.value)
    message.value = '注册成功，请使用新账号登录。'
    setTimeout(() => router.push('/login'), 700)
  } catch (err) {
    error.value = err.response?.data?.error?.message || '注册失败，请检查填写内容。'
  } finally { loading.value = false }
}
</script>

<template>
  <main class="auth-screen">
    <section class="auth-visual"><div class="visual-orb orb-a"></div><div class="visual-orb orb-b"></div><div class="visual-copy"><span class="eyebrow">A BETTER CHARGING LIFE</span><h1>开启更聪明的<br />用车体验。</h1><p>创建账号，管理车辆和会员权益。</p><div class="visual-line"></div><small>个人资料和手机号将按平台要求加密保存</small></div></section>
    <section class="auth-panel"><div class="auth-card"><div class="auth-icon">✦</div><p class="eyebrow">CREATE ACCOUNT</p><h2>注册车主账号</h2><p class="muted">填写基本信息，开始使用会员服务</p>
      <form @submit.prevent="submit"><label>登录账号<input v-model.trim="form.username" autocomplete="username" minlength="3" maxlength="64" placeholder="3–64 个字符" required /></label><label>显示姓名<input v-model.trim="form.display_name" maxlength="50" placeholder="怎么称呼您" required /></label><label>手机号<input v-model.trim="form.phone" autocomplete="tel" maxlength="20" placeholder="用于账号联系和找回" required /></label><label>设置密码<input v-model="form.password" autocomplete="new-password" type="password" minlength="10" placeholder="至少 10 位" required /></label><p v-if="error" class="form-error">{{ error }}</p><p v-if="message" class="form-success">{{ message }}</p><button class="button button-primary button-wide" :disabled="loading">{{ loading ? '正在创建…' : '创建账号' }} <span>→</span></button></form>
      <p class="auth-switch">已有账号？ <RouterLink to="/login">返回登录</RouterLink></p>
    </div><div class="auth-foot">注册后自动创建车主档案并分配车主角色</div></section>
  </main>
</template>
