<template>
  <view class="day-page">
    <scroll-view class="scroll" scroll-y :show-scrollbar="false">
      <!-- 头部 -->
      <view class="head">
        <view class="back" @click="save">
          <svg viewBox="0 0 24 24" fill="none" stroke="#1C1917" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M19 12H5M12 19l-7-7 7-7"/></svg>
        </view>
        <view class="head-main">
          <text class="head-title">第 {{ dayIndex }} 天</text>
          <text class="head-sub">{{ date }}</text>
        </view>
        <text class="ai-badge" :class="{ 'ai-badge--on': recommendations.length }">{{ recommendations.length ? '已推荐' : '待推荐' }}</text>
      </view>

      <!-- 可编辑概览：天气 / 预算 / 时间（FR-DY-03） -->
      <view class="overview">
        <!-- 当天天气：AI 默认生成，可直接手改 -->
        <view class="field">
          <view class="field-row field-row--weather">
            <svg class="ico" viewBox="0 0 24 24" fill="none" stroke="#4D7C0F" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17.5 19a4.5 4.5 0 100-9 6 6 0 00-11.3 1.5A3.5 3.5 0 006 19h11.5z"/></svg>
            <text class="field-label field-label--w">当天天气</text>
            <input
              class="field-input"
              v-model="weather"
              placeholder="如：晴 26°C"
              placeholder-style="color:#78716C"
            />
            <text class="ai-tag-sm">AI</text>
          </view>
        </view>

        <!-- 天气精度提示：城市级预报，大范围目的地（如省份）仅供参考 -->
        <text class="hint">天气为城市级预报；若目的地是省份等大范围区域，仅代表其行政中心附近，可能不准确，仅供参考。</text>

        <!-- 当天预算 / 游玩时间：并排，无默认值，可手填 -->
        <view class="grid2">
          <view class="field">
            <view class="field-row">
              <svg class="ico" viewBox="0 0 24 24" fill="none" stroke="#A16207" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 2v20M17 5.5H9.5a3 3 0 000 6h5a3 3 0 010 6H6"/></svg>
              <text class="field-label field-label--sm">当天预算</text>
            </view>
            <view class="field-row2">
              <text class="yen">¥</text>
              <input
                class="field-input"
                v-model="dailyBudget"
                type="digit"
                placeholder="自填"
                placeholder-style="color:#78716C"
              />
            </view>
          </view>
          <view class="field">
            <view class="field-row">
              <svg class="ico" viewBox="0 0 24 24" fill="none" stroke="#0284C7" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 3"/></svg>
              <text class="field-label field-label--sm">游玩时间</text>
            </view>
            <input
              class="field-input field-input--mt"
              v-model="tourTime"
              placeholder="自填"
              placeholder-style="color:#78716C"
            />
          </view>
        </view>

        <text class="hint">以上字段均可手动修改；天气默认由 AI 生成，修改后将以你的输入为准</text>
      </view>

      <!-- AI 推荐景点（FR-DY-04） -->
      <view class="section">
        <view class="section-head">
          <text class="section-title">景点卡片</text>
          <text class="section-hint">点击卡片加入 / 取消</text>
        </view>
        <view class="reco-btn" :class="{ 'reco-btn--busy': generating }" @click="generate">
          <svg viewBox="0 0 24 24" fill="none" stroke="#1C1917" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 3l1.9 5.1L19 10l-5.1 1.9L12 17l-1.9-5.1L5 10l5.1-1.9L12 3z"/></svg>
          <text class="reco-btn-text">{{ generating ? '生成中…' : (recommendations.length ? '继续推荐更多景点' : '让 AI 推荐当天景点') }}</text>
        </view>

        <!-- 手动添加景点（字段与 AI 推荐 Attraction 一致） -->
        <view class="manual-btn" @click="openAdd">
          <svg viewBox="0 0 24 24" fill="none" stroke="#A16207" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 5v14M5 12h14"/></svg>
          <text class="manual-btn-text">手动添加景点</text>
        </view>

        <view v-if="allCards.length" class="reco-list">
          <view
            v-for="(a, i) in allCards"
            :key="a.name"
            class="reco-card"
            :class="{ 'reco-card--on': isSelected(a) }"
            @click="toggle(a)"
          >
            <view class="reco-ico" :class="{ 'reco-ico--on': isSelected(a) }">
              <svg viewBox="0 0 24 24" fill="none" stroke="#78716C" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 10c0 7-9 12-9 12s-9-5-9-12a9 9 0 0118 0z"/><circle cx="12" cy="10" r="3"/></svg>
            </view>
            <view class="reco-main">
              <view class="reco-name-row">
                <text class="reco-name">{{ a.name }}</text>
                <text class="reco-tag" :class="isSelected(a) ? 'reco-tag--on' : 'reco-tag--off'">{{ a.type || '景点' }}</text>
              </view>
              <text class="reco-desc">{{ a.description }}</text>
              <text class="reco-meta">建议 {{ fmtDur(a.suggested_duration) }} · 人均 ¥{{ a.budget_per_person }}</text>
            </view>
            <view class="reco-side">
              <text class="reco-add" :class="{ 'reco-add--on': isSelected(a) }" @click.stop="toggle(a)">{{ isSelected(a) ? '已加入' : '+ 加入' }}</text>
              <view class="reco-del" @click.stop="deleteCard(a)">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 6h18M8 6V4a2 2 0 012-2h4a2 2 0 012 2v2m3 0v14a2 2 0 01-2 2H7a2 2 0 01-2-2V6"/></svg>
              </view>
            </view>
          </view>
        </view>
        <view v-else class="empty">
          <text class="empty-text">点击上方按钮，让 AI 推荐当天景点，或手动添加</text>
        </view>
      </view>

      <!-- 我的路线（FR-DY-05/06） -->
      <view class="section">
        <view class="section-head">
          <text class="section-title">我的路线</text>
          <text class="section-hint">已选 {{ selected.length }} 个景点</text>
        </view>
        <view class="route-box">
          <block v-if="selected.length">
            <view v-for="(a, i) in selected" :key="i" class="route-item">
              <text class="route-idx">{{ i + 1 }}</text>
              <text class="route-name">{{ a.name }}</text>
              <view class="route-ops">
                <view class="op-btn" :class="{ 'op-btn--off': i === 0 }" @click="moveUp(i)">
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 19V5M5 12l7-7 7 7"/></svg>
                </view>
                <view class="op-btn" :class="{ 'op-btn--off': i === selected.length - 1 }" @click="moveDown(i)">
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 5v14M19 12l-7 7-7-7"/></svg>
                </view>
                <view class="op-btn op-btn--del" @click="removeAt(i)">
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 6h18M8 6V4a2 2 0 012-2h4a2 2 0 012 2v2m3 0v14a2 2 0 01-2 2H7a2 2 0 01-2-2V6"/></svg>
                </view>
              </view>
            </view>
            <view class="route-summary">{{ routeSummary }}</view>
          </block>
          <view v-else class="empty">
            <text class="empty-text">还没有选择景点\n从上方 AI 推荐中挑选加入当天路线</text>
          </view>
        </view>
        <text class="hint hint--mt">点击「↑ / ↓」调整游览顺序 · 时段与预算随选择实时汇总</text>
      </view>
    </scroll-view>

    <!-- 底部：返回总览（保存并退出） -->
    <view class="footer">
      <view class="back-overview-btn" @click="save">
        <text class="back-overview-text">返回总览</text>
      </view>
    </view>

    <!-- 手动添加景点弹窗 -->
    <view v-if="addVisible" class="mask" @click="closeAdd">
      <view class="dialog" @click.stop>
        <text class="dialog-title">手动添加景点</text>
        <view class="form">
          <view class="form-item">
            <text class="form-label">景点名称</text>
            <input class="form-input" v-model="addForm.name" maxlength="50" placeholder="必填，如：清水寺" placeholder-style="color:#A8A29E" @input="addError = ''" />
          </view>
          <view class="form-item">
            <text class="form-label">景点类型</text>
            <input class="form-input" v-model="addForm.type" maxlength="20" placeholder="选填，如：老街 / 美食 / 自然" placeholder-style="color:#A8A29E" />
          </view>
          <view class="form-row">
            <view class="form-item form-item--half">
              <text class="form-label">建议时长（小时）</text>
              <input class="form-input" v-model="addForm.duration" type="digit" placeholder="如 2 或 1.5" placeholder-style="color:#A8A29E" />
            </view>
            <view class="form-item form-item--half">
              <text class="form-label">人均预算（元）</text>
              <input class="form-input" v-model="addForm.budget" type="digit" placeholder="如 60" placeholder-style="color:#A8A29E" />
            </view>
          </view>
          <view class="form-item">
            <text class="form-label">景点描述</text>
            <textarea class="form-textarea" v-model="addForm.description" maxlength="200" placeholder="选填，简短介绍（200 字内）" placeholder-style="color:#A8A29E" />
          </view>
        </view>
        <text v-if="addError" class="dialog-error">{{ addError }}</text>
        <view class="dialog-ops">
          <view class="dialog-btn" @click="closeAdd"><text class="dialog-btn-text">取消</text></view>
          <view class="dialog-btn dialog-btn--primary" @click="submitAdd"><text class="dialog-btn-text dialog-btn-text--primary">添加</text></view>
        </view>
      </view>
    </view>
  </view>
