import 'package:flutter/material.dart';
import 'package:openexam_app/core/theme/app_theme.dart';
import 'package:openexam_app/core/theme/app_tokens.dart';
import 'package:openexam_app/core/ui/responsive.dart';
import 'package:openexam_app/core/constants/categories.dart';
import 'package:openexam_app/core/ui/stroke_icons.dart';
import 'package:openexam_app/core/ui/ui_kit.dart';
import 'package:openexam_app/data/db/app_database.dart';
import 'package:openexam_app/features/diagnosis/diagnosis_page.dart';
import 'package:openexam_app/data/models/question.dart';
import 'package:openexam_app/features/practice/practice_session_page.dart';

/// 成绩报告 — every finished session, so a 模考 result survives leaving the page.
class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key, this.paperId, this.pageTitle});

  /// When set, only sessions that mostly belong to this paper.
  final String? paperId;
  final String? pageTitle;

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  bool _loading = true;
  List<ExamReport> _reports = const [];

  /// 只看某一类。null 是全部。
  String? _kind;

  /// 当前筛选下要显示的。
  List<ExamReport> get _shown =>
      _kind == null ? _reports : _reports.where((r) => r.kind == _kind).toList();

  /// 有哪几类记录 —— 只列真的存在的，空筛子没意义。
  List<String> get _kinds {
    final seen = <String>[];
    for (final r in _reports) {
      if (!seen.contains(r.kind)) seen.add(r.kind);
    }
    return seen;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final reports = await AppDatabase.instance.listReports(
      paperId: widget.paperId,
    );
    if (!mounted) return;
    setState(() {
      _reports = reports;
      _loading = false;
    });
  }

  /// 没做完的接着做 —— 从停下的那题开始，之前答过的都还在。
  Future<void> _resume(ExamReport report) async {
    final questions =
        await AppDatabase.instance.fetchByIds(report.questionIds);
    if (!mounted || questions.isEmpty) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PracticeSessionPage(
          questions: questions,
          title: report.title,
          startAt: report.cursor.clamp(0, questions.length - 1),
          resumeAnswers: report.answers,
          resumeElapsed: report.elapsed,
          resumeReportId: report.id,
        ),
      ),
    );
    _load();
  }

  Future<void> _review(ExamReport report, {bool wrongOnly = false}) async {
    // 背词记录存的是词，不是题 id，拿去查题库只会一无所获 ——
    // 与其点了没反应，不如说清楚。
    if (report.kind == 'vocab' || report.kind == 'essay') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            report.kind == 'essay' ? '申论记录去申论页看批改' : '背词记录没有题目可以逐题回顾',
          ),
        ),
      );
      return;
    }
    final questions = await AppDatabase.instance.fetchByIds(report.questionIds);
    if (!mounted) return;
    final list = wrongOnly
        ? questions
            .where((q) => report.answers[q.id] != q.answer.toUpperCase())
            .toList()
        : questions;
    if (list.isEmpty) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PracticeSessionPage(
          questions: list,
          reviewAnswers: report.answers,
          title: wrongOnly ? '错题回顾' : '逐题回顾',
        ),
      ),
    );
  }

  /// Pick another report and show a module-by-module diff — the only way to
  /// tell whether a module actually improved or just got easier questions.
  /// 单份卷子的诊断。逐题用时对真题基准，本地就能出结论，AI 只是加一层。
  void _diagnose(ExamReport r) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => DiagnosisPage.report(r)),
    );
  }

  Future<void> _compare(ExamReport a) async {
    final others = _reports.where((r) => r.id != a.id).toList();
    if (others.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('至少要有两份报告才能对比')),
      );
      return;
    }
    final b = await showModalBottomSheet<ExamReport>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _PickReportSheet(reports: others),
    );
    if (b == null || !mounted) return;

    final qa = await AppDatabase.instance.fetchByIds(a.questionIds);
    final qb = await AppDatabase.instance.fetchByIds(b.questionIds);
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CompareSheet(
        newer: a.createdAt.isAfter(b.createdAt) ? a : b,
        older: a.createdAt.isAfter(b.createdAt) ? b : a,
        newerQuestions: a.createdAt.isAfter(b.createdAt) ? qa : qb,
        olderQuestions: a.createdAt.isAfter(b.createdAt) ? qb : qa,
      ),
    );
  }

  Future<void> _delete(ExamReport report) async {
    await AppDatabase.instance.deleteReport(report.id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 21),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        titleSpacing: 0,
        title: Text(widget.pageTitle ?? '练习历史'),
      ),
      body: ReadableWidth(
        maxWidth: context.isExpanded ? 820 : context.readableWidth,
        child: _loading
          ? const LoadingState()
          : _reports.isEmpty
              ? const EmptyState(
                  icon: Icons.assignment_outlined,
                  title: '还没有成绩报告',
                  art: EmptyArt.chart,
                  message: '练习、模考、背词都会记在这里。',
                )
              : ListView(
                  padding: const EdgeInsets.only(top: 6, bottom: 28),
                  children: [
                    if (_kinds.length > 1)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                            AppTheme.gutter, 2, AppTheme.gutter, 8),
                        child: Wrap(
                          spacing: 8,
                          children: [
                            _KindChip(
                              label: '全部',
                              on: _kind == null,
                              onTap: () => setState(() => _kind = null),
                            ),
                            for (final k in _kinds)
                              _KindChip(
                                label: reportKindLabel(k),
                                on: _kind == k,
                                onTap: () => setState(() => _kind = k),
                              ),
                          ],
                        ),
                      ),
                    for (var i = 0; i < _shown.length; i++) ...[
                      if (i > 0) const RowDivider(),
                      Dismissible(
                        key: ValueKey(_shown[i].id),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) => _delete(_shown[i]),
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: AppTheme.gutter),
                          color: t.dangerSoft,
                          child: Text(
                            '删除',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: t.danger,
                            ),
                          ),
                        ),
                        child: _ReportRow(
                          report: _shown[i],
                          onReview: () => _shown[i].done
                              ? _review(_shown[i])
                              : _resume(_shown[i]),
                          onReviewWrong: () => _review(_shown[i], wrongOnly: true),
                          onCompare: () => _compare(_shown[i]),
                          onDiagnose: () => _diagnose(_shown[i]),
                        ),
                      ),
                    ],
                  ],
                ),
      ),
    );
  }
}

