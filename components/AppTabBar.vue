<template>
  <view class="tabbar">
    <view
      v-for="t in tabs"
      :key="t.key"
      class="tab"
      :class="{ 'tab--on': current === t.key }"
      @click="go(t)"
    >
      <view class="tab-icon-wrap" :class="{ 'tab-icon-wrap--on': current === t.key }">
        <image class="tab-icon" :src="t.icon" mode="aspectFit" />
      </view>
      <text class="tab-text">{{ t.text }}</text>
    </view>
  </view>
</template>

<script setup>
// 自定义底部导航（原型决策：选中时图标背景变柠檬黄，文字颜色保持不变）。
// 全项目导航统一用 reLaunch，故此处点击也用 reLaunch 切换，避免依赖原生 tabBar。
import { ref } from 'vue'

const props = defineProps({
  current: { type: String, required: true }
})

const tabs = [
  { key: 'plans', text: '我的计划', icon: '/static/tab-plans.png', url: '/pages/plans/plans' },
  { key: 'assistant', text: '旅行助手', icon: '/static/tab-assistant.png', url: '/pages/assistant/assistant' },
  { key: 'profile', text: '个人中心', icon: '/static/tab-profile.png', url: '/pages/profile/profile' }
]

function go(t) {
  if (t.key === props.current) return
  uni.reLaunch({ url: t.url })
}
</script>

<style lang="scss" scoped>
.tabbar {
  position: fixed;
  left: 0;
  right: 0;
  bottom: 0;
  z-index: 60;
  height: calc(110rpx + env(safe-area-inset-bottom));
  padding-bottom: env(safe-area-inset-bottom);
  display: flex;
  align-items: center;
  box-sizing: border-box;
  background: #FFFFFF;
  border-top: 2rpx solid #FEF3C7;
}

.tab {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 8rpx;
  cursor: pointer;
  -webkit-tap-highlight-color: transparent;
}

.tab-icon-wrap {
  width: 64rpx;
  height: 64rpx;
  border-radius: 20rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  background: transparent;
  transition: background 0.18s ease;

  &--on {
    background: #FACC15;
  }
}

.tab-icon {
  width: 44rpx;
  height: 44rpx;
}

.tab-text {
  font-size: 22rpx;
  font-weight: 600;
  // 文字颜色固定，选中不变化
  color: #78716C;
}
</style>
