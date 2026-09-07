import 'package:flutter/material.dart';
import 'package:openexam_app/l10n/app_localizations.dart';
import 'package:openexam_app/core/constants/categories.dart';
import 'package:openexam_app/core/theme/app_theme.dart';
import 'package:openexam_app/core/theme/app_tokens.dart';
import 'package:openexam_app/features/practice/shore_home.dart';
import 'package:openexam_app/core/ui/ambient.dart';
import 'package:openexam_app/core/ui/responsive.dart';
import 'package:openexam_app/core/ui/ui_kit.dart';
import 'package:openexam_app/data/db/app_database.dart';
import 'package:openexam_app/data/models/question.dart';
import 'package:openexam_app/features/plan/data/starter_packs.dart';
import 'package:openexam_app/features/plan/data/study_plan_store.dart';
import 'package:openexam_app/features/plan/domain/models/plan_set.dart';
import 'package:openexam_app/features/plan/domain/models/study_task.dart';
import 'package:openexam_app/features/plan/presentation/widgets/study_task_editor_sheet.dart';
import 'package:openexam_app/features/practice/practice_session_page.dart';
import 'package:openexam_app/features/shell/app_shell.dart';
import 'package:openexam_app/features/vocab/presentation/vocab_page.dart';

class StudyPlanPage extends StatefulWidget {
  const StudyPlanPage({super.key, this.onRunTask, this.embedded = false});

  /// When opened from practice home, running a task can reuse the same starters.
  final Future<void> Function(StudyTask task)? onRunTask;

  /// True when shown as a shell tab — no back button.
  final bool embedded;

  @override
  State<StudyPlanPage> createState() => _StudyPlanPageState();
}

class _StudyPlanPageState extends State<StudyPlanPage> {
  static const _pastDays = 21;
  static const _futureDays = 56;
  static const _chipWidth = 56.0;
  static const _chipGap = 6.0;

