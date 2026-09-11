<template>
  <view class="new-page">
    <!-- 头部 -->
    <view class="head">
      <view class="back" @click="onBack">
        <!-- Lucide 官方 chevron-left（lucide-static v1.41.0，ISC 许可），path 为官方原始数据 -->
        <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#1C1917" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><path d="m15 18-6-6 6-6"/></svg>
      </view>
      <view class="head-main">
        <text class="step-hint">STEP {{ step + 1 }} / 2</text>
        <text class="head-title">{{ stepTitle }}</text>
      </view>
    </view>

    <!-- 步骤条 -->
    <StepIndicator :current="step" :total="2" />

    <scroll-view class="scroll" scroll-y>
    <!-- ============ STEP 1：计划信息（FR-WZ-01~05） ============ -->
    <view v-if="step === 0" class="step">
      <!-- 旅程名称 -->
      <view class="field">
        <text class="field-label">旅程名称</text>
        <view class="field-box">
          <svg class="field-ico" viewBox="0 0 24 24" fill="none" stroke="#A16207" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 20h9"/><path d="M16.5 3.5a2.1 2.1 0 013 3L7 19l-4 1 1-4 12.5-12.5z"/></svg>
          <input
            class="field-input"
            v-model="form.name"
            maxlength="20"
            placeholder="例如：京都秋日漫游"
            placeholder-style="color:#78716C"
            @input="errors.name = ''"
          />
        </view>
        <text v-if="errors.name" class="err">{{ errors.name }}</text>
        <text v-else class="hint">1-20 个字符，必填</text>
      </view>

      <!-- 目的地 -->
      <view class="field">
        <text class="field-label">目的地</text>
        <view class="field-box">
          <svg class="field-ico" viewBox="0 0 24 24" fill="none" stroke="#A16207" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 10c0 7-9 12-9 12s-9-5-9-12a9 9 0 0118 0z"/><circle cx="12" cy="10" r="3"/></svg>
          <input
            class="field-input"
            v-model="form.destination"
            maxlength="40"
            placeholder="想去哪里？"
            placeholder-style="color:#78716C"
            @input="errors.destination = ''"
          />
        </view>
        <text v-if="errors.destination" class="err">{{ errors.destination }}</text>
      </view>

      <!-- 往返日期 -->
      <view class="field">
        <text class="field-label">往返日期</text>
        <view class="field-row">
          <view class="field-box field-box--half">
            <svg class="field-ico" viewBox="0 0 24 24" fill="none" stroke="#78716C" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="4" width="18" height="18" rx="2"/><path d="M16 2v4M8 2v4M3 10h18"/></svg>
            <picker mode="date" :value="form.depart_date" @change="onDepart">
              <view class="picker" :class="{ 'picker--empty': !form.depart_date }">
                {{ form.depart_date || '出发日期' }}
              </view>
            </picker>
          </view>
          <view class="field-box field-box--half">
            <svg class="field-ico" viewBox="0 0 24 24" fill="none" stroke="#78716C" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="4" width="18" height="18" rx="2"/><path d="M16 2v4M8 2v4M3 10h18"/></svg>
            <picker mode="date" :value="form.return_date" @change="onReturn">
              <view class="picker" :class="{ 'picker--empty': !form.return_date }">
                {{ form.return_date || '返回日期' }}
              </view>
            </picker>
          </view>
        </view>
        <text v-if="errors.dates" class="err">{{ errors.dates }}</text>
        <text v-else-if="totalDays" class="hint">共 {{ totalDays }} 天</text>
      </view>

      <!-- 同行人数 -->
      <view class="field">
        <text class="field-label">同行人数</text>
        <view class="stepper">
          <view class="step-btn" @click="changePeople(-1)" aria-label="减少">
            <text class="step-btn-text">−</text>
          </view>
          <text class="step-num">{{ form.people_count }} 人</text>
          <view class="step-btn" @click="changePeople(1)" aria-label="增加">
            <text class="step-btn-text">+</text>
          </view>
        </view>
        <text v-if="errors.people" class="err">{{ errors.people }}</text>
      </view>

      <!-- 总预算 -->
      <view class="field">
        <text class="field-label">总预算（元）</text>
        <view class="field-box">
          <svg class="field-ico" viewBox="0 0 24 24" fill="none" stroke="#A16207" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 2v20M17 5.5H9.5a3 3 0 000 6h5a3 3 0 010 6H6"/></svg>
          <input
            class="field-input"
            v-model="form.total_budget"
            type="digit"
            maxlength="9"
            placeholder="预计总花费，如 15000"
            placeholder-style="color:#78716C"
          />
        </view>
      </view>

      <view class="spacer"></view>
      <view class="next-btn" @click="nextFromInfo">
        <text class="next-text">下一步：生成每日计划</text>
        <text class="next-arrow">›</text>
      </view>
    </view>

    <!-- ============ STEP 2：每日计划（本期占位，下一步实现） ============ -->
    <view v-else class="step">
      <view class="cover">
        <text class="cover-tag">JOURNEY PLAN · 总计划</text>
        <text class="cover-name">{{ form.name || '未命名旅程' }}</text>
        <view class="cover-grid">
          <view class="cover-cell">
            <text class="cover-cell-label">时间</text>
            <text class="cover-cell-value">{{ dateRange }}</text>
          </view>
          <view class="cover-cell">
            <text class="cover-cell-label">人数</text>
            <text class="cover-cell-value">{{ form.people_count }} 人</text>
          </view>
          <view class="cover-cell">
            <text class="cover-cell-label">天数</text>
            <text class="cover-cell-value">{{ totalDays || '-' }} 天</text>
          </view>
          <view class="cover-cell">
            <text class="cover-cell-label">预算</text>
            <text class="cover-cell-value">{{ form.total_budget ? form.total_budget + ' 元' : '未填' }}</text>
          </view>
        </view>
      </view>

      <!-- 一键为全部天数生成推荐 -->
      <view class="ghost-btn" :class="{ 'ghost-btn--busy': generating }" @click="generateAll">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#1C1917" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 3l1.9 5.1L19 10l-5.1 1.9L12 17l-1.9-5.1L5 10l5.1-1.9L12 3z"/></svg>
        <text class="ghost-btn-text">{{ generating ? (genProgress || '正在生成…') : 'AI 一键推荐全部景点' }}</text>
      </view>

      <!-- 每日计划列表 -->
      <view class="days-head">
        <text class="days-title">每日计划</text>
        <text class="days-progress">{{ doneDayCount }} / {{ dayList.length }} 天已安排</text>
      </view>
      <view class="day-list">
        <view v-for="d in dayList" :key="d.index" class="day-card" @click="openDay(d)">
          <view class="day-main">
            <text class="day-title">第 {{ d.index }} 天 · {{ d.date.slice(5) }}</text>
            <text class="day-sub">{{ daySummary(d) }}</text>
          </view>
          <text class="day-badge" :class="{ 'day-badge--done': savedMap[d.index] && (savedMap[d.index].attractions || []).length > 0 }">
            {{ savedMap[d.index] && (savedMap[d.index].attractions || []).length > 0 ? '已安排' : '待推荐' }}
          </text>
        </view>
        <view v-if="!dayList.length" class="day-empty">
          <text class="day-empty-text">请先在 STEP 1 填写往返日期</text>
        </view>
      </view>

      <view class="spacer"></view>
      <view class="next-btn" @click="finishPlan">
        <text class="next-text">完成计划</text>
      </view>
    </view>
    </scroll-view>
  </view>
