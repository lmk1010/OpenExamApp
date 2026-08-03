import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:openexam_app/core/constants/app_constants.dart';
import 'package:openexam_app/core/theme/app_theme.dart';
import 'package:openexam_app/core/theme/app_tokens.dart';
import 'package:openexam_app/core/theme/theme_controller.dart';
import 'package:openexam_app/core/ui/glass.dart';
import 'package:openexam_app/core/ui/stroke_icons.dart';
import 'package:openexam_app/core/ui/ui_kit.dart';
import 'package:openexam_app/data/db/app_database.dart';
import 'package:openexam_app/features/import/import_page.dart';
import 'package:openexam_app/features/marks/marked_page.dart';
import 'package:openexam_app/features/stats/stats_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 我的 — data, appearance, question-bank management and privacy in one place.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _loading = true;
  int _total = 0;
  int _imported = 0;
  int _answers = 0;
  int _correct = 0;
  int _wrong = 0;
  int _streak = 0;
  int _activeDays = 0;
  int _rate = 0;
  int _count = 20;
  int _marked = 0;
  List<int> _week = const [0, 0, 0, 0, 0, 0, 0];
  String _name = '备考中';
  DateTime? _examDate;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final db = AppDatabase.instance;
    final total = await db.countAll();
    final imported = await db.countImported();
    final answers = await db.countAnswers();
    final wrong = await db.countWrong();
    final marked = await db.countMarked();
    final stats = await db.categoryStats();
    final month = await db.dailyActivity(days: 30);
    final week = await db.dailyActivity();
    final prefs = await SharedPreferences.getInstance();

    var streak = 0;
    for (var i = month.length - 1; i >= 0; i--) {
      if (month[i] == 0) break;
      streak++;
    }
    final done = stats.fold<int>(0, (s, e) => s + e.done);
    final correct = stats.fold<int>(0, (s, e) => s + e.correct);

    if (!mounted) return;
    setState(() {
      _total = total;
      _imported = imported;
      _answers = answers;
      _wrong = wrong;
      _marked = marked;
      _correct = correct;
      _streak = streak;
      _activeDays = month.where((n) => n > 0).length;
      _rate = done == 0 ? 0 : (correct * 100 / done).round();
      _week = week;
      _count = prefs.getInt(Prefs.defaultCount) ?? 20;
      _name = prefs.getString(Prefs.nickname) ?? '备考中';
      final examRaw = prefs.getString(Prefs.examDate);
      _examDate = examRaw == null ? null : DateTime.tryParse(examRaw);
      _loading = false;
    });
  }

  Future<void> _editName() async {
    final name = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NameSheet(current: _name),
    );
    if (name == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(Prefs.nickname, name);
    if (mounted) setState(() => _name = name);
  }

  Future<void> _pickExamDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _examDate ?? now.add(const Duration(days: 60)),
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 1500)),
      helpText: '选择考试日期',
    );
    if (picked == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(Prefs.examDate, picked.toIso8601String());
    if (mounted) setState(() => _examDate = picked);
  }

  int? get _daysLeft {
    if (_examDate == null) return null;
    final now = DateTime.now();
    return _examDate!.difference(DateTime(now.year, now.month, now.day)).inDays;
  }

  Future<void> _setCount(int n) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(Prefs.defaultCount, n);
    if (mounted) setState(() => _count = n);
  }

  Future<void> _confirmClear() async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ConfirmSheet(
        title: '清除练习记录',
        message: '会删除所有答题记录、正确率和错题本，题库本身保留。此操作不可撤销。',
        confirm: '确认清除',
      ),
    );
    if (ok != true) return;
    await AppDatabase.instance.clearHistory();
    if (!mounted) return;
    await _reload();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('练习记录已清除')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingState();

    final text = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.only(bottom: 30),
      children: [
        // Identity + numbers in one glass card, so the page opens with a real
        // block instead of loose text floating on the backdrop.
        Padding(
          padding: const EdgeInsets.fromLTRB(AppTheme.gutter, 14, AppTheme.gutter, 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: GlassDecor.panel(context.tokens, radius: 22),
            child: Column(
              children: [
                Row(
                  children: [
                    _Avatar(name: _name, onTap: _editName),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: _editName,
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    _name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: text.titleMedium?.copyWith(fontSize: 17),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(Icons.edit_outlined,
                                    size: 14, color: context.tokens.muted),
                              ],
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text('打卡 $_activeDays 天 · 题库 $_total 题',
                              style: text.bodySmall),
                        ],
                      ),
                    ),
                    _Countdown(days: _daysLeft, onTap: _pickExamDate),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(height: 1, color: context.tokens.line),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _AccuracyRing(rate: _rate, answered: _answers, correct: _correct),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        children: [
                          _MetricRow(
                            icon: AppIcon.practice,
                            color: context.tokens.brand,
                            label: '累计答题',
                            value: _answers == 0 ? '0' : '$_correct / $_answers',
                          ),
                          const SizedBox(height: 13),
                          _MetricRow(
                            icon: AppIcon.wrongBook,
                            color: context.tokens.danger,
                            label: '待清错题',
                            value: '$_wrong',
                          ),
                          const SizedBox(height: 13),
                          _MetricRow(
                            icon: AppIcon.timer,
                            color: context.tokens.category('shuliang'),
                            label: '连续打卡',
                            value: '$_streak 天',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        // Week activity as a calendar strip — the bar chart read as a stray
        // widget here and carried no more information than this does.
        Padding(
          padding: const EdgeInsets.fromLTRB(AppTheme.gutter, 4, AppTheme.gutter, 20),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: GlassDecor.panel(context.tokens, radius: 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('本周练习', style: text.titleSmall),
                    const Spacer(),
                    Text(
                      _week.fold<int>(0, (a, b) => a + b) == 0
                          ? '还没开练'
                          : '${_week.fold<int>(0, (a, b) => a + b)} 题',
                      style: text.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _WeekStrip(counts: _week),
              ],
            ),
          ),
        ),
        _GroupLabel('外观'),
        _ThemeRow(),
        const RowDivider(),
        _SettingRow(
          icon: AppIcon.numbers,
          title: '默认每组题量',
          value: '$_count 题',
          onTap: () async {
            final picked = await showModalBottomSheet<int>(
              context: context,
              backgroundColor: Colors.transparent,
              builder: (_) => _CountSheet(current: _count),
            );
            if (picked != null) await _setCount(picked);
          },
        ),
        const RowDivider(),
        _SettingRow(
          icon: AppIcon.timer,
          title: '考试日期',
          value: _examDate == null
              ? '未设置'
              : '${_examDate!.year}-${_examDate!.month.toString().padLeft(2, '0')}'
                  '-${_examDate!.day.toString().padLeft(2, '0')}',
          onTap: _pickExamDate,
        ),
        const SizedBox(height: 28),
        _GroupLabel('我的题目'),
        _SettingRow(
          icon: AppIcon.chart,
          title: '学习统计',
          value: '近 30 天',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const StatsPage()),
          ),
        ),
        const RowDivider(),
        _SettingRow(
          icon: AppIcon.wrongBook,
          title: '我的收藏',
          value: _marked == 0 ? '暂无' : '$_marked 题',
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MarkedPage()),
            );
            _reload();
          },
        ),
        const RowDivider(),
        _SettingRow(
          icon: AppIcon.download,
          title: '导入题目',
          value: _imported == 0 ? '未导入' : '已导入 $_imported 题',
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ImportPage(standalone: true)),
            );
            _reload();
          },
        ),
        const RowDivider(),
        _SettingRow(
          icon: AppIcon.trash,
          title: '清除练习记录',
          value: _answers == 0 ? '暂无记录' : '$_answers 条',
          danger: true,
          onTap: _confirmClear,
        ),
        const SizedBox(height: 28),
        _GroupLabel('隐私与关于'),
        _SettingRow(
          icon: AppIcon.privacy,
          title: '数据与隐私',
          value: '全部本地',
          onTap: () => showModalBottomSheet<void>(
            context: context,
            backgroundColor: Colors.transparent,
            builder: (_) => const _InfoSheet(
              title: '数据与隐私',
              body: '这个 App 不联网。题库、答题记录、统计与错题本都存在本机的 SQLite 数据库里，'
                  '不上传服务器、不做任何埋点、没有账号体系。卸载 App 会一并删除这些数据，'
                  '需要保留请先在「导入」页备份自己的题目文件。',
            ),
          ),
        ),
        const RowDivider(),
        _SettingRow(
          icon: AppIcon.info,
          title: '关于 OpenExam',
          value: 'v1.0.1',
          onTap: () => showModalBottomSheet<void>(
            context: context,
            backgroundColor: Colors.transparent,
            builder: (_) => const _InfoSheet(
              title: '关于 OpenExam',
              body: '本地优先的公务员行测刷题工具，与 OpenExam 桌面端同源。'
                  '内置题来自桌面端行测种子库的精选文本题；商业题库请自行合法导入，'
                  'App 不会爬取第三方付费内容。',
            ),
          ),
        ),
      ],
    );
  }
}

