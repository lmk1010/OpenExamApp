import 'package:flutter/material.dart' show Brightness;
/// 「上岸」素材的路径表。
///
/// 散在各页里写字符串迟早会拼错，而且改名要全局搜 —— 集中在这里。
/// 生成脚本在 design/gen_scenes.py，三套风格锁死在里面：
/// 场景走 STYLE_DAY，徽章走 STYLE_BADGE，入口图标走 STYLE_ICON。
class ShoreArt {
  const ShoreArt._();

  static const _dir = 'assets/shore';

  // ── 场景（620px jpg）──
  /// 首页航程卡：晴天海面划船，远处白灯塔。
  static const voyage = '$_dir/day_voyage.jpg';
  static const nightVoyage = '$_dir/night_voyage.jpg';
  static const nightArrive = '$_dir/night_arrive.jpg';
  static const nightCalm = '$_dir/night_calm.jpg';

  /// 引导页：出发。
  static const start = '$_dir/day_start.jpg';

  /// 今日靠岸 / 我的：船靠岸，沙丘上一面旗。
  static const arrive = '$_dir/day_arrive.jpg';

  /// 空态：无人的海面。
  static const calm = '$_dir/day_calm.jpg';

  static const essay = '$_dir/day_essay.jpg';
  static const chart = '$_dir/day_chart.jpg';
  static const badgeScene = '$_dir/day_badge.jpg';
  static const log = '$_dir/day_log.jpg';

  /// 五座岛，按题型 id 取。
  static const _isles = <String, String>{
    'yanyu': '$_dir/day_yanyu.jpg',
    'shuliang': '$_dir/day_shuliang.jpg',
    'panduan': '$_dir/day_panduan.jpg',
    'ziliao': '$_dir/day_ziliao.jpg',
    'changshi': '$_dir/day_changshi.jpg',
  };

  static const _nightIsles = <String, String>{
    'yanyu': '$_dir/night_yanyu.jpg',
    'shuliang': '$_dir/night_shuliang.jpg',
    'panduan': '$_dir/night_panduan.jpg',
    'ziliao': '$_dir/night_ziliao.jpg',
    'changshi': '$_dir/night_changshi.jpg',
  };

  static String? isle(String? category, [Brightness b = Brightness.light]) =>
      b == Brightness.light ? _isles[category] : _nightIsles[category];

  /// 深色主题下换夜航的那几张。
  ///
  /// 白底贴夜景、黑底贴晴天，都是把插画和底色放进两个光线世界里。
  /// 同一个母题出两套光，切主题时画面跟着一起暗下来。
  static String forBrightness(String day, Brightness b) {
    if (b == Brightness.light) return day;
    return switch (day) {
      voyage || start => nightVoyage,
      arrive => nightArrive,
      calm => nightCalm,
      _ => day,
    };
  }

  // ── 成就徽章（320px png，六枚各画各的）──
  static const badgeFirst = '$_dir/badge_first.png';
  static const badgeWeek = '$_dir/badge_week.png';
  static const badgeKilo = '$_dir/badge_kilo.png';
  static const badgePerfect = '$_dir/badge_perfect.png';
  static const badgeDawn = '$_dir/badge_dawn.png';
  static const badgeShore = '$_dir/badge_shore.png';

  /// 空态插画。每屏没东西的时候露的就是这张。
  static const emptyBox = '$_dir/empty_box.png';
  static const emptyStar = '$_dir/empty_star.png';
  static const emptySearch = '$_dir/empty_search.png';
  static const emptyChart = '$_dir/empty_chart.png';
  static const emptyDone = '$_dir/empty_done.png';
  static const emptyEssay = '$_dir/empty_essay.png';
  static const emptyVocab = '$_dir/empty_vocab.png';
  static const emptyNote = '$_dir/empty_note.png';
  static const emptyWrong = '$_dir/empty_wrong.png';
  static const emptyBank = '$_dir/empty_bank.png';
  static const emptyPaper = '$_dir/empty_paper.png';

  /// 成就分组 → 徽章素材。每组各画各的，不是同一个图形换颜色。
  ///
  /// key 是稳定标识，不是显示名 —— 分组名已经跟着界面语言走了，
  /// 拿它查表在英文界面下一个都对不上，徽章图会全退成默认那张。
  static const _groups = <String, String>{
    'volume': badgeKilo,
    'consistency': badgeWeek,
    'accuracy': badgePerfect,
    'exams': badgeFirst,
    'grind': badgeShore,
  };

  static String badgeForGroup(String groupKey) =>
      _groups[groupKey] ?? badgeDawn;

  static const badges = <String>[
    badgeFirst, badgeWeek, badgeKilo, badgePerfect, badgeDawn, badgeShore,
  ];

  // ── 「我的」入口图标（320px png）──
  static const icoAchieve = '$_dir/ico_achieve.png';
  static const icoHistory = '$_dir/ico_history.png';
  static const icoNote = '$_dir/ico_note.png';
  static const icoMark = '$_dir/ico_mark.png';
  static const icoReport = '$_dir/ico_report.png';
  static const icoStats = '$_dir/ico_stats.png';
  static const icoTips = '$_dir/ico_tips.png';
  static const icoFix = '$_dir/ico_fix.png';
  static const icoVocab = '$_dir/ico_vocab.png';
}
