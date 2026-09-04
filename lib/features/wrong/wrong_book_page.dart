import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:openexam_app/core/constants/categories.dart';
import 'package:openexam_app/core/theme/app_theme.dart';
import 'package:openexam_app/core/theme/app_tokens.dart';
import 'package:openexam_app/features/practice/shore_home.dart';
import 'package:openexam_app/core/ui/responsive.dart';
import 'package:openexam_app/core/ui/filter_bar.dart';
import 'package:openexam_app/core/ui/glass.dart';
import 'package:openexam_app/core/ui/rich_content.dart';
import 'package:openexam_app/core/ui/stroke_icons.dart';
import 'package:openexam_app/core/ui/ui_kit.dart';
import 'package:openexam_app/data/db/app_database.dart';
import 'package:openexam_app/data/models/question.dart';
import 'package:openexam_app/features/practice/practice_session_page.dart';

/// 错题本 — the review loop 考公 users live in: everything answered wrong and
/// not yet re-answered correctly, grouped by 题型, one tap to re-practise.
class WrongBookPage extends StatefulWidget {
  const WrongBookPage({super.key});

  @override
  State<WrongBookPage> createState() => _WrongBookPageState();
}

class _WrongBookPageState extends State<WrongBookPage> {
  bool _loading = true;
  List<Question> _wrong = const [];
  Map<String, String> _reasons = const {};

  /// Independent filters, so 「言语 + 粗心 + 某套卷」 is one tap each instead of
  /// switching modes and losing the other choice.
  String _category = 'all';
  String _reasonFilter = 'all';
  String _paper = 'all';
  String _level = 'all';

  /// 概览优先：打开就是密密麻麻的错题列表，没人愿意复盘。先看分布、
  /// 挑一类练，需要逐题翻的时候再切到列表。
  bool _listMode = false;

  /// Sort by how many times a question has been missed, rather than recency.
  bool _sortByCount = false;
  Map<String, int> _counts = const {};
  List<ReviewPlan> _plans = const [];
  Map<String, int> _difficulty = const {};

