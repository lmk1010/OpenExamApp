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
import 'package:openexam_app/core/ui/shore.dart';
import 'package:openexam_app/core/ui/shore_art.dart';
import 'package:openexam_app/features/practice/shore_home.dart';
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
    final days = _daysLeft;
    final weekTotal = _week.fold<int>(0, (a, b) => a + b);

    final list = ListView(
      padding: const EdgeInsets.only(bottom: 158),
      children: [
        const SizedBox(height: ShoreGap.top),
        ShoreHeader(
          kicker: days == null
              ? '备考中'
              : (days > 0 ? '离岸 $days 天' : '就在今天'),
          title: '我的',
          actions: [
            ShoreRoundButton(
              icon: StrokeIcon(AppIcon.auto, size: 19, color: t.textSoft),
              onTap: () => _open(const DashboardPage()),
            ),
          ],
        ),
        const SizedBox(height: ShoreGap.titleToBody),
        // 航程总览：跟首页的航程卡同一套语言，只是统计全程不是今天。
        // 上一版三个数字并排一样大，没有主次，看完不知道该记住哪个。
        _VoyageTotal(
          name: _name,
          answers: _answers,
          rate: _rate,
          weekTotal: weekTotal,
          onTapName: _editName,
          onTap: () => _open(const DashboardPage()),
        ),

        // 八个常用入口装进一块卡。
        // 之前它们八个各自浮在背景上，格与格之间空一大截，
        // 跟上面的大卡、下面的列表行凑不成一套语言，整页就散了。
        const SizedBox(height: ShoreGap.section),
        SectionCard(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            children: [
              Row(
                children: [
                  _QuickTile(
                    art: ShoreArt.icoAchieve,
                    label: '成就',
                    badge: _badges == 0 ? null : '$_badges/$_badgeTotal',
                    onTap: () => _open(const AchievementsPage()),
                  ),
                  _QuickTile(
                    art: ShoreArt.icoHistory,
                    label: '记录',
                    onTap: () => _open(const TimelinePage()),
                  ),
                  _QuickTile(
                    art: ShoreArt.icoNote,
                    label: '笔记',
                    badge: _notes == 0 ? null : '$_notes',
                    onTap: () => _open(const NotesPage()),
                  ),
                  _QuickTile(
                    art: ShoreArt.icoMark,
                    label: '收藏',
                    badge: _marked == 0 ? null : '$_marked',
                    onTap: () => _open(const MarkedPage()),
                  ),
                ],
              ),
              Row(
                children: [
                  _QuickTile(
                    art: ShoreArt.icoReport,
                    label: '报告',
                    badge: _reports == 0 ? null : '$_reports',
                    onTap: () => _open(const ReportsPage()),
                  ),
                  _QuickTile(
                    art: ShoreArt.icoStats,
                    label: '统计',
                    onTap: () => _open(const StatsPage()),
                  ),
                  _QuickTile(
                    art: ShoreArt.icoTips,
                    label: '技巧',
                    onTap: () => _open(const TipsPage()),
                  ),
                  _QuickTile(
                    art: ShoreArt.icoFix,
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
          icon: AppIcon.plan,
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
          icon: AppIcon.region,
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
          icon: AppIcon.calendar,
          title: '考试日期',
          value: days == null ? null : (days > 0 ? '还有 $days 天' : '就在今天'),
          onTap: _pickExamDate,
        ),
        _SettingRow(
          icon: AppIcon.target,
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
          icon: AppIcon.stack,
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
          icon: AppIcon.import,
          title: '导入题目',
          value: _imported == 0 ? null : '$_imported 题',
          onTap: () => _open(const ImportPage(standalone: true)),
          active: _detail is ImportPage,
        ),
        _SettingRow(
          icon: AppIcon.health,
          title: '题库体检',
          onTap: () => _open(const BankHealthPage()),
          active: _detail is BankHealthPage,
        ),
        _SettingRow(
          icon: AppIcon.backup,
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
          icon: AppIcon.spark,
          title: 'AI 设置',
          value: _aiConfigured ? '已配置' : null,
          onTap: () async {
            await Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const AiSettingsPage()));
            _refreshAiState();
          },
        ),
        _SettingRow(
          icon: AppIcon.privacy,
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
          icon: AppIcon.info,
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
          icon: AppIcon.privacy,
          title: '清除练习记录',
          danger: true,
          onTap: _confirmClear,
        ),
        _SettingRow(
          icon: AppIcon.info,
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
                          // 角标压在卡上，描边就该是卡的颜色，不是页面的
                          border: Border.all(color: t.surface, width: 1.5),
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

/// 航程总览。插画占上半，一个大数字当主角，其余降成一行小字。
class _VoyageTotal extends StatelessWidget {
  const _VoyageTotal({
    required this.name,
    required this.answers,
    required this.rate,
    required this.weekTotal,
    required this.onTapName,
    required this.onTap,
  });

  final String name;
  final int answers;
  final int rate;
  final int weekTotal;
  final VoidCallback onTapName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final initial = name.isEmpty ? '考' : name.characters.first;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ShoreGap.page),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(26),
            boxShadow: t.shadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 头像压在插画下沿，卡的上下两半才连得上
              Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(26),
                    ),
                    child: Stack(
                      children: [
                        Image.asset(
                          ShoreArt.forBrightness(
                            ShoreArt.arrive,
                            Theme.of(context).brightness,
                          ),
                          height: 112,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          // 素材主体在下方，居中裁只剩一片天
                          alignment: const Alignment(0, 0.6),
                          filterQuality: FilterQuality.medium,
                          errorBuilder: (_, __, ___) =>
                              Container(height: 112, color: t.brandSoft),
                        ),
                        const Positioned(
                          left: 0, right: 0, bottom: -1, child: Waterline(),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 18,
                    bottom: -22,
                    child: GestureDetector(
                      onTap: onTapName,
                      child: Container(
                        width: 52,
                        height: 52,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: t.surface,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF16465A)
                                  .withValues(alpha: 0.16),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Text(
                          initial,
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            height: 1,
                            color: t.onAccentSoft,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 36, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '$answers',
                          style: text.displaySmall?.copyWith(
                            fontSize: 42,
                            height: 1,
                            letterSpacing: -1.4,
                            fontFeatures: AppTheme.numeric,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '题',
                          style: text.titleSmall?.copyWith(
                            fontSize: 14,
                            color: t.muted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      answers == 0
                          ? '还没开始记，划一组就有数了'
                          : '正确率 $rate% · 本周 $weekTotal 题',
                      style: text.bodySmall?.copyWith(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.value,
    this.danger = false,
    this.active = false,
  });

  /// 行首图标。设置行是安静的一列，线性图标比插画合适。
  final AppIcon icon;

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
            StrokeIcon(icon, size: 20, color: danger ? t.danger : t.textSoft, weight: 1.8),
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

/// 明暗切换。原来这里还是一排吉祥物皮肤卡，现在只剩一件事，
/// 就压成一行设置 —— 一件事不值得占 148px 高的横滑列表。
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
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        child: Row(
          children: [
            StrokeIcon(
              controller.icon.toAppIcon(),
              size: 20,
              color: t.textSoft,
              weight: 1.8,
            ),
            const SizedBox(width: 14),
            Expanded(child: Text('主题', style: text.bodyLarge)),
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: t.surfaceAlt,
                borderRadius: BorderRadius.circular(99),
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
                          color: controller.mode == m.mode ? t.accent : null,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Row(
                          children: [
                            StrokeIcon(
                              m.icon,
                              size: 14,
                              weight: 2,
                              color: controller.mode == m.mode
                                  ? t.onAccent
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
                                    ? t.onAccent
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
                              : t.surfaceAlt,
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
        border: Border(top: BorderSide(color: t.lineSoft)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: SafeArea(top: false, child: child),
    );
  }
}
