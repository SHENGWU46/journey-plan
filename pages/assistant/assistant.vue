<template>
  <view class="assistant-page">
    <text class="title">旅行助手</text>
    <text class="subtitle">AI 问答与行程建议 · 功能建设中</text>
  </view>
</template>

<script setup>
// 旅行助手占位页（Task 3.2）
// 完整 AI 问答能力为后续变更（FR-AS 模块）。
</script>

<style lang="scss" scoped>
.assistant-page {
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
