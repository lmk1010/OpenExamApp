/// 一条要背的词。成语为主，也收实词辨析里的双音节词。
class VocabWord {
  const VocabWord({
    required this.word,
    required this.meaning,
    this.usage = '',
    this.confusable = '',
    this.source = 'builtin',
    this.fromQuestionId = '',
    this.addedAt,
    this.box = 0,
    this.dueAt,
    this.seen = 0,
    this.known = 0,
  });

  final String word;

  /// 释义。一句话说清，不抄词典整段。
  final String meaning;

  /// 用法/语境提示：褒贬、搭配对象、常见误用。
  /// 逻辑填空考的就是这个，光背释义选不对。
  final String usage;

  /// 易混词，用顿号分隔。
  final String confusable;

  /// 拆成一个个词。种子里写的是「一挥而就、一气呵成」这种顿号串。
  List<String> get confusableList => confusable
      .split(RegExp(r'[、,，/\s]+'))
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  /// builtin = 内置词表；wrong = 从做错的题里自动收的。
  final String source;

  /// 从哪道题收来的，点开能回看原题。
  final String fromQuestionId;
  final DateTime? addedAt;

  /// 间隔重复的盒子号 0–5。答对进一格，答错回 0。
  final int box;

  /// 下次该复习的时间。null = 从没背过，今天就该背。
  final DateTime? dueAt;

  final int seen;
  final int known;

  bool get isNew => dueAt == null;

  bool dueOn(DateTime day) {
    final d = dueAt;
    if (d == null) return true;
    final end = DateTime(day.year, day.month, day.day, 23, 59, 59);
    return !d.isAfter(end);
  }

  /// 盒子号 → 隔几天再见。0 是当天再来一次，最后一格两周。
  static const intervals = <int>[0, 1, 2, 4, 7, 14];

  VocabWord answered({required bool right, DateTime? now}) {
    final at = now ?? DateTime.now();
    final next = right ? (box + 1).clamp(0, intervals.length - 1) : 0;
    return copyWith(
      box: next,
      // 答错的当天要再见一次，所以 0 号盒子是"今天晚点再来"，不是"明天"
      dueAt: DateTime(at.year, at.month, at.day)
          .add(Duration(days: intervals[next])),
      seen: seen + 1,
      known: known + (right ? 1 : 0),
    );
  }

  VocabWord copyWith({
    String? meaning,
    String? usage,
    String? confusable,
    int? box,
    DateTime? dueAt,
    int? seen,
    int? known,
  }) {
    return VocabWord(
      word: word,
      meaning: meaning ?? this.meaning,
      usage: usage ?? this.usage,
      confusable: confusable ?? this.confusable,
      source: source,
      fromQuestionId: fromQuestionId,
      addedAt: addedAt,
      box: box ?? this.box,
      dueAt: dueAt ?? this.dueAt,
      seen: seen ?? this.seen,
      known: known ?? this.known,
    );
  }

  Map<String, Object?> toRow() => {
        'word': word,
        'meaning': meaning,
        'usage': usage,
        'confusable': confusable,
        'source': source,
        'from_question_id': fromQuestionId,
        'added_at': (addedAt ?? DateTime.now()).toIso8601String(),
        'box': box,
        'due_at': dueAt?.toIso8601String(),
        'seen': seen,
        'known': known,
      };

  factory VocabWord.fromRow(Map<String, Object?> row) => VocabWord(
        word: '${row['word']}',
        meaning: '${row['meaning'] ?? ''}',
        usage: '${row['usage'] ?? ''}',
        confusable: '${row['confusable'] ?? ''}',
        source: '${row['source'] ?? 'builtin'}',
        fromQuestionId: '${row['from_question_id'] ?? ''}',
        addedAt: DateTime.tryParse('${row['added_at'] ?? ''}'),
        box: int.tryParse('${row['box'] ?? 0}') ?? 0,
        dueAt: DateTime.tryParse('${row['due_at'] ?? ''}'),
        seen: int.tryParse('${row['seen'] ?? 0}') ?? 0,
        known: int.tryParse('${row['known'] ?? 0}') ?? 0,
      );
}
