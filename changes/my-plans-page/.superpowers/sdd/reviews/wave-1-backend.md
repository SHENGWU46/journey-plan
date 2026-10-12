# Wave-1-backend 审查报告（任务 1.1 / 1.2 / 1.3）

- **Wave**：wave-1-backend（serial）
- **仓库**：`journey-plan-api`（base `73aa7fb` → head `434d972`）
- **审查日期**：2026-08-28
- **审查人**：code-review（wave gate）
- **Verdict**：**PASS**

---

## 1. 审查范围

- 规划产物（只读）：`changes/my-plans-page/tasks.md`、`specs/plan-api/spec.md`、`design.md`、`execution-contract.md`
- 实现者报告：`reports/task-1.1-report.md`、`task-1.2-report.md`（含第 7 节 total_days 修复记录）、`task-1.3-report.md`
- 代码 diff：`git diff 73aa7fb..434d972`，14 个文件 +971/−1 行
- 提交链（与报告声明一致，无额外杂入）：

```
434d972 feat(plan): POST/PATCH/DELETE /plans 与开发 CORS（task 1.3）
ef9946f fix(plan): total_days 按含首尾口径计算（返回-出发+1）
2f1c9ef feat(plan): GET /plans 列表查询与 seed 脚本（task 1.2）
8d18af7 feat(plan): 建立 app 骨架与 Plan 数据模型（task 1.1）
```

- 工作树状态：仅 `README.md` 有未提交改动（按计划忽略）；`.idea/` 未跟踪。diff 范围内无范围外文件。

## 2. 规格符合性逐项核对

### plan-api 规格（5 项 SHALL + 场景）

