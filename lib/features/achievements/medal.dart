import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:openexam_app/core/theme/app_tokens.dart';
import 'package:openexam_app/core/ui/shore_art.dart';
import 'package:openexam_app/features/achievements/achievements.dart';

/// 徽章。
///
/// 上一版是一整套手绘的「铸造金属章」：深色面、扫光金属圈、雕花。
/// 那套语言跟现在的亮色海景对不上 —— 一面亮黄的墙上嵌十八块深灰铁牌。
/// 现在章面用素材，分组各画各的；等级降级成一圈细环，
/// 没拿到的灰掉并露出进度弧。信息还是三条：是什么、什么等级、差多少。
class BadgeMedal extends StatelessWidget {
  const BadgeMedal({
    super.key,
    required this.badge,
    this.size = 72,
    this.animate = false,
    this.shine = false,
  });

  final AchievementBadge badge;
  final double size;

  /// 详情页第一次露出时弹一下。列表里十八枚一起弹会晃眼。
  final bool animate;
  final bool shine;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final unlocked = badge.unlocked;

    Widget art = Image.asset(
      ShoreArt.badgeForGroup(badge.groupKey),
      width: size * 0.78,
      height: size * 0.78,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, __, ___) => Icon(
        Icons.workspace_premium_outlined,
        size: size * 0.5,
        color: unlocked ? t.accent : t.muted,
      ),
    );

    if (!unlocked) {
      // 灰掉再压透明度。只压透明度的话彩色还在，一眼看不出没拿到。
      art = Opacity(
        opacity: 0.34,
        child: ColorFiltered(
          colorFilter: const ColorFilter.matrix(<double>[
            0.2126, 0.7152, 0.0722, 0, 0,
            0.2126, 0.7152, 0.0722, 0, 0,
            0.2126, 0.7152, 0.0722, 0, 0,
            0, 0, 0, 1, 0,
          ]),
          child: art,
        ),
      );
    }

    final medal = SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _RingPainter(
              tier: badge.tier.color,
              track: t.lineSoft,
              accent: t.accent,
              unlocked: unlocked,
              progress: badge.progress,
              glow: unlocked && shine,
            ),
          ),
          art,
        ],
      ),
    );

    if (!animate) return medal;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 620),
      curve: Curves.easeOutBack,
      builder: (_, v, child) => Transform.scale(scale: 0.72 + 0.28 * v, child: child),
      child: medal,
    );
  }
}

/// 拿到了画一圈等级色的实线；没拿到画一段进度弧。
/// 两者不同时出现 —— 同一个位置放两种意思，读的人得先分辨再理解。
class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.tier,
    required this.track,
    required this.accent,
    required this.unlocked,
    required this.progress,
    required this.glow,
  });

  final Color tier;
  final Color track;
  final Color accent;
  final bool unlocked;
  final double progress;
  final bool glow;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width * 0.455;
    final w = size.width * 0.042;

    if (glow) {
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..color = accent.withValues(alpha: 0.28)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, size.width * 0.12),
      );
    }

    // 没拿到也要看得出等级：同一组三枚长得一样，只有环色分得开铜银金。
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w
        ..isAntiAlias = true
        ..color = unlocked ? tier.withValues(alpha: 0.85) : tier.withValues(alpha: 0.30),
    );

    if (!unlocked && progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        -math.pi / 2,
        math.pi * 2 * progress,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = w
          ..strokeCap = StrokeCap.round
          ..isAntiAlias = true
          ..color = accent,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.unlocked != unlocked ||
      old.progress != progress ||
      old.tier != tier ||
      old.glow != glow;
}
