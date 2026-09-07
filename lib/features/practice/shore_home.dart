import 'package:flutter/material.dart';
import 'package:openexam_app/l10n/app_localizations.dart';
import 'package:openexam_app/core/constants/categories.dart';
import 'package:openexam_app/core/theme/app_theme.dart';
import 'package:openexam_app/core/theme/app_tokens.dart';
import 'package:openexam_app/core/ui/shore.dart';
import 'package:openexam_app/core/ui/shore_art.dart';
import 'package:openexam_app/core/ui/stroke_icons.dart';
import 'package:openexam_app/data/models/question.dart';
import 'package:openexam_app/features/plan/domain/models/study_task.dart';

/// 首页三段：航程卡 → 今日航线 → 五座岛。
///
/// 一句话原则：每块只留 2–3 条信息。之前航程卡塞了灯塔天数、离岸天数、
/// 12/30、正确率、进度条、一句话共六条 —— 拥挤不是间距不够，是塞太多。

/// 页面统一的间距节奏。区块间距是卡内的两倍多，「组」的边界才立得住。
class ShoreGap {
  const ShoreGap._();
  /// 跟 [AppTheme.gutter] 是同一个数，改一个必须改另一个。
  static const page = AppTheme.gutter;
  static const top = 34.0;
  static const titleToBody = 22.0;
  static const section = 30.0;
  static const headToList = 12.0;
}

// ─────────────────────────────────────────── 顶部标题

/// 小字在上、大标题在下。反过来的话标题和下面的卡之间就断开了。
class ShoreHeader extends StatelessWidget {
  const ShoreHeader({
    super.key,
    required this.kicker,
    required this.title,
    this.actions = const [],
  });

  final String kicker;
  final String title;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ShoreGap.page),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  kicker,
                  style: text.bodySmall?.copyWith(
                    fontSize: 11.5,
                    color: t.muted,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: text.displaySmall?.copyWith(
                    fontSize: 26,
                    height: 1.15,
                    letterSpacing: -0.7,
                  ),
                ),
              ],
            ),
          ),
          for (final a in actions) ...[const SizedBox(width: 10), a],
        ],
      ),
    );
  }
}

/// 顶部那两枚白色圆钮。
class ShoreRoundButton extends StatelessWidget {
  const ShoreRoundButton({super.key, required this.icon, this.onTap});

  final Widget icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: t.surface,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF16465A).withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: icon,
      ),
    );
  }
}

// ─────────────────────────────────────────── 航程卡

/// 插画独占上半，数字落在下半白底。把数字压在插画上，图和字互相干扰。
class VoyageCard extends StatelessWidget {
  const VoyageCard({
    super.key,
    required this.done,
    required this.goal,
    required this.streak,
    this.daysLeft,
    this.onTap,
  });

  final int done;
  final int goal;
  final int streak;
  final int? daysLeft;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final left = (goal - done).clamp(0, goal);
    final ratio = goal <= 0 ? 0.0 : (done / goal).clamp(0.0, 1.0);

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
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Stack(
                children: [
                  Image.asset(
                    ShoreArt.forBrightness(
                      ShoreArt.voyage,
                      Theme.of(context).brightness,
                    ),
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    // 素材的主体在下方三分之一，居中裁只会裁到一片空天
                    alignment: const Alignment(0, 0.55),
                    filterQuality: FilterQuality.medium,
                    errorBuilder: (_, __, ___) =>
                        Container(height: 150, color: t.brandSoft),
                  ),
                  // 插画没入水里，不是被一条直线切断
                  Positioned(
                    left: 0, right: 0, bottom: -1, child: Waterline(),
                  ),
                  if (streak > 0)
                    Positioned(
                      left: 12,
                      top: 12,
                      child: _Pill(
                        icon: _LighthouseGlyph(),
                        label: AppL.of(context).shoreStreak(streak),
                      ),
                    ),
                  if (daysLeft != null)
                    Positioned(
                      right: 12,
                      top: 12,
                      child: _Pill(label: AppL.of(context).profileDaysLeft(daysLeft!)),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '$done',
                          style: text.displaySmall?.copyWith(
                            fontSize: 46,
                            height: 1,
                            letterSpacing: -1.5,
                            fontFeatures: AppTheme.numeric,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '/ $goal',
                          style: text.titleSmall?.copyWith(
                            fontSize: 15,
                            color: t.muted,
                            fontFeatures: AppTheme.numeric,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6),
                    RouteBar(value: ratio),
                    SizedBox(height: 4),
                    Text(
                      left == 0 ? AppL.of(context).homeGreetDone : AppL.of(context).shoreLeftToday(left),
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

class _Pill extends StatelessWidget {
  const _Pill({required this.label, this.icon});

  final String label;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: t.surface.withValues(alpha: 0.93),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[icon!, const SizedBox(width: 5)],
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: icon == null ? t.text : t.onAccentSoft,
              fontFeatures: AppTheme.numeric,
            ),
          ),
        ],
      ),
    );
  }
}

