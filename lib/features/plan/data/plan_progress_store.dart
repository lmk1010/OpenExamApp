import 'package:openexam_app/features/plan/domain/models/daily_plan.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PlanProgressStore {
  PlanProgressStore(this._prefs);

  static const _taskStatePrefix = 'plan_task_state_';
  final SharedPreferences _prefs;

  static Future<PlanProgressStore> create() async {
    final prefs = await SharedPreferences.getInstance();
    return PlanProgressStore(prefs);
  }

  Map<String, Set<int>> loadAllTaskStates(List<DailyPlan> plans) {
    final result = <String, Set<int>>{};
    for (final plan in plans) {
      result[plan.dateKey] = loadCompletedTaskIndices(plan.dateKey);
    }
    return result;
  }

  Set<int> loadCompletedTaskIndices(String dateKey) {
    final raw = _prefs.getString(_taskKey(dateKey));
    if (raw == null || raw.isEmpty) {
      return <int>{};
    }

    final values = raw.split(',');
    final parsed = <int>{};
    for (final value in values) {
      final index = int.tryParse(value);
      if (index != null && index >= 0) {
        parsed.add(index);
      }
    }
    return parsed;
  }

  Future<void> saveCompletedTaskIndices(
    String dateKey,
    Set<int> indices,
  ) async {
    final normalized = indices.toList()..sort();
    if (normalized.isEmpty) {
      await _prefs.remove(_taskKey(dateKey));
      return;
    }
    final raw = normalized.join(',');
    await _prefs.setString(_taskKey(dateKey), raw);
  }

  String _taskKey(String dateKey) => '$_taskStatePrefix$dateKey';
}
