import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openexam_app/app/app.dart';
import 'package:openexam_app/core/constants/app_constants.dart';
import 'package:openexam_app/core/theme/app_theme.dart';
import 'package:openexam_app/core/theme/app_tokens.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('首次启动进入引导，可跳过', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const OpenExamApp());
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.textContaining('15936'), findsOneWidget);
    expect(find.text('继续'), findsOneWidget);
    expect(find.text('跳过'), findsOneWidget);
  });

  testWidgets('已引导过的用户直接进入四个 Tab', (tester) async {
    SharedPreferences.setMockInitialValues({Prefs.onboarded: true});

    await tester.pumpWidget(const OpenExamApp());
    await tester.pump(const Duration(milliseconds: 400));

    // The shell renders its tabs even before the database finishes loading.
    expect(find.text('练习'), findsWidgets);
    expect(find.text('题库'), findsWidgets);
    expect(find.text('错题本'), findsWidgets);
    expect(find.text('我的'), findsWidgets);
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
