// 引入关卡数据
var data = require('../../utils/data.js')

// 各关卡困难模式限时（秒）：1-4关60秒，5-8关90秒，9-12关120秒，13-16关150秒
function getLevelTimeLimit(levelIndex) {
  return 60 + Math.floor(levelIndex / 4) * 30
}

// 地图图层、箱子图层（尺寸在 initMap 时按关卡动态创建）
var map = []
var box = []
// 当前关卡的行数/列数
var rows = 0
var cols = 0

// 画布尺寸（px）
var canvasSize = 320
// 单个方块像素宽度（按地图尺寸动态计算）
var blockSize = 40
// 绘制起点偏移（居中）
var offsetX = 0
var offsetY = 0

// 主角（小鸟）坐标：行、列
var playerRow = 0
var playerCol = 0

// 悔棋历史栈（最多20步）
var historyStack = []
// 本局操作记录（方向字符串 up/down/left/right，用于回放）
var moveRecord = []

// 触摸起点坐标（clientX/Y 用于滑动方向，x/y 为相对画布的坐标用于点格子）
var touchStartX = 0
var touchStartY = 0
var touchStartCellX = 0
var touchStartCellY = 0

// 游戏音效
var moveAudio = wx.createInnerAudioContext()
moveAudio.src = '/images/sounds/move.wav'
var pushAudio = wx.createInnerAudioContext()
pushAudio.src = '/images/sounds/push.wav'
var winAudio = wx.createInnerAudioContext()
winAudio.src = '/images/sounds/win.wav'

