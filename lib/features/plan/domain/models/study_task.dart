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

  /// 背今日词语。
  vocab,

  /// 纯打卡：勾了就算，不跳任何页面。
  ///
  /// 备考里一多半事情是这种 —— 背二十个成语、看今天时政、把昨天的错题
  /// 抄一遍。硬塞进做题流程只会让人为了勾掉它去点开一个不相干的页面。
  check,
}

/// 一条任务的重复规则。
///
/// 每条任务都有 —— 不分是自己加的还是从起始包导进来的。以前只有自定义任务
/// 能设，导入的任务被钉在星期几上，用户想把"资料分析"从每天改成隔天都做不到。
enum RepeatRule { once, daily, weekdays, weekly, everyOtherDay }

extension RepeatRuleX on RepeatRule {
  String get label => switch (this) {
        RepeatRule.once => '只这一次',
        RepeatRule.daily => '每天',
        RepeatRule.weekdays => '工作日',
        RepeatRule.weekly => '每周这天',
        RepeatRule.everyOtherDay => '隔一天',
      };

  /// [day] 这天要不要出现。[from] 是任务创建的那天。
  bool occursOn(DateTime day, DateTime from) {
    final a = DateTime(from.year, from.month, from.day);
    final b = DateTime(day.year, day.month, day.day);
    if (b.isBefore(a)) return false;
    return switch (this) {
      RepeatRule.once => a == b,
      RepeatRule.daily => true,
      // 在职备考的主力节奏：周一到周五练，周末另算
      RepeatRule.weekdays => b.weekday <= DateTime.friday,
      RepeatRule.weekly => a.weekday == b.weekday,
      // 用天数差取模，不能用"上次是不是昨天"——中间隔了几天没开 app 就错位了
      RepeatRule.everyOtherDay => b.difference(a).inDays % 2 == 0,
    };
  }
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
    this.repeat = RepeatRule.once,
    this.startedOn,
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

  /// 历史字段：以前用来区分"导入的任务不能删"。现在任务全归用户所有，
  /// 都能改能删，只留着读老数据。
  final bool custom;

  /// 重复规则。决定这条任务哪天出现，也决定它存在哪：
  /// [RepeatRule.once] 落在那一天，其余存进用户的计划清单。
  final RepeatRule repeat;

  /// 创建日，重复规则从这天开始算。
  final DateTime? startedOn;

  /// 申论任务现在能直接进申论页作答批改，不再只是备忘。
  bool get runnable =>
      action != StudyAction.check &&
      (action != StudyAction.note || title.contains('申论'));

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
    RepeatRule? repeat,
    DateTime? startedOn,
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
      repeat: repeat ?? this.repeat,
      startedOn: startedOn ?? this.startedOn,
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
        if (repeat != RepeatRule.once) 'repeat': repeat.name,
        if (startedOn != null) 'startedOn': startedOn!.toIso8601String(),
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
      repeat: RepeatRule.values.firstWhere(
        (r) => r.name == json['repeat'],
        orElse: () => RepeatRule.once,
      ),
      startedOn: DateTime.tryParse('${json['startedOn'] ?? ''}'),
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
