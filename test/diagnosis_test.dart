import 'package:flutter_test/flutter_test.dart';
import 'package:openexam_app/data/models/question.dart';
import 'package:openexam_app/features/diagnosis/diagnosis.dart';

Question q(String id, String category) => Question(
      id: id,
      content: '题干 $id',
      options: const [
        QuestionOption(key: 'A', text: 'A'),
        QuestionOption(key: 'B', text: 'B'),
      ],
      answer: 'A',
      category: category,
    );

/// 造一份卷子：每个模块 n 道，指定对几道、每题几秒。
({
  List<Question> questions,
  Map<String, String> answers,
  Map<String, ({bool correct, int seconds})> timings,
}) paper(
  Map<String, ({int n, int correct, int seconds})> spec, {
  int blank = 0,
}) {
  final questions = <Question>[];
  final answers = <String, String>{};
  final timings = <String, ({bool correct, int seconds})>{};
  var i = 0;
  var skipped = 0;
  for (final e in spec.entries) {
    for (var k = 0; k < e.value.n; k++) {
      final id = 'q${i++}';
      questions.add(q(id, e.key));
      if (skipped < blank) {
        skipped++;
        continue; // 没作答：既不进 answers 也不进 timings
      }
      answers[id] = 'A';
      timings[id] = (correct: k < e.value.correct, seconds: e.value.seconds);
    }
  }
  return (questions: questions, answers: answers, timings: timings);
}

Diagnosis diagnose(
  Map<String, ({int n, int correct, int seconds})> spec, {
  int blank = 0,
  Duration elapsed = const Duration(minutes: 60),
}) {
  final p = paper(spec, blank: blank);
  return Diagnosis.fromReport(
    title: '测试卷',
    questions: p.questions,
    answers: p.answers,
    timings: p.timings,
    elapsed: elapsed,
  );
}

bool has(Diagnosis d, String fragment) =>
    d.findings.any((f) => f.title.contains(fragment));

