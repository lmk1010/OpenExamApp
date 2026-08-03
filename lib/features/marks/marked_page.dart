import 'package:flutter/material.dart';
import 'package:openexam_app/core/constants/categories.dart';
import 'package:openexam_app/core/theme/app_theme.dart';
import 'package:openexam_app/core/theme/app_tokens.dart';
import 'package:openexam_app/core/ui/rich_content.dart';
import 'package:openexam_app/core/ui/stroke_icons.dart';
import 'package:openexam_app/core/ui/ui_kit.dart';
import 'package:openexam_app/data/db/app_database.dart';
import 'package:openexam_app/data/models/question.dart';
import 'package:openexam_app/features/practice/practice_session_page.dart';

/// 我的收藏 — questions starred during practice, re-practisable as a set.
class MarkedPage extends StatefulWidget {
  const MarkedPage({super.key});

  @override
  State<MarkedPage> createState() => _MarkedPageState();
}

class _MarkedPageState extends State<MarkedPage> {
  bool _loading = true;
  List<Question> _items = const [];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final items = await AppDatabase.instance.fetchMarked();
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  Future<void> _practise(List<Question> questions) async {
    if (questions.isEmpty) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PracticeSessionPage(questions: questions)),
    );
    _reload();
  }

  Future<void> _unmark(Question q) async {
    await AppDatabase.instance.toggleMark(q.id, false);
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 21),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        titleSpacing: 0,
        title: const Text('我的收藏'),
        actions: [
          if (_items.isNotEmpty)
            TextButton(
              onPressed: () => _practise(_items.take(20).toList()),
              child: const Text('练一组'),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const LoadingState()
          : _items.isEmpty
              ? const EmptyState(
                  icon: Icons.star_border_rounded,
                  title: '还没有收藏',
                  message: '做题时点右上角的星标，题目会收进这里。',
                )
              : ListView(
                  padding: const EdgeInsets.only(top: 6, bottom: 28),
                  children: [
                    for (var i = 0; i < _items.length; i++) ...[
                      if (i > 0) const RowDivider(),
                      Dismissible(
                        key: ValueKey(_items[i].id),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) => _unmark(_items[i]),
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: AppTheme.gutter),
                          color: t.dangerSoft,
                          child: Text(
                            '取消收藏',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: t.danger,
                            ),
                          ),
                        ),
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _practise([_items[i]]),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.gutter,
                              vertical: 14,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: QuestionThumb(
                                    markup: _items[i].bodyMarkup,
                                    icon: categoryIcon(_items[i].category),
                                    color: t.category(_items[i].category),
                                  ),
                                ),
                                const SizedBox(width: 13),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _items[i].content,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: text.bodyLarge?.copyWith(
                                          fontSize: 15,
                                          height: 1.45,
                                        ),
                                      ),
                                      const SizedBox(height: 7),
                                      Text(
                                        '${categoryLabel(_items[i].category)}'
                                        '${_items[i].hasImage ? ' · 含图' : ''}',
                                        style: text.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: StrokeIcon(AppIcon.play, size: 22, color: t.muted),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
    );
  }
}
