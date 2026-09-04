<template>
  <view class="new-page">
    <!-- 头部 -->
    <view class="head">
      <view class="back" @click="onBack">
        <view class="arrow-h"></view>
        <view class="arrow-v"></view>
      </view>
      <text class="head-title">{{ stepTitle }}</text>
    </view>

    <!-- 步骤条 -->
    <StepIndicator :current="step" :total="3" />

    <!-- Step 1：命名 -->
    <view v-if="step === 0" class="step">
      <text class="step-label">给这段旅程起个名字</text>
      <input
        class="name-input"
        v-model="form.name"
        :value="form.name"
        maxlength="20"
        placeholder="如：国庆日本关西 7 日游"
        placeholder-class="ph"
        @input="nameError = ''"
      />
      <text v-if="nameError" class="err">{{ nameError }}</text>
      <view class="spacer"></view>
      <view class="next-btn" @click="nextFromName">
        <text class="next-text">下一步</text>
      </view>
    </view>

    <!-- Step 2：基本信息 + AI 推荐 -->
    <view v-else-if="step === 1" class="step">
      <text class="step-label">填写基本信息</text>

      <view class="field">
        <text class="field-label">目的地</text>
        <input class="field-input" v-model="form.destination" :value="form.destination" maxlength="40" placeholder="如：大阪、京都" placeholder-class="ph" />
      </view>
      <view class="field-row">
        <view class="field field--half">
          <text class="field-label">出发日期</text>
          <picker mode="date" :value="form.depart_date" @change="onDepart">
            <view class="picker" :class="{ 'picker--empty': !form.depart_date }">
              {{ form.depart_date || '选择日期' }}
            </view>
          </picker>
        </view>
        <view class="field field--half">
          <text class="field-label">返回日期</text>
          <picker mode="date" :value="form.return_date" @change="onReturn">
            <view class="picker" :class="{ 'picker--empty': !form.return_date }">
              {{ form.return_date || '选择日期' }}
            </view>
          </picker>
        </view>
      </view>
      <view class="field-row">
        <view class="field field--half">
          <text class="field-label">出行人数</text>
          <input class="field-input" v-model="form.people_count" :value="form.people_count" type="number" maxlength="3" placeholder="如：2" placeholder-class="ph" />
        </view>
        <view class="field field--half">
          <text class="field-label">总预算（元）</text>
          <input class="field-input" v-model="form.total_budget" :value="form.total_budget" type="number" maxlength="9" placeholder="如：15000" placeholder-class="ph" />
        </view>
      </view>

      <!-- 天数（自动算） -->
      <text class="days-hint" v-if="form.total_days">共 {{ form.total_days }} 天</text>

      <!-- AI 推荐 -->
      <view class="ai-section">
        <view class="ai-head">
          <view class="ai-dot"></view>
          <text class="ai-title">智能推荐景点</text>
          <text class="ai-sub">勾选你想去的，避开不感兴趣的</text>
        </view>

        <view v-if="!aiLoaded" class="ai-loading">
          <text class="ai-loading-text">{{ aiLoading ? '正在生成推荐…' : '点击下方按钮生成推荐' }}</text>
          <view class="ai-gen-btn" @click="genRecommend">
            <text class="ai-gen-text">{{ aiLoading ? '生成中…' : '生成推荐' }}</text>
          </view>
        </view>

        <view v-else class="rec-list">
          <view
            v-for="spot in recommendations"
            :key="spot.id"
            class="rec-card"
            :class="{ 'rec-card--confirm': spot.confirm, 'rec-card--avoid': spot.avoid }"
            @click="toggleSpot(spot)"
          >
            <view class="rec-icon">
              <image class="rec-icon-img" :src="spot.confirm ? '/static/icon-check.svg' : (spot.avoid ? '/static/icon-close.svg' : '/static/icon-plus.svg')" mode="aspectFit" />
            </view>
            <view class="rec-main">
              <text class="rec-name">{{ spot.name }}</text>
              <text class="rec-desc">{{ spot.desc }}</text>
            </view>
            <text class="rec-tag" v-if="spot.confirm">已选</text>
            <text class="rec-tag rec-tag--avoid" v-else-if="spot.avoid">避开</text>
          </view>
        </view>
      </view>

      <view class="spacer"></view>
      <view class="next-btn" @click="nextFromInfo">
        <text class="next-text">下一步</text>
      </view>
    </view>

    <!-- Step 3：每日计划 -->
    <view v-else class="step">
      <text class="step-label">每日计划</text>

      <view v-if="!daysGenerated" class="ai-loading">
        <text class="ai-loading-text">根据信息与推荐生成每日行程</text>
        <view class="ai-gen-btn" @click="genDays">
          <text class="ai-gen-text">{{ daysLoading ? '生成中…' : '生成每日计划' }}</text>
        </view>
      </view>

      <view v-else class="days">
        <view v-for="(d, i) in days" :key="i" class="day-card">
          <view class="day-head">
            <text class="day-title">第 {{ i + 1 }} 天</text>
            <text class="day-date">{{ d.date }}</text>
          </view>

          <view class="day-row">
            <text class="day-row-label">天气</text>
            <input class="day-row-input" v-model="d.weather" :value="d.weather" maxlength="20" placeholder="如：晴 22°C" placeholder-class="ph" />
          </view>
          <view class="day-row">
            <text class="day-row-label">预算</text>
            <input class="day-row-input" v-model="d.budget" :value="d.budget" type="number" maxlength="8" placeholder="元" placeholder-class="ph" />
          </view>
          <view class="day-row">
            <text class="day-row-label">时间</text>
            <input class="day-row-input" v-model="d.time" :value="d.time" maxlength="30" placeholder="如：09:00-18:00" placeholder-class="ph" />
          </view>

          <view class="route">
            <text class="route-title">路线安排</text>
            <view v-for="(r, ri) in d.routes" :key="ri" class="route-item">
              <text class="route-index">{{ ri + 1 }}</text>
              <text class="route-name">{{ r.name }}</text>
            </view>
          </view>
        </view>

        <view class="regen" @click="genDays">
          <text class="regen-text">重新生成（保留已选路线）</text>
        </view>
      </view>

      <view class="spacer"></view>
      <view class="next-btn" @click="finish">
        <text class="next-text">完成</text>
      </view>
      <text class="skip" @click="finish">跳过，稍后再完善</text>
    </view>
  </view>
