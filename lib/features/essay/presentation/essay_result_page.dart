import 'package:flutter/material.dart';
import 'package:openexam_app/core/theme/app_theme.dart';
import 'package:openexam_app/core/theme/app_tokens.dart';
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
        appBar: AppBar(title: const Text('作答记录')),
        body: Padding(
          padding: const EdgeInsets.all(AppTheme.gutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('这次没批改成功，答案已经存下来了。', style: text.bodyMedium),
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
      appBar: AppBar(title: const Text('批改结果')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.gutter,
          10,
          AppTheme.gutter,
          40,
        ),
        children: [
          // 分数卡
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            decoration: BoxDecoration(
              color: t.brand.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          review.score?.toStringAsFixed(
                                (review.score ?? 0) % 1 == 0 ? 0 : 1,
                              ) ??
                              '—',
                          style: text.displaySmall?.copyWith(
                            color: t.brand,
                            fontWeight: FontWeight.w700,
                            fontFeatures: AppTheme.numeric,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '/ ${review.maxScore?.toStringAsFixed(0) ?? '—'}',
                          style: text.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                _Stat(label: '要点覆盖', value: '${review.hitRate}%'),
                const SizedBox(width: 18),
                _Stat(label: '字数', value: '${attempt.wordCount}'),
                const SizedBox(width: 18),
                _Stat(label: '用时', value: _clock),
              ],
            ),
          ),

          if (review.summary != null && review.summary!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              decoration: BoxDecoration(
                color: t.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border(left: BorderSide(color: t.brand, width: 3)),
              ),
              child: Text(review.summary!,
                  style: text.bodyMedium?.copyWith(height: 1.85)),
            ),
          ],

          if (review.dimensions.isNotEmpty) ...[
            const SizedBox(height: 26),
            _SectionTitle('分项得分'),
            const SizedBox(height: 12),
            for (final d in review.dimensions) ...[
              _DimensionRow(dimension: d),
              const SizedBox(height: 12),
            ],
          ],

          if (review.points.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                _SectionTitle('采分点逐条对照'),
                const Spacer(),
                if (review.missed.isNotEmpty)
                  Text('漏 ${review.missed.length} 点',
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
            const SizedBox(height: 20),
            _SectionTitle('下次注意'),
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

          const SizedBox(height: 24),
          _SectionTitle('你的答案'),
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
    return Column(
      children: [
        Text(value,
            style: text.titleMedium?.copyWith(
              color: context.tokens.text,
              fontFeatures: AppTheme.numeric,
            )),
        const SizedBox(height: 2),
        Text(label, style: text.bodySmall?.copyWith(fontSize: 10.5)),
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
                color: t.brand,
                fontWeight: FontWeight.w600,
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
            minHeight: 4,
            backgroundColor: t.text.withValues(alpha: 0.07),
            valueColor: AlwaysStoppedAnimation(t.brand),
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
    final tint = point.hit ? t.success : t.danger;

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: point.hit ? t.surface : t.danger.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: point.hit ? t.line : t.danger.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 19,
            height: 19,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
            child: Icon(
              point.hit ? Icons.check_rounded : Icons.close_rounded,
              size: 13,
              color: Colors.white,
            ),
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
                  const SizedBox(height: 5),
                  Text('出处：${point.evidence}',
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
