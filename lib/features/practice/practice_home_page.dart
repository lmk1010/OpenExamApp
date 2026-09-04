import 'package:flutter/material.dart';
import 'package:openexam_app/core/constants/app_constants.dart';
import 'package:openexam_app/core/constants/categories.dart';
import 'package:openexam_app/core/theme/app_theme.dart';
import 'package:openexam_app/core/theme/app_tokens.dart';
import 'package:openexam_app/core/ui/responsive.dart';
import 'package:openexam_app/core/theme/theme_controller.dart';
import 'package:openexam_app/core/ui/ambient.dart';
import 'package:openexam_app/core/ui/glass.dart';
import 'package:openexam_app/core/ui/stroke_icons.dart';
import 'package:openexam_app/core/ui/ui_kit.dart';
import 'package:openexam_app/data/db/app_database.dart';
import 'package:openexam_app/data/models/question.dart';
import 'package:openexam_app/features/plan/data/study_plan_store.dart';
import 'package:openexam_app/features/plan/domain/models/study_task.dart';
import 'package:openexam_app/features/plan/presentation/pages/study_plan_page.dart';
import 'package:openexam_app/features/plan/presentation/widgets/study_task_editor_sheet.dart';
import 'package:openexam_app/features/plan/presentation/widgets/today_plan_section.dart';
import 'package:openexam_app/features/practice/practice_session_page.dart';
import 'package:openexam_app/features/essay/presentation/essay_page.dart';
import 'package:openexam_app/features/shell/app_shell.dart';
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
  QuestionScope _scope = QuestionScope.all;
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
  StudyPlanStore? _studyPlanStore;
  DayPlan? _todayPlan;
  Set<String> _todayPlanDone = const {};

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    // 首屏才全屏 Loading；之后静默刷新，避免整页闪动画。
    //
    // 这里原来是十六个 await 排成一队，每个都是一次 sqflite 平台通道往返，
    // 首页要等它们一个接一个跑完才出得来。彼此不依赖的查询并发发出去，
    // 总耗时就从"全部相加"变成"最慢的那个"。
    final db = AppDatabase.instance;
    final prefs = await SharedPreferences.getInstance();
    final province = prefs.getString(Prefs.province);

    final results = await Future.wait([
      db.countAll(),
      db.categoryStats(),
      db.dailyActivity(),
      db.countWrong(),
      db.loadResume(),
      province == null ? Future.value(0) : db.countByRegion(province),
      db.difficultyCounts(),
      db.reviewPlans(),
      db.dailyCheckins(days: 14),
      db.dailyStreak(),
      _studyPlanStore == null
          ? StudyPlanStore.create()
          : Future.value(_studyPlanStore!),
    ]);

    final total = results[0] as int;
    final stats = results[1] as List<CategoryStat>;
    final week = results[2] as List<int>;
    final wrong = results[3] as int;
    final resume = results[4] as ResumeState?;
    final provinceCount = results[5] as int;
    final hardCount = (results[6] as Map<int, int>)[3] ?? 0;
    final plans = results[7] as List<ReviewPlan>;
    final checkins = results[8] as Map<String, ({int total, int correct})>;
    final streak = results[9] as int;
    final studyStore = results[10] as StudyPlanStore;

    final saved = prefs.getInt(Prefs.defaultCount) ?? _count;
    final examRaw = prefs.getString(Prefs.examDate);
    final goal = prefs.getInt(Prefs.dailyGoal) ?? 30;
    final todayPlan =
        studyStore.isEnabled ? studyStore.planFor(DateTime.now()) : null;
    final todayPlanDone = todayPlan == null
        ? <String>{}
        : studyStore.loadDoneIds(todayPlan.dateKey);

    if (!mounted) return;
    setState(() {
      _total = total;
      _stats = stats;
      _week = week;
      _wrong = wrong;
      _count = saved;
      _goal = goal;
      _resume = resume;
      _province = province;
      _provinceCount = provinceCount;
      _hardCount = hardCount;
      _plans = plans.where((p) => !p.finished).toList();
      _checkins = checkins;
      _checkinStreak = streak;
      _examDate = examRaw == null ? null : DateTime.tryParse(examRaw);
      _studyPlanStore = studyStore;
      _todayPlan = todayPlan;
      _todayPlanDone = todayPlanDone;
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

  Future<void> _start({
    String? category,
    String? subCategory,
    int? limit,
    String? title,
  }) async {
    final questions = await AppDatabase.instance.fetchPractice(
      category: category,
      subCategory: subCategory,
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
    await _open(
      questions,
      title: title ??
          (subCategory != null
              ? subCategoryLabel(subCategory)
              : (category != null ? categoryLabel(category) : null)),
    );
  }

  /// 背题：不作答，直接翻答案和解析，用来快速过一遍。
  Future<void> _startRecite({String? category, String? subCategory}) async {
    final questions = await AppDatabase.instance.fetchPractice(
      category: category,
      subCategory: subCategory,
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
          title: subCategory != null
              ? '${subCategoryLabel(subCategory)} · 背题'
              : '背题',
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

  Future<void> _startTimed(
    String category, {
    String? subCategory,
    int? limit,
    int? minutes,
  }) async {
    final questions = await AppDatabase.instance.fetchPractice(
      category: category,
      subCategory: subCategory,
      limit: limit ?? _count,
      shuffle: true,
      scope: _scope,
    );
    if (questions.isEmpty) return;
    final duration = minutes != null
        ? Duration(minutes: minutes)
        : Duration(seconds: (_paceSeconds[category] ?? 60) * questions.length);
    await _open(
      questions,
      limit: duration,
      title: subCategory != null
          ? '${subCategoryLabel(subCategory)} · 限时'
          : '${categoryLabel(category)}限时练',
    );
  }

  Future<void> _toggleStudyTask(StudyTask task, bool done) async {
    final store = _studyPlanStore;
    final plan = _todayPlan;
    if (store == null || plan == null) return;
    await store.toggleDone(plan.dateKey, task.id, done);
    if (!mounted) return;
    setState(() {
      final next = {..._todayPlanDone};
      if (done) {
        next.add(task.id);
      } else {
        next.remove(task.id);
      }
      _todayPlanDone = next;
    });
  }

  Future<void> _runStudyTask(StudyTask task) async {
    switch (task.action) {
      case StudyAction.note:
        // 申论类任务现在有真正的去处：录题、作答、AI 批改
        if (task.title.contains('申论')) {
          await Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const EssayPage()));
          if (mounted) _reload();
          return;
        }
        await _toggleStudyTask(task, !_todayPlanDone.contains(task.id));
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('手写任务勾选即可，做完别忘了打勾')),
        );
        return;
      case StudyAction.openWrongBook:
        AppShell.jumpTo.value = AppShell.wrongBookTab;
        return;
      case StudyAction.practice:
        final category = task.category;
        if (category == null) return;
        if (task.timed || task.minutes != null) {
          await _startTimed(
            category,
            limit: task.count,
            minutes: task.minutes,
          );
        } else {
          await _start(category: category, limit: task.count);
        }
        break;
      case StudyAction.daily:
        await _startDaily();
        break;
      case StudyAction.mock:
        await _startMock();
        break;
      case StudyAction.wrong:
        await _open(
          await AppDatabase.instance.fetchWrong(limit: task.count ?? _count),
          title: '错题重练',
        );
        break;
      case StudyAction.adaptive:
        await _open(
          await AppDatabase.instance.fetchAdaptive(limit: task.count ?? _count),
          title: '弱项强化',
        );
        break;
    }

    // Session starters already reload stats; also tick this checklist item.
    final store = _studyPlanStore;
    final plan = _todayPlan;
    if (store != null && plan != null) {
      await store.toggleDone(plan.dateKey, task.id, true);
    }
    await _reload();
  }

  Future<void> _openStudyPlan() async {
    final planTab = AppShell.planTab;
    if (planTab != null) {
      AppShell.jumpTo.value = planTab;
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StudyPlanPage(onRunTask: _runStudyTask),
      ),
    );
    await _reload();
  }

  Future<void> _openStudyTask(StudyTask task) async {
    final store = _studyPlanStore;
    final plan = _todayPlan;
    if (store == null || plan == null) return;
    final result = await showStudyTaskEditor(context, initial: task);
    if (result == null) return;
    if (result.delete) {
      await store.deleteTask(plan.date, task);
      await _reload();
      return;
    }
    if (result.task != null) {
      await store.upsertTask(plan.date, result.task!);
      await _reload();
    }
  }

  Future<void> _renameStudyTask(StudyTask task) async {
    final store = _studyPlanStore;
    final plan = _todayPlan;
    if (store == null || plan == null) return;
    final name = await showRenameTaskDialog(context, initial: task.title);
    if (name == null || name.isEmpty) return;
    await store.renameTask(plan.date, task, name);
    await _reload();
  }

  Future<void> _deleteStudyTask(StudyTask task) async {
    final store = _studyPlanStore;
    final plan = _todayPlan;
    if (store == null || plan == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除安排'),
        content: Text('确定删除「${task.title}」？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await store.deleteTask(plan.date, task);
    await _reload();
  }

  Future<void> _longPressStudyTask(StudyTask task) async {
    await showStudyTaskActions(
      context,
      task: task,
      onEdit: () => _openStudyTask(task),
      onRename: () => _renameStudyTask(task),
      onDelete: () => _deleteStudyTask(task),
    );
  }

  List<Widget> _featureCards(AppTokens t) {
    return [
      if (_resume != null && _resume!.remaining > 0)
        _FeatureCard(
          title: '继续上次',
          meta: '${_resume!.title} · 还剩 ${_resume!.remaining} 题',
          glyph: AppIcon.replay,
          colors: [t.category('shuliang')],
          onTap: _continueResume,
          onLong: _dismissResume,
        ),
      _FeatureCard(
        title: '每日一练',
        meta: '今天的固定卷',
        glyph: AppIcon.shuffle,
        colors: [t.brand],
        onTap: _startDaily,
      ),
      if (_province != null && _provinceCount > 0)
        _FeatureCard(
          title: '$_province真题',
          meta: '$_provinceCount 题 · 你要考的卷',
          glyph: AppIcon.papers,
          colors: [t.category('yanyu')],
          onTap: _startRegion,
        ),
      _FeatureCard(
        title: '弱项强化',
        meta: _done < 20 ? '先练一组再解锁' : '按薄弱模块配比',
        glyph: AppIcon.chart,
        colors: [t.category('panduan')],
        onTap: _done < 20 ? null : _startAdaptive,
      ),
      _FeatureCard(
        title: '错题重练',
        meta: _wrong == 0 ? '暂无错题' : '$_wrong 题待清',
        glyph: AppIcon.replay,
        colors: [t.category('changshi')],
        onTap: _wrong == 0 ? null : _startWrong,
      ),
      _FeatureCard(
        title: '限时模考',
        meta: '50 题 · 45 分钟',
        glyph: AppIcon.timer,
        colors: [t.category('ziliao')],
        onTap: _startMock,
      ),
    ];
  }

  /// 次要练法收进抽屉。这些入口都是「偶尔想起来才用」的，
  /// 平铺在首页会跟今日计划抢注意力，而且内容还跟计划重复。
  Future<void> _openMorePractice() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        final t = sheetContext.tokens;
        return SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.all(10),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            decoration: BoxDecoration(
              color: t.bg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: t.line,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  '更多练法',
                  style: Theme.of(sheetContext).textTheme.titleMedium,
                ),
                const SizedBox(height: 14),
                // 每日一练打卡：断掉的那天点一下能补做
                Row(
                  children: [
                    Text(
                      _checkinStreak > 0 ? '连续打卡 $_checkinStreak 天' : '每日一练打卡',
                      style: Theme.of(sheetContext).textTheme.bodySmall?.copyWith(
                            color: _checkinStreak > 0 ? t.brand : null,
                          ),
                    ),
                    const Spacer(),
                    for (var i = 6; i >= 0; i--) ...[
                      if (i < 6) const SizedBox(width: 6),
                      Builder(builder: (context) {
                        final day = DateTime.now().subtract(Duration(days: i));
                        final mark = _checkins[AppDatabase.dayKey(day)];
                        final isToday = i == 0;
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: mark != null
                              ? null
                              : () {
                                  Navigator.of(sheetContext).pop();
                                  if (isToday) {
                                    _startDaily();
                                  } else {
                                    _makeUp(day);
                                  }
                                },
                          child: Container(
                            width: 22,
                            height: 22,
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
                                ? Icon(Icons.check,
                                    size: 12, color: GlassDecor.on(t.brand))
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
                        );
                      }),
                    ],
                  ],
                ),
                const SizedBox(height: 18),
                LayoutBuilder(
                  builder: (context, box) {
                    const gap = 9.0;
                    final cols = box.maxWidth >= 460 ? 3 : 2;
                    final width = (box.maxWidth - gap * (cols - 1)) / cols;
                    return Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      children: [
                        for (final card in _featureCards(t))
                          SizedBox(width: width, child: card),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
    if (mounted) _reload();
  }

  /// Tap a module → pick subtype (折叠分类) then start.
  Future<void> _openCategory(String category) async {
    final subs = await AppDatabase.instance.listSubCategories(category);
    if (!mounted) return;
    final per = _paceSeconds[category] ?? 60;
    final minutes = (per * _count / 60).round();
    final picked = await showModalBottomSheet<_CategoryPick>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _CategoryBrowseSheet(
        category: category,
        subs: subs,
        count: _count,
        minutes: minutes,
      ),
    );
    if (picked == null || !mounted) return;
    switch (picked.mode) {
      case 'practice':
        await _start(
          category: category,
          subCategory: picked.subCategory,
        );
      case 'timed':
        await _startTimed(category, subCategory: picked.subCategory);
      case 'recite':
        await _startRecite(
          category: category,
          subCategory: picked.subCategory,
        );
    }
  }

  /// Long-press still jumps straight to 练习 / 限时 / 背题 for the whole module.
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
    // 整套题只在真的要做的时候才取 —— 首页为了显示一行字去捞 20 道
    // 带 HTML 的题目，是之前首屏最慢的一步。
    if (_daily.isEmpty) {
      _daily = await AppDatabase.instance
          .fetchDailySet(day: DateTime.now(), limit: 20);
      _dailyProgress =
          await AppDatabase.instance.dailyProgress(_daily.map((q) => q.id).toList());
    }
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

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingState();

    final t = context.tokens;
    final byKey = {for (final s in _stats) s.category: s};

    final bottomPad = MediaQuery.paddingOf(context).bottom +
        (context.isWide ? 16 : 170);

    // 首屏只回答一句话：现在该做什么。
    // 焦点卡把「问候 + 今日数字 + 快捷入口 + 打卡条」四块压成一块，
    // 其余次要练法收进「更多练法」，不再平铺占屏。
    final tasks = _todayPlan?.tasks ?? const <StudyTask>[];
    final nextTask = tasks
        .where((task) => !_todayPlanDone.contains(task.id))
        .cast<StudyTask?>()
        .firstWhere((_) => true, orElse: () => null);
    final planDone = tasks.where((t) => _todayPlanDone.contains(t.id)).length;

    final head = <Widget>[
          _TopBar(total: _total),
          FadeInUp(
            child: _FocusCard(
            doneToday: _week.last,
            goal: _goal,
            streak: _streak,
            nextTask: nextTask,
            planTotal: tasks.length,
            planDone: planDone,
            onStart: () {
              if (nextTask != null) {
                _runStudyTask(nextTask);
              } else {
                _startDaily();
              }
            },
            onMore: _openMorePractice,
              onTapGoal: _pickGoal,
              examDate: _examDate,
            ),
          ),
          FadeInUp(
            delay: const Duration(milliseconds: 40),
            child: _FocusMeta(
              done: _week.last,
              goal: _goal,
              streak: _streak,
              examDate: _examDate,
              onTap: _pickGoal,
            ),
          ),
          // 在跑的四天计划：一行提醒，不再单开一块
          for (final plan in _plans)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.gutter,
                14,
                AppTheme.gutter,
                0,
              ),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => AppShell.jumpTo.value = AppShell.wrongBookTab,
                child: Row(
                  children: [
                    StrokeIcon(AppIcon.replay, size: 15, color: t.brand),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        plan.doneToday
                            ? '「${plan.label}」今天已完成'
                            : '「${plan.label}」第 ${plan.nextDay} 天还没做',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    Icon(Icons.chevron_right, size: 15, color: t.muted),
                  ],
                ),
              ),
            ),
          FadeInUp(
            delay: const Duration(milliseconds: 70),
            child: TodayPlanSection(
            plan: _todayPlan,
            doneIds: _todayPlanDone,
            onToggle: _toggleStudyTask,
            onRun: _runStudyTask,
            onOpen: _openStudyTask,
            onLongPress: _longPressStudyTask,
            onManage: _openStudyPlan,
            onEnable: _openStudyPlan,
            ),
          ),
    ];
    final rest = <Widget>[
          _ListHeader(
            title: '按题型练习',
            trailing: '$_count 题 · ${_scopeLabel(_scope)}',
            onTapTrailing: _pickCount,
            onTapSecondary: _pickScope,
          ),
          const SizedBox(height: 2),
          FadeInUp(
            delay: const Duration(milliseconds: 140),
            child: _TypeGrid(
              stats: byKey,
              onTap: _openCategory,
              onLong: _moduleMenu,
            ),
          ),
          if (_hardCount > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.gutter,
                14,
                AppTheme.gutter,
                0,
              ),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _startHard,
                child: Row(
                  children: [
                    StrokeIcon(AppIcon.timer, size: 15, color: t.brand),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        '自己标难的 $_hardCount 题',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    Icon(Icons.chevron_right, size: 15, color: t.muted),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
    ];

    // 平板横屏：左边问候 + 入口卡 + 今日安排；右边题型与近 7 天。
    if (context.isExpanded) {
      return RefreshIndicator(
        color: t.brand,
        backgroundColor: t.surface,
        onRefresh: _reload,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: ListView(
                padding: EdgeInsets.only(bottom: bottomPad),
                children: head,
              ),
            ),
            Container(
              width: 1,
              margin: const EdgeInsets.symmetric(vertical: 20),
              color: t.line.withValues(alpha: 0.5),
            ),
            Expanded(
              flex: 4,
              child: ListView(
                padding: EdgeInsets.only(top: 22, bottom: bottomPad),
                children: rest,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: t.brand,
      backgroundColor: t.surface,
      onRefresh: _reload,
      child: ReadableWidth(
        child: ListView(
          padding: EdgeInsets.only(bottom: bottomPad),
          children: [...head, ...rest],
        ),
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
        AppTheme.gutter,
        0,
      ),
      child: SizedBox(
        height: 36,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 与下方「按题型练习」同一左缘，不再被 Logo 顶开。
            Text(
              '练习',
              style: text.titleMedium?.copyWith(
                fontSize: 17,
                letterSpacing: -0.3,
                height: 1,
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
      ),
    );
  }
}
String _scopeLabel(QuestionScope scope) => switch (scope) {
      QuestionScope.all => '全部题',
      QuestionScope.unseen => '没做过',
      QuestionScope.wrong => '做错过',
    };

/// 卡片高度得跟着系统字号走 —— 写死会在放大字号时把标题挤出去。
/// 横向 ListView 需要一个确定高度，所以这里统一算一次给两边用。
double featureCardHeight(BuildContext context) {
  final scale = MediaQuery.textScalerOf(context).scale(1);
  const chrome = 10 + 10 + 28 + 3 + 6; // 上下内边距 + 图标行 + 行间距 + 余量
  return chrome + (14 * 1.1 + 11 * 1.2) * scale;
}

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
    final t = context.tokens;
    final disabled = onTap == null;
    final base = colors.first;
    final dark = t.name == 'dark';

    return Opacity(
      opacity: disabled ? 0.42 : 1,
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLong,
        child: Container(
          height: featureCardHeight(context),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            color: base.withValues(alpha: dark ? 0.22 : 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: base.withValues(alpha: dark ? 0.35 : 0.18),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: StrokeIcon(glyph, size: 15, color: base),
                  ),
                  const Spacer(),
                  Icon(Icons.chevron_right, size: 16, color: base),
                ],
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  height: 1.1,
                  color: t.text,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                meta,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.2,
                  color: t.muted,
                  fontFeatures: AppTheme.numeric,
                ),
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
      child: SizedBox(
        height: 36,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              title,
              style: text.titleMedium?.copyWith(
                fontSize: 17,
                height: 1,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            const Spacer(),
            if (trailing != null)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onTapSecondary ?? onTapTrailing,
                onLongPress: onTapTrailing,
                child: Row(
                  children: [
                    Text(
                      trailing!,
                      style: text.labelMedium?.copyWith(
                        color: onTapTrailing == null ? t.muted : t.brand,
                        height: 1,
                        fontFeatures: AppTheme.numeric,
                      ),
                    ),
                    if (onTapTrailing != null)
                      Icon(Icons.expand_more, size: 16, color: t.brand),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
class _ScopeSheet extends StatelessWidget {
  const _ScopeSheet({required this.current, required this.counts});

  final QuestionScope current;
  final Map<QuestionScope, int> counts;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    const items = [
      (scope: QuestionScope.all, label: '全部题', desc: '优先近年真题，同年内随机'),
      (scope: QuestionScope.unseen, label: '没做过的', desc: '跳过已做 · 仍优先近年'),
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

class _CategoryPick {
  const _CategoryPick(this.mode, {this.subCategory});

  final String mode;
  final String? subCategory;
}

/// Tap a 题型 → foldable subtypes, then choose how to start.
class _CategoryBrowseSheet extends StatefulWidget {
  const _CategoryBrowseSheet({
    required this.category,
    required this.subs,
    required this.count,
    required this.minutes,
  });

  final String category;
  final List<({String key, int count})> subs;
  final int count;
  final int minutes;

  @override
  State<_CategoryBrowseSheet> createState() => _CategoryBrowseSheetState();
}

class _CategoryBrowseSheetState extends State<_CategoryBrowseSheet> {
  String? _expanded;

  @override
  void initState() {
    super.initState();
    if (widget.subs.isNotEmpty) _expanded = widget.subs.first.key;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final color = t.category(widget.category);
    final total = widget.subs.fold<int>(0, (s, e) => s + e.count);

    Widget actions(String? sub) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
        child: Row(
          children: [
            for (final item in [
              ('practice', '开始'),
              ('timed', '限时'),
              ('recite', '背题'),
            ]) ...[
              if (item.$1 != 'practice') const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.of(context).pop(
                    _CategoryPick(item.$1, subCategory: sub),
                  ),
                  child: Container(
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: item.$1 == 'practice'
                          ? color.withValues(alpha: 0.16)
                          : t.glass,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: item.$1 == 'practice'
                            ? color.withValues(alpha: 0.4)
                            : t.glassBorder,
                      ),
                    ),
                    child: Text(
                      item.$2,
                      style: text.labelMedium?.copyWith(
                        color: item.$1 == 'practice' ? color : t.textSoft,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.78,
      ),
      decoration: BoxDecoration(
        color: t.gradient.last,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: t.glassBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  StrokeIcon(
                    categoryIcon(widget.category),
                    size: 20,
                    color: color,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          categoryLabel(widget.category),
                          style: text.titleMedium,
                        ),
                        Text(
                          total > 0 ? '共 $total 题 · 展开分类后开始' : '暂无细分',
                          style: text.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // 全部混练始终可见，不折叠。
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
              child: Container(
                decoration: BoxDecoration(
                  color: t.glass,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: t.glassBorder),
                ),
                child: Column(
                  children: [
                    ListTile(
                      dense: true,
                      title: Text('全部混练', style: text.titleSmall),
                      subtitle: Text(
                        '${widget.count} 题 · 约 ${widget.minutes} 分钟节奏',
                        style: text.bodySmall,
                      ),
                      trailing: Icon(Icons.shuffle, size: 18, color: color),
                    ),
                    actions(null),
                  ],
                ),
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                itemCount: widget.subs.length,
                itemBuilder: (context, i) {
                  final sub = widget.subs[i];
                  final open = _expanded == sub.key;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: open
                            ? color.withValues(alpha: 0.08)
                            : t.glass,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: open
                              ? color.withValues(alpha: 0.35)
                              : t.glassBorder,
                        ),
                      ),
                      child: Column(
                        children: [
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => setState(
                              () => _expanded = open ? null : sub.key,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                14,
                                12,
                                12,
                                12,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          subCategoryLabel(sub.key),
                                          style: text.titleSmall,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${sub.count} 题',
                                          style: text.bodySmall?.copyWith(
                                            fontFeatures: AppTheme.numeric,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    open
                                        ? Icons.expand_less
                                        : Icons.expand_more,
                                    size: 20,
                                    color: t.muted,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (open) actions(sub.key),
                        ],
                      ),
                    ),
                  );
                },
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

/// 今日主卡 —— 首屏的视觉锚点。
///
/// 一整块渐变卡 + 右侧插画，文字压在左边。整屏就这一块是"重"的，
/// 其余内容都比它轻，视线自然先落在这里，再往下扫。
class _FocusCard extends StatelessWidget {
  const _FocusCard({
    required this.doneToday,
    required this.goal,
    required this.streak,
    required this.nextTask,
    required this.planTotal,
    required this.planDone,
    required this.onStart,
    required this.onMore,
    required this.onTapGoal,
    required this.examDate,
  });

  final int doneToday;
  final int goal;
  final int streak;
  final StudyTask? nextTask;
  final int planTotal;
  final int planDone;

  final VoidCallback onStart;
  final VoidCallback onMore;
  final VoidCallback onTapGoal;
  final DateTime? examDate;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final dark = t.name == 'dark';
    final allDone = planTotal > 0 && planDone >= planTotal;

    // 标题直接就是那件事本身；件数、进度这些统计退到卡外面那行小字里
    final headline = allDone
        ? '今天做完了'
        : nextTask?.title ?? (doneToday > 0 ? '继续练' : '开始今天的第一组');

    final subline = allDone
        ? '$doneToday 题 · 明天见'
        : [
            if (nextTask?.count != null) '${nextTask!.count} 题',
            if (nextTask?.minutes != null) '约 ${nextTask!.minutes} 分钟',
            if (planTotal > 0) '今天第 ${planDone + 1} 件 / 共 $planTotal',
          ].join(' · ');

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppTheme.gutter, 12, AppTheme.gutter, 0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: dark
                  ? Colors.black.withValues(alpha: 0.38)
                  : const Color(0xFF1B2540).withValues(alpha: 0.07),
              blurRadius: dark ? 32 : 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // 底：实体卡面 + 品牌色渐变
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: t.surface,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: dark
                        ? [
                            t.brand.withValues(alpha: 0.34),
                            t.brand.withValues(alpha: 0.10),
                          ]
                        : [
                            t.brand.withValues(alpha: 0.20),
                            t.brand.withValues(alpha: 0.05),
                          ],
                  ),
                ),
              ),
            ),
            // 插画退到右下角，只做氛围。进度环在它上面，不能被盖住。
            // 插画完整落在右上那片留白里，跟卡面渐变是一体的
            Positioned(
              right: -10,
              top: 4,
              width: 116,
              height: 116,
              child: Opacity(
                opacity: dark ? 0.62 : 0.85,
                child: Image.asset(
                  allDone ? 'assets/art/empty_done.png' : 'assets/art/hero_desk.png',
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    allDone ? '今天' : '接下来',
                    style: text.bodySmall?.copyWith(
                      color: t.brand,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // 这一屏只有一个主角：现在该做的那件事。
                  // 之前主卡里塞了件数、下一件、进度环、两个按钮，
                  // 累的时候打开看到五样东西，等于还得先做一次选择。
                  Padding(
                    padding: const EdgeInsets.only(right: 96),
                    child: Text(
                    headline,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.headlineMedium?.copyWith(
                      color: t.text,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                      letterSpacing: -0.6,
                    ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subline,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall?.copyWith(color: t.textSoft),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: _StartButton(
                      label: allDone ? '再练一组' : '开始练习',
                      onTap: onStart,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

/// 主卡下面那一行统计。
///
/// 进度环、倒计时、完成件数都不是"现在要做的事"，摆在主卡里会跟主按钮
/// 抢注意力。压成一行小字，想看的时候看得到，不想看时不碍事。
class _FocusMeta extends StatelessWidget {
  const _FocusMeta({
    required this.done,
    required this.goal,
    required this.streak,
    required this.examDate,
    required this.onTap,
  });

  final int done;
  final int goal;
  final int streak;
  final DateTime? examDate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final ratio = goal <= 0 ? 0.0 : (done / goal).clamp(0.0, 1.0);

    final now = DateTime.now();
    final daysLeft = examDate == null
        ? null
        : DateTime(examDate!.year, examDate!.month, examDate!.day)
            .difference(DateTime(now.year, now.month, now.day))
            .inDays;

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppTheme.gutter + 4, 12, AppTheme.gutter + 4, 0),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Row(
          children: [
            SizedBox(
              width: 15,
              height: 15,
              child: CircularProgressIndicator(
                value: ratio,
                strokeWidth: 2.5,
                strokeCap: StrokeCap.round,
                backgroundColor: t.text.withValues(alpha: 0.10),
                valueColor: AlwaysStoppedAnimation(t.brand),
              ),
            ),
            const SizedBox(width: 9),
            Text(
              '今天 $done / $goal 题',
              style: text.bodySmall?.copyWith(fontFeatures: AppTheme.numeric),
            ),
            if (streak > 0) ...[
              Text('  ·  ', style: text.bodySmall),
              Text('连续 $streak 天', style: text.bodySmall),
            ],
            const Spacer(),
            if (daysLeft != null)
              Text(
                daysLeft > 0 ? '距考试 $daysLeft 天' : '考试就在今天',
                style: text.bodySmall?.copyWith(
                  color: t.brand,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StartButton extends StatelessWidget {
  const _StartButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        decoration: BoxDecoration(
          color: t.brand,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: t.brand.withValues(alpha: 0.30),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(width: 7),
            const Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class _TypeGrid extends StatelessWidget {
  const _TypeGrid({
    required this.stats,
    required this.onTap,
    required this.onLong,
  });

  final Map<String, CategoryStat> stats;
  final void Function(String category) onTap;
  final void Function(String category) onLong;

  static const _art = {
    'yanyu': 'assets/art/cat_yanyu.png',
    'shuliang': 'assets/art/cat_shuliang.png',
    'panduan': 'assets/art/cat_panduan.png',
    'ziliao': 'assets/art/cat_ziliao.png',
    'changshi': 'assets/art/cat_changshi.png',
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.gutter),
      child: LayoutBuilder(
        builder: (context, box) {
          const gap = 11.0;
          final cols = box.maxWidth >= 560 ? 3 : 2;
          final width = (box.maxWidth - gap * (cols - 1)) / cols;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final c in kGongkaoCategories)
                SizedBox(
                  width: width,
                  child: _TypeTile(
                    meta: c,
                    stat: stats[c.key],
                    art: _art[c.key],
                    onTap: () => onTap(c.key),
                    onLong: () => onLong(c.key),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _TypeTile extends StatelessWidget {
  const _TypeTile({
    required this.meta,
    required this.stat,
    required this.art,
    required this.onTap,
    required this.onLong,
  });

  final CategoryMeta meta;
  final CategoryStat? stat;
  final String? art;
  final VoidCallback onTap;
  final VoidCallback onLong;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final color = t.category(meta.key);
    final dark = t.name == 'dark';
    final done = stat?.done ?? 0;

    return PressableCard(
      onTap: onTap,
      onLongPress: onLong,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: dark
                  ? Colors.black.withValues(alpha: 0.34)
                  : const Color(0xFF1B2540).withValues(alpha: 0.06),
              blurRadius: dark ? 26 : 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            height: 104,
            child: Stack(
              children: [
                // 卡片底：一层淡淡的题型色渐变，从左上的实色过渡到右边留白，
                // 插画就落在那片留白上，跟卡面是一体的，不是贴上去的小图。
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: t.surface,
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          color.withValues(alpha: dark ? 0.16 : 0.10),
                          color.withValues(alpha: dark ? 0.05 : 0.03),
                        ],
                      ),
                    ),
                  ),
                ),
                // 插画完整、清晰地占住右侧那块，不再是角落里的半透明水印
                if (art != null)
                  Positioned(
                    right: -2,
                    top: 10,
                    bottom: 6,
                    width: 72,
                    child: Image.asset(
                      art!,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                // 文字压在左侧，跟插画不重叠
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 78, 0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meta.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleSmall?.copyWith(
                          color: t.text,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        done > 0 ? '做过 $done 题' : '${stat?.total ?? 0} 题',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodySmall?.copyWith(
                          fontSize: 12,
                          // muted 压在浅色卡面上几乎读不出来
                          color: t.textSoft,
                          fontWeight: FontWeight.w500,
                          fontFeatures: AppTheme.numeric,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
