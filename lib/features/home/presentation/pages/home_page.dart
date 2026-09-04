import 'package:flutter/material.dart';
import 'package:openexam_app/features/plan/presentation/pages/study_plan_page.dart';
import 'package:openexam_app/features/question_bank/presentation/pages/question_bank_page.dart';

/// Legacy shell kept for reference. The live app uses [AppShell].
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentTab = 0;

  static const _pages = [StudyPlanPage(), QuestionBankPage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentTab, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentTab,
        onDestinationSelected: (index) => setState(() => _currentTab = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.checklist_rounded),
            label: '每日计划',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            label: '题库',
          ),
        ],
      ),
    );
  }
}
