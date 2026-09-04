import 'package:flutter/material.dart';
import 'package:openexam_app/core/constants/categories.dart';
import 'package:openexam_app/core/theme/app_theme.dart';
import 'package:openexam_app/core/theme/app_tokens.dart';
import 'package:openexam_app/core/ui/ambient.dart';
import 'package:openexam_app/core/ui/responsive.dart';
import 'package:openexam_app/core/ui/ui_kit.dart';
import 'package:openexam_app/data/db/app_database.dart';
import 'package:openexam_app/data/models/question.dart';
import 'package:openexam_app/features/plan/data/plan_templates.dart';
import 'package:openexam_app/features/plan/data/study_plan_store.dart';
import 'package:openexam_app/features/plan/domain/models/study_task.dart';
import 'package:openexam_app/features/plan/presentation/widgets/study_task_editor_sheet.dart';
import 'package:openexam_app/features/plan/presentation/widgets/today_plan_section.dart';
import 'package:openexam_app/features/practice/practice_session_page.dart';
import 'package:openexam_app/features/shell/app_shell.dart';

class StudyPlanPage extends StatefulWidget {
  const StudyPlanPage({super.key, this.onRunTask, this.embedded = false});

  /// When opened from practice home, running a task can reuse the same starters.
  final StudyTaskCallback? onRunTask;

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
  String _templateId = PlanTemplates.workingId;
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
      _templateId = store.templateId;
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
    var title = task.title;
    final db = AppDatabase.instance;

    switch (task.action) {
      case StudyAction.practice:
        questions = await db.fetchPractice(
          category: task.category,
          limit: task.count ?? 20,
          shuffle: true,
        );
        title = task.category == null
            ? task.title
            : '${categoryLabel(task.category)}练习';
        if (task.minutes != null) {
          limit = Duration(minutes: task.minutes!);
        } else if (task.timed) {
          limit = Duration(seconds: 60 * questions.length);
        }
        break;
      case StudyAction.daily:
        questions = await db.fetchDailySet(day: DateTime.now(), limit: 20);
        title = '每日一练';
        break;
      case StudyAction.mock:
        questions = await db.fetchPractice(limit: 50, shuffle: true);
        limit = const Duration(minutes: 45);
        title = '限时模考';
        break;
      case StudyAction.wrong:
        questions = await db.fetchWrong(limit: task.count ?? 20);
        title = '错题重练';
        break;
      case StudyAction.adaptive:
        questions = await db.fetchAdaptive(limit: task.count ?? 20);
        title = '弱项强化';
        break;
      case StudyAction.note:
      case StudyAction.openWrongBook:
        return;
    }

    if (!mounted) return;
    if (questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('这里还没有题')),
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

