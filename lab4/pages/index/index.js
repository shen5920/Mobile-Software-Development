Page({
  data: {
    // 关卡预览图文件名（共16关，8x8 到 12x12 难度递增）
    levelNames: [
      'level01.png', 'level02.png', 'level03.png', 'level04.png',
      'level05.png', 'level06.png', 'level07.png', 'level08.png',
      'level09.png', 'level10.png', 'level11.png', 'level12.png',
      'level13.png', 'level14.png', 'level15.png', 'level16.png'
    ],
    // 关卡列表（含锁定/通关状态）
    levels: [],
    // 已解锁的最大关卡
    unlockedLevel: 1
  },

  /**
   * 构建关卡列表：读取解锁进度和通关记录
   */
  buildLevels: function () {
    let unlocked = wx.getStorageSync('unlocked_level') || 1
    let levels = this.data.levelNames.map(function (name, i) {
      return {
        src: '/images/' + name,
        num: i + 1,
        locked: i + 1 > unlocked,
        // 有最佳步数记录即视为已通关
        done: wx.getStorageSync('best_step_' + i) != ''
      }
    })
    this.setData({ levels: levels, unlockedLevel: unlocked })
  },

  /**
   * 页面显示时刷新解锁/通关状态
   */
  onShow: function () {
    this.buildLevels()
  },

  /**
   * 点击关卡跳转到游戏页（未解锁则提示）
   */
  chooseLevel: function (e) {
    let levelIndex = parseInt(e.currentTarget.dataset.level)
    if (levelIndex + 1 > this.data.unlockedLevel) {
      wx.showToast({ title: '请先通关上一关', icon: 'none' })
      return
    }
    wx.navigateTo({
      url: '../game/game?level=' + levelIndex
    })
  }
})
