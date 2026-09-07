import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openexam_app/data/importers/question_importer.dart';
import 'package:openexam_app/data/models/question.dart';
import 'package:openexam_app/features/bank/bank_export.dart';

Question q(
  String id, {
  String content = '题干',
  String contentHtml = '',
  String material = '',
  String materialId = '',
  String category = 'yanyu',
  String sub = 'xuanci',
  int order = 1,
  bool multi = false,
  List<QuestionOption>? options,
}) =>
    Question(
      id: id,
      content: content,
      contentHtml: contentHtml,
      material: material,
      materialId: materialId,
      options: options ??
          const [
            QuestionOption(key: 'A', text: '选项甲'),
            QuestionOption(key: 'B', text: '选项乙'),
          ],
      answer: multi ? 'AB' : 'A',
      category: category,
      subCategory: sub,
      analysis: '解析正文',
      paperId: 'p1',
      paperTitle: '2026 年测试卷',
      year: 2026,
      orderNum: order,
      isMulti: multi,
    );

void main() {
  group('导出的 JSON 能被导入器读回来', () {
    List<Question> roundTrip(List<Question> src) {
      final json = BankExporter.buildJson(
        src,
        paperId: 'p1',
        paperTitle: '2026 年测试卷',
        year: 2026,
      );
      return QuestionImporter.parseBytes(
        utf8.encode(json),
        fileName: 'questions.json',
      );
    }

    test('题干、选项、答案、解析、分类原样回来', () {
      final back = roundTrip([q('a1')]);
      expect(back, hasLength(1));
      final r = back.single;
      expect(r.content, '题干');
      expect(r.answer, 'A');
      expect(r.analysis, '解析正文');
      expect(r.category, 'yanyu');
      expect(r.subCategory, 'xuanci');
      expect(r.options.map((o) => o.key), ['A', 'B']);
      expect(r.options.map((o) => o.text), ['选项甲', '选项乙']);
    });

    test('多选题回来还是多选 —— 丢了这个标志，多选题在单选界面永远判错', () {
      final back = roundTrip([q('a1', multi: true)]);
      expect(back.single.isMulti, isTrue);
      expect(back.single.answer, 'AB');
    });

    test('卷子信息接得回去', () {
      final back = roundTrip([q('a1')]);
      expect(back.single.paperTitle, '2026 年测试卷');
      expect(back.single.year, 2026);
    });

    test('只导中间几题，题号不被按下标重排', () {
      // 比如只导错题：原卷第 37、58、104 题。按数组下标重排就成了 1、2、3，
      // 跟原卷再也对不上。
      final back = roundTrip([
        q('a1', order: 37),
        q('a2', order: 58),
        q('a3', order: 104),
      ]);
      expect(back.map((e) => e.orderNum), [37, 58, 104]);
    });

    test('一材多题：材料只写一份，导回来仍然共用同一个 material_id', () {
      final back = roundTrip([
        q('a1', material: '同一段材料正文', materialId: 'm1', order: 1),
        q('a2', material: '同一段材料正文', materialId: 'm1', order: 2),
      ]);
      expect(back, hasLength(2));
      expect(back[0].materialId, isNotEmpty);
      expect(back[0].materialId, back[1].materialId);
      expect(back[0].material, '同一段材料正文');
    });
  });

  group('图片', () {
    test('题干、材料、选项里的图都要收集到，一处都不能漏', () {
      final names = BankExporter.imageNamesOf([
        q('a1', contentHtml: '看图<img src="oeimg://aaa">'),
        q('a2', material: '材料图 <img src="oeimg://bbb">'),
        q('a3', options: const [
          QuestionOption(key: 'A', text: 'A', html: '<img src="oeimg://ccc">'),
          QuestionOption(key: 'B', text: 'B', html: '<img src="oeimg://ddd">'),
        ]),
      ]);
      expect(names, {'aaa', 'bbb', 'ccc', 'ddd'});
    });

    test('没有图就是空集合，不该误抓', () {
      expect(BankExporter.imageNamesOf([q('a1')]), isEmpty);
    });
  });

  group('zip 结构', () {
    test('打出来的包里有 questions.json，且能解开', () async {
      final bytes = await BankExporter.buildArchive(
        [q('a1'), q('a2', order: 2)],
        paperId: 'p1',
        paperTitle: '2026 年测试卷',
        year: 2026,
      );
      final archive = ZipDecoder().decodeBytes(bytes);
      final names = archive.files.map((f) => f.name).toList();
      expect(names, contains('questions.json'));

      // 再走一遍真正的导入路径：zip 进去，题出来。
      final bundle = QuestionImporter.parseFile(
        Uint8List.fromList(bytes),
        fileName: 'bank.zip',
      );
      expect(bundle.questions, hasLength(2));
      expect(bundle.questions.first.paperTitle, '2026 年测试卷');
    });
  });

  group('文件名', () {
    test('带题数，收到的人不打开也知道是什么', () {
      expect(BankExporter.fileName('行测真题', 120), contains('120题'));
      expect(BankExporter.fileName('行测真题', 120), endsWith('.zip'));
    });

    test('路径分隔符和空格不能进文件名', () {
      final name = BankExporter.fileName('2026/安徽 省考: 行测', 125);
      expect(name, isNot(contains('/')));
      expect(name, isNot(contains(':')));
      expect(name, isNot(contains(' ')));
    });

    test('名字整个被清光时也要有个能用的文件名', () {
      expect(BankExporter.fileName('///', 3), startsWith('bank-'));
    });
  });
}
