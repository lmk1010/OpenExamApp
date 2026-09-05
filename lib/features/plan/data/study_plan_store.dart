import 'dart:convert';

import 'package:openexam_app/core/constants/app_constants.dart';
import 'package:openexam_app/features/plan/data/plan_templates.dart';
import 'package:openexam_app/features/plan/domain/models/study_task.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists template choice, per-day completion, extras, and template overrides.
class StudyPlanStore {
  StudyPlanStore(this._prefs);

  final SharedPreferences _prefs;

  static const _donePrefix = 'study_plan_done_';
  /// 会重复的自定义任务只存一份，不按日期存 —— 按日期存的话
  /// "每天背单词"要往后每一天各写一条，改标题得改 365 处。
  static const _recurringKey = 'study_plan_recurring';
  static const _extraPrefix = 'study_plan_extra_';
  static const _overridePrefix = 'study_plan_override_';
  static const _hiddenPrefix = 'study_plan_hidden_';

  static Future<StudyPlanStore> create() async {
    final prefs = await SharedPreferences.getInstance();
    return StudyPlanStore(prefs);
  }

  String get templateId =>
      _prefs.getString(Prefs.studyPlanTemplate) ?? PlanTemplates.workingId;

  Future<void> setTemplateId(String id) async {
    await _prefs.setString(Prefs.studyPlanTemplate, id);
  }

  bool get isEnabled => templateId != PlanTemplates.offId;

  DayPlan planFor(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    final template = PlanTemplates.byId(templateId);
    final focus = template?.focusByWeekday[day.weekday] ?? '今天自由安排';
    final hidden = loadHiddenIds(day);
    final overrides = loadOverrides(day);
    final base = <StudyTask>[];
    for (final task in template?.tasksByWeekday[day.weekday] ?? const <StudyTask>[]) {
      if (hidden.contains(task.id)) continue;
      base.add(overrides[task.id] ?? task);
    }
    final extras = loadExtras(day);
    final recurring = loadRecurring()
        .where((t) => !hidden.contains(t.id))
        .where((t) => t.repeat.occursOn(day, t.startedOn ?? day))
        .map((t) => overrides[t.id] ?? t)
        .toList();
    return DayPlan(
      date: day,
      focus: focus,
      tasks: [...base, ...recurring, ...extras],
    );
  }

  // ------------------------------------------------------- 会重复的自定义任务