  /// Reviewing by 题型 finds weak modules; reviewing by 试卷 finds the paper you
  /// bombed. Both are how 考生 actually revisit mistakes.

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    if (!_loading) setState(() => _loading = true);
    final wrong = await AppDatabase.instance.fetchWrong(limit: 200);
    final reasons = await AppDatabase.instance.wrongReasons();
    final counts = await AppDatabase.instance.wrongCounts();
    final plans = await AppDatabase.instance.reviewPlans();
    final difficulty = await AppDatabase.instance.difficulties();
    if (!mounted) return;
    setState(() {
      _wrong = wrong;
      _reasons = reasons;
      _counts = counts;
      _plans = plans;
      _difficulty = difficulty;
      _loading = false;
    });
  }

  Future<void> _remove(Question q) async {
    await AppDatabase.instance.forgetQuestion(q.id);
    if (!mounted) return;
    await _reload();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        const SnackBar(
          content: Text('已移出错题本'),
          duration: Duration(milliseconds: 1200),
        ),
      );
  }

  /// Long-press menu: everything you might want to do with a wrong question
  /// without leaving the list.
  Future<void> _actions(Question q) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ActionSheet(
        question: q,
        reason: _reasons[q.id],
        times: _counts[q.id] ?? 1,
      ),
    );
    if (action == null || !mounted) return;
    switch (action) {
      case 'practise':
        await _practise([q]);
      case 'browse':
        await _browse([q]);
      case 'same':
        final list = await AppDatabase.instance.fetchPractice(
          category: q.category,
          limit: 10,
        );
        await _practise(list);
      case 'mark':
        await AppDatabase.instance.toggleMark(q.id, true);
        if (!mounted) return;
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            const SnackBar(
              content: Text('已收藏'),
              duration: Duration(milliseconds: 1100),
            ),
          );
      case 'remove':
        await _remove(q);
      default:
        // A reason key: tag it and refresh.
        await AppDatabase.instance.setWrongReason(q.id, action);
        await _reload();
    }
  }

  /// Exports the current view as Markdown — printable, greppable, and easy to
  /// paste into notes. Offline app, so the file goes wherever the user says.
  Future<void> _export(List<Question> questions) async {
    if (questions.isEmpty) return;
    final notes = await AppDatabase.instance.notes();
    final buffer = StringBuffer()
      ..writeln('# 错题本')
      ..writeln()
      ..writeln('导出时间：${DateTime.now().toString().substring(0, 16)}')
      ..writeln('共 ${questions.length} 题')
      ..writeln();

    for (var i = 0; i < questions.length; i++) {
      final q = questions[i];
      buffer
        ..writeln('## ${i + 1}. ${categoryLabel(q.category)}'
            '${q.year > 0 ? ' · ${q.year} 年' : ''}')
        ..writeln()
        ..writeln(q.content);
      if (q.hasImage) buffer.writeln('（本题含图，导出文件不含图片）');
      buffer.writeln();
      for (final o in q.options) {
        buffer.writeln('- ${o.key}. ${o.text.isEmpty ? '（图片选项）' : o.text}');
      }
      buffer
        ..writeln()
        ..writeln('**正确答案：${q.answer.toUpperCase()}**');
      final reason = _reasons[q.id];
      if (reason != null) buffer.writeln('**错因：${wrongReasonLabel(reason)}**');
      final times = _counts[q.id] ?? 1;
      if (times > 1) buffer.writeln('**错过 $times 次**');
      if (q.analysis.isNotEmpty) {
        buffer
          ..writeln()
          ..writeln('解析：${q.analysis}');
      }
      final note = notes[q.id];
      if (note != null && note.isNotEmpty) {
        buffer
          ..writeln()
          ..writeln('我的笔记：$note');
      }
      buffer
        ..writeln()
        ..writeln('---')
        ..writeln();
    }

    final now = DateTime.now();
    final name = 'openexam-错题-'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}.md';
    try {
      final path = await FilePicker.platform.saveFile(
        fileName: name,
        bytes: utf8.encode(buffer.toString()),
      );
      if (!mounted) return;
      if (path == null) {
        final dir = await getApplicationDocumentsDirectory();
        await File('${dir.path}/$name').writeAsString(buffer.toString());
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          content: Text(path == null ? '已保存到 App 文档目录：$name' : '已导出 $name'),
        ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导出失败：$e')),
      );
    }
  }

  /// 今日复盘：错次数多的排前面，取一组练。粉笔那套「同类错因连盯几天」的
  /// 前提是每天真的有一组能直接开练的题。
  Future<void> _reviewToday() async {
    final list = [..._wrong]
      ..sort((a, b) => (_counts[b.id] ?? 1).compareTo(_counts[a.id] ?? 1));
    await _practise(list.take(20).toList());
  }

  Future<void> _browseToday() async {
    final list = [..._wrong]
      ..sort((a, b) => (_counts[b.id] ?? 1).compareTo(_counts[a.id] ?? 1));
    await _browse(list.take(20).toList());
  }

  /// 开一个四天计划。同一个 key 再开一次就是重新计时。
  Future<void> _startPlan({
    required String key,
    required String kind,
    required String label,
  }) async {
    await AppDatabase.instance
        .startReviewPlan(key: key, kind: kind, label: label);
    await _reload();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text('已开始「$label」四天计划')));
  }

  /// Runs one step of a plan: day 3 is timed, day 4 mixes in fresh questions
  /// of the same type so you cannot pass on memory alone.
  Future<void> _runPlan(ReviewPlan plan) async {
    final day = plan.nextDay;
    var pool = _wrong.where((q) {
      if (plan.kind == 'reason') return (_reasons[q.id] ?? '_none') == plan.key;
      return q.category == plan.key;
    }).toList();
    if (pool.isEmpty) pool = [..._wrong];
    if (pool.isEmpty) return;
    pool = pool.take(15).toList();

    var questions = [...pool];
    if (day == 4) {
      final fresh = await AppDatabase.instance.fetchPractice(
        category: plan.kind == 'category' ? plan.key : pool.first.category,
        limit: 8,
        shuffle: true,
        scope: QuestionScope.unseen,
      );
      questions = [...pool, ...fresh]..shuffle();
    }

    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PracticeSessionPage(
          questions: questions,
          limit: day == 3
              ? Duration(seconds: 55 * questions.length)
              : null,
          title: '${plan.label} · 第 $day 天',
        ),
      ),
    );
    await AppDatabase.instance.tickReviewPlan(plan.key, day);
    await _reload();
  }

  void _focus({String? category, String? reason, String? paper}) {
    setState(() {
      _category = category ?? 'all';
      _reasonFilter = reason ?? 'all';
      _paper = paper ?? 'all';
      _listMode = true;
    });
  }

  Future<void> _practise(List<Question> questions) async {
    if (questions.isEmpty) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PracticeSessionPage(questions: questions),
      ),
    );
    _reload();
  }

  /// 只看答案与解析，不计入新一次作答。
  Future<void> _browse(List<Question> questions) async {
    if (questions.isEmpty) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PracticeSessionPage(
          questions: questions,
          preferScroll: true,
          reviewAnswers: {
            for (final q in questions) q.id: q.answer.trim().toUpperCase(),
          },
          title: '错题速览',
        ),
      ),
    );
  }


  /// 概览：先回答「我错在哪、今天该练什么」，再谈逐题翻。
  List<Widget> _overview(
    BuildContext context,
    Map<String, int> counts,
    Map<String, int> reasonCounts,
    Map<String, ({String title, int year, List<Question> items})> papers,
    List<String> paperKeys,
  ) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final worst = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final untagged = reasonCounts['_none'] ?? 0;
    final repeat = _counts.values.where((v) => v > 1).length;
    final max = worst.isEmpty ? 1 : worst.first.value;

    Widget header(String title, {String? action, VoidCallback? onAction}) =>
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.gutter,
            22,
            AppTheme.gutter,
            12,
          ),
          child: Row(
            children: [
              Expanded(child: Text(title, style: text.titleSmall)),
              if (action != null)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onAction,
                  child: Text(
                    action,
                    style: text.bodySmall?.copyWith(color: t.brand),
                  ),
                ),
            ],
          ),
        );

    return [
      // 今日复盘 — one tap into the questions that cost the most marks.
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.gutter),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _reviewToday,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 18, 14, 18),
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
                              '今日复盘',
                              style: text.titleSmall?.copyWith(fontSize: 16),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              repeat > 0
                                  ? '先啃错过两次以上的 $repeat 题'
                                  : '挑 ${_wrong.length > 20 ? 20 : _wrong.length} 题重做',
                              style: text.bodySmall?.copyWith(
                                color: const Color(0xFF96792F),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 11,
                        ),
                        decoration: BoxDecoration(
                          color: t.accent,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          '开始',
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
            ),
            const SizedBox(width: 10),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _browseToday,
              child: Container(
                width: 88,
                padding: const EdgeInsets.symmetric(vertical: 17, horizontal: 10),
                decoration: GlassDecor.panel(t, radius: 22, raised: false),
                child: Column(
                  children: [
                    StrokeIcon(AppIcon.papers, size: 20, color: t.brand),
                    const SizedBox(height: 8),
                    Text(
                      '速览解析',
                      style: text.labelMedium?.copyWith(
                        color: t.brand,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // 进行中的四天计划排在最前，因为它是有截止感的那件事。
      for (final plan in _plans.where((p) => !p.finished))
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.gutter,
            12,
            AppTheme.gutter,
            0,
          ),
          child: _PlanCard(
            plan: plan,
            onRun: () => _runPlan(plan),
            onDrop: () async {
              await AppDatabase.instance.dropReviewPlan(plan.key);
              await _reload();
            },
          ),
        ),
      if (untagged > 0)
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.gutter,
            12,
            AppTheme.gutter,
            0,
          ),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _focus(reason: '_none'),
            child: Row(
              children: [
                StrokeIcon(AppIcon.info, size: 16, color: t.muted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$untagged 题还没标错因，标了才知道是粗心还是不会',
                    style: text.bodySmall,
                  ),
                ),
                Icon(Icons.chevron_right, size: 15, color: t.muted),
              ],
            ),
          ),
        ),

      if (reasonCounts.isNotEmpty) ...[
        header('还在反复犯的'),
      Padding(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.gutter,
          0,
          AppTheme.gutter,
          10,
        ),
        child: Text('长按一类可以开四天专项计划', style: text.bodySmall),
      ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.gutter),
          child: Wrap(
            spacing: 9,
            runSpacing: 9,
            children: [
              for (final r in kWrongReasons)
                if ((reasonCounts[r.key] ?? 0) > 0)
                  _ReasonChip(
                    label: r.label,
                    count: reasonCounts[r.key]!,
                    onTap: () => _focus(reason: r.key),
                    onLong: () => _startPlan(
                      key: r.key,
                      kind: 'reason',
                      label: r.label,
                    ),
                  ),
              if (untagged > 0)
                _ReasonChip(
                  label: '未标错因',
                  count: untagged,
                  onTap: () => _focus(reason: '_none'),
                ),
            ],
          ),
        ),
      ],

      header('按题型', action: '全部 ›', onAction: () => _focus()),
      for (final e in worst)
        _DistRow(
          label: categoryLabel(e.key),
          count: e.value,
          ratio: e.value / max,
          color: t.category(e.key),
          icon: categoryIcon(e.key),
          onTap: () => _focus(category: e.key),
          onLong: () => _startPlan(
            key: e.key,
            kind: 'category',
            label: categoryLabel(e.key),
          ),
        ),

      if (paperKeys.length > 1) ...[
        header('错得最多的卷'),
        for (final key in paperKeys.take(4))
          _DistRow(
            label: papers[key]!.title,
            count: papers[key]!.items.length,
            ratio: papers[key]!.items.length / papers[paperKeys.first]!.items.length,
            color: t.brand,
            icon: AppIcon.papers,
            onTap: () => _focus(paper: key),
          ),
      ],

      const SizedBox(height: 26),
      if (!context.isExpanded)
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.gutter),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _listMode = true),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '逐题查看全部 ${_wrong.length} 题',
                style: text.bodySmall?.copyWith(color: t.brand),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, size: 15, color: t.brand),
            ],
          ),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingState();

    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final counts = <String, int>{};
    for (final q in _wrong) {
      counts[q.category] = (counts[q.category] ?? 0) + 1;
    }
    final papers = <String, ({String title, int year, List<Question> items})>{};
    for (final q in _wrong) {
      final key = q.paperId.isEmpty ? '_' : q.paperId;
      papers.putIfAbsent(
        key,
        () => (
          title: q.paperTitle.isEmpty ? '未归卷题目' : q.paperTitle,
          year: q.year,
          items: <Question>[],
        ),
      );
      papers[key]!.items.add(q);
    }
    final paperKeys = papers.keys.toList()
      ..sort(
        (a, b) => papers[b]!.items.length.compareTo(papers[a]!.items.length),
      );

    final reasonCounts = <String, int>{};
    for (final q in _wrong) {
      final key = _reasons[q.id] ?? '_none';
      reasonCounts[key] = (reasonCounts[key] ?? 0) + 1;
    }

    final base = _wrong.where((q) {
      if (_category != 'all' && q.category != _category) return false;
      if (_reasonFilter != 'all' &&
          (_reasons[q.id] ?? '_none') != _reasonFilter) {
        return false;
      }
      if (_paper != 'all' && (q.paperId.isEmpty ? '_' : q.paperId) != _paper) {
        return false;
      }
      if (_level != 'all' &&
          '${_difficulty[q.id] ?? 0}' != _level) {
        return false;
      }
      return true;
    }).toList();
    final shown = _sortByCount
        ? ([
            ...base,
          ]..sort((a, b) => (_counts[b.id] ?? 0).compareTo(_counts[a.id] ?? 0)))
        : base;

    // 平板横屏：概览钉在左边，右边是筛选后的题目列表。点左边的模块或错因
    // 直接换右边的内容，不用来回切视图。
    if (context.isExpanded && _wrong.isNotEmpty) {
      return Row(
        children: [
          SizedBox(
            width: 400,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(0, 18, 0, 30),
              children: [
                PageTitleBar(
                  title: '错题本',
                  meta: '${_wrong.length} 题待消灭',
                  top: 0,
                  bottom: 16,
                ),
                ..._overview(context, counts, reasonCounts, papers, paperKeys),
              ],
            ),
          ),
          Container(width: 1, color: t.line.withValues(alpha: 0.5)),
          Expanded(
            child: RefreshIndicator(
              color: t.brand,
              backgroundColor: t.surface,
              onRefresh: _reload,
              child: ListView(
                padding: const EdgeInsets.only(top: 18, bottom: 30),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.gutter,
                      0,
                      AppTheme.gutter,
                      10,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            shown.length == _wrong.length
                                ? '全部错题'
                                : '筛出 ${shown.length} 题',
                            style: text.titleSmall,
                          ),
                        ),
                        _IconAction(
                          icon: AppIcon.replay,
                          tip: '重练当前筛选的题',
                          onTap: () => _practise(shown.take(20).toList()),
                        ),
                        _IconAction(
                          icon: AppIcon.download,
                          tip: '导出当前列表为 Markdown',
                          onTap: () => _export(shown),
                        ),
                      ],
                    ),
                  ),
                  for (var i = 0; i < shown.length; i++) ...[
                    if (i > 0) const RowDivider(),
                    Reveal(
                      index: i,
                      child: _WrongRow(
                        question: shown[i],
                        reason: _reasons[shown[i].id],
                        times: _counts[shown[i].id] ?? 1,
                        onTap: () => _practise([shown[i]]),
                        onLong: () => _actions(shown[i]),
                        onRemove: () => _remove(shown[i]),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      );
    }

    return RefreshIndicator(
      color: t.brand,
      backgroundColor: t.surface,
      onRefresh: _reload,
      child: ReadableWidth(
        child: ListView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.paddingOf(context).bottom + 150,
        ),
        children: [
          const SizedBox(height: ShoreGap.top),
          ShoreHeader(
            kicker: _wrong.isEmpty
                ? '答错的题会自动收进来'
                : (_listMode
                    ? '${_wrong.length} 题 · 长按可标错因'
                    : '${_wrong.length} 题待消灭'),
            title: '错题本',
            actions: [
              if (_wrong.isNotEmpty) ...[
                if (_listMode)
                  ShoreRoundButton(
                    icon: StrokeIcon(AppIcon.chart, size: 19, color: t.textSoft),
                    onTap: () => setState(() => _listMode = false),
                  ),
                ShoreRoundButton(
                  icon: StrokeIcon(AppIcon.replay, size: 19, color: t.textSoft),
                  onTap: () => _practise(shown.take(20).toList()),
                ),
                ShoreRoundButton(
                  icon: StrokeIcon(AppIcon.papers, size: 19, color: t.textSoft),
                  onTap: () => _browse(shown.take(40).toList()),
                ),
              ],
            ],
          ),
          const SizedBox(height: ShoreGap.titleToBody),
          if (_wrong.isEmpty)
            const EmptyState(
              icon: Icons.verified_outlined,
              title: '还没有错题',
              art: EmptyArt.done,
              message: '去练习页刷一组，答错的题会自动进入这里，答对后自动移出。',
            )
          else if (!_listMode && !context.isExpanded)
            ..._overview(context, counts, reasonCounts, papers, paperKeys)
          else ...[
            FilterBar(
              filters: [
                FilterSpec(
                  key: 'category',
                  label: '题型',
                  value: _category,
                  icon: AppIcon.logic,
                  options: [
                    FilterOption('all', '全部题型', count: _wrong.length),
                    for (final c in kGongkaoCategories)
                      if ((counts[c.key] ?? 0) > 0)
                        FilterOption(c.key, c.label, count: counts[c.key]),
                  ],
                ),
                FilterSpec(
                  key: 'reason',
                  label: '错因',
                  value: _reasonFilter,
                  icon: AppIcon.wrongBook,
                  options: [
                    FilterOption('all', '全部错因', count: _wrong.length),
                    for (final r in kWrongReasons)
                      if ((reasonCounts[r.key] ?? 0) > 0)
                        FilterOption(
                          r.key,
                          r.label,
                          count: reasonCounts[r.key],
                        ),
                    if ((reasonCounts['_none'] ?? 0) > 0)
                      FilterOption(
                        '_none',
                        '未标错因',
                        count: reasonCounts['_none'],
                      ),
                  ],
                ),
                FilterSpec(
                  key: 'paper',
                  label: '来源卷',
                  value: _paper,
                  icon: AppIcon.papers,
                  options: [
                    FilterOption('all', '全部试卷', count: _wrong.length),
                    for (final key in paperKeys)
                      FilterOption(
                        key,
                        papers[key]!.title,
                        count: papers[key]!.items.length,
                      ),
                  ],
                ),
                FilterSpec(
                  key: 'level',
                  label: '难度',
                  value: _level,
                  icon: AppIcon.chart,
                  options: [
                    FilterOption('all', '全部难度', count: _wrong.length),
                    for (final lv in const [3, 2, 1, 0])
                      FilterOption(
                        '$lv',
                        const {3: '我标了难', 2: '一般', 1: '简单', 0: '没标过'}[lv]!,
                        count: _wrong
                            .where((q) => (_difficulty[q.id] ?? 0) == lv)
                            .length,
                      ),
                  ],
                ),
                FilterSpec(
                  key: 'sort',
                  label: '排序',
                  value: _sortByCount ? 'count' : 'all',
                  icon: AppIcon.chart,
                  options: const [
                    FilterOption('all', '最近错的在前'),
                    FilterOption('count', '错得最多在前'),
                  ],
                ),
              ],
              onChanged: (key, value) => setState(() {
                switch (key) {
                  case 'category':
                    _category = value;
                  case 'reason':
                    _reasonFilter = value;
                  case 'paper':
                    _paper = value;
                  case 'level':
                    _level = value;
                  case 'sort':
                    _sortByCount = value == 'count';
                }
              }),
              onReset: () => setState(() {
                _category = 'all';
                _reasonFilter = 'all';
                _paper = 'all';
                _level = 'all';
                _sortByCount = false;
              }),
            ),
            const SizedBox(height: 6),
            if (shown.length != _wrong.length)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.gutter,
                  6,
                  AppTheme.gutter,
                  0,
                ),
                child: Text(
                  '筛出 ${shown.length} 题 · 长按任意题可标错因或移出',
                  style: text.bodySmall,
                ),
              ),
            const SizedBox(height: 6),
            ListView.separated(
              shrinkWrap: true,
              primary: false,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: shown.length,
              separatorBuilder: (_, __) => const RowDivider(),
              itemBuilder: (context, i) => Reveal(
                index: i,
                child: _WrongRow(
                question: shown[i],
                reason: _reasons[shown[i].id],
                times: _counts[shown[i].id] ?? 1,
                onTap: () => _practise([shown[i]]),
                onLong: () => _actions(shown[i]),
                  onRemove: () => _remove(shown[i]),
                ),
              ),
            ),
          ],
        ],
      ),
      ),
    );
  }
}

