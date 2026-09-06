import 'package:flutter/material.dart';
import 'package:openexam_app/core/theme/app_theme.dart';
import 'package:openexam_app/core/theme/app_tokens.dart';
import 'package:openexam_app/features/practice/shore_home.dart';
import 'package:openexam_app/core/ui/responsive.dart';
import 'package:openexam_app/core/constants/app_constants.dart';
import 'package:openexam_app/core/constants/categories.dart';
import 'package:openexam_app/core/ui/filter_bar.dart';
import 'package:openexam_app/core/ui/glass.dart';
import 'package:openexam_app/core/ui/stroke_icons.dart';
import 'package:openexam_app/core/ui/ui_kit.dart';
import 'package:openexam_app/data/db/app_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:openexam_app/features/bank/paper_page.dart';
import 'package:openexam_app/features/reports/reports_page.dart';

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

  /// 宽屏分栏时选中的卷；窄屏为空，照旧 push 新页。
  _Paper? _selected;

  Future<void> _openPaper(_Paper paper) async {
    if (context.isExpanded) {
      setState(() => _selected = paper);
      return;
    }
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

    // Flat (year header | paper | divider) entries so the list can virtualize.
    final entries = <_BankEntry>[];
    for (final year in sortedYears) {
      final group = years[year]!;
      entries.add(_BankEntry.year(year, group.length));
      for (var i = 0; i < group.length; i++) {
        if (i > 0) entries.add(const _BankEntry.divider());
        entries.add(_BankEntry.paper(group[i]));
      }
    }

    final list = RefreshIndicator(
      color: t.brand,
      backgroundColor: t.surface,
      onRefresh: _reload,
      child: ReadableWidth(
        maxWidth: context.isExpanded ? double.infinity : null,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverList(
              delegate: SliverChildListDelegate([
                  const SizedBox(height: ShoreGap.top),
                  ShoreHeader(
                    kicker: matched.length == _papers.length
                        ? '${_papers.length} 套真题卷'
                        : '${matched.length} / ${_papers.length} 套',
                    title: '题库',
                    actions: [
                      ShoreRoundButton(
                        icon: StrokeIcon(
                          AppIcon.chart,
                          size: 19,
                          color: t.textSoft,
                        ),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ReportsPage()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: ShoreGap.titleToBody),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppTheme.gutter),
                    child: Container(
                      height: 42,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration:
                          GlassDecor.panel(t, radius: 21, raised: false),
                      child: Row(
                        children: [
                          Icon(Icons.search, size: 18, color: t.muted),
                          const SizedBox(width: 9),
                          Expanded(
                            child: TextField(
                              controller: _search,
                              onChanged: (v) =>
                                  setState(() => _query = v.trim()),
                              textInputAction: TextInputAction.search,
                              style: text.bodyMedium
                                  ?.copyWith(color: t.text, fontSize: 15),
                              decoration: InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                                hintText: '搜索年份、省份、卷名',
                                hintStyle:
                                    text.bodySmall?.copyWith(fontSize: 14),
                              ),
                            ),
                          ),
                          if (_query.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _search.clear();
                                setState(() => _query = '');
                              },
                              child:
                                  Icon(Icons.close, size: 17, color: t.muted),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (_recent.isNotEmpty && _query.isEmpty) ...[
                    const SizedBox(height: 14),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(
                        AppTheme.gutter,
                        0,
                        AppTheme.gutter,
                        8,
                      ),
                      child: SectionHeader(
                        title: '继续上次',
                        caption: '最近做过的卷',
                      ),
                    ),
                    for (final r in _recent)
                      if (_papers.any((p) => p.id == r.id))
                        _PaperRow(
                          paper: _papers.firstWhere((p) => p.id == r.id),
                          done: _progress[r.id] ?? 0,
                          onTap: () => _openPaper(
                            _papers.firstWhere((p) => p.id == r.id),
                          ),
                        ),
                    const SizedBox(height: 6),
                    const RowDivider(indent: 0),
                  ],
                  const SizedBox(height: 12),
                  FilterBar(
                    filters: [
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
                  const SizedBox(height: 12),
                  _RegionStrip(
                    options: _regionOptions(),
                    value: _region,
                    onPick: (v) => setState(() => _region = v),
                  ),
                  const SizedBox(height: 14),
                  if (matched.isEmpty)
                    EmptyState(
                      icon: Icons.search_off,
                      title: _query.isEmpty ? '还没有试卷' : '没有匹配的试卷',
                      art: _query.isEmpty ? EmptyArt.bank : EmptyArt.search,
                      message: _query.isEmpty
                          ? '到「我的 → 导入题目」导入后，整套试卷会出现在这里。'
                          : '换个关键词试试，比如 2025、江苏、国考。',
                    ),
                ]),
            ),
            if (matched.isNotEmpty)
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final e = entries[i];
                    switch (e.kind) {
                      case _BankKind.year:
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppTheme.gutter,
                            10,
                            AppTheme.gutter,
                            8,
                          ),
                          child: Row(
                            children: [
                              Text(
                                e.year == 0 ? '未标注年份' : '${e.year} 年',
                                style:
                                    text.titleMedium?.copyWith(fontSize: 16),
                              ),
                              const SizedBox(width: 8),
                              Text('${e.count} 套', style: text.bodySmall),
                            ],
                          ),
                        );
                      case _BankKind.divider:
                        // 现在每张卷本身就是一块卡片，行间线是多余的
                        return const SizedBox.shrink();
                      case _BankKind.paper:
                        final paper = e.paper!;
                        return _PaperRow(
                          paper: paper,
                          done: _progress[paper.id] ?? 0,
                          onTap: () => _openPaper(paper),
                        );
                    }
                  },
                  childCount: entries.length,
                ),
              ),
            // Bottom inset for the gesture nav / rail — kept as its own sliver
            // so the virtualized paper list above is not rebuild-padded.
            SliverToBoxAdapter(
              child: SizedBox(
                height: MediaQuery.paddingOf(context).bottom +
                    (context.isWide ? 30 : 152),
              ),
            ),
          ],
        ),
      ),
    );

    // 平板横屏：左边卷列表，右边直接是选中那张卷的详情。列表本来就是用来
    // 挑卷的，挑完还要跳走再跳回来，在这么宽的屏幕上没道理。
    if (!context.isExpanded) return list;
    final picked = _selected ??
        (_papers.isNotEmpty ? _papers.first : null);
    return Row(
      children: [
        Expanded(child: list),
        Container(width: 1, color: context.tokens.line.withValues(alpha: 0.5)),
        Expanded(
          child: picked == null
              ? const EmptyState(
                  icon: Icons.description_outlined,
                  title: '选一张卷',
                  art: EmptyArt.paper,
                  message: '左边挑一张。',
                )
              : PaperPage(
                  key: ValueKey(picked.id),
                  paperId: picked.id,
                  title: picked.shortTitle,
                  year: picked.year,
                  total: picked.count,
                  embedded: true,
                ),
        ),
      ],
    );
  }
}

