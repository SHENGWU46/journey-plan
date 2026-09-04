<template>
  <view class="assistant-page">
    <!-- 页面背景：顶部黄色 → 渐变浅灰白 → 白（原型 page-bg） -->
    <view class="page-bg"></view>

    <!-- 内容区（原型：relative / flex column） -->
    <view class="content">
      <!-- 头部：位于黄色部分，深色文字（原型 page-header） -->
      <view class="page-header">
        <h1 class="head-title">旅行助手</h1>
        <p class="head-desc">结合你的旅行计划给出针对性建议，也可以回答日常旅游问题。</p>
      </view>

      <!-- 白色内容卡片（原型 page-sheet） -->
      <view class="page-sheet">
        <!-- 消息区：flex:1 内部滚动（原型 ai-chat） -->
        <scroll-view
          ref="chatRef"
          class="ai-chat"
          scroll-y
          :scroll-top="scrollTop"
          :scroll-with-animation="true"
          :show-scrollbar="false"
        >
          <view
            v-for="(m, i) in messages"
            :key="i"
            class="msg"
            :class="m.role === 'user' ? 'msg--user' : 'msg--ai'"
          >
            <template v-if="m.role === 'ai'">
              <view class="msg-avatar">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#1C1917" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 3l1.9 5.1L19 10l-5.1 1.9L12 17l-1.9-5.1L5 10l5.1-1.9L12 3z"/><path d="M19 15l.9 2.1L22 18l-2.1.9L19 21l-.9-2.1L16 18l2.1-.9L19 15z"/></svg>
              </view>
              <view class="bubble bubble--ai">
                <text class="bubble-text">{{ m.text }}</text>
              </view>
            </template>
            <view v-else class="bubble bubble--user">
              <text class="bubble-text">{{ m.text }}</text>
            </view>
          </view>

          <view v-if="thinking" class="msg msg--ai">
            <view class="msg-avatar">
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#1C1917" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 3l1.9 5.1L19 10l-5.1 1.9L12 17l-1.9-5.1L5 10l5.1-1.9L12 3z"/><path d="M19 15l.9 2.1L22 18l-2.1.9L19 21l-.9-2.1L16 18l2.1-.9L19 15z"/></svg>
            </view>
            <view class="bubble bubble--ai">
              <view class="typing"><view class="dot"></view><view class="dot"></view><view class="dot"></view></view>
            </view>
          </view>
        </scroll-view>

        <!-- 输入区（原型：sheet 底部，sheet-fade 遮罩） -->
        <view class="input-area">
          <view class="input-bar">
            <input
              class="input"
              v-model="draft"
              :value="draft"
              maxlength="200"
              placeholder="问旅行助手任何问题…"
              placeholder-class="input-ph"
              @confirm="send"
            />
            <view class="send-btn" :class="{ 'send-btn--on': draft.trim() }" @click="send">
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#1C1917" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M22 2L11 13M22 2l-7 20-4-9-9-4 20-7z"/></svg>
            </view>
          </view>
          <p class="disclaimer">AI 生成内容仅供参考，出行前请以官方信息为准</p>
        </view>
      </view>
    </view>

    <app-tab-bar current="assistant" />
  </view>
</template>

<script setup>
// 旅行助手（严格参照 docs/journey-plan-prototype.html §PAGE 3 旅行助手）。
// AI 回答走 askAssistant（后端接口 TODO(backend)）；失败时本地 mock 回复，保证前端可交互。
import { ref, nextTick, onMounted } from 'vue'
import { askAssistant } from '@/api/assistant.js'
import AppTabBar from '@/components/AppTabBar.vue'

const messages = ref([])
const draft = ref('')
const thinking = ref(false)
const scrollTop = ref(0)
const chatRef = ref(null)

function append(role, text) {
  messages.value.push({ role, text })
  nextTick(() => {
    const el = chatRef.value
    if (el) {
      scrollTop.value = 0
      nextTick(() => {
        scrollTop.value = el.scrollHeight + 9999
      })
    }
  })
}

async function send() {
  const text = draft.value.trim()
  if (!text || thinking.value) return
  draft.value = ''
  append('user', text)
  await reply(text)
}

