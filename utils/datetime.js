// 时间格式化工具（约定：后端统一存 UTC，前端按用户本地时区展示）
//
// 背景：后端 _utcnow() 返回的是 UTC 时刻（存 MySQL/SQLite 均为 naive UTC），
// AGENTS.md 第 5 章规定时间字段统一 ISO8601。前端不改动后端，仅在展示层
// 将 UTC 时间转换为访问者本地时区，避免出现"创建时间比现在早 8 小时"的错觉。
//
// 注意：浏览器/uni-app 的 Date 构造器会自动把 ISO 字符串按本地时区解析，
// 故 new Date("2026-09-02T08:23:41") 在 UTC+8 环境下得到的就是北京时间 16:23。

/**
 * 将后端返回的 UTC 时间字符串（或 Date / 时间戳）按本地时区格式化为可读文本。
 * 入参为空时返回占位符 '-'。
 * @param {string|Date|number|null} value 后端 ISO 字符串 / Date / 毫秒时间戳
 * @param {boolean} withTime 是否包含时分（默认 true）
 * @returns {string} 例如 "2026-09-02 16:23"
 */
export function formatLocal(value, withTime = true) {
  if (value === null || value === undefined || value === '') return '-'

  const d = toDate(value)
  if (d === null) return '-' // 非法日期兜底

  const y = d.getFullYear()
  const m = String(d.getMonth() + 1).padStart(2, '0')
  const day = String(d.getDate()).padStart(2, '0')
  if (!withTime) return `${y}-${m}-${day}`

  const hh = String(d.getHours()).padStart(2, '0')
  const mm = String(d.getMinutes()).padStart(2, '0')
  return `${y}-${m}-${day} ${hh}:${mm}`
}

/**
 * 相对描述（可选增强）：把时间转为"刚刚 / x分钟前 / x小时前 / x天前"。
 * 用于计划列表等轻量展示场景。
 * @param {string|Date|number|null} value
 * @returns {string}
 */
export function fromNow(value) {
  if (value === null || value === undefined || value === '') return '-'

  const d = toDate(value)
  if (d === null) return '-'

  const diffMs = Date.now() - d.getTime()
  const min = Math.floor(diffMs / 60000)
  if (min < 1) return '刚刚'
  if (min < 60) return `${min}分钟前`
  const hr = Math.floor(min / 60)
  if (hr < 24) return `${hr}小时前`
  const day = Math.floor(hr / 24)
  if (day < 30) return `${day}天前`
  return formatLocal(value, false)
}

/**
 * 统一解析为 Date 对象。
 * 关键点：后端 SQLAlchemy 存 naive UTC，序列化为 JSON 时通常为无时区后缀的
 * ISO 字符串（如 "2026-09-02T08:23:41"）。浏览器/uni-app 的 Date 构造器会把它
 * 当作「本地时间」而非 UTC，导致转换失效。故检测到无时区后缀时，显式补 "+00:00"
 * 强制按 UTC 解析，再由 get* 方法按访问者本地时区取出，得到正确的北京时间。
 * @param {string|Date|number} value
 * @returns {Date|null}
 */
function toDate(value) {
  if (value instanceof Date) return value
  if (typeof value === 'number') return new Date(value)

  let str = String(value).trim()
  // 无时区信息（既无 Z 也无 +/-HH:MM）则当作 UTC
  if (!/[zZ]$/.test(str) && !/[+-]\d{2}:?\d{2}$/.test(str)) {
    // 兼容 "2026-09-02T08:23:41" 与 "2026-09-02 08:23:41" 两种写法
    str = str.replace(' ', 'T') + '+00:00'
  }
  const d = new Date(str)
  return isNaN(d.getTime()) ? null : d
}
