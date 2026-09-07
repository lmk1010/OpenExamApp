import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:openexam_app/l10n/app_localizations.dart';
import 'package:openexam_app/core/theme/app_theme.dart';
import 'package:openexam_app/core/theme/app_tokens.dart';
import 'package:openexam_app/core/ui/shore.dart';
import 'package:openexam_app/core/ui/shore_art.dart';
import 'package:openexam_app/core/ui/ui_kit.dart';
import 'package:openexam_app/data/db/app_database.dart';
import 'package:openexam_app/data/models/question.dart';
import 'package:openexam_app/features/vocab/data/vocab_repository.dart';
import 'package:openexam_app/features/vocab/domain/vocab_word.dart';

/// 词语。四件事收在一个入口里，不摊成一排图标。
///
/// 今日：一次一张卡，先只给词，想过了再翻开对释义。不做选择题 —— 逻辑填空
///       考的是"这个词能不能用在这儿"，给四个选项会让人靠排除法蒙对。
/// 高频：从 2077 道逻辑填空的选项统计出来的词频，不是谁拍脑袋定的"高频"。
///       兼做查词：搜索框搜的是整张四千词的表。
/// 辨析：一蹴而就 / 一挥而就 / 一气呵成 单看释义永远分不清，得摆在一起。
/// 我的：做错的题自动收进来的生词，加上手动加的。
class VocabPage extends StatefulWidget {
  const VocabPage({super.key, this.initialTab = VocabTab.today});

  /// 进来先停在哪一栏。工具页里"辨析""高频"各是一个入口，
  /// 点进来必须直接是那一栏。
  final VocabTab initialTab;

  @override
  State<VocabPage> createState() => _VocabPageState();
}

/// 词语页的四栏。工具页要按名字跳，所以是公开的。
enum VocabTab { today, top, confuse, mine }

typedef _Tab = VocabTab;

/// 顶层 const map 里放不了本地化字符串 —— 那里没有 context。
String _tabLabel(BuildContext context, _Tab tab) => switch (tab) {
      _Tab.today => AppL.of(context).vocabToday,
      _Tab.top => AppL.of(context).vocabFrequent,
      _Tab.confuse => AppL.of(context).vocabConfusable,
      _Tab.mine => AppL.of(context).vocabMine,
    };

