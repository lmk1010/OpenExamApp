import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:openexam_app/l10n/app_localizations.dart';
import 'package:openexam_app/core/ai/ai_settings.dart';
import 'package:openexam_app/core/theme/app_theme.dart';
import 'package:openexam_app/core/theme/app_tokens.dart';
import 'package:openexam_app/features/ai/ai_settings_page.dart';
import 'package:openexam_app/features/essay/data/essay_grader.dart';
import 'package:openexam_app/features/essay/data/essay_repository.dart';
import 'package:openexam_app/features/essay/domain/essay_models.dart';

/// 录入 / 编辑一道申论题。
///
/// 材料抄全是关键 —— AI 全靠它提炼采分点，材料缺一段，批改就会漏一片。
class EssayEditPage extends StatefulWidget {
  const EssayEditPage({super.key, this.existing});

  final EssayPrompt? existing;

  @override
  State<EssayEditPage> createState() => _EssayEditPageState();
}

class _EssayEditPageState extends State<EssayEditPage> {
  final _title = TextEditingController();
  final _province = TextEditingController();
  final _year = TextEditingController();
  final _wordLimit = TextEditingController();
  final _minutes = TextEditingController();
  final _material = TextEditingController();
  final _requirement = TextEditingController();
  final _reference = TextEditingController();
  final _points = TextEditingController();