</template>

<script setup>
// 新建旅程（原型 §制定计划）：STEP 1 计划信息（名称/目的地/往返日期/同行人数） → STEP 2 每日计划。
// 本期实现到 STEP 1（含完整校验与进入 STEP 2 的入口）；STEP 2 暂为占位封面。
// 数据流：新建时先 POST /plans 创建草稿拿 planId，其余字段通过 PATCH /plans/{id} 提交；
//        从「继续编辑」进入时 planId 已存在，改用 GET /plans/{id} 拉取详情回填表单。
// 注意：onLoad 是 uni-app 页面生命周期，必须从 @dcloudio/uni-app 导入，
// 不能从 'vue' 导入（Vue 无此导出，会导致本页模块加载失败、页面打不开）。
import { ref, reactive, computed } from 'vue'
import { onLoad, onShow } from '@dcloudio/uni-app'
import StepIndicator from '@/components/StepIndicator.vue'
import {
  createPlan,
  updatePlan,
  getPlan,
  generateDailyPlans,
  getDailyPlans,
  saveDailyPlan
} from '@/api/plan.js'

const step = ref(0) // 0 = STEP1 计划信息, 1 = STEP2 每日计划总览
const planId = ref(null)

const errors = reactive({ name: '', destination: '', dates: '', people: '' })

