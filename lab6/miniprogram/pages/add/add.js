const app = getApp()
const util = require('../../utils/util')
const db = wx.cloud.database()
const photos = db.collection('photos')

const HISTORY_PAGE_SIZE = 12

/** 从本地文件路径中安全提取扩展名(取不到时用 .jpg, 避免 match 为 null 崩溃) */
function safeExt(path) {
  const m = String(path || '').match(/\.(png|jpe?g|gif|webp)$/i)
  return m ? m[0] : '.jpg'
}

/** 是否已登录(在「个人」页设置过头像/昵称) */
function isLoggedIn() {
  const u = app.globalData.userInfo
  return !!(u && u.nickName)
}

function queryGet(query) {
  return new Promise((resolve, reject) => {
    query.get({ success: resolve, fail: reject })
  })
}

function queryCount(query) {
  return new Promise((resolve, reject) => {
    query.count({ success: resolve, fail: reject })
  })
}

/** 未登录引导: 弹窗提示并跳转「个人」页登录 */
function requireLogin(cb) {
  wx.showModal({
    title: '请先登录',
    content: '在「个人」页设置头像与昵称后, 即可发布你的光影瞬间',
    confirmText: '去登录',
    cancelText: '再逛逛',
    confirmColor: '#667eea',
    success: res => {
      if (res.confirm) {
        wx.switchTab({ url: '/pages/me/me', complete: cb })
      } else if (cb) {
        cb()
      }
    }
  })
}

