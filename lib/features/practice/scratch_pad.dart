import 'dart:ui' show PointMode;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:openexam_app/core/theme/app_theme.dart';
import 'package:openexam_app/core/theme/app_tokens.dart';
import 'package:openexam_app/core/ui/stroke_icons.dart';

/// One finger stroke on the scratch pad.
class Stroke {
  Stroke(this.points, this.color, this.width);

  final List<Offset> points;
  final Color color;
  final double width;
}

/// 草稿纸 + 计算器 — 数量关系和资料分析离了这两样没法做题。Strokes are kept
/// per question by the session, so flipping back to a question restores its
/// working out.
class ScratchPad extends StatefulWidget {
  const ScratchPad({
    super.key,
    required this.strokes,
    required this.onChanged,
  });

  final List<Stroke> strokes;
  final ValueChanged<List<Stroke>> onChanged;

  @override
  State<ScratchPad> createState() => _ScratchPadState();
}

class _ScratchPadState extends State<ScratchPad> {
  late List<Stroke> _strokes = List.of(widget.strokes);
  bool _calculator = false;
  int _pen = 0;

  static const _pens = [
    (width: 3.0, label: '细'),
    (width: 6.0, label: '中'),
    (width: 10.0, label: '粗'),
  ];

  void _commit() => widget.onChanged(_strokes);

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final ink = t.name == 'dark' ? const Color(0xFF1B2430) : const Color(0xFF2B3242);
    final paper = t.name == 'dark' ? const Color(0xFFE8EDF4) : Colors.white;

    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: BoxDecoration(
        color: t.gradient.last,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: t.glassBorder)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Row(
              children: [
                _Tab(
                  label: '草稿纸',
                  selected: !_calculator,
                  onTap: () => setState(() => _calculator = false),
                ),
                const SizedBox(width: 16),
                _Tab(
                  label: '计算器',
                  selected: _calculator,
                  onTap: () => setState(() => _calculator = true),
                ),
                const Spacer(),
                if (!_calculator) ...[
                  for (var i = 0; i < _pens.length; i++)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() => _pen = i),
                      child: Container(
                        width: 30,
                        height: 30,
                        alignment: Alignment.center,
                        child: Container(
                          width: _pens[i].width + 4,
                          height: _pens[i].width + 4,
                          decoration: BoxDecoration(
                            color: _pen == i ? t.brand : t.muted,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _strokes.isEmpty
                        ? null
                        : () {
                            setState(() => _strokes.removeLast());
                            _commit();
                            HapticFeedback.selectionClick();
                          },
                    child: SizedBox(
                      width: 36,
                      height: 36,
                      child: Icon(
                        Icons.undo_rounded,
                        size: 19,
                        color: _strokes.isEmpty ? t.muted : t.textSoft,
                      ),
                    ),
                  ),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _strokes.isEmpty
                        ? null
                        : () {
                            setState(() => _strokes = []);
                            _commit();
                            HapticFeedback.mediumImpact();
                          },
                    child: SizedBox(
                      width: 36,
                      height: 36,
                      child: StrokeIcon(
                        AppIcon.trash,
                        size: 18,
                        color: _strokes.isEmpty ? t.muted : t.danger,
                      ),
                    ),
                  ),
                ],
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.of(context).pop(),
                  child: const SizedBox(
                    width: 36,
                    height: 36,
                    child: Icon(Icons.keyboard_arrow_down_rounded, size: 24),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _calculator
                  ? const _Calculator()
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        color: paper,
                        child: GestureDetector(
                          onPanStart: (d) {
                            setState(() {
                              _strokes.add(
                                Stroke([d.localPosition], ink, _pens[_pen].width),
                              );
                            });
                          },
                          onPanUpdate: (d) {
                            setState(() => _strokes.last.points.add(d.localPosition));
                          },
                          onPanEnd: (_) => _commit(),
                          child: CustomPaint(
                            painter: _PadPainter(_strokes),
                            size: Size.infinite,
                            child: _strokes.isEmpty
                                ? Center(
                                    child: Text(
                                      '在这里算',
                                      style: text.bodySmall?.copyWith(
                                        color: Colors.black.withValues(alpha: 0.22),
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? t.text : t.muted,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 2,
            width: selected ? 18 : 0,
            decoration: BoxDecoration(
              color: t.brand,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}

class _PadPainter extends CustomPainter {
  _PadPainter(this.strokes);

  final List<Stroke> strokes;

  @override
  void paint(Canvas canvas, Size size) {
    // Faint grid, like real 草稿纸.
    final grid = Paint()
      ..color = Colors.black.withValues(alpha: 0.05)
      ..strokeWidth = 1;
    for (var x = 24.0; x < size.width; x += 24) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (var y = 24.0; y < size.height; y += 24) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    for (final stroke in strokes) {
      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke
        ..isAntiAlias = true;
      if (stroke.points.length == 1) {
        canvas.drawPoints(PointMode.points, stroke.points, paint);
        continue;
      }
      final path = Path()..moveTo(stroke.points.first.dx, stroke.points.first.dy);
      for (final p in stroke.points.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PadPainter old) => true;
}

/// Plain four-function calculator with percent — enough for 资料分析.
class _Calculator extends StatefulWidget {
  const _Calculator();

  @override
  State<_Calculator> createState() => _CalculatorState();
}

class _CalculatorState extends State<_Calculator> {
  String _expr = '';
  String _result = '';

  static const _keys = [
    ['C', '(', ')', '÷'],
    ['7', '8', '9', '×'],
    ['4', '5', '6', '−'],
    ['1', '2', '3', '+'],
    ['0', '.', '%', '='],
  ];

  void _tap(String key) {
    HapticFeedback.selectionClick();
    setState(() {
      switch (key) {
        case 'C':
          _expr = '';
          _result = '';
        case '=':
          final v = _eval(_expr);
          if (v != null) {
            _result = _format(v);
            _expr = _result;
          } else {
            _result = '算不了';
          }
        default:
          _expr += key;
          final v = _eval(_expr);
          _result = v == null ? '' : _format(v);
      }
    });
  }

  void _back() {
    HapticFeedback.selectionClick();
    setState(() {
      if (_expr.isNotEmpty) _expr = _expr.substring(0, _expr.length - 1);
      final v = _eval(_expr);
      _result = v == null ? '' : _format(v);
    });
  }

  String _format(double v) {
    if (v == v.roundToDouble() && v.abs() < 1e15) return v.toInt().toString();
    return v.toStringAsFixed(4).replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  }

  /// Tiny recursive-descent parser: + − × ÷ % with parentheses.
  double? _eval(String input) {
    final src = input
        .replaceAll('×', '*')
        .replaceAll('÷', '/')
        .replaceAll('−', '-');
    if (src.trim().isEmpty) return null;
    var pos = 0;

    void skip() {
      while (pos < src.length && src[pos] == ' ') {
        pos++;
      }
    }

    // Forward declaration so primary() can recurse into a parenthesised group.
    late double? Function() expr;

    double? primary() {
      skip();
      if (pos >= src.length) return null;
      if (src[pos] == '(') {
        pos++;
        final v = expr();
        skip();
        if (pos < src.length && src[pos] == ')') pos++;
        return v;
      }
      if (src[pos] == '-') {
        pos++;
        final v = primary();
        return v == null ? null : -v;
      }
      final start = pos;
      while (pos < src.length &&
          (RegExp(r'[0-9.]').hasMatch(src[pos]))) {
        pos++;
      }
      if (start == pos) return null;
      var value = double.tryParse(src.substring(start, pos));
      if (value == null) return null;
      // Trailing % turns the number into a fraction.
      if (pos < src.length && src[pos] == '%') {
        pos++;
        value = value / 100;
      }
      return value;
    }

    double? term() {
      var left = primary();
      if (left == null) return null;
      while (true) {
        skip();
        if (pos >= src.length) return left;
        final op = src[pos];
        if (op != '*' && op != '/') return left;
        pos++;
        final right = primary();
        if (right == null) return left;
        if (op == '/' && right == 0) return null;
        left = op == '*' ? left! * right : left! / right;
      }
    }

    double? exprImpl() {
      var left = term();
      if (left == null) return null;
      while (true) {
        skip();
        if (pos >= src.length) return left;
        final op = src[pos];
        if (op != '+' && op != '-') return left;
        pos++;
        final right = term();
        if (right == null) return left;
        left = op == '+' ? left! + right : left! - right;
      }
    }

    expr = exprImpl;
    final value = expr();
    return value != null && value.isFinite ? value : null;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
          decoration: BoxDecoration(
            color: t.name == 'dark'
                ? Colors.white.withValues(alpha: 0.06)
                : t.text.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _expr.isEmpty ? '0' : _expr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  color: t.text,
                  fontFeatures: AppTheme.numeric,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _result,
                style: text.bodySmall?.copyWith(
                  fontSize: 15,
                  color: t.brand,
                  fontFeatures: AppTheme.numeric,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Column(
            children: [
              for (final row in _keys)
                Expanded(
                  child: Row(
                    children: [
                      for (final key in row)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: _Key(
                              label: key,
                              onTap: () => _tap(key),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              SizedBox(
                height: 46,
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: _Key(label: '⌫', onTap: _back),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final isOp = '÷×−+=('.contains(label) || label == ')';
    final isEquals = label == '=';

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isEquals
              ? t.brand
              : (t.name == 'dark'
                  ? Colors.white.withValues(alpha: 0.07)
                  : t.text.withValues(alpha: 0.05)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: isEquals
                ? Colors.white
                : (isOp || label == 'C' ? t.brand : t.text),
          ),
        ),
      ),
    );
  }
}