/// Bare icon button for the header — labelled buttons made this row heavy.
class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.icon,
    required this.tip,
    required this.onTap,
  });

  final AppIcon icon;
  final String tip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Tooltip(
      message: tip,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Center(child: StrokeIcon(icon, size: 20, color: t.brand)),
        ),
      ),
    );
  }
}

/// Long-press menu for one wrong question.
class _ActionSheet extends StatelessWidget {
  const _ActionSheet({
    required this.question,
    required this.reason,
    required this.times,
  });

  final Question question;
  final String? reason;
  final int times;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    Widget row(
      AppIcon icon,
      String label,
      String value, {
      bool danger = false,
    }) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).pop(value),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: [
              StrokeIcon(icon, size: 19, color: danger ? t.danger : t.textSoft),
              const SizedBox(width: 14),
              Text(
                label,
                style: text.titleSmall?.copyWith(
                  color: danger ? t.danger : t.text,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: t.gradient.last,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: t.glassBorder)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question.content,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: text.bodyMedium?.copyWith(color: t.text, fontSize: 14),
            ),
            const SizedBox(height: 6),
            Text(
              '${categoryLabel(question.category)} · 错过 $times 次'
              '${reason == null ? '' : ' · ${wrongReasonLabel(reason)}'}',
              style: text.bodySmall,
            ),
            const SizedBox(height: 10),
            const RowDivider(indent: 0),
            row(AppIcon.play, '重做这道题', 'practise'),
            const RowDivider(indent: 0),
            row(AppIcon.papers, '只看答案解析', 'browse'),
            const RowDivider(indent: 0),
            row(AppIcon.shuffle, '再练 10 道同类型', 'same'),
            const RowDivider(indent: 0),
            row(AppIcon.wrongBook, '加入收藏', 'mark'),
            const RowDivider(indent: 0),
            Padding(
              padding: const EdgeInsets.only(top: 14, bottom: 8),
              child: Text('标记错因', style: text.bodySmall),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final r in kWrongReasons)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.of(context).pop(r.key),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: reason == r.key
                            ? t.brand.withValues(alpha: 0.15)
                            : t.glass,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: reason == r.key
                              ? t.brand.withValues(alpha: 0.5)
                              : Colors.transparent,
                        ),
                      ),
                      child: Text(
                        r.label,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          height: 1,
                          color: reason == r.key ? t.brand : t.textSoft,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            const RowDivider(indent: 0),
            row(AppIcon.trash, '移出错题本', 'remove', danger: true),
          ],
        ),
      ),
    );
  }
}

