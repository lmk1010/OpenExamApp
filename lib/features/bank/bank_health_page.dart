import 'package:flutter/material.dart';
import 'package:openexam_app/core/constants/categories.dart';
import 'package:openexam_app/core/theme/app_theme.dart';
import 'package:openexam_app/core/theme/app_tokens.dart';
import 'package:openexam_app/core/ui/stroke_icons.dart';
import 'package:openexam_app/core/ui/ui_kit.dart';
import 'package:openexam_app/data/db/app_database.dart';
import 'package:openexam_app/features/practice/practice_session_page.dart';

/// 题库体检 — coverage matrix + structural dirty rows.
/// Answers are not certified against official keys; this page makes gaps and
/// broken fields visible so you can spot-check and 纠错.
class BankHealthPage extends StatefulWidget {
  const BankHealthPage({super.key});

  @override
  State<BankHealthPage> createState() => _BankHealthPageState();
}

class _BankHealthPageState extends State<BankHealthPage> {
  bool _loading = true;
  BankHealthReport? _report;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final report = await AppDatabase.instance.bankHealth();
    if (!mounted) return;
    setState(() {
      _report = report;
      _loading = false;
    });
  }

  Future<void> _openDirty(BankDirtyItem item) async {
    final q = await AppDatabase.instance.questionById(item.id);
    if (!mounted || q == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PracticeSessionPage(
          questions: [q],
          reviewAnswers: {q.id: q.answer.toUpperCase()},
          title: '脏数据回看',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final r = _report;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 21),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        titleSpacing: 0,
        title: const Text('题库体检'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 21),
            onPressed: () {
              setState(() => _loading = true);
              _load();
            },
          ),
        ],
      ),
      body: _loading || r == null
          ? const LoadingState()
          : ListView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.paddingOf(context).bottom + 28,
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.gutter,
                    8,
                    AppTheme.gutter,
                    4,
                  ),
                  child: Text(
                    '结构体检自动跑；答案是否等于官方键，仍需抽样对照 PDF。'
                    '发现问题时做题长按题号可记入纠错。',
                    style: text.bodySmall?.copyWith(height: 1.45),
                  ),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.gutter),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _StatChip(
                        label: '题目',
                        value: '${r.questions}',
                        color: t.brand,
                      ),
                      _StatChip(
                        label: '试卷',
                        value: '${r.papers}',
                        color: t.brand,
                      ),
                      _StatChip(
                        label: '年份',
                        value: r.yearMin == 0
                            ? '—'
                            : '${r.yearMin}–${r.yearMax}',
                        color: t.brand,
                      ),
                      _StatChip(
                        label: '脏答案',
                        value: '${r.dirty.length}',
                        color: r.dirty.isEmpty ? t.success : t.danger,
                      ),
                      _StatChip(
                        label: '缺答案',
                        value: '${r.noAnswer}',
                        color: r.noAnswer == 0 ? t.success : t.danger,
                      ),
                      _StatChip(
                        label: '缺解析',
                        value: '${r.noAnalysis}',
                        color: r.noAnalysis == 0 ? t.success : t.danger,
                      ),
                      _StatChip(
                        label: '配图题',
                        value: '${r.withImage}',
                        color: t.muted,
                      ),
                      _StatChip(
                        label: '纠错',
                        value: '${r.feedback}',
                        color: t.muted,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.gutter,
                    10,
                    AppTheme.gutter,
                    0,
                  ),
                  child: Text(
                    'seed v${r.seedVersion} · data patch v${r.dataPatch}'
                    ' · 短题干 ${r.shortContent}（多为图形题）',
                    style: text.bodySmall?.copyWith(fontSize: 12),
                  ),
                ),
                const SizedBox(height: 22),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppTheme.gutter),
                  child: SectionHeader(
                    title: '模块分布',
                    caption: '五科题量',
                  ),
                ),
                const SizedBox(height: 8),
                for (final c in kGongkaoCategories)
                  _BarRow(
                    label: c.label,
                    value: r.byCategory[c.key] ?? 0,
                    max: r.questions,
                    color: t.category(c.key),
                  ),
                const SizedBox(height: 22),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppTheme.gutter),
                  child: SectionHeader(
                    title: '年份分布',
                    caption: '套数 / 题量',
                  ),
                ),
                const SizedBox(height: 6),
                for (final y in r.byYear)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.gutter,
                      vertical: 7,
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 52,
                          child: Text(
                            '${y.year}',
                            style: text.titleMedium?.copyWith(fontSize: 15),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '${y.papers} 套 · ${y.questions} 题',
                            style: text.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 22),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppTheme.gutter),
                  child: SectionHeader(
                    title: '覆盖矩阵',
                    caption: '地区 × 年份（按题量）',
                  ),
                ),
                const SizedBox(height: 6),
                for (final cell in r.coverage.take(40)) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.gutter,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 72,
                          child: Text(
                            cell.region,
                            style: text.titleMedium?.copyWith(fontSize: 14),
                          ),
                        ),
                        SizedBox(
                          width: 48,
                          child: Text(
                            '${cell.year}',
                            style: text.bodySmall?.copyWith(
                              fontFeatures: AppTheme.numeric,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '${cell.papers} 套 · ${cell.questions} 题',
                            style: text.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const RowDivider(),
                ],
                if (r.coverage.length > 40)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.gutter,
                      4,
                      AppTheme.gutter,
                      0,
                    ),
                    child: Text(
                      '仅展示题量前 40 格，共 ${r.coverage.length} 格。',
                      style: text.bodySmall?.copyWith(fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 22),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.gutter),
                  child: SectionHeader(
                    title: '脏数据',
                    caption: r.dirty.isEmpty ? '未发现异常答案' : '${r.dirty.length} 条待核',
                  ),
                ),
                const SizedBox(height: 6),
                if (r.dirty.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.gutter,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        StrokeIcon(AppIcon.info, size: 16, color: t.success),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '答案字段格式正常。仍建议按模块抽样对照官方 PDF。',
                            style: text.bodySmall?.copyWith(height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  for (var i = 0; i < r.dirty.length; i++) ...[
                    if (i > 0) const RowDivider(),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _openDirty(r.dirty[i]),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.gutter,
                          vertical: 12,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '答案「${r.dirty[i].answer.isEmpty ? '空' : r.dirty[i].answer}」',
                                  style: text.titleMedium?.copyWith(
                                    fontSize: 14,
                                    color: t.danger,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  categoryLabel(r.dirty[i].category),
                                  style: text.bodySmall,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${r.dirty[i].year} · ${r.dirty[i].paperTitle}',
                              style: text.bodySmall?.copyWith(fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              r.dirty[i].preview,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: text.bodySmall?.copyWith(height: 1.35),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                const SizedBox(height: 22),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppTheme.gutter),
                  child: SectionHeader(
                    title: '抽样对标清单',
                    caption: '人工核对用',
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.gutter,
                    10,
                    AppTheme.gutter,
                    0,
                  ),
                  child: Text(
                    '1. 挑你的目标卷（国考 / 本省）各 1 套，对照官方 PDF 题量是否齐全。\n'
                    '2. 每科每年抽 10–20 题，核答案字母与解析结论是否一致。\n'
                    '3. 抽样正确率低于 98% 时，整年来源应降级信任。\n'
                    '4. 发现问题：做题页长按题号 →「我的 → 纠错记录」。',
                    style: text.bodySmall?.copyWith(height: 1.55),
                  ),
                ),
              ],
            ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final t = context.tokens;
    return Container(
      width: 104,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: text.titleMedium?.copyWith(
              fontSize: 18,
              color: color,
              fontFeatures: AppTheme.numeric,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: text.bodySmall?.copyWith(color: t.muted)),
        ],
      ),
    );
  }
}

class _BarRow extends StatelessWidget {
  const _BarRow({
    required this.label,
    required this.value,
    required this.max,
    required this.color,
  });

  final String label;
  final int value;
  final int max;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final t = context.tokens;
    final ratio = max == 0 ? 0.0 : value / max;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.gutter,
        vertical: 6,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(label, style: text.bodyMedium?.copyWith(fontSize: 14)),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio.clamp(0.0, 1.0),
                minHeight: 7,
                backgroundColor: t.line.withValues(alpha: 0.35),
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 48,
            child: Text(
              '$value',
              textAlign: TextAlign.right,
              style: text.bodySmall?.copyWith(fontFeatures: AppTheme.numeric),
            ),
          ),
        ],
      ),
    );
  }
}
