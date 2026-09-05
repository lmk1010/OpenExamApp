import 'package:flutter/material.dart';
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

String studyActionLabel(StudyAction action) {
  switch (action) {
    case StudyAction.practice:
      return '题型练习';
    case StudyAction.daily:
      return '每日一练';
    case StudyAction.mock:
      return '限时模考';
    case StudyAction.wrong:
      return '错题重练';
    case StudyAction.adaptive:
      return '弱项强化';
    case StudyAction.note:
      return '备忘 / 手写';
    case StudyAction.check:
      return '打卡';
    case StudyAction.openWrongBook:
      return '打开错题本';
  }
}

String studyActionHint(StudyAction action) {
  switch (action) {
    case StudyAction.practice:
      return '按题型抽题练习';
    case StudyAction.daily:
      return '今天的固定卷';
    case StudyAction.mock:
      return '50 题 · 可设定分钟';
    case StudyAction.wrong:
      return '从错题里抽练';
    case StudyAction.adaptive:
      return '按薄弱模块抽题';
    case StudyAction.note:
      return '勾选完成即可，不自动开练';
    case StudyAction.check:
      return '做完打个勾，不跳任何页面';
    case StudyAction.openWrongBook:
      return '跳到错题本整理';
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
    _action = i?.action ?? StudyAction.note;
    _category = i?.category ?? kGongkaoCategories.first.key;
    _timed = i?.timed ?? false;
    _custom = i?.custom ?? widget.create;
    _repeat = i?.repeat ?? RepeatRule.once;
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
      title: _title.text.trim().isEmpty ? '未命名任务' : _title.text.trim(),
      subtitle: _subtitle.text.trim().isEmpty ? null : _subtitle.text.trim(),
      action: _action,
      category: _needsCategory ? _category : null,
      count: _needsCount ? (count ?? 20) : null,
      timed: _timed || minutes != null,
      minutes: minutes,
      custom: _custom,
      repeat: _custom ? _repeat : RepeatRule.once,
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
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: t.lineSoft)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.create ? '添加安排' : '任务安排',
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
                        '保存',
                        style: text.labelMedium?.copyWith(color: t.brand),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  children: [
                    TextField(
                      controller: _title,
                      decoration: const InputDecoration(
                        labelText: '名称',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _subtitle,
                      decoration: const InputDecoration(
                        labelText: '备注 / 时段（可选）',
                        hintText: '例如 20:10–21:20',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('安排类型', style: text.titleSmall),
                    const SizedBox(height: 6),
                    for (final action in StudyAction.values)
                      _ActionTile(
                        selected: _action == action,
                        title: studyActionLabel(action),
                        subtitle: studyActionHint(action),
                        onTap: () => setState(() => _action = action),
                      ),
                    if (_needsCategory) ...[
                      const SizedBox(height: 12),
                      Text('题型', style: text.titleSmall),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final c in kGongkaoCategories)
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
                        decoration: const InputDecoration(
                          labelText: '题量',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ],
                    // 重复只对自己加的任务有意义 —— 模板任务本来就按星期几排。
                    if (_custom) ...[
                      const SizedBox(height: 16),
                      Text('重复', style: text.titleSmall),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final rule in RepeatRule.values)
                            _RepeatChip(
                              label: rule.label,
                              on: _repeat == rule,
                              onTap: () => setState(() => _repeat = rule),
                            ),
                        ],
                      ),
                    ],
                    if (_action != StudyAction.note &&
                        _action != StudyAction.check &&
                        _action != StudyAction.openWrongBook) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: _minutes,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: '限时（分钟，可选）',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('按题量软限时', style: text.titleSmall),
                        subtitle: Text(
                          '未填分钟时，按题量估算时长',
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
                            .pop(const StudyTaskEditResult.delete()),
                        child: Text(
                          '删除此安排',
                          style: text.labelMedium?.copyWith(color: t.danger),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      '点「开始」才会进入练习；点这一行只改安排，避免误触。',
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
              Text(task.title, style: text.titleMedium),
              const SizedBox(height: 4),
              Text(
                studyActionLabel(task.action),
                style: text.bodySmall,
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.edit_outlined, size: 20),
                title: Text('编辑安排', style: text.titleSmall),
                onTap: () {
                  Navigator.of(ctx).pop();
                  onEdit();
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.drive_file_rename_outline, size: 20),
                title: Text('重命名', style: text.titleSmall),
                onTap: () {
                  Navigator.of(ctx).pop();
                  onRename();
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.delete_outline, size: 20, color: t.danger),
                title: Text(
                  '删除',
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
}) {
  final ctrl = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: const Text('重命名'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            isDense: true,
          ),
          onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
            child: const Text('确定'),
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
