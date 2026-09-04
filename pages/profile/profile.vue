<template>
  <view class="profile-page">
    <!-- 页面背景：顶部黄色 → 浅灰白 → 白（原型 page-bg） -->
    <view class="page-bg"></view>

    <view class="content">
      <!-- 头部：位于黄色部分（原型 page-header） -->
      <view class="page-header">
        <h1 class="head-title">个人中心</h1>
      </view>

      <!-- 白色内容卡片（原型 page-sheet，整体滚动） -->
      <view class="page-sheet">
        <!-- 头像卡 -->
        <view class="hero">
          <view class="avatar">{{ initial }}</view>
          <view class="hero-main">
            <text class="nickname">{{ nickname }}</text>
          </view>
          <view class="edit" @click="editProfile">
            <text class="edit-text">编辑</text>
          </view>
        </view>

        <!-- 统计 -->
        <view class="stats">
          <view class="stat" v-for="s in stats" :key="s.label">
            <text class="stat-num">{{ s.value }}</text>
            <text class="stat-label">{{ s.label }}</text>
          </view>
        </view>

        <!-- 菜单组 1 -->
        <view class="menu">
          <view class="menu-item" @click="onMenu('旅行偏好')">
            <view class="menu-icon" style="background: rgba(250,204,21,0.16)">
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#A16207" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 7H11M14 17H5M17 17a3 3 0 003-3M7 7a3 3 0 00-3 3"/></svg>
            </view>
            <text class="menu-label">旅行偏好</text>
            <text class="menu-hint">{{ prefsHint }}</text>
            <view class="chevron"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#94A3B8" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 18l6-6-6-6"/></svg></view>
          </view>
          <view class="menu-item" @click="onMenu('通知提醒')">
            <view class="menu-icon" style="background: rgba(132,204,22,0.14)">
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#4D7C0F" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M18 8a6 6 0 00-12 0c0 7-3 9-3 9h18s-3-2-3-9M13.7 21a2 2 0 01-3.4 0"/></svg>
            </view>
            <text class="menu-label">通知提醒</text>
            <text class="menu-hint">开启</text>
            <view class="chevron"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#94A3B8" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 18l6-6-6-6"/></svg></view>
          </view>
        </view>

        <!-- 菜单组 2 -->
        <view class="menu">
          <view class="menu-item" @click="onMenu('修改密码')">
            <view class="menu-icon" style="background: rgba(120,113,108,0.12)">
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#78716C" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="11" width="18" height="10" rx="2"/><path d="M7 11V7a5 5 0 0110 0v4"/></svg>
            </view>
            <text class="menu-label">修改密码</text>
            <view class="chevron"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#94A3B8" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 18l6-6-6-6"/></svg></view>
          </view>
          <view class="menu-item" @click="onMenu('切换账号')">
            <view class="menu-icon" style="background: rgba(120,113,108,0.12)">
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#78716C" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 21H5a2 2 0 01-2-2V5a2 2 0 012-2h4"/><path d="M16 17l5-5-5-5M21 12H9"/></svg>
            </view>
            <text class="menu-label">切换账号</text>
            <view class="chevron"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#94A3B8" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 18l6-6-6-6"/></svg></view>
          </view>
          <view class="menu-item" @click="onMenu('帮助与反馈')">
            <view class="menu-icon" style="background: rgba(120,113,108,0.12)">
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#78716C" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="9"/><path d="M9.5 9a2.5 2.5 0 015 0c0 2-2.5 2-2.5 4M12 17h.01"/></svg>
            </view>
            <text class="menu-label">帮助与反馈</text>
            <view class="chevron"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#94A3B8" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 18l6-6-6-6"/></svg></view>
          </view>
          <view class="menu-item" @click="onMenu('关于')">
            <view class="menu-icon" style="background: rgba(120,113,108,0.12)">
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#78716C" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="9"/><path d="M12 11v5M12 8h.01"/></svg>
            </view>
            <text class="menu-label">关于</text>
            <text class="menu-hint">v1.2</text>
            <view class="chevron"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#94A3B8" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 18l6-6-6-6"/></svg></view>
          </view>
        </view>

        <!-- 退出登录 -->
        <view class="logout" @click="logout">
          <text class="logout-text">退出登录</text>
        </view>
        <text class="version">Journey Plan · 让每段旅程都被用心安排</text>
      </view>
    </view>

    <app-tab-bar current="profile" />

    <!-- 通用弹窗：旅行偏好 / 修改密码 / 帮助与反馈 / 关于 -->
    <view v-if="dialog" class="modal-mask" @click="closeDialog">
      <view class="modal" @click.stop>
        <view class="modal-head">
          <text class="modal-title">{{ dialogTitle }}</text>
          <view class="modal-close" @click="closeDialog">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#78716C" stroke-width="2" stroke-linecap="round"><path d="M18 6L6 18M6 6l12 12"/></svg>
          </view>
        </view>

        <view class="modal-body">
          <!-- 旅行偏好 -->
          <view v-if="dialog === 'prefs'" class="chip-wrap">
            <view
              v-for="p in prefOptions"
              :key="p"
              class="chip"
              :class="{ 'chip--on': selectedPrefs.includes(p) }"
              @click="togglePref(p)"
            >{{ p }}</view>
          </view>

          <!-- 修改密码 -->
          <view v-else-if="dialog === 'pwd'" class="form">
            <input class="field" password v-model="pwd.oldPwd" placeholder="当前密码" />
            <input class="field" password v-model="pwd.newPwd" placeholder="新密码（≥6 位）" />
            <input class="field" password v-model="pwd.confirmPwd" placeholder="确认新密码" />
          </view>

          <!-- 帮助与反馈 -->
          <view v-else-if="dialog === 'help'">
            <textarea class="field-area" v-model="helpText" placeholder="描述你遇到的问题或建议…" />
          </view>

          <!-- 关于 -->
          <view v-else-if="dialog === 'about'" class="about">
            <text class="about-name">Journey Plan</text>
            <text class="about-ver">版本 v1.2</text>
            <text class="about-desc">让每段旅程都被用心安排。本应用帮助你规划行程、管理预算与天气，并随时向 AI 旅行助手求助。</text>
          </view>
        </view>

        <view class="modal-foot">
          <view v-if="dialog === 'prefs'" class="btn btn-primary" @click="savePrefs">保存</view>
          <view v-else-if="dialog === 'pwd'" class="btn btn-primary" @click="submitPwd">{{ pwdLoading ? '提交中…' : '提交' }}</view>
          <view v-else-if="dialog === 'help'" class="btn btn-primary" @click="submitHelp">提交反馈</view>
          <view v-else class="btn btn-primary" @click="closeDialog">我知道了</view>
        </view>
      </view>
    </view>
  </view>
