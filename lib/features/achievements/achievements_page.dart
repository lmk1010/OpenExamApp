import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:openexam_app/core/theme/app_theme.dart';
import 'package:openexam_app/core/theme/app_tokens.dart';
import 'package:openexam_app/core/ui/ui_kit.dart';
import 'package:openexam_app/features/achievements/achievements.dart';
import 'package:openexam_app/features/achievements/medal.dart';

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

class _BadgeCardState extends State<_BadgeCard> {
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
                MedalStage(badge: badge, size: 104),
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
                  MedalStage(badge: badge, size: 96, burst: true),
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

/// 徽章展台 — the medal plus everything moving around it: a breathing glow, a
/// slow ray fan, orbiting sparks and a gentle float. Only earned badges get
/// the full show; locked ones just sit there, which is the point.
class MedalStage extends StatefulWidget {
  const MedalStage({
    super.key,
    required this.badge,
    this.size = 104,
    this.burst = false,
  });

  final AchievementBadge badge;
  final double size;

  /// One-shot ring burst, for the moment a badge is unlocked.
  final bool burst;

  @override
  State<MedalStage> createState() => _MedalStageState();
}

class _MedalStageState extends State<MedalStage>
    with TickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 6000),
  );
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void initState() {
    super.initState();
    if (widget.badge.unlocked) {
      _loop.repeat();
      if (widget.burst) _pop.forward();
    }
  }

  @override
  void dispose() {
    _loop.dispose();
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final badge = widget.badge;
    final color = badge.tier.color;
    final box = widget.size * 1.55;

    return SizedBox(
      width: box,
      height: box,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (badge.unlocked)
            AnimatedBuilder(
              animation: Listenable.merge([_loop, _pop]),
              builder: (_, __) => CustomPaint(
                size: Size(box, box),
                painter: _StagePainter(
                  color: color,
                  t: _loop.value,
                  burst: widget.burst ? Curves.easeOutCubic.transform(_pop.value) : 0,
                ),
              ),
            ),
          if (badge.unlocked)
            AnimatedBuilder(
              animation: _loop,
              builder: (_, child) => Transform.translate(
                offset: Offset(0, math.sin(_loop.value * math.pi * 2) * 3.5),
                child: child,
              ),
              child: BadgeMedal(badge: badge, size: widget.size, animate: true, shine: true),
            )
          else
            BadgeMedal(badge: badge, size: widget.size, animate: true),
        ],
      ),
    );
  }
}

class _StagePainter extends CustomPainter {
  const _StagePainter({
    required this.color,
    required this.t,
    required this.burst,
  });

  final Color color;

  /// 0–1 looping.
  final double t;

  /// 0–1 one-shot ring.
  final double burst;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;

    // Breathing glow.
    final breathe = 0.86 + 0.14 * math.sin(t * math.pi * 2);
    canvas.drawCircle(
      c,
      r * 0.86 * breathe,
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: 0.26),
            color.withValues(alpha: 0.06),
            color.withValues(alpha: 0),
          ],
          stops: const [0, 0.55, 1],
        ).createShader(Rect.fromCircle(center: c, radius: r * 0.86 * breathe)),
    );

    // Ray fan, turning slowly behind the medal.
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(t * math.pi * 2);
    final ray = Paint()..color = color.withValues(alpha: 0.16);
    for (var i = 0; i < 12; i++) {
      final a = i * math.pi / 6;
      final w = i.isEven ? 0.055 : 0.03;
      final len = r * (i.isEven ? 0.94 : 0.80);
      final path = Path()
        ..moveTo(0, 0)
        ..lineTo(math.cos(a - w) * len, math.sin(a - w) * len)
        ..lineTo(math.cos(a + w) * len, math.sin(a + w) * len)
        ..close();
      canvas.drawPath(path, ray);
    }
    canvas.restore();

    // Orbiting sparks — two rings turning opposite ways.
    for (var i = 0; i < 7; i++) {
      final a = t * math.pi * 2 + i * math.pi * 2 / 7;
      final o = c + Offset(math.cos(a), math.sin(a)) * r * 0.80;
      canvas.drawCircle(
        o,
        1.6 + 1.2 * math.sin(t * math.pi * 4 + i),
        Paint()..color = color.withValues(alpha: 0.55),
      );
    }
    for (var i = 0; i < 5; i++) {
      final a = -t * math.pi * 2 + i * math.pi * 2 / 5;
      final o = c + Offset(math.cos(a), math.sin(a)) * r * 0.66;
      canvas.drawCircle(
        o,
        1.1,
        Paint()..color = Colors.white.withValues(alpha: 0.45),
      );
    }

    // Unlock shockwave.
    if (burst > 0 && burst < 1) {
      canvas.drawCircle(
        c,
        r * (0.4 + 0.6 * burst),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3 * (1 - burst)
          ..color = color.withValues(alpha: (1 - burst) * 0.8),
      );
      canvas.drawCircle(
        c,
        r * (0.2 + 0.7 * burst),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2 * (1 - burst)
          ..color = Colors.white.withValues(alpha: (1 - burst) * 0.6),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StagePainter old) =>
      old.t != t || old.burst != burst;
}