  Future<void> _pickTemplate() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _TemplateSheet(current: _templateId),
    );
    if (picked == null || _store == null) return;
    await _store!.setTemplateId(picked);
    await _reload();
  }

  Future<void> _addTask() async {
    final result = await showStudyTaskEditor(context, create: true);
    if (result == null || result.delete || result.task == null || _store == null) {
      return;
    }
    await _store!.upsertTask(_selected, result.task!.copyWith(custom: true));
    await _reload();
  }

  Future<void> _openTask(StudyTask task) async {
    final result = await showStudyTaskEditor(context, initial: task);
    if (result == null || _store == null) return;
    if (result.delete) {
      await _store!.deleteTask(_selected, task);
      await _reload();
      return;
    }
    if (result.task != null) {
      await _store!.upsertTask(_selected, result.task!);
      await _reload();
    }
  }

  Future<void> _renameTask(StudyTask task) async {
    final name = await showRenameTaskDialog(context, initial: task.title);
    if (name == null || name.isEmpty || _store == null) return;
    await _store!.renameTask(_selected, task, name);
    await _reload();
  }

  Future<void> _deleteTask(StudyTask task) async {
    if (_store == null) return;
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
    await _store!.deleteTask(_selected, task);
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
                              const SizedBox(width: 4),
                            ],
                            Text('复习计划', style: text.titleMedium),
                            const Spacer(),
                            TextButton(
                              onPressed: _pickTemplate,
                              child: Text(
                                _templateLabel(_templateId),
                                style: text.labelMedium?.copyWith(
                                  color: t.brand,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppTheme.gutter,
                          8,
                          AppTheme.gutter,
                          0,
                        ),
                        child: Text(
                          _streak > 0
                              ? '计划连签 $_streak 天 · 勾完当天清单算一天'
                              : '选好模板后，每天按清单练；可再加自己的任务',
                          style: text.bodySmall,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.gutter,
                        ),
                        child: Row(
                          children: [
                            Text(
                              '${_selected.month}月',
                              style: text.titleSmall,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '左右滑动看更多天',
                              style: text.bodySmall,
                            ),
                            const Spacer(),
                            if (!_sameDay(_selected, DateTime.now()))
                              TextButton(
                                onPressed: () => _selectDay(DateTime.now()),
                                child: Text(
                                  '回到今天',
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
                      if (_plan == null)
                        TodayPlanSection(
                          plan: null,
                          doneIds: const {},
                          onToggle: (_, __) async {},
                          onRun: (_) async {},
                          onManage: _pickTemplate,
                          onEnable: _pickTemplate,
                        )
                      else ...[
                        TodayPlanSection(
                          plan: _plan,
                          doneIds: _done,
                          onToggle: _toggle,
                          onRun: _run,
                          onOpen: _openTask,
                          onLongPress: _longPressTask,
                          onManage: _pickTemplate,
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppTheme.gutter,
                            8,
                            AppTheme.gutter,
                            0,
                          ),
                          child: Row(
                            children: [
                              TextButton.icon(
                                onPressed: _addTask,
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('添加安排'),
                              ),
                              const Spacer(),
                              TextButton(
                                onPressed: _pickTemplate,
                                child: Text(
                                  '换模板',
                                  style: text.labelMedium?.copyWith(
                                    color: t.brand,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  static String _templateLabel(String id) {
    if (id == PlanTemplates.offId) return '未启用';
    return PlanTemplates.byId(id)?.title ?? '换模板';
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
    const labels = ['一', '二', '三', '四', '五', '六', '日'];
    final today = DateTime.now();
    final isToday =
        day.year == today.year && day.month == today.month && day.day == today.day;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? t.brand
              : (complete ? t.brandSoft : t.glass),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isToday && !selected
                ? t.brand.withValues(alpha: 0.45)
                : t.glassBorder,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isToday ? '今' : labels[day.weekday - 1],
              style: text.bodySmall?.copyWith(
                color: selected ? t.onBrand : t.muted,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${day.day}',
              style: text.titleSmall?.copyWith(
                color: selected ? t.onBrand : t.text,
                fontFeatures: AppTheme.numeric,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              progressLabel,
              style: text.bodySmall?.copyWith(
                fontSize: 10,
                color: selected ? t.onBrand.withValues(alpha: 0.85) : t.muted,
                fontFeatures: AppTheme.numeric,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplateSheet extends StatelessWidget {
  const _TemplateSheet({required this.current});

  final String current;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final items = <(String, String, String)>[
      (
        PlanTemplates.workingId,
        PlanTemplates.working.title,
        PlanTemplates.working.blurb,
      ),
      (
        PlanTemplates.lightId,
        PlanTemplates.light.title,
        PlanTemplates.light.blurb,
      ),
      (PlanTemplates.offId, '关闭计划', '首页不再显示今日安排'),
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
            Text('复习节奏模板', style: text.titleMedium),
            const SizedBox(height: 6),
            Text('可随时更换；当天勾选进度会保留', style: text.bodySmall),
            const SizedBox(height: 6),
            for (final item in items)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(context).pop(item.$1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.$2,
                              style: text.titleSmall?.copyWith(
                                color: item.$1 == current ? t.brand : t.text,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(item.$3, style: text.bodySmall),
                          ],
                        ),
                      ),
                      if (item.$1 == current)
                        Icon(Icons.check, size: 18, color: t.brand),
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
