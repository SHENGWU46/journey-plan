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

/**
 * 更新计划基本信息（目的地/日期/人数/预算/天数/完成态等）。
 * TODO(backend): 后端当前 PATCH /plans/{id} 仅支持 { name }，多字段更新接口待实现
 * （见 journey-plan-api/app/routers/plans.py）。前端按原型设计先行调用，待后端补齐后生效。
 * @param {number|string} id
 * @param {Object} payload 任意可更新字段
 * @returns {Promise<Object>} 更新后的计划对象
 */
export function updatePlan(id, payload) {
  return apiPatch('/plans/' + id, payload)
}

/**
 * 获取单个计划详情。
 * TODO(backend): 后端当前无 GET /plans/{id}，待实现。前端用于「继续编辑草稿」回填。
 * @param {number|string} id
 * @returns {Promise<Object>}
 */
export function getPlan(id) {
  return apiGet('/plans/' + id)
}

/**
 * 生成每日计划（AI 推荐）。
 * TODO(backend): 后端无此接口，待实现。前端按原型调用，失败则本地 mock。
 * @param {number|string} id
 * @param {Object} [opts] { confirm_ids?: number[], avoid_ids?: number[] }
 * @returns {Promise<{days: Array}>}
 */
export function generateDailyPlans(id, opts = {}) {
  return apiPost('/plans/' + id + '/days', opts)
}

/**
 * 获取每日计划列表。
 * TODO(backend): 后端无此接口，待实现。
 * @param {number|string} id
 * @returns {Promise<{days: Array}>}
 */
export function getDailyPlans(id) {
  return apiGet('/plans/' + id + '/days')
}
