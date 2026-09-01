// pages/detail/detail.js
var common = require('../../utils/common.js') // 引用公共JS文件
var store = require('../../utils/store.js') // 引用缓存模块
Page({

  /**
   * 页面的初始数据
   */
  data: {
    article: {},  // 当前新闻内容
    isAdd: false, // 是否已收藏
    isLike: false // 是否已点赞
  },

  /**
   * 自定义函数--收藏 / 取消收藏
   */
  toggleFavorites: function () {
    if (this.data.isAdd) {
      store.removeFavorite(this.data.article.id)
      this.setData({ isAdd: false })
    } else {
      if (!this.checkLogin()) return
      store.addFavorite(this.data.article)
      this.setData({ isAdd: true })
    }
  },

  /**
   * 自定义函数--点赞 / 取消点赞
   */
  toggleLike: function () {
    if (this.data.isLike) {
      store.removeLike(this.data.article.id)
      this.setData({ isLike: false })
    } else {
      if (!this.checkLogin()) return
      store.addLike(this.data.article)
      this.setData({ isLike: true })
    }
  },

  /**
   * 自定义函数--检查登录
   */
  checkLogin: function () {
    if (getApp().globalData.isLogin) {
      return true
    }
    wx.showModal({
      title: '提示',
      content: '请先登录账号',
      cancelText: '取消',
      confirmText: '去登录',
      success: function (res) {
        if (res.confirm) {
          wx.switchTab({ url: '/pages/my/my' })
        }
      }
    })
    return false
  },

  /**
   * 生命周期函数--监听页面加载
   */
  onLoad: function (options) {
    let id = options.id
    let result = common.getNewsDetail(id)
    if (result.code == '200') {
      this.setData({
        article: result.news,
        isAdd: store.isFavorite(id),
        isLike: store.isLiked(id)
      })
    }
  }
})
