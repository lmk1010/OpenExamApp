import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:openexam_app/l10n/app_localizations.dart';
import 'package:openexam_app/core/ai/ai_settings.dart';
import 'package:openexam_app/core/theme/app_theme.dart';
import 'package:openexam_app/core/theme/app_tokens.dart';
import 'package:openexam_app/features/ai/ai_settings_page.dart';
import 'package:openexam_app/features/essay/data/essay_grader.dart';
import 'package:openexam_app/data/db/app_database.dart';
import 'package:openexam_app/features/essay/data/essay_repository.dart';
import 'package:openexam_app/features/essay/domain/essay_models.dart';
import 'package:openexam_app/features/essay/presentation/essay_result_page.dart';

/// 作答页：上面材料，下面答题框，顶栏计时。
///
/// 材料和答题区做成可拖的上下分栏 —— 写着写着要回头翻材料，
/// 固定比例总有一边不够用。
class EssayWritePage extends StatefulWidget {
  const EssayWritePage({super.key, required this.prompt});

  final EssayPrompt prompt;

  @override
  State<EssayWritePage> createState() => _EssayWritePageState();
}

class _EssayWritePageState extends State<EssayWritePage> {
  final _answer = TextEditingController();
  Timer? _timer;
  int _seconds = 0;
  bool _grading = false;

  /// 材料区占屏幕的比例，可拖。
  double _split = 0.42;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() => _seconds++),
    );
    _answer.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _answer.dispose();
    super.dispose();
  }

  int get _words => countWords(_answer.text);
  bool get _overLimit =>
      widget.prompt.wordLimit != null && _words > widget.prompt.wordLimit!;

  String get _clock {
    final m = (_seconds ~/ 60).toString().padLeft(2, '0');
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<bool> _confirmExit() async {
    if (_words == 0) return true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppL.of(context).essayQuit),
        content: Text(AppL.of(context).essayQuitBody),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(AppL.of(context).essayKeepWriting)),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(AppL.of(context).commonQuit)),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _submit() async {
    // AI 客户端要一份报错文案，而这里在 await 之后 —— 先取出来。
    final l = AppL.of(context);
    if (_words < 20) {
      _toast(AppL.of(context).essayTooShort);
      return;
    }

    final settings = await AiSettingsStore.load();
    if (!settings.isConfigured) {
      if (!mounted) return;
      final go = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(AppL.of(context).essayNeedAi),
          content: Text(AppL.of(context).essayNeedAiMark),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(AppL.of(context).commonLater)),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(AppL.of(context).scanGoSettings)),
          ],
        ),
      );
      // 不管去不去设置，先把答案落库，别让用户白写
      await _persist(null);
      if (!mounted) return;
      if (go == true) {
        await Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const AiSettingsPage()));
      }
      return;
    }

    setState(() => _grading = true);
    _timer?.cancel();

    final result = await EssayGrader(settings, l)
        .grade(prompt: widget.prompt, answer: _answer.text);
    if (!mounted) return;

    if (!result.isOk) {
      setState(() => _grading = false);
      // 兜底文案要在 await 之前取 —— 存答案之后 context 就跨 await 了。
      final fallback = AppL.of(context).essayMarkFailed;
      // 批改失败也要把答案存住
      await _persist(null);
      _toast(result.error ?? fallback);
      return;
    }

    final attempt = await _persist(result.value);
    if (!mounted) return;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => EssayResultPage(prompt: widget.prompt, attempt: attempt),
      ),
    );
  }

  Future<EssayAttempt> _persist(EssayReview? review) async {
    final attempt = EssayAttempt(
      id: EssayRepository.newId(),
      promptId: widget.prompt.id,
      answer: _answer.text,
      wordCount: _words,
      seconds: _seconds,
      score: review?.score,
      maxScore: review?.maxScore,
      review: review,
      rawReview: review == null ? null : jsonEncode(_reviewToJson(review)),
      createdAt: DateTime.now(),
    );
    await EssayRepository.instance.saveAttempt(attempt);
    await AppDatabase.instance.saveReport(
      title: widget.prompt.title,
      kind: 'essay',
      questionIds: [widget.prompt.id],
      answers: const {},
      correct: 0,
      elapsed: Duration(seconds: _seconds),
      cursor: 1,
      done: true,
      score: review?.score,
      maxScore: review?.maxScore,
    );
    return attempt;
  }

  Map<String, Object?> _reviewToJson(EssayReview r) => {
        'score': r.score,
        'maxScore': r.maxScore,
        'summary': r.summary,
        'improvements': r.improvements,
        'dimensions': [
          for (final d in r.dimensions)
            {'name': d.name, 'score': d.score, 'max': d.max, 'comment': d.comment},
        ],
        'points': [
          for (final p in r.points)
            {'text': p.text, 'hit': p.hit, 'evidence': p.evidence, 'why': p.why},
        ],
      };

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final leave = await _confirmExit();
        if (!leave || !context.mounted) return;
        Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.prompt.title, style: text.titleSmall),
          actions: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(right: 14),
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                decoration: BoxDecoration(
                  color: t.text.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _clock,
                  style: text.titleSmall?.copyWith(
                    fontFeatures: AppTheme.numeric,
                    color: t.text,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: LayoutBuilder(
          builder: (context, box) {
            final materialHeight = box.maxHeight * _split;
            return Column(
              children: [
                SizedBox(
                  height: materialHeight,
                  child: Container(
                    width: double.infinity,
                    color: t.surface,
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(
                        AppTheme.gutter,
                        12,
                        AppTheme.gutter,
                        14,
                      ),
                      children: [
                        Text(AppL.of(context).essaySource,
                            style: text.bodySmall?.copyWith(
                              color: t.muted,
                              letterSpacing: 0.4,
                            )),
                        const SizedBox(height: 8),
                        SelectableText(
                          widget.prompt.material,
                          style: text.bodyMedium?.copyWith(height: 1.9),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: t.brandSoft.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            widget.prompt.requirement,
                            style: text.bodySmall?.copyWith(height: 1.75),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 拖这条改上下比例
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onVerticalDragUpdate: (d) => setState(() {
                    _split = (_split + d.delta.dy / box.maxHeight)
                        .clamp(0.18, 0.70);
                  }),
                  child: Container(
                    height: 18,
                    color: t.bg,
                    alignment: Alignment.center,
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: t.line,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppTheme.gutter,
                      0,
                      AppTheme.gutter,
                      10,
                    ),
                    child: TextField(
                      controller: _answer,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      keyboardType: TextInputType.multiline,
                      style: text.bodyMedium?.copyWith(height: 2.0),
                      decoration: InputDecoration(
                        hintText: AppL.of(context).essayWriteHint,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.only(top: 10),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppTheme.gutter,
              6,
              AppTheme.gutter,
              10,
            ),
            child: Row(
              children: [
                Text(
                  widget.prompt.wordLimit == null
                      ? AppL.of(context).essayWords(_words)
                      : AppL.of(context).essayWordsOfLimit(
                            _words,
                            widget.prompt.wordLimit!,
                          ) +
                          (_overLimit
                              ? AppL.of(context).essayOverLimit
                              : ''),
                  style: text.bodySmall?.copyWith(
                    color: _overLimit ? t.danger : t.muted,
                    fontWeight: _overLimit ? FontWeight.w600 : FontWeight.w500,
                    fontFeatures: AppTheme.numeric,
                  ),
                ),
                Spacer(),
                FilledButton(
                  onPressed: _grading ? null : _submit,
                  child: Text(_grading ? AppL.of(context).essayMarking : AppL.of(context).essaySubmitMark),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
