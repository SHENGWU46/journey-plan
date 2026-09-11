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
  plugins: [uni()],
  // 开发服务器显式双栈监听（IPv6 '::' + IPv4 映射）：
  // 默认只绑 localhost，本机解析为 IPv6 后仅 [::1]:5173 可连，http://127.0.0.1:5173
  // 会被直接拒绝（curl 等只走 IPv4 的工具表现为 exit 7）。绑 '::' 后 IPv4/IPv6 均可达。
  // 注：这会同时监听局域网地址，便于真机联调；仅用于开发环境。
  server: {
    host: '::',
    port: 5173
  }
})
