/**
 * 光影集 - 通用工具函数
 * 供 index / add / detail / homepage 四个页面复用
 */

// 未设置昵称时的默认称呼
const DEFAULT_NAME = '光影旅人'

function pad(n) {
  return n < 10 ? '0' + n : '' + n
}

/**
 * 调用云函数(promise 化)
 * @param {string} name 云函数名
 * @param {object} data 参数
 */
function cloudFn(name, data) {
  return new Promise((resolve, reject) => {
    wx.cloud.callFunction({
      name: name,
      data: data || {},
      success: res => resolve(res.result || {}),
      fail: err => reject(err)
    })
  })
}

/** 轻提示 */
function showToast(title, icon) {
  wx.showToast({ title: title, icon: icon || 'none' })
}

// 云端配置引导弹窗(每次启动最多提示一次, 避免多个页面同时触发)
let cloudHintShown = false

/**
 * 云函数调用失败的引导弹窗:
 * 提示用户部署云函数并核对环境 ID, 而不是显示含义不明的"网络异常"
 */
function cloudHint() {
  if (cloudHintShown) return
  cloudHintShown = true
  wx.showModal({
    title: '云端功能未就绪',
    content: '获取用户身份失败。请检查:\n1. app.js 中环境 ID 与云开发控制台一致\n2. 云函数 getOpenid、interactPhoto 均已右键"上传并部署: 云端安装依赖"\n3. 数据库已创建 photos、comments 集合(权限: 所有用户可读, 仅创建者可写)',
    showCancel: false,
    confirmText: '知道了',
    fail: () => {}
  })
}

/**
 * 时间戳 -> 友好展示(今天/昨天/M月D日 HH:mm/YYYY年M月D日)
 * @param {number} ts 毫秒时间戳
 */
function timeText(ts) {
  if (!ts) return ''
  const d = new Date(ts)
  const now = new Date()
  const dayStart = t => new Date(t.getFullYear(), t.getMonth(), t.getDate()).getTime()
  const dayDiff = Math.round((dayStart(now) - dayStart(d)) / 86400000)
  const hm = pad(d.getHours()) + ':' + pad(d.getMinutes())
  if (dayDiff === 0) return '今天 ' + hm
  if (dayDiff === 1) return '昨天 ' + hm
  if (d.getFullYear() === now.getFullYear()) return (d.getMonth() + 1) + '月' + d.getDate() + '日 ' + hm
  return d.getFullYear() + '年' + (d.getMonth() + 1) + '月' + d.getDate() + '日'
}

/**
 * 短日期(我的作品缩略图上用): 今年显示 MM-DD, 跨年显示 YYYY-MM-DD
 */
function shortDate(ts) {
  if (!ts) return ''
  const d = new Date(ts)
  const now = new Date()
  const md = (d.getMonth() + 1) + '-' + pad(d.getDate())
  return d.getFullYear() === now.getFullYear() ? md : d.getFullYear() + '-' + md
}

/** 今天日期字符串 YYYY-MM-DD(兼容旧版 addDate 展示字段) */
function todayStr() {
  const d = new Date()
  return d.getFullYear() + '-' + pad(d.getMonth() + 1) + '-' + pad(d.getDate())
}

/** 省市拼接, 都没有则返回空串(空则 UI 不显示"来自 xxx") */
function regionText(province, country) {
  const list = []
  if (province && String(province).trim()) list.push(String(province).trim())
  if (country && String(country).trim()) list.push(String(country).trim())
  return list.join(', ')
}

/** 昵称首字符(头像兜底用), 空昵称给"影" */
function letterOf(name) {
  const t = String(name || '').trim()
  return t ? t[0] : '影'
}

/** 根据昵称哈希取渐变背景(字母头像配色) */
const AVATAR_PALETTES = [
  'linear-gradient(135deg,#667eea,#764ba2)',
  'linear-gradient(135deg,#f093fb,#f5576c)',
  'linear-gradient(135deg,#4facfe,#00f2fe)',
  'linear-gradient(135deg,#43e97b,#38c172)',
  'linear-gradient(135deg,#fa709a,#fee140)',
  'linear-gradient(135deg,#30cfd0,#330867)'
]

function avatarBg(name) {
  const s = String(name || '')
  let h = 0
  for (let i = 0; i < s.length; i++) {
    h = (h * 31 + s.charCodeAt(i)) >>> 0
  }
  return AVATAR_PALETTES[h % AVATAR_PALETTES.length]
}

/**
 * 照片记录 -> 页面可直接绑定的展示对象(去重三个列表页的重复逻辑)
 * 附加: nickName默认值/likes/views/address/displayTime/letter/avatarBg/homeUrl/detailUrl
 */
function enrichPhoto(item) {
  const o = item || {}
  const nickName = (o.nickName || '').trim() || DEFAULT_NAME
  return Object.assign({}, o, {
    nickName: nickName,
    likes: o.likes || 0,
    views: o.views || 0,
    address: regionText(o.province, o.country),
    displayTime: o.createTime ? timeText(o.createTime) : (o.addDate || ''),
    letter: letterOf(nickName),
    avatarBg: avatarBg(nickName),
    homeUrl: o._openid
      ? '/pages/homepage/homepage?id=' + encodeURIComponent(o._openid) +
        '&name=' + encodeURIComponent(nickName) +
        '&avatar=' + encodeURIComponent(o.avatarUrl || '') +
        '&province=' + encodeURIComponent(o.province || '') +
        '&country=' + encodeURIComponent(o.country || '')
      : '',
    detailUrl: o._id ? '/pages/detail/detail?id=' + o._id : ''
  })
}

module.exports = {
  DEFAULT_NAME: DEFAULT_NAME,
  cloudFn: cloudFn,
  showToast: showToast,
  cloudHint: cloudHint,
  timeText: timeText,
  shortDate: shortDate,
  todayStr: todayStr,
  regionText: regionText,
  letterOf: letterOf,
  avatarBg: avatarBg,
  enrichPhoto: enrichPhoto
}
