import 'dart:convert';

import 'package:archive/archive.dart';

/// 从一个文件里读出来的东西。
///
/// 两种形态：表格类（xlsx / csv）读出来是行列，一行往往就是一道题，能直接
/// 按列映射，不必花钱让模型读一遍；文档类（docx / txt / md）读出来是长文本，
/// 得交给模型断题。
class ExtractedDoc {
  const ExtractedDoc({
    required this.kind,
    this.text = '',
    this.rows = const [],
    this.sheetName = '',
  });

  final DocKind kind;

  /// 文档类的正文。
  final String text;

  /// 表格类的行，每行是一格一格的字符串。
  final List<List<String>> rows;

  final String sheetName;

  bool get isTable => kind == DocKind.table;
  bool get isEmpty => isTable ? rows.isEmpty : text.trim().isEmpty;

  /// 表格前几行的样子，给模型看着猜哪列是什么。
  String preview({int rows = 6}) {
    if (!isTable) {
      return text.length <= 2000 ? text : '${text.substring(0, 2000)}…';
    }
    return this
        .rows
        .take(rows)
        .map((r) => r.map((c) => c.replaceAll('\n', ' ')).join(' | '))
        .join('\n');
  }
}

enum DocKind { table, document }

/// 各种格式 → 文本或表格。
///
/// 全是纯 Dart：docx 和 xlsx 本质都是 zip 装着 XML，用已有的 archive 就能拆，
/// 不为这个引入新依赖。PDF 不在这儿 —— 它走渲染成图给视觉模型那条路。
class DocumentText {
  /// 认得的后缀。
  static const supported = {'docx', 'xlsx', 'csv', 'txt', 'md', 'json'};

  static bool canHandle(String fileName) =>
      supported.contains(_ext(fileName));

  static String _ext(String fileName) {
    final i = fileName.lastIndexOf('.');
    return i < 0 ? '' : fileName.substring(i + 1).toLowerCase();
  }

  static ExtractedDoc extract(List<int> bytes, {required String fileName}) {
    switch (_ext(fileName)) {
      case 'docx':
        return ExtractedDoc(kind: DocKind.document, text: _docx(bytes));
      case 'xlsx':
        return _xlsx(bytes);
      case 'csv':
        return ExtractedDoc(
          kind: DocKind.table,
          rows: _csv(_decode(bytes)),
        );
      default:
        return ExtractedDoc(kind: DocKind.document, text: _decode(bytes));
    }
  }

  // ------------------------------------------------------------------- docx

  /// Word 正文。
  ///
  /// docx 是 zip，正文在 word/document.xml。只取 `<w:t>` 里的文字，段落
  /// (`</w:p>`) 和换行 (`<w:br/>`) 转成换行符 —— 样式、批注、页眉全不要，
  /// 它们只会把喂给模型的内容撑大。
  static String _docx(List<int> bytes) {
    final archive = ZipDecoder().decodeBytes(bytes);
    final entry = archive.files.where((f) => f.name == 'word/document.xml');
    if (entry.isEmpty) return '';
    var xml = utf8.decode(entry.first.content as List<int>, allowMalformed: true);

    // 先把换行类标记换成占位，免得下一步剥标签时连位置都没了
    xml = xml
        .replaceAll(RegExp(r'<w:br\s*/?>'), '\n')
        .replaceAll(RegExp(r'<w:tab\s*/?>'), '\t')
        .replaceAll(RegExp(r'</w:p>'), '\n');

    // 表格单元格之间补个分隔，否则一行表格会黏成一坨
    xml = xml.replaceAll(RegExp(r'</w:tc>'), '\t');

    final buf = StringBuffer();
    for (final m in RegExp(r'<w:t[^>]*>(.*?)</w:t>', dotAll: true).allMatches(xml)) {
      buf.write(_unescape(m.group(1) ?? ''));
    }
    // 上面按 w:t 拼，换行占位在标签之外会被丢掉，所以这里再走一遍原文补结构
    final structured = xml
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll(RegExp(r'[ \t]*\n[ \t]*'), '\n');
    final text = _unescape(structured).trim().isEmpty
        ? buf.toString()
        : _unescape(structured);
    return _tidy(text);
  }

  // ------------------------------------------------------------------- xlsx

