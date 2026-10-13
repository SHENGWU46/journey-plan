# Journey Plan · 智能旅行计划

> 从需求分析、交互原型、前后端实现，到 AI Agent、域名备案与线上部署的**完整个人实践项目**。
>
> 移动端 uni-app（Vue 3） · 后端 FastAPI · MySQL 8 · LangChain / LangGraph 驱动的 AI 行程规划

---

## 在线体验

| 入口 | 地址 | 说明 |
|---|---|---|
| **移动端 H5** | <https://app.journey-plan.cn> | 可直接注册试用。手机打开体验最佳；桌面浏览器按 `F12` → 切手机视口（375×812） |
| **接口文档** | <https://api.journey-plan.cn/docs> | Swagger UI，11 个接口可在线调试 |

> 全部走 HTTPS，域名已完成 **ICP 备案 + 公安联网备案**。演示环境，数据可能随时清空。

---

## 这是什么

输入目的地与出行日期，AI 帮你拆解出**每天的行程**：推荐当天景点、给出天气与预算建议，支持手动增删与排序，最后落库保存。另有基于知识库检索（RAG）的**旅行助手**问答。

区别于"调个接口套个壳"的练习项目，这里完整走完了：

- **需求 → 原型 → 接口契约 → 编码 → 验证** 的规范流程（过程产物见 [`changes/`](changes/)）
- **AI Agent 的工程化落地**：工具调用、RAG 向量库、中间件日志、失败可诊断
- **真正上线**：域名、ICP / 公安备案、HTTPS 证书、nginx 反向代理、systemd 常驻
- **移动端交付**：uni-app 一套代码，可出 H5，也可云打包成 Android APK

---

## 功能

| 模块 | 能力 |
|---|---|
| 账号 | 注册 / 登录（JWT，access + refresh 双 token） |
| 我的计划 | 列表、关键字搜索、草稿 / 已完成筛选、改名、删除 |
| 制定计划 | 分步流程：命名 → 基本信息（目的地 / 往返日期 / 人数 / 预算） |
| 单日计划 | 天气 / 预算 / 游玩时间可编辑；**AI 推荐当天景点**；路线增删与排序；落库保存 |
| 旅行助手 | **AI 问答**（RAG 知识库检索 + 天气 / 定位工具调用） |
| 个人中心 | 资料、修改密码、退出登录 |

移动端共 8 个页面：`index` `login` `register` `plans` `plan-new` `day-plan` `assistant` `profile`

---

## 架构

```
        ┌──────────────┐
        │  Android App │  uni-app 云打包
        │   / H5 页面  │
        └──────┬───────┘
               │ HTTPS
        ┌──────▼───────────────────────┐
        │ nginx  (443 TLS / 80 → 301)  │  腾讯云轻量服务器
        └──────┬───────────────────────┘
               │ 反向代理 → 127.0.0.1:8000
        ┌──────▼───────────────────────┐
        │ FastAPI + uvicorn            │  systemd 常驻
        │  routers → repository → ORM  │
        └───┬───────────────────┬──────┘
            │                   │
     ┌──────▼──────┐     ┌──────▼────────────────────┐
     │  MySQL 8.4  │     │ LangChain Agent (qwen-max)│
     │  SQLAlchemy │     │  ├─ Chroma 向量库（RAG）  │
     │  + Alembic  │     │  └─ 工具：天气 / 定位     │
     └─────────────┘     └───────────────────────────┘
```

**技术栈**

| 层 | 选型 |
|---|---|
| 前端 | uni-app（Vue 3 + `<script setup>`）、SCSS 设计令牌、自定义图标组件（SVG + `<image>`） |
| 后端 | FastAPI、SQLAlchemy 2.x（异步 aiomysql）、Alembic、Pydantic v2、JWT |
| 数据库 | MySQL 8.4（开发期可回落 SQLite） |
| AI | LangChain 1.x + LangGraph（`create_agent`）、DashScope `qwen-max`、Chroma 向量库 |
| 部署 | OpenCloudOS 9、nginx、systemd、Miniconda（Python 3.13）、腾讯云 SSL 证书 |

---

## 目录结构

```
journey-plan/
├── journey-plan-app/        移动端（uni-app）
│   ├── pages/               8 个页面
│   ├── components/          AppIcon / AppTabBar / PlanCard / StepIndicator …
│   ├── api/                 请求封装与接口模块（统一走 request.js）
│   ├── static/icons/        图标资源（<图形>-<色值>.svg）
│   └── uni.scss             设计令牌（柠檬黄主题）
├── journey-plan-api/        后端（FastAPI）
│   ├── app/                 routers / models / schemas / repository / services / core
│   ├── agents/              AI 子系统（模型工厂 / 工具 / RAG 向量库 / 中间件）
│   ├── alembic/             数据库迁移
│   └── main.py              应用入口
├── docs/                    需求分析文档 · 交互原型 · 截图
├── changes/                 规范驱动开发的过程产物（proposal / design / tasks / specs）
├── deploy/                  部署脚本与 nginx 配置
├── tools/                   PRD 的 docx ↔ md 同步脚本
├── AGENTS.md                开发约定与踩坑记录
└── README.md
```

---

## 快速开始

