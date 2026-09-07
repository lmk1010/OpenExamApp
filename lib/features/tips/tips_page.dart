import 'package:flutter/material.dart';
import 'package:openexam_app/l10n/app_localizations.dart';
import 'package:openexam_app/core/constants/categories.dart';
import 'package:openexam_app/core/theme/app_theme.dart';
import 'package:openexam_app/core/theme/app_tokens.dart';
import 'package:openexam_app/core/ui/glass.dart';
import 'package:openexam_app/features/tips/tips.dart';

/// 解题技巧。从「我的」进，或者练习时点分类标签进。
///
/// 排版跟着内容走：上半页是真题里数出来的事实（这模块几道题、在卷子第几题、
/// 给几分钟、内部怎么分），下半页才是方法。以前整页是五张一模一样的圆角卡，
/// 每张一条心法 —— 卡片本身不带信息，还把一屏能放的内容压到了三条。
class TipsPage extends StatefulWidget {
  const TipsPage({super.key, this.category});

  /// Opens straight to one module when arriving from a question.
  final String? category;

  @override
  State<TipsPage> createState() => _TipsPageState();
}

class _TipsPageState extends State<TipsPage> {
  late String _selected = widget.category ?? kTipGroups.first.category;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final group = tipsFor(_selected) ?? kTipGroups.first;
    final color = t.category(group.category);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 21),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        titleSpacing: 0,
        title: Text(AppL.of(context).tipsTitle),
      ),
      body: Column(
        children: [
          _ModuleTabs(
            selected: _selected,
            onSelect: (c) => setState(() => _selected = c),
          ),
          Expanded(
            child: ListView(
              key: ValueKey(_selected),
              padding: EdgeInsets.only(
                bottom: MediaQuery.paddingOf(context).bottom + 30,
              ),
              children: [
                _Headline(group: group, color: color),
                const SizedBox(height: 16),
                _StatStrip(group: group, color: color),
                const SizedBox(height: 22),
                _PaperMaps(active: group.category),
                if (group.breakdown.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  _BreakdownTable(group: group, color: color),
                ],
                if (group.hotspots.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  _Hotspots(group: group, color: color),
                ],
                const SizedBox(height: 24),
                _Plays(group: group, color: color),
                const SizedBox(height: 24),
                _Methods(group: group),
                const SizedBox(height: 22),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.gutter),
                  child: Text(
                    kTipsFootnote,
                    style: TextStyle(
                        fontSize: 11.5, height: 1.6, color: t.muted),
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

/// 小标题。整页复用，省得每处各写一遍。
class _Label extends StatelessWidget {
  const _Label(this.text, {this.trailing});

  final String text;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppTheme.gutter, 0, AppTheme.gutter, 9),
      child: Row(
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
              color: t.muted,
            ),
          ),
          if (trailing != null) ...[
            const Spacer(),
            Text(
              trailing!,
              style: TextStyle(
                fontSize: 11,
                color: t.muted,
                fontFeatures: AppTheme.numeric,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 模块切换。胶囊上带题量 —— 一行字就把五个模块的权重摆出来了。
class _ModuleTabs extends StatelessWidget {
  const _ModuleTabs({required this.selected, required this.onSelect});

  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.gutter),
        children: [
          for (final g in kTipGroups)
            Padding(
              padding: const EdgeInsets.only(right: 7),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onSelect(g.category),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 13),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected == g.category
                        ? t.category(g.category)
                        : t.surfaceAlt,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Text(
                        CategoryRegistry.metaFor(g.category).short,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          height: 1,
                          color: selected == g.category
                              ? GlassDecor.on(t.category(g.category))
                              : t.textSoft,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${g.anhui.count}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          height: 1,
                          fontFeatures: AppTheme.numeric,
                          color: selected == g.category
                              ? GlassDecor.on(t.category(g.category))
                                  .withValues(alpha: 0.65)
                              : t.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Headline extends StatelessWidget {
  const _Headline({required this.group, required this.color});

  final TipGroup group;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppTheme.gutter, 18, AppTheme.gutter, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            group.summary,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              height: 1.4,
              letterSpacing: -0.3,
              color: t.text,
            ),
          ),
          const SizedBox(height: 9),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 2.5,
                height: 34,
                margin: const EdgeInsets.only(top: 3, right: 11),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: Text(
                  group.trend,
                  style: TextStyle(
                      fontSize: 13, height: 1.65, color: t.textSoft),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 四个数：题量、卷面题号、建议用时、单题秒数。
class _StatStrip extends StatelessWidget {
  const _StatStrip({required this.group, required this.color});

  final TipGroup group;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final items = <List<String>>[
      ['${group.anhui.count}', AppL.of(context).tipsUnitQuestions],
      [group.anhui.range, AppL.of(context).tipsPaperNumbers],
      ['${group.minutes}', AppL.of(context).tipsUnitMinutes],
      [group.paceValue, group.paceCaption],
    ];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.gutter),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: GlassDecor.panel(t, radius: 16, raised: false),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0)
              Container(width: 1, height: 26, color: t.lineSoft),
            Expanded(
              child: Column(
                children: [
                  Text(
                    items[i][0],
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                      letterSpacing: -0.5,
                      fontFeatures: AppTheme.numeric,
                      color: i == 0 ? color : t.text,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    items[i][1],
                    style: TextStyle(fontSize: 11, color: t.muted),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 卷面地图。色块宽度按真实题量画，当前模块高亮，其余压暗 ——
/// 一眼能看出这个模块坐在卷子的哪一段、前后是谁。
class _PaperMaps extends StatelessWidget {
  const _PaperMaps({required this.active});

  final String active;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(AppL.of(context).tipsWhereOnPaper, trailing: AppL.of(context).tipsYear2026),
        for (final layout in kPaperLayouts)
          Builder(builder: (context) {
            final hit =
                layout.segments.where((s) => s.category == active).firstOrNull;
            return Padding(
            padding: const EdgeInsets.fromLTRB(AppTheme.gutter, 0, AppTheme.gutter, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      layout.label,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: t.textSoft,
                      ),
                    ),
                    if (hit != null) ...[
                      SizedBox(width: 7),
                      Text(
                        AppL.of(context).tipsQuestionRange(hit.from, hit.to),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: t.category(active),
                          fontFeatures: AppTheme.numeric,
                        ),
                      ),
                    ],
                    Spacer(),
                    Text(
                      AppL.of(context).tipsTotalAndMinutes(layout.total, layout.minutes),
                      style: TextStyle(
                        fontSize: 11.5,
                        color: t.muted,
                        fontFeatures: AppTheme.numeric,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: SizedBox(
                    height: 26,
                    child: Row(
                      children: [
                        for (final seg in layout.segments)
                          Expanded(
                            flex: seg.count,
                            child: _Segment(
                              segment: seg,
                              on: seg.category == active,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                _Caret(layout: layout, hit: hit, active: active),
              ],
            ),
          );
          }),
      ],
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({required this.segment, required this.on});

  final PaperSegment segment;
  final bool on;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final color = t.category(segment.category);
    return Container(
      margin: const EdgeInsets.only(right: 2),
      alignment: Alignment.center,
      color: on ? color : color.withValues(alpha: 0.26),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Text(
            '${segment.count}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              height: 1,
              fontFeatures: AppTheme.numeric,
              // 压暗那几段的题量也是信息，别淡到读不出来。
              color: on ? GlassDecor.on(color) : t.textSoft,
            ),
          ),
        ),
      ),
    );
  }
}

/// 带子下面指向当前模块的小三角。题号区间摆在上面那行 —— 塞进色块下面
/// 那一小段宽度里会被压缩到读不出来（数量关系只占全卷 12%）。
class _Caret extends StatelessWidget {
  const _Caret({required this.layout, required this.hit, required this.active});

  final PaperLayout layout;
  final PaperSegment? hit;
  final String active;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final seg = hit;
    if (seg == null) return const SizedBox(height: 6);
    final before = seg.from - 1;
    final after = layout.total - seg.to;
    return SizedBox(
      height: 6,
      child: Row(
        children: [
          if (before > 0) Expanded(flex: before, child: const SizedBox()),
          Expanded(
            flex: seg.count,
            child: Center(
              child: CustomPaint(
                size: const Size(11, 5),
                painter: _CaretPainter(t.category(active)),
              ),
            ),
          ),
          if (after > 0) Expanded(flex: after, child: const SizedBox()),
        ],
      ),
    );
  }
}

class _CaretPainter extends CustomPainter {
  const _CaretPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_CaretPainter old) => old.color != color;
}

/// 模块内部：安徽几道、国考几道、单题给几秒。安徽那一列带条形，
/// 因为时间是按安徽的题量分的。
class _BreakdownTable extends StatelessWidget {
  const _BreakdownTable({required this.group, required this.color});

  final TipGroup group;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final max = group.breakdown
        .map((b) => b.anhui > b.guokao ? b.anhui : b.guokao)
        .reduce((a, b) => a > b ? a : b);
    final timed = group.breakdown.any((b) => b.seconds > 0);

    Widget head(String s, double w) => SizedBox(
          width: w,
          child: Text(
            s,
            textAlign: TextAlign.right,
            style: TextStyle(fontSize: 10.5, color: t.muted, height: 1),
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(timed ? AppL.of(context).tipsBreakdownPace : AppL.of(context).tipsBreakdown),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: AppTheme.gutter),
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
          decoration: GlassDecor.panel(t, radius: 16, raised: false),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8, left: 2),
                child: Row(
                  children: [
                    Spacer(),
                    head('安徽', 34),
                    head('国考', 34),
                    if (timed) head(AppL.of(context).dxColSeconds, 42),
                  ],
                ),
              ),
              for (final b in group.breakdown)
                Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 62,
                        child: Text(
                          b.name,
                          style: TextStyle(fontSize: 13, color: t.text),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: SizedBox(
                              height: 7,
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: b.anhui,
                                    child: Container(color: color),
                                  ),
                                  Expanded(
                                    flex: max - b.anhui,
                                    child: Container(color: t.lineSoft),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      _Num('${b.anhui}', width: 34, bold: true),
                      _Num('${b.guokao}', width: 34, soft: true),
                      if (timed)
                        _Num(b.seconds > 0 ? '${b.seconds}' : '—',
                            width: 42, soft: true),
                    ],
                  ),
                ),
            ],
          ),
        ),
        if (group.breakdownNote.isNotEmpty)
          Padding(
            padding:
                const EdgeInsets.fromLTRB(AppTheme.gutter, 9, AppTheme.gutter, 0),
            child: Text(
              group.breakdownNote,
              style: TextStyle(fontSize: 11.5, height: 1.5, color: t.muted),
            ),
          ),
      ],
    );
  }
}

