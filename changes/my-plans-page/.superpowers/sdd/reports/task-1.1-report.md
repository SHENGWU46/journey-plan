# Task 1.1 实现报告：后端骨架与 Plan 数据模型

- 任务：wave-1-backend 串行批次首任务
- 完成状态：DONE
- 提交：`8d18af794cdbc23391dc5b80d7128124747c189e`（journey-plan-api，master 原地修改）
- 环境：Python 3.14.5 / pytest 8.4.2（本次新增安装）/ SQLAlchemy 2.0.50 / fastapi 0.141.1

## 1. RED 失败证据

首跑 `python -m pytest tests/test_models.py`（此时尚未创建 `app/` 包）：

```
_____ ERROR collecting JourneyPlan/journey-plan-api/tests/test_models.py ______
ImportError while importing test module '...\tests\test_models.py'.
tests\test_models.py:14: in <module>
    from app.database import Base
E   ModuleNotFoundError: No module named 'app'
=========================== short test summary info ===========================
ERROR tests\test_models.py
!!!!!!!!!!!!!!!!!!! Interrupted: 1 error during collection !!!!!!!!!!!!!!!!!!!!
1 error in 0.77s
```

RED 成立：测试已存在且因缺失实现而失败。

## 2. 实现文件清单

| 文件 | 说明 |
|---|---|
| `app/__init__.py` | 应用包初始化 |
| `app/config.py` | `DATABASE_URL` 环境变量读取，默认 `sqlite:///./journey_plan.db`（决策 1 SQLite/MySQL 切换） |
| `app/database.py` | SQLAlchemy 2.0 `engine`/`SessionLocal`/`Base(DeclarativeBase)`/`get_session()` 封装（惰性连接，无测试文件写入） |
| `app/models.py` | `Plan` 模型（plans 表），见自审逐项核对 |
| `tests/test_models.py` | 5 个模型测试：表结构与字段集合、可空/类型、草稿默认值、完整字段持久化、updated_at 自动刷新 |
| `requirements.txt` | 主版本锁定（决策 10）：fastapi>=0.115,<1 / uvicorn>=0.30,<1 / SQLAlchemy>=2.0,<3 / pydantic>=2,<3 / pytest>=8,<9 |
| `pyproject.toml` | **额外新增**：使 pytest rootdir 固定为本项目（原 rootdir 被父目录 `Desktop\agent\pyproject.toml` 捕获，裸跑 `python -m pytest` 收集范围不可控）；`testpaths=["tests"]` |
| `.gitignore` | **额外新增**：忽略 `__pycache__/`、`.pytest_cache/`、`.idea/`、`journey_plan.db`（开发库文件） |

`main.py` 保持不变（可正常导入，`app:app` 结构后续挂载路由时使用）。

## 3. GREEN 证据

模型测试：

```
tests/test_models.py::test_plans_table_exists_with_all_columns PASSED    [ 20%]
tests/test_models.py::test_column_nullability_and_types PASSED           [ 40%]
tests/test_models.py::test_draft_plan_defaults PASSED                    [ 60%]
tests/test_models.py::test_full_plan_fields_persist PASSED               [ 80%]
tests/test_models.py::test_updated_at_refreshes_on_update PASSED         [100%]
============================== 5 passed in 0.38s ==============================
```

全量（证明命令）：

```
> cd journey-plan-api && python -m pytest
collected 5 items
tests\test_models.py .....                                               [100%]
============================== 5 passed in 0.33s ==============================
```

补充 sanity check（手动执行）：`DATABASE_URL=sqlite:///:memory:` 环境变量切换生效（engine url 跟随）；`main.py` 导入正常；`Base.metadata.create_all` 建表成功。

## 4. Commit

```
8d18af794cdbc23391dc5b80d7128124747c189e
feat(plan): 建立 app 骨架与 Plan 数据模型（task 1.1）
```

8 files changed, 252 insertions。暂存范围仅本任务文件；`README.md` 的既有未提交改动与 `.idea/` 保持未跟踪、未纳入本次提交。

## 5. 自审：契约符合性逐项核对

| 契约项 | 实现 | 证据 |
|---|---|---|
| 字段：id/user_id/name/destination/depart_date/return_date/people_count/completed/total_budget/created_at/updated_at | plans 表 11 列，集合精确一致（`set(columns) == EXPECTED_COLUMNS`） | test_plans_table_exists_with_all_columns |
| name 非空 | `nullable=False`，String(50) | test_column_nullability_and_types |
| destination/depart_date/return_date/people_count 可空（决策 8） | 均 `nullable=True` | 同上（逐字段断言） |
| depart_date/return_date 无时区 Date（决策 9） | `Date` 类型 | 同上（isinstance Date） |
| completed 默认 False（草稿） | `default=False`，Boolean；仅命名建行后为 False | test_draft_plan_defaults |
| total_budget 默认 0 | `default=0`，Integer | 同上 |
| user_id 默认 1（决策 7，MVP 单用户） | `default=1` | 同上 |
| updated_at 更新时自动刷新 | `onupdate=_utcnow`；改名后 updated_at 严格大于原值、created_at 不变 | test_updated_at_refreshes_on_update |
| DATABASE_URL 支持 SQLite/MySQL 切换（决策 1） | `os.environ.get("DATABASE_URL", "sqlite:///./journey_plan.db")`；engine 惰性创建 | config.py + sanity check |
| 模型可导入、建表成功 | `Base.metadata.create_all(engine)` 成功，plans 表存在 | 全部测试 + sanity check |
| 不做 API 路由、不建四态状态列 | 模型仅 completed 布尔字段，无 status 列；无路由文件 | git diff 可见 |
| requirements.txt 主版本锁定（决策 10） | 5 个依赖全部 `>=X,<X+1` 区间 | requirements.txt |

## 6. 备注 / 合理决定（按任务指示未停下询问）

1. **时间字段时区**：created_at/updated_at 存无时区 UTC（`datetime.now(timezone.utc).replace(tzinfo=None)`），避免 Python 3.12+ 对 `datetime.utcnow` 的弃用告警，SQLite/MySQL 均兼容；spec 中 `"2026-08-28T12:00:00Z"` 的输出格式由序列化层（任务 1.2）负责。
2. **name 长度**：DB 层 String(50)，2-20 字符校验属 API 层职责（FR-WZ-01，任务 1.3 实现），模型层不重复约束。
3. **total_budget 类型**：按 spec 示例整数值取 Integer（非 Float），草稿默认 0。
4. **额外新增 pyproject.toml / .gitignore**：前者必要性见文件清单说明（rootdir 捕获问题已实测确认）；后者为 Python 项目常规卫生，防止 `.pyc`/开发库文件被提交（首次 add 时确实误暂存了 `__pycache__/*.pyc`，已通过 .gitignore 修正）。
5. **测试隔离**：每个测试自建独立内存 SQLite engine（fixture 内 create_all + dispose），不触碰 `app.database` 的默认 engine，开发库文件不会被测试写入。
6. **SQLite 反射差异**：inspector 对 primary_key 返回 `1` 而非 `True`，测试按真值断言（非模型问题）。
