import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:openexam_app/core/theme/app_theme.dart';
import 'package:openexam_app/core/theme/app_tokens.dart';
import 'package:openexam_app/core/ui/shore.dart';
import 'package:openexam_app/core/ui/shore_art.dart';
import 'package:openexam_app/core/ui/ui_kit.dart';
import 'package:openexam_app/features/vocab/data/vocab_repository.dart';
import 'package:openexam_app/features/vocab/domain/vocab_word.dart';

/// 词语积累。一次一张卡：先只给词，想过了再翻开对释义。
///
/// 不做选择题。逻辑填空考的是"这个词能不能用在这儿"，
/// 给四个选项反而会让人靠排除法蒙对，背的时候必须自己先想。
class VocabPage extends StatefulWidget {
  const VocabPage({super.key});

  @override
  State<VocabPage> createState() => _VocabPageState();
}

class _VocabPageState extends State<VocabPage> {
  bool _loading = true;
  List<VocabWord> _deck = const [];
  int _index = 0;
  bool _flipped = false;
  int _right = 0;

  @override
  void initState() {
    super.initState();
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
        title: const Text('词语积累'),
        actions: [
          if (!_loading && _deck.isNotEmpty && _index < _deck.length)
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
      body: _loading
          ? const LoadingState()
          : _deck.isEmpty
              ? _Done(right: 0, total: 0, onAgain: _load, empty: true)
              : _index >= _deck.length
                  ? _Done(right: _right, total: _deck.length, onAgain: _load)
                  : _Card(
                      word: _deck[_index],
                      flipped: _flipped,
                      progress: _index / _deck.length,
                      onFlip: () => setState(() => _flipped = true),
                      onAnswer: _answer,
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