Page({
  data: {
    description: '',
    selectedImage: '',
    uploading: false,
    uploadProgress: 0,
    // 我的作品
    historyPhotos: [],
    historyTotal: 0,
    loading: true,
    loadingMore: false,
    noMore: false
  },

  /**
   * 描述输入
   */
  onDescInput: function (e) {
    this.setData({ description: e.detail.value })
  },

  /**
   * 选择图片(相册/相机), 支持压缩
   */
  chooseImage: function () {
    if (this.data.uploading) return
    wx.chooseMedia({
      count: 1,
      mediaType: ['image'],
      sizeType: ['compressed'],
      sourceType: ['album', 'camera'],
      success: res => {
        const file = res.tempFiles && res.tempFiles[0]
        if (file && file.tempFilePath) {
          this.setData({ selectedImage: file.tempFilePath })
        }
      },
      fail: err => {
        // 用户主动取消不提示
        if (err && err.errMsg && err.errMsg.indexOf('cancel') >= 0) return
        console.error('选择图片失败', err)
      }
    })
  },

  /** 预览已选图片 */
  previewSelected: function () {
    if (this.data.selectedImage) {
      wx.previewImage({ urls: [this.data.selectedImage], current: this.data.selectedImage })
    }
  },

  /**
   * 发布照片: 需已登录 → 上传云存储 → 写入数据库 → 提示并返回
   */
  publish: async function () {
    const selectedImage = this.data.selectedImage
    if (this.data.uploading) return
    if (!selectedImage) {
      util.showToast('请先选择一张图片')
      return
    }

    // 登录校验(首页入口已拦截, 这里是直达兜底)
    if (!isLoggedIn()) {
      requireLogin()
      return
    }

    const openid = await app.ensureOpenid()
    if (!openid) {
      util.cloudHint()
      return
    }

    const description = (this.data.description || '').trim()
    this.setData({ uploading: true, uploadProgress: 5 })

    try {
      // 1. 上传到云存储(按用户分目录, 真实进度)
      const cloudPath = 'photos/' + openid + '/' + Date.now() + '_' + Math.floor(Math.random() * 1000000) + safeExt(selectedImage)
      const uploaded = await new Promise((resolve, reject) => {
        const task = wx.cloud.uploadFile({
          cloudPath: cloudPath,
          filePath: selectedImage,
          success: resolve,
          fail: reject
        })
        if (task && task.onProgressUpdate) {
          task.onProgressUpdate(res => {
            const p = (res && res.progress) || 0
            this.setData({ uploadProgress: p })
          })
        }
      })

      // 2. 写入数据库(客户端创建, 权限规则允许)
      // chooseAvatar 的临时路径会过期, 仅持久化长期有效的 cloud:// / https:// 头像
      const u = app.globalData.userInfo || {}
      const avatarUrl = u.avatarUrl || ''
      const stableAvatar = avatarUrl.indexOf('cloud://') === 0 || avatarUrl.indexOf('https://') === 0 ? avatarUrl : ''
      await new Promise((resolve, reject) => {
        photos.add({
          data: {
            photoUrl: uploaded.fileID,
            avatarUrl: stableAvatar,
            nickName: (u.nickName || '').trim() || util.DEFAULT_NAME,
            country: u.country || '',
            province: u.province || '',
            addDate: util.todayStr(),
            createTime: Date.now(),
            description: description,
            likes: 0,
            likedBy: [],
            views: 0
          },
          success: resolve,
          fail: reject
        })
      })

      this.setData({ uploading: false, uploadProgress: 0, selectedImage: '', description: '' })
      this.loadHistory(true)
      wx.showToast({ title: '发布成功 🎉', icon: 'success' })

      // 稍等片刻让用户看到成功提示, 然后回到首页看效果
      setTimeout(() => {
        wx.navigateBack({
          fail: () => {
            wx.reLaunch({ url: '/pages/index/index' })
          }
        })
      }, 1200)
    } catch (err) {
      console.error('发布失败', err)
      this.setData({ uploading: false, uploadProgress: 0 })
      util.cloudHint()
      util.showToast('发布失败, 请检查云端配置')
    }
  },

  /**
   * 获取已上传图片历史记录
   */
  loadHistory: async function (reset) {
    const openid = await app.ensureOpenid()
    if (!openid) {
      this.setData({ loading: false, loadingMore: false })
      return
    }

    if (reset) {
      this.setData({ loading: true })
    }
    const skip = reset ? 0 : this.data.historyPhotos.length
    const base = photos.where({ _openid: openid }).orderBy('createTime', 'desc')

    try {
      const [cnt, pageRes] = await Promise.all([
        queryCount(base),
        queryGet(base.skip(skip).limit(HISTORY_PAGE_SIZE))
      ])
      const total = cnt.total || 0
      const page = pageRes.data.map(item => ({
        _id: item._id,
        photoUrl: item.photoUrl,
        label: item.createTime ? util.shortDate(item.createTime) : (item.addDate || '')
      }))
      const list = reset ? page : this.data.historyPhotos.concat(page)

      this.setData({
        historyPhotos: list,
        historyTotal: total,
        loading: false,
        loadingMore: false,
        noMore: list.length >= total
      })
    } catch (err) {
      console.error('加载历史失败', err)
      this.setData({ loading: false, loadingMore: false })
      if (reset && this.data.historyPhotos.length === 0) {
        util.showToast('加载失败, 请检查网络')
      }
    }
  },

  /** 加载更多历史作品 */
  loadMoreHistory: function () {
    if (this.data.loading || this.data.loadingMore || this.data.noMore) return
    this.setData({ loadingMore: true })
    this.loadHistory(false)
  },

  /** 预览历史图片 */
  previewHistory: function (e) {
    const url = e.currentTarget.dataset.url
    const urls = this.data.historyPhotos.map(item => item.photoUrl)
    wx.previewImage({ urls: urls, current: url })
  },

  /** 删除自己的历史作品(含云文件与评论级联) */
  deleteHistory: function (e) {
    const id = e.currentTarget.dataset.id
    const index = e.currentTarget.dataset.index
    wx.showModal({
      title: '删除照片',
      content: '删除后不可恢复, 确定删除吗?',
      confirmText: '删除',
      confirmColor: '#f5576c',
      success: async res => {
        if (!res.confirm) return
        wx.showLoading({ title: '删除中...', mask: true })
        try {
          const r = await util.cloudFn('interactPhoto', { action: 'delete', photoId: id })
          wx.hideLoading()
          if (r && r.ok) {
            const list = this.data.historyPhotos.slice()
            list.splice(index, 1)
            this.setData({
              historyPhotos: list,
              historyTotal: Math.max(0, this.data.historyTotal - 1)
            })
            wx.showToast({ title: '已删除', icon: 'success' })
          } else {
            util.showToast((r && r.msg) || '删除失败, 请重试')
          }
        } catch (err) {
          wx.hideLoading()
          console.error('删除失败', err)
          util.cloudHint()
          util.showToast('删除失败, 请重试')
        }
      }
    })
  },

  /**
   * 生命周期函数--监听页面加载
   */
  onLoad: function () {
    this.loadHistory(true)
  }
})
