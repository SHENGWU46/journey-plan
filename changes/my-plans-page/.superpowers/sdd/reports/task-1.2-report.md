# Task 1.2 实现报告：GET /plans 列表查询与草稿/非草稿语义 + seed 脚本

- 任务：wave-1-backend 串行批次第二任务（只做列表查询，POST/PATCH/DELETE 留给 1.3）
- 完成状态：DONE
- 提交：`2f1c9ef`（journey-plan-api，master 原地修改）
- 环境：Python 3.14.5 / fastapi 0.141.1 / SQLAlchemy 2.0.50 / pytest 8.4.2 / httpx 0.28.1

## 1. RED 失败证据

证明命令首跑（此时路由/序列化层尚未实现，GET /plans 404）：

```
> python -m pytest tests/test_plans_api.py -k list
collected 10 items
...
FAILED tests/test_plans_api.py::test_list_empty_returns_empty_items_and_total_zero - assert 404 == 200
FAILED tests/test_plans_api.py::test_list_orders_by_updated_at_desc - KeyError: 'items'
FAILED tests/test_plans_api.py::test_list_keyword_case_insensitive_and_chinese_substring
FAILED tests/test_plans_api.py::test_list_pagination_total_and_pages - KeyError: 'items'
FAILED tests/test_plans_api.py::test_list_invalid_pagination_params_rejected - assert 404 == 422
FAILED tests/test_plans_api.py::test_list_draft_plan_serialization - KeyError: 'items'
FAILED tests/test_plans_api.py::test_list_completed_plan_fields_and_total_days
FAILED tests/test_plans_api.py::test_list_total_days_same_day_return_is_one
FAILED tests/test_plans_api.py::test_list_total_days_null_when_dates_missing
FAILED tests/test_plans_api.py::test_list_generated_days_always_zero - KeyError: 'items'
======================== 10 failed, 1 warning in 0.72s ==========================
```

RED 成立：10 个列表测试全部因缺失实现而失败（404 / KeyError）。

## 2. 实现文件清单

| 文件 | 说明 |
|---|---|
| `app/schemas.py` | Pydantic v2 `PlanOut`（from_attributes；字段与 spec.md 计划对象 JSON 完全一致，snake_case，**无 status**；`total_days`/`generated_days` 为 `computed_field` 计算字段；created_at/updated_at 序列化为 `...T%H:%M:%SZ` 与 spec 示例一致）与 `PlanListOut`（items/total/page/page_size） |
| `app/routers/__init__.py` | 路由包初始化 |
| `app/routers/plans.py` | `GET /plans`：keyword（`Plan.name.ilike("%kw%")` 忽略大小写模糊匹配）、page(ge=1)/page_size(ge=1,le=100) 分页（offset/limit）、`order_by(updated_at.desc(), id.desc())` 稳定倒序、`count` 总数；无 status 参数 |
| `main.py` | 挂载 plans 路由（`include_router`），保持最小改动 |
| `scripts/seed.py` | 幂等演示数据脚本（每次运行清空 plans 表重建）：3 条非草稿（京都秋日漫游 10-02~10-09 / 大理环海慢游 08-15~08-19 / 北海道雪国之约 12-20~12-25，completed=True 含目的地/日期/人数/预算，日期覆盖过去与未来）+ 1 条草稿（成都美食探访，仅名称 completed=False 其余为空），风格参照原型 PLANS 数据 |
| `tests/test_plans_api.py` | 10 个列表接口测试（见 GREEN） |

## 3. GREEN 证据

证明命令：

```
> python -m pytest tests/test_plans_api.py -k list
collected 10 items
tests\test_plans_api.py ..........                                       [100%]
======================== 10 passed, 1 warning in 0.51s ==========================
```

覆盖点：空列表（items=[] total=0）；updated_at 倒序；keyword 忽略大小写（KYOTO 命中 Kyoto…）与中文子串（京都）；分页（total 正确、末页/空页、keyword+分页组合）；page/page_size 越界 422；草稿序列化（completed=false、destination/depart_date/return_date/people_count 全 null、total_budget 0、total_days null、generated_days 0、字段集合精确匹配 spec 且无 status）；非草稿完整字段 + total_days=7；同日往返 total_days=1；缺一个日期 total_days=null；generated_days 恒 0。

