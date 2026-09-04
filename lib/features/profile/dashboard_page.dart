
import 'package:flutter/material.dart';
import 'package:openexam_app/core/constants/app_constants.dart';
import 'package:openexam_app/core/constants/categories.dart';
import 'package:openexam_app/core/theme/app_theme.dart';
import 'package:openexam_app/core/theme/app_tokens.dart';
import 'package:openexam_app/core/ui/shore.dart';
import 'package:openexam_app/features/practice/shore_home.dart';
import 'package:openexam_app/core/ui/glass.dart';
import 'package:openexam_app/core/ui/responsive.dart';
import 'package:openexam_app/core/ui/stroke_icons.dart';
import 'package:openexam_app/core/ui/ui_kit.dart';
import 'package:openexam_app/data/db/app_database.dart';
import 'package:openexam_app/data/models/question.dart';
import 'package:openexam_app/features/practice/practice_session_page.dart';
import 'package:openexam_app/features/shell/app_shell.dart';
import 'package:openexam_app/features/reports/reports_page.dart';
import 'package:openexam_app/features/stats/stats_page.dart';
import 'package:openexam_app/features/wrong/wrong_book_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 备考档案 — the one screen that answers "where do I actually stand".
/// Everything animates in on open, because this page is meant to be looked at.
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _loading = true;
  Map<String, ({int done, int correct})> _thisWeek = const {};
  Map<String, ({int done, int correct})> _lastWeek = const {};

  String _name = '备考中';
  DateTime? _examDate;
  int _goal = 30;

  int _answers = 0;
  int _correct = 0;
  int _wrong = 0;
  int _streak = 0;
  int _activeDays = 0;
  List<CategoryStat> _stats = const [];
  List<DailyStat> _days = const [];
  List<ExamReport> _reports = const [];
  Map<String, int> _reasons = const {};
  Map<String, double> _pace = const {};
  List<int> _hours = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = AppDatabase.instance;
    final prefs = await SharedPreferences.getInstance();
    final stats = await db.categoryStats();
    final days = await db.dailyStats(days: 35);
    final reports = await db.listReports(limit: 20);
    final reasons = await db.wrongReasonCounts();
    final pace = await db.categoryPace();
    final hours = await db.hourlyActivity();
    final answers = await db.countAnswers();
    final wrong = await db.countWrong();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final thisWeek = await db.categoryAccuracyBetween(
      today.subtract(const Duration(days: 6)),
      today.add(const Duration(days: 1)),
    );
    final lastWeek = await db.categoryAccuracyBetween(
      today.subtract(const Duration(days: 13)),
      today.subtract(const Duration(days: 6)),
    );

    var streak = 0;
    for (var i = days.length - 1; i >= 0; i--) {
      if (days[i].answered == 0) break;
      streak++;
    }

    if (!mounted) return;
    setState(() {
      _name = prefs.getString(Prefs.nickname) ?? '备考中';
      _goal = prefs.getInt(Prefs.dailyGoal) ?? 30;
      final raw = prefs.getString(Prefs.examDate);
      _examDate = raw == null ? null : DateTime.tryParse(raw);
      _stats = stats;
      _days = days;
      _reports = reports.reversed.toList();
      _reasons = reasons;
      _pace = pace;
      _hours = hours;
      _answers = answers;
      _wrong = wrong;
      _thisWeek = thisWeek;
      _lastWeek = lastWeek;
      _correct = stats.fold<int>(0, (a, s) => a + s.correct);
      _streak = streak;
      _activeDays = days.where((d) => d.answered > 0).length;
      _loading = false;
    });
  }

  int get _rate {
    final done = _stats.fold<int>(0, (a, s) => a + s.done);
    return done == 0 ? 0 : (_correct * 100 / done).round();
  }

  int? get _daysLeft {
    if (_examDate == null) return null;
    final now = DateTime.now();
    return _examDate!.difference(DateTime(now.year, now.month, now.day)).inDays;
  }

  Future<void> _push(Widget page) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
    if (mounted) _load();
  }

  /// Tapping a module bar practises that module — the number is only useful if
  /// it leads somewhere.
  Future<void> _practiseModule(String category) async {
    final questions = await AppDatabase.instance.fetchPractice(
      category: category,
      limit: _goal.clamp(10, 30),
    );
    if (!mounted || questions.isEmpty) return;
    await _push(
      PracticeSessionPage(questions: questions, title: categoryLabel(category)),
    );
  }

  Future<void> _practiseWeakest() async {
    final questions = await AppDatabase.instance.fetchAdaptive(limit: _goal);
    if (!mounted || questions.isEmpty) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PracticeSessionPage(questions: questions, title: '弱项强化'),
      ),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final ranked = [..._stats.where((s) => s.done > 0)]
      ..sort((a, b) => a.accuracy.compareTo(b.accuracy));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 21),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        titleSpacing: 0,
        title: const Text('备考档案'),
      ),
      body: _loading
          ? const LoadingState()
          : ReadableWidth(
              maxWidth: context.isExpanded ? 880 : context.readableWidth,
              child: ListView(
              padding: const EdgeInsets.fromLTRB(AppTheme.gutter, 6, AppTheme.gutter, 30),
              children: [
                _Reveal(
                  delay: 0,
                  child: _Header(
                    name: _name,
                    daysLeft: _daysLeft,
                    activeDays: _activeDays,
                    streak: _streak,
                  ),
                ),
                const SizedBox(height: 26),
                _Reveal(
                  delay: 90,
                  child: _AccuracyBlock(
                    rate: _rate,
                    answered: _answers,
                    correct: _correct,
                    wrong: _wrong,
                    goal: _goal,
                    todayDone: _days.isEmpty ? 0 : _days.last.answered,
                    onTapAnswers: () => _push(const StatsPage()),
                    onTapWrong: () => _push(
                      const Scaffold(
                        body: SafeArea(child: WrongBookPage()),
                      ),
                    ),
                    onTapToday: () => _push(const ReportsPage()),
                  ),
                ),
                const SizedBox(height: 30),
                if (ranked.isNotEmpty) ...[
                  _Reveal(
                    delay: 180,
                    child: _SectionTitle(
                      title: '模块能力',
                      caption: '正确率由低到高',
                    ),
                  ),
                  const SizedBox(height: 14),
                  for (var i = 0; i < ranked.length; i++)
                    _Reveal(
                      delay: 220 + i * 60,
                      child: _ModuleBar(
                        stat: ranked[i],
                        pace: _pace[ranked[i].category],
                        rank: i,
                        onTap: () => _practiseModule(ranked[i].category),
                      ),
                    ),
                  const SizedBox(height: 26),
                ],
                _Reveal(
                  delay: 300,
                  child: _SectionTitle(title: '最近 35 天', caption: '颜色越深练得越多'),
                ),
                const SizedBox(height: 14),
                _Reveal(
                  delay: 340,
                  child: ShoreCard(child: _Heatmap(days: _days, goal: _goal)),
                ),
                const SizedBox(height: 30),
                if (_reports.length >= 2) ...[
                  _Reveal(
                    delay: 380,
                    child: _SectionTitle(
                      title: '成绩走势',
                      caption: '最近 ${_reports.length} 次',
                    ),
                  ),
                  const SizedBox(height: 14),
                  _Reveal(
                    delay: 420,
                    child: ShoreCard(child: _Sparkline(reports: _reports)),
                  ),
                  const SizedBox(height: 30),
                ],
                if (_hours.any((n) => n > 0)) ...[
                  _Reveal(
                    delay: 440,
                    child: _SectionTitle(title: '习惯时段', caption: '一天里你在什么时候刷题'),
                  ),
                  const SizedBox(height: 14),
                  _Reveal(delay: 470, child: _HourStrip(hours: _hours)),
                  const SizedBox(height: 30),
                ],
                _Reveal(
                  delay: 500,
                  child: _SectionTitle(title: '给你的建议', caption: '按当前数据推断'),
                ),
                const SizedBox(height: 14),
                for (var i = 0; i < _advice(ranked).length; i++)
                  _Reveal(
                    delay: 540 + i * 70,
                    child: _AdviceCard(
                      advice: _advice(ranked)[i],
                      onAct: switch (_advice(ranked)[i]) {
                        final a when a.onAct != null => () => a.onAct!(context),
                        final a when a.actionable => _practiseWeakest,
                        _ => null,
                      },
                    ),
                  ),
                if (_answers == 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      '刷完第一组题，这一页就会有内容。',
                      style: text.bodySmall,
                    ),
                  ),
                const SizedBox(height: 10),
                Text(
                  '数据只统计本机记录，清除练习记录后这一页会重新开始。',
                  style: text.bodySmall?.copyWith(color: t.muted),
                ),
              ],
            ),
            ),
    );
  }

  /// Turns the numbers into things to actually do.
  List<_Advice> _advice(List<CategoryStat> ranked) {
    final out = <_Advice>[];

    if (_answers == 0) {
      out.add(const _Advice(
        icon: AppIcon.practice,
        title: '先刷一组 20 题',
        body: '有了记录才能算正确率、排弱项，这一页也才有东西可看。',
      ));
      return out;
    }

    if (ranked.isNotEmpty && ranked.first.accuracy < 0.7) {
      final weak = ranked.first;
      out.add(_Advice(
        icon: categoryIcon(weak.category),
        title: '${categoryLabel(weak.category)}是当前短板',
        body: '正确率 ${(weak.accuracy * 100).round()}%，已练 ${weak.done} 题。'
            '弱项强化会给它最大配额，先把这块拉到 70% 以上。',
        actionable: true,
      ));
    }

    final topReason = _reasons.entries.fold<MapEntry<String, int>?>(
      null,
      (best, e) => best == null || e.value > best.value ? e : best,
    );
    if (topReason != null && topReason.value >= 3) {
      out.add(_Advice(
        icon: AppIcon.wrongBook,
        title: switch (topReason.key) {
          'careless' => '错题里"粗心"最多',
          'unknown' => '错题里"不会"最多',
          'misread' => '错题里"审题"最多',
          _ => '错题里"没时间"最多',
        },
        body: switch (topReason.key) {
          'careless' => '${topReason.value} 道标了粗心。别加量，做完把答案带回题干核对一遍。',
          'unknown' => '${topReason.value} 道标了不会。先回去补方法，再刷同类题才有意义。',
          'misread' => '${topReason.value} 道栽在审题。做题时把限定词和单位圈出来。',
          _ => '${topReason.value} 道是时间不够。先按模块限时练，再上整卷。',
        },
        actionLabel: '去错题本按错因过一遍',
        onAct: (context) async {
          AppShell.jumpTo.value = AppShell.wrongBookTab;
          Navigator.of(context).popUntil((r) => r.isFirst);
        },
      ));
    }

    // 最近 7 天 vs 前 7 天：累计正确率会把最近的变化稀释掉，看不出退步。
    final moved = <({String key, int now, int before, int done})>[];
    for (final entry in _thisWeek.entries) {
      final before = _lastWeek[entry.key];
      if (before == null || before.done < 5 || entry.value.done < 5) continue;
      moved.add((
        key: entry.key,
        now: (entry.value.correct * 100 / entry.value.done).round(),
        before: (before.correct * 100 / before.done).round(),
        done: entry.value.done,
      ));
    }
    moved.sort((a, b) => (a.now - a.before).compareTo(b.now - b.before));
    if (moved.isNotEmpty) {
      final worst = moved.first;
      final best = moved.last;
      if (worst.now - worst.before <= -8) {
        out.add(_Advice(
          icon: categoryIcon(worst.key),
          title: '${categoryLabel(worst.key)}这周退了 ${worst.before - worst.now} 个点',
          body: '上一周 ${worst.before}%，最近 7 天 ${worst.now}%（${worst.done} 题）。'
              '先别加量，去错题本按这个模块过一遍，看是同一类题反复错还是手生了。',
          actionLabel: '看这个模块的错题',
          onAct: (context) async {
            AppShell.jumpTo.value = AppShell.wrongBookTab;
            Navigator.of(context).popUntil((r) => r.isFirst);
          },
        ));
      } else if (best.now - best.before >= 8) {
        out.add(_Advice(
          icon: categoryIcon(best.key),
          title: '${categoryLabel(best.key)}这周涨了 ${best.now - best.before} 个点',
          body: '上一周 ${best.before}%，最近 7 天 ${best.now}%（${best.done} 题）。'
              '这块的练法是对的，可以开始压时间了。',
        ));
      }
    }

    final slow = _pace.entries
        .where((e) => e.value > 75)
        .fold<MapEntry<String, double>?>(
          null,
          (best, e) => best == null || e.value > best.value ? e : best,
        );
    if (slow != null) {
      out.add(_Advice(
        icon: AppIcon.timer,
        title: '${categoryLabel(slow.key)}花的时间偏长',
        body: '平均每题 ${slow.value.round()} 秒。行测里超过 90 秒的题在考场上应该先跳过，'
            '练的时候也要按这个标准掐表。',
        actionLabel: '限时练这个模块',
        onAct: (context) async {
          final questions = await AppDatabase.instance.fetchPractice(
            category: slow.key,
            limit: 15,
            shuffle: true,
          );
          if (!context.mounted || questions.isEmpty) return;
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PracticeSessionPage(
                questions: questions,
                limit: Duration(seconds: 55 * questions.length),
                title: '${categoryLabel(slow.key)}限时练',
              ),
            ),
          );
        },
      ));
    }

    if (_streak == 0) {
      out.add(const _Advice(
        icon: AppIcon.chart,
        title: '连续打卡断了',
        body: '每天 10 题也算数，节奏比单次量更重要。',
        actionable: true,
      ));
    } else if (_streak >= 3) {
      out.add(_Advice(
        icon: AppIcon.chart,
        title: '已经连续 $_streak 天',
        body: '保持住。真正拉开差距的是能不能天天回来，而不是某天刷了 200 题。',
      ));
    }

    if (out.isEmpty) {
      out.add(const _Advice(
        icon: AppIcon.chart,
        title: '各项都挺稳',
        body: '可以开始按整卷限时练，把速度也压进考试节奏。',
      ));
    }
    return out;
  }
}