| # | SHALL / 场景 | 实现 | 证据 | 结论 |
|---|---|---|---|---|
| S1 | completed 布尔字段区分草稿/非草稿，false=草稿，无四态派生状态 | 模型 Boolean 列（default=False）；响应仅 13 字段无 status；GET 无 status 参数 | schemas.py `PlanOut`、routers/plans.py 签名、`test_list_draft_plan_serialization`（`"status" not in plan` + 字段集合精确相等） | 符合 |
| S2 | GET /plans 响应 `{items,total,page,page_size}`，计划对象 snake_case 与 spec 示例一致 | `PlanListOut` 精确四字段；`PlanOut` 13 字段集合与 spec 示例完全一致；`total_days`/`generated_days` 为 computed_field | `test_list_empty...`（整体相等断言）、`set(plan) == EXPECTED_PLAN_FIELDS` | 符合（输出键序为 pydantic 声明序 + computed 追加，与示例字面键序不同，RFC 8259 键序无语义，前端按字段名取值不受影响） |
| S2a | 关键字搜索：keyword=京都 忽略大小写模糊匹配 | `Plan.name.ilike(f"%{kw}%")`，服务端执行（决策 3）；SQLite 原生 LIKE ASCII 不敏感，ilike 在 MySQL 生成 lower() 比较 | `test_list_keyword_case_insensitive_and_chinese_substring`（KYOTO→Kyoto、京都→京都冬雪之旅、无命中 total=0） | 符合 |
| S2b | 分页返回：total/page/page_size、翻页对应数据 | `page`(ge=1)、`page_size`(ge=1,le=100)、offset/limit；total 为过滤后总数（不受偏移影响） | `test_list_pagination_total_and_pages`（末页 1 条、空页 items=[] 而 total=5、keyword+分页组合）、`test_list_invalid_pagination_params_rejected`（page=0/page_size=0/101 → 422） | 符合 |
| S2c | 默认排序：不带排序参数按更新时间倒序 | `order_by(Plan.updated_at.desc(), Plan.id.desc())` | `test_list_orders_by_updated_at_desc` | **符合，无违背**。id 仅作同秒时间戳下的稳定次序键（保证分页跨页不重不漏），主排序仍是 updated_at 倒序，不改变规格「默认排序」场景语义 |
| S3 | POST /plans：去首尾空格 2-20 字符校验，201 + 完整计划对象；非法 422 且不创建 | `_PlanNameValidated` field_validator（strip 后校验，返回已去空格值）；`Plan(name=...)` 仅名称建行，completed=false / user_id=1 / total_budget=0 由模型默认值落地，`session.refresh` 返回完整对象 | `test_post_creates_draft_plan`（201、名称去空格、全字段断言、列表立即可见）、`test_post_rejects_invalid_names_and_creates_nothing`（""/"   "/"甲"/21 字符/带空格 21 字符 → 422 且 total=0）、`test_post_accepts_name_length_boundaries`（2/20 边界 201） | 符合 |
| S4 | PATCH /plans/{id}：同校验，200 + 更新后对象，updated_at 随之变化；非法 422 名称不变；不存在 404 | 复用同一校验基类；仅更新 name（`plan.name = payload.name`），updated_at 由 `onupdate=_utcnow` 自动刷新；`session.get` 为 None → HTTPException 404 | `test_patch_renames_plan_and_bumps_updated_at`（200、新名称、updated_at 变化、completed 不变、列表立即可见）、`test_patch_rejects_invalid_name_and_keeps_original`（422 且原名不变）、`test_patch_not_found_returns_404` | 符合 |
| S5 | DELETE /plans/{id}：204 物理删除，删除后列表不再返回；不存在 404 | `session.delete` + commit，`status_code=204`；404 分支同上 | `test_delete_removes_plan_physically`（204 + GET total=0 + `session.get(Plan,1) is None` 证明物理删除）、`test_delete_not_found_returns_404` | 符合 |
| S-extra | 草稿序列化：destination/depart_date/return_date/people_count 为 null、total_budget 0、completed false | 模型可空列 + 默认值，序列化直接透出 | `test_list_draft_plan_serialization` 逐字段断言 | 符合 |
| S-extra | total_days 含首尾口径：返回−出发+1；同日=1；缺失=null | `(return_date - depart_date).days + 1`；任一日 None → null | `test_list_completed_plan_fields_and_total_days`（10-02~10-09 → 8，与修订后 spec 一致）、`test_list_total_days_same_day_return_is_one`（=1）、`test_list_total_days_null_when_dates_missing`（缺 return_date → null） | 符合（实现曾为「晚数口径」7，revision 2 修复为含首尾 8，RED/GREEN 证据完整，见报告第 7 节） |
| S-extra | generated_days 恒 0（决策 12） | computed_field 恒 0 | `test_list_generated_days_always_zero`（草稿/非草稿都断言） | 符合 |
| S-extra | 时间字段输出与 spec 示例一致（`2026-08-28T12:00:00Z`） | field_serializer `%Y-%m-%dT%H:%M:%SZ`（DB 存无时区 UTC） | `ISO_Z_RE` 断言 + 实测输出 `2026-08-28T09:21:38Z` | 符合 |
| S-extra | GET 无 status 参数（决策 2） | 路由仅 keyword/page/page_size 三个 Query | 签名 + 实测 `?status=active` 被忽略返回 200 | 符合 |

### 设计决策（1/2/3/7/8/9/10/11/12）

| 决策 | 实现 | 结论 |
|---|---|---|
| 1 SQLAlchemy 2.0 + DATABASE_URL 切换 | `config.get_database_url()`（默认 SQLite，env 切 MySQL）；Mapped/mapped_column/DeclarativeBase 全 2.0 风格 | 符合 |
| 2 仅 completed、无四态 | 模型无 status 列、路由无 status 参数、响应无 status 字段（grep 全仓确认仅 HTTP status 模块 import 与注释提及） | 符合 |
| 3 搜索服务端执行 | ilike 过滤（见 S2a） | 符合 |
| 7 user_id 默认 1 | `mapped_column(Integer, default=1)`，测试断言 | 符合 |
| 8 草稿可空 | destination/depart_date/return_date/people_count 均 nullable=True，测试逐字段断言 | 符合 |
| 9 日期无时区 | 列类型 `Date`，created/updated 存无时区 UTC datetime | 符合 |
| 10 版本锁定 | requirements.txt 5 个依赖均 `>=X,<X+1` 主版本区间；**唯一缺口：httpx 未声明（见发现 I-1）** | 基本符合 |
| 11 开发 CORS 本地任意端口 | `allow_origin_regex=^http://(localhost\|127\.0\.0\.1)(:\d+)?$` + allow_credentials=False | 符合，见下 |
| 12 generated_days 恒 0 | 见 S-extra | 符合 |

