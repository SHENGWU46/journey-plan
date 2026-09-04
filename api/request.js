// 统一请求封装（设计决策 3/11：搜索由服务端执行，前端直连本地 API）
//
// 后端契约（journey-plan-api，REST 风格）：
//   - 路径无 /api/v1 前缀（如 /plans）
//   - 响应为业务对象本身：列表为 { items, total, page, page_size }，单对象为计划对象
//   - 状态码语义：200/201/204 成功；422 为校验失败；404 为资源不存在
//   - 错误响应体为 FastAPI 标准 { detail: ... }（detail 可为字符串或校验错误数组）
//
// 鉴权（2026-09-02）：/plans 系列接口要求 Bearer token，本模块自动附加；
//   401 表示 token 缺失/失效，会清除本地登录态并跳转登录页。
//   登录注册接口自身的 401（账号或密码错误）属业务错误，不跳转，需传 noAuthRedirect。
//
// 约定：页面与组件禁止直接调用 uni.request，一律走本模块。

import { getToken, clearSession } from '@/utils/token.js'

export const BASE_URL = 'http://localhost:8000'

/** 登录页路径（token 失效时跳转目标） */
const LOGIN_URL = '/pages/login/login'

/**
 * 从错误响应体中取出可展示的提示文案。
 * FastAPI 的 HTTPException 返回 { detail: string }，
 * 请求参数校验失败（422）返回 { detail: [{ loc, msg, type }, ...] }。
 */
function pickMessage(body, statusCode) {
  if (body == null || body === '') return '请求失败（' + statusCode + '）'
  if (typeof body === 'string') return body

  const detail = body.detail
  if (typeof detail === 'string' && detail) return detail
  if (Array.isArray(detail) && detail.length) {
    const first = detail[0] || {}
    return first.msg || first.message || '请求参数不合法'
  }
  if (typeof body.message === 'string' && body.message) return body.message
  return '请求失败（' + statusCode + '）'
}

/** 跳转到登录页（用 reLaunch 清空页面栈，避免返回键回到需要登录的页面） */
function redirectToLogin() {
  const pages = getCurrentPages()
  const current = pages.length ? pages[pages.length - 1] : null
  // 已在登录页则不重复跳转，避免死循环
  if (current && current.route === 'pages/login/login') return
  uni.reLaunch({ url: LOGIN_URL })
}

/**
 * 发起请求
 * @param {Object} opt
 * @param {string} opt.url     以 / 开头的接口路径
 * @param {string} [opt.method] GET / POST / PATCH / DELETE
 * @param {Object} [opt.data]  query 或 body 参数
 * @param {boolean} [opt.silent] true 时不弹错误提示（调用方自行处理）
 * @param {boolean} [opt.noAuthRedirect] true 时 401 不跳转登录页（登录/注册接口用）
 * @param {boolean} [opt.auth] 默认 true，附加 Authorization 头；登录注册等接口传 false
 * @returns {Promise<Object>} 成功时 resolve 响应体；204 无内容时 resolve { success: true }
 */
export function request(opt = {}) {
  const {
    url = '',
    method = 'GET',
    data = {},
    silent = false,
    noAuthRedirect = false,
    auth = true
  } = opt

  const header = { 'Content-Type': 'application/json' }
  const token = getToken()
  if (auth && token) header.Authorization = 'Bearer ' + token

  return new Promise((resolve, reject) => {
    uni.request({
      url: BASE_URL + url,
      method,
      data,
      header,
      success(res) {
        const statusCode = res.statusCode
        const body = res.data

        if (statusCode >= 200 && statusCode < 300) {
          // 204 No Content（DELETE）：uni.request 的 data 为空字符串
          return resolve(body === '' || body == null ? { success: true } : body)
        }

        // 401：token 缺失或失效（登录接口自身的 401 由 noAuthRedirect 排除）
        if (statusCode === 401 && !noAuthRedirect) {
          clearSession()
          redirectToLogin()
          reject({ statusCode, message: '登录已失效，请重新登录', data: body, expired: true })
          return
        }

        const message = pickMessage(body, statusCode)
        if (!silent) uni.showToast({ title: message, icon: 'none' })
        reject({ statusCode, message, data: body })
      },
      fail(err) {
        if (!silent) uni.showToast({ title: '网络异常，请检查后端服务', icon: 'none' })
        reject({ statusCode: 0, message: '网络异常，请检查后端服务', data: err })
      }
    })
  })
}

export const apiGet = (url, data, opt) => request(Object.assign({ url, method: 'GET', data }, opt))
export const apiPost = (url, data, opt) => request(Object.assign({ url, method: 'POST', data }, opt))
export const apiPatch = (url, data, opt) => request(Object.assign({ url, method: 'PATCH', data }, opt))
export const apiDel = (url, data, opt) => request(Object.assign({ url, method: 'DELETE', data }, opt))