/// Seven day cells tinted by volume — a calendar, not a chart.
class _WeekStrip extends StatelessWidget {
  const _WeekStrip({required this.counts});

  final List<int> counts;

  static const _weekday = ['一', '二', '三', '四', '五', '六', '日'];

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final max = counts.fold<int>(0, (m, c) => c > m ? c : m);
    final today = DateTime.now();

    return Row(
      children: [
        for (var i = 0; i < counts.length; i++)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i == counts.length - 1 ? 0 : 7),
              child: Column(
                children: [
                  AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: counts[i] == 0
                            ? (t.name == 'dark'
                                ? Colors.white.withValues(alpha: 0.06)
                                : t.text.withValues(alpha: 0.05))
                            : t.brand.withValues(
                                alpha: max == 0
                                    ? 0.2
                                    : (0.3 + 0.6 * (counts[i] / max)).clamp(0.3, 0.9),
                              ),
                        borderRadius: BorderRadius.circular(13),
                        border: i == counts.length - 1
                            ? Border.all(
                                color: t.brand.withValues(alpha: 0.5),
                                width: 1.4,
                              )
                            : null,
                      ),
                      child: Text(
                        counts[i] == 0 ? '' : '${counts[i]}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: max > 0 && counts[i] / max > 0.45
                              ? Colors.white
                              : t.text,
                          fontFeatures: AppTheme.numeric,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    _weekday[today
                            .subtract(Duration(days: counts.length - 1 - i))
                            .weekday -
                        1],
                    style: text.bodySmall?.copyWith(
                      fontSize: 11,
                      color: i == counts.length - 1 ? t.brand : t.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Gradient avatar carrying the first character of the nickname.
class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, required this.onTap});

  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final initial = name.isEmpty ? '考' : name.characters.first;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(t.brand, Colors.white, 0.18)!,
              t.brand,
              t.category('panduan'),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: t.brand.withValues(alpha: 0.24),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Text(
          initial,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            height: 1,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

/// 距考试 N 天 — the number every 考生 keeps in their head.
class _Countdown extends StatelessWidget {
  const _Countdown({required this.days, required this.onTap});

  final int? days;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    if (days == null) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
          child: Row(
            children: [
              StrokeIcon(AppIcon.timer, size: 16, color: t.brand),
              const SizedBox(width: 6),
              Text('设考试日', style: text.labelMedium?.copyWith(color: t.brand)),
            ],
          ),
        ),
      );
    }

    final over = days! < 0;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                over ? '已结束' : '${days!}',
                style: TextStyle(
                  fontSize: over ? 15 : 26,
                  fontWeight: FontWeight.w700,
                  height: 1,
                  letterSpacing: -0.8,
                  color: t.brand,
                  fontFeatures: AppTheme.numeric,
                ),
              ),
              if (!over) ...[
                const SizedBox(width: 3),
                Text('天', style: text.bodySmall?.copyWith(color: t.brand)),
              ],
            ],
          ),
          const SizedBox(height: 5),
          Text(over ? '考试日期' : '距考试', style: text.bodySmall?.copyWith(fontSize: 11.5)),
        ],
      ),
    );
  }
}

