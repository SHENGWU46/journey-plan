# Journey Plan 智能旅行计划 — 全局开发规范 (AGENTS.md)

## 项目概览

| 子项目 | 目录 | 技术栈 | 说明 |
|--------|------|--------|------|
| journey-plan-app | `journey-plan-app/` | uni-app（Vue 3 + Composition API）+ JavaScript + 自定义设计令牌（柠檬黄主题） | 移动端前端（H5 / 小程序 / App） |
| journey-plan-api | `journey-plan-api/` | FastAPI（Python 3.10+）+ SQLAlchemy 2.x + MySQL 8.x | 后端 API 服务 |
| 需求文档 | `docs/requirements.md` / `docs/requirements.docx` | 当前 V1.2 | **docx 为源，md 由脚本同步（双份必须一致）** |
| 过程产物 | `changes/` | — | 规范驱动开发的过程记录（proposal / design / tasks / specs） |
| 部署资产 | `deploy/` | nginx + systemd | 服务器部署脚本与站点配置 |

---

## 一、新功能开发流程（spec-workflow）

### 1.1 启动

```
"使用 workflow-start 进行 {功能名称} 的功能开发"
"按需求文档第 X 章开发 {功能名称}"
"给 {功能} 加一个需求并同步到 PRD"
```

- **Claude Code 环境**（已安装 spec-superflow 全家桶，`~/.claude/skills/`）：AI 自动路由到 `spec-superflow:workflow-start` 状态机，按 1.2 阶段推进。
- **WorkBuddy 环境**（本会话，未安装 spec-superflow）：按 1.2 同款阶段手动推进，产出物一致。
- 涉及需求变更时同步更新需求文档（docx + md 双份）。

### 1.2 阶段说明（spec-superflow 状态机）

状态流：`exploring → specifying → bridging → approved-for-build → executing → closing`（`debugging` 为 executing 侧路，`abandoned` 为终态）。

| 阶段 | 技能 | 产出物 | 确认点 |
|------|------|--------|--------|
| 需求澄清 | `need-explorer` | 变更定义（proposal.md 范围/约束） | DP-0：确认范围、约束 |
| 工件编写 | `spec-writer` | proposal.md + specs/ + design.md + tasks.md + DDL.sql + 接口契约 | DP-2：审查工件 |
| 合约构建 | `contract-builder` | execution-contract.md（验收条款） | DP-3：批准合约 |
| 执行（编码） | `build-executor` | 代码文件 | DP-4：选择执行模式 |
| 验证 | `code-reviewer` + 编译/lint + 冒烟 + Edge 截图 | 通过报告 | DP-6：验证通过 |
| 归档 | `release-archivist` + `spec-merger` | 规范合并、变更归档 | DP-7：确认归档 |

状态机命令（Claude Code 环境）：`ssf runtime check-update`、`ssf execution show <change-dir> --json`、`ssf handoff list/resolve`、`ssf checkpoint list`、`ssf runtime asset read docs/state-machine.md`。

### 1.3 各阶段产出物规范

**spec 规范（spec-writer 产物，OpenSpec delta 格式）：**
- 目录：`specs/{模块}/`，每能力一个 `spec.md`，章节头必须是 `## ADDED Requirements` / `## MODIFIED Requirements` / `## RENAMED Requirements` / `## REMOVED Requirements`
- 需求标题用 `### Requirement: <名称>`（保留 REQ-XXX 编号便于追溯），每个需求下必须含 `#### Scenario:` + `- **WHEN**` / `- **THEN**` 列表项
- `## 注意事项`：历史踩过的坑，置于 requirements 之后；文件 UTF-8 无 BOM
- 工件对应关系：`proposal.md`（变更定义）→ `specs/`（需求 delta）→ `design.md`（接口契约 + 数据模型）→ `tasks.md`（文件清单 + 接口清单）→ `execution-contract.md`（验收条款）

**需求文档更新规范：**
- **源文件**：`tools/gen_prd_v2.py` → 生成 docx → `tools/docx2md.py` 转 md；禁止只改 md 或只改 docx（依赖：python-docx）
- 每次变更必须：升 V 版本、修订记录新增一行、`9.3 变更记录`追加说明
- 文档当前版本 V1.2（技术栈 uni-app / FastAPI / MySQL 已确认）

**接口契约规范（第 6 章）：**
- 统一响应格式：`{ "code": 0, "message": "ok", "data": ... }`，成功 `code=0`，业务错误用负数 code + 错误码表
- 前端 `api/` 层每个方法必须与一个后端接口一一对应，注释标注 `@contract 对应 PRD 6.2 接口X`
- 未实现的后端接口：路由必须真实存在，返回 `code=501` + `"not implemented"`，禁止假数据冒充成功

