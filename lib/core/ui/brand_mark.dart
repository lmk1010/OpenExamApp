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
  // Desktop-logo gradient: orange → pink → violet → indigo.
  static const _colors = [
    Color(0xFFF08A2C),
    Color(0xFFEC4A79),
    Color(0xFF9B5DE5),
    Color(0xFF6366F1),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final dx = (size.width - s) / 2;
    final dy = (size.height - s) / 2;

    Offset p(double x, double y) => Offset(dx + x * s, dy + y * s);

    final shader = ui.Gradient.linear(
      p(0, 0),
      p(1, 1),
      _colors,
      const [0, 0.35, 0.7, 1],
    );

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.075
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = shader
      ..isAntiAlias = true;

    // Left page: outer cover down the left edge, inner leaf curving to the spine.
    final left = Path()
      ..moveTo(p(0.50, 0.80).dx, p(0.50, 0.80).dy)
      ..cubicTo(p(0.40, 0.68).dx, p(0.40, 0.68).dy, p(0.24, 0.64).dx,
          p(0.24, 0.64).dy, p(0.11, 0.65).dx, p(0.11, 0.65).dy)
      ..lineTo(p(0.11, 0.24).dx, p(0.11, 0.24).dy)
      ..cubicTo(p(0.26, 0.23).dx, p(0.26, 0.23).dy, p(0.42, 0.28).dx,
          p(0.42, 0.28).dy, p(0.50, 0.40).dx, p(0.50, 0.40).dy)
      ..lineTo(p(0.50, 0.80).dx, p(0.50, 0.80).dy);

    // Right page mirrors it around the spine.
    final right = Path()
      ..moveTo(p(0.50, 0.80).dx, p(0.50, 0.80).dy)
      ..cubicTo(p(0.60, 0.68).dx, p(0.60, 0.68).dy, p(0.76, 0.64).dx,
          p(0.76, 0.64).dy, p(0.89, 0.65).dx, p(0.89, 0.65).dy)
      ..lineTo(p(0.89, 0.24).dx, p(0.89, 0.24).dy)
      ..cubicTo(p(0.74, 0.23).dx, p(0.74, 0.23).dy, p(0.58, 0.28).dx,
          p(0.58, 0.28).dy, p(0.50, 0.40).dx, p(0.50, 0.40).dy)
      ..lineTo(p(0.50, 0.80).dx, p(0.50, 0.80).dy);

    canvas.drawPath(left, stroke);
    canvas.drawPath(right, stroke);

    // Text lines on the right leaf.
    final rule = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.062
      ..strokeCap = StrokeCap.round
      ..shader = shader
      ..isAntiAlias = true;

    canvas.drawLine(p(0.62, 0.40), p(0.79, 0.365), rule);
    canvas.drawLine(p(0.62, 0.505), p(0.79, 0.47), rule);
    canvas.drawLine(p(0.62, 0.61), p(0.79, 0.575), rule);
  }

  @override
  bool shouldRepaint(covariant _BookPainter oldDelegate) => false;
}
