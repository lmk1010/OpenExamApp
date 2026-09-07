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
}
