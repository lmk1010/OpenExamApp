import 'package:flutter/material.dart';
import 'package:openexam_app/core/constants/app_constants.dart';
import 'package:openexam_app/core/constants/categories.dart';
import 'package:openexam_app/core/theme/app_theme.dart';
import 'package:openexam_app/core/theme/app_tokens.dart';
import 'package:openexam_app/core/theme/theme_controller.dart';
import 'package:openexam_app/core/ui/ambient.dart';
import 'package:openexam_app/core/ui/glass.dart';
import 'package:openexam_app/core/ui/stroke_icons.dart';
import 'package:openexam_app/core/ui/ui_kit.dart';
import 'package:openexam_app/data/db/app_database.dart';
import 'package:openexam_app/data/models/question.dart';
import 'package:openexam_app/features/practice/practice_session_page.dart';
import 'package:openexam_app/features/search/search_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PracticeHomePage extends StatefulWidget {
  const PracticeHomePage({super.key});

  @override
  State<PracticeHomePage> createState() => _PracticeHomePageState();
}

class _PracticeHomePageState extends State<PracticeHomePage> {
  bool _loading = true;
  int _total = 0;
  int _wrong = 0;
  List<CategoryStat> _stats = const [];
  List<int> _week = const [0, 0, 0, 0, 0, 0, 0];
  int _count = 20;
  String _name = '备考中';
  DateTime? _examDate;
  int _goal = 30;
  ResumeState? _resume;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    if (!_loading) setState(() => _loading = true);
    final db = AppDatabase.instance;
    final total = await db.countAll();
    final stats = await db.categoryStats();
    final week = await db.dailyActivity();
    final wrong = await db.countWrong();
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt(Prefs.defaultCount) ?? _count;
    final name = prefs.getString(Prefs.nickname) ?? '备考中';
    final examRaw = prefs.getString(Prefs.examDate);
    final goal = prefs.getInt(Prefs.dailyGoal) ?? 30;
    final resume = await db.loadResume();
    if (!mounted) return;
    setState(() {
      _total = total;
      _stats = stats;
      _week = week;
      _wrong = wrong;
      _count = saved;
      _name = name;
      _goal = goal;
      _resume = resume;
      _examDate = examRaw == null ? null : DateTime.tryParse(examRaw);
      _loading = false;
    });
  }

  Future<void> _open(
    List<Question> questions, {
    Duration? limit,
    String? title,
  }) async {
    if (!mounted) return;
    if (questions.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('这里还没有题')));
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PracticeSessionPage(
          questions: questions,
          limit: limit,
          title: title,
        ),
      ),
    );
    _reload();
  }

  Future<void> _start({String? category, int? limit}) async {
    await _open(
      await AppDatabase.instance.fetchPractice(
        category: category,
        limit: limit ?? _count,
        shuffle: true,
      ),
    );
  }

  /// Mock exam: fixed set, countdown, answers hidden until 交卷.
  Future<void> _startMock() async {
    final questions = await AppDatabase.instance.fetchPractice(
      limit: 50,
      shuffle: true,
    );
    await _open(questions, limit: const Duration(minutes: 45), title: '限时模考');
  }

  /// Weakness-weighted set — the app decides the mix so the user doesn't have
  /// to guess which module needs work.
  Future<void> _startAdaptive() async {
    final questions = await AppDatabase.instance.fetchAdaptive(limit: _count);
    await _open(questions, title: '弱项强化');
  }

  Future<void> _startWrong() async {
    await _open(await AppDatabase.instance.fetchWrong(limit: _count));
  }

  /// Daily volume target — the thing that turns "有空就刷" into a habit.
  Future<void> _pickGoal() async {
    final picked = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _GoalSheet(current: _goal),
    );
    if (picked == null || !mounted) return;
    setState(() => _goal = picked);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(Prefs.dailyGoal, picked);
  }

  /// Picks an interrupted session back up where it stopped.
  Future<void> _continueResume() async {
    final state = _resume;
    if (state == null) return;
    final questions = await AppDatabase.instance.fetchByIds(state.questionIds);
    if (questions.isEmpty) {
      await AppDatabase.instance.clearResume();
      _reload();
      return;
    }
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PracticeSessionPage(
          questions: questions,
          title: state.title,
          limit: state.limit,
          startAt: state.index.clamp(0, questions.length - 1),
          resumeAnswers: state.answers,
          resumeElapsed: state.elapsed,
        ),
      ),
    );
    _reload();
  }

  Future<void> _dismissResume() async {
    await AppDatabase.instance.clearResume();
    if (mounted) setState(() => _resume = null);
  }

  Future<void> _pickCount() async {
    final picked = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _CountSheet(current: _count),
    );
    if (picked == null || !mounted) return;
    setState(() => _count = picked);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(Prefs.defaultCount, picked);
  }

  /// Consecutive days answered, counting back from today.
  int get _streak {
    var n = 0;
    for (var i = _week.length - 1; i >= 0; i--) {
      if (_week[i] == 0) break;
      n++;
    }
    return n;
  }

  int get _done => _stats.fold(0, (sum, s) => sum + s.done);
  int get _correct => _stats.fold(0, (sum, s) => sum + s.correct);

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingState();

    final t = context.tokens;
    final byKey = {for (final s in _stats) s.category: s};
    final rate = _done == 0 ? 0 : (_correct * 100 / _done).round();

    return RefreshIndicator(
      color: t.brand,
      backgroundColor: t.surface,
      onRefresh: _reload,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          _TopBar(total: _total),
          _Hero(
            name: _name,
            examDate: _examDate,
            total: _total,
            today: _week.last,
            goal: _goal,
            rate: rate,
            streak: _streak,
            onTapGoal: _pickGoal,
          ),
          const SizedBox(height: 18),
          if (_resume != null && _resume!.remaining > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.gutter,
                0,
                AppTheme.gutter,
                18,
              ),
              child: _ResumeBanner(
                state: _resume!,
                onContinue: _continueResume,
                onDismiss: _dismissResume,
              ),
            ),
          // Feature carousel — each card is a one-tap entry, image-led.
          SizedBox(
            height: 138,
            child: ShaderMask(
              // Fades the right edge so it's obvious the row keeps going.
              shaderCallback: (rect) => LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: const [Colors.black, Colors.black, Colors.transparent],
                stops: const [0, 0.9, 1],
              ).createShader(rect),
              blendMode: BlendMode.dstIn,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.gutter,
                ),
                children: [
                  _FeatureCard(
                    title: '每日一练',
                    meta: '$_count 题 · 随机抽题',
                    glyph: AppIcon.shuffle,
                    colors: [t.brand],
                    onTap: () => _start(),
                  ),
                  const SizedBox(width: 11),
                  _FeatureCard(
                    title: '弱项强化',
                    meta: _done < 20 ? '先练一组再解锁' : '按薄弱模块配比',
                    glyph: AppIcon.chart,
                    colors: [t.category('panduan')],
                    onTap: _done < 20 ? null : _startAdaptive,
                  ),
                  const SizedBox(width: 11),
                  _FeatureCard(
                    title: '错题重练',
                    meta: _wrong == 0 ? '暂无错题' : '$_wrong 题待清',
                    glyph: AppIcon.replay,
                    colors: [t.category('changshi')],
                    onTap: _wrong == 0 ? null : _startWrong,
                  ),
                  const SizedBox(width: 11),
                  _FeatureCard(
                    title: '限时模考',
                    meta: '50 题 · 45 分钟',
                    glyph: AppIcon.timer,
                    colors: [t.category('ziliao')],
                    onTap: _startMock,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 26),
          _ListHeader(
            title: '按题型练习',
            trailing: '$_count 题',
            onTapTrailing: _pickCount,
          ),
          for (final c in kGongkaoCategories)
            _TypeRow(
              meta: c,
              stat: byKey[c.key],
              onTap: () => _start(category: c.key),
            ),
          const SizedBox(height: 26),
          _ListHeader(
            title: '近 7 天',
            trailing: _done == 0 ? null : '正确率 $rate%',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.gutter),
            child: WeekBars(counts: _week),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.gutter,
        12,
        AppTheme.gutter - 8,
        0,
      ),
      child: Row(
        children: [
          const BrandLogo(size: 26),
          const SizedBox(width: 9),
          Text(
            'OpenExam',
            style: text.titleMedium?.copyWith(
              fontSize: 16.5,
              letterSpacing: -0.4,
            ),
          ),
          const Spacer(),
          PlainIconButton(
            icon: Icons.search,
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SearchPage())),
          ),
          PlainIconButton(
            icon: ThemeController.instance.icon,
            onTap: () => ThemeController.instance.cycle(),
          ),
          PlainIconButton(
            icon: Icons.info_outline,
            onTap: () => showModalBottomSheet<void>(
              context: context,
              backgroundColor: Colors.transparent,
              builder: (_) => const _AboutSheet(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Header that carries real weight: greeting, exam countdown, and 米家-style
/// tonal status tiles over the coloured backdrop.
class _Hero extends StatelessWidget {
  const _Hero({
    required this.name,
    required this.examDate,
    required this.total,
    required this.today,
    required this.goal,
    required this.rate,
    required this.streak,
    required this.onTapGoal,
  });

  final String name;
  final DateTime? examDate;
  final int total;
  final int today;
  final int goal;
  final int rate;
  final int streak;
  final VoidCallback onTapGoal;

  int? get _daysLeft {
    if (examDate == null) return null;
    final now = DateTime.now();
    return examDate!.difference(DateTime(now.year, now.month, now.day)).inDays;
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 6) return '夜深了';
    if (h < 11) return '早上好';
    if (h < 14) return '中午好';
    if (h < 18) return '下午好';
    return '晚上好';
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final days = _daysLeft;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.gutter,
        10,
        AppTheme.gutter,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$_greeting，$name',
                      style: text.bodySmall?.copyWith(fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      today >= goal
                          ? '今日目标已完成'
                          : (today == 0 ? '今天还没开练' : '今天已练 $today 题'),
                      style: text.displaySmall?.copyWith(
                        fontSize: 27,
                        letterSpacing: -1,
                      ),
                    ),
                  ],
                ),
              ),
              if (days != null && days >= 0)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '$days',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            height: 1,
                            letterSpacing: -1,
                            color: t.brand,
                            fontFeatures: AppTheme.numeric,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '天',
                          style: text.bodySmall?.copyWith(color: t.brand),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '距考试',
                      style: text.bodySmall?.copyWith(fontSize: 11.5),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _StatusTile(
                progress: goal == 0 ? 0 : today / goal,
                done: today >= goal,
                value: '$today/$goal',
                label: '今日目标',
                onTap: onTapGoal,
              ),
              const SizedBox(width: 10),
              _StatusTile(
                icon: AppIcon.chart,
                value: rate == 0 ? '—' : '$rate%',
                label: '正确率',
              ),
              const SizedBox(width: 10),
              _StatusTile(
                icon: AppIcon.timer,
                value: '$streak 天',
                label: '连续打卡',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Offer to pick up an interrupted session — losing half a 130-question paper
/// to a phone call is the kind of thing that makes people quit an app.
class _ResumeBanner extends StatelessWidget {
  const _ResumeBanner({
    required this.state,
    required this.onContinue,
    required this.onDismiss,
  });

  final ResumeState state;
  final VoidCallback onContinue;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onContinue,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        decoration: GlassDecor.panel(t, radius: 18),
        child: Row(
          children: [
            StrokeIcon(AppIcon.replay, size: 20, color: t.brand),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '继续 ${state.title}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleSmall?.copyWith(fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '还剩 ${state.remaining} 题'
                    '${state.isExam ? ' · 模考计时会接着走' : ''}',
                    style: text.bodySmall,
                  ),
                ],
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onDismiss,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(Icons.close, size: 17, color: t.muted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One status tile. Goal, accuracy and streak all use the same vertical
/// stack — the goal tile used to put its ring beside the number, which left
/// about 30dp for "12/30" and looked squashed.
class _StatusTile extends StatelessWidget {
  const _StatusTile({
    required this.value,
    required this.label,
    this.icon,
    this.progress,
    this.done = false,
    this.onTap,
  });

  final String value;
  final String label;

  /// Either a glyph or a progress ring sits at the top of the tile.
  final AppIcon? icon;
  final double? progress;
  final bool done;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 13, 12, 14),
          decoration: BoxDecoration(
            color: t.chip,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 26,
                child: progress == null
                    ? StrokeIcon(
                        icon!,
                        size: 17,
                        color: t.onChip.withValues(alpha: 0.85),
                      )
                    : SizedBox(
                        width: 26,
                        height: 26,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            TweenAnimationBuilder<double>(
                              tween: Tween(
                                begin: 0,
                                end: progress!.clamp(0.0, 1.0),
                              ),
                              duration: const Duration(milliseconds: 600),
                              curve: Curves.easeOutCubic,
                              builder: (_, v, __) => SizedBox(
                                width: 26,
                                height: 26,
                                child: CircularProgressIndicator(
                                  value: v == 0 ? 0.02 : v,
                                  strokeWidth: 2.6,
                                  strokeCap: StrokeCap.round,
                                  color: t.onChip,
                                  backgroundColor: t.onChip.withValues(
                                    alpha: 0.24,
                                  ),
                                ),
                              ),
                            ),
                            if (done)
                              Icon(
                                Icons.check_rounded,
                                size: 13,
                                color: t.onChip,
                              ),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: 12),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    height: 1,
                    letterSpacing: -0.4,
                    color: t.onChip,
                    fontFeatures: AppTheme.numeric,
                  ),
                ),
              ),
              const SizedBox(height: 7),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  height: 1,
                  color: t.onChip.withValues(alpha: 0.72),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Flat colour block with a headline/// Flat colour block with a headline, one line of meta and a play affordance —
/// the QQ音乐 entry-card pattern. No watermark art, no gradients fighting the text.
class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.title,
    required this.meta,
    required this.glyph,
    required this.colors,
    required this.onTap,
  });

  final String title;
  final String meta;
  final AppIcon glyph;
  final List<Color> colors;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    final base = colors.first;
    final on = GlassDecor.on(base);

    return Opacity(
      opacity: disabled ? 0.4 : 1,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 186,
          padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
          decoration: BoxDecoration(
            color: base,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StrokeIcon(glyph, size: 22, color: on.withValues(alpha: 0.9)),
              const Spacer(),
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  height: 1.1,
                  color: on,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.3,
                        color: on.withValues(alpha: 0.82),
                        fontFeatures: AppTheme.numeric,
                      ),
                    ),
                  ),
                  Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: on,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.play_arrow_rounded,
                      size: 19,
                      color: base,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ListHeader extends StatelessWidget {
  const _ListHeader({required this.title, this.trailing, this.onTapTrailing});

  final String title;
  final String? trailing;
  final VoidCallback? onTapTrailing;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.gutter,
        0,
        AppTheme.gutter,
        8,
      ),
      child: Row(
        children: [
          Text(title, style: text.titleMedium?.copyWith(fontSize: 17)),
          const Spacer(),
          if (trailing != null)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTapTrailing,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Text(
                      trailing!,
                      style: text.labelMedium?.copyWith(
                        color: onTapTrailing == null ? t.muted : t.brand,
                        fontFeatures: AppTheme.numeric,
                      ),
                    ),
                    if (onTapTrailing != null)
                      Icon(Icons.expand_more, size: 16, color: t.brand),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// One line per 题型: glyph, name, inline meter, percentage. Nothing wraps.
class _TypeRow extends StatelessWidget {
  const _TypeRow({required this.meta, required this.stat, required this.onTap});

  final CategoryMeta meta;
  final CategoryStat? stat;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final color = t.category(meta.key);
    final total = stat?.total ?? 0;
    final done = stat?.done ?? 0;
    final started = done > 0;
    // Accuracy, not completion: "4126 题做了 5 道 = 0.1%" reads like a score
    // and isn't one.
    final accuracy = stat == null ? 0 : (stat!.accuracy * 100).round();

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.gutter,
          vertical: 15,
        ),
        child: Row(
          children: [
            StrokeIcon(meta.icon, size: 21, color: color),
            const SizedBox(width: 14),
            SizedBox(
              width: 76,
              child: Text(
                meta.label,
                style: text.titleSmall?.copyWith(fontSize: 15.5),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Meter(
                value: total == 0 ? 0 : done / total,
                color: color,
                height: 4,
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 66,
              child: Text(
                started ? '$done/$total' : '$total 题',
                textAlign: TextAlign.right,
                style: text.bodySmall,
              ),
            ),
            SizedBox(
              width: 44,
              child: Text(
                started ? '$accuracy%' : '',
                textAlign: TextAlign.right,
                style: text.labelMedium?.copyWith(
                  color: color,
                  fontFeatures: AppTheme.numeric,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalSheet extends StatelessWidget {
  const _GoalSheet({required this.current});

  final int current;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        color: t.gradient.last,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: t.glassBorder)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('每日目标', style: text.titleMedium),
            const SizedBox(height: 6),
            Text('在职备考建议 20–30 题，全职冲刺 60 题以上', style: text.bodySmall),
            const SizedBox(height: 6),
            for (final n in const [10, 20, 30, 50, 80, 100])
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(context).pop(n),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    children: [
                      Text(
                        '$n 题',
                        style: text.titleSmall?.copyWith(
                          color: n == current ? t.brand : t.text,
                          fontFeatures: AppTheme.numeric,
                        ),
                      ),
                      const Spacer(),
                      if (n == current)
                        Icon(Icons.check, size: 19, color: t.brand),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CountSheet extends StatelessWidget {
  const _CountSheet({required this.current});

  final int current;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    return Container(
      decoration: GlassDecor.panel(t, radius: 28).copyWith(
        color: t.gradient.last,
        gradient: null,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('每组题量', style: text.titleMedium),
            const SizedBox(height: 6),
            for (final n in const [10, 20, 30, 50])
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(context).pop(n),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  child: Row(
                    children: [
                      Text(
                        '$n 题',
                        style: text.titleSmall?.copyWith(
                          color: n == current ? t.brand : t.text,
                          fontFeatures: AppTheme.numeric,
                        ),
                      ),
                      const Spacer(),
                      if (n == current)
                        Icon(Icons.check, size: 19, color: t.brand),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AboutSheet extends StatelessWidget {
  const _AboutSheet();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    return Container(
      decoration: GlassDecor.panel(t, radius: 28).copyWith(
        color: t.gradient.last,
        gradient: null,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 26),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const BrandLogo(size: 32),
                const SizedBox(width: 10),
                Text('OpenExam', style: text.titleMedium),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              '本地优先的公务员行测刷题工具。题库、答题记录、统计全部保存在这台设备上，'
              '不联网、不上传。内置题来自 OpenExam 桌面端种子库，也可以在「导入」页导入自己的题目。',
              style: text.bodyMedium,
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('知道了'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
