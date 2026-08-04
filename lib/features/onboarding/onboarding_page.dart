import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:openexam_app/core/constants/app_constants.dart';
import 'package:openexam_app/core/theme/app_theme.dart';
import 'package:openexam_app/core/theme/app_tokens.dart';
import 'package:openexam_app/core/ui/glass.dart';
import 'package:openexam_app/features/onboarding/illustrations.dart';
import 'package:openexam_app/core/ui/stroke_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// First launch: say what the app is, then get the two settings that make the
/// rest of it meaningful — the exam date and a daily target. Three taps, done.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _pager = PageController();
  int _page = 0;
  int _goal = 30;
  DateTime? _examDate;

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(Prefs.dailyGoal, _goal);
    if (_examDate != null) {
      await prefs.setString(Prefs.examDate, _examDate!.toIso8601String());
    }
    await prefs.setBool(Prefs.onboarded, true);
    widget.onDone();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _examDate ?? now.add(const Duration(days: 90)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 1500)),
      helpText: '选择考试日期',
    );
    if (picked != null && mounted) setState(() => _examDate = picked);
  }

  void _next() {
    if (_page >= 2) {
      _finish();
      return;
    }
    HapticFeedback.selectionClick();
    _pager.animateToPage(
      _page + 1,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pager,
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  _Slide(
                    kind: SceneKind.bank,
                    active: _page == 0,
                    title: '15936 道行测真题\n全部装在这台手机里',
                    body: '137 套历年真题卷，含 4230 张图形题配图。'
                        '不联网、不登录、没有广告，地铁上没信号也能刷。',
                  ),
                  _Slide(
                    kind: SceneKind.review,
                    active: _page == 1,
                    title: '答错的题\n会自己追着你',
                    body: '错题自动进错题本，可按题型、错因、试卷复盘；'
                        '答对后自动移出。做题时还能收藏、写笔记、标错因。',
                  ),
                  // Last slide collects the two settings instead of preaching.
                  _Setup(
                    active: _page == 2,
                    goal: _goal,
                    examDate: _examDate,
                    onGoal: (v) => setState(() => _goal = v),
                    onPickDate: _pickDate,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppTheme.gutter, 0, AppTheme.gutter, 20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < 3; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: i == _page ? 20 : 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: i == _page ? t.brand : t.line,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _next,
                      child: Text(_page == 2 ? '开始刷题' : '继续'),
                    ),
                  ),
                  if (_page < 2)
                    TextButton(
                      onPressed: _finish,
                      child: Text('跳过', style: text.bodySmall),
                    )
                  else
                    const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  const _Slide({
    required this.kind,
    required this.active,
    required this.title,
    required this.body,
  });

  final SceneKind kind;
  final bool active;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppTheme.gutter + 6, 16, AppTheme.gutter + 6, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The illustration carries the slide; text stays short underneath.
          Expanded(
            flex: 5,
            child: Center(child: OnboardingScene(kind: kind, active: active)),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: text.displaySmall?.copyWith(fontSize: 26, height: 1.35),
          ),
          const SizedBox(height: 14),
          Text(body, style: text.bodyMedium?.copyWith(fontSize: 15, height: 1.7)),
          const Spacer(),
        ],
      ),
    );
  }
}

class _Setup extends StatelessWidget {
  const _Setup({
    required this.active,
    required this.goal,
    required this.examDate,
    required this.onGoal,
    required this.onPickDate,
  });

  final bool active;
  final int goal;
  final DateTime? examDate;
  final ValueChanged<int> onGoal;
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final days = examDate == null
        ? null
        : examDate!.difference(DateTime.now()).inDays + 1;

    return ListView(
      padding: const EdgeInsets.fromLTRB(AppTheme.gutter + 6, 8, AppTheme.gutter + 6, 20),
      children: [
        SizedBox(
          height: 170,
          child: Center(
            child: OnboardingScene(kind: SceneKind.rhythm, active: active),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '定个节奏\n剩下的交给它',
          style: text.displaySmall?.copyWith(fontSize: 27, height: 1.35),
        ),
        const SizedBox(height: 12),
        Text(
          '这两项随时可以在「我的」里改。',
          style: text.bodyMedium?.copyWith(fontSize: 15),
        ),
        const SizedBox(height: 30),
        Text('每天练多少题', style: text.titleSmall),
        const SizedBox(height: 12),
        Wrap(
          spacing: 9,
          runSpacing: 9,
          children: [
            for (final n in const [10, 20, 30, 50, 80])
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  onGoal(n);
                  HapticFeedback.selectionClick();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                  decoration: BoxDecoration(
                    color: goal == n ? t.brand : t.glass,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '$n 题',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1,
                      color: goal == n ? Colors.white : t.textSoft,
                      fontFeatures: AppTheme.numeric,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 30),
        Text('考试是哪天', style: text.titleSmall),
        const SizedBox(height: 12),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onPickDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            decoration: GlassDecor.panel(t, radius: 16, raised: false),
            child: Row(
              children: [
                StrokeIcon(AppIcon.timer, size: 19, color: t.brand),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    examDate == null
                        ? '选一个日期（可跳过）'
                        : '${examDate!.year}-${examDate!.month.toString().padLeft(2, '0')}'
                            '-${examDate!.day.toString().padLeft(2, '0')}'
                            '${days == null ? '' : ' · 还有 $days 天'}',
                    style: text.titleSmall?.copyWith(
                      fontSize: 15,
                      color: examDate == null ? t.muted : t.text,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right, size: 18, color: t.muted),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
