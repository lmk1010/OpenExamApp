import 'package:flutter/material.dart';
import 'package:openexam_app/core/ai/ai_settings.dart';
import 'package:openexam_app/core/constants/categories.dart';
import 'package:openexam_app/core/theme/app_theme.dart';
import 'package:openexam_app/core/theme/app_tokens.dart';
import 'package:openexam_app/core/ui/glass.dart';
import 'package:openexam_app/core/ui/responsive.dart';
import 'package:openexam_app/core/ui/stroke_icons.dart';
import 'package:openexam_app/core/ui/ui_kit.dart';
import 'package:openexam_app/data/db/app_database.dart';
import 'package:openexam_app/data/models/question.dart';
import 'package:openexam_app/features/ai/ai_settings_page.dart';
import 'package:openexam_app/features/ai/ai_thinking.dart';
import 'package:openexam_app/features/diagnosis/ai_diagnosis_service.dart';
import 'package:openexam_app/features/diagnosis/diagnosis.dart';
import 'package:openexam_app/l10n/app_localizations.dart';

/// 弱点诊断页。
///
/// 顺序是刻意的：**结论 → 证据 → AI**。上面两段本地就能算，没配 AI 的人
/// 看到的东西一样完整；AI 那一段折在最后，是加分项不是主体。
///
/// 反过来做（整页等 AI 出结果）会有两个问题：没配 key 的人看到一张空页，
/// 配了的人每次都得等几十秒才知道自己哪里弱 —— 而那些数是本机现成的。
class DiagnosisPage extends StatefulWidget {
  const DiagnosisPage({super.key, required this.build, required this.cacheKey});

  /// 怎么算这份诊断。错题本传整段历史，成绩页传那一份卷子。
  /// 传进 AppL 是因为诊断引擎是纯模型、没有 BuildContext。
  final Future<Diagnosis> Function(AppL l) build;

  /// AI 结果的存档键：`history` 或 `report:<id>`。
  final String cacheKey;

  /// 整段作答记录。
  static DiagnosisPage history() => DiagnosisPage(
        cacheKey: 'history',
        build: (l) async =>
            Diagnosis.fromHistory(l, await AppDatabase.instance.diagnosisData()),
      );

  /// 一份成卷记录。逐题用时在 practice_logs 里，按这份记录的时间窗口去捞。
  static DiagnosisPage report(ExamReport r) => DiagnosisPage(
        cacheKey: 'report:${r.id}',
        build: (l) async {
          final db = AppDatabase.instance;
          final questions = await db.fetchByIds(r.questionIds);
          return Diagnosis.fromReport(
            l: l,
            title: r.title,
            questions: questions,
            answers: r.answers,
            timings: await db.reportTimings(r),
            elapsed: r.elapsed,
          );
        },
      );

  @override
  State<DiagnosisPage> createState() => _DiagnosisPageState();
}

