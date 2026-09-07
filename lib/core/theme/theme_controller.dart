import 'package:flutter/material.dart';
import 'package:openexam_app/l10n/app_localizations.dart';
import 'package:openexam_app/core/constants/app_constants.dart';
import 'package:openexam_app/core/theme/app_tokens.dart';
import 'package:openexam_app/core/ui/stroke_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 明暗模式。
///
/// 这里原来还挂着两套吉祥物皮肤（企鹅、狐狸）。它们是 3D 手办画风，
/// 跟「上岸」的扁平海景不在一个世界里，切过去等于换了一个 app；
/// 而且它们只有浅色一档，选了就锁死明暗切换。删掉。
class ThemeController extends ChangeNotifier {
  ThemeController._();
  static final ThemeController instance = ThemeController._();

  static const _modeKey = Prefs.themeMode;

  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_modeKey);
    _mode = switch (saved) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    // 老版本存过 guga / spark，现在没有对应的调色板了，顺手清掉。
    await prefs.remove(Prefs.themePalette);
    notifyListeners();
  }

  Future<void> set(ThemeMode mode) async {
    if (mode == _mode) return;
    _mode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modeKey, mode.name);
  }

  /// 跟随系统 → 浅色 → 深色，顶栏那颗圆钮按的就是它。
  Future<void> cycle() => set(switch (_mode) {
        ThemeMode.system => ThemeMode.light,
        ThemeMode.light => ThemeMode.dark,
        ThemeMode.dark => ThemeMode.system,
      });

  AppTokens tokensFor(Brightness brightness) =>
      brightness == Brightness.dark ? AppTokens.dark : AppTokens.light;

  ThemeMode get effectiveMode => _mode;

  String label(AppL l) => switch (_mode) {
        ThemeMode.system => l.settingsLanguageSystem,
        ThemeMode.light => l.profileThemeLight,
        ThemeMode.dark => l.profileThemeDark,
      };

  IconData get icon => switch (_mode) {
        ThemeMode.system => Icons.brightness_auto_outlined,
        ThemeMode.light => Icons.light_mode_outlined,
        ThemeMode.dark => Icons.dark_mode_outlined,
      };
}

extension ThemeIconX on IconData {
  /// Maps the controller's Material glyph onto the hand-drawn set.
  AppIcon toAppIcon() {
    if (this == Icons.light_mode_outlined) return AppIcon.sun;
    if (this == Icons.dark_mode_outlined) return AppIcon.moon;
    return AppIcon.auto;
  }
}
