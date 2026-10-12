# Task 1.3 实现报告：POST/PATCH/DELETE /plans 与开发 CORS

- 任务：wave-1-backend 串行批次第三任务（草稿创建、改名、删除 + 决策 11 开发 CORS）
- 完成状态：DONE
- 提交：`434d972`（journey-plan-api，master 原地修改）
- 环境：Python 3.14.5 / fastapi 0.141.1 / SQLAlchemy 2.0.50 / pytest 8.4.2 / starlette 1.3.1

## 1. RED 失败证据

在 `tests/test_plans_api.py` 追加 19 个用例（POST/PATCH/DELETE + CORS）后首跑
（此时写接口与 CORS 中间件尚未实现）：

```
> python -m pytest -q
FAILED tests/test_plans_api.py::test_post_creates_draft_plan - assert 405 == 201
FAILED tests/test_plans_api.py::test_post_rejects_invalid_names_and_creates_nothing[...]
  （5 个参数化："" / "   " / "甲" / "a"*21 / 首尾带空格的 21 字符）
FAILED tests/test_plans_api.py::test_post_accepts_name_length_boundaries - as...
FAILED tests/test_plans_api.py::test_patch_renames_plan_and_bumps_updated_at
FAILED tests/test_plans_api.py::test_patch_rejects_invalid_name_and_keeps_original[...]
  （4 个参数化）
FAILED tests/test_plans_api.py::test_delete_removes_plan_physically - assert ...
FAILED tests/test_plans_api.py::test_cors_preflight_allows_local_dev_origins[localhost:5173]
FAILED tests/test_plans_api.py::test_cors_preflight_allows_local_dev_origins[127.0.0.1:8080]
FAILED tests/test_plans_api.py::test_cors_simple_request_carries_allow_origin
======================== 16 failed, 18 passed, 1 warning in 0.97s ==========================
```

RED 成立：16 个新用例因方法未实现（405）或无 CORS 头而失败。另有 3 个新用例
在 RED 阶段「侥幸通过」（未实现时路径不匹配返回 404、无中间件时无 CORS 头），
GREEN 后改由真实实现路径验证，断言语义不变——见备注 3。

## 2. 实现文件清单

| 文件 | 说明 |
|---|---|
| `app/schemas.py` | 新增 `_PlanNameValidated`（私有基类）：`name` 字段 `field_validator` 去除首尾空格并校验 2-20 字符，非法抛 ValueError → FastAPI 422，合法返回已去空格值；`PlanIn`（POST 请求体）与 `PlanPatch`（PATCH 请求体）继承复用同一校验，避免重复 |
| `app/routers/plans.py` | 新增三路由：`POST /plans`（201 + `PlanOut`，仅名称建行，completed=false 等字段由模型默认值落地，`session.refresh` 返回完整对象）；`PATCH /plans/{id}`（200，仅更新 name，updated_at 由模型 `onupdate=_utcnow` 自动刷新；不存在 404）；`DELETE /plans/{id}`（204 物理删除；不存在 404）。404 用 `HTTPException(404, "计划不存在")` |
| `main.py` | `CORSMiddleware`：`allow_origin_regex=^http://(localhost\|127\.0\.0\.1)(:\d+)?$`，`allow_credentials=False`、`allow_methods=["*"]`、`allow_headers=["*"]`（决策 11，实现口径见备注 1） |
| `tests/test_plans_api.py` | 追加 19 个用例：POST 合法创建（201/去空格/completed false/null 字段/budget 0/total_days null/generated_days 0/列表立即可见）；POST 非法 5 例参数化（422 且 total=0 不创建）；2/20 字符边界；PATCH 合法（200/新名称/updated_at 变化/其余字段不变/列表立即可见）；PATCH 非法 4 例参数化（422 且原名不变）；PATCH 404；DELETE 成功（204/列表清空/DB 行 `session.get` 为 None 证明物理删除）；DELETE 404；CORS 预检本地来源 2 例、非预检简单请求、非本地来源拒绝 |

## 3. GREEN 证据

证明命令：

```
> python -m pytest tests/test_plans_api.py -q
======================== 29 passed, 1 warning in 0.76s ==========================
```

（29 = 本任务 19 + task 1.2 列表 10）

全量回归（REFACTOR 后）：

```
> python -m pytest -q
======================== 34 passed, 1 warning in 0.74s ==========================
```

（34 = 19 + 10 + task 1.1 模型测试 5；唯一 warning 为 fastapi testclient 的
httpx 弃用提示，1.2 已有，非本次引入）

## 4. Commit

```
434d972
feat(plan): POST/PATCH/DELETE /plans 与开发 CORS（task 1.3）
```

4 files changed, 257 insertions(+), 11 deletions(-)。`README.md` 的既有未提交
改动仍保持未纳入。

## 5. 自审：契约符合性逐项核对

