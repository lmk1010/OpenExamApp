import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:openexam_app/core/theme/app_theme.dart';
import 'package:openexam_app/core/theme/app_tokens.dart';
import 'package:openexam_app/core/ui/shore_art.dart';
import 'package:openexam_app/features/import/presentation/scan_paper_page.dart';
import 'package:openexam_app/data/db/app_database.dart';
import 'package:openexam_app/core/constants/categories.dart';
import 'package:openexam_app/core/ui/stroke_icons.dart';
import 'package:openexam_app/data/importers/question_importer.dart';

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

  Future<void> _pickAndImport() async {
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
        _fail('读不到这个文件，换一个试试');
        return;
      }
      final bundle = QuestionImporter.parseFile(bytes, fileName: file.name);
      if (bundle.isEmpty) {
        _fail('这个文件里没找到题目，看看下面的格式说明');
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
      if (!mounted) return;
      setState(() {
        _busy = false;
        _failed = false;
        _result =
            '成功导入 $count 题'
            '${bundle.images.isEmpty ? '' : '、${bundle.images.length} 张图'}'
            '${existing > 0 ? '（其中 $existing 题为覆盖更新）' : ''}';
      });
    } catch (e) {
      _fail('导入失败：$e');
    }
  }

  /// 拍照 / PDF：交给扫描页，回来的是已经确认过的题。
  Future<void> _scan() async {
    final done = await Navigator.of(context).push<int>(
      MaterialPageRoute(builder: (_) => const ScanPaperPage()),
    );
    if (!mounted || done == null) return;
    setState(() {
      _failed = false;
      _result = done == 0 ? '这次没有导入题目' : '成功导入 $done 题';
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
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    final body = ListView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.paddingOf(context).bottom + 24,
      ),
      children: [
        const SizedBox(height: 8),
        // 两条路，各一张卡。上面那张是主路：拍照或选 PDF，AI 逐页认。
        _Way(
          art: ShoreArt.icoNote,
          title: '拍照 / PDF',
          desc: '试卷、截图、买来的 PDF，AI 逐页认成题目',
          primary: true,
          onTap: _busy ? null : _scan,
        ),
        const SizedBox(height: 12),
        _Way(
          art: ShoreArt.icoHistory,
          title: '题目文件',
          desc: 'JSON / CSV，带图的打包成 zip',
          onTap: _busy ? null : _pickAndImport,
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
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.gutter),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _showFormat = !_showFormat),
            child: Row(
              children: [
                Text('题目文件长什么样', style: text.bodySmall),
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
                _formatSample,
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
        title: const Text('导入题目'),
      ),
      body: body,
    );
  }

  static const _formatSample =
      '{"paper": {"title": "2026 国考行测", "year": 2026},\n'
      ' "questions": [{\n'
      '   "content": "题干",\n'
      '   "material": "共用材料，没有可省",\n'
      '   "options": [{"key":"A","text":"甲"},\n'
      '               {"key":"B","text":"乙"}],\n'
      '   "answer": "A",\n'
      '   "analysis": "解析",\n'
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
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: t.lineSoft)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('解析结果', style: text.titleMedium),
            const SizedBox(height: 6),
            Text(fileName, style: text.bodySmall),
            const SizedBox(height: 16),
            Row(
              children: [
                _Stat(value: '${bundle.questions.length}', label: '题目'),
                _Stat(value: '${bundle.images.length}', label: '图片'),
                _Stat(value: '$duplicates', label: '覆盖已有'),
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
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                categoryLabel(entry.key),
                                style: text.bodyMedium?.copyWith(fontSize: 14),
                              ),
                            ),
                            Text('${entry.value} 题', style: text.bodySmall),
                          ],
                        ),
                      ),
                    for (final warning in bundle.warnings)
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
                    child: const Text('取消'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('确认导入'),
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
