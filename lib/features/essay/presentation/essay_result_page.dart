import 'package:flutter/material.dart';
import 'package:openexam_app/l10n/app_localizations.dart';
import 'package:openexam_app/core/theme/app_theme.dart';
import 'package:openexam_app/core/theme/app_tokens.dart';
import 'package:openexam_app/core/ui/shore.dart';
import 'package:openexam_app/features/essay/domain/essay_models.dart';

/// 批改结果。
///
/// 重点不是那个分数，是「采分点逐条对照」那一段 —— 漏了哪几点、为什么漏。
/// 所以漏点用红底摊开写，命中的收成一行。
class EssayResultPage extends StatelessWidget {
  const EssayResultPage({
    super.key,
    required this.prompt,
    required this.attempt,
  });

  final EssayPrompt prompt;
  final EssayAttempt attempt;

  String get _clock {
    final m = (attempt.seconds ~/ 60).toString().padLeft(2, '0');
    final s = (attempt.seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final review = attempt.review;

    if (review == null) {
      return Scaffold(
        appBar: AppBar(title: Text(AppL.of(context).essayAttempts)),
        body: Padding(
          padding: EdgeInsets.all(AppTheme.gutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppL.of(context).essayNotMarked, style: text.bodyMedium),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: SelectableText(
                    attempt.answer,
                    style: text.bodyMedium?.copyWith(height: 2.0),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(AppL.of(context).essayResult)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.gutter,
          10,
          AppTheme.gutter,
          40,
        ),
        children: [
          // 分数卡：罗盘当主角，三个次要数字排在右边。
          // 上一版一个大数字加三个同样大小的数字并排，四个数字互相抵消。
          Container(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            decoration: BoxDecoration(
              color: t.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: t.shadow,
            ),
            child: Row(
              children: [
                CompassDial(
                  value: (review.maxScore ?? 0) <= 0
                      ? 0
                      : (review.score ?? 0) / review.maxScore!,
                  label: review.score?.toStringAsFixed(
                        (review.score ?? 0) % 1 == 0 ? 0 : 1,
                      ) ??
                      '—',
                  caption: AppL.of(context).essayOutOf(
                    review.maxScore?.toStringAsFixed(0) ?? '—',
                  ),
                  size: 104,
                ),
                SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Stat(label: AppL.of(context).essayPointsCovered, value: '${review.hitRate}%'),
                      SizedBox(height: 12),
                      _Stat(label: AppL.of(context).essayWordCount, value: '${attempt.wordCount}'),
                      SizedBox(height: 12),
                      _Stat(label: AppL.of(context).essayTimeTaken, value: _clock),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (review.summary != null && review.summary!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.fromLTRB(18, 15, 18, 16),
              decoration: BoxDecoration(
                color: t.accentSoft,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(review.summary!,
                  style: text.bodyMedium?.copyWith(height: 1.85)),
            ),
          ],

          if (review.dimensions.isNotEmpty) ...[
            SizedBox(height: 26),
            _SectionTitle(AppL.of(context).essayBreakdown),
            const SizedBox(height: 12),
            for (final d in review.dimensions) ...[
              _DimensionRow(dimension: d),
              const SizedBox(height: 12),
            ],
          ],

          if (review.points.isNotEmpty) ...[
            SizedBox(height: 14),
            Row(
              children: [
                _SectionTitle(AppL.of(context).essayPointByPoint),
                Spacer(),
                if (review.missed.isNotEmpty)
                  Text(AppL.of(context).essayMissedPoints(review.missed.length),
                      style: text.bodySmall?.copyWith(
                        color: t.danger,
                        fontWeight: FontWeight.w600,
                      )),
              ],
            ),
            const SizedBox(height: 12),
            for (final p in review.points) ...[
              _PointRow(point: p),
              const SizedBox(height: 8),
            ],
          ],

          if (review.improvements.isNotEmpty) ...[
            SizedBox(height: 20),
            _SectionTitle(AppL.of(context).essayNextTime),
            const SizedBox(height: 12),
            for (var i = 0; i < review.improvements.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: t.brand.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('${i + 1}',
                          style: text.bodySmall?.copyWith(
                            color: t.brand,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          )),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(review.improvements[i],
                          style: text.bodyMedium?.copyWith(height: 1.8)),
                    ),
                  ],
                ),
              ),
          ],

          SizedBox(height: 24),
          _SectionTitle(AppL.of(context).essayYourAnswer),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: t.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: t.line),
            ),
            child: SelectableText(
              attempt.answer,
              style: text.bodyMedium?.copyWith(height: 2.0),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    // 标签在左、数字在右。竖着排三组的话，罗盘旁边就成了第二个数字阵。
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Expanded(
          child: Text(label, style: text.bodySmall?.copyWith(fontSize: 12.5)),
        ),
        Text(
          value,
          style: text.titleSmall?.copyWith(
            fontSize: 15,
            color: context.tokens.text,
            fontFeatures: AppTheme.numeric,
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(color: context.tokens.text),
      );
}

class _DimensionRow extends StatelessWidget {
  const _DimensionRow({required this.dimension});
  final ScoreDimension dimension;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(dimension.name,
                style: text.bodyMedium?.copyWith(
                  color: t.text,
                  fontWeight: FontWeight.w600,
                )),
            const Spacer(),
            Text(
              '${_fmt(dimension.score)} / ${_fmt(dimension.max)}',
              style: text.bodySmall?.copyWith(
                color: t.textSoft,
                fontWeight: FontWeight.w700,
                fontFeatures: AppTheme.numeric,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: dimension.ratio,
            minHeight: 5,
            backgroundColor: t.text.withValues(alpha: 0.07),
            valueColor: AlwaysStoppedAnimation(t.accent),
          ),
        ),
        if (dimension.comment != null && dimension.comment!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(dimension.comment!,
              style: text.bodySmall?.copyWith(height: 1.65)),
        ],
      ],
    );
  }

  String _fmt(double v) => v % 1 == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
}

class _PointRow extends StatelessWidget {
  const _PointRow({required this.point});
  final ScoringPoint point;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: point.hit ? t.surface : t.dangerSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: point.hit ? t.lineSoft : t.danger.withValues(alpha: 0.30),
          width: 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LifeRing(
            state: point.hit ? LifeRingState.done : LifeRingState.wrong,
            size: 20,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(point.text,
                    style: text.bodyMedium?.copyWith(
                      color: t.text,
                      height: 1.6,
                      fontWeight: FontWeight.w600,
                    )),
                if (point.evidence != null && point.evidence!.isNotEmpty) ...[
                  SizedBox(height: 5),
                  Text(AppL.of(context).essayEvidence(point.evidence ?? ''),
                      style: text.bodySmall?.copyWith(height: 1.65)),
                ],
                // 漏点的原因才是这页最该看的东西，单独框出来
                if (!point.hit && point.why != null && point.why!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: t.bg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(point.why!,
                        style: text.bodySmall?.copyWith(
                          height: 1.75,
                          color: t.text,
                        )),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