/// Slides + fades a block in, staggered by [delay].
class _Reveal extends StatelessWidget {
  const _Reveal({required this.delay, required this.child});

  final int delay;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 420 + delay),
      curve: Interval(
        (delay / (420 + delay)).clamp(0.0, 0.9),
        1,
        curve: Curves.easeOutCubic,
      ),
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, 18 * (1 - v)), child: child),
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.caption});

  final String title;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(title, style: text.titleMedium),
        if (caption != null) ...[
          const SizedBox(width: 8),
          Text(caption!, style: text.bodySmall),
        ],
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.name,
    required this.daysLeft,
    required this.activeDays,
    required this.streak,
  });

  final String name;
  final int? daysLeft;
  final int activeDays;
  final int streak;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: text.displaySmall?.copyWith(fontSize: 24)),
              const SizedBox(height: 8),
              Text(
                '练过 $activeDays 天 · 连续 $streak 天',
                style: text.bodySmall?.copyWith(fontSize: 13),
              ),
            ],
          ),
        ),
        if (daysLeft != null && daysLeft! >= 0)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: daysLeft!.toDouble()),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, __) => Text(
                      '${v.round()}',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        height: 1,
                        letterSpacing: -1,
                        color: t.brand,
                        fontFeatures: AppTheme.numeric,
                      ),
                    ),
                  ),
                  const SizedBox(width: 3),
                  Text('天', style: text.bodySmall?.copyWith(color: t.brand)),
                ],
              ),
              const SizedBox(height: 5),
              Text('距考试', style: text.bodySmall?.copyWith(fontSize: 11.5)),
            ],
          ),
      ],
    );
  }
}

