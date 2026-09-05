import 'package:flutter_test/flutter_test.dart';
import 'package:openexam_app/features/plan/domain/models/study_task.dart';

/// 重复规则是计划的地基：算错一天，用户第二天就看不到自己的任务。
void main() {
  final from = DateTime(2026, 9, 4); // 周五
  DateTime d(int day) => DateTime(2026, 9, day);

  test('只这一次：只有当天', () {
    expect(RepeatRule.once.occursOn(from, from), isTrue);
    expect(RepeatRule.once.occursOn(d(5), from), isFalse);
  });

  test('每天：从创建那天起每天都有', () {
    for (var i = 4; i <= 10; i++) {
      expect(RepeatRule.daily.occursOn(d(i), from), isTrue, reason: '9/$i');
    }
  });

  test('每周这天：只在同一个星期几', () {
    expect(RepeatRule.weekly.occursOn(d(11), from), isTrue); // 下周五
    expect(RepeatRule.weekly.occursOn(d(10), from), isFalse);
  });

  test('隔一天：按天数差取模，不看上次开没开过 app', () {
    expect(RepeatRule.everyOtherDay.occursOn(d(4), from), isTrue);
    expect(RepeatRule.everyOtherDay.occursOn(d(5), from), isFalse);
    expect(RepeatRule.everyOtherDay.occursOn(d(6), from), isTrue);
    // 中间一周没打开，回来那天照样对得上
    expect(RepeatRule.everyOtherDay.occursOn(d(20), from), isTrue);
    expect(RepeatRule.everyOtherDay.occursOn(d(21), from), isFalse);
  });

  test('创建日之前一律不出现', () {
    for (final rule in RepeatRule.values) {
      expect(rule.occursOn(d(3), from), isFalse, reason: rule.name);
    }
  });

  test('打卡任务不进做题页', () {
    const t = StudyTask(id: 'x', title: '背 20 个成语', action: StudyAction.check);
    expect(t.runnable, isFalse);
  });

  test('重复规则跟着任务存取', () {
    const t = StudyTask(
      id: 'x',
      title: '看时政',
      action: StudyAction.check,
      custom: true,
      repeat: RepeatRule.daily,
    );
    final back = StudyTask.fromJson(t.toJson());
    expect(back.repeat, RepeatRule.daily);
    expect(back.action, StudyAction.check);
  });
}
