import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:openexam_app/l10n/app_localizations.dart';
import 'package:openexam_app/data/models/question.dart';
import 'package:openexam_app/features/bank/bank_export.dart';
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
import 'package:openexam_app/features/shell/tab_reload.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:openexam_app/features/bank/paper_page.dart';
import 'package:openexam_app/features/bank/recent_papers_page.dart';

/// 题库 — 137 real papers. Searchable, grouped by year, each row showing how
/// far through that paper you are.
class BankPage extends StatefulWidget {
  const BankPage({super.key});

  @override
  State<BankPage> createState() => _BankPageState();
}

class _BankPageState extends State<BankPage> with TabReload {
  bool _exporting = false;
  @override
  AppTab get tab => AppTab.bank;

  /// 切回这一栏就重读一遍 —— IndexedStack 会把页面一直留着，
  /// 不重读的话显示的还是进 app 那一刻的数字。
  @override
  Future<void> onTabShown() => _reload();

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

  /// 导出题库成一个 zip，格式跟导入吃的完全一样 —— 导出的文件一定能导回来。
  ///
  /// 范围让用户选：整库通常几万道题、几百兆，多数人想发的只是某一卷。
  Future<void> _exportBank() async {
    final l = AppL.of(context);
    final scope = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ExportScopeSheet(papers: _papers),
    );
    if (scope == null || !mounted) return;