/// Big animated ring plus the three figures that matter next to it.
class _AccuracyBlock extends StatelessWidget {
  const _AccuracyBlock({
    required this.rate,
    required this.answered,
    required this.correct,
    required this.wrong,
    required this.goal,
    required this.todayDone,
    required this.onTapAnswers,
    required this.onTapWrong,
    required this.onTapToday,
  });

  final int rate;
  final int answered;
  final int correct;
  final int wrong;
  final int goal;
  final int todayDone;
  final VoidCallback onTapAnswers;
  final VoidCallback onTapWrong;
  final VoidCallback onTapToday;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Row(
      children: [
        // 正确率环换成罗盘：跟练习结果页、申论批改是同一个读数器。
        // 一个 app 里不该有两种"环形分数"的画法。
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: answered == 0 ? 0 : rate / 100),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          builder: (context, v, _) => CompassDial(
            value: v,
            label: answered == 0 ? '—' : '${(v * 100).round()}%',
            caption: '总正确率',
            size: 132,
            color: answered == 0 ? t.line : null,
          ),
        ),
        const SizedBox(width: 22),
        Expanded(
          child: Column(
            children: [
              _Figure(
                icon: AppIcon.practice,
                color: t.brand,
                label: '累计答题',
                value: '$correct / $answered',
                onTap: onTapAnswers,
              ),
              const SizedBox(height: 15),
              _Figure(
                icon: AppIcon.wrongBook,
                color: t.danger,
                label: '待清错题',
                value: '$wrong',
                onTap: onTapWrong,
              ),
              const SizedBox(height: 15),
              _Figure(
                icon: AppIcon.chart,
                color: t.success,
                label: '今日进度',
                value: '$todayDone / $goal',
                onTap: onTapToday,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    this.onTap,
  });

  final AppIcon icon;
  final Color color;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Row(
        children: [
          StrokeIcon(icon, size: 17, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: text.bodySmall?.copyWith(fontSize: 13))),
          Text(
            value,
            style: text.titleSmall?.copyWith(
              fontSize: 15.5,
              fontFeatures: AppTheme.numeric,
            ),
          ),
          if (onTap != null)
            Icon(Icons.chevron_right, size: 15, color: t.muted),
        ],
      ),
    );
  }
}


