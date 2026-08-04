import 'package:flutter/material.dart';
import 'package:openexam_app/core/constants/categories.dart';
import 'package:openexam_app/core/theme/app_theme.dart';
import 'package:openexam_app/core/theme/app_tokens.dart';
import 'package:openexam_app/core/ui/responsive.dart';
import 'package:openexam_app/core/ui/stroke_icons.dart';
import 'package:openexam_app/core/ui/ui_kit.dart';
import 'package:openexam_app/data/db/app_database.dart';
import 'package:openexam_app/data/models/question.dart';
import 'package:openexam_app/features/practice/practice_session_page.dart';
import 'package:openexam_app/features/profile/dashboard_page.dart';
import 'package:openexam_app/features/reports/reports_page.dart';

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
  List<ExamReport> _reports = const [];
  Map<String, int> _reasons = const {};
  List<DailyStat> _weeks = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final days = await AppDatabase.instance.dailyStats(days: 30);
    final stats = await AppDatabase.instance.categoryStats();
    final reports = await AppDatabase.instance.listReports(limit: 40);
    final reasons = await AppDatabase.instance.wrongReasonCounts();
    final weeks = await AppDatabase.instance.weeklyStats(weeks: 8);
    if (!mounted) return;
    setState(() {
      _days = days;
      _stats = stats;
      // Oldest first so the trend reads left-to-right like every other chart.
      _reports = reports.reversed.toList();
      _reasons = reasons;
      _weeks = weeks;
      _loading = false;
    });
  }

  /// Opens a saved session in review mode.
  Future<void> _review(ExamReport report) async {
    final questions = await AppDatabase.instance.fetchByIds(report.questionIds);
    if (!mounted || questions.isEmpty) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PracticeSessionPage(
          questions: questions,
          reviewAnswers: report.answers,
          title: report.title,
        ),
      ),
    );
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
          : ReadableWidth(
              maxWidth: context.isExpanded ? 880 : context.readableWidth,
              child: ListView(
              padding: const EdgeInsets.only(bottom: 30),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppTheme.gutter, 10, AppTheme.gutter, 22),
                  child: Row(
                    children: [
                      _Figure(
                        value: '$answered',
                        label: '近 30 天答题',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ReportsPage()),
                        ),
                      ),
                      _Figure(
                        value: answered == 0
                            ? '—'
                            : '${(correct * 100 / answered).round()}%',
                        label: '平均正确率',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const DashboardPage()),
                        ),
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
                if (_weeks.any((w) => w.answered > 0)) ...[
                  const SizedBox(height: 28),
                  const SectionHeader(title: '每周走势', caption: '题量与正确率，近 8 周'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.gutter),
                    child: _WeeklyChart(weeks: _weeks),
                  ),
                ],
                const SizedBox(height: 28),
                const SectionHeader(title: '正确率趋势', caption: '只统计练过的日子'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.gutter),
                  child: _AccuracyTrend(days: _days),
                ),
                const SizedBox(height: 28),
                SectionHeader(
                  title: '成绩趋势',
                  caption: _reports.length < 2
                      ? '完成 2 次以上练习后显示'
                      : '最近 ${_reports.length} 次',
                  trailing: _reports.isEmpty ? null : '全部记录',
                  onTapTrailing: _reports.isEmpty
                      ? null
                      : () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const ReportsPage()),
                          );
                          _load();
                        },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.gutter),
                  child: _ScoreTrend(
                    reports: _reports,
                    onTapLatest: _reports.isEmpty
                        ? null
                        : () => _review(_reports.last),
                  ),
                ),
                if (_reasons.isNotEmpty) ...[
                  const SizedBox(height: 28),
                  const SectionHeader(title: '错因分布', caption: '标记过的错题'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.gutter),
                    child: _ReasonBreakdown(counts: _reasons),
                  ),
                ],
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
            ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({required this.value, required this.label, this.onTap});

  final String value;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: text.headlineSmall?.copyWith(fontSize: 22)),
            const SizedBox(height: 5),
            Row(
              children: [
                Text(label, style: text.bodySmall?.copyWith(fontSize: 12)),
                if (onTap != null)
                  Icon(Icons.chevron_right, size: 13, color: t.muted),
              ],
            ),
          ],
        ),
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

