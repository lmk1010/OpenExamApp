import 'dart:convert';

/// 申论题型。行测是客观题，申论是主观题，所以走的是完全另一套流程。
enum EssayType { guina, duice, fenxi, guanche, dazuowen }

extension EssayTypeLabel on EssayType {
  String get label => switch (this) {
        EssayType.guina => '归纳概括',
        EssayType.duice => '提出对策',
        EssayType.fenxi => '综合分析',
        EssayType.guanche => '贯彻执行',
        EssayType.dazuowen => '大作文',
      };

  /// 每种题型的默认字数上限和建议用时，录题时预填，用户可改。
  int get defaultWordLimit => switch (this) {
        EssayType.guina => 200,
        EssayType.duice => 300,
        EssayType.fenxi => 300,
        EssayType.guanche => 500,
        EssayType.dazuowen => 1000,
      };

  int get defaultMinutes => switch (this) {
        EssayType.guina => 20,
        EssayType.duice => 25,
        EssayType.fenxi => 25,
        EssayType.guanche => 35,
        EssayType.dazuowen => 60,
      };

  static EssayType parse(String? raw) => EssayType.values.firstWhere(
        (t) => t.name == raw,
        orElse: () => EssayType.guina,
      );
}

class EssayPrompt {
  const EssayPrompt({
    required this.id,
    required this.title,
    required this.type,
    required this.material,
    required this.requirement,
    this.province,
    this.year,
    this.wordLimit,
    this.minutes,
    this.referenceAnswer,
    this.scoringPoints = const [],
    required this.createdAt,
    this.attemptCount = 0,
    this.bestScore,
  });

  final String id;
  final String title;
  final EssayType type;
  final String material;
  final String requirement;
  final String? province;
  final int? year;
  final int? wordLimit;
  final int? minutes;

  /// 官方参考答案，填了批改会准很多。
  final String? referenceAnswer;

  /// 已知采分点。留空则让 AI 自己从材料里提炼。
  final List<String> scoringPoints;

  final DateTime createdAt;

  /// 列表页用：练过几次、最好多少分。
  final int attemptCount;
  final double? bestScore;

  Map<String, Object?> toRow() => {
        'id': id,
        'title': title,
        'essay_type': type.name,
        'province': province,
        'year': year,
        'material': material,
        'requirement': requirement,
        'word_limit': wordLimit,
        'minutes': minutes,
        'reference_answer': referenceAnswer,
        'scoring_points': jsonEncode(scoringPoints),
        'created_at': createdAt.toIso8601String(),
      };

  factory EssayPrompt.fromRow(Map<String, Object?> row, {int attempts = 0, double? best}) {
    final rawPoints = row['scoring_points'] as String?;
    var points = const <String>[];
    if (rawPoints != null && rawPoints.isNotEmpty) {
      try {
        points = (jsonDecode(rawPoints) as List).map((e) => e.toString()).toList();
      } catch (_) {
        points = const [];
      }
    }
    return EssayPrompt(
      id: row['id'] as String,
      title: row['title'] as String,
      type: EssayTypeLabel.parse(row['essay_type'] as String?),
      province: row['province'] as String?,
      year: row['year'] as int?,
      material: (row['material'] as String?) ?? '',
      requirement: (row['requirement'] as String?) ?? '',
      wordLimit: row['word_limit'] as int?,
      minutes: row['minutes'] as int?,
      referenceAnswer: row['reference_answer'] as String?,
      scoringPoints: points,
      createdAt:
          DateTime.tryParse((row['created_at'] as String?) ?? '') ?? DateTime.now(),
      attemptCount: attempts,
      bestScore: best,
    );
  }
}

/// 一个采分点的命中情况 —— 批改的核心就是这个列表。
class ScoringPoint {
  const ScoringPoint({
    required this.text,
    required this.hit,
    this.evidence,
    this.why,
  });

  final String text;
  final bool hit;

  /// 材料里的出处，或考生答案里对应的句子。
  final String? evidence;

  /// 漏掉时说明为什么该写、为什么容易漏。
  final String? why;

