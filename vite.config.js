import { defineConfig } from 'vite'
import uni from '@dcloudio/vite-plugin-uni'

// uni-app Vite 工程化（设计决策 4）：npm run dev:h5 为开发与验收运行方式。
// vite 版本需与 @dcloudio/vite-plugin-uni 的 peerDependencies（5.2.8）保持一致。
//
// 注意：本工程为 HBuilderX 目录结构（manifest.json / pages.json / main.js 位于根目录，
// 而非 CLI 模板的 src/ 子目录）。uni CLI 默认以 process.cwd()/src 作为输入目录，
// 直接执行会报 ENOENT: src\manifest.json，故 package.json 的脚本统一通过
// cross-env UNI_INPUT_DIR=. 将输入目录指回工程根目录。
export default defineConfig({
  plugins: [uni()]
})