/// One module: name, animated accuracy bar, pace, and how much is left.
class _ModuleBar extends StatelessWidget {
  const _ModuleBar({
    required this.stat,
    required this.pace,
    required this.rank,
    required this.onTap,
  });

  final CategoryStat stat;
  final double? pace;
  final int rank;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final color = t.category(stat.category);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StrokeIcon(categoryIcon(stat.category), size: 17, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  categoryLabel(stat.category),
                  style: text.titleSmall?.copyWith(fontSize: 14.5),
                ),
              ),
              if (pace != null) ...[
                Text('${pace!.round()}s/题', style: text.bodySmall?.copyWith(fontSize: 11.5)),
                const SizedBox(width: 10),
              ],
              Text(
                '${stat.done} 题',
                style: text.bodySmall?.copyWith(fontSize: 11.5),
              ),
              const SizedBox(width: 10),
              Text(
                '${(stat.accuracy * 100).round()}%',
                style: text.labelLarge?.copyWith(
                  color: color,
                  fontFeatures: AppTheme.numeric,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: stat.accuracy.clamp(0.0, 1.0)),
            duration: Duration(milliseconds: 700 + rank * 90),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: v,
                minHeight: 7,
                color: color,
                backgroundColor: t.name == 'dark'
                    ? Colors.white.withValues(alpha: 0.10)
                    : t.text.withValues(alpha: 0.08),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}