/// Accuracy as a ring — the one metric worth a chart on this page.
class _AccuracyRing extends StatelessWidget {
  const _AccuracyRing({
    required this.rate,
    required this.answered,
    required this.correct,
  });

  final int rate;
  final int answered;
  final int correct;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return SizedBox(
      width: 96,
      height: 96,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: answered == 0 ? 0 : rate / 100),
            duration: const Duration(milliseconds: 650),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => CustomPaint(
              size: const Size(96, 96),
              painter: _RingPainter(
                value: v,
                color: t.brand,
                track: t.name == 'dark'
                    ? Colors.white.withValues(alpha: 0.13)
                    : t.text.withValues(alpha: 0.10),
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    answered == 0 ? '—' : '$rate',
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w700,
                      height: 1,
                      letterSpacing: -0.8,
                      color: t.text,
                      fontFeatures: AppTheme.numeric,
                    ),
                  ),
                  if (answered > 0)
                    Text('%', style: text.bodySmall?.copyWith(fontSize: 13)),
                ],
              ),
              const SizedBox(height: 4),
              Text('正确率', style: text.bodySmall?.copyWith(fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.value,
    required this.color,
    required this.track,
  });

  final double value;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(4, 4, size.width - 8, size.height - 8);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..color = track
      ..isAntiAlias = true;
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2, false, base);

    if (value <= 0) return;
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: math.pi * 1.5,
        colors: [color.withValues(alpha: 0.5), color],
      ).createShader(rect);
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * value, false, arc);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.value != value || old.color != color || old.track != track;
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final AppIcon icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        StrokeIcon(icon, size: 17, color: color),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: text.bodySmall?.copyWith(fontSize: 13))),
        Text(
          value,
          style: text.titleSmall?.copyWith(fontSize: 16, fontFeatures: AppTheme.numeric),
        ),
      ],
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppTheme.gutter, 0, AppTheme.gutter, 6),
      child: Text(text, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
    this.danger = false,
  });

  final AppIcon icon;
  final String title;
  final String value;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final tint = danger ? t.danger : t.textSoft;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.gutter, vertical: 15),
        child: Row(
          children: [
            StrokeIcon(icon, size: 20, color: tint),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: text.titleSmall?.copyWith(color: danger ? t.danger : t.text),
              ),
            ),
            Text(value, style: text.bodySmall),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right, size: 17, color: t.muted),
          ],
        ),
      ),
    );
  }
}