class _VocabPageState extends State<VocabPage> {
  late _Tab _tab;
  bool _loading = true;
  List<VocabWord> _deck = const [];
  int _index = 0;
  bool _flipped = false;
  int _right = 0;
  DateTime _startedAt = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab;
    _load();
  }

  Future<void> _load() async {
    await VocabRepository.instance.ensureSeeded();
    final deck = await VocabRepository.instance.todayDeck();
    if (!mounted) return;
    setState(() {
      _deck = deck;
      _index = 0;
      _flipped = false;
      _right = 0;
      _startedAt = DateTime.now();
      _loading = false;
    });
  }

  Future<void> _answer(bool right) async {
    final word = _deck[_index];
    HapticFeedback.selectionClick();
    await VocabRepository.instance.save(word.answered(right: right));
    if (!mounted) return;
    setState(() {
      if (right) _right++;
      _flipped = false;
      _index++;
    });
    // 背词以前完全不进练习历史 —— 背了半小时，记录页上一片空白，
    // 看起来就像今天什么都没干。过完一轮记一条。
    if (_index >= _deck.length) await _logRound();
  }

  Future<void> _logRound() async {
    if (_deck.isEmpty) return;
    await AppDatabase.instance.saveReport(
      title: AppL.of(context).taskVocab,
      kind: 'vocab',
      questionIds: _deck.map((w) => w.word).toList(),
      answers: const {},
      correct: _right,
      elapsed: DateTime.now().difference(_startedAt),
    );
  }

  Widget _body() {
    switch (_tab) {
      case _Tab.today:
        if (_loading) return const LoadingState();
        if (_deck.isEmpty) {
          return _Done(right: 0, total: 0, onAgain: _load, empty: true);
        }
        if (_index >= _deck.length) {
          return _Done(right: _right, total: _deck.length, onAgain: _load);
        }
        return _Card(
          word: _deck[_index],
          flipped: _flipped,
          progress: _index / _deck.length,
          onFlip: () => setState(() => _flipped = true),
          onAnswer: _answer,
        );
      case _Tab.top:
        return const _TopWordsView();
      case _Tab.confuse:
        return const _ConfusableView();
      case _Tab.mine:
        // 背完一轮回来, 我的词表要跟着更新
        return _MyWordsView(onChanged: _load);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 21),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        titleSpacing: 0,
        title: Text(AppL.of(context).profileVocab),
        actions: [
          if (_tab == _Tab.today &&
              !_loading &&
              _deck.isNotEmpty &&
              _index < _deck.length)
            Padding(
              padding: const EdgeInsets.only(right: AppTheme.gutter),
              child: Center(
                child: Text(
                  '${_index + 1} / ${_deck.length}',
                  style: text.bodySmall?.copyWith(
                    fontFeatures: AppTheme.numeric,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          _TabBar(value: _tab, onPick: (v) => setState(() => _tab = v)),
          Expanded(child: _body()),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.word,
    required this.flipped,
    required this.progress,
    required this.onFlip,
    required this.onAnswer,
  });

  final VocabWord word;
  final bool flipped;
  final double progress;
  final VoidCallback onFlip;
  final void Function(bool) onAnswer;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.gutter,
            4,
            AppTheme.gutter,
            0,
          ),
          child: RouteBar(value: progress, height: 28),
        ),
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: flipped ? null : onFlip,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.gutter,
                12,
                AppTheme.gutter,
                12,
              ),
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(22, 30, 22, 26),
                  decoration: BoxDecoration(
                    color: t.surface,
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: t.shadow,
                  ),
                  child: Column(
                    children: [
                      if (word.source == 'wrong')
                        Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 11,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: t.dangerSoft,
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              AppL.of(context).vocabMissedThis,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: t.danger,
                              ),
                            ),
                          ),
                        ),
                      Text(
                        word.word,
                        textAlign: TextAlign.center,
                        style: text.displaySmall?.copyWith(
                          fontSize: 34,
                          height: 1.3,
                          letterSpacing: 2,
                        ),
                      ),
                      if (!flipped) ...[
                        SizedBox(height: 20),
                        Text(
                          AppL.of(context).vocabThinkFirst,
                          style: text.bodySmall,
                        ),
                      ] else ...[
                        const SizedBox(height: 22),
                        Divider(color: t.lineSoft, height: 1),
                        SizedBox(height: 20),
                        _Row(label: AppL.of(context).vocabMeaning, value: word.meaning),
                        if (word.usage.isNotEmpty) ...[
                          SizedBox(height: 16),
                          _Row(label: AppL.of(context).vocabUsage, value: word.usage, accent: true),
                        ],
                        if (word.confusable.isNotEmpty) ...[
                          SizedBox(height: 16),
                          _Row(label: AppL.of(context).vocabDontConfuse, value: word.confusable),
                        ],
                      ],
                    ],
                  ),
                ),
                if (!flipped) ...[
                  SizedBox(height: 20),
                  Center(
                    child: Text(AppL.of(context).vocabTapToFlip, style: text.bodySmall),
                  ),
                ],
              ],
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.gutter,
              0,
              AppTheme.gutter,
              12,
            ),
            child: flipped
                ? Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => onAnswer(false),
                          child: Text(AppL.of(context).vocabForgot),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => onAnswer(true),
                          child: Text(AppL.of(context).vocabGotIt),
                        ),
                      ),
                    ],
                  )
                : SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: onFlip,
                      child: Text(AppL.of(context).vocabFlip),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.accent = false});

  final String label;
  final String value;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 52,
          child: Text(label, style: text.bodySmall?.copyWith(fontSize: 12.5)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            style: text.bodyMedium?.copyWith(
              fontSize: 15,
              height: 1.6,
              color: accent ? t.onAccentSoft : t.text,
              fontWeight: accent ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}

class _Done extends StatelessWidget {
  const _Done({
    required this.right,
    required this.total,
    required this.onAgain,
    this.empty = false,
  });

  final int right;
  final int total;
  final VoidCallback onAgain;
  final bool empty;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppTheme.gutter,
        30,
        AppTheme.gutter,
        30,
      ),
      children: [
        Center(
          child: Image.asset(
            ShoreArt.forBrightness(
              ShoreArt.calm,
              Theme.of(context).brightness,
            ),
            width: 200,
            height: 200,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => SizedBox.shrink(),
          ),
        ),
        SizedBox(height: 24),
        Text(
          empty ? AppL.of(context).vocabNoneToday : AppL.of(context).vocabDoneToday,
          textAlign: TextAlign.center,
          style: text.displaySmall?.copyWith(fontSize: 22),
        ),
        SizedBox(height: 10),
        Text(
          empty
              ? AppL.of(context).vocabAutoCollect
              : AppL.of(context).vocabResult(right, total),
          textAlign: TextAlign.center,
          style: text.bodySmall,
        ),
        const SizedBox(height: 26),
        if (!empty)
          Center(
            child: OutlinedButton(
              onPressed: onAgain,
              child: Text(AppL.of(context).vocabAgain),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────── 分栏

class _TabBar extends StatelessWidget {
  const _TabBar({required this.value, required this.onPick});

  final _Tab value;
  final ValueChanged<_Tab> onPick;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(
          AppTheme.gutter,
          0,
          AppTheme.gutter,
          0,
        ),
        children: [
          for (final tab in _Tab.values) ...[
            GestureDetector(
              onTap: () => onPick(tab),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                margin: const EdgeInsets.only(right: 7),
                padding: const EdgeInsets.symmetric(horizontal: 15),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: tab == value
                      ? t.brand
                      : t.text.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _tabLabel(context, tab),
                  style: text.bodyMedium?.copyWith(
                    fontSize: 13,
                    color: tab == value ? Colors.white : t.textSoft,
                    fontWeight:
                        tab == value ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────── 高频 / 查词

/// 考得最多的词排在最前。搜索框搜的是整张四千词的表，所以这一栏
/// 同时也是「查词」—— 不必再单开一个入口。
class _TopWordsView extends StatefulWidget {
  const _TopWordsView();

  @override
  State<_TopWordsView> createState() => _TopWordsViewState();
}

class _TopWordsViewState extends State<_TopWordsView> {
  final _search = TextEditingController();
  bool _loading = true;
  String _query = '';
  List<WordFreq> _words = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final db = AppDatabase.instance;
    final list = _query.isEmpty
        ? await db.topWords()
        : await db.searchWords(_query);
    if (!mounted) return;
    setState(() {
      _words = list;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppTheme.gutter, 4, AppTheme.gutter, 10),
          child: Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: t.surface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: t.lineSoft),
            ),
            child: Row(
              children: [
                Icon(Icons.search, size: 18, color: t.muted),
                SizedBox(width: 9),
                Expanded(
                  child: TextField(
                    controller: _search,
                    style: text.bodyMedium?.copyWith(color: t.text, fontSize: 14),
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: AppL.of(context).vocabSearchHint,
                      hintStyle: text.bodySmall?.copyWith(fontSize: 13),
                    ),
                    onChanged: (v) {
                      setState(() => _query = v.trim());
                      _load();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_loading)
          Expanded(child: LoadingState())
        else if (_words.isEmpty)
          Expanded(
            child: EmptyState(
              icon: Icons.search_off,
              title: _query.isEmpty ? AppL.of(context).vocabNoFreq : AppL.of(context).vocabNeverAsked,
              art: EmptyArt.search,
              message: _query.isEmpty
                  ? AppL.of(context).vocabNoFreqHint
                  : AppL.of(context).vocabNeverAskedHint,
            ),
          )
        else
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.gutter,
                0,
                AppTheme.gutter,
                24,
              ),
              itemCount: _words.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: t.lineSoft),
              itemBuilder: (_, i) => _WordRow(entry: _words[i]),
            ),
          ),
      ],
    );
  }
}

class _WordRow extends StatelessWidget {
  const _WordRow({required this.entry});

  final WordFreq entry;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _WordSheet(entry: entry),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                entry.word,
                style: text.titleSmall?.copyWith(fontSize: 15),
              ),
            ),
            Text(
              AppL.of(context).vocabAskedTimes(entry.count),
              style: text.bodySmall?.copyWith(
                fontSize: 12,
                fontFeatures: AppTheme.numeric,
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right, size: 18, color: t.muted),
          ],
        ),
      ),
    );
  }
}

