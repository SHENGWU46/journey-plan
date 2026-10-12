// 认证接口（journey-plan-api app/routers/auth_router.py）
//
//   POST /auth/register  { username, password, confirm_password } → 201，返回 { id, username }
//   POST /auth/login     { username, password }                   → 200，返回 { access_token, token_type, user }
//
// 校验规则（后端 Pydantic，前端做同款预校验以便即时反馈）：
//   - username：去首尾空格后 2-20 字符
//   - password：≥6 位
//   - 注册需 confirm_password 与 password 一致
// 错误码：422 格式非法 / 400 账号已存在 / 401 账号或密码错误

import { apiPost } from './request.js'

/**
 * 注册账号
 * @param {Object} payload { username, password, confirmPassword }
 * @returns {Promise<{id: number, username: string}>} 用户信息（不含密码字段）
 */
export function register(payload) {
  return apiPost(
    '/auth/register',
    {
      username: payload.username,
      password: payload.password,
      confirm_password: payload.confirmPassword
    },
    // 认证接口自身不携带 token，且其 400/401 是业务错误（账号已存在/密码错误），
    // 不能触发「登录失效跳转登录页」逻辑。
    { auth: false, noAuthRedirect: true }
  )
}

/**
 * 登录
 * @param {Object} payload { username, password }
 * @returns {Promise<{access_token: string, token_type: string, user: {id: number, username: string}}>}
 */
export function login(payload) {
  return apiPost(
    '/auth/login',
    {
      username: payload.username,
      password: payload.password
    },
    { auth: false, noAuthRedirect: true, silent: true }
  )
}
