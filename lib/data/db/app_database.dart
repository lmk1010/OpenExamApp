import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:openexam_app/data/models/question.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Local store. The whole question bank — text, papers and 4k+ figure images —
/// ships as one gzipped SQLite file that is unpacked on first launch, so the
/// app never touches the network.
class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  static const _dbFile = 'openexam.db';
  static const _legacyDbFile = 'openexam_local.db';
  static const _seedAsset = 'assets/seed/openexam_seed.db.gz';

  Database? _db;

  Future<Database> get database async => _db ??= await _open();

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    final path = p.join(dir, _dbFile);

    if (!await File(path).exists()) {
      await _installSeed(path);
      await _migrateLegacyHistory(dir, path);
    }

    final db = await openDatabase(path);
    await _ensureRuntimeTables(db);
    return db;
  }

  /// Unpacks the bundled seed. gzip decode runs off the UI isolate — the file
  /// is ~90 MB expanded.
  Future<void> _installSeed(String path) async {
    final data = await rootBundle.load(_seedAsset);
    final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    final decoded = await compute(_gunzip, bytes);
    await File(path).writeAsBytes(decoded, flush: true);
  }

  static Uint8List _gunzip(Uint8List bytes) =>
      Uint8List.fromList(gzip.decode(bytes));

  /// Carries answer history over from the pre-image database, if any.
  Future<void> _migrateLegacyHistory(String dir, String newPath) async {
    final legacy = File(p.join(dir, _legacyDbFile));
    if (!await legacy.exists()) return;
    try {
      final old = await openDatabase(legacy.path, readOnly: true);
      final logs = await old.query('practice_logs');
      await old.close();
      if (logs.isEmpty) return;
      final db = await openDatabase(newPath);
      final batch = db.batch();
      for (final row in logs) {
        batch.insert('practice_logs', {
          'question_id': row['question_id'],
          'user_answer': row['user_answer'],
          'is_correct': row['is_correct'],
          'created_at': row['created_at'],
        });
      }
      await batch.commit(noResult: true);
      await db.close();
    } catch (_) {
      // A broken legacy file must never block the new install.
    }
  }

  /// Tables the app writes to; the seed ships them, but an older seed might not.
  Future<void> _ensureRuntimeTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS practice_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        question_id TEXT NOT NULL,
        user_answer TEXT,
        is_correct INTEGER NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
    // Speed is what 行测 is actually about, so every answer records its time.
    try {
      await db.execute('ALTER TABLE practice_logs ADD COLUMN elapsed_ms INTEGER DEFAULT 0');
    } catch (_) {
      // Column already exists.
    }
    await db.execute('''
      CREATE TABLE IF NOT EXISTS marks (
        question_id TEXT PRIMARY KEY,
        created_at TEXT NOT NULL
      )
    ''');
    // Every finished session is kept so scores can be revisited later.
    await db.execute('''
      CREATE TABLE IF NOT EXISTS exam_reports (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        kind TEXT NOT NULL,
        total INTEGER NOT NULL,
        answered INTEGER NOT NULL,
        correct INTEGER NOT NULL,
        elapsed_ms INTEGER NOT NULL,
        question_ids TEXT NOT NULL,
        answers TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS meta (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  // ---------------------------------------------------------------- questions

  Question _fromRow(Map<String, Object?> row) => Question.fromRow(row);

  Future<int> countAll() async {
    final db = await database;
    return Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM questions')) ?? 0;
  }

  Future<List<CategoryStat>> categoryStats() async {
    final db = await database;
    final totals = await db.rawQuery('''
      SELECT category, COUNT(*) AS total
      FROM questions
      GROUP BY category
      ORDER BY total DESC
    ''');
    final logs = await db.rawQuery('''
      SELECT q.category AS category,
             COUNT(*) AS done,
             SUM(CASE WHEN l.is_correct = 1 THEN 1 ELSE 0 END) AS correct
      FROM practice_logs l
      JOIN questions q ON q.id = l.question_id
      GROUP BY q.category
    ''');
    final doneMap = <String, Map<String, int>>{};
    for (final row in logs) {
      doneMap['${row['category']}'] = {
        'done': int.tryParse('${row['done']}') ?? 0,
        'correct': int.tryParse('${row['correct']}') ?? 0,
      };
    }
    return totals.map((row) {
      final cat = '${row['category'] ?? ''}';
      return CategoryStat(
        category: cat,
        total: int.tryParse('${row['total']}') ?? 0,
        done: doneMap[cat]?['done'] ?? 0,
        correct: doneMap[cat]?['correct'] ?? 0,
      );
    }).toList();
  }

  Future<List<Question>> fetchByPaper(String paperId) async {
    final db = await database;
    final rows = await db.query(
      'questions',
      where: 'paper_id = ?',
      whereArgs: [paperId],
      orderBy: 'order_num ASC, id ASC',
    );
    return rows.map(_fromRow).toList();
  }

  Future<List<Question>> fetchPractice({
    String? category,
    int limit = 20,
    bool shuffle = true,
  }) async {
    final db = await database;
    final where = <String>[];
    final args = <Object?>[];
    if (category != null && category.isNotEmpty && category != 'all') {
      where.add('category = ?');
      args.add(category);
    }
    final sql = StringBuffer('SELECT * FROM questions');
    if (where.isNotEmpty) sql.write(' WHERE ${where.join(' AND ')}');
    sql.write(shuffle ? ' ORDER BY RANDOM()' : ' ORDER BY year DESC, order_num');
    sql.write(' LIMIT ?');
    args.add(limit);
    return (await db.rawQuery(sql.toString(), args)).map(_fromRow).toList();
  }

  Future<List<Map<String, Object?>>> listPapers({int limit = 200}) async {
    final db = await database;
    return db.rawQuery('''
      SELECT paper_id, paper_title, year, source, COUNT(*) AS question_count
      FROM questions
      WHERE paper_id IS NOT NULL AND paper_id != ''
      GROUP BY paper_id, paper_title, year, source
      ORDER BY year DESC, paper_title
      LIMIT ?
    ''', [limit]);
  }

  /// Distinct questions answered per paper, for the 题库 progress meters.
  Future<Map<String, int>> paperProgress() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT q.paper_id AS paper_id, COUNT(DISTINCT l.question_id) AS done
      FROM practice_logs l
      JOIN questions q ON q.id = l.question_id
      WHERE q.paper_id IS NOT NULL AND q.paper_id != ''
      GROUP BY q.paper_id
    ''');
    return {
      for (final row in rows)
        '${row['paper_id']}': int.tryParse('${row['done']}') ?? 0,
    };
  }

  Future<int> importQuestions(List<Question> questions) async {
    if (questions.isEmpty) return 0;
    final db = await database;
    final batch = db.batch();
    for (final q in questions) {
      batch.insert(
        'questions',
        q.toRow(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
    return questions.length;
  }

  /// Full-text-ish search over question bodies. LIKE is plenty for 16k rows
  /// and keeps the bundled database free of an FTS index.
  Future<List<Question>> search(String query, {int limit = 60}) async {
    final q = query.trim();
    if (q.isEmpty) return const [];
    final db = await database;
    final rows = await db.rawQuery(
      '''
      SELECT * FROM questions
      WHERE content LIKE ? OR analysis LIKE ?
      ORDER BY year DESC, order_num ASC
      LIMIT ?
      ''',
      ['%$q%', '%$q%', limit],
    );
    return rows.map(_fromRow).toList();
  }

  /// Per-day answered/correct counts for the trend chart, oldest first.
  Future<List<DailyStat>> dailyStats({int days = 30}) async {
    final db = await database;
    final since = DateTime.now().subtract(Duration(days: days - 1));
    final start = DateTime(since.year, since.month, since.day);
    final rows = await db.rawQuery(
      '''
      SELECT date(created_at) AS day,
             COUNT(*) AS n,
             SUM(CASE WHEN is_correct = 1 THEN 1 ELSE 0 END) AS correct
      FROM practice_logs
      WHERE created_at >= ?
      GROUP BY day
      ''',
      [start.toIso8601String()],
    );
    final byDay = {
      for (final row in rows)
        '${row['day']}': (
          n: int.tryParse('${row['n']}') ?? 0,
          correct: int.tryParse('${row['correct']}') ?? 0,
        ),
    };
    return List<DailyStat>.generate(days, (i) {
      final d = start.add(Duration(days: i));
      final key = '${d.year.toString().padLeft(4, '0')}-'
          '${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';
      final hit = byDay[key];
      return DailyStat(date: d, answered: hit?.n ?? 0, correct: hit?.correct ?? 0);
    });
  }

  // ----------------------------------------------------------------- reports

  Future<int> saveReport({
    required String title,
    required String kind,
    required List<String> questionIds,
    required Map<String, String> answers,
    required int correct,
    required Duration elapsed,
  }) async {
    final db = await database;
    return db.insert('exam_reports', {
      'title': title,
      'kind': kind,
      'total': questionIds.length,
      'answered': answers.length,
      'correct': correct,
      'elapsed_ms': elapsed.inMilliseconds,
      'question_ids': jsonEncode(questionIds),
      'answers': jsonEncode(answers),
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<ExamReport>> listReports({int limit = 60}) async {
    final db = await database;
    final rows = await db.query(
      'exam_reports',
      orderBy: 'id DESC',
      limit: limit,
    );
    return rows.map(ExamReport.fromRow).toList();
  }

  Future<void> deleteReport(int id) async {
    final db = await database;
    await db.delete('exam_reports', where: 'id = ?', whereArgs: [id]);
  }

  /// Questions by id, in the order given — used to replay a saved report.
  Future<List<Question>> fetchByIds(List<String> ids) async {
    if (ids.isEmpty) return const [];
    final db = await database;
    final placeholders = List.filled(ids.length, '?').join(',');
    final rows = await db.rawQuery(
      'SELECT * FROM questions WHERE id IN ($placeholders)',
      ids,
    );
    final byId = {for (final row in rows) '${row['id']}': _fromRow(row)};
    return [
      for (final id in ids)
        if (byId[id] != null) byId[id]!,
    ];
  }

  // ------------------------------------------------------------------ images

  final Map<String, Uint8List?> _imageCache = {};

  /// Figure bytes for an `oeimg://name` reference, cached in memory.
  Future<Uint8List?> image(String name) async {
    if (_imageCache.containsKey(name)) return _imageCache[name];
    final db = await database;
    final rows = await db.query(
      'images',
      columns: ['bytes'],
      where: 'name = ?',
      whereArgs: [name],
      limit: 1,
    );
    final bytes = rows.isEmpty ? null : rows.first['bytes'] as Uint8List?;
    if (_imageCache.length > 120) _imageCache.clear();
    _imageCache[name] = bytes;
    return bytes;
  }

  // ------------------------------------------------------------------ answers

  Future<void> logAnswer({
    required String questionId,
    required String userAnswer,
    required bool isCorrect,
    int elapsedMs = 0,
  }) async {
    final db = await database;
    await db.insert('practice_logs', {
      'question_id': questionId,
      'user_answer': userAnswer,
      'is_correct': isCorrect ? 1 : 0,
      'elapsed_ms': elapsedMs,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Median-ish pace per category: average seconds spent on answered questions.
  Future<Map<String, double>> categoryPace() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT q.category AS category, AVG(l.elapsed_ms) AS ms
      FROM practice_logs l
      JOIN questions q ON q.id = l.question_id
      WHERE l.elapsed_ms > 0
      GROUP BY q.category
    ''');
    return {
      for (final row in rows)
        '${row['category']}': (double.tryParse('${row['ms']}') ?? 0) / 1000,
    };
  }

  /// Everything the 试卷详情 page needs: per-category totals and progress.
  Future<List<CategoryStat>> paperCategoryStats(String paperId) async {
    final db = await database;
    final totals = await db.rawQuery(
      'SELECT category, COUNT(*) AS total FROM questions WHERE paper_id = ? GROUP BY category',
      [paperId],
    );
    final logs = await db.rawQuery('''
      SELECT q.category AS category,
             COUNT(DISTINCT l.question_id) AS done,
             SUM(CASE WHEN l.is_correct = 1 THEN 1 ELSE 0 END) AS correct
      FROM practice_logs l
      JOIN questions q ON q.id = l.question_id
      WHERE q.paper_id = ?
      GROUP BY q.category
    ''', [paperId]);
    final byCat = <String, Map<String, int>>{};
    for (final row in logs) {
      byCat['${row['category']}'] = {
        'done': int.tryParse('${row['done']}') ?? 0,
        'correct': int.tryParse('${row['correct']}') ?? 0,
      };
    }
    return totals.map((row) {
      final cat = '${row['category'] ?? ''}';
      return CategoryStat(
        category: cat,
        total: int.tryParse('${row['total']}') ?? 0,
        done: byCat[cat]?['done'] ?? 0,
        correct: byCat[cat]?['correct'] ?? 0,
      );
    }).toList();
  }

  /// Questions of one category inside one paper — 卷内模块练习.
  Future<List<Question>> fetchByPaperCategory(
    String paperId,
    String? category, {
    bool onlyUnanswered = false,
  }) async {
    final db = await database;
    final where = <String>['paper_id = ?'];
    final args = <Object?>[paperId];
    if (category != null && category.isNotEmpty) {
      where.add('category = ?');
      args.add(category);
    }
    if (onlyUnanswered) {
      where.add('id NOT IN (SELECT question_id FROM practice_logs)');
    }
    final rows = await db.rawQuery(
      'SELECT * FROM questions WHERE ${where.join(' AND ')} ORDER BY order_num ASC',
      args,
    );
    return rows.map(_fromRow).toList();
  }

  /// Wrong questions inside one paper.
  Future<List<Question>> fetchWrongByPaper(String paperId) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT q.* FROM questions q
      JOIN (
        SELECT question_id, MAX(id) AS last_id FROM practice_logs GROUP BY question_id
      ) last ON last.question_id = q.id
      JOIN practice_logs l ON l.id = last.last_id
      WHERE l.is_correct = 0 AND q.paper_id = ?
      ORDER BY q.order_num ASC
    ''', [paperId]);
    return rows.map(_fromRow).toList();
  }

  /// Wrong-answer counts per paper, for grouping 错题本 by 试卷.
  Future<List<({String id, String title, int year, int count})>>
      wrongByPaper() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT q.paper_id AS id, q.paper_title AS title, q.year AS year,
             COUNT(*) AS n
      FROM questions q
      JOIN (
        SELECT question_id, MAX(id) AS last_id FROM practice_logs GROUP BY question_id
      ) last ON last.question_id = q.id
      JOIN practice_logs l ON l.id = last.last_id
      WHERE l.is_correct = 0
      GROUP BY q.paper_id, q.paper_title, q.year
      ORDER BY n DESC
    ''');
    return rows
        .map((r) => (
              id: '${r['id'] ?? ''}',
              title: '${r['title'] ?? '未命名试卷'}',
              year: int.tryParse('${r['year'] ?? 0}') ?? 0,
              count: int.tryParse('${r['n']}') ?? 0,
            ))
        .toList();
  }

  /// Questions whose most recent answer was wrong.
  Future<List<Question>> fetchWrong({int limit = 20}) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT q.* FROM questions q
      JOIN (
        SELECT question_id, MAX(id) AS last_id
        FROM practice_logs
        GROUP BY question_id
      ) last ON last.question_id = q.id
      JOIN practice_logs l ON l.id = last.last_id
      WHERE l.is_correct = 0
      ORDER BY l.id DESC
      LIMIT ?
    ''', [limit]);
    return rows.map(_fromRow).toList();
  }

  Future<int> countWrong() async {
    final db = await database;
    return Sqflite.firstIntValue(await db.rawQuery('''
          SELECT COUNT(*) FROM (
            SELECT question_id, MAX(id) AS last_id FROM practice_logs GROUP BY question_id
          ) last
          JOIN practice_logs l ON l.id = last.last_id
          WHERE l.is_correct = 0
        ''')) ??
        0;
  }

  /// Drops a question out of 错题本 without pretending it was answered right.
  Future<void> forgetQuestion(String questionId) async {
    final db = await database;
    await db.delete('practice_logs', where: 'question_id = ?', whereArgs: [questionId]);
  }

  Future<void> clearHistory() async {
    final db = await database;
    await db.delete('practice_logs');
  }

  Future<int> countAnswers() async {
    final db = await database;
    return Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM practice_logs'),
        ) ??
        0;
  }

  Future<int> countImported() async {
    final db = await database;
    return Sqflite.firstIntValue(
          await db.rawQuery("SELECT COUNT(*) FROM questions WHERE source = 'imported'"),
        ) ??
        0;
  }

  /// Answers per local day for the last [days] days, oldest first.
  Future<List<int>> dailyActivity({int days = 7}) async {
    final db = await database;
    final since = DateTime.now().subtract(Duration(days: days - 1));
    final start = DateTime(since.year, since.month, since.day);
    final rows = await db.rawQuery(
      '''
      SELECT date(created_at) AS day, COUNT(*) AS n
      FROM practice_logs
      WHERE created_at >= ?
      GROUP BY day
      ''',
      [start.toIso8601String()],
    );
    final byDay = <String, int>{
      for (final row in rows) '${row['day']}': int.tryParse('${row['n']}') ?? 0,
    };
    return List<int>.generate(days, (i) {
      final d = start.add(Duration(days: i));
      final key = '${d.year.toString().padLeft(4, '0')}-'
          '${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';
      return byDay[key] ?? 0;
    });
  }

  // -------------------------------------------------------------------- marks

  Future<void> toggleMark(String questionId, bool marked) async {
    final db = await database;
    if (marked) {
      await db.insert(
        'marks',
        {'question_id': questionId, 'created_at': DateTime.now().toIso8601String()},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } else {
      await db.delete('marks', where: 'question_id = ?', whereArgs: [questionId]);
    }
  }

  Future<bool> isMarked(String questionId) async {
    final db = await database;
    final rows = await db.query(
      'marks',
      where: 'question_id = ?',
      whereArgs: [questionId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<Set<String>> markedIds() async {
    final db = await database;
    final rows = await db.query('marks', columns: ['question_id']);
    return rows.map((r) => '${r['question_id']}').toSet();
  }

  Future<int> countMarked() async {
    final db = await database;
    return Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM marks')) ?? 0;
  }

  Future<List<Question>> fetchMarked({int limit = 200}) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT q.* FROM questions q
      JOIN marks m ON m.question_id = q.id
      ORDER BY m.created_at DESC
      LIMIT ?
    ''', [limit]);
    return rows.map(_fromRow).toList();
  }
}
