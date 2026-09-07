import 'package:flutter/material.dart';
import 'package:openexam_app/core/theme/app_theme.dart';
import 'package:openexam_app/core/theme/app_tokens.dart';
import 'package:openexam_app/core/ui/responsive.dart';
import 'package:openexam_app/core/ui/ambient.dart';
import 'package:openexam_app/features/plan/presentation/pages/study_plan_page.dart';
import 'package:openexam_app/features/profile/domain/exam_profile.dart';
import 'package:openexam_app/features/search/search_page.dart';
import 'package:openexam_app/features/tips/tips_page.dart';
import 'package:openexam_app/features/vocab/presentation/vocab_page.dart';

/// 工具箱：把散落各处的小功能摆成一列。
///
/// 这些功能一直都在，只是四个词语相关的全挤在 [VocabPage] 的四个 tab 里、
/// 入口又只挂在「我的」页 —— 用起来像"没有这个功能"。这一页不新增任何能力，
/// 只把路修通：一条一个名字，点进去直接落到那一栏。
class ToolsPage extends StatelessWidget {
  const ToolsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    void push(Widget page) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
    }

    final profile = ExamProfileStore.current;
    // 词语那几条是给逻辑填空用的，技巧速查里只有行测的方法 —— 备别的考试时
    // 它们摆在这只是噪音。
    final items = <_Tool>[
      if (profile.has(ExamFeature.vocab))
      _Tool(
        icon: Icons.compare_arrows_rounded,
        title: '词语辨析',
        subtitle: '一蹴而就 / 一挥而就，摆一起才分得清',
        onTap: () => push(const VocabPage(initialTab: VocabTab.confuse)),
      ),
      if (profile.has(ExamFeature.vocab))
      _Tool(
        icon: Icons.trending_up_rounded,
        title: '高频词语',
        subtitle: '从 2077 道逻辑填空的选项统计出来的',
        onTap: () => push(const VocabPage(initialTab: VocabTab.top)),
      ),
      if (profile.has(ExamFeature.vocab))
      _Tool(
        icon: Icons.style_rounded,
        title: '今日词卡',
        subtitle: '按间隔重复排的，今天该背哪些',
        onTap: () => push(const VocabPage()),
      ),
      if (profile.has(ExamFeature.vocab))
      _Tool(
        icon: Icons.card_travel_rounded,
        title: '生词锦囊',
        subtitle: '做错的词自动收进来，也能自己加',
        onTap: () => push(const VocabPage(initialTab: VocabTab.mine)),
      ),
      if (profile.has(ExamFeature.vocab))
      _Tool(
        icon: Icons.search_rounded,
        title: '词语查询',
        subtitle: '四千词表，看真题里怎么用',
        onTap: () => push(const VocabPage(initialTab: VocabTab.top)),
      ),
      if (profile.has(ExamFeature.tips))
      _Tool(
        icon: Icons.lightbulb_outline_rounded,
        title: '行测助手',
        subtitle: '各模块解题思路速查，卡住时翻',
        onTap: () => push(const TipsPage()),
      ),
      _Tool(
        icon: Icons.check_circle_outline_rounded,
        title: '每日打卡',
        subtitle: '今天的安排，勾完算数',
        onTap: () => push(const StudyPlanPage()),
      ),
      _Tool(
        icon: Icons.manage_search_rounded,
        title: '题库搜索',
        subtitle: '一万六千道题，按关键词找',
        onTap: () => push(const SearchPage()),
      ),
    ];

    return Scaffold(
      backgroundColor: t.gradient.last,
      body: SafeArea(
        child: ReadableWidth(
          child: ListView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.paddingOf(context).bottom + 24,
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppTheme.gutter, 8,
                    AppTheme.gutter, 12),
                child: Row(
                  children: [
                    PlainIconButton(
                      icon: Icons.arrow_back,
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(width: 4),
                    Text('工具', style: text.titleMedium),
                  ],
                ),
              ),
              for (final item in items) _ToolRow(tool: item),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tool {
  const _Tool({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
}

class _ToolRow extends StatelessWidget {
  const _ToolRow({required this.tool});

  final _Tool tool;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return InkWell(
      onTap: tool.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.gutter,
          vertical: 11,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: t.accentSoft,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(tool.icon, size: 20, color: t.onAccentSoft),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tool.title, style: text.titleSmall),
                  const SizedBox(height: 2),
                  Text(
                    tool.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall?.copyWith(color: t.textSoft),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 20, color: t.textSoft),
          ],
        ),
      ),
    );
  }
}
