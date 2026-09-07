import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:openexam_app/core/ai/ai_client.dart';
import 'package:openexam_app/core/ai/ai_settings.dart';
import 'package:openexam_app/core/constants/categories.dart';
import 'package:openexam_app/core/theme/app_theme.dart';
import 'package:openexam_app/core/theme/app_tokens.dart';
import 'package:openexam_app/core/ui/shore.dart';
import 'package:openexam_app/core/ui/shore_art.dart';
import 'package:openexam_app/data/db/app_database.dart';
import 'package:openexam_app/data/models/question.dart';
import 'package:openexam_app/features/ai/ai_settings_page.dart';
import 'package:openexam_app/features/import/data/paper_scanner.dart';

/// 拍照 / PDF 识别成题目。
///
/// 一屏走完：选文件 → 逐页识别（看得见进度）→ 过一遍结果 → 导入。
/// 中间不解释、不教学，卡在哪一页就在哪一页给重试。
class ScanPaperPage extends StatefulWidget {
  const ScanPaperPage({super.key});

  @override
  State<ScanPaperPage> createState() => _ScanPaperPageState();
}

enum _Stage { pick, scanning, review }

class _ScanPaperPageState extends State<ScanPaperPage> {
  _Stage _stage = _Stage.pick;
  PaperScanner? _scanner;
  List<ScanPage> _pages = const [];
  String _sourceName = '';
  bool _cancelled = false;

  /// 识别出来的题，逐题可以剔掉。
  final _kept = <String, bool>{};
  List<Question> _questions = const [];

  /// 整批改成同一个题型。空 = 用模型逐题判的结果。
  String? _override;

  int get _failedCount => _pages.where((p) => p.state == PageState.failed).length;
  List<Question> get _selected =>
      _questions.where((q) => _kept[q.id] ?? true).toList();

  Future<void> _pick({required bool pdf}) async {
    final settings = await AiSettingsStore.load();
    if (!mounted) return;
    if (!settings.isConfigured) {
      final go = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('先配一个 AI'),
          content: const Text('识别试卷要调模型。填一个 key 就行，题目和图片只发给你自己配的那家。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('去设置'),
            ),
          ],
        ),
      );
      if (go == true && mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AiSettingsPage()),
        );
      }
      return;
    }

    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: pdf ? const ['pdf'] : const ['png', 'jpg', 'jpeg', 'webp'],
      allowMultiple: !pdf,
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) return;

    setState(() {
      _stage = _Stage.scanning;
      _cancelled = false;
      _sourceName = picked.files.first.name;
    });

    try {
      final scanner = PaperScanner(AiClient(settings));
      List<ScanPage> pages;
      if (pdf) {
        final bytes = await _bytesOf(picked.files.first);
        pages = await PaperScanner.pagesFromPdf(bytes);
      } else {
        final all = <Uint8List>[];
        for (final f in picked.files) {
          all.add(await _bytesOf(f));
        }
        pages = await PaperScanner.pagesFromImages(all);
      }
      if (!mounted) return;
      if (pages.isEmpty) {
        setState(() => _stage = _Stage.pick);
        _toast('这个文件里没有可识别的页面');
        return;
      }
      setState(() {
        _scanner = scanner;
        _pages = pages;
      });
      await _runAll();
    } catch (e) {
      if (!mounted) return;
      setState(() => _stage = _Stage.pick);
      _toast('打不开这个文件：$e');
    }
  }

  static Future<Uint8List> _bytesOf(PlatformFile f) async {
    if (f.bytes != null) return f.bytes!;
    return File(f.path!).readAsBytes();
  }

  /// 一页一页跑，不并发。并发省不下多少时间，却会同时撞上限流，
  /// 而且失败时说不清是哪几页。
  Future<void> _runAll() async {
    for (final page in _pages) {
      if (_cancelled || !mounted) return;
      if (page.state == PageState.done) continue;
      await _scanner!.scanPage(page);
      if (!mounted) return;
      setState(() {});
    }
    if (!mounted) return;
    _collect();
  }

  Future<void> _retry(ScanPage page) async {
    setState(() {});
    await _scanner!.scanPage(page);
    if (!mounted) return;
    setState(_collect);
  }

  void _collect() {
    final all = <Question>[];
    for (final p in _pages) {
      all.addAll(p.questions);
    }
    // 一材多题：同一段材料的题归到一个 id，材料只存一份
    final materialIds = <String, String>{};
    final now = DateTime.now().millisecondsSinceEpoch;
    _questions = [
      for (final q in all)
        q.material.isEmpty
            ? q
            : q.withMaterialId(materialIds.putIfAbsent(
                q.material,
                () => 'mat_${now}_${materialIds.length + 1}',
              )),
    ];
    setState(() => _stage = _Stage.review);
  }

  Future<void> _import() async {
    final list = _selected
        .map((q) => q.withCategory(
              _override ?? (q.category.isEmpty ? 'yanyu' : q.category),
            ))
        .toList();
    if (list.isEmpty) {
      Navigator.of(context).pop(0);
      return;
    }
    await AppDatabase.instance.importImages(_scanner!.figures);
    final n = await AppDatabase.instance.importQuestions(list);
    if (!mounted) return;
    Navigator.of(context).pop(n);
  }

  void _toast(String m) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 21),
          onPressed: () {
            _cancelled = true;
            Navigator.of(context).maybePop();
          },
        ),
        titleSpacing: 0,
        title: Text(switch (_stage) {
          _Stage.pick => '拍照 / PDF',
          _Stage.scanning => '识别中',
          _Stage.review => '过一遍',
        }),
      ),
      body: switch (_stage) {
        _Stage.pick => _PickBody(onPdf: () => _pick(pdf: true), onImages: () => _pick(pdf: false)),
        _Stage.scanning => _ScanBody(
            pages: _pages,
            name: _sourceName,
            onRetry: _retry,
          ),
        _Stage.review => _ReviewBody(
            questions: _questions,
            kept: _kept,
            failed: _failedCount,
            overrideCategory: _override,
            onOverride: (c) => setState(() => _override = c),
            onToggle: (id, v) => setState(() => _kept[id] = v),
            onImport: _import,
            onBackToScan: () => setState(() => _stage = _Stage.scanning),
          ),
      },
    );
  }
}

