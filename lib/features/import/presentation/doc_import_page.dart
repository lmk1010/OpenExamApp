import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:openexam_app/l10n/app_localizations.dart';
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
    // 这两句提示都在 await 之后才用，先取出来。
    final l = AppL.of(context);
    final settings = await AiSettingsStore.load();
    if (!settings.isConfigured) {
      _toast(l.docNeedAiKey);
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
      _toast(l.importUnreadable);
      return;
    }

    setState(() {
      _busy = true;
      _fileName = file.name;
      _questions = const [];
      _note = AppL.of(context).docOpening;
      _ratio = 0;
    });

    final doc = DocumentText.extract(bytes, fileName: file.name);
    if (doc.isEmpty) {
      setState(() {
        _busy = false;
        _note = AppL.of(context).docNoText;
      });
      return;
    }

    final hint = _subject.text.trim();
    await for (final p in DocParser(settings, l).parse(
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
                padding: EdgeInsets.fromLTRB(
                    AppTheme.gutter, 8, AppTheme.gutter, 10),
                child: Row(
                  children: [
                    PlainIconButton(
                      icon: Icons.arrow_back,
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                    SizedBox(width: 4),
                    // 标题占满剩下的宽度并截断 —— 英文标题比中文长，320 宽的屏上
                    // 顶死会把返回键那一行撑出黄黑条（见 i18n_layout_test）。
                    Expanded(
                      child: Text(
                        AppL.of(context).docImportTitle,
                        style: text.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppTheme.gutter),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppL.of(context).docImportBody,
                      style: text.bodySmall?.copyWith(color: t.textSoft),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _subject,
                      enabled: !_busy,
                      decoration: InputDecoration(
                        labelText: AppL.of(context).docWhichExam,
                        hintText: AppL.of(context).docWhichExamHint,
                        helperText: AppL.of(context).docWhichExamNote,
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _busy ? null : _pick,
                        child: Text(_questions.isEmpty ? AppL.of(context).docPickFile : AppL.of(context).docPickAnother),
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
                SizedBox(height: 22),
                SectionHeader(
                  title: AppL.of(context).docFound,
                  // 后半截是可选后缀，拼在 Dart 里。
                  caption: AppL.of(context).docFoundCount(_questions.length) +
                      (_noAnswer == 0
                          ? ''
                          : AppL.of(context).docNoAnswerCount(_noAnswer)),
                ),
                if (_noAnswer > 0)
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                        AppTheme.gutter, 2, AppTheme.gutter, 6),
                    child: Text(
                      AppL.of(context).docNoAnswerHint,
                      style: text.bodySmall?.copyWith(color: t.textSoft),
                    ),
                  ),
                for (var i = 0; i < _questions.length && i < 30; i++) ...[
                  if (i > 0) RowDivider(),
                  _Preview(question: _questions[i], index: i + 1),
                ],
                if (_questions.length > 30)
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                        AppTheme.gutter, 12, AppTheme.gutter, 0),
                    child: Text(
                      AppL.of(context).docMoreHidden(_questions.length - 30),
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
                  child: Text(AppL.of(context).docSaveCount(_questions.length)),
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
      padding: EdgeInsets.symmetric(
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
          SizedBox(height: 6),
          Wrap(
            spacing: 10,
            runSpacing: 4,
            children: [
              Text(
                noAnswer ? AppL.of(context).docNoAnswer : AppL.of(context).scanAnswerIs(question.answer),
                style: text.bodySmall?.copyWith(
                  color: noAnswer ? t.danger : t.success,
                ),
              ),
              Text(AppL.of(context).scanOptionCount(question.options.length),
                  style: text.bodySmall?.copyWith(color: t.textSoft)),
              if (question.category.isNotEmpty)
                Text(question.category,
                    style: text.bodySmall?.copyWith(color: t.brand)),
              if (question.analysis.isNotEmpty)
                Text(AppL.of(context).docHasAnalysis,
                    style: text.bodySmall?.copyWith(color: t.textSoft)),
            ],
          ),
        ],
      ),
    );
  }
}
