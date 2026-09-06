import 'dart:convert';

/// Which slice of the bank a practice set is drawn from.
enum QuestionScope { all, unseen, wrong }

class QuestionOption {
  const QuestionOption({required this.key, required this.text, this.html = ''});

  final String key;
  final String text;

  /// Original markup — 图形推理 options are images, so the plain text is empty.
  final String html;

  bool get hasImage => html.contains('oeimg://');

  Map<String, dynamic> toJson() => {'key': key, 'text': text, 'html': html};

  factory QuestionOption.fromJson(Map<String, dynamic> json) {
    final html = '${json['html'] ?? json['content'] ?? ''}'.trim();
    return QuestionOption(
      key: '${json['key'] ?? ''}'.trim().toUpperCase(),
      text: '${json['text'] ?? json['content'] ?? ''}'.trim(),
      html: html,
    );
  }

  /// An option is usable when it has readable text or a figure.
  bool get isUsable => key.isNotEmpty && (text.isNotEmpty || hasImage);

  /// 选项本身是图（图形推理）。这类题扫进来时文字位上放的是字母本身，
  /// 真正的选项内容在题干那张横条图里 —— 做题页别把字母再重复一遍。
  bool get isFigureOnly => text == key && html.isEmpty;
}

class Question {
  const Question({
    required this.id,
    required this.content,
    required this.options,
    required this.answer,
    required this.category,
    this.contentHtml = '',
    this.analysisHtml = '',
    this.subCategory = '',
    this.analysis = '',
    this.paperId = '',
    this.paperTitle = '',
    this.year = 0,
    this.difficulty = 2,
    this.source = 'builtin',
    this.orderNum = 0,
    this.materialId = '',
    this.material = '',
    this.isMulti = false,
  });

  final String id;
  final String content;
  final String contentHtml;
  final List<QuestionOption> options;
  final String answer;
  final String category;
  final String subCategory;
  final String analysis;
  final String analysisHtml;
  final String paperId;
  final String paperTitle;
  final int year;
  final int difficulty;
  final String source;
  final int orderNum;

  /// 共用材料的 id。资料分析、篇章阅读是「一材多题」：一段材料后面跟
  /// 三到五问，材料存一份，题指过去。
  final String materialId;

  /// 材料正文（HTML）。从 materials 表联查填进来，不落在 questions 行里。
  final String material;

  /// 多选题。答案形如 ABCD，按字母序存。
  ///
  /// 全库只有 51 道（都在常识判断），但在单选界面上它们**永远判错** ——
  /// 存进去的是一个字母，比的是四个字母，怎么点都不对，还会全部涌进错题本。
  final bool isMulti;

  bool get hasMaterial => material.trim().isNotEmpty;

  bool get hasImage =>
      contentHtml.contains('oeimg://') ||
      analysisHtml.contains('oeimg://') ||
      material.contains('oeimg://') ||
      options.any((o) => o.hasImage);

  /// Markup for rendering, falling back to plain text for imported questions.
  String get bodyMarkup => contentHtml.isNotEmpty ? contentHtml : content;
  String get analysisMarkup => analysisHtml.isNotEmpty ? analysisHtml : analysis;

  Map<String, Object?> toRow() => {
        'id': id,
        'content': content,
        'content_html': contentHtml,
        'options': jsonEncode(options.map((e) => e.toJson()).toList()),
        'answer': answer,
        'category': category,
        'sub_category': subCategory,
        'analysis': analysis,
        'analysis_html': analysisHtml,
        'paper_id': paperId,
        'paper_title': paperTitle,
        'year': year,
        'difficulty': difficulty,
        'source': source,
        'has_image': hasImage ? 1 : 0,
        'order_num': orderNum,
        'material_id': materialId,
      };

