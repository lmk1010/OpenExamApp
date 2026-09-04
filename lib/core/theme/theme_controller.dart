import 'package:flutter/material.dart';
import 'package:openexam_app/core/constants/app_constants.dart';
import 'package:openexam_app/core/theme/app_tokens.dart';
import 'package:openexam_app/core/ui/stroke_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme mode (light/dark/system) + cute palettes (classic / guga / spark).
class ThemeController extends ChangeNotifier {
  ThemeController._();
  static final ThemeController instance = ThemeController._();

  static const _modeKey = Prefs.themeMode;
  static const _paletteKey = Prefs.themePalette;

  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;

  /// `classic` | `guga` | `spark`
  String _palette = 'classic';
  String get palette => _palette;

  static const palettes = <({String id, String label, String? asset})>[
    (id: 'classic', label: '经典', asset: null),
    (id: 'guga', label: '咕咕嘎嘎', asset: 'assets/themes/guga_mascot.png'),
    (id: 'spark', label: '皮卡丘黄', asset: 'assets/themes/spark_mascot.png'),
  ];

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_modeKey);
    _mode = switch (saved) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    final p = prefs.getString(_paletteKey);
    if (p != null && palettes.any((e) => e.id == p)) _palette = p;
    notifyListeners();
  }

  Future<void> set(ThemeMode mode) async {
    if (mode == _mode) return;
    _mode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modeKey, mode.name);
  }

  Future<void> setPalette(String id) async {
    if (id == _palette) return;
    if (!palettes.any((e) => e.id == id)) return;
    _palette = id;
    // Cute themes are authored as light palettes — avoid muddy dark mapping.
    if (id != 'classic' && _mode == ThemeMode.dark) {
      _mode = ThemeMode.light;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_modeKey, _mode.name);
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_paletteKey, id);
  }

  /// Cycles 跟随系统 → 浅色 → 深色, used by the header toggle.
  Future<void> cycle() async {
    if (_palette != 'classic') {
      // On cute themes, cycle through palettes instead.
      final ids = palettes.map((e) => e.id).toList();
      final i = ids.indexOf(_palette);
      await setPalette(ids[(i + 1) % ids.length]);
      return;
    }
    await set(switch (_mode) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    });
  }

  /// Tokens for the current palette at a given brightness.
  AppTokens tokensFor(Brightness brightness) {
    switch (_palette) {
      case 'guga':
        return AppTokens.guga;
      case 'spark':
        return AppTokens.spark;
      default:
        return brightness == Brightness.dark ? AppTokens.dark : AppTokens.light;
    }
  }

  /// Effective Material themeMode — cute palettes stay light.
  ThemeMode get effectiveMode =>
      _palette == 'classic' ? _mode : ThemeMode.light;

  String get label {
    if (_palette != 'classic') {
      return palettes.firstWhere((e) => e.id == _palette).label;
    }
    return switch (_mode) {
      ThemeMode.system => '跟随系统',
      ThemeMode.light => '浅色',
      ThemeMode.dark => '深色',
    };
  }

  IconData get icon {
    if (_palette == 'guga' || _palette == 'spark') {
      return Icons.palette_outlined;
    }
    return switch (_mode) {
      ThemeMode.system => Icons.brightness_auto_outlined,
      ThemeMode.light => Icons.light_mode_outlined,
      ThemeMode.dark => Icons.dark_mode_outlined,
    };
  }
}

extension ThemeIconX on IconData {
  /// Maps the controller's Material glyph onto the hand-drawn set.
  AppIcon toAppIcon() {
    if (this == Icons.light_mode_outlined) return AppIcon.sun;
    if (this == Icons.dark_mode_outlined) return AppIcon.moon;
    if (this == Icons.palette_outlined) return AppIcon.shuffle;
    return AppIcon.auto;
  }
}