</template>

<script setup>
// 制定计划 3 步流程（原型 §制定计划 Step1-3）：命名 → 基本信息+AI推荐 → 每日计划。
// 数据流：Step1 真实创建草稿拿 planId；Step2/3 字段暂存，完成时通过预留 updatePlan 提交
// （后端多字段更新接口见 api/plan.js 中 TODO(backend)）。AI 推荐/每日生成本地 mock。
import { ref, reactive, computed, onLoad } from 'vue'
import StepIndicator from '@/components/StepIndicator.vue'
import { createPlan, updatePlan, getPlan, generateDailyPlans } from '@/api/plan.js'

const step = ref(0)
const planId = ref(null)
const nameError = ref('')

const form = reactive({
  name: '',
  destination: '',
  depart_date: '',
  return_date: '',
  people_count: '',
  total_budget: ''
})

const stepTitle = computed(() => ['第 1 步 · 命名', '第 2 步 · 信息', '第 3 步 · 每日计划'][step.value])

// 天数自动计算
const totalDays = computed(() => {
  if (!form.depart_date || !form.return_date) return 0
  const a = new Date(form.depart_date)
  const b = new Date(form.return_date)
  if (isNaN(a) || isNaN(b) || b < a) return 0
  return Math.round((b - a) / 86400000) + 1
})
const formWithDays = computed(() => ({
  ...form,
  total_days: totalDays.value ? totalDays.value : null,
  people_count: form.people_count ? Number(form.people_count) : null,
  total_budget: form.total_budget ? Number(form.total_budget) : null
}))

// AI 推荐
const aiLoaded = ref(false)
const aiLoading = ref(false)
const recommendations = ref([])

// 每日计划
const daysGenerated = ref(false)
const daysLoading = ref(false)
const days = ref([])
const selectedRoutes = ref([]) // 重新生成时保留

onLoad((opts) => {
  if (opts && opts.id) {
    // 继续编辑草稿：回填（后端 getPlan 待实现，先本地无回填）
    planId.value = Number(opts.id)
  }
})

function onDepart(e) { form.depart_date = e.detail.value }
function onReturn(e) { form.return_date = e.detail.value }

async function nextFromName() {
  const v = form.name.trim()
  if (v.length < 2 || v.length > 20) {
    nameError.value = '名称需 2-20 个字符'
    return
  }
  try {
    if (planId.value == null) {
      const created = await createPlan({ name: v })
      planId.value = created.id
    }
    step.value = 1
  } catch (err) {
    nameError.value = (err && err.message) || '创建失败'
  }
}

function toggleSpot(spot) {
  if (spot.confirm) { spot.confirm = false; spot.avoid = true }
  else if (spot.avoid) { spot.avoid = false }
  else { spot.confirm = true }
}