const form = reactive({
  name: '',
  destination: '',
  depart_date: '',
  return_date: '',
  people_count: 2,
  total_budget: ''
})

const MAX_DAYS = 14
const MIN_PEOPLE = 1
const MAX_PEOPLE = 10

const stepTitle = computed(() => ['计划信息', '每日计划'][step.value])

// 天数自动计算（往返均选且返回≥出发时有效）
const totalDays = computed(() => {
  if (!form.depart_date || !form.return_date) return 0
  const a = new Date(form.depart_date)
  const b = new Date(form.return_date)
  if (isNaN(a) || isNaN(b) || b < a) return 0
  return Math.round((b - a) / 86400000) + 1
})

const dateRange = computed(() => {
  if (!form.depart_date || !form.return_date) return '—'
  return form.depart_date.slice(5) + ' – ' + form.return_date.slice(5)
})

// ---------------- 每日计划（STEP 2 总览） ----------------
const savedDays = ref([])
const generating = ref(false)
const genProgress = ref('')

// 由往返日期展开出每天（第 1 天起），日期串用于调用 agent 接口
const dayList = computed(() => {
  if (!form.depart_date || !form.return_date || totalDays.value <= 0) return []
  const start = new Date(form.depart_date + 'T00:00:00')
  const list = []
  for (let i = 0; i < totalDays.value; i++) {
    const d = new Date(start.getTime() + i * 86400000)
    const mm = String(d.getMonth() + 1).padStart(2, '0')
    const dd = String(d.getDate()).padStart(2, '0')
    list.push({ index: i + 1, date: `${d.getFullYear()}-${mm}-${dd}` })
  }
  return list
})

// day_index → 已保存的单日计划，便于卡片读取状态
const savedMap = computed(() => {
  const m = {}
  savedDays.value.forEach(d => { m[d.day_index] = d })
  return m
})
const doneDayCount = computed(
  () => savedDays.value.filter(d => (d.attractions || []).length > 0).length
)

function daySummary(d) {
  const s = savedMap.value[d.index]
  if (!s) return '点击安排当天的景点与路线'
  const n = (s.attractions || []).length
  const w = s.weather || ''
  if (n) return w ? `${w} · 已选 ${n} 个景点` : `已选 ${n} 个景点`
  return w || '已保存'
}

async function loadDays() {
  if (planId.value == null) return
  try {
    const res = await getDailyPlans(planId.value)
    savedDays.value = res.items || []
  } catch (err) {
    console.error('[plan-new] 加载每日计划失败', err)
  }
}

function openDay(d) {
  uni.navigateTo({
    url: `/pages/day-plan/day-plan?planId=${planId.value}&day=${d.index}&date=${d.date}`
  })
}

// 一键为全部天数生成推荐：逐天调用 agent 接口并直接落库，
// 之后仍可进入单日详情页增删景点（生成结果作为当天的初始路线）。
async function generateAll() {
  if (planId.value == null) {
    uni.showToast({ title: '请先完成计划信息', icon: 'none' })
    return
  }
  if (!dayList.value.length) {
    uni.showToast({ title: '请先填写往返日期', icon: 'none' })
    return
  }
  generating.value = true
  let ok = 0
  try {
    for (const d of dayList.value) {
      genProgress.value = `正在生成 ${d.index} / ${dayList.value.length} 天`
      const res = await generateDailyPlans(planId.value, { date: d.date })
      await saveDailyPlan(planId.value, d.index, {
        date: d.date,
        weather: res.weather || '',
        attractions: res.attractions || []
      })
      ok++
    }
    await loadDays()
    uni.showToast({ title: `已生成 ${ok} 天计划`, icon: 'success' })
  } catch (err) {
    uni.showToast({ title: (err && err.message) || '生成失败', icon: 'none' })
  } finally {
    generating.value = false
    genProgress.value = ''
  }
}