  /// 存一份，每天按 [RepeatRule] 判断今天出不出现。
  List<StudyTask> loadRecurring() {
    final raw = _prefs.getString(_recurringKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      return (jsonDecode(raw) as List<dynamic>)
          .whereType<Map>()
          .map((e) => StudyTask.fromJson(Map<String, Object?>.from(e)))
          .map((t) => t.copyWith(custom: true))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveRecurring(List<StudyTask> tasks) async {
    if (tasks.isEmpty) {
      await _prefs.remove(_recurringKey);
      return;
    }
    await _prefs.setString(
      _recurringKey,
      jsonEncode(tasks.map((t) => t.toJson()).toList()),
    );
  }

  /// 加一条任务。[RepeatRule.once] 落在那一天，其余进重复表。
  Future<void> addTask(DateTime date, StudyTask task) async {
    final day = DateTime(date.year, date.month, date.day);
    if (task.repeat == RepeatRule.once) {
      await addExtra(day, task);
      return;
    }
    await saveRecurring([
      ...loadRecurring().where((t) => t.id != task.id),
      task.copyWith(custom: true, startedOn: task.startedOn ?? day),
    ]);
  }

  /// 删一条任务。重复的整条删掉，一次性的只删那天那条。
  Future<void> removeTask(DateTime date, String taskId) async {
    final recurring = loadRecurring();
    if (recurring.any((t) => t.id == taskId)) {
      await saveRecurring(recurring.where((t) => t.id != taskId).toList());
      return;
    }
    await removeExtra(date, taskId);
  }

  /// 只跳过某一天的重复任务，不动这条任务本身。
  Future<void> skipOnce(DateTime date, String taskId) async {
    await saveHiddenIds(date, loadHiddenIds(date)..add(taskId));
    await saveDoneIds(_dateKey(date), loadDoneIds(_dateKey(date))..remove(taskId));
  }

  Set<String> loadDoneIds(String dateKey) {
    final raw = _prefs.getString('$_donePrefix$dateKey');
    if (raw == null || raw.isEmpty) return <String>{};
    return raw.split(',').where((e) => e.isNotEmpty).toSet();
  }

  Future<void> saveDoneIds(String dateKey, Set<String> ids) async {
    final normalized = ids.toList()..sort();
    if (normalized.isEmpty) {
      await _prefs.remove('$_donePrefix$dateKey');
      return;
    }
    await _prefs.setString('$_donePrefix$dateKey', normalized.join(','));
  }

  Future<void> toggleDone(String dateKey, String taskId, bool done) async {
    final current = loadDoneIds(dateKey);
    if (done) {
      current.add(taskId);
    } else {
      current.remove(taskId);
    }
    await saveDoneIds(dateKey, current);
  }

  List<StudyTask> loadExtras(DateTime date) {
    final key = _dateKey(date);
    final raw = _prefs.getString('$_extraPrefix$key');
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .whereType<Map>()
          .map((e) => StudyTask.fromJson(Map<String, Object?>.from(e)))
          .map((t) => t.copyWith(custom: true))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveExtras(DateTime date, List<StudyTask> tasks) async {
    final key = _dateKey(date);
    if (tasks.isEmpty) {
      await _prefs.remove('$_extraPrefix$key');
      return;
    }
    final raw = jsonEncode(tasks.map((t) => t.toJson()).toList());
    await _prefs.setString('$_extraPrefix$key', raw);
  }

  Future<void> addExtra(DateTime date, StudyTask task) async {
    final extras = [...loadExtras(date), task.copyWith(custom: true)];
    await saveExtras(date, extras);
  }

  Future<void> removeExtra(DateTime date, String taskId) async {
    final extras = loadExtras(date).where((t) => t.id != taskId).toList();
    await saveExtras(date, extras);
    final done = loadDoneIds(_dateKey(date))..remove(taskId);
    await saveDoneIds(_dateKey(date), done);
  }

  Map<String, StudyTask> loadOverrides(DateTime date) {
    final raw = _prefs.getString('$_overridePrefix${_dateKey(date)}');
    if (raw == null || raw.isEmpty) return {};
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map.map(
        (k, v) => MapEntry(
          k,
          StudyTask.fromJson(Map<String, Object?>.from(v as Map))
              .copyWith(custom: false),
        ),
      );
    } catch (_) {
      return {};
    }
  }

  Future<void> saveOverrides(DateTime date, Map<String, StudyTask> overrides) async {
    final key = '$_overridePrefix${_dateKey(date)}';
    if (overrides.isEmpty) {
      await _prefs.remove(key);
      return;
    }
    final raw = jsonEncode(
      overrides.map((k, v) => MapEntry(k, v.toJson())),
    );
    await _prefs.setString(key, raw);
  }

  Set<String> loadHiddenIds(DateTime date) {
    final raw = _prefs.getString('$_hiddenPrefix${_dateKey(date)}');
    if (raw == null || raw.isEmpty) return <String>{};
    return raw.split(',').where((e) => e.isNotEmpty).toSet();
  }

  Future<void> saveHiddenIds(DateTime date, Set<String> ids) async {
    final key = '$_hiddenPrefix${_dateKey(date)}';
    final normalized = ids.toList()..sort();
    if (normalized.isEmpty) {
      await _prefs.remove(key);
      return;
    }
    await _prefs.setString(key, normalized.join(','));
  }

  /// Create or update a task for [date]. Template tasks become day overrides.
  Future<void> upsertTask(DateTime date, StudyTask task) async {
    if (task.custom) {
      final day = DateTime(date.year, date.month, date.day);
      final recurring = loadRecurring();
      final wasRecurring = recurring.any((t) => t.id == task.id);

      // 改了重复规则就要换存放的地方：一次性的落在那一天，
      // 会重复的只存一份。两边都清一遍，免得同一条任务出现两次。
      if (task.repeat != RepeatRule.once) {
        await removeExtra(day, task.id);
        await saveRecurring([
          ...recurring.where((t) => t.id != task.id),
          task.copyWith(
            custom: true,
            startedOn: task.startedOn ??
                recurring
                    .where((t) => t.id == task.id)
                    .map((t) => t.startedOn)
                    .firstOrNull ??
                day,
          ),
        ]);
        return;
      }
      if (wasRecurring) {
        await saveRecurring(recurring.where((t) => t.id != task.id).toList());
      }

      final extras = loadExtras(day);
      final idx = extras.indexWhere((e) => e.id == task.id);
      if (idx < 0) {
        await saveExtras(day, [...extras, task.copyWith(custom: true)]);
      } else {
        final next = [...extras];
        next[idx] = task.copyWith(custom: true);
        await saveExtras(day, next);
      }
      return;
    }
    final overrides = loadOverrides(date);
    final next = task.copyWith(custom: false);

    // 跟模板一模一样就别落盘。
    // 否则用户只是点开看了一眼、原样保存，也会写下一份快照，
    // 从此这条任务被冻在旧版本上 —— 以后模板改了标题也刷不出来。
    final template = PlanTemplates.byId(templateId)
        ?.tasksByWeekday[DateTime(date.year, date.month, date.day).weekday]
        ?.where((t) => t.id == task.id)
        .firstOrNull;
    if (template != null && _sameTask(template, next)) {
      overrides.remove(task.id);
    } else {
      overrides[task.id] = next;
    }
    await saveOverrides(date, overrides);
  }

  bool _sameTask(StudyTask a, StudyTask b) =>
      a.title == b.title &&
      a.subtitle == b.subtitle &&
      a.action == b.action &&
      a.category == b.category &&
      a.count == b.count &&
      a.timed == b.timed &&
      a.minutes == b.minutes;

  /// Rename keeping the rest of the task fields.
  Future<void> renameTask(DateTime date, StudyTask task, String title) async {
    await upsertTask(date, task.copyWith(title: title.trim()));
  }

  /// Delete custom task, or hide a template task for this day.
  Future<void> deleteTask(DateTime date, StudyTask task) async {
    if (task.custom) {
      await removeTask(date, task.id);
      return;
    }
    final hidden = loadHiddenIds(date)..add(task.id);
    await saveHiddenIds(date, hidden);
    final overrides = loadOverrides(date)..remove(task.id);
    await saveOverrides(date, overrides);
    final done = loadDoneIds(_dateKey(date))..remove(task.id);
    await saveDoneIds(_dateKey(date), done);
  }

  int streak(DateTime now) {
    var cursor = DateTime(now.year, now.month, now.day);
    final today = planFor(cursor);
    final todayDone = loadDoneIds(today.dateKey);
    final todayComplete =
        today.tasks.isNotEmpty && todayDone.length >= today.tasks.length;

    if (!todayComplete) {
      cursor = cursor.subtract(const Duration(days: 1));
    }

    var streak = 0;
    for (var i = 0; i < 60; i++) {
      final plan = planFor(cursor);
      if (plan.tasks.isEmpty) break;
      final done = loadDoneIds(plan.dateKey);
      if (done.length >= plan.tasks.length) {
        streak += 1;
        cursor = cursor.subtract(const Duration(days: 1));
        continue;
      }
      break;
    }
    return streak;
  }

  static String _dateKey(DateTime date) {
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '${date.year}-$m-$d';
  }
}
