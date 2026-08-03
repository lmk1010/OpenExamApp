import 'package:flutter/material.dart';
import 'package:openexam_app/core/theme/app_theme.dart';
import 'package:openexam_app/core/theme/app_tokens.dart';
import 'package:openexam_app/core/ui/stroke_icons.dart';
import 'package:openexam_app/core/ui/ui_kit.dart';
import 'package:openexam_app/data/db/app_database.dart';
import 'package:openexam_app/data/models/question.dart';
import 'package:openexam_app/features/practice/practice_session_page.dart';

/// 成绩报告 — every finished session, so a 模考 result survives leaving the page.
class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  bool _loading = true;
  List<ExamReport> _reports = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final reports = await AppDatabase.instance.listReports();
    if (!mounted) return;
    setState(() {
      _reports = reports;
      _loading = false;
    });
  }

  Future<void> _review(ExamReport report, {bool wrongOnly = false}) async {
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

  Future<void> _delete(ExamReport report) async {
    await AppDatabase.instance.deleteReport(report.id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 21),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        titleSpacing: 0,
        title: const Text('成绩报告'),
      ),
      body: _loading
          ? const LoadingState()
          : _reports.isEmpty
              ? const EmptyState(
                  icon: Icons.assignment_outlined,
                  title: '还没有成绩报告',
                  message: '完成一组 5 题以上的练习或模考后，成绩会保存在这里。',
                )
              : ListView(
                  padding: const EdgeInsets.only(top: 6, bottom: 28),
                  children: [
                    for (var i = 0; i < _reports.length; i++) ...[
                      if (i > 0) const RowDivider(),
                      Dismissible(
                        key: ValueKey(_reports[i].id),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) => _delete(_reports[i]),
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
                          report: _reports[i],
                          onReview: () => _review(_reports[i]),
                          onReviewWrong: () => _review(_reports[i], wrongOnly: true),
                        ),
                      ),
                    ],
                    Padding(
                      padding: const EdgeInsets.fromLTRB(AppTheme.gutter, 20, AppTheme.gutter, 0),
                      child: Text('左滑删除一条记录', style: text.bodySmall),
                    ),
                  ],
                ),
    );
  }
}

class _ReportRow extends StatelessWidget {
  const _ReportRow({
    required this.report,
    required this.onReview,
    required this.onReviewWrong,
  });

  final ExamReport report;
  final VoidCallback onReview;
  final VoidCallback onReviewWrong;

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
    final tint = report.rate >= 70
        ? t.success
        : (report.rate >= 50 ? t.category('shuliang') : t.danger);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onReview,
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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${report.rate}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          height: 1,
                          letterSpacing: -0.8,
                          color: tint,
                          fontFeatures: AppTheme.numeric,
                        ),
                      ),
                      Text('%', style: text.bodySmall?.copyWith(color: tint, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    report.isExam ? '模考' : '练习',
                    style: text.bodySmall?.copyWith(fontSize: 11),
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
                    '$_when · 答对 ${report.correct}/${report.total} · $_duration',
                    style: text.bodySmall,
                  ),
                  if (wrong > 0) ...[
                    const SizedBox(height: 9),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onReviewWrong,
                      child: Row(
                        children: [
                          StrokeIcon(AppIcon.wrongBook, size: 14, color: t.brand),
                          const SizedBox(width: 6),
                          Text(
                            '看这 $wrong 道错题',
                            style: text.labelMedium?.copyWith(color: t.brand),
                          ),
                        ],
                      ),
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
