import 'package:flutter/material.dart';
import 'package:openexam_app/l10n/app_localizations.dart';
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
  Map<String, String> _tags = const {};
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final items = await AppDatabase.instance.fetchMarked();
    final tags = await AppDatabase.instance.markTags();
    if (!mounted) return;
    setState(() {
      _items = items;
      _tags = tags;
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

  /// Tags keep a growing favourites list usable: 易错 / 公式 / 技巧 / 待复习.
  Future<void> _tag(Question q) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _TagSheet(current: _tags[q.id] ?? ''),
    );
    if (picked == null) return;
    await AppDatabase.instance.setMarkTag(q.id, picked);
    await _reload();
  }

  Future<void> _unmark(Question q) async {
    await AppDatabase.instance.toggleMark(q.id, false);
    await _reload();
  }

  int _countTag(String tag) =>
      _items.where((q) => (_tags[q.id] ?? '') == tag).length;

  List<Question> get _shown {
    if (_filter == 'all') return _items;
    final want = _filter == '_none' ? '' : _filter;
    return _items.where((q) => (_tags[q.id] ?? '') == want).toList();
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
        title: Text(AppL.of(context).marksTitle),
        actions: [
          if (_items.isNotEmpty)
            TextButton(
              onPressed: () => _practise(_items.take(20).toList()),
              child: Text(AppL.of(context).marksPractise),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? LoadingState()
          : _items.isEmpty
              ? EmptyState(
                  icon: Icons.star_border_rounded,
                  title: AppL.of(context).marksNone,
                  art: EmptyArt.star,
                  message: AppL.of(context).marksNoneHint,
                )
              : ListView(
                  padding: const EdgeInsets.only(top: 6, bottom: 28),
                  children: [
                    if (_items.isNotEmpty)
                      SizedBox(
                        height: 34,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: EdgeInsets.fromLTRB(
                            AppTheme.gutter,
                            0,
                            AppTheme.gutter,
                            0,
                          ),
                          children: [
                            _TagChip(
                              label: AppL.of(context).searchAllCount(_items.length),
                              selected: _filter == 'all',
                              onTap: () => setState(() => _filter = 'all'),
                            ),
                            for (final tag in kMarkTags)
                              if (_countTag(tag) > 0)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: _TagChip(
                                    label: '$tag ${_countTag(tag)}',
                                    selected: _filter == tag,
                                    onTap: () => setState(() => _filter = tag),
                                  ),
                                ),
                            if (_countTag('') > 0)
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: _TagChip(
                                  label: '未分类 ${_countTag('')}',
                                  selected: _filter == '_none',
                                  onTap: () => setState(() => _filter = '_none'),
                                ),
                              ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 8),
                    for (var i = 0; i < _shown.length; i++) ...[
                      if (i > 0) const RowDivider(),
                      Dismissible(
                        key: ValueKey(_shown[i].id),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) => _unmark(_shown[i]),
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: EdgeInsets.only(right: AppTheme.gutter),
                          color: t.dangerSoft,
                          child: Text(
                            AppL.of(context).marksUnsave,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: t.danger,
                            ),
                          ),
                        ),
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onLongPress: () => _tag(_shown[i]),
                          onTap: () => _practise([_shown[i]]),
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
                                    markup: _shown[i].bodyMarkup,
                                    icon: categoryIcon(_shown[i].category),
                                    color: t.category(_shown[i].category),
                                  ),
                                ),
                                const SizedBox(width: 13),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _shown[i].content,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: text.bodyLarge?.copyWith(
                                          fontSize: 15,
                                          height: 1.45,
                                        ),
                                      ),
                                      SizedBox(height: 7),
                                      Row(
                                        children: [
                                          Text(
                                            '${categoryLabel(_shown[i].category)}'
                                            '${_shown[i].hasImage ? AppL.of(context).searchHasFigure : ''}',
                                            style: text.bodySmall,
                                          ),
                                          const SizedBox(width: 8),
                                          GestureDetector(
                                            behavior: HitTestBehavior.opaque,
                                            onTap: () => _tag(_shown[i]),
                                            child: Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 3,
                                              ),
                                              decoration: BoxDecoration(
                                                color: (_tags[_shown[i].id] ?? '').isEmpty
                                                    ? t.surfaceAlt
                                                    : t.brand.withValues(alpha: 0.13),
                                                borderRadius: BorderRadius.circular(7),
                                              ),
                                              child: Text(
                                                (_tags[_shown[i].id] ?? '').isEmpty
                                                    ? AppL.of(context).marksAddTag
                                                    : _tags[_shown[i].id]!,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  height: 1,
                                                  color: (_tags[_shown[i].id] ?? '').isEmpty
                                                      ? t.muted
                                                      : t.brand,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
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

/// Filter chip for the tag row.
class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? t.brand : t.surfaceAlt,
          borderRadius: BorderRadius.circular(17),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            height: 1,
            color: selected ? Colors.white : t.textSoft,
          ),
        ),
      ),
    );
  }
}

/// Tag picker for a favourite.
class _TagSheet extends StatelessWidget {
  const _TagSheet({required this.current});

  final String current;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        color: t.gradient.last,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: t.lineSoft)),
      ),
      padding: EdgeInsets.fromLTRB(20, 18, 20, 16),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppL.of(context).marksTags, style: text.titleMedium),
            const SizedBox(height: 14),
            Wrap(
              spacing: 9,
              runSpacing: 9,
              children: [
                for (final tag in kMarkTags)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.of(context).pop(tag),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: current == tag
                            ? t.brand.withValues(alpha: 0.15)
                            : t.surfaceAlt,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: current == tag
                              ? t.brand.withValues(alpha: 0.5)
                              : Colors.transparent,
                        ),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1,
                          color: current == tag ? t.brand : t.textSoft,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(''),
                child: Text(AppL.of(context).marksClearTag),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
