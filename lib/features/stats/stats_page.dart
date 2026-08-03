import 'package:flutter/material.dart';
import 'package:openexam_app/core/constants/categories.dart';
import 'package:openexam_app/core/theme/app_theme.dart';
import 'package:openexam_app/core/theme/app_tokens.dart';
import 'package:openexam_app/core/ui/stroke_icons.dart';
import 'package:openexam_app/core/ui/ui_kit.dart';
import 'package:openexam_app/data/db/app_database.dart';
import 'package:openexam_app/data/models/question.dart';

/// 学习统计 — 30-day volume + accuracy trend and a per-category breakdown.
class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  bool _loading = true;
  List<DailyStat> _days = const [];
  List<CategoryStat> _stats = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final days = await AppDatabase.instance.dailyStats(days: 30);
    final stats = await AppDatabase.instance.categoryStats();
    if (!mounted) return;
    setState(() {
      _days = days;
      _stats = stats;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    final answered = _days.fold<int>(0, (s, d) => s + d.answered);
    final correct = _days.fold<int>(0, (s, d) => s + d.correct);
    final activeDays = _days.where((d) => d.answered > 0).length;
    final best = _days.fold<int>(0, (m, d) => d.answered > m ? d.answered : m);
    final ranked = [..._stats.where((s) => s.done > 0)]
      ..sort((a, b) => a.accuracy.compareTo(b.accuracy));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 21),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        titleSpacing: 0,
        title: const Text('学习统计'),
      ),
      body: _loading
          ? const LoadingState()
          : ListView(
              padding: const EdgeInsets.only(bottom: 30),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppTheme.gutter, 10, AppTheme.gutter, 22),
                  child: Row(
                    children: [
                      _Figure(value: '$answered', label: '近 30 天答题'),
                      _Figure(
                        value: answered == 0 ? '—' : '${(correct * 100 / answered).round()}%',
                        label: '平均正确率',
                      ),
                      _Figure(value: '$activeDays', label: '有效练习天'),
                    ],
                  ),
                ),
                const SectionHeader(title: '每日题量', caption: '近 30 天'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.gutter),
                  child: _VolumeChart(days: _days, max: best),
                ),
                const SizedBox(height: 28),
                const SectionHeader(title: '正确率趋势', caption: '只统计练过的日子'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.gutter),
                  child: _AccuracyTrend(days: _days),
                ),
                const SizedBox(height: 28),
                SectionHeader(
                  title: '题型强弱',
                  caption: ranked.isEmpty ? '还没有数据' : '正确率由低到高',
                ),
                if (ranked.isEmpty)
                  const EmptyState(
                    icon: Icons.insights_outlined,
                    title: '还没有练习记录',
                    message: '刷一组题后，这里会显示你的强项和弱项。',
                  )
                else
                  for (final s in ranked)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.gutter,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          StrokeIcon(
                            categoryIcon(s.category),
                            size: 19,
                            color: t.category(s.category),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 66,
                            child: Text(
                              categoryLabel(s.category),
                              style: text.titleSmall?.copyWith(fontSize: 14.5),
                            ),
                          ),
                          Expanded(
                            child: Meter(
                              value: s.accuracy,
                              color: t.category(s.category),
                              height: 6,
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 42,
                            child: Text(
                              '${(s.accuracy * 100).round()}%',
                              textAlign: TextAlign.right,
                              style: text.labelLarge?.copyWith(
                                fontFeatures: AppTheme.numeric,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 54,
                            child: Text(
                              ' ${s.done} 题',
                              textAlign: TextAlign.right,
                              style: text.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
              ],
            ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: text.headlineSmall?.copyWith(fontSize: 22)),
          const SizedBox(height: 5),
          Text(label, style: text.bodySmall?.copyWith(fontSize: 12)),
        ],
      ),
    );
  }
}

/// 30 slim bars — one per day, today on the right.
class _VolumeChart extends StatelessWidget {
  const _VolumeChart({required this.days, required this.max});

  final List<DailyStat> days;
  final int max;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final track = t.name == 'dark'
        ? Colors.white.withValues(alpha: 0.12)
        : t.text.withValues(alpha: 0.08);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 96,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < days.length; i++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1.5),
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        Container(
                          height: 96,
                          decoration: BoxDecoration(
                            color: track,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        TweenAnimationBuilder<double>(
                          tween: Tween(
                            begin: 0,
                            end: max == 0 || days[i].answered == 0
                                ? 0
                                : (days[i].answered / max).clamp(0.08, 1.0),
                          ),
                          duration: Duration(milliseconds: 300 + i * 12),
                          curve: Curves.easeOutCubic,
                          builder: (_, v, __) => Container(
                            height: 96 * v,
                            decoration: BoxDecoration(
                              color: i == days.length - 1
                                  ? t.brand
                                  : t.brand.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(_label(days.first.date), style: text.bodySmall?.copyWith(fontSize: 11)),
            const Spacer(),
            Text('峰值 $max 题', style: text.bodySmall?.copyWith(fontSize: 11)),
            const Spacer(),
            Text('今天', style: text.bodySmall?.copyWith(fontSize: 11)),
          ],
        ),
      ],
    );
  }

  String _label(DateTime d) => '${d.month}/${d.day}';
}

/// Accuracy line over the days that actually have answers.
class _AccuracyTrend extends StatelessWidget {
  const _AccuracyTrend({required this.days});

  final List<DailyStat> days;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final points = days.where((d) => d.answered > 0).toList();

    if (points.length < 2) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(
          points.isEmpty ? '还没有练习记录' : '再练一天就能看到趋势了',
          style: text.bodySmall,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 110,
          child: CustomPaint(
            size: const Size(double.infinity, 110),
            painter: _TrendPainter(
              values: points.map((p) => p.accuracy).toList(),
              color: t.brand,
              grid: t.name == 'dark'
                  ? Colors.white.withValues(alpha: 0.10)
                  : t.text.withValues(alpha: 0.08),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text('${_pct(points.first.accuracy)} 起', style: text.bodySmall?.copyWith(fontSize: 11)),
            const Spacer(),
            Text(
              '最新 ${_pct(points.last.accuracy)}',
              style: text.bodySmall?.copyWith(fontSize: 11, color: t.brand),
            ),
          ],
        ),
      ],
    );
  }

  String _pct(double v) => '${(v * 100).round()}%';
}

class _TrendPainter extends CustomPainter {
  const _TrendPainter({
    required this.values,
    required this.color,
    required this.grid,
  });

  final List<double> values;
  final Color color;
  final Color grid;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final step = values.length == 1 ? 0.0 : size.width / (values.length - 1);
    final points = [
      for (var i = 0; i < values.length; i++)
        Offset(step * i, size.height * (1 - values[i].clamp(0.0, 1.0))),
    ];

    // Soft fill under the line, then the line itself.
    final area = Path()..moveTo(points.first.dx, size.height);
    for (final p in points) {
      area.lineTo(p.dx, p.dy);
    }
    area
      ..lineTo(points.last.dx, size.height)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.28), color.withValues(alpha: 0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    final line = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      line.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      line,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color
        ..isAntiAlias = true,
    );

    canvas.drawCircle(points.last, 4.5, Paint()..color = color);
    canvas.drawCircle(points.last, 2, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _TrendPainter old) =>
      old.values != values || old.color != color;
}
