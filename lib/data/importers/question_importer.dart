import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:openexam_app/data/models/question.dart';

/// What a file yielded, before anything is written to the database — the
/// import screen shows this so nothing lands unseen.
class ImportBundle {
  const ImportBundle({
    required this.questions,
    required this.images,
    this.warnings = const [],
    this.missingImages = 0,
  });

  final List<Question> questions;

  /// Figure name (without extension) -> bytes, from a zip's images folder.
  final Map<String, Uint8List> images;
  final List<String> warnings;

  /// 题里引用了、但压缩包里没有的图片张数。
  ///
  /// 不在这里拼成一句中文警告 —— 解析器是纯数据层，没有 BuildContext，
  /// 拼出来的中文在英文界面上就是一句突兀的中文。只报数字，界面自己组句。
  final int missingImages;

  bool get isEmpty => questions.isEmpty;

  Map<String, int> get byCategory {
    final out = <String, int>{};
    for (final q in questions) {
      out[q.category.isEmpty ? 'other' : q.category] =
          (out[q.category.isEmpty ? 'other' : q.category] ?? 0) + 1;
    }
    return out;
  }
}

class QuestionImporter {
  /// Zip layout: any `*.json`/`*.csv` at any depth plus an images folder.
  /// Image references in the questions may be plain file names — they get
  /// rewritten to `oeimg://` so the renderer treats them like built-in figures.
  static ImportBundle parseArchive(List<int> bytes) {
    final archive = ZipDecoder().decodeBytes(bytes);
    final images = <String, Uint8List>{};
    final questions = <Question>[];
    final warnings = <String>[];

    for (final file in archive.files) {
      if (!file.isFile) continue;
      final name = file.name.split('/').last;
      if (name.startsWith('.')) continue;
      final lower = name.toLowerCase();
      if (lower.endsWith('.png') ||
          lower.endsWith('.jpg') ||
          lower.endsWith('.jpeg') ||
          lower.endsWith('.webp') ||
          lower.endsWith('.gif')) {
        final base = name.substring(0, name.lastIndexOf('.'));
        images[base] = Uint8List.fromList(file.content as List<int>);
      } else if (lower.endsWith('.json') || lower.endsWith('.csv') || lower.endsWith('.txt')) {
        try {
          questions.addAll(
            parseBytes(file.content as List<int>, fileName: name),
          );
        } catch (e) {
          // 文件名加错误原文就够了，不用再套一句中文 —— 这里没有 context。
          warnings.add('$name: $e');
        }
      }
    }

    // Rewrite <img src="foo.png"> to oeimg://foo when the zip carries it.
    final fixed = questions.map((q) => _rewriteImages(q, images.keys.toSet())).toList();
    final missing = <String>{};
    for (final q in fixed) {
      for (final match in RegExp(r'oeimg://([A-Za-z0-9._-]+)')
          .allMatches('${q.bodyMarkup}\n${q.material}')) {
        if (!images.containsKey(match.group(1))) missing.add(match.group(1)!);
      }
    }
    return ImportBundle(
      questions: fixed,
      images: images,
      warnings: warnings,
      missingImages: missing.length,
    );
  }

  static Question _rewriteImages(Question q, Set<String> names) {
    String fix(String markup) {
      if (markup.isEmpty) return markup;
      return markup.replaceAllMapped(
        RegExp(r'src="([^"]+)"', caseSensitive: false),
        (m) {
          final src = m.group(1)!;
          if (src.startsWith('oeimg://')) return m.group(0)!;
          final file = src.split('/').last;
          final base = file.contains('.')
              ? file.substring(0, file.lastIndexOf('.'))
              : file;
          return names.contains(base) ? 'src="oeimg://$base"' : m.group(0)!;
        },
      );
    }

    return Question(
      id: q.id,
      content: q.content,
      contentHtml: fix(q.contentHtml),
      options: q.options
          .map((o) => QuestionOption(key: o.key, text: o.text, html: fix(o.html)))
          .toList(),
      answer: q.answer,
      category: q.category,
      subCategory: q.subCategory,
      analysis: q.analysis,
      analysisHtml: fix(q.analysisHtml),
      paperId: q.paperId,
      paperTitle: q.paperTitle,
      year: q.year,
      difficulty: q.difficulty,
      source: q.source,
      orderNum: q.orderNum,
      materialId: q.materialId,
      material: fix(q.material),
    );
  }

