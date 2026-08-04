import 'package:flutter/material.dart';
import 'package:openexam_app/core/constants/app_constants.dart';
import 'package:openexam_app/core/theme/app_theme.dart';
import 'package:openexam_app/core/theme/app_tokens.dart';
import 'package:openexam_app/core/theme/theme_controller.dart';
import 'package:openexam_app/core/ui/glass.dart';
import 'package:openexam_app/core/ui/stroke_icons.dart';
import 'package:openexam_app/core/ui/ui_kit.dart';
import 'package:openexam_app/data/db/app_database.dart';
import 'package:openexam_app/features/backup/backup_page.dart';
import 'package:openexam_app/features/import/import_page.dart';
import 'package:openexam_app/features/marks/marked_page.dart';
import 'package:openexam_app/features/notes/notes_page.dart';
import 'package:openexam_app/features/onboarding/onboarding_page.dart';
import 'package:openexam_app/features/reports/reports_page.dart';
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
  int _activeDays = 0;
  int _rate = 0;
  int _count = 20;
  int _marked = 0;
  int _reports = 0;
  int _goal = 30;
  int _notes = 0;
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
    final marked = await db.countMarked();
    final reports = await db.listReports(limit: 200);
    final notes = await db.countNotes();
    final stats = await db.categoryStats();
    final month = await db.dailyActivity(days: 30);
    final week = await db.dailyActivity();
    final prefs = await SharedPreferences.getInstance();

    final done = stats.fold<int>(0, (s, e) => s + e.done);
    final correct = stats.fold<int>(0, (s, e) => s + e.correct);

    if (!mounted) return;
    setState(() {
      _total = total;
      _imported = imported;
      _answers = answers;
      _marked = marked;
      _reports = reports.length;
      _notes = notes;
      _activeDays = month.where((n) => n > 0).length;
      _rate = done == 0 ? 0 : (correct * 100 / done).round();
      _week = week;
      _count = prefs.getInt(Prefs.defaultCount) ?? 20;
      _goal = prefs.getInt(Prefs.dailyGoal) ?? 30;
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

    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final days = _daysLeft;
    final weekTotal = _week.fold<int>(0, (a, b) => a + b);

    return ListView(
      padding: const EdgeInsets.only(bottom: 30),
      children: [
        // This is a page, so it opens with a page title like every other tab.
        Padding(
          padding: const EdgeInsets.fromLTRB(AppTheme.gutter, 18, AppTheme.gutter, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('我的', style: text.displaySmall?.copyWith(fontSize: 26)),
              const SizedBox(height: 7),
              Text(
                '本地备考 · $_total 题在库',
                style: text.bodySmall?.copyWith(fontSize: 13),
              ),
            ],
          ),
        ),
        // Account row: who you are, one tap to rename.
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _editName,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.gutter, vertical: 8),
            child: Row(
              children: [
                _Avatar(name: _name, onTap: _editName),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_name, style: text.titleSmall?.copyWith(fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(
                        _answers == 0
                            ? '还没开始练习'
                            : '打卡 $_activeDays 天 · 答题 $_answers · 正确率 $_rate%',
                        style: text.bodySmall,
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, size: 17, color: t.muted),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        Padding(
          padding: const EdgeInsets.fromLTRB(AppTheme.gutter, 0, AppTheme.gutter, 12),
          child: Row(
            children: [
              Text('本周练习', style: text.titleSmall),
              const Spacer(),
              Text(weekTotal == 0 ? '还没开练' : '$weekTotal 题', style: text.bodySmall),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.gutter),
          child: _WeekStrip(counts: _week, goal: _goal),
        ),
        const SizedBox(height: 28),
        const _GroupLabel('学习'),
        _SettingRow(
          icon: AppIcon.papers,
          title: '成绩报告',
          value: _reports == 0 ? '暂无' : '$_reports 份',
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ReportsPage()),
            );
            _reload();
          },
        ),
        const RowDivider(),
        _SettingRow(
          icon: AppIcon.chart,
          title: '学习统计',
          value: _answers == 0 ? '暂无数据' : '正确率 $_rate%',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const StatsPage()),
          ),
        ),
        const RowDivider(),
        _SettingRow(
          icon: AppIcon.speech,
          title: '我的笔记',
          value: _notes == 0 ? '暂无' : '$_notes 条',
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotesPage()),
            );
            _reload();
          },
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
          icon: AppIcon.timer,
          title: '考试日期',
          value: days == null
              ? '未设置'
              : (days >= 0 ? '还有 $days 天' : '已结束'),
          onTap: _pickExamDate,
        ),
        const RowDivider(),
        _SettingRow(
          icon: AppIcon.chart,
          title: '每日目标',
          value: '$_goal 题',
          onTap: () async {
            final picked = await showModalBottomSheet<int>(
              context: context,
              backgroundColor: Colors.transparent,
              builder: (_) => _GoalSheet(current: _goal),
            );
            if (picked == null) return;
            final prefs = await SharedPreferences.getInstance();
            await prefs.setInt(Prefs.dailyGoal, picked);
            if (mounted) setState(() => _goal = picked);
          },
        ),
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
        const SizedBox(height: 28),
        const _GroupLabel('外观'),
        _ThemeRow(),
        const SizedBox(height: 28),
        const _GroupLabel('题库'),
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
          icon: AppIcon.privacy,
          title: '备份与恢复',
          value: '本地文件',
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const BackupPage()),
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
        const _GroupLabel('隐私与关于'),
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
                  '不上传服务器、不做任何埋点、没有账号体系。昵称和考试日期也只存在本机。',
            ),
          ),
        ),
        const RowDivider(),
        _SettingRow(
          icon: AppIcon.play,
          title: '重看引导',
          value: '3 屏',
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => OnboardingPage(
                  onDone: () => Navigator.of(context).maybePop(),
                ),
              ),
            );
            _reload();
          },
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
              body: '本地优先的公务员行测刷题工具，与 OpenExam 桌面端同源，'
                  '内置 15936 道行测真题与 137 套真题卷（含图形题）。'
                  '商业题库请自行合法导入，App 不会爬取第三方付费内容。',
            ),
          ),
        ),
      ],
    );
  }
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({required this.counts, required this.goal});

  final List<int> counts;

  /// Days that reached the daily target get the solid brand fill.
  final int goal;

  static const _weekday = ['一', '二', '三', '四', '五', '六', '日'];

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
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
                                alpha: goal <= 0 || counts[i] >= goal
                                    ? 1
                                    : (0.3 + 0.5 * (counts[i] / goal)).clamp(0.3, 0.85),
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
                          color: goal > 0 && counts[i] / goal > 0.5
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

