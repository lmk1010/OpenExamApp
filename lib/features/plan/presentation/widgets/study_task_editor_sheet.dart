import 'package:flutter/material.dart';
import 'package:openexam_app/l10n/app_localizations.dart';
import 'package:openexam_app/core/constants/categories.dart';
import 'package:openexam_app/core/theme/app_tokens.dart';
import 'package:openexam_app/features/plan/domain/models/study_task.dart';

/// Result of editing / creating a study task.
class StudyTaskEditResult {
  const StudyTaskEditResult.save(this.task) : delete = false;
  const StudyTaskEditResult.delete()
      : task = null,
        delete = true;

  final StudyTask? task;
  final bool delete;
}

String studyActionLabel(BuildContext context, StudyAction action) {
  switch (action) {
    case StudyAction.practice:
      return AppL.of(context).taskCatPractice;
    case StudyAction.daily:
      return AppL.of(context).homeDaily;
    case StudyAction.mock:
      return AppL.of(context).homeMock;
    case StudyAction.wrong:
      return AppL.of(context).homeRedoWrong;
    case StudyAction.adaptive:
      return AppL.of(context).homeWeakDrill;
    case StudyAction.note:
      return AppL.of(context).taskManual;
    case StudyAction.vocab:
      return AppL.of(context).taskVocab;
    case StudyAction.check:
      return AppL.of(context).taskCheckin;
    case StudyAction.openWrongBook:
      return AppL.of(context).taskOpenWrong;
  }
}

String studyActionHint(BuildContext context, StudyAction action) {
  switch (action) {
    case StudyAction.practice:
      return AppL.of(context).taskCatPracticeHint;
    case StudyAction.daily:
      return AppL.of(context).homeDailyHint;
    case StudyAction.mock:
      return AppL.of(context).taskMockHint;
    case StudyAction.wrong:
      return AppL.of(context).taskWrongHint;
    case StudyAction.adaptive:
      return AppL.of(context).taskWeakHint;
    case StudyAction.note:
      return AppL.of(context).taskManualHint;
    case StudyAction.vocab:
      return AppL.of(context).taskVocabHint;
    case StudyAction.check:
      return AppL.of(context).taskCheckinHint;
    case StudyAction.openWrongBook:
      return AppL.of(context).taskOpenWrongHint;
  }
}

Future<StudyTaskEditResult?> showStudyTaskEditor(
  BuildContext context, {
  StudyTask? initial,
  bool create = false,
}) {
  return showModalBottomSheet<StudyTaskEditResult>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _StudyTaskEditorSheet(
      initial: initial,
      create: create,
    ),
  );
}

class _StudyTaskEditorSheet extends StatefulWidget {
  const _StudyTaskEditorSheet({this.initial, this.create = false});

  final StudyTask? initial;
  final bool create;

  @override
  State<_StudyTaskEditorSheet> createState() => _StudyTaskEditorSheetState();
}

