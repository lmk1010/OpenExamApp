import 'package:flutter/material.dart';
import 'package:openexam_app/core/constants/app_constants.dart';
import 'package:openexam_app/core/constants/categories.dart';
import 'package:openexam_app/core/theme/app_theme.dart';
import 'package:openexam_app/core/theme/app_tokens.dart';
import 'package:openexam_app/core/ui/responsive.dart';
import 'package:openexam_app/core/theme/theme_controller.dart';
import 'package:openexam_app/core/ui/glass.dart';
import 'package:openexam_app/core/ui/stroke_icons.dart';
import 'package:openexam_app/core/ui/ui_kit.dart';
import 'package:openexam_app/data/db/app_database.dart';
import 'package:openexam_app/data/models/question.dart';
import 'package:openexam_app/features/achievements/achievements.dart';
import 'package:openexam_app/core/ai/ai_settings.dart';
import 'package:openexam_app/features/ai/ai_settings_page.dart';
import 'package:openexam_app/features/achievements/achievements_page.dart';
import 'package:openexam_app/features/backup/backup_page.dart';
import 'package:openexam_app/features/bank/bank_health_page.dart';
import 'package:openexam_app/features/feedback/feedback_page.dart';
import 'package:openexam_app/features/profile/dashboard_page.dart';
import 'package:openexam_app/features/import/import_page.dart';
import 'package:openexam_app/features/marks/marked_page.dart';
import 'package:openexam_app/features/notes/notes_page.dart';
import 'package:openexam_app/features/onboarding/onboarding_page.dart';
import 'package:openexam_app/features/plan/presentation/pages/study_plan_page.dart';
import 'package:openexam_app/features/reports/reports_page.dart';
import 'package:openexam_app/features/reports/timeline_page.dart';
import 'package:openexam_app/features/shell/app_shell.dart';
import 'package:openexam_app/features/stats/stats_page.dart';
import 'package:openexam_app/features/tips/tips_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 我的 — data, appearance, question-bank management and privacy in one place.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  /// 「AI 设置」那行显示已配置/未配置。
  bool _aiConfigured = false;

  Future<void> _refreshAiState() async {
    final settings = await AiSettingsStore.load();
    if (!mounted) return;
    setState(() => _aiConfigured = settings.isConfigured);
  }

  bool _loading = true;
  int _total = 0;
  int _imported = 0;
  int _answers = 0;
  int _rate = 0;
  int _count = 20;
  int _marked = 0;
  int _reports = 0;
  int _goal = 30;
  int _notes = 0;
  int _feedback = 0;
  int _badges = 0;
  int _badgeTotal = 0;
  String? _province;
  List<int> _week = const [0, 0, 0, 0, 0, 0, 0];
  String _name = '备考中';
  DateTime? _examDate;

  @override
  void initState() {
    super.initState();
    _reload();
    _refreshAiState();
  }

  Future<void> _reload() async {
    // 十个查询彼此不依赖，并发发出去，别排队等
    final db = AppDatabase.instance;
    final results = await Future.wait([
      db.countAll(),
      db.countImported(),
      db.countAnswers(),
      db.countMarked(),
      db.listReports(limit: 200),
      db.countNotes(),
      db.countFeedback(),
      Achievements.evaluate(),
      db.categoryStats(),
      db.dailyActivity(),
    ]);
    final total = results[0] as int;
    final imported = results[1] as int;
    final answers = results[2] as int;
    final marked = results[3] as int;
    final reports = results[4] as List;
    final notes = results[5] as int;
    final feedback = results[6] as int;
    final badges = results[7] as List<AchievementBadge>;
    final stats = results[8] as List<CategoryStat>;
    final week = results[9] as List<int>;
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
      _feedback = feedback;
      _badges = badges.where((b) => b.unlocked).length;
      _badgeTotal = badges.length;
      _rate = done == 0 ? 0 : (correct * 100 / done).round();
      _week = week;
      _count = prefs.getInt(Prefs.defaultCount) ?? 20;
      _goal = prefs.getInt(Prefs.dailyGoal) ?? 30;
      _province = prefs.getString(Prefs.province);
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

  /// 宽屏右栏当前显示的页面。窄屏恒为空，走正常 push。
  Widget? _detail;

  /// 窄屏 push，宽屏换右栏。
  void _open(Widget page) {
    if (context.isExpanded) {
      setState(() => _detail = page);
      return;
    }
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => page))
        .then((_) => _reload());
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingState();

    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final days = _daysLeft;
    final weekTotal = _week.fold<int>(0, (a, b) => a + b);

    final list = ListView(
      padding: const EdgeInsets.only(bottom: 140),
      children: [
        // This is a page, so it opens with a page title like every other tab.
        const PageTitleBar(title: '我的'),
        // 顶部大卡：身份 + 三个真正会看的数字。
        // 原来这里是一行小头像加一行灰字，再跟一整屏清一色的设置行，
        // 空间浪费得厉害，也没有主次。
        Padding(
          padding: const EdgeInsets.fromLTRB(AppTheme.gutter, 2, AppTheme.gutter, 0),
          child: PressableCard(
            scale: 0.985,
            onTap: () => _open(const DashboardPage()),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: t.name == 'dark'
                              ? [
                                  t.brand.withValues(alpha: 0.32),
                                  t.brand.withValues(alpha: 0.09),
                                ]
                              : [
                                  t.brand.withValues(alpha: 0.18),
                                  t.brand.withValues(alpha: 0.05),
                                ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: -22,
                    bottom: -24,
                    width: 118,
                    height: 118,
                    child: Opacity(
                      opacity: t.name == 'dark' ? 0.20 : 0.24,
                      child: Image.asset(
                        'assets/art/hero_plan.png',
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _Avatar(name: _name, onTap: _editName),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _name,
                                    style: text.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: t.text,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    days == null
                                        ? '还没设考试日期'
                                        : (days > 0 ? '距考试 $days 天' : '考试就在今天'),
                                    style: text.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right, size: 18, color: t.muted),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            _BigStat(value: '$_answers', label: '总答题'),
                            _BigStat(
                              value: _answers == 0 ? '—' : '$_rate%',
                              label: '正确率',
                            ),
                            _BigStat(value: '$weekTotal', label: '本周'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // 八个常用入口装进一块卡。
        // 之前它们八个各自浮在背景上，格与格之间空一大截，
        // 跟上面的大卡、下面的列表行凑不成一套语言，整页就散了。
        const SizedBox(height: 14),
        SectionCard(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            children: [
              Row(
                children: [
                  _QuickTile(
                    art: 'assets/art/ic_achieve.png',
                    label: '成就',
                    badge: _badges == 0 ? null : '$_badges/$_badgeTotal',
                    onTap: () => _open(const AchievementsPage()),
                  ),
                  _QuickTile(
                    art: 'assets/art/ic_history.png',
                    label: '记录',
                    onTap: () => _open(const TimelinePage()),
                  ),
                  _QuickTile(
                    art: 'assets/art/ic_note.png',
                    label: '笔记',
                    badge: _notes == 0 ? null : '$_notes',
                    onTap: () => _open(const NotesPage()),
                  ),
                  _QuickTile(
                    art: 'assets/art/ic_bookmark.png',
                    label: '收藏',
                    badge: _marked == 0 ? null : '$_marked',
                    onTap: () => _open(const MarkedPage()),
                  ),
                ],
              ),
              Row(
                children: [
                  _QuickTile(
                    art: 'assets/art/ic_report.png',
                    label: '报告',
                    badge: _reports == 0 ? null : '$_reports',
                    onTap: () => _open(const ReportsPage()),
                  ),
                  _QuickTile(
                    art: 'assets/art/ic_stats.png',
                    label: '统计',
                    onTap: () => _open(const StatsPage()),
                  ),
                  _QuickTile(
                    art: 'assets/art/ic_tips.png',
                    label: '技巧',
                    onTap: () => _open(const TipsPage()),
                  ),
                  _QuickTile(
                    art: 'assets/art/ic_fix.png',
                    label: '纠错',
                    badge: _feedback == 0 ? null : '$_feedback',
                    onTap: () => _open(const FeedbackPage()),
                  ),
                ],
              ),
            ],
          ),
        ),

        // ── 备考 ───────────────────────────────────────────────
        SectionCard(
          title: '备考',
          child: Column(children: [
        _SettingRow(
          art: 'assets/art/ic_plan.png',
          title: '复习计划',
          onTap: () {
            final planTab = AppShell.planTab;
            if (planTab != null) {
              AppShell.jumpTo.value = planTab;
              return;
            }
            _open(StudyPlanPage(onRunTask: (_) async {}));
          },
        ),
        _SettingRow(
          art: 'assets/art/ic_region.png',
          title: '报考地区',
          value: _province,
          onTap: () async {
            final picked = await showModalBottomSheet<String>(
              context: context,
              backgroundColor: Colors.transparent,
              builder: (_) => _ProvinceSheet(current: _province),
            );
            if (picked == null) return;
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(Prefs.province, picked);
            if (mounted) setState(() => _province = picked);
          },
        ),
        _SettingRow(
          art: 'assets/art/ic_calendar.png',
          title: '考试日期',
          value: days == null ? null : (days > 0 ? '还有 $days 天' : '就在今天'),
          onTap: _pickExamDate,
        ),
        _SettingRow(
          art: 'assets/art/ic_target.png',
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
        _SettingRow(
          art: 'assets/art/ic_stack.png',
          title: '每组题量',
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

          ]),
        ),

        // ── 题库 ───────────────────────────────────────────────
        SectionCard(
          title: '题库',
          child: Column(children: [
        _SettingRow(
          art: 'assets/art/ic_import.png',
          title: '导入题目',
          value: _imported == 0 ? null : '$_imported 题',
          onTap: () => _open(const ImportPage()),
          active: _detail is ImportPage,
        ),
        _SettingRow(
          art: 'assets/art/ic_health.png',
          title: '题库体检',
          onTap: () => _open(const BankHealthPage()),
          active: _detail is BankHealthPage,
        ),
        _SettingRow(
          art: 'assets/art/ic_backup.png',
          title: '备份与恢复',
          onTap: () => _open(const BackupPage()),
          active: _detail is BackupPage,
        ),

          ]),
        ),

        // ── 应用 ───────────────────────────────────────────────
        SectionCard(
          title: '应用',
          child: Column(children: [
            _ThemeRow(),
        _SettingRow(
          art: 'assets/art/ic_ai.png',
          title: 'AI 设置',
          value: _aiConfigured ? '已配置' : null,
          onTap: () async {
            await Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const AiSettingsPage()));
            _refreshAiState();
          },
        ),
        _SettingRow(
          art: 'assets/art/ic_privacy.png',
          title: '数据与隐私',
          onTap: () => showModalBottomSheet<void>(
            context: context,
            backgroundColor: Colors.transparent,
            builder: (_) => const _InfoSheet(
              title: '数据与隐私',
              body: '题库、答题记录、统计与错题本都存在本机的 SQLite 数据库里，'
                  '不上传服务器、不做任何埋点、没有账号体系。\n\n'
                  '唯一会联网的是 AI 功能（申论批改、拍照识题）：只有你主动触发时才发请求，'
                  '直接发往你自己填的服务商，API Key 存在本机。不配置就完全离线。',
            ),
          ),
        ),
        _SettingRow(
          art: 'assets/art/ic_about.png',
          title: '关于',
          value: 'v1.0.1',
          onTap: () => showModalBottomSheet<void>(
            context: context,
            backgroundColor: Colors.transparent,
            builder: (_) => _InfoSheet(
              title: '关于 OpenExam · $_total 题在库',
              body: '本地优先的公务员行测刷题工具，与 OpenExam 桌面端同源。\n\n'
                  '商业题库请自行合法导入，App 不会爬取第三方付费内容。',
            ),
          ),
        ),
        _SettingRow(
          art: 'assets/art/ic_privacy.png',
          title: '清除练习记录',
          danger: true,
          onTap: _confirmClear,
        ),
        _SettingRow(
          art: 'assets/art/ic_about.png',
          title: '重看引导',
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
          ]),
        ),
      ],
    );

    // 平板横屏：左边列表，右边直接把选中的那一页渲染出来。一列设置项孤零零
    // 挂在 1200px 宽的屏幕上，右边空着，谁看都别扭。
    if (!context.isExpanded) {
      return ReadableWidth(child: list);
    }
    return Row(
      children: [
        SizedBox(width: 380, child: list),
        Container(width: 1, color: context.tokens.line.withValues(alpha: 0.5)),
        Expanded(child: _detail ?? const DashboardPage()),
      ],
    );
  }
}

class _BigStat extends StatelessWidget {
  const _BigStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: text.headlineSmall?.copyWith(
              color: t.text,
              fontWeight: FontWeight.w700,
              height: 1,
              fontFeatures: AppTheme.numeric,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: text.bodySmall?.copyWith(fontSize: 11)),
        ],
      ),
    );
  }
}

