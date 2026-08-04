import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:openexam_app/core/constants/app_constants.dart';
import 'package:openexam_app/core/constants/categories.dart';
import 'package:openexam_app/core/theme/app_theme.dart';
import 'package:openexam_app/core/theme/app_tokens.dart';
import 'package:openexam_app/core/ui/glass.dart';
import 'package:openexam_app/core/ui/rich_content.dart';
import 'package:openexam_app/core/ui/stroke_icons.dart';
import 'package:openexam_app/core/ui/ui_kit.dart';
import 'package:openexam_app/data/db/app_database.dart';
import 'package:openexam_app/data/models/question.dart';
import 'package:openexam_app/features/achievements/achievements.dart';
import 'package:openexam_app/features/achievements/achievements_page.dart';
import 'package:openexam_app/features/practice/scratch_pad.dart';
import 'package:openexam_app/features/tips/tips_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PracticeSessionPage extends StatefulWidget {
  const PracticeSessionPage({
    super.key,
    required this.questions,
    this.limit,
    this.title,
    this.reviewAnswers,
    this.startAt = 0,
    this.resumeAnswers,
    this.resumeElapsed,
  });

  /// Answers carried over from an interrupted session.
  final Map<String, String>? resumeAnswers;
  final Duration? resumeElapsed;

  /// When set the session opens in review mode: the same question UI, but
  /// answers are already filled in and locked — reading a report should look
  /// like doing the paper, not like a list of letters.
  final Map<String, String>? reviewAnswers;

  /// Which question to open on (review mode jumps straight to a wrong one).
  final int startAt;

  final List<Question> questions;

  /// Mock-exam mode: counts down and hands the paper in automatically.
  final Duration? limit;

  /// Shown next to the counter (e.g. the paper name).
  final String? title;

  @override
  State<PracticeSessionPage> createState() => _PracticeSessionPageState();
}

class _PracticeSessionPageState extends State<PracticeSessionPage> {
  late final PageController _pager = PageController(initialPage: widget.startAt);

  late int _index = widget.startAt;
  final Map<String, String> _answers = {};
  Set<String> _marked = {};
  bool _finished = false;

  final _started = DateTime.now();
  Timer? _ticker;
  Duration _elapsed = Duration.zero;

  /// When the current question came on screen — 行测 lives or dies on pace.
  DateTime _questionShownAt = DateTime.now();
  final Map<String, int> _questionMs = {};

  double _fontScale = 1;
  bool _autoNext = true;

  /// question id -> 错因. Tagging right after answering is the only moment the
  /// reason is still fresh in the user's head.
  Map<String, String> _reasons = {};
  Map<String, int> _difficulty = {};
  Map<String, String> _notes = {};

  /// Scratch work per question, kept for the life of the session.
  final Map<String, List<Stroke>> _scratch = {};

  /// 存疑 — flagged during the run the way a real 答题卡 works: session-scoped,
  /// visible in the card, reviewable after 交卷.
  final Set<String> _doubts = {};

