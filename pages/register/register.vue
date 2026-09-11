<template>
  <view class="register-page">
    <!-- 品牌区：柠檬渐变封面，文字一律深色 -->
    <view class="brand">
      <text class="brand-name">Journey Plan</text>
      <text class="brand-slogan">规划你的下一段旅程</text>
    </view>

    <!-- 表单卡片 -->
    <view class="card">
      <view class="field">
        <text class="field-label">用户名</text>
        <input
          class="field-input"
          v-model="username"
          :value="username"
          maxlength="20"
          placeholder="2-20 个字符"
          placeholder-class="field-ph"
          @input="clearError"
        />
      </view>

      <view class="field">
        <text class="field-label">密码</text>
        <input
          class="field-input"
          v-model="password"
          :value="password"
          maxlength="64"
          password
          placeholder="至少 6 位"
          placeholder-class="field-ph"
          @input="clearError"
        />
      </view>

      <view class="field">
        <text class="field-label">确认密码</text>
        <input
          class="field-input"
          v-model="confirm"
          :value="confirm"
          maxlength="64"
          password
          placeholder="再次输入密码"
          placeholder-class="field-ph"
          @input="clearError"
          @confirm="submit"
        />
      </view>

      <text v-if="errorMsg" class="form-error">{{ errorMsg }}</text>

      <view class="submit-btn" @click="submit">
        <text class="submit-text">注册</text>
      </view>

      <view class="switch" @click="goLogin">
        <text class="switch-text">已有账号？返回登录</text>
      </view>
    </view>
  </view>
</template>

<script setup>
// 注册页：调用 /auth/register，成功后自动用同一账号登录并跳转到计划列表。
// 合约依据：api/auth.js → POST /auth/register { username, password, confirm_password }
import { ref } from 'vue'
import { register, login } from '@/api/auth.js'
import { saveSession } from '@/utils/token.js'

const username = ref('')
const password = ref('')
const confirm = ref('')
const errorMsg = ref('')

function clearError() {
  errorMsg.value = ''
}

function submit() {
  const u = username.value.trim()
  const p = password.value
  const c = confirm.value
  if (u.length < 2 || u.length > 20) {
    errorMsg.value = '用户名需 2-20 个字符'
    return
  }
  if (p.length < 6) {
    errorMsg.value = '密码至少 6 位'
    return
  }
  if (p !== c) {
    errorMsg.value = '两次输入的密码不一致'
    return
  }
  errorMsg.value = ''
  register({ username: u, password: p, confirmPassword: c })
    .then(() => login({ username: u, password: p }))
    .then(res => {
      saveSession(res.access_token, res.user, res.refresh_token)
      uni.showToast({ title: '注册成功', icon: 'success' })
      setTimeout(() => uni.reLaunch({ url: '/pages/plans/plans' }), 400)
    })
    .catch(err => {
      // 400 账号已存在 / 422 格式非法，文案来自后端
      errorMsg.value = (err && err.message) || '注册失败，请重试'
    })
}

function goLogin() {
  uni.navigateBack({
    fail() {
      uni.reLaunch({ url: '/pages/login/login' })
    }
  })
}
</script>

<style lang="scss" scoped>
.register-page {
  min-height: 100vh;
  background: $jp-bg;
  box-sizing: border-box;
}

.brand {
  background: $jp-gradient-lemon;
  padding: 120rpx 48rpx 80rpx;
  box-sizing: border-box;
  display: flex;
  flex-direction: column;
  align-items: flex-start;
}
.brand-name {
  font-family: $jp-font-heading;
  font-size: 48rpx;
  font-weight: 700;
  color: $jp-fg;
}
.brand-slogan {
  font-size: 26rpx;
  color: $jp-fg;
  opacity: 0.7;
  margin-top: 12rpx;
}

.card {
  margin: -40rpx 32rpx 0;
  background: $jp-card;
  border: 2rpx solid $jp-border;
  border-radius: $jp-radius;
  padding: 40rpx 32rpx;
  box-sizing: border-box;
}

.field {
  margin-bottom: 28rpx;
}
.field-label {
  display: block;
  font-size: 26rpx;
  font-weight: 600;
  color: $jp-muted-fg;
  margin-bottom: 12rpx;
}
.field-input {
  height: 88rpx;
  padding: 0 24rpx;
  box-sizing: border-box;
  border: 2rpx solid $jp-border;
  border-radius: $jp-radius-sm;
  font-size: 28rpx;
  color: $jp-fg;
  background: $jp-bg;
}
.field-input:focus {
  border-color: $jp-primary;
}
.field-ph {
  color: $jp-muted-fg;
}

.form-error {
  display: block;
  font-size: 24rpx;
  color: $jp-danger;
  margin-bottom: 20rpx;
}

.submit-btn {
  margin-top: 8rpx;
  height: 92rpx;
  background: $jp-gradient-lemon;
  border-radius: $jp-radius-pill;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
}
.submit-btn:hover {
  opacity: 0.92;
}
.submit-text {
  font-size: 30rpx;
  font-weight: 700;
  color: $jp-fg;
}

.switch {
  margin-top: 32rpx;
  text-align: center;
  cursor: pointer;
}
.switch-text {
  font-size: 26rpx;
  color: $jp-deep;
}
</style>
