// utils/store.js
// 收藏、点赞、用户信息的本地缓存读写

const FAV_KEY = 'favorites'
const LIKE_KEY = 'likes'
const USER_KEY = 'userInfo'

function getFavorites() {
  return wx.getStorageSync(FAV_KEY) || []
}

function getLikes() {
  return wx.getStorageSync(LIKE_KEY) || []
}

function isFavorite(id) {
  let list = getFavorites()
  for (let i = 0; i < list.length; i++) {
    if (list[i].id === id) return true
  }
  return false
}

function isLiked(id) {
  let list = getLikes()
  for (let i = 0; i < list.length; i++) {
    if (list[i].id === id) return true
  }
  return false
}

function addFavorite(article) {
  let list = getFavorites()
  for (let i = 0; i < list.length; i++) {
    if (list[i].id === article.id) return
  }
  list.push(article)
  wx.setStorageSync(FAV_KEY, list)
}

function removeFavorite(id) {
  let list = getFavorites().filter(function (a) { return a.id !== id })
  wx.setStorageSync(FAV_KEY, list)
}

function addLike(article) {
  let list = getLikes()
  for (let i = 0; i < list.length; i++) {
    if (list[i].id === article.id) return
  }
  list.push(article)
  wx.setStorageSync(LIKE_KEY, list)
}

function removeLike(id) {
  let list = getLikes().filter(function (a) { return a.id !== id })
  wx.setStorageSync(LIKE_KEY, list)
}

function getUserInfo() {
  return wx.getStorageSync(USER_KEY) || null
}

function setUserInfo(info) {
  wx.setStorageSync(USER_KEY, info)
}

function clearUserInfo() {
  wx.removeStorageSync(USER_KEY)
}

module.exports = {
  getFavorites: getFavorites,
  isFavorite: isFavorite,
  addFavorite: addFavorite,
  removeFavorite: removeFavorite,
  getLikes: getLikes,
  isLiked: isLiked,
  addLike: addLike,
  removeLike: removeLike,
  getUserInfo: getUserInfo,
  setUserInfo: setUserInfo,
  clearUserInfo: clearUserInfo
}