onLoad((opts) => {
  if (opts && opts.id) {
    // 继续编辑草稿：记住 id 后拉取详情回填表单（后端 GET /plans/{id} 已实现）
    planId.value = Number(opts.id)
    loadDraft(planId.value)
  }
})

onShow(() => {
  // 从单日详情页返回时刷新总览（plan-new 仍在页面栈中，只会触发 onShow）
  if (step.value === 1 && planId.value != null) loadDays()
})

// 草稿回填：GET /plans/{id} → 表单字段。
// 后端 PlanOut 约定（app/schemas/plan.py）：
//   destination/depart_date/return_date/people_count 草稿时为 null；
//   total_budget 为 int 且草稿默认 0，0 与「未填」等价，故回填为空串；
//   日期序列化为 YYYY-MM-DD，正好是 date picker 需要的格式。
// 若第一步信息已填（有往返日期），直接进入 STEP2 每日计划总览，
// 让日期卡片立即可见可点（否则默认落在 STEP1，易被误以为「每日计划进不去」）。
async function loadDraft(id) {
  try {
    const p = await getPlan(id)
    form.name = p.name || ''
    form.destination = p.destination || ''
    form.depart_date = p.depart_date || ''
    form.return_date = p.return_date || ''
    form.people_count = p.people_count != null ? p.people_count : 2
    form.total_budget = p.total_budget ? String(p.total_budget) : ''

    if (form.depart_date && form.return_date && totalDays.value > 0) {
      step.value = 1
      loadDays()
    }
  } catch (err) {
    // 提示由 request.js 统一弹出（含后端 detail，如「计划不存在」），此处仅兜底记录
    console.error('[plan-new] 加载草稿失败', id, err)
  }
}

function onDepart(e) {
  form.depart_date = e.detail.value
  errors.dates = ''
}
function onReturn(e) {
  form.return_date = e.detail.value
  errors.dates = ''
}

function changePeople(delta) {
  form.people_count = Math.min(MAX_PEOPLE, Math.max(MIN_PEOPLE, form.people_count + delta))
}

// STEP1 校验（FR-WZ-01~05）
function validate() {
  errors.name = ''
  errors.destination = ''
  errors.dates = ''
  errors.people = ''
  let ok = true

  const name = form.name.trim()
  if (name.length < 1 || name.length > 20) {
    errors.name = '名称需 1-20 个字符'
    ok = false
  }
  if (!form.destination.trim()) {
    errors.destination = '请填写目的地'
    ok = false
  }
  if (!form.depart_date || !form.return_date) {
    errors.dates = '请选择往返日期'
    ok = false
  } else if (new Date(form.return_date) < new Date(form.depart_date)) {
    errors.dates = '返回日期需不早于出发日期'
    ok = false
  } else if (totalDays.value > MAX_DAYS) {
    errors.dates = `暂支持最长 ${MAX_DAYS} 天行程`
    ok = false
  }
  if (form.people_count < MIN_PEOPLE) {
    errors.people = `人数至少 ${MIN_PEOPLE} 人`
    ok = false
  }
  return ok
}

