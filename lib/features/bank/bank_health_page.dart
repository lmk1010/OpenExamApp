import 'package:flutter/material.dart';
import 'package:openexam_app/l10n/app_localizations.dart';
import 'package:openexam_app/core/constants/categories.dart';
import 'package:openexam_app/core/theme/app_theme.dart';
import 'package:openexam_app/core/theme/app_tokens.dart';
import 'package:openexam_app/core/ui/ambient.dart';
import 'package:openexam_app/core/ui/responsive.dart';
import 'package:openexam_app/core/ui/ui_kit.dart';
import 'package:openexam_app/data/db/app_database.dart';
import 'package:openexam_app/data/models/question.dart';

/// 题库体检。
///
/// 原来这一页摆的是覆盖矩阵、年份分布、抽样对标清单 —— 数据是真的，但看完
/// 也不知道该干什么。现在只回答两个问题：**有多少题**、**哪些题有毛病**，
/// 而且每条毛病都能在这一页当场解决，不用记下题号再去别处找。
class BankHealthPage extends StatefulWidget {
  const BankHealthPage({super.key});

  @override
  State<BankHealthPage> createState() => _BankHealthPageState();
}

class _BankHealthPageState extends State<BankHealthPage> {
  bool _loading = true;
  List<CategoryStat> _stats = const [];
  List<Question> _noAnswer = const [];
  List<Question> _broken = const [];
  List<List<Question>> _dupes = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      AppDatabase.instance.categoryStats(),
      AppDatabase.instance.questionsMissingAnswer(),
      AppDatabase.instance.questionsBrokenOptions(),
      AppDatabase.instance.duplicateQuestions(),
    ]);
    if (!mounted) return;
    setState(() {
      _stats = (results[0] as List<CategoryStat>)
          .where((s) => s.total > 0)
          .toList();
      _noAnswer = results[1] as List<Question>;
      _broken = results[2] as List<Question>;
      _dupes = results[3] as List<List<Question>>;
      _loading = false;
    });
  }

  int get _total => _stats.fold(0, (sum, s) => sum + s.total);
  int get _problems =>
      _noAnswer.length + _broken.length + _dupes.length;

  /// 就地补答案。补完这道题立刻从列表里消失 —— 修好了就该看不见。
  Future<void> _fixAnswer(Question q) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _AnswerSheet(question: q),
    );
    if (picked == null || picked.isEmpty) return;
    await AppDatabase.instance.setQuestionAnswer(q.id, picked);
    await _load();
  }

  Future<void> _delete(Question q) async {
    await AppDatabase.instance.deleteQuestion(q.id);
    await _load();
  }

  /// 一组重复里只留第一道，其余删掉。同卷重复才会进到这里 —— 跨卷共用的题
  /// （联考各省同题、国考三卷同题）本来就该各卷都有一份，不算毛病。
  Future<void> _dedupe(List<Question> group) async {
    await AppDatabase.instance
        .deleteQuestions(group.skip(1).map((q) => q.id).toList());
    await _load();
  }

  Future<void> _dedupeAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppL.of(context).healthCleanAll),
        content: Text(AppL.of(context).healthCleanAllBody(_dupes.length, _dupes.fold<int>(0, (s, g) => s + g.length - 1))),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(AppL.of(context).commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(AppL.of(context).healthClean),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final ids = <String>[];
    for (final g in _dupes) {
      ids.addAll(g.skip(1).map((q) => q.id));
    }
    await AppDatabase.instance.deleteQuestions(ids);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: t.gradient.last,
      body: SafeArea(
        child: ReadableWidth(
          child: _loading
              ? LoadingState()
              : ListView(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.paddingOf(context).bottom + 28,
                  ),
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                          AppTheme.gutter, 8, AppTheme.gutter, 10),
                      child: Row(
                        children: [
                          PlainIconButton(
                            icon: Icons.arrow_back,
                            onTap: () => Navigator.of(context).maybePop(),
                          ),
                          SizedBox(width: 4),
                          // 标题占满剩下的宽度并截断 —— 英文标题比中文长，320 宽的屏上
                          // 顶死会把返回键那一行撑出黄黑条（见 i18n_layout_test）。
                          Expanded(
                            child: Text(
                              AppL.of(context).healthTitle,
                              style: text.titleMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: AppTheme.gutter),
                      child: _Summary(
                        total: _total,
                        problems: _problems,
                        categories: _stats.length,
                      ),
                    ),

                    if (_problems == 0) ...[
                      SizedBox(height: 26),
                      EmptyState(
                        icon: Icons.verified_outlined,
                        title: _total == 0 ? AppL.of(context).cmEmptyTitle : AppL.of(context).healthAllGood,
                        message: _total == 0
                            ? AppL.of(context).healthEmptyBody
                            : AppL.of(context).healthAllGoodBody,
                      ),
                    ],

                    if (_noAnswer.isNotEmpty) ...[
                      SizedBox(height: 22),
                      SectionHeader(
                        title: AppL.of(context).healthNoAnswer,
                        caption: AppL.of(context).healthNoAnswerCount(_noAnswer.length),
                      ),
                      for (final q in _noAnswer.take(50))
                        _ProblemRow(
                          question: q,
                          actionLabel: AppL.of(context).healthFillAnswer,
                          onAction: () => _fixAnswer(q),
                          onDelete: () => _delete(q),
                        ),
                      if (_noAnswer.length > 50)
                        _More(n: _noAnswer.length - 50),
                    ],

                    if (_broken.isNotEmpty) ...[
                      SizedBox(height: 22),
                      SectionHeader(
                        title: AppL.of(context).healthBrokenOptions,
                        caption: AppL.of(context).healthBrokenCount(_broken.length),
                      ),
                      for (final q in _broken.take(50))
                        _ProblemRow(
                          question: q,
                          onDelete: () => _delete(q),
                        ),
                      if (_broken.length > 50) _More(n: _broken.length - 50),
                    ],

                    if (_dupes.isNotEmpty) ...[
                      SizedBox(height: 22),
                      SectionHeader(
                        title: AppL.of(context).healthDupes,
                        caption: AppL.of(context).healthDupesCount(_dupes.length),
                        trailing: AppL.of(context).healthCleanAllShort,
                        onTapTrailing: _dedupeAll,
                      ),
                      for (final g in _dupes.take(30))
                        _ProblemRow(
                          question: g.first,
                          badge: AppL.of(context).healthCopies(g.length),
                          actionLabel: AppL.of(context).healthKeepOne,
                          onAction: () => _dedupe(g),
                        ),
                      if (_dupes.length > 30) _More(n: _dupes.length - 30),
                    ],

                    if (_stats.isNotEmpty) ...[
                      const SizedBox(height: 26),
                      SectionHeader(title: AppL.of(context).healthByCategory),
                      for (final s in _stats)
                        _CategoryBar(
                          stat: s,
                          ratio: _stats.first.total == 0
                              ? 0
                              : s.total / _stats.first.total,
                        ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({
    required this.total,
    required this.problems,
    required this.categories,
  });

  final int total;
  final int problems;
  final int categories;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return Container(
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: t.shadow,
      ),
      child: Row(
        children: [
          _Figure(value: '$total', label: AppL.of(context).healthUnitQuestions),
          _Figure(value: '$categories', label: AppL.of(context).healthUnitCategories),
          _Figure(
            value: '$problems',
            label: AppL.of(context).healthUnitProblems,
            tint: problems == 0 ? t.success : t.danger,
          ),
        ],
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({required this.value, required this.label, this.tint});

  final String value;
  final String label;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              height: 1.1,
              letterSpacing: -0.6,
              color: tint ?? t.text,
              fontFeatures: AppTheme.numeric,
            ),
          ),
          const SizedBox(height: 3),
          Text(label, style: text.bodySmall?.copyWith(color: t.textSoft)),
        ],
      ),
    );
  }
}

