import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:openexam_app/core/theme/app_tokens.dart';

/// Which scene an onboarding slide shows.
enum SceneKind { bank, review, rhythm }

/// Flat vector scene, drawn rather than shipped as an asset: it follows the
/// theme, stays sharp at any size, and each element can animate in.
class OnboardingScene extends StatefulWidget {
  const OnboardingScene({super.key, required this.kind, required this.active});

  final SceneKind kind;

  /// Replays the entrance animation whenever this slide becomes visible.
  final bool active;

  @override
  State<OnboardingScene> createState() => _OnboardingSceneState();
}

class _OnboardingSceneState extends State<OnboardingScene>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void initState() {
    super.initState();
    if (widget.active) _controller.forward();
  }

  @override
  void didUpdateWidget(covariant OnboardingScene old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) {
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return AspectRatio(
      aspectRatio: 1.15,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          painter: _ScenePainter(
            kind: widget.kind,
            progress: _controller.value,
            tokens: t,
          ),
        ),
      ),
    );
  }
}

class _ScenePainter extends CustomPainter {
  _ScenePainter({
    required this.kind,
    required this.progress,
    required this.tokens,
  });

  final SceneKind kind;
  final double progress;
  final AppTokens tokens;

  bool get _dark => tokens.name == 'dark';

  Color get _paper => _dark ? const Color(0xFF243244) : Colors.white;
  Color get _paperEdge =>
      _dark ? const Color(0xFF35486A) : const Color(0xFFD9E4F5);
  Color get _ink => _dark ? const Color(0xFF8FA6C4) : const Color(0xFFB9CBE6);
  Color get _blue => tokens.brand;
  Color get _blueSoft =>
      _dark ? const Color(0xFF2B4A78) : const Color(0xFFCBDDF6);
  Color get _amber => tokens.category('shuliang');

  /// Eased 0→1 for an element that starts at [start] and lasts [span].
  double _at(double start, [double span = 0.45]) {
    final v = ((progress - start) / span).clamp(0.0, 1.0);
    return Curves.easeOutBack.transform(v.clamp(0.0, 1.0));
  }

  double _fade(double start, [double span = 0.4]) =>
      ((progress - start) / span).clamp(0.0, 1.0);

  @override
  void paint(Canvas canvas, Size size) {
    // Everything is authored on a 340×296 grid and scaled to fit.
    final scale = size.width / 340;
    canvas.save();
    canvas.scale(scale);
    final h = size.height / scale;

    _backdrop(canvas, Size(340, h));
    switch (kind) {
      case SceneKind.bank:
        _bank(canvas, h);
      case SceneKind.review:
        _review(canvas, h);
      case SceneKind.rhythm:
        _rhythm(canvas, h);
    }
    canvas.restore();
  }

  // ------------------------------------------------------------------ shared

