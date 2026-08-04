import 'package:flutter/material.dart';
import 'package:openexam_app/core/theme/app_tokens.dart';
import 'package:openexam_app/core/ui/ambient.dart';
import 'package:openexam_app/core/ui/responsive.dart';
import 'package:openexam_app/core/ui/stroke_icons.dart';
import 'package:openexam_app/features/bank/bank_page.dart';
import 'package:openexam_app/features/practice/practice_home_page.dart';
import 'package:openexam_app/features/profile/profile_page.dart';
import 'package:openexam_app/features/wrong/wrong_book_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  /// 让别的页面能把用户送到某个 tab（比如首页的计划提醒 → 错题本）。
  /// 底部导航是这个 app 唯一的一级结构，push 一个没有导航栏的副本会更乱。
  static final ValueNotifier<int> jumpTo = ValueNotifier<int>(0);

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    AppShell.jumpTo.addListener(_onJump);
  }

  @override
  void dispose() {
    AppShell.jumpTo.removeListener(_onJump);
    super.dispose();
  }

  void _onJump() {
    if (!mounted) return;
    setState(() => _index = AppShell.jumpTo.value);
  }

  // The four things a 考公 user actually does: 练一组、按卷刷、清错题、管数据。
  static const _tabs = [
    (icon: AppIcon.practice, label: '练习'),
    (icon: AppIcon.papers, label: '题库'),
    (icon: AppIcon.wrongBook, label: '错题本'),
    (icon: AppIcon.profile, label: '我的'),
  ];

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final pages = const [
      PracticeHomePage(),
      BankPage(),
      WrongBookPage(),
      ProfilePage(),
    ];
    final body = IndexedStack(index: _index, children: pages);

    // 平板和横屏：导航挪到左侧竖着放。底部导航在宽屏上要么被拉成一条几百像素
    // 的空条，要么手够不着。
    if (context.isWide) {
      return Scaffold(
        body: SafeArea(
          bottom: false,
          child: Row(
            children: [
              _NavRail(
                tabs: _tabs,
                index: _index,
                extended: context.isExpanded,
                onTap: (i) => setState(() => _index = i),
              ),
              Expanded(child: body),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(bottom: false, child: body),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              t.gradient.last.withValues(alpha: 0),
              t.gradient.last.withValues(alpha: 0.9),
              t.gradient.last,
            ],
            stops: const [0, 0.3, 1],
          ),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 56,
            child: Row(
              children: [
                for (var i = 0; i < _tabs.length; i++)
                  _TabItem(
                    icon: _tabs[i].icon,
                    label: _tabs[i].label,
                    selected: _index == i,
                    onTap: () => setState(() => _index = i),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 宽屏下的侧边导航。窄的只有图标，够宽了带上文字。
class _NavRail extends StatelessWidget {
  const _NavRail({
    required this.tabs,
    required this.index,
    required this.extended,
    required this.onTap,
  });

  final List<({AppIcon icon, String label})> tabs;
  final int index;
  final bool extended;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      width: extended ? 168 : 76,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: t.line.withValues(alpha: 0.6)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: extended ? 18 : 0),
            child: Row(
              mainAxisAlignment:
                  extended ? MainAxisAlignment.start : MainAxisAlignment.center,
              children: [
                const BrandLogo(size: 26),
                if (extended) ...[
                  const SizedBox(width: 10),
                  Text(
                    'OpenExam',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 22),
          for (var i = 0; i < tabs.length; i++)
            Padding(
              padding: EdgeInsets.fromLTRB(extended ? 10 : 12, 0, extended ? 10 : 12, 6),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onTap(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 46,
                  padding: EdgeInsets.symmetric(horizontal: extended ? 14 : 0),
                  decoration: BoxDecoration(
                    color: index == i
                        ? t.brand.withValues(alpha: 0.14)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: extended
                        ? MainAxisAlignment.start
                        : MainAxisAlignment.center,
                    children: [
                      StrokeIcon(
                        tabs[i].icon,
                        size: 21,
                        color: index == i ? t.brand : t.muted,
                        weight: index == i ? 2.2 : 1.8,
                      ),
                      if (extended) ...[
                        const SizedBox(width: 12),
                        Text(
                          tabs[i].label,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: index == i ? t.brand : t.textSoft,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final AppIcon icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final color = selected ? t.brand : t.muted;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            StrokeIcon(icon, size: 23, color: color, weight: selected ? 2.2 : 1.8),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
