# 能力规格：计划后端接口（列表查询 / 草稿创建 / 改名 / 删除）

## Purpose

「我的计划页」的数据能力：提供计划列表查询、草稿创建、改名与删除接口。计划仅以 `completed` 标志区分草稿/非草稿，不做四态状态派生（产品决策 2026-08-28，FR-PL-02 取消）。

## ADDED Requirements

### Requirement: 草稿与非草稿以 completed 标志区分

The system SHALL 以计划对象中的 `completed` 布尔字段表达草稿/非草稿：false=草稿（尚未进入后续流程），true=非草稿（已进入后续流程）；接口不再返回四态派生状态。

#### Scenario: 草稿字段语义

- **WHEN** 计划通过 Step1 命名创建
- **THEN** 响应中 completed 为 false（草稿）

#### Scenario: 非草稿字段语义

- **WHEN** 计划已进入后续流程（completed 为 true）
- **THEN** 响应中 completed 为 true，前端据此渲染非草稿卡片

### Requirement: 计划列表接口（GET /plans）

The system SHALL 提供 GET /plans 接口：支持名称关键字搜索、分页；返回按更新时间倒序排列的计划列表与总数。计划对象 JSON 字段命名与 PRD 5.3 数据字典一致（snake_case）：

```json
{
  "id": 1,
  "user_id": 1,
  "name": "京都秋日漫游",
  "destination": "日本 · 京都",
  "depart_date": "2026-10-02",
  "return_date": "2026-10-09",
  "people_count": 2,
  "completed": true,
  "total_budget": 17400,
  "total_days": 8,
  "generated_days": 5,
  "created_at": "2026-08-28T12:00:00Z",
  "updated_at": "2026-08-28T12:00:00Z"
}
```

列表响应结构：`{"items": [计划对象...], "total": 4, "page": 1, "page_size": 20}`；草稿计划中 destination/depart_date/return_date/people_count 为 null，total_budget 为 0，completed 为 false。

#### Scenario: 关键字搜索

- **WHEN** 客户端请求 `GET /plans?keyword=京都`
- **THEN** 返回名称包含「京都」（忽略大小写）的计划

#### Scenario: 分页返回

- **WHEN** 计划总数超过单页数量
- **THEN** 响应包含 total 总数与 page/page_size 分页字段，翻页返回对应页数据

#### Scenario: 默认排序

- **WHEN** 客户端不带排序参数请求列表
- **THEN** 计划按更新时间倒序排列

### Requirement: 草稿创建接口（POST /plans）

The system SHALL 提供 POST /plans 接口：接收计划名称，去除首尾空格后校验 2-20 字符，创建状态为草稿的计划并返回完整计划对象（201）。

#### Scenario: 合法创建

- **WHEN** 客户端提交合法名称（去空格后 2-20 字符）
- **THEN** 返回 201 与计划对象：名称已去空格、completed 为 false（草稿）、destination/depart_date/return_date/people_count 为 null、total_budget 为 0、generated_days 为 0

#### Scenario: 非法名称拒绝

- **WHEN** 客户端提交空名称、仅空格名称，或去空格后长度不在 2-20 字符
- **THEN** 返回 422 校验错误且不创建任何数据

### Requirement: 计划改名接口（PATCH /plans/{id}）

The system SHALL 提供 PATCH /plans/{id} 接口：接收新名称，校验规则同创建（去空格后 2-20 字符），校验通过后更新名称与更新时间并返回更新后的计划对象。

#### Scenario: 合法改名

- **WHEN** 客户端对存在的计划提交合法新名称
- **THEN** 返回 200 与更新后的计划对象，列表查询立即可见新名称

#### Scenario: 非法名称拒绝

- **WHEN** 客户端提交空名称、仅空格名称，或去空格后长度不在 2-20 字符
- **THEN** 返回 422 校验错误且名称不变

#### Scenario: 计划不存在

- **WHEN** 客户端对不存在的计划 id 发起改名
- **THEN** 返回 404 错误

### Requirement: 计划删除接口（DELETE /plans/{id}）

The system SHALL 提供 DELETE /plans/{id} 接口：物理删除计划（MVP 无回收站），删除后列表查询不再返回该计划。

#### Scenario: 删除成功

- **WHEN** 客户端删除存在的计划
- **THEN** 返回 204，随后 GET /plans 不再包含该计划

#### Scenario: 计划不存在

- **WHEN** 客户端对不存在的计划 id 发起删除
- **THEN** 返回 404 错误