class _LighthouseGlyph extends StatelessWidget {
  const _LighthouseGlyph();

  @override
  Widget build(BuildContext context) => const SizedBox(
        width: 13,
        height: 13,
        child: CustomPaint(painter: _LighthousePainter()),
      );
}

class _LighthousePainter extends CustomPainter {
  const _LighthousePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    canvas.scale(s);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.1
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFFE08A1E)
      ..isAntiAlias = true;
    canvas.drawPath(
      Path()
        ..moveTo(9.5, 21)..lineTo(14.5, 21)
        ..moveTo(10, 21)..lineTo(11, 8)..lineTo(13, 8)..lineTo(14, 21)
        ..moveTo(10.4, 8)..lineTo(13.6, 8)..lineTo(13.3, 5)..lineTo(10.7, 5)..close()
        ..moveTo(6, 6.5)..lineTo(9, 8)
        ..moveTo(18, 6.5)..lineTo(15, 8),
      p,
    );
  }

  @override
  bool shouldRepaint(_LighthousePainter old) => false;
}

// ─────────────────────────────────────────── 今日航线

/// 一行只有名字和题数。当前那条整块黄底，是这张卡里唯一的重点。
class RouteList extends StatelessWidget {
  const RouteList({
    super.key,
    required this.tasks,
    required this.doneIds,
    required this.onRun,
    this.onLongPress,
    this.onToggle,
    this.max = 4,
    this.highlightCurrent = true,
  });

  final List<StudyTask> tasks;
  final Set<String> doneIds;
  final void Function(StudyTask) onRun;
  final void Function(StudyTask)? onLongPress;

  /// 点救生圈本身 = 勾掉/取消。计划页要，首页不要 —— 首页那一屏
  /// 只有一件事该做，点哪儿都应该是"开始"。
  final void Function(StudyTask, bool)? onToggle;

  /// 最多显示几条。首页只留 4 条，计划页全列。
  final int max;

  /// 是否把第一条没做完的整行点亮。
  final bool highlightCurrent;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    if (tasks.isEmpty) return const SizedBox.shrink();

    // 第一条没做完的就是「当前」
    final currentId = highlightCurrent
        ? tasks.where((x) => !doneIds.contains(x.id)).map((x) => x.id).firstOrNull
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ShoreGap.page),
      child: Container(
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(22),
          boxShadow: t.shadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            for (final task in tasks.take(max))
              _RouteRow(
                task: task,
                state: doneIds.contains(task.id)
                    ? LifeRingState.done
                    : (task.id == currentId
                        ? LifeRingState.active
                        : LifeRingState.todo),
                onRun: () => onRun(task),
                onLongPress:
                    onLongPress == null ? null : () => onLongPress!(task),
                onToggle: onToggle == null
                    ? null
                    : () => onToggle!(task, !doneIds.contains(task.id)),
              ),
          ],
        ),
      ),
    );
  }
}

class _RouteRow extends StatelessWidget {
  const _RouteRow({
    required this.task,
    required this.state,
    required this.onRun,
    this.onLongPress,
    this.onToggle,
  });

  final StudyTask task;
  final LifeRingState state;
  final VoidCallback onRun;
  final VoidCallback? onLongPress;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final current = state == LifeRingState.active;
    final done = state == LifeRingState.done;

