// H5 开发 / 构建包装器（被 package.json 的 dev:h5 / build:h5 调用）。
//
// 为什么要包这一层：
// 本工程用的是 HBuilderX 目录结构 —— manifest.json / pages.json / main.js 都放在**工程根目录**，
// 而不是 uni CLI 模板的 src/ 子目录。所以必须用 UNI_INPUT_DIR 把输入目录指回工程根，
// 否则 uni 会报 ENOENT: src\manifest.json。
//
// 踩过的坑（2026-10-13）：
// 传**相对路径** `UNI_INPUT_DIR=.` 时，uni 的静态资源复制步骤会**静默失败** ——
// 构建能成功、日志不报错，但产物里没有 static/ 目录。后果是：
//   /static/tab-*.png    底部导航图标 → 404
//   /static/icons/*.svg  页面图标     → 404
// 页面能打开，图标全是空白，非常难查（HBuilderX 打 App 时又是正常的）。
//
// 解法：把 UNI_INPUT_DIR 设为**绝对路径**（process.cwd()），static/ 就会被正确复制。
import { spawnSync } from 'node:child_process'

const mode = process.argv[2] === 'build' ? 'build' : ''
const env = { ...process.env, UNI_INPUT_DIR: process.cwd() }
const cmd = ['uni', mode, ...process.argv.slice(3)].filter(Boolean).join(' ')

const result = spawnSync(cmd, { stdio: 'inherit', env, shell: true })
process.exit(result.status ?? 1)