/// 宫格入口：一个大图标一个词。
///
/// 之前每格套了一层卡片底，图标只有 22px，卡里全是空白 —— 比例整个反了。
/// 现在去掉卡片，图标占主体，靠对齐的网格本身建立秩序。
class _QuickTile extends StatelessWidget {
  const _QuickTile({
    required this.art,
    required this.label,
    required this.onTap,
    this.badge,
  });

  /// 图标素材路径。
  final String art;
  final String label;
  final VoidCallback onTap;

  /// 有内容才显示的角标，没有就不占位。
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    return Expanded(
      child: PressableCard(
        scale: 0.93,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Image.asset(
                    art,
                    width: 48,
                    height: 48,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (_, __, ___) => SizedBox(
                      width: 48,
                      height: 48,
                      child: Icon(Icons.widgets_outlined, color: t.brand),
                    ),
                  ),
                  if (badge != null)
                    Positioned(
                      right: -6,
                      top: -2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: t.brand,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: t.bg, width: 1.5),
                        ),
                        child: Text(
                          badge!,
                          style: const TextStyle(
                            fontSize: 9.5,
                            height: 1.3,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: text.bodySmall?.copyWith(
                  color: t.text,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, required this.onTap});

  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final initial = name.isEmpty ? '考' : name.characters.first;
    final dark = t.name == 'dark';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          // 卡片本身已经是渐变了。头像再叠三色渐变加投影就会浮在卡上面、
          // 显得是两张图拼的。这里只用一层薄底，让它落进卡里。
          color: dark
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.62),
        ),
        child: Text(
          initial,
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w700,
            height: 1,
            color: dark ? Colors.white : t.brand,
          ),
        ),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.art,
    required this.title,
    required this.onTap,
    this.value,
    this.danger = false,
    this.active = false,
  });

  /// 行首图标素材。
  final String art;

  final String title;

  /// 右侧的值。没有实质内容就传 null —— 一整列「暂无」「未设置」
  /// 只会把页面填满噪音，真正有数的那几行反而看不见了。
  final String? value;

  final VoidCallback onTap;
  final bool danger;

  /// 宽屏主从视图里，右栏正在显示的那一项要标出来。
  final bool active;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        color: active ? t.brand.withValues(alpha: 0.08) : null,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            Image.asset(
              art,
              width: 26,
              height: 26,
              filterQuality: FilterQuality.high,
              // 素材缺失时留个占位，别把整行挤变形
              errorBuilder: (_, __, ___) => const SizedBox(width: 26, height: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: text.bodyLarge?.copyWith(
                  color: danger ? t.danger : t.text,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (value != null && value!.isNotEmpty)
              Text(value!, style: text.bodySmall),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, size: 16, color: t.muted.withValues(alpha: 0.6)),
          ],
        ),
      ),
    );
  }
}

