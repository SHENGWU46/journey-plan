<template>
  <view class="plans-page">
    <!-- 页面背景：顶部黄色 → 浅灰白 → 白（原型 page-bg） -->
    <view class="page-bg"></view>

    <view class="content">
      <!-- 头部：位于黄色部分（原型 page-header） -->
      <view class="page-header">
        <view class="head-titles">
          <h1 class="head-title">我的计划</h1>
          <p class="head-sub">共 {{ allPlans.length }} 段旅程</p>
        </view>
      </view>

      <!-- 白色内容卡片（原型 page-sheet） -->
      <view class="page-sheet">
        <!-- 搜索框（FR-PL-03） -->
        <view class="search">
          <view class="search-icon">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#78716C" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="7"/><path d="M21 21l-4.3-4.3"/></svg>
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
          <view v-if="keyword" class="search-clear" @click="clearSearch">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#78716C" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M18 6L6 18M6 6l12 12"/></svg>
          </view>
        </view>

        <!-- 筛选栏：全部 / 草稿 -->
        <view class="filters">
          <view
            v-for="f in filterOptions"
            :key="f.key"
            class="chip"
            :class="{ 'chip--on': activeFilter === f.key }"
            @click="activeFilter = f.key"
          >
            <text class="chip-text" :class="{ 'chip-text--on': activeFilter === f.key }">{{ f.label }}</text>
          </view>
        </view>

        <!-- 计划列表（内部滚动） -->
        <scroll-view class="list-scroll" scroll-y :show-scrollbar="false">
          <PlanCard
            v-for="p in visiblePlans"
            :key="p.id"
            :plan="p"
            @open="openPlan"
            @continue="continuePlan"
            @rename="openRename"
            @delete="removePlan"
          />

          <!-- 空态 -->
          <view v-if="!visiblePlans.length" class="empty">
            <text class="empty-title">{{ emptyTitle }}</text>
            <text class="empty-sub">{{ emptySub }}</text>
            <view class="empty-btn" @click="goNew">
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#1C1917" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><path d="M12 5v14M5 12h14"/></svg>
              <text class="empty-btn-text">新建一段旅程</text>
            </view>
          </view>

          <!-- 新建入口（空态时隐藏，避免重复） -->
          <view v-if="visiblePlans.length" class="new-btn" @click="goNew">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#A16207" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><path d="M12 5v14M5 12h14"/></svg>
            <text class="new-btn-text">新建一段旅程</text>
          </view>
        </scroll-view>
      </view>
    </view>

    <app-tab-bar current="plans" />

    <!-- 改名弹窗 -->
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
// 我的计划页（原型 §我的计划 v5）：搜索 + 筛选（全部/草稿）+ 卡片列表 + 改名/删除。
import { ref, computed } from 'vue'
import { onShow } from '@dcloudio/uni-app'
import { listPlans, renamePlan, deletePlan } from '@/api/plan.js'
import PlanCard from '@/components/PlanCard.vue'
import AppTabBar from '@/components/AppTabBar.vue'

const allPlans = ref([])
const keyword = ref('')
const activeFilter = ref('all') // all | draft
const renameVisible = ref(false)
const renameTarget = ref(null)
const renameValue = ref('')
const renameError = ref('')
const renameFocus = ref(false)
let searchTimer = null
let reqSeq = 0

const filterOptions = [
  { key: 'all', label: '全部' },
  { key: 'draft', label: '草稿' }
]

onShow(() => load())

function load() {
  const seq = ++reqSeq
  listPlans()
    .then(res => {
      if (seq !== reqSeq) return
      allPlans.value = (res.items || []).map(p => ({ ...p, completed: !!p.completed }))
    })
    .catch(() => {
      if (seq === reqSeq) allPlans.value = []
    })
}

function clearSearch() {
  keyword.value = ''
}

function onSearchInput() {
  if (searchTimer) clearTimeout(searchTimer)
  searchTimer = setTimeout(() => {
    activeFilter.value = activeFilter.value
  }, 250)
}

const visiblePlans = computed(() => {
  let list = allPlans.value
  if (activeFilter.value === 'draft') {
    list = list.filter(p => !p.completed)
  }
  const kw = keyword.value.trim().toLowerCase()
  if (kw) {
    list = list.filter(p => (p.name || '').toLowerCase().includes(kw))
  }
  return list
})

const emptyTitle = computed(() =>
  activeFilter.value === 'draft' ? '没有草稿计划' : (keyword.value ? '未找到匹配的计划' : '还没有计划')
)
const emptySub = computed(() =>
  activeFilter.value === 'draft' ? '完成的计划会出现在「全部」里' : '点下面的按钮，开始规划第一段旅程'
)

function openPlan(p) {
  // TODO: 已完成计划本应有独立详情页，但 pages/plan-detail 既未实现、也未在 pages.json
  //       注册，跳转会触发「页面加载失败」。暂与草稿共用 plan-new（getPlan 会回填已存信息）。
  continuePlan(p)
}
function continuePlan(p) {
  uni.navigateTo({ url: `/pages/plan-new/plan-new?id=${p.id}` })
}
function goNew() {
  uni.navigateTo({ url: '/pages/plan-new/plan-new' })
}

function openRename(p) {
  renameTarget.value = p
  renameValue.value = p.name
  renameError.value = ''
  renameVisible.value = true
  renameFocus.value = true
}
function closeRename() {
  renameVisible.value = false
  renameTarget.value = null
}
function submitRename() {
  const v = renameValue.value.trim()
  if (v.length < 2 || v.length > 20) {
    renameError.value = '名称需 2-20 个字符'
    return
  }
  renamePlan(renameTarget.value.id, v)
    .then(() => {
      const t = renameTarget.value
      const idx = allPlans.value.findIndex(x => x.id === t.id)
      if (idx >= 0) allPlans.value[idx].name = v
      closeRename()
      uni.showToast({ title: '已重命名', icon: 'success' })
    })
    .catch(err => {
      renameError.value = (err && err.message) || '重命名失败'
    })
}

