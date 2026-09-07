import 'package:flutter/material.dart';
import 'package:openexam_app/core/constants/categories.dart';
import 'package:openexam_app/l10n/app_localizations.dart';

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
  String label(AppL l) => switch (this) {
        RepeatRule.once => l.repeatOnce,
        RepeatRule.daily => l.repeatDaily,
        RepeatRule.weekdays => l.repeatWeekdays,
        RepeatRule.weekly => l.repeatWeekly,
        RepeatRule.everyOtherDay => l.repeatEveryOther,
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

  /// 显示用的名字。
  ///
  /// [title] 可以是空的：自动给新用户铺的那三条任务不写死名字 —— 写死了
  /// 英文用户第一次打开计划页看见的就是三行中文，而且存进去之后切语言
  /// 也改不回来。空的就按 [action] 和 [category] 现场兜底。
  /// 分类名（资料分析这些）跟着题库走，不跟界面语言走。
  String displayTitle(AppL l) {
    if (title.isNotEmpty) return title;
    return switch (action) {
      StudyAction.daily => l.planTaskDaily,
      StudyAction.wrong || StudyAction.openWrongBook => l.planTaskWrong,
      StudyAction.practice when category != null => timed
          ? l.planTaskTimed(categoryLabel(category))
          : categoryLabel(category),
      _ => l.taskUntitled,
    };
  }

  /// 是不是一条申论任务。
  ///
  /// 认的是**任务名里的中文**，不是界面上的「申论 / Essay」——
  /// 这些任务是从中文备考模板来的，名字跟着题库走；拿界面文案去比，
  /// 英文界面下一条也匹配不上，申论任务就再也点不开了。
  bool get isEssay => title.contains('申论');

  /// 申论任务现在能直接进申论页作答批改，不再只是备忘。
  bool get runnable =>
      action != StudyAction.check &&
      (action != StudyAction.note || isEssay);

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
      // 空标题留空串，显示时按当前语言兜底。
      title: json['title'] as String? ?? '',
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

  /// 星期几。交给 MaterialLocalizations —— 每种语言的缩写都不一样。
  String weekdayLabel(BuildContext context) =>
      MaterialLocalizations.of(context).narrowWeekdays[date.weekday % 7];

  String shortDateLabel(BuildContext context) =>
      '${date.month}/${date.day} ${weekdayLabel(context)}';
}
