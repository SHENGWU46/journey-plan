// 登录态本地存储（同步读写，无任何依赖）
//
// 为什么单独成文件：request.js 需要在每个请求里读取 token，而 store / api 又依赖
// request.js——若 request.js 反过来 import store 就会形成循环依赖。
// 故把「token 的读写」下沉为这个无依赖模块，request.js 与 store 都只依赖它。
//
// 存储键：
//   jp_token  — JWT access_token
//   jp_user   — { id, username } 的 JSON 字符串

const TOKEN_KEY = 'jp_token'
const USER_KEY = 'jp_user'

/**
 * 保存登录态
 * @param {string} token access_token
 * @param {{id: number, username: string}} user 用户信息
 */
export function saveSession(token, user) {
  try {
    uni.setStorageSync(TOKEN_KEY, token)
    uni.setStorageSync(USER_KEY, JSON.stringify(user || {}))
  } catch (e) {
    console.error('保存登录态失败', e)
  }
}

/** 读取 token；未登录返回空串 */
export function getToken() {
  try {
    return uni.getStorageSync(TOKEN_KEY) || ''
  } catch (e) {
    return ''
  }
}

/** 读取用户信息；未登录或数据损坏返回 null */
export function getUser() {
  try {
    const raw = uni.getStorageSync(USER_KEY)
    if (!raw) return null
    return typeof raw === 'string' ? JSON.parse(raw) : raw
  } catch (e) {
    return null
  }
}

/** 覆盖更新本地用户信息（如改昵称后刷新资料） */
export function setUser(user) {
  if (!user) return
  try {
    uni.setStorageSync(USER_KEY, JSON.stringify(user))
  } catch (e) {
    console.error('更新本地用户信息失败', e)
  }
}

/** 是否已登录（仅凭 token 是否存在判断，不校验有效期） */
export function isLoggedIn() {
  return !!getToken()
}

/** 清除登录态（退出登录 / token 失效时调用） */
export function clearSession() {
  try {
    uni.removeStorageSync(TOKEN_KEY)
    uni.removeStorageSync(USER_KEY)
  } catch (e) {
    console.error('清除登录态失败', e)
  }
}
