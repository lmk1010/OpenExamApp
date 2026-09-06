import 'package:flutter/widgets.dart';

/// 一级 tab 的身份。
///
/// 用身份不用下标 —— 宽屏侧栏比手机底栏多一个「计划」，同一个页面在两种
/// 布局里的下标不一样，按下标认页面迟早认错。
enum AppTab { practice, plan, bank, wrong, profile }

/// 当前露在前台的一级 tab。
///
/// AppShell 用 IndexedStack 把几个一级页面全都保活着，而每个页面只在
/// initState 里读一次库。于是做完一组题切回「我的」，看到的还是进 app 那一刻
/// 的数字 —— 实测刷完 20 题，「我的」仍显示「0 题 · 还没开始记」，
/// 下拉也没用，得杀进程重启才更新。
///
/// 修法是让页面在重新露面时再读一次库。这些查询都是本地 SQLite、几十毫秒，
/// 而切 tab 是用户手动触发的低频动作，不值得再搭一套「哪张表脏了」的账。
final ValueNotifier<AppTab> activeTab = ValueNotifier<AppTab>(AppTab.practice);

/// 一级页面混入它，就能在被切回前台时重新读库。
///
/// ```dart
/// class _FooPageState extends State<FooPage> with TabReload {
///   @override
///   AppTab get tab => AppTab.foo;
///
///   @override
///   Future<void> onTabShown() => _reload();
/// }
/// ```
mixin TabReload<T extends StatefulWidget> on State<T> {
  /// 这个页面占哪一栏。
  AppTab get tab;

  /// 重新露面时做什么。通常就是页面自己的 _reload()。
  ///
  /// 注意别在这里把整页打回 Loading —— 切个 tab 闪一下白屏比数字旧更难受。
  Future<void> onTabShown();

  @override
  void initState() {
    super.initState();
    activeTab.addListener(_onActiveTabChanged);
  }

  @override
  void dispose() {
    activeTab.removeListener(_onActiveTabChanged);
    super.dispose();
  }

  void _onActiveTabChanged() {
    if (!mounted || activeTab.value != tab) return;
    onTabShown();
  }
}