</template>

<script setup>
// 单日计划详情页（原型 §制定计划 STEP4 单日详情 / §3.4）：
// - 天气 / 当日预算 / 游玩时间 可编辑（AI 推荐时自动带出天气）
// - 「让 AI 推荐当天景点」调用后端 POST /plans/{id}/days 生成候选，点击卡片加入/移出路线
// - 我的路线支持排序与删除，确认后 PUT /plans/{id}/days/{day} 落库
// 入参：planId / day(第几天) / date，来自总览页跳转
import { ref, computed, reactive } from 'vue'
import { onLoad } from '@dcloudio/uni-app'
import {
  generateDailyPlans,
  getDailyPlans,
  saveDailyPlan
} from '@/api/plan.js'

const planId = ref(null)
const dayIndex = ref(1)
const date = ref('')
const generating = ref(false)

const weather = ref('')
const tourTime = ref('')
const dailyBudget = ref('')
const recommendations = ref([]) // AI 推荐候选
const selected = ref([])        // 已选入路线的景点（顺序即路线顺序）
const manualCards = ref([])     // 手动添加的景点：独立持久池，移出路线后也不消失（满足「不加入也要保留」）

// 手动添加景点（字段与 AI 推荐 Attraction 保持一致）
const addVisible = ref(false)
const addError = ref('')
const addForm = reactive({ name: '', type: '', duration: '', budget: '', description: '' })