class _DiagnosisPageState extends State<DiagnosisPage> {
  Diagnosis? _diagnosis;
  bool _configured = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final d = await widget.build(AppL.of(context));
    final settings = await AiSettingsStore.load();
    await AiDiagnosisService.instance.hydrate(widget.cacheKey);
    if (!mounted) return;
    setState(() {
      _diagnosis = d;
      _configured = settings.isConfigured;
    });
  }

  /// 配完回来要重新读一次设置，否则按钮还停在「去配置 AI」。
  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const AiSettingsPage()),
    );
    final settings = await AiSettingsStore.load();
    if (!mounted) return;
    setState(() => _configured = settings.isConfigured);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final d = _diagnosis;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 21),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        titleSpacing: 0,
        title: Text(AppL.of(context).dxPageTitle),
      ),
      body: d == null
          ? LoadingState()
          : d.attempts == 0
              ? EmptyState(
                  icon: Icons.query_stats_outlined,
                  title: AppL.of(context).dxEmptyTitle,
                  message: AppL.of(context).dxEmptyBody,
                )
              : ReadableWidth(
                  child: ListView(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.paddingOf(context).bottom + 34,
                    ),
                    children: [
                      _Headline(diagnosis: d),
                      const SizedBox(height: 22),
                      _ModuleTable(diagnosis: d),
                      const SizedBox(height: 26),
                      _Findings(diagnosis: d),
                      const SizedBox(height: 26),
                      _AiSection(
                        diagnosis: d,
                        cacheKey: widget.cacheKey,
                        configured: _configured,
                        onConfigure: _openSettings,
                      ),
                      const SizedBox(height: 24),
                      Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: AppTheme.gutter),
                        child: Text(
                          AppL.of(context).dxFootnote,
                          style: TextStyle(
                              fontSize: 11.5, height: 1.6, color: t.muted),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _Headline extends StatelessWidget {
  const _Headline({required this.diagnosis});

  final Diagnosis diagnosis;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppTheme.gutter, 16, AppTheme.gutter, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            diagnosis.scopeLabel,
            style: TextStyle(fontSize: 12, color: t.muted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 7),
          Text(
            diagnosis.headline,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              height: 1.45,
              letterSpacing: -0.3,
              color: t.text,
            ),
          ),
          if (diagnosis.note.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
              decoration: BoxDecoration(
                color: t.accentSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                diagnosis.note,
                style: TextStyle(
                    fontSize: 12.5, height: 1.5, color: t.onAccentSoft),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 实测 vs 基准，一行一个模块。这张表是整页的证据。
class _ModuleTable extends StatelessWidget {
  const _ModuleTable({required this.diagnosis});

  final Diagnosis diagnosis;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    if (diagnosis.modules.isEmpty) return const SizedBox.shrink();

    Widget head(String s, double w) => SizedBox(
          width: w,
          child: Text(
            s,
            textAlign: TextAlign.right,
            style: TextStyle(fontSize: 10.5, color: t.muted, height: 1),
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(AppL.of(context).dxModuleTable),
        Container(
          margin: EdgeInsets.symmetric(horizontal: AppTheme.gutter),
          padding: EdgeInsets.fromLTRB(14, 10, 14, 12),
          decoration: GlassDecor.panel(t, radius: 16, raised: false),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Spacer(),
                    head(AppL.of(context).dxColQuestions, 36),
                    head(AppL.of(context).dxColAccuracy, 52),
                    head(AppL.of(context).dxColSeconds, 46),
                    head(AppL.of(context).dxColBench, 40),
                  ],
                ),
              ),
              for (final m in diagnosis.modules)
                Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: t.category(m.category),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          categoryLabel(m.category),
                          style: TextStyle(fontSize: 13, color: t.text),
                        ),
                      ),
                      _Cell('${m.attempts}', width: 36),
                      _Cell(
                        '${(m.accuracy * 100).round()}%',
                        width: 52,
                        bold: true,
                        tint: m.accuracy < m.targetAccuracy - 0.15
                            ? t.danger
                            : m.accuracy >= m.targetAccuracy
                                ? t.success
                                : null,
                      ),
                      _Cell(
                        m.timed ? '${m.seconds}' : '—',
                        width: 46,
                        bold: true,
                        tint: !m.timed
                            ? null
                            : m.seconds >= m.benchSeconds * 1.25
                                ? t.danger
                                : m.seconds <= m.benchSeconds * 0.9
                                    ? t.success
                                    : null,
                      ),
                      _Cell('${m.benchSeconds}', width: 40, soft: true),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell(
    this.text, {
    required this.width,
    this.bold = false,
    this.soft = false,
    this.tint,
  });

  final String text;
  final double width;
  final bool bold;
  final bool soft;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return SizedBox(
      width: width,
      child: Text(
        text,
        textAlign: TextAlign.right,
        style: TextStyle(
          fontSize: 13,
          height: 1.3,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          fontFeatures: AppTheme.numeric,
          color: tint ?? (soft ? t.muted : t.text),
        ),
      ),
    );
  }
}

/// 结论。每条三段：判断、证据、动作。
class _Findings extends StatelessWidget {
  const _Findings({required this.diagnosis});

  final Diagnosis diagnosis;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    if (diagnosis.findings.isEmpty) {
      // 「没查出短板」和「压根没查」是两回事。基准是按行测五模块定的，
      // 换一门考试分类就对不上，这时候说"都在基准附近"是句假话。
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: AppTheme.gutter),
        child: Text(
          diagnosis.benchmarked
              ? AppL.of(context).dxNoWeakSpot
              : AppL.of(context).dxNoBenchmark,
          style: TextStyle(fontSize: 14, height: 1.7, color: t.textSoft),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(AppL.of(context).dxFindings, trailing: AppL.of(context).dxFindingsCount(diagnosis.findings.length)),
        for (var i = 0; i < diagnosis.findings.length; i++)
          _FindingRow(finding: diagnosis.findings[i], first: i == 0),
      ],
    );
  }
}

