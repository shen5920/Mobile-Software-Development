# Mobile-Software-Development

中国海洋大学 2026 夏季学期《移动软件开发》课程实验仓库。

覆盖**微信小程序**与**鸿蒙应用（HarmonyOS）**两个移动开发平台：前四个实验基于微信小程序原生开发（WXML / WXSS / JavaScript），从零完成由浅入深的小程序项目，覆盖页面结构、常用组件、API 调用、数据与状态管理、canvas 绘图、触摸交互、本地缓存等核心知识；实验5 基于 DevEco Studio 进行鸿蒙应用开发（ArkTS / ArkUI 声明式开发），实现功能完整的计算器应用。开发过程中结合 Python / Node.js 工具进行数据验证、素材生成与算法单元测试。

| 项目信息 | 内容 |
| --- | --- |
| 课程 | 中国海洋大学 2026 夏《移动软件开发》 |
| 平台 | 微信小程序（实验1-4）/ 鸿蒙应用 HarmonyOS NEXT（实验5） |
| 作者 | 沈卓娜（学号 24020007101） |

## 目录

- [仓库结构](#仓库结构)
- [实验列表](#实验列表)
- [技术要点](#技术要点)
- [快速开始](#快速开始)
- [目录结构](#目录结构)
- [实验报告](#实验报告)

## 仓库结构

| 实&nbsp;验 | 代&nbsp;码&nbsp;目&nbsp;录 | 项&nbsp;目&nbsp;名&nbsp;称 | 内容简介 |
| --- | --- | --- | --- |
| 实&nbsp;验&nbsp;1 | [lab1](lab1/) | 小&nbsp;程&nbsp;序&nbsp;入&nbsp;门 | 熟悉项目结构、页面与事件绑定，实现按钮点击切换图文内容的交互 demo |
| 实&nbsp;验&nbsp;2 | [lab2](lab2/) | 个&nbsp;人&nbsp;名&nbsp;片 | 静态页面布局与样式设计，展示个人信息名片 |
| 实&nbsp;验&nbsp;3 | [lab3](lab3/) | 高&nbsp;校&nbsp;新&nbsp;闻&nbsp;网 | 基于模拟数据的新闻小程序：分类展示、搜索、排序、时间筛选、点赞、收藏、登录（头像昵称填写）、左滑删除等完整功能 |
| 实&nbsp;验&nbsp;4 | [lab4](lab4/) | 推&nbsp;箱&nbsp;子&nbsp;游&nbsp;戏 | canvas 绘图小游戏：16 个可解关卡、三种操作方式、难度模式、分层限时挑战、悔棋、死局检测、分享、操作回放、音效 |
| 实&nbsp;验&nbsp;5 | [lab5](lab5/) | 鸿蒙计算器 | DevEco Studio 鸿蒙应用：普通/科学计算器、单位换算、历史记录、函数绘图、日期计算，含全屏适配与状态管理 |

## 实验列表

### 实验1：小程序入门（lab1）

第一个小程序实验，熟悉微信开发者工具的项目创建、页面结构（WXML / WXSS / JS / JSON）和基础事件绑定，实现一个简单的图文切换交互页面。

### 实验2：个人名片（lab2）

练习静态页面布局与样式设计，使用基础组件完成一张个人信息名片页，掌握 flex 布局、圆角、阴影、图片引用等常用技巧。

### 实验3：高校新闻网（lab3）

以中国海洋大学新闻网为原型，实现功能较完整的新闻小程序：

- **分类展示**：24 条新闻按「海大要闻 / 综合新闻 / 媒体海大 / 学术海大」四类展示，分类标签与轮播图联动；
- **搜索 / 排序 / 时间筛选**：标题关键词跨分类搜索；时间倒序 / 正序 / 默认排序；今日、本周、本月快捷筛选及日历选日期；
- **收藏与点赞**：详情页与列表页均可操作，个人中心分标签展示，支持左滑取消；
- **登录**：采用官方推荐的头像昵称填写能力（`open-type="chooseAvatar"` + `input type="nickname"`），支持退出登录；
- **性能**：新闻图片经压缩控制在 2MB 主包限制内，并附图片压缩脚本。

### 实验4：推箱子游戏（lab4）

基于 canvas 绘图 API 实现的推箱子小游戏：

- **16 个关卡，难度梯度化**：地图从 8×8 逐步扩大到 10×10、12×12，箱子数从 2 递增到 9，全部经 Python 求解器验证可解；
- **三种操作方式**：方向按钮、画布滑动、点击相邻格子直接移动；
- **难度模式**：进入关卡先弹窗选择——简单模式计时不限时、支持撤销悔棋；困难模式限时挑战、禁止撤销、超时失败；
- **分层限时**：困难模式限时随关卡递增（1-4 关 60 秒、5-8 关 90 秒、9-12 关 120 秒、13-16 关 150 秒）；
- **成绩与进度**：步数、每关最佳步数、最佳通关时间本地保存，通关解锁下一关；
- **进阶功能**：悔棋（20 步）、角落死局实时提示、携带关卡与难度参数的分享、通关后操作回放、移动/推箱/通关音效。

### 实验5：鸿蒙计算器（lab5）

基于 DevEco Studio（HarmonyOS NEXT 6.0.2 / API 22）与 ArkTS 声明式开发的计算器应用：

- **普通计算器**：四列圆形按键，表达式光标定位与任意位置插入/删除（`TextInput` + `TextInputController`）；
- **科学计算器**：独立计算引擎采用调度场算法（中缀转 RPN）求值，支持幂/阶乘/百分数/mod、三角/反三角/双曲函数、内存键、DEG/RAD 切换、下拉菜单，并自动补全未闭合括号；
- **单位换算**：汇率（23 种货币）/长度/面积/体积/重量/温度/速度/压强/功率/进制十个分类，双向输入、自定义搜索分组选择面板；
- **历史记录**：`AppStorage` 全局存储最近 50 条，支持左滑删除与清空；
- **函数绘图**：Canvas 自定义绘制坐标轴与函数曲线，支持缩放/平移、多函数多颜色、渐近线断开处理；
- **日期计算**：日期间隔与日期推算（加减切换解决软键盘无法输入负号的问题）；
- **全屏适配**：`setWindowLayoutFullScreen` 沉浸式布局 + `getWindowAvoidArea` 状态栏/导航条避让，横竖屏动态更新。

## 技术要点

- **微信小程序（实验1-4）**：组件 `tabBar`、`swiper`、`canvas`、`picker`、`radio`、`button`、`scroll-view` 等；API `wx.navigateTo` / `wx.redirectTo` / `wx.switchTab` 页面跳转、`wx.getStorageSync` / `wx.setStorageSync` 本地缓存、`wx.createCanvasContext` 绘图、触摸事件、`wx.showActionSheet` / `wx.showModal` / `wx.showToast`、`wx.createInnerAudioContext` 音频、`onShareAppMessage` 分享、`chooseAvatar` 头像昵称填写、`wx.getFileSystemManager` 文件持久化；工程组织上做到数据与视图分离、全局登录状态共享（`globalData`）、缓存读写统一封装（`store.js`）；
- **鸿蒙应用（实验5）**：ArkTS 语言与 ArkUI 声明式 UI、状态管理装饰器 `@State` / `@Builder` / `@StorageLink` / `AppStorage`、页面路由 `router`、全屏布局与避让区域监听、`Canvas` 自定义绘制、`TextInput` 光标控制、`DatePickerDialog`、`ForEach` keyGenerator 渲染优化；
- **辅助工具**：Python 编写推箱子求解器（A\* 搜索）与关卡反向生成器、图片压缩与关卡预览图生成、音效合成；PowerShell 图片优化脚本；Node.js 将 ArkTS 计算引擎转为 JS 做单元测试。

## 快速开始

**微信小程序（lab1 ~ lab4）**

1. 安装[微信开发者工具](https://developers.weixin.qq.com/miniprogram/dev/devtools/download.html)；
2. 使用开发者工具「导入项目」，选择本仓库中的 `lab1` ~ `lab4` 任意目录；
3. 实验3、实验4 需使用有效的小程序 AppID（`project.config.json` 中已配置）；
4. 编译运行即可预览；点击「预览」可生成二维码在真机调试。

**鸿蒙应用（lab5）**

1. 安装[DevEco Studio](https://developer.huawei.com/consumer/cn/deveco-studio/) 与 HarmonyOS SDK（API 22）；
2. File → Open 打开 `lab5` 目录，等待 hvigor 同步完成；
3. 在模拟器或真机上运行（DevEco Studio 的 Previewer 不支持 `router` 页面跳转，需在模拟器中测试）。

> 注意：实验4 的 `canvas` 为原生组件，真机上层级高于普通视图，弹窗类交互需避开画布渲染时机（详见实验4报告）。

## 目录结构

```
Mobile-Software-Development/
├── lab1/                 # 实验1：小程序入门
├── lab2/                 # 实验2：个人名片
├── lab3/                 # 实验3：高校新闻网
├── lab4/                 # 实验4：推箱子游戏
├── lab5/                 # 实验5：鸿蒙计算器
├── 实验1.md              # 实验1 报告
├── 实验2.md              # 实验2 报告
├── 实验3.md              # 实验3 报告
├── 实验4.md              # 实验4 报告
├── 实验5.md              # 实验5 报告
└── README.md             # 本文件
```

## 实验报告

- [实验1 报告](实验1.md) · [CSDN 博客](https://blog.csdn.net/natiedog/article/details/164065143)
- [实验2 报告](实验2.md) · [CSDN 博客](https://blog.csdn.net/natiedog/article/details/164095360)
- [实验3 报告](实验3.md) · [CSDN 博客](https://blog.csdn.net/natiedog/article/details/164222749)
- [实验4 报告](实验4.md) · [CSDN 博客](https://blog.csdn.net/natiedog/article/details/164256927)
- [实验5 报告](实验5.md) · [CSDN 博客](https://blog.csdn.net/natiedog/article/details/164507205)

各实验报告包含实验目的、项目创建与目录结构、视图设计、逻辑实现、运行效果截图以及问题总结与体会；完整实验过程见对应 CSDN 博客。