**CORS 决策 11 专项评估**：starlette 1.3.1 的 `allow_origins` 为精确字符串匹配（不支持 `:*` 端口通配），改用 `allow_origin_regex` 是实现「本地任意端口」意图的正确手段。实测覆盖矩阵：

```
http://localhost:5173        → 放行（dev:h5 默认端口）
http://127.0.0.1:8080        → 放行
http://localhost（无端口）     → 放行（正则端口可选，略宽于决策字面，可接受）
http://localhost:65535       → 放行（任意端口语义）
https://localhost:5173       → 拒绝（决策字面仅 http，dev 服务器为 http）
http://localhost.evil.com    → 拒绝（fullmatch 防后缀攻击）
http://127.0.0.1.evil.com    → 拒绝
http://user@localhost:5173   → 拒绝
```

不过度放行：仅两个本地主机名 + http scheme，hostile Origin 预检无 `Access-Control-Allow-Origin`（实测）。allow_methods/allow_headers 为 `["*"]` 属开发期常规姿态，且仅在 Origin 通过时反射头。决策 11 覆盖意图完整。

## 3. 代码质量

### TDD 证据（RED 是否真实）

| 任务 | RED 证据 | 判定 |
|---|---|---|
| 1.1 | `ModuleNotFoundError: No module named 'app'`（测试存在、实现缺失） | 真实 RED |
| 1.2 | 10 个列表测试全挂（404 / KeyError 'items'） | 真实 RED |
| 1.3 | 16 个新用例失败（405 / 无 CORS 头）；另有 3 个 404 路径/无头断言用例在 RED 阶段「侥幸通过」，报告如实披露且 GREEN 后改由真实实现路径验证 | 真实 RED + 诚实披露 |

### 测试可证伪性（非实现镜像）

- 排序测试用显式时间戳构造数据、断言名称顺序（行为断言，非实现复制）；
- 分页/空页/末页断言真实 HTTP 响应；删除测试用 `session.get` 证明 DB 行消失（物理删除的真实证明）；
- 字段集合断言基于 spec 常量 `EXPECTED_PLAN_FIELDS`，total_days 期望值为字面常量（8/1/None），不镜像计算式；
- 测试经 TestClient + dependency_overrides 走真实路由，`StaticPool + check_same_thread=False` 解决跨线程内存库问题（报告实测 9 failed 后修复，合理）。

### 结构与命名

- 包结构 `app/{config,database,models,schemas,routers}`、`tests/`、`scripts/seed.py`、`requirements.txt` 与执行合同 Wave-1 输出一致；
- 测试命名 `-k list` 可精确选中 1.2 全部用例，参数化命名清晰；
- 校验逻辑经 `_PlanNameValidated` 基类在 POST/PATCH 间复用，无重复。

### 其他

- SQLAlchemy 用法：2.0 风格正确（`session.get`/`select`/`scalar`）；seed.py 用旧版 `session.query(...)` 风格（可用但风格不一致，Minor）；
- 错误处理：404 统一 `detail="计划不存在"`，422 由 Pydantic 默认，无吞异常路径；
- seed 幂等性：**实测运行两遍输出完全一致（清 4 写 4，SQLite 空表复用 rowid，id 稳定 1-4）**；
- 无范围外代码：无 auth/登录、无 DayPlan 实体、无四态、路由仅 /plans。

## 4. 验证命令输出摘录

