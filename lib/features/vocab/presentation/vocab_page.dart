import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

const _tabLabels = {
  _Tab.today: '今日',
  _Tab.top: '高频',
  _Tab.confuse: '辨析',
  _Tab.mine: '我的',
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
      title: '背词语',
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
        title: const Text('词语'),
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 11,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: t.dangerSoft,
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              '你在题里错过这个词',
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
                        const SizedBox(height: 20),
                        Text(
                          '先自己想一遍，再点开对答案',
                          style: text.bodySmall,
                        ),
                      ] else ...[
                        const SizedBox(height: 22),
                        Divider(color: t.lineSoft, height: 1),
                        const SizedBox(height: 20),
                        _Row(label: '意思', value: word.meaning),
                        if (word.usage.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _Row(label: '怎么用', value: word.usage, accent: true),
                        ],
                        if (word.confusable.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _Row(label: '别混了', value: word.confusable),
                        ],
                      ],
                    ],
                  ),
                ),
                if (!flipped) ...[
                  const SizedBox(height: 20),
                  Center(
                    child: Text('点一下翻开', style: text.bodySmall),
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
                          child: const Text('没记住'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => onAnswer(true),
                          child: const Text('记住了'),
                        ),
                      ),
                    ],
                  )
                : SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: onFlip,
                      child: const Text('翻开'),
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
      padding: const EdgeInsets.fromLTRB(
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
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          empty ? '今天没有要背的词' : '今天的词过完了',
          textAlign: TextAlign.center,
          style: text.displaySmall?.copyWith(fontSize: 22),
        ),
        const SizedBox(height: 10),
        Text(
          empty
              ? '做错的逻辑填空会自动把词收进来'
              : '记住 $right / $total · 没记住的明天还会出现',
          textAlign: TextAlign.center,
          style: text.bodySmall,
        ),
        const SizedBox(height: 26),
        if (!empty)
          Center(
            child: OutlinedButton(
              onPressed: onAgain,
              child: const Text('再来一轮'),
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
                  _tabLabels[tab]!,
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
                const SizedBox(width: 9),
                Expanded(
                  child: TextField(
                    controller: _search,
                    style: text.bodyMedium?.copyWith(color: t.text, fontSize: 14),
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: '查一个词，比如「一以贯之」',
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
          const Expanded(child: LoadingState())
        else if (_words.isEmpty)
          Expanded(
            child: EmptyState(
              icon: Icons.search_off,
              title: _query.isEmpty ? '这版题库还没带词频' : '没有考过这个词',
              art: EmptyArt.search,
              message: _query.isEmpty
                  ? '词频是从逻辑填空的选项统计出来的，重装一次 App 就有了。'
                  : '换个说法试试，或者它确实没在真题里出现过。',
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
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                entry.word,
                style: text.titleSmall?.copyWith(fontSize: 15),
              ),
            ),
            Text(
              '考过 ${entry.count} 次',
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
                const SizedBox(width: 10),
                Text(
                  '真题里考过 ${widget.entry.count} 次',
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
                      child: const Text('已在我的词表里'),
                    )
                  : FilledButton(
                      onPressed: _add,
                      child: const Text('加进我的词表'),
                    ),
            ),
            const SizedBox(height: 22),
            Text(
              '考过这个词的题',
              style: text.titleSmall?.copyWith(fontSize: 14),
            ),
            const SizedBox(height: 10),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 30),
                child: LoadingState(),
              )
            else if (_questions.isEmpty)
              Text(
                '这一版题库里没找到原题。',
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
                      const SizedBox(height: 8),
                      Text(
                        '${q.paperTitle} · 正确答案 ${q.answer}',
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
      return const EmptyState(
        icon: Icons.compare_arrows,
        title: '还没有易混词',
        art: EmptyArt.vocab,
        message: '内置词表里标了易混词的条目会出现在这里。',
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
                const SizedBox(height: 8),
                Text(
                  '易混：${w.confusable}',
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
      return const EmptyState(
        icon: Icons.style_outlined,
        title: '词表还是空的',
        art: EmptyArt.vocab,
        message: '逻辑填空做错的题，那对词会自动收进来；也可以在「高频」里手动加。',
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
            padding: const EdgeInsets.symmetric(vertical: 13),
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
                        '做错收的',
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
