// app.js
const util = require('./utils/util')

App({
  globalData: {
    // env 参数说明：
    // env 参数决定接下来小程序发起的云开发调用（wx.cloud.xxx）会请求到哪个云环境的资源
    // 此处请填入环境 ID, 环境 ID 可在微信开发者工具右上顶部工具栏点击云开发按钮打开获取
    env: "cloud1-d1gfdc40s2d334078",
    userInfo: null,
    openid: ""
  },

  onLaunch: function () {
    if (!wx.cloud) {
      console.error("请使用 2.2.3 或以上的基础库以使用云能力")
      return
    }
    wx.cloud.init({
      env: this.globalData.env,
      traceUser: true
    })

    this._openidTask = null

    // 读取本地缓存(用户资料 + openid), 让冷启动立刻可用
    try {
      const saved = wx.getStorageSync("userProfile")
      if (saved && saved.nickName) {
        this.globalData.userInfo = saved
      }
    } catch (e) {
      // 缓存读取失败不影响使用
    }
    try {
      const cachedOpenid = wx.getStorageSync("openid")
      if (cachedOpenid) {
        this.globalData.openid = cachedOpenid
      }
    } catch (e) {
      // 缓存读取失败不影响使用
    }

    this.ensureOpenid()
    // 命中缓存时后台静默向云端校验一次(切换微信号场景下自动纠正, 失败不影响使用)
    if (this.globalData.openid) {
      this.refreshOpenidSilently()
    }
  },

  /** 后台静默刷新 openid(不弹提示, 失败忽略) */
  refreshOpenidSilently: function () {
    const self = this
    wx.cloud.callFunction({
      name: "getOpenid",
      success: function (res) {
        const openid = (res.result && res.result.openid) || ""
        if (openid && openid !== self.globalData.openid) {
          self.globalData.openid = openid
          try {
            wx.setStorageSync("openid", openid)
          } catch (e) {
            // 忽略缓存失败
          }
        }
      },
      fail: function (err) {
        console.error("后台刷新 openid 失败(继续使用缓存)", err)
      }
    })
  },

  /**
   * 确保拿到 openid(全局同一请求, 可被任意页面重复调用)。
   * 有本地缓存时立即返回; 无缓存则带重试地去云端获取。
   * 全部重试仍失败时返回空串, 并弹一次云端配置引导。
   */
  ensureOpenid: function () {
    if (this.globalData.openid) {
      return Promise.resolve(this.globalData.openid)
    }
    if (this._openidTask) {
      return this._openidTask
    }
    const self = this
    this._openidTask = new Promise(function (resolve) {
      self.fetchOpenid(resolve, 3)
    })
    return this._openidTask
  },

  /** 实际请求 getOpenid, 失败自动重试 attempts 次 */
  fetchOpenid: function (resolve, attempts) {
    const self = this
    wx.cloud.callFunction({
      name: "getOpenid",
      success: function (res) {
        const openid = (res.result && res.result.openid) || ""
        if (openid) {
          self.globalData.openid = openid
          try {
            wx.setStorageSync("openid", openid)
          } catch (e) {
            // 忽略缓存失败
          }
          resolve(openid)
        } else if (attempts > 1) {
          setTimeout(function () {
            self.fetchOpenid(resolve, attempts - 1)
          }, 500)
        } else {
          self._openidTask = null
          util.cloudHint()
          resolve("")
        }
      },
      fail: function (err) {
        console.error("获取 openid 失败(剩余重试 " + (attempts - 1) + " 次)", err)
        if (attempts > 1) {
          setTimeout(function () {
            self.fetchOpenid(resolve, attempts - 1)
          }, 500)
        } else {
          self._openidTask = null
          util.cloudHint()
          resolve("")
        }
      }
    })
  },

  /**
   * 保存用户资料(头像/昵称)并写入本地缓存
   */
  setUserProfile: function (profile) {
    this.globalData.userInfo = Object.assign({}, this.globalData.userInfo || {}, profile)
    try {
      wx.setStorageSync("userProfile", this.globalData.userInfo)
    } catch (e) {
      // 忽略缓存失败
    }
  },

  /**
   * 退出登录: 清除头像昵称档案(openid 保留, 游客浏览/点赞不受影响)
   */
  logout: function () {
    this.globalData.userInfo = null
    try {
      wx.removeStorageSync("userProfile")
    } catch (e) {
      // 忽略缓存失败
    }
  }
})