/// Theme picker as a compact inline segment — three big cards were louder
/// than the setting deserves.
class _ThemeRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final controller = ThemeController.instance;

    const modes = [
      (mode: ThemeMode.system, icon: AppIcon.auto, label: '自动'),
      (mode: ThemeMode.light, icon: AppIcon.sun, label: '浅色'),
      (mode: ThemeMode.dark, icon: AppIcon.moon, label: '深色'),
    ];

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.gutter,
          vertical: 11,
        ),
        child: Row(
          children: [
            StrokeIcon(controller.icon.toAppIcon(), size: 20, color: t.textSoft),
            const SizedBox(width: 14),
            Expanded(child: Text('主题', style: text.titleSmall)),
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: t.name == 'dark'
                    ? Colors.white.withValues(alpha: 0.07)
                    : t.text.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final m in modes)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => controller.set(m.mode),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                        decoration: BoxDecoration(
                          color: controller.mode == m.mode ? t.brand : null,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            StrokeIcon(
                              m.icon,
                              size: 14,
                              weight: 2,
                              color: controller.mode == m.mode
                                  ? Colors.white
                                  : t.muted,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              m.label,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                height: 1,
                                color: controller.mode == m.mode
                                    ? Colors.white
                                    : t.textSoft,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
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

class _GoalSheet extends StatelessWidget {
  const _GoalSheet({required this.current});

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
          Text('每日目标', style: text.titleMedium),
          const SizedBox(height: 6),
          Text('在职备考建议 20–30 题，全职冲刺 60 题以上', style: text.bodySmall),
          for (final n in const [10, 20, 30, 50, 80, 100])
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).pop(n),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
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
