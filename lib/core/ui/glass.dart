import 'package:flutter/material.dart';
import 'package:openexam_app/core/theme/app_tokens.dart';

/// Fake-glass decorations: a light-to-transparent sheen, a bright top edge and
/// a two-layer shadow. Reads like frosted acrylic but costs nothing to raster —
/// no BackdropFilter, so it stays smooth while scrolling.
class GlassDecor {
  const GlassDecor._();

  /// Panel / sheet material sitting on the ambient backdrop.
  /// 卡面。
  ///
  /// 上一版是半透明的白 0.88→0.62 加一圈白描边 —— 那是"玻璃"的做法：
  /// 背景一变，卡就跟着变色，白边在浅底上又几乎看不见，
  /// 剩下的观感就是一层塑料膜。现在是实底 + 一层软阴影，
  /// 卡就是卡，边界靠阴影而不是描边。
  static BoxDecoration panel(
    AppTokens t, {
    double radius = 22,
    bool raised = true,
  }) {
    return BoxDecoration(
      color: t.surface,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: raised ? t.shadow : null,
      border: raised ? null : Border.all(color: t.lineSoft, width: 1.5),
    );
  }

  /// Saturated tile — feature cards and category covers. The sheen sits on top
  /// of the brand colour instead of on the backdrop.
  /// 实色块 —— 需要一整块颜色的地方（强调卡、分类封面）。
  ///
  /// 原来是三段渐变加白描边加同色投影，一块颜色要用五个图层说，
  /// 放大了看是"湿玻璃"，缩到卡片尺寸就只剩脏。
  static BoxDecoration tinted(
    AppTokens t,
    Color color, {
    double radius = 20,
    bool glow = true,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: glow
          ? [
              BoxShadow(
                color: color.withValues(alpha: 0.30),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ]
          : null,
    );
  }

  /// Readable foreground for text sitting on [color]. Dark-theme category
  /// colours are light enough that white text on them fails contrast.
  static Color on(Color color) =>
      color.computeLuminance() > 0.55 ? const Color(0xFF14161C) : Colors.white;

  /// Specular highlight laid over a tinted tile — the "wet glass" top-left curve.
  static Widget sheen({double radius = 20, double opacity = 0.22}) {
    return Positioned.fill(
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.center,
              colors: [
                Colors.white.withValues(alpha: opacity),
                Colors.white.withValues(alpha: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