</template>

<script setup>
// 个人中心（原型 §我的/个人中心）：头像/昵称 + 统计卡 + 菜单列表 + 退出登录。
// 除「通知提醒」外，其余菜单功能均已实现（偏好本地持久化；修改密码走 API；切换账号/帮助/关于为交互流程）。
import { ref, computed } from 'vue'
import { onShow } from '@dcloudio/uni-app'
import { getUser, clearSession, setUser } from '@/utils/token.js'
import { getProfile, updateProfile, changePassword } from '@/api/user.js'
import AppTabBar from '@/components/AppTabBar.vue'

const user = ref({})

const PREFS_KEY = 'jp_prefs'
const prefOptions = ['文化', '自然', '美食', '购物', '探险', '休闲', '亲子', '摄影']
const selectedPrefs = ref([])

onShow(() => {
  selectedPrefs.value = uni.getStorageSync(PREFS_KEY) || ['文化', '自然']
  // 本地兜底，再尝试从后端拉取最新资料
  user.value = getUser() || {}
  getProfile({ silent: true })
    .then((u) => { user.value = u; setUser(u) })
    .catch(() => {})
})

const nickname = computed(() => user.value.username || '旅行者')
const initial = computed(() => (nickname.value ? nickname.value.charAt(0).toUpperCase() : '?'))

