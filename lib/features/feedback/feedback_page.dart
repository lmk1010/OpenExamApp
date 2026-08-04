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

/// 纠错记录 — questions the user flagged as wrong or unclear. Offline, so this
/// is a personal list rather than a ticket queue; it travels with backups.
class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  bool _loading = true;
  List<({int id, Question question, String kind, String note, DateTime at})>
      _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await AppDatabase.instance.listFeedback();
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
          title: '纠错回看',
        ),
      ),
    );
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
        title: const Text('纠错记录'),
      ),
      body: _loading
          ? const LoadingState()
          : _items.isEmpty
              ? const EmptyState(
                  icon: Icons.report_gmailerrorred_outlined,
                  title: '还没有纠错记录',
                  art: EmptyArt.box,
                  message: '做题时长按顶部的题号，可以标记答案有误、解析看不懂等问题。',
                )
              : ListView(
                  padding: const EdgeInsets.only(top: 6, bottom: 28),
                  children: [
                    for (var i = 0; i < _items.length; i++) ...[
                      if (i > 0) const RowDivider(),
                      Dismissible(
                        key: ValueKey(_items[i].id),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) async {
                          await AppDatabase.instance.deleteFeedback(_items[i].id);
                          await _load();
                        },
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: AppTheme.gutter),
                          color: t.dangerSoft,
                          child: Text(
                            '删除',
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
                            child: Row(
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
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _items[i].question.content,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: text.bodyLarge?.copyWith(
                                          fontSize: 15,
                                          height: 1.45,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: t.danger.withValues(alpha: 0.13),
                                              borderRadius: BorderRadius.circular(7),
                                            ),
                                            child: Text(
                                              kFeedbackKinds[_items[i].kind] ?? '问题',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                height: 1,
                                                color: t.danger,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '${_items[i].at.month}/${_items[i].at.day}',
                                            style: text.bodySmall,
                                          ),
                                        ],
                                      ),
                                      if (_items[i].note.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          _items[i].note,
                                          style: text.bodyMedium?.copyWith(
                                            fontSize: 13.5,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: StrokeIcon(
                                    AppIcon.play,
                                    size: 20,
                                    color: t.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppTheme.gutter,
                        20,
                        AppTheme.gutter,
                        0,
                      ),
                      child: Text(
                        '这些记录只存在本机，会随备份一起导出。左滑删除。',
                        style: text.bodySmall,
                      ),
                    ),
                  ],
                ),
    );
  }
}
