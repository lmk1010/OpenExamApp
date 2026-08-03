import 'package:flutter/material.dart';
import 'package:openexam_app/core/constants/app_constants.dart';
import 'package:openexam_app/core/ui/stroke_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the selected theme mode and persists it across launches.
class ThemeController extends ChangeNotifier {
  ThemeController._();
  static final ThemeController instance = ThemeController._();

  static const _key = Prefs.themeMode;

  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    _mode = switch (saved) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    notifyListeners();
  }

  Future<void> set(ThemeMode mode) async {
    if (mode == _mode) return;
    _mode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.name);
  }

  /// Cycles 跟随系统 → 浅色 → 深色, used by the header toggle.
  Future<void> cycle() async {
    await set(switch (_mode) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    });
  }

  String get label => switch (_mode) {
        ThemeMode.system => '跟随系统',
        ThemeMode.light => '浅色',
        ThemeMode.dark => '深色',
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
