// 旅行助手接口（对接后端 POST /assistant/ask，由 agents 子项目驱动）。
import { apiPost } from './request.js'

/**
 * 向旅行助手提问。
 * 后端契约：POST /assistant/ask { message, history } → { reply }
 * @param {string} message 本轮提问
 * @param {Array<{role:string,text:string}>} [history] 历史对话（不含本轮），用于上下文
 * @returns {Promise<{reply: string}>}
 */
export function askAssistant(message, history = []) {
  return apiPost('/assistant/ask', { message, history })
}