    final meta = task.count != null
        ? AppL.of(context).countQuestions(task.count!)
        : (task.minutes != null ? AppL.of(context).minutesCount(task.minutes!) : '');

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onRun,
      onLongPress: onLongPress,
      child: Container(
        color: current ? t.accentSoft : null,
        padding: EdgeInsets.fromLTRB(16, current ? 14 : 13, 16, current ? 14 : 13),
        child: Row(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onToggle,
              // 救生圈本身就是勾选区，但 21px 够不着，外面垫一圈
              child: Padding(
                padding: EdgeInsets.all(onToggle == null ? 0 : 6),
                child: LifeRing(state: state),
              ),
            ),
            SizedBox(width: onToggle == null ? 13 : 7),
            Expanded(
              child: Text(
                task.displayTitle(AppL.of(context)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.titleSmall?.copyWith(
                  fontSize: current ? 15 : 14.5,
                  fontWeight: current ? FontWeight.w700 : FontWeight.w500,
                  color: done ? t.muted : t.text,
                ),
              ),
            ),
            if (current)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                decoration: BoxDecoration(
                  color: t.accent,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  AppL.of(context).commonStart,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: t.onAccent,
                  ),
                ),
              )
            else if (meta.isNotEmpty)
              Text(
                meta,
                style: text.bodySmall?.copyWith(
                  color: done ? t.muted : t.textSoft,
                  fontFeatures: AppTheme.numeric,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────── 五座岛

const _isleArtHeight = 92.0;
const _isleWidth = 130.0;
const _islePadTop = 11.0;
const _islePadBottom = 13.0;
const _isleTextGap = 3.0;
const _isleLabelSize = 14.0;
const _isleCountSize = 11.0;

/// 卡片高度 = 插画 + 内边距 + 两行字。
///
/// 这里原来写死 148，但两行字按主题行高算就要 14×1.4 + 11×1.45 = 35.55，
/// 加上 92+11+3+13 是 154.55 —— 每张卡都稳定溢出 7px，debug 下满屏
/// RenderFlex overflowed。字号还会跟系统缩放走，所以只能算，不能写死。
double _isleCardHeight(BuildContext context) {
  final text = Theme.of(context).textTheme;
  final scaler = MediaQuery.textScalerOf(context);
  final label = scaler.scale(_isleLabelSize) * (text.titleSmall?.height ?? 1.4);
  final count = scaler.scale(_isleCountSize) * (text.bodySmall?.height ?? 1.45);
  return (_isleArtHeight + _islePadTop + label + _isleTextGap + count + _islePadBottom)
      .ceilToDouble();
}

/// 图在上、字在白底。亮色插画上压白字读不清，压深字又跟天空糊在一起。
class IsleStrip extends StatelessWidget {
  const IsleStrip({
    super.key,
    required this.stats,
    required this.onTap,
    this.onLong,
  });

  final Map<String, CategoryStat> stats;
  final void Function(String category) onTap;
  final void Function(String category)? onLong;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _isleCardHeight(context),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: ShoreGap.page),
        // 跟着题库里实际有的分类走。写死五个的时候，导进来的医师、法考题
        // 在这排卡片里一张都不出现，题在库里却没有入口点得到。
        itemCount: CategoryRegistry.current.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final c = CategoryRegistry.current[i];
          return _IsleCard(
            meta: c,
            stat: stats[c.key],
            onTap: () => onTap(c.key),
            onLong: onLong == null ? null : () => onLong!(c.key),
          );
        },
      ),
    );
  }
}

/// 没有配图的分类用这块顶上：分类色的底 + 那个分类的图标。
///
/// [CategoryRegistry] 会给没见过的分类按名字稳定地生成图标和颜色，
/// 所以同一个科目每次进来长得一样，不会这次是书下次是地球。
class _IsleGlyph extends StatelessWidget {
  const _IsleGlyph({required this.meta});

  final CategoryMeta meta;

  @override
  Widget build(BuildContext context) {
    final color = context.tokens.category(meta.key);
    return Container(
      height: _isleArtHeight,
      width: _isleWidth,
      color: color.withValues(alpha: 0.14),
      alignment: Alignment.center,
      child: StrokeIcon(meta.icon, size: 34, color: color, weight: 1.6),
    );
  }
}