/// Theme picker: large character cards for cute palettes + classic light/dark.
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                StrokeIcon(controller.icon.toAppIcon(), size: 20, color: t.textSoft),
                const SizedBox(width: 14),
                Expanded(child: Text('主题', style: text.titleSmall)),
                Text(
                  controller.label,
                  style: text.bodySmall?.copyWith(color: t.muted),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 148,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final p in ThemeController.palettes) ...[
                    GestureDetector(
                      onTap: () => controller.setPalette(p.id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 118,
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
                        decoration: BoxDecoration(
                          color: controller.palette == p.id
                              ? t.brand.withValues(alpha: 0.12)
                              : t.surfaceAlt.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: controller.palette == p.id
                                ? t.brand
                                : t.line.withValues(alpha: 0.45),
                            width: controller.palette == p.id ? 1.8 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: ColoredBox(
                                  color: Colors.white.withValues(alpha: 0.55),
                                  child: p.asset == null
                                      ? Center(
                                          child: Icon(
                                            Icons.contrast,
                                            size: 36,
                                            color: t.brand,
                                          ),
                                        )
                                      : Image.asset(
                                          p.asset!,
                                          fit: BoxFit.contain,
                                          filterQuality: FilterQuality.high,
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              p.label,
                              style: text.labelMedium?.copyWith(
                                color: controller.palette == p.id
                                    ? t.brand
                                    : t.text,
                                fontWeight: FontWeight.w700,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (controller.palette == 'classic') ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: Container(
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 11,
                              vertical: 7,
                            ),
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
              ),
            ] else ...[
              const SizedBox(height: 10),
              Text(
                controller.palette == 'guga'
                    ? '首页会换上咕咕嘎嘎插画；完成今日目标时切庆祝姿势。'
                    : '官方皮卡丘形象受限，用的是原创闪电黄伴读狐插画。',
                style: text.bodySmall?.copyWith(fontSize: 12, height: 1.4),
              ),
            ],
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

/// Region picker — drives the 本省真题 card and the 题库 default filter.
class _ProvinceSheet extends StatelessWidget {
  const _ProvinceSheet({required this.current});

  final String? current;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    return _SheetShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('报考地区', style: text.titleMedium),
          const SizedBox(height: 6),
          Text('用来优先推荐对应的真题卷', style: text.bodySmall),
          const SizedBox(height: 14),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.45,
            ),
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final p in kProvinces)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => Navigator.of(context).pop(p),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: p == current
                              ? t.brand.withValues(alpha: 0.15)
                              : t.glass,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: p == current
                                ? t.brand.withValues(alpha: 0.5)
                                : Colors.transparent,
                          ),
                        ),
                        child: Text(
                          p,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            height: 1,
                            color: p == current ? t.brand : t.textSoft,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
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
