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
}
