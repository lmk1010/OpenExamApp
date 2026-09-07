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
