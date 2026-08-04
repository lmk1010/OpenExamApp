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
import 'package:openexam_app/features/shell/app_shell.dart';
import 'package:openexam_app/features/profile/dashboard_page.dart';
import 'package:openexam_app/features/search/search_page.dart';
import 'package:openexam_app/features/stats/stats_page.dart';
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
  QuestionScope _scope = QuestionScope.all;
  String _name = '备考中';
  DateTime? _examDate;
  int _goal = 30;
  ResumeState? _resume;
  String? _province;
  List<Question> _daily = const [];
  ({int answered, int correct}) _dailyProgress = (answered: 0, correct: 0);
  int _provinceCount = 0;
  int _hardCount = 0;
  List<ReviewPlan> _plans = const [];
  Map<String, ({int total, int correct})> _checkins = const {};
  int _checkinStreak = 0;

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
    final daily = await db.fetchDailySet(day: DateTime.now(), limit: 20);
    final dailyProgress =
        await db.dailyProgress(daily.map((q) => q.id).toList());
    final province = prefs.getString(Prefs.province);
    final provinceCount =
        province == null ? 0 : await db.countByRegion(province);
    final hardCount = (await db.difficultyCounts())[3] ?? 0;
    final plans = await db.reviewPlans();
    final checkins = await db.dailyCheckins(days: 14);
    final streak = await db.dailyStreak();
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
      _province = province;
      _daily = daily;
      _dailyProgress = dailyProgress;
      _provinceCount = provinceCount;
      _hardCount = hardCount;
      _plans = plans.where((p) => !p.finished).toList();
      _checkins = checkins;
      _checkinStreak = streak;
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
    final questions = await AppDatabase.instance.fetchPractice(
      category: category,
      limit: limit ?? _count,
      shuffle: true,
      scope: _scope,
    );
    if (questions.isEmpty && _scope != QuestionScope.all) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _scope == QuestionScope.unseen ? '这个范围里没有没做过的题了' : '这里还没有错题',
          ),
        ),
      );
      return;
    }
    await _open(questions);
  }

  /// 背题：不作答，直接翻答案和解析，用来快速过一遍。
  Future<void> _startRecite({String? category}) async {
    final questions = await AppDatabase.instance.fetchPractice(
      category: category,
      limit: _count,
      shuffle: false,
      scope: _scope,
    );
    if (!mounted || questions.isEmpty) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PracticeSessionPage(
          questions: questions,
          reviewAnswers: {
            for (final q in questions) q.id: q.answer.toUpperCase(),
          },
          title: '背题',
        ),
      ),
    );
    _reload();
  }

  Future<void> _startHard() async {
    final questions = await AppDatabase.instance.fetchByDifficulty(3, limit: 30);
    await _open(questions, title: '标难的题');
  }

  /// 单模块限时练 — same question count as normal practice, but on the pace a
  /// real 行测 leaves you: seconds per question differ a lot by module.
  static const _paceSeconds = <String, int>{
    'yanyu': 55,
    'shuliang': 75,
    'panduan': 50,
    'ziliao': 70,
    'changshi': 20,
  };

  Future<void> _startTimed(String category) async {
    final questions = await AppDatabase.instance.fetchPractice(
      category: category,
      limit: _count,
      shuffle: true,
      scope: _scope,
    );
    if (questions.isEmpty) return;
    final per = _paceSeconds[category] ?? 60;
    await _open(
      questions,
      limit: Duration(seconds: per * questions.length),
      title: '${categoryLabel(category)}限时练',
    );
  }

  /// Long-pressing a module opens the three ways to run it, instead of
  /// silently starting 背题 like it used to.
  Future<void> _moduleMenu(String category) async {
    final per = _paceSeconds[category] ?? 60;
    final minutes = (per * _count / 60).round();
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ModuleSheet(
        category: category,
        count: _count,
        minutes: minutes,
      ),
    );
    if (picked == null || !mounted) return;
    switch (picked) {
      case 'practice':
        await _start(category: category);
      case 'timed':
        await _startTimed(category);
      case 'recite':
        await _startRecite(category: category);
    }
  }

  Future<void> _pickScope() async {
    final counts = await AppDatabase.instance.scopeCounts();
    if (!mounted) return;
    final picked = await showModalBottomSheet<QuestionScope>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ScopeSheet(current: _scope, counts: counts),
    );
    if (picked != null && mounted) setState(() => _scope = picked);
  }

  /// Mock exam: fixed set, countdown, answers hidden until 交卷.
  Future<void> _startMock() async {
    final questions = await AppDatabase.instance.fetchPractice(
      limit: 50,
      shuffle: true,
    );
    await _open(questions, limit: const Duration(minutes: 45), title: '限时模考');
  }

  /// Today's fixed set. Finished sets reopen in review mode rather than being
  /// re-answered, so the number on the card stays honest.
  Future<void> _startDaily() async {
    if (_daily.isEmpty) {
      await _start();
      return;
    }
    final done = _dailyProgress.answered >= _daily.length;
    if (done) {
      final answers = <String, String>{};
      for (final q in _daily) {
        final history = await AppDatabase.instance.historyFor(q.id, limit: 1);
        if (history.isNotEmpty) answers[q.id] = history.first.answer;
      }
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PracticeSessionPage(
            questions: _daily,
            reviewAnswers: answers,
            title: '今日一练回顾',
          ),
        ),
      );
      _reload();
      return;
    }
    await _open(_daily, title: '每日一练');
    await _checkDailyDone(DateTime.now(), _daily);
  }

  /// 做完当天的固定卷就记一次打卡。用记录而不是每次重算，是因为算一天的
  /// 题目集合是一次全表排序，画打卡条时重算 7 次太亏。
  Future<void> _checkDailyDone(DateTime day, List<Question> set) async {
    if (set.isEmpty) return;
    final progress =
        await AppDatabase.instance.dailyProgress(set.map((q) => q.id).toList());
    if (progress.answered < set.length) return;
    await AppDatabase.instance
        .markDailyDone(day, set.length, progress.correct);
    await _reload();
  }

  /// 补做某天的固定卷。断了的那天补回来，比"从今天重新开始"更留得住人。
  Future<void> _makeUp(DateTime day) async {
    final set = await AppDatabase.instance.fetchDailySet(day: day, limit: 20);
    if (set.isEmpty) return;
    await _open(set, title: '补做 ${day.month}/${day.day}');
    await _checkDailyDone(day, set);
  }

  /// Weakness-weighted set — the app decides the mix so the user doesn't have
  /// to guess which module needs work.
  Future<void> _startAdaptive() async {
    final questions = await AppDatabase.instance.fetchAdaptive(limit: _count);
    await _open(questions, title: '弱项强化');
  }

  /// Questions drawn only from the province the user is sitting for.
  Future<void> _startRegion() async {
    final region = _province;
    if (region == null) return;
    final questions =
        await AppDatabase.instance.fetchByRegion(region, limit: _count);
    await _open(questions, title: '$region真题');
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
            onTapRate: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const StatsPage()),
            ),
            onTapStreak: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const DashboardPage()),
            ),
          ),
          const SizedBox(height: 18),
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
                  // 中断的那组排在第一张：它是最该继续的一件事，但不值得
                  // 单独占一整行。长按可以放弃。
                  if (_resume != null && _resume!.remaining > 0) ...[
                    _FeatureCard(
                      title: '继续上次',
                      meta: '${_resume!.title} · 还剩 ${_resume!.remaining} 题',
                      glyph: AppIcon.replay,
                      colors: [t.category('shuliang')],
                      onTap: _continueResume,
                      onLong: _dismissResume,
                    ),
                    const SizedBox(width: 11),
                  ],
                  _FeatureCard(
                    title: '每日一练',
                    meta: _dailyProgress.answered >= _daily.length && _daily.isNotEmpty
                        ? '今天做完了 · 正确 ${_dailyProgress.correct}/${_daily.length}'
                        : (_dailyProgress.answered > 0
                            ? '继续 · ${_dailyProgress.answered}/${_daily.length}'
                            : '${_daily.length} 题 · 今天的固定卷'),
                    glyph: AppIcon.shuffle,
                    colors: [t.brand],
                    onTap: _startDaily,
                  ),
                  const SizedBox(width: 11),
                  if (_province != null && _provinceCount > 0) ...[
                    _FeatureCard(
                      title: '$_province真题',
                      meta: '$_provinceCount 题 · 你要考的卷',
                      glyph: AppIcon.papers,
                      colors: [t.category('yanyu')],
                      onTap: _startRegion,
                    ),
                    const SizedBox(width: 11),
                  ],
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
          // 有在跑的四天计划就提醒一句，否则开了计划也会忘。
          for (final plan in _plans)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.gutter,
                18,
                AppTheme.gutter,
                0,
              ),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => AppShell.jumpTo.value = 2,
                child: Row(
                  children: [
                    StrokeIcon(AppIcon.replay, size: 16, color: t.brand),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        plan.doneToday
                            ? '「${plan.label}」计划今天已完成，明天继续'
                            : '「${plan.label}」计划第 ${plan.nextDay} 天还没做 · '
                                '${ReviewPlan.stepTitles[plan.nextDay - 1]}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    Icon(Icons.chevron_right, size: 15, color: t.muted),
                  ],
                ),
              ),
            ),
          // 每日一练打卡条：断了的那天能点回去补做。
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.gutter,
              16,
              AppTheme.gutter,
              0,
            ),
            child: Row(
              children: [
                Text(
                  _checkinStreak > 0 ? '连续打卡 $_checkinStreak 天' : '每日一练打卡',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _checkinStreak > 0 ? t.brand : null,
                      ),
                ),
                const Spacer(),
                for (var i = 6; i >= 0; i--) ...[
                  if (i < 6) const SizedBox(width: 6),
                  Builder(builder: (context) {
                    final day = DateTime.now().subtract(Duration(days: i));
                    final key = AppDatabase.dayKey(day);
                    final mark = _checkins[key];
                    final isToday = i == 0;
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: mark != null
                          ? null
                          : (isToday ? _startDaily : () => _makeUp(day)),
                      child: Tooltip(
                        message: mark == null
                            ? (isToday ? '今天还没做' : '${day.month}/${day.day} 补做')
                            : '${day.month}/${day.day} 正确 ${mark.correct}/${mark.total}',
                        child: Container(
                          width: 20,
                          height: 20,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: mark != null
                                ? t.brand
                                : isToday
                                    ? t.brand.withValues(alpha: 0.18)
                                    : t.glass,
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: mark != null
                              ? Icon(
                                  Icons.check,
                                  size: 12,
                                  color: GlassDecor.on(t.brand),
                                )
                              : Text(
                                  '${day.day}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    height: 1,
                                    color: isToday ? t.brand : t.muted,
                                  ),
                                ),
                        ),
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
          const SizedBox(height: 26),
          _ListHeader(
            title: '按题型练习',
            trailing: '$_count 题 · ${_scopeLabel(_scope)}',
            onTapTrailing: _pickCount,
            onTapSecondary: _pickScope,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppTheme.gutter, 0, AppTheme.gutter, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '长按任意题型可以选限时练或背题',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                // 自己标过「难」的题，攒够了就该单独拉出来练。
                if (_hardCount > 0)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _startHard,
                    child: Text(
                      '标难的 $_hardCount 题 ›',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: t.brand),
                    ),
                  ),
              ],
            ),
          ),
          for (final c in kGongkaoCategories)
            _TypeRow(
              meta: c,
              stat: byKey[c.key],
              onTap: () => _start(category: c.key),
              onLong: () => _moduleMenu(c.key),
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
    required this.onTapRate,
    required this.onTapStreak,
  });

  final String name;
  final DateTime? examDate;
  final int total;
  final int today;
  final int goal;
  final int rate;
  final int streak;
  final VoidCallback onTapGoal;
  final VoidCallback onTapRate;
  final VoidCallback onTapStreak;

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
          const SizedBox(height: 14),
          // 三块指标以前各占一张卡，吃掉一整屏的三分之一。同样的信息压成
          // 一条：细进度条 + 一行数字，每段照样能点进去。
          _MetricStrip(
            today: today,
            goal: goal,
            rate: rate,
            streak: streak,
            onTapGoal: onTapGoal,
            onTapRate: onTapRate,
            onTapStreak: onTapStreak,
          ),
        ],
      ),
    );
  }
}

