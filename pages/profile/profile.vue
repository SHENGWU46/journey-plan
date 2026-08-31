<template>
  <view class="profile-page">
    <text class="title">个人中心</text>
    <text class="subtitle">头像、昵称、账号管理 · 功能建设中</text>
  </view>
</template>

<script setup>
// 个人中心占位页（Task 3.2）
// 完整用户信息/账号管理为后续变更（FR-US 模块）。
</script>

<style lang="scss" scoped>
.profile-page {
  min-height: 100vh;
  background: $jp-bg;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 0 60rpx;
  box-sizing: border-box;
}
.title {
  font-family: $jp-font-heading;
  font-size: 44rpx;
  font-weight: 700;
  color: $jp-fg;
}
.subtitle {
  font-size: 26rpx;
  color: $jp-muted-fg;
  margin-top: 16rpx;
  text-align: center;
}
</style>
