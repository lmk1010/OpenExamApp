import 'package:flutter/material.dart';
import 'package:openexam_app/core/constants/categories.dart';
import 'package:openexam_app/core/theme/app_theme.dart';
import 'package:openexam_app/core/theme/app_tokens.dart';
import 'package:openexam_app/core/ui/filter_bar.dart';
import 'package:openexam_app/core/ui/glass.dart';
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

  /// 笔记攒到几十条以后，翻是翻不动的 —— 得能搜、能按题型收窄。
  final TextEditingController _search = TextEditingController();
  String _query = '';
  String _category = 'all';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<({Question question, String body, DateTime at})> get _shown =>
      _items.where((e) {
        if (_category != 'all' && e.question.category != _category) return false;
        if (_query.isEmpty) return true;
        return e.body.contains(_query) || e.question.content.contains(_query);
      }).toList();

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
                    questions: _shown.map((e) => e.question).toList(),
                    reviewAnswers: {
                      for (final e in _shown)
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
                  art: EmptyArt.note,
                  message: '做题时点右上角的便签图标，写下方法或坑点，这里会汇总。',
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppTheme.gutter,
                        4,
                        AppTheme.gutter,
                        10,
                      ),
                      child: Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 13),
                        decoration: GlassDecor.panel(t, radius: 20, raised: false),
                        child: Row(
                          children: [
                            Icon(Icons.search, size: 17, color: t.muted),
                            const SizedBox(width: 9),
                            Expanded(
                              child: TextField(
                                controller: _search,
                                onChanged: (v) =>
                                    setState(() => _query = v.trim()),
                                style: text.bodyMedium
                                    ?.copyWith(color: t.text, fontSize: 14.5),
                                decoration: InputDecoration(
                                  isDense: true,
                                  border: InputBorder.none,
                                  hintText: '搜笔记内容或题干',
                                  hintStyle:
                                      text.bodySmall?.copyWith(fontSize: 13.5),
                                ),
                              ),
                            ),
                            if (_query.isNotEmpty)
                              GestureDetector(
                                onTap: () {
                                  _search.clear();
                                  setState(() => _query = '');
                                },
                                child: Icon(Icons.close,
                                    size: 16, color: t.muted),
                              ),
                          ],
                        ),
                      ),
                    ),
                    FilterBar(
                      filters: [
                        FilterSpec(
                          key: 'category',
                          label: '题型',
                          value: _category,
                          icon: AppIcon.logic,
                          options: [
                            FilterOption('all', '全部题型', count: _items.length),
                            for (final c in kGongkaoCategories)
                              if (_items.any(
                                  (e) => e.question.category == c.key))
                                FilterOption(
                                  c.key,
                                  c.label,
                                  count: _items
                                      .where((e) =>
                                          e.question.category == c.key)
                                      .length,
                                ),
                          ],
                        ),
                      ],
                      onChanged: (_, value) =>
                          setState(() => _category = value),
                      onReset: () => setState(() {
                        _category = 'all';
                        _query = '';
                        _search.clear();
                      }),
                    ),
                    if (_shown.isEmpty)
                      const Expanded(
                        child: EmptyState(
                          icon: Icons.search_off,
                          title: '没有匹配的笔记',
                          art: EmptyArt.search,
                          message: '换个关键词，或把题型筛选清掉。',
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.only(top: 4, bottom: 28),
                          itemCount: _shown.length,
                          separatorBuilder: (_, __) => const RowDivider(),
                          itemBuilder: (context, i) => Reveal(
                            index: i,
                            child: _NoteRow(
                              item: _shown[i],
                              onTap: () => _open(_shown[i].question),
                              onDelete: () => _delete(_shown[i].question),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }
}

/// 一条笔记：题干两行 + 笔记正文，左滑删除。
class _NoteRow extends StatelessWidget {
  const _NoteRow({
    required this.item,
    required this.onTap,
    required this.onDelete,
  });

  final ({Question question, String body, DateTime at}) item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return Dismissible(
      key: ValueKey(item.question.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
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
        onTap: onTap,
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
                      markup: item.question.bodyMarkup,
                      icon: categoryIcon(item.question.category),
                      color: t.category(item.question.category),
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Text(
                      item.question.content,
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
                  item.body,
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
                    categoryIcon(item.question.category),
                    size: 13,
                    color: t.muted,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    categoryLabel(item.question.category),
                    style: text.bodySmall,
                  ),
                  Text(
                    ' · ${item.at.month}/${item.at.day}',
                    style: text.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