async function nextFromInfo() {
  if (!validate()) return
  try {
    if (planId.value == null) {
      const created = await createPlan({ name: form.name.trim() })
      planId.value = created.id
    }
    if (planId.value != null) {
      // 失败不再静默吞掉：数据存不进去时，草稿回填出来就是空的，必须让用户看见原因
      await updatePlan(planId.value, {
        name: form.name.trim(),
        destination: form.destination.trim(),
        depart_date: form.depart_date,
        return_date: form.return_date,
        people_count: Number(form.people_count),
        total_budget: form.total_budget ? Number(form.total_budget) : null,
        total_days: totalDays.value
      }).catch(err => {
        console.error('[plan-new] 保存计划信息失败', err)
        uni.showToast({ title: (err && err.message) || '信息保存失败', icon: 'none' })
      })
    }
    step.value = 1
    loadDays()
  } catch (err) {
    uni.showToast({ title: (err && err.message) || '创建失败', icon: 'none' })
  }
}

// 完成计划：PATCH completed=true，成功后返回列表页（plans 页 onShow 会自动刷新列表）。
// 后端 PlanPatch 支持 completed 字段（app/schemas/plan.py）。
async function finishPlan() {
  if (planId.value == null) {
    uni.showToast({ title: '计划尚未创建', icon: 'none' })
    return
  }
  try {
    await updatePlan(planId.value, { completed: true })
    uni.showToast({ title: '计划已完成', icon: 'success' })
    setTimeout(() => uni.reLaunch({ url: '/pages/plans/plans' }), 500)
  } catch (err) {
    uni.showToast({ title: (err && err.message) || '完成失败', icon: 'none' })
  }
}

function onBack() {
  if (step.value === 0) {
    uni.navigateBack({ fail() { uni.reLaunch({ url: '/pages/plans/plans' }) } })
  } else {
    step.value -= 1
  }
}
</script>

<style lang="scss" scoped>
.new-page {
  height: 100vh;
  display: flex;
  flex-direction: column;
  background: $jp-bg;
  padding: 32rpx;
  padding-top: calc(32rpx + env(safe-area-inset-top));
  box-sizing: border-box;

  & * {
    box-sizing: border-box;
  }
}

.scroll {
  flex: 1 1 auto;
  min-height: 0;
}

.head {
  display: flex;
  align-items: center;
  margin-bottom: 28rpx;
}
.back {
  width: 48rpx;
  height: 48rpx;
  margin-right: 16rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
}
.head-main {
  display: flex;
  flex-direction: column;
}
.step-hint {
  font-size: 22rpx;
  font-weight: 600;
  letter-spacing: 2rpx;
  color: $jp-muted-fg;
}
.head-title {
  font-family: $jp-font-heading;
  font-size: 38rpx;
  font-weight: 700;
  color: $jp-fg;
  margin-top: 4rpx;
}

.step {
  margin-top: 32rpx;
}
.field {
  margin-bottom: 28rpx;
}
.field-row {
  display: flex;
  gap: 20rpx;
}
.field-label {
  display: block;
  font-size: 26rpx;
  font-weight: 600;
  color: $jp-muted-fg;
  margin-bottom: 12rpx;
}
.field-box {
  display: flex;
  align-items: center;
  gap: 16rpx;
  height: 88rpx;
  padding: 0 24rpx;
  background: $jp-card;
  border: 2rpx solid $jp-border;
  border-radius: $jp-radius-sm;
  transition: border-color .18s ease;

  &:focus-within {
    border-color: $jp-primary;
  }
  &--half {
    flex: 1;
  }
}
.field-ico {
  width: 32rpx;
  height: 32rpx;
  flex-shrink: 0;
}
.field-input {
  flex: 1;
  min-width: 0;
  background: transparent;
  font-size: 28rpx;
  color: $jp-fg;
}
.picker {
  flex: 1;
  min-width: 0;
  display: flex;
  align-items: center;
  font-size: 28rpx;
  color: $jp-fg;

  &--empty {
    color: $jp-muted-fg;
  }
}

.hint {
  display: block;
  font-size: 22rpx;
  color: $jp-muted-fg;
  margin-top: 12rpx;
}
.err {
  display: block;
  font-size: 22rpx;
  color: $jp-danger;
  margin-top: 12rpx;
}

