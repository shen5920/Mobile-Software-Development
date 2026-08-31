// pages/detail/detail.js
var common = require('../../utils/common.js') // 引用公共JS文件
Page({

  /**
   * 页面的初始数据
   */
  data: {
    article: {},  // 当前新闻内容
    isAdd: false  // 是否已收藏
  },

  /**
   * 自定义函数--添加收藏
   */
  addFavorites: function () {
    if (!getApp().globalData.isLogin) {
      wx.showModal({
        title: '提示',
        content: '请先登录账号',
        cancelText: '取消',
        confirmText: '去登录',
        success: function (res) {
          if (res.confirm) {
            wx.switchTab({
              url: '/pages/my/my'
            })
          }
        }
      })
      return
    }
    let article = this.data.article
    wx.setStorageSync(article.id, article)
    this.setData({
      isAdd: true
    })
  },

  /**
   * 自定义函数--取消收藏
   */
  cancelFavorites: function () {
    let article = this.data.article
    wx.removeStorageSync(article.id)
    this.setData({
      isAdd: false
    })
  },

  /**
   * 生命周期函数--监听页面加载
   */
  onLoad: function (options) {
    let id = options.id
    // 检查当前新闻是否在收藏夹中
    var newarticle = wx.getStorageSync(id)
    // 已存在
    if (newarticle != '') {
      this.setData({
        isAdd: true,
        article: newarticle
      })
    }
    // 不存在
    else {
      let result = common.getNewsDetail(id)
      // 获取新闻内容
      if (result.code == '200') {
        this.setData({
          article: result.news,
          isAdd: false
        })
      }
    }
  }
})
