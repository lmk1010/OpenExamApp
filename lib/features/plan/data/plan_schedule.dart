import 'package:openexam_app/features/plan/domain/models/daily_plan.dart';

class PlanSchedule {
  static final List<DailyPlan> _plans = [
    DailyPlan(
      date: DateTime(2026, 2, 13),
      weekday: '周五',
      tasks: ['全真1套125题（120min）', '错因分类'],
      target: '综合58%（摸底）',
    ),
    DailyPlan(
      date: DateTime(2026, 2, 14),
      weekday: '周六',
      tasks: ['全真1套125题', '输出弱项清单（TOP3）'],
      target: '综合60%',
    ),
    DailyPlan(
      date: DateTime(2026, 2, 15),
      weekday: '周日',
      tasks: ['资料20题', '判断35题', '数量8题', '错题30题'],
      target: '综合63%，资料≥70%',
    ),
    DailyPlan(
      date: DateTime(2026, 2, 16),
      weekday: '周一',
      tasks: ['言语35题', '判断25题', '资料10题', '常识20题'],
      target: '综合64%，言语≥68%',
    ),
    DailyPlan(
      date: DateTime(2026, 2, 17),
      weekday: '周二',
      tasks: ['全真1套', '回炉20题'],
      target: '综合64%',
    ),
    DailyPlan(
      date: DateTime(2026, 2, 18),
      weekday: '周三',
      tasks: ['错题回炉60题', '逻辑专项20题', '半套60题'],
      target: '回炉≥75%',
    ),
    DailyPlan(
      date: DateTime(2026, 2, 19),
      weekday: '周四',
      tasks: ['资料20题', '判断35题', '数量8题'],
      target: '综合65%，资料≥75%',
    ),
    DailyPlan(
      date: DateTime(2026, 2, 20),
      weekday: '周五',
      tasks: ['言语35题', '判断25题', '资料10题', '常识20题'],
      target: '综合65%，判断≥72%',
    ),
    DailyPlan(
      date: DateTime(2026, 2, 21),
      weekday: '周六',
      tasks: ['全真1套125题'],
      target: '综合65-66%',
    ),
    DailyPlan(
      date: DateTime(2026, 2, 22),
      weekday: '周日',
      tasks: ['错题回炉60题', '定义/类比30题', '半套60题'],
      target: '半套≥67%',
    ),
    DailyPlan(
      date: DateTime(2026, 2, 23),
      weekday: '周一',
      tasks: ['资料20题', '判断35题', '言语20题'],
      target: '综合66%',
    ),
    DailyPlan(
      date: DateTime(2026, 2, 24),
      weekday: '周二',
      tasks: ['言语35题', '资料15题', '判断20题', '常识20题'],
      target: '综合66%',
    ),
    DailyPlan(
      date: DateTime(2026, 2, 25),
      weekday: '周三',
      tasks: ['全真1套125题'],
      target: '综合66-67%',
    ),
    DailyPlan(
      date: DateTime(2026, 2, 26),
      weekday: '周四',
      tasks: ['资料20题', '判断35题', '数量8题'],
      target: '综合67%',
    ),
    DailyPlan(
      date: DateTime(2026, 2, 27),
      weekday: '周五',
      tasks: ['错题回炉50题', '逻辑20题', '半套60题'],
      target: '回炉≥78%',
    ),
    DailyPlan(
      date: DateTime(2026, 2, 28),
      weekday: '周六',
      tasks: ['全真1套125题'],
      target: '综合67-68%',
    ),
    DailyPlan(
      date: DateTime(2026, 3, 1),
      weekday: '周日',
      tasks: ['言语35题', '资料15题', '判断20题', '数量8题'],
      target: '综合68%',
    ),
    DailyPlan(
      date: DateTime(2026, 3, 2),
      weekday: '周一',
      tasks: ['资料20题', '判断35题', '常识20题'],
      target: '综合68%，资料≥80%',
    ),
    DailyPlan(
      date: DateTime(2026, 3, 3),
      weekday: '周二',
      tasks: ['全真1套125题'],
      target: '综合68-69%',
    ),
    DailyPlan(
      date: DateTime(2026, 3, 4),
      weekday: '周三',
      tasks: ['错题回炉50题', '言语主旨20题', '逻辑20题', '半套60题'],
      target: '半套≥69%',
    ),
    DailyPlan(
      date: DateTime(2026, 3, 5),
      weekday: '周四',
      tasks: ['资料20题', '判断35题', '数量8题', '言语20题'],
      target: '综合69%',
    ),
    DailyPlan(
      date: DateTime(2026, 3, 6),
      weekday: '周五',
      tasks: ['全真1套125题'],
      target: '综合69%',
    ),
    DailyPlan(
      date: DateTime(2026, 3, 7),
      weekday: '周六',
      tasks: ['9:00-11:00全真1套（按考场）', '下午复盘'],
      target: '综合69%',
    ),
    DailyPlan(
      date: DateTime(2026, 3, 8),
      weekday: '周日',
      tasks: ['错题回炉40题', '半套60题'],
      target: '回炉≥80%',
    ),
    DailyPlan(
      date: DateTime(2026, 3, 9),
      weekday: '周一',
      tasks: ['9:00-11:00全真1套'],
      target: '综合69-70%',
    ),
    DailyPlan(
      date: DateTime(2026, 3, 10),
      weekday: '周二',
      tasks: ['资料15题', '判断20题', '言语20题', '数量6题'],
      target: '综合70%',
    ),
    DailyPlan(
      date: DateTime(2026, 3, 11),
      weekday: '周三',
      tasks: ['最后一套全真（同考场节奏）'],
      target: '综合70%+',
    ),
    DailyPlan(
      date: DateTime(2026, 3, 12),
      weekday: '周四',
      tasks: ['半套60题', '错题本总复盘'],
      target: '半套≥72%',
    ),
    DailyPlan(
      date: DateTime(2026, 3, 13),
      weekday: '周五',
      tasks: ['资料10题', '判断15题', '言语15题', '常识10题'],
      target: '训练≥75%（保状态）',
    ),
  ];

  static final DateTime examDate = DateTime(2026, 3, 14);

  static List<DailyPlan> get plans => List.unmodifiable(_plans);

  static DailyPlan resolveTodayPlan(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);

    for (final plan in _plans) {
      if (_isSameDate(plan.date, today)) {
        return plan;
      }
    }

    if (today.isBefore(_plans.first.date)) {
      return _plans.first;
    }

    if (today.isAfter(_plans.last.date)) {
      return _plans.last;
    }

    for (final plan in _plans) {
      if (plan.date.isAfter(today)) {
        return plan;
      }
    }

    return _plans.last;
  }

  static DailyPlan? findPlanForDate(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    for (final plan in _plans) {
      if (_isSameDate(plan.date, normalized)) {
        return plan;
      }
    }
    return null;
  }

  static List<DailyPlan> upcomingPlans(DateTime now, {int count = 3}) {
    final today = DateTime(now.year, now.month, now.day);
    final upcoming = _plans
        .where((plan) => !plan.date.isBefore(today))
        .toList();
    if (upcoming.isEmpty) {
      return _plans.reversed.take(count).toList().reversed.toList();
    }
    return upcoming.take(count).toList();
  }

  static double progress(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final completed = _plans.where((plan) => plan.date.isBefore(today)).length;
    return completed / _plans.length;
  }

  static int daysUntilExam(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final days = examDate.difference(today).inDays;
    return days < 0 ? 0 : days;
  }

  static bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
