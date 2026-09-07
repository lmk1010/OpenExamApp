import 'package:flutter/material.dart';
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
        title: const Text('清空用量记录'),
        content: const Text('只清掉这里的统计，不影响已经生成的讲解和导入的题。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('清空'),
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
                      padding: const EdgeInsets.fromLTRB(
                          AppTheme.gutter, 8, AppTheme.gutter, 4),
                      child: Row(
                        children: [
                          PlainIconButton(
                            icon: Icons.arrow_back,
                            onTap: () => Navigator.of(context).maybePop(),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                              child: Text('AI 用量', style: text.titleMedium)),
                          if (_total > 0)
                            TextButton(
                              onPressed: _clear,
                              child: Text('清空',
                                  style: text.labelMedium
                                      ?.copyWith(color: t.textSoft)),
                            ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.gutter),
                      child: Wrap(
                        spacing: 8,
                        children: [
                          for (final d in const [7, 30, 0])
                            _RangeChip(
                              label: d == 0 ? '全部' : '近 $d 天',
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
                      const Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: EmptyState(
                          icon: Icons.data_usage_outlined,
                          title: '还没有用量',
                          message: 'AI 讲题、导入解析、申论批改都会记在这里。',
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
                      const SizedBox(height: 22),
                      const SectionHeader(
                        title: '花在哪',
                        caption: 'token 从多到少',
                      ),
                      for (final g in _byFeature)
                        _UsageRow(
                          label: _featureLabel(g.key),
                          group: g,
                          ratio: _total == 0 ? 0 : g.total / _total,
                        ),
                      const SizedBox(height: 18),
                      const SectionHeader(title: '按模型'),
                      for (final g in _byModel)
                        _UsageRow(
                          label: g.key.isEmpty ? '未记录' : g.key,
                          group: g,
                          ratio: _total == 0 ? 0 : g.total / _total,
                        ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                            AppTheme.gutter, 22, AppTheme.gutter, 0),
                        child: Text(
                          'token 数由模型返回，各家统计口径略有差别，'
                          '这里的数字用来比较大小，跟账单可能差一点。',
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

String _featureLabel(String key) => switch (key) {
      'explain' => 'AI 讲题',
      'import' => '文档导入',
      'scan' => '拍照 / PDF 识题',
      'essay' => '申论批改',
      'ocr' => '图片识题',
      'classify' => '分类整理',
      _ => '其他',
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
              const Spacer(),
              Text('$calls 次调用',
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
            const SizedBox(height: 7),
            Text('近 14 天', style: text.bodySmall?.copyWith(color: t.textSoft)),
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
            '${group.calls} 次 · 进 ${formatTokens(group.inputTokens)}'
            ' · 出 ${formatTokens(group.outputTokens)}',
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
