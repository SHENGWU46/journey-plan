<template>
  <view class="plans-page">
    <!-- 头部：标题 + 计数（spec 计划卡片列表展示 / 计数文案） -->
    <view class="page-head">
      <text class="page-title">我的计划</text>
      <text class="page-count">共 {{ totalAll }} 段旅程 · {{ visible }} 段可见</text>
    </view>

    <!-- 搜索框（FR-PL-03）：防抖 ≥300ms 后请求，忽略大小写模糊匹配 -->
    <view class="search">
      <view class="search-icon">
        <image class="search-icon-img" src="/static/icon-search.svg" mode="aspectFit" />
      </view>
      <input
        class="search-input"
        v-model="keyword"
        :value="keyword"
        maxlength="40"
        placeholder="搜索计划名称…"
        placeholder-class="search-ph"
        @input="onSearchInput"
      />
      <view v-if="keyword" class="search-clear" @click="clearSearch" aria-label="清空">
        <image class="search-clear-img" src="/static/icon-close.svg" mode="aspectFit" />
      </view>
    </view>

    <!-- 计划列表（FR-PL-01） -->
    <view class="plan-list">
      <view
        v-for="p in plans"
        :key="p.id"
        class="plan-card"
        :class="{ 'plan-card--draft': !p.completed }"
      >
        <!-- 非草稿：统一柠檬渐变封面 + 日期角标（无状态标签，产品决策 2026-08-28） -->
        <view v-if="p.completed" class="cover">
          <text class="cover-date">{{ dateRange(p) }}</text>
        </view>

        <view class="card-body">
          <!-- 草稿：编辑图标头 + 名称 + 草稿标签 -->
          <view v-if="!p.completed" class="draft-head">
            <view class="draft-icon">
              <image class="draft-icon-img" src="/static/icon-edit.svg" mode="aspectFit" />
            </view>
            <view class="draft-head-main">
              <view class="draft-title-row">
                <text class="plan-name plan-name--draft">{{ p.name }}</text>
                <text class="badge badge--draft">草稿</text>
              </view>
              <text class="plan-meta">{{ metaText(p) }}</text>
              <text class="draft-tip">已完成命名与基本信息，可继续生成每日计划</text>
            </view>
          </view>

          <!-- 非草稿：名称 + 要素 + 进度 -->
          <view v-else>
            <text class="plan-name">{{ p.name }}</text>
            <text class="plan-meta">{{ metaText(p) }}</text>
            <view class="progress">
              <view class="progress-bar" :style="{ width: progressOf(p) + '%' }"></view>
            </view>
            <text class="progress-text">每日计划已生成 {{ p.generated_days }} / {{ p.total_days }}</text>
          </view>

          <!-- 卡片操作：编辑（改名）/ 删除（FR-PL-05 / FR-PL-07） -->
          <view class="ops">
            <view class="op" @click="openRename(p)">
              <text class="op-text">编辑</text>
            </view>
            <view class="op op--danger" @click="removePlan(p)">
              <text class="op-text op-text--danger">删除</text>
            </view>
          </view>
        </view>
      </view>

      <!-- 空态：无计划 / 无匹配结果 -->
      <view v-if="!plans.length" class="empty">
        <text class="empty-title">{{ isSearching ? '没有找到匹配的计划' : '还没有任何计划' }}</text>
        <text class="empty-sub">{{ isSearching ? '试试其他关键字，或新建一段旅程' : '创建第一段旅程，开始安排行程' }}</text>
        <view class="empty-btn" @click="goNew">
          <view class="plus"><view class="plus-h"></view><view class="plus-v"></view></view>
          <text class="empty-btn-text">新建一段旅程</text>
        </view>
      </view>

      <!-- 新建入口：底部常驻（FR-PL-04） -->
      <view class="new-btn" @click="goNew">
        <view class="plus"><view class="plus-h"></view><view class="plus-v"></view></view>
        <text class="new-btn-text">新建一段旅程</text>
      </view>
    </view>

    <!-- 改名弹窗（FR-PL-05）：2-20 字符校验同命名（FR-WZ-01） -->
    <view v-if="renameVisible" class="mask" @click="closeRename">
      <view class="dialog" @click.stop>
        <text class="dialog-title">修改计划名称</text>
        <input
          class="dialog-input"
          v-model="renameValue"
          :focus="renameFocus"
          maxlength="20"
          placeholder="2-20 字符"
          placeholder-class="dialog-ph"
          @input="renameError = ''"
        />
        <text v-if="renameError" class="dialog-error">{{ renameError }}</text>
        <view class="dialog-ops">
          <view class="dialog-btn" @click="closeRename"><text class="dialog-btn-text">取消</text></view>
          <view class="dialog-btn dialog-btn--primary" @click="submitRename">
            <text class="dialog-btn-text dialog-btn-text--primary">保存</text>
          </view>
        </view>
      </view>
    </view>
  </view>
