import 'dart:convert';

import 'package:openexam_app/data/models/question.dart';

class QuestionImporter {
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
    if (decoded is List) {
      items.addAll(decoded);
    } else if (decoded is Map && decoded['questions'] is List) {
      items.addAll(decoded['questions'] as List);
    } else if (decoded is Map) {
      items.add(decoded);
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final out = <Question>[];
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      map['id'] = '${map['id'] ?? map['key'] ?? 'import_${now}_$i'}';
      map['source'] = 'imported';
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
            opts.add({'key': key, 'text': text});
          } else {
            opts.add({'key': String.fromCharCode(65 + j), 'text': '$o'});
          }
        }
        map['options'] = opts;
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
        paperTitle: '用户导入',
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
