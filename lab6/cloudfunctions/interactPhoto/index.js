// 云函数: 照片互动统一入口
// 因为客户端在"所有用户可读、仅创建者可写"的数据库规则下无法修改他人文档,
// 点赞/浏览/删除这类跨用户写操作统一走云函数(以管理员身份执行)。
// action: like | unlike | view | delete | stat
const cloud = require('wx-server-sdk')

cloud.init({ env: cloud.DYNAMIC_CURRENT_ENV })

const db = cloud.database()
const _ = db.command
const photos = db.collection('photos')
const comments = db.collection('comments')

/** 读取照片文档, 不存在返回 null */
async function getPhoto(photoId) {
  try {
    const res = await photos.doc(photoId).get()
    return res.data
  } catch (e) {
    return null
  }
}

/** 点赞/取消点赞(幂等: 状态一致时直接返回当前值, 不会重复计数) */
async function setLike(photoId, wantLike, openid) {
  const photo = await getPhoto(photoId)
  if (!photo) return { ok: false, msg: '照片不存在或已删除' }

  const likedBy = photo.likedBy || []
  const liked = likedBy.indexOf(openid) >= 0
  let likes = photo.likes || 0

  if (liked === wantLike) {
    return { ok: true, liked: liked, likes: likes }
  }

  const data = wantLike
    ? { likes: _.inc(1), likedBy: _.addToSet(openid) }
    : { likes: _.inc(-1), likedBy: _.pull(openid) }
  await photos.doc(photoId).update({ data: data })

  likes = Math.max(0, likes + (wantLike ? 1 : -1))
  return { ok: true, liked: wantLike, likes: likes }
}

// 云函数入口函数
exports.main = async (event, context) => {
  const { OPENID } = cloud.getWXContext()
  const action = event.action
  const photoId = event.photoId

  try {
    switch (action) {
      case 'like':
        return await setLike(photoId, true, OPENID)

      case 'unlike':
        return await setLike(photoId, false, OPENID)

      case 'view': {
        const photo = await getPhoto(photoId)
        if (photo) {
          await photos.doc(photoId).update({ data: { views: _.inc(1) } })
        }
        return { ok: true }
      }

      case 'delete': {
        const photo = await getPhoto(photoId)
        if (!photo) return { ok: false, msg: '照片不存在或已删除' }
        if (photo._openid !== OPENID) return { ok: false, msg: '只能删除自己上传的照片' }

        // 删除数据库记录
        await photos.doc(photoId).remove()

        // 级联删除该照片的全部评论(集合不存在时忽略)
        try {
          await comments.where({ photoId: photoId }).remove()
        } catch (e) {
          // comments 集合尚未创建时静默跳过
        }

        // 删除云存储中的图片文件(尽力而为)
        if (photo.photoUrl && photo.photoUrl.indexOf('cloud://') === 0) {
          try {
            await cloud.deleteFile({ fileList: [photo.photoUrl] })
          } catch (e) {
            console.error('删除云文件失败(不影响记录删除)', e)
          }
        }
        return { ok: true }
      }

      // 我的点赞: 我点赞过的照片(服务端查询, 不受集合权限限制; countOnly 只返回总数)
      case 'myLikes': {
        const q = photos.where({ likedBy: _.all([OPENID]) })
        const cntRes = await q.count()
        if (event.countOnly) {
          return { ok: true, total: cntRes.total || 0 }
        }
        const skip = Number(event.skip) || 0
        const limit = Math.min(50, Number(event.limit) || 20)
        const listRes = await q.orderBy('createTime', 'desc').skip(skip).limit(limit).get()
        const list = (listRes.data || []).map(d => ({
          _id: d._id,
          photoUrl: d.photoUrl,
          likes: d.likes || 0
        }))
        return { ok: true, total: cntRes.total || 0, list: list }
      }

      // 个人主页统计: 作品数 + 总获赞(服务端分页聚合, 突破客户端单次 20 条限制)
      case 'stat': {
        const owner = event.owner || OPENID
        let works = 0
        let totalLikes = 0
        let offset = 0
        while (true) {
          const res = await photos
            .where({ _openid: owner })
            .field({ likes: true })
            .skip(offset)
            .limit(100)
            .get()
          const rows = res.data || []
          works += rows.length
          for (let i = 0; i < rows.length; i++) {
            totalLikes += rows[i].likes || 0
          }
          if (rows.length < 100) break
          offset += 100
        }
        return { ok: true, works: works, totalLikes: totalLikes }
      }

      default:
        return { ok: false, msg: '未知操作' }
    }
  } catch (err) {
    console.error('interactPhoto 执行失败, action=' + action, err)
    return { ok: false, msg: '操作失败, 请重试' }
  }
}