/// Score per finished session — the "am I actually improving" chart. Bars
/// rather than a line, because sessions are discrete events, not a continuum.
class _ScoreTrend extends StatelessWidget {
  const _ScoreTrend({required this.reports, this.onTapLatest});

  final List<ExamReport> reports;
  final VoidCallback? onTapLatest;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    if (reports.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 22),
        child: Text('还没有成绩记录，完成一组 5 题以上的练习即可', style: text.bodySmall),
      );
    }

    final shown = reports.length > 14
        ? reports.sublist(reports.length - 14)
        : reports;
    final avg = reports.fold<int>(0, (a, r) => a + r.rate) / reports.length;
    final latest = reports.last;
    final delta = reports.length < 2
        ? 0
        : latest.rate - reports[reports.length - 2].rate;

    Color tint(int rate) => rate >= 70
        ? t.success
        : (rate >= 50 ? t.category('shuliang') : t.danger);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '${latest.rate}',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                height: 1,
                letterSpacing: -1,
                color: t.text,
                fontFeatures: AppTheme.numeric,
              ),
            ),
            Text('%', style: text.bodySmall?.copyWith(fontSize: 13)),
            const SizedBox(width: 8),
            if (reports.length >= 2)
              Text(
                delta == 0
                    ? '与上次持平'
                    : (delta > 0 ? '较上次 +$delta' : '较上次 $delta'),
                style: text.bodySmall?.copyWith(
                  color: delta > 0 ? t.success : (delta < 0 ? t.danger : t.muted),
                ),
              ),
            const Spacer(),
            Text('平均 ${avg.round()}%', style: text.bodySmall),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 92,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < shown.length; i++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: i == shown.length - 1 ? onTapLatest : null,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '${shown[i].rate}',
                            style: text.bodySmall?.copyWith(
                              fontSize: 10,
                              color: i == shown.length - 1 ? t.text : t.muted,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Stack(
                            alignment: Alignment.bottomCenter,
                            children: [
                              Container(
                                height: 58,
                                decoration: BoxDecoration(
                                  color: t.name == 'dark'
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : t.text.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                              TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0, end: shown[i].rate / 100),
                                duration: Duration(milliseconds: 320 + i * 40),
                                curve: Curves.easeOutCubic,
                                builder: (_, v, __) => Container(
                                  height: 58 * v,
                                  decoration: BoxDecoration(
                                    color: tint(shown[i].rate).withValues(
                                      alpha: i == shown.length - 1 ? 1 : 0.55,
                                    ),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Icon(
                            shown[i].isExam
                                ? Icons.timer_outlined
                                : Icons.edit_outlined,
                            size: 11,
                            color: t.muted,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '最右为最近一次（${latest.isExam ? '模考' : '练习'} · ${latest.total} 题），点它可逐题回顾',
          style: text.bodySmall?.copyWith(fontSize: 11.5),
        ),
      ],
    );
  }
}

/// 错因分布 — one bar per reason, biggest first. Tells you whether to slow
/// down (粗心/审题) or go back to the textbook (不会).
class _ReasonBreakdown extends StatelessWidget {
  const _ReasonBreakdown({required this.counts});

  final Map<String, int> counts;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final total = counts.values.fold<int>(0, (a, b) => a + b);
    if (total == 0) return const SizedBox.shrink();

    final rows = kWrongReasons
        .where((r) => (counts[r.key] ?? 0) > 0)
        .toList()
      ..sort((a, b) => (counts[b.key] ?? 0).compareTo(counts[a.key] ?? 0));

    final top = rows.first;
    final advice = switch (top.key) {
      'careless' => '大部分错题是粗心 —— 别加练，先放慢做题速度、把答案带回题干核对。',
      'unknown' => '大部分错题是知识点没掌握 —— 先回去补方法，再刷同类题。',
      'misread' => '大部分错题栽在审题 —— 做题时把限定词、单位圈出来。',
      _ => '大部分错题是时间不够 —— 先练单模块限时，再上整卷。',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final r in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              children: [
                SizedBox(
                  width: 52,
                  child: Text(r.label, style: text.titleSmall?.copyWith(fontSize: 14.5)),
                ),
                Expanded(
                  child: Meter(
                    value: (counts[r.key] ?? 0) / total,
                    color: r.key == 'unknown' ? t.danger : t.brand,
                    height: 6,
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 62,
                  child: Text(
                    '${counts[r.key]} 题',
                    textAlign: TextAlign.right,
                    style: text.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 2),
        Text(advice, style: text.bodyMedium?.copyWith(fontSize: 13.5)),
      ],
    );
  }
}

/// Weekly volume as bars with the accuracy line drawn over them — the two
/// numbers only mean something together (200 题 at 40% is not progress).
class _WeeklyChart extends StatelessWidget {
  const _WeeklyChart({required this.weeks});

  final List<DailyStat> weeks;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final max = weeks.fold<int>(0, (m, w) => w.answered > m ? w.answered : m);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 128,
          child: LayoutBuilder(
            builder: (context, box) => Stack(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var i = 0; i < weeks.length; i++)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                weeks[i].answered == 0 ? '' : '${weeks[i].answered}',
                                style: text.bodySmall?.copyWith(fontSize: 10.5),
                              ),
                              const SizedBox(height: 4),
                              TweenAnimationBuilder<double>(
                                tween: Tween(
                                  begin: 0,
                                  end: max == 0 ? 0 : weeks[i].answered / max,
                                ),
                                duration: Duration(milliseconds: 380 + i * 50),
                                curve: Curves.easeOutCubic,
                                builder: (_, v, __) => Container(
                                  height: 86 * v,
                                  decoration: BoxDecoration(
                                    color: i == weeks.length - 1
                                        ? t.brand.withValues(alpha: 0.9)
                                        : t.brand.withValues(alpha: 0.34),
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(5),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                // Accuracy overlay: only across weeks that have answers.
                Positioned.fill(
                  bottom: 0,
                  child: IgnorePointer(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOutCubic,
                      builder: (_, v, __) => CustomPaint(
                        painter: _AccuracyOverlay(
                          weeks: weeks,
                          progress: v,
                          color: t.category('shuliang'),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var i = 0; i < weeks.length; i++)
              Expanded(
                child: Text(
                  '${weeks[i].date.month}/${weeks[i].date.day}',
                  textAlign: TextAlign.center,
                  style: text.bodySmall?.copyWith(
                    fontSize: 10,
                    color: i == weeks.length - 1 ? t.brand : t.muted,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: t.brand.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 6),
            Text('题量', style: text.bodySmall?.copyWith(fontSize: 11)),
            const SizedBox(width: 16),
            Container(
              width: 14,
              height: 3,
              decoration: BoxDecoration(
                color: t.category('shuliang'),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 6),
            Text('正确率', style: text.bodySmall?.copyWith(fontSize: 11)),
          ],
        ),
      ],
    );
  }
}

class _AccuracyOverlay extends CustomPainter {
  const _AccuracyOverlay({
    required this.weeks,
    required this.progress,
    required this.color,
  });

  final List<DailyStat> weeks;
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final points = <Offset>[];
    final step = size.width / weeks.length;
    for (var i = 0; i < weeks.length; i++) {
      if (weeks[i].answered == 0) continue;
      final x = step * i + step / 2;
      // Chart area is the top 86px of the 128px box, minus the count label.
      final y = 18 + (86 * (1 - weeks[i].accuracy.clamp(0.0, 1.0)));
      points.add(Offset(x, y));
    }
    if (points.length < 2) {
      for (final p in points) {
        canvas.drawCircle(p, 3.5, Paint()..color = color);
      }
      return;
    }

    final visible = (points.length * progress).ceil().clamp(2, points.length);
    final shown = points.sublist(0, visible);
    final path = Path()..moveTo(shown.first.dx, shown.first.dy);
    for (final p in shown.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );
    for (final p in shown) {
      canvas.drawCircle(p, 3.5, Paint()..color = color);
      canvas.drawCircle(p, 1.6, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant _AccuracyOverlay old) =>
      old.progress != progress || old.weeks != weeks;
}
