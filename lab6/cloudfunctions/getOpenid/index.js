// 云函数入口文件
const cloud = require('wx-server-sdk')

// 使用当前部署环境, 避免多环境时请求到错误环境
cloud.init({ env: cloud.DYNAMIC_CURRENT_ENV })

// 云函数入口函数
exports.main = async (event, context) => {
  const wxContext = cloud.getWXContext()

  return {
    openid: wxContext.OPENID
  }
}