    setState(() => _exporting = true);
    try {
      final List<Question> questions;
      final String label;
      String? paperId;
      String? paperTitle;
      int? year;
      // 文件名在 await 之后才拼，先把兜底文案取出来。
      final bankLabel = AppL.of(context).bankTab;
      final paperLabel = AppL.of(context).bankPapers;
      if (scope == '_all') {
        questions = await AppDatabase.instance.fetchAllQuestions();
        label = bankLabel;
      } else {
        questions = await AppDatabase.instance.fetchByPaper(scope);
        final paper = _papers.where((p) => p.id == scope).firstOrNull;
        label = paper?.title.isNotEmpty == true ? paper!.title : paperLabel;
        paperId = scope;
        paperTitle = paper?.title;
        year = paper?.year;
      }
      if (questions.isEmpty) {
        _toast(l.bankExportEmpty);
        return;
      }
      final bytes = await BankExporter.buildArchive(
        questions,
        paperId: paperId,
        paperTitle: paperTitle,
        year: year,
      );
      final name = BankExporter.fileName(label, questions.length);
      final path = await FilePicker.platform.saveFile(
        fileName: name,
        bytes: bytes,
      );
      if (!mounted) return;
      _toast(path == null
          ? l.bankExportCancelled
          : l.bankExportDone(questions.length, name));
    } catch (e) {
      _toast(l.bankExportFailed('$e'));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
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
      FilterOption('all', AppL.of(context).bankAllRegions, count: _papers.length),
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
      FilterOption('all', AppL.of(context).bankAllYears, count: _papers.length),
      for (final y in years)
        FilterOption('$y', y == 0 ? AppL.of(context).bankNoYear : AppL.of(context).bankYear('$y'), count: counts[y]),
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
      FilterOption('all', AppL.of(context).bankAllStatus, count: _papers.length),
      FilterOption('todo', AppL.of(context).bankNotStarted, count: todo),
      FilterOption('doing', AppL.of(context).bankInProgress, count: doing),
      FilterOption('done', AppL.of(context).bankFinished, count: done),
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
          physics: AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverList(
              delegate: SliverChildListDelegate([
                  SizedBox(height: ShoreGap.top),
                  ShoreHeader(
                    kicker: matched.length == _papers.length
                        ? AppL.of(context).bankPaperCount(_papers.length)
                        : AppL.of(context).bankMatchedCount(matched.length, _papers.length),
                    title: '题库',
                    actions: [
                      // 导出：题库以前只进不出 —— 扫描试卷、文档导入辛苦攒出来
                      // 的一套题换台手机就没了，更别说发给别人。
                      ShoreRoundButton(
                        icon: StrokeIcon(
                          AppIcon.download,
                          size: 19,
                          color: t.textSoft,
                        ),
                        onTap: _exporting ? null : _exportBank,
                      ),
                      // 「继续上次」原来平铺在搜索框下面，一进题库先看见一段
                      // 最近记录，真正想找卷子的人得往下翻过去。收进这里。
                      ShoreRoundButton(
                        icon: StrokeIcon(
                          AppIcon.replay,
                          size: 19,
                          color: t.textSoft,
                        ),
                        onTap: () async {
                          final papers = {for (final p in _papers) p.id: p};
                          final picked = await Navigator.of(context).push<String>(
                            MaterialPageRoute(
                              builder: (_) => RecentPapersPage(
                                recent: [
                                  for (final r in _recent)
                                    if (papers[r.id] != null)
                                      (
                                        id: r.id,
                                        title: papers[r.id]!.title.isEmpty
                                            ? AppL.of(context).bankUntitledPaper
                                            : papers[r.id]!.title,
                                        total: papers[r.id]!.count,
                                        done: _progress[r.id] ?? 0,
                                        at: r.at,
                                      ),
                                ],
                              ),
                            ),
                          );
                          if (!mounted) return;
                          // 在历史页点了某张卷：回到题库再把它打开，
                          // 免得历史页自己也要抱一份打开卷子的逻辑
                          final target = picked == null ? null : papers[picked];
                          if (target != null) await _openPaper(target);
                          if (!mounted) return;
                          // 做完题回来，进度要跟着变
                          await _reload();
                        },
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
                          SizedBox(width: 9),
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
                                hintText: AppL.of(context).bankSearchHint,
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
                  SizedBox(height: 12),
                  FilterBar(
                    filters: [
                      FilterSpec(
                        key: 'year',
                        label: AppL.of(context).bankFilterYear,
                        value: _year,
                        icon: AppIcon.timer,
                        options: _yearOptions(),
                      ),
                      FilterSpec(
                        key: 'status',
                        label: AppL.of(context).bankFilterStatus,
                        value: _status,
                        icon: AppIcon.chart,
                        options: _statusOptions(),
                      ),
                      FilterSpec(
                        key: 'sort',
                        label: AppL.of(context).bankSort,
                        value: _sort == 'year' ? 'all' : _sort,
                        icon: AppIcon.papers,
                        options: [
                          FilterOption('all', AppL.of(context).bankSortYear),
                          FilterOption('progress', AppL.of(context).bankSortProgress),
                          FilterOption('size', AppL.of(context).bankSortSize),
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
                  SizedBox(height: 12),
                  _RegionStrip(
                    options: _regionOptions(),
                    value: _region,
                    onPick: (v) => setState(() => _region = v),
                  ),
                  SizedBox(height: 14),
                  if (matched.isEmpty)
                    EmptyState(
                      icon: Icons.search_off,
                      title: _query.isEmpty ? AppL.of(context).bankNoPapers : AppL.of(context).bankNoMatch,
                      art: _query.isEmpty ? EmptyArt.bank : EmptyArt.search,
                      message: _query.isEmpty
                          ? AppL.of(context).bankNoPapersHint
                          : AppL.of(context).bankNoMatchHint,
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
                          padding: EdgeInsets.fromLTRB(
                            AppTheme.gutter,
                            10,
                            AppTheme.gutter,
                            8,
                          ),
                          child: Row(
                            children: [
                              Text(
                                e.year == 0 ? AppL.of(context).bankUndatedGroup : AppL.of(context).bankYear('${e.year}'),
                                style:
                                    text.titleMedium?.copyWith(fontSize: 16),
                              ),
                              SizedBox(width: 8),
                              Text(AppL.of(context).bankPaperCountShort(e.count), style: text.bodySmall),
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
              ? EmptyState(
                  icon: Icons.description_outlined,
                  title: AppL.of(context).bankPickPaper,
                  art: EmptyArt.paper,
                  message: AppL.of(context).bankPickPaperHint,
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
        // 标题为空时留空串，由列表显示时按当前语言兜底 ——
        // 这里是行到模型的映射，没有 context。
        title: '${row['paper_title'] ?? ''}',
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
        // 左边跟标题、搜索框、年份行对齐到同一条 gutter 上 —— 少了这一段，
        // 整条 chip 会比页面上所有其他东西往左突出 20px。
        // 右边多留一截，最后一个 chip 不会被屏幕边缘齐刷刷切断。
        // 这两个数跟 FilterBar 是同一组，改一个必须改另一个。
        padding: const EdgeInsets.fromLTRB(
          AppTheme.gutter,
          0,
          AppTheme.gutter + 24,
          0,
        ),
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
                          padding: EdgeInsets.symmetric(
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
                        SizedBox(width: 7),
                        Text(
                          started ? AppL.of(context).bankPaperProgress(done, paper.count) : AppL.of(context).countQuestions(paper.count),
                          style: text.bodySmall?.copyWith(
                            fontSize: 11.5,
                            color: started ? t.brand : t.muted,
                            fontFeatures: AppTheme.numeric,
                          ),
                        ),
                        if (paper.imported) ...[
                          SizedBox(width: 8),
                          Text(AppL.of(context).bankImport,
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

/// 导出范围。整库通常几万道题几百兆，多数人想发的只是某一卷。
class _ExportScopeSheet extends StatelessWidget {
  const _ExportScopeSheet({required this.papers});

  final List<_Paper> papers;

  @override
  Widget build(BuildContext context) {
    final l = AppL.of(context);
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final total = papers.fold<int>(0, (s, p) => s + p.count);

    return Container(
      decoration: BoxDecoration(
        color: t.gradient.last,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: t.lineSoft)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.bankExportTitle, style: text.titleMedium),
            const SizedBox(height: 6),
            Text(
              l.bankExportBody,
              style: text.bodySmall,
            ),
            const SizedBox(height: 10),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  _ScopeRow(
                    title: l.bankExportWholeBank,
                    subtitle: l.bankExportWholeBankHint(total),
                    onTap: () => Navigator.of(context).pop('_all'),
                  ),
                  for (final p in papers)
                    _ScopeRow(
                      title: p.title.isEmpty
                          ? AppL.of(context).bankUntitledPaper
                          : p.title,
                      subtitle: l.bankExportCount(p.count),
                      onTap: () => Navigator.of(context).pop(p.id),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScopeRow extends StatelessWidget {
  const _ScopeRow({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: text.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(subtitle, style: text.bodySmall),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 20, color: t.muted),
          ],
        ),
      ),
    );
  }
}
