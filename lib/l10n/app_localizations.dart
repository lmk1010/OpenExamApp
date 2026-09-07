import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppL
/// returned by `AppL.of(context)`.
///
/// Applications need to include `AppL.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppL.localizationsDelegates,
///   supportedLocales: AppL.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppL.supportedLocales
/// property.
abstract class AppL {
  AppL(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppL of(BuildContext context) {
    return Localizations.of<AppL>(context, AppL)!;
  }

  static const LocalizationsDelegate<AppL> delegate = _AppLDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// App 名字，不翻译
  ///
  /// In zh, this message translates to:
  /// **'OpenExam'**
  String get appName;

  /// 引导第一屏标题。中文是双关（划船/刷题），英文不必强译
  ///
  /// In zh, this message translates to:
  /// **'上岸\n是划出来的'**
  String get onboardTitle;

  /// No description provided for @onboardBodyWithBank.
  ///
  /// In zh, this message translates to:
  /// **'{count} 道题在这台手机里\n不用登录，没网也能划'**
  String onboardBodyWithBank(int count);

  /// No description provided for @onboardBodyNoBank.
  ///
  /// In zh, this message translates to:
  /// **'题库和 App 是分开的\n导入一份就能开始，不用登录、没网也能划'**
  String get onboardBodyNoBank;

  /// No description provided for @onboardBodyLoading.
  ///
  /// In zh, this message translates to:
  /// **'不用登录，没网也能划'**
  String get onboardBodyLoading;

  /// No description provided for @onboardWrongTitle.
  ///
  /// In zh, this message translates to:
  /// **'错的题\n自己会记着'**
  String get onboardWrongTitle;

  /// No description provided for @onboardWrongBody.
  ///
  /// In zh, this message translates to:
  /// **'答错的进错题本，再答对就出去\n想写两句笔记、标一下错在哪，都行'**
  String get onboardWrongBody;

  /// No description provided for @onboardSkip.
  ///
  /// In zh, this message translates to:
  /// **'跳过'**
  String get onboardSkip;

  /// No description provided for @onboardStart.
  ///
  /// In zh, this message translates to:
  /// **'出发'**
  String get onboardStart;

  /// No description provided for @noBankTitle.
  ///
  /// In zh, this message translates to:
  /// **'还没有题库'**
  String get noBankTitle;

  /// No description provided for @noBankBody.
  ///
  /// In zh, this message translates to:
  /// **'这个版本不预装题目 —— 题库和 App 是分开的，装哪套题库就是练哪门考试。导入一份就能开始：做题、按卷模考、错题复盘、弱点诊断都不用联网。'**
  String get noBankBody;

  /// No description provided for @noBankImport.
  ///
  /// In zh, this message translates to:
  /// **'导入题库'**
  String get noBankImport;

  /// No description provided for @noBankHint.
  ///
  /// In zh, this message translates to:
  /// **'也可以把题库文件放进「文件」App 的 OpenExam 文件夹，或者用「扫描试卷」把纸质卷子拍成题目。'**
  String get noBankHint;

  /// No description provided for @bankTitle.
  ///
  /// In zh, this message translates to:
  /// **'题库'**
  String get bankTitle;

  /// No description provided for @bankExportTitle.
  ///
  /// In zh, this message translates to:
  /// **'导出题库'**
  String get bankExportTitle;

  /// No description provided for @bankExportBody.
  ///
  /// In zh, this message translates to:
  /// **'导出成 zip，含题目和图片。别人用「导入题库」就能装上 —— 跟导入是同一个格式。'**
  String get bankExportBody;

  /// No description provided for @bankExportWholeBank.
  ///
  /// In zh, this message translates to:
  /// **'整个题库'**
  String get bankExportWholeBank;

  /// No description provided for @bankExportWholeBankHint.
  ///
  /// In zh, this message translates to:
  /// **'{count} 题 · 文件会很大'**
  String bankExportWholeBankHint(int count);

  /// No description provided for @bankExportCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 题'**
  String bankExportCount(int count);

  /// No description provided for @bankExportEmpty.
  ///
  /// In zh, this message translates to:
  /// **'这个范围里没有题'**
  String get bankExportEmpty;

  /// No description provided for @bankExportCancelled.
  ///
  /// In zh, this message translates to:
  /// **'已取消'**
  String get bankExportCancelled;

  /// No description provided for @bankExportDone.
  ///
  /// In zh, this message translates to:
  /// **'已导出 {count} 题：{name}'**
  String bankExportDone(int count, String name);

  /// No description provided for @bankExportFailed.
  ///
  /// In zh, this message translates to:
  /// **'导出失败：{error}'**
  String bankExportFailed(String error);

  /// No description provided for @settingsLanguage.
  ///
  /// In zh, this message translates to:
  /// **'界面语言'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageSystem.
  ///
  /// In zh, this message translates to:
  /// **'跟随系统'**
  String get settingsLanguageSystem;

  /// No description provided for @settingsLanguageSystemHint.
  ///
  /// In zh, this message translates to:
  /// **'按手机的语言自动切换'**
  String get settingsLanguageSystemHint;

  /// No description provided for @onboardNext.
  ///
  /// In zh, this message translates to:
  /// **'下一个'**
  String get onboardNext;

  /// No description provided for @onboardFinish.
  ///
  /// In zh, this message translates to:
  /// **'开始划'**
  String get onboardFinish;

  /// No description provided for @importScanDone.
  ///
  /// In zh, this message translates to:
  /// **'已导入 {count} 道题'**
  String importScanDone(int count);

  /// No description provided for @importUnreadable.
  ///
  /// In zh, this message translates to:
  /// **'读不到这个文件，换一个试试'**
  String get importUnreadable;

  /// No description provided for @importNoQuestions.
  ///
  /// In zh, this message translates to:
  /// **'这个文件里没找到题目，看看下面的格式说明'**
  String get importNoQuestions;

  /// No description provided for @importFailed.
  ///
  /// In zh, this message translates to:
  /// **'导入失败：{error}'**
  String importFailed(String error);

  /// No description provided for @importWayScanTitle.
  ///
  /// In zh, this message translates to:
  /// **'拍照 / PDF'**
  String get importWayScanTitle;

  /// No description provided for @importWayScanDesc.
  ///
  /// In zh, this message translates to:
  /// **'试卷、截图、买来的 PDF，AI 逐页认成题目'**
  String get importWayScanDesc;

  /// No description provided for @importWayDocTitle.
  ///
  /// In zh, this message translates to:
  /// **'Word / Excel / 文本'**
  String get importWayDocTitle;

  /// No description provided for @importWayDocDesc.
  ///
  /// In zh, this message translates to:
  /// **'docx、xlsx、csv、txt，AI 直接读文字认成题目'**
  String get importWayDocDesc;

  /// No description provided for @importWayFileTitle.
  ///
  /// In zh, this message translates to:
  /// **'题目文件'**
  String get importWayFileTitle;

  /// No description provided for @importWayFileDesc.
  ///
  /// In zh, this message translates to:
  /// **'JSON / CSV，带图的打包成 zip'**
  String get importWayFileDesc;

  /// No description provided for @profileDefaultName.
  ///
  /// In zh, this message translates to:
  /// **'备考中'**
  String get profileDefaultName;

  /// No description provided for @profileClearTitle.
  ///
  /// In zh, this message translates to:
  /// **'清除练习记录'**
  String get profileClearTitle;

  /// No description provided for @profileClearBody.
  ///
  /// In zh, this message translates to:
  /// **'答题记录、正确率、错题本、成绩报告、错因、打卡、自评难度、复习计划和成就都会清空，回到刚装好的样子。\\n\\n收藏、笔记、词语积累和申论作答保留，题库本身也保留。此操作不可撤销 —— 想留一手就先去「备份与恢复」导出一份。'**
  String get profileClearBody;

  /// No description provided for @profileClearConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确认清除'**
  String get profileClearConfirm;

  /// No description provided for @profileClearDone.
  ///
  /// In zh, this message translates to:
  /// **'练习记录已清除'**
  String get profileClearDone;

  /// No description provided for @profileAboutTitle.
  ///
  /// In zh, this message translates to:
  /// **'关于 OpenExam · {count} 题在库'**
  String profileAboutTitle(int count);

  /// No description provided for @profileAboutBody.
  ///
  /// In zh, this message translates to:
  /// **'本地优先的刷题工具，与 OpenExam 桌面端同源。\\n\\n商业题库请自行合法导入，App 不会爬取第三方付费内容。'**
  String get profileAboutBody;

  /// No description provided for @profileReplayOnboarding.
  ///
  /// In zh, this message translates to:
  /// **'重看引导'**
  String get profileReplayOnboarding;

  /// No description provided for @profileClearHint.
  ///
  /// In zh, this message translates to:
  /// **'答题记录、错题本、成绩报告都会清空'**
  String get profileClearHint;

  /// No description provided for @profileDaysLeft.
  ///
  /// In zh, this message translates to:
  /// **'离岸 {days} 天'**
  String profileDaysLeft(int days);

  /// No description provided for @profileToday.
  ///
  /// In zh, this message translates to:
  /// **'就在今天'**
  String get profileToday;

  /// No description provided for @profileTab.
  ///
  /// In zh, this message translates to:
  /// **'我的'**
  String get profileTab;

  /// No description provided for @profileBadges.
  ///
  /// In zh, this message translates to:
  /// **'成就'**
  String get profileBadges;

  /// No description provided for @profileVocab.
  ///
  /// In zh, this message translates to:
  /// **'词语'**
  String get profileVocab;

  /// No description provided for @profileNotes.
  ///
  /// In zh, this message translates to:
  /// **'笔记'**
  String get profileNotes;

  /// No description provided for @profileMarks.
  ///
  /// In zh, this message translates to:
  /// **'收藏'**
  String get profileMarks;

  /// No description provided for @profileReports.
  ///
  /// In zh, this message translates to:
  /// **'记录'**
  String get profileReports;

  /// No description provided for @profileStats.
  ///
  /// In zh, this message translates to:
  /// **'统计'**
  String get profileStats;

  /// No description provided for @profileTips.
  ///
  /// In zh, this message translates to:
  /// **'技巧'**
  String get profileTips;

  /// No description provided for @profileFeedback.
  ///
  /// In zh, this message translates to:
  /// **'纠错'**
  String get profileFeedback;

  /// No description provided for @profileSectionExam.
  ///
  /// In zh, this message translates to:
  /// **'备考'**
  String get profileSectionExam;

  /// No description provided for @profileFeatures.
  ///
  /// In zh, this message translates to:
  /// **'界面模块'**
  String get profileFeatures;

  /// No description provided for @profileFeaturesOn.
  ///
  /// In zh, this message translates to:
  /// **'{count} 项开启'**
  String profileFeaturesOn(int count);

  /// No description provided for @profilePlan.
  ///
  /// In zh, this message translates to:
  /// **'复习计划'**
  String get profilePlan;

  /// No description provided for @profilePrefs.
  ///
  /// In zh, this message translates to:
  /// **'练习偏好'**
  String get profilePrefs;

  /// No description provided for @profileDailyGoalValue.
  ///
  /// In zh, this message translates to:
  /// **'每日 {count} 题'**
  String profileDailyGoalValue(int count);

  /// No description provided for @profileSectionBank.
  ///
  /// In zh, this message translates to:
  /// **'题库'**
  String get profileSectionBank;

  /// No description provided for @profileImport.
  ///
  /// In zh, this message translates to:
  /// **'导入题目'**
  String get profileImport;

  /// No description provided for @profileImportedCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 题'**
  String profileImportedCount(int count);

  /// No description provided for @profileBankManage.
  ///
  /// In zh, this message translates to:
  /// **'题库管理'**
  String get profileBankManage;

  /// No description provided for @profileBankHealth.
  ///
  /// In zh, this message translates to:
  /// **'题库体检'**
  String get profileBankHealth;

  /// No description provided for @profileBackup.
  ///
  /// In zh, this message translates to:
  /// **'备份与恢复'**
  String get profileBackup;

  /// No description provided for @profileSectionApp.
  ///
  /// In zh, this message translates to:
  /// **'应用'**
  String get profileSectionApp;

  /// No description provided for @profileAiSettings.
  ///
  /// In zh, this message translates to:
  /// **'AI 设置'**
  String get profileAiSettings;

  /// No description provided for @profileConfigured.
  ///
  /// In zh, this message translates to:
  /// **'已配置'**
  String get profileConfigured;

  /// No description provided for @profileAiUsage.
  ///
  /// In zh, this message translates to:
  /// **'AI 用量'**
  String get profileAiUsage;

  /// No description provided for @profilePrivacy.
  ///
  /// In zh, this message translates to:
  /// **'数据与隐私'**
  String get profilePrivacy;

  /// No description provided for @profilePrivacyBody.
  ///
  /// In zh, this message translates to:
  /// **'题库、答题记录、统计与错题本都存在本机的 SQLite 数据库里，不上传服务器、不做任何埋点、没有账号体系。\\n\\n唯一会联网的是 AI 功能（申论批改、拍照识题）：只有你主动触发时才发请求，直接发往你自己填的服务商，API Key 存在本机。不配置就完全离线。'**
  String get profilePrivacyBody;

  /// No description provided for @profileAbout.
  ///
  /// In zh, this message translates to:
  /// **'关于'**
  String get profileAbout;

  /// No description provided for @profileNoStatsYet.
  ///
  /// In zh, this message translates to:
  /// **'还没开始记，划一组就有数了'**
  String get profileNoStatsYet;

  /// No description provided for @profileStatsLine.
  ///
  /// In zh, this message translates to:
  /// **'正确率 {rate}% · 本周 {count} 题'**
  String profileStatsLine(int rate, int count);

  /// No description provided for @profileThemeAuto.
  ///
  /// In zh, this message translates to:
  /// **'自动'**
  String get profileThemeAuto;

  /// No description provided for @profileThemeLight.
  ///
  /// In zh, this message translates to:
  /// **'浅色'**
  String get profileThemeLight;

  /// No description provided for @profileThemeDark.
  ///
  /// In zh, this message translates to:
  /// **'深色'**
  String get profileThemeDark;

  /// No description provided for @profileTheme.
  ///
  /// In zh, this message translates to:
  /// **'主题'**
  String get profileTheme;

  /// No description provided for @profileRename.
  ///
  /// In zh, this message translates to:
  /// **'改个称呼'**
  String get profileRename;

  /// No description provided for @profileRenameHint.
  ///
  /// In zh, this message translates to:
  /// **'例如：上岸倒计时'**
  String get profileRenameHint;

  /// No description provided for @commonSave.
  ///
  /// In zh, this message translates to:
  /// **'保存'**
  String get commonSave;

  /// No description provided for @profileRegion.
  ///
  /// In zh, this message translates to:
  /// **'报考地区'**
  String get profileRegion;

  /// No description provided for @profileRegionHint.
  ///
  /// In zh, this message translates to:
  /// **'用来优先推荐对应的真题卷'**
  String get profileRegionHint;

  /// No description provided for @profileDailyGoal.
  ///
  /// In zh, this message translates to:
  /// **'每日目标'**
  String get profileDailyGoal;

  /// No description provided for @profileDailyGoalHint.
  ///
  /// In zh, this message translates to:
  /// **'在职备考建议 20–30 题，全职冲刺 60 题以上'**
  String get profileDailyGoalHint;

  /// No description provided for @profileSetSize.
  ///
  /// In zh, this message translates to:
  /// **'默认每组题量'**
  String get profileSetSize;

  /// No description provided for @commonGotIt.
  ///
  /// In zh, this message translates to:
  /// **'知道了'**
  String get commonGotIt;

  /// No description provided for @commonCancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get commonCancel;

  /// No description provided for @profilePickExamDate.
  ///
  /// In zh, this message translates to:
  /// **'选择考试日期'**
  String get profilePickExamDate;

  /// No description provided for @profileMockCount.
  ///
  /// In zh, this message translates to:
  /// **'模考题量'**
  String get profileMockCount;

  /// No description provided for @profileMockMinutes.
  ///
  /// In zh, this message translates to:
  /// **'模考时长'**
  String get profileMockMinutes;

  /// No description provided for @commonConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确定'**
  String get commonConfirm;

  /// No description provided for @profileSetSizeShort.
  ///
  /// In zh, this message translates to:
  /// **'每组题量'**
  String get profileSetSizeShort;

  /// No description provided for @profileExamDate.
  ///
  /// In zh, this message translates to:
  /// **'考试日期'**
  String get profileExamDate;

  /// No description provided for @profileDaysRemaining.
  ///
  /// In zh, this message translates to:
  /// **'还有 {days} 天'**
  String profileDaysRemaining(int days);

  /// No description provided for @profileMock.
  ///
  /// In zh, this message translates to:
  /// **'限时模考'**
  String get profileMock;

  /// No description provided for @profileMockHint.
  ///
  /// In zh, this message translates to:
  /// **'按自己那门考试的节奏'**
  String get profileMockHint;

  /// No description provided for @profileMockCountShort.
  ///
  /// In zh, this message translates to:
  /// **'题量'**
  String get profileMockCountShort;

  /// No description provided for @profileMockMinutesShort.
  ///
  /// In zh, this message translates to:
  /// **'时长'**
  String get profileMockMinutesShort;

  /// No description provided for @wrongRemoved.
  ///
  /// In zh, this message translates to:
  /// **'已移出错题本'**
  String get wrongRemoved;

  /// No description provided for @wrongSaved.
  ///
  /// In zh, this message translates to:
  /// **'已收藏'**
  String get wrongSaved;

  /// No description provided for @wrongExportHeading.
  ///
  /// In zh, this message translates to:
  /// **'# 错题本'**
  String get wrongExportHeading;

  /// No description provided for @wrongExportedAt.
  ///
  /// In zh, this message translates to:
  /// **'导出时间：{at}'**
  String wrongExportedAt(String at);

  /// No description provided for @wrongExportTotal.
  ///
  /// In zh, this message translates to:
  /// **'共 {count} 题'**
  String wrongExportTotal(int count);

  /// No description provided for @wrongExportHasImage.
  ///
  /// In zh, this message translates to:
  /// **'（本题含图，导出文件不含图片）'**
  String get wrongExportHasImage;

  /// No description provided for @wrongExportImageOption.
  ///
  /// In zh, this message translates to:
  /// **'（图片选项）'**
  String get wrongExportImageOption;

  /// No description provided for @wrongExportAnalysis.
  ///
  /// In zh, this message translates to:
  /// **'解析：{text}'**
  String wrongExportAnalysis(String text);

  /// No description provided for @wrongExportNote.
  ///
  /// In zh, this message translates to:
  /// **'我的笔记：{text}'**
  String wrongExportNote(String text);

  /// No description provided for @wrongExportSavedDocs.
  ///
  /// In zh, this message translates to:
  /// **'已保存到 App 文档目录：{name}'**
  String wrongExportSavedDocs(String name);

  /// No description provided for @wrongExportSaved.
  ///
  /// In zh, this message translates to:
  /// **'已导出 {name}'**
  String wrongExportSaved(String name);

  /// No description provided for @wrongExportFailed.
  ///
  /// In zh, this message translates to:
  /// **'导出失败：{error}'**
  String wrongExportFailed(String error);

  /// No description provided for @wrongQuickLook.
  ///
  /// In zh, this message translates to:
  /// **'错题速览'**
  String get wrongQuickLook;

  /// No description provided for @diagnosisTitle.
  ///
  /// In zh, this message translates to:
  /// **'弱点诊断'**
  String get diagnosisTitle;

  /// No description provided for @wrongDiagnosisHint.
  ///
  /// In zh, this message translates to:
  /// **'拿你的速度和正确率去比 161 套真题的基准'**
  String get wrongDiagnosisHint;

  /// No description provided for @wrongTodayReview.
  ///
  /// In zh, this message translates to:
  /// **'今日复盘'**
  String get wrongTodayReview;

  /// No description provided for @wrongRepeatFirst.
  ///
  /// In zh, this message translates to:
  /// **'先啃错过两次以上的 {count} 题'**
  String wrongRepeatFirst(int count);

  /// No description provided for @commonStart.
  ///
  /// In zh, this message translates to:
  /// **'开始'**
  String get commonStart;

  /// No description provided for @wrongBrowseAnalysis.
  ///
  /// In zh, this message translates to:
  /// **'速览解析'**
  String get wrongBrowseAnalysis;

  /// No description provided for @wrongUntagged.
  ///
  /// In zh, this message translates to:
  /// **'{count} 题还没标错因，标了才知道是粗心还是不会'**
  String wrongUntagged(int count);

  /// No description provided for @wrongRepeating.
  ///
  /// In zh, this message translates to:
  /// **'还在反复犯的'**
  String get wrongRepeating;

  /// No description provided for @wrongLongPressHint.
  ///
  /// In zh, this message translates to:
  /// **'长按一类可以开四天专项计划'**
  String get wrongLongPressHint;

  /// No description provided for @wrongNoReason.
  ///
  /// In zh, this message translates to:
  /// **'未标错因'**
  String get wrongNoReason;

  /// No description provided for @wrongByType.
  ///
  /// In zh, this message translates to:
  /// **'按题型'**
  String get wrongByType;

  /// No description provided for @commonAllArrow.
  ///
  /// In zh, this message translates to:
  /// **'全部 ›'**
  String get commonAllArrow;

  /// No description provided for @wrongViewAll.
  ///
  /// In zh, this message translates to:
  /// **'逐题查看全部 {count} 题'**
  String wrongViewAll(int count);

  /// No description provided for @wrongNoPaper.
  ///
  /// In zh, this message translates to:
  /// **'未归卷题目'**
  String get wrongNoPaper;

  /// No description provided for @wrongBookTitle.
  ///
  /// In zh, this message translates to:
  /// **'错题本'**
  String get wrongBookTitle;

  /// No description provided for @wrongToClear.
  ///
  /// In zh, this message translates to:
  /// **'{count} 题待消灭'**
  String wrongToClear(int count);

  /// No description provided for @wrongAll.
  ///
  /// In zh, this message translates to:
  /// **'全部错题'**
  String get wrongAll;

  /// No description provided for @wrongFiltered.
  ///
  /// In zh, this message translates to:
  /// **'筛出 {count} 题'**
  String wrongFiltered(int count);

  /// No description provided for @wrongRedoFiltered.
  ///
  /// In zh, this message translates to:
  /// **'重练当前筛选的题'**
  String get wrongRedoFiltered;

  /// No description provided for @wrongExportMarkdown.
  ///
  /// In zh, this message translates to:
  /// **'导出当前列表为 Markdown'**
  String get wrongExportMarkdown;

  /// No description provided for @wrongEmptyHint.
  ///
  /// In zh, this message translates to:
  /// **'答错的题会自动收进来'**
  String get wrongEmptyHint;

  /// No description provided for @wrongCountWithHint.
  ///
  /// In zh, this message translates to:
  /// **'{count} 题 · 长按可标错因'**
  String wrongCountWithHint(int count);

  /// No description provided for @sessionResultTitle.
  ///
  /// In zh, this message translates to:
  /// **'本场结果'**
  String get sessionResultTitle;

  /// No description provided for @sessionResultLine.
  ///
  /// In zh, this message translates to:
  /// **'正确率 {rate}% · 答对 {correct} / {total} · 用时 {time}'**
  String sessionResultLine(int rate, int correct, int total, String time);

  /// No description provided for @sessionSeeReport.
  ///
  /// In zh, this message translates to:
  /// **'看成绩单'**
  String get sessionSeeReport;

  /// No description provided for @sessionSeeAnalysis.
  ///
  /// In zh, this message translates to:
  /// **'逐题看解析'**
  String get sessionSeeAnalysis;

  /// No description provided for @sessionMock.
  ///
  /// In zh, this message translates to:
  /// **'限时模考'**
  String get sessionMock;

  /// No description provided for @sessionPracticeCount.
  ///
  /// In zh, this message translates to:
  /// **'练习 {count} 题'**
  String sessionPracticeCount(int count);

  /// No description provided for @sessionDaily.
  ///
  /// In zh, this message translates to:
  /// **'每日一练'**
  String get sessionDaily;

  /// No description provided for @sessionBlankLeft.
  ///
  /// In zh, this message translates to:
  /// **'还有 {count} 题没作答'**
  String sessionBlankLeft(int count);

  /// No description provided for @sessionSubmitWarn.
  ///
  /// In zh, this message translates to:
  /// **'交卷后未作答的题会计为错题，确定现在交卷吗？'**
  String get sessionSubmitWarn;

  /// No description provided for @sessionSubmitAnyway.
  ///
  /// In zh, this message translates to:
  /// **'仍然交卷'**
  String get sessionSubmitAnyway;

  /// No description provided for @sessionQuitMock.
  ///
  /// In zh, this message translates to:
  /// **'退出模考？'**
  String get sessionQuitMock;

  /// No description provided for @sessionQuitPractice.
  ///
  /// In zh, this message translates to:
  /// **'结束这组练习？'**
  String get sessionQuitPractice;

  /// No description provided for @sessionQuitMockBody.
  ///
  /// In zh, this message translates to:
  /// **'模考中途退出不会生成成绩报告，已答的题仍计入练习记录。'**
  String get sessionQuitMockBody;

  /// No description provided for @sessionQuitPracticeBody.
  ///
  /// In zh, this message translates to:
  /// **'已答的 {count} 题已经保存，可以随时再来一组。'**
  String sessionQuitPracticeBody(int count);

  /// No description provided for @commonQuit.
  ///
  /// In zh, this message translates to:
  /// **'退出'**
  String get commonQuit;

  /// No description provided for @sessionSavedHint.
  ///
  /// In zh, this message translates to:
  /// **'已收藏，可在「我的 → 我的收藏」查看'**
  String get sessionSavedHint;

  /// No description provided for @sessionUnsaved.
  ///
  /// In zh, this message translates to:
  /// **'已取消收藏'**
  String get sessionUnsaved;

  /// No description provided for @sessionReportedHint.
  ///
  /// In zh, this message translates to:
  /// **'已记下，可在「我的 → 纠错记录」里查看'**
  String get sessionReportedHint;

  /// No description provided for @sessionAnalysisTime.
  ///
  /// In zh, this message translates to:
  /// **'解析 · {time}'**
  String sessionAnalysisTime(String time);

  /// No description provided for @sessionReview.
  ///
  /// In zh, this message translates to:
  /// **'回顾'**
  String get sessionReview;

  /// No description provided for @sessionScore.
  ///
  /// In zh, this message translates to:
  /// **'成绩'**
  String get sessionScore;

  /// No description provided for @sessionQuestionNo.
  ///
  /// In zh, this message translates to:
  /// **'第 {n} 题'**
  String sessionQuestionNo(int n);

  /// No description provided for @sessionLastQuestion.
  ///
  /// In zh, this message translates to:
  /// **'最后一题'**
  String get sessionLastQuestion;

  /// No description provided for @sessionViewSingle.
  ///
  /// In zh, this message translates to:
  /// **'单题'**
  String get sessionViewSingle;

  /// No description provided for @sessionViewSingleHint.
  ///
  /// In zh, this message translates to:
  /// **'一屏一题，最专注'**
  String get sessionViewSingleHint;

  /// No description provided for @sessionViewDual.
  ///
  /// In zh, this message translates to:
  /// **'双题'**
  String get sessionViewDual;

  /// No description provided for @sessionViewDualHint.
  ///
  /// In zh, this message translates to:
  /// **'一屏两题，适合宽屏'**
  String get sessionViewDualHint;

  /// No description provided for @sessionViewScroll.
  ///
  /// In zh, this message translates to:
  /// **'整卷'**
  String get sessionViewScroll;

  /// No description provided for @sessionViewScrollHint.
  ///
  /// In zh, this message translates to:
  /// **'连续下滑，像纸质卷'**
  String get sessionViewScrollHint;

  /// No description provided for @sessionLayout.
  ///
  /// In zh, this message translates to:
  /// **'答题版式'**
  String get sessionLayout;

  /// No description provided for @sessionWasBlank.
  ///
  /// In zh, this message translates to:
  /// **'这道题当时没有作答'**
  String get sessionWasBlank;

  /// No description provided for @sessionTipsChip.
  ///
  /// In zh, this message translates to:
  /// **' 技巧'**
  String get sessionTipsChip;

  /// No description provided for @sessionSeeFigure.
  ///
  /// In zh, this message translates to:
  /// **'见上图'**
  String get sessionSeeFigure;

  /// No description provided for @sessionAnalysis.
  ///
  /// In zh, this message translates to:
  /// **'解析'**
  String get sessionAnalysis;

  /// No description provided for @sessionCorrectAnswer.
  ///
  /// In zh, this message translates to:
  /// **'正确答案 {answer}'**
  String sessionCorrectAnswer(String answer);

  /// No description provided for @sessionNext.
  ///
  /// In zh, this message translates to:
  /// **'下一题'**
  String get sessionNext;

  /// No description provided for @sessionMultiHint.
  ///
  /// In zh, this message translates to:
  /// **'多选题 · 选完点「确定」'**
  String get sessionMultiHint;

  /// No description provided for @commonConfirmShort.
  ///
  /// In zh, this message translates to:
  /// **'确定'**
  String get commonConfirmShort;

  /// No description provided for @sessionConfirmPicked.
  ///
  /// In zh, this message translates to:
  /// **'确定（已选 {count} 项）'**
  String sessionConfirmPicked(int count);

  /// No description provided for @sessionHintAuto.
  ///
  /// In zh, this message translates to:
  /// **'选中即进入下一题 · 长按选项可排除 · 左右滑动可回看'**
  String get sessionHintAuto;

  /// No description provided for @sessionHintManual.
  ///
  /// In zh, this message translates to:
  /// **'长按选项可排除 · 左右滑动切换题目 · 点图片可放大'**
  String get sessionHintManual;

  /// No description provided for @sessionMyNote.
  ///
  /// In zh, this message translates to:
  /// **'我的笔记'**
  String get sessionMyNote;

  /// No description provided for @sessionSubmit.
  ///
  /// In zh, this message translates to:
  /// **'交卷'**
  String get sessionSubmit;

  /// No description provided for @whenToday.
  ///
  /// In zh, this message translates to:
  /// **'今天'**
  String get whenToday;

  /// No description provided for @whenYesterday.
  ///
  /// In zh, this message translates to:
  /// **'昨天'**
  String get whenYesterday;

  /// No description provided for @whenDaysAgo.
  ///
  /// In zh, this message translates to:
  /// **'{days} 天前'**
  String whenDaysAgo(int days);

  /// No description provided for @sessionMockScore.
  ///
  /// In zh, this message translates to:
  /// **'本场成绩'**
  String get sessionMockScore;

  /// No description provided for @sessionPracticeResult.
  ///
  /// In zh, this message translates to:
  /// **'练习结果'**
  String get sessionPracticeResult;

  /// No description provided for @sessionGoodShape.
  ///
  /// In zh, this message translates to:
  /// **'状态不错'**
  String get sessionGoodShape;

  /// No description provided for @sessionKeepGoing.
  ///
  /// In zh, this message translates to:
  /// **'继续保持'**
  String get sessionKeepGoing;

  /// No description provided for @sessionAnotherSet.
  ///
  /// In zh, this message translates to:
  /// **'再练一组'**
  String get sessionAnotherSet;

  /// No description provided for @sessionTimeUsed.
  ///
  /// In zh, this message translates to:
  /// **'用时 {time}'**
  String sessionTimeUsed(String time);

  /// No description provided for @sessionPerQuestionNone.
  ///
  /// In zh, this message translates to:
  /// **'每题 —'**
  String get sessionPerQuestionNone;

  /// No description provided for @sessionUnanswered.
  ///
  /// In zh, this message translates to:
  /// **'未作答 {count}'**
  String sessionUnanswered(int count);

  /// No description provided for @sessionDoubtReview.
  ///
  /// In zh, this message translates to:
  /// **'存疑回顾'**
  String get sessionDoubtReview;

  /// No description provided for @sessionDoubtCount.
  ///
  /// In zh, this message translates to:
  /// **'做题时标了 {count} 道存疑，点开逐题看'**
  String sessionDoubtCount(int count);

  /// No description provided for @sessionSlowCount.
  ///
  /// In zh, this message translates to:
  /// **'有 {count} 题超过 90 秒，考场上这类题应该先跳过'**
  String sessionSlowCount(int count);

  /// No description provided for @sessionByType.
  ///
  /// In zh, this message translates to:
  /// **'各题型得分'**
  String get sessionByType;

  /// No description provided for @sessionWrongReview.
  ///
  /// In zh, this message translates to:
  /// **'错题回顾'**
  String get sessionWrongReview;

  /// No description provided for @sessionWrongCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 题 · 点开看原题'**
  String sessionWrongCount(int count);

  /// No description provided for @sessionAllCorrect.
  ///
  /// In zh, this message translates to:
  /// **'全部答对'**
  String get sessionAllCorrect;

  /// No description provided for @sessionAllCorrectBody.
  ///
  /// In zh, this message translates to:
  /// **'这一组没有错题，换个题型继续保持手感。'**
  String get sessionAllCorrectBody;

  /// No description provided for @sessionGoThrough.
  ///
  /// In zh, this message translates to:
  /// **'逐题回顾'**
  String get sessionGoThrough;

  /// No description provided for @commonDone.
  ///
  /// In zh, this message translates to:
  /// **'完成'**
  String get commonDone;

  /// No description provided for @sessionRedoWrong.
  ///
  /// In zh, this message translates to:
  /// **'重做错题 {count}'**
  String sessionRedoWrong(int count);

  /// No description provided for @sessionNoteTitle.
  ///
  /// In zh, this message translates to:
  /// **'这道题的笔记'**
  String get sessionNoteTitle;

  /// No description provided for @sessionNoteHint.
  ///
  /// In zh, this message translates to:
  /// **'记方法、坑点、公式 —— 回顾时会显示在解析下面'**
  String get sessionNoteHint;

  /// No description provided for @commonDelete.
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get commonDelete;

  /// No description provided for @sessionWhyWrong.
  ///
  /// In zh, this message translates to:
  /// **'这题为什么错？'**
  String get sessionWhyWrong;

  /// No description provided for @sessionTagged.
  ///
  /// In zh, this message translates to:
  /// **'已标记，可再点一次取消'**
  String get sessionTagged;

  /// No description provided for @sessionReportTitle.
  ///
  /// In zh, this message translates to:
  /// **'这道题有问题'**
  String get sessionReportTitle;

  /// No description provided for @sessionReportHint.
  ///
  /// In zh, this message translates to:
  /// **'记在本机，可在「我的」里查看，也会随备份一起导出'**
  String get sessionReportHint;

  /// No description provided for @sessionReportNote.
  ///
  /// In zh, this message translates to:
  /// **'补充两句（选填）'**
  String get sessionReportNote;

  /// No description provided for @sessionReportSubmit.
  ///
  /// In zh, this message translates to:
  /// **'记下'**
  String get sessionReportSubmit;

  /// No description provided for @sessionMaterial.
  ///
  /// In zh, this message translates to:
  /// **'材料'**
  String get sessionMaterial;

  /// No description provided for @fontSmall.
  ///
  /// In zh, this message translates to:
  /// **'小'**
  String get fontSmall;

  /// No description provided for @fontNormal.
  ///
  /// In zh, this message translates to:
  /// **'标准'**
  String get fontNormal;

  /// No description provided for @fontLarge.
  ///
  /// In zh, this message translates to:
  /// **'大'**
  String get fontLarge;

  /// No description provided for @fontHuge.
  ///
  /// In zh, this message translates to:
  /// **'特大'**
  String get fontHuge;

  /// No description provided for @sessionReading.
  ///
  /// In zh, this message translates to:
  /// **'阅读设置'**
  String get sessionReading;

  /// No description provided for @sessionFontSize.
  ///
  /// In zh, this message translates to:
  /// **'题目字号'**
  String get sessionFontSize;

  /// No description provided for @sessionAutoNext.
  ///
  /// In zh, this message translates to:
  /// **'答对自动下一题'**
  String get sessionAutoNext;

  /// No description provided for @sessionAutoNextHint.
  ///
  /// In zh, this message translates to:
  /// **'答错时仍会停下看解析'**
  String get sessionAutoNextHint;

  /// No description provided for @sessionCard.
  ///
  /// In zh, this message translates to:
  /// **'答题卡'**
  String get sessionCard;

  /// No description provided for @sessionAnsweredOf.
  ///
  /// In zh, this message translates to:
  /// **'已答 {done} / {total}'**
  String sessionAnsweredOf(int done, int total);

  /// No description provided for @sessionRight.
  ///
  /// In zh, this message translates to:
  /// **'对'**
  String get sessionRight;

  /// No description provided for @sessionWrongShort.
  ///
  /// In zh, this message translates to:
  /// **'错'**
  String get sessionWrongShort;

  /// No description provided for @sessionAnswered.
  ///
  /// In zh, this message translates to:
  /// **'已答'**
  String get sessionAnswered;

  /// No description provided for @sessionDoubt.
  ///
  /// In zh, this message translates to:
  /// **'存疑'**
  String get sessionDoubt;

  /// No description provided for @sessionSubmitEarly.
  ///
  /// In zh, this message translates to:
  /// **'提前交卷'**
  String get sessionSubmitEarly;

  /// No description provided for @difficultyEasy.
  ///
  /// In zh, this message translates to:
  /// **'简单'**
  String get difficultyEasy;

  /// No description provided for @difficultyMedium.
  ///
  /// In zh, this message translates to:
  /// **'一般'**
  String get difficultyMedium;

  /// No description provided for @difficultyHard.
  ///
  /// In zh, this message translates to:
  /// **'难'**
  String get difficultyHard;

  /// No description provided for @sessionDifficultyFor.
  ///
  /// In zh, this message translates to:
  /// **'这题对我'**
  String get sessionDifficultyFor;

  /// No description provided for @sessionScratch.
  ///
  /// In zh, this message translates to:
  /// **'草稿纸与计算器'**
  String get sessionScratch;

  /// No description provided for @sessionHasScratch.
  ///
  /// In zh, this message translates to:
  /// **'这题已有草稿'**
  String get sessionHasScratch;

  /// No description provided for @sessionScratchHint.
  ///
  /// In zh, this message translates to:
  /// **'资料分析可以直接算'**
  String get sessionScratchHint;

  /// No description provided for @sessionWriteNote.
  ///
  /// In zh, this message translates to:
  /// **'写笔记'**
  String get sessionWriteNote;

  /// No description provided for @sessionHasNote.
  ///
  /// In zh, this message translates to:
  /// **'这题已有笔记'**
  String get sessionHasNote;

  /// No description provided for @sessionNoteShort.
  ///
  /// In zh, this message translates to:
  /// **'记方法和坑点，回顾时会显示'**
  String get sessionNoteShort;

  /// No description provided for @sessionLayoutHint.
  ///
  /// In zh, this message translates to:
  /// **'单题 / 双题 / 整卷'**
  String get sessionLayoutHint;

  /// No description provided for @sessionReadingHint.
  ///
  /// In zh, this message translates to:
  /// **'字号与自动下一题'**
  String get sessionReadingHint;

  /// No description provided for @sessionUnsave.
  ///
  /// In zh, this message translates to:
  /// **'取消收藏'**
  String get sessionUnsave;

  /// No description provided for @sessionSave.
  ///
  /// In zh, this message translates to:
  /// **'收藏这题'**
  String get sessionSave;

  /// No description provided for @sessionSaveHint.
  ///
  /// In zh, this message translates to:
  /// **'收藏的题在「我的 → 我的收藏」'**
  String get sessionSaveHint;

  /// No description provided for @sessionReportShort.
  ///
  /// In zh, this message translates to:
  /// **'这题有问题'**
  String get sessionReportShort;

  /// No description provided for @sessionReportShortHint.
  ///
  /// In zh, this message translates to:
  /// **'答案有误、解析看不懂都可以标'**
  String get sessionReportShortHint;

  /// No description provided for @homeNoQuestionsHere.
  ///
  /// In zh, this message translates to:
  /// **'这里还没有题'**
  String get homeNoQuestionsHere;

  /// No description provided for @homeNoUnseen.
  ///
  /// In zh, this message translates to:
  /// **'这个范围里没有没做过的题了'**
  String get homeNoUnseen;

  /// No description provided for @homeNoWrongHere.
  ///
  /// In zh, this message translates to:
  /// **'这里还没有错题'**
  String get homeNoWrongHere;

  /// No description provided for @homeReciteSub.
  ///
  /// In zh, this message translates to:
  /// **'{name} · 背题'**
  String homeReciteSub(String name);

  /// No description provided for @homeRecite.
  ///
  /// In zh, this message translates to:
  /// **'背题'**
  String get homeRecite;

  /// No description provided for @homeHardTagged.
  ///
  /// In zh, this message translates to:
  /// **'标难的题'**
  String get homeHardTagged;

  /// No description provided for @homeTimedSub.
  ///
  /// In zh, this message translates to:
  /// **'{name} · 限时'**
  String homeTimedSub(String name);

  /// No description provided for @homeTimedCat.
  ///
  /// In zh, this message translates to:
  /// **'{name}限时练'**
  String homeTimedCat(String name);

  /// No description provided for @homeEssay.
  ///
  /// In zh, this message translates to:
  /// **'申论'**
  String get homeEssay;

  /// No description provided for @homeManualTask.
  ///
  /// In zh, this message translates to:
  /// **'手写任务勾选即可，做完别忘了打勾'**
  String get homeManualTask;

  /// No description provided for @homeRedoWrong.
  ///
  /// In zh, this message translates to:
  /// **'错题重练'**
  String get homeRedoWrong;

  /// No description provided for @homeWeakDrill.
  ///
  /// In zh, this message translates to:
  /// **'弱项强化'**
  String get homeWeakDrill;

  /// No description provided for @homeDeleteTask.
  ///
  /// In zh, this message translates to:
  /// **'删除安排'**
  String get homeDeleteTask;

  /// No description provided for @homeDeleteTaskConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确定删除「{title}」？'**
  String homeDeleteTaskConfirm(String title);

  /// No description provided for @homeResume.
  ///
  /// In zh, this message translates to:
  /// **'继续上次'**
  String get homeResume;

  /// No description provided for @homeResumeLine.
  ///
  /// In zh, this message translates to:
  /// **'{title} · 还剩 {count} 题'**
  String homeResumeLine(String title, int count);

  /// No description provided for @homeDaily.
  ///
  /// In zh, this message translates to:
  /// **'每日一练'**
  String get homeDaily;

  /// No description provided for @homeDailyHint.
  ///
  /// In zh, this message translates to:
  /// **'今天的固定卷'**
  String get homeDailyHint;

  /// No description provided for @homeProvincePapers.
  ///
  /// In zh, this message translates to:
  /// **'{name}真题'**
  String homeProvincePapers(String name);

  /// No description provided for @homeProvinceHint.
  ///
  /// In zh, this message translates to:
  /// **'{count} 题 · 你要考的卷'**
  String homeProvinceHint(int count);

  /// No description provided for @homeWeakLocked.
  ///
  /// In zh, this message translates to:
  /// **'先练一组再解锁'**
  String get homeWeakLocked;

  /// No description provided for @homeWeakHint.
  ///
  /// In zh, this message translates to:
  /// **'按薄弱模块配比'**
  String get homeWeakHint;

  /// No description provided for @homeNoWrong.
  ///
  /// In zh, this message translates to:
  /// **'暂无错题'**
  String get homeNoWrong;

  /// No description provided for @homeWrongLeft.
  ///
  /// In zh, this message translates to:
  /// **'{count} 题待清'**
  String homeWrongLeft(int count);

  /// No description provided for @homeEssayMark.
  ///
  /// In zh, this message translates to:
  /// **'申论批改'**
  String get homeEssayMark;

  /// No description provided for @homeEssayHint.
  ///
  /// In zh, this message translates to:
  /// **'写一篇，交给 AI 评'**
  String get homeEssayHint;

  /// No description provided for @homeMock.
  ///
  /// In zh, this message translates to:
  /// **'限时模考'**
  String get homeMock;

  /// No description provided for @homeMoreWays.
  ///
  /// In zh, this message translates to:
  /// **'更多练法'**
  String get homeMoreWays;

  /// No description provided for @homeStreak.
  ///
  /// In zh, this message translates to:
  /// **'连续打卡 {days} 天'**
  String homeStreak(int days);

  /// No description provided for @homeDailyCheckin.
  ///
  /// In zh, this message translates to:
  /// **'每日一练打卡'**
  String get homeDailyCheckin;

  /// No description provided for @homePerSet.
  ///
  /// In zh, this message translates to:
  /// **'每组 {count} 题'**
  String homePerSet(int count);

  /// No description provided for @homeTotalInBank.
  ///
  /// In zh, this message translates to:
  /// **'共 {count} 题'**
  String homeTotalInBank(int count);

  /// No description provided for @homeDailyReview.
  ///
  /// In zh, this message translates to:
  /// **'今日一练回顾'**
  String get homeDailyReview;

  /// No description provided for @homeCatchUp.
  ///
  /// In zh, this message translates to:
  /// **'补做 {date}'**
  String homeCatchUp(String date);

  /// No description provided for @homeRegionPapers.
  ///
  /// In zh, this message translates to:
  /// **'{name}真题'**
  String homeRegionPapers(String name);

  /// No description provided for @homeTodayRoute.
  ///
  /// In zh, this message translates to:
  /// **'今日航线'**
  String get homeTodayRoute;

  /// No description provided for @homeArrange.
  ///
  /// In zh, this message translates to:
  /// **'安排'**
  String get homeArrange;

  /// No description provided for @homeAllTasks.
  ///
  /// In zh, this message translates to:
  /// **'全部 {count}'**
  String homeAllTasks(int count);

  /// No description provided for @homeAdjust.
  ///
  /// In zh, this message translates to:
  /// **'调整'**
  String get homeAdjust;

  /// No description provided for @homeIslands.
  ///
  /// In zh, this message translates to:
  /// **'五座岛'**
  String get homeIslands;

  /// No description provided for @homeHardCount.
  ///
  /// In zh, this message translates to:
  /// **'自己标难的 {count} 题'**
  String homeHardCount(int count);

  /// No description provided for @homeGreetDone.
  ///
  /// In zh, this message translates to:
  /// **'今天划完了'**
  String get homeGreetDone;

  /// No description provided for @homeGreetMorning.
  ///
  /// In zh, this message translates to:
  /// **'早，该出发了'**
  String get homeGreetMorning;

  /// No description provided for @homeGreetKeep.
  ///
  /// In zh, this message translates to:
  /// **'继续划'**
  String get homeGreetKeep;

  /// No description provided for @homeGreetFinish.
  ///
  /// In zh, this message translates to:
  /// **'收个尾再靠岸'**
  String get homeGreetFinish;

  /// No description provided for @homeNoRoute.
  ///
  /// In zh, this message translates to:
  /// **'还没排今天的航线'**
  String get homeNoRoute;

  /// No description provided for @homeRouteHint.
  ///
  /// In zh, this message translates to:
  /// **'模板可以改，删掉不做的就行'**
  String get homeRouteHint;

  /// No description provided for @homeGoPlan.
  ///
  /// In zh, this message translates to:
  /// **'去安排'**
  String get homeGoPlan;

  /// No description provided for @scopeAll.
  ///
  /// In zh, this message translates to:
  /// **'全部题'**
  String get scopeAll;

  /// No description provided for @scopeUnseen.
  ///
  /// In zh, this message translates to:
  /// **'没做过'**
  String get scopeUnseen;

  /// No description provided for @scopeWrong.
  ///
  /// In zh, this message translates to:
  /// **'做错过'**
  String get scopeWrong;

  /// No description provided for @scopeAllHint.
  ///
  /// In zh, this message translates to:
  /// **'优先近年真题，同年内随机'**
  String get scopeAllHint;

  /// No description provided for @scopeUnseenLong.
  ///
  /// In zh, this message translates to:
  /// **'没做过的'**
  String get scopeUnseenLong;

  /// No description provided for @scopeUnseenHint.
  ///
  /// In zh, this message translates to:
  /// **'跳过已做 · 仍优先近年'**
  String get scopeUnseenHint;

  /// No description provided for @scopeWrongLong.
  ///
  /// In zh, this message translates to:
  /// **'做错过的'**
  String get scopeWrongLong;

  /// No description provided for @scopeWrongHint.
  ///
  /// In zh, this message translates to:
  /// **'只抽上次答错的题'**
  String get scopeWrongHint;

  /// No description provided for @scopeTitle.
  ///
  /// In zh, this message translates to:
  /// **'抽题范围'**
  String get scopeTitle;

  /// No description provided for @scopeHint.
  ///
  /// In zh, this message translates to:
  /// **'长按题量可以改每组题数'**
  String get scopeHint;

  /// No description provided for @scopeCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 题'**
  String scopeCount(int count);

  /// No description provided for @yearAllHint.
  ///
  /// In zh, this message translates to:
  /// **'题库里有的都抽，仍然优先近年'**
  String get yearAllHint;

  /// No description provided for @yearLast3Hint.
  ///
  /// In zh, this message translates to:
  /// **'{from}—{to} 年 · 结构和考点最贴近今年'**
  String yearLast3Hint(String from, String to);

  /// No description provided for @yearLast1Hint.
  ///
  /// In zh, this message translates to:
  /// **'只有 {year} 年 · 练常识时间政策题必用这一档'**
  String yearLast1Hint(String year);

  /// No description provided for @yearRangeTitle.
  ///
  /// In zh, this message translates to:
  /// **'年份范围'**
  String get yearRangeTitle;

  /// No description provided for @yearRangeHint.
  ///
  /// In zh, this message translates to:
  /// **'常识判断一半的题引的是考前一年的讲话原文和新出台文件，旧题的答案已经作废；言语、判断、资料的结构常年不动，老题照样能练。'**
  String get yearRangeHint;

  /// No description provided for @yearRangeCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 题'**
  String yearRangeCount(int count);

  /// No description provided for @homeDailyGoal.
  ///
  /// In zh, this message translates to:
  /// **'每日目标'**
  String get homeDailyGoal;

  /// No description provided for @homeDailyGoalHint.
  ///
  /// In zh, this message translates to:
  /// **'在职备考建议 20–30 题，全职冲刺 60 题以上'**
  String get homeDailyGoalHint;

  /// No description provided for @countQuestions.
  ///
  /// In zh, this message translates to:
  /// **'{count} 题'**
  String countQuestions(int count);

  /// No description provided for @homeSetSize.
  ///
  /// In zh, this message translates to:
  /// **'每组题量'**
  String get homeSetSize;

  /// No description provided for @homeAboutBody.
  ///
  /// In zh, this message translates to:
  /// **'本地优先的公务员行测刷题工具。题库、答题记录、统计全部保存在这台设备上，不联网、不上传。内置题来自 OpenExam 桌面端种子库，也可以在「导入」页导入自己的题目。'**
  String get homeAboutBody;

  /// No description provided for @homeTimed.
  ///
  /// In zh, this message translates to:
  /// **'限时'**
  String get homeTimed;

  /// No description provided for @homeExpandHint.
  ///
  /// In zh, this message translates to:
  /// **'共 {count} 题 · 展开分类后开始'**
  String homeExpandHint(int count);

  /// No description provided for @homeNoSubtypes.
  ///
  /// In zh, this message translates to:
  /// **'暂无细分'**
  String get homeNoSubtypes;

  /// No description provided for @homeMixAll.
  ///
  /// In zh, this message translates to:
  /// **'全部混练'**
  String get homeMixAll;

  /// No description provided for @homeMixHint.
  ///
  /// In zh, this message translates to:
  /// **'{count} 题 · 约 {minutes} 分钟节奏'**
  String homeMixHint(int count, int minutes);

  /// No description provided for @homeSubCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 题'**
  String homeSubCount(int count);

  /// No description provided for @homePlain.
  ///
  /// In zh, this message translates to:
  /// **'直接练'**
  String get homePlain;

  /// No description provided for @homePlainHint.
  ///
  /// In zh, this message translates to:
  /// **'{count} 题，不计时'**
  String homePlainHint(int count);

  /// No description provided for @homeTimedDrill.
  ///
  /// In zh, this message translates to:
  /// **'限时练'**
  String get homeTimedDrill;

  /// No description provided for @homeTimedDrillHint.
  ///
  /// In zh, this message translates to:
  /// **'{count} 题 · 约 {minutes} 分钟，按考场节奏'**
  String homeTimedDrillHint(int count, int minutes);

  /// No description provided for @homeReciteHint.
  ///
  /// In zh, this message translates to:
  /// **'不作答，直接看答案和解析'**
  String get homeReciteHint;

  /// No description provided for @dxScopeAll.
  ///
  /// In zh, this message translates to:
  /// **'全部作答记录'**
  String get dxScopeAll;

  /// No description provided for @dxThinSample.
  ///
  /// In zh, this message translates to:
  /// **'只有 {count} 条作答记录，结论还不稳。做够 100 题再看一次。'**
  String dxThinSample(int count);

  /// No description provided for @dxSlowTitle.
  ///
  /// In zh, this message translates to:
  /// **'{name} 慢得会拖垮整张卷'**
  String dxSlowTitle(String name);

  /// No description provided for @dxSlowEvidence.
  ///
  /// In zh, this message translates to:
  /// **'每题 {secs} 秒，基准 {bench} 秒，慢 {pct}%'**
  String dxSlowEvidence(int secs, int bench, int pct);

  /// No description provided for @dxSlowOverrun.
  ///
  /// In zh, this message translates to:
  /// **'；照这个速度一套卷多花 {mins} 分钟'**
  String dxSlowOverrun(int mins);

  /// No description provided for @dxSlightlySlowTitle.
  ///
  /// In zh, this message translates to:
  /// **'{name} 比基准慢一点'**
  String dxSlightlySlowTitle(String name);

  /// No description provided for @dxPaceEvidence.
  ///
  /// In zh, this message translates to:
  /// **'每题 {secs} 秒，基准 {bench} 秒'**
  String dxPaceEvidence(int secs, int bench);

  /// No description provided for @dxSlightlySlowAction.
  ///
  /// In zh, this message translates to:
  /// **'还在可控范围，但限时练的时候按 {bench} 秒卡表，别让它继续涨。'**
  String dxSlightlySlowAction(int bench);

  /// No description provided for @dxFastSteadyTitle.
  ///
  /// In zh, this message translates to:
  /// **'{name} 又快又稳'**
  String dxFastSteadyTitle(String name);

  /// No description provided for @dxFastSteadyEvidence.
  ///
  /// In zh, this message translates to:
  /// **'每题 {secs} 秒（基准 {bench} 秒），正确率 {rate}'**
  String dxFastSteadyEvidence(int secs, int bench, String rate);

  /// No description provided for @dxFastSteadyAction.
  ///
  /// In zh, this message translates to:
  /// **'这块不用再投时间，省下来的分钟给弱的模块。'**
  String get dxFastSteadyAction;

  /// No description provided for @dxRushTitle.
  ///
  /// In zh, this message translates to:
  /// **'{name} 是做太快错的，不是不会'**
  String dxRushTitle(String name);

  /// No description provided for @dxRushEvidence.
  ///
  /// In zh, this message translates to:
  /// **'每题 {secs} 秒，比基准 {bench} 秒快 {pct}%；正确率只有 {rate}（目标 {target}）'**
  String dxRushEvidence(
    int secs,
    int bench,
    int pct,
    String rate,
    String target,
  );

  /// No description provided for @dxRushAction.
  ///
  /// In zh, this message translates to:
  /// **'先把速度压回 {bench} 秒一题，正确率提到 {target} 之后再提速。省下来的几分钟换不回丢掉的分 —— {how}'**
  String dxRushAction(int bench, String target, String how);

  /// No description provided for @dxAccuracyGapTitle.
  ///
  /// In zh, this message translates to:
  /// **'{name} 正确率离目标还差一截'**
  String dxAccuracyGapTitle(String name);

  /// No description provided for @dxAccuracyGapEvidence.
  ///
  /// In zh, this message translates to:
  /// **'{rate}（{correct}/{attempts}），目标 {target}'**
  String dxAccuracyGapEvidence(
    String rate,
    int correct,
    int attempts,
    String target,
  );

  /// No description provided for @dxAlmostTitle.
  ///
  /// In zh, this message translates to:
  /// **'{name} 差一口气到目标'**
  String dxAlmostTitle(String name);

  /// No description provided for @dxAlmostEvidence.
  ///
  /// In zh, this message translates to:
  /// **'{rate}，目标 {target}'**
  String dxAlmostEvidence(String rate, String target);

  /// No description provided for @dxAlmostAction.
  ///
  /// In zh, this message translates to:
  /// **'按错因翻一遍这个模块的错题，看是同一类反复栽还是零散错。'**
  String get dxAlmostAction;

  /// No description provided for @dxTimeSinkTitle.
  ///
  /// In zh, this message translates to:
  /// **'数量关系吃掉了太多时间'**
  String get dxTimeSinkTitle;

  /// No description provided for @dxTimeSinkEvidence.
  ///
  /// In zh, this message translates to:
  /// **'它占了你 {share} 的做题时间，卷面上只占 {paper} 的题'**
  String dxTimeSinkEvidence(String share, String paper);

  /// No description provided for @dxOverthinkTitle.
  ///
  /// In zh, this message translates to:
  /// **'常识判断纠结太久'**
  String get dxOverthinkTitle;

  /// No description provided for @dxThinPracticeTitle.
  ///
  /// In zh, this message translates to:
  /// **'资料分析练得太少'**
  String get dxThinPracticeTitle;

  /// No description provided for @dxThinPracticeEvidence.
  ///
  /// In zh, this message translates to:
  /// **'只占你练习量的 {share}，卷面上占 {paper}'**
  String dxThinPracticeEvidence(String share, String paper);

  /// No description provided for @dxRepeatTitle.
  ///
  /// In zh, this message translates to:
  /// **'错题在重复犯，不是新错'**
  String get dxRepeatTitle;

  /// No description provided for @dxRepeatEvidence.
  ///
  /// In zh, this message translates to:
  /// **'错题本 {total} 题里有 {repeat} 题错过两次以上（{pct}）'**
  String dxRepeatEvidence(int total, int repeat, String pct);

  /// No description provided for @dxRepeatAction.
  ///
  /// In zh, this message translates to:
  /// **'重复错说明第一次复盘没弄懂原因。挑错得最多的那几道，逐题写下「当时为什么选了它」，比再做十道新题有用。'**
  String get dxRepeatAction;

  /// No description provided for @dxUntaggedTitle.
  ///
  /// In zh, this message translates to:
  /// **'大部分错题没标错因'**
  String get dxUntaggedTitle;

  /// No description provided for @dxUntaggedEvidence.
  ///
  /// In zh, this message translates to:
  /// **'{total} 题里只标了 {tagged} 题'**
  String dxUntaggedEvidence(int total, int tagged);

  /// No description provided for @dxUntaggedAction.
  ///
  /// In zh, this message translates to:
  /// **'标错因是复盘唯一的杠杆：知识点没会、看错题、算错、时间不够，这四类的补法完全不同，不分开就只能整本重做。'**
  String get dxUntaggedAction;

  /// No description provided for @dxTrendUpTitle.
  ///
  /// In zh, this message translates to:
  /// **'近两周在往上走'**
  String get dxTrendUpTitle;

  /// No description provided for @dxTrendDownTitle.
  ///
  /// In zh, this message translates to:
  /// **'近两周反而掉了'**
  String get dxTrendDownTitle;

  /// No description provided for @dxTrendEvidence.
  ///
  /// In zh, this message translates to:
  /// **'近两周 {recent}，之前 {earlier}'**
  String dxTrendEvidence(String recent, String earlier);

  /// No description provided for @dxTrendUpAction.
  ///
  /// In zh, this message translates to:
  /// **'保持现在的练法别换。'**
  String get dxTrendUpAction;

  /// No description provided for @dxTrendDownAction.
  ///
  /// In zh, this message translates to:
  /// **'一般是两种原因：开始限时了，或者换到了更难的模块。先确认是哪一种，前者正常，后者要放慢。'**
  String get dxTrendDownAction;

  /// No description provided for @dxTailBlankTitle.
  ///
  /// In zh, this message translates to:
  /// **'资料分析没做完 —— 时间是在前面丢的'**
  String get dxTailBlankTitle;

  /// No description provided for @dxBlankTitle.
  ///
  /// In zh, this message translates to:
  /// **'有 {count} 题没作答'**
  String dxBlankTitle(int count);

  /// No description provided for @dxBlankWithTail.
  ///
  /// In zh, this message translates to:
  /// **'共空 {total} 题，其中资料分析空 {tail} 题'**
  String dxBlankWithTail(int total, int tail);

  /// No description provided for @dxBlankOnly.
  ///
  /// In zh, this message translates to:
  /// **'共空 {total} 题'**
  String dxBlankOnly(int total);

  /// No description provided for @dxTailBlankAction.
  ///
  /// In zh, this message translates to:
  /// **'资料分析是全卷唯一练到位就能拿满的模块，绝不能留给残余时间。下次把它提到判断推理之后做，数量关系放最后。'**
  String get dxTailBlankAction;

  /// No description provided for @dxBlankAction.
  ///
  /// In zh, this message translates to:
  /// **'空着的题也要涂 —— 统一涂同一个字母，四个选项的正确率都在 25% 上下。'**
  String get dxBlankAction;

  /// No description provided for @dxOvertimeTitle.
  ///
  /// In zh, this message translates to:
  /// **'整卷超时'**
  String get dxOvertimeTitle;

  /// No description provided for @dxOvertimeEvidence.
  ///
  /// In zh, this message translates to:
  /// **'实际 {actual} 分钟，按基准这些题应该 {budget} 分钟'**
  String dxOvertimeEvidence(int actual, int budget);

  /// No description provided for @dxOvertimeAction.
  ///
  /// In zh, this message translates to:
  /// **'超时通常集中在一两个模块，看上面哪一块的「慢」被标红了，先卡那一块的表。'**
  String get dxOvertimeAction;

  /// No description provided for @dxUnderTimeTitle.
  ///
  /// In zh, this message translates to:
  /// **'整卷节奏比基准快'**
  String get dxUnderTimeTitle;

  /// No description provided for @dxUnderTimeEvidence.
  ///
  /// In zh, this message translates to:
  /// **'实际 {actual} 分钟，基准 {budget} 分钟'**
  String dxUnderTimeEvidence(int actual, int budget);

  /// No description provided for @dxUnderTimeAction.
  ///
  /// In zh, this message translates to:
  /// **'如果正确率也达标，可以把省下的时间还给数量关系多挑两道。'**
  String get dxUnderTimeAction;

  /// No description provided for @dxNoRecords.
  ///
  /// In zh, this message translates to:
  /// **'还没有作答记录'**
  String get dxNoRecords;

  /// No description provided for @dxHeadlineClean.
  ///
  /// In zh, this message translates to:
  /// **'{count} 题，正确率 {rate}，没查出明显短板'**
  String dxHeadlineClean(int count, String rate);

  /// No description provided for @dxHeadlineWorst.
  ///
  /// In zh, this message translates to:
  /// **'{count} 题，正确率 {rate}；最该先修的是{what}'**
  String dxHeadlineWorst(int count, String rate, String what);

  /// No description provided for @dxPageTitle.
  ///
  /// In zh, this message translates to:
  /// **'弱点诊断'**
  String get dxPageTitle;

  /// No description provided for @dxEmptyTitle.
  ///
  /// In zh, this message translates to:
  /// **'还没有作答记录'**
  String get dxEmptyTitle;

  /// No description provided for @dxEmptyBody.
  ///
  /// In zh, this message translates to:
  /// **'做完一组题再回来 —— 诊断靠的是你自己的做题数据，不是别人的经验。'**
  String get dxEmptyBody;

  /// No description provided for @dxFootnote.
  ///
  /// In zh, this message translates to:
  /// **'基准来自 161 套真题（安徽 2023—2026、国考 2022—2026）逐题统计出的题量和结构；单题秒数是按这套题量倒推的建议值，跟「解题技巧」页上的是同一个数。'**
  String get dxFootnote;

  /// No description provided for @dxModuleTable.
  ///
  /// In zh, this message translates to:
  /// **'各模块 · 实测对基准'**
  String get dxModuleTable;

  /// No description provided for @dxColQuestions.
  ///
  /// In zh, this message translates to:
  /// **'题'**
  String get dxColQuestions;

  /// No description provided for @dxColAccuracy.
  ///
  /// In zh, this message translates to:
  /// **'正确率'**
  String get dxColAccuracy;

  /// No description provided for @dxColSeconds.
  ///
  /// In zh, this message translates to:
  /// **'秒/题'**
  String get dxColSeconds;

  /// No description provided for @dxColBench.
  ///
  /// In zh, this message translates to:
  /// **'基准'**
  String get dxColBench;

  /// No description provided for @dxFindings.
  ///
  /// In zh, this message translates to:
  /// **'结论'**
  String get dxFindings;

  /// No description provided for @dxFindingsCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 条'**
  String dxFindingsCount(int count);

  /// No description provided for @dxNoWeakSpot.
  ///
  /// In zh, this message translates to:
  /// **'各模块的速度和正确率都在基准附近，没有单独拎出来说的短板。继续按现在的练法走。'**
  String get dxNoWeakSpot;

  /// No description provided for @dxNoBenchmark.
  ///
  /// In zh, this message translates to:
  /// **'这个题库的分类对不上行测五模块，没有可比的基准 —— 上面的总题数和正确率仍然是你的真实数据，但\"每题该几秒、正确率该到多少\"这类结论给不了。'**
  String get dxNoBenchmark;

  /// No description provided for @dxLevelBad.
  ///
  /// In zh, this message translates to:
  /// **'要修'**
  String get dxLevelBad;

  /// No description provided for @dxLevelWatch.
  ///
  /// In zh, this message translates to:
  /// **'注意'**
  String get dxLevelWatch;

  /// No description provided for @dxLevelGood.
  ///
  /// In zh, this message translates to:
  /// **'不错'**
  String get dxLevelGood;

  /// No description provided for @dxAiSection.
  ///
  /// In zh, this message translates to:
  /// **'AI 深入分析'**
  String get dxAiSection;

  /// No description provided for @dxRegenerate.
  ///
  /// In zh, this message translates to:
  /// **'重新生成'**
  String get dxRegenerate;

  /// No description provided for @dxAiPitch.
  ///
  /// In zh, this message translates to:
  /// **'上面的结论是本机按真题基准算的，已经能直接用。AI 在这基础上再串一遍因果，并排一份一周训练计划。'**
  String get dxAiPitch;

  /// No description provided for @dxAiNotConfigured.
  ///
  /// In zh, this message translates to:
  /// **'还没配 AI。上面的结论不用配也能看 —— AI 只是在它之上多一层解读。'**
  String get dxAiNotConfigured;

  /// No description provided for @dxAskAi.
  ///
  /// In zh, this message translates to:
  /// **'让 AI 分析'**
  String get dxAskAi;

  /// No description provided for @dxConfigureAi.
  ///
  /// In zh, this message translates to:
  /// **'去配置 AI'**
  String get dxConfigureAi;
}

class _AppLDelegate extends LocalizationsDelegate<AppL> {
  const _AppLDelegate();

  @override
  Future<AppL> load(Locale locale) {
    return SynchronousFuture<AppL>(lookupAppL(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLDelegate old) => false;
}

AppL lookupAppL(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLEn();
    case 'zh':
      return AppLZh();
  }

  throw FlutterError(
    'AppL.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