  List<Question> get _questions => widget.questions;
  Question get _current => _questions[_index];
  bool get _isExam => widget.limit != null && !_isReview;
  bool get _isReview => widget.reviewAnswers != null;
  Duration get _left =>
      widget.limit == null ? Duration.zero : widget.limit! - _elapsed;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    if (_isReview) {
      _answers.addAll(widget.reviewAnswers!);
      return;
    }
    if (widget.resumeAnswers != null) _answers.addAll(widget.resumeAnswers!);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _finished) return;
      setState(() => _elapsed =
          DateTime.now().difference(_started) + (widget.resumeElapsed ?? Duration.zero));
      if (_isExam && _left.inSeconds <= 0) _finish();
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _pager.dispose();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final marked = await AppDatabase.instance.markedIds();
    final reasons = await AppDatabase.instance.wrongReasons();
    final notes = await AppDatabase.instance.notes();
    final difficulty = await AppDatabase.instance.difficulties();
    if (!mounted) return;
    setState(() {
      _marked = marked;
      _reasons = reasons;
      _difficulty = difficulty;
      _notes = notes;
      _fontScale = prefs.getDouble(Prefs.fontScale) ?? 1;
      _autoNext = prefs.getBool(Prefs.autoNext) ?? true;
    });
  }

  // ---------------------------------------------------------------- answering

  Future<void> _select(String key) async {
    if (_finished || _isReview) return;
    final q = _current;
    if (_answers.containsKey(q.id)) return;

    final answer = key.toUpperCase();
    final correct = answer == q.answer.toUpperCase();
    final spent = DateTime.now().difference(_questionShownAt).inMilliseconds;
    _questionMs[q.id] = spent;
    setState(() => _answers[q.id] = answer);

    // Physical feedback: a soft tick for right, a heavier bump for wrong.
    if (_isExam) {
      HapticFeedback.selectionClick();
    } else {
      correct ? HapticFeedback.lightImpact() : HapticFeedback.heavyImpact();
    }

    await AppDatabase.instance.logAnswer(
      questionId: q.id,
      userAnswer: answer,
      isCorrect: correct,
      elapsedMs: spent,
    );
    await _snapshot();

    // In a mock exam picking an option IS the action — no confirm step, the
    // paper just advances. In practice mode a wrong answer stops for the
    // explanation; a right one flows on unless the user turned that off.
    final last = _index >= _questions.length - 1;
    if (last) return;
    if (_isExam) {
      await Future<void>.delayed(const Duration(milliseconds: 220));
      if (mounted && !_finished) _next();
    } else if (correct && _autoNext) {
      await Future<void>.delayed(const Duration(milliseconds: 450));
      if (mounted && !_finished) _next();
    }
  }

  void _goTo(int index) {
    if (index < 0 || index >= _questions.length) return;
    _pager.animateToPage(
      index,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  void _next() => _goTo(_index + 1);

  void _finish() {
    _ticker?.cancel();
    if (!mounted || _finished) return;
    setState(() {
      _elapsed = DateTime.now().difference(_started) +
          (widget.resumeElapsed ?? Duration.zero);
      _finished = true;
    });
    HapticFeedback.mediumImpact();
    _saveReport();
    AppDatabase.instance.clearResume();
    _celebrate();
  }

  /// Checks for newly earned badges once the session is over.
  Future<void> _celebrate() async {
    final fresh = await Achievements.claimNew();
    if (!mounted || fresh.isEmpty) return;
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    await BadgeUnlockedDialog.show(context, fresh);
  }

  /// Keeps an up-to-date copy of the session so an accidental exit, a phone
  /// call or a killed app doesn't throw the work away.
  Future<void> _snapshot() async {
    if (_isReview || _finished || _questions.length < 5) return;
    await AppDatabase.instance.saveResume(
      title: widget.title ?? (_isExam ? '限时模考' : '练习 ${_questions.length} 题'),
      questionIds: _questions.map((q) => q.id).toList(),
      answers: _answers,
      index: _index,
      limit: widget.limit,
      elapsed: _elapsed,
    );
  }

  /// Sessions worth revisiting are kept; a two-question retry is not.
  Future<void> _saveReport() async {
    if (_isReview || _answers.isEmpty || _questions.length < 5) return;
    final correct = _questions
        .where((q) => _answers[q.id] == q.answer.toUpperCase())
        .length;
    await AppDatabase.instance.saveReport(
      title: widget.title ?? (_isExam ? '限时模考' : '练习 ${_questions.length} 题'),
      kind: _isExam ? 'exam' : 'practice',
      questionIds: _questions.map((q) => q.id).toList(),
      answers: _answers,
      correct: correct,
      elapsed: _elapsed,
    );
  }

  /// Handing in with blanks left is almost always a slip — confirm first.
  Future<void> _submit() async {
    final blank = _questions.length - _answers.length;
    if (blank > 0) {
      final ok = await _confirm(
        title: '还有 $blank 题没作答',
        message: '交卷后未作答的题会计为错题，确定现在交卷吗？',
        confirm: '仍然交卷',
      );
      if (ok != true) return;
    }
    _finish();
  }

  /// Asks, then closes the session — kept in one place so both the back
  /// gesture and the close button behave identically.
  Future<void> _leave() async {
    if (!await _confirmExit()) return;
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<bool> _confirmExit() async {
    if (_finished || _isReview || _answers.isEmpty) return true;
    final ok = await _confirm(
      title: _isExam ? '退出模考？' : '结束这组练习？',
      message: _isExam
          ? '模考中途退出不会生成成绩报告，已答的题仍计入练习记录。'
          : '已答的 ${_answers.length} 题已经保存，可以随时再来一组。',
      confirm: '退出',
    );
    return ok == true;
  }

  Future<bool?> _confirm({
    required String title,
    required String message,
    required String confirm,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ConfirmSheet(
        title: title,
        message: message,
        confirm: confirm,
      ),
    );
  }

  Future<void> _toggleMark() async {
    final id = _current.id;
    final next = !_marked.contains(id);
    setState(() => next ? _marked.add(id) : _marked.remove(id));
    HapticFeedback.selectionClick();
    await AppDatabase.instance.toggleMark(id, next);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(next ? '已收藏，可在「我的 → 我的收藏」查看' : '已取消收藏'),
        duration: const Duration(milliseconds: 1200),
      ));
  }

  Future<void> _setReason(String questionId, String? reason) async {
    setState(() {
      reason == null ? _reasons.remove(questionId) : _reasons[questionId] = reason;
    });
    HapticFeedback.selectionClick();
    await AppDatabase.instance.setWrongReason(questionId, reason);
  }

  /// 自己标难度：1 简单 / 2 一般 / 3 难。再点一次取消。
  Future<void> _setDifficulty(String questionId, int level) async {
    final next = _difficulty[questionId] == level ? null : level;
    setState(() {
      next == null
          ? _difficulty.remove(questionId)
          : _difficulty[questionId] = next;
    });
    HapticFeedback.selectionClick();
    await AppDatabase.instance.setDifficulty(questionId, next);
  }

  Future<void> _editNote() async {
    final id = _current.id;
    final body = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NoteSheet(current: _notes[id] ?? ''),
    );
    if (body == null || !mounted) return;
    setState(() {
      body.trim().isEmpty ? _notes.remove(id) : _notes[id] = body.trim();
    });
    await AppDatabase.instance.setNote(id, body);
  }

  void _toggleDoubt() {
    final id = _current.id;
    setState(() {
      _doubts.contains(id) ? _doubts.remove(id) : _doubts.add(id);
    });
    HapticFeedback.selectionClick();
  }

  /// Local-only 纠错: no server, but the note is kept and travels with backups.
  Future<void> _reportIssue() async {
    final q = _current;
    final result = await showModalBottomSheet<({String kind, String note})>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _FeedbackSheet(),
    );
    if (result == null) return;
    await AppDatabase.instance.addFeedback(
      questionId: q.id,
      kind: result.kind,
      note: result.note,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(const SnackBar(
        content: Text('已记下，可在「我的 → 纠错记录」里查看'),
        duration: Duration(milliseconds: 1500),
      ));
  }

  Future<void> _openScratch() async {
    final id = _current.id;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ScratchPad(
        strokes: _scratch[id] ?? const [],
        onChanged: (v) => _scratch[id] = v,
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _openAnswerCard() async {
    final target = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _AnswerCard(
        questions: _questions,
        answers: _answers,
        doubts: _doubts,
        current: _index,
        isExam: _isExam,
      ),
    );
    if (target == null || !mounted) return;
    target == -1 ? _submit() : _goTo(target);
  }

  Future<void> _openReadingSettings() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReadingSheet(
        scale: _fontScale,
        autoNext: _autoNext,
        onScale: (v) async {
          setState(() => _fontScale = v);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setDouble(Prefs.fontScale, v);
        },
        onAutoNext: (v) async {
          setState(() => _autoNext = v);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool(Prefs.autoNext, v);
        },
      ),
    );
  }

  String _clock(Duration d) {
    final v = d.isNegative ? Duration.zero : d;
    final m = (v.inMinutes % 60).toString().padLeft(2, '0');
    final s = (v.inSeconds % 60).toString().padLeft(2, '0');
    return v.inHours > 0 ? '${v.inHours}:$m:$s' : '$m:$s';
  }

  // -------------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    if (_finished) return _ResultView(session: this);

    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final total = _questions.length;
    final q = _current;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _leave();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close, size: 21),
            onPressed: _leave,
          ),
          titleSpacing: 0,
          title: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onLongPress: _reportIssue,
            child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${_index + 1}',
                style: text.titleMedium?.copyWith(fontFeatures: AppTheme.numeric),
              ),
              Text(' / $total', style: text.bodySmall),
              const SizedBox(width: 10),
              // Elapsed (practice) or remaining (exam) — pace is the thing
              // 行测 candidates actually lose points to.
              if (!_isReview)
                Text(
                  _isExam ? _clock(_left) : _clock(_elapsed),
                  style: text.bodySmall?.copyWith(
                    color: _isExam && _left.inMinutes < 5 ? t.danger : t.muted,
                    fontFeatures: AppTheme.numeric,
                  ),
                )
              else
                Text('回顾', style: text.bodySmall?.copyWith(color: t.brand)),
              if (widget.title != null) ...[
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    widget.title!,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall,
                  ),
                ),
              ],
            ],
            ),
          ),
          actions: [
            _BarButton(
              icon: _doubts.contains(q.id)
                  ? Icons.flag_rounded
                  : Icons.outlined_flag_rounded,
              color: _doubts.contains(q.id) ? t.category('shuliang') : t.textSoft,
              onTap: _toggleDoubt,
            ),
            _BarButton(
              icon: Icons.calculate_outlined,
              color: (_scratch[q.id]?.isNotEmpty ?? false) ? t.brand : t.textSoft,
              onTap: _openScratch,
            ),
            _BarButton(
              icon: _notes.containsKey(q.id)
                  ? Icons.sticky_note_2
                  : Icons.sticky_note_2_outlined,
              color: _notes.containsKey(q.id) ? t.brand : t.textSoft,
              onTap: _editNote,
            ),
            _BarButton(
              icon: Icons.text_fields_rounded,
              color: t.textSoft,
              onTap: _openReadingSettings,
            ),
            _BarButton(
              icon: _marked.contains(q.id)
                  ? Icons.star_rounded
                  : Icons.star_border_rounded,
              color: _marked.contains(q.id) ? const Color(0xFFE9A400) : t.muted,
              onTap: _toggleMark,
            ),
            // Answer card doubles as the progress readout, so it carries the count.
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _openAnswerCard,
              child: Container(
                height: 30,
                margin: const EdgeInsets.only(right: AppTheme.gutter - 6, left: 2),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: t.brand.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.grid_view_rounded, size: 14, color: t.brand),
                    const SizedBox(width: 6),
                    Text(
                      '${_answers.length}/$total',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: t.brand,
                        fontFeatures: AppTheme.numeric,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(3),
            child: Meter(value: (_index + 1) / total, height: 3),
          ),
        ),
        // Swiping between questions is how every 刷题 app works.
        body: PageView.builder(
          controller: _pager,
          itemCount: total,
          onPageChanged: (i) {
            setState(() {
              _index = i;
              _questionShownAt = DateTime.now();
            });
            _snapshot();
          },
          itemBuilder: (context, i) => _QuestionView(
            question: _questions[i],
            selected: _answers[_questions[i].id],
            isExam: _isExam,
            fontScale: _fontScale,
            isLast: i == total - 1 && !_isReview,
            isReview: _isReview,
            reason: _reasons[_questions[i].id],
            difficulty: _difficulty[_questions[i].id],
            note: _notes[_questions[i].id],
            onReason: (r) => _setReason(_questions[i].id, r),
            onDifficulty: (l) => _setDifficulty(_questions[i].id, l),
            onEditNote: _editNote,
            onSelect: _select,
            onSubmit: _submit,
          ),
        ),
      ),
    );
  }
}