**数据模型规范（第 5 章）：**
- 表名：`{prefix}_{table}`；所有业务表含审计字段：`id, create_time, update_time, is_deleted`
- 多对多用独立关联表（`{prefix}_{主体}_{关联对象}`），禁止逗号分隔字段
- 金额：整数（元）；时间：ISO8601；枚举：字典/常量表

### 1.4 编码阶段技能/工具（必须）

> spec-superflow 环境：`build-executor` 编码时按 `ssf` 状态机执行 wave（`ssf execution show` 判断 eligible）；本项目的等价技能映射见下表。

| 技能 / 工具 | 用途 | 必须 |
|-------------|------|------|
| `ui-ux-pro-max` | UI 设计系统（柠檬黄主题令牌、UX 准则） | ✅ 涉及 UI 时 |
| `frontend-dev` / `ui-styling` | 页面/组件实现 | ✅ 前端编码 |
| `code-reviewer` | 代码审查（质量/一致性） | ✅ 每批代码完成后 |
| node（托管运行时） | JS 语法校验 + DOM 桩冒烟 | ✅ 前端交付前 |
| Edge/Chrome headless | 真实浏览器截图验证 UI（CSS 覆盖类 bug 桩测不出来） | ✅ UI 改动后 |
| python-docx | PRD docx 生成与 docx→md 转换 | ✅ PRD 变更时 |

### 1.5 关键原则

- **逐阶段确认**：每个 DP 点必须用户确认后才进入下一阶段
- **禁止 stub**：后端接口要么真正实现，要么明确返回 501；前端预留接口在 `api/` 层写模拟实现并标注 `TODO(backend)`
- **UI 验证必须跑真实浏览器**：历史教训——`flex` 类会覆盖 `.page{display:none}`，DOM 桩无法暴露，必须 Edge 截图确认
- **PRD 双份同步**：任何需求/技术栈变更必须 docx 与 md 同时更新
- **对照现有代码**：生成新文件前先看 2-3 个同类文件确认目录、命名、API 用法

### 1.6 交付前必检

```
node -e "校验内联/源码 JS 语法"          # 前端
DOM 桩冒烟（核心流程走一遍）               # 前端逻辑
Edge --headless --screenshot             # UI 实际渲染（三个 Tab + 制定流程）
python -m uvicorn main:app               # 后端启动检查
curl http://127.0.0.1:8000/xxx           # 接口冒烟
检查所有生成文件中文正常（无 ???）          # 编码
grep PRD 版本号 == README 中记录的版本      # 文档一致性
App 端专属行为必须云打包真机验证             # H5/Edge 截图测不出 App 端差异（如内联 svg 不渲染）
```

---

## 二、既有功能修改流程

### 2.1 先读规范

```
docs/requirements.md           ← 功能与业务规则（含 9.2 已确认决策）
AGENTS.md                      ← 本文件（编码约定与踩坑）
README.md（根目录）             ← 项目总览、架构、快速开始
journey-plan-api/README.md     ← 后端接口契约（需求文档第 6 章的落地细节）
```

### 2.2 按规模选流程

| 规模 | 流程 |
|------|------|
| 小改动（改文案、修 bug） | 直接改 → 前端跑 node 语法 + 冒烟；UI 改动加 Edge 截图 |
| 中改动（加字段、改逻辑） | 对照需求文档确认影响面 → 改代码 → 更新需求文档对应章节（若涉及需求） |
| 大改动（新模块、改流程） | 走完整 spec-workflow（见第一章） |

### 2.3 修改后

- 改了需求：更新需求文档（升版本 + 修订记录 + 双份同步；工具见 1.3）
- 踩了新坑：追加到本文档对应章节（或需求文档对应章节注意事项）

---

## 三、子项目编码规范

### 3.1 journey-plan-api（后端 FastAPI）

**目录结构：**
```
journey-plan-api/
├── main.py              应用入口（FastAPI 实例，CORS、路由注册）
├── alembic/             数据库迁移（versions/ 存版本脚本，建表不走 create_all）
├── scripts/             运维脚本（seed.py 演示数据，异步版）
└── app/
    ├── settings.py      全局配置唯一来源（DB_URI / JWT_*），自动 load_dotenv 读 .env
    ├── models/          ORM 模型包：__init__.py 集中 engine/AsyncSessionFactory/Base
    │                    + get_session；plan.py 等按表拆分（User / Plan / DayPlan ...）
    ├── repository/      数据访问层（plan_repo.py），封装表级查询与持久化
    ├── routers/         auth / plans / days / assistant / user（只编排，不写 SQL）
    ├── schemas/         Pydantic 模型（入参校验 + 出参序列化）
    ├── services/        AI Agent、天气等外部服务封装
    └── core/            auth.py（JWT 单例鉴权）等与业务无关的可复用能力
```