// 路线汇总文案（原型：酒店出发 → … → 返回酒店）
const routeSummary = computed(() => {
  if (!selected.value.length) return ''
  return '酒店出发 → ' + selected.value.map(s => s.name).join(' → ') + ' → 返回酒店'
})

// 上方卡片 = AI 推荐 ∪ 手动候选 ∪ 我的路线（按 name 去重）；手动候选移出路线后仍在卡片列表，不会凭空消失
const allCards = computed(() => {
  const list = []
  const seen = new Set()
  for (const a of recommendations.value) {
    if (!seen.has(a.name)) { seen.add(a.name); list.push(a) }
  }
  for (const a of manualCards.value) {
    if (!seen.has(a.name)) { seen.add(a.name); list.push(a) }
  }
  for (const a of selected.value) {
    if (!seen.has(a.name)) { seen.add(a.name); list.push(a) }
  }
  return list
})

// 同一景点以 name 作为唯一标识
function isSelected(a) {
  return selected.value.some(x => x.name === a.name)
}
function toggle(a) {
  if (isSelected(a)) {
    selected.value = selected.value.filter(x => x.name !== a.name)
  } else {
    selected.value = [...selected.value, a]
  }
}
function swap(i, j) {
  const arr = [...selected.value]
  const t = arr[i]
  arr[i] = arr[j]
  arr[j] = t
  selected.value = arr
}
function moveUp(i) {
  if (i > 0) swap(i, i - 1)
}
function moveDown(i) {
  if (i < selected.value.length - 1) swap(i, i + 1)
}
function removeAt(i) {
  selected.value = selected.value.filter((_, idx) => idx !== i)
}
// 从卡片列表彻底删除某张卡片：同时移出 AI 推荐池、手动候选池与已选路线（按 name 匹配）
function deleteCard(a) {
  recommendations.value = recommendations.value.filter(x => x.name !== a.name)
  manualCards.value = manualCards.value.filter(x => x.name !== a.name)
  selected.value = selected.value.filter(x => x.name !== a.name)
}