class _More extends StatelessWidget {
  const _More({required this.n});

  final int n;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: EdgeInsets.fromLTRB(AppTheme.gutter, 8, AppTheme.gutter, 0),
      child: Text(
        AppL.of(context).healthMore(n),
        style: Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(color: t.textSoft),
      ),
    );
  }
}

/// 一条有毛病的题：题干两行 + 一个能当场解决它的按钮。
class _ProblemRow extends StatelessWidget {
  const _ProblemRow({
    required this.question,
    this.badge,
    this.actionLabel,
    this.onAction,
    this.onDelete,
  });

  final Question question;
  final String? badge;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: AppTheme.gutter, vertical: 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question.content.trim().isEmpty ? AppL.of(context).healthEmptyStem : question.content,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: text.bodyLarge?.copyWith(fontSize: 14.5, height: 1.45),
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              if (question.category.isNotEmpty)
                Text(
                  CategoryRegistry.metaFor(question.category).label,
                  style: text.bodySmall
                      ?.copyWith(color: t.category(question.category)),
                ),
              if (badge != null) ...[
                const SizedBox(width: 8),
                Text(badge!,
                    style: text.bodySmall?.copyWith(color: t.danger)),
              ],
              Spacer(),
              if (onDelete != null)
                TextButton(
                  onPressed: onDelete,
                  child: Text(AppL.of(context).healthDelete,
                      style: text.labelMedium?.copyWith(color: t.textSoft)),
                ),
              if (actionLabel != null && onAction != null)
                TextButton(
                  onPressed: onAction,
                  child: Text(actionLabel!,
                      style: text.labelMedium?.copyWith(color: t.brand)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({required this.stat, required this.ratio});

  final CategoryStat stat;
  final double ratio;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final color = t.category(stat.category);

    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: AppTheme.gutter, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  CategoryRegistry.metaFor(stat.category).label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.titleSmall?.copyWith(fontSize: 14),
                ),
              ),
              Text('${stat.total}',
                  style: text.bodyMedium?.copyWith(
                    color: t.textSoft,
                    fontFeatures: AppTheme.numeric,
                  )),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: ratio.clamp(0.0, 1.0),
              minHeight: 4,
              backgroundColor: t.lineSoft,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// 补答案：把这道题的选项列出来，点一个就是答案。
///
/// 让人手打字母是没必要的 —— 选项就在眼前，而且手打还会打错大小写。
class _AnswerSheet extends StatelessWidget {
  const _AnswerSheet({required this.question});

  final Question question;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.8,
      ),
      decoration: BoxDecoration(
        color: t.gradient.last,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: t.lineSoft)),
      ),
      padding: EdgeInsets.fromLTRB(20, 18, 20, 10),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppL.of(context).healthWhichAnswer, style: text.titleMedium),
              const SizedBox(height: 10),
              Text(
                question.content,
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
                style: text.bodyMedium?.copyWith(height: 1.6),
              ),
              const SizedBox(height: 16),
              for (final o in question.options)
                InkWell(
                  onTap: () => Navigator.of(context).pop(o.key),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    child: Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: t.accentSoft,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Text(
                            o.key,
                            style: text.titleSmall
                                ?.copyWith(color: t.onAccentSoft),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(o.text,
                              style: text.bodyMedium?.copyWith(height: 1.5)),
                        ),
                      ],
                    ),
                  ),
                ),
              SizedBox(height: 6),
              Text(
                AppL.of(context).healthWhichAnswerHint,
                style: text.bodySmall?.copyWith(color: t.textSoft),
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }
}