/// 点开一个词看什么？——看真题里它怎么用。
///
/// 不查词典：词典只告诉你"是什么意思"，逻辑填空考的是"能不能用在这儿"。
/// 直接把考过它的题摆出来，语感是从这里来的。
class _WordSheet extends StatefulWidget {
  const _WordSheet({required this.entry});

  final WordFreq entry;

  @override
  State<_WordSheet> createState() => _WordSheetState();
}

class _WordSheetState extends State<_WordSheet> {
  bool _loading = true;
  List<Question> _questions = const [];
  VocabWord? _known;
  bool _added = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final qs = await AppDatabase.instance.questionsUsing(widget.entry.word);
    final known =
        await VocabRepository.instance.byWords([widget.entry.word]);
    if (!mounted) return;
    setState(() {
      _questions = qs;
      _known = known[widget.entry.word];
      _loading = false;
    });
  }

  Future<void> _add() async {
    await VocabRepository.instance.collect([
      VocabWord(
        word: widget.entry.word,
        meaning: '',
        source: 'manual',
        addedAt: DateTime.now(),
      ),
    ]);
    if (!mounted) return;
    setState(() => _added = true);
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final inDeck = _known != null || _added;
    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.4,
      maxChildSize: 0.94,
      expand: false,
      builder: (context, controller) => Container(
        decoration: BoxDecoration(
          color: t.bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(
            AppTheme.gutter,
            18,
            AppTheme.gutter,
            28,
          ),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  widget.entry.word,
                  style: text.titleLarge?.copyWith(fontSize: 22),
                ),
                SizedBox(width: 10),
                Text(
                  AppL.of(context).vocabAskedTimesLong(widget.entry.count),
                  style: text.bodySmall?.copyWith(
                    fontSize: 12,
                    fontFeatures: AppTheme.numeric,
                  ),
                ),
              ],
            ),
            if (_known?.meaning.isNotEmpty ?? false) ...[
              const SizedBox(height: 12),
              Text(_known!.meaning, style: text.bodyMedium?.copyWith(color: t.text)),
              if (_known!.usage.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(_known!.usage, style: text.bodySmall?.copyWith(fontSize: 13)),
              ],
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: inDeck
                  ? OutlinedButton(
                      onPressed: null,
                      child: Text(AppL.of(context).vocabAlreadyAdded),
                    )
                  : FilledButton(
                      onPressed: _add,
                      child: Text(AppL.of(context).vocabAdd),
                    ),
            ),
            SizedBox(height: 22),
            Text(
              AppL.of(context).vocabQuestionsWith,
              style: text.titleSmall?.copyWith(fontSize: 14),
            ),
            const SizedBox(height: 10),
            if (_loading)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 30),
                child: LoadingState(),
              )
            else if (_questions.isEmpty)
              Text(
                AppL.of(context).vocabNoSource,
                style: text.bodySmall?.copyWith(fontSize: 13),
              )
            else
              for (final q in _questions.take(6)) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: t.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        q.content,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodyMedium?.copyWith(
                          color: t.text,
                          fontSize: 14,
                          height: 1.6,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        AppL.of(context).vocabSourceLine(q.paperTitle, q.answer),
                        style: text.bodySmall?.copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────── 辨析

/// 一蹴而就 / 一挥而就 / 一气呵成 —— 单看释义永远分不清，得摆在一起看。
/// 所以这一栏不是词表，是「一组一组」的对照卡。
class _ConfusableView extends StatefulWidget {
  const _ConfusableView();

  @override
  State<_ConfusableView> createState() => _ConfusableViewState();
}

class _ConfusableViewState extends State<_ConfusableView> {
  bool _loading = true;
  List<VocabWord> _words = const [];
  Map<String, VocabWord> _byWord = const {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = VocabRepository.instance;
    await repo.ensureSeeded();
    final words = await repo.confusableGroups();
    // 易混词自己的释义也要一并取出来 —— 只显示词名等于没对比。
    final peers = <String>{
      for (final w in words) ...w.confusableList,
    };
    final byWord = await repo.byWords([...peers, ...words.map((w) => w.word)]);
    if (!mounted) return;
    setState(() {
      _words = words;
      _byWord = byWord;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    if (_loading) return const LoadingState();
    if (_words.isEmpty) {
      return EmptyState(
        icon: Icons.compare_arrows,
        title: AppL.of(context).vocabNoConfusable,
        art: EmptyArt.vocab,
        message: AppL.of(context).vocabNoConfusableHint,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.gutter,
        4,
        AppTheme.gutter,
        24,
      ),
      itemCount: _words.length,
      itemBuilder: (_, i) {
        final w = _words[i];
        final peers = w.confusableList
            .map((p) => _byWord[p])
            .whereType<VocabWord>()
            .toList();
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ConfuseLine(word: w, highlight: true),
              for (final p in peers) ...[
                Divider(height: 22, color: t.lineSoft),
                _ConfuseLine(word: p, highlight: false),
              ],
              if (peers.isEmpty) ...[
                SizedBox(height: 8),
                Text(
                  AppL.of(context).vocabConfusableWith(w.confusable),
                  style: text.bodySmall?.copyWith(fontSize: 12.5),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _ConfuseLine extends StatelessWidget {
  const _ConfuseLine({required this.word, required this.highlight});

  final VocabWord word;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          word.word,
          style: text.titleSmall?.copyWith(
            fontSize: 15,
            color: highlight ? t.brand : t.text,
          ),
        ),
        if (word.meaning.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            word.meaning,
            style: text.bodyMedium?.copyWith(color: t.text, fontSize: 14),
          ),
        ],
        if (word.usage.isNotEmpty) ...[
          const SizedBox(height: 3),
          // 用法才是分辨的依据：褒贬、搭配、常见误用。
          Text(word.usage, style: text.bodySmall?.copyWith(fontSize: 12.5)),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────── 我的

/// 做错的题里自动收进来的词，加上从高频表手动加的。
class _MyWordsView extends StatefulWidget {
  const _MyWordsView({required this.onChanged});

  final VoidCallback onChanged;

  @override
  State<_MyWordsView> createState() => _MyWordsViewState();
}

class _MyWordsViewState extends State<_MyWordsView> {
  bool _loading = true;
  List<VocabWord> _words = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await VocabRepository.instance.all();
    if (!mounted) return;
    setState(() {
      _words = list;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    if (_loading) return const LoadingState();
    if (_words.isEmpty) {
      return EmptyState(
        icon: Icons.style_outlined,
        title: AppL.of(context).vocabEmpty,
        art: EmptyArt.vocab,
        message: AppL.of(context).vocabEmptyHint,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.gutter,
        4,
        AppTheme.gutter,
        24,
      ),
      itemCount: _words.length,
      separatorBuilder: (_, __) => Divider(height: 1, color: t.lineSoft),
      itemBuilder: (_, i) {
        final w = _words[i];
        return Dismissible(
          key: ValueKey(w.word),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 18),
            color: t.dangerSoft,
            child: Icon(Icons.delete_outline, size: 20, color: t.danger),
          ),
          onDismissed: (_) async {
            await VocabRepository.instance.remove(w.word);
            setState(() => _words = [..._words]..removeAt(i));
            widget.onChanged();
          },
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Expanded(
                      child: Text(
                        w.word,
                        style: text.titleSmall?.copyWith(fontSize: 15),
                      ),
                    ),
                    // 从做错的题里收来的, 标出来 —— 这些是你自己的坑。
                    if (w.source == 'wrong')
                      Text(
                        AppL.of(context).vocabFromMistakes,
                        style: text.bodySmall?.copyWith(
                          fontSize: 11.5,
                          color: t.danger,
                        ),
                      ),
                  ],
                ),
                if (w.meaning.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    w.meaning,
                    style: text.bodyMedium?.copyWith(color: t.text, fontSize: 14),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
