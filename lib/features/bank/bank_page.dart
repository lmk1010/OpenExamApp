import 'package:flutter/material.dart';
import 'package:openexam_app/core/theme/app_theme.dart';
import 'package:openexam_app/core/theme/app_tokens.dart';
import 'package:openexam_app/core/ui/glass.dart';
import 'package:openexam_app/core/ui/stroke_icons.dart';
import 'package:openexam_app/core/ui/ui_kit.dart';
import 'package:openexam_app/data/db/app_database.dart';
import 'package:openexam_app/features/bank/paper_page.dart';

/// 题库 — 137 real papers. Searchable, grouped by year, each row showing how
/// far through that paper you are.
class BankPage extends StatefulWidget {
  const BankPage({super.key});

  @override
  State<BankPage> createState() => _BankPageState();
}

class _BankPageState extends State<BankPage> {
  final _search = TextEditingController();

  bool _loading = true;
  List<_Paper> _papers = const [];
  Map<String, int> _progress = const {};
  String _query = '';

  /// 'all' | 'national' | 'provincial'
  String _kind = 'all';

  /// 'all' | 'todo' | 'doing' | 'done'
  String _status = 'all';

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    if (!_loading) setState(() => _loading = true);
    final rows = await AppDatabase.instance.listPapers(limit: 400);
    final progress = await AppDatabase.instance.paperProgress();
    if (!mounted) return;
    setState(() {
      _papers = rows.map(_Paper.fromRow).toList();
      _progress = progress;
      _loading = false;
    });
  }

  Future<void> _openPaper(_Paper paper) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PaperPage(
          paperId: paper.id,
          title: paper.shortTitle,
          year: paper.year,
          total: paper.count,
        ),
      ),
    );
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingState();

    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    final matched = _papers.where((p) {
      if (_query.isNotEmpty &&
          !p.title.contains(_query) &&
          !'${p.year}'.contains(_query)) {
        return false;
      }
      if (_kind != 'all' && p.kind != _kind) return false;
      final done = _progress[p.id] ?? 0;
      switch (_status) {
        case 'todo':
          return done == 0;
        case 'doing':
          return done > 0 && done < p.count;
        case 'done':
          return p.count > 0 && done >= p.count;
      }
      return true;
    }).toList();

    // Group by exam year, newest first — how 考生 actually look for a paper.
    final years = <int, List<_Paper>>{};
    for (final paper in matched) {
      years.putIfAbsent(paper.year, () => []).add(paper);
    }
    final sortedYears = years.keys.toList()..sort((a, b) => b.compareTo(a));

    return RefreshIndicator(
      color: t.brand,
      backgroundColor: t.surface,
      onRefresh: _reload,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 30),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppTheme.gutter, 18, AppTheme.gutter, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('题库', style: text.displaySmall?.copyWith(fontSize: 26)),
                const SizedBox(width: 10),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    matched.length == _papers.length
                        ? '${_papers.length} 套真题卷'
                        : '${matched.length} / ${_papers.length} 套',
                    style: text.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.gutter),
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: GlassDecor.panel(t, radius: 21, raised: false),
              child: Row(
                children: [
                  Icon(Icons.search, size: 18, color: t.muted),
                  const SizedBox(width: 9),
                  Expanded(
                    child: TextField(
                      controller: _search,
                      onChanged: (v) => setState(() => _query = v.trim()),
                      textInputAction: TextInputAction.search,
                      style: text.bodyMedium?.copyWith(color: t.text, fontSize: 15),
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText: '搜索年份、省份、卷名',
                        hintStyle: text.bodySmall?.copyWith(fontSize: 14),
                      ),
                    ),
                  ),
                  if (_query.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _search.clear();
                        setState(() => _query = '');
                      },
                      child: Icon(Icons.close, size: 17, color: t.muted),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.gutter),
              children: [
                _Chip(
                  label: '全部卷',
                  selected: _kind == 'all' && _status == 'all',
                  onTap: () => setState(() {
                    _kind = 'all';
                    _status = 'all';
                  }),
                ),
                const SizedBox(width: 8),
                _Chip(
                  label: '国考',
                  selected: _kind == 'national',
                  onTap: () => setState(
                    () => _kind = _kind == 'national' ? 'all' : 'national',
                  ),
                ),
                const SizedBox(width: 8),
                _Chip(
                  label: '省考',
                  selected: _kind == 'provincial',
                  onTap: () => setState(
                    () => _kind = _kind == 'provincial' ? 'all' : 'provincial',
                  ),
                ),
                const SizedBox(width: 8),
                _Chip(
                  label: '未开始',
                  selected: _status == 'todo',
                  onTap: () => setState(
                    () => _status = _status == 'todo' ? 'all' : 'todo',
                  ),
                ),
                const SizedBox(width: 8),
                _Chip(
                  label: '进行中',
                  selected: _status == 'doing',
                  onTap: () => setState(
                    () => _status = _status == 'doing' ? 'all' : 'doing',
                  ),
                ),
                const SizedBox(width: 8),
                _Chip(
                  label: '已做完',
                  selected: _status == 'done',
                  onTap: () => setState(
                    () => _status = _status == 'done' ? 'all' : 'done',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (matched.isEmpty)
            EmptyState(
              icon: Icons.search_off,
              title: _query.isEmpty ? '还没有试卷' : '没有匹配的试卷',
              message: _query.isEmpty
                  ? '到「我的 → 导入题目」导入后，整套试卷会出现在这里。'
                  : '换个关键词试试，比如 2025、江苏、国考。',
            )
          else
            for (final year in sortedYears) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(AppTheme.gutter, 10, AppTheme.gutter, 8),
                child: Row(
                  children: [
                    Text(
                      year == 0 ? '未标注年份' : '$year 年',
                      style: text.titleMedium?.copyWith(fontSize: 16),
                    ),
                    const SizedBox(width: 8),
                    Text('${years[year]!.length} 套', style: text.bodySmall),
                  ],
                ),
              ),
              for (var i = 0; i < years[year]!.length; i++) ...[
                if (i > 0) const RowDivider(),
                _PaperRow(
                  paper: years[year]![i],
                  done: _progress[years[year]![i].id] ?? 0,
                  onTap: () => _openPaper(years[year]![i]),
                ),
              ],
            ],
        ],
      ),
    );
  }
}

