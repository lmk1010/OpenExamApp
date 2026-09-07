import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:openexam_app/l10n/app_localizations.dart';
import 'package:openexam_app/core/theme/app_theme.dart';
import 'package:openexam_app/core/theme/app_tokens.dart';
import 'package:openexam_app/core/ui/shore_art.dart';
import 'package:openexam_app/features/import/presentation/scan_paper_page.dart';
import 'package:openexam_app/data/db/app_database.dart';
import 'package:openexam_app/features/profile/domain/exam_profile.dart';
import 'package:openexam_app/core/constants/categories.dart';
import 'package:openexam_app/core/ui/stroke_icons.dart';
import 'package:openexam_app/data/importers/question_importer.dart';
import 'package:openexam_app/features/import/presentation/doc_import_page.dart';

class ImportPage extends StatefulWidget {
  const ImportPage({super.key, this.standalone = false});

  /// When pushed from 我的 it owns a Scaffold + back button of its own.
  final bool standalone;

  @override
  State<ImportPage> createState() => _ImportPageState();
}

class _ImportPageState extends State<ImportPage> {
  bool _busy = false;
  String? _result;
  bool _failed = false;
  bool _showFormat = false;

  Future<void> _openDocImport() async {
    final added = await Navigator.of(context).push<int>(
      MaterialPageRoute(builder: (_) => const DocImportPage()),
    );
    if (added != null && added > 0 && mounted) {
      final l = AppL.of(context);
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(l.importScanDone(added))));
    }
  }

  Future<void> _pickAndImport() async {
    final l = AppL.of(context);
    setState(() => _busy = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['json', 'csv', 'txt', 'zip'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) {
        setState(() => _busy = false);
        return;
      }
      final file = result.files.first;
      List<int>? bytes = file.bytes;
      if (bytes == null && file.path != null) {
        bytes = await File(file.path!).readAsBytes();
      }
      if (bytes == null) {
        _fail(l.importUnreadable);
        return;
      }
      final bundle = QuestionImporter.parseFile(bytes, fileName: file.name);
      if (bundle.isEmpty) {
        _fail(l.importNoQuestions);
        return;
      }

      // Nothing is written until the user has seen what the file contains.
      final existing = await AppDatabase.instance.countExisting(
        bundle.questions.map((q) => q.id).toList(),
      );
      if (!mounted) return;
      setState(() => _busy = false);
      final go = await showModalBottomSheet<bool>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (_) => _PreviewSheet(
          bundle: bundle,
          fileName: file.name,
          duplicates: existing,
        ),
      );
      if (go != true) return;

      setState(() => _busy = true);
      await AppDatabase.instance.importImages(bundle.images);
      final count = await AppDatabase.instance.importQuestions(
        bundle.questions,
      );
      // 导进来的是行测题库的话，把中文专属模块打开 —— 不然用户导完发现
      // 技巧速查、词语、申论都还关着，而他不知道设置里有「界面模块」。
      await ExamProfileStore.adoptFromBank(
        bundle.questions.map((q) => q.category),
      );
      if (!mounted) return;
      setState(() {
        _busy = false;
        _failed = false;
        // 两截后缀都是可选的，在 Dart 里拼。
        _result = l.importedCount(count) +
            (bundle.images.isEmpty
                ? ''
                : l.importedImages(bundle.images.length)) +
            (existing > 0 ? l.importedOverwritten(existing) : '');
      });
    } catch (e) {
      _fail(l.importFailed('$e'));
    }
  }

  /// 拍照 / PDF：交给扫描页，回来的是已经确认过的题。
  Future<void> _scan() async {
    final l = AppL.of(context);
    final done = await Navigator.of(context).push<int>(
      MaterialPageRoute(builder: (_) => const ScanPaperPage()),
    );
    if (!mounted || done == null) return;
    setState(() {
      _failed = false;
      _result = done == 0
          ? l.importedNothing
          : l.importedCount(done);
    });
  }

  void _fail(String message) {
    if (!mounted) return;
    setState(() {
      _busy = false;
      _failed = true;
      _result = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL.of(context);
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    final body = ListView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.paddingOf(context).bottom + 24,
      ),
      children: [
        const SizedBox(height: 8),
        // 主路是「题库文件」：App 不带题目了，绝大多数人是从官网下一个包
        // 进来的。以前这里把「拍照 / PDF」放在第一个还高亮着 —— 那条路
        // 要配 AI、要等模型逐页认，把它摆成默认动作等于劝退。
        _Way(
          art: ShoreArt.icoHistory,
          title: l.importWayFileTitle,
          desc: l.importWayFileDesc,
          primary: true,
          onTap: _busy ? null : _pickAndImport,
        ),
        const SizedBox(height: 12),
        // 文字文件不该走渲染成图那条路 —— 里面本来就有字，
        // 转成图再让模型认一遍，慢、贵、还更容易认错。
        _Way(
          art: ShoreArt.icoNote,
          title: l.importWayDocTitle,
          desc: l.importWayDocDesc,
          onTap: _busy ? null : _openDocImport,
        ),
        const SizedBox(height: 12),
        _Way(
          art: ShoreArt.icoMark,
          title: l.importWayScanTitle,
          desc: l.importWayScanDesc,
          onTap: _busy ? null : _scan,
        ),

        if (_busy) ...[
          const SizedBox(height: 22),
          const Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
        ],

        if (_result != null) ...[
          const SizedBox(height: 22),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.gutter),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _failed ? t.dangerSoft : t.accentSoft,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                _result!,
                style: text.bodyMedium?.copyWith(
                  color: _failed ? t.danger : t.onAccentSoft,
                ),
              ),
            ),
          ),
        ],

        const SizedBox(height: 26),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppTheme.gutter),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _showFormat = !_showFormat),
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    AppL.of(context).importFormatTitle,
                    style: text.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  _showFormat
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: t.muted,
                ),
              ],
            ),
          ),
        ),
        if (_showFormat) ...[
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.gutter),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: t.surfaceAlt,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                _formatSample(AppL.of(context)),
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11.5,
                  height: 1.6,
                  color: t.textSoft,
                ),
              ),
            ),
          ),
        ],
      ],
    );

    if (!widget.standalone) return body;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 21),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        titleSpacing: 0,
        title: Text(AppL.of(context).profileImport),
      ),
      body: body,
    );
  }

  /// 导入格式示例。键名是格式的一部分不能动，只有示例值跟着界面语言走。
  /// 整段没放进 arb —— 里面的花括号会被 ICU 当成占位符。
  static String _formatSample(AppL l) =>
      '{"paper": {"title": "${l.importSampleTitle}", "year": 2026},\n'
      ' "questions": [{\n'
      '   "content": "${l.importSampleContent}",\n'
      '   "material": "${l.importSampleMaterial}",\n'
      '   "options": [{"key":"A","text":"${l.importSampleOptA}"},\n'
      '               {"key":"B","text":"${l.importSampleOptB}"}],\n'
      '   "answer": "A",\n'
      '   "analysis": "${l.importSampleAnalysis}",\n'
      '   "category": "ziliao"\n'
      ' }]}';
}

