import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openexam_app/app/app.dart';
import 'package:openexam_app/core/constants/app_constants.dart';
import 'package:openexam_app/features/shell/app_shell.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:openexam_app/core/i18n/locale_controller.dart';
import 'package:openexam_app/core/theme/app_theme.dart';
import 'package:openexam_app/core/theme/theme_controller.dart';
import 'package:openexam_app/features/achievements/achievements_page.dart';
import 'package:openexam_app/features/ai/ai_settings_page.dart';
import 'package:openexam_app/features/ai/ai_usage_page.dart';
import 'package:openexam_app/features/backup/backup_page.dart';
import 'package:openexam_app/features/bank/bank_health_page.dart';
import 'package:openexam_app/features/bank/category_manage_page.dart';
import 'package:openexam_app/features/feedback/feedback_page.dart';
import 'package:openexam_app/features/import/import_page.dart';
import 'package:openexam_app/features/import/presentation/doc_import_page.dart';
import 'package:openexam_app/features/import/presentation/scan_paper_page.dart';
import 'package:openexam_app/features/marks/marked_page.dart';
import 'package:openexam_app/features/notes/notes_page.dart';
import 'package:openexam_app/features/plan/presentation/pages/study_plan_page.dart';
import 'package:openexam_app/features/profile/dashboard_page.dart';
import 'package:openexam_app/features/profile/presentation/exam_profile_page.dart';
import 'package:openexam_app/features/profile/profile_page.dart';
import 'package:openexam_app/features/reports/reports_page.dart';
import 'package:openexam_app/features/reports/timeline_page.dart';
import 'package:openexam_app/features/search/search_page.dart';
import 'package:openexam_app/features/stats/stats_page.dart';
import 'package:openexam_app/features/tips/tips_page.dart';
import 'package:openexam_app/features/tools/tools_page.dart';
import 'package:openexam_app/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// 英文界面的排版守门人。
///
/// 文案搬进 arb 之后最容易出的问题不是漏翻，是**翻了放不下** —— 同一句话
/// 英文常常比中文长一半，中文界面上刚好的那一行，英文一进去就是黄黑条。
/// 这种破法 flutter analyze 看不出来，人不去点也看不出来。
///
/// 这组用例把整个 app 在两种语言下、按最小的一档手机宽度渲一遍。AppShell 用
/// IndexedStack 把四个主页面同时建出来，所以一次 pump 就把它们全过了一遍；
/// 任何一处 RenderFlex overflow 都会让用例直接失败。
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  // 320 宽是还在用的最小一档（iPhone SE 一代 / 老安卓机）。英文放得下这个
  // 宽度，往上都放得下。
  const smallPhone = Size(320, 640);

  void useSmallPhone(WidgetTester tester) {
    tester.view.physicalSize = smallPhone;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  for (final lang in ['zh', 'en']) {
    testWidgets('$lang：320 宽的四个主页面都不溢出', (tester) async {
      SharedPreferences.setMockInitialValues({
        Prefs.onboarded: true,
        'ui_locale': lang,
      });
      useSmallPhone(tester);

      await tester.pumpWidget(const OpenExamApp());
      // 解种子库要几百毫秒，pump 一次不够。
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }

      expect(find.byType(AppShell), findsOneWidget);

      // 底栏只给**选中**的那个 tab 配字，其余是纯图标。所以这里只能钉住
      // 当前这一个 —— 「页面标题是英文、导航还是中文」这种夹生状态，
      // 从这一条就能看出来。
      final l = lookupAppL(Locale(lang));
      expect(find.text(l.tabPractice), findsWidgets, reason: '底栏少了 ${l.tabPractice}');
    });

    testWidgets('$lang：引导页三屏在 320 宽下都不溢出', (tester) async {
      SharedPreferences.setMockInitialValues({'ui_locale': lang});
      useSmallPhone(tester);

      await tester.pumpWidget(const OpenExamApp());
      await tester.pump(const Duration(milliseconds: 400));

      // 三屏都要翻过去看一遍 —— 最后一屏（设置考试日期）文字最长。
      // 走按钮不走手势：PageView 在测试里拖不一定翻页，翻不过去就等于
      // 什么都没测，还看不出来。
      for (var i = 0; i < 2; i++) {
        await tester.tap(find.byType(FilledButton));
        await tester.pumpAndSettle();
      }

      // 顺手钉死最后一屏的文案。这一屏是最晚搬的，装了旧包的人看见的是
      // 「Skip / Let's go」夹着满屏中文 —— 那是包旧了，不是没搬；这条断言
      // 就是用来分辨这两种情况的。
      final l = lookupAppL(Locale(lang));
      expect(find.text(l.onboardThreeThings), findsOneWidget);
      expect(find.text(l.onboardDailyGoal), findsOneWidget);
      // 「考试哪天」在 320 高的屏上要滚下去才建出来。
      await tester.scrollUntilVisible(find.text(l.onboardWhen), 120,
          scrollable: find.byType(Scrollable).last);
      expect(find.text(l.onboardWhen), findsOneWidget);
      // 测试环境没有内置题库，所以整段「你在哪考」不该出现 ——
      // 一张中国卷都没有还问用户选国考还是北京，是在问一个他答不了的问题。
      expect(find.text(l.onboardWhere), findsNothing);
    });
  }

  // 二级页面进不了 IndexedStack，得一张一张单独渲。这里挑的是所有
  // 无参构造的页面 —— 加了新页面而没加进来，这份清单就该跟着补。
  final pages = <String, Widget Function()>{
    'ToolsPage': () => const ToolsPage(),
    'AchievementsPage': () => const AchievementsPage(),
    'MarkedPage': () => const MarkedPage(),
    'CategoryManagePage': () => const CategoryManagePage(),
    'BankHealthPage': () => const BankHealthPage(),
    'FeedbackPage': () => const FeedbackPage(),
    'SearchPage': () => const SearchPage(),
    'NotesPage': () => const NotesPage(),
    'DashboardPage': () => const DashboardPage(),
    'PracticePrefsPage': () => const PracticePrefsPage(),
    'ExamProfilePage': () => const ExamProfilePage(),
    'AiSettingsPage': () => const AiSettingsPage(),
    'AiUsagePage': () => const AiUsagePage(),
    'BackupPage': () => const BackupPage(),
    'DocImportPage': () => const DocImportPage(),
    'ScanPaperPage': () => const ScanPaperPage(),
    'StatsPage': () => const StatsPage(),
    'TimelinePage': () => const TimelinePage(),
    'TipsPage': () => const TipsPage(),
    'ImportPage': () => const ImportPage(),
    'ReportsPage': () => const ReportsPage(),
    'StudyPlanPage': () => const StudyPlanPage(),
  };

  for (final entry in pages.entries) {
    for (final lang in ['zh', 'en']) {
    testWidgets('$lang：${entry.key} 在 320 宽下不溢出', (tester) async {
      SharedPreferences.setMockInitialValues({'ui_locale': lang});
      useSmallPhone(tester);
      await LocaleController.instance.set(Locale(lang));
      addTearDown(() => LocaleController.instance.set(null));

      await tester.pumpWidget(MaterialApp(
        locale: Locale(lang),
        supportedLocales: LocaleController.supported,
        localizationsDelegates: const [
          AppL.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: AppTheme.fromTokens(
          ThemeController.instance.tokensFor(Brightness.light),
          Brightness.light,
        ),
        home: entry.value(),
      ));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
    });
    }
  }
}
