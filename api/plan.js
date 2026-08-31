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

import { apiGet, apiPost, apiPatch, apiDel } from './request.js'

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
 * @param {Object} payload { name }，名称去首尾空格后须为 2-20 字符，否则后端返回 422
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
