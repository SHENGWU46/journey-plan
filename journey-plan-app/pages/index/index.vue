<template>
  <view class="launch">
    <view class="logo-wrap">
      <view class="logo-fallback">JP</view>
    </view>
    <text class="brand">Journey Plan</text>
    <text class="slogan">规划你的下一段旅程</text>

    <!-- 加载动画（三点脉冲） -->
    <view class="loader">
      <view class="dot"></view>
      <view class="dot"></view>
      <view class="dot"></view>
    </view>
  </view>
</template>

<script setup>
// 启动页（原型 §启动页）：logo + 标题 + slogan + 加载动画，2.5s 后按登录态跳转。
import { onLoad } from '@dcloudio/uni-app'
import { isLoggedIn } from '@/utils/token.js'

onLoad(() => {
  setTimeout(() => {
    const target = isLoggedIn() ? '/pages/plans/plans' : '/pages/login/login'
    uni.reLaunch({ url: target })
  }, 2500)
})
</script>

<style lang="scss" scoped>
.launch {
  min-height: 100vh;
  background: $jp-bg;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  box-sizing: border-box;
}
.logo-wrap {
  width: 160rpx;
  height: 160rpx;
  border-radius: 40rpx;
  background: $jp-gradient-lemon;
  display: flex;
  align-items: center;
  justify-content: center;
}
.logo-fallback {
  font-family: $jp-font-heading;
  font-size: 64rpx;
  font-weight: 700;
  color: $jp-fg;
}
.brand {
  font-family: $jp-font-heading;
  font-size: 48rpx;
  font-weight: 700;
  color: $jp-fg;
  margin-top: 36rpx;
}
.slogan {
  font-size: 26rpx;
  color: $jp-muted-fg;
  margin-top: 12rpx;
}

/* 三点脉冲加载 */
.loader {
  display: flex;
  gap: 14rpx;
  margin-top: 60rpx;
}
.dot {
  width: 16rpx;
  height: 16rpx;
  border-radius: 9999rpx;
  background: $jp-primary;
  animation: pulse 1.2s infinite ease-in-out;
}
.dot:nth-child(2) {
  animation-delay: 0.2s;
}
.dot:nth-child(3) {
  animation-delay: 0.4s;
}
@keyframes pulse {
  0%, 80%, 100% {
    opacity: 0.3;
    transform: scale(0.8);
  }
  40% {
    opacity: 1;
    transform: scale(1);
  }
}
</style>