Page({
  data: {
    level: 1,        // 当前显示的关卡数
    mode: 'easy',    // 难度模式：easy | hard
    steps: 0,        // 当前步数
    bestStep: '--',  // 历史最佳步数
    timeText: '0秒',  // 本局已用时间
    countdown: 60,    // 剩余时间（困难模式）
    timeLimit: 60,    // 本关困难模式限时（秒）
    replaying: false, // 是否正在操作回放
    showModeModal: true // 是否显示难度模式选择弹窗
  },

  /**
   * 页面加载：接收关卡与难度参数，初始化游戏
   */
  onLoad: function(options) {
    let levelIndex = parseInt(options.level)
    // 难度模式：分享进入时携带 mode 参数，否则读缓存
    let mode = options.mode || wx.getStorageSync('game_mode') || 'easy'
    // 本关限时：1-4关60秒、5-8关90秒、9-12关120秒、13-16关150秒
    let timeLimit = getLevelTimeLimit(levelIndex)
    this._timeLimit = timeLimit
    this.setData({
      level: levelIndex + 1,
      mode: mode,
      steps: 0,
      timeLimit: timeLimit,
      countdown: timeLimit,
      showModeModal: true
    })

    // 初始化地图数据（画布在难度弹窗关闭后才创建，避免原生 canvas 盖住弹窗）
    this.initMap(levelIndex)

    // 读取本地最佳步数
    let best = wx.getStorageSync('best_step_' + levelIndex)
    this.setData({ bestStep: best || '--' })
    // 计时器在玩家于弹窗确认难度后才启动
  },

  /**
   * 页面卸载：清除定时器，防止内存泄漏
   */
  onUnload: function() {
    this.stopTimer()
    if (this._replayTimer) clearInterval(this._replayTimer)
  },

  /**
   * 初始化地图数据：按关卡尺寸动态创建图层，分离地图、箱子、玩家位置
   */
  initMap: function(levelIndex) {
    let originMap = data.maps[levelIndex]
    historyStack = [] // 清空悔棋历史
    moveRecord = []   // 清空操作记录

    rows = originMap.length
    cols = originMap[0].length
    // 计算方块大小并居中
    blockSize = Math.floor(canvasSize / Math.max(rows, cols))
    offsetX = Math.floor((canvasSize - blockSize * cols) / 2)
    offsetY = Math.floor((canvasSize - blockSize * rows) / 2)

    map = []
    box = []
    for (var i = 0; i < rows; i++) {
      map.push([])
      box.push([])
      for (var j = 0; j < cols; j++) {
        box[i].push(0)
        map[i].push(originMap[i][j])

        // 提取箱子到独立图层（6 表示箱子已经在终点上）
        if (originMap[i][j] === 4 || originMap[i][j] === 6) {
          box[i][j] = 4
          map[i][j] = originMap[i][j] === 6 ? 3 : 2
        }
        // 提取玩家位置
        else if (originMap[i][j] === 5) {
          map[i][j] = 2  // 原位置改为路面
          playerRow = i
          playerCol = j
        }
      }
    }
    this.setData({ steps: 0 })
  },

  /**
   * 启动计时器：简单模式累计已用时间；困难模式额外倒计时
   */
  startTimer: function() {
    this.stopTimer()
    this._startTime = Date.now()
    this._won = false
    this.setData({ timeText: '0秒', countdown: this._timeLimit })
    let that = this
    this._timer = setInterval(function() {
      let elapsed = Math.floor((Date.now() - that._startTime) / 1000)
      that.setData({ timeText: that.formatSeconds(elapsed) })
      if (that.data.mode === 'hard') {
        let remain = that._timeLimit - elapsed
        if (remain <= 0) {
          that.stopTimer()
          that.onTimeUp()
          return
        }
        that.setData({ countdown: remain })
      }
    }, 1000)
  },

  /**
   * 停止计时器
   */
  stopTimer: function() {
    if (this._timer) {
      clearInterval(this._timer)
      this._timer = null
    }
  },

  /**
   * 秒数格式化：xx秒 / x分x秒
   */
  formatSeconds: function(s) {
    return s >= 60 ? Math.floor(s / 60) + '分' + (s % 60) + '秒' : s + '秒'
  },

  /**
   * 困难模式超时：挑战失败
   */
  onTimeUp: function() {
    if (this._won) return
    wx.showModal({
      title: '时间耗尽',
      content: '挑战失败！',
      confirmText: '重新开始',
      cancelText: '返回选关',
      success: (res) => {
        if (res.confirm) this.restartGame()
        else this.goHome()
      }
    })
  },

  /**
   * 难度弹窗：选择模式（简单/困难）
   */
  onModeSelect: function(e) {
    this.setData({ mode: e.detail.value })
  },

  /**
   * 难度弹窗：确认模式并开始游戏（启动计时）
   */
  startGame: function() {
    // 记住本次选择，下次进入弹窗默认选中
    wx.setStorageSync('game_mode', this.data.mode)
    let that = this
    // 弹窗关闭后才创建画布并绘制：原生 canvas 层级最高，存在时会盖住弹窗
    this.setData({ showModeModal: false }, function() {
      that.ctx = wx.createCanvasContext('myCanvas')
      that.drawCanvas()
    })
    this.startTimer()
  },

  /**
   * 绘制游戏画布
   */
  drawCanvas: function() {
    let ctx = this.ctx
    // 清空画布
    ctx.clearRect(0, 0, canvasSize, canvasSize)

    // 绘制地图底层
    for (var i = 0; i < rows; i++) {
      for (var j = 0; j < cols; j++) {
        let imgName = 'ice'  // 默认路面
        if (map[i][j] === 1) imgName = 'stone'  // 围墙
        if (map[i][j] === 3) imgName = 'pig'    // 终点

        ctx.drawImage(
          '/images/icons/' + imgName + '.png',
          offsetX + j * blockSize, offsetY + i * blockSize,
          blockSize, blockSize
        )

        // 叠加绘制箱子
        if (box[i][j] === 4) {
          ctx.drawImage(
            '/images/icons/box.png',
            offsetX + j * blockSize, offsetY + i * blockSize,
            blockSize, blockSize
          )
        }
      }
    }

    // 叠加绘制玩家
    ctx.drawImage(
      '/images/icons/bird.png',
      offsetX + playerCol * blockSize, offsetY + playerRow * blockSize,
      blockSize, blockSize
    )

    ctx.draw()
  },

  /**
   * 保存当前状态到历史栈（移动前调用）
   */
  saveState: function() {
    let boxCopy = []
    for (var i = 0; i < rows; i++) {
      boxCopy.push(box[i].slice()) // 深拷贝箱子布局
    }
    historyStack.push({
      row: playerRow,
      col: playerCol,
      box: boxCopy
    })
    // 限制最多20步撤销
    if (historyStack.length > 20) historyStack.shift()
  },

  /**
   * 撤销一步（悔棋，困难模式禁用）
   */
  undoStep: function() {
    if (this.data.mode === 'hard') {
      wx.showToast({ title: '困难模式不支持撤销', icon: 'none' })
      return
    }
    if (this.data.replaying) return
    if (historyStack.length === 0) {
      wx.showToast({ title: '没有可撤销的步骤', icon: 'none' })
      return
    }
    let last = historyStack.pop()
    playerRow = last.row
    playerCol = last.col
    box = last.box
    moveRecord.pop() // 操作记录同步移除，保证回放与局面一致

    this.setData({ steps: Math.max(0, this.data.steps - 1) })
    this.drawCanvas()
  },

  /**
   * 统一移动逻辑：上(-1,0) 下(1,0) 左(0,-1) 右(0,1)
   * 注：回放期间也调用本函数执行移动；用户输入已由按钮 disabled 和触摸守卫拦截
   */
  moveTo: function(dRow, dCol) {
    // 弹窗未确认难度前不响应移动
    if (this.data.showModeModal) return
    let nr = playerRow + dRow
    let nc = playerCol + dCol

    // 越界或撞墙
    if (nr < 0 || nr >= rows || nc < 0 || nc >= cols) return
    if (map[nr][nc] === 1) return

    let moved = false

    // 前方是箱子：尝试推动
    if (box[nr][nc] === 4) {
      let br = nr + dRow
      let bc = nc + dCol
      if (br < 0 || br >= rows || bc < 0 || bc >= cols) return
      if (map[br][bc] === 1 || box[br][bc] === 4) return

      this.saveState()
      box[br][bc] = 4
      box[nr][nc] = 0
      playerRow = nr
      playerCol = nc
      this.setData({ steps: this.data.steps + 1 })
      pushAudio.play()
      moved = true
    }
    // 前方是空地：直接移动
    else {
      this.saveState()
      playerRow = nr
      playerCol = nc
      this.setData({ steps: this.data.steps + 1 })
      moveAudio.play()
      moved = true
    }

    if (moved) {
      // 记录操作方向（供回放）
      moveRecord.push(dRow === -1 ? 'up' : dRow === 1 ? 'down' : dCol === -1 ? 'left' : 'right')
    }

    this.drawCanvas()
    this.checkDeadlock()
    this.checkWin()
  },

  /**
   * 四个方向移动（供按钮调用）
   */
  moveUp: function() { this.moveTo(-1, 0) },
  moveDown: function() { this.moveTo(1, 0) },
  moveLeft: function() { this.moveTo(0, -1) },
  moveRight: function() { this.moveTo(0, 1) },

  /**
   * 死局检测（角落死局）：箱子不在终点，且相邻两个方向都是墙
   * 此时四个方向都推不动（推的方向要么站不进人、要么推入墙中），箱子永远无法移动
   * 注意：只有相对两个方向是墙（如上下都是墙）并不算死局，箱子还能沿走廊滑动
   */
  checkDeadlock: function() {
    if (this.data.replaying) return
    for (var i = 0; i < rows; i++) {
      for (var j = 0; j < cols; j++) {
        if (box[i][j] === 4 && map[i][j] !== 3) {
          let up = i > 0 && map[i - 1][j] === 1
          let down = i < rows - 1 && map[i + 1][j] === 1
          let left = j > 0 && map[i][j - 1] === 1
          let right = j < cols - 1 && map[i][j + 1] === 1
          // 相邻两方向均为墙 → 角落死局
          if ((up && left) || (up && right) || (down && left) || (down && right)) {
            wx.showToast({
              title: this.data.mode === 'hard'
                ? '⚠️已进入死局，困难模式无法撤销，请重新开始'
                : '⚠️已进入死局，可以撤销或者重新开始',
              icon: 'none',
              duration: 2000
            })
            return
          }
        }
      }
    }
  },

  /**
   * 滑动触控开始：记录起点
   */
  touchStart: function(e) {
    touchStartX = e.touches[0].clientX
    touchStartY = e.touches[0].clientY
    touchStartCellX = e.touches[0].x
    touchStartCellY = e.touches[0].y
  },

  /**
   * 滑动触控结束：判断滑动方向并移动
   */
  touchEnd: function(e) {
    if (this.data.replaying) return
    let endX = e.changedTouches[0].clientX
    let endY = e.changedTouches[0].clientY
    let dx = endX - touchStartX
    let dy = endY - touchStartY

    // 滑动距离太短视为点击格子：点击相邻可达格子则移动过去
    if (Math.abs(dx) < 20 && Math.abs(dy) < 20) {
      this.tapCell(touchStartCellX, touchStartCellY)
      return
    }

    if (Math.abs(dx) > Math.abs(dy)) {
      dx > 0 ? this.moveRight() : this.moveLeft()
    } else {
      dy > 0 ? this.moveDown() : this.moveUp()
    }
  },

  /**
   * 点击格子移动：只有点击与人物相邻的格子才移动（不可一步到达则无反应）
   */
  tapCell: function(x, y) {
    if (this.data.replaying) return
    let col = Math.floor((x - offsetX) / blockSize)
    let row = Math.floor((y - offsetY) / blockSize)
    // 越界（含画布留白区域）不处理
    if (row < 0 || row >= rows || col < 0 || col >= cols) return
    let dr = row - playerRow
    let dc = col - playerCol
    // 仅相邻一格才响应
    if (Math.abs(dr) + Math.abs(dc) !== 1) return
    this.moveTo(dr, dc)
  },

  /**
   * 判断是否通关：所有箱子都在终点上
   */
  isWin: function() {
    for (var i = 0; i < rows; i++) {
      for (var j = 0; j < cols; j++) {
        // 存在箱子不在终点
        if (box[i][j] === 4 && map[i][j] !== 3) {
          return false
        }
      }
    }
    return true
  },

  /**
   * 通关检测：停止计时、更新最佳记录、解锁下一关、弹出操作菜单
   */
  checkWin: function() {
    if (this.data.replaying) return
    if (!this.isWin()) return

    this._won = true
    winAudio.play()
    this.stopTimer()

    let levelIndex = this.data.level - 1
    let currentStep = this.data.steps

    // 更新历史最佳步数
    let oldBest = wx.getStorageSync('best_step_' + levelIndex)
    if (!oldBest || currentStep < oldBest) {
      wx.setStorageSync('best_step_' + levelIndex, currentStep)
    }
    this.setData({ bestStep: wx.getStorageSync('best_step_' + levelIndex) })

    // 保存本关最佳通关时间（简单/困难共用一套）
    let elapsed = Math.floor((Date.now() - this._startTime) / 1000)
    let oldTime = wx.getStorageSync('best_time_' + levelIndex)
    if (!oldTime || elapsed < oldTime) {
      wx.setStorageSync('best_time_' + levelIndex, elapsed)
    }

    // 解锁下一关（最后一关不越界）
    if (this.data.level < data.maps.length) {
      let unlocked = wx.getStorageSync('unlocked_level') || 1
      if (this.data.level >= unlocked) {
        wx.setStorageSync('unlocked_level', this.data.level + 1)
      }
    }

    // 通关弹窗：底部操作菜单
    wx.showActionSheet({
      itemList: ['下一关', '重玩本关', '查看操作回放'],
      success: (res) => {
        if (res.tapIndex === 0) {
          this.nextLevel()
        } else if (res.tapIndex === 1) {
          this.restartGame()
        } else if (res.tapIndex === 2) {
          this.startReplay()
        }
      }
    })
  },

  /**
   * 操作回放：备份状态 → 重置到初始 → 每400ms回放一步 → 恢复
   */
  startReplay: function() {
    if (this.data.replaying) return
    if (moveRecord.length === 0) {
      wx.showToast({ title: '没有操作记录', icon: 'none' })
      return
    }
    // 备份当前（通关）状态
    let savedBox = box.map(function(r) { return r.slice() })
    let savedRow = playerRow
    let savedCol = playerCol
    let savedSteps = this.data.steps
    let savedTimeText = this.data.timeText
    let savedCountdown = this.data.countdown

    let record = moveRecord.slice()
    this._replaying = true
    this.setData({ replaying: true })
    // 重置为关卡初始状态
    this.initMap(this.data.level - 1)

    let that = this
    let idx = 0
    let moveMap = { up: [-1, 0], down: [1, 0], left: [0, -1], right: [0, 1] }
    this._replayTimer = setInterval(function() {
      if (idx >= record.length) {
        clearInterval(that._replayTimer)
        that._replayTimer = null
        // 恢复通关状态
        box = savedBox
        playerRow = savedRow
        playerCol = savedCol
        that._replaying = false
        that.setData({
          replaying: false,
          steps: savedSteps,
          timeText: savedTimeText,
          countdown: savedCountdown
        })
        that.drawCanvas()
        wx.showToast({ title: '回放结束', icon: 'none' })
        return
      }
      let dir = moveMap[record[idx++]]
      that.moveTo(dir[0], dir[1])
    }, 400)
  },

  /**
   * 进入下一关
   */
  nextLevel: function() {
    let currentIndex = this.data.level - 1
    if (currentIndex + 1 >= data.maps.length) {
      wx.showToast({ title: '已通关全部关卡！', icon: 'success' })
      setTimeout(function() { wx.navigateBack() }, 1500)
      return
    }
    wx.redirectTo({ url: '../game/game?level=' + (currentIndex + 1) + '&mode=' + this.data.mode })
  },

  /**
   * 返回首页
   */
  goHome: function() {
    wx.navigateBack()
  },

  /**
   * 重新开始当前关卡：重置计时、记录、步数
   */
  restartGame: function() {
    this.initMap(this.data.level - 1)
    this.startTimer()
    this.drawCanvas()
  },

  /**
   * 分享：携带关卡与难度参数，好友点开直接进入对应关卡和模式
   */
  onShareAppMessage: function() {
    let levelIndex = this.data.level - 1
    let levelNum = this.data.level
    let levelPic = 'level' + (levelNum < 10 ? '0' + levelNum : levelNum) + '.png'
    return {
      title: '第' + levelNum + '关 推箱子挑战，快来试试！',
      path: '/pages/game/game?level=' + levelIndex + '&mode=' + this.data.mode,
      imageUrl: '/images/' + levelPic
    }
  }
})
