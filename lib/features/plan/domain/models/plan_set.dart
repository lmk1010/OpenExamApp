import 'package:openexam_app/features/plan/domain/models/study_task.dart';
import 'package:openexam_app/l10n/app_localizations.dart';

/// 用户自己的一份计划清单。
///
/// 取代原来钉死在代码里的只读周模板。任务不再按星期几写在常量里，而是一条条
/// 存在用户的清单里、每条自带 [RepeatRule] —— 所以改一条、删一条，往后每天
/// 都是改过的样子，而不是只对今天生效。
///
/// 存多份就是"多套模板"：换一份等于换一套作息，各自的任务互不影响。
class PlanSet {
  const PlanSet({
    required this.id,
    required this.name,
    this.tasks = const [],
  });

  final String id;

  /// 用户起的名字。可能是空的 —— 自动建的那份没名字，显示时用
  /// [displayName] 按当前语言兜底，别直接把它渲染出去。
  final String name;

  String displayName(AppL l) => name.isEmpty ? l.planSetDefaultName : name;

  /// 无序不分天 —— 哪天出现由每条自己的 [StudyTask.repeat] 决定。
  final List<StudyTask> tasks;

  PlanSet copyWith({String? id, String? name, List<StudyTask>? tasks}) =>
      PlanSet(
        id: id ?? this.id,
        name: name ?? this.name,
        tasks: tasks ?? this.tasks,
      );

  /// 换掉同 id 的那条，没有就追加。
  PlanSet upsert(StudyTask task) {
    final next = [...tasks];
    final i = next.indexWhere((t) => t.id == task.id);
    if (i < 0) {
      next.add(task);
    } else {
      next[i] = task;
    }
    return copyWith(tasks: next);
  }

  PlanSet remove(String taskId) =>
      copyWith(tasks: tasks.where((t) => t.id != taskId).toList());

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'tasks': tasks.map((t) => t.toJson()).toList(),
      };

  factory PlanSet.fromJson(Map<String, Object?> json) => PlanSet(
        id: json['id'] as String? ?? 'set_${DateTime.now().millisecondsSinceEpoch}',
        name: json['name'] as String? ?? '',
        tasks: (json['tasks'] as List<dynamic>? ?? const [])
            .whereType<Map>()
            .map((e) => StudyTask.fromJson(Map<String, Object?>.from(e)))
            .toList(),
      );
}
