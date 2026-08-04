import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:openexam_app/core/theme/app_tokens.dart';
import 'package:openexam_app/core/ui/stroke_icons.dart';
import 'package:openexam_app/features/achievements/achievements.dart';

/// 徽章造型 — every group gets its own silhouette so a wall of medals reads as
/// a collection rather than eighteen copies of the same circle.
enum MedalShape { round, diamond, shield, hexagon, bloom }

MedalShape shapeForGroup(String group) => switch (group) {
      '题量' => MedalShape.round,
      '坚持' => MedalShape.bloom,
      '精度' => MedalShape.shield,
      '考场' => MedalShape.diamond,
      _ => MedalShape.hexagon,
    };

/// The four metals. Each is a full sweep — highlight, body, shadow, highlight —
/// so the rim catches light on two sides like a real struck medal.
List<Color> _metal(BadgeTier tier) => switch (tier) {
      BadgeTier.bronze => const [
          Color(0xFFF0C89A),
          Color(0xFFB0743C),
          Color(0xFF6E4520),
          Color(0xFFE3B183),
          Color(0xFF9A6432),
          Color(0xFF6E4520),
          Color(0xFFF0C89A),
        ],
      BadgeTier.silver => const [
          Color(0xFFF4F7FB),
          Color(0xFF9AA7B8),
          Color(0xFF5C6878),
          Color(0xFFE8EDF4),
          Color(0xFF8D9AAB),
          Color(0xFF5C6878),
          Color(0xFFF4F7FB),
        ],
      BadgeTier.gold => const [
          Color(0xFFFFF3CE),
          Color(0xFFE0AE33),
          Color(0xFF9A6C11),
          Color(0xFFFDEBB8),
          Color(0xFFD9A21B),
          Color(0xFF8F6410),
          Color(0xFFFFF3CE),
        ],
      BadgeTier.platinum => const [
          Color(0xFFE6F6FF),
          Color(0xFF7FC4E3),
          Color(0xFF2F6C8C),
          Color(0xFFD5EEFB),
          Color(0xFF4FA3C7),
          Color(0xFF2F6C8C),
          Color(0xFFE6F6FF),
        ],
    };

/// A struck-metal badge: coloured backing plate, dark face, bevelled metal rim
/// with a travelling highlight, and an embossed glyph. Locked badges are the
/// same object un-plated, with the progress ring around it.
class BadgeMedal extends StatefulWidget {
  const BadgeMedal({
    super.key,
    required this.badge,
    this.size = 72,
    this.animate = false,
    this.shine = false,
  });

  final AchievementBadge badge;
  final double size;

  /// Scale-in on first build — used when the medal is the star of the screen.
  final bool animate;

  /// Keeps a highlight travelling around the rim. Off in the grid: eighteen
  /// running tickers is not worth the frames.
  final bool shine;

  @override
  State<BadgeMedal> createState() => _BadgeMedalState();
}

