/// One checklist item in a day plan. Most actions jump into practice; [note]
/// is for 申论 / 复盘 items the app can't auto-run yet.
enum StudyAction {
  practice,
  daily,
  mock,
  wrong,
  adaptive,
  note,
  openWrongBook,
}

class StudyTask {
  const StudyTask({
    required this.id,
    required this.title,
    required this.action,
    this.subtitle,
    this.category,
    this.count,
    this.timed = false,
    this.minutes,
    this.custom = false,
  });

  final String id;
  final String title;

  /// Quiet meta under the title, e.g. time slot "20:10–21:20".
  final String? subtitle;
  final StudyAction action;
  final String? category;
  final int? count;
  final bool timed;

  /// Soft time budget shown in the UI (and used as session limit when set).
  final int? minutes;

  /// User-added task — can be deleted. Template tasks cannot.
  final bool custom;

  /// 申论任务现在能直接进申论页作答批改，不再只是备忘。
  bool get runnable =>
      action != StudyAction.note || title.contains('申论');

  StudyTask copyWith({
    String? id,
    String? title,
    String? subtitle,
    StudyAction? action,
    String? category,
    int? count,
    bool? timed,
    int? minutes,
    bool? custom,
  }) {
    return StudyTask(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      action: action ?? this.action,
      category: category ?? this.category,
      count: count ?? this.count,
      timed: timed ?? this.timed,
      minutes: minutes ?? this.minutes,
      custom: custom ?? this.custom,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'title': title,
        if (subtitle != null) 'subtitle': subtitle,
        'action': action.name,
        if (category != null) 'category': category,
        if (count != null) 'count': count,
        'timed': timed,
        if (minutes != null) 'minutes': minutes,
        'custom': custom,
      };

  factory StudyTask.fromJson(Map<String, Object?> json) {
    final actionName = json['action'] as String? ?? StudyAction.note.name;
    final action = StudyAction.values.firstWhere(
      (a) => a.name == actionName,
      orElse: () => StudyAction.note,
    );
    return StudyTask(
      id: json['id'] as String? ?? 'task_${DateTime.now().millisecondsSinceEpoch}',
      title: json['title'] as String? ?? '未命名任务',
      subtitle: json['subtitle'] as String?,
      action: action,
      category: json['category'] as String?,
      count: json['count'] as int?,
      timed: json['timed'] as bool? ?? false,
      minutes: json['minutes'] as int?,
      custom: json['custom'] as bool? ?? false,
    );
  }
}

class DayPlan {
  const DayPlan({
    required this.date,
    required this.focus,
    required this.tasks,
  });

  final DateTime date;
  final String focus;
  final List<StudyTask> tasks;

  String get dateKey {
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '${date.year}-$m-$d';
  }

  String get weekdayLabel {
    const labels = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return labels[date.weekday - 1];
  }

  String get shortDateLabel => '${date.month}/${date.day} $weekdayLabel';
}
