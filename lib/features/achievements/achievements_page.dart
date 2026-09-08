import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:openexam_app/l10n/app_localizations.dart';
import 'package:openexam_app/core/theme/app_theme.dart';
import 'package:openexam_app/core/theme/app_tokens.dart';
import 'package:openexam_app/core/ui/ambient.dart';
import 'package:openexam_app/core/ui/responsive.dart';
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
    // 让出一帧：_load 是 initState 里发起的，第一个 await 之前
    // AppL.of(context) 会抛 "called before initState() completed"。
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    final badges = await Achievements.evaluate(AppL.of(context));
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
        title: Text(AppL.of(context).badgesTitle),
      ),
      body: _loading
          ? LoadingState()
          : ListView(
              padding: EdgeInsets.fromLTRB(
                AppTheme.gutter,
                8,
                AppTheme.gutter,
                30,
              ).add(
                EdgeInsets.symmetric(
                  horizontal: context.isExpanded ? 40 : 0,
                ),
              ),
              children: [
                Text(
                  AppL.of(context).badgesUnlocked(unlocked, _badges.length),
                  style: text.displaySmall?.copyWith(fontSize: 22),
                ),
                SizedBox(height: 8),
                Text(AppL.of(context).badgesNote, style: text.bodySmall),
                const SizedBox(height: 22),
                for (final entry in groups.entries) ...[
                  Text(entry.key, style: text.titleSmall),
                  const SizedBox(height: 14),
                  // 一行四枚。之前固定 96 宽，手机上一行只放得下三枚，
                  // 每组第四枚单独换行，看着像少了一枚。
                  LayoutBuilder(
                    builder: (context, box) {
                      const gap = 10.0;
                      final cols = box.maxWidth >= 520 ? 6 : 4;
                      final w = (box.maxWidth - gap * (cols - 1)) / cols;
                      return Wrap(
                        spacing: gap,
                        runSpacing: 18,
                        children: [
                          for (final badge in entry.value)
                            SizedBox(
                              width: w,
                              child: _BadgeTile(
                                badge: badge,
                                onTap: () =>
                                    showBadgeCard(context, badge, all: _badges),
                              ),
                            ),
                        ],
                      );
                    },
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

    return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          children: [
            BadgeMedal(badge: badge, size: 64),
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
                  ? badge.tier.label(AppL.of(context))
                  : '${badge.value}/${badge.target}',
              style: text.bodySmall?.copyWith(
                fontSize: 11,
                color: badge.unlocked ? badge.tier.color : t.muted,
              ),
            ),
          ],
        ),
      );
  }
}

/// Opens the badge on its own page. A dialog card kept the medal at thumbnail
/// size; a badge you earned deserves the whole screen, and swiping sideways
/// through the set is how people actually browse a collection.
Future<void> showBadgeCard(
  BuildContext context,
  AchievementBadge badge, {
  List<AchievementBadge>? all,
}) {
  HapticFeedback.lightImpact();
  final list = (all == null || all.isEmpty) ? [badge] : all;
  final index = list.indexWhere((b) => b.id == badge.id);
  return Navigator.of(context).push<void>(
    PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 380),
      reverseTransitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (_, __, ___) =>
          BadgeDetailPage(badges: list, initial: index < 0 ? 0 : index),
      transitionsBuilder: (context, anim, _, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: Transform.scale(scale: 0.94 + 0.06 * curved.value, child: child),
        );
      },
    ),
  );
}

/// 徽章详情 — one badge per screen, swipe for the next.
class BadgeDetailPage extends StatefulWidget {
  const BadgeDetailPage({super.key, required this.badges, this.initial = 0});

  final List<AchievementBadge> badges;
  final int initial;

  @override
  State<BadgeDetailPage> createState() => _BadgeDetailPageState();
}

class _BadgeDetailPageState extends State<BadgeDetailPage> {
  late final PageController _pages = PageController(initialPage: widget.initial);
  late int _index = widget.initial;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final badge = widget.badges[_index];
    final tint = badge.unlocked ? badge.tier.color : t.muted;