/// 首页指标条：一条 3dp 的今日进度 + 一行可点的数字。
class _MetricStrip extends StatelessWidget {
  const _MetricStrip({
    required this.today,
    required this.goal,
    required this.rate,
    required this.streak,
    required this.onTapGoal,
    required this.onTapRate,
    required this.onTapStreak,
  });

  final int today;
  final int goal;
  final int rate;
  final int streak;
  final VoidCallback onTapGoal;
  final VoidCallback onTapRate;
  final VoidCallback onTapStreak;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    Widget item(String value, String label, VoidCallback onTap) =>
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  height: 1,
                  color: t.text,
                  fontFeatures: AppTheme.numeric,
                ),
              ),
              const SizedBox(width: 4),
              Text(label, style: text.bodySmall?.copyWith(fontSize: 12)),
              Icon(Icons.chevron_right, size: 13, color: t.muted),
            ],
          ),
        );

    Widget dot() => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9),
          child: Container(
            width: 3,
            height: 3,
            decoration: BoxDecoration(
              color: t.muted.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Meter(
          value: goal == 0 ? 0 : (today / goal).clamp(0.0, 1.0),
          height: 3,
        ),
        const SizedBox(height: 11),
        Row(
          children: [
            item('$today/$goal', '目标', onTapGoal),
            dot(),
            item(rate == 0 ? '—' : '$rate%', '正确率', onTapRate),
            dot(),
            item('$streak 天', '连续', onTapStreak),
          ],
        ),
      ],
    );
  }
}

