import 'package:flutter/material.dart';
import 'package:openexam_app/core/constants/categories.dart';
import 'package:openexam_app/core/theme/app_theme.dart';
import 'package:openexam_app/core/theme/app_tokens.dart';
import 'package:openexam_app/core/ui/glass.dart';
import 'package:openexam_app/core/ui/stroke_icons.dart';
import 'package:openexam_app/core/ui/ui_kit.dart';
import 'package:openexam_app/data/db/app_database.dart';
import 'package:openexam_app/data/models/question.dart';
import 'package:openexam_app/features/practice/practice_session_page.dart';
import 'package:openexam_app/features/reports/reports_page.dart';

/// 试卷详情 — the fix for the "专项题库是一锅大杂烩" complaint: inside one real
/// paper you can see the module split and practise a module, the blanks, or the
/// wrong ones, instead of only being able to run the whole 130-question exam.
class PaperPage extends StatefulWidget {
  const PaperPage({
    super.key,
    required this.paperId,
    required this.title,
    required this.year,
    required this.total,
    this.embedded = false,
  });

  /// 嵌在宽屏分栏右侧时不画自己的顶栏 —— 左边的列表还在，没有「返回」可言。

  final String paperId;
  final String title;
  final int year;
  final int total;
  final bool embedded;

  @override
  State<PaperPage> createState() => _PaperPageState();
}

