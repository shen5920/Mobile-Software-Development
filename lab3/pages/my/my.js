// pages/my/my.js
Page({

  /**
   * 页面的初始数据
   */
  data: {
    isLogin: false, // 登录状态
    src: '',        // 用户头像
    nickName: '',   // 用户昵称
    number: 0,      // 收藏新闻数量
    newsList: []    // 收藏新闻列表
  },

  /**
   * 自定义函数--获取个人信息
   */
  getUserInfo: function () {
    let that = this
    wx.getUserProfile({
      desc: 'desc',
      success(res) {
        // console.log(res.userInfo) // 这里可以在控制台输出用户信息
        res = res.userInfo
        getApp().globalData.isLogin = true
        getApp().globalData.userInfo = res
        that.setData({
          isLogin: true,
          src: res.avatarUrl, // 设置用户头像
          nickName: res.nickName // 设置用户昵称
        })
        // 登录后获取收藏列表
        that.getMyFavorites()
      }
    })
  },

  /**
   * 自定义函数--获取收藏列表
   */
  getMyFavorites: function () {
    let info = wx.getStorageInfoSync() // 读取本地缓存信息
    let keys = info.keys // 获取全部key信息
    let num = keys.length // 获取收藏新闻数量

    let myList = []
    for (var i = 0; i < num; i++) {
      let obj = wx.getStorageSync(keys[i])
      myList.push(obj)
    }
    // 更新收藏列表
    this.setData({
      newsList: myList,
      number: num
    })
  },

  /**
   * 自定义函数--跳转新页面浏览新闻内容
   */
  goToDetail: function (e) {
    // 获取携带的data-id数据
    let id = e.currentTarget.dataset.id
    // 携带新闻id进行页面跳转
    wx.navigateTo({
      url: '../detail/detail?id=' + id
    })
  },

  /**
   * 生命周期函数--监听页面显示
   */
  onShow: function () {
    if (getApp().globalData.isLogin) {
      this.getMyFavorites()
    }
  }
})
