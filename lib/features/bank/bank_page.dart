import 'package:flutter/material.dart';
import 'package:openexam_app/core/theme/app_theme.dart';
import 'package:openexam_app/core/theme/app_tokens.dart';
import 'package:openexam_app/core/constants/app_constants.dart';
import 'package:openexam_app/core/constants/categories.dart';
import 'package:openexam_app/core/ui/filter_bar.dart';
import 'package:openexam_app/core/ui/glass.dart';
import 'package:openexam_app/core/ui/stroke_icons.dart';
import 'package:openexam_app/core/ui/ui_kit.dart';
import 'package:openexam_app/data/db/app_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  bool _regionApplied = false;
  List<({String id, DateTime at})> _recent = const [];

  /// Region key: 'all', '国考' or a province name.
  String _region = 'all';

  /// Year as a string, or 'all'.
  String _year = 'all';

  /// 'all' | 'todo' | 'doing' | 'done'
  String _status = 'all';

  /// 'year' | 'progress' | 'size'
  String _sort = 'year';

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
    final recent = await AppDatabase.instance.recentPapers();
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _papers = rows.map(_Paper.fromRow).toList();
      _progress = progress;
      _recent = recent;
      // Default to the region the user is sitting for; they can widen it.
      if (_region == 'all' && !_regionApplied) {
        final mine = prefs.getString(Prefs.province);
        if (mine != null && _papers.any((p) => p.region == mine)) {
          _region = mine;
        }
        _regionApplied = true;
      }
      _loading = false;
    });
  }

  List<FilterOption> _regionOptions() {
    final counts = <String, int>{};
    for (final p in _papers) {
      counts[p.region] = (counts[p.region] ?? 0) + 1;
    }
    final keys = counts.keys.toList()
      ..sort((a, b) {
        if (a == '国考') return -1;
        if (b == '国考') return 1;
        return counts[b]!.compareTo(counts[a]!);
      });
    return [
      FilterOption('all', '全部地区', count: _papers.length),
      for (final k in keys) FilterOption(k, k, count: counts[k]),
    ];
  }

  List<FilterOption> _yearOptions() {
    final counts = <int, int>{};
    for (final p in _papers) {
      counts[p.year] = (counts[p.year] ?? 0) + 1;
    }
    final years = counts.keys.toList()..sort((a, b) => b.compareTo(a));
    return [
      FilterOption('all', '全部年份', count: _papers.length),
      for (final y in years)
        FilterOption('$y', y == 0 ? '未标注' : '$y 年', count: counts[y]),
    ];
  }

  List<FilterOption> _statusOptions() {
    var todo = 0;
    var doing = 0;
    var done = 0;
    for (final p in _papers) {
      final d = _progress[p.id] ?? 0;
      if (d == 0) {
        todo++;
      } else if (d < p.count) {
        doing++;
      } else {
        done++;
      }
    }
    return [
      FilterOption('all', '全部状态', count: _papers.length),
      FilterOption('todo', '未开始', count: todo),
      FilterOption('doing', '进行中', count: doing),
      FilterOption('done', '已做完', count: done),
    ];
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
      if (_region != 'all' && p.region != _region) return false;
      if (_year != 'all' && '${p.year}' != _year) return false;
      final done = _progress[p.id] ?? 0;
      switch (_status) {
        case 'todo':
          if (done != 0) return false;
        case 'doing':
          if (!(done > 0 && done < p.count)) return false;
        case 'done':
          if (!(p.count > 0 && done >= p.count)) return false;
      }
      return true;
    }).toList();

    // Sorting only matters once a filter has narrowed things down.
    if (_sort == 'progress') {
      matched.sort((a, b) {
        final pa = a.count == 0 ? 0.0 : (_progress[a.id] ?? 0) / a.count;
        final pb = b.count == 0 ? 0.0 : (_progress[b.id] ?? 0) / b.count;
        return pb.compareTo(pa);
      });
    } else if (_sort == 'size') {
      matched.sort((a, b) => b.count.compareTo(a.count));
    }

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
          // Whatever you were last working through comes first — that is almost
          // always what you came back for.
          if (_recent.isNotEmpty && _query.isEmpty) ...[
            const SizedBox(height: 14),
            const Padding(
              padding: EdgeInsets.fromLTRB(AppTheme.gutter, 0, AppTheme.gutter, 8),
              child: SectionHeader(title: '继续上次', caption: '最近做过的卷'),
            ),
            for (final r in _recent)
              if (_papers.any((p) => p.id == r.id))
                _PaperRow(
                  paper: _papers.firstWhere((p) => p.id == r.id),
                  done: _progress[r.id] ?? 0,
                  onTap: () =>
                      _openPaper(_papers.firstWhere((p) => p.id == r.id)),
                ),
            const SizedBox(height: 6),
            const RowDivider(indent: 0),
          ],
          const SizedBox(height: 12),
          FilterBar(
            filters: [
              FilterSpec(
                key: 'region',
                label: '地区',
                value: _region,
                icon: AppIcon.globe,
                options: _regionOptions(),
              ),
              FilterSpec(
                key: 'year',
                label: '年份',
                value: _year,
                icon: AppIcon.timer,
                options: _yearOptions(),
              ),
              FilterSpec(
                key: 'status',
                label: '状态',
                value: _status,
                icon: AppIcon.chart,
                options: _statusOptions(),
              ),
              FilterSpec(
                key: 'sort',
                label: '排序',
                value: _sort == 'year' ? 'all' : _sort,
                icon: AppIcon.papers,
                options: const [
                  FilterOption('all', '按年份（新→旧）'),
                  FilterOption('progress', '按完成度'),
                  FilterOption('size', '按题量'),
                ],
              ),
            ],
            onChanged: (key, value) => setState(() {
              switch (key) {
                case 'region':
                  _region = value;
                case 'year':
                  _year = value;
                case 'status':
                  _status = value;
                case 'sort':
                  _sort = value == 'all' ? 'year' : value;
              }
            }),
            onReset: () => setState(() {
              _region = 'all';
              _year = 'all';
              _status = 'all';
              _sort = 'year';
            }),
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
            // Flattened to (header | row) entries and built lazily: 137 papers
            // across 12 year groups is enough to feel the difference.
            ...[
              Builder(builder: (context) {
                final rows = <Widget>[];
                for (final year in sortedYears) {
                  rows.add(
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppTheme.gutter,
                        10,
                        AppTheme.gutter,
                        8,
                      ),
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
                  );
                  for (var i = 0; i < years[year]!.length; i++) {
                    if (i > 0) rows.add(const RowDivider());
                    final paper = years[year]![i];
                    rows.add(
                      _PaperRow(
                        paper: paper,
                        done: _progress[paper.id] ?? 0,
                        onTap: () => _openPaper(paper),
                      ),
                    );
                  }
                }
                return ListView.builder(
                  shrinkWrap: true,
                  primary: false,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: rows.length,
                  itemBuilder: (context, i) => rows[i],
                );
              }),
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

  /// 国考 or the province named in the title — the two things 考生 filter by.
  String get region {
    if (title.contains('国家公务员') || title.contains('国考')) return '国考';
    for (final p in kProvinces) {
      if (p != '国考' && title.contains(p)) return p;
    }
    return '其他';
  }

  /// Title without the leading year, which the group header already shows.
  String get shortTitle =>
      title.replaceFirst(RegExp(r'^\d{4}年\s*'), '').trim();
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