/// Offer to pick up an interrupted session — losing half a 130-question paper
class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.title,
    required this.meta,
    required this.glyph,
    required this.colors,
    required this.onTap,
    this.onLong,
  });

  final String title;
  final String meta;
  final AppIcon glyph;
  final List<Color> colors;
  final VoidCallback? onTap;
  final VoidCallback? onLong;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    final base = colors.first;
    final on = GlassDecor.on(base);

    return Opacity(
      opacity: disabled ? 0.4 : 1,
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLong,
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
  const _ListHeader({
    required this.title,
    this.trailing,
    this.onTapTrailing,
    this.onTapSecondary,
  });

  final String title;
  final String? trailing;
  final VoidCallback? onTapTrailing;

  /// Long-press opens the scope picker; the row is already crowded.
  final VoidCallback? onTapSecondary;

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
              onTap: onTapSecondary ?? onTapTrailing,
              onLongPress: onTapTrailing,
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
  const _TypeRow({
    required this.meta,
    required this.stat,
    required this.onTap,
    required this.onLong,
  });

  final CategoryMeta meta;
  final CategoryStat? stat;
  final VoidCallback onTap;

  /// Long-press starts 背题 for this module.
  final VoidCallback onLong;

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

String _scopeLabel(QuestionScope scope) => switch (scope) {
      QuestionScope.all => '全部题',
      QuestionScope.unseen => '没做过',
      QuestionScope.wrong => '做错过',
    };

/// Which slice of the bank to draw from.
class _ScopeSheet extends StatelessWidget {
  const _ScopeSheet({required this.current, required this.counts});

  final QuestionScope current;
  final Map<QuestionScope, int> counts;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    const items = [
      (scope: QuestionScope.all, label: '全部题', desc: '从整个题库里随机抽'),
      (scope: QuestionScope.unseen, label: '没做过的', desc: '跳过所有做过的题'),
      (scope: QuestionScope.wrong, label: '做错过的', desc: '只抽上次答错的题'),
    ];

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
            Text('抽题范围', style: text.titleMedium),
            const SizedBox(height: 6),
            Text('长按题量可以改每组题数', style: text.bodySmall),
            const SizedBox(height: 6),
            for (final item in items)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(context).pop(item.scope),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.label,
                              style: text.titleSmall?.copyWith(
                                color: item.scope == current ? t.brand : t.text,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(item.desc, style: text.bodySmall),
                          ],
                        ),
                      ),
                      Text('${counts[item.scope] ?? 0} 题', style: text.bodySmall),
                      const SizedBox(width: 10),
                      if (item.scope == current)
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