/// 记录类型的中文名。练习、模考、背词现在都写进同一张表，
/// 列表上得分得出谁是谁。
String reportKindLabel(String kind) => switch (kind) {
      'exam' => '模考',
      'vocab' => '背词',
      'daily' => '每日一练',
      'essay' => '申论',
      _ => '练习',
    };

class _KindChip extends StatelessWidget {
  const _KindChip({
    required this.label,
    required this.on,
    required this.onTap,
  });

  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
        decoration: BoxDecoration(
          color: on ? t.brand : t.accentSoft,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: on ? t.onAccent : t.onAccentSoft,
          ),
        ),
      ),
    );
  }
}

class _ReportRow extends StatelessWidget {
  const _ReportRow({
    required this.report,
    required this.onReview,
    required this.onReviewWrong,
    required this.onCompare,
    required this.onDiagnose,
  });

  final ExamReport report;
  final VoidCallback onReview;
  final VoidCallback onReviewWrong;
  final VoidCallback onCompare;
  final VoidCallback onDiagnose;

  String get _when {
    final d = report.createdAt;
    final now = DateTime.now();
    final sameDay = d.year == now.year && d.month == now.month && d.day == now.day;
    final hm = '${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}';
    return sameDay ? '今天 $hm' : '${d.month}/${d.day} $hm';
  }

  String get _duration {
    final m = report.elapsed.inMinutes;
    final s = report.elapsed.inSeconds % 60;
    return m > 0 ? '$m 分 $s 秒' : '$s 秒';
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final wrong = report.total - report.correct;
    final ongoing = !report.done;
    final tint = report.rate >= 70
        ? t.success
        : (report.rate >= 50 ? t.category('shuliang') : t.danger);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onReview,
      onLongPress: onCompare,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.gutter, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Score first — it is what you scan the list for.
            SizedBox(
              width: 54,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 没做完的别摆正确率 —— 二十题做了八题，按总题数一算永远
                  // 是个难看的低分，那不是成绩，是还没做完。
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        ongoing
                            ? '${report.answered}'
                            : (report.score != null
                                ? report.score!.round().toString()
                                : '${report.rate}'),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          height: 1,
                          letterSpacing: -0.8,
                          color: ongoing ? t.brand : tint,
                          fontFeatures: AppTheme.numeric,
                        ),
                      ),
                      Text(
                        ongoing
                            ? '/${report.total}'
                            : (report.maxScore != null
                                ? '/${report.maxScore!.round()}'
                                : '%'),
                        style: text.bodySmall?.copyWith(
                          color: ongoing ? t.brand : tint,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    ongoing ? '未做完' : reportKindLabel(report.kind),
                    style: text.bodySmall?.copyWith(
                      fontSize: 11,
                      color: ongoing ? t.brand : null,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleSmall?.copyWith(fontSize: 15),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    ongoing
                        ? '$_when · 停在第 ${report.cursor + 1} 题 · 点开接着做'
                        : (report.score != null
                            ? '$_when · $_duration'
                            : '$_when · 答对 ${report.correct}/${report.total} · $_duration'),
                    style: text.bodySmall,
                  ),
                  if (!ongoing || wrong > 0) ...[
                    const SizedBox(height: 9),
                    Wrap(
                      spacing: 16,
                      runSpacing: 7,
                      children: [
                        if (wrong > 0)
                          _RowLink(
                            icon: AppIcon.wrongBook,
                            label: '看这 $wrong 道错题',
                            onTap: onReviewWrong,
                          ),
                        // 一份成绩单只说了对几道，说不了"时间花在哪、
                        // 哪个模块拖了后腿"—— 那要拿逐题用时去比真题基准。
                        if (!ongoing)
                          _RowLink(
                            icon: AppIcon.chart,
                            label: '诊断这份卷子',
                            onTap: onDiagnose,
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Icon(Icons.chevron_right, size: 17, color: t.muted),
            ),
          ],
        ),
      ),
    );
  }
}