enum _BankKind { year, paper, divider }

class _BankEntry {
  const _BankEntry._(this.kind, {this.year = 0, this.count = 0, this.paper});

  const _BankEntry.year(int year, int count)
      : this._(_BankKind.year, year: year, count: count);

  const _BankEntry.paper(_Paper paper)
      : this._(_BankKind.paper, paper: paper);

  const _BankEntry.divider() : this._(_BankKind.divider);

  final _BankKind kind;
  final int year;
  final int count;
  final _Paper? paper;
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

  /// 国考 / 省份 / 联考 —— 考生真正用来筛卷的那一层。
  ///
  /// 光认省份不够：库里 37 套「全国联考」全落进"其他"，一整屏同一个标签
  /// 等于没有标签。
  String get region {
    if (title.contains('国家公务员') || title.contains('国考')) return '国考';
    for (final p in kProvinces) {
      if (p != '国考' && title.contains(p)) return p;
    }
    if (title.contains('联考')) return '联考';
    if (title.contains('事业单位') || title.contains('事业编')) return '事业';
    if (title.contains('选调')) return '选调';
    return '其他';
  }

  /// 这张卷属于哪一类考试 —— 决定列表里显示哪个图标。
  String get typeArt {
    if (region == '国考') return 'assets/shore/ico_exam_nat.png';
    if (region == '联考') return 'assets/shore/ico_exam_joint.png';
    if (region == '事业') return 'assets/shore/ico_exam_inst.png';
    if (region == '其他' || region == '选调') {
      return 'assets/shore/ico_exam_other.png';
    }
    return 'assets/shore/ico_exam_prov.png';
  }

  /// Title without the leading year, which the group header already shows.
  String get shortTitle =>
      title.replaceFirst(RegExp(r'^\d{4}年\s*'), '').trim();
}

/// 地区快捷条：把最常用的那一层筛选摊在页面上，不用点开下拉。
class _RegionStrip extends StatelessWidget {
  const _RegionStrip({
    required this.options,
    required this.value,
    required this.onPick,
  });

