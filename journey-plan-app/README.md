# Journey Plan · 移动端（uni-app）

Journey Plan 智能旅行计划的移动端，一套代码可产出 **Android App** 与 **H5**。

> 完整项目（含后端与 AI 子系统）见[仓库根 README](../README.md)。
>
> **线上 H5**：<https://app.journey-plan.cn> —— 可直接注册试用（演示环境，数据可能随时清空）。

## 技术栈

| 项 | 选型 |
|---|---|
| 框架 | uni-app（Vue 3 + `<script setup>` + Composition API） |
| 语言 | JavaScript |
| 样式 | SCSS + 设计令牌（柠檬黄主题，见 `uni.scss`） |
| 构建 | Vite 5（`@dcloudio/vite-plugin-uni`） |
| 打包 | HBuilderX 云打包（Android App） / `npm run build:h5`（H5） |

## 目录结构

```
journey-plan-app/
├── pages/               页面
│   ├── index/           启动页（跳转登录或计划列表）
│   ├── login/           登录
│   ├── register/        注册
│   ├── plans/           我的计划（搜索 / 筛选 / 卡片列表）
│   ├── plan-new/        新建旅程（命名 → 基本信息）
│   ├── day-plan/        单日计划（天气 / 预算 / 游玩时间 + AI 推荐 + 路线排序）
│   ├── assistant/       旅行助手（AI 问答）
│   └── profile/         个人中心
├── components/          通用组件（AppIcon / AppTabBar / PlanCard / StepIndicator …）
├── api/                 接口层
│   ├── request.js       uni.request 封装：BaseURL / 鉴权头 / 统一错误处理
│   └── auth.js · plan.js · day.js · assistant.js · user.js
├── utils/               日期、金额、token 等工具
├── static/              静态资源
│   └── icons/           图标（<图形>-<色值>.svg，由 AppIcon 组件引用）
├── uni.scss             设计令牌（颜色 / 圆角 / 字体 / 渐变）
├── pages.json           页面与导航配置
└── manifest.json        应用配置（appid / 应用名 / App 权限）
```

## 运行

```bash
npm install
npm run dev:h5          # 浏览器调试，默认 http://127.0.0.1:5173
```

打包 Android App：用 **HBuilderX** 打开本项目 → 发行 → 原生 App 云打包。

## 接口地址（按环境切换）

`api/request.js` 里按环境选择 BaseURL，开发连本机、正式连线上：

```js
export const BASE_URL = IS_DEV
  ? 'http://127.0.0.1:8000'          // 开发：本机后端
  : 'https://api.journey-plan.cn'    // 正式：打包 App 走这里
```

> 改动接口地址只需改这一处；所有请求都必须走 `api/request.js`，禁止页面内直接 `uni.request`。

## 图标约定（重要）

图标统一用 `components/AppIcon.vue`，**不要在页面里写内联 `<svg>`**：

```html
<AppIcon name="pin" color="#78716C" :size="36" />     <!-- size 数字 = rpx -->
<AppIcon name="close" color="#78716C" size="16px" />  <!-- size 字符串 = 原样 -->
```

原因（踩过的坑）：

- **uni-app App 端不渲染内联 `<svg>`**。App 端视图层用 `document.createElement()`（而非
  `createElementNS`）创建元素，`<svg>` 会变成 `HTMLUnknownElement`，浏览器画不出来 → 手机上图标空白；
  H5 端走标准 Vue 运行时（自带 SVG 命名空间判断）所以正常。**该问题在 H5 / Edge 截图里完全看不出来，只有真机才暴露。**
- 因此图标改为**静态 `.svg` 文件 + `<image>`**（App 端 `<image>` 最终是 WebView 里的 `<img>`，原生支持 SVG）。
- **颜色写进文件名**：以 `<img>` 方式加载的 SVG 拿不到外层 CSS 的 `color`，`currentColor` 会失效，
  所以每种颜色单独一个文件（如 `pin-78716c.svg`）。新增颜色只需加一个同图形、新色值后缀的文件，组件无需改动。
- 需要跟随状态变色时用绑定：`:color="isSelected(a) ? '#1C1917' : '#78716C'"`。

## 相关文档

- [需求分析文档](../docs/requirements.md)
- [交互原型](../docs/journey-plan-prototype.html)
- [开发约定与踩坑记录](../AGENTS.md)
