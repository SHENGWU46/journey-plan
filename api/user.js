// 用户相关接口（journey-plan-api）
//
// 约定：本文件的每个方法必须与一个后端接口一一对应，注释标注对应 PRD 章节。
// 后端已实现的「不涉及 AI」接口：/user/me、/user/profile、/user/password。
//
// @contract 对应 PRD 用户中心
//   GET  /user/me         → 返回 { id, username, plan_count, completed_count, travel_days }
//   PATCH /user/profile   { username }                         → 返回更新后的用户对象
//   PATCH /user/password  { old_password, new_password }       → { success: true }；400 原密码错误；401 未登录

import { apiGet, apiPatch } from './request.js'

/** 获取当前用户资料与统计（opt 透传 request 的 silent 等选项，便于后台静默刷新） */
export function getProfile(opt) {
  return apiGet('/user/me', {}, opt)
}

/** 修改昵称 */
export function updateProfile(payload) {
  return apiPatch('/user/profile', { username: payload.username })
}

/** 修改密码 */
export function changePassword(payload) {
  return apiPatch('/user/password', {
    old_password: payload.old_password,
    new_password: payload.new_password
  })
}
