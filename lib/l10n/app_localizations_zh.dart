// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLZh extends AppL {
  AppLZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => 'OpenExam';

  @override
  String get onboardTitle => '上岸\n是划出来的';

  @override
  String onboardBodyWithBank(int count) {
    return '$count 道题在这台手机里\n不用登录，没网也能划';
  }

  @override
  String get onboardBodyNoBank => '题库和 App 是分开的\n导入一份就能开始，不用登录、没网也能划';

  @override
  String get onboardBodyLoading => '不用登录，没网也能划';

  @override
  String get onboardWrongTitle => '错的题\n自己会记着';

  @override
  String get onboardWrongBody => '答错的进错题本，再答对就出去\n想写两句笔记、标一下错在哪，都行';

  @override
  String get onboardSkip => '跳过';

  @override
  String get onboardStart => '出发';

  @override
  String get noBankTitle => '还没有题库';

  @override
  String get noBankBody =>
      '这个版本不预装题目 —— 题库和 App 是分开的，装哪套题库就是练哪门考试。导入一份就能开始：做题、按卷模考、错题复盘、弱点诊断都不用联网。';

  @override
  String get noBankImport => '导入题库';

  @override
  String get noBankHint =>
      '也可以把题库文件放进「文件」App 的 OpenExam 文件夹，或者用「扫描试卷」把纸质卷子拍成题目。';

  @override
  String get bankTitle => '题库';

  @override
  String get bankExportTitle => '导出题库';

  @override
  String get bankExportBody => '导出成 zip，含题目和图片。别人用「导入题库」就能装上 —— 跟导入是同一个格式。';

  @override
  String get bankExportWholeBank => '整个题库';

  @override
  String bankExportWholeBankHint(int count) {
    return '$count 题 · 文件会很大';
  }

  @override
  String bankExportCount(int count) {
    return '$count 题';
  }

  @override
  String get bankExportEmpty => '这个范围里没有题';

  @override
  String get bankExportCancelled => '已取消';

  @override
  String bankExportDone(int count, String name) {
    return '已导出 $count 题：$name';
  }

  @override
  String bankExportFailed(String error) {
    return '导出失败：$error';
  }

  @override
  String get settingsLanguage => '界面语言';

  @override
  String get settingsLanguageSystem => '跟随系统';

  @override
  String get settingsLanguageSystemHint => '按手机的语言自动切换';

  @override
  String get onboardNext => '下一个';

  @override
  String get onboardFinish => '开始划';

  @override
  String importScanDone(int count) {
    return '已导入 $count 道题';
  }

  @override
  String get importUnreadable => '读不到这个文件，换一个试试';

  @override
  String get importNoQuestions => '这个文件里没找到题目，看看下面的格式说明';

  @override
  String importFailed(String error) {
    return '导入失败：$error';
  }

  @override
  String get importWayScanTitle => '拍照 / PDF';

  @override
  String get importWayScanDesc => '试卷、截图、买来的 PDF，AI 逐页认成题目';

  @override
  String get importWayDocTitle => 'Word / Excel / 文本';

  @override
  String get importWayDocDesc => 'docx、xlsx、csv、txt，AI 直接读文字认成题目';

  @override
  String get importWayFileTitle => '题目文件';

  @override
  String get importWayFileDesc => 'JSON / CSV，带图的打包成 zip';

  @override
  String get profileDefaultName => '备考中';

  @override
  String get profileClearTitle => '清除练习记录';

  @override
  String get profileClearBody =>
      '答题记录、正确率、错题本、成绩报告、错因、打卡、自评难度、复习计划和成就都会清空，回到刚装好的样子。\\n\\n收藏、笔记、词语积累和申论作答保留，题库本身也保留。此操作不可撤销 —— 想留一手就先去「备份与恢复」导出一份。';

  @override
  String get profileClearConfirm => '确认清除';

  @override
  String get profileClearDone => '练习记录已清除';

  @override
  String profileAboutTitle(int count) {
    return '关于 OpenExam · $count 题在库';
  }

  @override
  String get profileAboutBody =>
      '本地优先的刷题工具，与 OpenExam 桌面端同源。\\n\\n商业题库请自行合法导入，App 不会爬取第三方付费内容。';

  @override
  String get profileReplayOnboarding => '重看引导';

  @override
  String get profileClearHint => '答题记录、错题本、成绩报告都会清空';

  @override
  String profileDaysLeft(int days) {
    return '离岸 $days 天';
  }

  @override
  String get profileToday => '就在今天';

  @override
  String get profileTab => '我的';

  @override
  String get profileBadges => '成就';

  @override
  String get profileVocab => '词语';

  @override
  String get profileNotes => '笔记';

  @override
  String get profileMarks => '收藏';

  @override
  String get profileReports => '记录';

  @override
  String get profileStats => '统计';

  @override
  String get profileTips => '技巧';

  @override
  String get profileFeedback => '纠错';

  @override
  String get profileSectionExam => '备考';

  @override
  String get profileFeatures => '界面模块';

  @override
  String profileFeaturesOn(int count) {
    return '$count 项开启';
  }

  @override
  String get profilePlan => '复习计划';

  @override
  String get profilePrefs => '练习偏好';

  @override
  String profileDailyGoalValue(int count) {
    return '每日 $count 题';
  }

  @override
  String get profileSectionBank => '题库';

  @override
  String get profileImport => '导入题目';

  @override
  String profileImportedCount(int count) {
    return '$count 题';
  }

  @override
  String get profileBankManage => '题库管理';

  @override
  String get profileBankHealth => '题库体检';

  @override
  String get profileBackup => '备份与恢复';

  @override
  String get profileSectionApp => '应用';

  @override
  String get profileAiSettings => 'AI 设置';

  @override
  String get profileConfigured => '已配置';

  @override
  String get profileAiUsage => 'AI 用量';

  @override
  String get profilePrivacy => '数据与隐私';

  @override
  String get profilePrivacyBody =>
      '题库、答题记录、统计与错题本都存在本机的 SQLite 数据库里，不上传服务器、不做任何埋点、没有账号体系。\\n\\n唯一会联网的是 AI 功能（申论批改、拍照识题）：只有你主动触发时才发请求，直接发往你自己填的服务商，API Key 存在本机。不配置就完全离线。';

  @override
  String get profileAbout => '关于';

  @override
  String get profileNoStatsYet => '还没开始记，划一组就有数了';

  @override
  String profileStatsLine(int rate, int count) {
    return '正确率 $rate% · 本周 $count 题';
  }

  @override
  String get profileThemeAuto => '自动';

  @override
  String get profileThemeLight => '浅色';

  @override
  String get profileThemeDark => '深色';

  @override
  String get profileTheme => '主题';

  @override
  String get profileRename => '改个称呼';

  @override
  String get profileRenameHint => '例如：上岸倒计时';

  @override
  String get commonSave => '保存';

  @override
  String get profileRegion => '报考地区';

  @override
  String get profileRegionHint => '用来优先推荐对应的真题卷';

  @override
  String get profileDailyGoal => '每日目标';

  @override
  String get profileDailyGoalHint => '在职备考建议 20–30 题，全职冲刺 60 题以上';

  @override
  String get profileSetSize => '默认每组题量';

  @override
  String get commonGotIt => '知道了';

  @override
  String get commonCancel => '取消';

  @override
  String get profilePickExamDate => '选择考试日期';

  @override
  String get profileMockCount => '模考题量';

  @override
  String get profileMockMinutes => '模考时长';

  @override
  String get commonConfirm => '确定';

  @override
  String get profileSetSizeShort => '每组题量';

  @override
  String get profileExamDate => '考试日期';

  @override
  String profileDaysRemaining(int days) {
    return '还有 $days 天';
  }

  @override
  String get profileMock => '限时模考';

  @override
  String get profileMockHint => '按自己那门考试的节奏';

  @override
  String get profileMockCountShort => '题量';

  @override
  String get profileMockMinutesShort => '时长';

  @override
  String get wrongRemoved => '已移出错题本';

  @override
  String get wrongSaved => '已收藏';

  @override
  String get wrongExportHeading => '# 错题本';

  @override
  String wrongExportedAt(String at) {
    return '导出时间：$at';
  }

  @override
  String wrongExportTotal(int count) {
    return '共 $count 题';
  }

  @override
  String get wrongExportHasImage => '（本题含图，导出文件不含图片）';

  @override
  String get wrongExportImageOption => '（图片选项）';

  @override
  String wrongExportAnalysis(String text) {
    return '解析：$text';
  }

  @override
  String wrongExportNote(String text) {
    return '我的笔记：$text';
  }

  @override
  String wrongExportSavedDocs(String name) {
    return '已保存到 App 文档目录：$name';
  }

  @override
  String wrongExportSaved(String name) {
    return '已导出 $name';
  }

  @override
  String wrongExportFailed(String error) {
    return '导出失败：$error';
  }

  @override
  String get wrongQuickLook => '错题速览';

  @override
  String get diagnosisTitle => '弱点诊断';

  @override
  String get wrongDiagnosisHint => '拿你的速度和正确率去比 161 套真题的基准';

  @override
  String get wrongTodayReview => '今日复盘';

  @override
  String wrongRepeatFirst(int count) {
    return '先啃错过两次以上的 $count 题';
  }

  @override
  String get commonStart => '开始';

  @override
  String get wrongBrowseAnalysis => '速览解析';

  @override
  String wrongUntagged(int count) {
    return '$count 题还没标错因，标了才知道是粗心还是不会';
  }

  @override
  String get wrongRepeating => '还在反复犯的';

  @override
  String get wrongLongPressHint => '长按一类可以开四天专项计划';

  @override
  String get wrongNoReason => '未标错因';

  @override
  String get wrongByType => '按题型';

  @override
  String get commonAllArrow => '全部 ›';

  @override
  String wrongViewAll(int count) {
    return '逐题查看全部 $count 题';
  }

  @override
  String get wrongNoPaper => '未归卷题目';

  @override
  String get wrongBookTitle => '错题本';

  @override
  String wrongToClear(int count) {
    return '$count 题待消灭';
  }

  @override
  String get wrongAll => '全部错题';

  @override
  String wrongFiltered(int count) {
    return '筛出 $count 题';
  }

  @override
  String get wrongRedoFiltered => '重练当前筛选的题';

  @override
  String get wrongExportMarkdown => '导出当前列表为 Markdown';

  @override
  String get wrongEmptyHint => '答错的题会自动收进来';

  @override
  String wrongCountWithHint(int count) {
    return '$count 题 · 长按可标错因';
  }

  @override
  String get sessionResultTitle => '本场结果';

  @override
  String sessionResultLine(int rate, int correct, int total, String time) {
    return '正确率 $rate% · 答对 $correct / $total · 用时 $time';
  }

  @override
  String get sessionSeeReport => '看成绩单';

  @override
  String get sessionSeeAnalysis => '逐题看解析';

  @override
  String get sessionMock => '限时模考';

  @override
  String sessionPracticeCount(int count) {
    return '练习 $count 题';
  }

  @override
  String get sessionDaily => '每日一练';

  @override
  String sessionBlankLeft(int count) {
    return '还有 $count 题没作答';
  }

  @override
  String get sessionSubmitWarn => '交卷后未作答的题会计为错题，确定现在交卷吗？';

  @override
  String get sessionSubmitAnyway => '仍然交卷';

  @override
  String get sessionQuitMock => '退出模考？';

  @override
  String get sessionQuitPractice => '结束这组练习？';

  @override
  String get sessionQuitMockBody => '模考中途退出不会生成成绩报告，已答的题仍计入练习记录。';

  @override
  String sessionQuitPracticeBody(int count) {
    return '已答的 $count 题已经保存，可以随时再来一组。';
  }

  @override
  String get commonQuit => '退出';

  @override
  String get sessionSavedHint => '已收藏，可在「我的 → 我的收藏」查看';

  @override
  String get sessionUnsaved => '已取消收藏';

  @override
  String get sessionReportedHint => '已记下，可在「我的 → 纠错记录」里查看';

  @override
  String sessionAnalysisTime(String time) {
    return '解析 · $time';
  }

  @override
  String get sessionReview => '回顾';

  @override
  String get sessionScore => '成绩';

  @override
  String sessionQuestionNo(int n) {
    return '第 $n 题';
  }

  @override
  String get sessionLastQuestion => '最后一题';

  @override
  String get sessionViewSingle => '单题';

  @override
  String get sessionViewSingleHint => '一屏一题，最专注';

  @override
  String get sessionViewDual => '双题';

  @override
  String get sessionViewDualHint => '一屏两题，适合宽屏';

  @override
  String get sessionViewScroll => '整卷';

  @override
  String get sessionViewScrollHint => '连续下滑，像纸质卷';

  @override
  String get sessionLayout => '答题版式';

  @override
  String get sessionWasBlank => '这道题当时没有作答';

  @override
  String get sessionTipsChip => ' 技巧';

  @override
  String get sessionSeeFigure => '见上图';

  @override
  String get sessionAnalysis => '解析';

  @override
  String sessionCorrectAnswer(String answer) {
    return '正确答案 $answer';
  }

  @override
  String get sessionNext => '下一题';

  @override
  String get sessionMultiHint => '多选题 · 选完点「确定」';

  @override
  String get commonConfirmShort => '确定';

  @override
  String sessionConfirmPicked(int count) {
    return '确定（已选 $count 项）';
  }

  @override
  String get sessionHintAuto => '选中即进入下一题 · 长按选项可排除 · 左右滑动可回看';

  @override
  String get sessionHintManual => '长按选项可排除 · 左右滑动切换题目 · 点图片可放大';

  @override
  String get sessionMyNote => '我的笔记';

  @override
  String get sessionSubmit => '交卷';

  @override
  String get whenToday => '今天';

  @override
  String get whenYesterday => '昨天';

  @override
  String whenDaysAgo(int days) {
    return '$days 天前';
  }

  @override
  String get sessionMockScore => '本场成绩';

  @override
  String get sessionPracticeResult => '练习结果';

  @override
  String get sessionGoodShape => '状态不错';

  @override
  String get sessionKeepGoing => '继续保持';

  @override
  String get sessionAnotherSet => '再练一组';

  @override
  String sessionTimeUsed(String time) {
    return '用时 $time';
  }

  @override
  String get sessionPerQuestionNone => '每题 —';

  @override
  String sessionUnanswered(int count) {
    return '未作答 $count';
  }

  @override
  String get sessionDoubtReview => '存疑回顾';

  @override
  String sessionDoubtCount(int count) {
    return '做题时标了 $count 道存疑，点开逐题看';
  }

  @override
  String sessionSlowCount(int count) {
    return '有 $count 题超过 90 秒，考场上这类题应该先跳过';
  }

  @override
  String get sessionByType => '各题型得分';

  @override
  String get sessionWrongReview => '错题回顾';

  @override
  String sessionWrongCount(int count) {
    return '$count 题 · 点开看原题';
  }

  @override
  String get sessionAllCorrect => '全部答对';

  @override
  String get sessionAllCorrectBody => '这一组没有错题，换个题型继续保持手感。';

  @override
  String get sessionGoThrough => '逐题回顾';

  @override
  String get commonDone => '完成';

  @override
  String sessionRedoWrong(int count) {
    return '重做错题 $count';
  }

  @override
  String get sessionNoteTitle => '这道题的笔记';

  @override
  String get sessionNoteHint => '记方法、坑点、公式 —— 回顾时会显示在解析下面';

  @override
  String get commonDelete => '删除';

  @override
  String get sessionWhyWrong => '这题为什么错？';

  @override
  String get sessionTagged => '已标记，可再点一次取消';

  @override
  String get sessionReportTitle => '这道题有问题';

  @override
  String get sessionReportHint => '记在本机，可在「我的」里查看，也会随备份一起导出';

  @override
  String get sessionReportNote => '补充两句（选填）';

  @override
  String get sessionReportSubmit => '记下';

  @override
  String get sessionMaterial => '材料';

  @override
  String get fontSmall => '小';

  @override
  String get fontNormal => '标准';

  @override
  String get fontLarge => '大';

  @override
  String get fontHuge => '特大';

  @override
  String get sessionReading => '阅读设置';

  @override
  String get sessionFontSize => '题目字号';

  @override
  String get sessionAutoNext => '答对自动下一题';

  @override
  String get sessionAutoNextHint => '答错时仍会停下看解析';

  @override
  String get sessionCard => '答题卡';

  @override
  String sessionAnsweredOf(int done, int total) {
    return '已答 $done / $total';
  }

  @override
  String get sessionRight => '对';

  @override
  String get sessionWrongShort => '错';

  @override
  String get sessionAnswered => '已答';

  @override
  String get sessionDoubt => '存疑';

  @override
  String get sessionSubmitEarly => '提前交卷';

  @override
  String get difficultyEasy => '简单';

  @override
  String get difficultyMedium => '一般';

  @override
  String get difficultyHard => '难';

  @override
  String get sessionDifficultyFor => '这题对我';

  @override
  String get sessionScratch => '草稿纸与计算器';

  @override
  String get sessionHasScratch => '这题已有草稿';

  @override
  String get sessionScratchHint => '资料分析可以直接算';

  @override
  String get sessionWriteNote => '写笔记';

  @override
  String get sessionHasNote => '这题已有笔记';

  @override
  String get sessionNoteShort => '记方法和坑点，回顾时会显示';

  @override
  String get sessionLayoutHint => '单题 / 双题 / 整卷';

  @override
  String get sessionReadingHint => '字号与自动下一题';

  @override
  String get sessionUnsave => '取消收藏';

  @override
  String get sessionSave => '收藏这题';

  @override
  String get sessionSaveHint => '收藏的题在「我的 → 我的收藏」';

  @override
  String get sessionReportShort => '这题有问题';

  @override
  String get sessionReportShortHint => '答案有误、解析看不懂都可以标';

  @override
  String get homeNoQuestionsHere => '这里还没有题';

  @override
  String get homeNoUnseen => '这个范围里没有没做过的题了';

  @override
  String get homeNoWrongHere => '这里还没有错题';

  @override
  String homeReciteSub(String name) {
    return '$name · 背题';
  }

  @override
  String get homeRecite => '背题';

  @override
  String get homeHardTagged => '标难的题';

  @override
  String homeTimedSub(String name) {
    return '$name · 限时';
  }

  @override
  String homeTimedCat(String name) {
    return '$name限时练';
  }

  @override
  String get homeEssay => '申论';

  @override
  String get homeManualTask => '手写任务勾选即可，做完别忘了打勾';

  @override
  String get homeRedoWrong => '错题重练';

  @override
  String get homeWeakDrill => '弱项强化';

  @override
  String get homeDeleteTask => '删除安排';

  @override
  String homeDeleteTaskConfirm(String title) {
    return '确定删除「$title」？';
  }

  @override
  String get homeResume => '继续上次';

  @override
  String homeResumeLine(String title, int count) {
    return '$title · 还剩 $count 题';
  }

  @override
  String get homeDaily => '每日一练';

  @override
  String get homeDailyHint => '今天的固定卷';

  @override
  String homeProvincePapers(String name) {
    return '$name真题';
  }

  @override
  String homeProvinceHint(int count) {
    return '$count 题 · 你要考的卷';
  }

  @override
  String get homeWeakLocked => '先练一组再解锁';

  @override
  String get homeWeakHint => '按薄弱模块配比';

  @override
  String get homeNoWrong => '暂无错题';

  @override
  String homeWrongLeft(int count) {
    return '$count 题待清';
  }

  @override
  String get homeEssayMark => '申论批改';

  @override
  String get homeEssayHint => '写一篇，交给 AI 评';

  @override
  String get homeMock => '限时模考';

  @override
  String get homeMoreWays => '更多练法';

  @override
  String homeStreak(int days) {
    return '连续打卡 $days 天';
  }

  @override
  String get homeDailyCheckin => '每日一练打卡';

  @override
  String homePerSet(int count) {
    return '每组 $count 题';
  }

  @override
  String homeTotalInBank(int count) {
    return '共 $count 题';
  }

  @override
  String get homeDailyReview => '今日一练回顾';

  @override
  String homeCatchUp(String date) {
    return '补做 $date';
  }

  @override
  String homeRegionPapers(String name) {
    return '$name真题';
  }

  @override
  String get homeTodayRoute => '今日航线';

  @override
  String get homeArrange => '安排';

  @override
  String homeAllTasks(int count) {
    return '全部 $count';
  }

  @override
  String get homeAdjust => '调整';

  @override
  String get homeIslands => '五座岛';

  @override
  String homeHardCount(int count) {
    return '自己标难的 $count 题';
  }

  @override
  String get homeGreetDone => '今天划完了';

  @override
  String get homeGreetMorning => '早，该出发了';

  @override
  String get homeGreetKeep => '继续划';

  @override
  String get homeGreetFinish => '收个尾再靠岸';

  @override
  String get homeNoRoute => '还没排今天的航线';

  @override
  String get homeRouteHint => '模板可以改，删掉不做的就行';

  @override
  String get homeGoPlan => '去安排';

  @override
  String get scopeAll => '全部题';

  @override
  String get scopeUnseen => '没做过';

  @override
  String get scopeWrong => '做错过';

  @override
  String get scopeAllHint => '优先近年真题，同年内随机';

  @override
  String get scopeUnseenLong => '没做过的';

  @override
  String get scopeUnseenHint => '跳过已做 · 仍优先近年';

  @override
  String get scopeWrongLong => '做错过的';

  @override
  String get scopeWrongHint => '只抽上次答错的题';

  @override
  String get scopeTitle => '抽题范围';

  @override
  String get scopeHint => '长按题量可以改每组题数';

  @override
  String scopeCount(int count) {
    return '$count 题';
  }

  @override
  String get yearAllHint => '题库里有的都抽，仍然优先近年';

  @override
  String yearLast3Hint(String from, String to) {
    return '$from—$to 年 · 结构和考点最贴近今年';
  }

  @override
  String yearLast1Hint(String year) {
    return '只有 $year 年 · 练常识时间政策题必用这一档';
  }

  @override
  String get yearRangeTitle => '年份范围';

  @override
  String get yearRangeHint =>
      '常识判断一半的题引的是考前一年的讲话原文和新出台文件，旧题的答案已经作废；言语、判断、资料的结构常年不动，老题照样能练。';

  @override
  String yearRangeCount(int count) {
    return '$count 题';
  }

  @override
  String get homeDailyGoal => '每日目标';

  @override
  String get homeDailyGoalHint => '在职备考建议 20–30 题，全职冲刺 60 题以上';

  @override
  String countQuestions(int count) {
    return '$count 题';
  }

  @override
  String get homeSetSize => '每组题量';

  @override
  String get homeAboutBody =>
      '本地优先的公务员行测刷题工具。题库、答题记录、统计全部保存在这台设备上，不联网、不上传。内置题来自 OpenExam 桌面端种子库，也可以在「导入」页导入自己的题目。';

  @override
  String get homeTimed => '限时';

  @override
  String homeExpandHint(int count) {
    return '共 $count 题 · 展开分类后开始';
  }

  @override
  String get homeNoSubtypes => '暂无细分';

  @override
  String get homeMixAll => '全部混练';

  @override
  String homeMixHint(int count, int minutes) {
    return '$count 题 · 约 $minutes 分钟节奏';
  }

  @override
  String homeSubCount(int count) {
    return '$count 题';
  }

  @override
  String get homePlain => '直接练';

  @override
  String homePlainHint(int count) {
    return '$count 题，不计时';
  }

  @override
  String get homeTimedDrill => '限时练';

  @override
  String homeTimedDrillHint(int count, int minutes) {
    return '$count 题 · 约 $minutes 分钟，按考场节奏';
  }

  @override
  String get homeReciteHint => '不作答，直接看答案和解析';

  @override
  String get dxScopeAll => '全部作答记录';

  @override
  String dxThinSample(int count) {
    return '只有 $count 条作答记录，结论还不稳。做够 100 题再看一次。';
  }

  @override
  String dxSlowTitle(String name) {
    return '$name 慢得会拖垮整张卷';
  }

  @override
  String dxSlowEvidence(int secs, int bench, int pct) {
    return '每题 $secs 秒，基准 $bench 秒，慢 $pct%';
  }

  @override
  String dxSlowOverrun(int mins) {
    return '；照这个速度一套卷多花 $mins 分钟';
  }

  @override
  String dxSlightlySlowTitle(String name) {
    return '$name 比基准慢一点';
  }

  @override
  String dxPaceEvidence(int secs, int bench) {
    return '每题 $secs 秒，基准 $bench 秒';
  }

  @override
  String dxSlightlySlowAction(int bench) {
    return '还在可控范围，但限时练的时候按 $bench 秒卡表，别让它继续涨。';
  }

  @override
  String dxFastSteadyTitle(String name) {
    return '$name 又快又稳';
  }

  @override
  String dxFastSteadyEvidence(int secs, int bench, String rate) {
    return '每题 $secs 秒（基准 $bench 秒），正确率 $rate';
  }

  @override
  String get dxFastSteadyAction => '这块不用再投时间，省下来的分钟给弱的模块。';

  @override
  String dxRushTitle(String name) {
    return '$name 是做太快错的，不是不会';
  }

  @override
  String dxRushEvidence(
    int secs,
    int bench,
    int pct,
    String rate,
    String target,
  ) {
    return '每题 $secs 秒，比基准 $bench 秒快 $pct%；正确率只有 $rate（目标 $target）';
  }

  @override
  String dxRushAction(int bench, String target, String how) {
    return '先把速度压回 $bench 秒一题，正确率提到 $target 之后再提速。省下来的几分钟换不回丢掉的分 —— $how';
  }

  @override
  String dxAccuracyGapTitle(String name) {
    return '$name 正确率离目标还差一截';
  }

  @override
  String dxAccuracyGapEvidence(
    String rate,
    int correct,
    int attempts,
    String target,
  ) {
    return '$rate（$correct/$attempts），目标 $target';
  }

  @override
  String dxAlmostTitle(String name) {
    return '$name 差一口气到目标';
  }

  @override
  String dxAlmostEvidence(String rate, String target) {
    return '$rate，目标 $target';
  }

  @override
  String get dxAlmostAction => '按错因翻一遍这个模块的错题，看是同一类反复栽还是零散错。';

  @override
  String get dxTimeSinkTitle => '数量关系吃掉了太多时间';

  @override
  String dxTimeSinkEvidence(String share, String paper) {
    return '它占了你 $share 的做题时间，卷面上只占 $paper 的题';
  }

  @override
  String get dxOverthinkTitle => '常识判断纠结太久';

  @override
  String get dxThinPracticeTitle => '资料分析练得太少';

  @override
  String dxThinPracticeEvidence(String share, String paper) {
    return '只占你练习量的 $share，卷面上占 $paper';
  }

  @override
  String get dxRepeatTitle => '错题在重复犯，不是新错';

  @override
  String dxRepeatEvidence(int total, int repeat, String pct) {
    return '错题本 $total 题里有 $repeat 题错过两次以上（$pct）';
  }

  @override
  String get dxRepeatAction =>
      '重复错说明第一次复盘没弄懂原因。挑错得最多的那几道，逐题写下「当时为什么选了它」，比再做十道新题有用。';

  @override
  String get dxUntaggedTitle => '大部分错题没标错因';

  @override
  String dxUntaggedEvidence(int total, int tagged) {
    return '$total 题里只标了 $tagged 题';
  }

  @override
  String get dxUntaggedAction =>
      '标错因是复盘唯一的杠杆：知识点没会、看错题、算错、时间不够，这四类的补法完全不同，不分开就只能整本重做。';

  @override
  String get dxTrendUpTitle => '近两周在往上走';

  @override
  String get dxTrendDownTitle => '近两周反而掉了';

  @override
  String dxTrendEvidence(String recent, String earlier) {
    return '近两周 $recent，之前 $earlier';
  }

  @override
  String get dxTrendUpAction => '保持现在的练法别换。';

  @override
  String get dxTrendDownAction =>
      '一般是两种原因：开始限时了，或者换到了更难的模块。先确认是哪一种，前者正常，后者要放慢。';

  @override
  String get dxTailBlankTitle => '资料分析没做完 —— 时间是在前面丢的';

  @override
  String dxBlankTitle(int count) {
    return '有 $count 题没作答';
  }

  @override
  String dxBlankWithTail(int total, int tail) {
    return '共空 $total 题，其中资料分析空 $tail 题';
  }

  @override
  String dxBlankOnly(int total) {
    return '共空 $total 题';
  }

  @override
  String get dxTailBlankAction =>
      '资料分析是全卷唯一练到位就能拿满的模块，绝不能留给残余时间。下次把它提到判断推理之后做，数量关系放最后。';

  @override
  String get dxBlankAction => '空着的题也要涂 —— 统一涂同一个字母，四个选项的正确率都在 25% 上下。';

  @override
  String get dxOvertimeTitle => '整卷超时';

  @override
  String dxOvertimeEvidence(int actual, int budget) {
    return '实际 $actual 分钟，按基准这些题应该 $budget 分钟';
  }

  @override
  String get dxOvertimeAction => '超时通常集中在一两个模块，看上面哪一块的「慢」被标红了，先卡那一块的表。';

  @override
  String get dxUnderTimeTitle => '整卷节奏比基准快';

  @override
  String dxUnderTimeEvidence(int actual, int budget) {
    return '实际 $actual 分钟，基准 $budget 分钟';
  }

  @override
  String get dxUnderTimeAction => '如果正确率也达标，可以把省下的时间还给数量关系多挑两道。';

  @override
  String get dxNoRecords => '还没有作答记录';

  @override
  String dxHeadlineClean(int count, String rate) {
    return '$count 题，正确率 $rate，没查出明显短板';
  }

  @override
  String dxHeadlineWorst(int count, String rate, String what) {
    return '$count 题，正确率 $rate；最该先修的是$what';
  }

  @override
  String get dxPageTitle => '弱点诊断';

  @override
  String get dxEmptyTitle => '还没有作答记录';

  @override
  String get dxEmptyBody => '做完一组题再回来 —— 诊断靠的是你自己的做题数据，不是别人的经验。';

  @override
  String get dxFootnote =>
      '基准来自 161 套真题（安徽 2023—2026、国考 2022—2026）逐题统计出的题量和结构；单题秒数是按这套题量倒推的建议值，跟「解题技巧」页上的是同一个数。';

  @override
  String get dxModuleTable => '各模块 · 实测对基准';

  @override
  String get dxColQuestions => '题';

  @override
  String get dxColAccuracy => '正确率';

  @override
  String get dxColSeconds => '秒/题';

  @override
  String get dxColBench => '基准';

  @override
  String get dxFindings => '结论';

  @override
  String dxFindingsCount(int count) {
    return '$count 条';
  }

  @override
  String get dxNoWeakSpot => '各模块的速度和正确率都在基准附近，没有单独拎出来说的短板。继续按现在的练法走。';

  @override
  String get dxNoBenchmark =>
      '这个题库的分类对不上行测五模块，没有可比的基准 —— 上面的总题数和正确率仍然是你的真实数据，但\"每题该几秒、正确率该到多少\"这类结论给不了。';

  @override
  String get dxLevelBad => '要修';

  @override
  String get dxLevelWatch => '注意';

  @override
  String get dxLevelGood => '不错';

  @override
  String get dxAiSection => 'AI 深入分析';

  @override
  String get dxRegenerate => '重新生成';

  @override
  String get dxAiPitch => '上面的结论是本机按真题基准算的，已经能直接用。AI 在这基础上再串一遍因果，并排一份一周训练计划。';

  @override
  String get dxAiNotConfigured => '还没配 AI。上面的结论不用配也能看 —— AI 只是在它之上多一层解读。';

  @override
  String get dxAskAi => '让 AI 分析';

  @override
  String get dxConfigureAi => '去配置 AI';

  @override
  String get dashTitle => '备考档案';

  @override
  String get dashByModule => '模块能力';

  @override
  String get dashByModuleHint => '正确率由低到高';

  @override
  String get dashLast35 => '最近 35 天';

  @override
  String get dashHeatHint => '颜色越深练得越多';

  @override
  String get dashTrend => '成绩走势';

  @override
  String dashLastN(int count) {
    return '最近 $count 次';
  }

  @override
  String get dashWhen => '习惯时段';

  @override
  String get dashWhenHint => '一天里你在什么时候刷题';

  @override
  String get dashAdvice => '给你的建议';

  @override
  String get dashAdviceHint => '按当前数据推断';

  @override
  String get dashEmpty => '刷完第一组题，这一页就会有内容。';

  @override
  String get dashDataNote => '数据只统计本机记录，清除练习记录后这一页会重新开始。';

  @override
  String get dashDoFirstSet => '先刷一组 20 题';

  @override
  String get dashDoFirstSetHint => '有了记录才能算正确率、排弱项，这一页也才有东西可看。';

  @override
  String dashWeakest(String name) {
    return '$name是当前短板';
  }

  @override
  String dashWeakestBody(int rate, int done) {
    return '正确率 $rate%，已练 $done 题。弱项强化会给它最大配额，先把这块拉到 70% 以上。';
  }

  @override
  String get dashTopCareless => '错题里\"粗心\"最多';

  @override
  String get dashTopUnknown => '错题里\"不会\"最多';

  @override
  String get dashTopMisread => '错题里\"审题\"最多';

  @override
  String get dashTopNoTime => '错题里\"没时间\"最多';

  @override
  String dashCarelessBody(int count) {
    return '$count 道标了粗心。别加量，做完把答案带回题干核对一遍。';
  }

  @override
  String dashUnknownBody(int count) {
    return '$count 道标了不会。先回去补方法，再刷同类题才有意义。';
  }

  @override
  String dashMisreadBody(int count) {
    return '$count 道栽在审题。做题时把限定词和单位圈出来。';
  }

  @override
  String dashNoTimeBody(int count) {
    return '$count 道是时间不够。先按模块限时练，再上整卷。';
  }

  @override
  String get dashGoTagged => '去错题本按错因过一遍';

  @override
  String dashDropped(String name, int points) {
    return '$name这周退了 $points 个点';
  }

  @override
  String dashDroppedBody(int before, int now, int done) {
    return '上一周 $before%，最近 7 天 $now%（$done 题）。先别加量，去错题本按这个模块过一遍，看是同一类题反复错还是手生了。';
  }

  @override
  String get dashSeeModuleWrong => '看这个模块的错题';

  @override
  String dashRose(String name, int points) {
    return '$name这周涨了 $points 个点';
  }

  @override
  String dashRoseBody(int before, int now, int done) {
    return '上一周 $before%，最近 7 天 $now%（$done 题）。这块的练法是对的，可以开始压时间了。';
  }

  @override
  String dashSlow(String name) {
    return '$name花的时间偏长';
  }

  @override
  String dashSlowBody(int secs) {
    return '平均每题 $secs 秒。行测里超过 90 秒的题在考场上应该先跳过，练的时候也要按这个标准掐表。';
  }

  @override
  String get dashTimeThisModule => '限时练这个模块';

  @override
  String get dashStreakBroken => '连续打卡断了';

  @override
  String get dashStreakBrokenBody => '每天 10 题也算数，节奏比单次量更重要。';

  @override
  String dashStreakDays(int days) {
    return '已经连续 $days 天';
  }

  @override
  String get dashStreakBody => '保持住。真正拉开差距的是能不能天天回来，而不是某天刷了 200 题。';

  @override
  String get dashAllSteady => '各项都挺稳';

  @override
  String get dashAllSteadyBody => '可以开始按整卷限时练，把速度也压进考试节奏。';

  @override
  String dashDaysLine(int days, int streak) {
    return '练过 $days 天 · 连续 $streak 天';
  }

  @override
  String get unitDays => '天';

  @override
  String get dashToExam => '距考试';

  @override
  String get dashOverallRate => '总正确率';

  @override
  String get dashTotalAnswered => '累计答题';

  @override
  String get dashWrongLeft => '待清错题';

  @override
  String get dashToday => '今日进度';

  @override
  String dashPacePerQ(int secs) {
    return '${secs}s/题';
  }

  @override
  String get dashLess => '少';

  @override
  String get dashMore => '多';

  @override
  String get dashHeatToday => '右下角为今天';

  @override
  String dashFlat(int rate) {
    return '最近一次 $rate%，和最早那次持平';
  }

  @override
  String dashUp(int from, int to, int points) {
    return '从 $from% 到 $to%，涨了 $points 个点';
  }

  @override
  String dashDown(int from, int to, int points) {
    return '从 $from% 到 $to%，掉了 $points 个点';
  }

  @override
  String get dashHour0 => '0 点';

  @override
  String dashPeakHour(int hour) {
    return '最常在 $hour 点前后刷题';
  }

  @override
  String get dashHour23 => '23 点';

  @override
  String get dashPractiseNow => '现在就练';

  @override
  String get bankTab => '题库';

  @override
  String get bankPapers => '试卷';

  @override
  String get bankAllRegions => '全部地区';

  @override
  String get bankAllYears => '全部年份';

  @override
  String get bankNoYear => '未标注';

  @override
  String bankYear(String year) {
    return '$year 年';
  }

  @override
  String get bankAllStatus => '全部状态';

  @override
  String get bankNotStarted => '未开始';

  @override
  String get bankInProgress => '进行中';

  @override
  String get bankFinished => '已做完';

  @override
  String bankPaperCount(int count) {
    return '$count 套真题卷';
  }

  @override
  String bankMatchedCount(int matched, int total) {
    return '$matched / $total 套';
  }

  @override
  String get bankSearchHint => '搜索年份、省份、卷名';

  @override
  String get bankFilterYear => '年份';

  @override
  String get bankFilterStatus => '状态';

  @override
  String get bankSort => '排序';

  @override
  String get bankSortYear => '按年份（新→旧）';

  @override
  String get bankSortProgress => '按完成度';

  @override
  String get bankSortSize => '按题量';

  @override
  String get bankNoPapers => '还没有试卷';

  @override
  String get bankNoMatch => '没有匹配的试卷';

  @override
  String get bankNoPapersHint => '到「我的 → 导入题目」导入后，整套试卷会出现在这里。';

  @override
  String get bankNoMatchHint => '换个关键词试试，比如 2025、江苏、国考。';

  @override
  String get bankUndatedGroup => '未标注年份';

  @override
  String bankPaperCountShort(int count) {
    return '$count 套';
  }

  @override
  String get bankPickPaper => '选一张卷';

  @override
  String get bankPickPaperHint => '左边挑一张。';

  @override
  String get bankUntitledPaper => '未命名试卷';

  @override
  String bankPaperProgress(int done, int total) {
    return '$done / $total 题';
  }

  @override
  String get bankImport => '导入';

  @override
  String get badgeFirstBloodName => '开张';

  @override
  String get badgeFirstBloodDesc => '完成第一道题';

  @override
  String get badgeAnswers100Name => '百题';

  @override
  String get badgeAnswers100Desc => '累计答题 100 道';

  @override
  String get badgeAnswers500Name => '五百题';

  @override
  String get badgeAnswers500Desc => '累计答题 500 道';

  @override
  String get badgeAnswers2000Name => '两千题';

  @override
  String get badgeAnswers2000Desc => '累计答题 2000 道';

  @override
  String get badgeStreak3Name => '三天';

  @override
  String get badgeStreak3Desc => '连续练习 3 天';

  @override
  String get badgeStreak7Name => '一周不断';

  @override
  String get badgeStreak7Desc => '连续练习 7 天';

  @override
  String get badgeStreak30Name => '一月不断';

  @override
  String get badgeStreak30Desc => '连续练习 30 天';

  @override
  String get badgeActive20Name => '常客';

  @override
  String get badgeActive20Desc => '累计练习 20 天';

  @override
  String get badgeRate70Name => '及格线';

  @override
  String get badgeRate70Desc => '总正确率达到 70%（至少 50 题）';

  @override
  String get badgeRate85Name => '稳';

  @override
  String get badgeRate85Desc => '总正确率达到 85%（至少 200 题）';

  @override
  String get badgeStrong3Name => '三科过硬';

  @override
  String get badgeStrong3Desc => '三个模块正确率达到 80%（每个至少 20 题）';

  @override
  String get badgeExam1Name => '首战';

  @override
  String get badgeExam1Desc => '完成第一次限时模考';

  @override
  String get badgeExam10Name => '身经十战';

  @override
  String get badgeExam10Desc => '完成 10 次限时模考';

  @override
  String get badgeExam80Name => '高分卷';

  @override
  String get badgeExam80Desc => '任意一次模考正确率达到 80%';

  @override
  String get badgeCleanWrongName => '清空错题';

  @override
  String get badgeCleanWrongDesc => '把错题本清到 0（至少错过 20 题）';

  @override
  String get badgeDay100Name => '单日百题';

  @override
  String get badgeDay100Desc => '一天内做满 100 题';

  @override
  String get badgeNotes20Name => '会总结';

  @override
  String get badgeNotes20Desc => '写下 20 条题目笔记';

  @override
  String get badgeMarks30Name => '会收集';

  @override
  String get badgeMarks30Desc => '收藏 30 道题';

  @override
  String get badgeGroupVolume => '题量';

  @override
  String get badgeGroupConsistency => '坚持';

  @override
  String get badgeGroupAccuracy => '精度';

  @override
  String get badgeGroupExams => '考场';

  @override
  String get badgeGroupGrind => '攻坚';

  @override
  String get tierBronze => '铜';

  @override
  String get tierSilver => '银';

  @override
  String get tierGold => '金';

  @override
  String get tierPlatinum => '铂金';

  @override
  String get badgesTitle => '成就';

  @override
  String badgesUnlocked(int done, int total) {
    return '已解锁 $done / $total';
  }

  @override
  String get badgesNote => '全部按本机数据计算，清除练习记录会重新开始';

  @override
  String get badgesEarned => '已达成';

  @override
  String badgesToGo(int count) {
    return ' · 还差 $count';
  }

  @override
  String get badgesUnlockedTitle => '解锁成就';

  @override
  String badgesAlsoUnlocked(int count) {
    return '同时还解锁了 $count 个';
  }

  @override
  String get badgesTake => '收下';

  @override
  String badgesEarnedOn(String date) {
    return '$date获得';
  }

  @override
  String planCatPractice(String name) {
    return '$name练习';
  }

  @override
  String get planDeleteSet => '删除计划';

  @override
  String planDeleteSetBody(String name, int count) {
    return '「$name」和里面的 $count 条任务都会删掉，已打的勾不受影响。';
  }

  @override
  String get planDeleteTask => '删除安排';

  @override
  String planRepeatNote(String title, String rule) {
    return '「$title」是$rule的任务。';
  }

  @override
  String get planSkipToday => '今天先跳过';

  @override
  String get planDeleteForever => '以后都删';

  @override
  String get planTitle => '复习计划';

  @override
  String planStreak(int days) {
    return '计划连签 $days 天 · 勾完当天清单算一天';
  }

  @override
  String get planIntro => '选好模板后，每天按清单练；可再加自己的任务';

  @override
  String planMonth(int n) {
    return '$n月';
  }

  @override
  String get planSwipeHint => '左右滑动看更多天';

  @override
  String get planBackToToday => '回到今天';

  @override
  String get planNothingToday => '这天还没有安排';

  @override
  String get planAddHint => '加一条，或从范例开一份';

  @override
  String get planAdd => '加安排';

  @override
  String get planToday => '今日安排';

  @override
  String get planManage => '管理';

  @override
  String get planAddTitle => '添加安排';

  @override
  String get planMine => '我的计划';

  @override
  String get planOff => '未启用';

  @override
  String get planPick => '选计划';

  @override
  String get planTodayMark => '今';

  @override
  String get commonNew => '新建';

  @override
  String get planClosed => '计划已关闭';

  @override
  String get planClose => '关闭计划';

  @override
  String get planClosedHint => '计划已关闭，点下面任意一份重新用起来';

  @override
  String get planNone => '还没有计划，点右上角 ＋ 建一份';

  @override
  String planItemCount(int count) {
    return '$count 条';
  }

  @override
  String get planNewTitle => '新建计划';

  @override
  String get planCreate => '建好';

  @override
  String get planName => '名字';

  @override
  String get planNameHint => '例如 考前冲刺';

  @override
  String get planStartFrom => '从哪儿开始';

  @override
  String get planBlank => '空白';

  @override
  String get planBlankHint => '自己一条条加';

  @override
  String get planTemplateHint => '范例只是抄一份过来，每条都能改能删';

  @override
  String get taskCatPractice => '题型练习';

  @override
  String get taskManual => '备忘 / 手写';

  @override
  String get taskVocab => '背词语';

  @override
  String get taskCheckin => '打卡';

  @override
  String get taskOpenWrong => '打开错题本';

  @override
  String get taskCatPracticeHint => '按题型抽题练习';

  @override
  String get taskMockHint => '50 题 · 可设定分钟';

  @override
  String get taskWrongHint => '从错题里抽练';

  @override
  String get taskWeakHint => '按薄弱模块抽题';

  @override
  String get taskManualHint => '勾选完成即可，不自动开练';

  @override
  String get taskVocabHint => '今天到期的成语和易错词';

  @override
  String get taskCheckinHint => '做完打个勾，不跳任何页面';

  @override
  String get taskOpenWrongHint => '跳到错题本整理';

  @override
  String get taskUntitled => '未命名任务';

  @override
  String get taskEdit => '任务安排';

  @override
  String get taskWhat => '做什么';

  @override
  String get taskWhatHint => '例如 背 20 个成语';

  @override
  String get taskHowOften => '多久做一次';

  @override
  String get taskOnceOnly => '只出现在这一天';

  @override
  String get taskEditForever => '改这条任务，往后每次都跟着变';

  @override
  String get taskAlsoPractise => '顺便练题';

  @override
  String get taskAlsoPractiseHint => '勾完就算，不用设也行';

  @override
  String get taskType => '题型';

  @override
  String get taskCount => '题量';

  @override
  String get taskNote => '备注（可选）';

  @override
  String get taskMinutes => '限时（分钟，可选）';

  @override
  String get taskSoftLimit => '按题量软限时';

  @override
  String get taskSoftLimitHint => '未填分钟时，按题量估算时长';

  @override
  String get taskDelete => '删除此安排';

  @override
  String get taskTapHint => '点「开始」才会进入练习；点这一行只改安排，避免误触。';

  @override
  String get taskEditTitle => '编辑安排';

  @override
  String get commonRename => '重命名';

  @override
  String get repeatOnce => '只这一次';

  @override
  String get repeatDaily => '每天';

  @override
  String get repeatWeekdays => '工作日';

  @override
  String get repeatWeekly => '每周这天';

  @override
  String get repeatEveryOther => '隔一天';

  @override
  String cmExported(int count) {
    return '已导出 $count 道题';
  }

  @override
  String get cmClearBank => '清空题库';

  @override
  String cmClearBody(int count) {
    return '删掉全部 $count 道题。';
  }

  @override
  String get cmClearNote =>
      '做题记录、错题本、笔记不会删 —— 重新导入同一批题还能对上。\\n\\n这一步不可撤销，建议先导出。';

  @override
  String get cmClear => '清空';

  @override
  String cmCleared(int count) {
    return '已清空 $count 道题';
  }

  @override
  String get cmMerge => '合并分类';

  @override
  String cmMergeBody(int count, String from, String to) {
    return '「$from」的 $count 道题会并进「$to」。';
  }

  @override
  String get cmMergeNote => '这一步不可撤销，但题本身不会丢。';

  @override
  String get cmMergeConfirm => '合并';

  @override
  String cmMerged(String name) {
    return '已并入「$name」';
  }

  @override
  String get cmRenamed => '已改名';

  @override
  String get cmNeedAiKey => '先去「我的 → AI 设置」配一个 key';

  @override
  String get cmUncategorised => '未分类';

  @override
  String get cmNoTargets => '还没有别的分类可归，先手动建几个';

  @override
  String get cmAiSort => 'AI 重新分类';

  @override
  String cmAiSortBody(String name) {
    return '把「$name」里的题按现有分类重新归一遍。';
  }

  @override
  String cmAiSortNote(int count) {
    return 'AI 只会在你已有的 $count 个分类里选，不会新造。';
  }

  @override
  String get cmReading => '读题…';

  @override
  String get cmAiSortFailed => 'AI 没能归出结果，可以手动改';

  @override
  String cmAiSorted(int count) {
    return '归好了 $count 道';
  }

  @override
  String get cmTitle => '题库管理';

  @override
  String get cmRenameHint => '改名就是改名；改成已有的名字就是把两类并成一类。题一道都不会丢。';

  @override
  String get cmEmptyTitle => '题库还是空的';

  @override
  String get cmEmptyBody => '导入题目之后，分类会出现在这里。';

  @override
  String get cmRenameMerge => '改名 / 合并';

  @override
  String get cmMergeInto => '并进已有的：';

  @override
  String wrongMissedTimes(String name, int count) {
    return '$name · 错过 $count 次';
  }

  @override
  String wrongPlanStarted(String name) {
    return '已开始「$name」四天计划';
  }

  @override
  String wrongPlanDay(String name, int day) {
    return '$name · 第 $day 天';
  }

  @override
  String wrongPickRedo(int count) {
    return '挑 $count 题重做';
  }

  @override
  String get wrongNone => '还没有错题';

  @override
  String get wrongNoneHint => '去练习页刷一组，答错的题会自动进入这里，答对后自动移出。';

  @override
  String get wrongFilterType => '题型';

  @override
  String get wrongAllTypes => '全部题型';

  @override
  String get wrongFilterReason => '错因';

  @override
  String get wrongAllReasons => '全部错因';

  @override
  String get wrongFilterPaper => '来源卷';

  @override
  String get wrongAllPapers => '全部试卷';

  @override
  String get wrongFilterLevel => '难度';

  @override
  String get wrongAllLevels => '全部难度';

  @override
  String get wrongLevelHard => '我标了难';

  @override
  String get wrongLevelNone => '没标过';

  @override
  String get wrongSort => '排序';

  @override
  String get wrongSortRecent => '最近错的在前';

  @override
  String get wrongSortMost => '错得最多在前';

  @override
  String wrongFilteredHint(int count) {
    return '筛出 $count 题 · 长按任意题可标错因或移出';
  }

  @override
  String get wrongRedoThis => '重做这道题';

  @override
  String get wrongAnswerOnly => '只看答案解析';

  @override
  String get wrongTenMore => '再练 10 道同类型';

  @override
  String get wrongAddToSaved => '加入收藏';

  @override
  String get wrongTagReason => '标记错因';

  @override
  String get wrongRemoveFromBook => '移出错题本';

  @override
  String get wrongRemoveShort => '移出';

  @override
  String wrongCorrectAnswer(String answer) {
    return '  ·  正确答案 $answer';
  }

  @override
  String wrongPlanTitle(String name) {
    return '$name 四天计划';
  }

  @override
  String get wrongPlanDoneToday => '今天这步做完了，明天再来';

  @override
  String get wrongPlanGapHint => '中间隔一天，记忆才吃得住';

  @override
  String get wrongPlanAgain => '再练一次';

  @override
  String get statsTitle => '学习统计';

  @override
  String get statsLast30 => '近 30 天答题';

  @override
  String get statsAvgRate => '平均正确率';

  @override
  String get statsActiveDays => '有效练习天';

  @override
  String get statsDaily => '每日题量';

  @override
  String get statsLast30Short => '近 30 天';

  @override
  String get statsWeekly => '每周走势';

  @override
  String get statsLast8Weeks => '近 8 周';

  @override
  String get statsAccuracyTrend => '正确率趋势';

  @override
  String get statsDaysPractised => '练过的日子';

  @override
  String get statsScoreTrend => '成绩趋势';

  @override
  String get statsAllReports => '全部记录';

  @override
  String get statsReasons => '错因分布';

  @override
  String get statsTagged => '标记过的';

  @override
  String get statsByType => '题型强弱';

  @override
  String get statsLowToHigh => '低到高';

  @override
  String get statsEmptyTypes => '刷一组题后，这里会显示你的强项和弱项';

  @override
  String statsDoneCount(int count) {
    return ' $count 题';
  }

  @override
  String statsPeak(int count) {
    return '峰值 $count 题';
  }

  @override
  String get statsNoRecords => '还没有练习记录';

  @override
  String get statsOneMoreDay => '再练一天就能看到趋势了';

  @override
  String statsFrom(String rate) {
    return '$rate 起';
  }

  @override
  String statsLatest(String rate) {
    return '最新 $rate';
  }

  @override
  String get statsNoScores => '还没有成绩记录，完成一组 5 题以上的练习即可';

  @override
  String get statsSameAsLast => '与上次持平';

  @override
  String statsUpFromLast(int delta) {
    return '较上次 +$delta';
  }

  @override
  String statsDownFromLast(int delta) {
    return '较上次 $delta';
  }

  @override
  String statsAverage(int rate) {
    return '平均 $rate%';
  }

  @override
  String get statsMostlyCareless => '大部分错题是粗心 —— 别加练，先放慢做题速度、把答案带回题干核对。';

  @override
  String get statsMostlyGaps => '大部分错题是知识点没掌握 —— 先回去补方法，再刷同类题。';

  @override
  String get statsMostlyMisread => '大部分错题栽在审题 —— 做题时把限定词、单位圈出来。';

  @override
  String get statsMostlyTime => '大部分错题是时间不够 —— 先练单模块限时，再上整卷。';

  @override
  String get statsVolume => '题量';

  @override
  String statsLatestIs(String kind, int count) {
    return '最右为最近一次（$kind · $count 题），点它可逐题回顾';
  }

  @override
  String get statsKindMock => '模考';

  @override
  String get statsKindPractice => '练习';

  @override
  String get vocabToday => '今日';

  @override
  String get vocabFrequent => '高频';

  @override
  String get vocabConfusable => '辨析';

  @override
  String get vocabMine => '我的';

  @override
  String get vocabMissedThis => '你在题里错过这个词';

  @override
  String get vocabThinkFirst => '先自己想一遍，再点开对答案';

  @override
  String get vocabMeaning => '意思';

  @override
  String get vocabUsage => '怎么用';

  @override
  String get vocabDontConfuse => '别混了';

  @override
  String get vocabTapToFlip => '点一下翻开';

  @override
  String get vocabForgot => '没记住';

  @override
  String get vocabGotIt => '记住了';

  @override
  String get vocabFlip => '翻开';

  @override
  String get vocabNoneToday => '今天没有要背的词';

  @override
  String get vocabDoneToday => '今天的词过完了';

  @override
  String get vocabAutoCollect => '做错的逻辑填空会自动把词收进来';

  @override
  String vocabResult(int right, int total) {
    return '记住 $right / $total · 没记住的明天还会出现';
  }

  @override
  String get vocabAgain => '再来一轮';

  @override
  String get vocabSearchHint => '查一个词，比如「一以贯之」';

  @override
  String get vocabNoFreq => '这版题库还没带词频';

  @override
  String get vocabNeverAsked => '没有考过这个词';

  @override
  String get vocabNoFreqHint => '词频是从逻辑填空的选项统计出来的，重装一次 App 就有了。';

  @override
  String get vocabNeverAskedHint => '换个说法试试，或者它确实没在真题里出现过。';

  @override
  String vocabAskedTimes(int count) {
    return '考过 $count 次';
  }

  @override
  String vocabAskedTimesLong(int count) {
    return '真题里考过 $count 次';
  }

  @override
  String get vocabAlreadyAdded => '已在我的词表里';

  @override
  String get vocabAdd => '加进我的词表';

  @override
  String get vocabQuestionsWith => '考过这个词的题';

  @override
  String get vocabNoSource => '这一版题库里没找到原题。';

  @override
  String vocabSourceLine(String title, String answer) {
    return '$title · 正确答案 $answer';
  }

  @override
  String get vocabNoConfusable => '还没有易混词';

  @override
  String get vocabNoConfusableHint => '内置词表里标了易混词的条目会出现在这里。';

  @override
  String vocabConfusableWith(String words) {
    return '易混：$words';
  }

  @override
  String get vocabEmpty => '词表还是空的';

  @override
  String get vocabEmptyHint => '逻辑填空做错的题，那对词会自动收进来；也可以在「高频」里手动加。';

  @override
  String get vocabFromMistakes => '做错收的';

  @override
  String get scanNeedAi => '先配一个 AI';

  @override
  String get scanNeedAiBody => '识别试卷要调模型。填一个 key 就行，题目和图片只发给你自己配的那家。';

  @override
  String get scanGoSettings => '去设置';

  @override
  String get scanNoPages => '这个文件里没有可识别的页面';

  @override
  String scanCantOpen(String error) {
    return '打不开这个文件：$error';
  }

  @override
  String get scanReading => '识别中';

  @override
  String get scanReview => '过一遍';

  @override
  String get scanPickPdf => '选一个 PDF';

  @override
  String get scanPickPdfHint => '整本试卷，逐页识别';

  @override
  String get scanPickImages => '选图片';

  @override
  String get scanPickImagesHint => '拍的照片或截图，可以多选';

  @override
  String get scanPrivacyNote => '识别用的是你自己配的那家模型，一页一次调用。\\n题目和图片不经过我们的服务器。';

  @override
  String scanPageProgress(int done, int total) {
    return '$done / $total 页';
  }

  @override
  String scanPageNo(int n) {
    return '第 $n 页';
  }

  @override
  String get scanWaiting => '等着';

  @override
  String get scanNoWholeQuestion => '没有完整题目';

  @override
  String get commonRetry => '重试';

  @override
  String scanMissingAnswers(int count) {
    return '$count 题没认出答案，已排在最前';
  }

  @override
  String scanFailedPages(int count) {
    return '$count 页识别失败';
  }

  @override
  String get scanType => '题型';

  @override
  String scanTypeSummary(int types, int unknown) {
    return '识别出 $types 类，$unknown 题没认出';
  }

  @override
  String get scanTypeHint => '已逐题识别，不对可以整批改';

  @override
  String get scanAsDetected => '按识别结果';

  @override
  String get scanViewPage => '看页面';

  @override
  String get scanNothingSelected => '没有选中的题';

  @override
  String scanImportSelected(int count) {
    return '导入 $count 题';
  }

  @override
  String get scanNoAnswer => '没认出答案';

  @override
  String scanAnswerIs(String answer) {
    return '答案 $answer';
  }

  @override
  String get scanUnclassified => '未判定';

  @override
  String scanOptionCount(int count) {
    return '$count 个选项';
  }

  @override
  String get scanHasMaterial => '带材料';

  @override
  String get scanHasImage => '带图';

  @override
  String docFoundCount(int count) {
    return '$count 道';
  }

  @override
  String docNoAnswerCount(int count) {
    return ' · $count 道没答案';
  }

  @override
  String get docNeedAiKey => '先去「我的 → AI 设置」配一个 key，解析要用它';

  @override
  String get docOpening => '正在打开文件…';

  @override
  String get docNoText => '这个文件里没读到文字。扫描件请走「拍照 / PDF」那条路。';

  @override
  String get docImportTitle => '文档导入';

  @override
  String get docImportBody =>
      'Word、Excel、CSV、纯文本都行。AI 读一遍，认出题干、选项、答案和解析 —— 什么考试都可以，不限于行测。';

  @override
  String get docWhichExam => '这是什么考试的（可选）';

  @override
  String get docWhichExamHint => '例如 教师资格证 · 科目二';

  @override
  String get docWhichExamNote => '填了能帮 AI 分类分得准一些';

  @override
  String get docPickFile => '选择文件';

  @override
  String get docPickAnother => '换一个文件';

  @override
  String get docFound => '认出来的题';

  @override
  String get docNoAnswerHint =>
      '没答案的题做不了，多半是原文档把答案单独列在别处。存进去之后可以自己补，或者换一份带答案的资料。';

  @override
  String docMoreHidden(int count) {
    return '还有 $count 道，存进去就能看到';
  }

  @override
  String docSaveCount(int count) {
    return '存入题库 $count 道';
  }

  @override
  String get docNoAnswer => '没有答案';

  @override
  String get docHasAnalysis => '带解析';

  @override
  String get essayNeedAi => '先配置 AI';

  @override
  String get essayNeedAiBody => '拍照识题要用到 AI，去填一下 API Key？';

  @override
  String get commonLater => '以后再说';

  @override
  String get essayScanFailed => '识别失败';

  @override
  String get essayScanDone => '识别完成，检查一下材料有没有缺段';

  @override
  String get essayNeedFields => '标题、给定材料、作答要求都得填，AI 才批得准';

  @override
  String get essayNewTitle => '录入申论题';

  @override
  String get essayEditTitle => '编辑题目';

  @override
  String get commonSaving => '保存中…';

  @override
  String get essayScanning => '识别中，长材料要等十几秒…';

  @override
  String get essayScanHint => '拍照 / 选图，让 AI 认题';

  @override
  String get essayScanCheck => '认完记得核对材料有没有缺段 —— 材料缺一块，批改就会漏一片。';

  @override
  String get essayType => '题型';

  @override
  String get essayTitleField => '标题';

  @override
  String get essayProvince => '省份';

  @override
  String get essayYear => '年份';

  @override
  String get essayWordLimit => '字数上限';

  @override
  String get essaySuggestedMinutes => '建议用时（分钟）';

  @override
  String get essaySource => '给定材料';

  @override
  String get essayTask => '作答要求';

  @override
  String get essayReference => '参考答案与采分点（可选，填了批改更准）';

  @override
  String get essayModelAnswer => '参考答案';

  @override
  String get essayModelAnswerHint => '有官方答案就贴上';

  @override
  String get essayMarkPoints => '采分点，一行一个';

  @override
  String get essayTitleHint => '2025 国考副省级 第一题';

  @override
  String get essaySourceHint => '材料1……\\n材料2……';

  @override
  String get essayTaskHint => '根据给定资料，概括……要求：全面、准确、有条理，不超过 200 字。';

  @override
  String get essayMarkPointsHint => '基层治理成本高\\n群众参与度低\\n数字化手段缺位';

  @override
  String importMissingImages(int count) {
    return '有 $count 张图片在压缩包里找不到，这些题会显示\"图片缺失\"';
  }

  @override
  String get importedPaperTitle => '用户导入';

  @override
  String paperYearPrefix(String year) {
    return '$year 年 · ';
  }

  @override
  String paperDoneSuffix(int done, int rate) {
    return ' · 已练 $done · 正确率 $rate%';
  }

  @override
  String get paperNoQuestions => '这里没有题目';

  @override
  String paperSkim(String title) {
    return '速览 · $title';
  }

  @override
  String get paperHistory => '本卷历史';

  @override
  String get paperHistoryShort => '历史';

  @override
  String get paperFullMock => '整卷模考';

  @override
  String get paperMockMinutes => '120 分钟';

  @override
  String get paperResume => '继续未做';

  @override
  String get paperAllDone => '已做完';

  @override
  String get paperWrong => '本卷错题';

  @override
  String get commonNone => '暂无';

  @override
  String get paperSkimAnswers => '速览答案';

  @override
  String get paperAllAnalysis => '整卷解析';

  @override
  String get paperModules => '模块构成';

  @override
  String get paperModulesHint => '点一行只练这块';

  @override
  String paperModuleYear(String name, String year) {
    return '$name · $year 年';
  }

  @override
  String get paperNoTypes => '这套卷子还没有题目 —— 导入时缺少题型标注会这样';

  @override
  String get paperTipModules => '建议先按模块练，熟悉题型后再整卷限时。';

  @override
  String get paperTipMock => '整卷模考按 120 分钟计时，中途可用答题卡跳题。';

  @override
  String get healthCleanAll => '清理全部重复';

  @override
  String healthCleanAllBody(int groups, int removed) {
    return '$groups 组卷内重复，每组留一道，共删掉 $removed 道。';
  }

  @override
  String get healthClean => '清理';

  @override
  String get healthTitle => '题库体检';

  @override
  String get healthAllGood => '没查出问题';

  @override
  String get healthEmptyBody => '导入题目之后，这里会告诉你哪些题有毛病。';

  @override
  String get healthAllGoodBody => '每道题都有答案、有选项，卷内也没有收重。';

  @override
  String get healthNoAnswer => '没有答案';

  @override
  String healthNoAnswerCount(int count) {
    return '$count 题 · 这些题做了也判不了对错';
  }

  @override
  String get healthFillAnswer => '补答案';

  @override
  String get healthBrokenOptions => '选项残缺';

  @override
  String healthBrokenCount(int count) {
    return '$count 题 · 不足两个选项，多半是解析出错';
  }

  @override
  String get healthDupes => '重复的题';

  @override
  String healthDupesCount(int count) {
    return '$count 组 · 同一份卷里收了两遍';
  }

  @override
  String get healthCleanAllShort => '全部清理';

  @override
  String healthCopies(int count) {
    return '$count 份';
  }

  @override
  String get healthKeepOne => '只留一道';

  @override
  String get healthByCategory => '各科多少题';

  @override
  String get healthUnitQuestions => '道题';

  @override
  String get healthUnitCategories => '个科目';

  @override
  String get healthUnitProblems => '处待修';

  @override
  String healthMore(int count) {
    return '还有 $count 处，修完这批再刷新';
  }

  @override
  String get healthEmptyStem => '（空题干）';

  @override
  String get healthDelete => '删掉';

  @override
  String get healthWhichAnswer => '正确答案是哪个';

  @override
  String get healthWhichAnswerHint => '选错了也不要紧，之后在做题页还能改。';

  @override
  String get bankAllShort => '全部';

  @override
  String reportsTodayAt(String time) {
    return '今天 $time';
  }

  @override
  String reportsMinSec(int m, int s) {
    return '$m 分 $s 秒';
  }

  @override
  String reportsSec(int s) {
    return '$s 秒';
  }

  @override
  String reportsResume(String when, int n) {
    return '$when · 停在第 $n 题 · 点开接着做';
  }

  @override
  String reportsScoreLine(
    String when,
    int correct,
    int total,
    String duration,
  ) {
    return '$when · 答对 $correct/$total · $duration';
  }

  @override
  String reportsPlainLine(String when, String duration) {
    return '$when · $duration';
  }

  @override
  String get reportsEssayHint => '申论记录去申论页看批改';

  @override
  String get reportsVocabHint => '背词记录没有题目可以逐题回顾';

  @override
  String get reportsNeedTwo => '至少要有两份报告才能对比';

  @override
  String get reportsTitle => '练习历史';

  @override
  String get reportsNone => '还没有成绩报告';

  @override
  String get reportsNoneHint => '练习、模考、背词都会记在这里。';

  @override
  String get reportsKindVocab => '背词';

  @override
  String get reportsUnfinished => '未做完';

  @override
  String reportsSeeWrong(int count) {
    return '看这 $count 道错题';
  }

  @override
  String get reportsDiagnose => '诊断这份卷子';

  @override
  String get reportsCompareWith => '和哪一次比';

  @override
  String get reportsCompare => '两次对比';

  @override
  String get reportsLevel => '持平';

  @override
  String get reportsCompareNote => '题目不同，比的是各模块的正确率，不是同一批题。';

  @override
  String get notesReview => '笔记回顾';

  @override
  String get notesTitle => '我的笔记';

  @override
  String get notesWriteOne => '写一条';

  @override
  String get notesReviewAll => '全部回顾';

  @override
  String get notesNone => '还没有笔记';

  @override
  String get notesNoneHint => '做题时点便签图标记这道题的心得；跟具体题无关的经验，点下面写一条。';

  @override
  String get notesSearchHint => '搜笔记内容或题干';

  @override
  String get notesNoMatch => '没有匹配的笔记';

  @override
  String get notesNoMatchHint => '换个关键词，或把题型筛选清掉。';

  @override
  String get notesDelete => '删除笔记';

  @override
  String get notesQuick => '随手记';

  @override
  String get notesTitleField => '标题（可选）';

  @override
  String get notesTitleHint => '不写就取正文第一行';

  @override
  String get notesBody => '内容';

  @override
  String get notesBodyHint => '公式、坑点、这次模考的教训…';

  @override
  String get usageClear => '清空用量记录';

  @override
  String get usageClearBody => '只清掉这里的统计，不影响已经生成的讲解和导入的题。';

  @override
  String get usageClearShort => '清空';

  @override
  String get usageTitle => 'AI 用量';

  @override
  String usageLastDays(int days) {
    return '近 $days 天';
  }

  @override
  String get usageNone => '还没有用量';

  @override
  String get usageNoneHint => 'AI 讲题、导入解析、申论批改都会记在这里。';

  @override
  String get usageWhere => '花在哪';

  @override
  String get usageByTokens => 'token 从多到少';

  @override
  String get usageByModel => '按模型';

  @override
  String get usageUnrecorded => '未记录';

  @override
  String get usageTokenNote => 'token 数由模型返回，各家统计口径略有差别，这里的数字用来比较大小，跟账单可能差一点。';

  @override
  String get usageFeatureExplain => 'AI 讲题';

  @override
  String get usageFeatureDoc => '文档导入';

  @override
  String get usageFeatureScan => '拍照 / PDF 识题';

  @override
  String get usageFeatureEssay => '申论批改';

  @override
  String get usageFeatureImage => '图片识题';

  @override
  String get usageFeatureSort => '分类整理';

  @override
  String get usageFeatureOther => '其他';

  @override
  String usageCalls(int count) {
    return '$count 次调用';
  }

  @override
  String get usageLast14 => '近 14 天';

  @override
  String usageGroupLine(int calls, String inTok, String outTok) {
    return '$calls 次 · 进 $inTok · 出 $outTok';
  }

  @override
  String get explainTitle => '出题人视角';

  @override
  String get explainRedo => '重讲';

  @override
  String get explainWorking => '正在看这道题';

  @override
  String get explainPitch => '让 AI 从出题人的角度讲一遍：这题考什么、干扰项怎么设的、你错在哪。';

  @override
  String get explainAsk => 'AI 讲这道题';

  @override
  String get explainBackground => '可以先去做别的，回来接着看';

  @override
  String explainStamp(String stamp) {
    return 'AI 生成 · $stamp';
  }

  @override
  String searchFoundCount(int count) {
    return '找到 $count 题';
  }

  @override
  String get searchFilteredSuffix => ' · 已按题型筛选';

  @override
  String searchYearSuffix(String year) {
    return ' · $year 年';
  }

  @override
  String get searchHasFigure => ' · 含图';

  @override
  String get searchTitle => '搜题';

  @override
  String get searchPractiseThese => '练这些';

  @override
  String get searchHint => '搜题干、解析关键词';

  @override
  String searchAllCount(int count) {
    return '全部 $count';
  }

  @override
  String get searchTop60 => '只显示前 60 条';

  @override
  String get searchNoMatch => '没有匹配的题目';

  @override
  String get searchShorterHint => '换个更短的关键词试试。';

  @override
  String get searchRecent => '最近搜索';

  @override
  String get searchTryThese => '试试这些';

  @override
  String get searchNote => '搜索会扫描全库题目的题干与解析，命中的关键词会在结果里高亮。';

  @override
  String get toolVocabCompare => '词语辨析';

  @override
  String get toolVocabCompareHint => '一蹴而就 / 一挥而就，摆一起才分得清';

  @override
  String get toolVocabTop => '高频词语';

  @override
  String get toolVocabTopHint => '从 2077 道逻辑填空的选项统计出来的';

  @override
  String get toolVocabToday => '今日词卡';

  @override
  String get toolVocabTodayHint => '按间隔重复排的，今天该背哪些';

  @override
  String get toolVocabMine => '生词锦囊';

  @override
  String get toolVocabMineHint => '做错的词自动收进来，也能自己加';

  @override
  String get toolVocabLookup => '词语查询';

  @override
  String get toolVocabLookupHint => '四千词表，看真题里怎么用';

  @override
  String get toolTips => '行测助手';

  @override
  String get toolTipsHint => '各模块解题思路速查，卡住时翻';

  @override
  String get toolCheckin => '每日打卡';

  @override
  String get toolCheckinHint => '今天的安排，勾完算数';

  @override
  String get toolSearch => '题库搜索';

  @override
  String get toolSearchHint => '一万六千道题，按关键词找';

  @override
  String get toolsTitle => '工具';

  @override
  String get searchNoResults => '没找到相关题目';

  @override
  String importedCount(int count) {
    return '成功导入 $count 题';
  }

  @override
  String importedImages(int count) {
    return '、$count 张图';
  }

  @override
  String importedOverwritten(int count) {
    return '（其中 $count 题为覆盖更新）';
  }

  @override
  String get importedNothing => '这次没有导入题目';

  @override
  String get importFormatTitle => '题目文件长什么样';

  @override
  String get importParsed => '解析结果';

  @override
  String get importQuestions => '题目';

  @override
  String get importImages => '图片';

  @override
  String get importOverwrites => '覆盖已有';

  @override
  String get importConfirm => '确认导入';

  @override
  String get aiSaved => '已保存';

  @override
  String aiCantOpenBrowser(String url) {
    return '打不开浏览器，网址已复制：$url';
  }

  @override
  String get aiPickProvider => '选一家';

  @override
  String get aiEnterKey => '填 Key';

  @override
  String aiGetKeyAt(String where) {
    return '去 $where 领一个';
  }

  @override
  String get aiWhichModel => '用哪个模型';

  @override
  String get aiModelHint => '模型名，问服务商要';

  @override
  String get aiBaseUrl => '接口地址';

  @override
  String aiBaseUrlSet(String url) {
    return '接口地址已配好：$url';
  }

  @override
  String get aiTesting => '测试中…';

  @override
  String get aiTest => '测试连接';

  @override
  String get aiKeyPrivacy => 'Key 只存在这台手机上。请求直接发给你选的那家服务商，不经过我们任何服务器。';

  @override
  String get aiPaste => '粘贴';

  @override
  String get aiHide => '隐藏';

  @override
  String get aiShow => '显示';

  @override
  String get aiFree => '免费';

  @override
  String get essayDeletePrompt => '删除这道题？';

  @override
  String essayDeleteBody(String title) {
    return '「$title」连同它的作答记录会一起删掉。';
  }

  @override
  String get essayAddPrompt => '录入题目';

  @override
  String get essayNoneOfType => '这个题型还没有题';

  @override
  String get essayNone => '还没有申论题';

  @override
  String get essayNoneOfTypeHint => '换个题型看看，或者录一道新的。';

  @override
  String get essayNoneHint => '内置题库全是行测客观题，申论得自己录。\\n拍张照让 AI 认，或者直接粘贴材料和题干。';

  @override
  String get essayAddFirst => '录入第一道';

  @override
  String get essayQuit => '退出作答？';

  @override
  String get essayQuitBody => '还没交卷，写的内容会丢掉。';

  @override
  String get essayKeepWriting => '继续写';

  @override
  String get essayTooShort => '至少写够 20 字再交，不然批不出东西';

  @override
  String get essayNeedAiMark => '批改要用到 AI，去填一下 API Key？答案会先存下来，不会丢。';

  @override
  String get essayMarkFailed => '批改失败';

  @override
  String get essayWriteHint => '在这里作答。归纳概括先分条，再把每条的核心词提到句首。';

  @override
  String get essayMarking => 'AI 批改中，约 20 秒…';

  @override
  String get essaySubmitMark => '交卷批改';

  @override
  String get essayAttempts => '作答记录';

  @override
  String get essayNotMarked => '这次没批改成功，答案已经存下来了。';

  @override
  String get essayResult => '批改结果';

  @override
  String get essayPointsCovered => '要点覆盖';

  @override
  String get essayWordCount => '字数';

  @override
  String get essayTimeTaken => '用时';

  @override
  String get essayBreakdown => '分项得分';

  @override
  String get essayPointByPoint => '采分点逐条对照';

  @override
  String essayMissedPoints(int count) {
    return '漏 $count 点';
  }

  @override
  String get essayNextTime => '下次注意';

  @override
  String get essayYourAnswer => '你的答案';

  @override
  String essayEvidence(String text) {
    return '出处：$text';
  }

  @override
  String essayWords(int n) {
    return '$n 字';
  }

  @override
  String essayWordsOfLimit(int n, int limit) {
    return '$n / $limit 字';
  }

  @override
  String get essayOverLimit => ' · 超了';

  @override
  String essayOutOf(String max) {
    return '满分 $max';
  }

  @override
  String planDoneToday(String name) {
    return '「$name」今天已完成';
  }

  @override
  String planDayPending(String name, int day) {
    return '「$name」第 $day 天还没做';
  }

  @override
  String get tabPractice => '练习';

  @override
  String get tabPlan => '计划';

  @override
  String get navExpand => '展开导航';

  @override
  String get navCollapse => '收起导航';

  @override
  String shoreStreak(int days) {
    return '灯塔亮了 $days 天';
  }

  @override
  String backupExportedTo(String name) {
    return '已导出到 $name';
  }

  @override
  String get backupRestore => '恢复备份';

  @override
  String get backupRestoreBody =>
      '恢复会用备份中的答题记录与成绩报告覆盖当前数据，收藏、笔记、错因会合并，学习计划和考试日期按备份里的写回。题库本身不受影响。';

  @override
  String get backupPickFile => '选择文件恢复';

  @override
  String get backupUnreadable => '读不到这个文件';

  @override
  String get backupNotOurs => '这不是 OpenExam 的备份文件';

  @override
  String backupRestored(int count) {
    return '已恢复 $count 条记录';
  }

  @override
  String backupRestoreFailed(String error) {
    return '恢复失败：$error';
  }

  @override
  String get backupIntro => '这个 App 没有账号，数据只在本机。换手机或清除数据前，导出一份备份就能完整带走。';

  @override
  String get backupAnswers => '答题记录';

  @override
  String get backupReports => '成绩报告';

  @override
  String get backupExport => '导出备份';

  @override
  String get backupExportHint => '生成一个 JSON 文件，含答题记录、成绩报告、收藏、笔记与错因';

  @override
  String get backupFromFile => '从备份恢复';

  @override
  String get backupFromFileHint => '答题记录与成绩报告会被覆盖，收藏、笔记、错因合并保留';

  @override
  String get backupSizeNote => '备份文件不含题库（题目已随 App 内置），所以体积很小，可以直接发到微信或存进网盘。';

  @override
  String get aiNotConfigured => '还没配置 AI，去「我的 → AI 设置」里填一下';

  @override
  String aiNoVision(String provider) {
    return '$provider 不支持图片识别，换个支持视觉的模型';
  }

  @override
  String get aiUnparsable => '模型没有返回可解析的结果，再试一次';

  @override
  String get aiNoKey => '还没填 API Key';

  @override
  String get aiNoBaseUrl => '还没填接口地址';

  @override
  String aiConnOk(String model) {
    return '连接正常 · $model';
  }

  @override
  String get aiTimeout => '请求超时了，检查一下网络或换个接口地址';

  @override
  String aiRequestFailed(String error) {
    return '请求失败：$error';
  }

  @override
  String get aiNoContent =>
      '模型没吐出正文。多半是这个模型要先\"想\"一轮，配额被想的部分吃完了 —— 换成非推理模型，或者稍后再试。';

  @override
  String aiBadKey(int status, String detail) {
    return 'API Key 不对或没权限（$status）：$detail';
  }

  @override
  String aiNotFound(String detail) {
    return '接口地址或模型名不对（404）：$detail';
  }

  @override
  String aiRateLimited(String detail) {
    return '请求太频繁或余额不足（429）：$detail';
  }

  @override
  String aiServerError(int status, String detail) {
    return '服务返回 $status：$detail';
  }

  @override
  String get tipsTitle => '解题技巧';

  @override
  String get tipsUnitQuestions => '道题';

  @override
  String get tipsPaperNumbers => '卷面题号';

  @override
  String get tipsUnitMinutes => '分钟';

  @override
  String get tipsWhereOnPaper => '卷面位置';

  @override
  String get tipsYear2026 => '2026 年';

  @override
  String tipsQuestionRange(int from, int to) {
    return '第 $from–$to 题';
  }

  @override
  String tipsTotalAndMinutes(int count, int minutes) {
    return '$count 题 · $minutes 分钟';
  }

  @override
  String get tipsBreakdownPace => '内部结构 · 单题配速';

  @override
  String get tipsBreakdown => '内部结构';

  @override
  String get tipsHotspots => '高频考点';

  @override
  String get tipsHotspotsHint => '按出现频次排序';

  @override
  String get tipsHotspotsNote => '关键词粗分，一题可能算进多个考点 —— 看相对权重就行，别当精确占比。';

  @override
  String get tipsInExam => '考场怎么做';

  @override
  String get tipsMethods => '方法';

  @override
  String tipsMethodCount(int count) {
    return '$count 条';
  }

  @override
  String get examNewProfile => '新建备考目标';

  @override
  String get examNewProfileHint => '例如 执业医师 · 临床';

  @override
  String get examRename => '改名';

  @override
  String get examDeleteProfile => '删除备考目标';

  @override
  String examDeleteProfileBody(String name) {
    return '删掉「$name」。题库、错题、记录都不受影响。';
  }

  @override
  String get examWhichModules => '显示哪些模块';

  @override
  String get examWhichExam => '在备考哪一门';

  @override
  String get examModulesNote => '这几个模块是给考公做的。备别的考试用不上，关掉就不会再出现。';

  @override
  String get examGenericOnly => '只有通用模块';

  @override
  String examExtrasOn(int count) {
    return '开了 $count 个专属模块';
  }

  @override
  String get examSharedBank => '题库是共用的。换一份只是换一副眼镜 —— 题、错题本、练习记录都还在，不会因为切换丢东西。';

  @override
  String get examTwoProfiles => '同时备两门考试的话，右上角 ＋ 建第二份，各留各的模块。';

  @override
  String sessionHistoryPicked(String when, String answer) {
    return '$when做过，当时选了 $answer';
  }

  @override
  String get sessionHistoryRight => '（对）';

  @override
  String get sessionHistoryWrong => '（错）';

  @override
  String sessionHistoryMissedN(int count) {
    return ' · 一共错过 $count 次';
  }

  @override
  String sessionHistoryWasRight(String when) {
    return '$when做过，当时做对了';
  }

  @override
  String sessionHistoryWasWrong(String when) {
    return '$when做错过这道题';
  }

  @override
  String sessionAvgSeconds(String secs) {
    return '每题 $secs 秒';
  }

  @override
  String sessionYourAnswer(String yours, String right) {
    return '你的答案 $yours · 正确答案 $right';
  }

  @override
  String get sessionBlankAnswer => '未作答';

  @override
  String sessionDoneTimes(int count) {
    return '$count 次做过';
  }

  @override
  String sessionMissedN(int count) {
    return ' · 错过 $count 次';
  }

  @override
  String get sessionAllRight => ' · 全对';

  @override
  String sessionLastOn(String date) {
    return ' · 上次 $date';
  }

  @override
  String get sessionNoteExample => '例如：看到\"至少\"先想最不利原则';

  @override
  String sessionYearSuffix(String year) {
    return ' · $year 年';
  }

  @override
  String minutesCount(int count) {
    return '$count 分钟';
  }

  @override
  String get featEssay => '申论 / 主观题';

  @override
  String get featEssayHint => '写作 + AI 批改';

  @override
  String get featVocab => '词语';

  @override
  String get featVocabHint => '词卡、辨析、生词本';

  @override
  String get featTips => '技巧速查';

  @override
  String get featTipsHint => '各模块解题方法';

  @override
  String get featProvinces => '报考地区';

  @override
  String get featProvincesHint => '按省份筛选卷子';

  @override
  String get examMyProfile => '我的备考';

  @override
  String get yearAll => '不限年份';

  @override
  String get yearLast1 => '最近一年';

  @override
  String get yearLast3 => '最近三年';

  @override
  String get planStep1 => '放慢做对';

  @override
  String get planStep2 => '再来一遍';

  @override
  String get planStep3 => '限时加压';

  @override
  String get planStep4 => '混练验证';

  @override
  String get planStep1Hint => '不计时，把每道题的正确思路走一遍';

  @override
  String get planStep2Hint => '还是不计时，重点看昨天卡住的地方';

  @override
  String get planStep3Hint => '按考场配速做，逼自己在时间内定下来';

  @override
  String get planStep4Hint => '掺进同类新题一起做，验证是不是真会了';

  @override
  String get memoUntitled => '无标题';

  @override
  String get examGongkaoName => '公务员 · 行测申论';

  @override
  String get marksTitle => '我的收藏';

  @override
  String get marksPractise => '练一组';

  @override
  String get marksNone => '还没有收藏';

  @override
  String get marksNoneHint => '做题时点右上角的星标，题目会收进这里。';

  @override
  String get marksUnsave => '取消收藏';

  @override
  String get marksAddTag => '+ 标签';

  @override
  String get marksTags => '收藏标签';

  @override
  String get marksClearTag => '清除标签';

  @override
  String get onboardThreeThings => '还有三件事';

  @override
  String get onboardChangeLater => '随时能改，都在「我的」里';

  @override
  String get onboardDailyGoal => '一天划几题';

  @override
  String get onboardWhere => '考哪儿';

  @override
  String get onboardWhereHint => '选了之后题库优先推你要考的那套卷';

  @override
  String get onboardWhen => '考试哪天';

  @override
  String get onboardOptional => '不填也行';

  @override
  String onboardDaysLeft(int days) {
    return ' · 还有 $days 天';
  }

  @override
  String get recentTitle => '最近做过';

  @override
  String get recentHistory => '练习历史';

  @override
  String get recentNone => '还没做过整卷';

  @override
  String get recentNoneHint => '在题库里挑一张卷开始，之后这里会记着做到哪了。';

  @override
  String recentFinished(int count) {
    return '已做完 $count 题';
  }

  @override
  String recentProgress(int done, int total) {
    return '做到 $done / $total 题';
  }

  @override
  String get timelineTitle => '练习记录';

  @override
  String get timelineNoneHint => '刷完第一组题，这里会按天记下你练了什么。';

  @override
  String timelineDayLine(int count, int rate) {
    return '$count 题 · 正确率 $rate%';
  }

  @override
  String get timelineMetGoal => '达标';

  @override
  String get feedbackReview => '纠错回看';

  @override
  String get feedbackTitle => '纠错记录';

  @override
  String get feedbackNone => '还没有纠错记录';

  @override
  String get feedbackNoneHint => '做题时长按顶部的题号，可以标记答案有误、解析看不懂等问题。';

  @override
  String get feedbackIssue => '问题';

  @override
  String get feedbackNote => '这些记录只存在本机，会随备份一起导出。左滑删除。';

  @override
  String get padThin => '细';

  @override
  String get padMedium => '中';

  @override
  String get padThick => '粗';

  @override
  String get padScratch => '草稿纸';

  @override
  String get padCalculator => '计算器';

  @override
  String get padHere => '在这里算';

  @override
  String get padCantCompute => '算不了';

  @override
  String homeMockMeta(int count, int minutes) {
    return '$count 题 · $minutes 分钟';
  }

  @override
  String shoreLeftToday(int count) {
    return '今天还要划 $count 题';
  }

  @override
  String get shoreNotStarted => '未开航';

  @override
  String essayUnderWords(int n) {
    return '$n 字内';
  }

  @override
  String essayAttemptedTimes(int count) {
    return '练过 $count 次';
  }

  @override
  String get essayNeverAttempted => '没做过';

  @override
  String get imageMissing => '图片缺失';

  @override
  String get imagePinchHint => '双指缩放 · 点击关闭';

  @override
  String get filterClear => '清除';

  @override
  String get filterSearch => '搜一下';

  @override
  String get docNoContent => '这个文件里没读到内容';

  @override
  String get docLookingAtTable => '在看这张表怎么排的…';

  @override
  String get docUnknownColumns => '没认出这张表的列，换个文件试试';

  @override
  String docFoundQuestions(int count) {
    return '已认出 $count 道题';
  }

  @override
  String get docNoneInTable => '这张表里没找到题';

  @override
  String docChunk(int n, int total) {
    return '第 $n/$total 段';
  }

  @override
  String get docNoWholeQuestions => '没找到成形的题';

  @override
  String get modelCheapFast => '快且便宜，日常够用';

  @override
  String get modelStrong => '难题和长文批改更稳';

  @override
  String get modelCheapVision => '便宜，能看图';

  @override
  String get modelStrongerPricier => '更强，贵一些';

  @override
  String get modelBestWriting => '写作和批改最稳';

  @override
  String get modelFast => '快';

  @override
  String get modelGeneral => '通用';

  @override
  String get modelShortText => '短文本';

  @override
  String get modelLongText => '长材料';

  @override
  String get modelVision => '能看图';

  @override
  String get modelFreeTier => '免费额度内可用';

  @override
  String get modelStronger => '更强';

  @override
  String get providerCustom => '自定义';

  @override
  String get providerCustomHint => '任何 OpenAI 兼容接口，地址要带上 /v1';

  @override
  String get dxAiNotConfiguredShort => '还没配 AI。上面的结论不用配也能看，AI 只是多一层解读。';

  @override
  String get aiEmptyReply => '模型没给出内容，再试一次';

  @override
  String get modelNote_cheapFast => '快且便宜，日常够用';

  @override
  String get modelNote_strong => '难题和长文批改更稳';

  @override
  String get modelNote_cheapVision => '便宜，能看图';

  @override
  String get modelNote_strongerPricier => '更强，贵一些';

  @override
  String get modelNote_bestWriting => '写作和批改最稳';

  @override
  String get modelNote_fast => '快';

  @override
  String get modelNote_general => '通用';

  @override
  String get modelNote_shortText => '短文本';

  @override
  String get modelNote_longText => '长材料';

  @override
  String get modelNote_vision => '能看图';

  @override
  String get modelNote_freeTier => '免费额度内可用';

  @override
  String get modelNote_stronger => '更强';
}
