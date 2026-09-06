import 'package:openexam_app/data/db/app_database.dart';
import 'package:openexam_app/features/vocab/data/vocab_seed.dart';
import 'package:openexam_app/features/vocab/domain/vocab_word.dart';
import 'package:sqflite/sqflite.dart';

/// 词表的存取与每日选词。
class VocabRepository {
  VocabRepository._();
  static final instance = VocabRepository._();

  Future<Database> get _db => AppDatabase.instance.database;

  /// 首次用的时候把内置词表灌进去。之后每次启动只补新增的词，
  /// 不覆盖 —— 用户的复习进度在同一行上。
  Future<void> ensureSeeded() async {
    final db = await _db;
    final batch = db.batch();
    for (final w in kVocabSeed) {
      batch.insert('vocab', w.toRow(), conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await batch.commit(noResult: true);
  }

  /// 今天该背的：到期的排前面，不够就拿新词补。
  ///
  /// 先复习后新词，是因为复习的边际收益高得多 ——
  /// 快忘的词捞一把就回来了，新词今天不学明天学没差别。
  Future<List<VocabWord>> todayDeck({int limit = 12}) async {
    final db = await _db;
    final now = DateTime.now();
    final endOfDay =
        DateTime(now.year, now.month, now.day, 23, 59, 59).toIso8601String();

    final due = (await db.query(
      'vocab',
      where: 'due_at IS NOT NULL AND due_at <= ?',
      whereArgs: [endOfDay],
      orderBy: 'due_at ASC',
      limit: limit,
    ))
        .map(VocabWord.fromRow)
        .toList();

    if (due.length >= limit) return due;

    final fresh = (await db.query(
      'vocab',
      where: 'due_at IS NULL',
      // 从错题收来的排在内置词前面：那是你真的错过的词
      orderBy: "CASE source WHEN 'wrong' THEN 0 ELSE 1 END, added_at ASC",
      limit: limit - due.length,
    ))
        .map(VocabWord.fromRow)
        .toList();

    return [...due, ...fresh];
  }

  Future<void> save(VocabWord word) async {
    final db = await _db;
    await db.insert('vocab', word.toRow(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// 从做错的题里收词。同一个词只收一次，已经在背的不动它。
  Future<int> collect(Iterable<VocabWord> words) async {
    final db = await _db;
    var added = 0;
    for (final w in words) {
      final n = await db.insert('vocab', w.toRow(),
          conflictAlgorithm: ConflictAlgorithm.ignore);
      if (n > 0) added++;
    }
    return added;
  }

  Future<({int total, int due, int learning, int mastered})> stats() async {
    final db = await _db;
    final now = DateTime.now();
    final endOfDay =
        DateTime(now.year, now.month, now.day, 23, 59, 59).toIso8601String();
    int one(List<Map<String, Object?>> r) =>
        Sqflite.firstIntValue(r) ?? 0;
    return (
      total: one(await db.rawQuery('SELECT COUNT(*) FROM vocab')),
      due: one(await db.rawQuery(
        'SELECT COUNT(*) FROM vocab WHERE due_at IS NULL OR due_at <= ?',
        [endOfDay],
      )),
      learning: one(await db.rawQuery(
        'SELECT COUNT(*) FROM vocab WHERE box > 0 AND box < 5',
      )),
      mastered: one(await db.rawQuery(
        'SELECT COUNT(*) FROM vocab WHERE box >= 5',
      )),
    );
  }

  Future<List<VocabWord>> all({String? query, int limit = 300}) async {
    final db = await _db;
    final q = (query ?? '').trim();
    final rows = await db.query(
      'vocab',
      where: q.isEmpty ? null : 'word LIKE ? OR meaning LIKE ?',
      whereArgs: q.isEmpty ? null : ['%$q%', '%$q%'],
      orderBy: 'box ASC, added_at DESC',
      limit: limit,
    );
    return rows.map(VocabWord.fromRow).toList();
  }

  /// 有易混词的那些。逻辑填空真正难的不是不认识某个词，是分不清
  /// 一蹴而就 / 一挥而就 / 一气呵成 —— 单看释义永远分不清，得摆在一起看。
  Future<List<VocabWord>> confusableGroups({int limit = 200}) async {
    final db = await _db;
    final rows = await db.query(
      'vocab',
      where: "confusable IS NOT NULL AND confusable <> ''",
      orderBy: 'word ASC',
      limit: limit,
    );
    return rows.map(VocabWord.fromRow).toList();
  }

  /// 按词名取一条，用于辨析里把易混词的释义也一并显示出来。
  Future<Map<String, VocabWord>> byWords(Iterable<String> words) async {
    final list = words.toSet().toList();
    if (list.isEmpty) return const {};
    final db = await _db;
    final rows = await db.query(
      'vocab',
      where: 'word IN (${List.filled(list.length, '?').join(',')})',
      whereArgs: list,
    );
    return {
      for (final r in rows.map(VocabWord.fromRow)) r.word: r,
    };
  }

  Future<void> remove(String word) async {
    final db = await _db;
    await db.delete('vocab', where: 'word = ?', whereArgs: [word]);
  }
}
