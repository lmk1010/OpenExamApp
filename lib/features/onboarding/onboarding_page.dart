import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:openexam_app/core/constants/app_constants.dart';
import 'package:openexam_app/core/constants/categories.dart';
import 'package:openexam_app/core/theme/app_theme.dart';
import 'package:openexam_app/core/theme/app_tokens.dart';
import 'package:openexam_app/core/ui/shore_art.dart';
import 'package:openexam_app/core/ui/stroke_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 第一次打开：说清这是什么，然后拿到让后面一切有意义的两个设置 ——
/// 考试日期和每天的量。三下点完。
///
/// 布局是上中下三段：标题在上、插画在中、按钮在下。
/// 上一版把插画顶在上面、文字全堆到底部，头重脚轻，
/// 视线先撞图再回头找字，读一遍要走两趟。
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
  String? _province;

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(Prefs.dailyGoal, _goal);
    if (_province != null) await prefs.setString(Prefs.province, _province!);
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
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 跳过靠右上，是这一屏唯一的次要出口
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 12, 14, 0),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _finish,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      '跳过',
                      style: TextStyle(fontSize: 13.5, color: t.muted),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pager,
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  _Slide(
                    art: ShoreArt.forBrightness(
                      ShoreArt.start,
                      Theme.of(context).brightness,
                    ),
                    title: '上岸\n是划出来的',
                    body: '18686 道真题在这台手机里\n不用登录，没网也能划',
                  ),
                  _Slide(
                    art: dark ? ShoreArt.nightCalm : ShoreArt.chart,
                    title: '错的题\n自己会记着',
                    body: '答错的进错题本，再答对就出去\n想写两句笔记、标一下错在哪，都行',
                  ),
                  _Setup(
                    goal: _goal,
                    examDate: _examDate,
                    province: _province,
                    onGoal: (v) => setState(() => _goal = v),
                    onProvince: (v) => setState(() => _province = v),
                    onPickDate: _pickDate,
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < 3; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3.5),
                    width: i == _page ? 22 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == _page ? t.accent : t.line,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 26),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _next,
                  child: Text(
                    _page == 0 ? '出发' : (_page == 2 ? '开始划' : '下一个'),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

/// 一屏一件事：标题、两行说明、一幅图。多一句都是在开屏讲课。
class _Slide extends StatelessWidget {
  const _Slide({required this.art, required this.title, required this.body});

  final String art;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return Column(
      children: [
        const SizedBox(height: 22),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: text.displaySmall?.copyWith(
                  fontSize: 30,
                  height: 1.42,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                body,
                textAlign: TextAlign.center,
                style: text.bodyMedium?.copyWith(
                  fontSize: 14.5,
                  height: 1.8,
                  color: t.textSoft,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: Image.asset(
                  art,
                  width: 320,
                  height: 320,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.medium,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 最后一屏收设置，不再讲第三段道理。
class _Setup extends StatelessWidget {
  const _Setup({
    required this.goal,
    required this.examDate,
    required this.province,
    required this.onGoal,
    required this.onProvince,
    required this.onPickDate,
  });

  final int goal;
  final DateTime? examDate;
  final String? province;
  final ValueChanged<int> onGoal;
  final ValueChanged<String> onProvince;
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final days = examDate == null
        ? null
        : examDate!.difference(DateTime.now()).inDays + 1;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 12),
      children: [
        Text(
          '还有三件事',
          style: text.displaySmall?.copyWith(fontSize: 28, height: 1.2),
        ),
        const SizedBox(height: 8),
        Text(
          '随时能改，都在「我的」里',
          style: text.bodyMedium?.copyWith(fontSize: 14.5, color: t.textSoft),
        ),
        const SizedBox(height: 28),

        _Field(label: '一天划几题'),
        Wrap(
          spacing: 9,
          runSpacing: 9,
          children: [
            for (final n in const [10, 20, 30, 50, 80])
              _Pick(
                label: '$n 题',
                on: goal == n,
                onTap: () {
                  onGoal(n);
                  HapticFeedback.selectionClick();
                },
              ),
          ],
        ),

        const SizedBox(height: 26),
        _Field(label: '考哪儿', caption: '选了之后题库优先推你要考的那套卷'),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: kProvinces.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) => _Pick(
              label: kProvinces[i],
              on: province == kProvinces[i],
              onTap: () {
                onProvince(kProvinces[i]);
                HapticFeedback.selectionClick();
              },
            ),
          ),
        ),

        const SizedBox(height: 26),
        _Field(label: '考试哪天'),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onPickDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: t.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: t.shadow,
            ),
            child: Row(
              children: [
                StrokeIcon(AppIcon.calendar, size: 19, color: t.textSoft),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    examDate == null
                        ? '不填也行'
                        : '${examDate!.year} 年 ${examDate!.month} 月 ${examDate!.day} 日'
                            '${days == null ? '' : ' · 还有 $days 天'}',
                    style: text.titleSmall?.copyWith(
                      fontSize: 15,
                      color: examDate == null ? t.muted : t.text,
                      fontFeatures: AppTheme.numeric,
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

class _Field extends StatelessWidget {
  const _Field({required this.label, this.caption});

  final String label;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: text.titleSmall?.copyWith(fontSize: 15.5)),
          if (caption != null) ...[
            const SizedBox(height: 4),
            Text(caption!, style: text.bodySmall),
          ],
        ],
      ),
    );
  }
}

/// 选中态用黄，跟别处的"按下去会发生什么"是同一个颜色。
class _Pick extends StatelessWidget {
  const _Pick({required this.label, required this.on, required this.onTap});

  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        height: 38,
        decoration: BoxDecoration(
          color: on ? t.accent : t.surface,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: on ? t.accent : t.line, width: 1.5),
        ),
        // Container 一旦有 alignment 就会撑满可用宽度，
        // 放进 Wrap 里每颗 chip 就各占一行。用 widthFactor 收回来。
        child: Center(
          widthFactor: 1,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: on ? FontWeight.w700 : FontWeight.w500,
              height: 1,
              color: on ? t.onAccent : t.textSoft,
              fontFeatures: AppTheme.numeric,
            ),
          ),
        ),
      ),
    );
  }
}
