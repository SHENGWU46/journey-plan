<template>
  <image class="app-icon" :src="src" mode="aspectFit" :style="boxStyle" />
</template>

<script setup>
// 图标组件：统一用 <image> + static/icons/*.svg 渲染小图标。
//
// 为什么不用内联 <svg>：uni-app App 端的视图层渲染器是用 document.createElement()
// 创建元素的（不是 createElementNS），模板里的 <svg> 会变成 HTMLUnknownElement，
// 浏览器根本画不出来 → 手机上图标一片空白。H5 端走标准 Vue 运行时（自带 SVG
// 命名空间判断，产物里是 createElementNS），所以同一份代码在 PC 上正常、手机上空白。
//
// 为什么颜色写进文件名：以 <img> 方式加载的 SVG 拿不到外层 CSS 的 color 继承，
// currentColor 会退化，所以每种颜色单独导出一个文件，文件名后缀就是色值。
// 需要新颜色时，在 static/icons/ 下加一个同图形、不同后缀色的文件即可。
import { computed } from 'vue'

const props = defineProps({
  // 图标名，对应 static/icons/<name>-<color>.svg
  name: { type: String, required: true },
  // 颜色，'#RRGGBB' 或 'RRGGBB' 都接受
  color: { type: String, default: '#1C1917' },
  // 尺寸：数字 = 单位 rpx；字符串 = 原样使用（如 '18px'）
  size: { type: [Number, String], default: 32 }
})

const src = computed(
  () => `/static/icons/${props.name}-${props.color.replace('#', '').toLowerCase()}.svg`
)

const boxStyle = computed(() => {
  // 数字按 rpx 处理，交给 uni.upx2px 转 px，避免依赖“内联样式里写 rpx”这种行为
  const s = typeof props.size === 'number' ? `${uni.upx2px(props.size)}px` : props.size
  return { width: s, height: s, flexShrink: 0 }
})
</script>

<style lang="scss" scoped>
.app-icon {
  display: block;
}
</style>