/// Long-press menu for one wrong question.
class _WrongRow extends StatelessWidget {
  const _WrongRow({
    required this.question,
    required this.reason,
    required this.times,
    required this.onTap,
    required this.onLong,
    required this.onRemove,
  });

  final Question question;
  final String? reason;
  final int times;
  final VoidCallback onLong;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final color = t.category(question.category);

    return Dismissible(
      key: ValueKey(question.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onRemove(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppTheme.gutter),
        color: t.dangerSoft,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            StrokeIcon(AppIcon.trash, size: 19, color: t.danger),
            const SizedBox(width: 8),
            Text(
              '移出',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: t.danger,
              ),
            ),
          ],
        ),
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onLongPress: onLong,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.gutter,
            vertical: 14,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: QuestionThumb(
                  markup: question.bodyMarkup,
                  icon: categoryIcon(question.category),
                  color: color,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      question.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodyLarge?.copyWith(
                        fontSize: 15,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        Text(
                          categoryLabel(question.category),
                          style: text.bodySmall?.copyWith(color: color),
                        ),
                        Text(
                          '  ·  正确答案 ${question.answer.toUpperCase()}',
                          style: text.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: StrokeIcon(AppIcon.play, size: 22, color: t.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One bar in the 错题分布 lists — label, count, and how it compares.
class _DistRow extends StatelessWidget {
  const _DistRow({
    required this.label,
    required this.count,
    required this.ratio,
    required this.color,
    required this.icon,
    required this.onTap,
    this.onLong,
  });

  final String label;
  final int count;
  final double ratio;
  final Color color;
  final AppIcon icon;
  final VoidCallback onTap;
  final VoidCallback? onLong;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onLongPress: onLong,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.gutter,
          vertical: 10,
        ),
        child: Row(
          children: [
            StrokeIcon(icon, size: 18, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.titleSmall?.copyWith(fontSize: 14.5),
                        ),
                      ),
                      Text('$count 题', style: text.bodySmall),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Meter(value: ratio.clamp(0.0, 1.0), height: 4, color: color),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(Icons.chevron_right, size: 15, color: t.muted),
          ],
        ),
      ),
    );
  }
}