/// 第一屏：两个入口，一句话说清各自吃什么，没有第三句。
class _PickBody extends StatelessWidget {
  const _PickBody({required this.onPdf, required this.onImages});

  final VoidCallback onPdf;
  final VoidCallback onImages;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.gutter,
        8,
        AppTheme.gutter,
        24,
      ),
      children: [
        _Big(
          label: '选一个 PDF',
          caption: '整本试卷，逐页识别',
          primary: true,
          onTap: onPdf,
        ),
        const SizedBox(height: 12),
        _Big(
          label: '选图片',
          caption: '拍的照片或截图，可以多选',
          onTap: onImages,
        ),
        const SizedBox(height: 26),
        Center(
          child: Image.asset(
            ShoreArt.chart,
            width: 200,
            height: 200,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '识别用的是你自己配的那家模型，一页一次调用。\n'
          '题目和图片不经过我们的服务器。',
          textAlign: TextAlign.center,
          style: text.bodySmall,
        ),
      ],
    );
  }
}

class _Big extends StatelessWidget {
  const _Big({
    required this.label,
    required this.caption,
    required this.onTap,
    this.primary = false,
  });

  final String label;
  final String caption;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 18, 18),
        decoration: BoxDecoration(
          color: primary ? t.accent : t.surface,
          borderRadius: BorderRadius.circular(22),
          boxShadow: primary ? null : t.shadow,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: text.titleSmall?.copyWith(
                      fontSize: 16.5,
                      color: primary ? t.onAccent : t.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    caption,
                    style: text.bodySmall?.copyWith(
                      fontSize: 12.5,
                      color: primary
                          ? t.onAccent.withValues(alpha: 0.75)
                          : t.muted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: primary ? t.onAccent : t.muted,
            ),
          ],
        ),
      ),
    );
  }
}

/// 识别中：一页一格，看得见走到哪了、哪页崩了。
class _ScanBody extends StatelessWidget {
  const _ScanBody({
    required this.pages,
    required this.name,
    required this.onRetry,
  });

  final List<ScanPage> pages;
  final String name;
  final void Function(ScanPage) onRetry;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final done = pages.where((p) => p.state != PageState.waiting &&
        p.state != PageState.running).length;
    final found = pages.fold<int>(0, (s, p) => s + p.questions.length);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.gutter,
        8,
        AppTheme.gutter,
        24,
      ),
      children: [
        Text(name, style: text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '$found',
              style: text.displaySmall?.copyWith(
                fontSize: 40,
                height: 1,
                fontFeatures: AppTheme.numeric,
              ),
            ),
            const SizedBox(width: 8),
            Text('题', style: text.titleSmall?.copyWith(color: t.muted)),
            const Spacer(),
            Text(
              '$done / ${pages.length} 页',
              style: text.bodySmall?.copyWith(fontFeatures: AppTheme.numeric),
            ),
          ],
        ),
        const SizedBox(height: 10),
        RouteBar(value: pages.isEmpty ? 0 : done / pages.length),
        const SizedBox(height: 20),
        for (final p in pages) ...[
          _PageRow(page: p, onRetry: () => onRetry(p)),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _PageRow extends StatelessWidget {
  const _PageRow({required this.page, required this.onRetry});

  final ScanPage page;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final failed = page.state == PageState.failed;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: failed ? t.dangerSoft : t.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: failed ? null : t.shadow,
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              page.bytes,
              width: 40,
              height: 54,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.low,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '第 ${page.index} 页',
                  style: text.titleSmall?.copyWith(fontSize: 14),
                ),
                // 失败了要说为什么。只给一个"重试"，用户只能盲目再点一次。
                if (failed && (page.error ?? '').isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    page.error!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall?.copyWith(
                      fontSize: 11.5,
                      color: t.danger,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          switch (page.state) {
            PageState.waiting => Text('等着', style: text.bodySmall),
            PageState.running => SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: t.accent,
                ),
              ),
            PageState.done => Text(
                page.questions.isEmpty ? '没有完整题目' : '${page.questions.length} 题',
                style: text.bodySmall?.copyWith(
                  color: page.questions.isEmpty ? t.muted : t.success,
                  fontFeatures: AppTheme.numeric,
                ),
              ),
            PageState.failed => GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onRetry,
                child: Text(
                  '重试',
                  style: text.bodySmall?.copyWith(
                    color: t.danger,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          },
        ],
      ),
    );
  }
}