async function genRecommend() {
  if (aiLoading.value) return
  aiLoading.value = true
  // TODO(backend): 真实调用 AI 推荐服务；此处本地 mock
  await new Promise(r => setTimeout(r, 700))
  const mock = [
    { id: 1, name: '大阪城公园', desc: '历史悠久的天守阁与樱花名所', confirm: false, avoid: false },
    { id: 2, name: '道顿堀', desc: '美食与霓虹交织的繁华商圈', confirm: false, avoid: false },
    { id: 3, name: '清水寺', desc: '京都地标，俯瞰京都全景', confirm: false, avoid: false },
    { id: 4, name: '伏见稻荷大社', desc: '千本鸟居的红色长廊', confirm: false, avoid: false },
    { id: 5, name: '环球影城', desc: '哈利波特与任天堂园区', confirm: false, avoid: false }
  ]
  recommendations.value = mock
  aiLoading.value = false
  aiLoaded.value = true
}

async function nextFromInfo() {
  // 提交基本信息（后端多字段更新待实现，前端先提交 name 保证草稿可用）
  try {
    if (planId.value != null) {
      // 仅 name 可真实提交；其余字段预留 updatePlan
      await updatePlan(planId.value, formWithDays.value).catch(() => {})
    }
  } catch (e) { /* 后端未实现多字段更新时忽略，不阻塞流程 */ }
  step.value = 2
}

async function genDays() {
  if (daysLoading.value) return
  daysLoading.value = true
  await new Promise(r => setTimeout(r, 800))
  const n = totalDays.value || 3
  const base = form.depart_date ? new Date(form.depart_date) : new Date()
  const newDays = []
  for (let i = 0; i < n; i++) {
    const dt = new Date(base)
    dt.setDate(base.getDate() + i)
    const dateStr = `${dt.getFullYear()}-${String(dt.getMonth() + 1).padStart(2, '0')}-${String(dt.getDate()).padStart(2, '0')}`
    const keep = selectedRoutes.value[i] || []
    newDays.push({
      date: dateStr,
      weather: '晴 22°C',
      budget: '',
      time: '09:00-18:00',
      routes: keep.length ? keep : [{ name: form.destination || '自由活动' }]
    })
  }
  days.value = newDays
  daysLoading.value = false
  daysGenerated.value = true
}

async function finish() {
  // 标记完成（后端多字段/完成态更新待实现，前端调用预留接口）
  try {
    if (planId.value != null) {
      await updatePlan(planId.value, { ...formWithDays.value, completed: true }).catch(() => {})
    }
  } catch (e) { /* ignore */ }
  uni.showToast({ title: '计划已创建', icon: 'success' })
  setTimeout(() => uni.reLaunch({ url: '/pages/plans/plans' }), 400)
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
  min-height: 100vh;
  background: $jp-bg;
  padding: 32rpx;
  box-sizing: border-box;
}

.head {
  display: flex;
  align-items: center;
  margin-bottom: 28rpx;
}
.back {
  position: relative;
  width: 48rpx;
  height: 48rpx;
  margin-right: 16rpx;
  cursor: pointer;
}
.arrow-h {
  position: absolute;
  top: 22rpx;
  left: 10rpx;
  width: 22rpx;
  height: 3rpx;
  background: $jp-fg;
  border-radius: 2rpx;
  transform: rotate(45deg);
}
.arrow-v {
  position: absolute;
  top: 8rpx;
  left: 10rpx;
  width: 3rpx;
  height: 22rpx;
  background: $jp-fg;
  border-radius: 2rpx;
  transform: rotate(45deg);
}
.head-title {
  font-family: $jp-font-heading;
  font-size: 36rpx;
  font-weight: 700;
  color: $jp-fg;
}

.step {
  margin-top: 32rpx;
}
.step-label {
  display: block;
  font-size: 30rpx;
  font-weight: 700;
  color: $jp-fg;
  margin-bottom: 24rpx;
}

.name-input {
  height: 96rpx;
  padding: 0 24rpx;
  background: $jp-card;
  border: 2rpx solid $jp-border;
  border-radius: $jp-radius-sm;
  font-size: 30rpx;
  color: $jp-fg;
}
.ph {
  color: $jp-muted-fg;
}
.err {
  display: block;
  font-size: 24rpx;
  color: $jp-danger;
  margin-top: 12rpx;
}

.field {
  margin-bottom: 24rpx;
}
.field-row {
  display: flex;
  gap: 20rpx;
}
.field--half {
  flex: 1;
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
  background: $jp-card;
  border: 2rpx solid $jp-border;
  border-radius: $jp-radius-sm;
  font-size: 28rpx;
  color: $jp-fg;
}
.picker {
  height: 88rpx;
  padding: 0 24rpx;
  display: flex;
  align-items: center;
  background: $jp-card;
  border: 2rpx solid $jp-border;
  border-radius: $jp-radius-sm;
  font-size: 28rpx;
  color: $jp-fg;

  &--empty {
    color: $jp-muted-fg;
  }
}
.days-hint {
  display: block;
  font-size: 24rpx;
  color: $jp-deep;
  margin: 4rpx 0 8rpx;
}

