import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:openexam_app/core/theme/app_theme.dart';
import 'package:openexam_app/core/theme/app_tokens.dart';
import 'package:openexam_app/core/ui/ui_kit.dart';
import 'package:openexam_app/data/db/app_database.dart';
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
        allowedExtensions: const ['json', 'csv', 'txt'],
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
      final questions = QuestionImporter.parseBytes(bytes, fileName: file.name);
      if (questions.isEmpty) {
        _fail('这个文件里没找到题目，看看下面的格式说明');
        return;
      }
      final count = await AppDatabase.instance.importQuestions(questions);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _failed = false;
        _result = '成功导入 $count 题，去「练习」页就能刷了';
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
                    Text('三步就好，题目只存在这台手机上', style: text.bodySmall?.copyWith(fontSize: 13)),
                  ],
                ),
              ),
              if (_result != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppTheme.gutter, 0, AppTheme.gutter, 22),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        _failed ? Icons.error_outline : Icons.check_circle_outline,
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
                desc: '手机里存一个 JSON 或 CSV 文件，微信/QQ 收到的也行，先保存到「文件」里。',
              ),
              const _Step(
                index: 2,
                title: '点下面的按钮选中它',
                desc: '会打开系统文件选择器，选中文件就自动解析，不用填任何东西。',
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
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.gutter),
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
                  padding: const EdgeInsets.fromLTRB(AppTheme.gutter, 4, AppTheme.gutter, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '支持 JSON / CSV / TXT。每道题至少要有题干、选项和答案：',
                        style: text.bodyMedium,
                      ),
                      const SizedBox(height: 14),
                      Surface(
                        fill: true,
                        radius: 16,
                        padding: const EdgeInsets.all(14),
                        child: Text(
                          '[\n  {\n    "content": "题干",\n    "options": [\n      {"key": "A", "text": "选项一"},\n      {"key": "B", "text": "选项二"}\n    ],\n    "answer": "A",\n    "category": "yanyu",\n    "analysis": "解析（选填）"\n  }\n]',
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
                        'category 可填 yanyu 言语 / shuliang 数量 / panduan 判断 / ziliao 资料 / changshi 常识，'
                        '不填会归到「综合」。',
                        style: text.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '内置题来自 OpenExam 桌面端种子库。商业题库请自行合法导入，App 不会爬取第三方付费内容。',
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
                    child: Container(width: 1.5, color: t.brand.withValues(alpha: 0.16)),
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
                    Text(desc, style: text.bodyMedium?.copyWith(fontSize: 13.5)),
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