/// Theme picker: 跟随系统 / 浅色 / 深色 as a segmented control.
class _ThemeRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final controller = ThemeController.instance;

    const modes = [
      (mode: ThemeMode.system, icon: AppIcon.auto, label: '跟随系统'),
      (mode: ThemeMode.light, icon: AppIcon.sun, label: '浅色'),
      (mode: ThemeMode.dark, icon: AppIcon.moon, label: '深色'),
    ];

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => Padding(
        padding: const EdgeInsets.fromLTRB(AppTheme.gutter, 8, AppTheme.gutter, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('主题', style: text.titleSmall),
            const SizedBox(height: 12),
            Row(
              children: [
                for (final m in modes)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: m == modes.last ? 0 : 9),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => controller.set(m.mode),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          decoration: controller.mode == m.mode
                              ? GlassDecor.tinted(t, t.brand, radius: 16, glow: false)
                              : GlassDecor.panel(t, radius: 16, raised: false),
                          child: Column(
                            children: [
                              StrokeIcon(
                                m.icon,
                                size: 21,
                                color: controller.mode == m.mode ? Colors.white : t.textSoft,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                m.label,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  height: 1,
                                  color: controller.mode == m.mode ? Colors.white : t.textSoft,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NameSheet extends StatefulWidget {
  const _NameSheet({required this.current});

  final String current;

  @override
  State<_NameSheet> createState() => _NameSheetState();
}

class _NameSheetState extends State<_NameSheet> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.current);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: _SheetShell(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('改个称呼', style: text.titleMedium),
            const SizedBox(height: 14),
            Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: GlassDecor.panel(t, radius: 14, raised: false),
              child: Center(
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  maxLength: 12,
                  style: text.titleSmall,
                  decoration: const InputDecoration(
                    isDense: true,
                    counterText: '',
                    border: InputBorder.none,
                    hintText: '例如：上岸倒计时',
                  ),
                  onSubmitted: (v) => Navigator.of(context).pop(v.trim()),
                ),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  final value = _controller.text.trim();
                  Navigator.of(context).pop(value.isEmpty ? '备考中' : value);
                },
                child: const Text('保存'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountSheet extends StatelessWidget {
  const _CountSheet({required this.current});

  final int current;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    return _SheetShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('默认每组题量', style: text.titleMedium),
          const SizedBox(height: 4),
          for (final n in const [10, 20, 30, 50])
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).pop(n),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 15),
                child: Row(
                  children: [
                    Text(
                      '$n 题',
                      style: text.titleSmall?.copyWith(
                        color: n == current ? t.brand : t.text,
                        fontFeatures: AppTheme.numeric,
                      ),
                    ),
                    const Spacer(),
                    if (n == current) Icon(Icons.check, size: 19, color: t.brand),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoSheet extends StatelessWidget {
  const _InfoSheet({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return _SheetShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: text.titleMedium),
          const SizedBox(height: 12),
          Text(body, style: text.bodyMedium),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('知道了'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmSheet extends StatelessWidget {
  const _ConfirmSheet({
    required this.title,
    required this.message,
    required this.confirm,
  });

  final String title;
  final String message;
  final String confirm;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    return _SheetShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: text.titleMedium),
          const SizedBox(height: 12),
          Text(message, style: text.bodyMedium),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('取消'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: t.danger),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(confirm),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SheetShell extends StatelessWidget {
  const _SheetShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      decoration: BoxDecoration(
        color: t.gradient.last,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: t.glassBorder)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: SafeArea(top: false, child: child),
    );
  }
}
