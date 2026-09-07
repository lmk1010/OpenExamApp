import 'package:flutter/material.dart';
import 'package:openexam_app/l10n/app_localizations.dart';
import 'package:openexam_app/core/theme/app_theme.dart';
import 'package:openexam_app/core/theme/app_tokens.dart';
import 'package:openexam_app/core/ui/ambient.dart';
import 'package:openexam_app/core/ui/responsive.dart';
import 'package:openexam_app/core/ui/ui_kit.dart';
import 'package:openexam_app/data/db/app_database.dart';
import 'package:openexam_app/data/models/question.dart';

/// AI 用量。
///
/// key 是用户自己的，花的是他自己的钱。花在哪、花了多少，应该在 app 里看得见，
/// 而不是只能去服务商后台对账 —— 尤其"导一本书"这种一次几十万 token 的操作，
/// 事前没个数，事后容易吓一跳。
class AiUsagePage extends StatefulWidget {
  const AiUsagePage({super.key});

  @override
  State<AiUsagePage> createState() => _AiUsagePageState();
}

class _AiUsagePageState extends State<AiUsagePage> {
  bool _loading = true;
  List<AiUsageGroup> _byFeature = const [];
  List<AiUsageGroup> _byModel = const [];
  List<int> _daily = const [];
  int _rangeDays = 30;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final since = _rangeDays == 0
        ? null
        : DateTime.now().subtract(Duration(days: _rangeDays));
    final results = await Future.wait([
      AppDatabase.instance.aiUsageBy('feature', since: since),
      AppDatabase.instance.aiUsageBy('model', since: since),
      AppDatabase.instance.aiUsageDaily(days: 14),
    ]);
    if (!mounted) return;
    setState(() {
      _byFeature = results[0] as List<AiUsageGroup>;
      _byModel = results[1] as List<AiUsageGroup>;
      _daily = results[2] as List<int>;
      _loading = false;
    });
  }

  Future<void> _clear() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppL.of(context).usageClear),
        content: Text(AppL.of(context).usageClearBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(AppL.of(context).commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(AppL.of(context).usageClearShort),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await AppDatabase.instance.clearAiUsage();
    await _load();
  }

  int get _total =>
      _byFeature.fold(0, (sum, g) => sum + g.total);
  int get _calls => _byFeature.fold(0, (sum, g) => sum + g.calls);

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: t.gradient.last,
      body: SafeArea(
        child: ReadableWidth(
          child: _loading
              ? const LoadingState()
              : ListView(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.paddingOf(context).bottom + 28,
                  ),
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                          AppTheme.gutter, 8, AppTheme.gutter, 4),
                      child: Row(
                        children: [
                          PlainIconButton(
                            icon: Icons.arrow_back,
                            onTap: () => Navigator.of(context).maybePop(),
                          ),
                          SizedBox(width: 4),
                          Expanded(
                              child: Text(AppL.of(context).usageTitle, style: text.titleMedium)),
                          if (_total > 0)
                            TextButton(
                              onPressed: _clear,
                              child: Text(AppL.of(context).usageClearShort,
                                  style: text.labelMedium
                                      ?.copyWith(color: t.textSoft)),
                            ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: AppTheme.gutter),
                      child: Wrap(
                        spacing: 8,
                        children: [
                          for (final d in [7, 30, 0])
                            _RangeChip(
                              label: d == 0 ? AppL.of(context).bankAllShort : AppL.of(context).usageLastDays(d),
                              on: _rangeDays == d,
                              onTap: () {
                                setState(() {
                                  _rangeDays = d;
                                  _loading = true;
                                });
                                _load();
                              },
                            ),
                        ],
                      ),
                    ),

                    if (_total == 0)
                      Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: EmptyState(
                          icon: Icons.data_usage_outlined,
                          title: AppL.of(context).usageNone,
                          message: AppL.of(context).usageNoneHint,
                        ),
                      )
                    else ...[
                      const SizedBox(height: 18),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.gutter),
                        child: _TotalCard(
                          total: _total,
                          calls: _calls,
                          daily: _daily,
                        ),
                      ),
                      SizedBox(height: 22),
                      SectionHeader(
                        title: AppL.of(context).usageWhere,
                        caption: AppL.of(context).usageByTokens,
                      ),
                      for (final g in _byFeature)
                        _UsageRow(
                          label: _featureLabel(context, g.key),
                          group: g,
                          ratio: _total == 0 ? 0 : g.total / _total,
                        ),
                      SizedBox(height: 18),
                      SectionHeader(title: AppL.of(context).usageByModel),
                      for (final g in _byModel)
                        _UsageRow(
                          label: g.key.isEmpty ? AppL.of(context).usageUnrecorded : g.key,
                          group: g,
                          ratio: _total == 0 ? 0 : g.total / _total,
                        ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                            AppTheme.gutter, 22, AppTheme.gutter, 0),
                        child: Text(
                          AppL.of(context).usageTokenNote,
                          style: text.bodySmall?.copyWith(color: t.textSoft),
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

String _featureLabel(BuildContext context, String key) => switch (key) {
      'explain' => AppL.of(context).usageFeatureExplain,
      'import' => AppL.of(context).usageFeatureDoc,
      'scan' => AppL.of(context).usageFeatureScan,
      'essay' => AppL.of(context).usageFeatureEssay,
      'ocr' => AppL.of(context).usageFeatureImage,
      'classify' => AppL.of(context).usageFeatureSort,
      _ => AppL.of(context).usageFeatureOther,
    };

/// 万位以上折成 k，一屏排得下。
String formatTokens(int n) {
  if (n < 10000) return '$n';
  if (n < 1000000) return '${(n / 1000).toStringAsFixed(1)}k';
  return '${(n / 1000000).toStringAsFixed(2)}M';
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({
    required this.total,
    required this.calls,
    required this.daily,
  });

  final int total;
  final int calls;
  final List<int> daily;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final peak = daily.isEmpty ? 0 : daily.reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: t.shadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                formatTokens(total),
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  height: 1,
                  letterSpacing: -1,
                  color: t.text,
                  fontFeatures: AppTheme.numeric,
                ),
              ),
              const SizedBox(width: 6),
              Text('tokens', style: text.bodySmall?.copyWith(color: t.textSoft)),
              Spacer(),
              Text(AppL.of(context).usageCalls(calls),
                  style: text.bodySmall?.copyWith(color: t.textSoft)),
            ],
          ),
          if (daily.isNotEmpty && peak > 0) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 44,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < daily.length; i++) ...[
                    if (i > 0) const SizedBox(width: 3),
                    Expanded(
                      child: Container(
                        // 有用量的那天至少留 3px，否则看着像那天没用过
                        height: daily[i] == 0
                            ? 2
                            : (3 + 41 * (daily[i] / peak)).clamp(3, 44),
                        decoration: BoxDecoration(
                          color: daily[i] == 0 ? t.lineSoft : t.brand,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: 7),
            Text(AppL.of(context).usageLast14, style: text.bodySmall?.copyWith(color: t.textSoft)),
          ],
        ],
      ),
    );
  }
}

class _UsageRow extends StatelessWidget {
  const _UsageRow({
    required this.label,
    required this.group,
    required this.ratio,
  });

  final String label;
  final AiUsageGroup group;
  final double ratio;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.gutter, vertical: 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleSmall?.copyWith(fontSize: 14.5)),
              ),
              Text(
                formatTokens(group.total),
                style: text.bodyMedium?.copyWith(
                  fontFeatures: AppTheme.numeric,
                  color: t.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: ratio.clamp(0.0, 1.0),
              minHeight: 4,
              backgroundColor: t.lineSoft,
              color: t.brand,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            AppL.of(context).usageGroupLine(
              group.calls,
              formatTokens(group.inputTokens),
              formatTokens(group.outputTokens),
            ),
            style: text.bodySmall?.copyWith(color: t.textSoft, fontSize: 11.5),
          ),
        ],
      ),
    );
  }
}

class _RangeChip extends StatelessWidget {
  const _RangeChip({
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
