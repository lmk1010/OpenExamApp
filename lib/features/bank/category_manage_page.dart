import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:openexam_app/l10n/app_localizations.dart';
import 'package:openexam_app/core/ai/ai_client.dart';
import 'package:openexam_app/core/ai/ai_settings.dart';
import 'package:openexam_app/core/constants/categories.dart';
import 'package:openexam_app/core/theme/app_theme.dart';
import 'package:openexam_app/core/theme/app_tokens.dart';
import 'package:openexam_app/core/ui/ambient.dart';
import 'package:openexam_app/core/ui/responsive.dart';
import 'package:openexam_app/core/ui/stroke_icons.dart';
import 'package:openexam_app/core/ui/ui_kit.dart';
import 'package:openexam_app/data/db/app_database.dart';
import 'package:openexam_app/data/models/question.dart';
import 'package:openexam_app/features/ai/ai_thinking.dart';

/// 分类整理。
///
/// 导入是一次一本书地来的，AI 每次都在独立判断分类 —— 今天导出来"数据库"，
/// 下个月那本导成"数据库系统"，练习页就多一张卡片。单次导入内部会自动收口，
/// 跨导入的只能在这里手动并：把名字改成已有的那个，两类就合成一类。
///
/// 还有一条 AI 的路：把某一类（通常是「未分类」）里的题，按你现有的分类
/// 重新归一遍。它只在你已有的名字里选，不会自己造新的。
class CategoryManagePage extends StatefulWidget {
  const CategoryManagePage({super.key});

  @override
  State<CategoryManagePage> createState() => _CategoryManagePageState();
}

class _CategoryManagePageState extends State<CategoryManagePage> {
  bool _loading = true;
  List<CategoryStat> _stats = const [];
  String? _working;
  String _note = '';
  bool _busyGlobal = false;

  int get _totalQuestions =>
      _stats.fold(0, (sum, s) => sum + s.total);

  /// 导出题库本身。「备份与恢复」导的是做题记录，不含题目 —— 换手机之后
  /// 记录都在、题是空的，这是另外半件事。
  Future<void> _export() async {
    setState(() => _busyGlobal = true);
    try {
      final rows = await AppDatabase.instance.exportQuestions();
      final json = const JsonEncoder.withIndent('  ').convert(rows);
      final now = DateTime.now();
      final name = 'openexam-questions-'
          '${now.year}${now.month.toString().padLeft(2, '0')}'
          '${now.day.toString().padLeft(2, '0')}-'
          '${now.hour.toString().padLeft(2, '0')}'
          '${now.minute.toString().padLeft(2, '0')}.json';
      final path = await FilePicker.platform.saveFile(
        fileName: name,
        bytes: utf8.encode(json),
      );
      if (!mounted) return;
      if (path != null) {
        _toast(AppL.of(context).cmExported(rows.length));
      } else {
        // 选择器不可用时落到 app 文档目录，总比整个失败强
        final dir = await getApplicationDocumentsDirectory();
        await File('${dir.path}/$name').writeAsString(json);
        if (mounted) _toast(AppL.of(context).wrongExportSavedDocs(name));
      }
    } catch (e) {
      if (mounted) _toast(AppL.of(context).wrongExportFailed('$e'));
    } finally {
      if (mounted) setState(() => _busyGlobal = false);
    }
  }

  /// 清空题库。做题记录不动 —— 它按 question_id 存，重新导入同一批题还能对上。
  Future<void> _clearAll() async {
    final ok = await _confirm(
      title: AppL.of(context).cmClearBank,
      body: '${AppL.of(context).cmClearBody(_totalQuestions)}'
          '${AppL.of(context).cmClearNote}',
      action: AppL.of(context).cmClear,
    );
    if (ok != true) return;
    setState(() => _busyGlobal = true);
    final n = await AppDatabase.instance.clearQuestions();
    await _load();
    if (!mounted) return;
    setState(() => _busyGlobal = false);
    _toast(AppL.of(context).cmCleared(n));
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final stats = await AppDatabase.instance.categoryStats();
    if (!mounted) return;
    setState(() {
      _stats = stats.where((s) => s.total > 0).toList();
      _loading = false;
    });
    CategoryRegistry.updateFrom(_stats.map((e) => e.category));
  }