  factory ScoringPoint.fromJson(Map<String, dynamic> json) => ScoringPoint(
        text: (json['text'] ?? '').toString(),
        hit: json['hit'] == true,
        evidence: json['evidence']?.toString(),
        why: json['why']?.toString(),
      );
}

class ScoreDimension {
  const ScoreDimension({
    required this.name,
    required this.score,
    required this.max,
    this.comment,
  });

  final String name;
  final double score;
  final double max;
  final String? comment;

  double get ratio => max <= 0 ? 0 : (score / max).clamp(0.0, 1.0);

  factory ScoreDimension.fromJson(Map<String, dynamic> json) => ScoreDimension(
        name: (json['name'] ?? '').toString(),
        score: _toDouble(json['score']) ?? 0,
        max: _toDouble(json['max']) ?? 0,
        comment: json['comment']?.toString(),
      );
}

/// AI 批改结果。
class EssayReview {
  const EssayReview({
    this.score,
    this.maxScore,
    this.dimensions = const [],
    this.points = const [],
    this.summary,
    this.improvements = const [],
  });

  final double? score;
  final double? maxScore;
  final List<ScoreDimension> dimensions;
  final List<ScoringPoint> points;
  final String? summary;
  final List<String> improvements;

  List<ScoringPoint> get missed => points.where((p) => !p.hit).toList();

  /// 要点覆盖率 —— 申论最该看的一个数。
  int get hitRate => points.isEmpty
      ? 0
      : (((points.length - missed.length) / points.length) * 100).round();

  factory EssayReview.fromJson(Map<String, dynamic> json) => EssayReview(
        score: _toDouble(json['score']),
        maxScore: _toDouble(json['maxScore']),
        dimensions: (json['dimensions'] as List? ?? [])
            .whereType<Map>()
            .map((e) => ScoreDimension.fromJson(e.cast<String, dynamic>()))
            .toList(),
        points: (json['points'] as List? ?? [])
            .whereType<Map>()
            .map((e) => ScoringPoint.fromJson(e.cast<String, dynamic>()))
            .toList(),
        summary: json['summary']?.toString(),
        improvements: (json['improvements'] as List? ?? [])
            .map((e) => e.toString())
            .where((e) => e.isNotEmpty)
            .toList(),
      );

  static EssayReview? decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      return EssayReview.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}

class EssayAttempt {
  const EssayAttempt({
    required this.id,
    required this.promptId,
    required this.answer,
    required this.wordCount,
    required this.seconds,
    required this.createdAt,
    this.score,
    this.maxScore,
    this.review,
    this.rawReview,
  });

  final String id;
  final String promptId;
  final String answer;
  final int wordCount;
  final int seconds;
  final DateTime createdAt;
  final double? score;
  final double? maxScore;
  final EssayReview? review;

  /// 原始 JSON，存库用。
  final String? rawReview;

  Map<String, Object?> toRow() => {
        'id': id,
        'prompt_id': promptId,
        'answer': answer,
        'word_count': wordCount,
        'seconds': seconds,
        'score': score,
        'max_score': maxScore,
        'review': rawReview,
        'created_at': createdAt.toIso8601String(),
      };

  factory EssayAttempt.fromRow(Map<String, Object?> row) {
    final raw = row['review'] as String?;
    return EssayAttempt(
      id: row['id'] as String,
      promptId: row['prompt_id'] as String,
      answer: (row['answer'] as String?) ?? '',
      wordCount: (row['word_count'] as int?) ?? 0,
      seconds: (row['seconds'] as int?) ?? 0,
      score: _toDouble(row['score']),
      maxScore: _toDouble(row['max_score']),
      review: EssayReview.decode(raw),
      rawReview: raw,
      createdAt:
          DateTime.tryParse((row['created_at'] as String?) ?? '') ?? DateTime.now(),
    );
  }
}

double? _toDouble(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

/// 中文字数：不算空白。
int countWords(String text) => text.replaceAll(RegExp(r'\s'), '').length;