class _Num extends StatelessWidget {
  const _Num(this.text, {required this.width, this.bold = false, this.soft = false});

  final String text;
  final double width;
  final bool bold;
  final bool soft;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return SizedBox(
      width: width,
      child: Text(
        text,
        textAlign: TextAlign.right,
        style: TextStyle(
          fontSize: 13,
          height: 1.3,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          fontFeatures: AppTheme.numeric,
          color: soft ? t.muted : t.text,
        ),
      ),
    );
  }
}

/// 数量关系没有官方题型划分，只能列高频考点。
class _Hotspots extends StatelessWidget {
  const _Hotspots({required this.group, required this.color});

  final TipGroup group;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(AppL.of(context).tipsHotspots, trailing: AppL.of(context).tipsHotspotsHint),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.gutter),
          child: Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              for (final h in group.hotspots)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    h,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                      color: color,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(AppTheme.gutter, 9, AppTheme.gutter, 0),
          child: Text(
            AppL.of(context).tipsHotspotsNote,
            style: TextStyle(fontSize: 11.5, height: 1.5, color: t.muted),
          ),
        ),
      ],
    );
  }
}

/// 考场动作。带序号，因为它们是有先后的。
class _Plays extends StatelessWidget {
  const _Plays({required this.group, required this.color});

  final TipGroup group;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(AppL.of(context).tipsInExam),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: AppTheme.gutter),
          decoration: GlassDecor.panel(t, radius: 16, raised: false),
          child: Column(
            children: [
              for (var i = 0; i < group.plays.length; i++)
                Container(
                  padding: EdgeInsets.fromLTRB(14, i == 0 ? 13 : 12, 14, 12),
                  decoration: BoxDecoration(
                    border: i == 0
                        ? null
                        : Border(top: BorderSide(color: t.lineSoft)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 19,
                        height: 19,
                        margin: const EdgeInsets.only(top: 1, right: 10),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            height: 1,
                            color: GlassDecor.on(color),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              group.plays[i].action,
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                                height: 1.45,
                                color: t.text,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              group.plays[i].why,
                              style: TextStyle(
                                fontSize: 12.5,
                                height: 1.6,
                                color: t.textSoft,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 方法速查。一条一行，靠分隔线断开 —— 不再一条一张卡。
class _Methods extends StatelessWidget {
  const _Methods({required this.group});

  final TipGroup group;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(AppL.of(context).tipsMethods, trailing: AppL.of(context).tipsMethodCount(group.tips.length)),
        for (var i = 0; i < group.tips.length; i++)
          Container(
            padding: EdgeInsets.fromLTRB(
                AppTheme.gutter, i == 0 ? 0 : 13, AppTheme.gutter, 13),
            decoration: BoxDecoration(
              border: i == 0
                  ? null
                  : Border(
                      top: BorderSide(
                        color: t.lineSoft,
                      ),
                    ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.tips[i].title,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                    color: t.text,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  group.tips[i].body,
                  style: TextStyle(
                      fontSize: 13.5, height: 1.75, color: t.textSoft),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
