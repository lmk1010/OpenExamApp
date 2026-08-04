import 'package:flutter/material.dart';
import 'package:openexam_app/core/theme/app_tokens.dart';

/// Fake-glass decorations: a light-to-transparent sheen, a bright top edge and
/// a two-layer shadow. Reads like frosted acrylic but costs nothing to raster —
/// no BackdropFilter, so it stays smooth while scrolling.
class GlassDecor {
  const GlassDecor._();

  /// Panel / sheet material sitting on the ambient backdrop.
  static BoxDecoration panel(
    AppTokens t, {
    double radius = 22,
    bool raised = true,
  }) {
    final dark = t.name == 'dark';
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: dark
            ? [
                Colors.white.withValues(alpha: 0.10),
                Colors.white.withValues(alpha: 0.035),
              ]
            : [
                Colors.white.withValues(alpha: 0.88),
                Colors.white.withValues(alpha: 0.62),
              ],
      ),
      border: Border.all(
        color: Colors.white.withValues(alpha: dark ? 0.09 : 0.65),
        width: 1,
      ),
      boxShadow: raised
          ? [
              BoxShadow(
                color: dark
                    ? Colors.black.withValues(alpha: 0.42)
                    : const Color(0xFF3B3B6B).withValues(alpha: 0.10),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: dark
                    ? Colors.black.withValues(alpha: 0.22)
                    : const Color(0xFF3B3B6B).withValues(alpha: 0.05),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ]
          : null,
    );
  }

  /// Saturated tile — feature cards and category covers. The sheen sits on top
  /// of the brand colour instead of on the backdrop.
  static BoxDecoration tinted(
    AppTokens t,
    Color color, {
    double radius = 20,
    bool glow = true,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.lerp(color, Colors.white, 0.14)!,
          color,
          Color.lerp(color, Colors.black, 0.10)!,
        ],
        stops: const [0, 0.55, 1],
      ),
      border: Border.all(color: Colors.white.withValues(alpha: 0.16), width: 1),
      boxShadow: glow
          ? [
              BoxShadow(
                color: color.withValues(alpha: t.name == 'dark' ? 0.34 : 0.28),
                blurRadius: 20,
                offset: const Offset(0, 9),
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
