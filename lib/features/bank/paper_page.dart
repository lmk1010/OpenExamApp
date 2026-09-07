import 'package:flutter/material.dart';
import 'package:openexam_app/l10n/app_localizations.dart';
import 'package:openexam_app/core/constants/categories.dart';
import 'package:openexam_app/core/theme/app_theme.dart';
import 'package:openexam_app/core/theme/app_tokens.dart';
import 'package:openexam_app/features/practice/shore_home.dart';
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
        SnackBar(content: Text(AppL.of(context).paperNoQuestions)),
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
        SnackBar(content: Text(AppL.of(context).paperNoQuestions)),
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
          title: title ?? AppL.of(context).paperSkim(widget.title),
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
          icon: Icon(Icons.arrow_back, size: 21),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        titleSpacing: 0,
        title: Text(AppL.of(context).bankPapers),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ReportsPage(
                  paperId: widget.paperId,
                  pageTitle: AppL.of(context).paperHistory,
                ),
              ),
            ),
            child: Text(AppL.of(context).paperHistoryShort),
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
                  padding: EdgeInsets.fromLTRB(
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
                                      pageTitle: AppL.of(context).paperHistory,
                                    ),
                                  ),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.only(left: 8),
                                  child: Text(
                                    AppL.of(context).paperHistoryShort,
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
                        // 前缀和后缀都是可选的，在 Dart 里拼。
                        (widget.year > 0
                                ? AppL.of(context)
                                    .paperYearPrefix('${widget.year}')
                                : '') +
                            AppL.of(context).countQuestions(widget.total) +
                            (done > 0
                                ? AppL.of(context).paperDoneSuffix(done, rate)
                                : ''),
                        style: text.bodySmall?.copyWith(fontSize: 13),
                      ),
                      SizedBox(height: 14),
                      Meter(value: widget.total == 0 ? 0 : done / widget.total, height: 4),
                    ],
                  ),
                ),
                // Four ways into the paper: timed run, continue, wrongs, browse.
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppTheme.gutter),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _Action(
                            icon: AppIcon.timer,
                            label: AppL.of(context).paperFullMock,
                            meta: AppL.of(context).paperMockMinutes,
                            primary: true,
                            onTap: () async {
                              final all = await AppDatabase.instance
                                  .fetchByPaper(widget.paperId);
                              await _run(all, limit: const Duration(minutes: 120));
                            },
                          ),
                          SizedBox(width: 10),
                          _Action(
                            icon: AppIcon.practice,
                            label: AppL.of(context).paperResume,
                            meta: _unanswered == 0 ? AppL.of(context).paperAllDone : AppL.of(context).countQuestions(_unanswered),
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
                      SizedBox(height: 10),
                      Row(
                        children: [
                          _Action(
                            icon: AppIcon.wrongBook,
                            label: AppL.of(context).paperWrong,
                            meta: _wrong == 0 ? AppL.of(context).commonNone : AppL.of(context).countQuestions(_wrong),
                            enabled: _wrong > 0,
                            onTap: () async {
                              final wrong = await AppDatabase.instance
                                  .fetchWrongByPaper(widget.paperId);
                              await _run(wrong);
                            },
                          ),
                          SizedBox(width: 10),
                          _Action(
                            icon: AppIcon.papers,
                            label: AppL.of(context).paperSkimAnswers,
                            meta: AppL.of(context).paperAllAnalysis,
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
                SizedBox(height: 28),
                ShoreSection(
                  title: AppL.of(context).paperModules,
                  caption: AppL.of(context).paperModulesHint,
                  child: ShoreCard(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(children: [
                for (var i = 0; i < _stats.length; i++) ...[
                  if (i > 0) const RowDivider(),
                  _ModuleRow(
                    stat: _stats[i],
                    onTap: () async {
                      // 标题在 await 之后才用，先取出来。
                      final title = AppL.of(context).paperModuleYear(
                        categoryLabel(_stats[i].category),
                        '${widget.year}',
                      );
                      final list = await AppDatabase.instance.fetchByPaperCategory(
                        widget.paperId,
                        _stats[i].category,
                      );
                      await _run(list, title: title);
                    },
                    onLongPress: () async {
                      final title = AppL.of(context)
                          .paperSkim(categoryLabel(_stats[i].category));
                      final list = await AppDatabase.instance.fetchByPaperCategory(
                        widget.paperId,
                        _stats[i].category,
                      );
                      await _browse(list, title: title);
                    },
                  ),
                ],
                if (_stats.isEmpty)
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      AppL.of(context).paperNoTypes,
                      style: text.bodySmall,
                    ),
                  ),
                    ]),
                  ),
                ),
                SizedBox(height: 24),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppTheme.gutter),
                  child: Text(
                    done == 0
                        ? AppL.of(context).paperTipModules
                        : AppL.of(context).paperTipMock,
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
    final on = enabled ? (primary ? t.onAccent : t.text) : t.muted;

    return Expanded(
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: enabled ? onTap : null,
          child: Container(
            padding: const EdgeInsets.fromLTRB(13, 13, 13, 13),
            decoration: primary
                ? BoxDecoration(
                    color: t.accent,
                    borderRadius: BorderRadius.circular(20),
                  )
                : BoxDecoration(
                    color: t.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: t.shadow,
                  ),
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
                    color: primary ? t.onAccent.withValues(alpha: 0.72) : t.muted,
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
            SizedBox(width: 12),
            SizedBox(
              width: 58,
              child: Text(
                started ? '${stat.done}/${stat.total}' : AppL.of(context).countQuestions(stat.total),
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