</template>

<script setup>
// 我的计划页（FR-PL-01 / FR-PL-05 / FR-PL-07 / FR-PL-04）
// 契约依据：changes/my-plans-page/specs/plan-list/spec.md
// 产品决策（2026-08-28）：状态系统取消，卡片仅按 completed 区分草稿/非草稿，无筛选栏、无状态标签。
import { ref } from 'vue'
import { onShow } from '@dcloudio/uni-app'
import { listPlans, renamePlan, deletePlan } from '@/api/plan.js'

const plans = ref([])
const totalAll = ref(0)
const visible = ref(0)

/** 搜索关键字（FR-PL-03，task 2.3） */
const keyword = ref('')
const isSearching = ref(false) // 是否处于搜索态（区分"无计划"与"无匹配结果"空态）
let searchTimer = null
let reqSeq = 0 // 请求序号：丢弃过期响应，避免竞态（实施备注：前端竞态处理只在前端）

const renameVisible = ref(false)
const renameFocus = ref(false)
const renameValue = ref('')
const renameError = ref('')
let renameId = null

onShow(() => {
  load()
})

/** 列表加载（带关键字）。reqSeq 递增，仅最新请求的结果落地，丢弃过期响应。 */
function load() {
  const seq = ++reqSeq
  const kw = keyword.value.trim()
  isSearching.value = !!kw
  return listPlans({ keyword: kw, page: 1, page_size: 100 })
    .then(res => {
      if (seq !== reqSeq) return // 已有更新的请求发出，丢弃本次过期响应
      plans.value = res.items || []
      totalAll.value = res.total || 0
      visible.value = res.total || 0
    })
    .catch(() => {
      if (seq !== reqSeq) return
      plans.value = []
      totalAll.value = 0
      visible.value = 0
    })
}

/** 输入防抖 ≥300ms（FR-PL-03） */
function onSearchInput(e) {
  keyword.value = e.detail ? e.detail.value : e.target.value
  clearTimeout(searchTimer)
  searchTimer = setTimeout(() => load(), 300)
}

/** 清空搜索（保留 keyword 绑定一致性） */
function clearSearch() {
  keyword.value = ''
  isSearching.value = false
  clearTimeout(searchTimer)
  load()
}

/** 跳转 Step1 命名页（task 3.1 落地） */
function goNew() {
  uni.navigateTo({ url: '/pages/plan-new/plan-new' })
}

/* ---------- 展示格式化 ---------- */

function shortDate(d) {
  if (!d) return ''
  const parts = String(d).split('-')
  return parts.length >= 3 ? parts[1] + '.' + parts[2] : String(d)
}

function dateRange(p) {
  const s = shortDate(p.depart_date)
  const e = shortDate(p.return_date)
  return s && e ? s + ' – ' + e : '待完善'
}

function money(n) {
  return '¥' + (Number(n) || 0).toLocaleString('zh-CN')
}

/** 卡片要素行：已填写要素正常显示，未填写以「待完善」占位（spec 草稿卡片展示） */
function metaText(p) {
  const parts = []
  if (p.depart_date && p.return_date) parts.push(dateRange(p))
  if (p.total_days != null) parts.push(p.total_days + ' 天')
  if (p.people_count != null) parts.push(p.people_count + ' 人')
  if (p.completed) parts.push('总预算 ' + money(p.total_budget))
  return parts.length ? parts.join(' · ') : '待完善'
}

function progressOf(p) {
  return p.total_days ? Math.round((p.generated_days / p.total_days) * 100) : 0
}

/* ---------- 编辑（改名） ---------- */

function openRename(p) {
  renameId = p.id
  renameValue.value = p.name
  renameError.value = ''
  renameVisible.value = true
  // 下一帧再聚焦，确保 input 已渲染
  renameFocus.value = false
  setTimeout(() => { renameFocus.value = true }, 50)
}

function closeRename() {
  renameVisible.value = false
  renameFocus.value = false
  renameId = null
}

function submitRename() {
  const name = (renameValue.value || '').trim()
  if (name.length < 2 || name.length > 20) {
    renameError.value = '请为计划起一个名字（2-20 字符）'
    return
  }
  renamePlan(renameId, { name })
    .then(() => {
      closeRename()
      uni.showToast({ title: '已更新', icon: 'success' })
      load()
    })
    .catch(() => {})
}

/* ---------- 删除 ---------- */