/// One question page: body, options, analysis.
class _QuestionView extends StatelessWidget {
  const _QuestionView({
    required this.question,
    required this.selected,
    required this.isExam,
    required this.fontScale,
    required this.isLast,
    required this.isReview,
    required this.reason,
    required this.difficulty,
    required this.note,
    required this.onReason,
    required this.onDifficulty,
    required this.onEditNote,
    required this.onSelect,
    required this.onSubmit,
  });

  final Question question;
  final String? selected;
  final bool isExam;
  final double fontScale;
  final bool isLast;
  final bool isReview;
  final String? reason;
  final int? difficulty;
  final String? note;
  final ValueChanged<String?> onReason;
  final ValueChanged<int> onDifficulty;
  final VoidCallback onEditNote;
  final ValueChanged<String> onSelect;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final revealed = isReview || (selected != null && !isExam);
    final accent = t.category(question.category);

    return ListView(
      padding: const EdgeInsets.fromLTRB(AppTheme.gutter, 16, AppTheme.gutter, 28),
      children: [
        // What happened last time on this exact question.
        if (!isExam)
          _History(questionId: question.id, answered: selected != null),
        if (isReview && selected == null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              '这道题当时没有作答',
              style: text.bodySmall?.copyWith(color: t.danger),
            ),
          ),
        if (!isExam)
          // Tapping the type opens that module's method cards — the moment you
          // need them is the moment you're stuck on one of its questions.
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => TipsPage(category: question.category),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  StrokeIcon(categoryIcon(question.category), size: 15, color: accent),
                  const SizedBox(width: 6),
                  Text(
                    categoryLabel(question.category),
                    style: text.bodySmall?.copyWith(color: accent),
                  ),
                  if (question.year > 0)
                    Text(' · ${question.year} 年', style: text.bodySmall),
                  const SizedBox(width: 6),
                  Icon(Icons.lightbulb_outline, size: 13, color: t.muted),
                  Text(
                    ' 技巧',
                    style: text.bodySmall?.copyWith(fontSize: 11.5),
                  ),
                ],
              ),
            ),
          ),
        RichContent(
          question.bodyMarkup,
          style: text.bodyLarge?.copyWith(fontSize: 16 * fontScale, height: 1.75),
          maxImageHeight: 360,
        ),
        const SizedBox(height: 22),
        ...question.options.map((opt) {
          final key = opt.key.toUpperCase();
          final chosen = selected == key;
          final isAnswer = key == question.answer.toUpperCase();

          Color badgeBg = t.surfaceAlt;
          Color badgeFg = t.textSoft;
          Color fg = t.text;
          BoxDecoration decoration = GlassDecor.panel(t, radius: 16, raised: false);

          if (isExam && chosen) {
            badgeBg = t.brand;
            badgeFg = Colors.white;
            fg = t.brand;
            decoration = BoxDecoration(
              color: t.brand.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
            );
          } else if (revealed && isAnswer) {
            badgeBg = t.success;
            badgeFg = Colors.white;
            fg = t.success;
            decoration = BoxDecoration(
              color: t.successSoft,
              borderRadius: BorderRadius.circular(16),
            );
          } else if (revealed && chosen) {
            badgeBg = t.danger;
            badgeFg = Colors.white;
            fg = t.danger;
            decoration = BoxDecoration(
              color: t.dangerSoft,
              borderRadius: BorderRadius.circular(16),
            );
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onSelect(opt.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(14, 14, 15, 14),
                decoration: decoration,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: badgeBg, shape: BoxShape.circle),
                      child: Text(
                        key,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          height: 1,
                          color: badgeFg,
                        ),
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: opt.hasImage
                          ? RichContent(
                              opt.html,
                              style: text.bodyLarge?.copyWith(
                                fontSize: 15 * fontScale,
                                height: 1.5,
                                color: fg,
                              ),
                              maxImageHeight: 150,
                            )
                          : Text(
                              opt.text,
                              style: text.bodyLarge?.copyWith(
                                fontSize: 15 * fontScale,
                                height: 1.5,
                                color: fg,
                              ),
                            ),
                    ),
                    if (revealed && isAnswer)
                      Padding(
                        padding: const EdgeInsets.only(left: 8, top: 2),
                        child: Icon(Icons.check_rounded, size: 18, color: t.success),
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
        // Wrong answers get a one-tap 错因 tag; this is what makes the 错题本
        // worth reviewing instead of just a pile of questions.
        if (revealed && selected != null && selected != question.answer.toUpperCase()) ...[
          const SizedBox(height: 6),
          _ReasonPicker(selected: reason, onPick: onReason),
        ],
        if (revealed && question.analysisMarkup.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: GlassDecor.panel(t, radius: 18, raised: false),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb_outline, size: 15, color: t.brand),
                    const SizedBox(width: 6),
                    Text('解析', style: text.labelLarge?.copyWith(color: t.brand)),
                    const Spacer(),
                    Text(
                      '正确答案 ${question.answer.toUpperCase()}',
                      style: text.bodySmall?.copyWith(color: t.success),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                RichContent(
                  question.analysisMarkup,
                  style: text.bodyMedium?.copyWith(
                    fontSize: 14 * fontScale,
                    color: t.textSoft,
                    height: 1.7,
                  ),
                  maxImageHeight: 260,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _DifficultyPicker(level: difficulty, onPick: onDifficulty),
        ] else if (selected == null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              isExam ? '选中即进入下一题 · 左右滑动可回看' : '左右滑动切换题目 · 点图片可放大',
              style: text.bodySmall?.copyWith(fontSize: 12),
            ),
          ),
        if (note != null && (revealed || isReview)) ...[
          const SizedBox(height: 10),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onEditNote,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: t.category('shuliang').withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.sticky_note_2_outlined,
                          size: 15, color: t.category('shuliang')),
                      const SizedBox(width: 6),
                      Text(
                        '我的笔记',
                        style: text.labelLarge?.copyWith(
                          color: t.category('shuliang'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    note!,
                    style: text.bodyMedium?.copyWith(
                      fontSize: 14 * fontScale,
                      color: t.text,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        // Submitting lives on the last page (and in the answer card), not in a
        // bar that eats a strip of every screen.
        if (isLast) ...[
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(onPressed: onSubmit, child: const Text('交卷')),
          ),
        ],
      ],
    );
  }
}

/// Prior attempts at this question, if any.
class _History extends StatelessWidget {
  const _History({required this.questionId, required this.answered});

  final String questionId;

  /// Before answering we only hint that it was missed; afterwards we can name
  /// the option without spoiling anything.
  final bool answered;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return FutureBuilder<List<({String answer, bool correct, DateTime at})>>(
      future: AppDatabase.instance.historyFor(questionId),
      builder: (context, snap) {
        final all = snap.data ?? const <({String answer, bool correct, DateTime at})>[];
        // The current attempt is already logged; drop it here.
        final past = answered && all.isNotEmpty ? all.skip(1).toList() : all;
        if (past.isEmpty) return const SizedBox.shrink();

        final last = past.first;
        final wrongTimes = past.where((e) => !e.correct).length;
        final days = DateTime.now().difference(last.at).inDays;
        final when = days == 0 ? '今天' : (days == 1 ? '昨天' : '$days 天前');

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Icon(
                last.correct ? Icons.history_rounded : Icons.warning_amber_rounded,
                size: 15,
                color: last.correct ? t.muted : t.danger,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  answered
                      ? '$when做过，当时选了 ${last.answer}'
                          '${last.correct ? '（对）' : '（错）'}'
                          '${wrongTimes > 1 ? ' · 一共错过 $wrongTimes 次' : ''}'
                      : (last.correct ? '$when做过，当时做对了' : '$when做错过这道题'),
                  style: text.bodySmall?.copyWith(
                    fontSize: 12.5,
                    color: last.correct ? t.muted : t.danger,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BarButton extends StatelessWidget {
  const _BarButton({required this.icon, required this.color, required this.onTap});

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(width: 38, height: 42, child: Icon(icon, size: 20, color: color)),
    );
  }
}

/// Result view — score, breakdown, wrong list, and what to do next.
class _ResultView extends StatelessWidget {
  const _ResultView({required this.session});

  final _PracticeSessionPageState session;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final questions = session._questions;
    final answers = session._answers;
    final total = questions.length;
    final correct =
        questions.where((q) => answers[q.id] == q.answer.toUpperCase()).length;
    final rate = (correct * 100 / total).round();
    final wrong =
        questions.where((q) => answers[q.id] != q.answer.toUpperCase()).toList();

    final totals = <String, int>{};
    final rights = <String, int>{};
    for (final q in questions) {
      totals[q.category] = (totals[q.category] ?? 0) + 1;
      if (answers[q.id] == q.answer.toUpperCase()) {
        rights[q.category] = (rights[q.category] ?? 0) + 1;
      }
    }
    final byCategory = totals.keys.toList()
      ..sort((a, b) => totals[b]!.compareTo(totals[a]!));

    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false, title: const Text('练习结果')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppTheme.gutter, 8, AppTheme.gutter, 24),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 16, 2, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rate >= 80 ? '状态不错' : (rate >= 60 ? '继续保持' : '再练一组'),
                  style: text.bodySmall?.copyWith(fontSize: 13),
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$rate',
                      style: TextStyle(
                        fontSize: 54,
                        fontWeight: FontWeight.w700,
                        color: t.text,
                        height: 1,
                        letterSpacing: -2,
                        fontFeatures: AppTheme.numeric,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '%',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: t.muted,
                      ),
                    ),
                    const Spacer(),
                    Text('答对 $correct / $total', style: text.bodySmall),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    StrokeIcon(AppIcon.timer, size: 15, color: t.muted),
                    const SizedBox(width: 6),
                    Text('用时 ${session._clock(session._elapsed)}', style: text.bodySmall),
                    const SizedBox(width: 14),
                    StrokeIcon(AppIcon.chart, size: 15, color: t.muted),
                    const SizedBox(width: 6),
                    // Pace is the number 行测 candidates need most.
                    Text(
                      answers.isEmpty
                          ? '每题 —'
                          : '每题 ${(session._questionMs.values.fold<int>(0, (a, b) => a + b) / answers.length / 1000).toStringAsFixed(1)}s',
                      style: text.bodySmall,
                    ),
                    if (answers.length < total) ...[
                      const SizedBox(width: 14),
                      StrokeIcon(AppIcon.wrongBook, size: 15, color: t.muted),
                      const SizedBox(width: 6),
                      Text('未作答 ${total - answers.length}', style: text.bodySmall),
                    ],
                  ],
                ),
                const SizedBox(height: 18),
                Meter(value: correct / total, height: 4),
              ],
            ),
          ),
          const SizedBox(height: 22),
          if (session._doubts.isNotEmpty) ...[
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                final flagged = questions
                    .where((q) => session._doubts.contains(q.id))
                    .toList();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PracticeSessionPage(
                      questions: flagged,
                      reviewAnswers: answers,
                      title: '存疑回顾',
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Row(
                  children: [
                    Icon(Icons.flag_rounded, size: 17, color: t.category('shuliang')),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        '做题时标了 ${session._doubts.length} 道存疑，点开逐题看',
                        style: text.bodyMedium?.copyWith(fontSize: 13.5),
                      ),
                    ),
                    Icon(Icons.chevron_right, size: 17, color: t.muted),
                  ],
                ),
              ),
            ),
          ],
          if (session._questionMs.isNotEmpty) ...[
            Builder(builder: (context) {
              final slow = questions
                  .where((q) => (session._questionMs[q.id] ?? 0) > 90000)
                  .toList();
              if (slow.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StrokeIcon(AppIcon.timer, size: 16, color: t.category('shuliang')),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        '有 ${slow.length} 题超过 90 秒，考场上这类题应该先跳过',
                        style: text.bodyMedium?.copyWith(fontSize: 13.5),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
          if (byCategory.length > 1) ...[
            const SectionHeader(title: '各题型得分'),
            for (final key in byCategory)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 11),
                child: Row(
                  children: [
                    StrokeIcon(categoryIcon(key), size: 18, color: t.category(key)),
                    const SizedBox(width: 12),
                    Expanded(child: Text(categoryLabel(key), style: text.titleSmall)),
                    SizedBox(
                      width: 72,
                      child: Meter(
                        value: (rights[key] ?? 0) / totals[key]!,
                        color: t.category(key),
                        height: 3,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('${rights[key] ?? 0}/${totals[key]}', style: text.bodySmall),
                  ],
                ),
              ),
            const SizedBox(height: 20),
          ],
          if (wrong.isNotEmpty) ...[
            SectionHeader(title: '错题回顾', caption: '${wrong.length} 题 · 点开看原题'),
            for (var i = 0; i < wrong.length; i++) ...[
              if (i > 0) const RowDivider(indent: 0),
              AppRow(
                padding: const EdgeInsets.symmetric(vertical: 14),
                title: wrong[i].content,
                maxLines: 3,
                subtitle:
                    '你的答案 ${answers[wrong[i].id] ?? '未作答'} · 正确答案 ${wrong[i].answer.toUpperCase()}',
                leading: QuestionThumb(
                  markup: wrong[i].bodyMarkup,
                  icon: categoryIcon(wrong[i].category),
                  color: t.danger,
                ),
                // Opens the real question view at this question, not a list row.
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PracticeSessionPage(
                      questions: questions,
                      reviewAnswers: answers,
                      startAt: questions.indexOf(wrong[i]),
                      title: '错题回顾',
                    ),
                  ),
                ),
              ),
            ],
          ] else
            const EmptyState(
              icon: Icons.emoji_events_outlined,
              title: '全部答对',
              message: '这一组没有错题，换个题型继续保持手感。',
            ),
        ],
      ),
      bottomNavigationBar: ActionBar(
        safeBottom: true,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PracticeSessionPage(
                      questions: questions,
                      reviewAnswers: answers,
                      title: '逐题回顾',
                    ),
                  ),
                ),
                child: const Text('逐题回顾'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: wrong.isEmpty
                    ? () => Navigator.of(context).pop()
                    : () => Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => PracticeSessionPage(questions: wrong),
                          ),
                        ),
                child: Text(wrong.isEmpty ? '完成' : '重做错题 ${wrong.length}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Free-text note for one question.
class _NoteSheet extends StatefulWidget {
  const _NoteSheet({required this.current});

  final String current;

  @override
  State<_NoteSheet> createState() => _NoteSheetState();
}

class _NoteSheetState extends State<_NoteSheet> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.current);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: _SheetShell(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('这道题的笔记', style: text.titleMedium),
            const SizedBox(height: 6),
            Text('记方法、坑点、公式 —— 回顾时会显示在解析下面', style: text.bodySmall),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: GlassDecor.panel(t, radius: 14, raised: false),
              child: TextField(
                controller: _controller,
                autofocus: true,
                maxLines: 5,
                minLines: 3,
                style: text.bodyMedium?.copyWith(color: t.text, fontSize: 15),
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: '例如：看到"至少"先想最不利原则',
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (widget.current.isNotEmpty) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(''),
                      child: const Text('删除'),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(_controller.text),
                    child: const Text('保存'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 错因 chips — 粗心 / 不会 / 审题 / 没时间, tapping again clears the tag.
class _ReasonPicker extends StatelessWidget {
  const _ReasonPicker({required this.selected, required this.onPick});

  final String? selected;
  final ValueChanged<String?> onPick;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('这题为什么错？', style: text.bodySmall),
              const SizedBox(width: 8),
              if (selected != null)
                Text(
                  '已标记，可再点一次取消',
                  style: text.bodySmall?.copyWith(fontSize: 11.5, color: t.muted),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final r in kWrongReasons)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onPick(selected == r.key ? null : r.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: selected == r.key
                          ? t.brand.withValues(alpha: 0.15)
                          : t.glass,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selected == r.key
                            ? t.brand.withValues(alpha: 0.55)
                            : Colors.transparent,
                      ),
                    ),
                    child: Text(
                      r.label,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        height: 1,
                        color: selected == r.key ? t.brand : t.textSoft,
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

/// 纠错弹层 — 类型 + 可选说明。
class _FeedbackSheet extends StatefulWidget {
  const _FeedbackSheet();

  @override
  State<_FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends State<_FeedbackSheet> {
  final _note = TextEditingController();
  String _kind = 'answer';

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: _SheetShell(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('这道题有问题', style: text.titleMedium),
            const SizedBox(height: 6),
            Text('记在本机，可在「我的」里查看，也会随备份一起导出', style: text.bodySmall),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final entry in kFeedbackKinds.entries)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => _kind = entry.key),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: _kind == entry.key
                            ? t.brand.withValues(alpha: 0.15)
                            : t.glass,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: _kind == entry.key
                              ? t.brand.withValues(alpha: 0.5)
                              : Colors.transparent,
                        ),
                      ),
                      child: Text(
                        entry.value,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          height: 1,
                          color: _kind == entry.key ? t.brand : t.textSoft,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: GlassDecor.panel(t, radius: 14, raised: false),
              child: TextField(
                controller: _note,
                maxLines: 3,
                minLines: 2,
                style: text.bodyMedium?.copyWith(color: t.text, fontSize: 14.5),
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: '补充两句（选填）',
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('取消'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(
                      (kind: _kind, note: _note.text.trim()),
                    ),
                    child: const Text('记下'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Reading preferences: type size and auto-advance.
class _ReadingSheet extends StatefulWidget {
  const _ReadingSheet({
    required this.scale,
    required this.autoNext,
    required this.onScale,
    required this.onAutoNext,
  });

  final double scale;
  final bool autoNext;
  final ValueChanged<double> onScale;
  final ValueChanged<bool> onAutoNext;

  @override
  State<_ReadingSheet> createState() => _ReadingSheetState();
}

class _ReadingSheetState extends State<_ReadingSheet> {
  late double _scale = widget.scale;
  late bool _auto = widget.autoNext;

  static const _steps = [
    (value: 0.9, label: '小'),
    (value: 1.0, label: '标准'),
    (value: 1.15, label: '大'),
    (value: 1.3, label: '特大'),
  ];

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return _SheetShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('阅读设置', style: text.titleMedium),
          const SizedBox(height: 16),
          Text('题目字号', style: text.bodySmall),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final step in _steps)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: step == _steps.last ? 0 : 9),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        setState(() => _scale = step.value);
                        widget.onScale(step.value);
                        HapticFeedback.selectionClick();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        height: 52,
                        alignment: Alignment.center,
                        decoration: _scale == step.value
                            ? GlassDecor.tinted(t, t.brand, radius: 14, glow: false)
                            : GlassDecor.panel(t, radius: 14, raised: false),
                        child: Text(
                          step.label,
                          style: TextStyle(
                            fontSize: 13 + (step.value - 0.9) * 12,
                            fontWeight: FontWeight.w600,
                            color: _scale == step.value ? Colors.white : t.textSoft,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('答对自动下一题', style: text.titleSmall),
                    const SizedBox(height: 4),
                    Text('答错时仍会停下看解析', style: text.bodySmall),
                  ],
                ),
              ),
              Switch(
                value: _auto,
                onChanged: (v) {
                  setState(() => _auto = v);
                  widget.onAutoNext(v);
                  HapticFeedback.selectionClick();
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('完成'),
            ),
          ),
        ],
      ),
    );
  }
}

