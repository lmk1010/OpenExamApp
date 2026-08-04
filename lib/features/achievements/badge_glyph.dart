import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 徽章主纹 — solid emblems drawn for the medal face. The app's stroke icons
/// are built for 20dp toolbars; blown up to a medal they read as thin wire.
/// These are filled shapes with real mass, so they can be struck into metal.
enum BadgeGlyph { nib, flame, target, scroll, peak, crown }

BadgeGlyph glyphForGroup(String group) => switch (group) {
      '题量' => BadgeGlyph.nib,
      '坚持' => BadgeGlyph.flame,
      '精度' => BadgeGlyph.target,
      '考场' => BadgeGlyph.scroll,
      '攻坚' => BadgeGlyph.peak,
      _ => BadgeGlyph.crown,
    };

/// Builds the emblem centred on [c], sized to fit a box of half-extent [r].
Path badgeGlyphPath(BadgeGlyph glyph, Offset c, double r) {
  final p = Path()..fillType = PathFillType.evenOdd;
  double x(double v) => c.dx + v * r;
  double y(double v) => c.dy + v * r;

  switch (glyph) {
    case BadgeGlyph.nib:
      // A fountain-pen nib: shoulders, taper to a point, slit and vent hole.
      p.moveTo(x(-0.62), y(-0.95));
      p.lineTo(x(0.62), y(-0.95));
      p.quadraticBezierTo(x(0.70), y(-0.20), x(0.30), y(0.42));
      p.lineTo(x(0), y(0.98));
      p.lineTo(x(-0.30), y(0.42));
      p.quadraticBezierTo(x(-0.70), y(-0.20), x(-0.62), y(-0.95));
      p.close();
      // Slit.
      p.moveTo(x(-0.075), y(0.10));
      p.lineTo(x(0.075), y(0.10));
      p.lineTo(x(0), y(0.72));
      p.close();
      // Vent hole.
      p.addOval(Rect.fromCircle(center: Offset(x(0), y(-0.14)), radius: r * 0.17));
      // Shoulder groove.
      p.addRect(Rect.fromLTRB(x(-0.48), y(-0.78), x(0.48), y(-0.66)));

    case BadgeGlyph.flame:
      // Outer flame.
      p.moveTo(x(0), y(-1.0));
      p.cubicTo(x(0.52), y(-0.52), x(0.78), y(-0.10), x(0.72), y(0.28));
      p.cubicTo(x(0.66), y(0.74), x(0.36), y(1.0), x(0), y(1.0));
      p.cubicTo(x(-0.36), y(1.0), x(-0.66), y(0.74), x(-0.72), y(0.28));
      p.cubicTo(x(-0.78), y(-0.10), x(-0.52), y(-0.52), x(0), y(-1.0));
      p.close();
      // Inner flame, cut out so the metal shows through.
      p.moveTo(x(0), y(-0.16));
      p.cubicTo(x(0.30), y(0.10), x(0.36), y(0.36), x(0.24), y(0.58));
      p.cubicTo(x(0.14), y(0.76), x(-0.14), y(0.76), x(-0.24), y(0.58));
      p.cubicTo(x(-0.36), y(0.36), x(-0.30), y(0.10), x(0), y(-0.16));
      p.close();

    case BadgeGlyph.target:
      // Three rings and a bullseye — even-odd turns the pairs into bands.
      for (final rr in const [1.0, 0.86, 0.64, 0.50, 0.28]) {
        p.addOval(Rect.fromCircle(center: c, radius: r * rr));
      }
      p.addOval(Rect.fromCircle(center: c, radius: r * 0.14));

    case BadgeGlyph.scroll:
      // A sheet with a folded corner and three lines of writing.
      p.moveTo(x(-0.74), y(-0.96));
      p.lineTo(x(0.30), y(-0.96));
      p.lineTo(x(0.76), y(-0.46));
      p.lineTo(x(0.76), y(0.96));
      p.lineTo(x(-0.74), y(0.96));
      p.close();
      // Fold.
      p.moveTo(x(0.30), y(-0.96));
      p.lineTo(x(0.30), y(-0.46));
      p.lineTo(x(0.76), y(-0.46));
      p.close();
      for (var i = 0; i < 3; i++) {
        final ly = -0.16 + i * 0.36;
        p.addRRect(
          RRect.fromLTRBR(
            x(-0.46),
            y(ly),
            x(i == 2 ? 0.16 : 0.48),
            y(ly + 0.15),
            Radius.circular(r * 0.07),
          ),
        );
      }

    case BadgeGlyph.peak:
      // Twin summits with a snow cap cut into the taller one.
      p.moveTo(x(-1.0), y(0.76));
      p.lineTo(x(-0.30), y(-0.34));
      p.lineTo(x(0.02), y(0.10));
      p.lineTo(x(0.36), y(-0.86));
      p.lineTo(x(1.0), y(0.76));
      p.close();
      // Snow.
      p.moveTo(x(0.36), y(-0.86));
      p.lineTo(x(0.62), y(-0.22));
      p.lineTo(x(0.46), y(-0.32));
      p.lineTo(x(0.30), y(-0.16));
      p.lineTo(x(0.16), y(-0.30));
      p.close();

    case BadgeGlyph.crown:
      p.moveTo(x(-0.94), y(-0.52));
      p.lineTo(x(-0.44), y(0.06));
      p.lineTo(x(0), y(-0.76));
      p.lineTo(x(0.44), y(0.06));
      p.lineTo(x(0.94), y(-0.52));
      p.lineTo(x(0.74), y(0.62));
      p.lineTo(x(-0.74), y(0.62));
      p.close();
      for (final dx in const [-0.42, 0.0, 0.42]) {
        p.addOval(Rect.fromCircle(center: Offset(x(dx), y(0.30)), radius: r * 0.11));
      }
  }
  return p;
}

/// Paints the emblem struck into metal: a dark impression, the lit face, then
/// a hairline that keeps the edges crisp at small sizes.
void paintBadgeGlyph(
  Canvas canvas,
  BadgeGlyph glyph,
  Offset center,
  double r, {
  required List<Color> metal,
  required bool unlocked,
  required Color flat,
}) {
  if (!unlocked) {
    canvas.drawPath(
      badgeGlyphPath(glyph, center, r),
      Paint()..color = flat,
    );
    return;
  }

  canvas.drawPath(
    badgeGlyphPath(glyph, center + Offset(0, r * 0.075), r),
    Paint()..color = Colors.black.withValues(alpha: 0.45),
  );
  final face = badgeGlyphPath(glyph, center, r);
  canvas.drawPath(
    face,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [metal[0], metal[4], metal[2]],
        stops: const [0, 0.55, 1],
      ).createShader(Rect.fromCircle(center: center, radius: r * 1.1)),
  );
  canvas.drawPath(
    face,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.8, r * 0.035)
      ..color = Colors.black.withValues(alpha: 0.28),
  );
}