class _FindingRow extends StatelessWidget {
  const _FindingRow({required this.finding, required this.first});

  final Finding finding;
  final bool first;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final (color, mark) = switch (finding.level) {
      FindingLevel.bad => (t.danger, AppL.of(context).dxLevelBad),
      FindingLevel.watch => (t.accent, AppL.of(context).dxLevelWatch),
      FindingLevel.good => (t.success, AppL.of(context).dxLevelGood),
    };

    return Container(
      padding: EdgeInsets.fromLTRB(
          AppTheme.gutter, first ? 0 : 14, AppTheme.gutter, 14),
      decoration: BoxDecoration(
        border: first ? null : Border(top: BorderSide(color: t.lineSoft)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 2, right: 9),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  mark,
                  style: TextStyle(
                    fontSize: 10.5,
                    height: 1.1,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  finding.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 1.45,
                    color: t.text,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            finding.evidence,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.6,
              color: t.muted,
              fontFeatures: AppTheme.numeric,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            finding.action,
            style: TextStyle(fontSize: 13.5, height: 1.75, color: t.textSoft),
          ),
        ],
      ),
    );
  }
}

/// AI 那一层。刻意放在最后，也刻意不自动开始 —— 上面的结论已经能用了，
/// 花不花这次钱由用户决定。
class _AiSection extends StatelessWidget {
  const _AiSection({
    required this.diagnosis,
    required this.cacheKey,
    required this.configured,
    required this.onConfigure,
  });

  final Diagnosis diagnosis;
  final String cacheKey;
  final bool configured;
  final VoidCallback onConfigure;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final service = AiDiagnosisService.instance;

    return ValueListenableBuilder<AiDiagnosisState>(
      valueListenable: service.stateOf(cacheKey),
      builder: (context, state, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Label(
              AppL.of(context).dxAiSection,
              trailing: state.text.isNotEmpty && !state.streaming ? AppL.of(context).dxRegenerate : null,
              onTapTrailing: state.text.isNotEmpty && !state.streaming
                  ? () => service.regenerate(cacheKey, diagnosis)
                  : null,
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: AppTheme.gutter),
              padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
              decoration: GlassDecor.panel(t, radius: 16, raised: false),
              child: switch (state) {
                _ when state.streaming && state.text.isEmpty =>
                  const AiThinkingSkeleton(),
                _ when state.text.isNotEmpty => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.text,
                        style: TextStyle(
                            fontSize: 14, height: 1.8, color: t.text),
                      ),
                      if (state.streaming) ...[
                        const SizedBox(height: 6),
                        AiCaret(),
                      ] else if (state.stamp != null) ...[
                        SizedBox(height: 12),
                        Text(
                          state.stamp!,
                          style: TextStyle(fontSize: 11, color: t.muted),
                        ),
                      ],
                    ],
                  ),
                _ => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        configured
                            ? AppL.of(context).dxAiPitch
                            : AppL.of(context).dxAiNotConfigured,
                        style: TextStyle(
                            fontSize: 13.5, height: 1.75, color: t.textSoft),
                      ),
                      if (state.error != null) ...[
                        SizedBox(height: 10),
                        Text(
                          state.error!,
                          style: TextStyle(fontSize: 12.5, color: t.danger),
                        ),
                      ],
                      SizedBox(height: 14),
                      _AskButton(
                        label: configured ? AppL.of(context).dxAskAi : AppL.of(context).dxConfigureAi,
                        onTap: configured
                            ? () => service.start(cacheKey, diagnosis)
                            : onConfigure,
                      ),
                    ],
                  ),
              },
            ),
          ],
        );
      },
    );
  }
}

class _AskButton extends StatelessWidget {
  const _AskButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(
          color: t.accent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            StrokeIcon(AppIcon.spark, size: 15, color: t.onAccent),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: t.onAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text, {this.trailing, this.onTapTrailing});

  final String text;
  final String? trailing;
  final VoidCallback? onTapTrailing;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppTheme.gutter, 0, AppTheme.gutter, 10),
      child: Row(
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
              color: t.muted,
            ),
          ),
          const Spacer(),
          if (trailing != null)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTapTrailing,
              child: Text(
                trailing!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: t.brand,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
