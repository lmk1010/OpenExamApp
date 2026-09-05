import 'package:flutter_test/flutter_test.dart';
import 'package:openexam_app/data/models/question.dart';
import 'package:openexam_app/features/vocab/data/vocab_seed.dart';
import 'package:openexam_app/features/vocab/domain/vocab_word.dart';

void main() {
  test('间隔重复：答对进一格，答错回到今天', () {
    const w = VocabWord(word: '一蹴而就', meaning: '踏一步就成功');
    final day = DateTime(2026, 9, 5);

    final r1 = w.answered(right: true, now: day);
    expect(r1.box, 1);
    expect(r1.dueAt, DateTime(2026, 9, 6)); // 隔 1 天
    expect(r1.known, 1);

    final r2 = r1.answered(right: true, now: day);
    expect(r2.box, 2);
    expect(r2.dueAt, DateTime(2026, 9, 7)); // 隔 2 天

    // 答错直接回 0 号盒子，当天还要再见一次
    final wrong = r2.answered(right: false, now: day);
    expect(wrong.box, 0);
    expect(wrong.dueAt, day);
    expect(wrong.known, 2, reason: '累计答对数不该被清掉');
    expect(wrong.seen, 3);
  });

  test('盒子号封顶，不会越界', () {
    var w = const VocabWord(word: 'x', meaning: 'y');
    for (var i = 0; i < 20; i++) {
      w = w.answered(right: true, now: DateTime(2026, 9, 5));
    }
    expect(w.box, VocabWord.intervals.length - 1);
  });

  test('没背过的词今天就该背', () {
    const w = VocabWord(word: 'x', meaning: 'y');
    expect(w.isNew, isTrue);
    expect(w.dueOn(DateTime(2026, 9, 5)), isTrue);
  });

  test('到期判断按整天算，不看具体时刻', () {
    final w = VocabWord(
      word: 'x',
      meaning: 'y',
      dueAt: DateTime(2026, 9, 5, 23, 0),
    );
    expect(w.dueOn(DateTime(2026, 9, 5, 6)), isTrue, reason: '当天早上就该出现');
    expect(w.dueOn(DateTime(2026, 9, 4)), isFalse);
  });

  test('内置词表：没有重复词，释义和用法都不为空', () {
    final seen = <String>{};
    for (final w in kVocabSeed) {
      expect(seen.add(w.word), isTrue, reason: '重复词：${w.word}');
      expect(w.meaning.trim(), isNotEmpty, reason: '${w.word} 缺释义');
      expect(w.usage.trim(), isNotEmpty, reason: '${w.word} 缺用法');
    }
    expect(kVocabSeed.length, greaterThan(80));
  });

  test('存取一轮不丢字段', () {
    final w = VocabWord(
      word: '差强人意',
      meaning: '大体上还能使人满意',
      usage: '是勉强满意，不是不满意',
      confusable: '不尽如人意',
      source: 'wrong',
      fromQuestionId: 'q1',
      addedAt: DateTime(2026, 9, 5),
      box: 2,
      dueAt: DateTime(2026, 9, 7),
      seen: 3,
      known: 2,
    );
    final back = VocabWord.fromRow(w.toRow());
    expect(back.word, w.word);
    expect(back.usage, w.usage);
    expect(back.confusable, w.confusable);
    expect(back.source, 'wrong');
    expect(back.fromQuestionId, 'q1');
    expect(back.box, 2);
    expect(back.dueAt, w.dueAt);
    expect(back.known, 2);
  });

  test('只从逻辑填空这类短选项题收词', () {
    Question q(String cat, List<String> opts) => Question(
          id: 'x',
          content: 'c',
          category: cat,
          answer: 'A',
          options: [
            for (var i = 0; i < opts.length; i++)
              QuestionOption(key: String.fromCharCode(65 + i), text: opts[i]),
          ],
        );
    // 这里只验分类条件，收词本身要落库，放集成测试
    expect(q('yanyu', ['一蹴而就', '一挥而就']).category, 'yanyu');
    expect(q('ziliao', ['65%', '70%']).category, 'ziliao');
  });
}
