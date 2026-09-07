class AppConstants {
  static const appName = 'OpenExam App';

  /// 「关于」里显示的版本号。
  ///
  /// 必须跟 pubspec.yaml 的 version 一致 —— app_version_test 会去比。
  /// 之前这里是写死在设置页里的 'v1.0.1'，pubspec 都到 1.1.0 了它还挂着
  /// 上一版的号，用户报 bug 报的是个不存在的版本。
  static const appVersion = '1.1.0';
}

/// Shared preference keys.
class Prefs {
  const Prefs._();

  static const defaultCount = 'default_count';
  static const nickname = 'nickname';
  static const examDate = 'exam_date';
  static const themeMode = 'theme_mode';

  /// 旧的皮肤键，只留着给 ThemeController 启动时清一次遗留值。
  static const themePalette = 'theme_palette';
  static const fontScale = 'font_scale';
  static const autoNext = 'auto_next';
  static const dailyGoal = 'daily_goal';
  static const onboarded = 'onboarded';
  static const province = 'province';

  /// Active study-plan template id (`working` / `light` / `off`).
  static const studyPlanTemplate = 'study_plan_template';

  /// Wide layout: hide the left nav rail for a wider content pane.
  static const navRailHidden = 'nav_rail_hidden';

  /// Practice session layout: `single` | `dual` | `scroll`.
  static const practiceViewMode = 'practice_view_mode';
}
