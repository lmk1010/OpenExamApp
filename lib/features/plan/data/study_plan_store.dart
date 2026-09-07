import 'dart:convert';

import 'package:openexam_app/core/constants/app_constants.dart';
import 'package:openexam_app/features/plan/data/starter_packs.dart';
import 'package:openexam_app/features/plan/domain/models/plan_set.dart';
import 'package:openexam_app/features/plan/domain/models/study_task.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 改一条任务，是只改今天还是往后都改。
///
/// 老版本没得选：所有编辑都写成"某年某月某日的补丁"，用户改了今天，第二天
/// 打开发现原封不动 —— 现在默认 [forever]，[today] 留给临时挪一次的情况。
enum PlanEditScope { today, forever }

/// 存用户的计划清单、每天的完成情况，以及"只改今天"这类单天补丁。
///
/// 数据模型是一份任务清单（[PlanSet]），每条自带 [RepeatRule] 决定哪天出现。
/// 可以存多份清单来回切 —— 那就是"多套模板"，只不过每一套都归用户自己所有。
class StudyPlanStore {
  StudyPlanStore(this._prefs);

  final SharedPreferences _prefs;

  /// 计划关掉了：首页不再显示今日安排。
  static const offId = 'off';

  static const _setsKey = 'study_plan_sets';
  static const _activeKey = 'study_plan_active';
  static const _donePrefix = 'study_plan_done_';
  /// 只这一次的任务，落在具体某天。
  static const _extraPrefix = 'study_plan_extra_';
  /// 单天补丁："只改今天"改出来的那一份。
  static const _overridePrefix = 'study_plan_override_';
  /// 今天先跳过这条，不动任务本身。
  static const _hiddenPrefix = 'study_plan_hidden_';

  // 老键，只在迁移时读一次
  static const _legacyRecurringKey = 'study_plan_recurring';

  static Future<StudyPlanStore> create() async {
    final prefs = await SharedPreferences.getInstance();
    final store = StudyPlanStore(prefs);
    await store._migrateIfNeeded();
    return store;
  }

  // ------------------------------------------------------------------ 计划清单

