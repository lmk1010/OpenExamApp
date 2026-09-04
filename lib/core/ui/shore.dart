import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:openexam_app/core/theme/app_tokens.dart';

/// 「上岸」母题的定制组件。
///
/// 通用的圆角矩形进度条和打勾圈谁都有，这四个是这个 app 自己的：
/// 备考是划船渡海，所以进度是航迹、勾选是救生圈、图文交界是水线、
/// 分数环是罗盘。母题只停在插画里不算数，得走进每天出现几十次的组件。

// ─────────────────────────────────────────── 航迹进度条

/// 航迹：虚线是还没走的航段，实线带尾流点，船停在当前位置，终点是灯塔。
///
/// 走满时航线转绿、灯塔亮一圈光晕 —— 完成态不靠一句文案，靠画面本身。
class RouteBar extends StatelessWidget {
  const RouteBar({
    super.key,
    required this.value,
    this.height = 34,
    this.color,
  });

  /// 0–1。
  final double value;
  final double height;

  /// 覆盖航线颜色。留空用 accent，满了自动转 success。
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final v = value.clamp(0.0, 1.0);
    final done = v >= 0.999;
    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: _RoutePainter(
          value: v,
          line: color ?? (done ? t.success : t.accent),
          idle: t.line,
          hull: t.onAccent,
          lamp: t.accent,
          tower: done ? t.success : t.muted,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _RoutePainter extends CustomPainter {
  _RoutePainter({
    required this.value,
    required this.line,
    required this.idle,
    required this.hull,
    required this.lamp,
    required this.tower,
  });

  final double value;
  final Color line, idle, hull, lamp, tower;

  /// 航线本体。留出右端一截给灯塔站着。
  Path _route(Size size) {
    const inset = 8.0;
    final right = size.width - 14;
    final y = size.height - 12;
    final path = Path()..moveTo(inset, y);
    // 四段波峰波谷交替，看着像水面而不是一条直线
    final span = (right - inset) / 4;
    for (var i = 0; i < 4; i++) {
      final x0 = inset + span * i;
      path.quadraticBezierTo(
        x0 + span / 2, y + (i.isEven ? -8 : 8),
        x0 + span, y,
      );
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = _route(size);
    final metric = path.computeMetrics().first;
    final travelled = metric.length * value;

    // 没走的航段：淡虚线
    canvas.drawPath(
      _dash(path, 1, 7),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = idle
        ..isAntiAlias = true,
    );

    // 已走的航段
    if (travelled > 0.5) {
      canvas.drawPath(
        metric.extractPath(0, travelled),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.4
          ..strokeCap = StrokeCap.round
          ..color = line
          ..isAntiAlias = true,
      );
    }

    // 尾流点：越靠后越实，暗示"刚划过这里"
    for (var i = 1; i <= 3; i++) {
      final at = travelled - i * 18;
      if (at <= 4) continue;
      final tan = metric.getTangentForOffset(at);
      if (tan == null) continue;
      canvas.drawCircle(
        tan.position,
        1.6,
        Paint()..color = line.withValues(alpha: 0.85 - i * 0.2),
      );
    }

    final done = value >= 0.999;
    if (!done && travelled > 2) {
      final tan = metric.getTangentForOffset(travelled);
      // 船要坐在航线上，所以 y 取切点而不是画布底边；-3 让船底压住线
      if (tan != null) _boat(canvas, tan.position.translate(0, -3));
    }
    // 灯塔立在航线终点，同理
    final end = metric.getTangentForOffset(metric.length)?.position ??
        Offset(size.width - 14, size.height - 12);
    _lighthouse(canvas, end.translate(6, 0), done);
  }

  void _boat(Canvas canvas, Offset at) {
    canvas.save();
    canvas.translate(at.dx, at.dy);
    // 船身
    canvas.drawPath(
      Path()
        ..moveTo(-8, 2)..lineTo(8, 2)..lineTo(5.5, 7)..lineTo(-5.5, 7)..close(),
      Paint()..color = hull..isAntiAlias = true,
    );
    // 帆
    final sail = Path()..moveTo(0, 2)..lineTo(0, -9)..lineTo(7, -2)..close();
    canvas.drawPath(sail, Paint()..color = lamp..isAntiAlias = true);
    canvas.drawPath(
      sail,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..strokeJoin = StrokeJoin.round
        ..color = hull
        ..isAntiAlias = true,
    );
    canvas.restore();
  }

  void _lighthouse(Canvas canvas, Offset at, bool lit) {
    canvas.save();
    canvas.translate(at.dx, at.dy);
    if (lit) {
      canvas.drawCircle(
        const Offset(0, -15), 7,
        Paint()..color = lamp.withValues(alpha: 0.28),
      );
    }
    canvas.drawPath(
      Path()
        ..moveTo(-3.4, 0)..lineTo(-2.2, -13)..lineTo(2.2, -13)..lineTo(3.4, 0)..close(),
      Paint()..color = tower..isAntiAlias = true,
    );
    canvas.drawRRect(
      RRect.fromLTRBR(-2.8, -17, 2.8, -12.8, const Radius.circular(1.2)),
      Paint()..color = lamp..isAntiAlias = true,
    );
    canvas.restore();
  }

  /// Flutter 没有 strokeDasharray，自己切。
  Path _dash(Path src, double on, double off) {
    final out = Path();
    for (final m in src.computeMetrics()) {
      var at = 0.0;
      while (at < m.length) {
        out.addPath(m.extractPath(at, math.min(at + on, m.length)), Offset.zero);
        at += on + off;
      }
    }
    return out;
  }

  @override
  bool shouldRepaint(_RoutePainter old) =>
      old.value != value || old.line != line || old.idle != idle;
}

// ─────────────────────────────────────────── 救生圈勾选

enum LifeRingState { todo, active, done, wrong, skipped }

/// 救生圈：圈上四道开口是绑绳。通用打勾圈没有这个，一眼就能认出是我们的。
class LifeRing extends StatelessWidget {
  const LifeRing({super.key, required this.state, this.size = 21});

  final LifeRingState state;
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(
          state: state,
          idle: t.line,
          active: t.accent,
          activeRim: Color.lerp(t.accent, Colors.black, 0.18)!,
          done: t.success,
          wrong: t.danger,
          wrongSoft: t.dangerSoft,
          rope: t.surface,
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.state,
    required this.idle,
    required this.active,
    required this.activeRim,
    required this.done,
    required this.wrong,
    required this.wrongSoft,
    required this.rope,
  });

  final LifeRingState state;
  final Color idle, active, activeRim, done, wrong, wrongSoft, rope;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 26; // 26 单位设计网格
    canvas.save();
    canvas.scale(s);
    const c = Offset(13, 13);

    switch (state) {
      case LifeRingState.todo:
        _rim(canvas, c, idle, 3);
        _ropes(canvas, rope);
      case LifeRingState.active:
        _rim(canvas, c, activeRim, 3);
        _ropes(canvas, rope);
        canvas.drawCircle(c, 4.4, Paint()..color = active..isAntiAlias = true);
      case LifeRingState.done:
        canvas.drawCircle(c, 10, Paint()..color = done..isAntiAlias = true);
        // 绑绳留半透明，完成了也还看得出是救生圈
        _ropes(canvas, rope.withValues(alpha: 0.55));
        canvas.drawPath(
          Path()..moveTo(9, 13.4)..lineTo(11.7, 16.1)..lineTo(17.2, 10),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.3
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..color = rope
            ..isAntiAlias = true,
        );
      case LifeRingState.wrong:
        canvas.drawCircle(c, 10, Paint()..color = wrongSoft..isAntiAlias = true);
        _rim(canvas, c, wrong, 2.4);
        canvas.drawPath(
          Path()..moveTo(9.6, 9.6)..lineTo(16.4, 16.4)..moveTo(16.4, 9.6)..lineTo(9.6, 16.4),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.3
            ..strokeCap = StrokeCap.round
            ..color = wrong
            ..isAntiAlias = true,
        );
      case LifeRingState.skipped:
        _rim(canvas, c, idle, 3, dashed: true);
    }
    canvas.restore();
  }

  void _rim(Canvas canvas, Offset c, Color color, double w, {bool dashed = false}) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..color = color
      ..isAntiAlias = true;
    if (!dashed) {
      canvas.drawCircle(c, 10, paint);
      return;
    }
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      canvas.drawArc(Rect.fromCircle(center: c, radius: 10), a, math.pi / 7, false, paint);
    }
  }

  /// 四道开口，救生圈的绑绳。
  void _ropes(Canvas canvas, Color color) {
    canvas.drawPath(
      Path()
        ..moveTo(13, 3)..lineTo(13, 7)
        ..moveTo(13, 19)..lineTo(13, 23)
        ..moveTo(3, 13)..lineTo(7, 13)
        ..moveTo(19, 13)..lineTo(23, 13),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..color = color
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.state != state;
}

// ─────────────────────────────────────────── 水线

/// 插画和下方内容的交界。图没入水里，不是被一条直线硬切。
class Waterline extends StatelessWidget {
  const Waterline({super.key, this.height = 20, this.color});

  final double height;

  /// 水面颜色，通常是卡片底色。
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _WavePainter(color ?? context.tokens.surface),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  _WavePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final crest = size.height * 0.6;
    final path = Path()..moveTo(0, crest);
    final span = size.width / 4;
    for (var i = 0; i < 4; i++) {
      path.quadraticBezierTo(
        span * i + span / 4, i.isEven ? crest - 10 : crest + 6,
        span * (i + 1), crest,
      );
    }
    path
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color..isAntiAlias = true);
  }

  @override
  bool shouldRepaint(_WavePainter old) => old.color != color;
}