class _StudyTaskEditorSheetState extends State<_StudyTaskEditorSheet> {
  late final TextEditingController _title;
  late final TextEditingController _subtitle;
  late final TextEditingController _count;
  late final TextEditingController _minutes;
  late StudyAction _action;
  String? _category;
  late bool _timed;
  late bool _custom;
  late RepeatRule _repeat;
  late bool _advanced;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _title = TextEditingController(text: i?.title ?? '');
    _subtitle = TextEditingController(text: i?.subtitle ?? '');
    _count = TextEditingController(text: (i?.count ?? 20).toString());
    _minutes = TextEditingController(
      text: i?.minutes != null ? i!.minutes.toString() : '',
    );
    _action = i?.action ?? StudyAction.check;
    // 已经是做题任务的，进来就把高级区摊开；纯打卡的收着
    _advanced = i != null && i.action != StudyAction.check;
    _category = i?.category ?? CategoryRegistry.current.first.key;
    _timed = i?.timed ?? false;
    _custom = i?.custom ?? widget.create;
    _repeat = i?.repeat ?? (widget.create ? RepeatRule.daily : RepeatRule.once);
  }

  @override
  void dispose() {
    _title.dispose();
    _subtitle.dispose();
    _count.dispose();
    _minutes.dispose();
    super.dispose();
  }

  bool get _needsCategory => _action == StudyAction.practice;
  bool get _needsCount =>
      _action == StudyAction.practice ||
      _action == StudyAction.wrong ||
      _action == StudyAction.adaptive;

  StudyTask _buildTask() {
    final id = widget.initial?.id ??
        'c_${DateTime.now().millisecondsSinceEpoch}';
    final count = int.tryParse(_count.text.trim());
    final minutes = int.tryParse(_minutes.text.trim());
    return StudyTask(
      id: id,
      title: _title.text.trim().isEmpty ? AppL.of(context).taskUntitled : _title.text.trim(),
      subtitle: _subtitle.text.trim().isEmpty ? null : _subtitle.text.trim(),
      action: _action,
      category: _needsCategory ? _category : null,
      count: _needsCount ? (count ?? 20) : null,
      timed: _timed || minutes != null,
      minutes: minutes,
      custom: _custom,
      repeat: _repeat,
      startedOn: widget.initial?.startedOn,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        ),
        decoration: BoxDecoration(
          color: t.gradient.last,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: t.lineSoft)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.create ? AppL.of(context).planAddTitle : AppL.of(context).taskEdit,
                        style: text.titleMedium,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        final task = _buildTask();
                        if (task.title.isEmpty) return;
                        Navigator.of(context).pop(StudyTaskEditResult.save(task));
                      },
                      child: Text(
                        AppL.of(context).commonSave,
                        style: text.labelMedium?.copyWith(color: t.brand),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 16),
                  children: [
                    TextField(
                      controller: _title,
                      autofocus: widget.create,
                      decoration: InputDecoration(
                        labelText: AppL.of(context).taskWhat,
                        hintText: AppL.of(context).taskWhatHint,
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    SizedBox(height: 18),
                    Text(AppL.of(context).taskHowOften, style: text.titleSmall),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final rule in RepeatRule.values)
                          _RepeatChip(
                            label: rule.label(AppL.of(context)),
                            on: _repeat == rule,
                            onTap: () => setState(() => _repeat = rule),
                          ),
                      ],
                    ),
                    SizedBox(height: 6),
                    Text(
                      _repeat == RepeatRule.once
                          ? AppL.of(context).taskOnceOnly
                          : AppL.of(context).taskEditForever,
                      style: text.bodySmall?.copyWith(color: t.textSoft),
                    ),

                    // 到这儿一条待办就齐了。下面全是"顺便还想练题"才用得上的东西，
                    // 平铺出来会让"加个待办"这么点事看着像填表。
                    const SizedBox(height: 18),
                    InkWell(
                      onTap: () => setState(() => _advanced = !_advanced),
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Icon(
                              _advanced
                                  ? Icons.keyboard_arrow_down
                                  : Icons.keyboard_arrow_right,
                              size: 20,
                              color: t.textSoft,
                            ),
                            SizedBox(width: 4),
                            Text(AppL.of(context).taskAlsoPractise, style: text.titleSmall),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _advanced ? '' : AppL.of(context).taskAlsoPractiseHint,
                                style: text.bodySmall?.copyWith(color: t.textSoft),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_advanced) ...[
                      const SizedBox(height: 4),
                      for (final action in StudyAction.values)
                        _ActionTile(
                          selected: _action == action,
                          title: studyActionLabel(context, action),
                          subtitle: studyActionHint(context, action),
                          onTap: () => setState(() => _action = action),
                        ),
                      if (_needsCategory) ...[
                        SizedBox(height: 12),
                        Text(AppL.of(context).taskType, style: text.titleSmall),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final c in CategoryRegistry.current)
                              ChoiceChip(
                                label: Text(c.short),
                                selected: _category == c.key,
                                onSelected: (_) =>
                                    setState(() => _category = c.key),
                              ),
                          ],
                        ),
                      ],
                      if (_needsCount) ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: _count,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: AppL.of(context).taskCount,
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ],
                      SizedBox(height: 12),
                      TextField(
                        controller: _subtitle,
                        decoration: InputDecoration(
                          labelText: AppL.of(context).taskNote,
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ],
                    if (_advanced &&
                        _action != StudyAction.note &&
                        _action != StudyAction.check &&
                        _action != StudyAction.openWrongBook) ...[
                      SizedBox(height: 12),
                      TextField(
                        controller: _minutes,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: AppL.of(context).taskMinutes,
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(AppL.of(context).taskSoftLimit, style: text.titleSmall),
                        subtitle: Text(
                          AppL.of(context).taskSoftLimitHint,
                          style: text.bodySmall,
                        ),
                        value: _timed,
                        onChanged: (v) => setState(() => _timed = v),
                      ),
                    ],
                    if (!widget.create) ...[
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => Navigator.of(context)
                            .pop(StudyTaskEditResult.delete()),
                        child: Text(
                          AppL.of(context).taskDelete,
                          style: text.labelMedium?.copyWith(color: t.danger),
                        ),
                      ),
                    ],
                    SizedBox(height: 8),
                    Text(
                      AppL.of(context).taskTapHint,
                      style: text.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: text.titleSmall?.copyWith(
                      color: selected ? t.brand : t.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: text.bodySmall),
                ],
              ),
            ),
            if (selected) Icon(Icons.check, size: 18, color: t.brand),
          ],
        ),
      ),
    );
  }
}

