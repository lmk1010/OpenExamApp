import 'package:flutter/material.dart';
import 'package:openexam_app/core/constants/categories.dart';
import 'package:openexam_app/core/theme/app_theme.dart';
import 'package:openexam_app/core/theme/app_tokens.dart';
import 'package:openexam_app/core/ui/shore_art.dart';
import 'package:openexam_app/core/ui/ambient.dart';
import 'package:openexam_app/core/ui/stroke_icons.dart';
import 'package:openexam_app/core/ui/ui_kit.dart';
import 'package:openexam_app/features/plan/domain/models/study_task.dart';

typedef StudyTaskCallback = Future<void> Function(StudyTask task);

/// Compact "今日安排" block for the practice home — same quiet surface language
/// as the rest of the shell, not the old glow card.
class TodayPlanSection extends StatelessWidget {
  const TodayPlanSection({
    super.key,
    required this.plan,
    required this.doneIds,
    required this.onToggle,
    required this.onRun,
    required this.onManage,
    this.onOpen,
    this.onLongPress,
    this.onEnable,
  });

  final DayPlan? plan;
  final Set<String> doneIds;
  final Future<void> Function(StudyTask task, bool done) onToggle;
  final StudyTaskCallback onRun;
  final VoidCallback onManage;

  /// Tap the row body → open task arrangement (not start practice).
  final ValueChanged<StudyTask>? onOpen;

  /// Long-press → rename / delete / edit menu.
  final ValueChanged<StudyTask>? onLongPress;
  final VoidCallback? onEnable;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    if (plan == null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.gutter,
          18,
          AppTheme.gutter,
          0,
        ),
        child: Panel(
          fill: true,
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          onTap: onEnable ?? onManage,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('今日安排', style: text.titleSmall),
                    const SizedBox(height: 4),
                    Text(
                      '还没有复习计划。选用在职晚间模板，每天打开就知道练什么。',
                      style: text.bodySmall,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, size: 18, color: t.muted),
            ],
          ),
        ),
      );
    }

    final tasks = plan!.tasks;
    final done = tasks.where((task) => doneIds.contains(task.id)).length;
    final total = tasks.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.gutter,
            20,
            AppTheme.gutter,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
            children: [
              Text(
                '今日安排',
                style: text.titleMedium?.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$done / $total',
                style: text.bodySmall?.copyWith(
                  color: done >= total && total > 0 ? t.brand : t.muted,
                  fontFeatures: AppTheme.numeric,
                ),
              ),
              const Spacer(),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onManage,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    '管理',
                    style: text.labelMedium?.copyWith(color: t.brand),
                  ),
                ),
              ),
            ],
          ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 116,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.gutter),
            itemCount: tasks.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final task = tasks[i];
              return _TaskCard(
                task: task,
                checked: doneIds.contains(task.id),
                onToggle: (v) => onToggle(task, v),
                onRun: () => onRun(task),
                onLongPress:
                    onLongPress == null ? null : () => onLongPress!(task),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// 每种任务对应的图标和颜色 —— 一列纯文字扫不动，图标才是锚点。
({AppIcon icon, Color color, String? art}) _taskGlyph(StudyTask task, AppTokens t) {
  // 有题型就用题型的插画和配色，跟下面的题型卡是同一套视觉
  if (task.category != null) {
    for (final c in kGongkaoCategories) {
      if (c.key == task.category) {
        return (
          icon: c.icon,
          color: t.category(c.key),
          art: ShoreArt.isle(c.key),
        );
      }
    }
  }
  return switch (task.action) {
    StudyAction.daily =>
      (icon: AppIcon.shuffle, color: t.brand, art: ShoreArt.chart),
    StudyAction.mock =>
      (icon: AppIcon.timer, color: t.brand, art: ShoreArt.log),
    StudyAction.wrong =>
      (icon: AppIcon.replay, color: t.danger, art: ShoreArt.emptyWrong),
    StudyAction.openWrongBook =>
      (icon: AppIcon.wrongBook, color: t.danger, art: ShoreArt.emptyWrong),
    StudyAction.adaptive =>
      (icon: AppIcon.auto, color: t.brand, art: ShoreArt.icoStats),
    StudyAction.note =>
      (icon: AppIcon.papers, color: t.success, art: ShoreArt.essay),
    StudyAction.practice =>
      (icon: AppIcon.practice, color: t.brand, art: ShoreArt.voyage),
  };
}

/// 任务卡：图标 + 标题 + 一个数字，点卡片直接开练。
/// 左上角的圆点是完成开关，做完整张卡变淡。
class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.checked,
    required this.onToggle,
    required this.onRun,
    this.onLongPress,
  });

  final StudyTask task;
  final bool checked;
  final ValueChanged<bool> onToggle;
  final VoidCallback onRun;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final glyph = _taskGlyph(task, t);
    final dark = t.name == 'dark';

    // 图标已经说明了题型，标题里写过的数字也别再重复一遍
    final countText = task.count == null ? '' : '${task.count} 题';
    final meta = countText.isNotEmpty && !task.title.contains(countText)
        ? countText
        : (task.minutes != null && !task.title.contains('分钟')
            ? '${task.minutes} 分钟'
            : '');

    return Opacity(
      // 做完的卡整体淡下去就够了。再叠删除线、再留一幅插画，
      // 一张"已经不用管"的卡反而最扎眼。
      opacity: checked ? 0.4 : 1,
      child: PressableCard(
        onTap: checked ? () => onToggle(false) : onRun,
        onLongPress: onLongPress,
        child: Container(
          width: 176,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: dark
                    ? Colors.black.withValues(alpha: 0.32)
                    : const Color(0xFF1B2540).withValues(alpha: 0.055),
                blurRadius: dark ? 22 : 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: t.surface,
                      // 一层很淡的色，从左侧过渡到右边留白，插画落在那片留白上
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          glyph.color.withValues(alpha: dark ? 0.16 : 0.10),
                          glyph.color.withValues(alpha: dark ? 0.04 : 0.02),
                        ],
                      ),
                    ),
                  ),
                ),
                if (glyph.art != null && !checked)
                  Positioned(
                    right: -26,
                    bottom: -26,
                    width: 72,
                    height: 72,
                    child: Opacity(
                      // 压到角上、再压淡一点：它是氛围，标题才是要读的
                      opacity: dark ? 0.20 : 0.26,
                      child: Image.asset(
                        glyph.art!,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          StrokeIcon(glyph.icon, size: 19, color: glyph.color),
                          const Spacer(),
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => onToggle(!checked),
                            child: Container(
                              width: 21,
                              height: 21,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: checked ? t.success : Colors.transparent,
                                border: checked
                                    ? null
                                    : Border.all(
                                        color: t.text.withValues(alpha: 0.26),
                                        width: 1.6,
                                      ),
                              ),
                              child: checked
                                  ? const Icon(Icons.check_rounded,
                                      size: 13, color: Colors.white)
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 44),
                        child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            task.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: text.titleSmall?.copyWith(
                              fontSize: 13.5,
                              height: 1.3,
                              color: t.text,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (meta.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              meta,
                              style: text.bodySmall?.copyWith(fontSize: 11),
                            ),
                          ],
                        ],
                        ),
                      ),
                    ],
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

String categoryShort(String? key) {
  for (final item in kGongkaoCategories) {
    if (item.key == key) return item.short;
  }
  return key ?? '';
}
