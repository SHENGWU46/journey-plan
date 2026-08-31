import { defineConfig } from 'vite'
import uni from '@dcloudio/vite-plugin-uni'

// uni-app Vite 工程化（设计决策 4）：npm run dev:h5 为开发与验收运行方式。
// vite 版本需与 @dcloudio/vite-plugin-uni 的 peerDependencies（5.2.8）保持一致。
export default defineConfig({
  plugins: [uni()]
})
