<template>
  <view class="card" :class="{ 'card--draft': !plan.completed }" @click="$emit('open', plan)">
    <!-- 草稿：图标头 + 名称 + 草稿标签 -->
    <view v-if="!plan.completed" class="draft-head">
      <view class="draft-icon">
        <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#A16207" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 20h9M16.5 3.5a2.1 2.1 0 013 3L7 19l-4 1 1-4 12.5-12.5z"/></svg>
      </view>
      <view class="draft-main">
        <view class="draft-title-row">
          <text class="name">{{ plan.name }}</text>
          <StatusBadge status="draft" />
        </view>
        <text class="tip">已完成命名与基本信息，可继续生成每日计划</text>
      </view>
    </view>

    <!-- 非草稿：aurora 渐变封面 -->
    <view v-else class="cover">
      <text class="cover-date">{{ dateRange }}</text>
    </view>

    <!-- 卡片主体 -->
    <view class="body">
      <text v-if="plan.completed" class="name">{{ plan.name }}</text>
      <text class="meta">{{ metaText }}</text>

      <!-- 进度（仅非草稿显示；generated_days 后端当前恒 0） -->
      <view v-if="plan.completed" class="progress">
        <view class="progress-bar" :style="{ width: progress + '%' }"></view>
      </view>
      <text v-if="plan.completed" class="progress-text">
        每日计划已生成 {{ plan.generated_days || 0 }} / {{ plan.total_days || 0 }}
      </text>

      <!-- 操作 -->
      <view class="ops" @click.stop>
        <view v-if="!plan.completed" class="op" @click="$emit('continue', plan)">
          <text class="op-text">继续编辑</text>
        </view>
        <view class="op" @click="$emit('rename', plan)">
          <text class="op-text">重命名</text>
        </view>
        <view class="op op--danger" @click="$emit('delete', plan)">
          <text class="op-text op-text--danger">删除</text>
        </view>
      </view>
    </view>
  </view>
</template>

<script setup>
// 计划卡片（原型 §我的计划）：仅区分草稿 / 非草稿两态。
// 草稿 = !completed（图标头 + 草稿标签）；非草稿 = completed（aurora 渐变封面 + 进度）。
import { computed } from 'vue'
import StatusBadge from './StatusBadge.vue'

const props = defineProps({
  plan: { type: Object, required: true }
})
defineEmits(['open', 'continue', 'rename', 'delete'])

const dateRange = computed(() => {
  const p = props.plan
  const f = (d) => (d ? d.slice(5).replace('-', '.') : '')
  const s = f(p.depart_date)
  const e = f(p.return_date)
  return s && e ? `${s} – ${e}` : '待完善日期'
})

const metaText = computed(() => {
  const p = props.plan
  const parts = []
  if (p.destination) parts.push(p.destination)
  if (p.total_days != null) parts.push(p.total_days + ' 天')
  if (p.people_count != null) parts.push(p.people_count + ' 人')
  if (p.completed && p.total_budget) parts.push('¥' + Number(p.total_budget).toLocaleString('zh-CN'))
  return parts.length ? parts.join(' · ') : '待完善'
})

const progress = computed(() => {
  const p = props.plan
  const total = p.total_days || 0
  const gen = p.generated_days || 0
  return total ? Math.round((gen / total) * 100) : 0
})
</script>

<style lang="scss" scoped>
.card {
  background: $jp-card;
  border: 2rpx solid $jp-border;
  border-radius: $jp-radius;
  overflow: hidden;
  margin-bottom: 24rpx;
  cursor: pointer;

  &--draft {
    border-style: dashed;
  }
}

/* 草稿头 */
.draft-head {
  display: flex;
  align-items: flex-start;
  padding: 24rpx;
}
.draft-icon {
  width: 72rpx;
  height: 72rpx;
  border-radius: 20rpx;
  background: $jp-muted;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-right: 20rpx;
  flex-shrink: 0;
}
.draft-main {
  flex: 1;
  min-width: 0;
}
.draft-title-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
}
.tip {
  display: block;
  font-size: 24rpx;
  color: $jp-muted-fg;
  margin-top: 12rpx;
}

/* 渐变封面（aurora 柠檬→青柠→天蓝，文字一律深色） */
.cover {
  height: 168rpx;
  padding: 20rpx 24rpx;
  box-sizing: border-box;
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  justify-content: flex-end;
  background: $jp-gradient-lemon;
}
.cover-date {
  display: inline-block;
  font-size: 24rpx;
  font-weight: 700;
  color: $jp-fg;
  background: rgba(0, 0, 0, 0.1);
  border-radius: $jp-radius-pill;
  padding: 6rpx 20rpx;
}

/* 主体 */
.body {
  padding: 24rpx;
}
.name {
  display: block;
  font-family: $jp-font-heading;
  font-size: 32rpx;
  font-weight: 700;
  color: $jp-fg;
}
.meta {
  display: block;
  font-size: 24rpx;
  color: $jp-muted-fg;
  margin-top: 8rpx;
}

.progress {
  height: 12rpx;
  background: $jp-muted;
  border-radius: $jp-radius-pill;
  overflow: hidden;
  margin-top: 20rpx;
}
.progress-bar {
  height: 100%;
  background: $jp-gradient-progress;
  border-radius: $jp-radius-pill;
  transition: width 0.3s ease;
}
.progress-text {
  display: block;
  font-size: 22rpx;
  color: $jp-muted-fg;
  margin-top: 10rpx;
}

/* 操作 */
.ops {
  display: flex;
  margin-top: 24rpx;
}
.op {
  flex: 1;
  text-align: center;
  border: 2rpx solid $jp-border;
  border-radius: $jp-radius-sm;
  padding: 16rpx 0;
  cursor: pointer;

  & + .op {
    margin-left: 16rpx;
  }
  &:hover {
    border-color: $jp-primary;
  }
}
.op-text {
  font-size: 24rpx;
  font-weight: 600;
  color: $jp-deep;
}
.op:hover .op-text {
  color: $jp-deep;
}
.op--danger:hover {
  border-color: $jp-danger;
}
.op-text--danger {
  color: $jp-danger;
}
</style>