function removePlan(p) {
  uni.showModal({
    title: '删除计划',
    content: '删除后不可恢复，确认删除该计划？',
    confirmColor: '#DC2626',
    success(res) {
      if (!res.confirm) return
      deletePlan(p.id)
        .then(() => {
          uni.showToast({ title: '已删除', icon: 'success' })
          load()
        })
        .catch(() => {})
    }
  })
}
</script>

<style lang="scss" scoped>
.plans-page {
  min-height: 100vh;
  background: $jp-bg;
  padding: 0 32rpx 40rpx;
  box-sizing: border-box;
}

.page-head {
  padding: 32rpx 0 24rpx;
}
.page-title {
  display: block;
  font-family: $jp-font-heading;
  font-size: 48rpx;
  font-weight: 700;
  color: $jp-fg;
}
.page-count {
  display: block;
  font-size: 26rpx;
  color: $jp-muted-fg;
  margin-top: 6rpx;
}

/* ---------- 搜索框（FR-PL-03） ---------- */
.search {
  display: flex;
  align-items: center;
  gap: 12rpx;
  margin-top: 24rpx;
  padding: 0 24rpx;
  height: 80rpx;
  box-sizing: border-box;
  background: $jp-card;
  border: 2rpx solid $jp-border;
  border-radius: $jp-radius-sm;
}
.search:focus-within {
  border-color: $jp-primary;
}
.search-icon {
  width: 32rpx;
  height: 32rpx;
  flex-shrink: 0;
  display: flex;
  align-items: center;
  justify-content: center;
}
.search-icon-img {
  width: 32rpx;
  height: 32rpx;
}
.search-input {
  flex: 1;
  min-width: 0;
  height: 100%;
  font-size: 28rpx;
  color: $jp-fg;
  background: transparent;
}
.search-ph {
  color: $jp-muted-fg;
}
.search-clear {
  width: 40rpx;
  height: 40rpx;
  flex-shrink: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  color: $jp-muted-fg;
  cursor: pointer;
}
.search-clear:hover {
  color: $jp-deep;
}
.search-clear-img {
  width: 28rpx;
  height: 28rpx;
}

/* ---------- 卡片 ---------- */
.plan-card {
  background: $jp-card;
  border: 2rpx solid $jp-border;
  border-radius: $jp-radius;
  overflow: hidden;
  margin-bottom: 24rpx;
}
.plan-card--draft {
  border-style: dashed;
}

.cover {
  height: 160rpx;
  background: $jp-gradient-lemon;
  padding: 20rpx 24rpx;
  box-sizing: border-box;
}
/* 渐变上文字一律深色（避免黄底白字） */
.cover-date {
  display: inline-block;
  font-size: 22rpx;
  font-weight: 700;
  color: $jp-fg;
  background: rgba(0, 0, 0, 0.1);
  border-radius: $jp-radius-pill;
  padding: 6rpx 20rpx;
}

.card-body {
  padding: 24rpx;
}

.plan-name {
  display: block;
  font-family: $jp-font-heading;
  font-size: 32rpx;
  font-weight: 700;
  color: $jp-fg;
}
.plan-meta {
  display: block;
  font-size: 24rpx;
  color: $jp-muted-fg;
  margin-top: 8rpx;
}

/* 草稿头：编辑图标 + 名称 + 草稿标签 */
.draft-head {
  display: flex;
  align-items: flex-start;
}
.draft-icon {
  width: 72rpx;
  height: 72rpx;
  border-radius: 20rpx;
  background: $jp-muted;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-right: 20rpx;
  flex-shrink: 0;
}
.draft-icon-img {
  width: 36rpx;
  height: 36rpx;
}
.draft-head-main {
  flex: 1;
  min-width: 0;
}
.draft-title-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
}
.plan-name--draft {
  flex: 1;
  min-width: 0;
}
.badge {
  font-size: 22rpx;
  font-weight: 700;
  padding: 6rpx 18rpx;
  border-radius: $jp-radius-pill;
  flex-shrink: 0;
  margin-left: 12rpx;
}
.badge--draft {
  color: $jp-deep3;
  background: rgba(56, 189, 248, 0.12);
}
.draft-tip {
  display: block;
  font-size: 24rpx;
  color: $jp-muted-fg;
  margin-top: 12rpx;
}

/* 进度（generated_days 本次恒 0，待 FR-DY 接入真实数据，设计决策 12） */
.progress {
  height: 12rpx;
  background: $jp-muted;
  border-radius: $jp-radius-pill;
  overflow: hidden;
  margin-top: 20rpx;
}
.progress-bar {
  height: 100%;
  background: $jp-gradient-progress;
  border-radius: $jp-radius-pill;
  transition: width 0.3s ease;
}
.progress-text {
  display: block;
  font-size: 22rpx;
  color: $jp-muted-fg;
  margin-top: 10rpx;
}

