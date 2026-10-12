# 执行合同：我的计划页

## Intent Lock

- **变更名称**：my-plans-page
- **要解决的问题**：需求 V1.2 §3.3「我的计划页」无任何支撑代码（前端为空模板、后端为空 FastAPI），用户无法查看/搜索/新建/管理计划。
- **范围内**：FR-PL-01 列表展示（仅草稿/非草稿两种卡片）、FR-PL-03 关键字搜索、FR-PL-04 新建入口（含最小 Step1 命名与草稿创建）、FR-PL-05 修改名称（卡片按钮文本「编辑」）、FR-PL-07 删除（二次确认+物理删除）、FR-NAV-01 底部导航、FR-WZ-01 命名校验子集；后端 Plan 表 + GET/POST/PATCH/DELETE /plans + pytest + CORS + seed 脚本；前端 pages/plans、pages/plan-new、占位页、API 服务层、TabBar、Vite 工程化、uni.scss 设计令牌。
- **产品决策（DP-3，2026-08-28）**：状态系统全面取消——不做 PRD 3.2.2 四态派生、不提供 FR-PL-02 状态筛选，列表仅以 completed 标志区分草稿/非草稿；验收基准相应调整（AC-PL-01 中状态筛选相关项取消）。
- **范围外**：四态状态派生与状态筛选（已取消）、Step2/Step3 制定流程、FR-PL-06 编辑每日计划、卡片点击进入计划详情、前端分页交互（本次一次性加载）、Tab 位图图标（本次文字 Tab）、DayPlan 真实进度（generated_days 恒 0）、认证与多用户隔离、助手/个人中心实际功能、Agent AI/天气/地图外部接口。

## Approved Behavior

- **已批准需求摘要**：11 项 SHALL 需求（plan-list 规格 6 项：卡片列表/关键字搜索/新建入口/Step1 命名/卡片编辑删除/底部导航；plan-api 规格 5 项：completed 字段语义/GET/POST/PATCH/DELETE），共 22 个场景，按 DP-3 产品决策修订（状态系统取消）。
- **关键场景**：非草稿卡片（统一柠檬渐变封面+日期角标+信息区+进度条，无状态标签）、草稿虚线卡片（「草稿」标签+「已完成命名与基本信息，可继续生成每日计划」引导）、计数「共 N 段旅程 · M 段可见」、搜索防抖 ≥300ms 忽略大小写、底部常驻新建按钮、Step1 提交保存草稿回列表、编辑改名即时生效、删除二次确认后物理删除、completed 字段区分草稿/非草稿。
- **验收检查**：后端 `python -m pytest` 全绿；前端 `npm run dev:h5` 启动 + 手动验收（草稿/非草稿卡片、搜索、空态、编辑、删除 + AC-NAV）；视觉对照原型 v5（四态样式除外）。

## Design Constraints

- **架构约束**：SQLAlchemy 2.0 ORM，SQLite 开发/MySQL 生产（DATABASE_URL 切换，决策 1）；取消四态状态系统，仅 completed 标志区分草稿/非草稿（决策 2，产品决策）；搜索服务端执行（决策 3）；前端 uni-app Vite 工程化 @dcloudio/vite-plugin-uni + Vue 3（决策 4）；MVP 单用户 user_id=1（决策 7）；草稿关键字段可空、卡片占位「待完善」（决策 8）。
- **接口约束**：API 字段 snake_case 对齐 PRD 5.3（id/name/destination/depart_date/return_date/people_count/completed/total_budget/total_days/generated_days/created_at/updated_at）；列表响应 {items,total,page,page_size}；GET 仅 keyword/分页参数（无 status 参数）；POST 201/PATCH 200/DELETE 204，校验失败 422，不存在 404；completed=false 为草稿。
- **依赖约束**：后端主版本锁定 fastapi 0.115.*/SQLAlchemy 2.0.*/pytest 8.*；前端 package-lock.json 固化（决策 10）；开发 CORS 放行 localhost（决策 11）。
- **数据约束**：depart_date/return_date 为无时区 date；total_days 按「返回−出发+1」日历日派生（含首尾，决策 9），草稿无日期时为空；total_budget 默认 0；删除为物理删除无回收站。

## Execution Plan

按合同批准后（DP-3），在进入 build-executor（DP-4）时先运行 `ssf execution recommend <change-dir>` 按任务量与 wave 策略列出可用执行方式并推荐一种，保存 recommendation receipt；用户以 `--confirm` 显式确认（选择非推荐方式须附 `--acknowledge-recommendation`），再运行 `ssf execution plan <change-dir> --mode <mode> --confirm ...` 持久化执行计划到 `<change>/.superpowers/sdd/execution-plan.json`。Batch Inline 为串行模式，不得描述为并行。

## Execution Waves

每个 wave 必须有唯一 ID；只有依赖 wave 的 review receipt 为 `pass` 后，后续 wave 才可以开始。`parallel` 只表示宿主支持并发派发时允许同时执行；宿主不支持并发时必须如实报告，不得把 `parallel` 悄然改写为串行。

### Wave 1：后端数据能力（批次 1）