  final List<FilterOption> options;
  final String value;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        // 右边留一段，最后一个 chip 不会被屏幕边缘齐刷刷切断
        padding: const EdgeInsets.only(right: 24),
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 7),
        itemBuilder: (_, i) {
          final o = options[i];
          final on = o.value == value;
          return GestureDetector(
            onTap: () => onPick(o.value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              padding: const EdgeInsets.symmetric(horizontal: 13),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: on
                    ? t.brand
                    : (t.name == 'dark'
                        ? Colors.white.withValues(alpha: 0.06)
                        : t.text.withValues(alpha: 0.05)),
                borderRadius: BorderRadius.circular(999),
              ),
              // 地区名 13px、计数 11px，行高倍数也不同（1.55 / 1.45）。
              // 居中对齐只对齐了两个行框，基线还差着 ~0.8px，数字看着往下掉。
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    o.label == '全部地区' ? '全部' : o.label,
                    style: text.bodyMedium?.copyWith(
                      fontSize: 13,
                      color: on ? Colors.white : t.textSoft,
                      fontWeight: on ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  if (o.count != null) ...[
                    const SizedBox(width: 5),
                    Text(
                      '${o.count}',
                      style: text.bodySmall?.copyWith(
                        fontSize: 11,
                        color: on
                            ? Colors.white.withValues(alpha: 0.8)
                            : t.muted,
                        fontFeatures: AppTheme.numeric,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PaperRow extends StatelessWidget {
  const _PaperRow({required this.paper, required this.done, required this.onTap});

  final _Paper paper;
  final int done;
  final VoidCallback onTap;

  /// 按考试类型给色，不按地区名哈希 —— 哈希出来的颜色没有含义，
  /// 而"国考一个色、联考一个色"扫一眼就能分堆。
  Color _regionColor(AppTokens t) {
    return switch (paper.region) {
      '国考' => t.category('ziliao'),
      '联考' => t.category('ziliao'),
      '事业' => t.category('panduan'),
      '选调' => t.category('shuliang'),
      '其他' => t.muted,
      _ => t.category('yanyu'),
    };
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final ratio = paper.count == 0 ? 0.0 : (done / paper.count).clamp(0.0, 1.0);
    final started = done > 0;
    final color = _regionColor(t);
    final dark = t.name == 'dark';

    // 卷名前面那串日期和"全国联考"是每张卷都有的，留着只会让每一行长得一样
    final title = paper.shortTitle
        .replaceFirst(RegExp(r'^\d{4}[.\-/]\d{1,2}[.\-/]\d{1,2}\s*'), '')
        .trim();

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppTheme.gutter, 0, AppTheme.gutter, 9),
      child: PressableCard(
        scale: 0.985,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: dark
                    ? Colors.black.withValues(alpha: 0.30)
                    : const Color(0xFF1B2540).withValues(alpha: 0.05),
                blurRadius: dark ? 20 : 18,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Row(
            children: [
              // 试卷类型图标：一眼分清国考 / 省考 / 联考 / 事业单位
              // 图标直接放，不再套一层圆角色块 —— 卡片已经是容器了
              Image.asset(
                paper.typeArt,
                width: 42,
                height: 42,
                filterQuality: FilterQuality.high,
                errorBuilder: (_, __, ___) => SizedBox(
                  width: 42,
                  height: 42,
                  child: Center(
                    child: Text(
                      paper.region.characters.first,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.isEmpty ? paper.shortTitle : title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleSmall?.copyWith(
                        fontSize: 14.5,
                        height: 1.3,
                        color: t.text,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: dark ? 0.22 : 0.14),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            paper.region,
                            style: TextStyle(
                              fontSize: 10.5,
                              height: 1.5,
                              fontWeight: FontWeight.w600,
                              color: color,
                            ),
                          ),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          started ? '$done / ${paper.count} 题' : '${paper.count} 题',
                          style: text.bodySmall?.copyWith(
                            fontSize: 11.5,
                            color: started ? t.brand : t.muted,
                            fontFeatures: AppTheme.numeric,
                          ),
                        ),
                        if (paper.imported) ...[
                          const SizedBox(width: 8),
                          Text('导入',
                              style: text.bodySmall
                                  ?.copyWith(fontSize: 11.5, color: t.brand)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // 做过才显示进度环，没做过就别摆一个空圈占地方
              if (started)
                SizedBox(
                  width: 30,
                  height: 30,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: ratio,
                        strokeWidth: 3,
                        strokeCap: StrokeCap.round,
                        backgroundColor: t.text.withValues(alpha: 0.10),
                        valueColor: AlwaysStoppedAnimation(color),
                      ),
                      Text(
                        '${(ratio * 100).round()}',
                        style: TextStyle(
                          fontSize: 9.5,
                          height: 1,
                          fontWeight: FontWeight.w700,
                          color: t.textSoft,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Icon(Icons.chevron_right, size: 17, color: t.muted),
            ],
          ),
        ),
      ),
    );
  }
}
