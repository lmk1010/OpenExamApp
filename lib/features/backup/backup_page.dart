import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:openexam_app/core/theme/app_theme.dart';
import 'package:openexam_app/core/theme/app_tokens.dart';
import 'package:openexam_app/core/ui/glass.dart';
import 'package:openexam_app/core/ui/stroke_icons.dart';
import 'package:openexam_app/core/ui/ui_kit.dart';
import 'package:openexam_app/data/db/app_database.dart';
import 'package:path_provider/path_provider.dart';

/// 备份与恢复 — the app has no account, so换手机 or 清数据 would otherwise lose
/// every answer, note and report. One JSON file covers all of it.
class BackupPage extends StatefulWidget {
  const BackupPage({super.key});

  @override
  State<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {
  bool _busy = false;
  String? _message;
  bool _failed = false;

  int _logs = 0;
  int _marks = 0;
  int _notes = 0;
  int _reports = 0;

  @override
  void initState() {
    super.initState();
    _counts();
  }

  Future<void> _counts() async {
    final db = AppDatabase.instance;
    final logs = await db.countAnswers();
    final marks = await db.countMarked();
    final notes = await db.countNotes();
    final reports = await db.listReports(limit: 500);
    if (!mounted) return;
    setState(() {
      _logs = logs;
      _marks = marks;
      _notes = notes;
      _reports = reports.length;
    });
  }

  void _say(String message, {bool failed = false}) {
    if (!mounted) return;
    setState(() {
      _busy = false;
      _failed = failed;
      _message = message;
    });
  }

  Future<void> _export() async {
    setState(() => _busy = true);
    try {
      final data = await AppDatabase.instance.exportUserData();
      final json = const JsonEncoder.withIndent('  ').convert(data);
      final now = DateTime.now();
      final name = 'openexam-backup-'
          '${now.year}${now.month.toString().padLeft(2, '0')}'
          '${now.day.toString().padLeft(2, '0')}-'
          '${now.hour.toString().padLeft(2, '0')}'
          '${now.minute.toString().padLeft(2, '0')}.json';

      // Let the user put it wherever they keep files; fall back to the app's
      // documents folder if the picker is unavailable.
      final path = await FilePicker.platform.saveFile(
        fileName: name,
        bytes: utf8.encode(json),
      );
      if (path != null) {
        _say('已导出到 $name');
        return;
      }
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$name');
      await file.writeAsString(json);
      _say('已保存到 App 文档目录：$name');
    } catch (e) {
      _say('导出失败：$e', failed: true);
    }
  }

  Future<void> _import() async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ConfirmSheet(
        title: '恢复备份',
        message: '恢复会用备份中的答题记录与成绩报告覆盖当前数据，收藏、笔记、错因会合并。'
            '题库本身不受影响。',
        confirm: '选择文件恢复',
      ),
    );
    if (ok != true) return;

    setState(() => _busy = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['json'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) {
        setState(() => _busy = false);
        return;
      }
      final file = result.files.first;
      final bytes = file.bytes ??
          (file.path == null ? null : await File(file.path!).readAsBytes());
      if (bytes == null) {
        _say('读不到这个文件', failed: true);
        return;
      }
      final data = jsonDecode(utf8.decode(bytes));
      if (data is! Map<String, dynamic> || data['logs'] == null) {
        _say('这不是 OpenExam 的备份文件', failed: true);
        return;
      }
      final restored = await AppDatabase.instance.importUserData(data);
      await _counts();
      _say('已恢复 $restored 条记录');
    } catch (e) {
      _say('恢复失败：$e', failed: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 21),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        titleSpacing: 0,
        title: const Text('备份与恢复'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppTheme.gutter, 8, AppTheme.gutter, 28),
        children: [
          Text(
            '这个 App 没有账号，数据只在本机。换手机或清除数据前，'
            '导出一份备份就能完整带走。',
            style: text.bodyMedium,
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: GlassDecor.panel(t, radius: 20),
            child: Row(
              children: [
                _Figure(value: '$_logs', label: '答题记录'),
                _Figure(value: '$_reports', label: '成绩报告'),
                _Figure(value: '$_marks', label: '收藏'),
                _Figure(value: '$_notes', label: '笔记'),
              ],
            ),
          ),
          if (_message != null) ...[
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  _failed ? Icons.error_outline : Icons.check_circle_outline,
                  size: 18,
                  color: _failed ? t.danger : t.success,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _message!,
                    style: text.bodyMedium?.copyWith(
                      color: _failed ? t.danger : t.success,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 26),
          _ActionRow(
            icon: AppIcon.download,
            title: '导出备份',
            desc: '生成一个 JSON 文件，含答题记录、成绩报告、收藏、笔记与错因',
            onTap: _busy ? null : _export,
          ),
          const RowDivider(indent: 0),
          _ActionRow(
            icon: AppIcon.replay,
            title: '从备份恢复',
            desc: '答题记录与成绩报告会被覆盖，收藏、笔记、错因合并保留',
            onTap: _busy ? null : _import,
          ),
          const SizedBox(height: 22),
          Text(
            '备份文件不含题库（题目已随 App 内置），所以体积很小，'
            '可以直接发到微信或存进网盘。',
            style: text.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Expanded(
      child: Column(
        children: [
          Text(value, style: text.headlineSmall?.copyWith(fontSize: 19)),
          const SizedBox(height: 5),
          Text(label, style: text.bodySmall?.copyWith(fontSize: 11.5)),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.title,
    required this.desc,
    required this.onTap,
  });

  final AppIcon icon;
  final String title;
  final String desc;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    return Opacity(
      opacity: onTap == null ? 0.5 : 1,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: StrokeIcon(icon, size: 20, color: t.brand),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: text.titleSmall),
                    const SizedBox(height: 5),
                    Text(desc, style: text.bodySmall),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Icon(Icons.chevron_right, size: 17, color: t.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfirmSheet extends StatelessWidget {
  const _ConfirmSheet({
    required this.title,
    required this.message,
    required this.confirm,
  });

  final String title;
  final String message;
  final String confirm;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        color: t.gradient.last,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: t.lineSoft)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: text.titleMedium),
            const SizedBox(height: 12),
            Text(message, style: text.bodyMedium),
            const SizedBox(height: 20),
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
                    child: Text(confirm),
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
