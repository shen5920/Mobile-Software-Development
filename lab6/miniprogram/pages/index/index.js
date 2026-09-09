const app = getApp()
const util = require('../../utils/util')
const db = wx.cloud.database()
const photos = db.collection('photos')

const PAGE_SIZE = 10

function queryGet(query) {
  return new Promise((resolve, reject) => {
    query.get({ success: resolve, fail: reject })
  })
}

Page({
  data: {
    photoList: [],
    loading: true,
    loadingMore: false,
    noMore: false,
    openid: '',
    splashOn: true,
    splashScene: true
  },

  /* ================= 开屏动画 ================= */

  /**
   * 页面加载即隐藏底部 Tab, 让开屏动画铺满全屏(动画结束后恢复)
   */
  onLoad: function () {
    wx.hideTabBar({
      animation: false,
      fail: err => {
        console.error('隐藏 TabBar 失败(不影响开屏)', err)
      }
    })
  },

  /**
   * 在页面首次渲染完成时启动(此时 CSS 时间轴动画与 JS 计时器起点对齐):
   * 动画全由 CSS 2.4s 时间轴驱动; JS 只在快门瞬间(约 1450ms)补发音效与震动
   */
  onReady: function () {
    this.startSplash()
  },

  startSplash: function () {
    const audio = wx.createInnerAudioContext()
    audio.src = '/assets/audio/shutter.wav'
    audio.onError(err => {
      console.error('快门音效播放失败(不影响动画)', err)
    })
    this._splashAudio = audio
    this._splashTimer = setTimeout(() => {
      try {
        audio.play()
      } catch (e) {
        // 个别机型播放受限时静默降级为震动
      }
      if (wx.vibrateShort) {
        wx.vibrateShort({ type: 'light' })
      }
    }, 1450)
    // 全白停顿中段撤下背景场景层(白层之下此时已是真实首页)
    this._splashTimer2 = setTimeout(() => {
      this.setData({ splashScene: false })
    }, 1900)
    // 白层淡出完成, 彻底移除开屏
    this._splashTimer3 = setTimeout(() => this.finishSplash(), 2500)
  },

  /** 收尾: 释放音效资源并移除开屏层 */
  finishSplash: function () {
    if (this._splashFinished) return
    this._splashFinished = true
    clearTimeout(this._splashTimer)
    clearTimeout(this._splashTimer2)
    clearTimeout(this._splashTimer3)
    const audio = this._splashAudio
    if (audio) {
      try {
        audio.stop()
      } catch (e) {
        // 忽略
      }
      try {
        audio.destroy()
      } catch (e) {
        // 忽略
      }
      this._splashAudio = null
    }
    this.setData({ splashOn: false, splashScene: false })
    // 开屏结束, 恢复底部 Tab
    wx.showTabBar({
      animation: true,
      fail: err => {
        console.error('恢复 TabBar 失败', err)
      }
    })
  },

  /** 点击跳过动画 */
  skipSplash: function () {
    this.finishSplash()
  },

  /** 锁定开屏期间页面滚动 */
  splashNoop: function () {},

  onUnload: function () {
    // 页面被销毁时同样清理(避免 setData 到已卸载页面)
    this._splashFinished = true
    clearTimeout(this._splashTimer)
    clearTimeout(this._splashTimer2)
    clearTimeout(this._splashTimer3)
    if (this._splashAudio) {
      try {
        this._splashAudio.destroy()
      } catch (e) {
        // 忽略
      }
      this._splashAudio = null
    }
  },

  /** 拉取一页(首页 / 上拉加载更多) */
  fetchPage: async function (skip, append) {
    const query = photos.orderBy('createTime', 'desc').skip(skip).limit(PAGE_SIZE)
    let res
    try {
      res = await queryGet(query)
    } catch (err) {
      console.error('加载图片失败', err)
      this.setData({ loading: false, loadingMore: false })
      wx.stopPullDownRefresh()
      if (this.data.photoList.length === 0) {
        util.showToast('加载失败, 请检查网络')
      }
      return
    }

    const openid = app.globalData.openid || this.data.openid
    const list = res.data.map(item => {
      const photo = util.enrichPhoto(item)
      photo.liked = (item.likedBy || []).indexOf(openid) >= 0
      return photo
    })

    this.setData({
      photoList: append ? this.data.photoList.concat(list) : list,
      loading: false,
      loadingMore: false,
      noMore: list.length < PAGE_SIZE
    })
    wx.stopPullDownRefresh()
  },

  /** 下拉/返回页面时刷新第一页 */
  refresh: async function (showSkeleton) {
    if (showSkeleton) {
      this.setData({ loading: true })
    }
    const openid = await app.ensureOpenid()
    if (this.data.openid !== openid) {
      this.setData({ openid: openid })
    }
    await this.fetchPage(0, false)
  },

  /** 上拉加载更多 */
  loadMore: async function () {
    if (this.data.loading || this.data.loadingMore || this.data.noMore) return
    this.setData({ loadingMore: true })
    await this.fetchPage(this.data.photoList.length, true)
  },

  /**
   * 点击作者头像/昵称:
   * 自己 → 切换到底部「个人」Tab; 他人 → 进入 TA 的主页
   */
  openProfile: function (e) {
    const ds = e.currentTarget.dataset
    const target = ds.id || ''
    const mine = app.globalData.openid || this.data.openid
    if (!target) return

    if (target === mine) {
      wx.switchTab({ url: '/pages/me/me' })
      return
    }
    const base = '/pages/homepage/homepage?id=' + encodeURIComponent(target)
    const extra =
      '&name=' + encodeURIComponent(ds.name || '') +
      '&avatar=' + encodeURIComponent(ds.avatar || '') +
      '&province=' + encodeURIComponent(ds.province || '') +
      '&country=' + encodeURIComponent(ds.country || '')
    wx.navigateTo({ url: base + extra })
  },

  /**
   * 上传入口: 需先登录(在「个人」页设置头像昵称), 未登录引导去登录
   */
  goToAdd: function () {
    const u = app.globalData.userInfo
    const loggedIn = !!(u && u.nickName)
    if (!loggedIn) {
      wx.showModal({
        title: '请先登录',
        content: '在「个人」页设置头像与昵称后, 即可发布你的光影瞬间',
        confirmText: '去登录',
        cancelText: '再逛逛',
        confirmColor: '#667eea',
        success: res => {
          if (res.confirm) {
            wx.switchTab({ url: '/pages/me/me' })
          }
        }
      })
      return
    }
    wx.navigateTo({ url: '../add/add' })
  },

  /**
   * 点赞/取消点赞(走云函数: openid 由服务端上下文取, 无需客户端先登录)
   */
  toggleLike: async function (e) {
    const id = e.currentTarget.dataset.id
    const index = e.currentTarget.dataset.index
    const item = this.data.photoList[index]
    if (!item) return

    const wantLike = !item.liked
    const prevLiked = item.liked
    const prevLikes = item.likes || 0

    // 乐观更新
    this.patchItem(index, {
      liked: wantLike,
      likes: Math.max(0, prevLikes + (wantLike ? 1 : -1))
    })

    try {
      const r = await util.cloudFn('interactPhoto', {
        action: wantLike ? 'like' : 'unlike',
        photoId: id
      })
      if (r && r.ok) {
        // 以服务端返回校准(防止多端并发造成计数漂移)
        this.patchItem(index, { liked: r.liked, likes: r.likes })
      } else {
        this.patchItem(index, { liked: prevLiked, likes: prevLikes })
        util.showToast((r && r.msg) || '操作失败, 请重试')
      }
    } catch (err) {
      console.error('点赞失败', err)
      this.patchItem(index, { liked: prevLiked, likes: prevLikes })
      util.cloudHint()
      util.showToast('操作失败, 请重试')
    }
  },

  /** 局部更新列表某一项 */
  patchItem: function (index, patch) {
    const list = this.data.photoList.slice()
    if (list[index]) {
      list[index] = Object.assign({}, list[index], patch)
      this.setData({ photoList: list })
    }
  },

  /**
   * 删除照片(走云函数: 记录 + 评论 + 云文件 一次清理)
   */
  deletePhoto: function (e) {
    const id = e.currentTarget.dataset.id
    const index = e.currentTarget.dataset.index

    wx.showModal({
      title: '删除照片',
      content: '照片、评论记录将一并删除且不可恢复, 确定删除吗?',
      confirmText: '删除',
      confirmColor: '#f5576c',
      success: async res => {
        if (!res.confirm) return
        wx.showLoading({ title: '删除中...', mask: true })
        try {
          const r = await util.cloudFn('interactPhoto', {
            action: 'delete',
            photoId: id
          })
          wx.hideLoading()
          if (r && r.ok) {
            const list = this.data.photoList.slice()
            list.splice(index, 1)
            this.setData({ photoList: list })
            wx.showToast({ title: '已删除', icon: 'success' })
          } else {
            util.showToast((r && r.msg) || '删除失败, 请重试')
          }
        } catch (err) {
          wx.hideLoading()
          console.error('删除照片失败', err)
          util.cloudHint()
          util.showToast('删除失败, 请重试')
        }
      }
    })
  },

  /**
   * 回到首页时原地同步(不重置分页位置):
   * 拉取与已加载数量相当的最新数据, 按服务器顺序重建列表
   * (新发布自动插到前面, 被删除的自动消失, 点赞/浏览状态原地刷新), 尾部超出深度的旧项保留
   */
  syncInPlace: async function () {
    const openid = await app.ensureOpenid()
    if (this.data.openid !== openid) {
      this.setData({ openid: openid })
    }
    const current = this.data.photoList
    if (current.length === 0) return
    const pages = Math.max(1, Math.ceil(current.length / PAGE_SIZE))
    const fetchedItems = []
    for (let i = 0; i < pages; i++) {
      const query = photos.orderBy('createTime', 'desc').skip(i * PAGE_SIZE).limit(PAGE_SIZE)
      try {
        const res = await queryGet(query)
        fetchedItems.push.apply(fetchedItems, res.data)
      } catch (err) {
        console.error('同步列表失败(保留原列表)', err)
        return
      }
    }
    const seen = {}
    const next = []
    fetchedItems.forEach(item => {
      if (seen[item._id]) return
      seen[item._id] = 1
      const photo = util.enrichPhoto(item)
      photo.liked = (item.likedBy || []).indexOf(openid) >= 0
      next.push(photo)
    })
    current.forEach(item => {
      if (!seen[item._id]) next.push(item)
    })
    this.setData({ photoList: next })
  },

  /** 生命周期函数--监听页面显示(返回本页/首次进入) */
  onShow: function () {
    if (this.data.photoList.length === 0) {
      this.refresh(true)
    } else {
      this.syncInPlace()
    }
  },

  /**
   * 页面相关事件处理函数--监听用户下拉动作(全量刷新第一页)
   */
  onPullDownRefresh: function () {
    this.refresh(false)
  },

  /**
   * 页面上拉触底
   */
  onReachBottom: function () {
    this.loadMore()
  }
})
