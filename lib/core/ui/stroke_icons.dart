import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Hand-drawn icon set. Every glyph is built from paths on a 24×24 grid with a
/// single stroke weight and round caps, so the whole app shares one drawing
/// hand instead of borrowing three different stock sets.
enum AppIcon {
  // Question types
  speech, // 言语理解
  numbers, // 数量关系
  logic, // 判断推理
  chart, // 资料分析
  globe, // 常识判断
  shuffle, // 随机练习
  // Navigation
  practice,
  plan, // 复习计划 / Todo
  papers,
  wrongBook,
  profile,
  // Actions /状态
  replay,
  timer,
  play,
  download,
  moon,
  sun,
  auto,
  privacy,
  trash,
  info,
  // 设置行用的一组：跟上面同一套 24 网格、同一个描边宽度
  region, // 报考地区
  calendar, // 考试日期
  target, // 每日目标
  stack, // 每组题量
  import, // 导入题目
  health, // 题库体检
  backup, // 备份
  spark, // AI
  search,
}

class StrokeIcon extends StatelessWidget {
  const StrokeIcon(
    this.icon, {
    super.key,
    this.size = 24,
    this.color,
    this.weight = 1.9,
  });

  final AppIcon icon;
  final double size;
  final Color? color;
  final double weight;

  @override
  Widget build(BuildContext context) {
    final c = color ?? IconTheme.of(context).color ?? Colors.black;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _IconPainter(icon, c, weight)),
    );
  }
}

class _IconPainter extends CustomPainter {
  _IconPainter(this.icon, this.color, this.weight);

  final AppIcon icon;
  final Color color;
  final double weight;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide / 24; // 24-unit design grid
    canvas.save();
    canvas.scale(s);

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = weight
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color
      ..isAntiAlias = true;

    final fill = Paint()
      ..style = PaintingStyle.fill
      ..color = color
      ..isAntiAlias = true;

