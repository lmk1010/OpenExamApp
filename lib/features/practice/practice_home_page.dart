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
import 'package:openexam_app/features/practice/practice_session_page.dart';
import 'package:openexam_app/features/practice/shore_home.dart';
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
      // 申论不该只能从当天的计划任务进。没排任务的日子它就消失了。
      _FeatureCard(
        title: '申论批改',
        meta: '写一篇，交给 AI 评',
        glyph: AppIcon.papers,
        colors: [t.success],
        onTap: () async {
          if (!mounted) return;
          Navigator.of(context).pop();
          await Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const EssayPage()));
          if (mounted) _reload();
        },
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
                            color: _checkinStreak > 0 ? t.success : null,
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
                            width: 24,
                            height: 24,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: mark != null
                                  ? t.success
                                  : isToday
                                      ? t.accentSoft
                                      : t.surfaceAlt,
                              shape: BoxShape.circle,
                            ),
                            child: mark != null
                                ? const Icon(Icons.check,
                                    size: 13, color: Colors.white)
                                : Text(
                                    '${day.day}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      height: 1,
                                      color:
                                          isToday ? t.onAccentSoft : t.muted,
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
                const SizedBox(height: 16),
                // 练法的两个参数放在这里，首页不为它们留位置
                Row(
                  children: [
                    _SheetLink(
                      label: '每组 $_count 题',
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        _pickCount();
                      },
                    ),
                    const SizedBox(width: 18),
                    _SheetLink(
                      label: _scopeLabel(_scope),
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        _pickScope();
                      },
                    ),
                    const Spacer(),
                    _SheetLink(
                      label: '共 $_total 题',
                      onTap: () => showModalBottomSheet<void>(
                        context: sheetContext,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const _AboutSheet(),
                      ),
                    ),
                  ],
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
    final tasks = _todayPlan?.tasks ?? const <StudyTask>[];

    final bottomPad =
        MediaQuery.paddingOf(context).bottom + (context.isWide ? 16 : 158);

    final now = DateTime.now();
    final daysLeft = _examDate == null
        ? null
        : DateTime(_examDate!.year, _examDate!.month, _examDate!.day)
            .difference(DateTime(now.year, now.month, now.day))
            .inDays;

    final head = <Widget>[
      const SizedBox(height: ShoreGap.top),
      ShoreHeader(
        kicker: '${now.month} 月 ${now.day} 日 · ${_weekdayCn(now)}',
        title: _greeting(now),
        actions: [
          ShoreRoundButton(
            icon: Icon(Icons.search, size: 19, color: t.textSoft),
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const SearchPage())),
          ),
          ShoreRoundButton(
            icon: Icon(ThemeController.instance.icon,
                size: 19, color: t.textSoft),
            onTap: () => ThemeController.instance.cycle(),
          ),
        ],
      ),
      const SizedBox(height: ShoreGap.titleToBody),
      VoyageCard(
        done: _week.last,
        goal: _goal,
        streak: _streak,
        daysLeft: (daysLeft != null && daysLeft >= 0) ? daysLeft : null,
        onTap: _pickGoal,
      ),
      const SizedBox(height: ShoreGap.section),
      if (tasks.isEmpty)
        ShoreSection(
          title: '今日航线',
          action: '安排',
          onAction: _openStudyPlan,
          child: _EmptyRoute(onTap: _openStudyPlan),
        )
      else
        ShoreSection(
          title: '今日航线',
          action: tasks.length > 4 ? '全部 ${tasks.length}' : '调整',
          onAction: _openStudyPlan,
          child: RouteList(
            tasks: tasks,
            doneIds: _todayPlanDone,
            onRun: _runStudyTask,
            onLongPress: _longPressStudyTask,
          ),
        ),
      // 在跑的四天计划：一行提醒，不单开一块
      for (final plan in _plans)
        _HintRow(
          icon: AppIcon.replay,
          text: plan.doneToday
              ? '「${plan.label}」今天已完成'
              : '「${plan.label}」第 ${plan.nextDay} 天还没做',
          onTap: () => AppShell.jumpTo.value = AppShell.wrongBookTab,
        ),
    ];

    final rest = <Widget>[
      const SizedBox(height: ShoreGap.section),
      ShoreSection(
        title: '五座岛',
        action: '更多练法',
        onAction: _openMorePractice,
        child: IsleStrip(
          stats: byKey,
          onTap: _openCategory,
          onLong: _moduleMenu,
        ),
      ),
      if (_hardCount > 0)
        _HintRow(
          icon: AppIcon.timer,
          text: '自己标难的 $_hardCount 题',
          onTap: _startHard,
        ),
      const SizedBox(height: 12),
    ];

    // 平板横屏：左边航程与航线，右边五座岛。
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
            Expanded(
              flex: 4,
              child: ListView(
                padding: EdgeInsets.only(top: ShoreGap.top, bottom: bottomPad),
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

  String _greeting(DateTime now) {
    if (_week.last >= _goal) return '今天划完了';
    if (now.hour < 11) return '早，该出发了';
    if (now.hour < 18) return '继续划';
    return '收个尾再靠岸';
  }
}

String _weekdayCn(DateTime d) =>
    const ['周一', '周二', '周三', '周四', '周五', '周六', '周日'][d.weekday - 1];


/// 没排航线时的占位。空态给一句话和一个动作，不给一张空卡。
class _EmptyRoute extends StatelessWidget {
  const _EmptyRoute({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ShoreGap.page),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          decoration: BoxDecoration(
            color: t.accentSoft,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '还没排今天的航线',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontSize: 15.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '模板可以改，删掉不做的就行',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(fontSize: 12.5, color: t.onAccentSoft),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                decoration: BoxDecoration(
                  color: t.accent,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '去安排',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: t.onAccent,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 一行次要提醒。够用的信息不值得一张卡。
class _HintRow extends StatelessWidget {
  const _HintRow({required this.icon, required this.text, this.onTap});

  final AppIcon icon;
  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.fromLTRB(ShoreGap.page, 14, ShoreGap.page, 0),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Row(
          children: [
            StrokeIcon(icon, size: 15, color: t.brand),
            const SizedBox(width: 9),
            Expanded(
              child: Text(text, style: Theme.of(context).textTheme.bodySmall),
            ),
            Icon(Icons.chevron_right, size: 15, color: t.muted),
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
  const chrome = 11 + 11 + 19 + 3 + 8; // 上下内边距 + 图标行 + 行间距 + 余量
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

    return Opacity(
      opacity: disabled ? 0.42 : 1,
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLong,
        // 五张卡五个底色、每个 icon 还各自套一层色块，一屏就成了调色盘。
        // 现在卡面统一是白的，颜色只留在 icon 上 —— 卡片本身已经是容器了。
        child: Container(
          height: featureCardHeight(context),
          padding: const EdgeInsets.fromLTRB(14, 11, 12, 11),
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(18),
            boxShadow: t.shadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  StrokeIcon(glyph, size: 19, color: base),
                  const Spacer(),
                  Icon(Icons.chevron_right, size: 16, color: t.muted),
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
        border: Border(top: BorderSide(color: t.lineSoft)),
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
        border: Border(top: BorderSide(color: t.lineSoft)),
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
                  // 题型色只做标记，不做按钮。按钮一律是那一个动作色，
                  // 否则每开一个题型，"开始"就换一种颜色。
                  child: Container(
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: item.$1 == 'practice' ? t.accent : t.surfaceAlt,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      item.$2,
                      style: text.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: item.$1 == 'practice' ? t.onAccent : t.textSoft,
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
        border: Border(top: BorderSide(color: t.lineSoft)),
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
                  color: t.surfaceAlt,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: t.lineSoft),
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
                            : t.surfaceAlt,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: open
                              ? color.withValues(alpha: 0.35)
                              : t.lineSoft,
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

/// 主卡下面那一行统计。
///

/// 面板里的文字按钮。比一整行 ListTile 轻，也不抢主动作。
class _SheetLink extends StatelessWidget {
  const _SheetLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: context.tokens.brand,
          ),
        ),
      ),
    );
  }
}