  Future<void> _rename(CategoryStat stat) async {
    final l = AppL.of(context);
    final others = _stats
        .map((e) => e.category)
        .where((c) => c != stat.category)
        .toList();

    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => _RenameDialog(current: stat.category, others: others),
    );
    if (name == null || name.isEmpty || name == stat.category) return;

    final merging = others.contains(name);
    if (merging) {
      final ok = await _confirm(
        title: l.cmMerge,
        body: '${l.cmMergeBody(stat.total, stat.category, name)}'
            '${l.cmMergeNote}',
        action: l.cmMergeConfirm,
      );
      if (ok != true) return;
    }
    await AppDatabase.instance.renameCategory(stat.category, name);
    await _load();
    if (mounted) _toast(merging ? l.cmMerged(name) : l.cmRenamed);
  }

  /// 让 AI 把这一类里的题重新分到现有分类里。
  Future<void> _autoClassify(CategoryStat stat) async {
    final l = AppL.of(context);
    final settings = await AiSettingsStore.load();
    if (!settings.isConfigured) {
      _toast(l.cmNeedAiKey);
      return;
    }
    final targets = _stats
        .map((e) => e.category)
        .where((c) => c != stat.category && c != l.cmUncategorised)
        .toList();
    if (targets.isEmpty) {
      _toast(l.cmNoTargets);
      return;
    }

    final ok = await _confirm(
      title: l.cmAiSort,
      body: '${l.cmAiSortBody(stat.category)}'
          '${l.cmAiSortNote(targets.length)}',
      action: l.commonStart,
    );
    if (ok != true) return;

    setState(() {
      _working = stat.category;
      _note = l.cmReading;
    });

    final briefs = await AppDatabase.instance.questionBriefs(stat.category);
    // 一次三十道：太多了模型容易漏答、也容易顶到输出上限
    const batch = 30;
    var moved = 0;

    for (var i = 0; i < briefs.length; i += batch) {
      final slice = briefs.skip(i).take(batch).toList();
      if (mounted) {
        setState(() => _note = '${i + slice.length}/${briefs.length}');
      }

      final buf = StringBuffer()
        ..writeln('可选分类：${targets.join('、')}')
        ..writeln()
        ..writeln('把下面每道题归到上面某一个分类里。');
      for (var j = 0; j < slice.length; j++) {
        final text = slice[j].content.replaceAll('\n', ' ');
        buf.writeln('$j. ${text.length > 120 ? text.substring(0, 120) : text}');
      }

      AiClient.feature = 'classify';
      final result = await AiClient(settings).completeJson(
        system: _classifySystem,
        prompt: buf.toString(),
      );
      if (!result.isOk || result.value == null) continue;

      final raw = result.value!['items'];
      if (raw is! List) continue;
      final updates = <String, String>{};
      for (final item in raw) {
        if (item is! Map) continue;
        final idx = int.tryParse('${item['index']}');
        final category = '${item['category'] ?? ''}'.trim();
        if (idx == null || idx < 0 || idx >= slice.length) continue;
        // 只认它在给定清单里挑的，模型自己造的名字一律不要 ——
        // 否则"重新归类"会变成"又多几个新分类"
        if (!targets.contains(category)) continue;
        updates[slice[idx].id] = category;
      }
      await AppDatabase.instance.setCategoryFor(updates);
      moved += updates.length;
    }

    if (!mounted) return;
    setState(() {
      _working = null;
      _note = '';
    });
    await _load();
    if (mounted) {
      _toast(moved == 0 ? l.cmAiSortFailed : l.cmAiSorted(moved));
    }
  }

  Future<bool?> _confirm({
    required String title,
    required String body,
    required String action,
  }) =>
      showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(AppL.of(context).commonCancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(action),
            ),
          ],
        ),
      );

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: t.gradient.last,
      body: SafeArea(
        child: ReadableWidth(
          child: _loading
              ? LoadingState()
              : ListView(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.paddingOf(context).bottom + 28,
                  ),
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                          AppTheme.gutter, 8, AppTheme.gutter, 6),
                      child: Row(
                        children: [
                          PlainIconButton(
                            icon: Icons.arrow_back,
                            onTap: () => Navigator.of(context).maybePop(),
                          ),
                          SizedBox(width: 4),
                          Expanded(
                              child: Text(AppL.of(context).cmTitle, style: text.titleMedium)),
                          if (_stats.isNotEmpty) ...[
                            IconButton(
                              tooltip: AppL.of(context).bankExportTitle,
                              visualDensity: VisualDensity.compact,
                              icon: Icon(Icons.ios_share,
                                  size: 19, color: t.textSoft),
                              onPressed: _busyGlobal ? null : _export,
                            ),
                            IconButton(
                              tooltip: AppL.of(context).cmClearBank,
                              visualDensity: VisualDensity.compact,
                              icon: Icon(Icons.delete_sweep_outlined,
                                  size: 20, color: t.textSoft),
                              onPressed: _busyGlobal ? null : _clearAll,
                            ),
                          ],
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                          AppTheme.gutter, 0, AppTheme.gutter, 14),
                      child: Text(
                        AppL.of(context).cmRenameHint,
                        style: text.bodySmall?.copyWith(color: t.textSoft),
                      ),
                    ),
                    if (_stats.isEmpty)
                      EmptyState(
                        icon: Icons.category_outlined,
                        title: AppL.of(context).cmEmptyTitle,
                        message: AppL.of(context).cmEmptyBody,
                      ),
                    for (final s in _stats)
                      _CategoryRow(
                        stat: s,
                        busy: _working == s.category,
                        note: _working == s.category ? _note : null,
                        onRename: _working == null && !_busyGlobal
                            ? () => _rename(s)
                            : null,
                        onAuto: _working == null && !_busyGlobal
                            ? () => _autoClassify(s)
                            : null,
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}

const _classifySystem = '''
你在给题目归类。给你一份分类清单和一批题，说出每道题属于哪一类。

只回 JSON：
{"items": [{"index": 0, "category": "清单里的某一个"}]}

规矩：
1. category 必须**逐字**来自给定清单，不要改写、不要合并、不要新造。
2. 拿不准的那道题直接不写进 items，跳过比归错强。
3. index 是题前面的序号。
''';

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.stat,
    required this.busy,
    required this.note,
    required this.onRename,
    required this.onAuto,
  });

  final CategoryStat stat;
  final bool busy;
  final String? note;
  final VoidCallback? onRename;
  final VoidCallback? onAuto;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final meta = CategoryRegistry.metaFor(stat.category);

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.gutter, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: t.category(stat.category).withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: StrokeIcon(meta.icon,
                size: 19, color: t.category(stat.category)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meta.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.titleSmall,
                ),
                SizedBox(height: 2),
                Row(
                  children: [
                    Text(AppL.of(context).countQuestions(stat.total),
                        style: text.bodySmall?.copyWith(color: t.textSoft)),
                    if (busy) ...[
                      const SizedBox(width: 8),
                      AiDots(),
                      SizedBox(width: 6),
                      Text(note ?? '',
                          style:
                              text.bodySmall?.copyWith(color: t.textSoft)),
                    ],
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: AppL.of(context).cmAiSort,
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.auto_awesome_outlined,
                size: 18, color: t.textSoft),
            onPressed: onAuto,
          ),
          IconButton(
            tooltip: AppL.of(context).cmRenameMerge,
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.drive_file_rename_outline,
                size: 18, color: t.textSoft),
            onPressed: onRename,
          ),
        ],
      ),
    );
  }
}

/// 改名对话框。已有的分类摆在下面，点一下就是合并 —— 手打一个一模一样的
/// 名字才能合并，太容易打错。
class _RenameDialog extends StatefulWidget {
  const _RenameDialog({required this.current, required this.others});

  final String current;
  final List<String> others;

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final TextEditingController _ctrl =
      TextEditingController(text: widget.current);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return AlertDialog(
      title: Text(AppL.of(context).cmRenameMerge),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _ctrl,
            autofocus: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onSubmitted: (v) => Navigator.of(context).pop(v.trim()),
          ),
          if (widget.others.isNotEmpty) ...[
            SizedBox(height: 14),
            Text(AppL.of(context).cmMergeInto,
                style: text.bodySmall?.copyWith(color: t.textSoft)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (final name in widget.others)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => _ctrl.text = name),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 11, vertical: 5),
                      decoration: BoxDecoration(
                        color: _ctrl.text == name ? t.brand : t.accentSoft,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        name,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: _ctrl.text == name
                              ? t.onAccent
                              : t.onAccentSoft,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppL.of(context).commonCancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_ctrl.text.trim()),
          child: Text(AppL.of(context).commonConfirm),
        ),
      ],
    );
  }
}
