# iOS 上架

面向**非中国区** App Store。这一条省掉了国内上架必须的 ICP 备案和软件著作权
登记 —— 那两样加起来通常要一两个月，海外区一样都不要。

## 两个发行形态

同一份代码，区别只在 `assets/seed/` 里有没有题库文件。app 运行时探测，不是
编译开关 —— 开关会和实际打进包里的东西对不上，运行时探测不会。

```bash
python3 tool/bank.py status     # 这次构建带不带题库
python3 tool/bank.py link       # 带（Android 侧载 / 自用）
python3 tool/bank.py unlink     # 不带（App Store）
```

| | 带题库 | 不带题库 |
|---|---|---|
| 用途 | Android 侧载、自己和家人用 | App Store |
| 体积 | +45MB 包体，首次启动解包约 90MB | 基本没有额外体积 |
| 首次启动 | 直接能刷 | 首页只有一张「还没有题库」卡片，引导导入 |
| 为什么 | 无所谓 | 见下面「知识产权」 |

## 上架前必须先定的一件事

**App Store 那个版本，第一次打开给用户看什么题？**

现在的实现是「一道题都没有，请导入」。这能过，但是有风险的走法（见 4.2）。
三个选项：

1. **完全空**，靠引导 + 审核备注里给审核员一份题库文件。Anki 是这么干的，
   能过，但它有庞大的共享牌组生态撑着说服力。
2. **内置一个几十道题的示例库**，自己出题或用明确可商用的内容。最稳，
   审核员打开就能点、能做、能看到诊断和统计。
3. **内置真题的一小部分**。体积问题解决了，版权问题一点没解决 —— 不建议。

我倾向 2。真要走 2，需要你决定示例题从哪来（自己写几十道？还是找一份
明确授权的公开题集），这我没法替你定。

## 审核风险，按可能性排

### 5.2 知识产权 —— 这是不打包题库的根本原因

题库是 15936 道公务员真题，来源是抓取。真题本身的著作权、以及各家机构的
解析文字，都不是我们的。把它打进一个上架 App 里分发，是这个项目最大的
法律暴露面，比包体大小严重得多。

对策，三条都要做到：

- 包里不带真题（`tool/bank.py unlink`）；
- **App Store 的描述、截图、关键词里不出现任何真题内容**，也不要暗示
  「提供公务员真题」。App 的定位是「离线刷题工具，题库自备」；
- 截图用示例题，不要用真题截图。

### 4.2 最低功能 —— 空 App 的经典死法

审核员装上、打开、点两下，什么都没有 → 「App 功能过于简单」。

对策：
- 空库时首页**只显示**「还没有题库 + 导入」这一张卡，不再摆一屏点不出题的
  按钮（已实现）。摆死按钮比空白更糟 —— 那是「坏掉的 App」，不是「等你装
  内容的工具」；
- 审核备注里给一份可下载的示例题库 + 三步操作说明（模板见下）；
- 最好还是内置示例题（见上面那个决定）。

### 2.1 App 完整性 —— 审核员得能真的用起来

如果他导不进题库，前面所有解释都没用。已经做的：

- `UIFileSharingEnabled` + `LSSupportsOpeningDocumentsInPlace` —— 题库文件
  可以直接从「文件」App 拖进 OpenExam 文件夹，不用走选择器；
- 审核备注里给直链和步骤。

### 5.1 隐私

- App **不收集任何数据**，全部本地，无账号、无登录、无分析 SDK。
  App Privacy 里如实选「不收集数据」。
- 但 AI 功能是例外：用户填自己的 API Key，题干和作答会发给**用户自己选的**
  服务商。这一条必须写进隐私政策，也要在 App 内说清。现在 AI 是可选功能、
  默认关闭、Key 只存本机 —— 这个形态是安全的，别改成我们代收代付。
- **iOS 17+ 需要 `PrivacyInfo.xcprivacy`**（隐私清单）。主 App 用到了
  UserDefaults 和文件时间戳这类 required-reason API，要声明用途码。
  插件（shared_preferences / path_provider / file_picker）新版本自带各自的
  清单，但主 target 的那份要自己加。**没加会在上传时被自动检查拦下**。
- 需要一个能公开访问的隐私政策 URL（App Store Connect 必填）。

### 3.1 支付

现在没有任何购买 → 不触发。但两件事以后别踩：
- 要卖题库，必须走 IAP，不能引外链付款（3.1.1）；
- 描述里不能出现引导站外购买的措辞（3.1.3）。