    // Scaffolds are transparent app-wide, so this page paints its own backdrop
    // — without it the grid underneath showed straight through.
    return AmbientBackground(
      child: Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 21),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        titleSpacing: 0,
      ),
      body: Stack(
        children: [
          // The whole screen takes on the badge's colour and re-tints as you
          // swipe — the medal is the subject, not a thumbnail on a card.
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.45),
                radius: 1.1,
                colors: [
                  tint.withValues(alpha: t.name == 'dark' ? 0.30 : 0.22),
                  tint.withValues(alpha: 0),
                ],
              ),
            ),
          ),
          PageView.builder(
            controller: _pages,
            itemCount: widget.badges.length,
            onPageChanged: (i) {
              HapticFeedback.selectionClick();
              setState(() => _index = i);
            },
            itemBuilder: (context, i) => _BadgeDetail(badge: widget.badges[i]),
          ),
          if (widget.badges.length > 1)
            Positioned(
              left: 0,
              right: 0,
              bottom: 26,
              child: _Dots(count: widget.badges.length, index: _index, color: tint),
            ),
        ],
      ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index, required this.color});

  final int count;
  final int index;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    // Eighteen dots would run off the screen: show a window around the current.
    const window = 7;
    var start = index - window ~/ 2;
    if (start > count - window) start = count - window;
    if (start < 0) start = 0;
    final end = (start + window).clamp(0, count);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = start; i < end; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: i == index ? 18 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: i == index ? color : t.muted.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
      ],
    );
  }
}

class _BadgeDetail extends StatelessWidget {
  const _BadgeDetail({required this.badge});

  final AchievementBadge badge;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final color = badge.unlocked ? badge.tier.color : t.muted;
    final width = MediaQuery.sizeOf(context).width;
    final medal = (width * 0.54).clamp(150.0, 210.0);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          children: [
            const Spacer(flex: 3),
            MedalStage(key: ValueKey(badge.id), badge: badge, size: medal),
            const Spacer(flex: 2),
            Text(
              badge.name,
              textAlign: TextAlign.center,
              style: text.displaySmall?.copyWith(
                fontSize: 30,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              badge.desc,
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(fontSize: 15, height: 1.6),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                // label 是方法不是字段：漏了括号，插值出来的是「Closure: (AppL) => String」。
                // 编译和 analyze 都不报 —— 插值接受任何 Object。
                '${badge.group} · ${badge.tier.label(AppL.of(context))}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  height: 1,
                  color: color,
                ),
              ),
            ),
            Spacer(flex: 3),
            if (badge.unlocked)
              Text(
                badge.unlockedAt == null
                    ? AppL.of(context).badgesEarned
                    : AppL.of(context).badgesEarnedOn(
                        MaterialLocalizations.of(context)
                            .formatShortDate(badge.unlockedAt!),
                      ),
                style: text.bodySmall,
              )
            else ...[
              SizedBox(
                width: 220,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: badge.progress),
                  duration: const Duration(milliseconds: 900),
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
              ),
              SizedBox(height: 11),
              Text(
                '${badge.value} / ${badge.target}'
                '${badge.target - badge.value > 0 ? AppL.of(context).badgesToGo(badge.target - badge.value) : ''}',
                style: text.bodySmall,
              ),
            ],
            const SizedBox(height: 52),
          ],
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
            border: Border.all(color: t.lineSoft),
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
              SizedBox(height: 18),
              Text(AppL.of(context).badgesUnlockedTitle, style: text.bodySmall),
              const SizedBox(height: 6),
              Text(badge.name, style: text.displaySmall?.copyWith(fontSize: 24)),
              const SizedBox(height: 10),
              Text(
                badge.desc,
                textAlign: TextAlign.center,
                style: text.bodyMedium?.copyWith(fontSize: 14),
              ),
              if (badges.length > 1) ...[
                SizedBox(height: 12),
                Text(AppL.of(context).badgesAlsoUnlocked(badges.length - 1), style: text.bodySmall),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(AppL.of(context).badgesTake),
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