function fmtDur(v) {
  const n = Number(v)
  if (!n) return '时长未定'
  return Number.isInteger(n) ? `${n} 小时` : `${n.toFixed(1)} 小时`
}

async function generate() {
  if (planId.value == null) return
  generating.value = true
  try {
    const res = await generateDailyPlans(planId.value, {
      date: date.value,
      tour_time: tourTime.value || undefined,
      daily_budget: dailyBudget.value ? Number(dailyBudget.value) : undefined,
      // 换一批：把当前已展示的所有卡片名传给后端，后端会排除它们并检索不同候选
      existing_attractions: allCards.value.map(x => x.name)
    })
    // AI 重新生成的卡片「追加」到已有卡片之后（按 name 去重，避免与已推荐/已加入的重复）
    const incoming = res.attractions || []
    const existingNames = new Set(allCards.value.map(x => x.name))
    const appended = incoming.filter(a => !existingNames.has(a.name))
    recommendations.value = [...recommendations.value, ...appended]
    if (!weather.value && res.weather) weather.value = res.weather
  } catch (err) {
    uni.showToast({ title: (err && err.message) || '推荐失败', icon: 'none' })
  } finally {
    generating.value = false
  }
}

async function loadSaved() {
  if (planId.value == null) return
  try {
    const res = await getDailyPlans(planId.value)
    const d = (res.items || []).find(x => x.day_index === dayIndex.value)
    if (d) {
      weather.value = d.weather || ''
      tourTime.value = d.tour_time || ''
      dailyBudget.value = d.daily_budget != null ? String(d.daily_budget) : ''
      // 候选池优先取 candidate_cards（完整候选池，含未入路线的卡片）；
      // 旧数据无该字段时回退到 attractions，保证兼容。
      // 否则未入路线的卡片只存在于 selected，移出路线即整张消失。
      const pool = (d.candidate_cards && d.candidate_cards.length) ? d.candidate_cards : (d.attractions || [])
      recommendations.value = [...pool]
      selected.value = [...(d.attractions || [])]
    }
  } catch (err) {
    console.error('[day-plan] 加载已保存计划失败', err)
  }
}

async function save() {
  if (planId.value == null) return
  try {
    await saveDailyPlan(planId.value, dayIndex.value, {
      date: date.value,
      weather: weather.value,
      tour_time: tourTime.value || null,
      daily_budget: dailyBudget.value ? Number(dailyBudget.value) : null,
      attractions: selected.value,
      candidate_cards: allCards.value
    })
    uni.showToast({ title: '已保存', icon: 'success' })
    setTimeout(() => uni.navigateBack(), 400)
  } catch (err) {
    uni.showToast({ title: (err && err.message) || '保存失败', icon: 'none' })
  }
}

