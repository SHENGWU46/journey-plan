# 实现任务：我的计划页

## 交付与证明

| 批次 | 交付结果 | 依赖 | 证明 |
|---|---|---|---|
| 1 | 后端 Plan 模型 + GET/POST/PATCH/DELETE /plans + 草稿/非草稿字段语义，pytest 覆盖 | 无 | `python -m pytest`（journey-plan-api 目录）全绿 |
| 2 | 前端工程化 + 我的计划页（草稿/非草稿卡片、搜索、编辑、删除） | 批次 1 | `npm run dev:h5` 启动成功 + 手动验收卡片/搜索/编辑/删除项 |
| 3 | 新建入口 + Step1 命名页 + 底部导航 | 批次 2 | `npm run dev:h5` 手动验收空态引导 + AC-NAV；后端 pytest 仍全绿 |

## 任务

- [ ] **1.1 后端骨架与 Plan 数据模型**：在 `journey-plan-api/` 建立 app 包（config/database/models），Plan 表字段对齐 PRD 5.1（user_id、name、destination、depart_date、return_date、people_count、completed、total_budget、created_at、updated_at），`DATABASE_URL` 支持 SQLite/MySQL 切换（决策 1）；完成后模型可导入、建表成功；证明：`python -m pytest tests/test_models.py`。
- [ ] **1.2 列表查询 API 与草稿/非草稿语义**：新增 GET /plans（keyword/page/page_size），name LIKE 忽略大小写模糊匹配、updated_at 倒序，响应结构按 plan-api 规格（items/total/page/page_size + snake_case 计划对象，completed 区分草稿，total_days 按日历日派生，决策 9）；新增 `scripts/seed.py` 生成草稿与非草稿演示数据供手动验收；证明：`python -m pytest tests/test_plans_api.py -k list`。
- [ ] **1.3 草稿创建、改名、删除 API 与开发 CORS**：新增 POST /plans（名称去首尾空格后 2-20 字符校验，非法 422；合法创建草稿 completed=false 返回 201）、PATCH /plans/{id}（同校验，404 处理）、DELETE /plans/{id}（物理删除 204，404 处理）；配置开发 CORS 放行本地来源（决策 11）；证明：`python -m pytest tests/test_plans_api.py`。
- [ ] **2.1 前端工程化与 API 服务层**：`journey-plan-app/` 新增 package.json、vite.config.js（@dcloudio/vite-plugin-uni + Vue 3，决策 4/10），api/request.js 统一 baseURL/错误处理，api/plan.js 封装列表查询、创建、改名、删除；uni.scss 落地原型 v5 设计令牌（决策 5）；完成后 `npm run dev:h5` 可启动；证明：`npm run dev:h5` 启动日志无报错。
- [ ] **2.2 我的计划列表页**：新增 pages/plans/plans.vue 按原型 v5 结构：非草稿卡片（统一柠檬渐变封面+日期角标+信息区+进度条「每日计划已生成 X / Y」）、草稿虚线卡片（编辑图标头+「草稿」标签+「已完成命名与基本信息，可继续生成每日计划」引导）、计数文案「共 N 段旅程 · M 段可见」、空态与底部常驻「新建一段旅程」虚线按钮、卡片「编辑」改名与「删除」二次确认交互；证明：dev:h5 手动验收草稿/非草稿卡片、空态、编辑与删除（对照 seed 数据与原型）。
- [ ] **2.3 关键字搜索**：搜索框输入防抖 ≥300ms 后请求，忽略大小写模糊匹配，无结果空态 + 新建引导（原型文案），以请求序号丢弃过期响应；证明：dev:h5 手动验收搜索与快速输入场景。
- [ ] **3.1 新建入口与 Step1 命名页**：列表底部与空态入口 → pages/plan-new/plan-new.vue 按原型 STEP 1/3 步进器样式（名称输入框、2-20 字符去空格校验提示、「下一步」主按钮），提交 POST /plans 保存草稿后返回列表刷新；证明：dev:h5 手动验收创建草稿回显列表（带「草稿」标签、排序在顶部）。
- [ ] **3.2 底部导航接入**：pages.json 配置 3 Tab（我的计划为启动 Tab + 旅行助手/个人中心占位页，文字 Tab 无位图图标，决策 6，高亮色 deep），新增 pages/assistant、pages/profile 占位页；证明：dev:h5 手动验收 AC-NAV（默认进入我的计划、Tab 高亮、切换后保留搜索状态）。

## 实施备注（仅在必要时）

- 后端测试使用 SQLite 内存库，覆盖草稿/非草稿 completed 语义、大小写搜索与增删改校验。
- 状态筛选与四态派生已按产品决策取消（2026-08-28）：GET /plans 无 status 参数，前端无筛选栏。
- 前端列表本次一次性加载（请求 page_size 上限内），分页交互（加载更多/无限滚动）为后续变更；后端分页字段已就绪。
- 卡片「编辑」当前仅修改名称（FR-PL-05）；编辑每日计划（FR-PL-06）与卡片点击进入详情为后续变更。
- 响应竞态处理只在前端（请求序号），不依赖服务端保证。
- Hello 页文件保留但不再作为启动页；启动页改为 pages/plans/plans。