### 后端

```bash
cd journey-plan-api

# 1) 依赖（requirements.lock.txt 是与实际运行环境一致的精确版本）
python -m venv .venv && source .venv/bin/activate     # Windows: .venv\Scripts\activate
pip install -r requirements.lock.txt

# 2) 配置：填自己的值（.env 不入库）
cat > .env <<'EOF'
DATABASE_URL=mysql+aiomysql://root:你的密码@127.0.0.1:3306/journey-base?charset=utf8mb4
JWT_SECRET_KEY=换成一串随机字符串
DASHSCOPE_API_KEY=sk-你的阿里云百炼Key
EOF

# 3) 建表并启动
alembic upgrade head
uvicorn main:app --reload --port 8000
```

打开 <http://127.0.0.1:8000/docs> 即可看到全部 11 个接口并在线调试。

> AI 功能需要 `DASHSCOPE_API_KEY`（阿里云百炼）。不配也能启动，只有两个 AI 接口会返回 502。
>
> 知识库语料已随仓库提供（`agents/data/` 下 13 份 `XX旅游景点.txt`），但**向量库不进仓库**。
> 首次使用 AI 问答前先建一次索引：
>
> ```bash
> python -m agents.rag.vector_store     # 在 journey-plan-api/ 目录下执行
> ```
>
> 之后重复执行会按文件 MD5 自动跳过已入库的语料。

### 移动端

```bash
cd journey-plan-app
npm install
npm run dev:h5          # 浏览器调试（http://127.0.0.1:5173）
```

打包 Android App：用 **HBuilderX** 打开项目 → 发行 → 原生 App 云打包。
接口地址在 `api/request.js` 中按环境切换：开发连本机、正式连 `https://api.journey-plan.cn`。

---

## 接口一览

完整契约见 [`journey-plan-api/README.md`](journey-plan-api/README.md)，或直接看线上 Swagger：<https://api.journey-plan.cn/docs>

| 方法 | 路径 | 说明 |
|---|---|---|
| POST | `/auth/register` · `/auth/login` · `/auth/refresh` | 注册 / 登录 / 刷新 token |
| GET · POST | `/plans` | 计划列表（搜索 + 分页） / 新建草稿 |
| GET · PATCH · DELETE | `/plans/{plan_id}` | 详情 / 部分更新 / 删除 |
| POST · GET | `/plans/{plan_id}/days` | 🤖 AI 生成某日计划 / 已保存的每日计划 |
| PUT | `/plans/{plan_id}/days/{day_index}` | 幂等保存某天计划 |
| GET · PATCH · PATCH | `/user/me` · `/user/profile` · `/user/password` | 资料与改密 |
| POST | `/assistant/ask` | 🤖 旅行助手问答 |

约定：除 `/auth/*` 外均需 `Authorization: Bearer <token>`；业务错误统一 `{"detail": "..."}`；越权访问他人资源返回 404（不暴露资源是否存在）。

---

## 部署

[`deploy/`](deploy/) 下有可直接复用的脚本与配置，对应的操作已在腾讯云 OpenCloudOS 9 上跑通：

- `deploy-api.sh` —— 装 MySQL、建库导入、建 Python 环境、写 systemd、配 nginx 反代
- `deploy-h5.sh` —— 部署 H5 静态站、写 nginx 配置，并**自动识别证书**启用 HTTPS
- `enable-https.sh` —— 部署证书、配置 443 与 80 跳转
- `nginx/` —— 三个站点的 nginx 配置

线上共三个站点，各走独立 `server` 块：

| 域名 | 用途 | 说明 |
|---|---|---|
| `app.journey-plan.cn` | 移动端 H5 | 静态托管到 `/var/www/h5`，独立 DV 证书（443 + 80 跳转） |
| `api.journey-plan.cn` | 后端接口 | 反向代理 → `127.0.0.1:8000`，独立 DV 证书（443 + 80 跳转） |
| `www.journey-plan.cn` | 网站首页（备案信息展示） | 底部悬挂 ICP 备案号与公安联网备案号，均链接至官方查询站 |

> 免费 DV 证书是**单域名**的，`api` 与 `app` 各需一张（可用 `openssl x509 -checkhost` 校验覆盖范围）；
> 有效期 90 天，到期需重新申请并部署。

配套完成的还有：域名解析、**ICP 备案**与**公安联网备案**、安全组最小化放行（只开 80 / 443，**不暴露 8000 与 3306**）、数据库仅监听本机。

---

## 工程实践

- **规范驱动开发**：`changes/` 保留了 proposal → design → tasks → execution-contract → specs 的完整过程，而不是"写完补文档"。
- **失败要看得见**：AI 调用失败时前端明确提示原因，后端记录完整 traceback——**不做静默降级**（早期版本失败时会返回写死的 mock 回复，演示时无法分辨真假，已移除）。
- **配置外部化**：数据库地址、JWT 密钥、模型 Key 全部走环境变量；`.env` 不入库。
- **约定固化**：[`AGENTS.md`](AGENTS.md) 记录了目录规范、编码约定与踩过的坑（例如"App 端不渲染内联 `<svg>`，必须用静态 SVG + `<image>`"）。

---

## License

[MIT](LICENSE)
