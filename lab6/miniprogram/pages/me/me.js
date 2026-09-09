const app = getApp()
const util = require('../../utils/util')
const db = wx.cloud.database()
const photos = db.collection('photos')

const PAGE_SIZE = 10
const LIKE_PAGE_SIZE = 12

function queryGet(query) {
  return new Promise((resolve, reject) => {
    query.get({ success: resolve, fail: reject })
  })
}

/** 是否已登录(设置过头像或昵称) */
function isLoggedIn() {
  const u = app.globalData.userInfo
  return !!(u && u.nickName)
}

/** 本地文件路径安全取扩展名 */
function safeExt(path) {
  const m = String(path || '').match(/\.(png|jpe?g|gif|webp)$/i)
  return m ? m[0] : '.jpg'
}

Page({
  data: {
    loggedIn: false,
    editing: false,
    activeTab: 'works',
    // 登录/编辑表单
    loginNick: '',
    avatarDraft: '',
    avatarSrc: '',
    loginLetter: '影',
    loginBg: '',
    // 已登录后的主页数据
    profile: null,
    works: 0,
    totalLikes: 0,
    photoList: [],
    loading: true,
    loaded: false,
    loadingMore: false,
    noMore: false,
    // 我的点赞
    likedList: [],
    likedTotal: 0,
    likedLoaded: false,
    likedLoading: false,
    likedLoadingMore: false,
    likedNoMore: false
  },

  /* ========== 登录 / 资料编辑 ========== */

  /** 由全局用户资料派生主页头部 */
  profileFromUser: function () {
    const u = app.globalData.userInfo || {}
    const nick = (u.nickName || '').trim() || util.DEFAULT_NAME
    return {
      nickName: nick,
      avatarUrl: u.avatarUrl || '',
      letter: util.letterOf(nick),
      avatarBg: util.avatarBg(nick),
      address: util.regionText(u.province, u.country)
    }
  },

  /** 选择微信头像(临时路径, 登录时上传云存储) */
  onChooseAvatar: function (e) {
    const url = e.detail.avatarUrl || ''
    if (!url) return
    this.setData({ avatarDraft: url, avatarSrc: url })
  },

  /** 昵称输入(type=nickname 触发微信键盘) */
  onNickInput: function (e) {
    const nick = e.detail.value || ''
    this.setData({
      loginNick: nick,
      loginLetter: util.letterOf(nick),
      loginBg: util.avatarBg(nick)
    })
  },

  /** 打开编辑(预填当前资料) */
  startEdit: function () {
    const u = app.globalData.userInfo || {}
    this.setData({
      editing: true,
      loginNick: u.nickName || '',
      avatarDraft: '',
      avatarSrc: u.avatarUrl || ''
    })
  },

  cancelEdit: function () {
    this.setData({ editing: false })
  },

  /** 退出登录(二次确认后清除头像昵称档案, 回到登录卡) */
  doLogout: function () {
    wx.showModal({
      title: '退出登录',
      content: '退出后仍可浏览与点赞, 但发布作品需要重新设置头像昵称',
      confirmText: '退出',
      cancelText: '再想想',
      confirmColor: '#f5576c',
      success: res => {
        if (!res.confirm) return
        app.logout()
        this._openid = null
        this.setData({
          loggedIn: false,
          editing: false,
          activeTab: 'works',
          profile: null,
          photoList: [],
          works: 0,
          totalLikes: 0,
          loading: false,
          loaded: true,
          likedList: [],
          likedTotal: 0,
          likedLoaded: false,
          likedLoading: false,
          likedLoadingMore: false,
          likedNoMore: false,
          loginNick: '',
          avatarDraft: '',
          avatarSrc: '',
          loginLetter: '影',
          loginBg: ''
        })
        wx.showToast({ title: '已退出登录' })
      }
    })
  },

  /**
   * 登录 / 保存资料:
   * 头像临时路径 → 云存储 → 全局缓存, 之后即视为已登录
   */
  saveProfile: async function () {
    const wasEditing = this.data.editing
    const nick = (this.data.loginNick || '').trim()
    const avatarDraft = this.data.avatarDraft
    const oldUser = app.globalData.userInfo || {}

    if (!nick && !avatarDraft) {
      util.showToast('请选择微信头像或输入昵称')
      return
    }

    wx.showLoading({ title: '保存中...', mask: true })
    const openid = await app.ensureOpenid()
    this._openid = openid
    try {
      if (!openid) {
        wx.hideLoading()
        util.cloudHint()
        return
      }
      let avatarUrl = oldUser.avatarUrl || ''
      if (avatarDraft) {
        const cloudPath = 'avatars/' + openid + '_' + Date.now() + safeExt(avatarDraft)
        const up = await new Promise((resolve, reject) => {
          wx.cloud.uploadFile({
            cloudPath: cloudPath,
            filePath: avatarDraft,
            success: resolve,
            fail: reject
          })
        })
        avatarUrl = up.fileID
      }

      const finalName = nick || oldUser.nickName || util.DEFAULT_NAME
      app.setUserProfile({ nickName: finalName, avatarUrl: avatarUrl })

      this.setData({
        loggedIn: true,
        editing: false,
        loginNick: finalName,
        avatarDraft: '',
        avatarSrc: avatarUrl,
        profile: this.profileFromUser()
      })
      wx.hideLoading()
      wx.showToast({ title: wasEditing ? '资料已保存' : '登录成功 🎉', icon: 'success' })
      this.enterHome()
    } catch (err) {
      wx.hideLoading()
      console.error('保存资料失败', err)
      util.showToast('保存失败, 请重试')
    }
  },

  /* ========== 已登录主页数据 ========== */

  /** 首次登录/刷新时加载作品数据 */
  enterHome: function () {
    this.setData({ loading: true, loaded: false })
    this.fetchStat()
    this.fetchPage(0, false)
    this.refreshLikedCount()
  },

  /** 作品数/获赞(云函数聚合) */
  fetchStat: function () {
    if (!this._openid) return
    util.cloudFn('interactPhoto', { action: 'stat', owner: this._openid })
      .then(r => {
        if (r && r.ok) {
          this.setData({ works: r.works || 0, totalLikes: r.totalLikes || 0 })
        }
      })
      .catch(err => {
        console.error('获取统计失败(不影响列表)', err)
      })
  },

  /** 拉取一页自己的作品 */
  fetchPage: async function (skip, append) {
    if (!this._openid) {
      this.setData({ loading: false, loaded: true, loadingMore: false })
      return
    }
    const query = photos
      .where({ _openid: this._openid })
      .orderBy('createTime', 'desc')
      .skip(skip)
      .limit(PAGE_SIZE)
    try {
      const res = await queryGet(query)
      const list = res.data.map(item => util.enrichPhoto(item))
      this.setData({
        photoList: append ? this.data.photoList.concat(list) : list,
        loading: false,
        loaded: true,
        loadingMore: false,
        noMore: list.length < PAGE_SIZE
      })
      wx.stopPullDownRefresh()
    } catch (err) {
      console.error('加载作品失败', err)
      this.setData({ loading: false, loaded: true, loadingMore: false })
      wx.stopPullDownRefresh()
      if (this.data.photoList.length === 0) {
        util.showToast('加载失败, 请检查网络')
      }
    }
  },

  /** 页面显示时原地同步(新作品插入/已删作品消失/状态刷新, 不重置分页) */
  syncInPlace: async function () {
    const current = this.data.photoList
    if (current.length === 0) return
    const pages = Math.max(1, Math.ceil(current.length / PAGE_SIZE))
    const fetchedItems = []
    for (let i = 0; i < pages; i++) {
      const query = photos
        .where({ _openid: this._openid })
        .orderBy('createTime', 'desc')
        .skip(i * PAGE_SIZE)
        .limit(PAGE_SIZE)
      try {
        const res = await queryGet(query)
        fetchedItems.push.apply(fetchedItems, res.data)
      } catch (err) {
        console.error('同步作品列表失败(保留原列表)', err)
        return
      }
    }
    const seen = {}
    const next = []
    fetchedItems.forEach(item => {
      if (seen[item._id]) return
      seen[item._id] = 1
      next.push(util.enrichPhoto(item))
    })
    current.forEach(item => {
      if (!seen[item._id]) next.push(item)
    })
    this.setData({ photoList: next })
    this.fetchStat()
  },

  /* ========== 我的点赞 ========== */

  /** 切换 作品/点赞 分段 */
  switchTab: function (e) {
    const tab = e.currentTarget.dataset.tab
    if (!tab || tab === this.data.activeTab) return
    this.setData({ activeTab: tab })
    if (tab !== 'likes') return
    if (!this.data.likedLoaded) {
      this.fetchLikes(true)
    } else {
      this.syncLikesInPlace()
    }
  },

  /**
   * 拉取一页我点赞的照片
   * 走云函数 interactPhoto.myLikes(服务端以当前登录身份查询, 不受集合权限限制)
   */
  fetchLikes: async function (reset) {
    if (!this.data.loggedIn) {
      this.setData({ likedLoading: false, likedLoadingMore: false })
      return
    }
    if (reset) {
      this.setData({ likedLoading: true })
    }
    const skip = reset ? 0 : this.data.likedList.length
    try {
      const r = await util.cloudFn('interactPhoto', {
        action: 'myLikes',
        skip: skip,
        limit: LIKE_PAGE_SIZE
      })
      if (!r || !r.ok) throw new Error((r && r.msg) || '查询失败')
      const total = r.total || 0
      const page = r.list || []
      const list = reset ? page : this.data.likedList.concat(page)
      this.setData({
        likedList: list,
        likedTotal: total,
        likedLoaded: true,
        likedLoading: false,
        likedLoadingMore: false,
        likedNoMore: list.length >= total
      })
    } catch (err) {
      console.error('加载点赞列表失败', err)
      this.setData({ likedLoading: false, likedLoadingMore: false })
      if (reset && this.data.likedList.length === 0) {
        util.showToast('加载失败, 请检查云端配置')
      }
    }
  },

  /** 点赞墙原地同步(取消赞/照片被删自动消失, 新点赞插入, 不重置位置) */
  syncLikesInPlace: async function () {
    const current = this.data.likedList
    if (current.length === 0) {
      this.fetchLikes(true)
      return
    }
    const pages = Math.max(1, Math.ceil(current.length / LIKE_PAGE_SIZE))
    const fetchedItems = []
    for (let i = 0; i < pages; i++) {
      try {
        const r = await util.cloudFn('interactPhoto', {
          action: 'myLikes',
          skip: i * LIKE_PAGE_SIZE,
          limit: LIKE_PAGE_SIZE
        })
        if (!r || !r.ok) throw new Error((r && r.msg) || '查询失败')
        fetchedItems.push.apply(fetchedItems, r.list || [])
      } catch (err) {
        console.error('同步点赞列表失败(保留原列表)', err)
        return
      }
    }
    const seen = {}
    const next = []
    fetchedItems.forEach(item => {
      if (seen[item._id]) return
      seen[item._id] = 1
      next.push(item)
    })
    current.forEach(item => {
      if (!seen[item._id]) next.push(item)
    })
    this.setData({ likedList: next })
    this.refreshLikedCount()
  },

  /** 刷新点赞总数(列表未加载过时也保持分段计数准确) */
  refreshLikedCount: async function () {
    if (!this.data.loggedIn) return
    try {
      const r = await util.cloudFn('interactPhoto', { action: 'myLikes', countOnly: true })
      if (r && r.ok) {
        this.setData({ likedTotal: r.total || 0 })
      }
    } catch (err) {
      console.error('刷新点赞计数失败', err)
    }
  },

  /** 点击点赞墙某张照片 → 详情页(可在详情里取消赞) */
  openLikedDetail: function (e) {
    wx.navigateTo({ url: '../detail/detail?id=' + e.currentTarget.dataset.id })
  },

  /** 加载更多 */
  loadMore: function () {
    if (this.data.loading || this.data.loadingMore || this.data.noMore) return
    this.setData({ loadingMore: true })
    this.fetchPage(this.data.photoList.length, true)
  },

  /** 删除作品(云函数级联清理) */
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
          const r = await util.cloudFn('interactPhoto', { action: 'delete', photoId: id })
          wx.hideLoading()
          if (r && r.ok) {
            const list = this.data.photoList.slice()
            list.splice(index, 1)
            this.setData({ photoList: list, works: Math.max(0, this.data.works - 1) })
            wx.showToast({ title: '已删除', icon: 'success' })
            this.fetchStat()
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

  /** 生命周期函数--首次加载 */
  onLoad: async function () {
    const loggedIn = isLoggedIn()
    this.setData({
      loggedIn: loggedIn,
      profile: loggedIn ? this.profileFromUser() : null,
      loginNick: (app.globalData.userInfo && app.globalData.userInfo.nickName) || '',
      avatarSrc: (app.globalData.userInfo && app.globalData.userInfo.avatarUrl) || ''
    })
    if (!loggedIn) {
      this.setData({ loading: false, loaded: true })
      return
    }
    const openid = await app.ensureOpenid()
    this._openid = openid
    if (!openid) {
      this.setData({ loading: false, loaded: true })
      return
    }
    this.fetchStat()
    this.fetchPage(0, false)
    this.refreshLikedCount()
  },

  /** 每次切回本 Tab: 登录状态可能变化(如在首页被引导来登录) */
  onShow: async function () {
    if (!this._inited) {
      this._inited = true
      return // 首次展示由 onLoad 负责
    }
    const loggedIn = isLoggedIn()
    const patch = { loggedIn: loggedIn }
    if (loggedIn) {
      patch.profile = this.profileFromUser()
      if (!this._openid) {
        this._openid = await app.ensureOpenid()
      }
      if (this.data.photoList.length === 0 && !this.data.loading) {
        patch.loading = true
        this.setData(patch)
        this.fetchStat()
        this.fetchPage(0, false)
        this.refreshLikedCount()
        return
      }
      this.setData(patch)
      this.syncInPlace()
      // 点赞数据已加载过则一并同步(可能在详情页取消了赞/点了新赞)
      if (this.data.likedLoaded) {
        this.syncLikesInPlace()
      } else {
        this.refreshLikedCount()
      }
    } else {
      patch.profile = null
      patch.photoList = []
      patch.likedList = []
      patch.likedLoaded = false
      this.setData(patch)
    }
  },

  onPullDownRefresh: function () {
    if (!this.data.loggedIn) {
      wx.stopPullDownRefresh()
      return
    }
    if (this.data.activeTab === 'likes') {
      this.fetchLikes(true)
      return
    }
    this.fetchPage(0, false)
  },

  onReachBottom: function () {
    if (!this.data.loggedIn) return
    if (this.data.activeTab === 'likes') {
      if (!this.data.likedLoaded || this.data.likedLoading || this.data.likedLoadingMore || this.data.likedNoMore) return
      this.setData({ likedLoadingMore: true })
      this.fetchLikes(false)
      return
    }
    this.loadMore()
  }
})
