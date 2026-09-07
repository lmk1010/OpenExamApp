import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:openexam_app/core/ai/ai_settings.dart';
import 'package:openexam_app/core/constants/categories.dart';
import 'package:openexam_app/core/theme/app_theme.dart';
import 'package:openexam_app/core/theme/app_tokens.dart';
import 'package:openexam_app/core/ui/ambient.dart';
import 'package:openexam_app/core/ui/responsive.dart';
import 'package:openexam_app/core/ui/ui_kit.dart';
import 'package:openexam_app/data/db/app_database.dart';
import 'package:openexam_app/data/importers/doc_parser.dart';
import 'package:openexam_app/data/importers/document_text.dart';
import 'package:openexam_app/data/models/question.dart';
import 'package:openexam_app/features/ai/ai_thinking.dart';

/// Word / Excel / CSV / 纯文本 → 题目。
///
/// 跟「拍照 / PDF」那条路的区别是这里根本不过图：文件里本来就有文字，
/// 渲染成图再让模型认一遍既慢又贵还更容易错。表格更进一步 —— 一次调用
/// 认出列的含义，剩下几千行全在本地转，不再花钱。
class DocImportPage extends StatefulWidget {
  const DocImportPage({super.key});

  @override
  State<DocImportPage> createState() => _DocImportPageState();
}

class _DocImportPageState extends State<DocImportPage> {
  bool _busy = false;
  String _note = '';
  double _ratio = 0;
  String _fileName = '';
  List<Question> _questions = const [];
  final _subject = TextEditingController();

  @override
  void dispose() {
    _subject.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final settings = await AiSettingsStore.load();
    if (!settings.isConfigured) {
      _toast('先去「我的 → AI 设置」配一个 key，解析要用它');
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['docx', 'xlsx', 'csv', 'txt', 'md'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    var bytes = file.bytes;
    if (bytes == null && file.path != null) {
      bytes = await File(file.path!).readAsBytes();
    }
    if (bytes == null) {
      _toast('读不到这个文件，换一个试试');
      return;
    }

    setState(() {
      _busy = true;
      _fileName = file.name;
      _questions = const [];
      _note = '正在打开文件…';
      _ratio = 0;
    });

    final doc = DocumentText.extract(bytes, fileName: file.name);
    if (doc.isEmpty) {
      setState(() {
        _busy = false;
        _note = '这个文件里没读到文字。扫描件请走「拍照 / PDF」那条路。';
      });
      return;
    }

    final hint = _subject.text.trim();
    await for (final p in DocParser(settings).parse(
      doc,
      subjectHint: hint.isEmpty ? null : hint,
    )) {
      if (!mounted) return;
      setState(() {
        _note = p.note;
        _ratio = p.ratio;
        _questions = p.questions;
      });
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _save() async {
    if (_questions.isEmpty) return;
    setState(() => _busy = true);
    await AppDatabase.instance.importQuestions(_questions);
    CategoryRegistry.updateFrom(await AppDatabase.instance.categoryKeys());
    if (!mounted) return;
    setState(() => _busy = false);
    Navigator.of(context).pop(_questions.length);
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// 没答案的题进了题库也做不了，单独数出来提醒。
  int get _noAnswer => _questions.where((q) => q.answer.isEmpty).length;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: t.gradient.last,
      body: SafeArea(
        child: ReadableWidth(
          child: ListView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.paddingOf(context).bottom + 100,
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppTheme.gutter, 8, AppTheme.gutter, 10),
                child: Row(
                  children: [
                    PlainIconButton(
                      icon: Icons.arrow_back,
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(width: 4),
                    Text('文档导入', style: text.titleMedium),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.gutter),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Word、Excel、CSV、纯文本都行。AI 读一遍，认出题干、选项、'
                      '答案和解析 —— 什么考试都可以，不限于行测。',
                      style: text.bodySmall?.copyWith(color: t.textSoft),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _subject,
                      enabled: !_busy,
                      decoration: const InputDecoration(
                        labelText: '这是什么考试的（可选）',
                        hintText: '例如 教师资格证 · 科目二',
                        helperText: '填了能帮 AI 分类分得准一些',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _busy ? null : _pick,
                        child: Text(_questions.isEmpty ? '选择文件' : '换一个文件'),
                      ),
                    ),
                  ],
                ),
              ),

              if (_busy || _note.isNotEmpty) ...[
                const SizedBox(height: 20),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppTheme.gutter),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _fileName.isEmpty ? _note : '$_fileName · $_note',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: text.bodySmall?.copyWith(color: t.textSoft),
                            ),
                          ),
                          if (_busy) ...[
                            const SizedBox(width: 8),
                            const AiDots(),
                          ],
                        ],
                      ),
                      if (_busy) ...[
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: _ratio == 0 ? null : _ratio,
                            minHeight: 5,
                            backgroundColor: t.lineSoft,
                            color: t.brand,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              if (_questions.isNotEmpty) ...[
                const SizedBox(height: 22),
                SectionHeader(
                  title: '认出来的题',
                  caption: '${_questions.length} 道'
                      '${_noAnswer == 0 ? '' : ' · $_noAnswer 道没答案'}',
                ),
                if (_noAnswer > 0)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppTheme.gutter, 2, AppTheme.gutter, 6),
                    child: Text(
                      '没答案的题做不了，多半是原文档把答案单独列在别处。'
                      '存进去之后可以自己补，或者换一份带答案的资料。',
                      style: text.bodySmall?.copyWith(color: t.textSoft),
                    ),
                  ),
                for (var i = 0; i < _questions.length && i < 30; i++) ...[
                  if (i > 0) const RowDivider(),
                  _Preview(question: _questions[i], index: i + 1),
                ],
                if (_questions.length > 30)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppTheme.gutter, 12, AppTheme.gutter, 0),
                    child: Text(
                      '还有 ${_questions.length - 30} 道，存进去就能看到',
                      style: text.bodySmall?.copyWith(color: t.textSoft),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: _questions.isEmpty
          ? null
          : ActionBar(
              safeBottom: true,
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _busy ? null : _save,
                  child: Text('存入题库 ${_questions.length} 道'),
                ),
              ),
            ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.question, required this.index});

  final Question question;
  final int index;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final noAnswer = question.answer.isEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.gutter, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$index. ${question.content}',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: text.bodyLarge?.copyWith(fontSize: 14.5, height: 1.45),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 10,
            runSpacing: 4,
            children: [
              Text(
                noAnswer ? '没有答案' : '答案 ${question.answer}',
                style: text.bodySmall?.copyWith(
                  color: noAnswer ? t.danger : t.success,
                ),
              ),
              Text('${question.options.length} 个选项',
                  style: text.bodySmall?.copyWith(color: t.textSoft)),
              if (question.category.isNotEmpty)
                Text(question.category,
                    style: text.bodySmall?.copyWith(color: t.brand)),
              if (question.analysis.isNotEmpty)
                Text('带解析',
                    style: text.bodySmall?.copyWith(color: t.textSoft)),
            ],
          ),
        ],
      ),
    );
  }
}
