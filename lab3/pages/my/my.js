// pages/my/my.js
var store = require('../../utils/store.js')
Page({

  /**
   * 页面的初始数据
   */
  data: {
    isLogin: false,       // 登录状态
    src: '',              // 用户头像
    nickName: '',         // 用户昵称
    // 登录弹框
    showLoginModal: false,
    avatarUrl: '',        // 弹框中选择的头像
    inputNickName: '',    // 弹框中输入的昵称
    // 列表标签
    currentTab: 'favorite', // favorite | like
    favorites: [],        // 收藏列表
    likes: [],            // 点赞列表
    favoriteNum: 0,       // 收藏数量
    likeNum: 0            // 点赞数量
  },

  /**
   * 自定义函数--打开登录弹框
   */
  openLoginModal: function () {
    this.setData({
      showLoginModal: true,
      avatarUrl: '',
      inputNickName: ''
    })
  },

  /**
   * 自定义函数--关闭登录弹框
   */
  closeLoginModal: function () {
    this.setData({ showLoginModal: false })
  },

  noop: function () {},

  /**
   * 自定义函数--选择头像
   */
  onChooseAvatar: function (e) {
    let that = this
    let tempPath = e.detail.avatarUrl
    wx.getFileSystemManager().saveFile({
      tempFilePath: tempPath,
      success: function (res) {
        that.setData({ avatarUrl: res.savedFilePath })
      },
      fail: function () {
        that.setData({ avatarUrl: tempPath })
      }
    })
  },

  /**
   * 自定义函数--输入昵称
   */
  onInputNickName: function (e) {
    this.setData({ inputNickName: e.detail.value })
  },

  /**
   * 自定义函数--确认登录
   */
  confirmLogin: function () {
    let nickName = this.data.inputNickName.trim()
    if (!nickName) {
      wx.showToast({ title: '请输入昵称', icon: 'none' })
      return
    }
    let userInfo = {
      avatarUrl: this.data.avatarUrl,
      nickName: nickName
    }
    store.setUserInfo(userInfo)
    getApp().globalData.isLogin = true
    getApp().globalData.userInfo = userInfo
    this.setData({
      showLoginModal: false,
      isLogin: true,
      src: this.data.avatarUrl,
      nickName: nickName
    })
    this.refreshLists()
  },

  /**
   * 自定义函数--退出登录
   */
  logout: function () {
    let that = this
    wx.showModal({
      title: '提示',
      content: '确定退出登录吗？',
      cancelText: '取消',
      confirmText: '退出',
      success: function (res) {
        if (res.confirm) {
          store.clearUserInfo()
          getApp().globalData.isLogin = false
          getApp().globalData.userInfo = null
          that.setData({
            isLogin: false,
            src: '',
            nickName: ''
          })
          that.refreshLists()
        }
      }
    })
  },

  /**
   * 自定义函数--切换列表标签
   */
  switchTab: function (e) {
    this.setData({ currentTab: e.currentTarget.dataset.tab })
  },

  /**
   * 自定义函数--刷新收藏/点赞列表
   */
  refreshLists: function () {
    let favorites = store.getFavorites().map(function (item) {
      item.offsetX = 0
      return item
    })
    let likes = store.getLikes().map(function (item) {
      item.offsetX = 0
      return item
    })
    this.setData({
      favorites: favorites,
      likes: likes,
      favoriteNum: favorites.length,
      likeNum: likes.length
    })
  },

  /**
   * 自定义函数--左滑开始
   */
  touchStart: function (e) {
    this._startX = e.touches[0].clientX
    this._currentTab = e.currentTarget.dataset.tab
    this._currentIndex = e.currentTarget.dataset.index
    this.closeAll()
  },

  /**
   * 自定义函数--左滑移动
   */
  touchMove: function (e) {
    let deltaX = e.touches[0].clientX - this._startX
    if (deltaX < 0) {
      let offsetX = Math.max(deltaX, -this._deleteWidth)
      this.updateOffset(this._currentTab, this._currentIndex, offsetX)
    }
  },

  /**
   * 自定义函数--左滑结束
   */
  touchEnd: function (e) {
    let deltaX = e.changedTouches[0].clientX - this._startX
    let offsetX = deltaX < -this._deleteWidth / 2 ? -this._deleteWidth : 0
    this.updateOffset(this._currentTab, this._currentIndex, offsetX)
  },

  /**
   * 自定义函数--更新某条偏移
   */
  updateOffset: function (tab, index, offsetX) {
    let key = tab + '[' + index + '].offsetX'
    let data = {}
    data[key] = offsetX
    this.setData(data)
  },

  /**
   * 自定义函数--关闭所有展开项
   */
  closeAll: function () {
    let favorites = this.data.favorites.map(function (item) {
      item.offsetX = 0
      return item
    })
    let likes = this.data.likes.map(function (item) {
      item.offsetX = 0
      return item
    })
    this.setData({ favorites: favorites, likes: likes })
  },

  /**
   * 自定义函数--取消收藏
   */
  cancelFavorite: function (e) {
    store.removeFavorite(e.currentTarget.dataset.id)
    this.refreshLists()
  },

  /**
   * 自定义函数--取消点赞
   */
  cancelLike: function (e) {
    store.removeLike(e.currentTarget.dataset.id)
    this.refreshLists()
  },

  /**
   * 自定义函数--跳转新页面浏览新闻内容
   */
  goToDetail: function (e) {
    let tab = e.currentTarget.dataset.tab
    let index = e.currentTarget.dataset.index
    let list = this.data[tab]
    if (list && list[index] && list[index].offsetX < 0) {
      this.closeAll()
      return
    }
    let id = e.currentTarget.dataset.id
    wx.navigateTo({ url: '../detail/detail?id=' + id })
  },

  /**
   * 生命周期函数--监听页面加载
   */
  onLoad: function () {
    let info = wx.getSystemInfoSync()
    this._deleteWidth = info.windowWidth * 160 / 750
  },

  /**
   * 生命周期函数--监听页面显示
   */
  onShow: function () {
    let userInfo = store.getUserInfo()
    if (userInfo) {
      getApp().globalData.isLogin = true
      getApp().globalData.userInfo = userInfo
      this.setData({
        isLogin: true,
        src: userInfo.avatarUrl,
        nickName: userInfo.nickName
      })
    } else {
      this.setData({ isLogin: false, src: '', nickName: '' })
    }
    this.refreshLists()
  }
})
