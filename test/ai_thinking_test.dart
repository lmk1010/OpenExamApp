import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openexam_app/core/theme/app_theme.dart';
import 'package:openexam_app/features/ai/ai_thinking.dart';

/// 等 AI 讲题要几十秒，这几个动画是那段时间里唯一的动静 —— 它们必须一直转，
/// 而且离场时别把 ticker 留下。
void main() {
  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(body: child),
        ),
      );

  testWidgets('骨架屏一直在动，不会自己停', (tester) async {
    await pump(tester, const AiThinkingSkeleton());
    // 循环动画下 pumpAndSettle 永远等不完，只能一帧帧推
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(AiThinkingSkeleton), findsOneWidget);
  });

  testWidgets('光标闪烁，透明度在变', (tester) async {
    await pump(tester, const AiCaret());
    // MaterialApp 自己也有 FadeTransition，只认光标里的那个
    final caretFade = find.descendant(
      of: find.byType(AiCaret),
      matching: find.byType(FadeTransition),
    );
    await tester.pump(const Duration(milliseconds: 450));
    final before = tester.widget<FadeTransition>(caretFade).opacity.value;
    await tester.pump(const Duration(milliseconds: 400));
    final after = tester.widget<FadeTransition>(caretFade).opacity.value;
    expect(before, isNot(closeTo(after, 0.01)));
  });

  testWidgets('三个点的透明度始终在 0-1 之间', (tester) async {
    await pump(tester, const AiDots());
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      final dots = find.descendant(
        of: find.byType(AiDots),
        matching: find.byType(Opacity),
      );
      for (final o in tester.widgetList<Opacity>(dots)) {
        expect(o.opacity, inInclusiveRange(0.0, 1.0));
      }
    }
  });

  testWidgets('移除后不留 ticker', (tester) async {
    await pump(tester, const AiThinkingSkeleton());
    await tester.pump(const Duration(milliseconds: 200));
    await pump(tester, const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 200));
    // 没抛 "was disposed with an active Ticker" 就算过
    expect(find.byType(AiThinkingSkeleton), findsNothing);
  });
}