  /// Excel 第一张表。
  ///
  /// 字符串单元格存的是 sharedStrings 里的下标（`t="s"`），得先把那张表读出来
  /// 再回填，否则拿到的全是数字。
  static ExtractedDoc _xlsx(List<int> bytes) {
    final archive = ZipDecoder().decodeBytes(bytes);

    String? read(String name) {
      final hit = archive.files.where((f) => f.name == name);
      if (hit.isEmpty) return null;
      return utf8.decode(hit.first.content as List<int>, allowMalformed: true);
    }

    final shared = <String>[];
    final sharedXml = read('xl/sharedStrings.xml');
    if (sharedXml != null) {
      for (final si in RegExp(r'<si>(.*?)</si>', dotAll: true).allMatches(sharedXml)) {
        final buf = StringBuffer();
        for (final t in RegExp(r'<t[^>]*>(.*?)</t>', dotAll: true)
            .allMatches(si.group(1) ?? '')) {
          buf.write(_unescape(t.group(1) ?? ''));
        }
        shared.add(buf.toString());
      }
    }

    // 工作表文件名不固定，取排序后的第一个
    final sheetNames = archive.files
        .map((f) => f.name)
        .where((n) => n.startsWith('xl/worksheets/') && n.endsWith('.xml'))
        .toList()
      ..sort();
    if (sheetNames.isEmpty) return const ExtractedDoc(kind: DocKind.table);
    final sheet = read(sheetNames.first) ?? '';

    final rows = <List<String>>[];
    for (final rowM in RegExp(r'<row[^>]*>(.*?)</row>', dotAll: true).allMatches(sheet)) {
      final cells = <int, String>{};
      var maxCol = -1;
      for (final cM in RegExp(r'<c([^>]*)>(.*?)</c>', dotAll: true)
          .allMatches(rowM.group(1) ?? '')) {
        final attrs = cM.group(1) ?? '';
        final body = cM.group(2) ?? '';
        final ref = RegExp(r'r="([A-Z]+)\d+"').firstMatch(attrs)?.group(1);
        final col = ref == null ? maxCol + 1 : _colOf(ref);
        final isShared = attrs.contains('t="s"');
        final isInline = attrs.contains('t="inlineStr"');

        String value;
        if (isInline) {
          value = RegExp(r'<t[^>]*>(.*?)</t>', dotAll: true)
                  .allMatches(body)
                  .map((m) => _unescape(m.group(1) ?? ''))
                  .join() ;
        } else {
          final raw = RegExp(r'<v>(.*?)</v>', dotAll: true).firstMatch(body)?.group(1) ?? '';
          if (isShared) {
            final idx = int.tryParse(raw) ?? -1;
            value = (idx >= 0 && idx < shared.length) ? shared[idx] : '';
          } else {
            value = _unescape(raw);
          }
        }
        cells[col] = value;
        if (col > maxCol) maxCol = col;
      }
      if (maxCol < 0) continue;
      final row = [for (var i = 0; i <= maxCol; i++) cells[i] ?? ''];
      if (row.every((c) => c.trim().isEmpty)) continue;
      rows.add(row);
    }

    return ExtractedDoc(
      kind: DocKind.table,
      rows: rows,
      sheetName: sheetNames.first.split('/').last,
    );
  }

  /// "A" → 0，"AB" → 27。
  static int _colOf(String letters) {
    var n = 0;
    for (final c in letters.codeUnits) {
      n = n * 26 + (c - 64); // 'A' = 65
    }
    return n - 1;
  }

  // -------------------------------------------------------------------- csv

  /// 带引号的 CSV。引号里的逗号和换行都不算分隔。
  static List<List<String>> _csv(String text) {
    final rows = <List<String>>[];
    var row = <String>[];
    final cell = StringBuffer();
    var quoted = false;

    for (var i = 0; i < text.length; i++) {
      final ch = text[i];
      if (quoted) {
        if (ch == '"') {
          if (i + 1 < text.length && text[i + 1] == '"') {
            cell.write('"');
            i++;
          } else {
            quoted = false;
          }
        } else {
          cell.write(ch);
        }
        continue;
      }
      switch (ch) {
        case '"':
          quoted = true;
        case ',':
          row.add(cell.toString());
          cell.clear();
        case '\r':
          break;
        case '\n':
          row.add(cell.toString());
          cell.clear();
          if (row.any((c) => c.trim().isNotEmpty)) rows.add(row);
          row = <String>[];
        default:
          cell.write(ch);
      }
    }
    if (cell.isNotEmpty || row.isNotEmpty) {
      row.add(cell.toString());
      if (row.any((c) => c.trim().isNotEmpty)) rows.add(row);
    }
    return rows;
  }

  // ------------------------------------------------------------------ 杂活

  static String _decode(List<int> bytes) {
    try {
      return utf8.decode(bytes);
    } catch (_) {
      // 国内导出的 txt/csv 常是 GBK。没有解码器，至少别整个失败
      return latin1.decode(bytes, allowInvalid: true);
    }
  }

  static String _unescape(String s) => s
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&apos;', "'")
      .replaceAll('&#10;', '\n')
      .replaceAll('&amp;', '&');

  static String _tidy(String s) => s
      .replaceAll('\r\n', '\n')
      .replaceAll(RegExp(r'[ \t]+\n'), '\n')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();
}
