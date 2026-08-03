import 'dart:convert';

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

  bool get hasImage =>
      contentHtml.contains('oeimg://') ||
      analysisHtml.contains('oeimg://') ||
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
    );
  }

  Question copyWith({String? source}) => Question(
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