- **Wave ID**：wave-1-backend
- **任务**：1.1 后端骨架与 Plan 数据模型；1.2 GET /plans 列表查询与 completed 语义 + seed 脚本；1.3 POST/PATCH/DELETE /plans 与开发 CORS
- **依赖 wave**：无
- **策略**：`serial`（同包同目录，1.2/1.3 依赖 1.1 模型）
- **目标**：Plan 表 + 四个接口 + 草稿/非草稿字段语义 + CORS 就绪
- **输入**：plan-api 规格（响应结构/枚举/状态码）、设计决策 1/2/9/11
- **输出**：`journey-plan-api/app/`（config/database/models/schemas/routers）、tests/、scripts/seed.py、requirements.txt
- **完成标准**：`python -m pytest` 全绿（completed 语义、搜索大小写、422/404、CRUD）
- **Review gate**：`ssf execution review` 记录 review receipt `pass` 后 Wave 2 方可开始

### Wave 2：前端列表交互（批次 2）

- **Wave ID**：wave-2-frontend-list
- **任务**：2.1 前端工程化 + API 服务层 + uni.scss 令牌；2.2 我的计划列表页（草稿/非草稿卡片/编辑/删除/计数/空态）；2.3 关键字搜索
- **依赖 wave**：wave-1-backend（API 可用）
- **策略**：`serial`（2.2/2.3 同改 pages/plans/plans.vue；2.1 为前置）
- **目标**：列表页按原型 v5 完整可用（草稿/非草稿卡片、搜索、编辑、删除）
- **输入**：wave-1 接口 + seed 演示数据、plan-list 规格、设计决策 3/4/5/10
- **输出**：package.json、vite.config.js、uni.scss、api/request.js、api/plan.js、pages/plans/plans.vue
- **完成标准**：`npm run dev:h5` 启动无报错 + 手动验收（对照 seed 数据与原型）
- **Review gate**：`ssf execution review` 记录 review receipt `pass` 后 Wave 3 方可开始

### Wave 3：入口与导航（批次 3）

- **Wave ID**：wave-3-entry-nav
- **任务**：3.1 新建入口与 Step1 命名页（pages/plan-new）；3.2 底部导航接入（pages.json 3 Tab + 占位页）
- **依赖 wave**：wave-2-frontend-list
- **策略**：`serial`（3.1 与 3.2 均需改 pages.json 注册页）
- **目标**：新建入口端到端可用（入口→Step1→草稿回显），AC-NAV 验收通过
- **输入**：plan-list 规格（入口/Step1/导航场景）、设计决策 5/6/8
- **输出**：pages/plan-new/plan-new.vue、pages/assistant/assistant.vue、pages/profile/profile.vue、pages.json
- **完成标准**：dev:h5 手动验收创建草稿回显（草稿标签、列表顶部）+ AC-NAV 三项
- **Review gate**：`ssf execution review` 记录 review receipt `pass` 后进入收口

## Test Obligations

- **必须先从失败测试开始的行为**（TDD，后端）：completed 字段语义（草稿 false/非草稿 true）；GET 搜索忽略大小写与模糊匹配；POST/PATCH 名称校验（空/全空格/1 字符/2 字符/20 字符/21 字符）；DELETE 204 与删除后列表不再返回；404 路径。前端无自动化测试框架（设计风险已记录），以手动验收清单替代。
- **必需的边界情况**：大小写与中文子串搜索；草稿 null 字段序列化；分页边界（恰好整页/空页）；total_days 派生（同日往返=1 天）。
- **回归敏感区域**：pages.json TabBar 与启动页变更（Hello 页不再启动，需确认不破坏模板启动）；completed 字段语义（后续 FR-DY 变更依赖其草稿判定）。

## Execution Mode

- **可用方式与推荐**：待 DP-4 由 `ssf execution recommend <change-dir>` 生成并持久化 recommendation receipt。
- **用户确认的模式**：待 DP-4 用户以 `--confirm` 确认。
- **推荐理由 / 项目事实**：8 任务 3 wave，无并行宿主需求（同仓库同文件区），Batch Inline 为串行模式。
- **非推荐选择的风险确认**：`--acknowledge-recommendation`（若适用）。
- **执行计划命令**：`ssf execution plan <change-dir> --mode <mode> --confirm --reason <text> --wave <id>:<parallel|serial>:<task,...>[:<depends-on,...>]`。
- **允许的修订**：保留或升级为 `sdd`；先重新 recommend 再以 `--confirm` 生成新 revision；不允许降级（`ssf execution revise`）。
- **计划 revision / artifact hash**：待 DP-4 持久化后回填。

## Verification Dimensions

| 维度 | 状态 | 发现 |
|------|------|------|
| Completeness | Pending | — |
| Correctness | Pending | — |
| Coherence | Pending | — |

**总体结论**：Pending

## Review Gates

- **强制审查点**：每个 Execution Wave 完成后必须记录 `ssf execution review` 的 review receipt（review report 路径 + base/head SHA + verdict）。
- **阻塞类别**：依赖 wave review receipt 非 `pass`；receipt 缺失或过期（artifacts/contract 变更后）。
- **收口条件**：全部 3 个 wave 均持有当前 `pass` review receipt 后方可进入 release-archivist 收口。

## Escalation Rules

- **何时回退到 `specifying`**：PRD/原型规则或产品决策再变更（如恢复状态系统、卡片要素、文案口径）；用户提出本范围外需求且要求并入（如 Step2/Step3、FR-PL-06）；规格之间出现矛盾。
- **何时回退到 `bridging`**：scope 越过 Scope Fence（如引入 DayPlan 实体/认证）；设计决策被推翻（如更换 ORM、恢复四态派生）；契约与四份规划产物发生漂移（Stale Contract）。
- **何时不得继续实现**：dp_3 未批准；无当前 `ssf execution plan`；依赖 wave 的 review receipt 非 `pass`；测试失败未排查（转 bug-investigator，不得绕过失败继续写码）。