/// 答题卡 — jump anywhere, see what's left.
class _AnswerCard extends StatelessWidget {
  const _AnswerCard({
    required this.questions,
    required this.answers,
    required this.doubts,
    required this.current,
    required this.isExam,
  });

  final List<Question> questions;
  final Map<String, String> answers;
  final Set<String> doubts;
  final int current;
  final bool isExam;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final done = answers.length;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.72,
      ),
      decoration: BoxDecoration(
        color: t.gradient.last,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: t.glassBorder)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('答题卡', style: text.titleMedium),
                const SizedBox(width: 10),
                Text('已答 $done / ${questions.length}', style: text.bodySmall),
                const Spacer(),
                if (!isExam) ...[
                  _Legend(color: t.success, label: '对'),
                  const SizedBox(width: 10),
                  _Legend(color: t.danger, label: '错'),
                ] else
                  _Legend(color: t.brand, label: '已答'),
                if (doubts.isNotEmpty) ...[
                  const SizedBox(width: 10),
                  _Legend(color: t.category('shuliang'), label: '存疑'),
                ],
              ],
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (var i = 0; i < questions.length; i++)
                      _CardChip(
                        index: i,
                        question: questions[i],
                        answer: answers[questions[i].id],
                        doubt: doubts.contains(questions[i].id),
                        isCurrent: i == current,
                        isExam: isExam,
                        onTap: () => Navigator.of(context).pop(i),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(-1),
                child: Text(done == questions.length ? '交卷' : '提前交卷'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _CardChip extends StatelessWidget {
  const _CardChip({
    required this.index,
    required this.question,
    required this.answer,
    required this.doubt,
    required this.isCurrent,
    required this.isExam,
    required this.onTap,
  });

  final int index;
  final Question question;
  final String? answer;
  final bool doubt;
  final bool isCurrent;
  final bool isExam;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final answered = answer != null;
    final right = answered && answer == question.answer.toUpperCase();

    Color bg = t.glass;
    Color fg = t.textSoft;
    if (answered) {
      if (isExam) {
        bg = t.brand.withValues(alpha: 0.16);
        fg = t.brand;
      } else if (right) {
        bg = t.success.withValues(alpha: 0.16);
        fg = t.success;
      } else {
        bg = t.danger.withValues(alpha: 0.16);
        fg = t.danger;
      }
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 46,
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: isCurrent ? Border.all(color: t.brand, width: 1.6) : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (doubt)
              Positioned(
                top: 4,
                right: 5,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: t.category('shuliang'),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            Text(
          '${index + 1}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: answered || isCurrent ? FontWeight.w700 : FontWeight.w500,
            color: isCurrent && !answered ? t.brand : fg,
            fontFeatures: AppTheme.numeric,
          ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfirmSheet extends StatelessWidget {
  const _ConfirmSheet({
    required this.title,
    required this.message,
    required this.confirm,
  });

  final String title;
  final String message;
  final String confirm;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    return _SheetShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: text.titleMedium),
          const SizedBox(height: 12),
          Text(message, style: text.bodyMedium),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('取消'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: t.danger),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(confirm),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SheetShell extends StatelessWidget {
  const _SheetShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      decoration: BoxDecoration(
        color: t.gradient.last,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: t.glassBorder)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: SafeArea(top: false, child: child),
    );
  }
}

/// 难度自评：做完一题顺手标一下，以后能单独把「难」的挑出来重练。
class _DifficultyPicker extends StatelessWidget {
  const _DifficultyPicker({required this.level, required this.onPick});

  final int? level;
  final ValueChanged<int> onPick;

  static const _labels = ['简单', '一般', '难'];

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final colors = [t.success, t.category('shuliang'), t.danger];

    return Row(
      children: [
        Text('这题对我', style: text.bodySmall),
        const SizedBox(width: 10),
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) const SizedBox(width: 7),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onPick(i + 1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
              decoration: BoxDecoration(
                color: level == i + 1
                    ? colors[i].withValues(alpha: 0.16)
                    : t.glass,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Text(
                _labels[i],
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  height: 1,
                  color: level == i + 1 ? colors[i] : t.muted,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
