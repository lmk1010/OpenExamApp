import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:openexam_app/core/theme/app_theme.dart';
import 'package:openexam_app/core/theme/app_tokens.dart';
import 'package:openexam_app/core/ui/ambient.dart';

/// Borderless content block. No card, no border, no shadow — the ambient
/// backdrop is the background. [fill] adds a faint wash when a block needs to
/// read as its own tap target.
class Surface extends StatelessWidget {
  const Surface({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.color,
    this.radius = AppTheme.radius,
    this.fill = false,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final double radius;
  final bool fill;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Panel(
      padding: padding,
      radius: radius,
      fill: fill,
      color: color,
      onTap: onTap,
      child: child,
    );
  }
}

/// Section heading: title plus an optional quiet caption.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.caption,
    this.trailing,
    this.onTapTrailing,
  });

  final String title;
  final String? caption;
  final String? trailing;
  final VoidCallback? onTapTrailing;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppTheme.gutter, 0, AppTheme.gutter, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(title, style: text.titleMedium),
          if (caption != null) ...[
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                caption!,
                style: text.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ] else
            const Spacer(),
          if (trailing != null)
            GestureDetector(
              onTap: onTapTrailing,
              child: Text(
                trailing!,
                style: text.labelMedium?.copyWith(color: t.brand),
              ),
            ),
        ],
      ),
    );
  }
}

/// Page-level title row: title + meta + actions on one horizontal line.
class PageTitleBar extends StatelessWidget {
  const PageTitleBar({
    super.key,
    required this.title,
    this.meta,
    this.actions = const [],
    this.top = 18,
    this.bottom = 14,
  });

  final String title;
  final String? meta;
  final List<Widget> actions;
  final double top;
  final double bottom;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(AppTheme.gutter, top, AppTheme.gutter, bottom),
      child: SizedBox(
        height: 36,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              title,
              style: text.displaySmall?.copyWith(
                fontSize: 26,
                height: 1,
              ),
            ),
            if (meta != null) ...[
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  meta!,
                  style: text.bodySmall?.copyWith(fontSize: 13, height: 1.2),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ] else
              const Spacer(),
            for (var i = 0; i < actions.length; i++) ...[
              if (i > 0) const SizedBox(width: 4),
              actions[i],
            ],
          ],
        ),
      ),
    );
  }
}

/// Bare category glyph — colour only, no tile behind it.
class CategoryGlyph extends StatelessWidget {
  const CategoryGlyph({super.key, required this.icon, required this.color, this.size = 21});

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Icon(icon, size: size, color: color);
}

/// Thin rounded meter.
class Meter extends StatelessWidget {
  const Meter({super.key, required this.value, this.color, this.height = 4});

  final double value;
  final Color? color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
        builder: (_, v, __) => LinearProgressIndicator(
          value: v,
          minHeight: height,
          color: color ?? t.brand,
          // The hairline token is too pale on the tinted backdrop — the empty
          // part of a meter needs its own, darker tone.
          backgroundColor: t.name == 'dark'
              ? Colors.white.withValues(alpha: 0.14)
              : t.text.withValues(alpha: 0.11),
        ),
      ),
    );
  }
}

/// Seven-day activity bars. Fixed-width rounded pills so a single active day
/// reads as a bar, not a block.
class WeekBars extends StatelessWidget {
  const WeekBars({super.key, required this.counts});

  final List<int> counts;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final max = counts.fold<int>(0, (m, c) => c > m ? c : m);
    final today = DateTime.now();
    final track = t.name == 'dark'
        ? Colors.white.withValues(alpha: 0.13)
        : t.text.withValues(alpha: 0.09);

