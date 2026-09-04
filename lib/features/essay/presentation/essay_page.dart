import 'package:flutter/material.dart';
import 'package:openexam_app/core/theme/app_theme.dart';
import 'package:openexam_app/core/theme/app_tokens.dart';
import 'package:openexam_app/core/ui/ui_kit.dart';
import 'package:openexam_app/features/essay/data/essay_repository.dart';
import 'package:openexam_app/features/essay/domain/essay_models.dart';
import 'package:openexam_app/features/essay/presentation/essay_edit_page.dart';
import 'package:openexam_app/features/essay/presentation/essay_write_page.dart';

/// 申论 —— 一天一道，写完交给 AI 逐条对采分点。
///
/// 种子题库里全是行测客观题，申论一道都没有，所以题目要用户自己录进来
/// （手打或拍照识别）。这也是为什么空态要把话说清楚。
class EssayPage extends StatefulWidget {
  const EssayPage({super.key, this.initialType});

  final EssayType? initialType;

  @override
  State<EssayPage> createState() => _EssayPageState();
}

class _EssayPageState extends State<EssayPage> {
  bool _loading = true;
  List<EssayPrompt> _prompts = const [];
  EssayType? _filter;

  @override
  void initState() {
    super.initState();
    _filter = widget.initialType;
    _load();
  }

  Future<void> _load() async {
    final list = await EssayRepository.instance.listPrompts(type: _filter);
    if (!mounted) return;
    setState(() {
      _prompts = list;
      _loading = false;
    });
  }

  Future<void> _create() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const EssayEditPage()),
    );
    if (saved == true) _load();
  }

  Future<void> _open(EssayPrompt prompt) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EssayWritePage(prompt: prompt)),
    );
    if (mounted) _load();
  }

  Future<void> _delete(EssayPrompt prompt) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除这道题？'),
        content: Text('「${prompt.title}」连同它的作答记录会一起删掉。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await EssayRepository.instance.deletePrompt(prompt.id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return Scaffold(
      appBar: AppBar(
        title: const Text('申论'),
        actions: [
          IconButton(
            tooltip: '录入题目',
            onPressed: _create,
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 46,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.gutter),
              children: [
                _TypeChip(
                  label: '全部',
                  selected: _filter == null,
                  onTap: () {
                    setState(() => _filter = null);
                    _load();
                  },
                ),
                for (final type in EssayType.values)
                  _TypeChip(
                    label: type.label,
                    selected: _filter == type,
                    onTap: () {
                      setState(() => _filter = _filter == type ? null : type);
                      _load();
                    },
                  ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const LoadingState()
                : _prompts.isEmpty
                    ? _EmptyEssay(onCreate: _create, filtered: _filter != null)
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          AppTheme.gutter,
                          8,
                          AppTheme.gutter,
                          32,
                        ),
                        itemCount: _prompts.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _PromptCard(
                          prompt: _prompts[i],
                          onTap: () => _open(_prompts[i]),
                          onDelete: () => _delete(_prompts[i]),
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: _prompts.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _create,
              backgroundColor: t.accent,
              foregroundColor: t.onAccent,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('录入题目'),
            ),
    );
  }
}

class _EmptyEssay extends StatelessWidget {
  const _EmptyEssay({required this.onCreate, required this.filtered});

  final VoidCallback onCreate;
  final bool filtered;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: EmptyState(
            icon: Icons.description_outlined,
            art: EmptyArt.essay,
            title: filtered ? '这个题型还没有题' : '还没有申论题',
            message: filtered
                ? '换个题型看看，或者录一道新的。'
                : '内置题库全是行测客观题，申论得自己录。\n拍张照让 AI 认，或者直接粘贴材料和题干。',
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.gutter,
            0,
            AppTheme.gutter,
            40,
          ),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onCreate,
              child: const Text('录入第一道'),
            ),
          ),
        ),
      ],
    );
  }
}

class _PromptCard extends StatelessWidget {
  const _PromptCard({
    required this.prompt,
    required this.onTap,
    required this.onDelete,
  });

  final EssayPrompt prompt;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    final meta = <String>[
      prompt.type.label,
      if (prompt.province != null && prompt.province!.isNotEmpty) prompt.province!,
      if (prompt.year != null) '${prompt.year} 年',
      if (prompt.wordLimit != null) '${prompt.wordLimit} 字内',
    ];

    return GestureDetector(
      onTap: onTap,
      onLongPress: onDelete,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 15, 14, 15),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: t.shadow,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prompt.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleSmall?.copyWith(color: t.text),
                  ),
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      for (final m in meta)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: m == prompt.type.label
                                ? t.accentSoft
                                : t.surfaceAlt,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            m,
                            style: text.bodySmall?.copyWith(
                              fontSize: 11,
                              color: m == prompt.type.label
                                  ? t.onAccentSoft
                                  : t.muted,
                              fontWeight: m == prompt.type.label
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (prompt.attemptCount > 0)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    prompt.bestScore == null
                        ? '—'
                        : prompt.bestScore!.toStringAsFixed(
                            prompt.bestScore! % 1 == 0 ? 0 : 1,
                          ),
                    style: text.titleMedium?.copyWith(
                      fontSize: 20,
                      color: t.success,
                      fontFeatures: AppTheme.numeric,
                    ),
                  ),
                  Text(
                    '练过 ${prompt.attemptCount} 次',
                    style: text.bodySmall?.copyWith(fontSize: 10.5),
                  ),
                ],
              )
            else
              Text('没做过', style: text.bodySmall),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 18, color: t.muted),
          ],
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.only(right: 8, top: 6, bottom: 6),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? t.accent : t.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? t.accent : t.line,
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: selected ? t.onAccent : t.textSoft,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
          ),
        ),
      ),
    );
  }
}
