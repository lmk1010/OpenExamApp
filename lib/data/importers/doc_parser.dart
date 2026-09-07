
import 'package:openexam_app/l10n/app_localizations.dart';
import 'package:openexam_app/core/ai/ai_client.dart';
import 'package:openexam_app/core/ai/ai_settings.dart';
import 'package:openexam_app/data/importers/document_text.dart';
import 'package:openexam_app/data/models/question.dart';

/// 解析进度，一步一条，用来在界面上显示"到哪了"。
class ParseProgress {
  const ParseProgress({
    required this.done,
    required this.total,
    required this.note,
    this.questions = const [],
  });

  final int done;
  final int total;
  final String note;

  /// 到目前为止解出来的题，边解边往上加。
  final List<Question> questions;

  double get ratio => total == 0 ? 0 : done / total;
}

/// 把一份文档变成题目。
///
/// 两条路，走哪条看文件本身：
///
/// - **表格**（xlsx / csv）：一行通常就是一道题。先花一次调用让模型认出
///   哪列是题干、哪列是答案，之后成千上万行都在本地转换 —— 一万道题
///   一次 API 调用，而不是一万次。
/// - **文档**（docx / txt / md）：没有结构可依，只能切块交给模型断题。
///
/// 不绑定任何考试。category 是模型按文档内容自己起的名字，考公、教资、
/// 法考都一样处理 —— 这个 app 不该只认行测那五个模块。
class DocParser {
  const DocParser(this.settings, this.l);

  final AiSettings settings;

  /// 报错和进度文案由调用方传进来 —— 这一层没有 BuildContext。
  final AppL l;

  Stream<ParseProgress> parse(
    ExtractedDoc doc, {
    String? subjectHint,
  }) async* {
    if (doc.isEmpty) {
      yield ParseProgress(done: 0, total: 0, note: l.docNoContent);
      return;
    }
    if (doc.isTable) {
      yield* _parseTable(doc, subjectHint: subjectHint);
    } else {
      yield* _parseText(doc.text, subjectHint: subjectHint);
    }
  }

  // ------------------------------------------------------------------- 表格

  Stream<ParseProgress> _parseTable(
    ExtractedDoc doc, {
    String? subjectHint,
  }) async* {
    yield ParseProgress(done: 0, total: 1, note: l.docLookingAtTable);

    final mapping = await _columnMapping(doc, subjectHint: subjectHint);
    if (mapping == null) {
      yield ParseProgress(done: 0, total: 1, note: l.docUnknownColumns);
      return;
    }

    // 表头那几行不是题
    final body = doc.rows.skip(mapping.headerRows).toList();
    final out = <Question>[];
    for (var i = 0; i < body.length; i++) {
      final q = mapping.toQuestion(body[i], index: i);
      if (q != null) out.add(q);
      // 本地转换很快，没必要一行一个事件
      if (i % 50 == 0 || i == body.length - 1) {
        yield ParseProgress(
          done: i + 1,
          total: body.length,
          note: l.docFoundQuestions(out.length),
          questions: List.unmodifiable(out),
        );
      }
    }
    // 表格只调一次模型，分类天生比逐块解析一致；但空分类同样要有落脚处
    final tidy = normalizeCategories(out);
    yield ParseProgress(
      done: body.length,
      total: body.length,
      note: tidy.isEmpty ? l.docNoneInTable : l.docFoundQuestions(tidy.length),
      questions: List.unmodifiable(tidy),
    );
  }

  /// 让模型看前几行，说清楚哪列是什么。只调一次。
  Future<_ColumnMapping?> _columnMapping(
    ExtractedDoc doc, {
    String? subjectHint,
  }) async {
    AiClient.feature = 'import';
    final result = await AiClient(settings, l).completeJson(
      system: _tableSystem,
      prompt: '这是一张题库表的前几行'
          '${subjectHint == null ? '' : '（科目：$subjectHint）'}：\n\n'
          '${doc.preview(rows: 8)}\n\n'
          '总列数 ${doc.rows.isEmpty ? 0 : doc.rows.first.length}。',
    );
    if (!result.isOk || result.value == null) return null;
    return _ColumnMapping.fromJson(result.value!);
  }

