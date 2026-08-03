import 'package:flutter/material.dart';
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
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(title, style: text.titleMedium),
          if (caption != null) ...[
            const SizedBox(width: 8),
            Expanded(child: Text(caption!, style: text.bodySmall)),
          ] else
            const Spacer(),
          if (trailing != null)
            GestureDetector(
              onTap: onTapTrailing,
              child: Text(trailing!, style: text.labelMedium?.copyWith(color: t.brand)),
            ),
        ],
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

  static const _weekday = ['一', '二', '三', '四', '五', '六', '日'];

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
                    _weekday[today
                            .subtract(Duration(days: counts.length - 1 - i))
                            .weekday -
                        1],
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
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 46),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 30, color: t.muted),
            const SizedBox(height: 14),
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
