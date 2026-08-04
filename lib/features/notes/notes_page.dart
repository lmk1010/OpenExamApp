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

/// 我的笔记 — every question the user wrote something on, newest first.
class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  bool _loading = true;
  List<({Question question, String body, DateTime at})> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await AppDatabase.instance.notedQuestions();
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  Future<void> _open(Question q) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PracticeSessionPage(
          questions: [q],
          reviewAnswers: {q.id: q.answer.toUpperCase()},
          title: '笔记回顾',
        ),
      ),
    );
    _load();
  }

  Future<void> _delete(Question q) async {
    await AppDatabase.instance.setNote(q.id, '');
    await _load();
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
        title: const Text('我的笔记'),
        actions: [
          if (_items.isNotEmpty)
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PracticeSessionPage(
                    questions: _items.map((e) => e.question).toList(),
                    reviewAnswers: {
                      for (final e in _items)
                        e.question.id: e.question.answer.toUpperCase(),
                    },
                    title: '笔记回顾',
                  ),
                ),
              ),
              child: const Text('全部回顾'),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const LoadingState()
          : _items.isEmpty
              ? const EmptyState(
                  icon: Icons.sticky_note_2_outlined,
                  title: '还没有笔记',
                  art: EmptyArt.box,
                  message: '做题时点右上角的便签图标，写下方法或坑点，这里会汇总。',
                )
              : ListView(
                  padding: const EdgeInsets.only(top: 6, bottom: 28),
                  children: [
                    for (var i = 0; i < _items.length; i++) ...[
                      if (i > 0) const RowDivider(),
                      Dismissible(
                        key: ValueKey(_items[i].question.id),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) => _delete(_items[i].question),
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: AppTheme.gutter),
                          color: t.dangerSoft,
                          child: Text(
                            '删除笔记',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: t.danger,
                            ),
                          ),
                        ),
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _open(_items[i].question),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.gutter,
                              vertical: 14,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: QuestionThumb(
                                        markup: _items[i].question.bodyMarkup,
                                        icon: categoryIcon(_items[i].question.category),
                                        color: t.category(_items[i].question.category),
                                      ),
                                    ),
                                    const SizedBox(width: 13),
                                    Expanded(
                                      child: Text(
                                        _items[i].question.content,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: text.bodyLarge?.copyWith(
                                          fontSize: 15,
                                          height: 1.45,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                // The note itself is the point of this row.
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: t.category('shuliang').withValues(alpha: 0.10),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _items[i].body,
                                    style: text.bodyMedium?.copyWith(
                                      color: t.text,
                                      height: 1.55,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    StrokeIcon(
                                      categoryIcon(_items[i].question.category),
                                      size: 13,
                                      color: t.muted,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      categoryLabel(_items[i].question.category),
                                      style: text.bodySmall,
                                    ),
                                    Text(
                                      ' · ${_items[i].at.month}/${_items[i].at.day}',
                                      style: text.bodySmall,
                                    ),
                                  ],
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