  // ------------------------------------------------------------------- 文档

  Stream<ParseProgress> _parseText(String text, {String? subjectHint}) async* {
    final chunks = _chunk(text);
    final out = <Question>[];
    final seen = <String>{};

    for (var i = 0; i < chunks.length; i++) {
      yield ParseProgress(
        done: i,
        total: chunks.length,
        note: l.docChunk(i + 1, chunks.length),
        questions: List.unmodifiable(out),
      );

      // 把前面已经认出来的分类名带上。不带的话每块都是从零判断，
      // 第一块写"数据库"、第五块写"数据库系统"、第十二块写"数据库技术"，
      // 一个科目会裂成三张卡片 —— 这是分块解析最容易翻车的地方。
      final known = out.map((q) => q.category).where((c) => c.isNotEmpty).toSet();
      AiClient.feature = 'import';
      final result = await AiClient(settings, l).completeJson(
        system: _textSystem,
        prompt: '${subjectHint == null ? '' : '科目：$subjectHint\n\n'}'
            '${known.isEmpty ? '' : '这份资料前面已经用过这些分类：'
                '${known.join('、')}。'
                '能归进去的就用原名，不要另起近义的新名字。\n\n'}'
            '下面是资料的第 ${i + 1} 段，把其中完整的题抽出来：\n\n${chunks[i]}',
        maxTokens: 8192,
      );
      if (!result.isOk || result.value == null) continue;

      for (final q in _questionsFrom(result.value!)) {
        // 相邻块有重叠，同一道题会被切进两块里，按题干去重
        final key = q.content.replaceAll(RegExp(r'\s+'), '');
        if (key.isEmpty || !seen.add(key)) continue;
        out.add(q);
      }
    }

    // 很多资料把答案统一放在末尾（"1.A 2.C 3.B…"），逐段解析时前面的题
    // 根本看不到自己的答案。扫完再从全文找答案表，按题号回填。
    final filled = normalizeCategories(_fillAnswers(out, text));

    yield ParseProgress(
      done: chunks.length,
      total: chunks.length,
      note: filled.isEmpty ? l.docNoWholeQuestions : l.docFoundQuestions(filled.length),
      questions: List.unmodifiable(filled),
    );
  }

  /// 按段落边界切块，尽量不从一道题中间断开。
  static List<String> _chunk(String text) => chunkForParsing(text);



  /// 从全文尾部的答案表里按题号回填。
  ///
  /// 只填原本没答案的题，已经解析到答案的不动 —— 题号对不齐时宁可少填。
  static List<Question> _fillAnswers(List<Question> questions, String text) =>
      fillAnswersFromKey(questions, text);





  static List<Question> _questionsFrom(Map<String, dynamic> json) {
    final raw = json['questions'];
    if (raw is! List) return const [];
    final out = <Question>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final q = questionFromLooseJson(Map<String, Object?>.from(item));
      if (q != null) out.add(q);
    }
    return out;
  }
}

Question _withAnswer(Question q, String answer) => Question(
      id: q.id,
      content: q.content,
      contentHtml: q.contentHtml,
      options: q.options,
      answer: answer,
      category: q.category,
      subCategory: q.subCategory,
      analysis: q.analysis,
      analysisHtml: q.analysisHtml,
      paperId: q.paperId,
      paperTitle: q.paperTitle,
      year: q.year,
      difficulty: q.difficulty,
      source: q.source,
      orderNum: q.orderNum,
      materialId: q.materialId,
      material: q.material,
      isMulti: q.isMulti,
    );

/// 一次喂给模型多少字。太大容易漏题、也容易顶到输出上限。
const _chunkChars = 3000;