```
> python -m pytest                    # journey-plan-api 目录
collected 34 items
tests\test_models.py .....                                       [ 14%]
tests\test_plans_api.py .............................            [100%]
======================== 34 passed, 1 warning in 0.75s ========================
（唯一 warning：starlette 对 httpx 的弃用提示，1.2 已存在，非本次引入）

> python scripts/seed.py   （连续运行两遍，输出一致）
已清空旧数据 4 条，写入 4 条演示计划：
  [1] 京都秋日漫游 | 2026-10-02 ~ 2026-10-09 | 2人 | 预算 17400 | completed=True
  [2] 大理环海慢游 | 2026-08-15 ~ 2026-08-19 | 4人 | 预算 18400 | completed=True
  [3] 北海道雪国之约 | 2026-12-20 ~ 2026-12-25 | 2人 | 预算 26000 | completed=True
  [4] 成都美食探访 | 无日期 | None人 | 预算 0 | completed=False （草稿，仅名称）
（第二遍输出逐行一致，幂等成立）

> 实测探针（TestClient 直连真实 engine）
GET /plans?status=active&keyword=京都  → 200（status 参数被忽略，无四态筛选）
OPTIONS /plans Origin=http://localhost.evil.com → 无 Access-Control-Allow-Origin 头
GET /plans?page=2&page_size=1 → total=4，北海道 total_days=6（12-20~12-25，5+1=6 ✓）
```

## 5. 发现列表

### Critical（阻塞）

无。

### Important（质量隐患，不阻塞本 wave）

- **I-1：requirements.txt 未声明 httpx**。`fastapi.testclient` 的 TestClient 运行时必需 httpx（实测 fastapi Requires: annotated-doc/pydantic/starlette/typing-extensions/typing-inspection；starlette Requires: anyio——均不传递依赖 httpx）。全新环境按 requirements.txt 安装后 `python -m pytest` 会在导入测试文件时 `ModuleNotFoundError: No module named 'httpx'`。当前环境因手工装了 httpx 0.28.1 而全绿，但违背决策 10「可复现构建」。建议在 requirements.txt 补 `httpx>=0.27,<1`（wave-2 开始前一行即可）。

### Minor（建议）

- M-1：seed.py 使用旧版 `session.query()` API，与其余 2.0 风格不一致，建议改 `select()`/`delete()` 2.0 写法；
- M-2：keyword 未转义 `%`/`_`（SQL 通配符语义），报告已文档化；MVP 可接受，若未来搜索需求收紧（如用户输入 `%`）需补转义与测试；
- M-3：应用无 startup 建表（lifespan），裸跑 uvicorn 未先 seed 会报 no such table；seed.py 为文档化初始化路径，MVP 可接受，建议后续加 lifespan create_all；
- M-4：total_days 对 `return_date < depart_date` 无下限保护（可能得 ≤0）；本 wave 无日期输入 API 不可达，Step2 增加日期填写时需补校验；
- M-5：`test_models.py` 用 `time.sleep(0.02)` 制造时间差，可行但轻微脆弱，可考虑显式写入旧 updated_at（如 API 测试那样）；
- M-6：无显式回归测试覆盖「未知查询参数被忽略」与「hostile Origin（localhost.evil.com 后缀攻击）被拒」（后者已人工实测通过），可各补一条。

## 6. 总体结论

规格符合性：plan-api 规格 5 项 SHALL 及全部场景、设计决策 1/2/3/7/8/9/10/11/12 逐项核对全部符合（total_days 口径经 revision 2 修正后与修订版 spec 一致：京都 8 天含首尾；排序 id 稳定键不违背默认排序场景；CORS 正则精确实现「本地任意端口」且不过度放行）。代码质量：TDD RED 证据真实、测试行为可证伪、结构命名清晰、无范围外代码。验证：`python -m pytest` 34 passed；`python scripts/seed.py` 两遍幂等。唯一 Important 发现（httpx 未声明）不阻塞本 wave 功能与验收，建议 wave-2 前修复。

**Verdict：PASS**（wave-2-frontend-list 可以开始）
