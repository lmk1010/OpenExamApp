import 'package:flutter/material.dart';
import 'package:openexam_app/features/plan/presentation/pages/daily_plan_page.dart';
import 'package:openexam_app/features/question_bank/presentation/pages/question_bank_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentTab = 0;

  static const _pages = [DailyPlanPage(), QuestionBankPage()];

  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;
    final title = _currentTab == 0 ? '每日冲分' : '题库';
    final subtitle = _currentTab == 0 ? '打开就知道今天做什么' : '即将接入专项练习';

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        toolbarHeight: platform == TargetPlatform.android ? 72 : 60,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        actions: [
          if (_currentTab == 0)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FilledButton.tonalIcon(
                onPressed: () {},
                icon: const Icon(Icons.flash_on_rounded),
                label: const Text('冲刺模式'),
              ),
            ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 360),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: KeyedSubtree(
          key: ValueKey(_currentTab),
          child: _pages[_currentTab],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentTab,
        onDestinationSelected: (index) {
          setState(() {
            _currentTab = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.checklist_rounded),
            selectedIcon: Icon(Icons.checklist_rounded),
            label: '每日计划',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book_rounded),
            label: '题库',
          ),
        ],
      ),
      floatingActionButton: _currentTab == 0
          ? FloatingActionButton.extended(
              onPressed: () {},
              icon: const Icon(Icons.flag_rounded),
              label: const Text('开始今日任务'),
            )
          : null,
    );
  }
}