  void _backdrop(Canvas canvas, Size size) {
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          _blue.withValues(alpha: _dark ? 0.20 : 0.14),
          _blue.withValues(alpha: 0),
        ],
      ).createShader(
        Rect.fromCircle(center: Offset(170, size.height * 0.52), radius: 160),
      );
    canvas.drawCircle(Offset(170, size.height * 0.52), 160, glow);
  }

  void _card(
    Canvas canvas,
    Rect rect, {
    double radius = 12,
    Color? fill,
    bool border = true,
  }) {
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    canvas.drawRRect(rrect, Paint()..color = fill ?? _paper);
    if (border) {
      canvas.drawRRect(
        rrect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = _paperEdge,
      );
    }
  }

  void _lines(Canvas canvas, Offset origin, List<double> widths,
      {double gap = 11, double weight = 5, Color? color}) {
    final paint = Paint()
      ..color = color ?? _ink
      ..strokeWidth = weight
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < widths.length; i++) {
      final y = origin.dy + i * gap;
      canvas.drawLine(Offset(origin.dx, y), Offset(origin.dx + widths[i], y), paint);
    }
  }

  void _sparkle(Canvas canvas, Offset c, double r, Color color, double t) {
    if (t <= 0) return;
    final paint = Paint()
      ..color = color.withValues(alpha: t.clamp(0, 1))
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final rr = r * t;
    canvas.drawLine(Offset(c.dx - rr, c.dy), Offset(c.dx + rr, c.dy), paint);
    canvas.drawLine(Offset(c.dx, c.dy - rr), Offset(c.dx, c.dy + rr), paint);
  }

  // ------------------------------------------------------- scene 1: the bank

  void _bank(Canvas canvas, double h) {
    final baseY = h * 0.5;

    // Stacked papers fanning out behind the phone.
    for (var i = 2; i >= 0; i--) {
      final t = _at(0.02 + i * 0.06);
      if (t <= 0) continue;
      canvas.save();
      canvas.translate(170, baseY);
      canvas.rotate((-0.18 + i * 0.12) * t);
      canvas.translate(-170, -baseY);
      final rect = Rect.fromCenter(
        center: Offset(170 + (i - 1) * 12, baseY - 6),
        width: 150 * t,
        height: 190 * t,
      );
      _card(canvas, rect, radius: 14, fill: i == 0 ? _paper : _blueSoft);
      if (i == 0) {
        _lines(canvas, Offset(rect.left + 22, rect.top + 34),
            [72, 96, 60], gap: 14);
      }
      canvas.restore();
    }

    // Phone in front, holding a question.
    final phoneT = _at(0.2);
    if (phoneT > 0) {
      final phone = Rect.fromCenter(
        center: Offset(170, baseY + 8),
        width: 126 * phoneT,
        height: 210 * phoneT,
      );
      _card(canvas, phone, radius: 20, fill: _paper);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(phone.left + 10, phone.top + 16, phone.width - 20, 44),
          const Radius.circular(10),
        ),
        Paint()..color = _blue.withValues(alpha: 0.16),
      );
      _lines(canvas, Offset(phone.left + 20, phone.top + 30), [58, 40],
          gap: 13, color: _blue.withValues(alpha: 0.75));

      // Answer options, the last one ticked.
      for (var i = 0; i < 3; i++) {
        final t = _fade(0.42 + i * 0.09, 0.25);
        if (t <= 0) continue;
        final y = phone.top + 78 + i * 34;
        final r = Rect.fromLTWH(phone.left + 12, y, phone.width - 24, 26);
        canvas.drawRRect(
          RRect.fromRectAndRadius(r, const Radius.circular(8)),
          Paint()
            ..color = (i == 2 ? _blue : _ink)
                .withValues(alpha: (i == 2 ? 0.9 : 0.22) * t),
        );
        if (i == 2) {
          final p = Path()
            ..moveTo(r.right - 34, y + 13)
            ..lineTo(r.right - 26, y + 20)
            ..lineTo(r.right - 12, y + 6);
          canvas.drawPath(
            p,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3
              ..strokeCap = StrokeCap.round
              ..strokeJoin = StrokeJoin.round
              ..color = Colors.white.withValues(alpha: t),
          );
        }
      }
    }

    // Floating chips: a figure tile and an offline badge.
    final chipT = _at(0.55, 0.4);
    if (chipT > 0) {
      final tile = Rect.fromCenter(
        center: Offset(74, baseY - 44),
        width: 74 * chipT,
        height: 74 * chipT,
      );
      _card(canvas, tile, radius: 16);
      final g = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = _amber;
      canvas.drawRect(Rect.fromLTWH(tile.left + 16, tile.top + 16, 20, 20), g);
      canvas.drawCircle(Offset(tile.right - 24, tile.bottom - 24), 11, g);
    }

    final badgeT = _at(0.66, 0.34);
    if (badgeT > 0) {
      final badge = Rect.fromCenter(
        center: Offset(268, baseY + 40),
        width: 96 * badgeT,
        height: 46 * badgeT,
      );
      _card(canvas, badge, radius: 14, fill: _blue);
      _lines(canvas, Offset(badge.left + 16, badge.center.dy - 6), [46, 30],
          gap: 12, weight: 5, color: Colors.white.withValues(alpha: 0.9));
    }

    _sparkle(canvas, Offset(268, baseY - 78), 12, _amber, _fade(0.7, 0.3));
    _sparkle(canvas, Offset(58, baseY + 84), 9, _blue, _fade(0.78, 0.3));
  }

  // ------------------------------------------------ scene 2: the review loop

  void _review(Canvas canvas, double h) {
    final baseY = h * 0.5;

    // Wrong sheet on the left.
    final wrongT = _at(0.02);
    if (wrongT > 0) {
      canvas.save();
      canvas.translate(104, baseY);
      canvas.rotate(-0.08);
      canvas.translate(-104, -baseY);
      final r = Rect.fromCenter(
        center: Offset(104, baseY),
        width: 118 * wrongT,
        height: 152 * wrongT,
      );
      _card(canvas, r, radius: 16);
      _lines(canvas, Offset(r.left + 18, r.top + 30), [64, 82, 50], gap: 14);
      final cross = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..color = tokens.danger;
      final c = Offset(r.center.dx, r.bottom - 40);
      canvas.drawCircle(c, 20, Paint()..color = tokens.danger.withValues(alpha: 0.14));
      canvas.drawLine(c + const Offset(-7, -7), c + const Offset(7, 7), cross);
      canvas.drawLine(c + const Offset(7, -7), c + const Offset(-7, 7), cross);
      canvas.restore();
    }

    // Right sheet, the same question answered correctly.
    final rightT = _at(0.34);
    if (rightT > 0) {
      canvas.save();
      canvas.translate(240, baseY);
      canvas.rotate(0.08);
      canvas.translate(-240, -baseY);
      final r = Rect.fromCenter(
        center: Offset(240, baseY),
        width: 118 * rightT,
        height: 152 * rightT,
      );
      _card(canvas, r, radius: 16);
      _lines(canvas, Offset(r.left + 18, r.top + 30), [64, 82, 50], gap: 14);
      final c = Offset(r.center.dx, r.bottom - 40);
      canvas.drawCircle(c, 20, Paint()..color = tokens.success.withValues(alpha: 0.16));
      canvas.drawPath(
        Path()
          ..moveTo(c.dx - 9, c.dy)
          ..lineTo(c.dx - 2, c.dy + 7)
          ..lineTo(c.dx + 10, c.dy - 7),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = tokens.success,
      );
      canvas.restore();
    }

    // The loop arrow that ties them together.
    final loopT = _fade(0.5, 0.4);
    if (loopT > 0) {
      final path = Path()
        ..moveTo(120, baseY - 96)
        ..cubicTo(160, baseY - 132, 210, baseY - 128, 236, baseY - 98);
      final metric = path.computeMetrics().first;
      canvas.drawPath(
        metric.extractPath(0, metric.length * loopT),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round
          ..color = _blue,
      );
      if (loopT > 0.92) {
        canvas.drawPath(
          Path()
            ..moveTo(226, baseY - 108)
            ..lineTo(238, baseY - 96)
            ..lineTo(224, baseY - 88),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..color = _blue,
        );
      }
    }

    // Reason tags floating under the pair.
    for (var i = 0; i < 3; i++) {
      final t = _at(0.6 + i * 0.08, 0.34);
      if (t <= 0) continue;
      final w = [58.0, 46.0, 62.0][i];
      final rect = Rect.fromCenter(
        center: Offset(78 + i * 92.0, baseY + 106),
        width: w * t,
        height: 30 * t,
      );
      _card(
        canvas,
        rect,
        radius: 15,
        fill: i == 1 ? _amber.withValues(alpha: 0.9) : _blueSoft,
        border: false,
      );
    }
  }

  // ----------------------------------------------- scene 3: goal and rhythm

  void _rhythm(Canvas canvas, double h) {
    final baseY = h * 0.48;

    // Calendar with a few days already filled in.
    final calT = _at(0.02);
    if (calT > 0) {
      final rect = Rect.fromCenter(
        center: Offset(112, baseY),
        width: 156 * calT,
        height: 150 * calT,
      );
      _card(canvas, rect, radius: 16);
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(rect.left, rect.top, rect.width, 30),
          topLeft: const Radius.circular(15),
          topRight: const Radius.circular(15),
        ),
        Paint()..color = _blue,
      );
      for (var r = 0; r < 3; r++) {
        for (var c = 0; c < 4; c++) {
          final i = r * 4 + c;
          final t = _fade(0.2 + i * 0.02, 0.2);
          if (t <= 0) continue;
          final cell = Rect.fromLTWH(
            rect.left + 16 + c * 30,
            rect.top + 44 + r * 30,
            20,
            20,
          );
          final filled = i % 3 != 2 && i < 9;
          canvas.drawRRect(
            RRect.fromRectAndRadius(cell, const Radius.circular(6)),
            Paint()
              ..color = (filled ? _blue : _ink)
                  .withValues(alpha: (filled ? 0.85 : 0.25) * t),
          );
        }
      }
    }

    // Goal ring on the right.
    final ringT = _fade(0.34, 0.5);
    if (ringT > 0) {
      final c = Offset(246, baseY - 12);
      const radius = 52.0;
      canvas.drawCircle(
        c,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 12
          ..color = _blueSoft,
      );
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: radius),
        -math.pi / 2,
        math.pi * 2 * 0.78 * ringT,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 12
          ..strokeCap = StrokeCap.round
          ..color = _blue,
      );
      final tick = _fade(0.72, 0.28);
      if (tick > 0) {
        canvas.drawPath(
          Path()
            ..moveTo(c.dx - 16 * tick, c.dy)
            ..lineTo(c.dx - 4 * tick, c.dy + 12 * tick)
            ..lineTo(c.dx + 17 * tick, c.dy - 13 * tick),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 7
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..color = tokens.success,
        );
      }
    }

    // Rising bars under the ring: the streak.
    for (var i = 0; i < 4; i++) {
      final t = _at(0.6 + i * 0.07, 0.32);
      if (t <= 0) continue;
      final height = (26 + i * 16.0) * t;
      final rect = Rect.fromLTWH(214 + i * 20.0, baseY + 74 - height, 12, height);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(6)),
        Paint()..color = i == 3 ? _amber : _blue.withValues(alpha: 0.55),
      );
    }

    _sparkle(canvas, Offset(300, baseY - 78), 11, _amber, _fade(0.78, 0.22));
    _sparkle(canvas, Offset(56, baseY + 92), 9, _blue, _fade(0.84, 0.16));
  }

  @override
  bool shouldRepaint(covariant _ScenePainter old) =>
      old.progress != progress || old.kind != kind || old.tokens != tokens;
}