// ─────────────────────────────────────────── 罗盘分数环

/// 罗盘：外圈四个主刻度 + 四个斜向副刻度是度盘。
class CompassDial extends StatelessWidget {
  const CompassDial({
    super.key,
    required this.value,
    required this.label,
    this.caption,
    this.size = 104,
    this.color,
  });

  /// 0–1。
  final double value;

  /// 圈心的大字，通常是百分数或分数。
  final String label;
  final String? caption;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final v = value.clamp(0.0, 1.0);
    // 低于六成转红，六到八成用黄，再高转绿 —— 颜色本身就是评价
    final tint = color ?? (v < 0.6 ? t.danger : (v < 0.8 ? t.accent : t.success));
    final text = Theme.of(context).textTheme;

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DialPainter(value: v, arc: tint, track: t.surfaceAlt, tick: t.line),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: text.headlineSmall?.copyWith(
                  fontSize: size * 0.22,
                  fontWeight: FontWeight.w700,
                  height: 1,
                  color: t.text,
                ),
              ),
              if (caption != null) ...[
                const SizedBox(height: 3),
                Text(
                  caption!,
                  style: text.bodySmall?.copyWith(fontSize: size * 0.105, height: 1),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  _DialPainter({
    required this.value,
    required this.arc,
    required this.track,
    required this.tick,
  });

  final double value;
  final Color arc, track, tick;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width * 0.375;
    final stroke = size.width * 0.075;

    // 度盘刻度：正向四道长，斜向四道短
    void mark(double angle, double len, double w, Color color) {
      final dir = Offset(math.cos(angle), math.sin(angle));
      canvas.drawLine(
        c + dir * (size.width * 0.5 - 4),
        c + dir * (size.width * 0.5 - 4 - len),
        Paint()
          ..strokeWidth = w
          ..strokeCap = StrokeCap.round
          ..color = color
          ..isAntiAlias = true,
      );
    }

    for (var i = 0; i < 4; i++) {
      mark(i * math.pi / 2, size.width * 0.055, 2, tick);
    }
    for (var i = 0; i < 4; i++) {
      mark(math.pi / 4 + i * math.pi / 2, size.width * 0.04, 1.6,
          tick.withValues(alpha: 0.5));
    }

    final rect = Rect.fromCircle(center: c, radius: r);
    canvas.drawArc(rect, 0, math.pi * 2, false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..color = track
          ..isAntiAlias = true);
    if (value > 0) {
      canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * value, false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = stroke
            ..strokeCap = StrokeCap.round
            ..color = arc
            ..isAntiAlias = true);
    }
  }

  @override
  bool shouldRepaint(_DialPainter old) => old.value != value || old.arc != arc;
}
