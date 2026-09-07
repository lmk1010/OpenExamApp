class AppConstants {
  static const appName = 'OpenExam App';
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
