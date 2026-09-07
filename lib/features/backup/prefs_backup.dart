import 'package:openexam_app/core/constants/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 备份里的「设置与学习计划」。
///
/// 以前备份只导数据库 —— 答题记录、错题、成绩单都在，可**自己排的学习计划
/// 一条都不在**。计划存在 SharedPreferences 里（[StudyPlanStore] 那一套
/// `study_plan_*` 键），换台手机、重装一次，攒了几个月的计划就没了，而它恰恰
/// 是最花心思、最难重排的东西。
///
/// 用白名单而不是"导出全部 prefs"：AI 的 API Key 也在 SharedPreferences 里，
/// 全导会把密钥写进一个用户随手分享的 JSON。这里只认下面这些键。
class PrefsBackup {
  const PrefsBackup._();

  /// 按前缀整片带走的。计划的完成情况、单天补丁都是「前缀 + 日期」的键，
  /// 数量不定，只能按前缀捞。
  static const _prefixes = <String>['study_plan_'];

  /// 逐个点名带走的。**新增设置项要往这里补**，否则它不会进备份。
  static const _keys = <String>[
    Prefs.examDate,
    Prefs.dailyGoal,
    Prefs.defaultCount,
    Prefs.nickname,
    Prefs.province,
    Prefs.autoNext,
    Prefs.fontScale,
    Prefs.themeMode,
    Prefs.practiceViewMode,
    Prefs.navRailHidden,
    Prefs.studyPlanTemplate,
  ];

  static bool _wanted(String key) =>
      _keys.contains(key) || _prefixes.any(key.startsWith);

  /// 导出成一个 JSON 能装下的 map。
  static Future<Map<String, Object?>> export() async {
    final prefs = await SharedPreferences.getInstance();
    final out = <String, Object?>{};
    for (final key in prefs.getKeys()) {
      if (!_wanted(key)) continue;
      final value = prefs.get(key);
      // List<String> 原样进 JSON 没问题，其余都是标量。
      if (value != null) out[key] = value;
    }
    return out;
  }

  /// 写回去。返回恢复了几条。
  ///
  /// 老备份没有这一节，传 null 就当没有 —— 不能因此把用户现有的计划清空。
  static Future<int> import(Object? raw) async {
    if (raw is! Map) return 0;
    final prefs = await SharedPreferences.getInstance();
    var n = 0;
    for (final entry in raw.entries) {
      final key = '${entry.key}';
      if (!_wanted(key)) continue;
      final value = entry.value;
      if (value is String) {
        await prefs.setString(key, value);
      } else if (value is bool) {
        await prefs.setBool(key, value);
      } else if (value is int) {
        await prefs.setInt(key, value);
      } else if (value is double) {
        await prefs.setDouble(key, value);
      } else if (value is List) {
        await prefs.setStringList(key, value.map((e) => '$e').toList());
      } else {
        continue;
      }
      n++;
    }
    return n;
  }
}