  /// Single-file import, wrapped so callers get the same shape as a zip.
  static ImportBundle parseFile(List<int> bytes, {required String fileName}) {
    if (fileName.toLowerCase().endsWith('.zip')) return parseArchive(bytes);
    return ImportBundle(
      questions: parseBytes(bytes, fileName: fileName),
      images: const {},
    );
  }

  static List<Question> parseBytes(List<int> bytes, {String fileName = 'import'}) {
    final text = utf8.decode(bytes, allowMalformed: true).trim();
    if (text.isEmpty) return const [];

    if (fileName.toLowerCase().endsWith('.csv') || text.contains(',') && text.contains('\n') && !text.trimLeft().startsWith('[') && !text.trimLeft().startsWith('{')) {
      return _parseCsv(text);
    }
    return _parseJson(text);
  }

  static List<Question> _parseJson(String text) {
    final decoded = jsonDecode(text);
    final items = <dynamic>[];
    Map<String, dynamic> paper = {};
    if (decoded is List) {
      items.addAll(decoded);
    } else if (decoded is Map && decoded['questions'] is List) {
      if (decoded['paper'] is Map) {
        paper = Map<String, dynamic>.from(decoded['paper'] as Map);
      }
      items.addAll(decoded['questions'] as List);
    } else if (decoded is Map) {
      items.add(decoded);
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final materialIds = <String, String>{};
    final paperId = '${paper['id'] ?? ''}';
    final paperTitle = '${paper['title'] ?? ''}';
    final paperYear = paper['year'];
    final out = <Question>[];
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      map['id'] = '${map['id'] ?? map['key'] ?? 'import_${now}_$i'}';
      map['source'] = 'imported';
      if ((map['paperId'] == null || '${map['paperId']}'.isEmpty) && paperId.isNotEmpty) {
        map['paperId'] = paperId;
      }
      if ((map['paperTitle'] == null || '${map['paperTitle']}'.isEmpty) && paperTitle.isNotEmpty) {
        map['paperTitle'] = paperTitle;
      }
      if (map['year'] == null && paperYear != null) {
        map['year'] = paperYear;
      }
      if (map['orderNum'] == null && map['order_num'] == null) {
        map['orderNum'] = i + 1;
      }
      if ((map['category'] == null || '${map['category']}'.isEmpty) && map['module'] != null) {
        map['category'] = _guessCategory('${map['module']}');
      }
      // Pei-Pei / Fenbi-like option shapes
      if (map['options'] is List) {
        final opts = <Map<String, dynamic>>[];
        final raw = map['options'] as List;
        for (var j = 0; j < raw.length; j++) {
          final o = raw[j];
          if (o is Map) {
            final key = '${o['key'] ?? o['label'] ?? String.fromCharCode(65 + j)}';
            final text = '${o['text'] ?? o['content'] ?? o['value'] ?? ''}';
            // html 必须原样带过去。图形推理的选项本身就是图：text 是空的，
            // 内容全在 html 里的 oeimg://。这里把 html 抹掉的话，
            // QuestionOption.isUsable 判它没用 → 选项被丢 → 不足两个 →
            // 整道题被丢。自己导出的包再导回来也会少题。
            final html = '${o['html'] ?? ''}';
            opts.add({'key': key, 'text': text, if (html.isNotEmpty) 'html': html});
          } else {
            opts.add({'key': String.fromCharCode(65 + j), 'text': '$o'});
          }
        }
        map['options'] = opts;
      }
      // 一材多题：同一批里材料正文相同的题，自动归到同一个 material_id。
      // 导出方通常每题都重复一遍材料，不去重的话一段材料会存五份。
      final material = '${map['material'] ?? map['材料'] ?? ''}'.trim();
      if (material.isNotEmpty) {
        map['material'] = material;
        map['materialId'] = '${map['materialId'] ?? map['material_id'] ?? ''}'
                .trim()
                .isNotEmpty
            ? '${map['materialId'] ?? map['material_id']}'
            : materialIds.putIfAbsent(
                material,
                () => 'mat_${now}_${materialIds.length + 1}',
              );
      }

      final q = Question.fromJson(map);
      if (q.content.isNotEmpty && q.options.length >= 2 && q.answer.isNotEmpty) {
        out.add(q);
      }
    }
    return out;
  }