function removePlan(p) {
  uni.showModal({
    title: '删除计划',
    content: `确认删除「${p.name}」？此操作不可撤销。`,
    confirmColor: '#DC2626',
    success(res) {
      if (!res.confirm) return
      deletePlan(p.id)
        .then(() => {
          allPlans.value = allPlans.value.filter(x => x.id !== p.id)
          uni.showToast({ title: '已删除', icon: 'success' })
        })
        .catch(err => {
          uni.showToast({ title: (err && err.message) || '删除失败', icon: 'none' })
        })
    }
  })
}
</script>

<style lang="scss" scoped>
.plans-page {
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
  align-items: flex-end;
  justify-content: space-between;
  padding: 56rpx 48rpx 24rpx;
  color: #1C1917;
}
.head-title {
  font-family: $jp-font-heading;
  font-size: 48rpx;
  font-weight: 700;
}
.head-sub {
  font-size: 26rpx;
  color: rgba(28, 25, 23, 0.7);
  margin-top: 8rpx;
}

/* 白色卡片 */
.page-sheet {
  position: relative;
  z-index: 10;
  background: #FFFFFF;
  border-radius: 56rpx 56rpx 0 0;
  box-shadow: 0 12rpx 30rpx -18rpx rgba(28, 25, 23, 0.28);
  margin: 28rpx 28rpx 0;
  flex: 1 1 auto;
  min-height: 0;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

/* 搜索 */
.search {
  flex-shrink: 0;
  display: flex;
  align-items: center;
  height: 80rpx;
  margin: 32rpx 32rpx 0;
  padding: 0 24rpx;
  background: $jp-card;
  border: 2rpx solid $jp-border;
  border-radius: $jp-radius-pill;
  box-sizing: border-box;
}
.search-icon {
  width: 32rpx;
  height: 32rpx;
  margin-right: 12rpx;
  flex-shrink: 0;
  display: flex;
  align-items: center;
  justify-content: center;
}
.search-input {
  flex: 1;
  font-size: 28rpx;
  color: $jp-fg;
}
.search-ph { color: $jp-muted-fg; }
.search-clear {
  width: 36rpx;
  height: 36rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
}

/* 筛选栏 */
.filters {
  flex-shrink: 0;
  display: flex;
  gap: 16rpx;
  margin: 24rpx 32rpx;
}
.chip {
  padding: 12rpx 32rpx;
  border-radius: $jp-radius-pill;
  background: $jp-card;
  border: 2rpx solid $jp-border;
  cursor: pointer;

  &--on {
    background: $jp-fg;
    border-color: $jp-fg;
  }
}
.chip-text {
  font-size: 26rpx;
  font-weight: 600;
  color: $jp-muted-fg;

  &--on { color: $jp-primary; }
}

/* 列表 */
.list-scroll {
  flex: 1;
  min-height: 0;
  padding: 8rpx 32rpx calc(120rpx + env(safe-area-inset-bottom));
  box-sizing: border-box;

  &::-webkit-scrollbar { width: 0; height: 0; display: none; }
  scrollbar-width: none;
}

/* 空态 */
.empty {
  text-align: center;
  padding: 80rpx 0 40rpx;
}
.empty-title {
  display: block;
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
  margin: 36rpx auto 0;
  display: inline-flex;
  align-items: center;
  gap: 12rpx;
  padding: 20rpx 40rpx;
  background: $jp-gradient-lemon;
  border-radius: $jp-radius-pill;
  cursor: pointer;
}
.empty-btn-text {
  font-size: 28rpx;
  font-weight: 700;
  color: $jp-fg;
}

/* 新建入口 */
.new-btn {
  margin-top: 32rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 12rpx;
  height: 96rpx;
  border: 2rpx dashed $jp-border;
  border-radius: $jp-radius;
  cursor: pointer;

  &:hover { border-color: $jp-primary; }
}
.new-btn-text {
  font-size: 28rpx;
  font-weight: 600;
  color: $jp-deep;
}

/* 改名弹窗 */
.mask {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.4);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 100;
}
.dialog {
  width: 560rpx;
  background: $jp-card;
  border-radius: $jp-radius;
  padding: 40rpx 32rpx;
  box-sizing: border-box;
}
.dialog-title {
  display: block;
  font-size: 32rpx;
  font-weight: 700;
  color: $jp-fg;
  margin-bottom: 28rpx;
}
.dialog-input {
  height: 88rpx;
  padding: 0 24rpx;
  border: 2rpx solid $jp-border;
  border-radius: $jp-radius-sm;
  font-size: 28rpx;
  color: $jp-fg;
  background: $jp-bg;
}
.dialog-ph { color: $jp-muted-fg; }
.dialog-error {
  display: block;
  font-size: 24rpx;
  color: $jp-danger;
  margin-top: 12rpx;
}
.dialog-ops {
  display: flex;
  gap: 20rpx;
  margin-top: 32rpx;
}
.dialog-btn {
  flex: 1;
  text-align: center;
  height: 84rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  border: 2rpx solid $jp-border;
  border-radius: $jp-radius-sm;
  cursor: pointer;

  &--primary {
    background: $jp-fg;
    border-color: $jp-fg;
  }
}
.dialog-btn-text {
  font-size: 28rpx;
  font-weight: 600;
  color: $jp-muted-fg;

  &--primary { color: $jp-primary; }
}
</style>
