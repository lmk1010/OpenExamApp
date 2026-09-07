import 'package:flutter/material.dart';
import 'package:openexam_app/l10n/app_localizations.dart';
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

  /// 不挂在题上的笔记。经验、公式、教训这些跟具体某道题无关的，
  /// 以前根本没地方写。
  List<Memo> _memos = const [];

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
    final results = await Future.wait([
      AppDatabase.instance.notedQuestions(),
      AppDatabase.instance.listMemos(),
    ]);
    if (!mounted) return;
    setState(() {
      _items = results[0] as List<({Question question, String body, DateTime at})>;
      _memos = results[1] as List<Memo>;
      _loading = false;
    });
  }

  List<Memo> get _shownMemos => _memos.where((m) {
        // 随手记没有题型，题型筛选一开就该把它们收起来
        if (_category != 'all') return false;
        if (_query.isEmpty) return true;
        return m.body.contains(_query) || m.title.contains(_query);
      }).toList();

  Future<void> _editMemo([Memo? memo]) async {
    final result = await showModalBottomSheet<Memo>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _MemoSheet(memo: memo ?? Memo.blank()),
    );
    if (result == null) return;
    if (result.body.trim().isEmpty && result.title.trim().isEmpty) {
      // 什么都没写就当没建，别在列表里留一条空的
      if (memo != null) await AppDatabase.instance.deleteMemo(memo.id);
    } else {
      await AppDatabase.instance.saveMemo(result);
    }
    await _load();
  }

  Future<void> _deleteMemo(Memo memo) async {
    await AppDatabase.instance.deleteMemo(memo.id);
    await _load();
  }

  Future<void> _open(Question q) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PracticeSessionPage(
          questions: [q],
          reviewAnswers: {q.id: q.answer.toUpperCase()},
          title: AppL.of(context).notesReview,
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
          icon: Icon(Icons.arrow_back, size: 21),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        titleSpacing: 0,
        title: Text(AppL.of(context).notesTitle),
        actions: [
          IconButton(
            tooltip: AppL.of(context).notesWriteOne,
            icon: Icon(Icons.add, size: 22),
            onPressed: () => _editMemo(),
          ),
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
                    title: AppL.of(context).notesReview,
                  ),
                ),
              ),
              child: Text(AppL.of(context).notesReviewAll),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? LoadingState()
          : (_items.isEmpty && _memos.isEmpty)
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      EmptyState(
                        icon: Icons.sticky_note_2_outlined,
                        title: AppL.of(context).notesNone,
                        art: EmptyArt.note,
                        message: AppL.of(context).notesNoneHint,
                      ),
                      const SizedBox(height: 8),
                      FilledButton(
                        onPressed: () => _editMemo(),
                        child: Text(AppL.of(context).notesWriteOne),
                      ),
                    ],
                  ),
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
                            SizedBox(width: 9),
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
                                  hintText: AppL.of(context).notesSearchHint,
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
                          label: AppL.of(context).wrongFilterType,
                          value: _category,
                          icon: AppIcon.logic,
                          options: [
                            FilterOption('all', AppL.of(context).wrongAllTypes, count: _items.length),
                            for (final c in CategoryRegistry.current)
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
                    if (_shown.isEmpty && _shownMemos.isEmpty)
                      Expanded(
                        child: EmptyState(
                          icon: Icons.search_off,
                          title: AppL.of(context).notesNoMatch,
                          art: EmptyArt.search,
                          message: AppL.of(context).notesNoMatchHint,
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.only(top: 4, bottom: 28),
                          itemCount: _shownMemos.length + _shown.length,
                          separatorBuilder: (_, __) => const RowDivider(),
                          itemBuilder: (context, i) {
                            if (i < _shownMemos.length) {
                              final m = _shownMemos[i];
                              return Reveal(
                                index: i,
                                child: _MemoRow(
                                  memo: m,
                                  onTap: () => _editMemo(m),
                                  onDelete: () => _deleteMemo(m),
                                ),
                              );
                            }
                            final item = _shown[i - _shownMemos.length];
                            return Reveal(
                              index: i,
                              child: _NoteRow(
                                item: item,
                                onTap: () => _open(item.question),
                                onDelete: () => _delete(item.question),
                              ),
                            );
                          },
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
        padding: EdgeInsets.only(right: AppTheme.gutter),
        color: t.dangerSoft,
        child: Text(
          AppL.of(context).notesDelete,
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

/// 一条随手记：标题 + 正文，左滑删除。
///
/// 跟题笔记摆在同一个列表里，但左边多一个便签图标 —— 不然分不清哪条能点开
/// 看题、哪条点开是编辑。
class _MemoRow extends StatelessWidget {
  const _MemoRow({
    required this.memo,
    required this.onTap,
    required this.onDelete,
  });

  final Memo memo;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  /// 带 context：相对日期的说法跟着界面语言走。
  String _when(BuildContext context) {
    final now = DateTime.now();
    final days = DateTime(now.year, now.month, now.day)
        .difference(DateTime(memo.at.year, memo.at.month, memo.at.day))
        .inDays;
    return switch (days) {
      0 => AppL.of(context).whenToday,
      1 => AppL.of(context).whenYesterday,
      < 7 => AppL.of(context).whenDaysAgo(days),
      _ => '${memo.at.month}/${memo.at.day}',
    };
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return Dismissible(
      key: ValueKey(memo.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: AppTheme.gutter),
        color: t.dangerSoft,
        child: Text(
          AppL.of(context).commonDelete,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: t.danger,
          ),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.gutter, vertical: 13),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: t.accentSoft,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(Icons.edit_note_rounded,
                    size: 19, color: t.onAccentSoft),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            memo.displayTitle.isEmpty
                                ? AppL.of(context).memoUntitled
                                : memo.displayTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.titleSmall?.copyWith(fontSize: 14.5),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(_when(context),
                            style:
                                text.bodySmall?.copyWith(color: t.textSoft)),
                      ],
                    ),
                    if (memo.body.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        memo.body.trim(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodySmall?.copyWith(
                          color: t.textSoft,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 写一条随手记。
class _MemoSheet extends StatefulWidget {
  const _MemoSheet({required this.memo});

  final Memo memo;

  @override
  State<_MemoSheet> createState() => _MemoSheetState();
}

class _MemoSheetState extends State<_MemoSheet> {
  late final _title = TextEditingController(text: widget.memo.title);
  late final _body = TextEditingController(text: widget.memo.body);

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: t.gradient.last,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: t.lineSoft)),
        ),
        padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(AppL.of(context).notesQuick, style: text.titleMedium)),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(
                      widget.memo.copyWith(
                        title: _title.text,
                        body: _body.text,
                      ),
                    ),
                    child: Text(AppL.of(context).commonSave,
                        style: text.labelMedium?.copyWith(color: t.brand)),
                  ),
                ],
              ),
              SizedBox(height: 6),
              TextField(
                controller: _title,
                decoration: InputDecoration(
                  labelText: AppL.of(context).notesTitleField,
                  hintText: AppL.of(context).notesTitleHint,
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: _body,
                autofocus: true,
                maxLines: 8,
                minLines: 5,
                decoration: InputDecoration(
                  labelText: AppL.of(context).notesBody,
                  hintText: AppL.of(context).notesBodyHint,
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