  factory Question.fromRow(Map<String, Object?> row) {
    final optionsRaw = jsonDecode('${row['options'] ?? '[]'}') as List<dynamic>;
    return Question(
      id: '${row['id']}',
      content: '${row['content'] ?? ''}',
      contentHtml: '${row['content_html'] ?? ''}',
      options: optionsRaw
          .whereType<Map>()
          .map((e) => QuestionOption.fromJson(Map<String, dynamic>.from(e)))
          .where((o) => o.isUsable)
          .toList(),
      answer: '${row['answer'] ?? ''}'.toUpperCase(),
      category: '${row['category'] ?? ''}',
      subCategory: '${row['sub_category'] ?? ''}',
      analysis: '${row['analysis'] ?? ''}',
      analysisHtml: '${row['analysis_html'] ?? ''}',
      paperId: '${row['paper_id'] ?? ''}',
      paperTitle: '${row['paper_title'] ?? ''}',
      year: int.tryParse('${row['year'] ?? 0}') ?? 0,
      difficulty: int.tryParse('${row['difficulty'] ?? 2}') ?? 2,
      source: '${row['source'] ?? 'builtin'}',
      orderNum: int.tryParse('${row['order_num'] ?? 0}') ?? 0,
      materialId: '${row['material_id'] ?? ''}',
      isMulti: '${row['type'] ?? 'single'}' == 'multiple',
      // 联查来的列，普通 questions 查询没有它，取不到就是空。
      material: '${row['material'] ?? ''}',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'contentHtml': contentHtml,
        'options': options.map((e) => e.toJson()).toList(),
        'answer': answer,
        'category': category,
        'subCategory': subCategory,
        'analysis': analysis,
        'analysisHtml': analysisHtml,
        'paperId': paperId,
        'paperTitle': paperTitle,
        'year': year,
        'difficulty': difficulty,
        'source': source,
        if (isMulti) 'isMulti': true,
        if (materialId.isNotEmpty) 'materialId': materialId,
        if (material.isNotEmpty) 'material': material,
      };

  factory Question.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'];
    final options = <QuestionOption>[];
    if (rawOptions is List) {
      for (final item in rawOptions) {
        if (item is Map) {
          final option = QuestionOption.fromJson(Map<String, dynamic>.from(item));
          if (option.isUsable) options.add(option);
        }
      }
    }

    return Question(
      id: '${json['id'] ?? ''}',
      content: '${json['content'] ?? json['title'] ?? ''}'.trim(),
      contentHtml: '${json['contentHtml'] ?? json['content_html'] ?? ''}',
      options: options,
      answer: '${json['answer'] ?? ''}'.trim().toUpperCase(),
      category: '${json['category'] ?? ''}',
      subCategory: '${json['subCategory'] ?? json['sub_category'] ?? ''}',
      analysis: '${json['analysis'] ?? ''}',
      analysisHtml: '${json['analysisHtml'] ?? json['analysis_html'] ?? ''}',
      paperId: '${json['paperId'] ?? json['paper_id'] ?? ''}',
      paperTitle: '${json['paperTitle'] ?? json['paper_title'] ?? ''}',
      year: int.tryParse('${json['year'] ?? 0}') ?? 0,
      difficulty: int.tryParse('${json['difficulty'] ?? 2}') ?? 2,
      source: '${json['source'] ?? 'builtin'}',
      orderNum: int.tryParse('${json['orderNum'] ?? json['order_num'] ?? 0}') ?? 0,
      materialId: '${json['materialId'] ?? json['material_id'] ?? ''}',
      material: '${json['material'] ?? ''}',
      isMulti: json['isMulti'] == true,
    );
  }

  /// 扫描出来的题在入库前要补两样东西：归到哪个题型、共用材料的 id。
  /// 单独给方法而不是塞进 copyWith，是因为这两个字段平时不该被顺手改掉。
  Question withCategory(String value) => _with(category: value);
  Question withMaterialId(String value) => _with(materialId: value);

  Question _with({String? category, String? materialId}) => Question(
        id: id,
        content: content,
        contentHtml: contentHtml,
        options: options,
        answer: answer,
        category: category ?? this.category,
        subCategory: subCategory,
        analysis: analysis,
        analysisHtml: analysisHtml,
        paperId: paperId,
        paperTitle: paperTitle,
        year: year,
        difficulty: difficulty,
        source: source,
        orderNum: orderNum,
        materialId: materialId ?? this.materialId,
        material: material,
        isMulti: isMulti,
      );

  Question copyWith({String? source, String? material}) => Question(
        id: id,
        content: content,
        contentHtml: contentHtml,
        options: options,
        answer: answer,
        category: category,
        subCategory: subCategory,
        analysis: analysis,
        analysisHtml: analysisHtml,
        paperId: paperId,
        paperTitle: paperTitle,
        year: year,
        difficulty: difficulty,
        source: source ?? this.source,
        orderNum: orderNum,
        materialId: materialId,
        material: material ?? this.material,
        isMulti: isMulti,
      );
}

class CategoryStat {
  const CategoryStat({
    required this.category,
    required this.total,
    required this.done,
    required this.correct,
  });

  final String category;
  final int total;
  final int done;
  final int correct;

  double get accuracy => done == 0 ? 0 : correct / done;
}

/// One day of practice, used by the trend chart.
class DailyStat {
  const DailyStat({
    required this.date,
    required this.answered,
    required this.correct,
  });

  final DateTime date;
  final int answered;
  final int correct;

  double get accuracy => answered == 0 ? 0 : correct / answered;
}

/// A finished session, kept so the score can be revisited.
class ExamReport {
  const ExamReport({
    required this.id,
    required this.title,
    required this.kind,
    required this.total,
    required this.answered,
    required this.correct,
    required this.elapsed,
    required this.questionIds,
    required this.answers,
    required this.createdAt,
  });