class _BadgeMedalState extends State<BadgeMedal>
    with SingleTickerProviderStateMixin {
  AnimationController? _spin;

  @override
  void initState() {
    super.initState();
    if (widget.shine && widget.badge.unlocked) {
      _spin = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 3600),
      )..repeat();
    }
  }

  @override
  void dispose() {
    _spin?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final badge = widget.badge;
    final size = widget.size;
    final tint = badge.tier.color;

    final face = Stack(
      alignment: Alignment.center,
      children: [
        if (_spin == null)
          CustomPaint(size: Size(size, size), painter: _painter(t, 0.18))
        else
          AnimatedBuilder(
            animation: _spin!,
            builder: (_, __) => CustomPaint(
              size: Size(size, size),
              painter: _painter(t, _spin!.value),
            ),
          ),
        // The glyph is struck into the face: a dark impression under a
        // metal-lit top layer.
        Transform.translate(
          offset: _detail
              ? Offset(-size * 0.11, -size * 0.03)
              : Offset(0, size * 0.015),
          child: StrokeIcon(
            badge.icon,
            size: size * (_detail ? 0.26 : 0.3),
            color: Colors.black.withValues(alpha: badge.unlocked ? 0.55 : 0.18),
            weight: 2.4,
          ),
        ),
        Transform.translate(
          offset: _detail ? Offset(-size * 0.11, -size * 0.045) : Offset.zero,
          child: ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (rect) => LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: badge.unlocked
                ? [_metal(badge.tier)[0], _metal(badge.tier)[4]]
                : [t.muted, t.muted],
          ).createShader(rect),
          child: StrokeIcon(
            badge.icon,
            size: size * (_detail ? 0.26 : 0.3),
            color: Colors.white,
            weight: 2.2,
          ),
          ),
        ),
      ],
    );

    final withShadow = badge.unlocked
        ? DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: tint.withValues(alpha: 0.30),
                  blurRadius: size * 0.28,
                  offset: Offset(0, size * 0.07),
                ),
              ],
            ),
            child: face,
          )
        : face;

    if (!widget.animate) return withShadow;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 760),
      curve: Curves.elasticOut,
      builder: (_, v, child) => Transform.scale(
        scale: 0.5 + 0.5 * v.clamp(0.0, 1.4),
        child: Transform.rotate(angle: (1 - v) * 0.5, child: child),
      ),
      child: withShadow,
    );
  }

  bool get _detail => widget.size >= 120;

  /// 20000 reads better than 20000; anything past a thousand gets shortened
  /// the way the app does elsewhere.
  String get _label {
    final n = widget.badge.target;
    if (n >= 10000) return '${(n / 10000).toStringAsFixed(n % 10000 == 0 ? 0 : 1)}万';
    return '$n';
  }

  _MedalPainter _painter(AppTokens t, double phase) => _MedalPainter(
        shape: shapeForGroup(widget.badge.group),
        metal: _metal(widget.badge.tier),
        tint: widget.badge.tier.color,
        unlocked: widget.badge.unlocked,
        progress: widget.badge.progress,
        phase: phase,
        dark: t.name == 'dark',
        track: t.name == 'dark'
            ? Colors.white.withValues(alpha: 0.12)
            : t.text.withValues(alpha: 0.10),
        detail: _detail,
        label: _detail ? _label : '',
        sub: _detail ? widget.badge.group : '',
      );
}

class _MedalPainter extends CustomPainter {
  const _MedalPainter({
    required this.shape,
    required this.metal,
    required this.tint,
    required this.unlocked,
    required this.progress,
    required this.phase,
    required this.dark,
    required this.track,
    required this.detail,
    required this.label,
    required this.sub,
  });

  final MedalShape shape;
  final List<Color> metal;
  final Color tint;
  final bool unlocked;
  final double progress;

  /// 0–1, where the travelling highlight sits on the rim.
  final double phase;
  final bool dark;
  final Color track;

  /// Big renders get the full struck-medal treatment: engraved guilloche,
  /// rim studs, the target number and a name plate. At 72dp it is mush.
  final bool detail;
  final String label;
  final String sub;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final s = size.width;
    // Room for the backing plate corners and the progress ring.
    final r = s * 0.36;
    final rim = s * 0.075;

    _plate(canvas, c, s);

    final body = _bodyPath(c, r);

    // Face: a dark plate with a soft top-left light, like the reference medals.
    canvas.drawPath(
      body,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: unlocked
              ? [const Color(0xFF474C55), const Color(0xFF20242B)]
              : dark
                  ? [
                      Colors.white.withValues(alpha: 0.07),
                      Colors.white.withValues(alpha: 0.03),
                    ]
                  : [
                      Colors.black.withValues(alpha: 0.05),
                      Colors.black.withValues(alpha: 0.02),
                    ],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );

    if (detail) _engrave(canvas, c, r, body);

