import 'package:flutter/material.dart';
import 'package:openexam_app/core/constants/categories.dart';
import 'package:openexam_app/core/theme/app_theme.dart';
import 'package:openexam_app/core/theme/app_tokens.dart';
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
  String _filter = 'all';

  /// 'type' groups by 题型, 'paper' by 试卷, 'reason' by 错因.
  String _mode = 'type';

  /// Sort by how many times a question has been missed, rather than recency.
  bool _sortByCount = false;
  Map<String, int> _counts = const {};

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
    if (!mounted) return;
    setState(() {
      _wrong = wrong;
      _reasons = reasons;
      _counts = counts;
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

  Future<void> _practise(List<Question> questions) async {
    if (questions.isEmpty) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PracticeSessionPage(questions: questions),
      ),
    );
    _reload();
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

    final base = _filter == 'all'
        ? _wrong
        : (_mode == 'reason'
              ? _wrong
                    .where((q) => (_reasons[q.id] ?? '_none') == _filter)
                    .toList()
              : _wrong.where((q) => q.category == _filter).toList());
    final shown = _sortByCount
        ? ([
            ...base,
          ]..sort((a, b) => (_counts[b.id] ?? 0).compareTo(_counts[a.id] ?? 0)))
        : base;

    return RefreshIndicator(
      color: t.brand,
      backgroundColor: t.surface,
      onRefresh: _reload,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 30),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.gutter,
              18,
              AppTheme.gutter,
              16,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '错题本',
                        style: text.displaySmall?.copyWith(fontSize: 26),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _wrong.isEmpty ? '答错的题会自动收进来' : '${_wrong.length} 题待消灭',
                        style: text.bodySmall?.copyWith(fontSize: 13),
                      ),
                    ],
                  ),
                ),
                if (_wrong.isNotEmpty) ...[
                  // Icon-only: the list itself already says what this page is.
                  _IconAction(
                    icon: AppIcon.replay,
                    tip: '重练当前筛选的题',
                    onTap: () => _practise(shown.take(20).toList()),
                  ),
                  const SizedBox(width: 4),
                  _IconAction(
                    icon: _sortByCount ? AppIcon.chart : AppIcon.timer,
                    tip: _sortByCount ? '当前：错得最多在前' : '当前：最近错的在前',
                    onTap: () => setState(() => _sortByCount = !_sortByCount),
                  ),
                ],
              ],
            ),
          ),
          if (_wrong.isEmpty)
            const EmptyState(
              icon: Icons.verified_outlined,
              title: '还没有错题',
              message: '去练习页刷一组，答错的题会自动进入这里，答对后自动移出。',
            )
          else ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.gutter,
                0,
                AppTheme.gutter,
                12,
              ),
              child: Row(
                children: [
                  _ModeTab(
                    label: '按题型',
                    selected: _mode == 'type',
                    onTap: () => setState(() {
                      _mode = 'type';
                      _filter = 'all';
                    }),
                  ),
                  const SizedBox(width: 16),
                  _ModeTab(
                    label: '按错因',
                    selected: _mode == 'reason',
                    onTap: () => setState(() {
                      _mode = 'reason';
                      _filter = 'all';
                    }),
                  ),
                  const SizedBox(width: 16),
                  _ModeTab(
                    label: '按试卷',
                    selected: _mode == 'paper',
                    onTap: () => setState(() => _mode = 'paper'),
                  ),
                ],
              ),
            ),
            if (_mode == 'paper') ...[
              for (final key in paperKeys) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.gutter,
                    12,
                    AppTheme.gutter,
                    8,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          papers[key]!.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.titleSmall?.copyWith(fontSize: 14.5),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${papers[key]!.items.length} 题',
                        style: text.bodySmall,
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () => _practise(papers[key]!.items),
                        child: Text(
                          '重练',
                          style: text.labelMedium?.copyWith(color: t.brand),
                        ),
                      ),
                    ],
                  ),
                ),
                for (var i = 0; i < papers[key]!.items.length; i++) ...[
                  if (i > 0) const RowDivider(),
                  _WrongRow(
                    question: papers[key]!.items[i],
                    reason: _reasons[papers[key]!.items[i].id],
                    times: _counts[papers[key]!.items[i].id] ?? 1,
                    onTap: () => _practise([papers[key]!.items[i]]),
                    onLong: () => _actions(papers[key]!.items[i]),
                    onRemove: () => _remove(papers[key]!.items[i]),
                  ),
                ],
              ],
            ] else ...[
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.gutter,
                  ),
                  children: [
                    _FilterChip(
                      label: '全部 ${_wrong.length}',
                      selected: _filter == 'all',
                      color: t.brand,
                      onTap: () => setState(() => _filter = 'all'),
                    ),
                    for (final c in kGongkaoCategories)
                      if ((counts[c.key] ?? 0) > 0)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: _FilterChip(
                            label: '${c.short} ${counts[c.key]}',
                            selected: _filter == c.key,
                            color: t.category(c.key),
                            onTap: () => setState(() => _filter = c.key),
                          ),
                        ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              ListView.separated(
                shrinkWrap: true,
                primary: false,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: shown.length,
                separatorBuilder: (_, __) => const RowDivider(),
                itemBuilder: (context, i) => _WrongRow(
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
        ],
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

/// Underlined switch between the two review modes.
class _ModeTab extends StatelessWidget {
  const _ModeTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? t.text : t.muted,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 2,
            width: selected ? 16 : 0,
            decoration: BoxDecoration(
              color: t.brand,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.16) : null,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? color.withValues(alpha: 0.5) : t.line,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            height: 1,
            color: selected ? color : t.textSoft,
            fontFeatures: AppTheme.numeric,
          ),
        ),
      ),
    );
  }
}

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
