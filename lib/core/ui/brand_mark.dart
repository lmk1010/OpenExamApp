import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// The OpenExam open-book mark, drawn as vector paths so it scales cleanly and
/// carries no baked-in background — it sits on any theme.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 28});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _BookPainter()),
    );
  }
}

class _BookPainter extends CustomPainter {
  // 桌面端 logo 的四段渐变：橙 → 粉 → 紫 → 靛。
  static const _colors = [
    Color(0xFFF0862C),
    Color(0xFFEC4A79),
    Color(0xFF9B5DE5),
    Color(0xFF5B6BE8),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final dx = (size.width - s) / 2;
    final dy = (size.height - s) / 2;

    // 桌面端 logo 是在 100×100 的格子上画的，这里照搬同一套坐标，
    // 免得两端的书本长得不一样。
    Offset p(double x, double y) => Offset(dx + x / 100 * s, dy + y / 100 * s);
    double u(double v) => v / 100 * s;

    final shader = ui.Gradient.linear(
      p(16, 14),
      p(84, 82),
      _colors,
      const [0, 0.34, 0.68, 1],
    );

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = u(4.6)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = shader
      ..isAntiAlias = true;

    // 书封：两侧包住内页的外壳。
    final leftCover = Path()
      ..moveTo(p(28, 23.5).dx, p(28, 23.5).dy)
      ..lineTo(p(21.5, 26.4).dx, p(21.5, 26.4).dy)
      ..cubicTo(p(19.8, 27.2).dx, p(19.8, 27.2).dy, p(19, 28.4).dx,
          p(19, 28.4).dy, p(19, 30).dx, p(19, 30).dy)
      ..lineTo(p(19, 70.4).dx, p(19, 70.4).dy)
      ..cubicTo(p(19, 72.5).dx, p(19, 72.5).dy, p(20.7, 74.2).dx,
          p(20.7, 74.2).dy, p(22.9, 74.2).dx, p(22.9, 74.2).dy)
      ..lineTo(p(43.5, 74.2).dx, p(43.5, 74.2).dy);

    final rightCover = Path()
      ..moveTo(p(72, 23.5).dx, p(72, 23.5).dy)
      ..lineTo(p(78.5, 26.4).dx, p(78.5, 26.4).dy)
      ..cubicTo(p(80.2, 27.2).dx, p(80.2, 27.2).dy, p(81, 28.4).dx,
          p(81, 28.4).dy, p(81, 30).dx, p(81, 30).dy)
      ..lineTo(p(81, 70.4).dx, p(81, 70.4).dy)
      ..cubicTo(p(81, 72.5).dx, p(81, 72.5).dy, p(79.3, 74.2).dx,
          p(79.3, 74.2).dy, p(77.1, 74.2).dx, p(77.1, 74.2).dy)
      ..lineTo(p(56.5, 74.2).dx, p(56.5, 74.2).dy);

    // 内页：从书脊向两侧翻开，页面本身是浅色的。
    final leftPage = Path()
      ..moveTo(p(50, 30.5).dx, p(50, 30.5).dy)
      ..cubicTo(p(44.2, 21.4).dx, p(44.2, 21.4).dy, p(37, 17.2).dx,
          p(37, 17.2).dy, p(28, 17.2).dx, p(28, 17.2).dy)
      ..lineTo(p(28, 66.2).dx, p(28, 66.2).dy)
      ..cubicTo(p(37, 66.2).dx, p(37, 66.2).dy, p(44.6, 69.6).dx,
          p(44.6, 69.6).dy, p(50, 76.4).dx, p(50, 76.4).dy)
      ..close();

    final rightPage = Path()
      ..moveTo(p(50, 30.5).dx, p(50, 30.5).dy)
      ..cubicTo(p(55.8, 21.4).dx, p(55.8, 21.4).dy, p(63, 17.2).dx,
          p(63, 17.2).dy, p(72, 17.2).dx, p(72, 17.2).dy)
      ..lineTo(p(72, 66.2).dx, p(72, 66.2).dy)
      ..cubicTo(p(63, 66.2).dx, p(63, 66.2).dy, p(55.4, 69.6).dx,
          p(55.4, 69.6).dy, p(50, 76.4).dx, p(50, 76.4).dy)
      ..close();

    final pageFill = Paint()
      ..isAntiAlias = true
      ..shader = ui.Gradient.linear(
        p(22, 18),
        p(78, 78),
        const [Color(0xFFFFF3E4), Color(0xFFFFFDFB), Color(0xFFFFF7FB)],
        const [0, 0.55, 1],
      );

    canvas.drawPath(leftCover, stroke);
    canvas.drawPath(rightCover, stroke);
    canvas.drawPath(leftPage, pageFill);
    canvas.drawPath(rightPage, pageFill);
    canvas.drawPath(leftPage, stroke);
    canvas.drawPath(rightPage, stroke);

    // 右页上的三条字线。
    final rule = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = u(4)
      ..strokeCap = StrokeCap.round
      ..shader = shader
      ..isAntiAlias = true;

    canvas.drawLine(p(58, 38.6), p(67.6, 35.9), rule);
    canvas.drawLine(p(58, 46.6), p(67.6, 43.9), rule);
    canvas.drawLine(p(58, 54.6), p(67.6, 51.9), rule);
  }

  @override
  bool shouldRepaint(covariant _BookPainter oldDelegate) => false;
}
