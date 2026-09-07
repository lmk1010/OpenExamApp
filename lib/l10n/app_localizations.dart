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
