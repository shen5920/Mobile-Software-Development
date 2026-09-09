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

function safeDecode(v) {
  if (!v) return ''
  try {
    return decodeURIComponent(v)
  } catch (e) {
    return v
  }
}

Page({
  data: {
    profile: null,
    works: 0,
    totalLikes: 0,
    photoList: [],
    loading: true,
    loaded: false,
    loadingMore: false,
    noMore: false,
    mine: false
  },

  /** 拉取一页作品 */
  fetchPage: async function (skip, append) {
    const query = photos
      .where({ _openid: this.targetOpenid })
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

      // 第一页到达后, 若导航参数没带资料, 用最新一条作品补全主页头部
      if (skip === 0 && !this.data.profile && list.length > 0) {
        this.setData({
          profile: this.buildProfileFrom(list[0])
        })
      }
    } catch (err) {
      console.error('加载作品失败', err)
      this.setData({ loading: false, loaded: true, loadingMore: false })
      wx.stopPullDownRefresh()
      if (this.data.photoList.length === 0) {
        util.showToast('加载失败, 请检查网络')
      }
    }
  },

  /** 由照片记录派生主页头部资料 */
  buildProfileFrom: function (photo) {
    return {
      nickName: photo.nickName,
      avatarUrl: photo.avatarUrl,
      letter: photo.letter,
      avatarBg: photo.avatarBg,
      address: photo.address
    }
  },

  /** 刷新作品数/获赞(删除后保持统计准确) */
  refreshStat: function () {
    util.cloudFn('interactPhoto', { action: 'stat', owner: this.targetOpenid })
      .then(r => {
        if (r && r.ok) {
          this.setData({ works: r.works || 0, totalLikes: r.totalLikes || 0 })
        }
      })
      .catch(err => {
        console.error('刷新统计失败', err)
      })
  },

  /** 加载更多 */
  loadMore: function () {
    if (this.data.loading || this.data.loadingMore || this.data.noMore) return
    this.setData({ loadingMore: true })
    this.fetchPage(this.data.photoList.length, true)
  },

  /** 删除自己的作品(本人主页) */
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
            this.setData({
              photoList: list,
              works: Math.max(0, this.data.works - 1)
            })
            wx.showToast({ title: '已删除', icon: 'success' })
            this.refreshStat()
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
   * 参数: id(openid) name avatar province country (来自导航时的编码参数)
   */
  onLoad: async function (options) {
    this.targetOpenid = (options.id || '').trim()
    if (!this.targetOpenid) {
      util.showToast('参数错误')
      this.setData({ loading: false })
      return
    }

    // 导航参数里的资料作为主页头部兜底(即使 TA 还没发过作品也能看到主页)
    const navProfile = {
      nickName: safeDecode(options.name) || util.DEFAULT_NAME,
      avatarUrl: safeDecode(options.avatar),
      province: safeDecode(options.province),
      country: safeDecode(options.country)
    }
    if (navProfile.nickName || navProfile.avatarUrl) {
      this.setData({
        profile: {
          nickName: navProfile.nickName,
          avatarUrl: navProfile.avatarUrl,
          letter: util.letterOf(navProfile.nickName),
          avatarBg: util.avatarBg(navProfile.nickName),
          address: util.regionText(navProfile.province, navProfile.country)
        }
      })
    }

    const myOpenid = await app.ensureOpenid()
    this.setData({ mine: !!myOpenid && myOpenid === this.targetOpenid })

    // 作品数 + 总获赞(服务端聚合, 不受单次 20 条限制)
    util.cloudFn('interactPhoto', { action: 'stat', owner: this.targetOpenid })
      .then(r => {
        if (r && r.ok) {
          this.setData({ works: r.works || 0, totalLikes: r.totalLikes || 0 })
        }
      })
      .catch(err => {
        console.error('获取统计失败(不影响列表)', err)
      })

    this.fetchPage(0, false)
  },

  /** 页面显示时原地同步(新作品插入/已删作品消失/状态刷新, 不重置分页) */
  syncInPlace: async function () {
    const current = this.data.photoList
    if (current.length === 0) return
    const pages = Math.max(1, Math.ceil(current.length / PAGE_SIZE))
    const fetchedItems = []
    for (let i = 0; i < pages; i++) {
      const query = photos
        .where({ _openid: this.targetOpenid })
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
    this.refreshStat()
  },

  onShow: function () {
    if (!this.data.loading && this.data.photoList.length > 0) {
      this.syncInPlace()
    }
  },

  onPullDownRefresh: function () {
    this.fetchPage(0, false)
  },

  onReachBottom: function () {
    this.loadMore()
  }
})
