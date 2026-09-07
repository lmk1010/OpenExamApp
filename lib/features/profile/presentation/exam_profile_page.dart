import 'package:flutter/material.dart';
import 'package:openexam_app/l10n/app_localizations.dart';
import 'package:openexam_app/core/theme/app_theme.dart';
import 'package:openexam_app/core/theme/app_tokens.dart';
import 'package:openexam_app/core/ui/ambient.dart';
import 'package:openexam_app/core/ui/responsive.dart';
import 'package:openexam_app/core/ui/ui_kit.dart';
import 'package:openexam_app/features/profile/domain/exam_profile.dart';

/// 备考目标。
///
/// 这个 app 原本从头到尾按考公写的，申论、词语、行测技巧、报考省份都直接摆在
/// 界面上。备医师、教资的人用不上那些，还得绕开 —— 这一页就是让人把用不着的
/// 关掉，顺便把模考的题量时长调成自己那门考试的。
///
/// 默认那份是"公务员 · 行测申论"且全部开启，所以什么都不做的人看到的界面
/// 跟以前一模一样。
class ExamProfilePage extends StatefulWidget {
  const ExamProfilePage({super.key});

  @override
  State<ExamProfilePage> createState() => _ExamProfilePageState();
}

class _ExamProfilePageState extends State<ExamProfilePage> {
  Future<void> _switchTo(String id) async {
    await ExamProfileStore.switchTo(id);
    if (mounted) setState(() {});
  }

  Future<void> _create() async {
    final name = await _askName(title: AppL.of(context).examNewProfile, hint: AppL.of(context).examNewProfileHint);
    if (name == null) return;
    await ExamProfileStore.create(name);
    if (mounted) setState(() {});
  }

  Future<void> _rename(ExamProfile p) async {
    final name = await _askName(title: AppL.of(context).examRename, initial: p.name);
    if (name == null || name.isEmpty) return;
    await ExamProfileStore.save(p.copyWith(name: name));
    if (mounted) setState(() {});
  }

  Future<void> _remove(ExamProfile p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppL.of(context).examDeleteProfile),
        content: Text(AppL.of(context).examDeleteProfileBody(p.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(AppL.of(context).commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(AppL.of(context).commonDelete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ExamProfileStore.remove(p.id);
    if (mounted) setState(() {});
  }

  Future<String?> _askName({
    required String title,
    String initial = '',
    String? hint,
  }) {
    final ctrl = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
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
      ),
    ).whenComplete(ctrl.dispose);
  }

  Future<void> _toggle(ExamFeature f, bool on) async {
    final p = ExamProfileStore.current;
    final next = {...p.features};
    on ? next.add(f) : next.remove(f);
    await ExamProfileStore.save(p.copyWith(features: next));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final current = ExamProfileStore.current;
    final all = ExamProfileStore.all;

    return Scaffold(
      backgroundColor: t.gradient.last,
      body: SafeArea(
        child: ReadableWidth(
          child: ListView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.paddingOf(context).bottom + 28,
            ),
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                    AppTheme.gutter, 8, AppTheme.gutter, 4),
                child: Row(
                  children: [
                    PlainIconButton(
                      icon: Icons.arrow_back,
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                    SizedBox(width: 4),
                    Expanded(
                        child: Text(AppL.of(context).examWhichModules, style: text.titleMedium)),
                    IconButton(
                      tooltip: AppL.of(context).commonNew,
                      icon: const Icon(Icons.add, size: 22),
                      color: t.brand,
                      onPressed: _create,
                    ),
                  ],
                ),
              ),

              // 只有一份的时候不必列成"可切换的列表"，那会让人以为少了点什么
              if (all.length > 1) ...[
                SectionHeader(title: AppL.of(context).examWhichExam),
                for (final p in all)
                  _ProfileRow(
                    profile: p,
                    selected: p.id == current.id,
                    onTap: () => _switchTo(p.id),
                    onRename: () => _rename(p),
                    onDelete: all.length > 1 ? () => _remove(p) : null,
                  ),
                const SizedBox(height: 8),
              ],

              Padding(
                padding: EdgeInsets.fromLTRB(
                    AppTheme.gutter, 0, AppTheme.gutter, 12),
                child: Text(
                  AppL.of(context).examModulesNote,
                  style: text.bodySmall?.copyWith(color: t.textSoft),
                ),
              ),
              for (final f in ExamFeature.values)
                SwitchListTile(
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: AppTheme.gutter),
                  title: Text(f.label, style: text.titleSmall),
                  subtitle: Text(f.hint, style: text.bodySmall),
                  value: current.has(f),
                  onChanged: (v) => _toggle(f, v),
                ),

              Padding(
                padding: EdgeInsets.fromLTRB(
                    AppTheme.gutter, 22, AppTheme.gutter, 0),
                child: Text(
                  all.length > 1
                      ? AppL.of(context).examSharedBank
                      : AppL.of(context).examTwoProfiles,
                  style: text.bodySmall?.copyWith(color: t.textSoft),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.profile,
    required this.selected,
    required this.onTap,
    required this.onRename,
    this.onDelete,
  });

  final ExamProfile profile;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final on = profile.features.length;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.gutter, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: selected ? t.brand : t.accentSoft,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                selected ? Icons.check : Icons.school_outlined,
                size: 19,
                color: selected ? t.onAccent : t.onAccentSoft,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleSmall
                        ?.copyWith(color: selected ? t.brand : t.text),
                  ),
                  SizedBox(height: 2),
                  Text(
                    on == 0 ? AppL.of(context).examGenericOnly : AppL.of(context).examExtrasOn(on),
                    style: text.bodySmall?.copyWith(color: t.textSoft),
                  ),
                ],
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: Icon(Icons.drive_file_rename_outline,
                  size: 18, color: t.textSoft),
              onPressed: onRename,
            ),
            if (onDelete != null)
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.delete_outline, size: 18, color: t.textSoft),
                onPressed: onDelete,
              ),
          ],
        ),
      ),
    );
  }
}