void main() {
  group('基准', () {
    test('五个行测模块都有基准，且跟技巧页同源', () {
      for (final c in ['changshi', 'yanyu', 'shuliang', 'panduan', 'ziliao']) {
        expect(Benchmark.of(c), isNotNull, reason: c);
      }
      // 常识 30 题 8 分钟 = 16 秒；资料 20 题 27 分钟 = 81 秒。
      expect(Benchmark.of('changshi')!.seconds, 16);
      expect(Benchmark.of('ziliao')!.seconds, 81);
      // 数量不按平均配速算 —— 那个打法是挑着做，用 90 秒的止损线。
      expect(Benchmark.of('shuliang')!.seconds, 90);
    });

    test('题量占比加起来是 1', () {
      final sum = Benchmark.all.values.fold<double>(0, (s, b) => s + b.share);
      expect(sum, closeTo(1.0, 0.001));
    });
  });

  group('单卷诊断', () {
    test('慢得离谱的模块要标成 bad，并算出一套卷多花几分钟', () {
      final d = diagnose({
        // 资料基准 81 秒，这里 130 秒
        'ziliao': (n: 20, correct: 17, seconds: 130),
      });
      final f = d.findings.firstWhere((f) => f.category == 'ziliao');
      expect(f.level, FindingLevel.bad);
      expect(f.evidence, contains('130 秒'));
      expect(f.evidence, contains('81 秒'));
      // (130-81)*20/60 ≈ 16 分钟
      expect(f.evidence, contains('16 分钟'));
    });

    test('又快又准不报警，报表扬', () {
      // 20 题资料的基准是 27 分钟，整卷用时得给个相称的值 ——
      // 否则会额外报一条「整卷超时」，测的就不是模块结论了。
      final d = diagnose(
        {'ziliao': (n: 20, correct: 18, seconds: 70)},
        elapsed: const Duration(minutes: 25),
      );
      expect(
        d.findings.where((f) => f.level == FindingLevel.bad),
        isEmpty,
      );
      expect(has(d, '又快又稳'), isTrue);
    });

    test('正确率差一截要标 bad，差一点标 watch', () {
      // 言语目标 75%
      final bad = diagnose({'yanyu': (n: 25, correct: 13, seconds: 55)});
      expect(
        bad.findings
            .firstWhere((f) => f.title.contains('正确率'))
            .level,
        FindingLevel.bad,
      );

      final watch = diagnose({'yanyu': (n: 25, correct: 17, seconds: 55)});
      expect(
        watch.findings.firstWhere((f) => f.title.contains('差一口气')).level,
        FindingLevel.watch,
      );
    });

    test('题太少的模块不下结论 —— 三道题的正确率是噪声', () {
      final d = diagnose({'yanyu': (n: 3, correct: 0, seconds: 300)});
      expect(d.findings.where((f) => f.category == 'yanyu'), isEmpty);
    });

    test('空在资料分析上，说的是时间在前面丢的', () {
      final d = diagnose({
        'changshi': (n: 30, correct: 18, seconds: 16),
        'ziliao': (n: 20, correct: 10, seconds: 81),
      }, blank: 0);
      expect(has(d, '没做完'), isFalse);

      // 把 changshi 排在前面，blank 会先落在它身上；换成只有资料的卷子来测尾部空题
      final tail = diagnose({'ziliao': (n: 20, correct: 8, seconds: 81)}, blank: 6);
      expect(has(tail, '资料分析没做完'), isTrue);
      final f = tail.findings.firstWhere((f) => f.title.contains('没做完'));
      expect(f.level, FindingLevel.bad);
      expect(f.action, contains('数量关系放最后'));
    });

    test('整卷超时要报，且拿基准分钟数说话', () {
      // 20 题资料，基准 81 秒 = 27 分钟；实际 40 分钟
      final d = diagnose(
        {'ziliao': (n: 20, correct: 17, seconds: 120)},
        elapsed: const Duration(minutes: 40),
      );
      final f = d.findings.firstWhere((f) => f.title == '整卷超时');
      expect(f.evidence, contains('40 分钟'));
      expect(f.evidence, contains('27 分钟'));
    });

    test('结论按严重程度排序，bad 在最前', () {
      final d = diagnose({
        'ziliao': (n: 20, correct: 6, seconds: 130),
        'yanyu': (n: 25, correct: 19, seconds: 55),
      });
      expect(d.findings.first.level, FindingLevel.bad);
      final levels = d.findings.map((f) => f.level.index).toList();
      expect(levels, orderedEquals([...levels]..sort()));
    });

    test('送给模型的摘要只有聚合数字，不含题干', () {
      final d = diagnose({'ziliao': (n: 20, correct: 10, seconds: 130)});
      final prompt = d.toPrompt();
      expect(prompt, contains('资料分析'));
      expect(prompt, contains('基准 81 秒'));
      expect(prompt, isNot(contains('题干 q')));
    });

    test('快而不准要说成"做太快"，不是"不会"', () {
      // 言语基准 55 秒：42 秒一题（快 24%）但只有 46% —— 这是赶工。
      final d = diagnose(
        {'yanyu': (n: 28, correct: 13, seconds: 42)},
        elapsed: const Duration(minutes: 20),
      );
      final f = d.findings.firstWhere((f) => f.category == 'yanyu');
      expect(f.level, FindingLevel.bad);
      expect(f.title, contains('做太快'));
      expect(f.evidence, contains('快 24%'));
      // 处方必须是踩刹车，不能是"练方法"
      expect(f.action, contains('压回 55 秒'));
      // 别再同时报一条泛泛的"正确率不够"
      expect(
        d.findings.where((f) => f.title.contains('正确率离目标')),
        isEmpty,
      );
    });

    test('慢且不准，走的还是正确率那条', () {
      final d = diagnose(
        {'yanyu': (n: 28, correct: 13, seconds: 70)},
        elapsed: const Duration(minutes: 33),
      );
      expect(has(d, '正确率离目标还差一截'), isTrue);
      expect(has(d, '做太快'), isFalse);
    });

    test('题库分类对不上基准时，不许说"没查出短板"', () {
      // 医师、教师编、任意导入的题库都会走到这里。
      final d = diagnose({'内科学': (n: 40, correct: 20, seconds: 60)});
      expect(d.attempts, 40);       // 总数还是真的
      expect(d.modules, isEmpty);   // 但一个模块也比不了
      expect(d.benchmarked, isFalse);
      expect(d.findings, isEmpty);
    });

    test('行测题库上 benchmarked 为真', () {
      final d = diagnose(
        {'ziliao': (n: 20, correct: 18, seconds: 70)},
        elapsed: const Duration(minutes: 25),
      );
      expect(d.benchmarked, isTrue);
    });
  });

  group('年份范围', () {
    test('起始年份按题库最新年份算，不按今天', () {
      expect(YearRange.all.floor(2026), isNull);
      expect(YearRange.last1.floor(2026), 2026);
      expect(YearRange.last3.floor(2026), 2024);
    });
  });
}
