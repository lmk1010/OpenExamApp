import 'package:flutter_test/flutter_test.dart';
import 'package:openexam_app/data/importers/doc_parser.dart';
import 'package:openexam_app/data/models/question.dart';

/// 导入管线里最容易翻车的三处：切块把题切断、答案表回填错位、
/// 选项挤在一格里拆不开。这些都是纯逻辑，不用连网也能验。
void main() {
  Question q(String content, {String answer = ''}) => Question(
        id: content,
        content: content,
        options: const [
          QuestionOption(key: 'A', text: '甲'),
          QuestionOption(key: 'B', text: '乙'),
        ],
        answer: answer,
        category: '',
      );

  group('切块', () {
    test('短文本就一块', () {
      expect(chunkForParsing('就一句话。').length, 1);
    });

    test('长文本切多块，且每块都带上一块的尾巴', () {
      final text = List.generate(400, (i) => '第 $i 段内容填充填充填充').join('\n');
      final chunks = chunkForParsing(text);
      expect(chunks.length, greaterThan(1));
      // 重叠的意义：上一块结尾的内容要在下一块开头再出现一次
      final tailOfFirst = chunks.first.trim().split('\n').last;
      expect(chunks[1], contains(tailOfFirst));
    });

    test('切完不丢内容', () {
      final text = List.generate(200, (i) => '行$i').join('\n');
      final joined = chunkForParsing(text).join('\n');
      for (final i in [0, 99, 199]) {
        expect(joined, contains('行$i'));
      }
    });
  });

  group('答案表回填', () {
    test('从末尾的答案表按题号填', () {
      final questions = [q('第一题'), q('第二题'), q('第三题'), q('第四题')];
      const text = '''
第一题 …
第二题 …
第三题 …
第四题 …
参考答案
1.A 2.C 3.B 4.D
''';
      final filled = fillAnswersFromKey(questions, text);
      expect(filled.map((e) => e.answer), ['A', 'C', 'B', 'D']);
    });

    test('已经有答案的不覆盖', () {
      final questions = [q('第一题', answer: 'B'), q('第二题')];
      final filled = fillAnswersFromKey(questions, '1.A 2.C');
      expect(filled.first.answer, 'B', reason: '解析阶段拿到的答案更可信');
      expect(filled[1].answer, 'C');
    });

    test('命中太少就整个不填，宁可空着也别填错', () {
      // 只有一组编号，四道题 —— 多半是题干里的序号，不是答案表
      final questions = [q('一'), q('二'), q('三'), q('四')];
      final filled = fillAnswersFromKey(questions, '见第 3 页 A 部分');
      expect(filled.every((e) => e.answer.isEmpty), isTrue);
    });

    test('全都有答案时原样返回', () {
      final questions = [q('一', answer: 'A'), q('二', answer: 'B')];
      expect(identical(fillAnswersFromKey(questions, '1.C 2.D'), questions), isTrue);
    });
  });

  group('一格里的选项', () {
    test('A. 甲 B. 乙 这种拆得开', () {
      final opts = splitInlineOptions('A.北京 B.上海 C.广州 D.深圳');
      expect(opts.map((e) => e.key), ['A', 'B', 'C', 'D']);
      expect(opts.map((e) => e.text), ['北京', '上海', '广州', '深圳']);
    });

    test('顿号、括号这些标号也认', () {
      expect(splitInlineOptions('A、甲 B、乙').length, 2);
      expect(splitInlineOptions('A）甲 B）乙').length, 2);
    });

    test('没有字母标号就按换行拆', () {
      final opts = splitInlineOptions('甲\n乙\n丙');
      expect(opts.map((e) => e.key), ['A', 'B', 'C']);
      expect(opts.last.text, '丙');
    });

    test('拆不出两个就当没有', () {
      expect(splitInlineOptions('就一个'), isEmpty);
      expect(splitInlineOptions(''), isEmpty);
    });
  });

  group('宽松 JSON 转题目', () {
    test('常规一道题', () {
      final r = questionFromLooseJson({
        'content': '中国的首都是？',
        'options': [
          {'key': 'A', 'text': '北京'},
          {'key': 'B', 'text': '上海'},
        ],
        'answer': 'A',
        'category': '地理常识',
      });
      expect(r, isNotNull);
      expect(r!.answer, 'A');
      // 分类用资料自己的叫法，不硬套成行测那五个模块
      expect(r.category, '地理常识');
      expect(r.source, 'import');
    });

    test('选项是纯字符串数组也认', () {
      final r = questionFromLooseJson({
        'stem': '题干',
        'options': ['甲', '乙', '丙'],
        'answer': 'C',
      });
      expect(r!.options.map((e) => e.key), ['A', 'B', 'C']);
      expect(r.answer, 'C');
    });

    test('答案不在选项里就置空，不硬塞', () {
      final r = questionFromLooseJson({
        'content': '题干',
        'options': ['甲', '乙'],
        'answer': '正确',
      });
      expect(r!.answer, isEmpty);
    });

    test('选项不足两个不算题', () {
      expect(
        questionFromLooseJson({'content': '题干', 'options': ['只有一个']}),
        isNull,
      );
    });

    test('没题干不算题', () {
      expect(questionFromLooseJson({'options': ['甲', '乙']}), isNull);
    });
  });
}