/* AI 推荐 */
.ai-section {
  margin-top: 32rpx;
}
.ai-head {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  margin-bottom: 20rpx;
}
.ai-dot {
  width: 16rpx;
  height: 16rpx;
  border-radius: 9999rpx;
  background: $jp-primary;
  margin-right: 12rpx;
}
.ai-title {
  font-size: 28rpx;
  font-weight: 700;
  color: $jp-fg;
  margin-right: 12rpx;
}
.ai-sub {
  font-size: 22rpx;
  color: $jp-muted-fg;
}
.ai-loading {
  text-align: center;
  padding: 40rpx 0;
}
.ai-loading-text {
  display: block;
  font-size: 26rpx;
  color: $jp-muted-fg;
  margin-bottom: 24rpx;
}
.ai-gen-btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  padding: 18rpx 48rpx;
  background: $jp-gradient-lemon;
  border-radius: $jp-radius-pill;
  cursor: pointer;
}
.ai-gen-text {
  font-size: 28rpx;
  font-weight: 700;
  color: $jp-fg;
}

.rec-list {
  display: flex;
  flex-direction: column;
  gap: 16rpx;
}
.rec-card {
  display: flex;
  align-items: center;
  padding: 20rpx 24rpx;
  background: $jp-card;
  border: 2rpx solid $jp-border;
  border-radius: $jp-radius-sm;
  cursor: pointer;

  &--confirm {
    border-color: $jp-primary;
    background: rgba(250, 204, 21, 0.08);
  }
  &--avoid {
    opacity: 0.5;
  }
}
.rec-icon {
  width: 56rpx;
  height: 56rpx;
  border-radius: 16rpx;
  background: $jp-muted;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-right: 20rpx;
  flex-shrink: 0;
}
.rec-icon-img {
  width: 30rpx;
  height: 30rpx;
}
.rec-main {
  flex: 1;
  min-width: 0;
}
.rec-name {
  display: block;
  font-size: 28rpx;
  font-weight: 700;
  color: $jp-fg;
}
.rec-desc {
  display: block;
  font-size: 22rpx;
  color: $jp-muted-fg;
  margin-top: 4rpx;
}
.rec-tag {
  font-size: 22rpx;
  font-weight: 700;
  color: $jp-deep;
  margin-left: 12rpx;

  &--avoid {
    color: $jp-danger;
  }
}

/* 每日计划 */
.days {
  display: flex;
  flex-direction: column;
  gap: 20rpx;
}
.day-card {
  padding: 24rpx;
  background: $jp-card;
  border: 2rpx solid $jp-border;
  border-radius: $jp-radius;
}
.day-head {
  display: flex;
  align-items: baseline;
  justify-content: space-between;
  margin-bottom: 20rpx;
}
.day-title {
  font-size: 30rpx;
  font-weight: 700;
  color: $jp-fg;
}
.day-date {
  font-size: 24rpx;
  color: $jp-muted-fg;
}
.day-row {
  display: flex;
  align-items: center;
  padding: 12rpx 0;
}
.day-row-label {
  width: 80rpx;
  font-size: 24rpx;
  color: $jp-muted-fg;
  flex-shrink: 0;
}
.day-row-input {
  flex: 1;
  height: 72rpx;
  padding: 0 20rpx;
  background: $jp-bg;
  border: 2rpx solid $jp-border;
  border-radius: $jp-radius-sm;
  font-size: 26rpx;
  color: $jp-fg;
}
.route {
  margin-top: 16rpx;
  border-top: 2rpx solid $jp-border;
  padding-top: 16rpx;
}
.route-title {
  display: block;
  font-size: 24rpx;
  font-weight: 700;
  color: $jp-fg;
  margin-bottom: 12rpx;
}
.route-item {
  display: flex;
  align-items: center;
  padding: 10rpx 0;
}
.route-index {
  width: 36rpx;
  height: 36rpx;
  border-radius: 9999rpx;
  background: $jp-muted;
  color: $jp-deep;
  font-size: 22rpx;
  font-weight: 700;
  text-align: center;
  line-height: 36rpx;
  margin-right: 16rpx;
  flex-shrink: 0;
}
.route-name {
  font-size: 26rpx;
  color: $jp-fg;
}
.regen {
  text-align: center;
  padding: 24rpx 0;
  cursor: pointer;
}
.regen-text {
  font-size: 26rpx;
  font-weight: 600;
  color: $jp-deep;
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
.skip {
  display: block;
  text-align: center;
  font-size: 24rpx;
  color: $jp-muted-fg;
  margin-top: 20rpx;
  cursor: pointer;
}
</style>