/* ---------- 卡片操作 ---------- */
.ops {
  display: flex;
  margin-top: 24rpx;
}
.op {
  flex: 1;
  text-align: center;
  border: 2rpx solid $jp-border;
  border-radius: $jp-radius-sm;
  padding: 16rpx 0;
  cursor: pointer;
}
.op + .op {
  margin-left: 16rpx;
}
.op:hover {
  border-color: $jp-primary;
}
.op-text {
  font-size: 24rpx;
  font-weight: 600;
  color: $jp-muted-fg;
}
.op:hover .op-text {
  color: $jp-deep;
}
.op--danger:hover {
  border-color: $jp-danger;
}
.op-text--danger {
  color: $jp-danger;
}

/* ---------- 空态 ---------- */
.empty {
  text-align: center;
  padding: 80rpx 24rpx;
  border: 2rpx dashed $jp-border;
  border-radius: $jp-radius;
}
.empty-title {
  display: block;
  font-family: $jp-font-heading;
  font-size: 30rpx;
  font-weight: 700;
  color: $jp-fg;
}
.empty-sub {
  display: block;
  font-size: 24rpx;
  color: $jp-muted-fg;
  margin-top: 12rpx;
}
.empty-btn {
  display: inline-flex;
  align-items: center;
  margin-top: 32rpx;
  padding: 18rpx 48rpx;
  border-radius: $jp-radius-pill;
  background: $jp-gradient-lemon;
  color: $jp-fg;
  cursor: pointer;
}
.empty-btn-text {
  font-size: 28rpx;
  font-weight: 700;
  color: $jp-fg;
  margin-left: 12rpx;
}

/* ---------- 新建入口 ---------- */
.new-btn {
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 28rpx;
  color: $jp-muted-fg;
  border: 2rpx dashed $jp-border;
  border-radius: $jp-radius;
  padding: 32rpx 0;
  cursor: pointer;
}
.new-btn:hover {
  border-color: $jp-primary;
  color: $jp-deep;
}
.new-btn-text {
  font-size: 28rpx;
  color: inherit;
  margin-left: 12rpx;
}

/* 加号图标：两条同色细线组成，随 currentColor 变化（不用 emoji） */
.plus {
  position: relative;
  width: 28rpx;
  height: 28rpx;
}
.plus-h {
  position: absolute;
  top: 13rpx;
  left: 0;
  width: 28rpx;
  height: 2rpx;
  background: currentColor;
}
.plus-v {
  position: absolute;
  left: 13rpx;
  top: 0;
  width: 2rpx;
  height: 28rpx;
  background: currentColor;
}

/* ---------- 改名弹窗 ---------- */
.mask {
  position: fixed;
  left: 0;
  right: 0;
  top: 0;
  bottom: 0;
  background: rgba(28, 25, 23, 0.45);
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 0 60rpx;
  z-index: 999;
}
.dialog {
  width: 100%;
  background: $jp-card;
  border-radius: $jp-radius;
  padding: 40rpx 32rpx 32rpx;
  box-sizing: border-box;
}
.dialog-title {
  display: block;
  font-family: $jp-font-heading;
  font-size: 32rpx;
  font-weight: 700;
  color: $jp-fg;
}
.dialog-input {
  margin-top: 24rpx;
  height: 88rpx;
  padding: 0 24rpx;
  box-sizing: border-box;
  border: 2rpx solid $jp-border;
  border-radius: $jp-radius-sm;
  font-size: 28rpx;
  color: $jp-fg;
  background: $jp-bg;
}
.dialog-input:focus {
  border-color: $jp-primary;
}
.dialog-ph {
  color: $jp-muted-fg;
}
.dialog-error {
  display: block;
  margin-top: 12rpx;
  font-size: 24rpx;
  color: $jp-danger;
}
.dialog-ops {
  display: flex;
  margin-top: 32rpx;
}
.dialog-btn {
  flex: 1;
  text-align: center;
  padding: 20rpx 0;
  border-radius: $jp-radius-sm;
  border: 2rpx solid $jp-border;
  cursor: pointer;
}
.dialog-btn + .dialog-btn {
  margin-left: 20rpx;
}
.dialog-btn--primary {
  background: $jp-primary;
  border-color: $jp-primary;
}
.dialog-btn-text {
  font-size: 28rpx;
  font-weight: 600;
  color: $jp-muted-fg;
}
.dialog-btn-text--primary {
  color: $jp-fg;
}
</style>
