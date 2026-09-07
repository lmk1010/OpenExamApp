import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:openexam_app/l10n/app_localizations.dart';
import 'package:openexam_app/core/theme/app_theme.dart';
import 'package:openexam_app/core/theme/app_tokens.dart';
import 'package:openexam_app/core/ui/glass.dart';
import 'package:openexam_app/core/ui/stroke_icons.dart';
import 'package:openexam_app/core/ui/ui_kit.dart';
import 'package:openexam_app/data/db/app_database.dart';
import 'package:openexam_app/features/backup/prefs_backup.dart';
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
    // 这一串提示都在 await 之后才用，先把本地化对象取出来。
    final l = AppL.of(context);
    setState(() => _busy = true);
    try {
      final data = await AppDatabase.instance.exportUserData();
      // 学习计划和考试日期存在 SharedPreferences 里，不在数据库里 ——
      // 以前备份漏了这一整块，换台手机计划就没了。
      data['settings'] = await PrefsBackup.export();
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
        _say(l.backupExportedTo(name));
        return;
      }
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$name');
      await file.writeAsString(json);
      _say(l.wrongExportSavedDocs(name));
    } catch (e) {
      _say(l.wrongExportFailed('$e'), failed: true);
    }
  }

  Future<void> _import() async {
    // 这一串提示都在 await 之后才用，先把本地化对象取出来。
    final l = AppL.of(context);
    final ok = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ConfirmSheet(
        title: l.backupRestore,
        message: l.backupRestoreBody,
        confirm: l.backupPickFile,
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
        _say(l.backupUnreadable, failed: true);
        return;
      }
      final data = jsonDecode(utf8.decode(bytes));
      if (data is! Map<String, dynamic> || data['logs'] == null) {
        _say(l.backupNotOurs, failed: true);
        return;
      }
      final restored = await AppDatabase.instance.importUserData(data);
      // 老备份没有 settings 这一节，import 会当 0 条处理，不清空现有计划。
      await PrefsBackup.import(data['settings']);
      await _counts();
      _say(l.backupRestored(restored));
    } catch (e) {
      _say(l.backupRestoreFailed('$e'), failed: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: 21),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        titleSpacing: 0,
        title: Text(AppL.of(context).profileBackup),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(AppTheme.gutter, 8, AppTheme.gutter, 28),
        children: [
          Text(
            AppL.of(context).backupIntro,
            style: text.bodyMedium,
          ),
          SizedBox(height: 22),
          Container(
            padding: EdgeInsets.symmetric(vertical: 16),
            decoration: GlassDecor.panel(t, radius: 20),
            child: Row(
              children: [
                _Figure(value: '$_logs', label: AppL.of(context).backupAnswers),
                _Figure(value: '$_reports', label: AppL.of(context).backupReports),
                _Figure(value: '$_marks', label: AppL.of(context).profileMarks),
                _Figure(value: '$_notes', label: AppL.of(context).profileNotes),
              ],
            ),
          ),
          if (_message != null) ...[
            SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  _failed ? Icons.error_outline : Icons.check_circle_outline,
                  size: 18,
                  color: _failed ? t.danger : t.success,
                ),
                SizedBox(width: 10),
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
          SizedBox(height: 26),
          _ActionRow(
            icon: AppIcon.download,
            title: AppL.of(context).backupExport,
            desc: AppL.of(context).backupExportHint,
            onTap: _busy ? null : _export,
          ),
          RowDivider(indent: 0),
          _ActionRow(
            icon: AppIcon.replay,
            title: AppL.of(context).backupFromFile,
            desc: AppL.of(context).backupFromFileHint,
            onTap: _busy ? null : _import,
          ),
          SizedBox(height: 22),
          Text(
            AppL.of(context).backupSizeNote,
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
                    child: Text(AppL.of(context).commonCancel),
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