    return SizedBox(
      height: 86,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < counts.length; i++)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    height: 14,
                    child: counts[i] == 0
                        ? null
                        : Text(
                            '${counts[i]}',
                            style: text.bodySmall?.copyWith(
                              fontSize: 11,
                              color: i == counts.length - 1 ? t.brand : t.muted,
                              fontWeight: i == counts.length - 1
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                          ),
                  ),
                  const SizedBox(height: 5),
                  // The empty track is always drawn, so the week reads as a
                  // rhythm even before any practice.
                  SizedBox(
                    height: 46,
                    width: 13,
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: track,
                            borderRadius: BorderRadius.circular(7),
                          ),
                        ),
                        TweenAnimationBuilder<double>(
                          tween: Tween(
                            begin: 0,
                            end: counts[i] == 0
                                ? 0
                                : (max == 0 ? 0 : (counts[i] / max).clamp(0.14, 1.0)),
                          ),
                          duration: Duration(milliseconds: 380 + i * 40),
                          curve: Curves.easeOutCubic,
                          builder: (_, v, __) => Container(
                            height: 46 * v,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: i == counts.length - 1
                                    ? [t.brand, Color.lerp(t.brand, Colors.white, 0.28)!]
                                    : [
                                        t.brand.withValues(alpha: 0.42),
                                        t.brand.withValues(alpha: 0.28),
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(7),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    // narrowWeekdays 按周日起头，DateTime.weekday 周日是 7，
                    // 取模刚好落回 0。
                    MaterialLocalizations.of(context).narrowWeekdays[today
                            .subtract(Duration(days: counts.length - 1 - i))
                            .weekday %
                        7],
                    style: text.bodySmall?.copyWith(
                      fontSize: 11,
                      color: i == counts.length - 1 ? t.textSoft : t.muted,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Borderless list row.
class AppRow extends StatelessWidget {
  const AppRow({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.maxLines = 2,
    this.padding = const EdgeInsets.symmetric(horizontal: AppTheme.gutter, vertical: 14),
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final int maxLines;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: padding,
        child: Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 13)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: text.titleSmall, maxLines: maxLines, overflow: TextOverflow.ellipsis),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(subtitle!, style: text.bodySmall),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 10), trailing!],
          ],
        ),
      ),
    );
  }
}

/// Hairline between rows, inset to align with the row text.
class RowDivider extends StatelessWidget {
  const RowDivider({super.key, this.indent = AppTheme.gutter});

  final double indent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: indent, right: indent),
      child: Divider(height: 1, color: context.tokens.line),
    );
  }
}

/// Sticky footer with the page's primary action — no border, fades into the
/// backdrop instead.
class ActionBar extends StatelessWidget {
  const ActionBar({super.key, required this.child, this.safeBottom = false});

  final Widget child;
  final bool safeBottom;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final bar = Padding(
      padding: const EdgeInsets.fromLTRB(AppTheme.gutter, 12, AppTheme.gutter, 12),
      child: child,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            t.gradient.last.withValues(alpha: 0),
            t.gradient.last.withValues(alpha: 0.92),
            t.gradient.last,
          ],
          stops: const [0, 0.35, 1],
        ),
      ),
      child: safeBottom ? SafeArea(top: false, child: bar) : bar,
    );
  }
}

class LoadingState extends StatelessWidget {
  const LoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2.2, color: context.tokens.brand),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.art = EmptyArt.box,
  });

  final IconData icon;
  final String title;
  final String message;

  /// Small drawn scene above the text — a bare grey glyph made every empty
  /// screen look broken.
  final EmptyArt art;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            EmptyArtwork(kind: art),
            const SizedBox(height: 18),
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

/// Which little scene an empty state shows.
enum EmptyArt { box, star, search, chart, done, essay, vocab, note, wrong, bank, paper }

/// 每种空态对应的插画资源。
const _emptyArtAsset = <EmptyArt, String>{
  EmptyArt.box: 'assets/shore/empty_box.png',
  EmptyArt.star: 'assets/shore/empty_star.png',
  EmptyArt.search: 'assets/shore/empty_search.png',
  EmptyArt.chart: 'assets/shore/empty_chart.png',
  EmptyArt.done: 'assets/shore/empty_done.png',
  EmptyArt.essay: 'assets/shore/empty_essay.png',
  EmptyArt.vocab: 'assets/shore/empty_vocab.png',
  EmptyArt.note: 'assets/shore/empty_note.png',
  EmptyArt.wrong: 'assets/shore/empty_wrong.png',
  EmptyArt.bank: 'assets/shore/empty_bank.png',
  EmptyArt.paper: 'assets/shore/empty_paper.png',
};

/// Drawn empty-state art: a few shapes with a soft glow, in theme colours.
class EmptyArtwork extends StatelessWidget {
  const EmptyArtwork({super.key, required this.kind, this.size = 92});