async function reply(text) {
  thinking.value = true
  try {
    // 取历史消息（不含本轮用户提问）作为上下文传给后端智能体
    const history = messages.value
      .slice(0, -1)
      .map((m) => ({ role: m.role, text: m.text }))
    const res = await askAssistant(text, history)
    append('ai', res.reply || mockReply(text))
  } catch (e) {
    append('ai', mockReply(text))
  } finally {
    thinking.value = false
  }
}

function mockReply(text) {
  if (text.includes('天气')) {
    return '10 月是京都的秋天，白天约 20–25°C，早晚偏凉，建议薄外套 + 舒适步行鞋。遇降雨可换室内方案：京都国立博物馆、锦市场、高岛屋，或雨中漫步伏见稻荷。'
  }
  if (text.includes('预算') || text.includes('分配')) {
    return '建议预算分配：住宿 35%、餐饮 25%、交通 15%、景点门票 10%、购物与机动 15%。若有温泉或米其林安排，提前 3 天确认并预留浮动额度。'
  }
  if (text.includes('生成') || text.includes('行程')) {
    return '好的，已为你生成 3 天东京建议：D1 浅草寺+晴空塔+秋叶原；D2 明治神宫+涩谷+表参道；D3 筑地市场+银座+台场。需要补充每日路线、预算和餐厅吗？'
  }
  if (text.includes('雨天') || text.includes('下雨')) {
    return '遇降雨可换室内方案：京都国立博物馆、锦市场、高岛屋，或雨中漫步伏见稻荷。需要我把备选写进具体某天的计划备注吗？'
  }
  if (text.includes('赶') || text.includes('节奏') || text.includes('建议')) {
    return '结合你的计划：第 3 天（岚山竹林 → 天龙寺 → 渡月桥）全程步行约 5km，节奏轻松。当天预算 ¥560，天气晴 25°C，建议 9 点前到竹林避开人流，中午在渡月桥附近用餐。整体不赶，可以把傍晚空出来加一个野宫神社。'
  }
  return '收到。请告诉我更关注哪方面：交通接驳、景点预约、餐饮推荐，还是天气与备选方案？我可以帮你更新对应日期的计划。'
}

// 进入助手页的开场问候语
function greet() {
  append('ai', '你好，我是你的旅行助手。我可以帮你推荐目的地、规划每日行程、查天气与预算，或对现有计划给出优化建议。想从哪里开始？')
}

onMounted(() => {
  if (messages.value.length === 0) greet()
})
</script>

<style lang="scss" scoped>
.assistant-page {
  position: relative;
  height: 100%;
  overflow: hidden;
  display: flex;
  flex-direction: column;
  box-sizing: border-box;
}