全量回归（REFACTOR 后）：

```
> python -m pytest
======================== 15 passed, 1 warning in 0.55s ==========================
```

（15 = 本任务 10 + task 1.1 模型测试 5）

端到端 sanity（真实默认 engine + seed 库，非测试覆盖）：`python scripts/seed.py` 写入 4 条（重复运行验证幂等：清 4 写 4，id 1-4）；TestClient 请求 `/plans` 返回 4 条按 id 倒序，草稿 JSON 全 null、`total_days` 7/5/4/null，`keyword=京都` 命中，`page=2&page_size=3` 返回 total=4 + 1 条。时间戳输出 `2026-08-28T09:03:27Z` 与 spec 示例格式一致。

## 4. Commit

```
2f1c9ef
feat(plan): GET /plans 列表查询与 seed 脚本（task 1.2）
```

6 files changed, 475 insertions。`README.md` 的既有未提交改动仍保持未纳入；`journey_plan.db`/`__pycache__` 等已被 .gitignore 忽略（seed 产出的开发库文件不会入库）。

## 5. 自审：契约符合性逐项核对

| 契约项 | 实现 | 证据 |
|---|---|---|
| GET /plans 仅 keyword/page/page_size 参数，无 status 参数（决策 2，产品决策） | 路由仅三个 Query 参数 | router 签名 + 测试字段断言 `"status" not in plan` |
| 响应结构 `{"items": [...], "total": N, "page": P, "page_size": S}` | `PlanListOut` 精确四字段 | test_list_empty 整体相等断言 |
| 计划对象 snake_case 字段与 spec 示例一致（id/user_id/name/destination/depart_date/return_date/people_count/completed/total_budget/total_days/generated_days/created_at/updated_at） | `PlanOut` 13 字段集合精确匹配，无多余/缺失 | `set(plan) == EXPECTED_PLAN_FIELDS` |
| keyword 忽略大小写模糊匹配（决策 3 服务端执行） | `Plan.name.ilike("%kw%")`；SQLite 原生 LIKE 对 ASCII 不敏感，MySQL 由 ilike 生成 lower() 比较 | KYOTO→Kyoto、京都 子串、无命中 total=0 三个断言 |
| updated_at 倒序（spec「默认排序」） | `order_by(Plan.updated_at.desc(), Plan.id.desc())`（id 作稳定次序键） | test_list_orders_by_updated_at_desc |
| 分页 page>=1、1<=page_size<=100 | Query(ge=1 / ge=1, le=100)，offset/limit | 越界 422 测试 + 末页/空页测试 |
| total 为过滤后总数（不受分页偏移影响） | 过滤条件内 `count()` | page=4 空页 total 仍为 5 |
| 草稿语义：completed=false；destination/depart_date/return_date/people_count 为 null；total_budget 0（决策 2/8） | 仅名称建行天然为默认值；序列化直接透出 | test_list_draft_plan_serialization 逐字段断言 |
| total_days：含首尾日历日派生，日期缺失为 null（决策 9） | 计算字段；同日期=1；缺任一日为 null。**口径见备注 1** | 京都→7、同日→1、缺 return_date→null |
| generated_days 恒 0（决策 12） | `computed_field` 恒 0 | 草稿/非草稿两条断言 |
| 时间字段输出格式对齐 spec 示例 `...T12:00:00Z` | `field_serializer` 输出 `%Y-%m-%dT%H:%M:%SZ`（DB 存无时区 UTC，加 Z 标记） | ISO_Z_RE 断言 + 端到端输出 |
| 不实现 POST/PATCH/DELETE（留给 1.3） | 本提交无写接口 | git diff 仅含 GET 路由 |
| seed 脚本：3 条非草稿（日期覆盖过去与未来）+ 1 条草稿（仅名称），可重复运行 | `scripts/seed.py` 清空重建幂等；风格参照原型 PLANS | 运行两遍输出一致（清 4 写 4） |

## 6. 备注 / 合理决定（按任务指示未停下询问）

