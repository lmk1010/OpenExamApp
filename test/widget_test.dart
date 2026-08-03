import 'package:flutter_test/flutter_test.dart';
import 'package:openexam_app/app/app.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Home shell shows plan tab content', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const OpenExamApp());
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('每日冲分'), findsOneWidget);
    expect(find.text('今日冲分计划'), findsOneWidget);
    expect(find.text('题库'), findsOneWidget);
  });
}
