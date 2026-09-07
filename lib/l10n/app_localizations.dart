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

  /// No description provided for @dashTitle.
  ///
  /// In zh, this message translates to:
  /// **'备考档案'**
  String get dashTitle;

  /// No description provided for @dashByModule.
  ///
  /// In zh, this message translates to:
  /// **'模块能力'**
  String get dashByModule;

  /// No description provided for @dashByModuleHint.
  ///
  /// In zh, this message translates to:
  /// **'正确率由低到高'**
  String get dashByModuleHint;

  /// No description provided for @dashLast35.
  ///
  /// In zh, this message translates to:
  /// **'最近 35 天'**
  String get dashLast35;

  /// No description provided for @dashHeatHint.
  ///
  /// In zh, this message translates to:
  /// **'颜色越深练得越多'**
  String get dashHeatHint;

  /// No description provided for @dashTrend.
  ///
  /// In zh, this message translates to:
  /// **'成绩走势'**
  String get dashTrend;

  /// No description provided for @dashLastN.
  ///
  /// In zh, this message translates to:
  /// **'最近 {count} 次'**
  String dashLastN(int count);

  /// No description provided for @dashWhen.
  ///
  /// In zh, this message translates to:
  /// **'习惯时段'**
  String get dashWhen;

  /// No description provided for @dashWhenHint.
  ///
  /// In zh, this message translates to:
  /// **'一天里你在什么时候刷题'**
  String get dashWhenHint;

  /// No description provided for @dashAdvice.
  ///
  /// In zh, this message translates to:
  /// **'给你的建议'**
  String get dashAdvice;

  /// No description provided for @dashAdviceHint.
  ///
  /// In zh, this message translates to:
  /// **'按当前数据推断'**
  String get dashAdviceHint;

  /// No description provided for @dashEmpty.
  ///
  /// In zh, this message translates to:
  /// **'刷完第一组题，这一页就会有内容。'**
  String get dashEmpty;

  /// No description provided for @dashDataNote.
  ///
  /// In zh, this message translates to:
  /// **'数据只统计本机记录，清除练习记录后这一页会重新开始。'**
  String get dashDataNote;

  /// No description provided for @dashDoFirstSet.
  ///
  /// In zh, this message translates to:
  /// **'先刷一组 20 题'**
  String get dashDoFirstSet;

  /// No description provided for @dashDoFirstSetHint.
  ///
  /// In zh, this message translates to:
  /// **'有了记录才能算正确率、排弱项，这一页也才有东西可看。'**
  String get dashDoFirstSetHint;

  /// No description provided for @dashWeakest.
  ///
  /// In zh, this message translates to:
  /// **'{name}是当前短板'**
  String dashWeakest(String name);

  /// No description provided for @dashWeakestBody.
  ///
  /// In zh, this message translates to:
  /// **'正确率 {rate}%，已练 {done} 题。弱项强化会给它最大配额，先把这块拉到 70% 以上。'**
  String dashWeakestBody(int rate, int done);

  /// No description provided for @dashTopCareless.
  ///
  /// In zh, this message translates to:
  /// **'错题里\"粗心\"最多'**
  String get dashTopCareless;

  /// No description provided for @dashTopUnknown.
  ///
  /// In zh, this message translates to:
  /// **'错题里\"不会\"最多'**
  String get dashTopUnknown;

  /// No description provided for @dashTopMisread.
  ///
  /// In zh, this message translates to:
  /// **'错题里\"审题\"最多'**
  String get dashTopMisread;

  /// No description provided for @dashTopNoTime.
  ///
  /// In zh, this message translates to:
  /// **'错题里\"没时间\"最多'**
  String get dashTopNoTime;

  /// No description provided for @dashCarelessBody.
  ///
  /// In zh, this message translates to:
  /// **'{count} 道标了粗心。别加量，做完把答案带回题干核对一遍。'**
  String dashCarelessBody(int count);

  /// No description provided for @dashUnknownBody.
  ///
  /// In zh, this message translates to:
  /// **'{count} 道标了不会。先回去补方法，再刷同类题才有意义。'**
  String dashUnknownBody(int count);

  /// No description provided for @dashMisreadBody.
  ///
  /// In zh, this message translates to:
  /// **'{count} 道栽在审题。做题时把限定词和单位圈出来。'**
  String dashMisreadBody(int count);

  /// No description provided for @dashNoTimeBody.
  ///
  /// In zh, this message translates to:
  /// **'{count} 道是时间不够。先按模块限时练，再上整卷。'**
  String dashNoTimeBody(int count);

  /// No description provided for @dashGoTagged.
  ///
  /// In zh, this message translates to:
  /// **'去错题本按错因过一遍'**
  String get dashGoTagged;

  /// No description provided for @dashDropped.
  ///
  /// In zh, this message translates to:
  /// **'{name}这周退了 {points} 个点'**
  String dashDropped(String name, int points);

  /// No description provided for @dashDroppedBody.
  ///
  /// In zh, this message translates to:
  /// **'上一周 {before}%，最近 7 天 {now}%（{done} 题）。先别加量，去错题本按这个模块过一遍，看是同一类题反复错还是手生了。'**
  String dashDroppedBody(int before, int now, int done);

  /// No description provided for @dashSeeModuleWrong.
  ///
  /// In zh, this message translates to:
  /// **'看这个模块的错题'**
  String get dashSeeModuleWrong;

  /// No description provided for @dashRose.
  ///
  /// In zh, this message translates to:
  /// **'{name}这周涨了 {points} 个点'**
  String dashRose(String name, int points);

  /// No description provided for @dashRoseBody.
  ///
  /// In zh, this message translates to:
  /// **'上一周 {before}%，最近 7 天 {now}%（{done} 题）。这块的练法是对的，可以开始压时间了。'**
  String dashRoseBody(int before, int now, int done);

  /// No description provided for @dashSlow.
  ///
  /// In zh, this message translates to:
  /// **'{name}花的时间偏长'**
  String dashSlow(String name);

  /// No description provided for @dashSlowBody.
  ///
  /// In zh, this message translates to:
  /// **'平均每题 {secs} 秒。行测里超过 90 秒的题在考场上应该先跳过，练的时候也要按这个标准掐表。'**
  String dashSlowBody(int secs);

  /// No description provided for @dashTimeThisModule.
  ///
  /// In zh, this message translates to:
  /// **'限时练这个模块'**
  String get dashTimeThisModule;

  /// No description provided for @dashStreakBroken.
  ///
  /// In zh, this message translates to:
  /// **'连续打卡断了'**
  String get dashStreakBroken;

  /// No description provided for @dashStreakBrokenBody.
  ///
  /// In zh, this message translates to:
  /// **'每天 10 题也算数，节奏比单次量更重要。'**
  String get dashStreakBrokenBody;

  /// No description provided for @dashStreakDays.
  ///
  /// In zh, this message translates to:
  /// **'已经连续 {days} 天'**
  String dashStreakDays(int days);

  /// No description provided for @dashStreakBody.
  ///
  /// In zh, this message translates to:
  /// **'保持住。真正拉开差距的是能不能天天回来，而不是某天刷了 200 题。'**
  String get dashStreakBody;

  /// No description provided for @dashAllSteady.
  ///
  /// In zh, this message translates to:
  /// **'各项都挺稳'**
  String get dashAllSteady;

  /// No description provided for @dashAllSteadyBody.
  ///
  /// In zh, this message translates to:
  /// **'可以开始按整卷限时练，把速度也压进考试节奏。'**
  String get dashAllSteadyBody;

  /// No description provided for @dashDaysLine.
  ///
  /// In zh, this message translates to:
  /// **'练过 {days} 天 · 连续 {streak} 天'**
  String dashDaysLine(int days, int streak);

  /// No description provided for @unitDays.
  ///
  /// In zh, this message translates to:
  /// **'天'**
  String get unitDays;

  /// No description provided for @dashToExam.
  ///
  /// In zh, this message translates to:
  /// **'距考试'**
  String get dashToExam;

  /// No description provided for @dashOverallRate.
  ///
  /// In zh, this message translates to:
  /// **'总正确率'**
  String get dashOverallRate;

  /// No description provided for @dashTotalAnswered.
  ///
  /// In zh, this message translates to:
  /// **'累计答题'**
  String get dashTotalAnswered;

  /// No description provided for @dashWrongLeft.
  ///
  /// In zh, this message translates to:
  /// **'待清错题'**
  String get dashWrongLeft;

  /// No description provided for @dashToday.
  ///
  /// In zh, this message translates to:
  /// **'今日进度'**
  String get dashToday;

  /// No description provided for @dashPacePerQ.
  ///
  /// In zh, this message translates to:
  /// **'{secs}s/题'**
  String dashPacePerQ(int secs);

  /// No description provided for @dashLess.
  ///
  /// In zh, this message translates to:
  /// **'少'**
  String get dashLess;

  /// No description provided for @dashMore.
  ///
  /// In zh, this message translates to:
  /// **'多'**
  String get dashMore;

  /// No description provided for @dashHeatToday.
  ///
  /// In zh, this message translates to:
  /// **'右下角为今天'**
  String get dashHeatToday;

  /// No description provided for @dashFlat.
  ///
  /// In zh, this message translates to:
  /// **'最近一次 {rate}%，和最早那次持平'**
  String dashFlat(int rate);

  /// No description provided for @dashUp.
  ///
  /// In zh, this message translates to:
  /// **'从 {from}% 到 {to}%，涨了 {points} 个点'**
  String dashUp(int from, int to, int points);

  /// No description provided for @dashDown.
  ///
  /// In zh, this message translates to:
  /// **'从 {from}% 到 {to}%，掉了 {points} 个点'**
  String dashDown(int from, int to, int points);

  /// No description provided for @dashHour0.
  ///
  /// In zh, this message translates to:
  /// **'0 点'**
  String get dashHour0;

  /// No description provided for @dashPeakHour.
  ///
  /// In zh, this message translates to:
  /// **'最常在 {hour} 点前后刷题'**
  String dashPeakHour(int hour);

  /// No description provided for @dashHour23.
  ///
  /// In zh, this message translates to:
  /// **'23 点'**
  String get dashHour23;

  /// No description provided for @dashPractiseNow.
  ///
  /// In zh, this message translates to:
  /// **'现在就练'**
  String get dashPractiseNow;

  /// No description provided for @bankTab.
  ///
  /// In zh, this message translates to:
  /// **'题库'**
  String get bankTab;

  /// No description provided for @bankPapers.
  ///
  /// In zh, this message translates to:
  /// **'试卷'**
  String get bankPapers;

  /// No description provided for @bankAllRegions.
  ///
  /// In zh, this message translates to:
  /// **'全部地区'**
  String get bankAllRegions;

  /// No description provided for @bankAllYears.
  ///
  /// In zh, this message translates to:
  /// **'全部年份'**
  String get bankAllYears;

  /// No description provided for @bankNoYear.
  ///
  /// In zh, this message translates to:
  /// **'未标注'**
  String get bankNoYear;

  /// No description provided for @bankYear.
  ///
  /// In zh, this message translates to:
  /// **'{year} 年'**
  String bankYear(String year);

  /// No description provided for @bankAllStatus.
  ///
  /// In zh, this message translates to:
  /// **'全部状态'**
  String get bankAllStatus;

  /// No description provided for @bankNotStarted.
  ///
  /// In zh, this message translates to:
  /// **'未开始'**
  String get bankNotStarted;

  /// No description provided for @bankInProgress.
  ///
  /// In zh, this message translates to:
  /// **'进行中'**
  String get bankInProgress;

  /// No description provided for @bankFinished.
  ///
  /// In zh, this message translates to:
  /// **'已做完'**
  String get bankFinished;

  /// No description provided for @bankPaperCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 套真题卷'**
  String bankPaperCount(int count);

  /// No description provided for @bankMatchedCount.
  ///
  /// In zh, this message translates to:
  /// **'{matched} / {total} 套'**
  String bankMatchedCount(int matched, int total);

  /// No description provided for @bankSearchHint.
  ///
  /// In zh, this message translates to:
  /// **'搜索年份、省份、卷名'**
  String get bankSearchHint;

  /// No description provided for @bankFilterYear.
  ///
  /// In zh, this message translates to:
  /// **'年份'**
  String get bankFilterYear;

  /// No description provided for @bankFilterStatus.
  ///
  /// In zh, this message translates to:
  /// **'状态'**
  String get bankFilterStatus;

  /// No description provided for @bankSort.
  ///
  /// In zh, this message translates to:
  /// **'排序'**
  String get bankSort;

  /// No description provided for @bankSortYear.
  ///
  /// In zh, this message translates to:
  /// **'按年份（新→旧）'**
  String get bankSortYear;

  /// No description provided for @bankSortProgress.
  ///
  /// In zh, this message translates to:
  /// **'按完成度'**
  String get bankSortProgress;

  /// No description provided for @bankSortSize.
  ///
  /// In zh, this message translates to:
  /// **'按题量'**
  String get bankSortSize;

  /// No description provided for @bankNoPapers.
  ///
  /// In zh, this message translates to:
  /// **'还没有试卷'**
  String get bankNoPapers;

  /// No description provided for @bankNoMatch.
  ///
  /// In zh, this message translates to:
  /// **'没有匹配的试卷'**
  String get bankNoMatch;

  /// No description provided for @bankNoPapersHint.
  ///
  /// In zh, this message translates to:
  /// **'到「我的 → 导入题目」导入后，整套试卷会出现在这里。'**
  String get bankNoPapersHint;

  /// No description provided for @bankNoMatchHint.
  ///
  /// In zh, this message translates to:
  /// **'换个关键词试试，比如 2025、江苏、国考。'**
  String get bankNoMatchHint;

  /// No description provided for @bankUndatedGroup.
  ///
  /// In zh, this message translates to:
  /// **'未标注年份'**
  String get bankUndatedGroup;

  /// No description provided for @bankPaperCountShort.
  ///
  /// In zh, this message translates to:
  /// **'{count} 套'**
  String bankPaperCountShort(int count);

  /// No description provided for @bankPickPaper.
  ///
  /// In zh, this message translates to:
  /// **'选一张卷'**
  String get bankPickPaper;

  /// No description provided for @bankPickPaperHint.
  ///
  /// In zh, this message translates to:
  /// **'左边挑一张。'**
  String get bankPickPaperHint;

  /// No description provided for @bankUntitledPaper.
  ///
  /// In zh, this message translates to:
  /// **'未命名试卷'**
  String get bankUntitledPaper;

  /// No description provided for @bankPaperProgress.
  ///
  /// In zh, this message translates to:
  /// **'{done} / {total} 题'**
  String bankPaperProgress(int done, int total);

  /// No description provided for @bankImport.
  ///
  /// In zh, this message translates to:
  /// **'导入'**
  String get bankImport;

  /// No description provided for @badgeFirstBloodName.
  ///
  /// In zh, this message translates to:
  /// **'开张'**
  String get badgeFirstBloodName;

  /// No description provided for @badgeFirstBloodDesc.
  ///
  /// In zh, this message translates to:
  /// **'完成第一道题'**
  String get badgeFirstBloodDesc;

  /// No description provided for @badgeAnswers100Name.
  ///
  /// In zh, this message translates to:
  /// **'百题'**
  String get badgeAnswers100Name;

  /// No description provided for @badgeAnswers100Desc.
  ///
  /// In zh, this message translates to:
  /// **'累计答题 100 道'**
  String get badgeAnswers100Desc;

  /// No description provided for @badgeAnswers500Name.
  ///
  /// In zh, this message translates to:
  /// **'五百题'**
  String get badgeAnswers500Name;

  /// No description provided for @badgeAnswers500Desc.
  ///
  /// In zh, this message translates to:
  /// **'累计答题 500 道'**
  String get badgeAnswers500Desc;

  /// No description provided for @badgeAnswers2000Name.
  ///
  /// In zh, this message translates to:
  /// **'两千题'**
  String get badgeAnswers2000Name;

  /// No description provided for @badgeAnswers2000Desc.
  ///
  /// In zh, this message translates to:
  /// **'累计答题 2000 道'**
  String get badgeAnswers2000Desc;

  /// No description provided for @badgeStreak3Name.
  ///
  /// In zh, this message translates to:
  /// **'三天'**
  String get badgeStreak3Name;

  /// No description provided for @badgeStreak3Desc.
  ///
  /// In zh, this message translates to:
  /// **'连续练习 3 天'**
  String get badgeStreak3Desc;

  /// No description provided for @badgeStreak7Name.
  ///
  /// In zh, this message translates to:
  /// **'一周不断'**
  String get badgeStreak7Name;

  /// No description provided for @badgeStreak7Desc.
  ///
  /// In zh, this message translates to:
  /// **'连续练习 7 天'**
  String get badgeStreak7Desc;

  /// No description provided for @badgeStreak30Name.
  ///
  /// In zh, this message translates to:
  /// **'一月不断'**
  String get badgeStreak30Name;

  /// No description provided for @badgeStreak30Desc.
  ///
  /// In zh, this message translates to:
  /// **'连续练习 30 天'**
  String get badgeStreak30Desc;

  /// No description provided for @badgeActive20Name.
  ///
  /// In zh, this message translates to:
  /// **'常客'**
  String get badgeActive20Name;

  /// No description provided for @badgeActive20Desc.
  ///
  /// In zh, this message translates to:
  /// **'累计练习 20 天'**
  String get badgeActive20Desc;

  /// No description provided for @badgeRate70Name.
  ///
  /// In zh, this message translates to:
  /// **'及格线'**
  String get badgeRate70Name;

  /// No description provided for @badgeRate70Desc.
  ///
  /// In zh, this message translates to:
  /// **'总正确率达到 70%（至少 50 题）'**
  String get badgeRate70Desc;

  /// No description provided for @badgeRate85Name.
  ///
  /// In zh, this message translates to:
  /// **'稳'**
  String get badgeRate85Name;

  /// No description provided for @badgeRate85Desc.
  ///
  /// In zh, this message translates to:
  /// **'总正确率达到 85%（至少 200 题）'**
  String get badgeRate85Desc;

  /// No description provided for @badgeStrong3Name.
  ///
  /// In zh, this message translates to:
  /// **'三科过硬'**
  String get badgeStrong3Name;

  /// No description provided for @badgeStrong3Desc.
  ///
  /// In zh, this message translates to:
  /// **'三个模块正确率达到 80%（每个至少 20 题）'**
  String get badgeStrong3Desc;

  /// No description provided for @badgeExam1Name.
  ///
  /// In zh, this message translates to:
  /// **'首战'**
  String get badgeExam1Name;

  /// No description provided for @badgeExam1Desc.
  ///
  /// In zh, this message translates to:
  /// **'完成第一次限时模考'**
  String get badgeExam1Desc;

  /// No description provided for @badgeExam10Name.
  ///
  /// In zh, this message translates to:
  /// **'身经十战'**
  String get badgeExam10Name;

  /// No description provided for @badgeExam10Desc.
  ///
  /// In zh, this message translates to:
  /// **'完成 10 次限时模考'**
  String get badgeExam10Desc;

  /// No description provided for @badgeExam80Name.
  ///
  /// In zh, this message translates to:
  /// **'高分卷'**
  String get badgeExam80Name;

  /// No description provided for @badgeExam80Desc.
  ///
  /// In zh, this message translates to:
  /// **'任意一次模考正确率达到 80%'**
  String get badgeExam80Desc;

  /// No description provided for @badgeCleanWrongName.
  ///
  /// In zh, this message translates to:
  /// **'清空错题'**
  String get badgeCleanWrongName;

  /// No description provided for @badgeCleanWrongDesc.
  ///
  /// In zh, this message translates to:
  /// **'把错题本清到 0（至少错过 20 题）'**
  String get badgeCleanWrongDesc;

  /// No description provided for @badgeDay100Name.
  ///
  /// In zh, this message translates to:
  /// **'单日百题'**
  String get badgeDay100Name;

  /// No description provided for @badgeDay100Desc.
  ///
  /// In zh, this message translates to:
  /// **'一天内做满 100 题'**
  String get badgeDay100Desc;

  /// No description provided for @badgeNotes20Name.
  ///
  /// In zh, this message translates to:
  /// **'会总结'**
  String get badgeNotes20Name;

  /// No description provided for @badgeNotes20Desc.
  ///
  /// In zh, this message translates to:
  /// **'写下 20 条题目笔记'**
  String get badgeNotes20Desc;

  /// No description provided for @badgeMarks30Name.
  ///
  /// In zh, this message translates to:
  /// **'会收集'**
  String get badgeMarks30Name;

  /// No description provided for @badgeMarks30Desc.
  ///
  /// In zh, this message translates to:
  /// **'收藏 30 道题'**
  String get badgeMarks30Desc;

  /// No description provided for @badgeGroupVolume.
  ///
  /// In zh, this message translates to:
  /// **'题量'**
  String get badgeGroupVolume;

  /// No description provided for @badgeGroupConsistency.
  ///
  /// In zh, this message translates to:
  /// **'坚持'**
  String get badgeGroupConsistency;

  /// No description provided for @badgeGroupAccuracy.
  ///
  /// In zh, this message translates to:
  /// **'精度'**
  String get badgeGroupAccuracy;

  /// No description provided for @badgeGroupExams.
  ///
  /// In zh, this message translates to:
  /// **'考场'**
  String get badgeGroupExams;

  /// No description provided for @badgeGroupGrind.
  ///
  /// In zh, this message translates to:
  /// **'攻坚'**
  String get badgeGroupGrind;

  /// No description provided for @tierBronze.
  ///
  /// In zh, this message translates to:
  /// **'铜'**
  String get tierBronze;

  /// No description provided for @tierSilver.
  ///
  /// In zh, this message translates to:
  /// **'银'**
  String get tierSilver;

  /// No description provided for @tierGold.
  ///
  /// In zh, this message translates to:
  /// **'金'**
  String get tierGold;

  /// No description provided for @tierPlatinum.
  ///
  /// In zh, this message translates to:
  /// **'铂金'**
  String get tierPlatinum;

  /// No description provided for @badgesTitle.
  ///
  /// In zh, this message translates to:
  /// **'成就'**
  String get badgesTitle;

  /// No description provided for @badgesUnlocked.
  ///
  /// In zh, this message translates to:
  /// **'已解锁 {done} / {total}'**
  String badgesUnlocked(int done, int total);

  /// No description provided for @badgesNote.
  ///
  /// In zh, this message translates to:
  /// **'全部按本机数据计算，清除练习记录会重新开始'**
  String get badgesNote;

  /// No description provided for @badgesEarned.
  ///
  /// In zh, this message translates to:
  /// **'已达成'**
  String get badgesEarned;

  /// No description provided for @badgesToGo.
  ///
  /// In zh, this message translates to:
  /// **' · 还差 {count}'**
  String badgesToGo(int count);

  /// No description provided for @badgesUnlockedTitle.
  ///
  /// In zh, this message translates to:
  /// **'解锁成就'**
  String get badgesUnlockedTitle;

  /// No description provided for @badgesAlsoUnlocked.
  ///
  /// In zh, this message translates to:
  /// **'同时还解锁了 {count} 个'**
  String badgesAlsoUnlocked(int count);

  /// No description provided for @badgesTake.
  ///
  /// In zh, this message translates to:
  /// **'收下'**
  String get badgesTake;

  /// No description provided for @badgesEarnedOn.
  ///
  /// In zh, this message translates to:
  /// **'{date}获得'**
  String badgesEarnedOn(String date);

  /// No description provided for @planCatPractice.
  ///
  /// In zh, this message translates to:
  /// **'{name}练习'**
  String planCatPractice(String name);

  /// No description provided for @planDeleteSet.
  ///
  /// In zh, this message translates to:
  /// **'删除计划'**
  String get planDeleteSet;

  /// No description provided for @planDeleteSetBody.
  ///
  /// In zh, this message translates to:
  /// **'「{name}」和里面的 {count} 条任务都会删掉，已打的勾不受影响。'**
  String planDeleteSetBody(String name, int count);

  /// No description provided for @planDeleteTask.
  ///
  /// In zh, this message translates to:
  /// **'删除安排'**
  String get planDeleteTask;

  /// No description provided for @planRepeatNote.
  ///
  /// In zh, this message translates to:
  /// **'「{title}」是{rule}的任务。'**
  String planRepeatNote(String title, String rule);

  /// No description provided for @planSkipToday.
  ///
  /// In zh, this message translates to:
  /// **'今天先跳过'**
  String get planSkipToday;

  /// No description provided for @planDeleteForever.
  ///
  /// In zh, this message translates to:
  /// **'以后都删'**
  String get planDeleteForever;

  /// No description provided for @planTitle.
  ///
  /// In zh, this message translates to:
  /// **'复习计划'**
  String get planTitle;

  /// No description provided for @planStreak.
  ///
  /// In zh, this message translates to:
  /// **'计划连签 {days} 天 · 勾完当天清单算一天'**
  String planStreak(int days);

  /// No description provided for @planIntro.
  ///
  /// In zh, this message translates to:
  /// **'选好模板后，每天按清单练；可再加自己的任务'**
  String get planIntro;

  /// No description provided for @planMonth.
  ///
  /// In zh, this message translates to:
  /// **'{n}月'**
  String planMonth(int n);

  /// No description provided for @planSwipeHint.
  ///
  /// In zh, this message translates to:
  /// **'左右滑动看更多天'**
  String get planSwipeHint;

  /// No description provided for @planBackToToday.
  ///
  /// In zh, this message translates to:
  /// **'回到今天'**
  String get planBackToToday;

  /// No description provided for @planNothingToday.
  ///
  /// In zh, this message translates to:
  /// **'这天还没有安排'**
  String get planNothingToday;

  /// No description provided for @planAddHint.
  ///
  /// In zh, this message translates to:
  /// **'加一条，或从范例开一份'**
  String get planAddHint;

  /// No description provided for @planAdd.
  ///
  /// In zh, this message translates to:
  /// **'加安排'**
  String get planAdd;

  /// No description provided for @planToday.
  ///
  /// In zh, this message translates to:
  /// **'今日安排'**
  String get planToday;

  /// No description provided for @planManage.
  ///
  /// In zh, this message translates to:
  /// **'管理'**
  String get planManage;

  /// No description provided for @planAddTitle.
  ///
  /// In zh, this message translates to:
  /// **'添加安排'**
  String get planAddTitle;

  /// No description provided for @planMine.
  ///
  /// In zh, this message translates to:
  /// **'我的计划'**
  String get planMine;

  /// No description provided for @planOff.
  ///
  /// In zh, this message translates to:
  /// **'未启用'**
  String get planOff;

  /// No description provided for @planPick.
  ///
  /// In zh, this message translates to:
  /// **'选计划'**
  String get planPick;

  /// No description provided for @planTodayMark.
  ///
  /// In zh, this message translates to:
  /// **'今'**
  String get planTodayMark;

  /// No description provided for @commonNew.
  ///
  /// In zh, this message translates to:
  /// **'新建'**
  String get commonNew;

  /// No description provided for @planClosed.
  ///
  /// In zh, this message translates to:
  /// **'计划已关闭'**
  String get planClosed;

  /// No description provided for @planClose.
  ///
  /// In zh, this message translates to:
  /// **'关闭计划'**
  String get planClose;

  /// No description provided for @planClosedHint.
  ///
  /// In zh, this message translates to:
  /// **'计划已关闭，点下面任意一份重新用起来'**
  String get planClosedHint;

  /// No description provided for @planNone.
  ///
  /// In zh, this message translates to:
  /// **'还没有计划，点右上角 ＋ 建一份'**
  String get planNone;

  /// No description provided for @planItemCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 条'**
  String planItemCount(int count);

  /// No description provided for @planNewTitle.
  ///
  /// In zh, this message translates to:
  /// **'新建计划'**
  String get planNewTitle;

  /// No description provided for @planCreate.
  ///
  /// In zh, this message translates to:
  /// **'建好'**
  String get planCreate;

  /// No description provided for @planName.
  ///
  /// In zh, this message translates to:
  /// **'名字'**
  String get planName;

  /// No description provided for @planNameHint.
  ///
  /// In zh, this message translates to:
  /// **'例如 考前冲刺'**
  String get planNameHint;

  /// No description provided for @planStartFrom.
  ///
  /// In zh, this message translates to:
  /// **'从哪儿开始'**
  String get planStartFrom;

  /// No description provided for @planBlank.
  ///
  /// In zh, this message translates to:
  /// **'空白'**
  String get planBlank;

  /// No description provided for @planBlankHint.
  ///
  /// In zh, this message translates to:
  /// **'自己一条条加'**
  String get planBlankHint;

  /// No description provided for @planTemplateHint.
  ///
  /// In zh, this message translates to:
  /// **'范例只是抄一份过来，每条都能改能删'**
  String get planTemplateHint;

  /// No description provided for @taskCatPractice.
  ///
  /// In zh, this message translates to:
  /// **'题型练习'**
  String get taskCatPractice;

  /// No description provided for @taskManual.
  ///
  /// In zh, this message translates to:
  /// **'备忘 / 手写'**
  String get taskManual;

  /// No description provided for @taskVocab.
  ///
  /// In zh, this message translates to:
  /// **'背词语'**
  String get taskVocab;

  /// No description provided for @taskCheckin.
  ///
  /// In zh, this message translates to:
  /// **'打卡'**
  String get taskCheckin;

  /// No description provided for @taskOpenWrong.
  ///
  /// In zh, this message translates to:
  /// **'打开错题本'**
  String get taskOpenWrong;

  /// No description provided for @taskCatPracticeHint.
  ///
  /// In zh, this message translates to:
  /// **'按题型抽题练习'**
  String get taskCatPracticeHint;

  /// No description provided for @taskMockHint.
  ///
  /// In zh, this message translates to:
  /// **'50 题 · 可设定分钟'**
  String get taskMockHint;

  /// No description provided for @taskWrongHint.
  ///
  /// In zh, this message translates to:
  /// **'从错题里抽练'**
  String get taskWrongHint;

  /// No description provided for @taskWeakHint.
  ///
  /// In zh, this message translates to:
  /// **'按薄弱模块抽题'**
  String get taskWeakHint;

  /// No description provided for @taskManualHint.
  ///
  /// In zh, this message translates to:
  /// **'勾选完成即可，不自动开练'**
  String get taskManualHint;

  /// No description provided for @taskVocabHint.
  ///
  /// In zh, this message translates to:
  /// **'今天到期的成语和易错词'**
  String get taskVocabHint;

  /// No description provided for @taskCheckinHint.
  ///
  /// In zh, this message translates to:
  /// **'做完打个勾，不跳任何页面'**
  String get taskCheckinHint;

  /// No description provided for @taskOpenWrongHint.
  ///
  /// In zh, this message translates to:
  /// **'跳到错题本整理'**
  String get taskOpenWrongHint;

  /// No description provided for @taskUntitled.
  ///
  /// In zh, this message translates to:
  /// **'未命名任务'**
  String get taskUntitled;

  /// No description provided for @taskEdit.
  ///
  /// In zh, this message translates to:
  /// **'任务安排'**
  String get taskEdit;

  /// No description provided for @taskWhat.
  ///
  /// In zh, this message translates to:
  /// **'做什么'**
  String get taskWhat;

  /// No description provided for @taskWhatHint.
  ///
  /// In zh, this message translates to:
  /// **'例如 背 20 个成语'**
  String get taskWhatHint;

  /// No description provided for @taskHowOften.
  ///
  /// In zh, this message translates to:
  /// **'多久做一次'**
  String get taskHowOften;

  /// No description provided for @taskOnceOnly.
  ///
  /// In zh, this message translates to:
  /// **'只出现在这一天'**
  String get taskOnceOnly;

  /// No description provided for @taskEditForever.
  ///
  /// In zh, this message translates to:
  /// **'改这条任务，往后每次都跟着变'**
  String get taskEditForever;

  /// No description provided for @taskAlsoPractise.
  ///
  /// In zh, this message translates to:
  /// **'顺便练题'**
  String get taskAlsoPractise;

  /// No description provided for @taskAlsoPractiseHint.
  ///
  /// In zh, this message translates to:
  /// **'勾完就算，不用设也行'**
  String get taskAlsoPractiseHint;

  /// No description provided for @taskType.
  ///
  /// In zh, this message translates to:
  /// **'题型'**
  String get taskType;

  /// No description provided for @taskCount.
  ///
  /// In zh, this message translates to:
  /// **'题量'**
  String get taskCount;

  /// No description provided for @taskNote.
  ///
  /// In zh, this message translates to:
  /// **'备注（可选）'**
  String get taskNote;

  /// No description provided for @taskMinutes.
  ///
  /// In zh, this message translates to:
  /// **'限时（分钟，可选）'**
  String get taskMinutes;

  /// No description provided for @taskSoftLimit.
  ///
  /// In zh, this message translates to:
  /// **'按题量软限时'**
  String get taskSoftLimit;

  /// No description provided for @taskSoftLimitHint.
  ///
  /// In zh, this message translates to:
  /// **'未填分钟时，按题量估算时长'**
  String get taskSoftLimitHint;

  /// No description provided for @taskDelete.
  ///
  /// In zh, this message translates to:
  /// **'删除此安排'**
  String get taskDelete;

  /// No description provided for @taskTapHint.
  ///
  /// In zh, this message translates to:
  /// **'点「开始」才会进入练习；点这一行只改安排，避免误触。'**
  String get taskTapHint;

  /// No description provided for @taskEditTitle.
  ///
  /// In zh, this message translates to:
  /// **'编辑安排'**
  String get taskEditTitle;

  /// No description provided for @commonRename.
  ///
  /// In zh, this message translates to:
  /// **'重命名'**
  String get commonRename;

  /// No description provided for @repeatOnce.
  ///
  /// In zh, this message translates to:
  /// **'只这一次'**
  String get repeatOnce;

  /// No description provided for @repeatDaily.
  ///
  /// In zh, this message translates to:
  /// **'每天'**
  String get repeatDaily;

  /// No description provided for @repeatWeekdays.
  ///
  /// In zh, this message translates to:
  /// **'工作日'**
  String get repeatWeekdays;

  /// No description provided for @repeatWeekly.
  ///
  /// In zh, this message translates to:
  /// **'每周这天'**
  String get repeatWeekly;

  /// No description provided for @repeatEveryOther.
  ///
  /// In zh, this message translates to:
  /// **'隔一天'**
  String get repeatEveryOther;

  /// No description provided for @cmExported.
  ///
  /// In zh, this message translates to:
  /// **'已导出 {count} 道题'**
  String cmExported(int count);

  /// No description provided for @cmClearBank.
  ///
  /// In zh, this message translates to:
  /// **'清空题库'**
  String get cmClearBank;

  /// No description provided for @cmClearBody.
  ///
  /// In zh, this message translates to:
  /// **'删掉全部 {count} 道题。'**
  String cmClearBody(int count);

  /// No description provided for @cmClearNote.
  ///
  /// In zh, this message translates to:
  /// **'做题记录、错题本、笔记不会删 —— 重新导入同一批题还能对上。\\n\\n这一步不可撤销，建议先导出。'**
  String get cmClearNote;

  /// No description provided for @cmClear.
  ///
  /// In zh, this message translates to:
  /// **'清空'**
  String get cmClear;

  /// No description provided for @cmCleared.
  ///
  /// In zh, this message translates to:
  /// **'已清空 {count} 道题'**
  String cmCleared(int count);

  /// No description provided for @cmMerge.
  ///
  /// In zh, this message translates to:
  /// **'合并分类'**
  String get cmMerge;

  /// No description provided for @cmMergeBody.
  ///
  /// In zh, this message translates to:
  /// **'「{from}」的 {count} 道题会并进「{to}」。'**
  String cmMergeBody(int count, String from, String to);

  /// No description provided for @cmMergeNote.
  ///
  /// In zh, this message translates to:
  /// **'这一步不可撤销，但题本身不会丢。'**
  String get cmMergeNote;

  /// No description provided for @cmMergeConfirm.
  ///
  /// In zh, this message translates to:
  /// **'合并'**
  String get cmMergeConfirm;

  /// No description provided for @cmMerged.
  ///
  /// In zh, this message translates to:
  /// **'已并入「{name}」'**
  String cmMerged(String name);

  /// No description provided for @cmRenamed.
  ///
  /// In zh, this message translates to:
  /// **'已改名'**
  String get cmRenamed;

  /// No description provided for @cmNeedAiKey.
  ///
  /// In zh, this message translates to:
  /// **'先去「我的 → AI 设置」配一个 key'**
  String get cmNeedAiKey;

  /// No description provided for @cmUncategorised.
  ///
  /// In zh, this message translates to:
  /// **'未分类'**
  String get cmUncategorised;

  /// No description provided for @cmNoTargets.
  ///
  /// In zh, this message translates to:
  /// **'还没有别的分类可归，先手动建几个'**
  String get cmNoTargets;

  /// No description provided for @cmAiSort.
  ///
  /// In zh, this message translates to:
  /// **'AI 重新分类'**
  String get cmAiSort;

  /// No description provided for @cmAiSortBody.
  ///
  /// In zh, this message translates to:
  /// **'把「{name}」里的题按现有分类重新归一遍。'**
  String cmAiSortBody(String name);

  /// No description provided for @cmAiSortNote.
  ///
  /// In zh, this message translates to:
  /// **'AI 只会在你已有的 {count} 个分类里选，不会新造。'**
  String cmAiSortNote(int count);

  /// No description provided for @cmReading.
  ///
  /// In zh, this message translates to:
  /// **'读题…'**
  String get cmReading;

  /// No description provided for @cmAiSortFailed.
  ///
  /// In zh, this message translates to:
  /// **'AI 没能归出结果，可以手动改'**
  String get cmAiSortFailed;

  /// No description provided for @cmAiSorted.
  ///
  /// In zh, this message translates to:
  /// **'归好了 {count} 道'**
  String cmAiSorted(int count);

  /// No description provided for @cmTitle.
  ///
  /// In zh, this message translates to:
  /// **'题库管理'**
  String get cmTitle;

  /// No description provided for @cmRenameHint.
  ///
  /// In zh, this message translates to:
  /// **'改名就是改名；改成已有的名字就是把两类并成一类。题一道都不会丢。'**
  String get cmRenameHint;

  /// No description provided for @cmEmptyTitle.
  ///
  /// In zh, this message translates to:
  /// **'题库还是空的'**
  String get cmEmptyTitle;

  /// No description provided for @cmEmptyBody.
  ///
  /// In zh, this message translates to:
  /// **'导入题目之后，分类会出现在这里。'**
  String get cmEmptyBody;

  /// No description provided for @cmRenameMerge.
  ///
  /// In zh, this message translates to:
  /// **'改名 / 合并'**
  String get cmRenameMerge;

  /// No description provided for @cmMergeInto.
  ///
  /// In zh, this message translates to:
  /// **'并进已有的：'**
  String get cmMergeInto;

  /// No description provided for @wrongMissedTimes.
  ///
  /// In zh, this message translates to:
  /// **'{name} · 错过 {count} 次'**
  String wrongMissedTimes(String name, int count);

  /// No description provided for @wrongPlanStarted.
  ///
  /// In zh, this message translates to:
  /// **'已开始「{name}」四天计划'**
  String wrongPlanStarted(String name);

  /// No description provided for @wrongPlanDay.
  ///
  /// In zh, this message translates to:
  /// **'{name} · 第 {day} 天'**
  String wrongPlanDay(String name, int day);

  /// No description provided for @wrongPickRedo.
  ///
  /// In zh, this message translates to:
  /// **'挑 {count} 题重做'**
  String wrongPickRedo(int count);

  /// No description provided for @wrongNone.
  ///
  /// In zh, this message translates to:
  /// **'还没有错题'**
  String get wrongNone;

  /// No description provided for @wrongNoneHint.
  ///
  /// In zh, this message translates to:
  /// **'去练习页刷一组，答错的题会自动进入这里，答对后自动移出。'**
  String get wrongNoneHint;

  /// No description provided for @wrongFilterType.
  ///
  /// In zh, this message translates to:
  /// **'题型'**
  String get wrongFilterType;

  /// No description provided for @wrongAllTypes.
  ///
  /// In zh, this message translates to:
  /// **'全部题型'**
  String get wrongAllTypes;

  /// No description provided for @wrongFilterReason.
  ///
  /// In zh, this message translates to:
  /// **'错因'**
  String get wrongFilterReason;

  /// No description provided for @wrongAllReasons.
  ///
  /// In zh, this message translates to:
  /// **'全部错因'**
  String get wrongAllReasons;

  /// No description provided for @wrongFilterPaper.
  ///
  /// In zh, this message translates to:
  /// **'来源卷'**
  String get wrongFilterPaper;

  /// No description provided for @wrongAllPapers.
  ///
  /// In zh, this message translates to:
  /// **'全部试卷'**
  String get wrongAllPapers;

  /// No description provided for @wrongFilterLevel.
  ///
  /// In zh, this message translates to:
  /// **'难度'**
  String get wrongFilterLevel;

  /// No description provided for @wrongAllLevels.
  ///
  /// In zh, this message translates to:
  /// **'全部难度'**
  String get wrongAllLevels;

  /// No description provided for @wrongLevelHard.
  ///
  /// In zh, this message translates to:
  /// **'我标了难'**
  String get wrongLevelHard;

  /// No description provided for @wrongLevelNone.
  ///
  /// In zh, this message translates to:
  /// **'没标过'**
  String get wrongLevelNone;

  /// No description provided for @wrongSort.
  ///
  /// In zh, this message translates to:
  /// **'排序'**
  String get wrongSort;

  /// No description provided for @wrongSortRecent.
  ///
  /// In zh, this message translates to:
  /// **'最近错的在前'**
  String get wrongSortRecent;

  /// No description provided for @wrongSortMost.
  ///
  /// In zh, this message translates to:
  /// **'错得最多在前'**
  String get wrongSortMost;

  /// No description provided for @wrongFilteredHint.
  ///
  /// In zh, this message translates to:
  /// **'筛出 {count} 题 · 长按任意题可标错因或移出'**
  String wrongFilteredHint(int count);

  /// No description provided for @wrongRedoThis.
  ///
  /// In zh, this message translates to:
  /// **'重做这道题'**
  String get wrongRedoThis;

  /// No description provided for @wrongAnswerOnly.
  ///
  /// In zh, this message translates to:
  /// **'只看答案解析'**
  String get wrongAnswerOnly;

  /// No description provided for @wrongTenMore.
  ///
  /// In zh, this message translates to:
  /// **'再练 10 道同类型'**
  String get wrongTenMore;

  /// No description provided for @wrongAddToSaved.
  ///
  /// In zh, this message translates to:
  /// **'加入收藏'**
  String get wrongAddToSaved;

  /// No description provided for @wrongTagReason.
  ///
  /// In zh, this message translates to:
  /// **'标记错因'**
  String get wrongTagReason;

  /// No description provided for @wrongRemoveFromBook.
  ///
  /// In zh, this message translates to:
  /// **'移出错题本'**
  String get wrongRemoveFromBook;

  /// No description provided for @wrongRemoveShort.
  ///
  /// In zh, this message translates to:
  /// **'移出'**
  String get wrongRemoveShort;

  /// No description provided for @wrongCorrectAnswer.
  ///
  /// In zh, this message translates to:
  /// **'  ·  正确答案 {answer}'**
  String wrongCorrectAnswer(String answer);

  /// No description provided for @wrongPlanTitle.
  ///
  /// In zh, this message translates to:
  /// **'{name} 四天计划'**
  String wrongPlanTitle(String name);

  /// No description provided for @wrongPlanDoneToday.
  ///
  /// In zh, this message translates to:
  /// **'今天这步做完了，明天再来'**
  String get wrongPlanDoneToday;

  /// No description provided for @wrongPlanGapHint.
  ///
  /// In zh, this message translates to:
  /// **'中间隔一天，记忆才吃得住'**
  String get wrongPlanGapHint;

  /// No description provided for @wrongPlanAgain.
  ///
  /// In zh, this message translates to:
  /// **'再练一次'**
  String get wrongPlanAgain;

  /// No description provided for @statsTitle.
  ///
  /// In zh, this message translates to:
  /// **'学习统计'**
  String get statsTitle;

  /// No description provided for @statsLast30.
  ///
  /// In zh, this message translates to:
  /// **'近 30 天答题'**
  String get statsLast30;

  /// No description provided for @statsAvgRate.
  ///
  /// In zh, this message translates to:
  /// **'平均正确率'**
  String get statsAvgRate;

  /// No description provided for @statsActiveDays.
  ///
  /// In zh, this message translates to:
  /// **'有效练习天'**
  String get statsActiveDays;

  /// No description provided for @statsDaily.
  ///
  /// In zh, this message translates to:
  /// **'每日题量'**
  String get statsDaily;

  /// No description provided for @statsLast30Short.
  ///
  /// In zh, this message translates to:
  /// **'近 30 天'**
  String get statsLast30Short;

  /// No description provided for @statsWeekly.
  ///
  /// In zh, this message translates to:
  /// **'每周走势'**
  String get statsWeekly;

  /// No description provided for @statsLast8Weeks.
  ///
  /// In zh, this message translates to:
  /// **'近 8 周'**
  String get statsLast8Weeks;

  /// No description provided for @statsAccuracyTrend.
  ///
  /// In zh, this message translates to:
  /// **'正确率趋势'**
  String get statsAccuracyTrend;

  /// No description provided for @statsDaysPractised.
  ///
  /// In zh, this message translates to:
  /// **'练过的日子'**
  String get statsDaysPractised;

  /// No description provided for @statsScoreTrend.
  ///
  /// In zh, this message translates to:
  /// **'成绩趋势'**
  String get statsScoreTrend;

  /// No description provided for @statsAllReports.
  ///
  /// In zh, this message translates to:
  /// **'全部记录'**
  String get statsAllReports;

  /// No description provided for @statsReasons.
  ///
  /// In zh, this message translates to:
  /// **'错因分布'**
  String get statsReasons;

  /// No description provided for @statsTagged.
  ///
  /// In zh, this message translates to:
  /// **'标记过的'**
  String get statsTagged;

  /// No description provided for @statsByType.
  ///
  /// In zh, this message translates to:
  /// **'题型强弱'**
  String get statsByType;

  /// No description provided for @statsLowToHigh.
  ///
  /// In zh, this message translates to:
  /// **'低到高'**
  String get statsLowToHigh;

  /// No description provided for @statsEmptyTypes.
  ///
  /// In zh, this message translates to:
  /// **'刷一组题后，这里会显示你的强项和弱项'**
  String get statsEmptyTypes;

  /// No description provided for @statsDoneCount.
  ///
  /// In zh, this message translates to:
  /// **' {count} 题'**
  String statsDoneCount(int count);

  /// No description provided for @statsPeak.
  ///
  /// In zh, this message translates to:
  /// **'峰值 {count} 题'**
  String statsPeak(int count);

  /// No description provided for @statsNoRecords.
  ///
  /// In zh, this message translates to:
  /// **'还没有练习记录'**
  String get statsNoRecords;

  /// No description provided for @statsOneMoreDay.
  ///
  /// In zh, this message translates to:
  /// **'再练一天就能看到趋势了'**
  String get statsOneMoreDay;

  /// No description provided for @statsFrom.
  ///
  /// In zh, this message translates to:
  /// **'{rate} 起'**
  String statsFrom(String rate);

  /// No description provided for @statsLatest.
  ///
  /// In zh, this message translates to:
  /// **'最新 {rate}'**
  String statsLatest(String rate);

  /// No description provided for @statsNoScores.
  ///
  /// In zh, this message translates to:
  /// **'还没有成绩记录，完成一组 5 题以上的练习即可'**
  String get statsNoScores;

  /// No description provided for @statsSameAsLast.
  ///
  /// In zh, this message translates to:
  /// **'与上次持平'**
  String get statsSameAsLast;

  /// No description provided for @statsUpFromLast.
  ///
  /// In zh, this message translates to:
  /// **'较上次 +{delta}'**
  String statsUpFromLast(int delta);

  /// No description provided for @statsDownFromLast.
  ///
  /// In zh, this message translates to:
  /// **'较上次 {delta}'**
  String statsDownFromLast(int delta);

  /// No description provided for @statsAverage.
  ///
  /// In zh, this message translates to:
  /// **'平均 {rate}%'**
  String statsAverage(int rate);

  /// No description provided for @statsMostlyCareless.
  ///
  /// In zh, this message translates to:
  /// **'大部分错题是粗心 —— 别加练，先放慢做题速度、把答案带回题干核对。'**
  String get statsMostlyCareless;

  /// No description provided for @statsMostlyGaps.
  ///
  /// In zh, this message translates to:
  /// **'大部分错题是知识点没掌握 —— 先回去补方法，再刷同类题。'**
  String get statsMostlyGaps;

  /// No description provided for @statsMostlyMisread.
  ///
  /// In zh, this message translates to:
  /// **'大部分错题栽在审题 —— 做题时把限定词、单位圈出来。'**
  String get statsMostlyMisread;

  /// No description provided for @statsMostlyTime.
  ///
  /// In zh, this message translates to:
  /// **'大部分错题是时间不够 —— 先练单模块限时，再上整卷。'**
  String get statsMostlyTime;

  /// No description provided for @statsVolume.
  ///
  /// In zh, this message translates to:
  /// **'题量'**
  String get statsVolume;

  /// No description provided for @statsLatestIs.
  ///
  /// In zh, this message translates to:
  /// **'最右为最近一次（{kind} · {count} 题），点它可逐题回顾'**
  String statsLatestIs(String kind, int count);

  /// No description provided for @statsKindMock.
  ///
  /// In zh, this message translates to:
  /// **'模考'**
  String get statsKindMock;

  /// No description provided for @statsKindPractice.
  ///
  /// In zh, this message translates to:
  /// **'练习'**
  String get statsKindPractice;

  /// No description provided for @vocabToday.
  ///
  /// In zh, this message translates to:
  /// **'今日'**
  String get vocabToday;

  /// No description provided for @vocabFrequent.
  ///
  /// In zh, this message translates to:
  /// **'高频'**
  String get vocabFrequent;

  /// No description provided for @vocabConfusable.
  ///
  /// In zh, this message translates to:
  /// **'辨析'**
  String get vocabConfusable;

  /// No description provided for @vocabMine.
  ///
  /// In zh, this message translates to:
  /// **'我的'**
  String get vocabMine;

  /// No description provided for @vocabMissedThis.
  ///
  /// In zh, this message translates to:
  /// **'你在题里错过这个词'**
  String get vocabMissedThis;

  /// No description provided for @vocabThinkFirst.
  ///
  /// In zh, this message translates to:
  /// **'先自己想一遍，再点开对答案'**
  String get vocabThinkFirst;

  /// No description provided for @vocabMeaning.
  ///
  /// In zh, this message translates to:
  /// **'意思'**
  String get vocabMeaning;

  /// No description provided for @vocabUsage.
  ///
  /// In zh, this message translates to:
  /// **'怎么用'**
  String get vocabUsage;

  /// No description provided for @vocabDontConfuse.
  ///
  /// In zh, this message translates to:
  /// **'别混了'**
  String get vocabDontConfuse;

  /// No description provided for @vocabTapToFlip.
  ///
  /// In zh, this message translates to:
  /// **'点一下翻开'**
  String get vocabTapToFlip;

  /// No description provided for @vocabForgot.
  ///
  /// In zh, this message translates to:
  /// **'没记住'**
  String get vocabForgot;

  /// No description provided for @vocabGotIt.
  ///
  /// In zh, this message translates to:
  /// **'记住了'**
  String get vocabGotIt;

  /// No description provided for @vocabFlip.
  ///
  /// In zh, this message translates to:
  /// **'翻开'**
  String get vocabFlip;

  /// No description provided for @vocabNoneToday.
  ///
  /// In zh, this message translates to:
  /// **'今天没有要背的词'**
  String get vocabNoneToday;

  /// No description provided for @vocabDoneToday.
  ///
  /// In zh, this message translates to:
  /// **'今天的词过完了'**
  String get vocabDoneToday;

  /// No description provided for @vocabAutoCollect.
  ///
  /// In zh, this message translates to:
  /// **'做错的逻辑填空会自动把词收进来'**
  String get vocabAutoCollect;

  /// No description provided for @vocabResult.
  ///
  /// In zh, this message translates to:
  /// **'记住 {right} / {total} · 没记住的明天还会出现'**
  String vocabResult(int right, int total);

  /// No description provided for @vocabAgain.
  ///
  /// In zh, this message translates to:
  /// **'再来一轮'**
  String get vocabAgain;

  /// No description provided for @vocabSearchHint.
  ///
  /// In zh, this message translates to:
  /// **'查一个词，比如「一以贯之」'**
  String get vocabSearchHint;

  /// No description provided for @vocabNoFreq.
  ///
  /// In zh, this message translates to:
  /// **'这版题库还没带词频'**
  String get vocabNoFreq;

  /// No description provided for @vocabNeverAsked.
  ///
  /// In zh, this message translates to:
  /// **'没有考过这个词'**
  String get vocabNeverAsked;

  /// No description provided for @vocabNoFreqHint.
  ///
  /// In zh, this message translates to:
  /// **'词频是从逻辑填空的选项统计出来的，重装一次 App 就有了。'**
  String get vocabNoFreqHint;

  /// No description provided for @vocabNeverAskedHint.
  ///
  /// In zh, this message translates to:
  /// **'换个说法试试，或者它确实没在真题里出现过。'**
  String get vocabNeverAskedHint;

  /// No description provided for @vocabAskedTimes.
  ///
  /// In zh, this message translates to:
  /// **'考过 {count} 次'**
  String vocabAskedTimes(int count);

  /// No description provided for @vocabAskedTimesLong.
  ///
  /// In zh, this message translates to:
  /// **'真题里考过 {count} 次'**
  String vocabAskedTimesLong(int count);

  /// No description provided for @vocabAlreadyAdded.
  ///
  /// In zh, this message translates to:
  /// **'已在我的词表里'**
  String get vocabAlreadyAdded;

  /// No description provided for @vocabAdd.
  ///
  /// In zh, this message translates to:
  /// **'加进我的词表'**
  String get vocabAdd;

  /// No description provided for @vocabQuestionsWith.
  ///
  /// In zh, this message translates to:
  /// **'考过这个词的题'**
  String get vocabQuestionsWith;

  /// No description provided for @vocabNoSource.
  ///
  /// In zh, this message translates to:
  /// **'这一版题库里没找到原题。'**
  String get vocabNoSource;

  /// No description provided for @vocabSourceLine.
  ///
  /// In zh, this message translates to:
  /// **'{title} · 正确答案 {answer}'**
  String vocabSourceLine(String title, String answer);

  /// No description provided for @vocabNoConfusable.
  ///
  /// In zh, this message translates to:
  /// **'还没有易混词'**
  String get vocabNoConfusable;

  /// No description provided for @vocabNoConfusableHint.
  ///
  /// In zh, this message translates to:
  /// **'内置词表里标了易混词的条目会出现在这里。'**
  String get vocabNoConfusableHint;

  /// No description provided for @vocabConfusableWith.
  ///
  /// In zh, this message translates to:
  /// **'易混：{words}'**
  String vocabConfusableWith(String words);

  /// No description provided for @vocabEmpty.
  ///
  /// In zh, this message translates to:
  /// **'词表还是空的'**
  String get vocabEmpty;

  /// No description provided for @vocabEmptyHint.
  ///
  /// In zh, this message translates to:
  /// **'逻辑填空做错的题，那对词会自动收进来；也可以在「高频」里手动加。'**
  String get vocabEmptyHint;

  /// No description provided for @vocabFromMistakes.
  ///
  /// In zh, this message translates to:
  /// **'做错收的'**
  String get vocabFromMistakes;

  /// No description provided for @scanNeedAi.
  ///
  /// In zh, this message translates to:
  /// **'先配一个 AI'**
  String get scanNeedAi;

  /// No description provided for @scanNeedAiBody.
  ///
  /// In zh, this message translates to:
  /// **'识别试卷要调模型。填一个 key 就行，题目和图片只发给你自己配的那家。'**
  String get scanNeedAiBody;

  /// No description provided for @scanGoSettings.
  ///
  /// In zh, this message translates to:
  /// **'去设置'**
  String get scanGoSettings;

  /// No description provided for @scanNoPages.
  ///
  /// In zh, this message translates to:
  /// **'这个文件里没有可识别的页面'**
  String get scanNoPages;

  /// No description provided for @scanCantOpen.
  ///
  /// In zh, this message translates to:
  /// **'打不开这个文件：{error}'**
  String scanCantOpen(String error);

  /// No description provided for @scanReading.
  ///
  /// In zh, this message translates to:
  /// **'识别中'**
  String get scanReading;

  /// No description provided for @scanReview.
  ///
  /// In zh, this message translates to:
  /// **'过一遍'**
  String get scanReview;

  /// No description provided for @scanPickPdf.
  ///
  /// In zh, this message translates to:
  /// **'选一个 PDF'**
  String get scanPickPdf;

  /// No description provided for @scanPickPdfHint.
  ///
  /// In zh, this message translates to:
  /// **'整本试卷，逐页识别'**
  String get scanPickPdfHint;

  /// No description provided for @scanPickImages.
  ///
  /// In zh, this message translates to:
  /// **'选图片'**
  String get scanPickImages;

  /// No description provided for @scanPickImagesHint.
  ///
  /// In zh, this message translates to:
  /// **'拍的照片或截图，可以多选'**
  String get scanPickImagesHint;

  /// No description provided for @scanPrivacyNote.
  ///
  /// In zh, this message translates to:
  /// **'识别用的是你自己配的那家模型，一页一次调用。\\n题目和图片不经过我们的服务器。'**
  String get scanPrivacyNote;

  /// No description provided for @scanPageProgress.
  ///
  /// In zh, this message translates to:
  /// **'{done} / {total} 页'**
  String scanPageProgress(int done, int total);

  /// No description provided for @scanPageNo.
  ///
  /// In zh, this message translates to:
  /// **'第 {n} 页'**
  String scanPageNo(int n);

  /// No description provided for @scanWaiting.
  ///
  /// In zh, this message translates to:
  /// **'等着'**
  String get scanWaiting;

  /// No description provided for @scanNoWholeQuestion.
  ///
  /// In zh, this message translates to:
  /// **'没有完整题目'**
  String get scanNoWholeQuestion;

  /// No description provided for @commonRetry.
  ///
  /// In zh, this message translates to:
  /// **'重试'**
  String get commonRetry;

  /// No description provided for @scanMissingAnswers.
  ///
  /// In zh, this message translates to:
  /// **'{count} 题没认出答案，已排在最前'**
  String scanMissingAnswers(int count);

  /// No description provided for @scanFailedPages.
  ///
  /// In zh, this message translates to:
  /// **'{count} 页识别失败'**
  String scanFailedPages(int count);

  /// No description provided for @scanType.
  ///
  /// In zh, this message translates to:
  /// **'题型'**
  String get scanType;

  /// No description provided for @scanTypeSummary.
  ///
  /// In zh, this message translates to:
  /// **'识别出 {types} 类，{unknown} 题没认出'**
  String scanTypeSummary(int types, int unknown);

  /// No description provided for @scanTypeHint.
  ///
  /// In zh, this message translates to:
  /// **'已逐题识别，不对可以整批改'**
  String get scanTypeHint;

  /// No description provided for @scanAsDetected.
  ///
  /// In zh, this message translates to:
  /// **'按识别结果'**
  String get scanAsDetected;

  /// No description provided for @scanViewPage.
  ///
  /// In zh, this message translates to:
  /// **'看页面'**
  String get scanViewPage;

  /// No description provided for @scanNothingSelected.
  ///
  /// In zh, this message translates to:
  /// **'没有选中的题'**
  String get scanNothingSelected;

  /// No description provided for @scanImportSelected.
  ///
  /// In zh, this message translates to:
  /// **'导入 {count} 题'**
  String scanImportSelected(int count);

  /// No description provided for @scanNoAnswer.
  ///
  /// In zh, this message translates to:
  /// **'没认出答案'**
  String get scanNoAnswer;

  /// No description provided for @scanAnswerIs.
  ///
  /// In zh, this message translates to:
  /// **'答案 {answer}'**
  String scanAnswerIs(String answer);

  /// No description provided for @scanUnclassified.
  ///
  /// In zh, this message translates to:
  /// **'未判定'**
  String get scanUnclassified;

  /// No description provided for @scanOptionCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 个选项'**
  String scanOptionCount(int count);

  /// No description provided for @scanHasMaterial.
  ///
  /// In zh, this message translates to:
  /// **'带材料'**
  String get scanHasMaterial;

  /// No description provided for @scanHasImage.
  ///
  /// In zh, this message translates to:
  /// **'带图'**
  String get scanHasImage;

  /// No description provided for @docFoundCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 道'**
  String docFoundCount(int count);

  /// No description provided for @docNoAnswerCount.
  ///
  /// In zh, this message translates to:
  /// **' · {count} 道没答案'**
  String docNoAnswerCount(int count);

  /// No description provided for @docNeedAiKey.
  ///
  /// In zh, this message translates to:
  /// **'先去「我的 → AI 设置」配一个 key，解析要用它'**
  String get docNeedAiKey;

  /// No description provided for @docOpening.
  ///
  /// In zh, this message translates to:
  /// **'正在打开文件…'**
  String get docOpening;

  /// No description provided for @docNoText.
  ///
  /// In zh, this message translates to:
  /// **'这个文件里没读到文字。扫描件请走「拍照 / PDF」那条路。'**
  String get docNoText;

  /// No description provided for @docImportTitle.
  ///
  /// In zh, this message translates to:
  /// **'文档导入'**
  String get docImportTitle;

  /// No description provided for @docImportBody.
  ///
  /// In zh, this message translates to:
  /// **'Word、Excel、CSV、纯文本都行。AI 读一遍，认出题干、选项、答案和解析 —— 什么考试都可以，不限于行测。'**
  String get docImportBody;

  /// No description provided for @docWhichExam.
  ///
  /// In zh, this message translates to:
  /// **'这是什么考试的（可选）'**
  String get docWhichExam;

  /// No description provided for @docWhichExamHint.
  ///
  /// In zh, this message translates to:
  /// **'例如 教师资格证 · 科目二'**
  String get docWhichExamHint;

  /// No description provided for @docWhichExamNote.
  ///
  /// In zh, this message translates to:
  /// **'填了能帮 AI 分类分得准一些'**
  String get docWhichExamNote;

  /// No description provided for @docPickFile.
  ///
  /// In zh, this message translates to:
  /// **'选择文件'**
  String get docPickFile;

  /// No description provided for @docPickAnother.
  ///
  /// In zh, this message translates to:
  /// **'换一个文件'**
  String get docPickAnother;

  /// No description provided for @docFound.
  ///
  /// In zh, this message translates to:
  /// **'认出来的题'**
  String get docFound;

  /// No description provided for @docNoAnswerHint.
  ///
  /// In zh, this message translates to:
  /// **'没答案的题做不了，多半是原文档把答案单独列在别处。存进去之后可以自己补，或者换一份带答案的资料。'**
  String get docNoAnswerHint;

  /// No description provided for @docMoreHidden.
  ///
  /// In zh, this message translates to:
  /// **'还有 {count} 道，存进去就能看到'**
  String docMoreHidden(int count);

  /// No description provided for @docSaveCount.
  ///
  /// In zh, this message translates to:
  /// **'存入题库 {count} 道'**
  String docSaveCount(int count);

  /// No description provided for @docNoAnswer.
  ///
  /// In zh, this message translates to:
  /// **'没有答案'**
  String get docNoAnswer;

  /// No description provided for @docHasAnalysis.
  ///
  /// In zh, this message translates to:
  /// **'带解析'**
  String get docHasAnalysis;

  /// No description provided for @essayNeedAi.
  ///
  /// In zh, this message translates to:
  /// **'先配置 AI'**
  String get essayNeedAi;

  /// No description provided for @essayNeedAiBody.
  ///
  /// In zh, this message translates to:
  /// **'拍照识题要用到 AI，去填一下 API Key？'**
  String get essayNeedAiBody;

  /// No description provided for @commonLater.
  ///
  /// In zh, this message translates to:
  /// **'以后再说'**
  String get commonLater;

  /// No description provided for @essayScanFailed.
  ///
  /// In zh, this message translates to:
  /// **'识别失败'**
  String get essayScanFailed;

  /// No description provided for @essayScanDone.
  ///
  /// In zh, this message translates to:
  /// **'识别完成，检查一下材料有没有缺段'**
  String get essayScanDone;

  /// No description provided for @essayNeedFields.
  ///
  /// In zh, this message translates to:
  /// **'标题、给定材料、作答要求都得填，AI 才批得准'**
  String get essayNeedFields;

  /// No description provided for @essayNewTitle.
  ///
  /// In zh, this message translates to:
  /// **'录入申论题'**
  String get essayNewTitle;

  /// No description provided for @essayEditTitle.
  ///
  /// In zh, this message translates to:
  /// **'编辑题目'**
  String get essayEditTitle;

  /// No description provided for @commonSaving.
  ///
  /// In zh, this message translates to:
  /// **'保存中…'**
  String get commonSaving;

  /// No description provided for @essayScanning.
  ///
  /// In zh, this message translates to:
  /// **'识别中，长材料要等十几秒…'**
  String get essayScanning;

  /// No description provided for @essayScanHint.
  ///
  /// In zh, this message translates to:
  /// **'拍照 / 选图，让 AI 认题'**
  String get essayScanHint;

  /// No description provided for @essayScanCheck.
  ///
  /// In zh, this message translates to:
  /// **'认完记得核对材料有没有缺段 —— 材料缺一块，批改就会漏一片。'**
  String get essayScanCheck;

  /// No description provided for @essayType.
  ///
  /// In zh, this message translates to:
  /// **'题型'**
  String get essayType;

  /// No description provided for @essayTitleField.
  ///
  /// In zh, this message translates to:
  /// **'标题'**
  String get essayTitleField;

  /// No description provided for @essayProvince.
  ///
  /// In zh, this message translates to:
  /// **'省份'**
  String get essayProvince;

  /// No description provided for @essayYear.
  ///
  /// In zh, this message translates to:
  /// **'年份'**
  String get essayYear;

  /// No description provided for @essayWordLimit.
  ///
  /// In zh, this message translates to:
  /// **'字数上限'**
  String get essayWordLimit;

  /// No description provided for @essaySuggestedMinutes.
  ///
  /// In zh, this message translates to:
  /// **'建议用时（分钟）'**
  String get essaySuggestedMinutes;

  /// No description provided for @essaySource.
  ///
  /// In zh, this message translates to:
  /// **'给定材料'**
  String get essaySource;

  /// No description provided for @essayTask.
  ///
  /// In zh, this message translates to:
  /// **'作答要求'**
  String get essayTask;

  /// No description provided for @essayReference.
  ///
  /// In zh, this message translates to:
  /// **'参考答案与采分点（可选，填了批改更准）'**
  String get essayReference;

  /// No description provided for @essayModelAnswer.
  ///
  /// In zh, this message translates to:
  /// **'参考答案'**
  String get essayModelAnswer;

  /// No description provided for @essayModelAnswerHint.
  ///
  /// In zh, this message translates to:
  /// **'有官方答案就贴上'**
  String get essayModelAnswerHint;

  /// No description provided for @essayMarkPoints.
  ///
  /// In zh, this message translates to:
  /// **'采分点，一行一个'**
  String get essayMarkPoints;

  /// No description provided for @essayTitleHint.
  ///
  /// In zh, this message translates to:
  /// **'2025 国考副省级 第一题'**
  String get essayTitleHint;

  /// No description provided for @essaySourceHint.
  ///
  /// In zh, this message translates to:
  /// **'材料1……\\n材料2……'**
  String get essaySourceHint;

  /// No description provided for @essayTaskHint.
  ///
  /// In zh, this message translates to:
  /// **'根据给定资料，概括……要求：全面、准确、有条理，不超过 200 字。'**
  String get essayTaskHint;

  /// No description provided for @essayMarkPointsHint.
  ///
  /// In zh, this message translates to:
  /// **'基层治理成本高\\n群众参与度低\\n数字化手段缺位'**
  String get essayMarkPointsHint;

  /// No description provided for @importMissingImages.
  ///
  /// In zh, this message translates to:
  /// **'有 {count} 张图片在压缩包里找不到，这些题会显示\"图片缺失\"'**
  String importMissingImages(int count);

  /// No description provided for @importedPaperTitle.
  ///
  /// In zh, this message translates to:
  /// **'用户导入'**
  String get importedPaperTitle;

  /// No description provided for @paperYearPrefix.
  ///
  /// In zh, this message translates to:
  /// **'{year} 年 · '**
  String paperYearPrefix(String year);

  /// No description provided for @paperDoneSuffix.
  ///
  /// In zh, this message translates to:
  /// **' · 已练 {done} · 正确率 {rate}%'**
  String paperDoneSuffix(int done, int rate);

  /// No description provided for @paperNoQuestions.
  ///
  /// In zh, this message translates to:
  /// **'这里没有题目'**
  String get paperNoQuestions;

  /// No description provided for @paperSkim.
  ///
  /// In zh, this message translates to:
  /// **'速览 · {title}'**
  String paperSkim(String title);

  /// No description provided for @paperHistory.
  ///
  /// In zh, this message translates to:
  /// **'本卷历史'**
  String get paperHistory;

  /// No description provided for @paperHistoryShort.
  ///
  /// In zh, this message translates to:
  /// **'历史'**
  String get paperHistoryShort;

  /// No description provided for @paperFullMock.
  ///
  /// In zh, this message translates to:
  /// **'整卷模考'**
  String get paperFullMock;

  /// No description provided for @paperMockMinutes.
  ///
  /// In zh, this message translates to:
  /// **'120 分钟'**
  String get paperMockMinutes;

  /// No description provided for @paperResume.
  ///
  /// In zh, this message translates to:
  /// **'继续未做'**
  String get paperResume;

  /// No description provided for @paperAllDone.
  ///
  /// In zh, this message translates to:
  /// **'已做完'**
  String get paperAllDone;

  /// No description provided for @paperWrong.
  ///
  /// In zh, this message translates to:
  /// **'本卷错题'**
  String get paperWrong;

  /// No description provided for @commonNone.
  ///
  /// In zh, this message translates to:
  /// **'暂无'**
  String get commonNone;

  /// No description provided for @paperSkimAnswers.
  ///
  /// In zh, this message translates to:
  /// **'速览答案'**
  String get paperSkimAnswers;

  /// No description provided for @paperAllAnalysis.
  ///
  /// In zh, this message translates to:
  /// **'整卷解析'**
  String get paperAllAnalysis;

  /// No description provided for @paperModules.
  ///
  /// In zh, this message translates to:
  /// **'模块构成'**
  String get paperModules;

  /// No description provided for @paperModulesHint.
  ///
  /// In zh, this message translates to:
  /// **'点一行只练这块'**
  String get paperModulesHint;

  /// No description provided for @paperModuleYear.
  ///
  /// In zh, this message translates to:
  /// **'{name} · {year} 年'**
  String paperModuleYear(String name, String year);

  /// No description provided for @paperNoTypes.
  ///
  /// In zh, this message translates to:
  /// **'这套卷子还没有题目 —— 导入时缺少题型标注会这样'**
  String get paperNoTypes;

  /// No description provided for @paperTipModules.
  ///
  /// In zh, this message translates to:
  /// **'建议先按模块练，熟悉题型后再整卷限时。'**
  String get paperTipModules;

  /// No description provided for @paperTipMock.
  ///
  /// In zh, this message translates to:
  /// **'整卷模考按 120 分钟计时，中途可用答题卡跳题。'**
  String get paperTipMock;

  /// No description provided for @healthCleanAll.
  ///
  /// In zh, this message translates to:
  /// **'清理全部重复'**
  String get healthCleanAll;

  /// No description provided for @healthCleanAllBody.
  ///
  /// In zh, this message translates to:
  /// **'{groups} 组卷内重复，每组留一道，共删掉 {removed} 道。'**
  String healthCleanAllBody(int groups, int removed);

  /// No description provided for @healthClean.
  ///
  /// In zh, this message translates to:
  /// **'清理'**
  String get healthClean;

  /// No description provided for @healthTitle.
  ///
  /// In zh, this message translates to:
  /// **'题库体检'**
  String get healthTitle;

  /// No description provided for @healthAllGood.
  ///
  /// In zh, this message translates to:
  /// **'没查出问题'**
  String get healthAllGood;

  /// No description provided for @healthEmptyBody.
  ///
  /// In zh, this message translates to:
  /// **'导入题目之后，这里会告诉你哪些题有毛病。'**
  String get healthEmptyBody;

  /// No description provided for @healthAllGoodBody.
  ///
  /// In zh, this message translates to:
  /// **'每道题都有答案、有选项，卷内也没有收重。'**
  String get healthAllGoodBody;

  /// No description provided for @healthNoAnswer.
  ///
  /// In zh, this message translates to:
  /// **'没有答案'**
  String get healthNoAnswer;

  /// No description provided for @healthNoAnswerCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 题 · 这些题做了也判不了对错'**
  String healthNoAnswerCount(int count);

  /// No description provided for @healthFillAnswer.
  ///
  /// In zh, this message translates to:
  /// **'补答案'**
  String get healthFillAnswer;

  /// No description provided for @healthBrokenOptions.
  ///
  /// In zh, this message translates to:
  /// **'选项残缺'**
  String get healthBrokenOptions;

  /// No description provided for @healthBrokenCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 题 · 不足两个选项，多半是解析出错'**
  String healthBrokenCount(int count);

  /// No description provided for @healthDupes.
  ///
  /// In zh, this message translates to:
  /// **'重复的题'**
  String get healthDupes;

  /// No description provided for @healthDupesCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 组 · 同一份卷里收了两遍'**
  String healthDupesCount(int count);

  /// No description provided for @healthCleanAllShort.
  ///
  /// In zh, this message translates to:
  /// **'全部清理'**
  String get healthCleanAllShort;

  /// No description provided for @healthCopies.
  ///
  /// In zh, this message translates to:
  /// **'{count} 份'**
  String healthCopies(int count);

  /// No description provided for @healthKeepOne.
  ///
  /// In zh, this message translates to:
  /// **'只留一道'**
  String get healthKeepOne;

  /// No description provided for @healthByCategory.
  ///
  /// In zh, this message translates to:
  /// **'各科多少题'**
  String get healthByCategory;

  /// No description provided for @healthUnitQuestions.
  ///
  /// In zh, this message translates to:
  /// **'道题'**
  String get healthUnitQuestions;

  /// No description provided for @healthUnitCategories.
  ///
  /// In zh, this message translates to:
  /// **'个科目'**
  String get healthUnitCategories;

  /// No description provided for @healthUnitProblems.
  ///
  /// In zh, this message translates to:
  /// **'处待修'**
  String get healthUnitProblems;

  /// No description provided for @healthMore.
  ///
  /// In zh, this message translates to:
  /// **'还有 {count} 处，修完这批再刷新'**
  String healthMore(int count);

  /// No description provided for @healthEmptyStem.
  ///
  /// In zh, this message translates to:
  /// **'（空题干）'**
  String get healthEmptyStem;

  /// No description provided for @healthDelete.
  ///
  /// In zh, this message translates to:
  /// **'删掉'**
  String get healthDelete;

  /// No description provided for @healthWhichAnswer.
  ///
  /// In zh, this message translates to:
  /// **'正确答案是哪个'**
  String get healthWhichAnswer;

  /// No description provided for @healthWhichAnswerHint.
  ///
  /// In zh, this message translates to:
  /// **'选错了也不要紧，之后在做题页还能改。'**
  String get healthWhichAnswerHint;

  /// No description provided for @bankAllShort.
  ///
  /// In zh, this message translates to:
  /// **'全部'**
  String get bankAllShort;

  /// No description provided for @reportsTodayAt.
  ///
  /// In zh, this message translates to:
  /// **'今天 {time}'**
  String reportsTodayAt(String time);

  /// No description provided for @reportsMinSec.
  ///
  /// In zh, this message translates to:
  /// **'{m} 分 {s} 秒'**
  String reportsMinSec(int m, int s);

  /// No description provided for @reportsSec.
  ///
  /// In zh, this message translates to:
  /// **'{s} 秒'**
  String reportsSec(int s);

  /// No description provided for @reportsResume.
  ///
  /// In zh, this message translates to:
  /// **'{when} · 停在第 {n} 题 · 点开接着做'**
  String reportsResume(String when, int n);

  /// No description provided for @reportsScoreLine.
  ///
  /// In zh, this message translates to:
  /// **'{when} · 答对 {correct}/{total} · {duration}'**
  String reportsScoreLine(String when, int correct, int total, String duration);

  /// No description provided for @reportsPlainLine.
  ///
  /// In zh, this message translates to:
  /// **'{when} · {duration}'**
  String reportsPlainLine(String when, String duration);

  /// No description provided for @reportsEssayHint.
  ///
  /// In zh, this message translates to:
  /// **'申论记录去申论页看批改'**
  String get reportsEssayHint;

  /// No description provided for @reportsVocabHint.
  ///
  /// In zh, this message translates to:
  /// **'背词记录没有题目可以逐题回顾'**
  String get reportsVocabHint;

  /// No description provided for @reportsNeedTwo.
  ///
  /// In zh, this message translates to:
  /// **'至少要有两份报告才能对比'**
  String get reportsNeedTwo;

  /// No description provided for @reportsTitle.
  ///
  /// In zh, this message translates to:
  /// **'练习历史'**
  String get reportsTitle;

  /// No description provided for @reportsNone.
  ///
  /// In zh, this message translates to:
  /// **'还没有成绩报告'**
  String get reportsNone;

  /// No description provided for @reportsNoneHint.
  ///
  /// In zh, this message translates to:
  /// **'练习、模考、背词都会记在这里。'**
  String get reportsNoneHint;

  /// No description provided for @reportsKindVocab.
  ///
  /// In zh, this message translates to:
  /// **'背词'**
  String get reportsKindVocab;

  /// No description provided for @reportsUnfinished.
  ///
  /// In zh, this message translates to:
  /// **'未做完'**
  String get reportsUnfinished;

  /// No description provided for @reportsSeeWrong.
  ///
  /// In zh, this message translates to:
  /// **'看这 {count} 道错题'**
  String reportsSeeWrong(int count);

  /// No description provided for @reportsDiagnose.
  ///
  /// In zh, this message translates to:
  /// **'诊断这份卷子'**
  String get reportsDiagnose;

  /// No description provided for @reportsCompareWith.
  ///
  /// In zh, this message translates to:
  /// **'和哪一次比'**
  String get reportsCompareWith;

  /// No description provided for @reportsCompare.
  ///
  /// In zh, this message translates to:
  /// **'两次对比'**
  String get reportsCompare;

  /// No description provided for @reportsLevel.
  ///
  /// In zh, this message translates to:
  /// **'持平'**
  String get reportsLevel;

  /// No description provided for @reportsCompareNote.
  ///
  /// In zh, this message translates to:
  /// **'题目不同，比的是各模块的正确率，不是同一批题。'**
  String get reportsCompareNote;

  /// No description provided for @notesReview.
  ///
  /// In zh, this message translates to:
  /// **'笔记回顾'**
  String get notesReview;

  /// No description provided for @notesTitle.
  ///
  /// In zh, this message translates to:
  /// **'我的笔记'**
  String get notesTitle;

  /// No description provided for @notesWriteOne.
  ///
  /// In zh, this message translates to:
  /// **'写一条'**
  String get notesWriteOne;

  /// No description provided for @notesReviewAll.
  ///
  /// In zh, this message translates to:
  /// **'全部回顾'**
  String get notesReviewAll;

  /// No description provided for @notesNone.
  ///
  /// In zh, this message translates to:
  /// **'还没有笔记'**
  String get notesNone;

  /// No description provided for @notesNoneHint.
  ///
  /// In zh, this message translates to:
  /// **'做题时点便签图标记这道题的心得；跟具体题无关的经验，点下面写一条。'**
  String get notesNoneHint;

  /// No description provided for @notesSearchHint.
  ///
  /// In zh, this message translates to:
  /// **'搜笔记内容或题干'**
  String get notesSearchHint;

  /// No description provided for @notesNoMatch.
  ///
  /// In zh, this message translates to:
  /// **'没有匹配的笔记'**
  String get notesNoMatch;

  /// No description provided for @notesNoMatchHint.
  ///
  /// In zh, this message translates to:
  /// **'换个关键词，或把题型筛选清掉。'**
  String get notesNoMatchHint;

  /// No description provided for @notesDelete.
  ///
  /// In zh, this message translates to:
  /// **'删除笔记'**
  String get notesDelete;

  /// No description provided for @notesQuick.
  ///
  /// In zh, this message translates to:
  /// **'随手记'**
  String get notesQuick;

  /// No description provided for @notesTitleField.
  ///
  /// In zh, this message translates to:
  /// **'标题（可选）'**
  String get notesTitleField;

  /// No description provided for @notesTitleHint.
  ///
  /// In zh, this message translates to:
  /// **'不写就取正文第一行'**
  String get notesTitleHint;

  /// No description provided for @notesBody.
  ///
  /// In zh, this message translates to:
  /// **'内容'**
  String get notesBody;

  /// No description provided for @notesBodyHint.
  ///
  /// In zh, this message translates to:
  /// **'公式、坑点、这次模考的教训…'**
  String get notesBodyHint;

  /// No description provided for @usageClear.
  ///
  /// In zh, this message translates to:
  /// **'清空用量记录'**
  String get usageClear;

  /// No description provided for @usageClearBody.
  ///
  /// In zh, this message translates to:
  /// **'只清掉这里的统计，不影响已经生成的讲解和导入的题。'**
  String get usageClearBody;

  /// No description provided for @usageClearShort.
  ///
  /// In zh, this message translates to:
  /// **'清空'**
  String get usageClearShort;

  /// No description provided for @usageTitle.
  ///
  /// In zh, this message translates to:
  /// **'AI 用量'**
  String get usageTitle;

  /// No description provided for @usageLastDays.
  ///
  /// In zh, this message translates to:
  /// **'近 {days} 天'**
  String usageLastDays(int days);

  /// No description provided for @usageNone.
  ///
  /// In zh, this message translates to:
  /// **'还没有用量'**
  String get usageNone;

  /// No description provided for @usageNoneHint.
  ///
  /// In zh, this message translates to:
  /// **'AI 讲题、导入解析、申论批改都会记在这里。'**
  String get usageNoneHint;

  /// No description provided for @usageWhere.
  ///
  /// In zh, this message translates to:
  /// **'花在哪'**
  String get usageWhere;

  /// No description provided for @usageByTokens.
  ///
  /// In zh, this message translates to:
  /// **'token 从多到少'**
  String get usageByTokens;

  /// No description provided for @usageByModel.
  ///
  /// In zh, this message translates to:
  /// **'按模型'**
  String get usageByModel;

  /// No description provided for @usageUnrecorded.
  ///
  /// In zh, this message translates to:
  /// **'未记录'**
  String get usageUnrecorded;

  /// No description provided for @usageTokenNote.
  ///
  /// In zh, this message translates to:
  /// **'token 数由模型返回，各家统计口径略有差别，这里的数字用来比较大小，跟账单可能差一点。'**
  String get usageTokenNote;

  /// No description provided for @usageFeatureExplain.
  ///
  /// In zh, this message translates to:
  /// **'AI 讲题'**
  String get usageFeatureExplain;

  /// No description provided for @usageFeatureDoc.
  ///
  /// In zh, this message translates to:
  /// **'文档导入'**
  String get usageFeatureDoc;

  /// No description provided for @usageFeatureScan.
  ///
  /// In zh, this message translates to:
  /// **'拍照 / PDF 识题'**
  String get usageFeatureScan;

  /// No description provided for @usageFeatureEssay.
  ///
  /// In zh, this message translates to:
  /// **'申论批改'**
  String get usageFeatureEssay;

  /// No description provided for @usageFeatureImage.
  ///
  /// In zh, this message translates to:
  /// **'图片识题'**
  String get usageFeatureImage;

  /// No description provided for @usageFeatureSort.
  ///
  /// In zh, this message translates to:
  /// **'分类整理'**
  String get usageFeatureSort;

  /// No description provided for @usageFeatureOther.
  ///
  /// In zh, this message translates to:
  /// **'其他'**
  String get usageFeatureOther;

  /// No description provided for @usageCalls.
  ///
  /// In zh, this message translates to:
  /// **'{count} 次调用'**
  String usageCalls(int count);

  /// No description provided for @usageLast14.
  ///
  /// In zh, this message translates to:
  /// **'近 14 天'**
  String get usageLast14;

  /// No description provided for @usageGroupLine.
  ///
  /// In zh, this message translates to:
  /// **'{calls} 次 · 进 {inTok} · 出 {outTok}'**
  String usageGroupLine(int calls, String inTok, String outTok);

  /// No description provided for @explainTitle.
  ///
  /// In zh, this message translates to:
  /// **'出题人视角'**
  String get explainTitle;

  /// No description provided for @explainRedo.
  ///
  /// In zh, this message translates to:
  /// **'重讲'**
  String get explainRedo;

  /// No description provided for @explainWorking.
  ///
  /// In zh, this message translates to:
  /// **'正在看这道题'**
  String get explainWorking;

  /// No description provided for @explainPitch.
  ///
  /// In zh, this message translates to:
  /// **'让 AI 从出题人的角度讲一遍：这题考什么、干扰项怎么设的、你错在哪。'**
  String get explainPitch;

  /// No description provided for @explainAsk.
  ///
  /// In zh, this message translates to:
  /// **'AI 讲这道题'**
  String get explainAsk;

  /// No description provided for @explainBackground.
  ///
  /// In zh, this message translates to:
  /// **'可以先去做别的，回来接着看'**
  String get explainBackground;

  /// No description provided for @explainStamp.
  ///
  /// In zh, this message translates to:
  /// **'AI 生成 · {stamp}'**
  String explainStamp(String stamp);

  /// No description provided for @searchFoundCount.
  ///
  /// In zh, this message translates to:
  /// **'找到 {count} 题'**
  String searchFoundCount(int count);

  /// No description provided for @searchFilteredSuffix.
  ///
  /// In zh, this message translates to:
  /// **' · 已按题型筛选'**
  String get searchFilteredSuffix;

  /// No description provided for @searchYearSuffix.
  ///
  /// In zh, this message translates to:
  /// **' · {year} 年'**
  String searchYearSuffix(String year);

  /// No description provided for @searchHasFigure.
  ///
  /// In zh, this message translates to:
  /// **' · 含图'**
  String get searchHasFigure;

  /// No description provided for @searchTitle.
  ///
  /// In zh, this message translates to:
  /// **'搜题'**
  String get searchTitle;

  /// No description provided for @searchPractiseThese.
  ///
  /// In zh, this message translates to:
  /// **'练这些'**
  String get searchPractiseThese;

  /// No description provided for @searchHint.
  ///
  /// In zh, this message translates to:
  /// **'搜题干、解析关键词'**
  String get searchHint;

  /// No description provided for @searchAllCount.
  ///
  /// In zh, this message translates to:
  /// **'全部 {count}'**
  String searchAllCount(int count);

  /// No description provided for @searchTop60.
  ///
  /// In zh, this message translates to:
  /// **'只显示前 60 条'**
  String get searchTop60;

  /// No description provided for @searchNoMatch.
  ///
  /// In zh, this message translates to:
  /// **'没有匹配的题目'**
  String get searchNoMatch;

  /// No description provided for @searchShorterHint.
  ///
  /// In zh, this message translates to:
  /// **'换个更短的关键词试试。'**
  String get searchShorterHint;

  /// No description provided for @searchRecent.
  ///
  /// In zh, this message translates to:
  /// **'最近搜索'**
  String get searchRecent;

  /// No description provided for @searchTryThese.
  ///
  /// In zh, this message translates to:
  /// **'试试这些'**
  String get searchTryThese;

  /// No description provided for @searchNote.
  ///
  /// In zh, this message translates to:
  /// **'搜索会扫描全库题目的题干与解析，命中的关键词会在结果里高亮。'**
  String get searchNote;

  /// No description provided for @toolVocabCompare.
  ///
  /// In zh, this message translates to:
  /// **'词语辨析'**
  String get toolVocabCompare;

  /// No description provided for @toolVocabCompareHint.
  ///
  /// In zh, this message translates to:
  /// **'一蹴而就 / 一挥而就，摆一起才分得清'**
  String get toolVocabCompareHint;

  /// No description provided for @toolVocabTop.
  ///
  /// In zh, this message translates to:
  /// **'高频词语'**
  String get toolVocabTop;

  /// No description provided for @toolVocabTopHint.
  ///
  /// In zh, this message translates to:
  /// **'从 2077 道逻辑填空的选项统计出来的'**
  String get toolVocabTopHint;

  /// No description provided for @toolVocabToday.
  ///
  /// In zh, this message translates to:
  /// **'今日词卡'**
  String get toolVocabToday;

  /// No description provided for @toolVocabTodayHint.
  ///
  /// In zh, this message translates to:
  /// **'按间隔重复排的，今天该背哪些'**
  String get toolVocabTodayHint;

  /// No description provided for @toolVocabMine.
  ///
  /// In zh, this message translates to:
  /// **'生词锦囊'**
  String get toolVocabMine;

  /// No description provided for @toolVocabMineHint.
  ///
  /// In zh, this message translates to:
  /// **'做错的词自动收进来，也能自己加'**
  String get toolVocabMineHint;

  /// No description provided for @toolVocabLookup.
  ///
  /// In zh, this message translates to:
  /// **'词语查询'**
  String get toolVocabLookup;

  /// No description provided for @toolVocabLookupHint.
  ///
  /// In zh, this message translates to:
  /// **'四千词表，看真题里怎么用'**
  String get toolVocabLookupHint;

  /// No description provided for @toolTips.
  ///
  /// In zh, this message translates to:
  /// **'行测助手'**
  String get toolTips;

  /// No description provided for @toolTipsHint.
  ///
  /// In zh, this message translates to:
  /// **'各模块解题思路速查，卡住时翻'**
  String get toolTipsHint;

  /// No description provided for @toolCheckin.
  ///
  /// In zh, this message translates to:
  /// **'每日打卡'**
  String get toolCheckin;

  /// No description provided for @toolCheckinHint.
  ///
  /// In zh, this message translates to:
  /// **'今天的安排，勾完算数'**
  String get toolCheckinHint;

  /// No description provided for @toolSearch.
  ///
  /// In zh, this message translates to:
  /// **'题库搜索'**
  String get toolSearch;

  /// No description provided for @toolSearchHint.
  ///
  /// In zh, this message translates to:
  /// **'一万六千道题，按关键词找'**
  String get toolSearchHint;

  /// No description provided for @toolsTitle.
  ///
  /// In zh, this message translates to:
  /// **'工具'**
  String get toolsTitle;

  /// No description provided for @searchNoResults.
  ///
  /// In zh, this message translates to:
  /// **'没找到相关题目'**
  String get searchNoResults;

  /// No description provided for @importedCount.
  ///
  /// In zh, this message translates to:
  /// **'成功导入 {count} 题'**
  String importedCount(int count);

  /// No description provided for @importedImages.
  ///
  /// In zh, this message translates to:
  /// **'、{count} 张图'**
  String importedImages(int count);

  /// No description provided for @importedOverwritten.
  ///
  /// In zh, this message translates to:
  /// **'（其中 {count} 题为覆盖更新）'**
  String importedOverwritten(int count);

  /// No description provided for @importedNothing.
  ///
  /// In zh, this message translates to:
  /// **'这次没有导入题目'**
  String get importedNothing;

  /// No description provided for @importFormatTitle.
  ///
  /// In zh, this message translates to:
  /// **'题目文件长什么样'**
  String get importFormatTitle;

  /// No description provided for @importParsed.
  ///
  /// In zh, this message translates to:
  /// **'解析结果'**
  String get importParsed;

  /// No description provided for @importQuestions.
  ///
  /// In zh, this message translates to:
  /// **'题目'**
  String get importQuestions;

  /// No description provided for @importImages.
  ///
  /// In zh, this message translates to:
  /// **'图片'**
  String get importImages;

  /// No description provided for @importOverwrites.
  ///
  /// In zh, this message translates to:
  /// **'覆盖已有'**
  String get importOverwrites;

  /// No description provided for @importConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确认导入'**
  String get importConfirm;

  /// No description provided for @aiSaved.
  ///
  /// In zh, this message translates to:
  /// **'已保存'**
  String get aiSaved;

  /// No description provided for @aiCantOpenBrowser.
  ///
  /// In zh, this message translates to:
  /// **'打不开浏览器，网址已复制：{url}'**
  String aiCantOpenBrowser(String url);

  /// No description provided for @aiPickProvider.
  ///
  /// In zh, this message translates to:
  /// **'选一家'**
  String get aiPickProvider;

  /// No description provided for @aiEnterKey.
  ///
  /// In zh, this message translates to:
  /// **'填 Key'**
  String get aiEnterKey;

  /// No description provided for @aiGetKeyAt.
  ///
  /// In zh, this message translates to:
  /// **'去 {where} 领一个'**
  String aiGetKeyAt(String where);

  /// No description provided for @aiWhichModel.
  ///
  /// In zh, this message translates to:
  /// **'用哪个模型'**
  String get aiWhichModel;

  /// No description provided for @aiModelHint.
  ///
  /// In zh, this message translates to:
  /// **'模型名，问服务商要'**
  String get aiModelHint;

  /// No description provided for @aiBaseUrl.
  ///
  /// In zh, this message translates to:
  /// **'接口地址'**
  String get aiBaseUrl;

  /// No description provided for @aiBaseUrlSet.
  ///
  /// In zh, this message translates to:
  /// **'接口地址已配好：{url}'**
  String aiBaseUrlSet(String url);

  /// No description provided for @aiTesting.
  ///
  /// In zh, this message translates to:
  /// **'测试中…'**
  String get aiTesting;

  /// No description provided for @aiTest.
  ///
  /// In zh, this message translates to:
  /// **'测试连接'**
  String get aiTest;

  /// No description provided for @aiKeyPrivacy.
  ///
  /// In zh, this message translates to:
  /// **'Key 只存在这台手机上。请求直接发给你选的那家服务商，不经过我们任何服务器。'**
  String get aiKeyPrivacy;

  /// No description provided for @aiPaste.
  ///
  /// In zh, this message translates to:
  /// **'粘贴'**
  String get aiPaste;

  /// No description provided for @aiHide.
  ///
  /// In zh, this message translates to:
  /// **'隐藏'**
  String get aiHide;

  /// No description provided for @aiShow.
  ///
  /// In zh, this message translates to:
  /// **'显示'**
  String get aiShow;

  /// No description provided for @aiFree.
  ///
  /// In zh, this message translates to:
  /// **'免费'**
  String get aiFree;

  /// No description provided for @essayDeletePrompt.
  ///
  /// In zh, this message translates to:
  /// **'删除这道题？'**
  String get essayDeletePrompt;

  /// No description provided for @essayDeleteBody.
  ///
  /// In zh, this message translates to:
  /// **'「{title}」连同它的作答记录会一起删掉。'**
  String essayDeleteBody(String title);

  /// No description provided for @essayAddPrompt.
  ///
  /// In zh, this message translates to:
  /// **'录入题目'**
  String get essayAddPrompt;

  /// No description provided for @essayNoneOfType.
  ///
  /// In zh, this message translates to:
  /// **'这个题型还没有题'**
  String get essayNoneOfType;

  /// No description provided for @essayNone.
  ///
  /// In zh, this message translates to:
  /// **'还没有申论题'**
  String get essayNone;

  /// No description provided for @essayNoneOfTypeHint.
  ///
  /// In zh, this message translates to:
  /// **'换个题型看看，或者录一道新的。'**
  String get essayNoneOfTypeHint;

  /// No description provided for @essayNoneHint.
  ///
  /// In zh, this message translates to:
  /// **'内置题库全是行测客观题，申论得自己录。\\n拍张照让 AI 认，或者直接粘贴材料和题干。'**
  String get essayNoneHint;

  /// No description provided for @essayAddFirst.
  ///
  /// In zh, this message translates to:
  /// **'录入第一道'**
  String get essayAddFirst;

  /// No description provided for @essayQuit.
  ///
  /// In zh, this message translates to:
  /// **'退出作答？'**
  String get essayQuit;

  /// No description provided for @essayQuitBody.
  ///
  /// In zh, this message translates to:
  /// **'还没交卷，写的内容会丢掉。'**
  String get essayQuitBody;

  /// No description provided for @essayKeepWriting.
  ///
  /// In zh, this message translates to:
  /// **'继续写'**
  String get essayKeepWriting;

  /// No description provided for @essayTooShort.
  ///
  /// In zh, this message translates to:
  /// **'至少写够 20 字再交，不然批不出东西'**
  String get essayTooShort;

  /// No description provided for @essayNeedAiMark.
  ///
  /// In zh, this message translates to:
  /// **'批改要用到 AI，去填一下 API Key？答案会先存下来，不会丢。'**
  String get essayNeedAiMark;

  /// No description provided for @essayMarkFailed.
  ///
  /// In zh, this message translates to:
  /// **'批改失败'**
  String get essayMarkFailed;

  /// No description provided for @essayWriteHint.
  ///
  /// In zh, this message translates to:
  /// **'在这里作答。归纳概括先分条，再把每条的核心词提到句首。'**
  String get essayWriteHint;

  /// No description provided for @essayMarking.
  ///
  /// In zh, this message translates to:
  /// **'AI 批改中，约 20 秒…'**
  String get essayMarking;

  /// No description provided for @essaySubmitMark.
  ///
  /// In zh, this message translates to:
  /// **'交卷批改'**
  String get essaySubmitMark;

  /// No description provided for @essayAttempts.
  ///
  /// In zh, this message translates to:
  /// **'作答记录'**
  String get essayAttempts;

  /// No description provided for @essayNotMarked.
  ///
  /// In zh, this message translates to:
  /// **'这次没批改成功，答案已经存下来了。'**
  String get essayNotMarked;

  /// No description provided for @essayResult.
  ///
  /// In zh, this message translates to:
  /// **'批改结果'**
  String get essayResult;

  /// No description provided for @essayPointsCovered.
  ///
  /// In zh, this message translates to:
  /// **'要点覆盖'**
  String get essayPointsCovered;

  /// No description provided for @essayWordCount.
  ///
  /// In zh, this message translates to:
  /// **'字数'**
  String get essayWordCount;

  /// No description provided for @essayTimeTaken.
  ///
  /// In zh, this message translates to:
  /// **'用时'**
  String get essayTimeTaken;

  /// No description provided for @essayBreakdown.
  ///
  /// In zh, this message translates to:
  /// **'分项得分'**
  String get essayBreakdown;

  /// No description provided for @essayPointByPoint.
  ///
  /// In zh, this message translates to:
  /// **'采分点逐条对照'**
  String get essayPointByPoint;

  /// No description provided for @essayMissedPoints.
  ///
  /// In zh, this message translates to:
  /// **'漏 {count} 点'**
  String essayMissedPoints(int count);

  /// No description provided for @essayNextTime.
  ///
  /// In zh, this message translates to:
  /// **'下次注意'**
  String get essayNextTime;

  /// No description provided for @essayYourAnswer.
  ///
  /// In zh, this message translates to:
  /// **'你的答案'**
  String get essayYourAnswer;

  /// No description provided for @essayEvidence.
  ///
  /// In zh, this message translates to:
  /// **'出处：{text}'**
  String essayEvidence(String text);

  /// No description provided for @essayWords.
  ///
  /// In zh, this message translates to:
  /// **'{n} 字'**
  String essayWords(int n);

  /// No description provided for @essayWordsOfLimit.
  ///
  /// In zh, this message translates to:
  /// **'{n} / {limit} 字'**
  String essayWordsOfLimit(int n, int limit);

  /// No description provided for @essayOverLimit.
  ///
  /// In zh, this message translates to:
  /// **' · 超了'**
  String get essayOverLimit;

  /// No description provided for @essayOutOf.
  ///
  /// In zh, this message translates to:
  /// **'满分 {max}'**
  String essayOutOf(String max);

  /// No description provided for @planDoneToday.
  ///
  /// In zh, this message translates to:
  /// **'「{name}」今天已完成'**
  String planDoneToday(String name);

  /// No description provided for @planDayPending.
  ///
  /// In zh, this message translates to:
  /// **'「{name}」第 {day} 天还没做'**
  String planDayPending(String name, int day);

  /// No description provided for @tabPractice.
  ///
  /// In zh, this message translates to:
  /// **'练习'**
  String get tabPractice;

  /// No description provided for @tabPlan.
  ///
  /// In zh, this message translates to:
  /// **'计划'**
  String get tabPlan;

  /// No description provided for @navExpand.
  ///
  /// In zh, this message translates to:
  /// **'展开导航'**
  String get navExpand;

  /// No description provided for @navCollapse.
  ///
  /// In zh, this message translates to:
  /// **'收起导航'**
  String get navCollapse;

  /// No description provided for @shoreStreak.
  ///
  /// In zh, this message translates to:
  /// **'灯塔亮了 {days} 天'**
  String shoreStreak(int days);

  /// No description provided for @backupExportedTo.
  ///
  /// In zh, this message translates to:
  /// **'已导出到 {name}'**
  String backupExportedTo(String name);

  /// No description provided for @backupRestore.
  ///
  /// In zh, this message translates to:
  /// **'恢复备份'**
  String get backupRestore;

  /// No description provided for @backupRestoreBody.
  ///
  /// In zh, this message translates to:
  /// **'恢复会用备份中的答题记录与成绩报告覆盖当前数据，收藏、笔记、错因会合并，学习计划和考试日期按备份里的写回。题库本身不受影响。'**
  String get backupRestoreBody;

  /// No description provided for @backupPickFile.
  ///
  /// In zh, this message translates to:
  /// **'选择文件恢复'**
  String get backupPickFile;

  /// No description provided for @backupUnreadable.
  ///
  /// In zh, this message translates to:
  /// **'读不到这个文件'**
  String get backupUnreadable;

  /// No description provided for @backupNotOurs.
  ///
  /// In zh, this message translates to:
  /// **'这不是 OpenExam 的备份文件'**
  String get backupNotOurs;

  /// No description provided for @backupRestored.
  ///
  /// In zh, this message translates to:
  /// **'已恢复 {count} 条记录'**
  String backupRestored(int count);

  /// No description provided for @backupRestoreFailed.
  ///
  /// In zh, this message translates to:
  /// **'恢复失败：{error}'**
  String backupRestoreFailed(String error);

  /// No description provided for @backupIntro.
  ///
  /// In zh, this message translates to:
  /// **'这个 App 没有账号，数据只在本机。换手机或清除数据前，导出一份备份就能完整带走。'**
  String get backupIntro;

  /// No description provided for @backupAnswers.
  ///
  /// In zh, this message translates to:
  /// **'答题记录'**
  String get backupAnswers;

  /// No description provided for @backupReports.
  ///
  /// In zh, this message translates to:
  /// **'成绩报告'**
  String get backupReports;

  /// No description provided for @backupExport.
  ///
  /// In zh, this message translates to:
  /// **'导出备份'**
  String get backupExport;

  /// No description provided for @backupExportHint.
  ///
  /// In zh, this message translates to:
  /// **'生成一个 JSON 文件，含答题记录、成绩报告、收藏、笔记与错因'**
  String get backupExportHint;

  /// No description provided for @backupFromFile.
  ///
  /// In zh, this message translates to:
  /// **'从备份恢复'**
  String get backupFromFile;

  /// No description provided for @backupFromFileHint.
  ///
  /// In zh, this message translates to:
  /// **'答题记录与成绩报告会被覆盖，收藏、笔记、错因合并保留'**
  String get backupFromFileHint;

  /// No description provided for @backupSizeNote.
  ///
  /// In zh, this message translates to:
  /// **'备份文件不含题库（题目已随 App 内置），所以体积很小，可以直接发到微信或存进网盘。'**
  String get backupSizeNote;

  /// No description provided for @aiNotConfigured.
  ///
  /// In zh, this message translates to:
  /// **'还没配置 AI，去「我的 → AI 设置」里填一下'**
  String get aiNotConfigured;

  /// No description provided for @aiNoVision.
  ///
  /// In zh, this message translates to:
  /// **'{provider} 不支持图片识别，换个支持视觉的模型'**
  String aiNoVision(String provider);

  /// No description provided for @aiUnparsable.
  ///
  /// In zh, this message translates to:
  /// **'模型没有返回可解析的结果，再试一次'**
  String get aiUnparsable;

  /// No description provided for @aiNoKey.
  ///
  /// In zh, this message translates to:
  /// **'还没填 API Key'**
  String get aiNoKey;

  /// No description provided for @aiNoBaseUrl.
  ///
  /// In zh, this message translates to:
  /// **'还没填接口地址'**
  String get aiNoBaseUrl;

  /// No description provided for @aiConnOk.
  ///
  /// In zh, this message translates to:
  /// **'连接正常 · {model}'**
  String aiConnOk(String model);

  /// No description provided for @aiTimeout.
  ///
  /// In zh, this message translates to:
  /// **'请求超时了，检查一下网络或换个接口地址'**
  String get aiTimeout;

  /// No description provided for @aiRequestFailed.
  ///
  /// In zh, this message translates to:
  /// **'请求失败：{error}'**
  String aiRequestFailed(String error);

  /// No description provided for @aiNoContent.
  ///
  /// In zh, this message translates to:
  /// **'模型没吐出正文。多半是这个模型要先\"想\"一轮，配额被想的部分吃完了 —— 换成非推理模型，或者稍后再试。'**
  String get aiNoContent;

  /// No description provided for @aiBadKey.
  ///
  /// In zh, this message translates to:
  /// **'API Key 不对或没权限（{status}）：{detail}'**
  String aiBadKey(int status, String detail);

  /// No description provided for @aiNotFound.
  ///
  /// In zh, this message translates to:
  /// **'接口地址或模型名不对（404）：{detail}'**
  String aiNotFound(String detail);

  /// No description provided for @aiRateLimited.
  ///
  /// In zh, this message translates to:
  /// **'请求太频繁或余额不足（429）：{detail}'**
  String aiRateLimited(String detail);

  /// No description provided for @aiServerError.
  ///
  /// In zh, this message translates to:
  /// **'服务返回 {status}：{detail}'**
  String aiServerError(int status, String detail);

  /// No description provided for @tipsTitle.
  ///
  /// In zh, this message translates to:
  /// **'解题技巧'**
  String get tipsTitle;

  /// No description provided for @tipsUnitQuestions.
  ///
  /// In zh, this message translates to:
  /// **'道题'**
  String get tipsUnitQuestions;

  /// No description provided for @tipsPaperNumbers.
  ///
  /// In zh, this message translates to:
  /// **'卷面题号'**
  String get tipsPaperNumbers;

  /// No description provided for @tipsUnitMinutes.
  ///
  /// In zh, this message translates to:
  /// **'分钟'**
  String get tipsUnitMinutes;

  /// No description provided for @tipsWhereOnPaper.
  ///
  /// In zh, this message translates to:
  /// **'卷面位置'**
  String get tipsWhereOnPaper;

  /// No description provided for @tipsYear2026.
  ///
  /// In zh, this message translates to:
  /// **'2026 年'**
  String get tipsYear2026;

  /// No description provided for @tipsQuestionRange.
  ///
  /// In zh, this message translates to:
  /// **'第 {from}–{to} 题'**
  String tipsQuestionRange(int from, int to);

  /// No description provided for @tipsTotalAndMinutes.
  ///
  /// In zh, this message translates to:
  /// **'{count} 题 · {minutes} 分钟'**
  String tipsTotalAndMinutes(int count, int minutes);

  /// No description provided for @tipsBreakdownPace.
  ///
  /// In zh, this message translates to:
  /// **'内部结构 · 单题配速'**
  String get tipsBreakdownPace;

  /// No description provided for @tipsBreakdown.
  ///
  /// In zh, this message translates to:
  /// **'内部结构'**
  String get tipsBreakdown;

  /// No description provided for @tipsHotspots.
  ///
  /// In zh, this message translates to:
  /// **'高频考点'**
  String get tipsHotspots;

  /// No description provided for @tipsHotspotsHint.
  ///
  /// In zh, this message translates to:
  /// **'按出现频次排序'**
  String get tipsHotspotsHint;

  /// No description provided for @tipsHotspotsNote.
  ///
  /// In zh, this message translates to:
  /// **'关键词粗分，一题可能算进多个考点 —— 看相对权重就行，别当精确占比。'**
  String get tipsHotspotsNote;

  /// No description provided for @tipsInExam.
  ///
  /// In zh, this message translates to:
  /// **'考场怎么做'**
  String get tipsInExam;

  /// No description provided for @tipsMethods.
  ///
  /// In zh, this message translates to:
  /// **'方法'**
  String get tipsMethods;

  /// No description provided for @tipsMethodCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 条'**
  String tipsMethodCount(int count);

  /// No description provided for @examNewProfile.
  ///
  /// In zh, this message translates to:
  /// **'新建备考目标'**
  String get examNewProfile;

  /// No description provided for @examNewProfileHint.
  ///
  /// In zh, this message translates to:
  /// **'例如 执业医师 · 临床'**
  String get examNewProfileHint;

  /// No description provided for @examRename.
  ///
  /// In zh, this message translates to:
  /// **'改名'**
  String get examRename;

  /// No description provided for @examDeleteProfile.
  ///
  /// In zh, this message translates to:
  /// **'删除备考目标'**
  String get examDeleteProfile;

  /// No description provided for @examDeleteProfileBody.
  ///
  /// In zh, this message translates to:
  /// **'删掉「{name}」。题库、错题、记录都不受影响。'**
  String examDeleteProfileBody(String name);

  /// No description provided for @examWhichModules.
  ///
  /// In zh, this message translates to:
  /// **'显示哪些模块'**
  String get examWhichModules;

  /// No description provided for @examWhichExam.
  ///
  /// In zh, this message translates to:
  /// **'在备考哪一门'**
  String get examWhichExam;

  /// No description provided for @examModulesNote.
  ///
  /// In zh, this message translates to:
  /// **'这几个模块是给考公做的。备别的考试用不上，关掉就不会再出现。'**
  String get examModulesNote;

  /// No description provided for @examGenericOnly.
  ///
  /// In zh, this message translates to:
  /// **'只有通用模块'**
  String get examGenericOnly;

  /// No description provided for @examExtrasOn.
  ///
  /// In zh, this message translates to:
  /// **'开了 {count} 个专属模块'**
  String examExtrasOn(int count);

  /// No description provided for @examSharedBank.
  ///
  /// In zh, this message translates to:
  /// **'题库是共用的。换一份只是换一副眼镜 —— 题、错题本、练习记录都还在，不会因为切换丢东西。'**
  String get examSharedBank;

  /// No description provided for @examTwoProfiles.
  ///
  /// In zh, this message translates to:
  /// **'同时备两门考试的话，右上角 ＋ 建第二份，各留各的模块。'**
  String get examTwoProfiles;

  /// No description provided for @sessionHistoryPicked.
  ///
  /// In zh, this message translates to:
  /// **'{when}做过，当时选了 {answer}'**
  String sessionHistoryPicked(String when, String answer);

  /// No description provided for @sessionHistoryRight.
  ///
  /// In zh, this message translates to:
  /// **'（对）'**
  String get sessionHistoryRight;

  /// No description provided for @sessionHistoryWrong.
  ///
  /// In zh, this message translates to:
  /// **'（错）'**
  String get sessionHistoryWrong;

  /// No description provided for @sessionHistoryMissedN.
  ///
  /// In zh, this message translates to:
  /// **' · 一共错过 {count} 次'**
  String sessionHistoryMissedN(int count);

  /// No description provided for @sessionHistoryWasRight.
  ///
  /// In zh, this message translates to:
  /// **'{when}做过，当时做对了'**
  String sessionHistoryWasRight(String when);

  /// No description provided for @sessionHistoryWasWrong.
  ///
  /// In zh, this message translates to:
  /// **'{when}做错过这道题'**
  String sessionHistoryWasWrong(String when);

  /// No description provided for @sessionAvgSeconds.
  ///
  /// In zh, this message translates to:
  /// **'每题 {secs} 秒'**
  String sessionAvgSeconds(String secs);

  /// No description provided for @sessionYourAnswer.
  ///
  /// In zh, this message translates to:
  /// **'你的答案 {yours} · 正确答案 {right}'**
  String sessionYourAnswer(String yours, String right);

  /// No description provided for @sessionBlankAnswer.
  ///
  /// In zh, this message translates to:
  /// **'未作答'**
  String get sessionBlankAnswer;

  /// No description provided for @sessionDoneTimes.
  ///
  /// In zh, this message translates to:
  /// **'{count} 次做过'**
  String sessionDoneTimes(int count);

  /// No description provided for @sessionMissedN.
  ///
  /// In zh, this message translates to:
  /// **' · 错过 {count} 次'**
  String sessionMissedN(int count);

  /// No description provided for @sessionAllRight.
  ///
  /// In zh, this message translates to:
  /// **' · 全对'**
  String get sessionAllRight;

  /// No description provided for @sessionLastOn.
  ///
  /// In zh, this message translates to:
  /// **' · 上次 {date}'**
  String sessionLastOn(String date);

  /// No description provided for @sessionNoteExample.
  ///
  /// In zh, this message translates to:
  /// **'例如：看到\"至少\"先想最不利原则'**
  String get sessionNoteExample;

  /// No description provided for @sessionYearSuffix.
  ///
  /// In zh, this message translates to:
  /// **' · {year} 年'**
  String sessionYearSuffix(String year);

  /// No description provided for @minutesCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 分钟'**
  String minutesCount(int count);
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
