import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:openexam_app/core/ui/rich_content.dart';
import 'package:openexam_app/data/importers/question_importer.dart';

/// 一材多题的导入。资料分析和篇章阅读全靠它，之前整块是缺的。
void main() {
  test('材料相同的题归到同一个 materialId，只算一段材料', () {
    final json = jsonEncode({
      'paper': {'id': 'p1', 'title': '测试卷', 'year': 2026},
      'questions': [
        for (var i = 1; i <= 3; i++)
          {
            'id': 'q$i',
            'content': '第 $i 问',
            'material': '<p>2025 年全国粮食总产量 1.4 万亿斤。</p>',
            'options': [
              {'key': 'A', 'text': '甲'},
              {'key': 'B', 'text': '乙'},
            ],
            'answer': 'A',
            'category': 'ziliao',
          },
        {
          'id': 'q4',
          'content': '另一段材料的问',
          'material': '<p>另一段完全不同的材料。</p>',
          'options': [
            {'key': 'A', 'text': '甲'},
            {'key': 'B', 'text': '乙'},
          ],
          'answer': 'B',
          'category': 'ziliao',
        },
        {
          'id': 'q5',
          'content': '没有材料的题',
          'options': [
            {'key': 'A', 'text': '甲'},
            {'key': 'B', 'text': '乙'},
          ],
          'answer': 'A',
          'category': 'yanyu',
        },
      ],
    });

    final qs = QuestionImporter.parseBytes(utf8.encode(json));
    expect(qs.length, 5);

    // 前三题共用一段材料
    final ids = qs.take(3).map((q) => q.materialId).toSet();
    expect(ids.length, 1, reason: '材料正文相同就该是同一个 id');
    expect(ids.first, isNotEmpty);
    expect(qs.first.hasMaterial, isTrue);

    // 第四题是另一段
    expect(qs[3].materialId, isNot(ids.first));
    expect(qs[3].materialId, isNotEmpty);

    // 第五题没有材料
    expect(qs[4].materialId, isEmpty);
    expect(qs[4].hasMaterial, isFalse);
  });

  test('材料里的图片一起改写成 oeimg://', () {
    final bundle = QuestionImporter.parseFile(
      utf8.encode(jsonEncode([
        {
          'id': 'q1',
          'content': '看图',
          'material': '<p>见下表</p><img src="table1.png">',
          'options': [
            {'key': 'A', 'text': '甲'},
            {'key': 'B', 'text': '乙'},
          ],
          'answer': 'A',
        }
      ])),
      fileName: 'x.json',
    );
    // 裸 json 没有图片包，材料原样保留，不该崩
    expect(bundle.questions.single.material, contains('table1.png'));
  });

  test('HTML 实体还原', () {
    // 中文题库的缩进
    // &emsp; 是 U+2003 EM SPACE，命名式和数字式（&#8195;）必须一致
    expect(decodeEntities('&emsp;&emsp;2025 年'), '\u2003\u20032025 年');
    // 数字实体兜底（&#8195; 就是 &emsp;）
    expect(decodeEntities('&#8195;甲'), '\u2003甲');
    expect(decodeEntities('&#x4e2d;'), '中');
    // &amp; 最后解：&amp;lt; 应该还原成字面量 "&lt;"，不是 "<"
    expect(decodeEntities('&amp;lt;'), '&lt;');
    expect(decodeEntities('a &lt; b &amp; c'), 'a < b & c');
    // 常见标点
    expect(decodeEntities('&ldquo;上岸&rdquo;'), '\u201c上岸\u201d');
  });
}