  static List<Question> _parseCsv(String text) {
    final lines = const LineSplitter().convert(text).where((e) => e.trim().isNotEmpty).toList();
    if (lines.length < 2) return const [];
    final header = _splitCsv(lines.first).map((e) => e.trim().toLowerCase()).toList();
    int idx(String name) => header.indexOf(name);

    final idI = idx('id');
    final contentI = [idx('content'), idx('title'), idx('题干'), idx('题目')].firstWhere((e) => e >= 0, orElse: () => -1);
    final answerI = [idx('answer'), idx('答案')].firstWhere((e) => e >= 0, orElse: () => -1);
    final catI = [idx('category'), idx('模块'), idx('题型')].firstWhere((e) => e >= 0, orElse: () => -1);
    final analysisI = [idx('analysis'), idx('解析')].firstWhere((e) => e >= 0, orElse: () => -1);
    final aI = [idx('a'), idx('option_a'), idx('选项a')].firstWhere((e) => e >= 0, orElse: () => -1);
    final bI = [idx('b'), idx('option_b'), idx('选项b')].firstWhere((e) => e >= 0, orElse: () => -1);
    final cI = [idx('c'), idx('option_c'), idx('选项c')].firstWhere((e) => e >= 0, orElse: () => -1);
    final dI = [idx('d'), idx('option_d'), idx('选项d')].firstWhere((e) => e >= 0, orElse: () => -1);

    if (contentI < 0 || answerI < 0 || aI < 0 || bI < 0) return const [];

    final now = DateTime.now().millisecondsSinceEpoch;
    final out = <Question>[];
    for (var i = 1; i < lines.length; i++) {
      final cols = _splitCsv(lines[i]);
      String at(int i) => i >= 0 && i < cols.length ? cols[i].trim() : '';
      final options = <QuestionOption>[
        QuestionOption(key: 'A', text: at(aI)),
        QuestionOption(key: 'B', text: at(bI)),
      ];
      if (at(cI).isNotEmpty) options.add(QuestionOption(key: 'C', text: at(cI)));
      if (at(dI).isNotEmpty) options.add(QuestionOption(key: 'D', text: at(dI)));
      final content = at(contentI);
      final answer = at(answerI).toUpperCase();
      if (content.isEmpty || answer.isEmpty || options.length < 2) continue;
      out.add(Question(
        id: at(idI).isEmpty ? 'csv_${now}_$i' : at(idI),
        content: content,
        options: options,
        answer: answer,
        category: _guessCategory(at(catI)),
        analysis: at(analysisI),
        paperTitle: '',
        source: 'imported',
      ));
    }
    return out;
  }

  static String _guessCategory(String raw) {
    final t = raw.toLowerCase();
    if (t.contains('言语') || t.contains('yanyu')) return 'yanyu';
    if (t.contains('数量') || t.contains('shuliang')) return 'shuliang';
    if (t.contains('判断') || t.contains('panduan')) return 'panduan';
    if (t.contains('资料') || t.contains('ziliao')) return 'ziliao';
    if (t.contains('常识') || t.contains('changshi')) return 'changshi';
    if (t.startsWith('cs_')) return raw;
    if (t.contains('计算机') || t.contains('computer') || t.contains('计基')) return 'cs_base';
    if (t.contains('安全')) return 'cs_security';
    if (t.contains('windows') || t.contains('系统')) return 'cs_windows';
    if (t.contains('office') || t.contains('excel') || t.contains('word') || t.contains('办公')) {
      return 'cs_office';
    }
    if (t.contains('程序') || t.contains('编程') || t.contains('c语言')) return 'cs_prog';
    if (t.contains('数据库') || t.contains('sql')) return 'cs_db';
    if (t.contains('网络')) return 'cs_net';
    if (t.contains('软件工程') || t.contains('软工')) return 'cs_se';
    return raw.isEmpty ? 'yanyu' : raw;
  }

  static List<String> _splitCsv(String line) {
    final result = <String>[];
    final buf = StringBuffer();
    var inQuotes = false;
    for (var i = 0; i < line.length; i++) {
      final ch = line[i];
      if (ch == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          buf.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (ch == ',' && !inQuotes) {
        result.add(buf.toString());
        buf.clear();
      } else {
        buf.write(ch);
      }
    }
    result.add(buf.toString());
    return result;
  }
}
