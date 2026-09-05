import 'package:openexam_app/data/models/question.dart';
import 'package:openexam_app/features/vocab/data/vocab_repository.dart';
import 'package:openexam_app/features/vocab/data/vocab_seed.dart';
import 'package:openexam_app/features/vocab/domain/vocab_word.dart';

/// 从做错的逻辑填空题里把词收进词表。
///
/// 只收「正确答案里的那个词」和「你选错的那个词」两类 —— 这两个是
/// 你当场分不清的一对，比把四个选项全收进来有用得多。
class VocabCollector {
  const VocabCollector._();

  /// 只对逻辑填空生效：别的题型的选项不是词语。
  static bool applies(Question q) =>
      q.category == 'yanyu' &&
      (q.subCategory == 'xuanci' || q.subCategory.isEmpty) &&
      q.options.every((o) => o.text.length <= 10);

  static Future<int> collect(Question q, String chosen) async {
    if (!applies(q)) return 0;
    final right = q.answer.toUpperCase();
    if (chosen.toUpperCase() == right) return 0;

    final wanted = <String>{};
    for (final o in q.options) {
      if (o.key == right || o.key == chosen.toUpperCase()) {
        final w = o.text.trim();
        // 一到两字多半是虚词或截断，四字以上不是成语就是句子
        if (w.length >= 2 && w.length <= 6) wanted.add(w);
      }
    }
    if (wanted.isEmpty) return 0;

    final now = DateTime.now();
    final words = <VocabWord>[];
    for (final w in wanted) {
      // 内置词表里有释义就带上，没有就先空着 —— 空着也要收，
      // 释义可以之后补，词错过就再也想不起来了。
      final known = _seedIndex[w];
      words.add(VocabWord(
        word: w,
        meaning: known?.meaning ?? '',
        usage: known?.usage ?? '',
        confusable: known?.confusable ?? '',
        source: 'wrong',
        fromQuestionId: q.id,
        addedAt: now,
      ));
    }
    return VocabRepository.instance.collect(words);
  }

  static final Map<String, VocabWord> _seedIndex = {
    for (final w in kVocabSeed) w.word: w,
  };
}