/* 人数步进器 */
.stepper {
  display: flex;
  align-items: center;
  justify-content: space-between;
  height: 88rpx;
  padding: 0 8rpx;
  background: $jp-card;
  border: 2rpx solid $jp-border;
  border-radius: $jp-radius-sm;
}
.step-btn {
  width: 64rpx;
  height: 64rpx;
  border-radius: 9999rpx;
  background: $jp-muted;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
}
.step-btn-text {
  font-size: 36rpx;
  font-weight: 700;
  color: $jp-deep;
  line-height: 1;
}
.step-num {
  font-size: 28rpx;
  font-weight: 700;
  color: $jp-fg;
}

/* STEP2 封面预览（占位） */
.cover {
  border-radius: $jp-radius;
  padding: 40rpx 32rpx;
  background: $jp-gradient-lemon;
}
.cover-tag {
  font-size: 20rpx;
  letter-spacing: 3rpx;
  color: rgba(28, 25, 23, 0.6);
}
.cover-name {
  display: block;
  font-family: $jp-font-heading;
  font-size: 36rpx;
  font-weight: 700;
  color: $jp-fg;
  margin-top: 8rpx;
}
.cover-grid {
  display: flex;
  gap: 16rpx;
  margin-top: 28rpx;
}
.cover-cell {
  flex: 1;
  background: rgba(0, 0, 0, 0.08);
  border-radius: 16rpx;
  padding: 16rpx 12rpx;
  text-align: center;
}
.cover-cell-label {
  display: block;
  font-size: 20rpx;
  color: rgba(28, 25, 23, 0.6);
}
.cover-cell-value {
  display: block;
  font-size: 24rpx;
  font-weight: 700;
  color: $jp-fg;
  margin-top: 6rpx;
}

/* STEP2 单日操作区 */
.ghost-btn {
  margin-top: 28rpx;
  height: 84rpx;
  border: 2rpx dashed $jp-border;
  border-radius: $jp-radius-pill;
  background: $jp-card;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 10rpx;
  cursor: pointer;

  &--busy {
    opacity: 0.7;
  }
}
.ghost-btn-text {
  font-size: 27rpx;
  font-weight: 600;
  color: $jp-fg;
}

.days-head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-top: 36rpx;
  margin-bottom: 16rpx;
}
.days-title {
  font-family: $jp-font-heading;
  font-size: 30rpx;
  font-weight: 700;
  color: $jp-fg;
}
.days-progress {
  font-size: 23rpx;
  color: $jp-muted-fg;
}

.day-list {
  display: flex;
  flex-direction: column;
  gap: 16rpx;
}
.day-card {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 26rpx 28rpx;
  background: $jp-card;
  border: 2rpx solid $jp-border;
  border-radius: $jp-radius;
  cursor: pointer;

  &:hover {
    border-color: $jp-deep;
  }
}
.day-main {
  display: flex;
  flex-direction: column;
  flex: 1;
  min-width: 0;
}
.day-title {
  font-size: 28rpx;
  font-weight: 700;
  color: $jp-fg;
}
.day-sub {
  font-size: 22rpx;
  color: $jp-muted-fg;
  margin-top: 8rpx;
}
.day-badge {
  flex-shrink: 0;
  margin-left: 16rpx;
  font-size: 21rpx;
  font-weight: 600;
  padding: 6rpx 16rpx;
  border-radius: 9999rpx;
  background: transparent;
  border: 2rpx solid $jp-border;
  color: $jp-muted-fg;

  &--done {
    background: $jp-muted;
    border-color: $jp-muted;
    color: $jp-deep;
  }
}
.day-empty {
  padding: 40rpx;
  text-align: center;
}
.day-empty-text {
  font-size: 24rpx;
  color: $jp-muted-fg;
}

/* 底部按钮 */
.spacer {
  height: 48rpx;
}
.next-btn {
  height: 96rpx;
  background: $jp-gradient-lemon;
  border-radius: $jp-radius-pill;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8rpx;
  cursor: pointer;

  &:hover {
    opacity: 0.92;
  }
}
.next-text {
  font-size: 30rpx;
  font-weight: 700;
  color: $jp-fg;
}
.next-arrow {
  font-size: 34rpx;
  font-weight: 700;
  color: $jp-fg;
}
</style>