/// 一条导入路径。图标 + 一句话，点了就走，不解释第二句。
class _Way extends StatelessWidget {
  const _Way({
    required this.art,
    required this.title,
    required this.desc,
    required this.onTap,
    this.primary = false,
  });

  final String art;
  final String title;
  final String desc;
  final VoidCallback? onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.gutter),
      child: Opacity(
        opacity: onTap == null ? 0.5 : 1,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 18, 16, 18),
            decoration: BoxDecoration(
              color: primary ? t.accentSoft : t.surface,
              borderRadius: BorderRadius.circular(22),
              boxShadow: primary ? null : t.shadow,
            ),
            child: Row(
              children: [
                Image.asset(
                  art,
                  width: 40,
                  height: 40,
                  filterQuality: FilterQuality.medium,
                  errorBuilder: (_, __, ___) => const SizedBox(width: 40),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: text.titleSmall?.copyWith(fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(
                        desc,
                        style: text.bodySmall?.copyWith(
                          fontSize: 12.5,
                          color: primary ? t.onAccentSoft : t.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, size: 18, color: t.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


/// Import preview — shows exactly what a file will do before it does it.
class _PreviewSheet extends StatelessWidget {
  const _PreviewSheet({
    required this.bundle,
    required this.fileName,
    required this.duplicates,
  });

  final ImportBundle bundle;
  final String fileName;
  final int duplicates;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final byCategory = bundle.byCategory;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: t.gradient.last,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: t.lineSoft)),
      ),
      padding: EdgeInsets.fromLTRB(20, 18, 20, 16),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppL.of(context).importParsed, style: text.titleMedium),
            SizedBox(height: 6),
            Text(fileName, style: text.bodySmall),
            SizedBox(height: 16),
            Row(
              children: [
                _Stat(value: '${bundle.questions.length}', label: AppL.of(context).importQuestions),
                _Stat(value: '${bundle.images.length}', label: AppL.of(context).importImages),
                _Stat(value: '$duplicates', label: AppL.of(context).importOverwrites),
              ],
            ),
            const SizedBox(height: 18),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final entry in byCategory.entries)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            StrokeIcon(
                              categoryIcon(entry.key),
                              size: 16,
                              color: t.category(entry.key),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                categoryLabel(entry.key),
                                style: text.bodyMedium?.copyWith(fontSize: 14),
                              ),
                            ),
                            Text(AppL.of(context).countQuestions(entry.value), style: text.bodySmall),
                          ],
                        ),
                      ),
                    // 缺图那条由界面组句 —— 解析器只报数字，见 ImportBundle。
                    for (final warning in [
                      ...bundle.warnings,
                      if (bundle.missingImages > 0)
                        AppL.of(context)
                            .importMissingImages(bundle.missingImages),
                    ])
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 15,
                              color: t.danger,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                warning,
                                style: text.bodySmall?.copyWith(
                                  color: t.danger,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(AppL.of(context).commonCancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text(AppL.of(context).importConfirm),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: text.headlineSmall?.copyWith(fontSize: 21)),
          const SizedBox(height: 5),
          Text(label, style: text.bodySmall?.copyWith(fontSize: 12)),
        ],
      ),
    );
  }
}
