<template>
  <view class="new-page">
    <!-- 头部：aurora 渐变 + 返回 + STEP 指示器（原型 STEP 1/3） -->
    <view class="head">
      <view class="head-top">
        <view class="back" @click="goBack" aria-label="返回">
          <image class="back-img" src="/static/icon-close.svg" mode="aspectFit" />
        </view>
        <view class="head-titles">
          <text class="step-hint">STEP 1 / 3</text>
          <text class="step-title">计划命名</text>
        </view>
      </view>

      <!-- 步骤点：1 高亮，2/3 未到（Step2/3 为后续变更） -->
      <view class="steps">
        <view class="step-dot step-dot--on">1</view>
        <view class="step-line"></view>
        <view class="step-dot">2</view>
        <view class="step-line"></view>
        <view class="step-dot">3</view>
      </view>
    </view>

    <!-- STEP 1：命名（FR-WZ-01） -->
    <view class="body">
      <view class="field">
        <text class="field-label">旅程名称</text>
        <input
          class="field-input"
          v-model="name"
          :value="name"
          maxlength="20"
          placeholder="例如：成都美食探访"
          placeholder-class="field-ph"
          @input="onInput"
          @confirm="submit"
        />
        <text class="field-tip">2-20 个字符，必填</text>
        <text v-if="error" class="field-error">{{ error }}</text>
      </view>

      <!-- 主按钮（task 3.1：提交命名创建草稿，返回列表刷新） -->
      <view class="foot">
        <view class="submit" @click="submit">
          <text class="submit-text">创建计划草稿</text>
          <image class="submit-arrow" src="/static/icon-arrow-right.svg" mode="aspectFit" />
        </view>
      </view>
    </view>
  </view>
</template>

<script setup>
// 新建计划 · Step1 命名（FR-WZ-01，task 3.1）
// 行为：提交 POST /plans（名称去首尾空格后 2-20 字符）创建草稿，返回列表并刷新。
// Step2（基本信息+AI推荐）/ Step3（每日计划）为后续变更，本页仅实现命名。
// 契约依据：changes/my-plans-page/specs/plan-api/spec.md（POST /plans → 201 草稿）
import { ref } from 'vue'
import { createPlan } from '@/api/plan.js'

const name = ref('')
const error = ref('')

function onInput(e) {
  name.value = e.detail ? e.detail.value : e.target.value
  if (error.value) error.value = ''
}

function goBack() {
  uni.navigateBack({
    fail() {
      uni.redirectTo({ url: '/pages/plans/plans' })
    }
  })
}

function submit() {
  const v = (name.value || '').trim()
  if (v.length < 2 || v.length > 20) {
    error.value = '请为计划起一个名字（2-20 字符）'
    return
  }
  createPlan({ name: v })
    .then(() => {
      uni.showToast({ title: '已创建草稿', icon: 'success' })
      // 返回列表并刷新（onShow 会重新 load）
      setTimeout(() => {
        uni.navigateBack({
          fail() {
            uni.redirectTo({ url: '/pages/plans/plans' })
          }
        })
      }, 600)
    })
    .catch(() => {
      uni.showToast({ title: '创建失败，请重试', icon: 'none' })
    })
}
</script>

<style lang="scss" scoped>
.new-page {
  min-height: 100vh;
  background: $jp-bg;
  box-sizing: border-box;
}

/* aurora 渐变头部（柠檬 → 青柠），其上文字一律深色（禁止黄底白字） */
.head {
  background: $jp-gradient-lemon;
  padding: 32rpx 32rpx 36rpx;
  border-bottom-left-radius: 32rpx;
  border-bottom-right-radius: 32rpx;
}
.head-top {
  display: flex;
  align-items: center;
  gap: 24rpx;
}
.back {
  width: 72rpx;
  height: 72rpx;
  border-radius: 9999rpx;
  background: rgba(0, 0, 0, 0.1);
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  flex-shrink: 0;
}
.back:hover {
  background: rgba(0, 0, 0, 0.18);
}
.back-img {
  width: 32rpx;
  height: 32rpx;
}
.head-titles {
  display: flex;
  flex-direction: column;
}
.step-hint {
  font-size: 22rpx;
  font-weight: 600;
  letter-spacing: 2rpx;
  color: $jp-fg;
  opacity: 0.6;
}
.step-title {
  font-family: $jp-font-heading;
  font-size: 44rpx;
  font-weight: 700;
  color: $jp-fg;
  margin-top: 4rpx;
}

/* 步骤点：1 高亮，2/3 未达 */
.steps {
  display: flex;
  align-items: center;
  margin-top: 28rpx;
}
.step-dot {
  width: 48rpx;
  height: 48rpx;
  border-radius: 9999rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 24rpx;
  font-weight: 700;
  background: rgba(0, 0, 0, 0.12);
  color: $jp-fg;
  flex-shrink: 0;
}
.step-dot--on {
  background: $jp-fg;
  color: $jp-primary;
}
.step-line {
  flex: 1;
  height: 4rpx;
  background: rgba(0, 0, 0, 0.12);
  margin: 0 16rpx;
}

/* 表单区 */
.body {
  padding: 40rpx 32rpx;
}
.field-label {
  display: block;
  font-size: 24rpx;
  font-weight: 600;
  color: $jp-muted-fg;
  margin-bottom: 12rpx;
}
.field-input {
  height: 96rpx;
  padding: 0 28rpx;
  box-sizing: border-box;
  background: $jp-card;
  border: 2rpx solid $jp-border;
  border-radius: $jp-radius-sm;
  font-size: 30rpx;
  color: $jp-fg;
}
.field-input:focus {
  border-color: $jp-primary;
}
.field-ph {
  color: $jp-muted-fg;
}
.field-tip {
  display: block;
  font-size: 22rpx;
  color: $jp-muted-fg;
  margin-top: 12rpx;
}
.field-error {
  display: block;
  font-size: 24rpx;
  color: $jp-danger;
  margin-top: 12rpx;
}

/* 主按钮（aurora 渐变 + 深色文字） */
.foot {
  margin-top: 56rpx;
}
.submit {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 12rpx;
  height: 96rpx;
  border-radius: $jp-radius;
  background: $jp-gradient-lemon;
  box-shadow: 0 8rpx 24rpx rgba(250, 204, 21, 0.35);
  cursor: pointer;
}
.submit:active {
  opacity: 0.88;
}
.submit-text {
  font-family: $jp-font-heading;
  font-size: 30rpx;
  font-weight: 700;
  color: $jp-fg;
}
.submit-arrow {
  width: 28rpx;
  height: 28rpx;
}
</style>