    switch (icon) {
      case AppIcon.speech:
        canvas.drawRRect(
          RRect.fromLTRBR(3, 4, 21, 16, const Radius.circular(4)),
          stroke,
        );
        canvas.drawPath(
          Path()
            ..moveTo(8, 16)
            ..lineTo(8, 20.5)
            ..lineTo(12.5, 16),
          stroke,
        );
        canvas.drawLine(const Offset(7, 8.4), const Offset(17, 8.4), stroke);
        canvas.drawLine(const Offset(7, 11.8), const Offset(13.5, 11.8), stroke);

      case AppIcon.numbers:
        canvas.drawLine(const Offset(4, 8.5), const Offset(10, 8.5), stroke);
        canvas.drawLine(const Offset(7, 5.5), const Offset(7, 11.5), stroke);
        canvas.drawLine(const Offset(14, 8.5), const Offset(20, 8.5), stroke);
        canvas.drawLine(const Offset(4.5, 15), const Offset(10, 19.5), stroke);
        canvas.drawLine(const Offset(10, 15), const Offset(4.5, 19.5), stroke);
        canvas.drawLine(const Offset(14, 15.5), const Offset(20, 15.5), stroke);
        canvas.drawLine(const Offset(14, 19), const Offset(20, 19), stroke);

      case AppIcon.logic:
        canvas.drawCircle(const Offset(8.5, 8.5), 4.6, stroke);
        canvas.drawRRect(
          RRect.fromLTRBR(11, 11, 20.5, 20.5, const Radius.circular(3)),
          stroke,
        );

      case AppIcon.chart:
        canvas.drawLine(const Offset(4, 20), const Offset(20.5, 20), stroke);
        canvas.drawLine(const Offset(7.5, 20), const Offset(7.5, 13), stroke);
        canvas.drawLine(const Offset(12.5, 20), const Offset(12.5, 8), stroke);
        canvas.drawLine(const Offset(17.5, 20), const Offset(17.5, 11), stroke);

      case AppIcon.globe:
        canvas.drawCircle(const Offset(12, 12), 8.4, stroke);
        canvas.drawLine(const Offset(3.6, 12), const Offset(20.4, 12), stroke);
        canvas.drawOval(
          Rect.fromCenter(center: const Offset(12, 12), width: 9, height: 16.8),
          stroke,
        );

      case AppIcon.shuffle:
        canvas.drawPath(
          Path()
            ..moveTo(3.5, 7)
            ..lineTo(7.5, 7)
            ..cubicTo(11, 7, 13, 17, 16.5, 17)
            ..lineTo(20, 17),
          stroke,
        );
        canvas.drawPath(
          Path()
            ..moveTo(3.5, 17)
            ..lineTo(7.5, 17)
            ..cubicTo(9.4, 17, 10.8, 14, 12, 12),
          stroke,
        );
        canvas.drawPath(
          Path()
            ..moveTo(17.5, 14.5)
            ..lineTo(20.5, 17)
            ..lineTo(17.5, 19.5),
          stroke,
        );
        canvas.drawPath(
          Path()
            ..moveTo(17.5, 4.5)
            ..lineTo(20.5, 7)
            ..lineTo(17.5, 9.5),
          stroke,
        );
        canvas.drawPath(
          Path()
            ..moveTo(14.2, 9.6)
            ..cubicTo(15, 8.3, 15.6, 7, 16.5, 7)
            ..lineTo(20, 7),
          stroke,
        );

      case AppIcon.practice:
        // Pencil over a writing line.
        canvas.drawPath(
          Path()
            ..moveTo(14.6, 4.4)
            ..lineTo(19.2, 9)
            ..lineTo(9.6, 18.6)
            ..lineTo(4.4, 20)
            ..lineTo(5.8, 14.8)
            ..close(),
          stroke,
        );
        canvas.drawLine(const Offset(13, 6), const Offset(17.6, 10.6), stroke);

      case AppIcon.plan:
        // Checklist: two rows with checkmarks.
        canvas.drawRRect(
          RRect.fromLTRBR(3.5, 3.5, 20.5, 20.5, const Radius.circular(4)),
          stroke,
        );
        canvas.drawLine(const Offset(7, 9), const Offset(9.2, 11.2), stroke);
        canvas.drawLine(const Offset(9.2, 11.2), const Offset(13.5, 7.2), stroke);
        canvas.drawLine(const Offset(15, 9.2), const Offset(19, 9.2), stroke);
        canvas.drawLine(const Offset(7, 16), const Offset(9.2, 18.2), stroke);
        canvas.drawLine(const Offset(9.2, 18.2), const Offset(13.5, 14.2), stroke);
        canvas.drawLine(const Offset(15, 16.2), const Offset(19, 16.2), stroke);

      case AppIcon.papers:
        canvas.drawRRect(
          RRect.fromLTRBR(7, 3.5, 20, 17, const Radius.circular(3)),
          stroke,
        );
        canvas.drawLine(const Offset(10.5, 8), const Offset(16.5, 8), stroke);
        canvas.drawLine(const Offset(10.5, 12), const Offset(14.5, 12), stroke);
        canvas.drawPath(
          Path()
            ..moveTo(16.5, 20.5)
            ..lineTo(6.5, 20.5)
            ..cubicTo(4.9, 20.5, 4, 19.6, 4, 18)
            ..lineTo(4, 7),
          stroke,
        );

      case AppIcon.wrongBook:
        // Bookmarked page with a cross.
        canvas.drawPath(
          Path()
            ..moveTo(5.5, 4.5)
            ..lineTo(5.5, 20.4)
            ..lineTo(12, 16.4)
            ..lineTo(18.5, 20.4)
            ..lineTo(18.5, 4.5)
            ..cubicTo(18.5, 3.7, 18, 3.2, 17.2, 3.2)
            ..lineTo(6.8, 3.2)
            ..cubicTo(6, 3.2, 5.5, 3.7, 5.5, 4.5)
            ..close(),
          stroke,
        );
        canvas.drawLine(const Offset(9.8, 7.6), const Offset(14.2, 12), stroke);
        canvas.drawLine(const Offset(14.2, 7.6), const Offset(9.8, 12), stroke);

      case AppIcon.profile:
        canvas.drawCircle(const Offset(12, 8.4), 4.2, stroke);
        canvas.drawPath(
          Path()
            ..moveTo(4.6, 20.2)
            ..cubicTo(4.6, 16.2, 8, 14.2, 12, 14.2)
            ..cubicTo(16, 14.2, 19.4, 16.2, 19.4, 20.2),
          stroke,
        );

      case AppIcon.replay:
        canvas.drawArc(
          Rect.fromCircle(center: const Offset(12, 12), radius: 8),
          -2.5,
          5.0,
          false,
          stroke,
        );
        canvas.drawPath(
          Path()
            ..moveTo(5.4, 8.6)
            ..lineTo(5.0, 3.8)
            ..moveTo(5.0, 3.8)
            ..lineTo(9.8, 4.6),
          stroke,
        );

      case AppIcon.timer:
        canvas.drawCircle(const Offset(12, 13.4), 7.8, stroke);
        canvas.drawLine(const Offset(12, 9.4), const Offset(12, 13.4), stroke);
        canvas.drawLine(const Offset(12, 13.4), const Offset(15, 15.4), stroke);
        canvas.drawLine(const Offset(9.4, 2.8), const Offset(14.6, 2.8), stroke);
        canvas.drawLine(const Offset(12, 2.8), const Offset(12, 5.6), stroke);

      case AppIcon.play:
        canvas.drawCircle(const Offset(12, 12), 8.4, stroke);
        canvas.drawPath(
          Path()
            ..moveTo(10.2, 8.6)
            ..lineTo(16, 12)
            ..lineTo(10.2, 15.4)
            ..close(),
          fill,
        );

      case AppIcon.download:
        canvas.drawLine(const Offset(12, 3.6), const Offset(12, 14.6), stroke);
        canvas.drawPath(
          Path()
            ..moveTo(7.8, 10.6)
            ..lineTo(12, 14.8)
            ..lineTo(16.2, 10.6),
          stroke,
        );
        canvas.drawPath(
          Path()
            ..moveTo(4.4, 16.4)
            ..lineTo(4.4, 18.6)
            ..cubicTo(4.4, 19.8, 5.2, 20.6, 6.4, 20.6)
            ..lineTo(17.6, 20.6)
            ..cubicTo(18.8, 20.6, 19.6, 19.8, 19.6, 18.6)
            ..lineTo(19.6, 16.4),
          stroke,
        );

      case AppIcon.moon:
        canvas.drawPath(
          Path()
            ..moveTo(19.4, 14.6)
            ..cubicTo(17.8, 15.4, 15.9, 15.5, 14.1, 14.7)
            ..cubicTo(10.7, 13.2, 9.2, 9.2, 10.7, 5.8)
            ..cubicTo(11, 5.2, 11.3, 4.7, 11.7, 4.2)
            ..cubicTo(7.4, 4.6, 4.2, 8.3, 4.5, 12.6)
            ..cubicTo(4.8, 17, 8.6, 20.3, 13, 20)
            ..cubicTo(16, 19.8, 18.5, 17.7, 19.4, 14.6)
            ..close(),
          stroke,
        );

      case AppIcon.sun:
        canvas.drawCircle(const Offset(12, 12), 4.6, stroke);
        for (var i = 0; i < 8; i++) {
          final a = i * math.pi / 4;
          final cos = math.cos(a);
          final sin = math.sin(a);
          canvas.drawLine(
            Offset(12 + 6.9 * cos, 12 + 6.9 * sin),
            Offset(12 + 9.2 * cos, 12 + 9.2 * sin),
            stroke,
          );
        }

      case AppIcon.auto:
        canvas.drawCircle(const Offset(12, 12), 8.2, stroke);
        canvas.drawPath(
          Path()
            ..moveTo(12, 3.8)
            ..cubicTo(16.5, 3.8, 20.2, 7.5, 20.2, 12)
            ..cubicTo(20.2, 16.5, 16.5, 20.2, 12, 20.2)
            ..close(),
          fill,
        );

      case AppIcon.privacy:
        canvas.drawPath(
          Path()
            ..moveTo(12, 3.4)
            ..lineTo(19.4, 6.4)
            ..lineTo(19.4, 12)
            ..cubicTo(19.4, 16.4, 16.3, 19.4, 12, 20.8)
            ..cubicTo(7.7, 19.4, 4.6, 16.4, 4.6, 12)
            ..lineTo(4.6, 6.4)
            ..close(),
          stroke,
        );
        canvas.drawPath(
          Path()
            ..moveTo(9, 12.2)
            ..lineTo(11.2, 14.4)
            ..lineTo(15.2, 10),
          stroke,
        );

      case AppIcon.trash:
        canvas.drawLine(const Offset(4.4, 6.6), const Offset(19.6, 6.6), stroke);
        canvas.drawPath(
          Path()
            ..moveTo(6.6, 6.6)
            ..lineTo(7.5, 19)
            ..cubicTo(7.6, 20.1, 8.3, 20.8, 9.4, 20.8)
            ..lineTo(14.6, 20.8)
            ..cubicTo(15.7, 20.8, 16.4, 20.1, 16.5, 19)
            ..lineTo(17.4, 6.6),
          stroke,
        );
        canvas.drawPath(
          Path()
            ..moveTo(9.6, 6.6)
            ..lineTo(9.9, 4.4)
            ..cubicTo(10, 3.6, 10.5, 3.2, 11.3, 3.2)
            ..lineTo(12.7, 3.2)
            ..cubicTo(13.5, 3.2, 14, 3.6, 14.1, 4.4)
            ..lineTo(14.4, 6.6),
          stroke,
        );
        canvas.drawLine(const Offset(11, 10), const Offset(11.3, 17), stroke);
        canvas.drawLine(const Offset(13, 10), const Offset(12.7, 17), stroke);


      case AppIcon.region:
        canvas.drawPath(
          Path()
            ..moveTo(12, 21)
            ..cubicTo(16.7, 16.6, 19, 13.2, 19, 10)
            ..cubicTo(19, 6.1, 15.9, 3, 12, 3)
            ..cubicTo(8.1, 3, 5, 6.1, 5, 10)
            ..cubicTo(5, 13.2, 7.3, 16.6, 12, 21)
            ..close(),
          stroke,
        );
        canvas.drawCircle(const Offset(12, 9.8), 2.6, stroke);

      case AppIcon.calendar:
        canvas.drawRRect(
          RRect.fromLTRBR(4, 5, 20, 20, const Radius.circular(3.2)),
          stroke,
        );
        canvas.drawLine(const Offset(8, 3), const Offset(8, 7), stroke);
        canvas.drawLine(const Offset(16, 3), const Offset(16, 7), stroke);
        canvas.drawLine(const Offset(4, 10), const Offset(20, 10), stroke);

      case AppIcon.target:
        canvas.drawCircle(const Offset(12, 12), 8.4, stroke);
        canvas.drawCircle(const Offset(12, 12), 4.4, stroke);
        canvas.drawCircle(const Offset(12, 12), 1.2, fill);

      case AppIcon.stack:
        canvas.drawPath(
          Path()
            ..moveTo(12, 3.5)
            ..lineTo(20.5, 7.6)
            ..lineTo(12, 11.7)
            ..lineTo(3.5, 7.6)
            ..close(),
          stroke,
        );
        canvas.drawPath(
          Path()
            ..moveTo(3.5, 12)
            ..lineTo(12, 16.1)
            ..lineTo(20.5, 12),
          stroke,
        );
        canvas.drawPath(
          Path()
            ..moveTo(3.5, 16.4)
            ..lineTo(12, 20.5)
            ..lineTo(20.5, 16.4),
          stroke,
        );

      case AppIcon.import:
        canvas.drawPath(
          Path()
            ..moveTo(4, 15)
            ..lineTo(4, 19)
            ..cubicTo(4, 20.1, 4.9, 21, 6, 21)
            ..lineTo(18, 21)
            ..cubicTo(19.1, 21, 20, 20.1, 20, 19)
            ..lineTo(20, 15),
          stroke,
        );
        canvas.drawLine(const Offset(12, 3), const Offset(12, 15.5), stroke);
        canvas.drawPath(
          Path()
            ..moveTo(7.8, 11.3)
            ..lineTo(12, 15.5)
            ..lineTo(16.2, 11.3),
          stroke,
        );

      case AppIcon.health:
        canvas.drawCircle(const Offset(12, 12), 8.4, stroke);
        canvas.drawPath(
          Path()
            ..moveTo(4.6, 12.6)
            ..lineTo(8.6, 12.6)
            ..lineTo(10.4, 8.6)
            ..lineTo(13.4, 16)
            ..lineTo(15.2, 12.6)
            ..lineTo(19.4, 12.6),
          stroke,
        );

      case AppIcon.backup:
        canvas.drawOval(
          Rect.fromCenter(center: const Offset(12, 6.4), width: 14, height: 5.6),
          stroke,
        );
        canvas.drawPath(
          Path()
            ..moveTo(5, 6.4)
            ..lineTo(5, 17.6)
            ..moveTo(19, 6.4)
            ..lineTo(19, 17.6),
          stroke,
        );
        canvas.drawPath(
          Path()
            ..moveTo(5, 12)
            ..cubicTo(5, 13.6, 8.1, 14.8, 12, 14.8)
            ..cubicTo(15.9, 14.8, 19, 13.6, 19, 12),
          stroke,
        );
        canvas.drawPath(
          Path()
            ..moveTo(5, 17.6)
            ..cubicTo(5, 19.2, 8.1, 20.4, 12, 20.4)
            ..cubicTo(15.9, 20.4, 19, 19.2, 19, 17.6),
          stroke,
        );

      case AppIcon.spark:
        canvas.drawPath(
          Path()
            ..moveTo(10, 3)
            ..lineTo(11.7, 8.3)
            ..lineTo(17, 10)
            ..lineTo(11.7, 11.7)
            ..lineTo(10, 17)
            ..lineTo(8.3, 11.7)
            ..lineTo(3, 10)
            ..lineTo(8.3, 8.3)
            ..close(),
          stroke,
        );
        canvas.drawPath(
          Path()
            ..moveTo(17.5, 14)
            ..lineTo(18.4, 16.6)
            ..lineTo(21, 17.5)
            ..lineTo(18.4, 18.4)
            ..lineTo(17.5, 21)
            ..lineTo(16.6, 18.4)
            ..lineTo(14, 17.5)
            ..lineTo(16.6, 16.6)
            ..close(),
          stroke,
        );

      case AppIcon.search:
        canvas.drawCircle(const Offset(11, 11), 7, stroke);
        canvas.drawLine(const Offset(16.2, 16.2), const Offset(20.5, 20.5), stroke);

      case AppIcon.info:
        canvas.drawCircle(const Offset(12, 12), 8.4, stroke);
        canvas.drawLine(const Offset(12, 11), const Offset(12, 16.2), stroke);
        canvas.drawCircle(const Offset(12, 7.8), 0.95, fill);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _IconPainter old) =>
      old.icon != icon || old.color != color || old.weight != weight;
}