> 分层参考 `fastapi学习/AN-API`：settings 集中配置、models 集中引擎、repository 封装数据访问。

**关键约定：**
- **分层依赖方向**：`routers → repository → models`，反向依赖禁止；
  路由层只做参数校验、编排 repo、响应序列化与 404 等业务判定，**禁止在路由内直接写 DB 操作**
- **配置唯一来源**：`app.settings`（模块内 `load_dotenv` 读取项目根 `.env`，已 gitignore）；
  新增配置一律加在此处，禁止各处散落 `os.environ`；`.env` 未被读取 = 配置静默失效（踩过的坑）
- **数据库全异步**：`app.models` 的 `engine` / `AsyncSessionFactory` / `get_session`；
  驱动 `aiomysql`（MySQL）/ `aiosqlite`（SQLite 开发默认），会话一律 `await`
- **Repository 写法**：读方法只查询；写方法内部完成 add/commit/refresh，一次请求调用一个写方法。
  不要在 repo 方法内用 `async with session.begin()`（同请求多次调用会因事务已开始而报错，参考项目有此坑）
- **JWT 鉴权**：`app.core.auth.AuthHandler`（线程安全单例），
  用法 `user_id: int = Depends(auth_handler.auth_access_dependency)`；密钥走 `JWT_SECRET_KEY` 环境变量
- 路由前缀：`/api/v1/{module}`，用 `APIRouter(prefix=...)` 组织
- 统一响应：`{code, message, data}`，见 1.3 接口契约
- 入参必须 Pydantic 校验（禁止裸 `dict`/`**kwargs` 传参）
- SQLAlchemy 2.x 声明式模型；`Base` 带 naming_convention（与 0001 迁移的 `pk_plans` 一致，避免 autogenerate 假差异）
- 密码 `bcrypt` 加密存储
- 时间字段统一 ISO8601；金额整数（元）
- AI Agent（推荐景点/生成每日计划/问答）封装在 `services/`，提示词与模型配置走环境变量
- **测试**：按既有约定，测试不纳入仓库（`.gitignore` 已忽略 `tests/`、`pytest.ini`、`smoke_test.py`）。
  若日后补充测试：`pytest` + `pytest-asyncio`（`pytest.ini` 设 `asyncio_mode = auto`）；
  接口测试用 `httpx.AsyncClient` + `ASGITransport` 直连 ASGI，配合 `dependency_overrides` 覆盖 `get_session` 走内存 SQLite

### 3.2 journey-plan-app（前端 uni-app / Vue3）

**目录结构：**
```
journey-plan-app/
├── pages/
│   ├── index/           启动/占位页
│   ├── plans/           我的计划列表（筛选/搜索/卡片）
│   ├── plan-create/     制定计划 3 步流程（命名 → 基本信息+AI推荐勾选 → 每日计划）
│   ├── assistant/       旅行助手（AI 问答）
│   └── profile/         个人中心（头像/昵称/密码/切换账号/退出登录）
├── api/
│   ├── request.js       uni.request 封装：BaseURL / 鉴权头 / 统一错误处理
│   ├── auth.js / plan.js / day.js / assistant.js / user.js   ← 接口模块（预留后端）
├── components/          通用组件（AppIcon 图标 / 景点卡片 / 步骤条 / 路线列表 / 空态）
├── store/               Pinia（user / plan）
├── utils/               日期、金额格式化等
├── pages.json           tabBar 三页：我的计划 / 旅行助手 / 个人中心
├── uni.scss             设计令牌（柠檬黄主题）
└── static/              图标等资源（图标放 static/icons/，命名 `<图形>-<色值>.svg`）
```

**关键约定：**
- Vue 3 + `<script setup>` + Composition API
- **所有请求必须走 `api/request.js`**，禁止页面内直接 `uni.request`
- BaseURL 统一在 `request.js` 配置（默认 `http://127.0.0.1:8000`）
- 设计令牌（与 HTML 原型一致，勿改）：
  - primary `#FACC15`（亮柠檬，填充/渐变）· deep `#A16207`（深柠檬，浅底文字/图标）
  - secondary `#84CC16`（青柠）· deep2 `#4D7C0F` · accent `#38BDF8`（天蓝）· deep3 `#0284C7`
  - bg `#FFFBEB` · fg `#1C1917` · card `#FFFFFF` · muted `#FEF9C3` · mutedfg `#78716C` · bord `#FEF3C7`