class _PaperPageState extends State<PaperPage> {
  bool _loading = true;
  List<CategoryStat> _stats = const [];
  int _wrong = 0;
  int _unanswered = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = AppDatabase.instance;
    final stats = await db.paperCategoryStats(widget.paperId);
    final wrong = await db.countWrongByPaper(widget.paperId);
    final unanswered = await db.countUnansweredByPaper(widget.paperId);
    if (!mounted) return;
    setState(() {
      _stats = stats;
      _wrong = wrong;
      _unanswered = unanswered;
      _loading = false;
    });
  }

  Future<void> _run(
    List<Question> questions, {
    Duration? limit,
    String? title,
  }) async {
    if (!mounted) return;
    if (questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('这里没有题目')),
      );
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PracticeSessionPage(
          questions: questions,
          limit: limit,
          title: title ?? widget.title,
        ),
      ),
    );
    _load();
  }

  /// 整卷/模块速览：答案已填、整卷滚动，不用先做一遍。
  Future<void> _browse(List<Question> questions, {String? title}) async {
    if (!mounted) return;
    if (questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('这里没有题目')),
      );
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PracticeSessionPage(
          questions: questions,
          preferScroll: true,
          reviewAnswers: {
            for (final q in questions) q.id: q.answer.trim().toUpperCase(),
          },
          title: title ?? '速览 · ${widget.title}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final done = _stats.fold<int>(0, (s, e) => s + e.done);
    final correct = _stats.fold<int>(0, (s, e) => s + e.correct);
    final rate = done == 0 ? 0 : (correct * 100 / done).round();

    if (widget.embedded) {
      return _loading ? const LoadingState() : _content(context, done, correct, rate);
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 21),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        titleSpacing: 0,
        title: const Text('试卷'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ReportsPage(
                  paperId: widget.paperId,
                  pageTitle: '本卷历史',
                ),
              ),
            ),
            child: const Text('历史'),
          ),
        ],
      ),
      body: _loading
          ? const LoadingState()
          : _content(context, done, correct, rate),
    );
  }

  Widget _content(BuildContext context, int done, int correct, int rate) {
    final text = Theme.of(context).textTheme;
    return ListView(
              padding: const EdgeInsets.only(bottom: 30),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.gutter,
                    18,
                    AppTheme.gutter,
                    14,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 36,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                widget.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: text.displaySmall?.copyWith(
                                  fontSize: 26,
                                  height: 1,
                                ),
                              ),
                            ),
                            if (widget.embedded)
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ReportsPage(
                                      paperId: widget.paperId,
                                      pageTitle: '本卷历史',
                                    ),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: Text(
                                    '历史',
                                    style: text.labelMedium?.copyWith(
                                      color: context.tokens.brand,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 9),
                      Text(
                        '${widget.year > 0 ? '${widget.year} 年 · ' : ''}'
                        '${widget.total} 题'
                        '${done > 0 ? ' · 已练 $done · 正确率 $rate%' : ''}',
                        style: text.bodySmall?.copyWith(fontSize: 13),
                      ),
                      const SizedBox(height: 14),
                      Meter(value: widget.total == 0 ? 0 : done / widget.total, height: 4),
                    ],
                  ),
                ),
                // Four ways into the paper: timed run, continue, wrongs, browse.
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.gutter),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _Action(
                            icon: AppIcon.timer,
                            label: '整卷模考',
                            meta: '120 分钟',
                            primary: true,
                            onTap: () async {
                              final all = await AppDatabase.instance
                                  .fetchByPaper(widget.paperId);
                              await _run(all, limit: const Duration(minutes: 120));
                            },
                          ),
                          const SizedBox(width: 10),
                          _Action(
                            icon: AppIcon.practice,
                            label: '继续未做',
                            meta: _unanswered == 0 ? '已做完' : '$_unanswered 题',
                            enabled: _unanswered > 0,
                            onTap: () async {
                              final blank =
                                  await AppDatabase.instance.fetchByPaperCategory(
                                widget.paperId,
                                null,
                                onlyUnanswered: true,
                              );
                              await _run(blank);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _Action(
                            icon: AppIcon.wrongBook,
                            label: '本卷错题',
                            meta: _wrong == 0 ? '暂无' : '$_wrong 题',
                            enabled: _wrong > 0,
                            onTap: () async {
                              final wrong = await AppDatabase.instance
                                  .fetchWrongByPaper(widget.paperId);
                              await _run(wrong);
                            },
                          ),
                          const SizedBox(width: 10),
                          _Action(
                            icon: AppIcon.papers,
                            label: '速览答案',
                            meta: '整卷解析',
                            onTap: () async {
                              final all = await AppDatabase.instance
                                  .fetchByPaper(widget.paperId);
                              await _browse(all);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                const SectionHeader(title: '模块构成', caption: '点一行只练这一模块 · 长按速览'),
                for (var i = 0; i < _stats.length; i++) ...[
                  if (i > 0) const RowDivider(),
                  _ModuleRow(
                    stat: _stats[i],
                    onTap: () async {
                      final list = await AppDatabase.instance.fetchByPaperCategory(
                        widget.paperId,
                        _stats[i].category,
                      );
                      await _run(
                        list,
                        title: '${categoryLabel(_stats[i].category)} · ${widget.year} 年',
                      );
                    },
                    onLongPress: () async {
                      final list = await AppDatabase.instance.fetchByPaperCategory(
                        widget.paperId,
                        _stats[i].category,
                      );
                      await _browse(
                        list,
                        title: '速览 · ${categoryLabel(_stats[i].category)}',
                      );
                    },
                  ),
                ],
                if (_stats.isEmpty)
                  const EmptyState(
                    icon: Icons.inbox_outlined,
                    title: '这套卷子还没有题目',
                    message: '导入的题目缺少题型标注时会出现这种情况。',
                  ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.gutter),
                  child: Text(
                    done == 0
                        ? '建议先按模块练，熟悉题型后再整卷限时。'
                        : '整卷模考按 120 分钟计时，中途可用答题卡跳题。',
                    style: text.bodySmall,
                  ),
                ),
              ],
            );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.label,
    required this.meta,
    required this.onTap,
    this.primary = false,
    this.enabled = true,
  });

  final AppIcon icon;
  final String label;
  final String meta;
  final VoidCallback onTap;
  final bool primary;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final on = enabled
        ? (primary ? GlassDecor.on(t.brand) : t.text)
        : t.muted;

    return Expanded(
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: enabled ? onTap : null,
          child: Container(
            padding: const EdgeInsets.fromLTRB(13, 13, 13, 13),
            decoration: primary
                ? GlassDecor.tinted(t, t.brand, radius: 18)
                : GlassDecor.panel(t, radius: 18, raised: false),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StrokeIcon(icon, size: 18, color: on),
                const SizedBox(height: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1,
                    color: on,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  meta,
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1,
                    color: primary ? on.withValues(alpha: 0.78) : t.muted,
                    fontFeatures: AppTheme.numeric,
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

class _ModuleRow extends StatelessWidget {
  const _ModuleRow({
    required this.stat,
    required this.onTap,
    this.onLongPress,
  });

  final CategoryStat stat;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final color = t.category(stat.category);
    final started = stat.done > 0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.gutter, vertical: 15),
        child: Row(
          children: [
            StrokeIcon(categoryIcon(stat.category), size: 20, color: color),
            const SizedBox(width: 14),
            SizedBox(
              width: 76,
              child: Text(
                categoryLabel(stat.category),
                style: text.titleSmall?.copyWith(fontSize: 15.5),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Meter(
                value: stat.total == 0 ? 0 : stat.done / stat.total,
                color: color,
                height: 4,
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 58,
              child: Text(
                started ? '${stat.done}/${stat.total}' : '${stat.total} 题',
                textAlign: TextAlign.right,
                style: text.bodySmall,
              ),
            ),
            SizedBox(
              width: 44,
              child: Text(
                started ? '${(stat.accuracy * 100).round()}%' : '',
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