/// 35 days as a 7×5 grid — the shape of a study habit.
class _Heatmap extends StatelessWidget {
  const _Heatmap({required this.days, required this.goal});

  final List<DailyStat> days;
  final int goal;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final empty = t.name == 'dark'
        ? Colors.white.withValues(alpha: 0.05)
        : t.text.withValues(alpha: 0.045);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, box) {
            const cols = 7;
            const gap = 5.0;
            // Cap cell size so a wide tablet doesn't turn the grid into tiles.
            final raw = (box.maxWidth - gap * (cols - 1)) / cols;
            final cell = raw.clamp(18.0, 28.0);
            final gridWidth = cell * cols + gap * (cols - 1);
            return Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: gridWidth,
                child: Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (var i = 0; i < days.length; i++)
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: Duration(milliseconds: 260 + i * 14),
                        curve: Curves.easeOut,
                        builder: (_, v, __) => Opacity(
                          opacity: v,
                          child: Container(
                            width: cell,
                            height: cell,
                            decoration: BoxDecoration(
                              color: days[i].answered == 0
                                  ? empty
                                  : t.brand.withValues(
                                      alpha: goal <= 0 ||
                                              days[i].answered >= goal
                                          ? 0.95
                                          : (0.25 +
                                                  0.6 *
                                                      (days[i].answered /
                                                          goal))
                                              .clamp(0.25, 0.9),
                                    ),
                              borderRadius: BorderRadius.circular(6),
                              border: i == days.length - 1
                                  ? Border.all(
                                      color: t.brand.withValues(alpha: 0.6),
                                      width: 1.2,
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Text('少', style: text.bodySmall?.copyWith(fontSize: 11)),
            const SizedBox(width: 6),
            for (final a in [0.1, 0.35, 0.6, 0.95])
              Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: t.brand.withValues(alpha: a),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            Text('多', style: text.bodySmall?.copyWith(fontSize: 11)),
            const Spacer(),
            Text(
              '右下角为今天',
              style: text.bodySmall?.copyWith(fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }
}

/// Score per session as a line — improvement, or the lack of it.
class _Sparkline extends StatelessWidget {
  const _Sparkline({required this.reports});

  final List<ExamReport> reports;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final values = reports.map((r) => r.rate / 100).toList();
    final delta = reports.last.rate - reports.first.rate;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 96,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => CustomPaint(
              size: const Size(double.infinity, 96),
              painter: _LinePainter(
                values: values,
                progress: v,
                color: t.brand,
                grid: t.name == 'dark'
                    ? Colors.white.withValues(alpha: 0.08)
                    : t.text.withValues(alpha: 0.07),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          delta == 0
              ? '最近一次 ${reports.last.rate}%，和最早那次持平'
              : (delta > 0
                  ? '从 ${reports.first.rate}% 到 ${reports.last.rate}%，涨了 $delta 个点'
                  : '从 ${reports.first.rate}% 到 ${reports.last.rate}%，掉了 ${-delta} 个点'),
          style: text.bodySmall,
        ),
      ],
    );
  }
}

class _LinePainter extends CustomPainter {
  const _LinePainter({
    required this.values,
    required this.progress,
    required this.color,
    required this.grid,
  });

  final List<double> values;
  final double progress;
  final Color color;
  final Color grid;

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i <= 3; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        Paint()
          ..color = grid
          ..strokeWidth = 1,
      );
    }
    if (values.length < 2) return;

    final step = size.width / (values.length - 1);
    final points = [
      for (var i = 0; i < values.length; i++)
        Offset(step * i, size.height * (1 - values[i].clamp(0.0, 1.0))),
    ];

    final visible = (points.length * progress).ceil().clamp(2, points.length);
    final shown = points.sublist(0, visible);

    final area = Path()..moveTo(shown.first.dx, size.height);
    for (final p in shown) {
      area.lineTo(p.dx, p.dy);
    }
    area
      ..lineTo(shown.last.dx, size.height)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.26), color.withValues(alpha: 0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    final line = Path()..moveTo(shown.first.dx, shown.first.dy);
    for (final p in shown.skip(1)) {
      line.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      line,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );
    canvas.drawCircle(shown.last, 5, Paint()..color = color);
    canvas.drawCircle(shown.last, 2.2, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _LinePainter old) =>
      old.progress != progress || old.values != values;
}

/// 24 slim bars: when in the day the answers happened.
class _HourStrip extends StatelessWidget {
  const _HourStrip({required this.hours});

  final List<int> hours;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final max = hours.fold<int>(0, (m, n) => n > m ? n : m);
    final peak = hours.indexOf(max);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 62,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var h = 0; h < 24; h++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1.5),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(
                        begin: 0,
                        end: max == 0 ? 0 : (hours[h] / max).clamp(0.0, 1.0),
                      ),
                      duration: Duration(milliseconds: 420 + h * 12),
                      curve: Curves.easeOutCubic,
                      builder: (_, v, __) => Container(
                        height: 6 + 50 * v,
                        decoration: BoxDecoration(
                          color: hours[h] == 0
                              ? (t.name == 'dark'
                                  ? Colors.white.withValues(alpha: 0.07)
                                  : t.text.withValues(alpha: 0.06))
                              : (h == peak
                                  ? t.brand
                                  : t.brand.withValues(alpha: 0.45)),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text('0 点', style: text.bodySmall?.copyWith(fontSize: 11)),
            const Spacer(),
            Text(
              max == 0 ? '' : '最常在 $peak 点前后刷题',
              style: text.bodySmall?.copyWith(fontSize: 11, color: t.brand),
            ),
            const Spacer(),
            Text('23 点', style: text.bodySmall?.copyWith(fontSize: 11)),
          ],
        ),
      ],
    );
  }
}

class _Advice {
  const _Advice({
    required this.icon,
    required this.title,
    required this.body,
    this.actionable = false,
    this.actionLabel,
    this.onAct,
  });

  final AppIcon icon;
  final String title;
  final String body;
  final bool actionable;

  /// 每条建议带自己的出口，比统统跳「弱项强化」有用。
  final String? actionLabel;
  final Future<void> Function(BuildContext context)? onAct;
}

class _AdviceCard extends StatelessWidget {
  const _AdviceCard({required this.advice, this.onAct});

  final _Advice advice;
  final VoidCallback? onAct;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
        decoration: GlassDecor.panel(t, radius: 18, raised: false),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: StrokeIcon(advice.icon, size: 19, color: t.brand),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(advice.title, style: text.titleSmall?.copyWith(fontSize: 15)),
                  const SizedBox(height: 6),
                  Text(
                    advice.body,
                    style: text.bodyMedium?.copyWith(fontSize: 13.5, height: 1.6),
                  ),
                  if (onAct != null) ...[
                    const SizedBox(height: 10),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onAct,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            advice.actionLabel ?? '现在就练',
                            style: text.labelMedium?.copyWith(color: t.brand),
                          ),
                          Icon(Icons.chevron_right, size: 16, color: t.brand),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
