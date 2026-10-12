<template>
  <text class="badge" :class="'badge--' + status">{{ label }}</text>
</template>

<script setup>
// 状态标签（原型 §我的计划 v5）：草稿 / 即将出发 / 进行中 / 已完成
// 颜色按产品决策映射：草稿=天蓝、即将出发=亮柠檬、进行中=青柠、已完成=深柠檬
import { computed } from 'vue'

const props = defineProps({
  status: { type: String, required: true } // draft | upcoming | ongoing | completed
})

const map = {
  draft: '草稿',
  upcoming: '即将出发',
  ongoing: '进行中',
  completed: '已完成'
}
const label = computed(() => map[props.status] || '草稿')
</script>

<style lang="scss" scoped>
.badge {
  display: inline-block;
  font-size: 22rpx;
  font-weight: 700;
  padding: 6rpx 18rpx;
  border-radius: $jp-radius-pill;
  flex-shrink: 0;

  &--draft {
    color: $jp-deep3;
    background: rgba(56, 189, 248, 0.12);
  }
  &--upcoming {
    color: $jp-deep;
    background: rgba(250, 204, 21, 0.16);
  }
  &--ongoing {
    color: $jp-deep2;
    background: rgba(132, 204, 22, 0.14);
  }
  &--completed {
    color: $jp-deep;
    background: rgba(161, 98, 7, 0.12);
  }
}
</style>