  final int id;
  final String title;

  /// 'exam' for timed papers, 'practice' otherwise.
  final String kind;
  final int total;
  final int answered;
  final int correct;
  final Duration elapsed;
  final List<String> questionIds;
  final Map<String, String> answers;
  final DateTime createdAt;

  int get rate => total == 0 ? 0 : (correct * 100 / total).round();
  bool get isExam => kind == 'exam';

  factory ExamReport.fromRow(Map<String, Object?> row) => ExamReport(
        id: int.tryParse('${row['id']}') ?? 0,
        title: '${row['title'] ?? ''}',
        kind: '${row['kind'] ?? 'practice'}',
        total: int.tryParse('${row['total']}') ?? 0,
        answered: int.tryParse('${row['answered']}') ?? 0,
        correct: int.tryParse('${row['correct']}') ?? 0,
        elapsed: Duration(milliseconds: int.tryParse('${row['elapsed_ms']}') ?? 0),
        questionIds: (jsonDecode('${row['question_ids'] ?? '[]'}') as List)
            .map((e) => '$e')
            .toList(),
        answers: (jsonDecode('${row['answers'] ?? '{}'}') as Map)
            .map((k, v) => MapEntry('$k', '$v')),
        createdAt:
            DateTime.tryParse('${row['created_at'] ?? ''}') ?? DateTime.now(),
      );
}

/// An unfinished session, restored on the next launch.
class ResumeState {
  const ResumeState({
    required this.title,
    required this.questionIds,
    required this.answers,
    required this.index,
    required this.limit,
    required this.elapsed,
    required this.savedAt,
  });

  final String title;
  final List<String> questionIds;
  final Map<String, String> answers;
  final int index;
  final Duration? limit;
  final Duration elapsed;
  final DateTime savedAt;

  int get remaining => questionIds.length - answers.length;
  bool get isExam => limit != null;

  factory ResumeState.fromJson(Map<String, dynamic> json) => ResumeState(
        title: '${json['title'] ?? '练习'}',
        questionIds:
            (json['ids'] as List? ?? const []).map((e) => '$e').toList(),
        answers: (json['answers'] as Map? ?? const {})
            .map((k, v) => MapEntry('$k', '$v')),
        index: int.tryParse('${json['index'] ?? 0}') ?? 0,
        limit: json['limitMs'] == null
            ? null
            : Duration(milliseconds: int.tryParse('${json['limitMs']}') ?? 0),
        elapsed: Duration(milliseconds: int.tryParse('${json['elapsedMs'] ?? 0}') ?? 0),
        savedAt: DateTime.tryParse('${json['at'] ?? ''}') ?? DateTime.now(),
      );
}

/// 四天复习计划 — one 错因 or 题型 tracked across the four review steps.
/// 粉笔的说法：前两天放慢做对，第三天限时加压，第四天混练验证。
class ReviewPlan {
  const ReviewPlan({
    required this.key,
    required this.kind,
    required this.label,
    required this.startedAt,
    required this.doneDays,
    this.lastDone,
  });

  factory ReviewPlan.fromRow(Map<String, Object?> row) => ReviewPlan(
        key: '${row['key']}',
        kind: '${row['kind']}',
        label: '${row['label']}',
        startedAt:
            DateTime.tryParse('${row['started_at']}') ?? DateTime.now(),
        doneDays: '${row['done_days']}'
            .split(',')
            .map(int.tryParse)
            .whereType<int>()
            .toSet(),
        lastDone: row['last_done'] == null
            ? null
            : DateTime.tryParse('${row['last_done']}'),
      );

  final String key;

  /// 'reason' or 'category'.
  final String kind;
  final String label;
  final DateTime startedAt;

  /// Which of the four steps are ticked (1–4).
  final Set<int> doneDays;
  final DateTime? lastDone;

  bool get finished => doneDays.length >= 4;

  /// The step to do next — the lowest unticked one.
  int get nextDay {
    for (var d = 1; d <= 4; d++) {
      if (!doneDays.contains(d)) return d;
    }
    return 4;
  }

  /// One step per day: if today's step is already ticked, the plan rests.
  bool get doneToday {
    final at = lastDone;
    if (at == null) return false;
    final now = DateTime.now();
    return at.year == now.year && at.month == now.month && at.day == now.day;
  }

  static const stepTitles = ['放慢做对', '再来一遍', '限时加压', '混练验证'];
  static const stepHints = [
    '不计时，把每道题的正确思路走一遍',
    '还是不计时，重点看昨天卡住的地方',
    '按考场配速做，逼自己在时间内定下来',
    '掺进同类新题一起做，验证是不是真会了',
  ];
}