/// 相邻两块重叠一点，免得正好在一道题中间切开。
const _overlapChars = 260;

/// 把长文本切成一块块喂给模型。
///
/// 按段落边界切，相邻两块重叠一小段 —— 正好切在一道题中间的话，
/// 两块各拿到半道，谁也认不出来。重叠部分带来的重复由调用方按题干去重。
List<String> chunkForParsing(String text) {
  final paragraphs = text.split('\n');
  final chunks = <String>[];
  final buf = StringBuffer();

  for (final p in paragraphs) {
    if (buf.length + p.length > _chunkChars && buf.isNotEmpty) {
      final s = buf.toString();
      chunks.add(s);
      buf.clear();
      // 把上一块的尾巴带进下一块
      final tail = s.length <= _overlapChars
          ? s
          : s.substring(s.length - _overlapChars);
      buf.writeln(tail);
    }
    buf.writeln(p);
  }
  if (buf.toString().trim().isNotEmpty) chunks.add(buf.toString());
  return chunks;
}

List<Question> fillAnswersFromKey(List<Question> questions, String text) {
  final missing = questions.where((q) => q.answer.isEmpty).length;
  if (missing == 0) return questions;

  // "1.A" "1、A" "1 A" "1．A"，一行里可能连着好几组
  final table = <int, String>{};
  for (final m in RegExp(r'(\d{1,3})\s*[.．、:：]?\s*([A-Da-d])(?![A-Za-z一-龥])')
      .allMatches(text)) {
    final no = int.tryParse(m.group(1) ?? '');
    if (no == null) continue;
    table[no] = m.group(2)!.toUpperCase();
  }
  // 命中的数量还不如题数的一半，八成是把题干里的编号当成答案了，不冒这个险
  if (table.length < questions.length ~/ 2) return questions;

  return [
    for (var i = 0; i < questions.length; i++)
      questions[i].answer.isNotEmpty
          ? questions[i]
          : _withAnswer(questions[i], table[i + 1] ?? ''),
  ];
}