/// 正确率的颜色：低于 60% 报警，80% 以上算稳。
///
/// 题数太少时不上色 —— 三题对两题算 67%，染成红的只会吓人。
Color _rateColor(AppTokens t, CategoryStat s) {
  if (s.done < 10) return t.textSoft;
  if (s.accuracy < 0.6) return t.danger;
  if (s.accuracy >= 0.8) return t.brand;
  return t.text;
}

class _IsleCard extends StatelessWidget {
  const _IsleCard({
    required this.meta,
    required this.stat,
    required this.onTap,
    this.onLong,
  });

  final CategoryMeta meta;
  final CategoryStat? stat;
  final VoidCallback onTap;
  final VoidCallback? onLong;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final art = ShoreArt.isle(meta.key, Theme.of(context).brightness);
    final s = stat;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onLongPress: onLong,
      child: Container(
        width: _isleWidth,
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: t.shadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 配图只有行测那五个模块有。导进计算机、驾考、法考这些题库时
            // art 是 null —— 以前这里直接不画，卡片上半截就空着一块，
            // 一排卡全是空白。没有图就画一块底色 + 分类图标，尺寸照旧。
            if (art != null)
              Image.asset(
                art,
                height: _isleArtHeight,
                width: _isleWidth,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.medium,
                errorBuilder: (_, __, ___) => _IsleGlyph(meta: meta),
              )
            else
              _IsleGlyph(meta: meta),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, _islePadTop, 12, _islePadBottom),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meta.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleSmall?.copyWith(fontSize: _isleLabelSize),
                  ),
                  SizedBox(height: _isleTextGap),
                  // 卡片上原来只有"练了几题"。做了多少是过程，做对多少才是
                  // 想知道的事 —— 正确率本来就在 CategoryStat 里，只是没拿出来。
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          s == null || s.done == 0
                              ? AppL.of(context).shoreNotStarted
                              : '${s.done} / ${s.total}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodySmall?.copyWith(
                            fontSize: _isleCountSize,
                            fontFeatures: AppTheme.numeric,
                          ),
                        ),
                      ),
                      if (s != null && s.done > 0) ...[
                        Text(
                          ' · ',
                          style: text.bodySmall?.copyWith(
                            fontSize: _isleCountSize,
                            color: t.textSoft,
                          ),
                        ),
                        Text(
                          '${(s.accuracy * 100).round()}%',
                          style: text.bodySmall?.copyWith(
                            fontSize: _isleCountSize,
                            fontWeight: FontWeight.w700,
                            fontFeatures: AppTheme.numeric,
                            color: _rateColor(t, s),
                          ),
                        ),
                      ],
                    ],
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

// ─────────────────────────────────────────── 区块

/// 区块头：标题在左，一个可点的次动作在右。
/// 右边只放一个词，放两个就会跟标题抢。
class ShoreSection extends StatelessWidget {
  const ShoreSection({
    super.key,
    required this.title,
    required this.child,
    this.caption,
    this.action,
    this.onAction,
  });

  final String title;
  final Widget child;

  /// 右侧的说明文字。不可点，所以是灰的 —— 蓝色是"这行字能点"的意思，
  /// 拿来写「近 30 天」会让人一直想去点它。
  final String? caption;

  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: ShoreGap.page),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontSize: 17, letterSpacing: -0.3),
                ),
              ),
              const Spacer(),
              if (caption != null)
                Text(
                  caption!,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontSize: 12.5),
                ),
              if (caption != null && action != null) const SizedBox(width: 12),
              if (action != null)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onAction,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      action!,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: t.brand,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: ShoreGap.headToList),
        child,
      ],
    );
  }
}

/// 一段内容的白卡。图表、列表、说明都装进它，页面才有"块"。
///
/// 统计页原来是标题、图、标题、图直接落在背景上，没有块的边界，
/// 一屏扫下来分不出哪句话管哪张图。
class ShoreCard extends StatelessWidget {
  const ShoreCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ShoreGap.page),
      child: Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(22),
          boxShadow: t.shadow,
        ),
        child: child,
      ),
    );
  }
}