const stats = computed(() => [
  { label: '计划', value: user.value.plan_count ?? 0 },
  { label: '旅行天数', value: user.value.travel_days ?? 0 }
])

const prefsHint = computed(() => (selectedPrefs.value.length ? selectedPrefs.value.join(' · ') : '未设置'))

// ---- 弹窗 ----
const dialog = ref(null) // 'prefs' | 'pwd' | 'help' | 'about'
const dialogTitle = computed(() => ({
  prefs: '旅行偏好',
  pwd: '修改密码',
  help: '帮助与反馈',
  about: '关于 Journey Plan'
}[dialog.value] || ''))

function openDialog(t) { dialog.value = t }
function closeDialog() { dialog.value = null }

function onMenu(name) {
  if (name === '通知提醒') {
    uni.showToast({ title: '通知提醒（待实现）', icon: 'none' })
    return
  }
  if (name === '旅行偏好') return openDialog('prefs')
  if (name === '修改密码') return openDialog('pwd')
  if (name === '切换账号') return switchAccount()
  if (name === '帮助与反馈') return openDialog('help')
  if (name === '关于') return openDialog('about')
}

// 旅行偏好
function togglePref(p) {
  const i = selectedPrefs.value.indexOf(p)
  if (i >= 0) selectedPrefs.value.splice(i, 1)
  else selectedPrefs.value.push(p)
}
function savePrefs() {
  uni.setStorageSync(PREFS_KEY, selectedPrefs.value)
  uni.showToast({ title: '偏好已保存', icon: 'success' })
  closeDialog()
}

// 修改密码
const pwd = ref({ oldPwd: '', newPwd: '', confirmPwd: '' })
const pwdLoading = ref(false)
function submitPwd() {
  const { oldPwd, newPwd, confirmPwd } = pwd.value
  if (!oldPwd || !newPwd) return uni.showToast({ title: '请填写完整', icon: 'none' })
  if (newPwd.length < 6) return uni.showToast({ title: '新密码至少 6 位', icon: 'none' })
  if (newPwd !== confirmPwd) return uni.showToast({ title: '两次输入不一致', icon: 'none' })
  pwdLoading.value = true
  changePassword({ old_password: oldPwd, new_password: newPwd })
    .then(() => {
      uni.showToast({ title: '密码已修改', icon: 'success' })
      pwd.value = { oldPwd: '', newPwd: '', confirmPwd: '' }
      closeDialog()
    })
    .catch((e) => {
      uni.showToast({ title: (e && e.message) || '修改失败', icon: 'none' })
    })
    .finally(() => { pwdLoading.value = false })
}

// 帮助与反馈
const helpText = ref('')
function submitHelp() {
  if (!helpText.value.trim()) return uni.showToast({ title: '请输入内容', icon: 'none' })
  uni.setStorageSync('jp_feedback', helpText.value)
  uni.showToast({ title: '已提交，感谢反馈', icon: 'success' })
  helpText.value = ''
  closeDialog()
}

// 切换账号
function switchAccount() {
  uni.showModal({
    title: '切换账号',
    content: '将退出当前账号并返回登录页，确定吗？',
    success(res) {
      if (!res.confirm) return
      clearSession()
      uni.reLaunch({ url: '/pages/login/login' })
    }
  })
}

function editProfile() {
  uni.showModal({
    title: '修改昵称',
    editable: true,
    placeholderText: '请输入 2-20 字昵称',
    content: nickname.value,
    success(res) {
      if (!res.confirm) return
      const name = (res.content || '').trim()
      if (!name) return uni.showToast({ title: '昵称不能为空', icon: 'none' })
      updateProfile({ username: name })
        .then((u) => { user.value = u; setUser(u); uni.showToast({ title: '已保存', icon: 'success' }) })
        .catch((e) => uni.showToast({ title: (e && e.message) || '修改失败', icon: 'none' }))
    }
  })
}

function logout() {
  uni.showModal({
    title: '退出登录',
    content: '确认退出当前账号？',
    confirmColor: '#DC2626',
    success(res) {
      if (!res.confirm) return
      clearSession()
      uni.reLaunch({ url: '/pages/login/login' })
    }
  })
}
</script>

