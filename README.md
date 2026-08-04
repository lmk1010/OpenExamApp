<p align="center">
  <img src="docs/logo.png" width="96" alt="OpenExam">
</p>

<h1 align="center">OpenExam App</h1>

<p align="center">
  公务员行测刷题 App · 15936 道真题装在手机里 · 不用登录，没网也能刷
</p>

<p align="center">
  <img alt="Flutter" src="https://img.shields.io/badge/Flutter-3.32-02569B?logo=flutter&logoColor=white">
  <img alt="Dart" src="https://img.shields.io/badge/Dart-3.8-0175C2?logo=dart&logoColor=white">
  <img alt="Platform" src="https://img.shields.io/badge/platform-Android%20%7C%20iOS-lightgrey">
  <img alt="Offline" src="https://img.shields.io/badge/离线-100%25-success">
</p>

---

## 这是什么

OpenExam 桌面端的手机端。题库由桌面端导出成一个 gzip 过的 SQLite 种子库，首次启动解包到本地，之后**全程离线**：没有账号、没有服务器、没有埋点。所有答题记录、笔记、错题、成就都只存在这台手机上，能一键导出成 JSON 备份带走。

- **15936 道真题**，137 套历年卷，4230 张图（图形推理、资料分析的图都在库里，以 BLOB 存储）
- **五个模块**：言语理解、数量关系、判断推理、资料分析、常识判断

## 截图

| 练习首页 | 错题本 | 学习统计 |
|---|---|---|
| <img src="docs/screenshots/home.jpg" width="240"> | <img src="docs/screenshots/wrong-book.jpg" width="240"> | <img src="docs/screenshots/stats.jpg" width="240"> |

| 我的 | 成就徽章 | 引导 |
|---|---|---|
| <img src="docs/screenshots/profile.jpg" width="240"> | <img src="docs/screenshots/badge.jpg" width="240"> | <img src="docs/screenshots/onboarding-1.jpg" width="240"> |

## 主要功能

### 练

- **每日一练**：按日期确定的固定卷，同一天打开永远是同一组题；七天打卡条，断掉的那天可以补做
- **弱项强化**：按各模块正确率加权抽题，不用自己猜该练哪块
- **限时模考 / 单模块限时练**：按各模块真实考场配速换算时长（言语 55s、数量 75s、判断 50s、资料 70s、常识 20s 每题）
- **按卷刷**：试卷详情能看模块分布，可以只练其中一个模块、只练空题、只练错题
- **背题**：不作答，直接翻答案和解析
- 做题页没有底部工具条：选中答案即进入下一题，左右滑动切换；草稿纸、计算器、笔记、存疑标记都在顶栏

### 复盘

- **错题本概览优先**：进去先看今日复盘、模块分布、错因分布、错得最多的卷，逐题列表要点底部进 —— 一打开就是密密麻麻的错题，没人愿意复盘
- **错因标签**：粗心 / 不会 / 审题 / 没时间，可多轴筛选（题型 × 错因 × 来源卷 × 难度）
- **四天专项计划**：粉笔那套「同类错因连盯四天」—— 前两天不计时慢做，第三天限时加压，第四天掺同类新题混练验证
- **难度自评**：解析下面标简单 / 一般 / 难，之后能把标难的单独拉出来重练
- **本题历史作答**：答完当场显示这题做过几次、错过几次、最近 5 次分别选了什么
- **导出**：错题可导出 Markdown，全部数据可导出 JSON 备份

### 看

- **备考档案**：正确率环、模块分布、35 天热力图、成绩走势、时段分布
- **弱项诊断**：最近 7 天 vs 前 7 天的模块对比，退步或进步 8 个点以上直接点名并附具体数字；每条建议带自己的出口（跳错题本、直接开限时练）
- **成就**：18 枚徽章分 5 组 4 个等级，全部按本机数据计算，整页展示可左右滑动

## 设计

界面语言叫 **Ambient Glass**，规范见 [docs/DESIGN.md](docs/DESIGN.md)。三条底线：

1. **不用 `BackdropFilter`** —— 真实高斯模糊在中端机上掉帧，玻璃质感靠渐变、描边和阴影堆出来
2. **无边框、少卡片** —— 背景本身就是层次，能用留白分组就不画框
3. **图标全部手绘** —— 20 个描边图标、勋章纹样、引导插画、图表都是 `CustomPainter`，没有图标字体依赖

## 技术

| | |
|---|---|
| 框架 | Flutter 3.32 / Dart 3.8，Material 3 |
| 主题 | 自建 `ThemeExtension` 令牌系统，浅色 / 深色 / 跟随系统 |
| 存储 | sqflite，题库以 gzip 种子库随包分发，首启在独立 isolate 里解包 |
| 图片 | SQLite BLOB + `oeimg://` 协议 + 12MB LRU 内存缓存 |
| 设置 | shared_preferences |
| 依赖 | 只有 sqflite / path_provider / shared_preferences / file_picker，没有网络库 |

目录结构：

```
lib/
  core/        令牌、主题、手绘图标、玻璃装饰、通用组件
  data/        数据库、模型、种子库安装
  features/    practice 练习 · bank 题库 · wrong 错题本 · profile 我的
               achievements 成就 · reports 报告 · stats 统计 · onboarding 引导 …
tool/
  build_seed.py  从桌面端仓库构建手机端种子库
```

## 运行

```bash
flutter pub get
flutter run                    # 调试
flutter build apk --release    # 打 APK
flutter build appbundle --release
```

首次启动会解压约 30MB 的种子库到应用私有目录，需要几秒。

## 许可

题目内容来自公开真题，仅供个人备考使用。
