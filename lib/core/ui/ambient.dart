import 'package:flutter/material.dart';
import 'package:openexam_app/core/theme/app_tokens.dart';
import 'package:openexam_app/core/ui/brand_mark.dart';

/// Full-screen ambient backdrop: a vertical wash plus two soft light blobs.
/// Pure gradients — no BackdropFilter anywhere, so scrolling stays cheap.
class AmbientBackground extends StatelessWidget {
  const AmbientBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: t.gradient,
                stops: const [0, 0.45, 1],
              ),
            ),
          ),
        ),
        // Two soft light sources give the backdrop its liquid, glassy depth.
        Positioned(top: -150, right: -120, child: _Blob(color: t.glow, size: 360)),
        Positioned(
          top: 90,
          left: -150,
          child: _Blob(color: t.brand.withValues(alpha: 0.22), size: 330),
        ),
        Positioned(
          top: 260,
          right: -80,
          child: _Blob(
            color: t.category('ziliao').withValues(alpha: 0.14),
            size: 260,
          ),
        ),
        Positioned.fill(child: child),
      ],
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}

/// Borderless block. Content sits on the ambient backdrop; [fill] adds only a
/// faint tonal wash for blocks that must read as a distinct hit target.
class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.radius = 20,
    this.fill = false,
    this.color,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool fill;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final box = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? (fill ? t.glass : null),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: child,
    );
    if (onTap == null) return box;
    return GestureDetector(behavior: HitTestBehavior.opaque, onTap: onTap, child: box);
  }
}

/// Bare icon button — no background, no border, just the glyph.
class PlainIconButton extends StatelessWidget {
  const PlainIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 22,
    this.color,
  });

  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 40,
        height: 40,
        child: Icon(icon, size: size, color: color ?? context.tokens.textSoft),
      ),
    );
  }
}

/// Underlined text tabs (场景 / 全屋 / 主卧 style).
class TabStrip extends StatelessWidget {
  const TabStrip({
    super.key,
    required this.items,
    required this.index,
    required this.onChanged,
  });

  final List<String> items;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 22),
        itemBuilder: (context, i) {
          final selected = i == index;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onChanged(i),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 150),
                  style: TextStyle(
                    fontSize: selected ? 17 : 15.5,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    letterSpacing: -0.3,
                    color: selected ? t.text : t.textSoft.withValues(alpha: 0.5),
                  ),
                  child: Text(items[i]),
                ),
                const SizedBox(height: 5),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 170),
                  height: 3,
                  width: selected ? 22 : 0,
                  decoration: BoxDecoration(
                    color: t.brand,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// The OpenExam book mark — see [BrandMark] for the vector implementation.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.size = 30});

  final double size;

  @override
  Widget build(BuildContext context) => BrandMark(size: size);
}