<style lang="scss" scoped>
.profile-page {
  position: relative;
  height: 100%;
  overflow: hidden;
  display: flex;
  flex-direction: column;
  box-sizing: border-box;
}
.page-bg {
  position: absolute;
  inset: 0;
  z-index: 0;
  background: linear-gradient(180deg, #FACC15 0%, #FACC15 16.66%, #F4F1EA 40%, #FFFFFF 100%);
}
.content {
  position: relative;
  z-index: 10;
  height: 100%;
  display: flex;
  flex-direction: column;
  box-sizing: border-box;
}

/* 头部 */
.page-header {
  flex-shrink: 0;
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 56rpx 48rpx 24rpx;
  color: #1C1917;
}
.head-title {
  font-family: $jp-font-heading;
  font-size: 48rpx;
  font-weight: 700;
}
/* 白色卡片（整体滚动） */
.page-sheet {
  position: relative;
  z-index: 10;
  background: #FFFFFF;
  border-radius: 56rpx 56rpx 0 0;
  box-shadow: 0 12rpx 30rpx -18rpx rgba(28, 25, 23, 0.28);
  margin: 28rpx 28rpx 0;
  flex: 1 1 auto;
  min-height: 0;
  overflow-y: auto;
  padding: 32rpx 32rpx calc(120rpx + env(safe-area-inset-bottom));
  box-sizing: border-box;

  &::-webkit-scrollbar { width: 0; height: 0; display: none; }
  scrollbar-width: none;
}

/* 头像卡 */
.hero {
  display: flex;
  align-items: center;
  padding: 24rpx 0 8rpx;
}
.avatar {
  width: 120rpx;
  height: 120rpx;
  border-radius: 9999rpx;
  background: rgba(250, 204, 21, 0.1);
  border: 4rpx solid rgba(250, 204, 21, 0.3);
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  font-family: $jp-font-heading;
  font-size: 52rpx;
  font-weight: 700;
  color: $jp-deep;
}
.hero-main {
  flex: 1;
  margin-left: 24rpx;
  min-width: 0;
}
.nickname {
  display: block;
  font-family: $jp-font-heading;
  font-size: 40rpx;
  font-weight: 700;
  color: $jp-fg;
}
.edit {
  height: 52rpx;
  padding: 0 24rpx;
  background: $jp-muted;
  border-radius: $jp-radius-pill;
  display: flex;
  align-items: center;
  cursor: pointer;
}
.edit-text {
  font-size: 24rpx;
  font-weight: 700;
  color: $jp-deep;
}

/* 统计卡 */
.stats {
  display: flex;
  background: $jp-bg;
  border: 2rpx solid $jp-border;
  border-radius: $jp-radius;
  padding: 28rpx 0;
  margin: 28rpx 0;
}
.stat {
  flex: 1;
  text-align: center;
  position: relative;

  & + .stat::before {
    content: '';
    position: absolute;
    left: 0;
    top: 12rpx;
    bottom: 12rpx;
    width: 2rpx;
    background: $jp-border;
  }
}
.stat-num {
  display: block;
  font-family: $jp-font-heading;
  font-size: 40rpx;
  font-weight: 700;
  color: $jp-fg;
}
.stat-label {
  display: block;
  font-size: 22rpx;
  color: $jp-muted-fg;
  margin-top: 6rpx;
}

/* 菜单 */
.menu {
  background: $jp-card;
  border: 2rpx solid $jp-border;
  border-radius: $jp-radius;
  overflow: hidden;
  margin-bottom: 28rpx;
}
.menu-item {
  display: flex;
  align-items: center;
  padding: 28rpx 24rpx;
  cursor: pointer;

  & + .menu-item {
    border-top: 2rpx solid $jp-border;
  }
  &:hover { background: $jp-bg; }
}
.menu-icon {
  width: 64rpx;
  height: 64rpx;
  border-radius: 18rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-right: 24rpx;
  flex-shrink: 0;
}
.menu-label {
  flex: 1;
  font-size: 28rpx;
  font-weight: 600;
  color: $jp-fg;
}
.menu-hint {
  font-size: 24rpx;
  color: $jp-muted-fg;
  margin-right: 12rpx;
}
.chevron {
  width: 32rpx;
  height: 32rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

/* 退出 */
.logout {
  height: 92rpx;
  background: $jp-card;
  border: 2rpx solid $jp-border;
  border-radius: $jp-radius;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;

  &:hover { border-color: $jp-danger; }
}
.logout-text {
  font-size: 28rpx;
  font-weight: 700;
  color: $jp-danger;
}
.version {
  display: block;
  text-align: center;
  font-size: 22rpx;
  color: $jp-muted-fg;
  margin: 40rpx 0 16rpx;
}

/* 通用弹窗 */
.modal-mask {
  position: fixed;
  inset: 0;
  z-index: 100;
  background: rgba(28, 25, 23, 0.45);
  display: flex;
  align-items: flex-end;
  justify-content: center;
}
.modal {
  width: 100%;
  max-height: 78vh;
  background: #FFFFFF;
  border-radius: 36rpx 36rpx 0 0;
  box-sizing: border-box;
  display: flex;
  flex-direction: column;
  overflow: hidden;
  animation: sheetUp 0.22s ease;
}
@keyframes sheetUp {
  from { transform: translateY(40rpx); opacity: 0.6; }
  to { transform: translateY(0); opacity: 1; }
}
.modal-head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 32rpx 32rpx 16rpx;
}
.modal-title {
  font-family: $jp-font-heading;
  font-size: 34rpx;
  font-weight: 700;
  color: $jp-fg;
}
.modal-close {
  width: 56rpx;
  height: 56rpx;
  border-radius: 9999rpx;
  background: $jp-bg;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
}
.modal-body {
  flex: 1;
  min-height: 0;
  overflow-y: auto;
  padding: 16rpx 32rpx 24rpx;
  box-sizing: border-box;
}
.modal-foot {
  padding: 16rpx 32rpx calc(28rpx + env(safe-area-inset-bottom));
}
.btn {
  height: 88rpx;
  border-radius: $jp-radius-pill;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 30rpx;
  font-weight: 700;
  cursor: pointer;
}
.btn-primary {
  background: $jp-primary;
  color: $jp-fg;
}

/* 偏好标签 */
.chip-wrap {
  display: flex;
  flex-wrap: wrap;
  gap: 20rpx;
}
.chip {
  padding: 16rpx 28rpx;
  border-radius: $jp-radius-pill;
  background: $jp-bg;
  border: 2rpx solid $jp-border;
  font-size: 26rpx;
  color: $jp-muted-fg;
  cursor: pointer;
  &--on {
    background: rgba(250, 204, 21, 0.16);
    border-color: $jp-primary;
    color: $jp-deep;
    font-weight: 700;
  }
}

/* 表单 */
.form {
  display: flex;
  flex-direction: column;
  gap: 20rpx;
}
.field {
  height: 88rpx;
  background: $jp-bg;
  border: 2rpx solid $jp-border;
  border-radius: $jp-radius;
  padding: 0 24rpx;
  font-size: 28rpx;
  color: $jp-fg;
  box-sizing: border-box;
}
.field-area {
  width: 100%;
  height: 220rpx;
  background: $jp-bg;
  border: 2rpx solid $jp-border;
  border-radius: $jp-radius;
  padding: 20rpx 24rpx;
  font-size: 28rpx;
  color: $jp-fg;
  box-sizing: border-box;
}

/* 关于 */
.about {
  display: flex;
  flex-direction: column;
  align-items: center;
  text-align: center;
  padding: 24rpx 0;
}
.about-name {
  font-family: $jp-font-heading;
  font-size: 40rpx;
  font-weight: 700;
  color: $jp-fg;
}
.about-ver {
  font-size: 24rpx;
  color: $jp-muted-fg;
  margin: 8rpx 0 20rpx;
}
.about-desc {
  font-size: 26rpx;
  color: $jp-muted-fg;
  line-height: 1.7;
}
</style>