  List<PlanSet> loadSets() {
    final raw = _prefs.getString(_setsKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      return (jsonDecode(raw) as List<dynamic>)
          .whereType<Map>()
          .map((e) => PlanSet.fromJson(Map<String, Object?>.from(e)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveSets(List<PlanSet> sets) async {
    await _prefs.setString(
      _setsKey,
      jsonEncode(sets.map((s) => s.toJson()).toList()),
    );
  }

  String get activeSetId => _prefs.getString(_activeKey) ?? offId;

  PlanSet? get activeSet {
    final id = activeSetId;
    if (id == offId) return null;
    for (final s in loadSets()) {
      if (s.id == id) return s;
    }
    return null;
  }

  bool get isEnabled => activeSet != null;

  Future<void> setActiveSet(String id) async {
    await _prefs.setString(_activeKey, id);
  }

  /// 新建一份清单并切过去。[tasks] 为空就是从零开始。
  Future<PlanSet> createSet(String name, {List<StudyTask> tasks = const []}) async {
    final set = PlanSet(
      id: 'set_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim().isEmpty ? '我的计划' : name.trim(),
      tasks: tasks,
    );
    await saveSets([...loadSets(), set]);
    await setActiveSet(set.id);
    return set;
  }

  /// 从起始包导入一份新清单。
  Future<PlanSet> importPack(StarterPack pack, {DateTime? from}) =>
      createSet(pack.name, tasks: pack.expand(from ?? DateTime.now()));

  Future<void> renameSet(String id, String name) async {
    final sets = loadSets()
        .map((s) => s.id == id ? s.copyWith(name: name.trim()) : s)
        .toList();
    await saveSets(sets);
  }

  /// 删掉一份清单。删的是当前那份就顺手切到别的，没有别的就关掉计划。
  Future<void> deleteSet(String id) async {
    final rest = loadSets().where((s) => s.id != id).toList();
    await saveSets(rest);
    if (activeSetId == id) {
      await setActiveSet(rest.isEmpty ? offId : rest.first.id);
    }
  }

  Future<void> _saveActive(PlanSet next) async {
    await saveSets(
      loadSets().map((s) => s.id == next.id ? next : s).toList(),
    );
  }

  // ---------------------------------------------------------------- 某天的安排

  DayPlan planFor(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    final set = activeSet;
    final hidden = loadHiddenIds(day);
    final overrides = loadOverrides(day);

    final recurring = (set?.tasks ?? const <StudyTask>[])
        .where((t) => !hidden.contains(t.id))
        .where((t) => t.repeat.occursOn(day, t.startedOn ?? day))
        .map((t) => overrides[t.id] ?? t)
        .toList();
    final extras = loadExtras(day)
        .where((t) => !hidden.contains(t.id))
        .map((t) => overrides[t.id] ?? t)
        .toList();

    return DayPlan(
      date: day,
      focus: set?.name ?? '',
      tasks: [...recurring, ...extras],
    );
  }

  // -------------------------------------------------------------------- 增删改

  /// 存一条任务。
  ///
  /// [RepeatRule.once] 落在 [date] 那一天，其余进当前清单 —— 存一份，往后每天
  /// 都照这份来。[scope] 为 [PlanEditScope.today] 时只写单天补丁，不动清单。
  Future<void> upsertTask(
    DateTime date,
    StudyTask task, {
    PlanEditScope scope = PlanEditScope.forever,
  }) async {
    final day = DateTime(date.year, date.month, date.day);

    if (scope == PlanEditScope.today && task.repeat != RepeatRule.once) {
      final overrides = loadOverrides(day)..[task.id] = task;
      await saveOverrides(day, overrides);
      return;
    }

    final set = activeSet;

    if (task.repeat == RepeatRule.once) {
      // 从重复变一次性：清掉清单里那条，免得两边各出现一次
      if (set != null && set.tasks.any((t) => t.id == task.id)) {
        await _saveActive(set.remove(task.id));
      }
      final extras = [...loadExtras(day)];
      final i = extras.indexWhere((e) => e.id == task.id);
      if (i < 0) {
        extras.add(task);
      } else {
        extras[i] = task;
      }
      await saveExtras(day, extras);
      return;
    }

    // 变成重复的：从那天的一次性列表里挪走
    await _removeExtra(day, task.id, keepDone: true);

    // 改的是任务本身，早先"只改今天"留下的补丁就该让位，否则今天看到的还是旧的
    final overrides = loadOverrides(day)..remove(task.id);
    await saveOverrides(day, overrides);

    final target = set ?? await createSet('我的计划');
    final startedOn = task.startedOn ??
        target.tasks.where((t) => t.id == task.id).map((t) => t.startedOn).firstOrNull ??
        day;
    await _saveActive(target.upsert(task.copyWith(startedOn: startedOn)));
  }

  /// 删一条任务。默认往后都不再出现；[PlanEditScope.today] 只跳过今天。
  Future<void> deleteTask(
    DateTime date,
    StudyTask task, {
    PlanEditScope scope = PlanEditScope.forever,
  }) async {
    final day = DateTime(date.year, date.month, date.day);

    if (scope == PlanEditScope.today) {
      await skipOnce(day, task.id);
      return;
    }

    final set = activeSet;
    if (set != null && set.tasks.any((t) => t.id == task.id)) {
      await _saveActive(set.remove(task.id));
    }
    await _removeExtra(day, task.id);
    final overrides = loadOverrides(day)..remove(task.id);
    await saveOverrides(day, overrides);
    final done = loadDoneIds(_dateKey(day))..remove(task.id);
    await saveDoneIds(_dateKey(day), done);
  }

  /// 今天先跳过这条，任务本身留着。
  Future<void> skipOnce(DateTime date, String taskId) async {
    await saveHiddenIds(date, loadHiddenIds(date)..add(taskId));
    final key = _dateKey(date);
    await saveDoneIds(key, loadDoneIds(key)..remove(taskId));
  }

  /// 改名：其余字段原样带走。
  Future<void> renameTask(
    DateTime date,
    StudyTask task,
    String title, {
    PlanEditScope scope = PlanEditScope.forever,
  }) =>
      upsertTask(date, task.copyWith(title: title.trim()), scope: scope);

  /// 清空当前清单里的所有任务，留一份空清单。
  Future<void> clearActiveTasks() async {
    final set = activeSet;
    if (set == null) return;
    await _saveActive(set.copyWith(tasks: const []));
  }

  // ------------------------------------------------------------ 一次性任务 / 完成

  List<StudyTask> loadExtras(DateTime date) {
    final raw = _prefs.getString('$_extraPrefix${_dateKey(date)}');
    if (raw == null || raw.isEmpty) return const [];
    try {
      return (jsonDecode(raw) as List<dynamic>)
          .whereType<Map>()
          .map((e) => StudyTask.fromJson(Map<String, Object?>.from(e)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveExtras(DateTime date, List<StudyTask> tasks) async {
    final key = '$_extraPrefix${_dateKey(date)}';
    if (tasks.isEmpty) {
      await _prefs.remove(key);
      return;
    }
    await _prefs.setString(key, jsonEncode(tasks.map((t) => t.toJson()).toList()));
  }

  Future<void> _removeExtra(DateTime date, String taskId, {bool keepDone = false}) async {
    final extras = loadExtras(date);
    if (!extras.any((t) => t.id == taskId)) return;
    await saveExtras(date, extras.where((t) => t.id != taskId).toList());
    if (keepDone) return;
    final key = _dateKey(date);
    await saveDoneIds(key, loadDoneIds(key)..remove(taskId));
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

  // ------------------------------------------------------------------ 单天补丁

  Map<String, StudyTask> loadOverrides(DateTime date) {
    final raw = _prefs.getString('$_overridePrefix${_dateKey(date)}');
    if (raw == null || raw.isEmpty) return {};
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map.map(
        (k, v) => MapEntry(
          k,
          StudyTask.fromJson(Map<String, Object?>.from(v as Map)),
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
    await _prefs.setString(
      key,
      jsonEncode(overrides.map((k, v) => MapEntry(k, v.toJson()))),
    );
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

  // -------------------------------------------------------------------- 连续天

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

  // ---------------------------------------------------------------------- 迁移

  /// 老数据搬到新模型，只跑一次。
  ///
  /// 老版本存的是"选了哪个内置模板"+ 一堆按天的补丁。搬过来的原则是让用户
  /// 之前的编辑**变成永久的** —— 他当初改今天，本来就是想以后都这样，
  /// 只是老版本做不到。打过的勾按任务 id 存，id 不变就都还在。
  Future<void> _migrateIfNeeded() async {
    if (_prefs.containsKey(_setsKey)) return;

    final legacyTemplate = _prefs.getString(Prefs.studyPlanTemplate);

    // 全新用户：给最没争议的三条打底，不给那套 6:00 起床的作息表
    if (legacyTemplate == null) {
      final set = StarterPacks.minimal.toPlanSet(id: 'mine', name: '我的计划');
      await saveSets([set]);
      await setActiveSet(set.id);
      return;
    }

    if (legacyTemplate == offId) {
      await saveSets(const []);
      await setActiveSet(offId);
      await _prefs.remove(Prefs.studyPlanTemplate);
      return;
    }

    final pack = StarterPacks.byId(legacyTemplate) ?? StarterPacks.minimal;
    final tasks = <String, StudyTask>{
      for (final t in pack.expand(DateTime.now())) t.id: t,
    };

    // 老的自定义重复任务原样并进来
    final recurringRaw = _prefs.getString(_legacyRecurringKey);
    if (recurringRaw != null && recurringRaw.isNotEmpty) {
      try {
        for (final e in (jsonDecode(recurringRaw) as List<dynamic>).whereType<Map>()) {
          final t = StudyTask.fromJson(Map<String, Object?>.from(e));
          tasks[t.id] = t;
        }
      } catch (_) {
        // 存坏了就算了，丢几条自定义任务比整个计划打不开强
      }
    }

    // 用户改过的：老版本只能写成单天补丁，取每条最新的那份提成永久
    final overrideKeys = _prefs
        .getKeys()
        .where((k) => k.startsWith(_overridePrefix))
        .toList()
      ..sort(); // key 里带 yyyy-MM-dd，字典序就是时间序
    for (final key in overrideKeys) {
      final date = DateTime.tryParse(key.substring(_overridePrefix.length));
      if (date == null) continue;
      for (final e in loadOverrides(date).entries) {
        final existing = tasks[e.key];
        if (existing == null) continue;
        tasks[e.key] = e.value.copyWith(
          repeat: existing.repeat,
          startedOn: existing.startedOn,
        );
      }
      await _prefs.remove(key);
    }

    final set = PlanSet(id: 'mine', name: '我的计划', tasks: tasks.values.toList());
    await saveSets([set]);
    await setActiveSet(set.id);
    await _prefs.remove(Prefs.studyPlanTemplate);
    await _prefs.remove(_legacyRecurringKey);
  }

  static String _dateKey(DateTime date) {
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '${date.year}-$m-$d';
  }
}