- **aurora 渐变（柠檬→青柠→天蓝）上文字/描边必须深色 `#1C1917`，禁止黄底白字**
- 页面/区块显隐若用 class 控制，display 规则必须 `!important`（踩坑：Tailwind `flex` 覆盖 `.page{display:none}`）
- 图标用 SVG，禁止 emoji；交互元素加 `hover`/`focus-visible`/`cursor`
- **图标实现（2026-10-12 起）**：统一用 `components/AppIcon.vue`，不要各页自己写图标标签
  ```
  <AppIcon name="pin" color="#78716C" :size="36" />     <!-- size 数字 = rpx -->
  <AppIcon name="close" color="#78716C" size="16px" />  <!-- size 字符串 = 原样 -->
  ```
  - 资源在 `static/icons/<图形>-<6位小写色值>.svg`（如 `pin-78716c.svg`），**颜色直接烘焙进文件**：
    `<image>` 加载的 SVG 拿不到外层 CSS 的 `color`，`currentColor` 会失效；要换色就加一个
    同图形、新色值后缀的文件，组件无需改动
  - 需要跟随状态变色时用绑定：`:color="isSelected(a) ? '#1C1917' : '#78716C'"`
  - **禁止在页面模板里写内联 `<svg>`**：uni-app App 端视图层用 `document.createElement()`（而非
    `createElementNS`）创建元素，内联 `<svg>` 会变成 HTMLUnknownElement，浏览器画不出来 → 手机上
    图标空白；H5 端走标准 Vue 运行时（带 SVG 命名空间判断）所以正常。
    ⚠️ **该问题在 H5 / Edge headless 截图里完全看不出来**，只有 App 端才暴露 → 必须真机验证
- 制定计划 3 步流程按需求文档 3.4 实现：命名 → 基本信息 + AI 推荐卡片勾选 → 每日计划（天气/预算/时间可编辑、重新生成保留已选路线、路线可排序、计划完成可跳过未完成天）

---

## 四、工具与技能使用指南

| 技能 / 工具 | 用途 | 适用端 | 触发方式 |
|-------------|------|--------|----------|
| `spec-superflow` 全家桶（Claude Code 环境） | 规范驱动开发状态机：`workflow-start`（入口）、`need-explorer`、`spec-writer`、`contract-builder`、`build-executor`、`code-reviewer`、`release-archivist`、`spec-merger` | 全栈 | "使用 workflow-start 进行 X 的功能开发" |
| `ui-ux-pro-max` | 设计系统（风格/配色/字体/UX） | 前端 | "UI 设计"、"评审界面" |
| `frontend-dev` / `ui-styling` | 页面/组件实现 | 前端 | "实现页面"、"写组件" |
| `code-reviewer` | 代码审查 | 全栈 | "审查代码" |
| Edge/Chrome headless | UI 截图验证（`--headless=new --screenshot` + `#tab` 锚点） | 前端 | UI 改动后必做 |
| node DOM 桩冒烟 | 逻辑流程验证（新建/推荐/选择/完成等） | 前端 | 交付前 |
| python-docx | PRD 生成（`tools/gen_prd_v2.py`）与 docx→md 转换（`tools/docx2md.py`） | 文档 | PRD 变更时 |

---

## 五、文件编码规范

- **所有源码文件**：UTF-8 无 BOM（本项目工具链写入均默认此编码）
- 禁止用 PowerShell `Set-Content` 改写源码文件（会破坏 UTF-8 编码）
- 每个 wave 完成后检查中文是否正常（不能出现 `???`）：
  ```
  grep -rP '\?\?\?' --include='*.vue' --include='*.js' --include='*.py' --include='*.md' .
  ```

---

## 六、禁止事项

- 禁止硬编码密码、密钥、API Key（必须走环境变量 `.env`）
- 禁止绕过 `api/request.js` 直接 `uni.request`
- 禁止后端接口写 stub 冒充成功（未实现返回 501 + 明确提示）
- 禁止 aurora/黄底上使用白色文字（对比度不足）
- 禁止页面显隐 class 不带 `!important`（历史踩坑：`flex` 覆盖 `display:none`）
- 禁止用 emoji 替代图标（必须 SVG）
- 禁止在页面模板里写内联 `<svg>` 元素（App 端不渲染；统一用 `<AppIcon>`，见 3.2 图标实现）
- 禁止只更新 docx 或只更新 md（PRD 必须双份一致；源为 `tools/gen_prd_v2.py` → docx → `tools/docx2md.py` → md）
- 禁止修改 PRD 不升版本、不改修订记录
- 禁止用逗号分隔字段存多对多关联（必须独立关联表）
- 禁止在移动端使用桌面端组件库语义的组件（本项目无 Element UI，统一 uni-app 原生组件 + 自定义组件）