  StudyPlanStore? _store;
  late DateTime _selected;
  DayPlan? _plan;
  Set<String> _done = {};
  String _setId = StudyPlanStore.offId;
  List<PlanSet> _sets = const [];
  int _streak = 0;
  bool _loading = true;
  late final ScrollController _dayScroll;
  late final List<DateTime> _days;
  bool _didScrollToSelected = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selected = DateTime(now.year, now.month, now.day);
    _dayScroll = ScrollController();
    final start = _selected.subtract(const Duration(days: _pastDays));
    _days = List.generate(
      _pastDays + _futureDays + 1,
      (i) => DateTime(start.year, start.month, start.day).add(Duration(days: i)),
    );
    _reload();
  }

  @override
  void dispose() {
    _dayScroll.dispose();
    super.dispose();
  }

  void _scrollDayIntoView({bool animated = true}) {
    if (!_dayScroll.hasClients) return;
    final index = _days.indexWhere((d) => _sameDay(d, _selected));
    if (index < 0) return;
    final viewport = _dayScroll.position.viewportDimension;
    final offset = index * (_chipWidth + _chipGap) - (viewport - _chipWidth) / 2;
    final target = offset.clamp(0.0, _dayScroll.position.maxScrollExtent);
    if (animated) {
      _dayScroll.animateTo(
        target,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    } else {
      _dayScroll.jumpTo(target);
    }
  }

  Future<void> _reload() async {
    final store = _store ?? await StudyPlanStore.create();
    final plan = store.isEnabled ? store.planFor(_selected) : null;
    final done = plan == null ? <String>{} : store.loadDoneIds(plan.dateKey);
    if (!mounted) return;
    setState(() {
      _store = store;
      _setId = store.activeSetId;
      _sets = store.loadSets();
      _plan = plan;
      _done = done;
      _streak = store.streak(DateTime.now());
      _loading = false;
    });
  }

  Future<void> _selectDay(DateTime day) async {
    setState(() => _selected = DateTime(day.year, day.month, day.day));
    await _reload();
    _scrollDayIntoView();
  }

  Future<void> _toggle(StudyTask task, bool done) async {
    final store = _store;
    final plan = _plan;
    if (store == null || plan == null) return;
    await store.toggleDone(plan.dateKey, task.id, done);
    await _reload();
  }

  Future<void> _run(StudyTask task) async {
    final runner = widget.onRunTask;
    if (runner != null) {
      await runner(task);
      await _reload();
      return;
    }
    await _runLocally(task);
  }

  Future<void> _runLocally(StudyTask task) async {
    // 各分支都在 await 之后拼标题，先把本地化对象取出来 ——
    // 跨 await 摸 context 会被 lint 拦。
    final l = AppL.of(context);
    if (task.action == StudyAction.note) {
      await _toggle(task, !_done.contains(task.id));
      return;
    }
    if (task.action == StudyAction.openWrongBook) {
      if (mounted) Navigator.of(context).maybePop();
      AppShell.jumpTo.value = AppShell.wrongBookTab;
      return;
    }

    List<Question> questions = const [];
    Duration? limit;
    var title = task.displayTitle(l);
    final db = AppDatabase.instance;

    switch (task.action) {
      case StudyAction.vocab:
        await Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const VocabPage()));
        if (mounted) await _reload();
        return;
      case StudyAction.check:
        // 打卡项没有去处，勾掉就是完成。
        await _toggle(task, !_done.contains(task.id));
        return;
      case StudyAction.practice:
        questions = await db.fetchPractice(
          category: task.category,
          limit: task.count ?? 20,
          shuffle: true,
        );
        title = task.category == null
            ? task.displayTitle(l)
            : l.planCatPractice(categoryLabel(task.category));
        if (task.minutes != null) {
          limit = Duration(minutes: task.minutes!);
        } else if (task.timed) {
          limit = Duration(seconds: 60 * questions.length);
        }
        break;
      case StudyAction.daily:
        questions = await db.fetchDailySet(day: DateTime.now(), limit: 20);
        title = l.homeDaily;
        break;
      case StudyAction.mock:
        questions = await db.fetchPractice(limit: 50, shuffle: true);
        limit = const Duration(minutes: 45);
        title = l.homeMock;
        break;
      case StudyAction.wrong:
        questions = await db.fetchWrong(limit: task.count ?? 20);
        title = l.homeRedoWrong;
        break;
      case StudyAction.adaptive:
        questions = await db.fetchAdaptive(limit: task.count ?? 20);
        title = l.homeWeakDrill;
        break;
      case StudyAction.note:
      case StudyAction.openWrongBook:
        return;
    }

    if (!mounted) return;
    if (questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.homeNoQuestionsHere)),
      );
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
    final store = _store;
    final plan = _plan;
    if (store != null && plan != null) {
      await store.toggleDone(plan.dateKey, task.id, true);
    }
    await _reload();
  }

  Future<void> _pickPlanSet() async {
    final store = _store;
    if (store == null) return;
    final picked = await showModalBottomSheet<PlanSetAction>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _PlanSetSheet(current: _setId, sets: _sets),
    );
    if (picked == null || !mounted) return;

    switch (picked) {
      case UseSet(:final id):
        await store.setActiveSet(id);
      case TurnOffPlan():
        await store.setActiveSet(StudyPlanStore.offId);
      case StartNewSet():
        final created = await showModalBottomSheet<(String, StarterPack?)>(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (_) => const _NewPlanSheet(),
        );
        if (created == null) return;
        final (name, pack) = created;
        await store.createSet(
          name,
          tasks: pack?.expand(DateTime.now()) ?? const [],
        );
      case RenamePlanSet(:final set):
        final name = await showRenameTaskDialog(context, initial: set.displayName(AppL.of(context)));
        if (name == null || name.isEmpty) return;
        await store.renameSet(set.id, name);
      case DeletePlanSet(:final set):
        final ok = await _confirm(
          title: AppL.of(context).planDeleteSet,
          body: AppL.of(context).planDeleteSetBody(set.name, set.tasks.length),
          action: AppL.of(context).commonDelete,
        );
        if (ok != true) return;
        await store.deleteSet(set.id);
    }
    await _reload();
  }

  Future<bool?> _confirm({
    required String title,
    required String body,
    required String action,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(AppL.of(context).commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(action),
          ),
        ],
      ),
    );
  }

  Future<void> _addTask() async {
    final result = await showStudyTaskEditor(context, create: true);
    if (result == null || result.delete || result.task == null || _store == null) {
      return;
    }
    await _store!.upsertTask(_selected, result.task!);
    await _reload();
  }

  Future<void> _openTask(StudyTask task) async {
    final result = await showStudyTaskEditor(context, initial: task);
    if (result == null || _store == null) return;
    if (result.delete) {
      await _deleteTask(task);
      return;
    }
    if (result.task != null) {
      await _store!.upsertTask(_selected, result.task!);
      await _reload();
    }
  }

  Future<void> _renameTask(StudyTask task) async {
    final name = await showRenameTaskDialog(context, initial: task.displayTitle(AppL.of(context)));
    if (name == null || name.isEmpty || _store == null) return;
    await _store!.renameTask(_selected, task, name);
    await _reload();
  }

  Future<void> _deleteTask(StudyTask task) async {
    if (_store == null) return;

    // 一次性任务只活在这一天，删就是删，没什么可问的
    if (task.repeat == RepeatRule.once) {
      final ok = await _confirm(
        title: AppL.of(context).planDeleteTask,
        body: AppL.of(context).homeDeleteTaskConfirm(task.displayTitle(AppL.of(context))),
        action: AppL.of(context).commonDelete,
      );
      if (ok != true) return;
      await _store!.deleteTask(_selected, task);
      await _reload();
      return;
    }

    // 重复任务问清楚：今天不想做，和以后都不做，是两回事
    final scope = await showDialog<PlanEditScope>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppL.of(context).planDeleteTask),
        content: Text(AppL.of(context).planRepeatNote(
            task.displayTitle(AppL.of(context)), task.repeat.label(AppL.of(context)))),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppL.of(context).commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(PlanEditScope.today),
            child: Text(AppL.of(context).planSkipToday),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(PlanEditScope.forever),
            child: Text(AppL.of(context).planDeleteForever),
          ),
        ],
      ),
    );
    if (scope == null) return;
    await _store!.deleteTask(_selected, task, scope: scope);
    await _reload();
  }

  Future<void> _longPressTask(StudyTask task) async {
    await showStudyTaskActions(
      context,
      task: task,
      onEdit: () => _openTask(task),
      onRename: () => _renameTask(task),
      onDelete: () => _deleteTask(task),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientBackground(
        child: SafeArea(
          child: _loading
              ? const LoadingState()
              : ReadableWidth(
                  // 平板侧栏里铺满可用宽度；手机 push 进来仍限可读宽。
                  maxWidth: widget.embedded ? double.infinity : null,
                  child: ListView(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.paddingOf(context).bottom + 28,
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppTheme.gutter,
                          8,
                          AppTheme.gutter - 8,
                          0,
                        ),
                        child: Row(
                          children: [
                            if (!widget.embedded) ...[
                              PlainIconButton(
                                icon: Icons.arrow_back,
                                onTap: () => Navigator.of(context).maybePop(),
                              ),
                              SizedBox(width: 4),
                            ],
                            // 标题占满剩下的宽度并截断 —— 英文标题比中文长，320 宽的屏上
                            // 顶死会把返回键那一行撑出黄黑条（见 i18n_layout_test）。
                            Expanded(
                              child: Text(
                                AppL.of(context).planTitle,
                                style: text.titleMedium,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Spacer(),
                            TextButton(
                              onPressed: _pickPlanSet,
                              child: Text(
                                _setLabel(),
                                style: text.labelMedium?.copyWith(
                                  color: t.brand,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          AppTheme.gutter,
                          8,
                          AppTheme.gutter,
                          0,
                        ),
                        child: Text(
                          _streak > 0
                              ? AppL.of(context).planStreak(_streak)
                              : AppL.of(context).planIntro,
                          style: text.bodySmall,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppTheme.gutter,
                        ),
                        child: Row(
                          children: [
                            Text(
                              AppL.of(context).planMonth(_selected.month),
                              style: text.titleSmall,
                            ),
                            SizedBox(width: 8),
                            // 提示语可以截，月份和「回到今天」不能被挤掉。
                            Flexible(
                              child: Text(
                                AppL.of(context).planSwipeHint,
                                style: text.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Spacer(),
                            if (!_sameDay(_selected, DateTime.now()))
                              TextButton(
                                onPressed: () => _selectDay(DateTime.now()),
                                child: Text(
                                  AppL.of(context).planBackToToday,
                                  style: text.labelMedium?.copyWith(
                                    color: t.brand,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 76,
                        child: ListView.separated(
                          controller: _dayScroll,
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.gutter,
                          ),
                          itemCount: _days.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: _chipGap),
                          itemBuilder: (context, i) {
                            final day = _days[i];
                            final selected = _sameDay(day, _selected);
                            final plan = _store?.isEnabled == true
                                ? _store!.planFor(day)
                                : null;
                            final doneCount = plan == null
                                ? 0
                                : _store!
                                    .loadDoneIds(plan.dateKey)
                                    .intersection(
                                      plan.tasks.map((e) => e.id).toSet(),
                                    )
                                    .length;
                            final total = plan?.tasks.length ?? 0;
                            final complete =
                                total > 0 && doneCount >= total;
                            if (!_didScrollToSelected) {
                              _didScrollToSelected = true;
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                _scrollDayIntoView(animated: false);
                              });
                            }
                            return SizedBox(
                              width: _chipWidth,
                              child: _DayChip(
                                day: day,
                                selected: selected,
                                complete: complete,
                                progressLabel:
                                    total == 0 ? '—' : '$doneCount/$total',
                                onTap: () => _selectDay(day),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 22),
                      if (_plan == null || _plan!.tasks.isEmpty)
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: ShoreGap.page,
                          ),
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            // 空计划要能就地加第一条 —— 以前这里只能去挑模板，
                            // 新建一份空的之后就卡死在这，一条也加不进去
                            onTap: _addTask,
                            child: Container(
                              padding: EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: t.accentSoft,
                                borderRadius: BorderRadius.circular(22),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          AppL.of(context).planNothingToday,
                                          style: text.titleSmall
                                              ?.copyWith(fontSize: 15.5),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          AppL.of(context).planAddHint,
                                          style: text.bodySmall?.copyWith(
                                            fontSize: 12.5,
                                            color: t.onAccentSoft,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 11,
                                    ),
                                    decoration: BoxDecoration(
                                      color: t.accent,
                                      borderRadius: BorderRadius.circular(99),
                                    ),
                                    child: Text(
                                      AppL.of(context).planAdd,
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
                        )
                      else ...[
                        // 跟首页「今日航线」是同一个清单组件。
                        // 之前这里是一排横滑的彩色任务卡，跟首页各说各的，
                        // 同一份计划在两个页面长得完全不像同一件事。
                        ShoreSection(
                          title: AppL.of(context).planToday,
                          caption: '${_done.intersection(_plan!.tasks.map((e) => e.id).toSet()).length} / ${_plan!.tasks.length}',
                          action: AppL.of(context).planManage,
                          onAction: _pickPlanSet,
                          child: RouteList(
                            tasks: _plan!.tasks,
                            doneIds: _done,
                            onRun: _run,
                            onToggle: _toggle,
                            onLongPress: _longPressTask,
                            max: 99,
                            highlightCurrent:
                                _sameDay(_selected, DateTime.now()),
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: ShoreGap.page,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _addTask,
                                child: Text(AppL.of(context).planAddTitle),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _pickPlanSet,
                                child: Text(AppL.of(context).planMine),
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

  String _setLabel() {
    if (_setId == StudyPlanStore.offId) return AppL.of(context).planOff;
    for (final s in _sets) {
      if (s.id == _setId) return s.displayName(AppL.of(context));
    }
    return AppL.of(context).planPick;
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.day,
    required this.selected,
    required this.complete,
    required this.progressLabel,
    required this.onTap,
  });

  final DateTime day;
  final bool selected;
  final bool complete;
  final String progressLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final today = DateTime.now();
    final isToday =
        day.year == today.year && day.month == today.month && day.day == today.day;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          // 选中走 accent，跟别处"按下去会发生什么"同一个色；
          // 做完那天留一层淡绿，一眼能扫出这周哪几天划完了。
          color: selected
              ? t.accent
              : (complete ? t.successSoft : t.surface),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? t.accent
                : (isToday ? t.accent.withValues(alpha: 0.55) : t.lineSoft),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isToday
                  ? AppL.of(context).planTodayMark
                  : MaterialLocalizations.of(context)
                      .narrowWeekdays[day.weekday % 7],
              style: text.bodySmall?.copyWith(
                color: selected ? t.onAccent : t.muted,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${day.day}',
              style: text.titleSmall?.copyWith(
                color: selected ? t.onAccent : t.text,
                fontFeatures: AppTheme.numeric,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              progressLabel,
              style: text.bodySmall?.copyWith(
                fontSize: 10,
                color: selected
                    ? t.onAccent.withValues(alpha: 0.75)
                    : (complete ? t.success : t.muted),
                fontFeatures: AppTheme.numeric,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 在计划管理面板上选了什么。
sealed class PlanSetAction {
  const PlanSetAction();
}

class UseSet extends PlanSetAction {
  const UseSet(this.id);
  final String id;
}

/// 去新建流程 —— 名字和起点在那一步里选，不摊在这个面板上。
class StartNewSet extends PlanSetAction {
  const StartNewSet();
}

class RenamePlanSet extends PlanSetAction {
  const RenamePlanSet(this.set);
  final PlanSet set;
}

class DeletePlanSet extends PlanSetAction {
  const DeletePlanSet(this.set);
  final PlanSet set;
}

class TurnOffPlan extends PlanSetAction {
  const TurnOffPlan();
}

/// 管计划清单：换一份、新建、改名、删掉。
///
/// 只列用户自己的几份清单。新建和关闭是顶上两个图标 —— 它们不是"另一份计划"，
/// 跟清单平铺成一样的行会让人一眼分不清哪些是自己的东西。范例也不在这儿，
/// 挪进新建那一步：想开新的才需要看见它们。
class _PlanSetSheet extends StatelessWidget {
  const _PlanSetSheet({required this.current, required this.sets});

  final String current;
  final List<PlanSet> sets;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final off = current == StudyPlanStore.offId;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.75,
      ),
      decoration: BoxDecoration(
        color: t.gradient.last,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: t.lineSoft)),
      ),
      padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(width: 4),
                Expanded(child: Text(AppL.of(context).planMine, style: text.titleMedium)),
                IconButton(
                  tooltip: AppL.of(context).commonNew,
                  icon: Icon(Icons.add, size: 22),
                  color: t.brand,
                  onPressed: () =>
                      Navigator.of(context).pop(StartNewSet()),
                ),
                IconButton(
                  tooltip: off ? AppL.of(context).planClosed : AppL.of(context).planClose,
                  icon: Icon(
                    off ? Icons.visibility_off : Icons.visibility_off_outlined,
                    size: 21,
                  ),
                  color: off ? t.brand : t.textSoft,
                  onPressed: () =>
                      Navigator.of(context).pop(const TurnOffPlan()),
                ),
              ],
            ),
            if (off)
              Padding(
                padding: EdgeInsets.fromLTRB(6, 2, 6, 8),
                child: Text(
                  AppL.of(context).planClosedHint,
                  style: text.bodySmall?.copyWith(color: t.textSoft),
                ),
              ),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final set in sets)
                      _SetRow(
                        set: set,
                        selected: set.id == current,
                        onTap: () => Navigator.of(context).pop(UseSet(set.id)),
                        onRename: () =>
                            Navigator.of(context).pop(RenamePlanSet(set)),
                        onDelete: () =>
                            Navigator.of(context).pop(DeletePlanSet(set)),
                      ),
                    if (sets.isEmpty)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 26),
                        child: Text(
                          AppL.of(context).planNone,
                          style: text.bodySmall?.copyWith(color: t.textSoft),
                        ),
                      ),
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

/// 一份计划一行：左边图标，中间名字和条数，右边改名 / 删除。
class _SetRow extends StatelessWidget {
  const _SetRow({
    required this.set,
    required this.selected,
    required this.onTap,
    required this.onRename,
    required this.onDelete,
  });

  final PlanSet set;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: selected ? t.brand : t.accentSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                selected ? Icons.check : Icons.checklist_rounded,
                size: 20,
                color: selected ? t.onAccent : t.onAccentSoft,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    set.displayName(AppL.of(context)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleSmall
                        ?.copyWith(color: selected ? t.brand : t.text),
                  ),
                  SizedBox(height: 2),
                  Text(
                    AppL.of(context).planItemCount(set.tasks.length),
                    style: text.bodySmall?.copyWith(color: t.textSoft),
                  ),
                ],
              ),
            ),
            _MiniIcon(icon: Icons.drive_file_rename_outline, onTap: onRename),
            _MiniIcon(icon: Icons.delete_outline, onTap: onDelete),
          ],
        ),
      ),
    );
  }
}

class _MiniIcon extends StatelessWidget {
  const _MiniIcon({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return InkResponse(
      onTap: onTap,
      radius: 20,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 8),
        child: Icon(icon, size: 18, color: t.textSoft),
      ),
    );
  }
}

/// 新建一份计划：起个名字，选个起点。
///
/// 范例只在这一步露面 —— 平时管计划的时候不该有一堆"别人的模板"杵在那儿。
class _NewPlanSheet extends StatefulWidget {
  const _NewPlanSheet();

  @override
  State<_NewPlanSheet> createState() => _NewPlanSheetState();
}

class _NewPlanSheetState extends State<_NewPlanSheet> {
  final _name = TextEditingController();
  StarterPack? _pack;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _name.text.trim().isEmpty
        ? (_pack?.name ?? AppL.of(context).planMine)
        : _name.text.trim();
    Navigator.of(context).pop((name, _pack));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        ),
        decoration: BoxDecoration(
          color: t.gradient.last,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: t.lineSoft)),
        ),
        padding: EdgeInsets.fromLTRB(20, 16, 20, 10),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(AppL.of(context).planNewTitle, style: text.titleMedium)),
                  TextButton(
                    onPressed: _submit,
                    child: Text(
                      AppL.of(context).planCreate,
                      style: text.labelMedium?.copyWith(color: t.brand),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              TextField(
                controller: _name,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: AppL.of(context).planName,
                  hintText: AppL.of(context).planNameHint,
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              SizedBox(height: 18),
              Text(AppL.of(context).planStartFrom, style: text.titleSmall),
              SizedBox(height: 8),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _StartOption(
                        icon: Icons.edit_outlined,
                        title: AppL.of(context).planBlank,
                        subtitle: AppL.of(context).planBlankHint,
                        selected: _pack == null,
                        onTap: () => setState(() => _pack = null),
                      ),
                      for (final pack in StarterPacks.all)
                        _StartOption(
                          icon: Icons.auto_awesome_outlined,
                          title: pack.name,
                          subtitle: pack.blurb,
                          selected: _pack?.id == pack.id,
                          onTap: () => setState(() => _pack = pack),
                        ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 4),
              Text(
                AppL.of(context).planTemplateHint,
                style: text.bodySmall?.copyWith(color: t.textSoft),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StartOption extends StatelessWidget {
  const _StartOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: selected ? t.brand : t.accentSoft,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                icon,
                size: 19,
                color: selected ? t.onAccent : t.onAccentSoft,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleSmall
                        ?.copyWith(color: selected ? t.brand : t.text),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall?.copyWith(color: t.textSoft),
                  ),
                ],
              ),
            ),
            if (selected) Icon(Icons.check, size: 18, color: t.brand),
          ],
        ),
      ),
    );
  }
}