/// Picks the second report for a comparison.
class _PickReportSheet extends StatelessWidget {
  const _PickReportSheet({required this.reports});

  final List<ExamReport> reports;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      decoration: BoxDecoration(
        color: t.gradient.last,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: t.lineSoft)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('和哪一次比', style: text.titleMedium),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: reports.length,
                itemBuilder: (context, i) {
                  final r = reports[i];
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.of(context).pop(r),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 44,
                            child: Text(
                              '${r.rate}%',
                              style: text.titleSmall?.copyWith(
                                fontFeatures: AppTheme.numeric,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              r.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: text.bodyMedium?.copyWith(fontSize: 14),
                            ),
                          ),
                          Text(
                            '${r.createdAt.month}/${r.createdAt.day}',
                            style: text.bodySmall,
                          ),
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

/// Module-by-module diff between two sessions.
class _CompareSheet extends StatelessWidget {
  const _CompareSheet({
    required this.newer,
    required this.older,
    required this.newerQuestions,
    required this.olderQuestions,
  });

  final ExamReport newer;
  final ExamReport older;
  final List<Question> newerQuestions;
  final List<Question> olderQuestions;

  Map<String, ({int right, int total})> _byCategory(
    ExamReport report,
    List<Question> questions,
  ) {
    final out = <String, ({int right, int total})>{};
    for (final q in questions) {
      final prev = out[q.category] ?? (right: 0, total: 0);
      final right = report.answers[q.id] == q.answer.toUpperCase();
      out[q.category] = (
        right: prev.right + (right ? 1 : 0),
        total: prev.total + 1,
      );
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final a = _byCategory(older, olderQuestions);
    final b = _byCategory(newer, newerQuestions);
    final keys = {...a.keys, ...b.keys}.toList();
    final delta = newer.rate - older.rate;

    String pct(({int right, int total})? v) =>
        v == null || v.total == 0 ? '—' : '${(v.right * 100 / v.total).round()}%';

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: t.gradient.last,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: t.lineSoft)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('两次对比', style: text.titleMedium),
            const SizedBox(height: 6),
            Text(
              '${older.createdAt.month}/${older.createdAt.day} → '
              '${newer.createdAt.month}/${newer.createdAt.day}',
              style: text.bodySmall,
            ),
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '${older.rate}%',
                  style: text.titleMedium?.copyWith(color: t.muted),
                ),
                const SizedBox(width: 10),
                Icon(Icons.arrow_forward_rounded, size: 16, color: t.muted),
                const SizedBox(width: 10),
                Text(
                  '${newer.rate}%',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    height: 1,
                    color: t.text,
                    fontFeatures: AppTheme.numeric,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  delta == 0 ? '持平' : (delta > 0 ? '+$delta' : '$delta'),
                  style: text.titleSmall?.copyWith(
                    color: delta > 0
                        ? t.success
                        : (delta < 0 ? t.danger : t.muted),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final key in keys)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          StrokeIcon(
                            categoryIcon(key),
                            size: 17,
                            color: t.category(key),
                          ),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Text(
                              categoryLabel(key),
                              style: text.titleSmall?.copyWith(fontSize: 14.5),
                            ),
                          ),
                          Text(pct(a[key]), style: text.bodySmall),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 13,
                            color: t.muted,
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 46,
                            child: Text(
                              pct(b[key]),
                              textAlign: TextAlign.right,
                              style: text.labelLarge?.copyWith(
                                color: _trend(a[key], b[key], t),
                                fontFeatures: AppTheme.numeric,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '题目不同，比的是各模块的正确率，不是同一批题。',
              style: text.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Color _trend(
    ({int right, int total})? a,
    ({int right, int total})? b,
    dynamic t,
  ) {
    if (a == null || b == null || a.total == 0 || b.total == 0) return t.text;
    final pa = a.right / a.total;
    final pb = b.right / b.total;
    if (pb > pa + 0.02) return t.success;
    if (pb < pa - 0.02) return t.danger;
    return t.text;
  }
}

/// 记录行下面那排小链接。
class _RowLink extends StatelessWidget {
  const _RowLink({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final AppIcon icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          StrokeIcon(icon, size: 14, color: t.brand),
          const SizedBox(width: 6),
          Text(label, style: text.labelMedium?.copyWith(color: t.brand)),
        ],
      ),
    );
  }
}