  EssayType _type = EssayType.guina;
  bool _saving = false;
  bool _recognizing = false;
  bool _showOptional = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _title.text = e.title;
      _type = e.type;
      _province.text = e.province ?? '';
      _year.text = e.year?.toString() ?? '';
      _wordLimit.text = e.wordLimit?.toString() ?? '';
      _minutes.text = e.minutes?.toString() ?? '';
      _material.text = e.material;
      _requirement.text = e.requirement;
      _reference.text = e.referenceAnswer ?? '';
      _points.text = e.scoringPoints.join('\n');
    } else {
      _wordLimit.text = _type.defaultWordLimit.toString();
      _minutes.text = _type.defaultMinutes.toString();
    }
  }

  @override
  void dispose() {
    for (final c in [
      _title, _province, _year, _wordLimit, _minutes,
      _material, _requirement, _reference, _points,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _pickType(EssayType type) {
    setState(() {
      _type = type;
      // 只在用户没改过的时候跟着题型走，改过就别覆盖
      if (_wordLimit.text.isEmpty ||
          EssayType.values.any((t) => t.defaultWordLimit.toString() == _wordLimit.text)) {
        _wordLimit.text = type.defaultWordLimit.toString();
      }
      if (_minutes.text.isEmpty ||
          EssayType.values.any((t) => t.defaultMinutes.toString() == _minutes.text)) {
        _minutes.text = type.defaultMinutes.toString();
      }
    });
  }

  Future<void> _recognize() async {
    // AI 客户端要一份报错文案，而这里在 await 之后 —— 先取出来。
    final l = AppL.of(context);
    final settings = await AiSettingsStore.load();
    if (!settings.isConfigured) {
      if (!mounted) return;
      final go = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(AppL.of(context).essayNeedAi),
          content: Text(AppL.of(context).essayNeedAiBody),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(AppL.of(context).commonLater)),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(AppL.of(context).scanGoSettings)),
          ],
        ),
      );
      if (go == true && mounted) {
        await Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const AiSettingsPage()));
      }
      return;
    }

    final picked = await FilePicker.platform.pickFiles(type: FileType.image);
    final path = picked?.files.single.path;
    if (path == null) return;

    setState(() => _recognizing = true);
    try {
      final bytes = await File(path).readAsBytes();
      final mime = path.toLowerCase().endsWith('.jpg') ||
              path.toLowerCase().endsWith('.jpeg')
          ? 'image/jpeg'
          : 'image/png';
      final result = await EssayGrader(settings, l)
          .recognize(imageBase64: base64Encode(bytes), mimeType: mime);
      if (!mounted) return;

      if (!result.isOk) {
        _toast(result.error ?? AppL.of(context).essayScanFailed);
        return;
      }
      final p = result.value!;
      setState(() {
        if (_title.text.isEmpty) _title.text = p.title;
        _type = p.type;
        if (p.province != null) _province.text = p.province!;
        if (p.year != null) _year.text = p.year!.toString();
        if (p.wordLimit != null) _wordLimit.text = p.wordLimit!.toString();
        _material.text = p.material;
        _requirement.text = p.requirement;
      });
      _toast(AppL.of(context).essayScanDone);
    } finally {
      if (mounted) setState(() => _recognizing = false);
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty ||
        _material.text.trim().isEmpty ||
        _requirement.text.trim().isEmpty) {
      _toast(AppL.of(context).essayNeedFields);
      return;
    }
    setState(() => _saving = true);
    final prompt = EssayPrompt(
      id: widget.existing?.id ?? EssayRepository.newId(),
      title: _title.text.trim(),
      type: _type,
      province: _province.text.trim().isEmpty ? null : _province.text.trim(),
      year: int.tryParse(_year.text.trim()),
      material: _material.text.trim(),
      requirement: _requirement.text.trim(),
      wordLimit: int.tryParse(_wordLimit.text.trim()),
      minutes: int.tryParse(_minutes.text.trim()),
      referenceAnswer:
          _reference.text.trim().isEmpty ? null : _reference.text.trim(),
      scoringPoints: _points.text
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList(),
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
    );
    await EssayRepository.instance.savePrompt(prompt);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? AppL.of(context).essayNewTitle : AppL.of(context).essayEditTitle),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? AppL.of(context).commonSaving : AppL.of(context).commonSave),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.gutter,
          10,
          AppTheme.gutter,
          40,
        ),
        children: [
          OutlinedButton.icon(
            onPressed: _recognizing ? null : _recognize,
            icon: _recognizing
                ? SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.photo_camera_outlined, size: 18),
            label: Text(_recognizing ? AppL.of(context).essayScanning : AppL.of(context).essayScanHint),
          ),
          SizedBox(height: 8),
          Text(AppL.of(context).essayScanCheck,
              style: text.bodySmall),
          SizedBox(height: 22),

          _Label(AppL.of(context).essayType),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final type in EssayType.values)
                GestureDetector(
                  onTap: () => _pickType(type),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: _type == type ? t.brand : t.surface,
                      borderRadius: BorderRadius.circular(999),
                      border:
                          Border.all(color: _type == type ? t.brand : t.line),
                    ),
                    child: Text(
                      type.label,
                      style: text.bodyMedium?.copyWith(
                        color: _type == type ? Colors.white : t.textSoft,
                        fontWeight:
                            _type == type ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 20),

          _Label(AppL.of(context).essayTitleField),
          SizedBox(height: 8),
          _Input(controller: _title, hint: AppL.of(context).essayTitleHint),
          SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Label(AppL.of(context).essayProvince),
                    const SizedBox(height: 8),
                    _Input(controller: _province, hint: '国考'),
                  ],
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Label(AppL.of(context).essayYear),
                    const SizedBox(height: 8),
                    _Input(controller: _year, hint: '2025', number: true),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Label(AppL.of(context).essayWordLimit),
                    const SizedBox(height: 8),
                    _Input(controller: _wordLimit, hint: '200', number: true),
                  ],
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Label(AppL.of(context).essaySuggestedMinutes),
                    const SizedBox(height: 8),
                    _Input(controller: _minutes, hint: '20', number: true),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 18),

          _Label(AppL.of(context).essaySource),
          SizedBox(height: 8),
          _Input(controller: _material, hint: AppL.of(context).essaySourceHint, lines: 10),
          SizedBox(height: 18),

          _Label(AppL.of(context).essayTask),
          SizedBox(height: 8),
          _Input(
            controller: _requirement,
            hint: AppL.of(context).essayTaskHint,
            lines: 3,
          ),
          const SizedBox(height: 20),

          GestureDetector(
            onTap: () => setState(() => _showOptional = !_showOptional),
            child: Row(
              children: [
                Icon(
                  _showOptional ? Icons.expand_less : Icons.expand_more,
                  size: 20,
                  color: t.muted,
                ),
                SizedBox(width: 4),
                Text(AppL.of(context).essayReference,
                    style: text.bodySmall?.copyWith(color: t.textSoft)),
              ],
            ),
          ),
          if (_showOptional) ...[
            SizedBox(height: 14),
            _Label(AppL.of(context).essayModelAnswer),
            SizedBox(height: 8),
            _Input(controller: _reference, hint: AppL.of(context).essayModelAnswerHint, lines: 5),
            SizedBox(height: 18),
            _Label(AppL.of(context).essayMarkPoints),
            SizedBox(height: 8),
            _Input(
              controller: _points,
              hint: AppL.of(context).essayMarkPointsHint,
              lines: 5,
            ),
          ],
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(color: context.tokens.text),
      );
}

class _Input extends StatelessWidget {
  const _Input({
    required this.controller,
    required this.hint,
    this.lines = 1,
    this.number = false,
  });

  final TextEditingController controller;
  final String hint;
  final int lines;
  final bool number;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: t.line),
      ),
      child: TextField(
        controller: controller,
        maxLines: lines,
        minLines: lines,
        keyboardType: number
            ? TextInputType.number
            : (lines > 1 ? TextInputType.multiline : TextInputType.text),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.7),
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        ),
      ),
    );
  }
}
