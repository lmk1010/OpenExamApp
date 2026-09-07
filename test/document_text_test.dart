import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openexam_app/data/importers/document_text.dart';

/// docx 和 xlsx 都是 zip 装 XML，这里按真实结构造出来再解，
/// 不然"能读 Word"只是一句话。
void main() {
  List<int> zipOf(Map<String, String> files) {
    final archive = Archive();
    for (final e in files.entries) {
      final bytes = utf8.encode(e.value);
      archive.addFile(ArchiveFile(e.key, bytes.length, bytes));
    }
    return ZipEncoder().encode(archive);
  }

  group('docx', () {
    List<int> docx(String body) => zipOf({
          '[Content_Types].xml': '<Types/>',
          'word/document.xml':
              '<?xml version="1.0"?><w:document><w:body>$body</w:body></w:document>',
        });

    test('段落各成一行', () {
      final doc = DocumentText.extract(
        docx('<w:p><w:r><w:t>第一题</w:t></w:r></w:p>'
            '<w:p><w:r><w:t>A. 选项一</w:t></w:r></w:p>'),
        fileName: 'a.docx',
      );
      expect(doc.isTable, isFalse);
      expect(doc.text.split('\n'), ['第一题', 'A. 选项一']);
    });

    test('一段里的多个片段拼回一句', () {
      // Word 会把一句话按格式切成好几个 w:t，不拼起来就成了碎片
      final doc = DocumentText.extract(
        docx('<w:p><w:r><w:t>下列</w:t></w:r>'
            '<w:r><w:t>哪一项</w:t></w:r>'
            '<w:r><w:t>正确？</w:t></w:r></w:p>'),
        fileName: 'a.docx',
      );
      expect(doc.text, '下列哪一项正确？');
    });

    test('XML 实体还原', () {
      final doc = DocumentText.extract(
        docx('<w:p><w:r><w:t>a &lt; b &amp;&amp; c &gt; d</w:t></w:r></w:p>'),
        fileName: 'a.docx',
      );
      expect(doc.text, 'a < b && c > d');
    });

    test('换行标记转成换行', () {
      final doc = DocumentText.extract(
        docx('<w:p><w:r><w:t>上句</w:t><w:br/><w:t>下句</w:t></w:r></w:p>'),
        fileName: 'a.docx',
      );
      expect(doc.text, '上句\n下句');
    });

    test('没有正文的 docx 不炸', () {
      expect(
        DocumentText.extract(zipOf({'a.txt': 'x'}), fileName: 'a.docx').isEmpty,
        isTrue,
      );
    });
  });

  group('xlsx', () {
    List<int> xlsx({required String sheet, List<String> shared = const []}) =>
        zipOf({
          'xl/sharedStrings.xml':
              '<sst>${shared.map((s) => '<si><t>$s</t></si>').join()}</sst>',
          'xl/worksheets/sheet1.xml': '<worksheet><sheetData>$sheet</sheetData></worksheet>',
        });

    test('共享字符串回填成文字，不是下标', () {
      final doc = DocumentText.extract(
        xlsx(
          shared: ['题干', '答案', '中国的首都是？', 'A'],
          sheet: '<row r="1"><c r="A1" t="s"><v>0</v></c>'
              '<c r="B1" t="s"><v>1</v></c></row>'
              '<row r="2"><c r="A2" t="s"><v>2</v></c>'
              '<c r="B2" t="s"><v>3</v></c></row>',
        ),
        fileName: 'a.xlsx',
      );
      expect(doc.isTable, isTrue);
      expect(doc.rows, [
        ['题干', '答案'],
        ['中国的首都是？', 'A'],
      ]);
    });

    test('中间空着的列不会让后面的串位', () {
      // A 和 C 有值、B 空 —— 按顺序读会把 C 的内容挪到 B
      final doc = DocumentText.extract(
        xlsx(
          shared: ['一', '三'],
          sheet: '<row r="1"><c r="A1" t="s"><v>0</v></c>'
              '<c r="C1" t="s"><v>1</v></c></row>',
        ),
        fileName: 'a.xlsx',
      );
      expect(doc.rows.first, ['一', '', '三']);
    });

    test('数字单元格按原样读', () {
      final doc = DocumentText.extract(
        xlsx(sheet: '<row r="1"><c r="A1"><v>2026</v></c></row>'),
        fileName: 'a.xlsx',
      );
      expect(doc.rows.first, ['2026']);
    });

    test('AB 列的位置算得对', () {
      final doc = DocumentText.extract(
        xlsx(
          shared: ['末列'],
          sheet: '<row r="1"><c r="AB1" t="s"><v>0</v></c></row>',
        ),
        fileName: 'a.xlsx',
      );
      expect(doc.rows.first.length, 28);
      expect(doc.rows.first.last, '末列');
    });

    test('整行空白跳过', () {
      final doc = DocumentText.extract(
        xlsx(
          shared: ['有内容', ''],
          sheet: '<row r="1"><c r="A1" t="s"><v>0</v></c></row>'
              '<row r="2"><c r="A2" t="s"><v>1</v></c></row>',
        ),
        fileName: 'a.xlsx',
      );
      expect(doc.rows.length, 1);
    });
  });

  group('csv', () {
    ExtractedDoc csv(String text) =>
        DocumentText.extract(utf8.encode(text), fileName: 'a.csv');

    test('引号里的逗号不当分隔', () {
      expect(
        csv('题干,答案\n"甲，乙，丙",A').rows,
        [
          ['题干', '答案'],
          ['甲，乙，丙', 'A'],
        ],
      );
    });

    test('引号里的换行留在格子里', () {
      expect(csv('"上\n下",B').rows, [
        ['上\n下', 'B'],
      ]);
    });

    test('两个引号是一个引号', () {
      expect(csv('"他说""好""",C').rows.first.first, '他说"好"');
    });

    test('末行没有换行也算一行', () {
      expect(csv('a,b\nc,d').rows.length, 2);
    });
  });

  test('认得的格式', () {
    for (final f in ['a.docx', 'b.xlsx', 'c.csv', 'd.txt', 'e.md']) {
      expect(DocumentText.canHandle(f), isTrue, reason: f);
    }
    expect(DocumentText.canHandle('f.pdf'), isFalse, reason: 'PDF 走视觉那条路');
  });
}
