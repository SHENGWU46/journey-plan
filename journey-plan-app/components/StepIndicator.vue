<template>
  <view class="steps">
    <template v-for="(s, i) in steps" :key="i">
      <view class="dot" :class="stateOf(i)">{{ i + 1 }}</view>
      <view v-if="i < steps.length - 1" class="line" :class="{ 'line--on': i < current }"></view>
    </template>
  </view>
</template>

<script setup>
// 步骤条（原型 §制定计划 Step1-3）：current 表示已完成/进行到的步骤序号（0-based）。
import { computed } from 'vue'

const props = defineProps({
  current: { type: Number, default: 0 }, // 当前所在步（0-based）
  total: { type: Number, default: 3 }
})

const steps = computed(() => Array.from({ length: props.total }))

function stateOf(i) {
  if (i < props.current) return 'dot--done'
  if (i === props.current) return 'dot--on'
  return ''
}
</script>

<style lang="scss" scoped>
.steps {
  display: flex;
  align-items: center;
}
.dot {
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

  &--on {
    background: $jp-fg;
    color: $jp-primary;
  }
  &--done {
    background: $jp-primary;
    color: $jp-fg;
  }
}
.line {
  flex: 1;
  height: 4rpx;
  background: rgba(0, 0, 0, 0.12);
  margin: 0 16rpx;

  &--on {
    background: $jp-primary;
  }
}
</style>