  final EmptyArt kind;
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final asset = _emptyArtAsset[kind];
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutBack,
      builder: (context, v, _) => Transform.scale(
        scale: 0.85 + 0.15 * v,
        child: Opacity(
          opacity: v.clamp(0.0, 1.0),
          child: SizedBox(
            width: size + 20,
            height: size + 20,
            child: asset == null
                ? CustomPaint(
                    painter: _EmptyArtPainter(
                      kind: kind,
                      brand: t.brand,
                      soft: t.name == 'dark'
                          ? Colors.white.withValues(alpha: 0.10)
                          : t.text.withValues(alpha: 0.08),
                      accent: t.category('shuliang'),
                    ),
                  )
                : Image.asset(
                    asset,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    // 素材没跟上版本时不能把整页拖垮，退回手绘那套
                    errorBuilder: (context, _, __) => CustomPaint(
                      painter: _EmptyArtPainter(
                        kind: kind,
                        brand: t.brand,
                        soft: t.name == 'dark'
                            ? Colors.white.withValues(alpha: 0.10)
                            : t.text.withValues(alpha: 0.08),
                        accent: t.category('shuliang'),
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _EmptyArtPainter extends CustomPainter {
  const _EmptyArtPainter({
    required this.kind,
    required this.brand,
    required this.soft,
    required this.accent,
  });

  final EmptyArt kind;
  final Color brand;
  final Color soft;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 92;
    canvas.save();
    canvas.scale(s);

    // Soft halo behind everything.
    canvas.drawCircle(
      const Offset(46, 46),
      34,
      Paint()
        ..shader = RadialGradient(
          colors: [brand.withValues(alpha: 0.16), brand.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: const Offset(46, 46), radius: 34)),
    );

    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = brand.withValues(alpha: 0.85);
    final fill = Paint()..color = soft;

    switch (kind) {
      // 新增的几种只有插画资源，画不出来时统一退回箱子
      case EmptyArt.essay:
      case EmptyArt.vocab:
      case EmptyArt.note:
      case EmptyArt.wrong:
      case EmptyArt.bank:
      case EmptyArt.paper:
      case EmptyArt.box:
        canvas.drawRRect(
          RRect.fromLTRBR(24, 34, 68, 66, const Radius.circular(8)),
          fill,
        );
        canvas.drawRRect(
          RRect.fromLTRBR(24, 34, 68, 66, const Radius.circular(8)),
          line,
        );
        canvas.drawLine(const Offset(24, 44), const Offset(68, 44), line);
        canvas.drawLine(const Offset(40, 34), const Offset(40, 44), line);
      case EmptyArt.star:
        final path = Path();
        for (var i = 0; i < 5; i++) {
          final a = -1.5708 + i * 1.2566;
          final outer = Offset(46 + 20 * _cos(a), 48 + 20 * _sin(a));
          final b = a + 0.6283;
          final inner = Offset(46 + 8 * _cos(b), 48 + 8 * _sin(b));
          if (i == 0) {
            path.moveTo(outer.dx, outer.dy);
          } else {
            path.lineTo(outer.dx, outer.dy);
          }
          path.lineTo(inner.dx, inner.dy);
        }
        path.close();
        canvas.drawPath(path, fill);
        canvas.drawPath(path, line);
      case EmptyArt.search:
        canvas.drawCircle(const Offset(42, 42), 16, fill);
        canvas.drawCircle(const Offset(42, 42), 16, line);
        canvas.drawLine(const Offset(54, 54), const Offset(66, 66), line);
      case EmptyArt.chart:
        canvas.drawLine(const Offset(24, 66), const Offset(70, 66), line);
        for (var i = 0; i < 3; i++) {
          final h = 12.0 + i * 10;
          final rect = RRect.fromLTRBR(
            30 + i * 14,
            66 - h,
            40 + i * 14,
            66,
            const Radius.circular(4),
          );
          canvas.drawRRect(rect, fill);
          canvas.drawRRect(rect, line);
        }
      case EmptyArt.done:
        canvas.drawCircle(const Offset(46, 46), 22, fill);
        canvas.drawCircle(const Offset(46, 46), 22, line);
        canvas.drawPath(
          Path()
            ..moveTo(36, 47)
            ..lineTo(43, 54)
            ..lineTo(58, 39),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.4
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..color = accent,
        );
    }

    canvas.restore();
  }

  double _sin(double v) => math.sin(v);
  double _cos(double v) => math.cos(v);

  @override
  bool shouldRepaint(covariant _EmptyArtPainter old) => old.kind != kind;
}

/// 入场：淡入 + 上移 18dp，按 index 递增延迟。列表整块「啪」地出现太生硬，
/// 错开几十毫秒就有了层次。只在首屏用，滚动到下面的项不再等。
class Reveal extends StatelessWidget {
  const Reveal({
    super.key,
    required this.index,
    required this.child,
    this.step = 45,
    this.max = 6,
  });

  final int index;
  final Widget child;

  /// 每一项之间的延迟。
  final int step;

  /// 超过这个序号就不再延迟，否则长列表末尾要等很久。
  final int max;

  @override
  Widget build(BuildContext context) {
    final delay = (index.clamp(0, max)) * step;
    return TweenAnimationBuilder<double>(
      key: ValueKey(index),
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 380 + delay),
      curve: Interval(
        (delay / (380 + delay)).clamp(0.0, 0.9),
        1,
        curve: Curves.easeOutCubic,
      ),
      builder: (context, v, child) => Opacity(
        opacity: v.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, 18 * (1 - v)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

/// 按下反馈：手指按住时给出状态，抬起才触发。选项这种「按住看看、滑开取消」
/// 的操作没有按下态，就只能靠手感赌自己点没点中。
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.builder,
    this.onTap,
    this.onLongPress,
    this.haptic = true,
    this.holdToCancel = false,
  });

  final Widget Function(bool pressed) builder;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// 按住不放就当作放弃：抬手不触发 onTap。用在「点下去就没法反悔」的地方
  /// —— 选项一旦选中就算作答，按住看半天不该被判成已选。
  final bool holdToCancel;

  /// 按下时轻震一下，抬起不再震 —— 选中本身另有反馈。
  final bool haptic;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;

  void _set(bool v) {
    if (_pressed == v) return;
    setState(() => _pressed = v);
    if (v && widget.haptic) HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null || widget.onLongPress != null;
    // 给了 onLongPress 的手势里，长按会吃掉这一次 onTap —— holdToCancel 就是
    // 借这一点：按住只是看看，松手什么也不发生。
    final onLongPress = widget.onLongPress ??
        (widget.holdToCancel && widget.onTap != null
            ? () {
                if (mounted) setState(() => _pressed = false);
              }
            : null);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => _set(true) : null,
      onTapUp: enabled ? (_) => _set(false) : null,
      onTapCancel: enabled ? () => _set(false) : null,
      onLongPressStart: onLongPress == null ? null : (_) {},
      onLongPressEnd: onLongPress == null ? null : (_) => _set(false),
      onTap: widget.onTap,
      onLongPress: onLongPress,
      child: widget.builder(_pressed && enabled),
    );
  }
}

/// 一组功能装进一块圆角卡。
///
/// 页面的层级不该靠"有的地方是卡、有的地方裸奔"来区分 —— 那会让整页
/// 看着像几个人拼的。统一成"每组一块卡、卡内紧凑、卡间等距"，
/// 米家那类工具型 app 的信息密度就是这么来的。
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.child,
    this.title,
    this.trailing,
    this.padding = const EdgeInsets.symmetric(vertical: 4),
    this.margin = const EdgeInsets.fromLTRB(AppTheme.gutter, 0, AppTheme.gutter, 12),
  });

  final Widget child;

  /// 组标题。放在卡外面、贴着卡，不另起一段留白。
  final String? title;
  final Widget? trailing;

  final EdgeInsets padding;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final dark = t.name == 'dark';
    return Padding(
      padding: margin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
              child: Row(
                children: [
                  Text(
                    title!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: t.muted,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                        ),
                  ),
                  const Spacer(),
                  if (trailing != null) trailing!,
                ],
              ),
            ),
          ],
          Container(
            width: double.infinity,
            padding: padding,
            decoration: BoxDecoration(
              // 实体卡面，不是半透明叠色 —— 背景本身是有色渐变，
              // 半透明卡会被底色染透，看不出"一块东西浮在上面"。
              color: t.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: dark
                      ? Colors.black.withValues(alpha: 0.30)
                      : const Color(0xFF1B2540).withValues(alpha: 0.07),
                  blurRadius: dark ? 18 : 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}

/// 可按压的卡片：按下去会微微缩一下再弹回来。
///
/// 没有按压反馈的卡看着就是一张贴纸 —— "塑料感"有一半来自这里：
/// 元素不会对手指做出反应，就不像实物。
class PressableCard extends StatefulWidget {
  const PressableCard({
    super.key,
    required this.child,
    required this.onTap,
    this.onLongPress,
    this.scale = 0.97,
  });

  final Widget child;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  /// 按下时缩到多少。卡越大缩得越少，不然会像弹簧。
  final double scale;

  @override
  State<PressableCard> createState() => _PressableCardState();
}

class _PressableCardState extends State<PressableCard> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// 进场时依次淡入上移一点点。
///
/// 一屏内容"啪"地整块出现，跟一张静态图没区别；错开几十毫秒依次进场，
/// 页面才有被"搭起来"的感觉。
class FadeInUp extends StatefulWidget {
  const FadeInUp({
    super.key,
    required this.child,
    this.delay = Duration.zero,
  });

  final Widget child;
  final Duration delay;

  @override
  State<FadeInUp> createState() => _FadeInUpState();
}

class _FadeInUpState extends State<FadeInUp>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(widget.delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curve = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    return AnimatedBuilder(
      animation: curve,
      builder: (context, child) => Opacity(
        opacity: curve.value,
        child: Transform.translate(
          offset: Offset(0, 14 * (1 - curve.value)),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}
