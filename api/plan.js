// 计划接口（对应 changes/my-plans-page/specs/plan-api/spec.md）
//
//   GET    /plans?keyword=&page=&page_size=  → { items, total, page, page_size }
//   POST   /plans          { name }          → 201，创建草稿计划
//   PATCH  /plans/{id}     { name }          → 200，改名
//   DELETE /plans/{id}                       → 204，物理删除
//
// 字段约定（snake_case，与后端 PlanOut 一致）：
//   id / user_id / name / destination / depart_date / return_date / people_count /
//   completed / total_budget / total_days / generated_days / created_at / updated_at
// 草稿语义：completed=false 即草稿，destination/日期/people_count 为 null，total_budget 为 0。

import { apiGet, apiPost, apiPut, apiPatch, apiDel } from './request.js'

/**
 * 计划列表（关键字搜索 + 分页，按 updated_at 倒序）
 * @param {Object} [params] { keyword, page, page_size }
 * @returns {Promise<{items: Array, total: number, page: number, page_size: number}>}
 */
export function listPlans(params = {}) {
  return apiGet('/plans', {
    keyword: params.keyword || undefined,
    page: params.page || 1,
    page_size: params.page_size || 20
  })
}

/**
 * 创建草稿计划
 * @param {Object} payload { name }，名称去首尾空格后须为 1-20 字符，否则后端返回 422
 * @returns {Promise<Object>} 新建的计划对象
 */
export function createPlan(payload) {
  return apiPost('/plans', { name: payload.name })
}

/**
 * 修改计划名称
 * @param {number|string} id
 * @param {Object} payload { name }
 * @returns {Promise<Object>} 更新后的计划对象
 */
export function renamePlan(id, payload) {
  return apiPatch('/plans/' + id, { name: payload.name })
}

/**
 * 物理删除计划（MVP 无回收站）
 * @param {number|string} id
 * @returns {Promise<Object>} { success: true }
 */
export function deletePlan(id) {
  return apiDel('/plans/' + id)
}

/**
 * 更新计划基本信息（目的地/日期/人数/预算/天数/完成态等）。
 * 对应后端 PATCH /plans/{id}（app/routers/plans.py）：支持多字段部分更新，
 * 未提供字段保持原值；total_days 为前端派生，后端忽略。
 * @param {number|string} id
 * @param {Object} payload 任意可更新字段
 * @returns {Promise<Object>} 更新后的计划对象
 */
export function updatePlan(id, payload) {
  return apiPatch('/plans/' + id, payload)
}

/**
 * 获取单个计划详情（对应后端 GET /plans/{id}，含 total_days 等派生字段）。
 * @param {number|string} id
 * @returns {Promise<Object>}
 */
export function getPlan(id) {
  return apiGet('/plans/' + id)
}

/**
 * 生成某日计划（agent 接口）。
 * 后端：POST /plans/{id}/days
 *
 * 入参：date 必填；tour_time / daily_budget 可选。
 *      第一步填的目的地/往返时间/同行人数/总预算由服务端按 plan_id 从计划本体读取
 *      后注入 agent，不在此传递，避免客户端篡改计划级事实。
 *
 * 返回：{ date, weather, attractions: [{ name, type, suggested_duration,
 *        budget_per_person, description }] }
 *
 * @param {number|string} id 计划 id
 * @param {{date: string, tour_time?: string, daily_budget?: number}} payload
 * @returns {Promise<Object>}
 */
export function generateDailyPlans(id, payload) {
  return apiPost('/plans/' + id + '/days', payload)
}

/**
 * 获取某计划下已保存的每日计划列表（按天序号升序）。
 * 后端：GET /plans/{id}/days → { items, total }
 * @param {number|string} id
 * @returns {Promise<{items: Array, total: number}>}
 */
export function getDailyPlans(id) {
  return apiGet('/plans/' + id + '/days')
}

/**
 * 新增或更新某天的计划（按 plan_id + day_index 幂等 upsert）。
 * 后端：PUT /plans/{id}/days/{dayIndex}
 *
 * @param {number|string} id 计划 id
 * @param {number} dayIndex 第几天，从 1 开始
 * @param {{date: string, weather?: string, tour_time?: string,
 *          daily_budget?: number|null, attractions?: Array}} payload
 * @returns {Promise<Object>} 保存后的单日计划对象
 */
export function saveDailyPlan(id, dayIndex, payload) {
  return apiPut('/plans/' + id + '/days/' + dayIndex, payload)
}
