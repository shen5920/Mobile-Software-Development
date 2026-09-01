// pages/index/index.js
var common = require('../../utils/common.js') // 引用公共JS文件
var store = require('../../utils/store.js') // 引用缓存模块
Page({

  /**
   * 页面的初始数据
   */
  data: {
    // 幻灯片素材（跟随当前分类，只含有图新闻）
    swiperImg: [],
    // 新闻分类
    categories: [],
    // 当前选中的分类
    currentCategory: '海大要闻',
    // 新闻列表
    newsList: [],
    // 搜索关键词
    searchKeyword: '',
    // 是否处于搜索状态
    searching: false,
    // 排序方式：time-desc 最新优先 / time-asc 最早优先 / default 默认顺序
    sortType: 'time-desc',
    // 排序选项
    sortOptions: [
      { key: 'time-desc', label: '最新优先' },
      { key: 'time-asc', label: '最早优先' },
      { key: 'default', label: '默认顺序' }
    ],
    // 时间筛选：all / today / week / month / 具体日期 YYYY-MM-DD
    timeFilter: 'all',
    // 筛选按钮显示文字
    filterLabel: '筛选',
    // 是否展开筛选面板
    showFilter: false,
    // 日期选择器的值
    pickerDate: ''
  },

  /**
   * 自定义函数--排序
   */
  sortList: function (list, sortType) {
    let sorted = list.slice();
    if (sortType === 'time-desc') {
      sorted.sort(function (a, b) {
        return a.add_date < b.add_date ? 1 : -1;
      });
    } else if (sortType === 'time-asc') {
      sorted.sort(function (a, b) {
        return a.add_date > b.add_date ? 1 : -1;
      });
    }
    return sorted;
  },

  /**
   * 自定义函数--日期格式化 YYYY-MM-DD
   */
  formatDate: function (d) {
    let m = d.getMonth() + 1
    let day = d.getDate()
    return d.getFullYear() + '-' + (m < 10 ? '0' + m : m) + '-' + (day < 10 ? '0' + day : day)
  },

  /**
   * 自定义函数--获取本周范围（周一到周日）
   */
  getWeekRange: function (now) {
    let d = new Date(now.getFullYear(), now.getMonth(), now.getDate())
    let day = d.getDay()
    let mondayOffset = day === 0 ? -6 : (1 - day)
    let monday = new Date(d.getFullYear(), d.getMonth(), d.getDate() + mondayOffset)
    let sunday = new Date(monday.getFullYear(), monday.getMonth(), monday.getDate() + 6)
    return { start: this.formatDate(monday), end: this.formatDate(sunday) }
  },

  /**
   * 自定义函数--按时间筛选
   */
  filterByTime: function (list, filter) {
    if (!filter || filter === 'all') return list
    let todayStr = this.formatDate(new Date())
    if (filter === 'today') {
      return list.filter(function (n) { return n.add_date === todayStr })
    }
    if (filter === 'week') {
      let range = this.getWeekRange(new Date())
      return list.filter(function (n) { return n.add_date >= range.start && n.add_date <= range.end })
    }
    if (filter === 'month') {
      let ym = todayStr.slice(0, 7)
      return list.filter(function (n) { return n.add_date.indexOf(ym) === 0 })
    }
    return list.filter(function (n) { return n.add_date === filter })
  },

  /**
   * 自定义函数--标注点赞状态
   */
  annotateLikes: function (list) {
    return list.map(function (item) {
      item.liked = store.isLiked(item.id)
      return item
    })
  },

  /**
   * 自定义函数--渲染新闻列表
   */
  renderNewsList: function () {
    let list = this.filterByTime(this._baseList, this.data.timeFilter)
    list = this.annotateLikes(this.sortList(list, this.data.sortType))
    this.setData({ newsList: list })
  },

  /**
   * 自定义函数--切换排序
   */
  changeSort: function (e) {
    this.setData({ sortType: e.currentTarget.dataset.sort })
    this.renderNewsList()
  },

  /**
   * 自定义函数--切换分类
   */
  switchCategory: function (e) {
    let category = e.currentTarget.dataset.category;
    this._baseList = common.getNewsList(category)
    this.setData({
      currentCategory: category,
      swiperImg: common.getSwiperList(category)
    })
    this.renderNewsList()
  },

  /**
   * 自定义函数--搜索输入
   */
  onSearchInput: function (e) {
    let keyword = e.detail.value.trim();
    if (keyword.length > 0) {
      this._baseList = common.searchNews(keyword)
      this.setData({
        searchKeyword: keyword,
        searching: true
      })
    } else {
      this._baseList = common.getNewsList(this.data.currentCategory)
      this.setData({
        searchKeyword: '',
        searching: false,
        swiperImg: common.getSwiperList(this.data.currentCategory)
      })
    }
    this.renderNewsList()
  },

  /**
   * 自定义函数--展开/收起筛选面板
   */
  toggleFilterPanel: function () {
    this.setData({ showFilter: !this.data.showFilter })
  },

  /**
   * 自定义函数--快捷时间筛选
   */
  setTimeFilter: function (e) {
    this.applyTimeFilter(e.currentTarget.dataset.filter)
  },

  /**
   * 自定义函数--日历选择日期
   */
  onDateChange: function (e) {
    this.setData({ pickerDate: e.detail.value })
    this.applyTimeFilter(e.detail.value)
  },

  /**
   * 自定义函数--应用时间筛选
   */
  applyTimeFilter: function (filter) {
    this.setData({
      timeFilter: filter,
      filterLabel: this.getFilterLabel(filter),
      showFilter: false
    })
    this.renderNewsList()
  },

  /**
   * 自定义函数--获取筛选按钮文字
   */
  getFilterLabel: function (filter) {
    if (filter === 'all') return '筛选'
    if (filter === 'today') return '今日'
    if (filter === 'week') return '本周'
    if (filter === 'month') return '本月'
    return filter.slice(5)
  },

  /**
   * 自定义函数--点赞 / 取消点赞（列表）
   */
  toggleLike: function (e) {
    if (!getApp().globalData.isLogin) {
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
      return
    }
    let id = e.currentTarget.dataset.id
    let item = null
    for (let i = 0; i < this.data.newsList.length; i++) {
      if (this.data.newsList[i].id === id) {
        item = this.data.newsList[i]
        break
      }
    }
    if (!item) return
    if (store.isLiked(id)) {
      store.removeLike(id)
    } else {
      store.addLike({
        id: item.id,
        poster: item.poster,
        add_date: item.add_date,
        title: item.title,
        category: item.category
      })
    }
    this.renderNewsList()
  },

  /**
   * 自定义函数--跳转新页面浏览新闻内容
   */
  goToDetail: function (e) {
    // 获取携带的data-id数据
    let id = e.currentTarget.dataset.id;
    // 携带新闻id进行页面跳转
    wx.navigateTo({
      url: '../detail/detail?id=' + id
    });
  },

  /**
   * 自定义函数--点击轮播图跳转详情
   */
  goToDetailFromSwiper: function (e) {
    let id = e.currentTarget.dataset.id;
    wx.navigateTo({
      url: '../detail/detail?id=' + id
    });
  },

  /**
   * 生命周期函数--监听页面加载
   */
  onLoad: function (options) {
    // 获取分类列表
    let categories = common.getCategories();
    this._baseList = common.getNewsList(this.data.currentCategory)
    this.setData({
      categories: categories,
      swiperImg: common.getSwiperList(this.data.currentCategory),
      pickerDate: this.formatDate(new Date())
    })
    this.renderNewsList()
  }
})
