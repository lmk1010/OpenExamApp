import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:openexam_app/core/theme/app_theme.dart';
import 'package:openexam_app/core/theme/app_tokens.dart';
import 'package:openexam_app/core/ui/stroke_icons.dart';
import 'package:openexam_app/core/ui/ui_kit.dart';
import 'package:openexam_app/features/achievements/achievements.dart';

/// 成就 — every badge, grouped, with progress on the locked ones so they read
/// as goals rather than mysteries.
class AchievementsPage extends StatefulWidget {
  const AchievementsPage({super.key});

  @override
  State<AchievementsPage> createState() => _AchievementsPageState();
}

class _AchievementsPageState extends State<AchievementsPage> {
  bool _loading = true;
  List<AchievementBadge> _badges = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final badges = await Achievements.evaluate();
    if (!mounted) return;
    setState(() {
      _badges = badges;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final unlocked = _badges.where((b) => b.unlocked).length;
    final groups = <String, List<AchievementBadge>>{};
    for (final b in _badges) {
      groups.putIfAbsent(b.group, () => []).add(b);
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 21),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        titleSpacing: 0,
        title: const Text('成就'),
      ),
      body: _loading
          ? const LoadingState()
          : ListView(
              padding: const EdgeInsets.fromLTRB(AppTheme.gutter, 8, AppTheme.gutter, 30),
              children: [
                Text(
                  '已解锁 $unlocked / ${_badges.length}',
                  style: text.displaySmall?.copyWith(fontSize: 22),
                ),
                const SizedBox(height: 8),
                Text('全部按本机数据计算，清除练习记录会重新开始', style: text.bodySmall),
                const SizedBox(height: 22),
                for (final entry in groups.entries) ...[
                  Text(entry.key, style: text.titleSmall),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 12,
                    runSpacing: 18,
                    children: [
                      for (final badge in entry.value)
                        _BadgeTile(
                          badge: badge,
                          onTap: () => showBadgeCard(context, badge),
                        ),
                    ],
                  ),
                  const SizedBox(height: 26),
                ],
              ],
            ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({required this.badge, required this.onTap});

  final AchievementBadge badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return SizedBox(
      width: 96,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          children: [
            BadgeMedal(badge: badge, size: 72),
            const SizedBox(height: 9),
            Text(
              badge.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.titleSmall?.copyWith(
                fontSize: 13.5,
                color: badge.unlocked ? t.text : t.muted,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              badge.unlocked
                  ? badge.tier.label
                  : '${badge.value}/${badge.target}',
              style: text.bodySmall?.copyWith(
                fontSize: 11,
                color: badge.unlocked ? badge.tier.color : t.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The medal itself: a tier-coloured ring that fills with progress while
/// locked, and glows once earned.
class BadgeMedal extends StatelessWidget {
  const BadgeMedal({
    super.key,
    required this.badge,
    this.size = 72,
    this.animate = false,
  });

  final AchievementBadge badge;
  final double size;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final color = badge.tier.color;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: animate ? 0 : 1, end: 1),
      duration: Duration(milliseconds: animate ? 700 : 1),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size(size, size),
              painter: _MedalPainter(
                progress: badge.progress,
                unlocked: badge.unlocked,
                color: color,
                track: t.name == 'dark'
                    ? Colors.white.withValues(alpha: 0.10)
                    : t.text.withValues(alpha: 0.08),
                fill: badge.unlocked
                    ? color.withValues(alpha: 0.14)
                    : (t.name == 'dark'
                        ? Colors.white.withValues(alpha: 0.04)
                        : t.text.withValues(alpha: 0.03)),
              ),
            ),
            StrokeIcon(
              badge.icon,
              size: size * 0.34,
              color: badge.unlocked ? color : t.muted.withValues(alpha: 0.7),
              weight: 2,
            ),
          ],
        ),
      ),
    );
  }
}

class _MedalPainter extends CustomPainter {
  const _MedalPainter({
    required this.progress,
    required this.unlocked,
    required this.color,
    required this.track,
    required this.fill,
  });

  final double progress;
  final bool unlocked;
  final Color color;
  final Color track;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 5;

    canvas.drawCircle(c, r - 2, Paint()..color = fill);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = track,
    );

    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        -math.pi / 2,
        math.pi * 2 * progress,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round
          ..color = color.withValues(alpha: unlocked ? 1 : 0.55),
      );
    }

    // Earned medals get eight short rays, like a stamped seal.
    if (unlocked) {
      final ray = Paint()
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..color = color.withValues(alpha: 0.55);
      for (var i = 0; i < 8; i++) {
        final a = i * math.pi / 4 + math.pi / 8;
        canvas.drawLine(
          c + Offset(math.cos(a), math.sin(a)) * (r + 3),
          c + Offset(math.cos(a), math.sin(a)) * (r + 7),
          ray,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MedalPainter old) =>
      old.progress != progress || old.unlocked != unlocked;
}

/// Opens the badge card with a spring-scale + fade transition. A bottom sheet
/// made an earned medal feel like a settings row; this reads like a card being
/// dealt onto the table.
Future<void> showBadgeCard(BuildContext context, AchievementBadge badge) {
  HapticFeedback.lightImpact();
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: badge.name,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    transitionDuration: const Duration(milliseconds: 420),
    pageBuilder: (_, __, ___) => _BadgeCard(badge: badge),
    transitionBuilder: (context, anim, _, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
      return Opacity(
        opacity: anim.value.clamp(0.0, 1.0),
        child: Transform.scale(
          scale: 0.82 + 0.18 * curved.value,
          child: Transform.rotate(
            angle: (1 - curved.value) * 0.06,
            child: child,
          ),
        ),
      );
    },
  );
}