function openAdd() {
  addError.value = ''
  addForm.name = ''
  addForm.type = ''
  addForm.duration = ''
  addForm.budget = ''
  addForm.description = ''
  addVisible.value = true
}
function closeAdd() {
  addVisible.value = false
}
function submitAdd() {
  const name = addForm.name.trim()
  if (!name) {
    addError.value = '请填写景点名称'
    return
  }
  if (allCards.value.some(x => x.name === name)) {
    addError.value = '该景点已存在'
    return
  }
  // 与 AI 推荐 Attraction 字段对齐：name/type/suggested_duration/budget_per_person/description
  const card = {
    name,
    type: addForm.type.trim(),
    suggested_duration: Number(addForm.duration) || 0,
    budget_per_person: Math.round(Number(addForm.budget) || 0),
    description: addForm.description.trim()
  }
  // 同时进入「手动候选池」与「路线」：从路线移出后仍在候选池，不会凭空消失
  manualCards.value = [...manualCards.value, card]
  selected.value = [...selected.value, card]
  closeAdd()
  uni.showToast({ title: '已添加', icon: 'success' })
}

onLoad((opts) => {
  planId.value = Number(opts.planId)
  dayIndex.value = Number(opts.day) || 1
  date.value = opts.date || ''
  loadSaved()
})
</script>

<style lang="scss" scoped>
.day-page {
  position: relative;
  height: 100vh;
  overflow: hidden;
  display: flex;
  flex-direction: column;
  box-sizing: border-box;
  padding-top: env(safe-area-inset-top);
  background: $jp-bg;

  & * {
    box-sizing: border-box;
  }
}
.scroll {
  flex: 1 1 auto;
  min-height: 0;
  padding: 40rpx;
  box-sizing: border-box;
}

/* 头部 */
.head {
  display: flex;
  align-items: center;
  gap: 24rpx;
  margin-bottom: 32rpx;
}
.back {
  width: 72rpx;
  height: 72rpx;
  border-radius: 9999rpx;
  background: $jp-card;
  border: 2rpx solid $jp-border;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;

  svg { width: 36rpx; height: 36rpx; }
}
.head-main {
  flex: 1;
  display: flex;
  flex-direction: column;
  min-width: 0;
}
.head-title {
  font-family: $jp-font-heading;
  font-size: 36rpx;
  font-weight: 700;
  color: $jp-fg;
}
.head-sub {
  font-size: 24rpx;
  color: $jp-muted-fg;
  margin-top: 4rpx;
}
.ai-badge {
  flex-shrink: 0;
  font-size: 20rpx;
  font-weight: 700;
  color: $jp-muted-fg;
  background: $jp-muted;
  padding: 8rpx 20rpx;
  border-radius: 9999rpx;

  &--on {
    color: $jp-deep;
    background: rgba(250, 204, 21, 0.12);
  }
}

/* 概览区 */
.overview {
  display: flex;
  flex-direction: column;
  gap: 16rpx;
  margin-bottom: 32rpx;
}
.field {
  background: $jp-card;
  border-radius: $jp-radius;
  border: 2rpx solid $jp-border;
  padding: 24rpx;
}
.field-row {
  display: flex;
  align-items: center;
  gap: 16rpx;

  &--weather { gap: 24rpx; }
}
.field-row2 {
  display: flex;
  align-items: center;
  gap: 8rpx;
  margin-top: 12rpx;
}
.ico {
  width: 30rpx;
  height: 30rpx;
  flex-shrink: 0;
}
.field-label {
  font-size: 22rpx;
  font-weight: 600;
  color: $jp-muted-fg;

  &--sm { font-size: 20rpx; }
  &--w { width: 96rpx; flex-shrink: 0; }
}
.field-input {
  flex: 1;
  min-width: 0;
  background: transparent;
  font-size: 28rpx;
  font-weight: 500;
  color: $jp-fg;

  &--mt { margin-top: 12rpx; }
}
.yen {
  font-size: 28rpx;
  color: $jp-muted-fg;
}
.ai-tag-sm {
  flex-shrink: 0;
  font-size: 18rpx;
  font-weight: 700;
  color: $jp-deep3;
  background: rgba(56, 189, 248, 0.12);
  padding: 4rpx 16rpx;
  border-radius: 9999rpx;
}
.grid2 {
  display: flex;
  gap: 16rpx;

  .field { flex: 1; }
}
.hint {
  font-size: 20rpx;
  color: $jp-muted-fg;
  line-height: 1.5;
  padding: 0 8rpx;

  &--mt { margin-top: 16rpx; }
}

