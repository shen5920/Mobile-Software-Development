const app = getApp()
const util = require('../../utils/util')
const db = wx.cloud.database()
const photos = db.collection('photos')
const comments = db.collection('comments')

function docGet(ref) {
  return new Promise((resolve, reject) => {
    ref.get({ success: resolve, fail: reject })
  })
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

function docRemove(ref) {
  return new Promise((resolve, reject) => {
    ref.remove({ success: resolve, fail: reject })
  })
}

Page({
  data: {
    photo: null,
    liked: false,
    showHeart: false,
    lastTapTime: 0,
    shareImg: '',
    // 评论
    comments: [],
    commentTotal: 0,
    draft: '',
    canSend: false,
    sending: false,
    loadingComments: true
  },

  /** 图片单击/双击处理(双击点赞 + 爱心动画) */
  onImageTap: function () {
    const now = Date.now()
    const isDouble = now - this.data.lastTapTime < 300
    this.setData({ lastTapTime: now })
    if (isDouble) {
      if (!this.data.liked) {
        this.setData({ showHeart: true })
        setTimeout(() => {
          this.setData({ showHeart: false })
        }, 800)
      }
      this.doLike()
    }
  },

  /** 长按图片: 保存/预览 */
  onLongPress: function () {
    wx.showActionSheet({
      itemList: ['保存图片到相册', '全屏预览'],
      success: res => {
        if (res.tapIndex === 0) {
          this.downloadPhoto()
        } else if (res.tapIndex === 1) {
          this.previewPhoto()
        }
      }
    })
  },

  /** 点赞/取消点赞(云函数从请求上下文取 openid, 客户端无需知道, 以服务端返回值校准) */
  doLike: async function () {
    const photo = this.data.photo
    if (!photo) return

    const wantLike = !this.data.liked
    const prevLiked = this.data.liked
    const prevLikes = photo.likes || 0

    this.setData({
      liked: wantLike,
      'photo.likes': Math.max(0, prevLikes + (wantLike ? 1 : -1))
    })

    try {
      const r = await util.cloudFn('interactPhoto', {
        action: wantLike ? 'like' : 'unlike',
        photoId: photo._id
      })
      if (r && r.ok) {
        this.setData({ liked: r.liked, 'photo.likes': r.likes })
      } else {
        this.setData({ liked: prevLiked, 'photo.likes': prevLikes })
        util.showToast((r && r.msg) || '操作失败, 请重试')
      }
    } catch (err) {
      console.error('点赞失败', err)
      this.setData({ liked: prevLiked, 'photo.likes': prevLikes })
      util.cloudHint()
      util.showToast('操作失败, 请重试')
    }
  },

  /** 点击点赞按钮(与双击同一逻辑) */
  toggleLike: function () {
    this.doLike()
  },

  /** 保存图片到相册 */
  downloadPhoto: function () {
    wx.showLoading({ title: '下载中...' })
    wx.cloud.downloadFile({
      fileID: this.data.photo.photoUrl,
      success: res => {
        wx.saveImageToPhotosAlbum({
          filePath: res.tempFilePath,
          success: () => {
            wx.hideLoading()
            wx.showToast({ title: '已保存到相册', icon: 'success' })
          },
          fail: err => {
            wx.hideLoading()
            if (err && err.errMsg && err.errMsg.indexOf('auth deny') >= 0) {
              wx.showModal({
                title: '需要授权',
                content: '需要您授权保存图片到相册',
                success: modalRes => {
                  if (modalRes.confirm) {
                    wx.openSetting()
                  }
                }
              })
            } else {
              util.showToast('保存失败, 请重试')
            }
          }
        })
      },
      fail: err => {
        wx.hideLoading()
        console.error('下载失败', err)
        util.showToast('下载失败, 请重试')
      }
    })
  },

  /** 全屏预览 */
  previewPhoto: function () {
    wx.previewImage({
      urls: [this.data.photo.photoUrl],
      current: this.data.photo.photoUrl
    })
  },

  /** 作者删除照片(云函数级联清理) */
  deletePhoto: function () {
    wx.showModal({
      title: '删除照片',
      content: '照片与全部评论将一并删除且不可恢复, 确定删除吗?',
      confirmText: '删除',
      confirmColor: '#f5576c',
      success: async res => {
        if (!res.confirm) return
        wx.showLoading({ title: '删除中...', mask: true })
        try {
          const r = await util.cloudFn('interactPhoto', {
            action: 'delete',
            photoId: this.data.photo._id
          })
          wx.hideLoading()
          if (r && r.ok) {
            wx.showToast({ title: '已删除', icon: 'success' })
            setTimeout(() => {
              wx.navigateBack({
                fail: () => {
                  wx.reLaunch({ url: '/pages/index/index' })
                }
              })
            }, 800)
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

  /** 加载评论列表 */
  loadComments: async function () {
    this.setData({ loadingComments: true })
    try {
      const base = comments.where({ photoId: this.photoId })
      const [cnt, pageRes] = await Promise.all([
        queryCount(base),
        queryGet(base.orderBy('createTime', 'asc').limit(50))
      ])
      const openid = app.globalData.openid || this.data.openid
      const list = pageRes.data.map(item => ({
        _id: item._id,
        content: item.content,
        nickName: (item.nickName || '').trim() || util.DEFAULT_NAME,
        avatarUrl: item.avatarUrl || '',
        timeText: util.timeText(item.createTime),
        letter: util.letterOf(item.nickName),
        avatarBg: util.avatarBg(item.nickName),
        mine: openid && item._openid === openid
      }))
      this.setData({
        comments: list,
        commentTotal: cnt.total || 0,
        loadingComments: false
      })
    } catch (err) {
      // comments 集合尚未创建/网络问题: 静默降级为空评论
      console.error('加载评论失败', err)
      this.setData({ comments: [], loadingComments: false })
    }
  },

  /** 发布评论 */
  sendComment: async function () {
    const content = (this.data.draft || '').trim()
    if (!content || this.data.sending) return

    this.setData({ sending: true })
    const u = app.globalData.userInfo || {}
    const avatarUrl = u.avatarUrl || ''
    const stableAvatar = avatarUrl.indexOf('cloud://') === 0 || avatarUrl.indexOf('https://') === 0
      ? avatarUrl : ''

    try {
      await new Promise((resolve, reject) => {
        comments.add({
          data: {
            photoId: this.photoId,
            content: content.slice(0, 100),
            nickName: (u.nickName || '').trim() || util.DEFAULT_NAME,
            avatarUrl: stableAvatar,
            createTime: Date.now()
          },
          success: resolve,
          fail: reject
        })
      })
      this.setData({ draft: '' })
      await this.loadComments()
      util.showToast('评论成功', 'success')
    } catch (err) {
      console.error('评论失败', err)
      util.showToast('评论失败, 请重试')
    }
    this.setData({ sending: false })
  },

  /** 删除自己的评论 */
  deleteComment: function (e) {
    const id = e.currentTarget.dataset.id
    wx.showModal({
      title: '删除评论',
      content: '确定删除这条评论吗?',
      confirmText: '删除',
      confirmColor: '#f5576c',
      success: async res => {
        if (!res.confirm) return
        try {
          await docRemove(comments.doc(id))
          await this.loadComments()
          util.showToast('已删除', 'success')
        } catch (err) {
          console.error('删除评论失败', err)
          util.showToast('删除失败, 请重试')
        }
      }
    })
  },

  onDraftInput: function (e) {
    const draft = e.detail.value
    this.setData({ draft: draft, canSend: !!draft.trim() })
  },

  /** 加载照片详情 */
  loadPhoto: async function () {
    try {
      const res = await docGet(photos.doc(this.photoId))
      const raw = res.data
      const openid = app.globalData.openid || this.data.openid
      const photo = util.enrichPhoto(raw)
      this.setData({
        photo: photo,
        liked: (raw.likedBy || []).indexOf(openid) >= 0,
        openid: openid
      })

      // 分享卡片图: cloud:// fileID 需要先换 https 临时链接
      if (raw.photoUrl && raw.photoUrl.indexOf('cloud://') === 0) {
        wx.cloud.getTempFileURL({
          fileList: [raw.photoUrl],
          success: r => {
            const list = r.fileList || []
            if (list[0] && list[0].tempFileURL) {
              this.setData({ shareImg: list[0].tempFileURL })
            }
          },
          fail: err => {
            console.error('获取分享图片链接失败(不影响浏览)', err)
          }
        })
      }
    } catch (err) {
      console.error('加载照片失败', err)
      util.showToast('照片不存在或加载失败')
    }
  },

  /** 记录一次浏览量(失败不影响页面) */
  recordView: function () {
    util.cloudFn('interactPhoto', { action: 'view', photoId: this.photoId })
      .then(r => {
        if (r && r.ok) {
          this.setData({ 'photo.views': (this.data.photo.views || 0) + 1 })
        }
      })
      .catch(err => {
        console.error('记录浏览量失败(不影响页面)', err)
      })
  },

  /** 生命周期函数--监听页面加载 */
  onLoad: async function (options) {
    this.photoId = options.id || ''
    if (!this.photoId) {
      util.showToast('参数错误')
      return
    }
    const openid = await app.ensureOpenid()
    if (this.data.openid !== openid) {
      this.setData({ openid: openid })
    }
    await this.loadPhoto()
    if (this.data.photo) {
      this.recordView()
    }
    this.loadComments()
  },

  /** 用户点击右上角分享给朋友 */
  onShareAppMessage: function () {
    const photo = this.data.photo
    const base = {
      title: (photo && photo.description) || '分享一张好看的图片给你',
      path: '/pages/detail/detail?id=' + (photo ? photo._id : this.photoId)
    }
    if (this.data.shareImg) {
      base.imageUrl = this.data.shareImg
    }
    return base
  },

  /** 分享到朋友圈 */
  onShareTimeline: function () {
    const photo = this.data.photo
    const base = {
      title: (photo && photo.description) || '光影集里的一张好图',
      query: 'id=' + (photo ? photo._id : this.photoId)
    }
    if (this.data.shareImg) {
      base.imageUrl = this.data.shareImg
    }
    return base
  }
})