/// Sheet behind a long-press on a module row.
class _ModuleSheet extends StatelessWidget {
  const _ModuleSheet({
    required this.category,
    required this.count,
    required this.minutes,
  });

  final String category;
  final int count;
  final int minutes;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final color = t.category(category);
    final items = <({String key, String label, String desc, AppIcon icon})>[
      (
        key: 'practice',
        label: '直接练',
        desc: '$count 题，不计时',
        icon: AppIcon.practice,
      ),
      (
        key: 'timed',
        label: '限时练',
        desc: '$count 题 · 约 $minutes 分钟，按考场节奏',
        icon: AppIcon.timer,
      ),
      (
        key: 'recite',
        label: '背题',
        desc: '不作答，直接看答案和解析',
        icon: AppIcon.papers,
      ),
    ];

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(10),
        padding: const EdgeInsets.fromLTRB(6, 18, 6, 8),
        decoration: GlassDecor.panel(t, radius: 26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Row(
                children: [
                  StrokeIcon(categoryIcon(category), size: 20, color: color),
                  const SizedBox(width: 10),
                  Text(
                    categoryLabel(category),
                    style: text.titleSmall?.copyWith(fontSize: 16),
                  ),
                ],
              ),
            ),
            for (final it in items)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(context).pop(it.key),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 13,
                  ),
                  child: Row(
                    children: [
                      StrokeIcon(it.icon, size: 19, color: color),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              it.label,
                              style: text.titleSmall?.copyWith(fontSize: 15),
                            ),
                            const SizedBox(height: 3),
                            Text(it.desc, style: text.bodySmall),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, size: 16, color: t.muted),
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