List<QuestionOption> splitInlineOptions(String cell) {
  if (cell.trim().isEmpty) return const [];
  final matches = RegExp(
    r'([A-Da-d])\s*[.．、:：)）]\s*([^A-Da-d]*(?:[A-Da-d](?![.．、:：)）])[^A-Da-d]*)*)',
  ).allMatches(cell).toList();
  if (matches.length < 2) {
    // 没有字母标号，退回按换行拆
    final lines = cell
        .split(RegExp(r'[\n;；]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (lines.length < 2) return const [];
    return [
      for (var i = 0; i < lines.length; i++)
        QuestionOption(key: String.fromCharCode(65 + i), text: lines[i]),
    ];
  }
  return [
    for (final m in matches)
      QuestionOption(
        key: m.group(1)!.toUpperCase(),
        text: (m.group(2) ?? '').trim(),
      ),
  ];
}

/// 一道题最少要有的东西：题干和两个选项。缺了就不是题。
Question? questionFromLooseJson(Map<String, Object?> map) {
  final stem = '${map['content'] ?? map['stem'] ?? ''}'.trim();
  if (stem.isEmpty) return null;

  final options = <QuestionOption>[];
  final rawOptions = map['options'];
  if (rawOptions is List) {
    for (var i = 0; i < rawOptions.length; i++) {
      final o = rawOptions[i];
      final key = o is Map
          ? '${o['key'] ?? String.fromCharCode(65 + i)}'
          : String.fromCharCode(65 + i);
      final textValue = o is Map ? '${o['text'] ?? ''}' : '$o';
      if (textValue.trim().isEmpty) continue;
      options.add(QuestionOption(
        key: key.trim().toUpperCase(),
        text: textValue.trim(),
      ));
    }
  }
  if (options.length < 2) return null;

  final answer = '${map['answer'] ?? ''}'.trim().toUpperCase();
  return Question(
    id: 'imp_${DateTime.now().microsecondsSinceEpoch}_${stem.hashCode}',
    content: stem,
    options: options,
    // 答案只认选项里真有的字母，模型偶尔会回 "正确" 这种
    answer: options.any((o) => o.key == answer) ? answer : '',
    category: '${map['category'] ?? ''}'.trim(),
    subCategory: '${map['subCategory'] ?? map['sub_category'] ?? ''}'.trim(),
    analysis: '${map['analysis'] ?? ''}'.trim(),
    source: 'import',
  );
}

/// 表格里每列是什么。
class _ColumnMapping {
  const _ColumnMapping({
    required this.headerRows,
    required this.stem,
    required this.options,
    required this.answer,
    this.analysis,
    this.category,
    this.optionsInOneCell = false,
  });

  /// 前几行是表头，不是题。
  final int headerRows;
  final int stem;

  /// 选项各占一列时是那几列的下标。
  final List<int> options;
  final int answer;
  final int? analysis;
  final int? category;

  /// 选项挤在一个格子里（"A.甲 B.乙 C.丙"），要就地拆开。
  final bool optionsInOneCell;

  static _ColumnMapping? fromJson(Map<String, dynamic> json) {
    int? num(Object? v) {
      if (v == null) return null;
      final n = int.tryParse('$v');
      return (n == null || n < 0) ? null : n;
    }

    final stem = num(json['stem']);
    final answer = num(json['answer']);
    if (stem == null || answer == null) return null;

    final rawOptions = json['options'];
    final options = <int>[];
    if (rawOptions is List) {
      for (final o in rawOptions) {
        final n = num(o);
        if (n != null) options.add(n);
      }
    }
    final single = num(rawOptions is List ? null : rawOptions);
    return _ColumnMapping(
      headerRows: num(json['headerRows']) ?? 1,
      stem: stem,
      options: options.isNotEmpty ? options : [if (single != null) single],
      answer: answer,
      analysis: num(json['analysis']),
      category: num(json['category']),
      optionsInOneCell: options.length < 2,
    );
  }

  String _at(List<String> row, int? i) =>
      (i == null || i < 0 || i >= row.length) ? '' : row[i].trim();

  Question? toQuestion(List<String> row, {required int index}) {
    final stemText = _at(row, stem);
    if (stemText.isEmpty) return null;

    final opts = <QuestionOption>[];
    if (optionsInOneCell) {
      opts.addAll(_splitOptions(_at(row, options.isEmpty ? -1 : options.first)));
    } else {
      for (var i = 0; i < options.length; i++) {
        final t = _at(row, options[i]);
        if (t.isEmpty) continue;
        opts.add(QuestionOption(key: String.fromCharCode(65 + i), text: t));
      }
    }
    if (opts.length < 2) return null;

    final ans = _at(row, answer).toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '');
    return Question(
      id: 'imp_${DateTime.now().microsecondsSinceEpoch}_$index',
      content: stemText,
      options: opts,
      answer: opts.any((o) => o.key == ans) ? ans : '',
      category: _at(row, category),
      analysis: _at(row, analysis),
      source: 'import',
    );
  }

  /// "A.甲 B.乙 C.丙" → 三个选项。分隔符各家写法不一，按字母标号切。
  static List<QuestionOption> _splitOptions(String cell) => splitInlineOptions(cell);


}

const _tableSystem = '''
你在读一张题库表格，要说出每一列装的是什么。

只回 JSON，不要解释：
{
  "headerRows": 表头占了前几行（没有表头填 0）,
  "stem": 题干在第几列（下标从 0 开始）,
  "options": 选项列的下标数组；如果四个选项挤在同一格里，就填那一列的下标（单个数字，不是数组）,
  "answer": 答案列的下标,
  "analysis": 解析列的下标，没有填 null,
  "category": 题型/科目列的下标，没有填 null
}

判断依据是内容不是表头文字 —— 表头可能写着"题目""问题""Question"，也可能压根没有。
答案列的特征是一格里只有一个 A-D 的字母。
''';

const _textSystem = '''
你在从一份资料里把题目抽出来，做成结构化数据。这份资料可能是任何考试的：
公考行测、教师资格、法考、医考、四六级、驾照，都一样处理。

只回 JSON，不要解释：
{"questions": [
  {
    "content": "题干全文，不含选项",
    "options": [{"key": "A", "text": "选项文字"}],
    "answer": "A",
    "analysis": "解析全文，没有就 null",
    "category": "这道题属于哪一类，用资料里的叫法，判断不出填 null",
    "subCategory": "更细的分类，没有填 null"
  }
]}

规矩：
1. 只抽完整的题。这一段开头或结尾被截断的半道题直接丢掉，下一段会重新看到它。
2. answer 只在资料里明确写了才填，找不到就填 null，绝对不要猜、不要编。
3. 选项不足两个的不算题，丢掉。
4. category 用资料本身的说法（"言语理解""刑法""教育心理学"都行），不要硬套成别的体系。
5. 题干里的填空位保留成连续下划线。
6. 一道题都没有就回 {"questions": []}。
''';

/// 把近义的分类名并成一个。
///
/// 就算 prompt 里带了已见分类，模型仍会写出"数据库"和"数据库系统"这种同物
/// 异名 —— 落到界面上就是两张卡片、两份统计，用户以为自己导重复了。
///
/// 合并只认**包含关系**，并到出现次数多的那个上。这条判据保守但安全：
/// "数据库" ⊂ "数据库系统" 是同一件事，而"民法"和"刑法"谁也不包含谁，
/// 不会被错误地揉到一起。
List<Question> normalizeCategories(List<Question> questions) {
  final counts = <String, int>{};
  for (final q in questions) {
    final c = q.category.trim();
    if (c.isEmpty) continue;
    counts[c] = (counts[c] ?? 0) + 1;
  }
  if (counts.length < 2) return _withFallbackCategory(questions);

  // 长的先看：短名并进长名还是反过来，取决于谁出现得多
  final names = counts.keys.toList()
    ..sort((a, b) => b.length.compareTo(a.length));

  final canonical = <String, String>{};
  for (final name in names) {
    canonical[name] = name;
  }

  for (var i = 0; i < names.length; i++) {
    for (var j = i + 1; j < names.length; j++) {
      final long = names[i];
      final short = names[j];
      if (long == short || !long.contains(short)) continue;
      // 已经并到别处的不再动，免得连环改写
      if (canonical[long] != long || canonical[short] != short) continue;
      final winner = (counts[short] ?? 0) >= (counts[long] ?? 0) ? short : long;
      canonical[long] = winner;
      canonical[short] = winner;
    }
  }

  return _withFallbackCategory([
    for (final q in questions)
      q.category.trim().isEmpty ||
              canonical[q.category.trim()] == q.category.trim()
          ? q
          : _retag(q, canonical[q.category.trim()]!),
  ]);
}

/// 没分类的题给个落脚处。
///
/// category 为空的话，题进了库却不出现在任何模块卡片下面 —— 看着像导丢了。
/// 归到「未分类」至少点得进去，用户自己再改。
List<Question> _withFallbackCategory(List<Question> questions) => [
      for (final q in questions)
        q.category.trim().isEmpty ? _retag(q, '未分类') : q,
    ];

Question _retag(Question q, String category) => Question(
      id: q.id,
      content: q.content,
      contentHtml: q.contentHtml,
      options: q.options,
      answer: q.answer,
      category: category,
      subCategory: q.subCategory,
      analysis: q.analysis,
      analysisHtml: q.analysisHtml,
      paperId: q.paperId,
      paperTitle: q.paperTitle,
      year: q.year,
      difficulty: q.difficulty,
      source: q.source,
      orderNum: q.orderNum,
      materialId: q.materialId,
      material: q.material,
      isMulti: q.isMulti,
    );
