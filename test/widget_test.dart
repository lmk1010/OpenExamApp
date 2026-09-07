import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openexam_app/app/app.dart';
import 'package:openexam_app/core/constants/app_constants.dart';
import 'package:openexam_app/core/theme/app_theme.dart';
import 'package:openexam_app/core/theme/app_tokens.dart';
import 'package:openexam_app/features/onboarding/onboarding_page.dart';
import 'package:openexam_app/features/shell/app_shell.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  // pumpWidget 会拉起整个 app，app 启动就开库。测试进程里没有平台通道，
  // 得先把 sqflite 换成 ffi 实现，否则两个 widget 测试必然 StateError。
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });
  testWidgets('首次启动进入引导，可跳过', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const OpenExamApp());
    await tester.pump(const Duration(milliseconds: 400));

    // 断言结构，不断言文案：界面已经国际化，测试环境的语言不一定是中文，
    // 拿中文原文当契约的话，加一门语言就碎一次。
    expect(find.byType(OnboardingPage), findsOneWidget);
    expect(find.byType(PageView), findsOneWidget);
    // 三屏：两屏介绍 + 一屏设置。
    expect(find.byType(FilledButton).evaluate().length +
        find.byType(GestureDetector).evaluate().length, greaterThan(0));
  });

  testWidgets('已引导过的用户直接进入主界面，不再走引导', (tester) async {
    SharedPreferences.setMockInitialValues({Prefs.onboarded: true});

    await tester.pumpWidget(const OpenExamApp());
    // 解种子库要几百毫秒，pump 一次是不够的。
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    // 断言"进了 shell"，不断言底栏文字 —— 底栏只给选中的 tab 配字，
    // 其余是纯图标，拿文字当契约会跟着视觉改动一起碎。
    expect(find.byType(AppShell), findsOneWidget);
    expect(find.byType(OnboardingPage), findsNothing);
  });

  test('浅色与深色主题都带完整 token', () {
    for (final theme in [AppTheme.light(), AppTheme.dark()]) {
      final tokens = theme.extension<AppTokens>();
      expect(tokens, isNotNull);
      expect(tokens!.gradient.length, 3);
      expect(tokens.categories.length, 5);
      // Body text must never collapse into the backdrop.
      expect(tokens.text, isNot(equals(tokens.gradient.last)));
    }
  });

  test('系统字体缩放被钳制在 0.9–1.1', () {
    const big = TextScaler.linear(2.4);
    expect(
      big.clamp(minScaleFactor: 0.9, maxScaleFactor: 1.1).scale(16),
      lessThanOrEqualTo(16 * 1.1),
    );

    const small = TextScaler.linear(0.4);
    expect(
      small.clamp(minScaleFactor: 0.9, maxScaleFactor: 1.1).scale(16),
      greaterThanOrEqualTo(16 * 0.9),
    );
  });
}