Future<void> showStudyTaskActions(
  BuildContext context, {
  required StudyTask task,
  required VoidCallback onEdit,
  required VoidCallback onRename,
  required VoidCallback onDelete,
}) {
  final t = context.tokens;
  final text = Theme.of(context).textTheme;
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return Container(
        decoration: BoxDecoration(
          color: t.gradient.last,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: t.lineSoft)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task.displayTitle(AppL.of(context)),
                style: text.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                studyActionLabel(context, task.action),
                style: text.bodySmall,
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.edit_outlined, size: 20),
                title: Text(AppL.of(context).taskEditTitle, style: text.titleSmall),
                onTap: () {
                  Navigator.of(ctx).pop();
                  onEdit();
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.drive_file_rename_outline, size: 20),
                title: Text(AppL.of(context).commonRename, style: text.titleSmall),
                onTap: () {
                  Navigator.of(ctx).pop();
                  onRename();
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.delete_outline, size: 20, color: t.danger),
                title: Text(
                  AppL.of(context).commonDelete,
                  style: text.titleSmall?.copyWith(color: t.danger),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  onDelete();
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<String?> showRenameTaskDialog(
  BuildContext context, {
  required String initial,
  /// 默认值不能是方法调用，null 表示"用当前语言的『重命名』"。
  String? title,
  String? hint,
}) {
  final ctrl = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: Text(title ?? AppL.of(ctx).commonRename),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: hint,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppL.of(context).commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
            child: Text(AppL.of(context).commonConfirm),
          ),
        ],
      );
    },
  ).whenComplete(ctrl.dispose);
}

/// 重复规则的选项。跟别处的 chip 一样：选中走动作色，全圆角。
class _RepeatChip extends StatelessWidget {
  const _RepeatChip({
    required this.label,
    required this.on,
    required this.onTap,
  });

  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: on ? t.accent : t.surfaceAlt,
          borderRadius: BorderRadius.circular(99),
        ),
        // Container 有 alignment 就会撑满宽度，Wrap 里每颗会各占一行
        child: Center(
          widthFactor: 1,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: on ? FontWeight.w700 : FontWeight.w500,
              height: 1,
              color: on ? t.onAccent : t.textSoft,
            ),
          ),
        ),
      ),
    );
  }
}