| 契约项 | 实现 | 证据 |
|---|---|---|
| POST /plans 合法名称返回 201 与完整计划对象 | `status_code=201, response_model=PlanOut` | test_post_creates_draft_plan（201 + 字段集合 == EXPECTED_PLAN_FIELDS） |
| 名称去首尾空格后 2-20 字符校验（非法 422 且不创建） | `field_validator` strip + 长度校验 → Pydantic 422；校验通过后存储即去空格值 | test_post_rejects_invalid_names_and_creates_nothing（5 例 422 + total=0）；空名/仅空格/1 字符/21 字符（含首尾空格干扰）全覆盖 |
| 边界：恰好 2 与 20 字符合法 | 校验区间 `2 <= len <= 20` | test_post_accepts_name_length_boundaries |
| POST 创建 completed=false 草稿，destination/depart_date/return_date/people_count 为 null、total_budget 0、generated_days 0 | `Plan(name=...)` 仅名称建行，模型默认值（completed=False、total_budget=0、user_id=1、时间默认 _utcnow）落地；generated_days 由 PlanOut computed_field 恒 0 | test_post_creates_draft_plan 逐字段断言 |
| PATCH 合法：200、新名称生效、updated_at 随之变化 | `plan.name = payload.name` + commit；updated_at `onupdate=_utcnow` 自动刷新；`session.refresh` 确保返回最新值 | test_patch_renames_plan_and_bumps_updated_at（旧 updated_at 2026-08-01T09:00:00Z → 变化断言；列表立即可见新名称） |
| PATCH 仅更新 name（其余字段不变） | 路由只赋值 `plan.name` | test_patch_renames_plan_and_bumps_updated_at 断言 completed 仍为 false |
| PATCH 非法 422 且名称不变 | 同 POST 校验（PlanPatch 继承 _PlanNameValidated） | test_patch_rejects_invalid_name_and_keeps_original（4 例 422 后列表仍为「原名」） |
| PATCH 不存在 404 | `session.get` 为 None → `HTTPException(404)` | test_patch_not_found_returns_404 |
| DELETE 成功 204 且列表不再返回 | `session.delete` + commit，`status_code=204` | test_delete_removes_plan_physically（204 + GET items=[] total=0 + `session.get(Plan, 1) is None` 证明物理删除，MVP 无回收站） |
| DELETE 不存在 404 | 同上 404 分支 | test_delete_not_found_returns_404 |
| 决策 11：开发期 CORS 放行 http://localhost:* 与 http://127.0.0.1:*（本地任意端口） | `allow_origin_regex` 精确实现「任意端口」语义（口径见备注 1） | test_cors_preflight_allows_local_dev_origins（localhost:5173 / 127.0.0.1:8080 预检 200 且回显 Origin）+ test_cors_simple_request_carries_allow_origin + test_cors_rejects_non_local_origin（evil.example.com 不带 Allow-Origin 头，实测 400） |
| 生产收紧为明确域名（决策 11「生产配置项已预留」） | 本次仅放行 localhost/127.0.0.1，其余 Origin 一律不放行 | test_cors_rejects_non_local_origin + regex 只匹配本地两主机名 |

## 6. 备注 / 合理决定（按任务指示未停下询问）

1. **CORS 实现口径**：任务指令字面为 `allow_origins=["http://localhost:*", "http://127.0.0.1:*"]`，
   但实测 starlette 1.3.1 `CORSMiddleware.is_allowed_origin` 对 `allow_origins` 做**精确字符串
   匹配**（不支持 `:*` 端口通配），字面条目永远匹配不上真实 Origin 头。故改用
   `allow_origin_regex=r"^http://(localhost|127\.0\.0\.1)(:\d+)?$"` 落实决策 11 的
   「本地任意端口」意图（已读中间件源码确认 fullmatch 语义）。正则含端口为可选（`:8000` 无端口
   亦放行）。若验收脚本直接断言字面 `allow_origins` 配置项，仅需把正则换回字面列表
   （行为上本地端口会被拒，与决策 11 意图不符）。
2. **PATCH 请求体**：spec「计划改名接口」只收新名称，`PlanPatch` 仅含 name 字段
   （必填），缺 name 或空请求体同样走 422。
3. **RED 阶段 3 个侥幸通过用例**：`test_patch_not_found_returns_404` /
   `test_delete_not_found_returns_404`（端点未实现时 FastAPI 对不匹配路径返回 404）、
   `test_cors_rejects_non_local_origin`（无中间件时响应无 CORS 头）。GREEN 后这些
   断言改由真实实现验证，语义一致，无弱化。
4. **404 细节**：与 1.2 的校验型 422 一致，404 统一 `detail="计划不存在"`；路由参数
   `plan_id: int` 非整数自动 422（FastAPI 内置，未另测）。
5. **204 响应**：decorator `status_code=204` + 显式返回 `Response(status_code=204)`，
   无响应体。
6. **updated_at 断言的可测性**：SQLite DateTime 秒级精度下，请求内两次 `_utcnow` 可能同秒，
   故 PATCH 测试插入时显式指定旧 updated_at（复用 1.2 的 `_add_plan` helper 的 updated_at 参数），
   断言「变化」而非「更大」。
7. 未改动 `.superpowers/sdd/` 与 `changes/` 规划产物（progress.md 等保持只读，
   由规划侧推进）；唯一落盘产物为本报告 `reports/task-1.3-report.md`。
