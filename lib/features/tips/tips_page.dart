import 'package:flutter/material.dart';
import 'package:openexam_app/core/constants/categories.dart';
import 'package:openexam_app/core/theme/app_theme.dart';
import 'package:openexam_app/core/theme/app_tokens.dart';
import 'package:openexam_app/core/ui/glass.dart';
import 'package:openexam_app/core/ui/stroke_icons.dart';
import 'package:openexam_app/features/tips/tips.dart';

/// 解题技巧 — method cards per module. Opened from 我的, or from the category
/// chip while practising when a question type stops making sense.
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
    final text = Theme.of(context).textTheme;
    final group = tipsFor(_selected) ?? kTipGroups.first;
    final color = t.category(group.category);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 21),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        titleSpacing: 0,
        title: const Text('解题技巧'),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.gutter),
              children: [
                for (final g in kTipGroups)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() => _selected = g.category),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _selected == g.category
                              ? t.category(g.category)
                              : t.glass,
                          borderRadius: BorderRadius.circular(19),
                        ),
                        child: Text(
                          categoryLabel(g.category),
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            height: 1,
                            color: _selected == g.category
                                ? GlassDecor.on(t.category(g.category))
                                : t.textSoft,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.gutter,
                18,
                AppTheme.gutter,
                30,
              ),
              children: [
                Row(
                  children: [
                    StrokeIcon(categoryIcon(group.category), size: 20, color: color),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Text(
                        group.summary,
                        style: text.titleSmall?.copyWith(fontSize: 15),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                for (var i = 0; i < group.tips.length; i++) ...[
                  if (i > 0) const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
                    decoration: GlassDecor.panel(t, radius: 18, raised: false),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${i + 1}',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  height: 1,
                                  color: color,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                group.tips[i].title,
                                style: text.titleSmall?.copyWith(fontSize: 15),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          group.tips[i].body,
                          style: text.bodyMedium?.copyWith(
                            fontSize: 14,
                            height: 1.7,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                Text(
                  '这些是通用方法，具体题型的技巧还是要靠自己在错题里总结 —— '
                  '做题时可以随手记进笔记。',
                  style: text.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
