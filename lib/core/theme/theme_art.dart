import 'package:flutter/material.dart';
import 'package:openexam_app/core/theme/theme_controller.dart';

/// Cute-theme illustration catalog. Classic palette has no mascot art.
class ThemeArt {
  const ThemeArt._();

  static String get palette => ThemeController.instance.palette;

  static bool get hasMascot => palette == 'guga' || palette == 'spark';

  /// Hero / picker main portrait.
  static String? get mascot {
    switch (palette) {
      case 'guga':
        return 'assets/themes/guga_mascot.png';
      case 'spark':
        return 'assets/themes/spark_mascot.png';
      default:
        return null;
    }
  }

  /// Studying pose — home hero when not yet hit today's goal.
  static String? get study {
    switch (palette) {
      case 'guga':
        return 'assets/themes/guga_study.png';
      case 'spark':
        return 'assets/themes/spark_study.png';
      default:
        return null;
    }
  }

  /// Celebrate pose — used when today's goal is done (guga only for now).
  static String? get cheer {
    switch (palette) {
      case 'guga':
        return 'assets/themes/guga_cheer.png';
      case 'spark':
        return 'assets/themes/spark_mascot.png';
      default:
        return null;
    }
  }

  static String? assetForPalette(String id) {
    switch (id) {
      case 'guga':
        return 'assets/themes/guga_mascot.png';
      case 'spark':
        return 'assets/themes/spark_mascot.png';
      default:
        return null;
    }
  }

  /// Pick home-hero art: cheer when goal done, else study pose, else mascot.
  static String? heroAsset({required bool goalDone}) {
    if (!hasMascot) return null;
    if (goalDone) return cheer ?? mascot;
    return study ?? mascot;
  }
}

/// Soft cutout portrait used on home / empty / picker.
class ThemeMascot extends StatelessWidget {
  const ThemeMascot({
    super.key,
    required this.asset,
    this.width = 120,
    this.height = 120,
  });

  final String asset;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Image.asset(
        asset,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      ),
    );
  }
}
