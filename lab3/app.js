// app.js
var store = require('./utils/store.js')
App({
  globalData: {
    isLogin: false,  // 登录状态
    userInfo: null   // 用户信息
  },
  onLaunch: function () {
    var userInfo = store.getUserInfo()
    if (userInfo) {
      this.globalData.isLogin = true
      this.globalData.userInfo = userInfo
    }
  }
})
