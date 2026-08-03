class DailyPlan {
  const DailyPlan({
    required this.date,
    required this.weekday,
    required this.tasks,
    required this.target,
  });

  final DateTime date;
  final String weekday;
  final List<String> tasks;
  final String target;

  String get dateKey {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String get shortDateLabel => '${date.month}/${date.day} $weekday';

  bool get isMockDay => tasks.any((task) => task.contains('全真1套'));

  bool get isSpringFestivalBoost {
    const startMonth = 2;
    const startDay = 15;
    const endMonth = 2;
    const endDay = 23;

    final isAfterStart =
        date.month > startMonth ||
        (date.month == startMonth && date.day >= startDay);
    final isBeforeEnd =
        date.month < endMonth || (date.month == endMonth && date.day <= endDay);

    return isAfterStart && isBeforeEnd;
  }
}