/* 页面背景：顶部黄色 → 浅灰白 → 白（原型 page-bg） */
.page-bg {
  position: absolute;
  inset: 0;
  z-index: 0;
  background: linear-gradient(180deg, #FACC15 0%, #FACC15 16.66%, #F4F1EA 40%, #FFFFFF 100%);
}

/* 内容层（原型 content，relative / flex column） */
.content {
  position: relative;
  z-index: 10;
  height: 100%;
  display: flex;
  flex-direction: column;
  box-sizing: border-box;
}

/* 头部：位于黄色部分（原型 page-header） */
.page-header {
  flex-shrink: 0;
  padding: 56rpx 48rpx 24rpx;
  color: #1C1917;
}
.head-title {
  font-family: $jp-font-heading;
  font-size: 48rpx;
  font-weight: 700;
  margin-top: 4rpx;
}
.head-desc {
  font-size: 28rpx;
  line-height: 1.5;
  color: rgba(28, 25, 23, 0.7);
  max-width: 560rpx;
  margin-top: 16rpx;
}

/* 白色内容卡片（原型 page-sheet） */
.page-sheet {
  position: relative;
  z-index: 10;
  background: #FFFFFF;
  border-radius: 56rpx 56rpx 0 0;
  box-shadow: 0 12rpx 30rpx -18rpx rgba(28, 25, 23, 0.28);
  margin: 28rpx 28rpx 0;
  padding-bottom: calc(120rpx + env(safe-area-inset-bottom));
  flex: 1 1 auto;
  min-height: 0;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

/* 消息区（原型 ai-chat） */
.ai-chat {
  flex: 1;
  min-height: 0;
  padding: 32rpx;
  box-sizing: border-box;

  &::-webkit-scrollbar {
    width: 0;
    height: 0;
    display: none;
  }
  scrollbar-width: none;
}

.msg {
  display: flex;
  align-items: flex-start;
  margin-bottom: 24rpx;

  &--user {
    justify-content: flex-end;
  }
  &--ai {
    gap: 16rpx;
  }
}

.msg-avatar {
  width: 56rpx;
  height: 56rpx;
  border-radius: 9999rpx;
  @extend %aurora;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  margin-top: 4rpx;

  .msg--user & {
    display: none;
  }
}

.bubble {
  max-width: 82%;
  padding: 20rpx 28rpx;
  border-radius: 32rpx;
  box-sizing: border-box;

  &--ai {
    background: $jp-card;
    border: 2rpx solid $jp-border;
    border-top-left-radius: 12rpx;
  }
  &--user {
    max-width: 78%;
    background: linear-gradient(to right, #FACC15 0%, #38BDF8 100%);
    border-top-right-radius: 12rpx;
  }
}
.bubble-text {
  font-size: 28rpx;
  line-height: 1.6;
  color: $jp-fg;

  .bubble--user & {
    color: #1C1917;
  }
}

.typing {
  display: flex;
  gap: 8rpx;
  padding: 6rpx 0;
}
.dot {
  width: 12rpx;
  height: 12rpx;
  border-radius: 9999rpx;
  background: $jp-muted-fg;
  animation: blink 1.2s infinite;

  &:nth-child(2) { animation-delay: 0.2s; }
  &:nth-child(3) { animation-delay: 0.4s; }
}
@keyframes blink {
  0%, 80%, 100% { opacity: 0.25; }
  40% { opacity: 1; }
}

/* 输入区（原型 input-area + sheet-fade） */
.input-area {
  flex-shrink: 0;
  padding: 16rpx 32rpx 24rpx;
  background: linear-gradient(to top, #FFFFFF 70%, rgba(255, 255, 255, 0));
}
.input-bar {
  display: flex;
  align-items: center;
  gap: 16rpx;
  background: $jp-card;
  border: 2rpx solid $jp-border;
  border-radius: 32rpx;
  padding: 12rpx 12rpx 12rpx 32rpx;
}
.input {
  flex: 1;
  height: 64rpx;
  background: transparent;
  font-size: 28rpx;
  color: $jp-fg;
}
.input-ph {
  color: $jp-muted-fg;
}
.send-btn {
  width: 72rpx;
  height: 72rpx;
  border-radius: 24rpx;
  @extend %aurora;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  flex-shrink: 0;
}
.disclaimer {
  text-align: center;
  font-size: 20rpx;
  color: $jp-muted-fg;
  margin-top: 12rpx;
}

/* aurora 多色渐变（原型 .aurora） */
%aurora {
  color: #1C1917;
  background:
    radial-gradient(120% 90% at 15% 10%, rgba(250, 204, 21, 0.95) 0%, rgba(250, 204, 21, 0) 55%),
    radial-gradient(110% 80% at 90% 20%, rgba(132, 204, 22, 0.85) 0%, rgba(132, 204, 22, 0) 50%),
    radial-gradient(80% 70% at 60% 100%, rgba(56, 189, 248, 0.7) 0%, rgba(56, 189, 248, 0) 60%),
    linear-gradient(135deg, #FACC15 0%, #FDE047 40%, #A3E635 100%);
  background-size: 200% 200%;
  animation: auroraShift 12s ease-in-out infinite;
}
@keyframes auroraShift {
  0%, 100% { background-position: 0% 50%; }
  50% { background-position: 100% 50%; }
}
@media (prefers-reduced-motion: reduce) {
  %aurora { animation: none; background-size: 100% 100%; }
}
</style>