    if (unlocked) {
      // Bevel: a dark inner line, then the metal rim, then the highlight sweep.
      canvas.drawPath(
        body,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = rim * 1.5
          ..color = Colors.black.withValues(alpha: 0.30),
      );
      canvas.drawPath(
        body,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = rim
          ..shader = SweepGradient(
            colors: metal,
            transform: GradientRotation(-math.pi * 0.75),
          ).createShader(Rect.fromCircle(center: c, radius: r)),
      );
      // Travelling glint — a narrow bright band that runs the rim.
      canvas.drawPath(
        body,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = rim * 0.8
          ..shader = SweepGradient(
            colors: [
              Colors.white.withValues(alpha: 0),
              Colors.white.withValues(alpha: 0),
              Colors.white.withValues(alpha: 0.75),
              Colors.white.withValues(alpha: 0),
              Colors.white.withValues(alpha: 0),
            ],
            stops: const [0, 0.42, 0.5, 0.58, 1],
            transform: GradientRotation(phase * math.pi * 2),
          ).createShader(Rect.fromCircle(center: c, radius: r)),
      );
      // Inner hairline, the way a struck medal has a raised inner border.
      canvas.drawPath(
        _bodyPath(c, r - rim * 1.35),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.012
          ..color = metal[0].withValues(alpha: 0.45),
      );
      // Glass highlight across the upper-left of the face.
      canvas.save();
      canvas.clipPath(_bodyPath(c, r - rim * 0.6));
      canvas.drawCircle(
        c - Offset(r * 0.45, r * 0.55),
        r * 0.95,
        Paint()
          ..shader = RadialGradient(
            colors: [
              Colors.white.withValues(alpha: 0.16),
              Colors.white.withValues(alpha: 0),
            ],
          ).createShader(
            Rect.fromCircle(
              center: c - Offset(r * 0.45, r * 0.55),
              radius: r * 0.95,
            ),
          ),
      );
      canvas.restore();
      if (detail) {
        _studs(canvas, c, r, rim);
        _numerals(canvas, c, r);
      }
    } else {
      canvas.drawPath(
        body,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.02
          ..color = track,
      );
      // Locked badges wear their progress as a ring outside the shape.
      final ring = Rect.fromCircle(center: c, radius: s * 0.44);
      canvas.drawArc(
        ring,
        0,
        math.pi * 2,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.038
          ..color = track,
      );
      if (progress > 0) {
        canvas.drawArc(
          ring,
          -math.pi / 2,
          math.pi * 2 * progress,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = s * 0.038
            ..strokeCap = StrokeCap.round
            ..shader = SweepGradient(
              colors: [tint.withValues(alpha: 0.5), tint],
              transform: const GradientRotation(-math.pi / 2),
            ).createShader(ring),
        );
      }
    }
  }

  /// Guilloche — the fine engine-turned lines struck into a real medal's face.
  /// Cheap to draw, and it is what stops the face reading as flat paint.
  void _engrave(Canvas canvas, Offset c, double r, Path body) {
    canvas.save();
    canvas.clipPath(body);
    final ink = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.012
      ..color = unlocked
          ? Colors.white.withValues(alpha: 0.07)
          : track.withValues(alpha: 0.5);
    // Concentric rings, off-centre so the light side reads thicker.
    for (var i = 1; i <= 7; i++) {
      canvas.drawCircle(c + Offset(-r * 0.02, -r * 0.02), r * i / 8.5, ink);
    }
    // Radial hairlines.
    for (var i = 0; i < 36; i++) {
      final a = i * math.pi / 18;
      canvas.drawLine(
        c + Offset(math.cos(a), math.sin(a)) * r * 0.42,
        c + Offset(math.cos(a), math.sin(a)) * r * 0.86,
        ink,
      );
    }
    canvas.restore();
  }

  /// Small raised beads set into the rim, evenly spaced.
  void _studs(Canvas canvas, Offset c, double r, double rim) {
    final stud = Paint()..color = metal[0].withValues(alpha: 0.75);
    final shade = Paint()..color = Colors.black.withValues(alpha: 0.35);
    for (var i = 0; i < 16; i++) {
      final a = i * math.pi / 8 + math.pi / 16;
      final o = c + Offset(math.cos(a), math.sin(a)) * (r - rim * 0.05);
      canvas.drawCircle(o + Offset(0, rim * 0.10), rim * 0.17, shade);
      canvas.drawCircle(o, rim * 0.16, stud);
    }
  }

  /// The target number, struck into the lower right of the face, with the
  /// group name on a dark plate under it — the reference badges' anchor.
  void _numerals(Canvas canvas, Offset c, double r) {
    if (label.isEmpty) return;
    final anchor = c + Offset(r * 0.30, r * 0.14);

    void draw(String value, double size, Color color, Offset at, {double weight = 800}) {
      final tp = TextPainter(
        text: TextSpan(
          text: value,
          style: TextStyle(
            fontSize: size,
            height: 1,
            letterSpacing: -size * 0.02,
            fontWeight: FontWeight.values[(weight ~/ 100) - 1],
            color: color,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, at - Offset(tp.width / 2, tp.height / 2));
    }

    final fs = r * 0.34;
    draw(label, fs, Colors.black.withValues(alpha: 0.55), anchor + Offset(0, fs * 0.06));
    draw(label, fs, metal[0], anchor);

    if (sub.isEmpty) return;
    final tp = TextPainter(
      text: TextSpan(
        text: sub,
        style: TextStyle(
          fontSize: r * 0.16,
          height: 1,
          letterSpacing: r * 0.02,
          fontWeight: FontWeight.w700,
          color: metal[0].withValues(alpha: 0.92),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final plate = Rect.fromCenter(
      center: anchor + Offset(0, fs * 0.82),
      width: tp.width + r * 0.20,
      height: tp.height + r * 0.13,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(plate, Radius.circular(r * 0.05)),
      Paint()..color = const Color(0xFF15171B).withValues(alpha: 0.92),
    );
    tp.paint(canvas, plate.center - Offset(tp.width / 2, tp.height / 2));
  }

  /// The coloured shape sitting behind the medal — what gives the reference
  /// badges their depth. Rotated off-axis from the body so it reads as two
  /// stacked objects.
  void _plate(Canvas canvas, Offset c, double s) {
    if (!unlocked) return;
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          tint.withValues(alpha: 0.85),
          tint.withValues(alpha: 0.35),
        ],
      ).createShader(Rect.fromCircle(center: c, radius: s * 0.46));

    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(math.pi / 4);
    final side = s * 0.60;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: side, height: side),
        Radius.circular(s * 0.10),
      ),
      paint,
    );
    canvas.restore();
  }

  Path _bodyPath(Offset c, double r) {
    final p = Path();
    switch (shape) {
      case MedalShape.round:
        p.addOval(Rect.fromCircle(center: c, radius: r));
      case MedalShape.diamond:
        p.addRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: c, width: r * 1.78, height: r * 1.78),
            Radius.circular(r * 0.30),
          ),
        );
      case MedalShape.hexagon:
        for (var i = 0; i < 6; i++) {
          final a = -math.pi / 2 + i * math.pi / 3;
          final o = c + Offset(math.cos(a), math.sin(a)) * r;
          i == 0 ? p.moveTo(o.dx, o.dy) : p.lineTo(o.dx, o.dy);
        }
        p.close();
      case MedalShape.shield:
        p.moveTo(c.dx - r * 0.86, c.dy - r * 0.82);
        p.lineTo(c.dx + r * 0.86, c.dy - r * 0.82);
        p.lineTo(c.dx + r * 0.86, c.dy + r * 0.18);
        p.quadraticBezierTo(
          c.dx + r * 0.80,
          c.dy + r * 0.82,
          c.dx,
          c.dy + r * 1.02,
        );
        p.quadraticBezierTo(
          c.dx - r * 0.80,
          c.dy + r * 0.82,
          c.dx - r * 0.86,
          c.dy + r * 0.18,
        );
        p.close();
      case MedalShape.bloom:
        // Eight soft lobes — a flower/seal outline.
        for (var i = 0; i <= 64; i++) {
          final a = i / 64 * math.pi * 2;
          final rr = r * (0.90 + 0.10 * math.cos(a * 8));
          final o = c + Offset(math.cos(a), math.sin(a)) * rr;
          i == 0 ? p.moveTo(o.dx, o.dy) : p.lineTo(o.dx, o.dy);
        }
        p.close();
    }
    return p;
  }

  @override
  bool shouldRepaint(covariant _MedalPainter old) =>
      old.phase != phase ||
      old.progress != progress ||
      old.unlocked != unlocked ||
      old.detail != detail ||
      old.label != label ||
      old.shape != shape;
}