### 2.3 元数据准确

App 目前**只有中文界面**。所以：
- App Store Connect 的**主语言选简体中文**，别选英文然后配一堆英文截图 ——
  截图里全是中文界面，会被判元数据不符；
- **审核备注（App Review Notes）用英文写**，审核员多半不懂中文；
- 描述里说「离线」，就别在别处说「云端同步」。AI 是联网的，描述里要提一句
  「可选的 AI 功能需要联网并使用你自己的 API Key」。

### 其它已处理

- 出口合规：`ITSAppUsesNonExemptEncryption = false`（只用系统 HTTPS，属豁免）。
  不写这个键每次上传都会被问一遍。
- `NSPhotoLibraryUsageDescription`：申论插图 / 扫描试卷会走相册。
  **缺这条 iOS 会直接杀进程**，不只是审核问题。
- 显示名从 `Openexam App` 改成 `OpenExam`，`CFBundleName` 同步。
- `CFBundleLocalizations = zh_CN`，让系统知道主语言是中文。

## 还没做的

### 国际化（i18n）

**现状：完全没有。** 没有 `flutter_localizations`，没有 `intl`，没有 ARB，
所有中文都硬编码在 widget 里，几百处。

这**不阻塞上架** —— Apple 不要求本地化，中文单语 App 可以正常上架任何区。
要不要做取决于目标：

- 只是自己和家人用、顺便挂在商店上：**不用做**。主语言设中文，收工。
- 想要海外用户：必须做，而且这是个比目前所有改动加起来还大的工程 ——
  抽字符串、建 ARB、逐处替换、翻译、再回归测试一遍所有页面。
  而且内容本身（行测、申论、公务员考试）对非中文用户没有意义，
  除非题库也换掉。

我的判断：**先中文单语上架，i18n 等到真有海外用户需求再做**。现在做等于
为一个还不存在的用户群付一大笔工程费。

### iPad

Xcode 里目前是通用 App。通用就必须在 iPad 上跑得对，否则 2.1 挂。
代码里有响应式布局（`context.isExpanded` 那套双栏），但**没在 iPad 上实测过**。
两个选择：真机/模拟器实测一轮，或者在 Xcode target 里只勾 iPhone。
后者更省事。

### 签名

`android/app/build.gradle.kts` 的 release 还在用 debug 签名（有 TODO）。
Android 侧载无所谓，但要上 Google Play 得换。iOS 这边需要：
- Apple Developer Program（99 美元/年）
- App ID：`com.liumingkang.openexamApp`（跟 Xcode 里一致）
- Distribution 证书 + App Store Provisioning Profile

## 提交清单

- [ ] 决定示例题库怎么办（上面那个决定）
- [ ] `python3 tool/bank.py unlink` 确认不带题库
- [ ] 加 `PrivacyInfo.xcprivacy`
- [ ] 隐私政策页面上线，拿到 URL
- [ ] iPad：实测 或 取消勾选
- [ ] 图标全尺寸、启动图
- [ ] 截图：6.9" 和 6.5" 各一组，**用示例题不用真题**
- [ ] App Store Connect 建 App，主语言选简体中文
- [ ] App Privacy 填「不收集数据」，AI 那条在隐私政策里说明
- [ ] 年龄分级：4+
- [ ] 审核备注（英文）
- [ ] `flutter build ipa`，Transporter 上传

## 审核备注模板（英文，按实际情况改）

> OpenExam is an offline quiz-practice tool. The app ships without any question
> content — users bring their own question bank, similar to how Anki ships
> without decks. This is intentional: the app is the study engine (timed mock
> exams, mistake review, per-module pace diagnostics), not a content library.
>
> To review the full functionality, please load the sample bank:
>
> 1. Download the sample file: <URL>
> 2. Open the app, tap "导入题库" (Import question bank) on the home screen
> 3. Select the downloaded file
>
> Alternatively, copy the file into the OpenExam folder in the Files app.
>
> After importing, all features become available: practice, timed mock exam,
> mistake notebook, statistics, and the weakness diagnosis page.
>
> The AI features are optional and disabled by default. They require the user
> to supply their own third-party API key, which is stored only on the device.
> The app collects no data and requires no account.

界面是中文的，所以备注里带上关键按钮的中文原文 + 英文括注，审核员照着点
就行。
