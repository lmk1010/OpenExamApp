import 'package:flutter/material.dart';
import 'package:openexam_app/core/i18n/locale_controller.dart';
import 'package:openexam_app/l10n/app_localizations.dart';
import 'package:openexam_app/core/constants/app_constants.dart';
import 'package:openexam_app/core/constants/categories.dart';
import 'package:openexam_app/core/theme/app_theme.dart';
import 'package:openexam_app/core/theme/app_tokens.dart';
import 'package:openexam_app/core/ui/ambient.dart';
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
import 'package:openexam_app/features/ai/ai_usage_page.dart';
import 'package:openexam_app/features/bank/category_manage_page.dart';
import 'package:openexam_app/features/profile/domain/exam_profile.dart';
import 'package:openexam_app/features/profile/presentation/exam_profile_page.dart';
import 'package:openexam_app/features/import/import_page.dart';
import 'package:openexam_app/features/marks/marked_page.dart';
import 'package:openexam_app/features/notes/notes_page.dart';
import 'package:openexam_app/features/onboarding/onboarding_page.dart';
import 'package:openexam_app/features/plan/presentation/pages/study_plan_page.dart';
import 'package:openexam_app/features/reports/reports_page.dart';
import 'package:openexam_app/features/shell/app_shell.dart';
import 'package:openexam_app/core/ui/shore.dart';
import 'package:openexam_app/core/ui/shore_art.dart';
import 'package:openexam_app/features/practice/shore_home.dart';
import 'package:openexam_app/features/shell/tab_reload.dart';
import 'package:openexam_app/features/stats/stats_page.dart';
import 'package:openexam_app/features/vocab/data/vocab_repository.dart';
import 'package:openexam_app/features/vocab/presentation/vocab_page.dart';
import 'package:openexam_app/features/tips/tips_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 我的 — data, appearance, question-bank management and privacy in one place.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with TabReload {
  @override
  AppTab get tab => AppTab.profile;

  /// 切回这一栏就重读一遍 —— IndexedStack 会把页面一直留着，
  /// 不重读的话显示的还是进 app 那一刻的数字。
  @override
  Future<void> onTabShown() => _reload();

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
  int _marked = 0;
  int _reports = 0;
  int _vocabDue = 0;
  int _goal = 30;
  int _notes = 0;
  int _feedback = 0;
  int _badges = 0;
  int _badgeTotal = 0;
  List<int> _week = const [0, 0, 0, 0, 0, 0, 0];
  /// 空串 = 用户没起过名字，显示时兜底成本地化的默认称呼。
  /// 不能在字段初始化器里取 AppL —— 那时候还没有 context。
  String _name = '';
  DateTime? _examDate;

  @override
  void initState() {
    super.initState();
    _reload();
    _refreshAiState();
  }

  Future<void> _reload() async {
    // 这些查询彼此不依赖，并发发出去，别排队等。
    final db = AppDatabase.instance;
    // 徽章名要按当前语言算，可 _reload 是 initState 里发起的：第一个 await
    // 之前这段代码还在 initState 里跑，那时候 AppL.of(context) 会抛
    // "called before initState() completed"。先让出一帧再取。
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    final l = AppL.of(context);
    await VocabRepository.instance.ensureSeeded();
    final results = await Future.wait([
      db.countAll(),
      db.countImported(),
      db.countAnswers(),
      db.countMarked(),
      db.listReports(limit: 200),
      db.countNotes(),
      db.countFeedback(),
      Achievements.evaluate(l),
      db.categoryStats(),
      db.dailyActivity(),
      VocabRepository.instance.stats(),
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
    final vocab =
        results[10] as ({int total, int due, int learning, int mastered});
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
      _vocabDue = vocab.due;
      _goal = prefs.getInt(Prefs.dailyGoal) ?? 30;
      _name = prefs.getString(Prefs.nickname) ?? '';
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
      builder: (_) => _NameSheet(
        current: _name.isEmpty ? AppL.of(context).profileDefaultName : _name,
      ),
    );
    if (name == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(Prefs.nickname, name);
    if (mounted) setState(() => _name = name);
  }

  int? get _daysLeft {
    if (_examDate == null) return null;
    final now = DateTime.now();
    return _examDate!.difference(DateTime(now.year, now.month, now.day)).inDays;
  }

  Future<void> _confirmClear() async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ConfirmSheet(
        title: AppL.of(context).profileClearTitle,
        message: AppL.of(context).profileClearBody,
        confirm: AppL.of(context).profileClearConfirm,
      ),
    );
    if (ok != true) return;
    await AppDatabase.instance.clearHistory();
    if (!mounted) return;
    await _reload();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppL.of(context).profileClearDone)),
    );
  }

  /// 关于页。
  ///
  /// 「清除练习记录」和「重看引导」收在这儿：前者不可逆，摆在能误触的地方
  /// 本身就不对；后者一年用一次，不值得占首屏一行。
  Future<void> _openAbout() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final t = ctx.tokens;
        final text = Theme.of(ctx).textTheme;
        return Container(
          decoration: BoxDecoration(
            color: t.gradient.last,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(top: BorderSide(color: t.lineSoft)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppL.of(context).profileAboutTitle(_total),
                    style: text.titleMedium),
                const SizedBox(height: 8),
                Text(
                  AppL.of(context).profileAboutBody,
                  style: text.bodySmall,
                ),
                const SizedBox(height: 16),
                Divider(color: t.lineSoft, height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(AppL.of(context).profileReplayOnboarding, style: text.titleSmall),
                  onTap: () async {
                    Navigator.of(ctx).pop();
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
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(AppL.of(context).profileClearTitle,
                      style: text.titleSmall?.copyWith(color: t.danger)),
                  subtitle: Text(AppL.of(context).profileClearHint,
                      style: text.bodySmall),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _confirmClear();
                  },
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
        );
      },
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
              ? AppL.of(context).profileDefaultName
              : (days > 0 ? AppL.of(context).profileDaysLeft(days) : AppL.of(context).profileToday),
          title: AppL.of(context).profileTab,
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
          name: _name.isEmpty ? AppL.of(context).profileDefaultName : _name,
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
                    label: AppL.of(context).profileBadges,
                    badge: _badges == 0 ? null : '$_badges/$_badgeTotal',
                    onTap: () => _open(const AchievementsPage()),
                  ),
                  if (ExamProfileStore.current.has(ExamFeature.vocab))
                    _QuickTile(
                      art: ShoreArt.icoVocab,
                      label: AppL.of(context).profileVocab,
                      badge: _vocabDue == 0 ? null : '$_vocabDue',
                      onTap: () => _open(const VocabPage()),
                    ),
                  _QuickTile(
                    art: ShoreArt.icoNote,
                    label: AppL.of(context).profileNotes,
                    badge: _notes == 0 ? null : '$_notes',
                    onTap: () => _open(const NotesPage()),
                  ),
                  _QuickTile(
                    art: ShoreArt.icoMark,
                    label: AppL.of(context).profileMarks,
                    badge: _marked == 0 ? null : '$_marked',
                    onTap: () => _open(const MarkedPage()),
                  ),
                ],
              ),
              Row(
                children: [
                  _QuickTile(
                    art: ShoreArt.icoHistory,
                    label: AppL.of(context).profileReports,
                    badge: _reports == 0 ? null : '$_reports',
                    onTap: () => _open(const ReportsPage()),
                  ),
                  _QuickTile(
                    art: ShoreArt.icoStats,
                    label: AppL.of(context).profileStats,
                    onTap: () => _open(const StatsPage()),
                  ),
                  if (ExamProfileStore.current.has(ExamFeature.tips))
                    _QuickTile(
                      art: ShoreArt.icoTips,
                      label: AppL.of(context).profileTips,
                      onTap: () => _open(const TipsPage()),
                    ),
                  _QuickTile(
                    art: ShoreArt.icoFix,
                    label: AppL.of(context).profileFeedback,
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
          title: AppL.of(context).profileSectionExam,
          child: Column(children: [
        _SettingRow(
          icon: AppIcon.papers,
          title: AppL.of(context).profileFeatures,
          value: AppL.of(context).profileFeaturesOn(ExamProfileStore.current.features.length),
          // _open 回来会走 _reload，名字改了这一行跟着更新
          onTap: () => _open(const ExamProfilePage()),
        ),
        _SettingRow(
          icon: AppIcon.plan,
          title: AppL.of(context).profilePlan,
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
          icon: AppIcon.target,
          title: AppL.of(context).profilePrefs,
          value: AppL.of(context).profileDailyGoalValue(_goal),
          onTap: () => _open(const PracticePrefsPage()),
        ),

          ]),
        ),

        // ── 题库 ───────────────────────────────────────────────
        SectionCard(
          title: AppL.of(context).profileSectionBank,
          child: Column(children: [
        _SettingRow(
          icon: AppIcon.import,
          title: AppL.of(context).profileImport,
          value: _imported == 0 ? null : AppL.of(context).profileImportedCount(_imported),
          onTap: () => _open(const ImportPage(standalone: true)),
          active: _detail is ImportPage,
        ),
        _SettingRow(
          icon: AppIcon.logic,
          title: AppL.of(context).profileBankManage,
          onTap: () => _open(const CategoryManagePage()),
        ),
        _SettingRow(
          icon: AppIcon.health,
          title: AppL.of(context).profileBankHealth,
          onTap: () => _open(const BankHealthPage()),
          active: _detail is BankHealthPage,
        ),
        _SettingRow(
          icon: AppIcon.backup,
          title: AppL.of(context).profileBackup,
          onTap: () => _open(const BackupPage()),
          active: _detail is BackupPage,
        ),

          ]),
        ),

        // ── 应用 ───────────────────────────────────────────────
        SectionCard(
          title: AppL.of(context).profileSectionApp,
          child: Column(children: [
            _ThemeRow(),
            const _LanguageRow(),
        _SettingRow(
          icon: AppIcon.spark,
          title: AppL.of(context).profileAiSettings,
          value: _aiConfigured ? AppL.of(context).profileConfigured : null,
          onTap: () async {
            await Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const AiSettingsPage()));
            _refreshAiState();
          },
        ),
        _SettingRow(
          icon: AppIcon.chart,
          title: AppL.of(context).profileAiUsage,
          onTap: () => _open(const AiUsagePage()),
        ),
        _SettingRow(
          icon: AppIcon.privacy,
          title: AppL.of(context).profilePrivacy,
          onTap: () => showModalBottomSheet<void>(
            context: context,
            backgroundColor: Colors.transparent,
            builder: (_) => _InfoSheet(
              title: AppL.of(context).profilePrivacy,
              body: AppL.of(context).profilePrivacyBody,
            ),
          ),
        ),
        _SettingRow(
          icon: AppIcon.info,
          title: AppL.of(context).profileAbout,
          value: 'v1.0.1',
          onTap: _openAbout,
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
    // 名字为空时取当前语言默认称呼的首字 —— 写死一个「考」，
    // 英文界面上会冒出一个孤零零的汉字。
    final initial = (name.isEmpty ? AppL.of(context).profileDefaultName : name)
        .characters
        .first;

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
                        SizedBox(width: 8),
                        Text(
                          AppL.of(context).dxColQuestions,
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
                          ? AppL.of(context).profileNoStatsYet
                          : AppL.of(context).profileStatsLine(rate, weekTotal),
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
    this.active = false,
  });

  /// 行首图标。设置行是安静的一列，线性图标比插画合适。
  final AppIcon icon;

  final String title;

  /// 右侧的值。没有实质内容就传 null —— 一整列「暂无」「未设置」
  /// 只会把页面填满噪音，真正有数的那几行反而看不见了。
  final String? value;

  final VoidCallback onTap;

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
            StrokeIcon(icon, size: 20, color: t.textSoft, weight: 1.8),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: text.bodyLarge?.copyWith(
                  color: t.text,
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

    final modes = [
      (mode: ThemeMode.system, icon: AppIcon.auto, label: AppL.of(context).profileThemeAuto),
      (mode: ThemeMode.light, icon: AppIcon.sun, label: AppL.of(context).profileThemeLight),
      (mode: ThemeMode.dark, icon: AppIcon.moon, label: AppL.of(context).profileThemeDark),
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
            Expanded(child: Text(AppL.of(context).profileTheme, style: text.bodyLarge)),
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
            Text(AppL.of(context).profileRename, style: text.titleMedium),
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
                  decoration: InputDecoration(
                    isDense: true,
                    counterText: '',
                    border: InputBorder.none,
                    hintText: AppL.of(context).profileRenameHint,
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
                  Navigator.of(context).pop(value.isEmpty ? AppL.of(context).profileDefaultName : value);
                },
                child: Text(AppL.of(context).commonSave),
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
          Text(AppL.of(context).profileRegion, style: text.titleMedium),
          const SizedBox(height: 6),
          Text(AppL.of(context).profileRegionHint, style: text.bodySmall),
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
          Text(AppL.of(context).profileDailyGoal, style: text.titleMedium),
          const SizedBox(height: 6),
          Text(AppL.of(context).profileDailyGoalHint, style: text.bodySmall),
          for (final n in const [10, 20, 30, 50, 80, 100])
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).pop(n),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  children: [
                    Text(
                      AppL.of(context).countQuestions(n),
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
          Text(AppL.of(context).profileSetSize, style: text.titleMedium),
          const SizedBox(height: 4),
          for (final n in const [10, 20, 30, 50])
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).pop(n),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 15),
                child: Row(
                  children: [
                    Text(
                      AppL.of(context).countQuestions(n),
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
              child: Text(AppL.of(context).commonGotIt),
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
                  child: Text(AppL.of(context).commonCancel),
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

/// 练习偏好。
///
/// 报考地区、考试日期、每日目标、每组题量、模考节奏 —— 这几样都是"设一次
/// 就不再动"的数字，原来各占设置页一行，把「复习计划」这种天天要点的入口
/// 挤到了下面。收进这一页，设置页第一屏就清爽了。
class PracticePrefsPage extends StatefulWidget {
  const PracticePrefsPage({super.key});

  @override
  State<PracticePrefsPage> createState() => _PracticePrefsPageState();
}

class _PracticePrefsPageState extends State<PracticePrefsPage> {
  String _province = '国考';
  DateTime? _examDate;
  int _goal = 30;
  int _count = 20;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _province = prefs.getString(Prefs.province) ?? '国考';
      _examDate = DateTime.tryParse(prefs.getString(Prefs.examDate) ?? '');
      _goal = prefs.getInt(Prefs.dailyGoal) ?? 30;
      _count = prefs.getInt(Prefs.defaultCount) ?? 20;
      _loading = false;
    });
  }

  int? get _daysLeft {
    if (_examDate == null) return null;
    final now = DateTime.now();
    return _examDate!.difference(DateTime(now.year, now.month, now.day)).inDays;
  }

  Future<void> _pickExamDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _examDate ?? now.add(const Duration(days: 60)),
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 1500)),
      helpText: AppL.of(context).profilePickExamDate,
    );
    if (picked == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(Prefs.examDate, picked.toIso8601String());
    if (mounted) setState(() => _examDate = picked);
  }

  Future<void> _editMock({required bool count}) async {
    final profile = ExamProfileStore.current;
    final ctrl = TextEditingController(
      text: '${count ? profile.mockCount : profile.mockMinutes}',
    );
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(count ? AppL.of(context).profileMockCount : AppL.of(context).profileMockMinutes),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            suffixText: count ? AppL.of(context).dxColQuestions : AppL.of(context).tipsUnitMinutes,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppL.of(context).commonCancel),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(ctx).pop(int.tryParse(ctrl.text.trim())),
            child: Text(AppL.of(context).commonConfirm),
          ),
        ],
      ),
    ).whenComplete(ctrl.dispose);
    if (result == null || result <= 0) return;
    await ExamProfileStore.save(
      count
          ? profile.copyWith(mockCount: result)
          : profile.copyWith(mockMinutes: result),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final days = _daysLeft;
    final profile = ExamProfileStore.current;

    return Scaffold(
      backgroundColor: t.gradient.last,
      body: SafeArea(
        child: ReadableWidth(
          child: _loading
              ? const LoadingState()
              : ListView(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.paddingOf(context).bottom + 28,
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                          AppTheme.gutter, 8, AppTheme.gutter, 10),
                      child: Row(
                        children: [
                          PlainIconButton(
                            icon: Icons.arrow_back,
                            onTap: () => Navigator.of(context).maybePop(),
                          ),
                          SizedBox(width: 4),
                          Text(AppL.of(context).profilePrefs, style: text.titleMedium),
                        ],
                      ),
                    ),
                    _SettingRow(
                      icon: AppIcon.target,
                      title: AppL.of(context).profileDailyGoal,
                      value: AppL.of(context).countQuestions(_goal),
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
                      title: AppL.of(context).profileSetSizeShort,
                      value: AppL.of(context).countQuestions(_count),
                      onTap: () async {
                        final picked = await showModalBottomSheet<int>(
                          context: context,
                          backgroundColor: Colors.transparent,
                          builder: (_) => _CountSheet(current: _count),
                        );
                        if (picked == null) return;
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setInt(Prefs.defaultCount, picked);
                        if (mounted) setState(() => _count = picked);
                      },
                    ),
                    _SettingRow(
                      icon: AppIcon.calendar,
                      title: AppL.of(context).profileExamDate,
                      value: days == null
                          ? null
                          : (days > 0 ? AppL.of(context).profileDaysRemaining(days) : AppL.of(context).profileToday),
                      onTap: _pickExamDate,
                    ),
                    if (profile.has(ExamFeature.provinces))
                      _SettingRow(
                        icon: AppIcon.region,
                        title: AppL.of(context).profileRegion,
                        value: _province,
                        onTap: () async {
                          final picked =
                              await showModalBottomSheet<String>(
                            context: context,
                            backgroundColor: Colors.transparent,
                            builder: (_) =>
                                _ProvinceSheet(current: _province),
                          );
                          if (picked == null) return;
                          final prefs =
                              await SharedPreferences.getInstance();
                          await prefs.setString(Prefs.province, picked);
                          if (mounted) setState(() => _province = picked);
                        },
                      ),
                    SizedBox(height: 12),
                    SectionHeader(
                      title: AppL.of(context).profileMock,
                      caption: AppL.of(context).profileMockHint,
                    ),
                    _SettingRow(
                      icon: AppIcon.stack,
                      title: AppL.of(context).profileMockCountShort,
                      value: AppL.of(context).countQuestions(profile.mockCount),
                      onTap: () => _editMock(count: true),
                    ),
                    _SettingRow(
                      icon: AppIcon.timer,
                      title: AppL.of(context).profileMockMinutesShort,
                      value: AppL.of(context).minutesCount(profile.mockMinutes),
                      onTap: () => _editMock(count: false),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}


/// 界面语言。默认跟手机走 —— 但必须能手动改：有一批用户人在国外、手机是
/// 英文，备的却是中文考试，按系统语言强行切成英文对他们是纯粹的倒退。
class _LanguageRow extends StatelessWidget {
  const _LanguageRow();

  @override
  Widget build(BuildContext context) {
    final l = AppL.of(context);
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final controller = LocaleController.instance;

    final options = <({Locale? locale, String label})>[
      (locale: null, label: l.settingsLanguageSystem),
      (locale: const Locale('zh'), label: '中文'),
      (locale: const Locale('en'), label: 'English'),
    ];

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        child: Row(
          children: [
            StrokeIcon(AppIcon.globe, size: 20, color: t.textSoft, weight: 1.8),
            const SizedBox(width: 14),
            Expanded(
              child: Text(l.settingsLanguage, style: text.bodyLarge),
            ),
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: t.surfaceAlt,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final o in options)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => controller.set(o.locale),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: controller.locale == o.locale ? t.accent : null,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          o.label,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: controller.locale == o.locale
                                ? t.onAccent
                                : t.textSoft,
                          ),
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