/// 错因 chip on the overview.
class _ReasonChip extends StatelessWidget {
  const _ReasonChip({
    required this.label,
    required this.count,
    required this.onTap,
    this.onLong,
  });

  final String label;
  final int count;
  final VoidCallback onTap;
  final VoidCallback? onLong;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onLongPress: onLong,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: t.glass,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                height: 1,
                color: t.textSoft,
              ),
            ),
            const SizedBox(width: 7),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1,
                color: t.brand,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 四天计划卡：四个格子，今天该做哪一步、做完打上勾。
class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.onRun,
    required this.onDrop,
  });

  final ReviewPlan plan;
  final VoidCallback onRun;
  final VoidCallback onDrop;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final day = plan.nextDay;
    final rest = plan.doneToday;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
      decoration: GlassDecor.panel(t, radius: 20, raised: false),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StrokeIcon(AppIcon.replay, size: 17, color: t.brand),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  '${plan.label} 四天计划',
                  style: text.titleSmall?.copyWith(fontSize: 15),
                ),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onDrop,
                child: Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: StrokeIcon(AppIcon.trash, size: 16, color: t.muted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              for (var d = 1; d <= 4; d++) ...[
                if (d > 1) const SizedBox(width: 7),
                Expanded(
                  child: _Step(
                    index: d,
                    done: plan.doneDays.contains(d),
                    current: d == day && !rest,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rest
                          ? '今天这步做完了，明天再来'
                          : '第 $day 天 · ${ReviewPlan.stepTitles[day - 1]}',
                      style: text.titleSmall?.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      rest ? '中间隔一天，记忆才吃得住' : ReviewPlan.stepHints[day - 1],
                      style: text.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onRun,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: rest ? t.glass : t.brand,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    rest ? '再练一次' : '开始',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      height: 1,
                      color: rest ? t.textSoft : GlassDecor.on(t.brand),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.index,
    required this.done,
    required this.current,
  });

  final int index;
  final bool done;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: done
            ? t.brand.withValues(alpha: 0.18)
            : current
                ? t.brand
                : t.glass,
        borderRadius: BorderRadius.circular(11),
      ),
      child: done
          ? Icon(Icons.check, size: 16, color: t.brand)
          : Text(
              '$index',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1,
                color: current ? GlassDecor.on(t.brand) : t.muted,
              ),
            ),
    );
  }
}
