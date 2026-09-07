import 'package:flutter/material.dart';
import 'package:openexam_app/l10n/app_localizations.dart';
import 'package:openexam_app/core/constants/app_constants.dart';
import 'package:openexam_app/core/theme/app_theme.dart';
import 'package:openexam_app/core/theme/app_tokens.dart';
import 'package:openexam_app/core/ui/stroke_icons.dart';
import 'package:openexam_app/core/ui/ui_kit.dart';
import 'package:openexam_app/data/db/app_database.dart';
import 'package:openexam_app/data/models/question.dart';
import 'package:openexam_app/features/practice/practice_session_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 练习记录 — every day you practised, newest first, with the sessions that
/// made up that day. Reports answer "how did that set go"; this answers
/// "what have I actually been doing".
class TimelinePage extends StatefulWidget {
  const TimelinePage({super.key});

  @override
  State<TimelinePage> createState() => _TimelinePageState();
}

class _TimelinePageState extends State<TimelinePage> {
  bool _loading = true;
  List<DailyStat> _days = const [];
  List<ExamReport> _reports = const [];
  int _goal = 30;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final days = await AppDatabase.instance.dailyStats(days: 60);
    final reports = await AppDatabase.instance.listReports(limit: 200);
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _goal = prefs.getInt(Prefs.dailyGoal) ?? 30;
      _days = days.reversed.where((d) => d.answered > 0).toList();
      _reports = reports;
      _loading = false;
    });
  }

  Future<void> _review(ExamReport report) async {
    final questions = await AppDatabase.instance.fetchByIds(report.questionIds);
    if (!mounted || questions.isEmpty) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PracticeSessionPage(
          questions: questions,
          reviewAnswers: report.answers,
          title: report.title,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 21),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        titleSpacing: 0,
        title: Text(AppL.of(context).timelineTitle),
      ),
      body: _loading
          ? LoadingState()
          : _days.isEmpty
              ? EmptyState(
                  icon: Icons.timeline,
                  title: AppL.of(context).statsNoRecords,
                  art: EmptyArt.chart,
                  message: AppL.of(context).timelineNoneHint,
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.gutter,
                    10,
                    AppTheme.gutter,
                    30,
                  ),
                  itemCount: _days.length,
                  itemBuilder: (context, i) {
                    final day = _days[i];
                    final sessions = _reports
                        .where((r) =>
                            r.createdAt.year == day.date.year &&
                            r.createdAt.month == day.date.month &&
                            r.createdAt.day == day.date.day)
                        .toList();
                    return Reveal(
                      index: i,
                      child: _DayBlock(
                      day: day,
                      sessions: sessions,
                      goal: _goal,
                      isFirst: i == 0,
                      isLast: i == _days.length - 1,
                        onReview: _review,
                      ),
                    );
                  },
                ),
    );
  }
}

class _DayBlock extends StatelessWidget {
  const _DayBlock({
    required this.day,
    required this.sessions,
    required this.goal,
    required this.isFirst,
    required this.isLast,
    required this.onReview,
  });

  final DailyStat day;
  final List<ExamReport> sessions;
  final int goal;
  final bool isFirst;
  final bool isLast;
  final void Function(ExamReport) onReview;

  String _label(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(day.date).inDays;
    if (diff == 0) return AppL.of(context).whenToday;
    if (diff == 1) return AppL.of(context).whenYesterday;
    if (diff < 7) return AppL.of(context).whenDaysAgo(diff);
    return MaterialLocalizations.of(context).formatShortDate(day.date);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final rate = day.answered == 0 ? 0 : (day.correct * 100 / day.answered).round();
    final hit = day.answered >= goal;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The spine: a dot per day, connected top and bottom.
          SizedBox(
            width: 26,
            child: Column(
              children: [
                Container(
                  width: 2,
                  height: isFirst ? 6 : 14,
                  color: isFirst ? Colors.transparent : t.line,
                ),
                Container(
                  width: hit ? 12 : 9,
                  height: hit ? 12 : 9,
                  decoration: BoxDecoration(
                    color: hit ? t.brand : t.muted.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                    border: hit
                        ? Border.all(
                            color: t.brand.withValues(alpha: 0.25),
                            width: 3,
                          )
                        : null,
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: isLast ? Colors.transparent : t.line,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(_label(context), style: text.titleSmall?.copyWith(fontSize: 15)),
                      SizedBox(width: 10),
                      Text(
                        AppL.of(context).timelineDayLine(day.answered, rate),
                        style: text.bodySmall,
                      ),
                      Spacer(),
                      if (hit)
                        Text(
                          AppL.of(context).timelineMetGoal,
                          style: text.bodySmall?.copyWith(color: t.brand),
                        ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  Meter(value: day.accuracy, height: 4),
                  if (sessions.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    for (final s in sessions)
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onReview(s),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              StrokeIcon(
                                s.isExam ? AppIcon.timer : AppIcon.practice,
                                size: 14,
                                color: t.muted,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  s.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: text.bodySmall?.copyWith(fontSize: 12.5),
                                ),
                              ),
                              Text(
                                '${s.correct}/${s.total}',
                                style: text.bodySmall?.copyWith(fontSize: 12.5),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.chevron_right,
                                size: 14,
                                color: t.muted,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