/* 区块标题 */
.section { margin-top: 32rpx; }
.section-head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 16rpx;
}
.section-title {
  font-family: $jp-font-heading;
  font-size: 28rpx;
  font-weight: 700;
  color: $jp-fg;
}
.section-hint {
  font-size: 22rpx;
  color: $jp-muted-fg;
}

/* AI 推荐按钮（aurora 渐变主按钮） */
.reco-btn {
  width: 100%;
  background: $jp-gradient-lemon;
  color: #1C1917;
  font-weight: 700;
  font-size: 28rpx;
  padding: 28rpx 0;
  border-radius: $jp-radius;
  box-shadow: 0 10rpx 30rpx -12rpx rgba(28, 25, 23, 0.22);
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 12rpx;
  cursor: pointer;

  &--busy { opacity: 0.7; }
  svg { width: 32rpx; height: 32rpx; }
}
.reco-btn-text {
  font-size: 28rpx;
  font-weight: 700;
  color: #1C1917;
}

/* 推荐卡片 */
.reco-list {
  display: flex;
  flex-direction: column;
  gap: 20rpx;
  margin-top: 20rpx;
}
.reco-card {
  width: 100%;
  background: $jp-card;
  border-radius: $jp-radius;
  border: 2rpx solid $jp-border;
  padding: 28rpx;
  display: flex;
  align-items: flex-start;
  gap: 24rpx;
  text-align: left;
  cursor: pointer;

  &--on { border-color: $jp-primary; }
}
.reco-ico {
  width: 80rpx;
  height: 80rpx;
  border-radius: 24rpx;
  background: $jp-muted;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;

  svg { width: 36rpx; height: 36rpx; }
  &--on {
    background: $jp-gradient-lemon;
    svg { stroke: #1C1917; }
  }
}
.reco-main {
  flex: 1;
  min-width: 0;
  display: flex;
  flex-direction: column;
}
.reco-name-row {
  display: flex;
  align-items: center;
  gap: 12rpx;
  flex-wrap: wrap;
}
.reco-name {
  font-size: 28rpx;
  font-weight: 700;
  color: $jp-fg;
}
.reco-tag {
  font-size: 18rpx;
  font-weight: 700;
  padding: 4rpx 12rpx;
  border-radius: 9999rpx;

  &--on { color: $jp-deep; background: rgba(250, 204, 21, 0.12); }
  &--off { color: $jp-deep2; background: rgba(132, 204, 22, 0.12); }
}
.reco-desc {
  font-size: 22rpx;
  color: $jp-muted-fg;
  margin-top: 8rpx;
  line-height: 1.5;
}
.reco-meta {
  font-size: 20rpx;
  color: $jp-muted-fg;
  margin-top: 12rpx;
}
.reco-side {
  flex-shrink: 0;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 12rpx;
}
.reco-add {
  flex-shrink: 0;
  font-size: 20rpx;
  font-weight: 700;
  padding: 10rpx 20rpx;
  border-radius: 9999rpx;
  background: $jp-muted;
  color: $jp-deep;

  &--on { background: #A16207; color: #FFFFFF; }
}
.reco-del {
  width: 44rpx;
  height: 44rpx;
  border-radius: 9999rpx;
  background: $jp-muted;
  color: $jp-danger;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;

  svg { width: 26rpx; height: 26rpx; }
  &:active { background: rgba(220, 38, 38, 0.12); }
}

/* 我的路线 */
.route-box {
  background: $jp-card;
  border-radius: $jp-radius;
  border: 2rpx solid $jp-border;
  padding: 32rpx;
}
.route-item {
  display: flex;
  align-items: center;
  gap: 16rpx;
  padding: 16rpx 0;

  & + .route-item { border-top: 2rpx solid $jp-border; }
}
.route-idx {
  width: 48rpx;
  height: 48rpx;
  border-radius: 9999rpx;
  background: rgba(250, 204, 21, 0.12);
  color: $jp-deep;
  font-size: 20rpx;
  font-weight: 700;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}
.route-name {
  flex: 1;
  min-width: 0;
  font-size: 28rpx;
  font-weight: 600;
  color: $jp-fg;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.route-ops {
  display: flex;
  gap: 8rpx;
}
.op-btn {
  padding: 8rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  color: $jp-muted-fg;
  cursor: pointer;

  svg { width: 30rpx; height: 30rpx; }
  &--off { opacity: 0.3; pointer-events: none; }
  &--del { color: $jp-danger; }
}
.route-summary {
  margin-top: 16rpx;
  padding-top: 20rpx;
  border-top: 2rpx solid $jp-border;
  font-size: 22rpx;
  color: $jp-muted-fg;
  line-height: 1.6;
}

/* 空态 */
.empty {
  padding: 30rpx 0;
  text-align: center;
}
.empty-text {
  font-size: 24rpx;
  color: $jp-muted-fg;
  line-height: 1.6;
}

/* 底部：返回总览 */
.footer {
  flex-shrink: 0;
  padding: 16rpx 32rpx calc(16rpx + env(safe-area-inset-bottom));
  background: linear-gradient(to top, #FFFBEB 70%, rgba(255, 251, 235, 0));
}
.back-overview-btn {
  width: 100%;
  background: $jp-card;
  border: 2rpx solid $jp-border;
  border-radius: $jp-radius;
  padding: 24rpx 0;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;

  &:hover { border-color: $jp-primary; }
  &:hover .back-overview-text { color: $jp-deep; }
}
.back-overview-text {
  font-size: 28rpx;
  font-weight: 600;
  color: $jp-muted-fg;
}

/* 手动添加景点入口 */
.manual-btn {
  margin-top: 20rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 12rpx;
  padding: 22rpx 0;
  border: 2rpx dashed $jp-border;
  border-radius: $jp-radius;
  cursor: pointer;

  svg { width: 30rpx; height: 30rpx; }
  &:hover { border-color: $jp-primary; }
}
.manual-btn-text {
  font-size: 26rpx;
  font-weight: 600;
  color: $jp-deep;
}

/* 手动添加弹窗 */
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
  width: 620rpx;
  max-height: 80vh;
  overflow-y: auto;
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
.form {
  display: flex;
  flex-direction: column;
  gap: 20rpx;
}
.form-row {
  display: flex;
  gap: 16rpx;
}
.form-item {
  display: flex;
  flex-direction: column;
  gap: 10rpx;

  &--half { flex: 1; min-width: 0; }
}
.form-label {
  font-size: 22rpx;
  font-weight: 600;
  color: $jp-muted-fg;
}
.form-input {
  height: 80rpx;
  padding: 0 20rpx;
  border: 2rpx solid $jp-border;
  border-radius: $jp-radius-sm;
  font-size: 28rpx;
  color: $jp-fg;
  background: $jp-bg;
  box-sizing: border-box;
}
.form-textarea {
  width: 100%;
  height: 160rpx;
  padding: 16rpx 20rpx;
  border: 2rpx solid $jp-border;
  border-radius: $jp-radius-sm;
  font-size: 26rpx;
  color: $jp-fg;
  background: $jp-bg;
  box-sizing: border-box;
}
.dialog-error {
  display: block;
  font-size: 24rpx;
  color: $jp-danger;
  margin-top: 12rpx;
}
.dialog-ops {
  display: flex;
  gap: 20rpx;
  margin-top: 28rpx;
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
