import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:openexam_app/core/theme/app_theme.dart';
import 'package:openexam_app/core/theme/app_tokens.dart';
import 'package:openexam_app/core/ui/ui_kit.dart';
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

    final body = Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 20),
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  AppTheme.gutter,
                  widget.standalone ? 8 : 24,
                  AppTheme.gutter,
                  22,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!widget.standalone) ...[
                      Text(
                        '导入题目',
                        style: text.displaySmall?.copyWith(fontSize: 26),
                      ),
                      const SizedBox(height: 7),
                    ],
                    Text(
                      '三步就好，题目只存在这台手机上',
                      style: text.bodySmall?.copyWith(fontSize: 13),
                    ),
                  ],
                ),
              ),
              if (_result != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.gutter,
                    0,
                    AppTheme.gutter,
                    22,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        _failed
                            ? Icons.error_outline
                            : Icons.check_circle_outline,
                        size: 19,
                        color: _failed ? t.danger : t.success,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _result!,
                          style: text.bodyMedium?.copyWith(
                            color: _failed ? t.danger : t.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const _Step(
                index: 1,
                title: '准备一个题目文件',
                desc: '手机里存一个 JSON / CSV 文件；带图的题目可以打包成 zip（题目文件 + 图片放一起）。',
              ),
              const _Step(
                index: 2,
                title: '点下面的按钮选中它',
                desc: '选中后会先显示解析结果：多少题、按题型分布、多少张图、有多少题会被覆盖。',
              ),
              const _Step(
                index: 3,
                title: '回「练习」页开刷',
                desc: '导入的题会和内置题库合并，按题型分类统计。重复的题会自动覆盖。',
                last: true,
              ),
              const SizedBox(height: 12),
              // Format details stay collapsed — beginners never need to open it.
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.gutter,
                ),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _showFormat = !_showFormat),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        Text('文件格式说明', style: text.titleSmall),
                        const SizedBox(width: 6),
                        Icon(
                          _showFormat ? Icons.expand_less : Icons.expand_more,
                          size: 19,
                          color: t.muted,
                        ),
                        const Spacer(),
                        Text('可选', style: text.bodySmall),
                      ],
                    ),
                  ),
                ),
              ),
              if (_showFormat) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.gutter,
                    4,
                    AppTheme.gutter,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '推荐一份 paper.json：试卷元数据 + questions 数组。也兼容旧的题目数组。CSV 最低集是 content,A,B,C,D,answer,category,analysis。',
                        style: text.bodyMedium,
                      ),
                      const SizedBox(height: 14),
                      Surface(
                        fill: true,
                        radius: 16,
                        padding: const EdgeInsets.all(14),
                        child: Text(
                          '{\n  "schemaVersion": 1,\n  "paper": {\n    "id": "paper_user_001",\n    "title": "我的试卷",\n    "examKind": "gongwuyuan",\n    "examLevel": "provincial",\n    "region": "anhui",\n    "subject": "computer",\n    "source": "imported"\n  },\n  "questions": [\n    {\n      "content": "题干",\n      "options": [\n        {"key": "A", "text": "选项一"},\n        {"key": "B", "text": "选项二"}\n      ],\n      "answer": "A",\n      "category": "cs_base",\n      "analysis": "解析（选填）"\n    }\n  ]\n}',
                          style: text.bodySmall?.copyWith(
                            fontFamily: 'Menlo',
                            fontSize: 12,
                            color: t.textSoft,
                            height: 1.6,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'examKind：gongwuyuan 公务员 / shiyedanwei 事业单位。examLevel：national 国家 / provincial 省级。'
                        'subject：xingce 行测 / computer 计算机。'
                        '行测 category：yanyu / shuliang / panduan / ziliao / changshi。'
                        '计算机 category：cs_base / cs_security / cs_windows / cs_office / cs_prog / cs_db / cs_net / cs_se。',
                        style: text.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'ZIP：题目文件和图片放进同一个压缩包，题干写 '
                        '<img src="图片文件名.png">。完整字段见仓库 data/original/IMPORT_SCHEMA.md。',
                        style: text.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '导入内容的权利归内容来源方。请只导入你有权使用的材料。',
                        style: text.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        ActionBar(
          safeBottom: widget.standalone,
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _busy ? null : _pickAndImport,
              child: Text(_busy ? '正在解析…' : '选择文件'),
            ),
          ),
        ),
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
}

/// Numbered step with a connector line — the beginner path down the page.
class _Step extends StatelessWidget {
  const _Step({
    required this.index,
    required this.title,
    required this.desc,
    this.last = false,
  });

  final int index;
  final String title;
  final String desc;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.gutter),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: t.brand.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$index',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 1,
                      color: t.brand,
                    ),
                  ),
                ),
                if (!last)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      color: t.brand.withValues(alpha: 0.16),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: 2, bottom: last ? 0 : 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: text.titleSmall),
                    const SizedBox(height: 5),
                    Text(
                      desc,
                      style: text.bodyMedium?.copyWith(fontSize: 13.5),
                    ),
                  ],
                ),
              ),
            ),
          ],
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
