import 'package:flutter/material.dart';
import 'package:openexam_app/l10n/app_localizations.dart';
import 'package:openexam_app/core/constants/app_constants.dart';
import 'package:openexam_app/core/theme/app_tokens.dart';
import 'package:openexam_app/core/ui/ambient.dart';
import 'package:openexam_app/core/ui/responsive.dart';
import 'package:openexam_app/core/ui/stroke_icons.dart';
import 'package:openexam_app/features/bank/bank_page.dart';
import 'package:openexam_app/features/plan/presentation/pages/study_plan_page.dart';
import 'package:openexam_app/features/practice/practice_home_page.dart';
import 'package:openexam_app/features/profile/profile_page.dart';
import 'package:openexam_app/features/shell/tab_reload.dart';
import 'package:openexam_app/features/wrong/wrong_book_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  /// 让别的页面能把用户送到某个 tab（比如首页的计划提醒 → 错题本）。
  /// 底部导航是这个 app 唯一的一级结构，push 一个没有导航栏的副本会更乱。
  static final ValueNotifier<int> jumpTo = ValueNotifier<int>(0);

  /// 当前是否宽屏布局。由 [AppShell] 在 build 时写入，供跨页跳转算 tab 下标。
  static bool wideNav = false;

  /// 错题本 tab：手机 2，平板侧栏多了「计划」后是 3。
  static int get wrongBookTab => wideNav ? 3 : 2;

  /// 计划 tab：只在宽屏侧栏存在；手机上没有这一栏。
  static int? get planTab => wideNav ? 1 : null;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  bool _railHidden = false;

  @override
  void initState() {
    super.initState();
    AppShell.jumpTo.addListener(_onJump);
    _loadRailPref();
  }

  @override
  void dispose() {
    AppShell.jumpTo.removeListener(_onJump);
    super.dispose();
  }

  Future<void> _loadRailPref() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _railHidden = prefs.getBool(Prefs.navRailHidden) ?? false);
  }

  Future<void> _setRailHidden(bool hidden) async {
    setState(() => _railHidden = hidden);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(Prefs.navRailHidden, hidden);
  }

  void _onJump() {
    if (!mounted) return;
    setState(() => _index = AppShell.jumpTo.value);
  }

  /// 跟下面两组 tab、以及 build 里那两组 pages 一一对应，改一处必须改三处。
  static const _phoneOrder = [
    AppTab.practice,
    AppTab.bank,
    AppTab.wrong,
    AppTab.profile,
  ];
  static const _wideOrder = [
    AppTab.practice,
    AppTab.plan,
    AppTab.bank,
    AppTab.wrong,
    AppTab.profile,
  ];

  /// 图标是常量，标签跟着语言走，所以整张表得在 build 里现造。
  static List<({AppIcon icon, String label})> _phoneTabs(BuildContext c) => [
        (icon: AppIcon.practice, label: AppL.of(c).tabPractice),
        (icon: AppIcon.papers, label: AppL.of(c).bankTab),
        (icon: AppIcon.wrongBook, label: AppL.of(c).wrongBookTitle),
        (icon: AppIcon.profile, label: AppL.of(c).profileTab),
      ];

  /// 平板侧栏多一栏「计划」——空间够，打开就能管 Todo。
  static List<({AppIcon icon, String label})> _wideTabs(BuildContext c) => [
        (icon: AppIcon.practice, label: AppL.of(c).tabPractice),
        (icon: AppIcon.plan, label: AppL.of(c).tabPlan),
        (icon: AppIcon.papers, label: AppL.of(c).bankTab),
        (icon: AppIcon.wrongBook, label: AppL.of(c).wrongBookTitle),
        (icon: AppIcon.profile, label: AppL.of(c).profileTab),
      ];

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final wide = context.isWide;
    AppShell.wideNav = wide;

    final tabs = wide ? _wideTabs(context) : _phoneTabs(context);
    final pages = wide
        ? const [
            PracticeHomePage(),
            StudyPlanPage(embedded: true),
            BankPage(),
            WrongBookPage(),
            ProfilePage(),
          ]
        : const [
            PracticeHomePage(),
            BankPage(),
            WrongBookPage(),
            ProfilePage(),
          ];

    // 从宽屏切回窄屏时，下标可能越界（例如停在「我的」）。
    final safeIndex = _index.clamp(0, pages.length - 1);
    if (safeIndex != _index) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _index = safeIndex);
      });
    }

    // 告诉页面「你露面了，去把数据重读一遍」。IndexedStack 把它们全保活着，
    // 不说一声的话它们会一直显示进 app 那一刻的数字（见 tab_reload.dart）。
    // 只能在帧后改 —— 监听方会 setState，build 期间通知是要报错的。
    final shown = (wide ? _wideOrder : _phoneOrder)[safeIndex];
    if (activeTab.value != shown) {
      WidgetsBinding.instance.addPostFrameCallback((_) => activeTab.value = shown);
    }

    final body = IndexedStack(index: safeIndex, children: pages);

    // 平板和横屏：导航挪到左侧竖着放。底部导航在宽屏上要么被拉成一条几百像素
    // 的空条，要么手够不着。
    if (wide) {
      return Scaffold(
        body: SafeArea(
          // 底边留给内容自己加 padding，避免半截卡片贴在系统手势条上。
          bottom: false,
          child: Stack(
            children: [
              Row(
                children: [
                  // Width animates closed so content expands smoothly.
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    width: _railHidden ? 0 : 72,
                    child: ClipRect(
                      child: OverflowBox(
                        alignment: Alignment.centerLeft,
                        minWidth: 72,
                        maxWidth: 72,
                        child: _NavRail(
                          tabs: tabs,
                          index: safeIndex,
                          onTap: (i) => setState(() => _index = i),
                          onHide: () => _setRailHidden(true),
                        ),
                      ),
                    ),
                  ),
                  Expanded(child: body),
                ],
              ),
              // Slim mid-edge tab — does not cover page titles.
              if (_railHidden)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _RailReveal(onTap: () => _setRailHidden(false)),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      // 内容延伸到底栏后面，渐变底栏才是沉浸式而不是一块实底。
      extendBody: true,
      body: SafeArea(bottom: false, child: body),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          // 不贴屏幕边，悬浮起来 —— 通栏实底会把内容硬切成两段
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: t.surface,
              borderRadius: BorderRadius.circular(99),
              boxShadow: [
                BoxShadow(
                  color: t.name == 'dark'
                      ? Colors.black.withValues(alpha: 0.42)
                      : const Color(0xFF16465A).withValues(alpha: 0.14),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                for (var i = 0; i < tabs.length; i++)
                  _TabItem(
                    icon: tabs[i].icon,
                    label: tabs[i].label,
                    selected: safeIndex == i,
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

/// Slim vertical tab on the left mid-edge — peek only, no floating card on titles.
class _RailReveal extends StatelessWidget {
  const _RailReveal({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Tooltip(
      message: AppL.of(context).navExpand,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onHorizontalDragEnd: (d) {
          if ((d.primaryVelocity ?? 0) > 80) onTap();
        },
        child: Padding(
          // Hit target wider than the visible pill.
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 0),
          child: Container(
            width: 16,
            height: 72,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: t.brand.withValues(alpha: 0.88),
              borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(12),
              ),
              boxShadow: [
                BoxShadow(
                  color: t.brand.withValues(alpha: 0.22),
                  blurRadius: 10,
                  offset: const Offset(2, 0),
                ),
              ],
            ),
            child: Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: t.onBrand,
            ),
          ),
        ),
      ),
    );
  }
}

/// Icon-only side nav. Keep it narrow so content panes can sit 50/50.
class _NavRail extends StatelessWidget {
  const _NavRail({
    required this.tabs,
    required this.index,
    required this.onTap,
    required this.onHide,
  });

  final List<({AppIcon icon, String label})> tabs;
  final int index;
  final ValueChanged<int> onTap;
  final VoidCallback onHide;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return SizedBox(
      width: 72,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(color: t.line.withValues(alpha: 0.6)),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 18),
              child: Center(child: BrandLogo(size: 26)),
            ),
            for (var i = 0; i < tabs.length; i++)
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
                child: Tooltip(
                  message: tabs[i].label,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onTap(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      height: 46,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: index == i
                            ? t.brand.withValues(alpha: 0.14)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: StrokeIcon(
                        tabs[i].icon,
                        size: 21,
                        color: index == i ? t.brand : t.muted,
                        weight: index == i ? 2.2 : 1.8,
                      ),
                    ),
                  ),
                ),
              ),
            Spacer(),
            // Chevron only — no "隐藏" label eating the content ratio.
            Tooltip(
              message: AppL.of(context).navCollapse,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onHide,
                child: SizedBox(
                  height: 40,
                  child: Icon(
                    Icons.chevron_left_rounded,
                    size: 20,
                    color: t.muted,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 底栏的一格。
///
/// 选中态不是变个颜色 —— 那在 23px 的图标上太弱。选中的展开成一枚
/// 「图标 + 文字」横排的黄色药丸，没选中的只留图标：形状本身就不一样。
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

    if (selected) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 11),
          decoration: BoxDecoration(
            color: t.accent,
            borderRadius: BorderRadius.circular(99),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              StrokeIcon(icon, size: 20, color: t.onAccent, weight: 2),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: t.onAccent,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          // heightFactor 必须给。Row 传给孩子的纵向约束是整屏高度且是 loose，
          // 默认的 Center 会撑满 —— 整条底栏就被拉成一个全屏的圆角块。
          child: Center(
            heightFactor: 1,
            child: StrokeIcon(icon, size: 21, color: t.muted, weight: 1.9),
          ),
        ),
      ),
    );
  }
}
