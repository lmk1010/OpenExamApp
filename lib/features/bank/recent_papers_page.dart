import 'package:flutter/material.dart';
import 'package:openexam_app/core/theme/app_theme.dart';
import 'package:openexam_app/core/theme/app_tokens.dart';
import 'package:openexam_app/core/ui/ambient.dart';
import 'package:openexam_app/core/ui/responsive.dart';
import 'package:openexam_app/core/ui/ui_kit.dart';
import 'package:openexam_app/features/reports/reports_page.dart';

/// 一张最近做过的卷。
typedef RecentPaper = ({
  String id,
  String title,
  int total,
  int done,
  DateTime at,
});

/// 最近做过的卷子。
///
/// 这一段原来平铺在题库页搜索框下面 —— 一进题库先看见半屏"上次做到哪"，
/// 真要找一张新卷的人得先翻过去。它是回头看的东西，不该占着入口。
class RecentPapersPage extends StatelessWidget {
  const RecentPapersPage({super.key, required this.recent});

  final List<RecentPaper> recent;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: t.gradient.last,
      body: SafeArea(
        child: ReadableWidth(
          child: ListView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.paddingOf(context).bottom + 28,
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppTheme.gutter, 8, AppTheme.gutter, 8),
                child: Row(
                  children: [
                    PlainIconButton(
                      icon: Icons.arrow_back,
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(width: 4),
                    Expanded(child: Text('最近做过', style: text.titleMedium)),
                    TextButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const ReportsPage()),
                      ),
                      child: Text('练习历史',
                          style: text.labelMedium?.copyWith(color: t.brand)),
                    ),
                  ],
                ),
              ),
              if (recent.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: EmptyState(
                    icon: Icons.history,
                    title: '还没做过整卷',
                    message: '在题库里挑一张卷开始，之后这里会记着做到哪了。',
                  ),
                )
              else
                for (var i = 0; i < recent.length; i++) ...[
                  if (i > 0) const RowDivider(),
                  _RecentRow(
                    paper: recent[i],
                    onTap: () => Navigator.of(context).pop(recent[i].id),
                  ),
                ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentRow extends StatelessWidget {
  const _RecentRow({required this.paper, required this.onTap});

  final RecentPaper paper;
  final VoidCallback onTap;

  String get _when {
    final now = DateTime.now();
    final days = DateTime(now.year, now.month, now.day)
        .difference(DateTime(paper.at.year, paper.at.month, paper.at.day))
        .inDays;
    return switch (days) {
      0 => '今天',
      1 => '昨天',
      < 7 => '$days 天前',
      _ => '${paper.at.month}/${paper.at.day}',
    };
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final ratio = paper.total == 0 ? 0.0 : paper.done / paper.total;
    final finished = paper.total > 0 && paper.done >= paper.total;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.gutter, vertical: 13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    paper.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleSmall?.copyWith(fontSize: 14.5),
                  ),
                ),
                const SizedBox(width: 10),
                Text(_when,
                    style: text.bodySmall?.copyWith(color: t.textSoft)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: ratio.clamp(0.0, 1.0),
                minHeight: 4,
                backgroundColor: t.lineSoft,
                color: finished ? t.success : t.brand,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              finished
                  ? '已做完 ${paper.total} 题'
                  : '做到 ${paper.done} / ${paper.total} 题',
              style: text.bodySmall?.copyWith(
                color: finished ? t.success : t.textSoft,
                fontSize: 11.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