class _Paper {
  const _Paper({
    required this.id,
    required this.title,
    required this.year,
    required this.count,
    required this.imported,
  });

  final String id;
  final String title;
  final int year;
  final int count;
  final bool imported;

  factory _Paper.fromRow(Map<String, Object?> row) => _Paper(
        id: '${row['paper_id']}',
        title: '${row['paper_title'] ?? '未命名试卷'}',
        year: int.tryParse('${row['year'] ?? 0}') ?? 0,
        count: int.tryParse('${row['question_count'] ?? 0}') ?? 0,
        imported: '${row['source'] ?? ''}' == 'imported',
      );

  /// Papers are titled 「2025年江苏省考《行测》」 — pull the region out for the meta line.
  String get region {
    final match = RegExp(r'^\d{4}年([^《（(]{2,10})').firstMatch(title);
    return match?.group(1)?.trim() ?? '';
  }

  /// 国考 vs 省考 — the split every 考生 filters by first.
  String get kind {
    if (title.contains('国家公务员') || title.contains('国考')) return 'national';
    if (title.contains('省考') ||
        title.contains('省公务员') ||
        title.contains('选调') ||
        title.contains('公务员录用考试')) {
      return 'provincial';
    }
    return 'other';
  }

  /// Title without the leading year, which the group header already shows.
  String get shortTitle =>
      title.replaceFirst(RegExp(r'^\d{4}年\s*'), '').trim();
}

/// Filter chip for the 题库 toolbar.
class _Chip extends StatelessWidget {
  const _Chip({
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
          color: selected ? t.brand : t.glass,
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

class _PaperRow extends StatelessWidget {
  const _PaperRow({required this.paper, required this.done, required this.onTap});

  final _Paper paper;
  final int done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final ratio = paper.count == 0 ? 0.0 : (done / paper.count).clamp(0.0, 1.0);
    final started = done > 0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.gutter, vertical: 14),
        child: Row(
          children: [
            StrokeIcon(
              AppIcon.papers,
              size: 21,
              color: started ? t.brand : t.muted,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    paper.shortTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleSmall?.copyWith(fontSize: 15),
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      SizedBox(
                        width: 62,
                        child: Meter(value: ratio, height: 3),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        started ? '$done / ${paper.count}' : '${paper.count} 题',
                        style: text.bodySmall,
                      ),
                      if (paper.imported) ...[
                        const SizedBox(width: 8),
                        Text('导入', style: text.bodySmall?.copyWith(color: t.brand)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(Icons.chevron_right, size: 17, color: t.muted),
          ],
        ),
      ),
    );
  }
}