1. **total_days 口径冲突已按 spec 示例与任务指令解决**：design.md 决策 9 公式字面「返回−出发+1」对 2026-10-02~10-09 得 8，但 spec.md 计划对象示例与原型数据均为 `total_days: 7`（原型 dayCount 函数自身对京都数据也会得 8，原型内部即不一致），任务指令亦明确「2026-10-02~2026-10-09 → 7」。取 spec 示例 + 任务指令口径：`max(1, (return_date - depart_date).days)`（日期差，至少 1 天）——京都→7、同日→1、缺失→null 三条指令样例全部满足；代码内注释与本文档均已记录差异。若后续验收坚持「返回−出发+1」，仅需改 schemas.py 一行并同步测试断言（spec.md 示例 JSON 需一并修正）。
2. **created_at/updated_at 加 Z 后缀**：task 1.1 备注将输出格式责任留给序列化层；DB 存无时区 UTC，输出带 Z 使前端 `new Date()` 按 UTC 解析（否则按本地时区误读 8 小时）。
3. **排序稳定键**：updated_at 相同（seed 同批写入）时按 id 倒序兜底，保证分页跨页不重不漏。
4. **测试线程问题**：TestClient 在独立线程处理请求，内存 SQLite 默认禁跨线程，fixture 采用 `StaticPool + check_same_thread=False` 固定单连接（首跑实测 9 failed 的 ProgrammingError 后修复）。
5. **测试命名**：全部用例函数以 `list` 为前缀，保证证明命令 `-k list` 恰好选中本任务全部 10 个测试。
6. **seed 控制台输出**：`sys.stdout.reconfigure(utf-8)` 避免 Windows GBK 控制台对字符编码报错（实测 `¥` 曾触发 UnicodeEncodeError，改用「预算 N」文案并强制 UTF-8）。
7. **keyword 不做转义/去空格**：契约未定义；空串 keyword 等效无过滤，`%`/`_` 通配语义按 SQL 原生行为（MVP 可接受，报告留痕）。
8. 未改动 `.superpowers/sdd/` 与 `changes/` 规划产物；只读目录规范遵守。

## 7. 修复记录（2026-08-28，执行计划修订 revision 2）

### 修复原因

执行计划修订确认 total_days 采用「含首尾」口径：design.md 决策 9 公式字面「返回−出发+1」，与 PRD 场景一「Agent 生成 8 天每日计划」一致；spec.md 计划对象示例已由 `total_days: 7` 修正为 `8`（京都 2026-10-02~10-09）。上一实现（见备注 1）按 spec 示例采用的「晚数口径」`max(1, 日期差)`（京都→7）作废，现按「返回日期 − 出发日期 + 1」计算：京都→8、同日往返→1、日期缺失→null 不变。

### 变更文件

| 文件 | 变更 |
|---|---|
| `app/schemas.py` | `total_days` 计算由 `max(1, (return_date - depart_date).days)` 改为 `(return_date - depart_date).days + 1`；同步更新类注释与口径注释（删除原「与决策 9 冲突」说明） |
| `tests/test_plans_api.py` | 期望值 `total_days == 7` → `8`（2026-10-02~10-09）；同日往返 = 1、缺日期 = null 断言不变 |

### RED 证据

仅改测试期望（7→8）、实现未动（仍返回晚数 7）时：

```
> python -m pytest
FAILED tests/test_plans_api.py::test_list_completed_plan_fields_and_total_days - assert 7 == 8
=================== 1 failed, 14 passed, 1 warning in 0.78s ===================
```

同日往返（0+1=1 与 max(1,0)=1 同值）与缺日期→null 两条边界用例在 RED 阶段即通过，说明新公式对这两个契约点不回归。

### GREEN 证据

实现改为「返回−出发+1」后全量回归：

```
> python -m pytest
======================== 15 passed, 1 warning in 0.58s ==========================
```

### 修复 Commit

```
ef9946f
fix(plan): total_days 按含首尾口径计算（返回-出发+1）
```

2 files changed, 6 insertions(+), 8 deletions(-)；`README.md` 的既有未提交改动仍保持未纳入。