/// 过一遍：缺答案的排最前，勾掉不要的，选个题型，导入。
class _ReviewBody extends StatelessWidget {
  const _ReviewBody({
    required this.questions,
    required this.kept,
    required this.failed,
    required this.overrideCategory,
    required this.onOverride,
    required this.onToggle,
    required this.onImport,
    required this.onBackToScan,
  });

  final List<Question> questions;
  final Map<String, bool> kept;
  final int failed;
  /// 整批覆盖的题型。字段不能叫 override —— 会盖掉 @override 注解。
  final String? overrideCategory;
  final ValueChanged<String?> onOverride;
  final void Function(String, bool) onToggle;
  final VoidCallback onImport;
  final VoidCallback onBackToScan;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final selected = questions.where((q) => kept[q.id] ?? true).length;
    // 缺答案的排最前 —— 要改的东西不该埋在一百题里
    final sorted = [...questions]..sort((a, b) {
        final ai = a.answer.isEmpty ? 0 : 1;
        final bi = b.answer.isEmpty ? 0 : 1;
        return ai.compareTo(bi);
      });
    final missing = questions.where((q) => q.answer.isEmpty).length;
    final unknown = questions.where((q) => q.category.isEmpty).length;
    final byCategory = questions
        .map((q) => q.category)
        .where((c) => c.isNotEmpty)
        .toSet();

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.gutter,
              8,
              AppTheme.gutter,
              16,
            ),
            children: [
              if (missing > 0 || failed > 0)
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: t.accentSoft,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    [
                      if (missing > 0) '$missing 题没认出答案，已排在最前',
                      if (failed > 0) '$failed 页识别失败',
                    ].join('；'),
                    style: text.bodySmall?.copyWith(color: t.onAccentSoft),
                  ),
                ),
              // 题型逐题判过了。这一行是"判错了就整批改"的兜底，
              // 不是必填项 —— 默认那颗选中的就是"按识别结果"。
              Text('题型', style: text.titleSmall),
              const SizedBox(height: 4),
              Text(
                unknown > 0
                    ? '识别出 ${byCategory.length} 类，$unknown 题没认出'
                    : '已逐题识别，不对可以整批改',
                style: text.bodySmall,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Chip(
                    label: '按识别结果',
                    on: overrideCategory == null,
                    onTap: () => onOverride(null),
                  ),
                  for (final c in CategoryRegistry.current)
                    _Chip(
                      label: c.label,
                      on: overrideCategory == c.key,
                      onTap: () => onOverride(c.key),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              for (final q in sorted) ...[
                _QuestionCard(
                  question: q,
                  on: kept[q.id] ?? true,
                  category: overrideCategory ?? q.category,
                  onToggle: (v) => onToggle(q.id, v),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.gutter,
              4,
              AppTheme.gutter,
              12,
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onBackToScan,
                    child: const Text('看页面'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: onImport,
                    child: Text(selected == 0 ? '没有选中的题' : '导入 $selected 题'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.question,
    required this.on,
    required this.category,
    required this.onToggle,
  });

  final Question question;
  final bool on;
  final String category;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final noAnswer = question.answer.isEmpty;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onToggle(!on),
      child: Opacity(
        opacity: on ? 1 : 0.45,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(18),
            boxShadow: t.shadow,
            border: noAnswer
                ? Border.all(color: t.danger.withValues(alpha: 0.4), width: 1.5)
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LifeRing(
                    state: on ? LifeRingState.done : LifeRingState.skipped,
                    size: 20,
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      question.content,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodyMedium?.copyWith(
                        color: t.text,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(left: 31),
                child: Row(
                  children: [
                    Text(
                      noAnswer ? '没认出答案' : '答案 ${question.answer}',
                      style: text.bodySmall?.copyWith(
                        color: noAnswer ? t.danger : t.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // 题型用一条 3px 色条加短名，跟别处一样，不染整块
                    Container(
                      width: 3,
                      height: 11,
                      margin: const EdgeInsets.only(right: 5),
                      decoration: BoxDecoration(
                        color: category.isEmpty
                            ? t.muted
                            : t.category(category),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    Text(
                      category.isEmpty ? '未判定' : categoryLabel(category),
                      style: text.bodySmall,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${question.options.length} 个选项',
                      style: text.bodySmall,
                    ),
                    if (question.hasMaterial) ...[
                      const SizedBox(width: 12),
                      Text('带材料', style: text.bodySmall),
                    ],
                    if (question.hasImage) ...[
                      const SizedBox(width: 12),
                      Text('带图', style: text.bodySmall),
                    ],
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

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.on, required this.onTap});

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