class _BadgeCard extends StatefulWidget {
  const _BadgeCard({required this.badge});

  final AchievementBadge badge;

  @override
  State<_BadgeCard> createState() => _BadgeCardState();
}

class _BadgeCardState extends State<_BadgeCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shine = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat();

  @override
  void dispose() {
    _shine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final badge = widget.badge;
    final color = badge.tier.color;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 34),
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 26, 24, 20),
            decoration: BoxDecoration(
              color: t.gradient.last,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: badge.unlocked
                    ? color.withValues(alpha: 0.4)
                    : t.glassBorder,
              ),
              boxShadow: t.shadow,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Earned medals get a slow rotating halo.
                    if (badge.unlocked)
                      AnimatedBuilder(
                        animation: _shine,
                        builder: (_, __) => Transform.rotate(
                          angle: _shine.value * 6.28,
                          child: CustomPaint(
                            size: const Size(132, 132),
                            painter: _HaloPainter(color: color),
                          ),
                        ),
                      ),
                    BadgeMedal(badge: badge, size: 104, animate: true),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(badge.name, style: text.displaySmall?.copyWith(fontSize: 23)),
                    const SizedBox(width: 9),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badge.tier.label,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          height: 1,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  badge.desc,
                  textAlign: TextAlign.center,
                  style: text.bodyMedium?.copyWith(fontSize: 14, height: 1.6),
                ),
                const SizedBox(height: 20),
                if (badge.unlocked)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, size: 16, color: t.success),
                      const SizedBox(width: 7),
                      Text(
                        badge.unlockedAt == null
                            ? '已达成'
                            : '${badge.unlockedAt!.month} 月 ${badge.unlockedAt!.day} 日解锁',
                        style: text.bodySmall?.copyWith(color: t.success),
                      ),
                    ],
                  )
                else ...[
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: badge.progress),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, __) => ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: v,
                        minHeight: 6,
                        color: color,
                        backgroundColor: t.name == 'dark'
                            ? Colors.white.withValues(alpha: 0.10)
                            : t.text.withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${badge.value} / ${badge.target}'
                    '${badge.target - badge.value > 0 ? ' · 还差 ${badge.target - badge.value}' : ''}',
                    style: text.bodySmall,
                  ),
                ],
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('关闭'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HaloPainter extends CustomPainter {
  const _HaloPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final paint = Paint()
      ..shader = SweepGradient(
        colors: [
          color.withValues(alpha: 0),
          color.withValues(alpha: 0.35),
          color.withValues(alpha: 0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: c, radius: size.width / 2))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;
    canvas.drawCircle(c, size.width / 2 - 8, paint);
  }

  @override
  bool shouldRepaint(covariant _HaloPainter old) => false;
}

/// Celebration shown right after a session when something new is earned.
class BadgeUnlockedDialog extends StatelessWidget {
  const BadgeUnlockedDialog({super.key, required this.badges});

  final List<AchievementBadge> badges;

  static Future<void> show(BuildContext context, List<AchievementBadge> badges) {
    if (badges.isEmpty) return Future.value();
    HapticFeedback.heavyImpact();
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (_) => BadgeUnlockedDialog(badges: badges),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final badge = badges.first;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          decoration: BoxDecoration(
            color: t.gradient.last,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: t.glassBorder),
            boxShadow: t.shadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  // Burst of rays behind the medal.
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, __) => CustomPaint(
                      size: const Size(160, 160),
                      painter: _BurstPainter(progress: v, color: badge.tier.color),
                    ),
                  ),
                  BadgeMedal(badge: badge, size: 96, animate: true),
                ],
              ),
              const SizedBox(height: 18),
              Text('解锁成就', style: text.bodySmall),
              const SizedBox(height: 6),
              Text(badge.name, style: text.displaySmall?.copyWith(fontSize: 24)),
              const SizedBox(height: 10),
              Text(
                badge.desc,
                textAlign: TextAlign.center,
                style: text.bodyMedium?.copyWith(fontSize: 14),
              ),
              if (badges.length > 1) ...[
                const SizedBox(height: 12),
                Text('同时还解锁了 ${badges.length - 1} 个', style: text.bodySmall),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('收下'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BurstPainter extends CustomPainter {
  const _BurstPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final paint = Paint()
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 12; i++) {
      final a = i * math.pi / 6;
      final start = 52 + 16 * progress;
      final len = 10 * progress;
      paint.color = color.withValues(alpha: (1 - progress) * 0.8);
      canvas.drawLine(
        c + Offset(math.cos(a), math.sin(a)) * start,
        c + Offset(math.cos(a), math.sin(a)) * (start + len),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BurstPainter old) => old.progress != progress;
}
