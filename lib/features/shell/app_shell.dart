import 'package:flutter/material.dart';
import 'package:openexam_app/core/theme/app_tokens.dart';
import 'package:openexam_app/core/ui/stroke_icons.dart';
import 'package:openexam_app/features/bank/bank_page.dart';
import 'package:openexam_app/features/practice/practice_home_page.dart';
import 'package:openexam_app/features/profile/profile_page.dart';
import 'package:openexam_app/features/wrong/wrong_book_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

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
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _index,
          children: const [
            PracticeHomePage(),
            BankPage(),
            WrongBookPage(),
            ProfilePage(),
          ],
        ),
      ),
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
