# 变更提案：我的计划页（My Plans Page）

## 背景（Why）

需求文档 V1.2 §3.3 定义「我的计划页」为用户管理旅程计划的入口：卡片列表展示（名称、时间范围、天数、人数、总预算、进度）、按名称搜索、从本页发起新建旅程。当前工程不具备任何计划数据能力：`journey-plan-app` 是 uni-app 空模板（仅 Hello 页、无构建脚本），`journey-plan-api` 是单文件空 FastAPI 应用，不存在 Plan 数据模型、列表接口或对应页面。用户打开应用后无法查看或创建任何计划。项目已有可交互原型 `docs/journey-plan-prototype.html`（v5，含柠檬黄设计令牌与完整页面交互），本次实现以其为视觉与交互基准。

**产品决策（2026-08-28，DP-3 记录）**：计划状态系统全面取消——不做四态派生（PRD 3.2.2）、不提供状态筛选（FR-PL-02 取消），列表仅区分「草稿 / 非草稿」；与 PRD 的冲突以本决策为准。

## 变更内容（What Changes）

- 后端新增 Plan 数据模型与持久化（开发期 SQLite，DATABASE_URL 可切换 MySQL 8.x，符合 PRD 9.2-6）；计划仅以 `completed` 标志区分草稿（false）/非草稿（true），不做四态状态派生。
- 后端新增 API：`GET /plans`（名称关键字搜索 + 分页，更新时间倒序）、`POST /plans`（校验名称后创建草稿计划）、`PATCH /plans/{id}`（修改计划名称）、`DELETE /plans/{id}`（物理删除）。
- 前端新增「我的计划」页：卡片列表按原型 v5 结构（非草稿=统一柠檬渐变封面 + 日期角标 + 信息区 + 进度条；草稿=虚线卡片 + 「草稿」标签 + 引导文案）、卡片内「编辑/删除」操作（编辑=修改名称，删除需二次确认）、计数文案（共 N 段旅程 · M 段可见）、空态引导、列表底部常驻「新建一段旅程」入口。
- 关键字搜索（防抖 ≥300ms、忽略大小写模糊匹配、无结果空态）。
- 前端新增最小 Step1 命名页（原型 STEP 1/3 步进器样式）：默认提示与 2-20 字符校验、去首尾空格，提交即保存草稿并返回列表刷新（Step2/Step3 为后续变更，本次提交即回列表）。
- 接入 3 Tab 底部导航（FR-NAV-01）：我的计划（默认启动 Tab）/旅行助手/个人中心（后两者为占位页）。
- 前端补齐工程化：package.json + Vite + @dcloudio/vite-plugin-uni，`npm run dev:h5` 作为开发与验收运行方式；uni.scss 落地原型设计令牌。

## 范围（Scope）

### 范围内（In Scope）

- FR-PL-01 计划列表展示（草稿/非草稿两种卡片）、FR-PL-03 关键字搜索、FR-PL-04 新建旅程入口（含最小 Step1 命名与草稿创建）。
- FR-PL-05 修改名称（卡片按钮文本为「编辑」）、FR-PL-07 删除计划（原型列表卡片含操作按钮，随本次一并交付）。
- FR-NAV-01 底部导航；FR-WZ-01 命名校验子集。
- 视觉基准：参照 `docs/journey-plan-prototype.html` v5 的页面结构与设计令牌（柠檬黄主题），不修改原型文件本身。
- 后端：Plan 表、GET/POST/PATCH/DELETE /plans、pytest 测试（搜索/叠加、创建/改名/删除校验）、开发 CORS 配置、开发演示种子脚本（含草稿与非草稿数据）。
- 前端：pages/plans、pages/plan-new、旅行助手与个人中心占位页、API 服务层、pages.json TabBar 配置、Vite 工程化文件、uni.scss 设计令牌。

### 范围外（Out of Scope）

- **FR-PL-02 状态筛选与 PRD 3.2.2 四态派生：按产品决策取消**（列表仅区分草稿/非草稿），不实现筛选栏与四态状态。
- 制定计划 Step2（目的地/日期/人数/景点推荐）与 Step3（每日计划/路线/计划完成）——后续变更。
- FR-PL-06 编辑每日计划（依赖 Step3/DayPlan）——后续变更。
- 卡片点击进入计划详情/继续编辑（原型 openPlan 行为）——依赖 Step3，后续变更。
- 前端列表分页交互（加载更多/无限滚动）：后端分页能力就绪，前端本次一次性加载（数据量小），交互后续变更。
- Tab 位图图标资源（原型为内联 SVG，uni-app tabBar 需位图，本次文字 Tab，图标后续视觉打磨补齐）。
- DayPlan/Spot/路线等实体：进度字段 generated_days 本次恒为 0，待 FR-DY 变更接入真实数据。
- 账号认证与多用户隔离：MVP 固定默认用户，认证模块后续接入。
- 旅行助手（FR-AS）与个人中心（FR-ME）实际功能：本次仅 Tab 占位页。
- Agent AI、天气、地图/地点联想等外部接口。

## 影响与验证

- **影响区域**：`journey-plan-api`（重组为 app 包：config/database/models/schemas/routers + tests + seed 脚本）；`journey-plan-app`（新增 pages/plans、pages/plan-new、pages/assistant、pages/profile、api 服务层、package.json/vite.config.js、uni.scss，修改 pages.json）；`docs/journey-plan-prototype.html` 仅作为参照基准，不修改。
- **完成证明**：
  - 后端：`python -m pytest` 全绿，覆盖草稿/非草稿字段语义、搜索（忽略大小写/模糊）、创建/改名/删除校验。
  - 前端：`npm run dev:h5` 启动成功；手动验收（验收基准随产品决策调整）：卡片要素完整且草稿/非草稿区分正确、搜索可用、空态有引导、「编辑」改名与删除可用（AC-PL-01 中与状态筛选相关项随决策取消）；AC-NAV（3 Tab 可达、默认进入我的计划、切换保留页面状态）；页面结构与视觉对照原型 v5。
