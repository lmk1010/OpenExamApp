import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:openexam_app/core/ui/rich_content.dart';
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

  /// 缓存的是「打开中」的 Future 而不是打开好的库：启动时 main 和首页会同时
  /// 要库，缓存 Database 的话两边都会看到 null，于是把 82MB 的种子解包两遍。
  Future<Database>? _opening;

  Future<Database> get database => _opening ??= _open();

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
    // 词语积累。逻辑填空错的那个词，第二天还会在别的题里再错一次 ——
    // 收进来按间隔重复过，比重做一遍原题有用。
    await db.execute('''
      CREATE TABLE IF NOT EXISTS vocab (
        word TEXT PRIMARY KEY,
        meaning TEXT NOT NULL DEFAULT '',
        usage TEXT NOT NULL DEFAULT '',
        confusable TEXT NOT NULL DEFAULT '',
        source TEXT NOT NULL DEFAULT 'builtin',
        from_question_id TEXT NOT NULL DEFAULT '',
        added_at TEXT NOT NULL,
        box INTEGER NOT NULL DEFAULT 0,
        due_at TEXT,
        seen INTEGER NOT NULL DEFAULT 0,
        known INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_vocab_due ON vocab(due_at)');

    // 一材多题：资料分析和篇章阅读是一段材料后面跟三到五问。
    // 材料存一份、题指过去，不是每题复制一遍 —— 一段材料上千字，
    // 五题复制五遍既浪费又会在改错时改漏。
    await db.execute('''
      CREATE TABLE IF NOT EXISTS materials (
        id TEXT PRIMARY KEY,
        content TEXT NOT NULL DEFAULT '',
        content_html TEXT NOT NULL DEFAULT '',
        paper_id TEXT NOT NULL DEFAULT '',
        source TEXT NOT NULL DEFAULT ''
      )
    ''');
    try {
      await db.execute("ALTER TABLE questions ADD COLUMN material_id TEXT DEFAULT ''");
    } catch (_) {
      // Column already exists.
    }
    try {
      await db.execute('CREATE INDEX IF NOT EXISTS idx_q_material ON questions(material_id)');
    } catch (_) {
      // 老库上 questions 可能是只读附加表，建不了索引也不该拦住启动。
    }
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
    // 复盘的关键不是"我错了"，而是"我为什么错"。
    // 自己的解题笔记比任何官方解析都好使，尤其是回看的时候。
    await db.execute('''
      CREATE TABLE IF NOT EXISTS notes (
        question_id TEXT PRIMARY KEY,
        body TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS wrong_reasons (
        question_id TEXT PRIMARY KEY,
        reason TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
    // Tagging a favourite ("公式""易错") is what makes it findable later.
    try {
      await db.execute("ALTER TABLE marks ADD COLUMN tag TEXT DEFAULT ''");
    } catch (_) {
      // Column already exists.
    }
    // 本地纠错记录：没有服务器，但至少让用户能标出来、导出带走。
    await db.execute('''
      CREATE TABLE IF NOT EXISTS feedback (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        question_id TEXT NOT NULL,
        kind TEXT NOT NULL,
        note TEXT,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS badges (
        id TEXT PRIMARY KEY,
        unlocked_at TEXT NOT NULL
      )
    ''');
    // 每日一练打卡：哪天做完了固定卷。直接记结果，避免为了画打卡条
    // 反复重算每天的题目集合（那是一次全表排序）。
    await db.execute('''
      CREATE TABLE IF NOT EXISTS daily_checkin (
        day TEXT PRIMARY KEY,
        total INTEGER NOT NULL,
        correct INTEGER NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
    // Hot paths: historyFor / wrong book / paper progress all hit practice_logs.
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_logs_qid ON practice_logs(question_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_logs_created ON practice_logs(created_at)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_reports_created ON exam_reports(created_at)',
    );
    // 自己标的难度。没有服务器统计，也就没有「全站正确率」这种东西；
    // 但「这题对我难」本来就是个人的判断，标一次以后能筛出来重练。
    await db.execute('''
      CREATE TABLE IF NOT EXISTS difficulty (
        question_id TEXT PRIMARY KEY,
        level INTEGER NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    // 四天复习计划：粉笔那套「同类错因连盯四天」——前两天放慢做对，
    // 第三天限时加压，第四天混练验证。计划本身只是四条打卡记录。
    await db.execute('''
      CREATE TABLE IF NOT EXISTS review_plans (
        key TEXT PRIMARY KEY,
        kind TEXT NOT NULL,
        label TEXT NOT NULL,
        started_at TEXT NOT NULL,
        done_days TEXT NOT NULL DEFAULT '',
        last_done TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS meta (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
    // 申论题。种子库里一道都没有 —— 行测才有真题，申论得自己录或拍照识别。
    await db.execute('''
      CREATE TABLE IF NOT EXISTS essay_prompts (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        essay_type TEXT NOT NULL DEFAULT 'guina',
        province TEXT,
        year INTEGER,
        material TEXT NOT NULL DEFAULT '',
        requirement TEXT NOT NULL DEFAULT '',
        word_limit INTEGER,
        minutes INTEGER,
        reference_answer TEXT,
        scoring_points TEXT,
        created_at TEXT NOT NULL
      )
    ''');
    // 一道题可以反复练，每次作答连同 AI 批改结果单独存一条。
    await db.execute('''
      CREATE TABLE IF NOT EXISTS essay_attempts (
        id TEXT PRIMARY KEY,
        prompt_id TEXT NOT NULL,
        answer TEXT NOT NULL DEFAULT '',
        word_count INTEGER NOT NULL DEFAULT 0,
        seconds INTEGER NOT NULL DEFAULT 0,
        score REAL,
        max_score REAL,
        review TEXT,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_essay_attempts_prompt ON essay_attempts(prompt_id)',
    );
    await _applyDataPatches(db);
  }

  /// Fixes already-installed DBs when the bundled seed cannot be re-unpacked.
  Future<void> _applyDataPatches(Database db) async {
    final rows = await db.query('meta', where: 'key = ?', whereArgs: ['data_patch']);
    final current = int.tryParse('${rows.isEmpty ? 0 : rows.first['value']}') ?? 0;
    if (current >= 1) return;

    // Patch 1: three 2023 判断题 had answer corrupted to "}" (解析结论为 C).
    await db.update(
      'questions',
      {'answer': 'C'},
      where: 'id IN (?, ?, ?, ?, ?, ?)',
      whereArgs: const [
        'paper_oe_19486_q100',
        'paper_oe_19488_q91',
        'paper_oe_19501_q100',
        'paper_saduck_19486_q100',
        'paper_saduck_19488_q91',
        'paper_saduck_19501_q100',
      ],
    );
    await db.insert(
      'meta',
      {'key': 'data_patch', 'value': '1'},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ---------------------------------------------------------------- questions

  Question _fromRow(Map<String, Object?> row) => Question.fromRow(row);

  /// 把共用材料补进题里。
  ///
  /// 不在每条查询上 JOIN：一段材料上千字，五题就是五份重复传输。
  /// 先取题，再按去重后的 material_id 取一次材料，然后贴回去。
  Future<List<Question>> _withMaterials(List<Question> questions) async {
    final ids = questions
        .map((q) => q.materialId)
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
    if (ids.isEmpty) return questions;
    final db = await database;
    final rows = await db.query(
      'materials',
      where: 'id IN (${List.filled(ids.length, '?').join(',')})',
      whereArgs: ids,
    );
    if (rows.isEmpty) return questions;
    final byId = <String, String>{
      for (final r in rows)
        '${r['id']}': '${r['content_html'] ?? ''}'.isNotEmpty
            ? '${r['content_html']}'
            : '${r['content'] ?? ''}',
    };
    return [
      for (final q in questions)
        q.materialId.isEmpty || byId[q.materialId] == null
            ? q
            : q.copyWith(material: byId[q.materialId]),
    ];
  }

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
    return _withMaterials(rows.map(_fromRow).toList());
  }

  Future<List<Question>> fetchPractice({
    String? category,
    String? subCategory,
    int limit = 20,
    bool shuffle = true,
    QuestionScope scope = QuestionScope.all,
  }) async {
    final db = await database;
    final where = <String>[];
    final args = <Object?>[];
    if (category != null && category.isNotEmpty && category != 'all') {
      where.add('category = ?');
      args.add(category);
    }
    if (subCategory != null && subCategory.isNotEmpty) {
      where.add('sub_category = ?');
      args.add(subCategory);
    }
    switch (scope) {
      case QuestionScope.unseen:
        where.add('id NOT IN (SELECT question_id FROM practice_logs)');
      case QuestionScope.wrong:
        where.add('''id IN (
          SELECT l.question_id FROM practice_logs l
          JOIN (SELECT question_id, MAX(id) AS last_id FROM practice_logs
                GROUP BY question_id) last ON last.last_id = l.id
          WHERE l.is_correct = 0
        )''');
      case QuestionScope.all:
        break;
    }
    final sql = StringBuffer('SELECT * FROM questions');
    if (where.isNotEmpty) sql.write(' WHERE ${where.join(' AND ')}');
    // 刷题优先近年：同年内再随机。老卷（year 小）排后面，LIMIT 自然落到新题。
    sql.write(
      shuffle
          ? ' ORDER BY year DESC, RANDOM()'
          : ' ORDER BY year DESC, order_num',
    );
    sql.write(' LIMIT ?');
    args.add(limit);
    return _withMaterials(
      (await db.rawQuery(sql.toString(), args)).map(_fromRow).toList(),
    );
  }

  /// Sub-types under a 行测 module, ordered by question count.
  Future<List<({String key, int count})>> listSubCategories(String category) async {
    final db = await database;
    final rows = await db.rawQuery(
      '''
      SELECT sub_category AS key, COUNT(*) AS n
      FROM questions
      WHERE category = ? AND sub_category IS NOT NULL AND TRIM(sub_category) != ''
      GROUP BY sub_category
      ORDER BY n DESC, sub_category ASC
      ''',
      [category],
    );
    return [
      for (final row in rows)
        (key: '${row['key']}', count: (row['n'] as int?) ?? 0),
    ];
  }

  /// How many questions each scope currently holds, for the picker labels.
  Future<Map<QuestionScope, int>> scopeCounts({String? category}) async {
    final db = await database;
    final cat = category == null || category.isEmpty || category == 'all'
        ? null
        : category;
    final catWhere = cat == null ? '' : ' AND category = ?';
    final args = cat == null ? <Object?>[] : <Object?>[cat];

    final all = Sqflite.firstIntValue(await db.rawQuery(
          'SELECT COUNT(*) FROM questions WHERE 1=1$catWhere',
          args,
        )) ??
        0;
    final unseen = Sqflite.firstIntValue(await db.rawQuery(
          'SELECT COUNT(*) FROM questions WHERE id NOT IN '
          '(SELECT question_id FROM practice_logs)$catWhere',
          args,
        )) ??
        0;
    final wrong = Sqflite.firstIntValue(await db.rawQuery(
          '''SELECT COUNT(*) FROM questions WHERE id IN (
            SELECT l.question_id FROM practice_logs l
            JOIN (SELECT question_id, MAX(id) AS last_id FROM practice_logs
                  GROUP BY question_id) last ON last.last_id = l.id
            WHERE l.is_correct = 0
          )$catWhere''',
          args,
        )) ??
        0;
    return {
      QuestionScope.all: all,
      QuestionScope.unseen: unseen,
      QuestionScope.wrong: wrong,
    };
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

  /// Papers whose title mentions a region (or 国考), newest first.
  Future<List<Map<String, Object?>>> listPapersByRegion(
    String region, {
    int limit = 60,
  }) async {
    final db = await database;
    final like = region == '国考' ? '%国家公务员%' : '%$region%';
    return db.rawQuery('''
      SELECT paper_id, paper_title, year, source, COUNT(*) AS question_count
      FROM questions
      WHERE paper_title LIKE ?
      GROUP BY paper_id, paper_title, year, source
      ORDER BY year DESC
      LIMIT ?
    ''', [like, limit]);
  }

  /// Random questions drawn only from a region's papers — 本省真题练习.
  Future<List<Question>> fetchByRegion(
    String region, {
    int limit = 20,
  }) async {
    final db = await database;
    final like = region == '国考' ? '%国家公务员%' : '%$region%';
    final rows = await db.rawQuery(
      'SELECT * FROM questions WHERE paper_title LIKE ? ORDER BY RANDOM() LIMIT ?',
      [like, limit],
    );
    return _withMaterials(rows.map(_fromRow).toList());
  }

  Future<int> countByRegion(String region) async {
    final db = await database;
    final like = region == '国考' ? '%国家公务员%' : '%$region%';
    return Sqflite.firstIntValue(await db.rawQuery(
          'SELECT COUNT(*) FROM questions WHERE paper_title LIKE ?',
          [like],
        )) ??
        0;
  }

  /// Papers touched most recently, newest first — 「继续上次那套」.
  Future<List<({String id, DateTime at})>> recentPapers({int limit = 3}) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT q.paper_id AS id, MAX(l.created_at) AS at
      FROM practice_logs l
      JOIN questions q ON q.id = l.question_id
      WHERE q.paper_id IS NOT NULL AND q.paper_id != ''
      GROUP BY q.paper_id
      ORDER BY at DESC
      LIMIT ?
    ''', [limit]);
    return rows
        .map((r) => (
              id: '${r['id']}',
              at: DateTime.tryParse('${r['at']}') ?? DateTime.now(),
            ))
        .toList();
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

  /// Ids already in the bank — the import preview reports these as 覆盖.
  Future<int> countExisting(List<String> ids) async {
    if (ids.isEmpty) return 0;
    final db = await database;
    final placeholders = List.filled(ids.length, '?').join(',');
    return Sqflite.firstIntValue(await db.rawQuery(
          'SELECT COUNT(*) FROM questions WHERE id IN ($placeholders)',
          ids,
        )) ??
        0;
  }

  /// Figures that came with an imported zip.
  Future<void> importImages(Map<String, Uint8List> images) async {
    if (images.isEmpty) return;
    final db = await database;
    final batch = db.batch();
    for (final entry in images.entries) {
      batch.insert(
        'images',
        {'name': entry.key, 'bytes': entry.value},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
    _imageCache.clear();
    _imageCacheBytes = 0;
  }

  Future<int> importQuestions(List<Question> questions) async {
    if (questions.isEmpty) return 0;
    final db = await database;
    final batch = db.batch();

    // 材料先落一份。同一段材料会被同批的三到五题引用，去重后只写一次。
    final seen = <String>{};
    for (final q in questions) {
      if (q.materialId.isEmpty || q.material.isEmpty) continue;
      if (!seen.add(q.materialId)) continue;
      batch.insert(
        'materials',
        {
          'id': q.materialId,
          'content': _stripTags(q.material),
          'content_html': q.material,
          'paper_id': q.paperId,
          'source': q.source,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

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

  /// 材料的纯文本版，给搜索用。渲染永远走 content_html。
  static String _stripTags(String html) => decodeEntities(
        html
            .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
            .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n')
            .replaceAll(RegExp(r'<[^>]+>'), ''),
      ).trim();

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
    return _withMaterials(rows.map(_fromRow).toList());
  }

  /// Per-week answered/correct counts, oldest first — the daily chart is too
  /// noisy to show whether a month of work went anywhere.
  Future<List<DailyStat>> weeklyStats({int weeks = 8}) async {
    final db = await database;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Week starts on Monday.
    final thisMonday = today.subtract(Duration(days: today.weekday - 1));
    final start = thisMonday.subtract(Duration(days: 7 * (weeks - 1)));

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

    final buckets = List<DailyStat>.generate(
      weeks,
      (i) => DailyStat(
        date: start.add(Duration(days: 7 * i)),
        answered: 0,
        correct: 0,
      ),
    );
    final counts = List<int>.filled(weeks, 0);
    final corrects = List<int>.filled(weeks, 0);

    for (final row in rows) {
      final day = DateTime.tryParse('${row['day']}');
      if (day == null) continue;
      final index = day.difference(start).inDays ~/ 7;
      if (index < 0 || index >= weeks) continue;
      counts[index] += int.tryParse('${row['n']}') ?? 0;
      corrects[index] += int.tryParse('${row['correct']}') ?? 0;
    }

    return [
      for (var i = 0; i < weeks; i++)
        DailyStat(
          date: buckets[i].date,
          answered: counts[i],
          correct: corrects[i],
        ),
    ];
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

  /// 今日一练 — the same questions all day, so closing the app and coming back
  /// continues the set instead of shuffling a new one. Deterministic from the
  /// date, no storage needed.
  Future<List<Question>> fetchDailySet({
    required DateTime day,
    int limit = 20,
  }) async {
    final db = await database;
    final seed = day.year * 10000 + day.month * 100 + day.day;
    final a = 1103515245 + (seed % 7919);
    final b = seed % 104729;
    final rows = await db.rawQuery(
      'SELECT * FROM questions ORDER BY ((rowid * ? + ?) % 100003) LIMIT ?',
      [a, b, limit],
    );
    return _withMaterials(rows.map(_fromRow).toList());
  }

  /// How far today's set has been taken: answered and correct among its ids.
  Future<({int answered, int correct})> dailyProgress(List<String> ids) async {
    if (ids.isEmpty) return (answered: 0, correct: 0);
    final db = await database;
    final placeholders = List.filled(ids.length, '?').join(',');
    final rows = await db.rawQuery('''
      SELECT COUNT(*) AS n,
             SUM(CASE WHEN l.is_correct = 1 THEN 1 ELSE 0 END) AS correct
      FROM (
        SELECT question_id, MAX(id) AS last_id
        FROM practice_logs
        WHERE question_id IN ($placeholders)
        GROUP BY question_id
      ) last
      JOIN practice_logs l ON l.id = last.last_id
    ''', ids);
    if (rows.isEmpty) return (answered: 0, correct: 0);
    return (
      answered: int.tryParse('${rows.first['n']}') ?? 0,
      correct: int.tryParse('${rows.first['correct'] ?? 0}') ?? 0,
    );
  }

  /// Weakness-weighted set: modules you are worst at get the biggest share,
  /// and inside each module previously-wrong questions come first, then
  /// unseen ones. This is what "刷题要刷弱项" means in practice.
  Future<List<Question>> fetchAdaptive({int limit = 20}) async {
    final stats = await categoryStats();
    final practised = stats.where((s) => s.total > 0).toList();
    if (practised.isEmpty) return fetchPractice(limit: limit);

    // Never-practised modules count as 50% accuracy so they still show up.
    double weightOf(CategoryStat s) {
      final acc = s.done < 5 ? 0.5 : s.accuracy;
      return (1 - acc).clamp(0.12, 1.0);
    }

    final weights = {for (final s in practised) s.category: weightOf(s)};
    final sum = weights.values.fold<double>(0, (a, b) => a + b);
    final quota = <String, int>{};
    var assigned = 0;
    for (final s in practised) {
      final n = ((weights[s.category]! / sum) * limit).floor();
      quota[s.category] = n;
      assigned += n;
    }
    // Hand the rounding remainder to the weakest module.
    if (assigned < limit) {
      final weakest = practised
          .reduce((a, b) => weightOf(a) >= weightOf(b) ? a : b)
          .category;
      quota[weakest] = (quota[weakest] ?? 0) + (limit - assigned);
    }

    final db = await database;
    final picked = <Question>[];
    for (final entry in quota.entries) {
      if (entry.value <= 0) continue;
      final rows = await db.rawQuery('''
        SELECT q.*,
               CASE
                 WHEN l.is_correct = 0 THEN 0
                 WHEN l.question_id IS NULL THEN 1
                 ELSE 2
               END AS priority
        FROM questions q
        LEFT JOIN (
          SELECT question_id, MAX(id) AS last_id FROM practice_logs GROUP BY question_id
        ) last ON last.question_id = q.id
        LEFT JOIN practice_logs l ON l.id = last.last_id
        WHERE q.category = ?
        ORDER BY priority ASC, RANDOM()
        LIMIT ?
      ''', [entry.key, entry.value]);
      picked.addAll(rows.map(_fromRow));
    }
    picked.shuffle();
    return picked;
  }

  // ------------------------------------------------------------------ backup

  /// Everything the user created (not the bank itself) as one JSON map.
  /// The question bank ships with the app, so a backup only needs the
  /// answers, marks, tags, notes, reasons, plans and reports.
  Future<Map<String, dynamic>> exportUserData() async {
    final db = await database;
    return {
      // 2 起带上 vocab / essay。老备份没有这几个键，put() 遇到缺键当空处理。
      'version': 2,
      'exportedAt': DateTime.now().toIso8601String(),
      'logs': await db.query('practice_logs'),
      'marks': await db.query('marks'),
      'notes': await db.query('notes'),
      'reasons': await db.query('wrong_reasons'),
      'plans': await db.query('review_plans'),
      'difficulty': await db.query('difficulty'),
      'checkins': await db.query('daily_checkin'),
      'reports': await db.query('exam_reports'),
      'feedback': await db.query('feedback'),
      'badges': await db.query('badges'),
      // 词语积累和申论作答以前不在备份里 —— 每天早上攒的词、写过的申论，
      // 换台手机就全没了。
      'vocab': await db.query('vocab'),
      'essayPrompts': await db.query('essay_prompts'),
      'essayAttempts': await db.query('essay_attempts'),
    };
  }

  /// Restores a backup. Existing rows with the same key are replaced; practice
  /// logs are wiped first so a restore is a restore, not a merge.
  Future<int> importUserData(Map<String, dynamic> data) async {
    final db = await database;
    var restored = 0;

    /// [keepId] —— practice_logs / exam_reports / feedback 的 id 是自增的，
    /// 带着旧 id 插会撞主键，所以丢掉让它重新发号。申论那两张表的 id 是 TEXT
    /// 主键（作答要靠它指回题目），丢了就断了。
    Future<void> put(
      String table,
      String key, {
      bool wipe = false,
      bool keepId = false,
    }) async {
      final rows = (data[key] as List?) ?? const [];
      if (wipe && rows.isNotEmpty) await db.delete(table);
      final batch = db.batch();
      for (final row in rows) {
        if (row is! Map) continue;
        final map = Map<String, Object?>.from(row);
        if (!keepId) map.remove('id');
        batch.insert(table, map, conflictAlgorithm: ConflictAlgorithm.replace);
        restored++;
      }
      await batch.commit(noResult: true);
    }

    await put('practice_logs', 'logs', wipe: true);
    await put('marks', 'marks');
    await put('notes', 'notes');
    await put('wrong_reasons', 'reasons');
    await put('review_plans', 'plans');
    await put('difficulty', 'difficulty');
    await put('daily_checkin', 'checkins');
    await put('exam_reports', 'reports', wipe: true);
    await put('feedback', 'feedback', wipe: true);
    await put('badges', 'badges');
    await put('vocab', 'vocab');
    await put('essay_prompts', 'essayPrompts', keepId: true);
    await put('essay_attempts', 'essayAttempts', keepId: true);
    _imageCache.clear();
    _imageCacheBytes = 0;
    return restored;
  }

  // ------------------------------------------------------------------- notes

  Future<void> setNote(String questionId, String body) async {
    final db = await database;
    final text = body.trim();
    if (text.isEmpty) {
      await db.delete('notes', where: 'question_id = ?', whereArgs: [questionId]);
      return;
    }
    await db.insert(
      'notes',
      {
        'question_id': questionId,
        'body': text,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, String>> notes() async {
    final db = await database;
    final rows = await db.query('notes');
    return {for (final r in rows) '${r['question_id']}': '${r['body']}'};
  }

  Future<int> countNotes() async {
    final db = await database;
    return Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM notes')) ?? 0;
  }

  /// Noted questions, newest note first — the 我的笔记 list.
  Future<List<({Question question, String body, DateTime at})>> notedQuestions({
    int limit = 200,
  }) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT q.*, n.body AS note_body, n.updated_at AS note_at
      FROM notes n
      JOIN questions q ON q.id = n.question_id
      ORDER BY n.updated_at DESC
      LIMIT ?
    ''', [limit]);
    return rows
        .map((r) => (
              question: _fromRow(r),
              body: '${r['note_body']}',
              at: DateTime.tryParse('${r['note_at']}') ?? DateTime.now(),
            ))
        .toList();
  }

  // ------------------------------------------------------------- resume state

  static const _resumeKey = 'resume_session';

  /// Snapshot of an unfinished session so closing the app mid-practice is not
  /// punished. Stored in `meta` as JSON — one live session at a time.
  Future<void> saveResume({
    required String title,
    required List<String> questionIds,
    required Map<String, String> answers,
    required int index,
    Duration? limit,
    required Duration elapsed,
  }) async {
    final db = await database;
    await db.insert(
      'meta',
      {
        'key': _resumeKey,
        'value': jsonEncode({
          'title': title,
          'ids': questionIds,
          'answers': answers,
          'index': index,
          'limitMs': limit?.inMilliseconds,
          'elapsedMs': elapsed.inMilliseconds,
          'at': DateTime.now().toIso8601String(),
        }),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> clearResume() async {
    final db = await database;
    await db.delete('meta', where: 'key = ?', whereArgs: [_resumeKey]);
  }

  Future<ResumeState?> loadResume() async {
    final db = await database;
    final rows = await db.query('meta', where: 'key = ?', whereArgs: [_resumeKey]);
    if (rows.isEmpty) return null;
    try {
      final map = jsonDecode('${rows.first['value']}') as Map<String, dynamic>;
      final state = ResumeState.fromJson(map);
      // A day-old snapshot is noise, not a helpful offer.
      if (DateTime.now().difference(state.savedAt).inHours > 24) {
        await clearResume();
        return null;
      }
      return state;
    } catch (_) {
      await clearResume();
      return null;
    }
  }

  // ------------------------------------------------------------ daily streak

  static String dayKey(DateTime day) =>
      '${day.year}-${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';

  Future<void> markDailyDone(DateTime day, int total, int correct) async {
    final db = await database;
    await db.insert(
      'daily_checkin',
      {
        'day': dayKey(day),
        'total': total,
        'correct': correct,
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// day key -> (total, correct) for the last [days] days.
  Future<Map<String, ({int total, int correct})>> dailyCheckins({
    int days = 14,
  }) async {
    final db = await database;
    final rows = await db.query(
      'daily_checkin',
      orderBy: 'day DESC',
      limit: days,
    );
    return {
      for (final row in rows)
        '${row['day']}': (
          total: int.tryParse('${row['total']}') ?? 0,
          correct: int.tryParse('${row['correct']}') ?? 0,
        ),
    };
  }

  /// 连续打卡天数。今天还没做不算断，从昨天往前数。
  Future<int> dailyStreak() async {
    final marks = await dailyCheckins(days: 400);
    if (marks.isEmpty) return 0;
    final today = DateTime.now();
    var streak = 0;
    var cursor = marks.containsKey(dayKey(today))
        ? today
        : today.subtract(const Duration(days: 1));
    while (marks.containsKey(dayKey(cursor))) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  // -------------------------------------------------------------- difficulty

  /// level: 1 简单 / 2 一般 / 3 难；null 取消标记。
  Future<void> setDifficulty(String questionId, int? level) async {
    final db = await database;
    if (level == null) {
      await db.delete('difficulty', where: 'question_id = ?', whereArgs: [questionId]);
      return;
    }
    await db.insert(
      'difficulty',
      {
        'question_id': questionId,
        'level': level,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, int>> difficulties() async {
    final db = await database;
    final rows = await db.query('difficulty');
    return {
      for (final row in rows)
        '${row['question_id']}': int.tryParse('${row['level']}') ?? 2,
    };
  }

  /// Questions the user has flagged at [level], newest tag first.
  Future<List<Question>> fetchByDifficulty(int level, {int limit = 50}) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT q.* FROM questions q
      JOIN difficulty d ON d.question_id = q.id
      WHERE d.level = ?
      ORDER BY d.updated_at DESC
      LIMIT ?
    ''', [level, limit]);
    return _withMaterials(rows.map(_fromRow).toList());
  }

  Future<Map<int, int>> difficultyCounts() async {
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT level, COUNT(*) AS n FROM difficulty GROUP BY level',
    );
    return {
      for (final row in rows)
        (int.tryParse('${row['level']}') ?? 2):
            (int.tryParse('${row['n']}') ?? 0),
    };
  }

  // ------------------------------------------------------------ review plans

  /// Starts (or restarts) a four-day plan on one 错因 or one 题型.
  Future<void> startReviewPlan({
    required String key,
    required String kind,
    required String label,
  }) async {
    final db = await database;
    await db.insert(
      'review_plans',
      {
        'key': key,
        'kind': kind,
        'label': label,
        'started_at': DateTime.now().toIso8601String(),
        'done_days': '',
        'last_done': null,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ReviewPlan>> reviewPlans() async {
    final db = await database;
    final rows = await db.query('review_plans', orderBy: 'started_at DESC');
    return rows.map(ReviewPlan.fromRow).toList();
  }

  /// Marks today's step done. Days already ticked are kept, so finishing the
  /// same day twice does not skip a step.
  Future<void> tickReviewPlan(String key, int day) async {
    final db = await database;
    final rows = await db.query('review_plans', where: 'key = ?', whereArgs: [key]);
    if (rows.isEmpty) return;
    final plan = ReviewPlan.fromRow(rows.first);
    final days = {...plan.doneDays, day}.toList()..sort();
    await db.update(
      'review_plans',
      {
        'done_days': days.join(','),
        'last_done': DateTime.now().toIso8601String(),
      },
      where: 'key = ?',
      whereArgs: [key],
    );
  }

  Future<void> dropReviewPlan(String key) async {
    final db = await database;
    await db.delete('review_plans', where: 'key = ?', whereArgs: [key]);
  }

  // ------------------------------------------------------------ wrong reasons

  Future<void> setWrongReason(String questionId, String? reason) async {
    final db = await database;
    if (reason == null) {
      await db.delete('wrong_reasons', where: 'question_id = ?', whereArgs: [questionId]);
      return;
    }
    await db.insert(
      'wrong_reasons',
      {
        'question_id': questionId,
        'reason': reason,
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// question id -> reason key, for the 错题本 rows and filters.
  Future<Map<String, String>> wrongReasons() async {
    final db = await database;
    final rows = await db.query('wrong_reasons');
    return {
      for (final row in rows) '${row['question_id']}': '${row['reason']}',
    };
  }

  /// How many currently-wrong questions carry each reason.
  Future<Map<String, int>> wrongReasonCounts() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT r.reason AS reason, COUNT(*) AS n
      FROM wrong_reasons r
      JOIN (
        SELECT question_id, MAX(id) AS last_id FROM practice_logs GROUP BY question_id
      ) last ON last.question_id = r.question_id
      JOIN practice_logs l ON l.id = last.last_id
      WHERE l.is_correct = 0
      GROUP BY r.reason
    ''');
    return {
      for (final row in rows)
        '${row['reason']}': int.tryParse('${row['n']}') ?? 0,
    };
  }

  // ------------------------------------------------------------------ badges

  Future<Map<String, DateTime>> unlockedBadges() async {
    final db = await database;
    final rows = await db.query('badges');
    return {
      for (final r in rows)
        '${r['id']}':
            DateTime.tryParse('${r['unlocked_at']}') ?? DateTime.now(),
    };
  }

  Future<void> unlockBadge(String id) async {
    final db = await database;
    await db.insert(
      'badges',
      {'id': id, 'unlocked_at': DateTime.now().toIso8601String()},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  // ---------------------------------------------------------------- feedback

  Future<void> addFeedback({
    required String questionId,
    required String kind,
    String note = '',
  }) async {
    final db = await database;
    await db.insert('feedback', {
      'question_id': questionId,
      'kind': kind,
      'note': note,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<int> countFeedback() async {
    final db = await database;
    return Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM feedback')) ?? 0;
  }

  Future<List<({int id, Question question, String kind, String note, DateTime at})>>
      listFeedback({int limit = 200}) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT f.id AS fid, f.kind AS kind, f.note AS note, f.created_at AS at, q.*
      FROM feedback f
      JOIN questions q ON q.id = f.question_id
      ORDER BY f.id DESC
      LIMIT ?
    ''', [limit]);
    return rows
        .map((r) => (
              id: int.tryParse('${r['fid']}') ?? 0,
              question: _fromRow(r),
              kind: '${r['kind']}',
              note: '${r['note'] ?? ''}',
              at: DateTime.tryParse('${r['at']}') ?? DateTime.now(),
            ))
        .toList();
  }

  Future<void> deleteFeedback(int id) async {
    final db = await database;
    await db.delete('feedback', where: 'id = ?', whereArgs: [id]);
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

  Future<List<ExamReport>> listReports({int limit = 60, String? paperId}) async {
    final db = await database;
    final rows = await db.query(
      'exam_reports',
      orderBy: 'id DESC',
      limit: paperId == null ? limit : 300,
    );
    final reports = rows.map(ExamReport.fromRow).toList();
    if (paperId == null || paperId.isEmpty) {
      return reports.take(limit).toList();
    }
    final idRows = await db.rawQuery(
      'SELECT id FROM questions WHERE paper_id = ?',
      [paperId],
    );
    final idSet = {for (final r in idRows) '${r['id']}'};
    if (idSet.isEmpty) return const [];
    return reports
        .where((r) {
          if (r.questionIds.isEmpty) return false;
          final hit = r.questionIds.where(idSet.contains).length;
          // 半数以上题目属于该卷，当作本卷历史（整卷模考 / 模块练都算）。
          return hit >= (r.questionIds.length / 2).ceil();
        })
        .take(limit)
        .toList();
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

  /// LRU keyed by figure name. Insertion order is the recency order, so the
  /// oldest entry is simply the first key.
  final Map<String, Uint8List?> _imageCache = {};
  int _imageCacheBytes = 0;

  /// Roughly 12 MB of figures — a whole 130-question paper's worth — beyond
  /// which older ones are dropped instead of growing without bound.
  static const _imageCacheBudget = 12 * 1024 * 1024;

  /// Figure bytes for an `oeimg://name` reference, cached in memory.
  Future<Uint8List?> image(String name) async {
    if (_imageCache.containsKey(name)) {
      // Touch: re-insert so this entry becomes the most recent.
      final hit = _imageCache.remove(name);
      _imageCache[name] = hit;
      return hit;
    }
    final db = await database;
    final rows = await db.query(
      'images',
      columns: ['bytes'],
      where: 'name = ?',
      whereArgs: [name],
      limit: 1,
    );
    final bytes = rows.isEmpty ? null : rows.first['bytes'] as Uint8List?;
    _imageCache[name] = bytes;
    _imageCacheBytes += bytes?.lengthInBytes ?? 0;
    while (_imageCacheBytes > _imageCacheBudget && _imageCache.length > 1) {
      final oldest = _imageCache.keys.first;
      _imageCacheBytes -= _imageCache.remove(oldest)?.lengthInBytes ?? 0;
    }
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

  /// 某段时间内每个模块的答题量与正确率。用来做「这周 vs 上周」的对比 ——
  /// 只看累计正确率的话，最近的进步或退步会被历史数据稀释掉。
  Future<Map<String, ({int done, int correct})>> categoryAccuracyBetween(
    DateTime from,
    DateTime to,
  ) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT q.category AS category,
             COUNT(*) AS done,
             SUM(CASE WHEN l.is_correct = 1 THEN 1 ELSE 0 END) AS correct
      FROM practice_logs l
      JOIN questions q ON q.id = l.question_id
      WHERE l.created_at >= ? AND l.created_at < ?
      GROUP BY q.category
    ''', [from.toIso8601String(), to.toIso8601String()]);
    return {
      for (final row in rows)
        '${row['category']}': (
          done: int.tryParse('${row['done']}') ?? 0,
          correct: int.tryParse('${row['correct']}') ?? 0,
        ),
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
    return _withMaterials(rows.map(_fromRow).toList());
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
    return _withMaterials(rows.map(_fromRow).toList());
  }

  /// Count only — paper detail chips don't need full rows.
  Future<int> countWrongByPaper(String paperId) async {
    final db = await database;
    return Sqflite.firstIntValue(await db.rawQuery('''
          SELECT COUNT(*) FROM questions q
          JOIN (
            SELECT question_id, MAX(id) AS last_id FROM practice_logs GROUP BY question_id
          ) last ON last.question_id = q.id
          JOIN practice_logs l ON l.id = last.last_id
          WHERE l.is_correct = 0 AND q.paper_id = ?
        ''', [paperId])) ??
        0;
  }

  Future<int> countUnansweredByPaper(String paperId) async {
    final db = await database;
    return Sqflite.firstIntValue(await db.rawQuery('''
          SELECT COUNT(*) FROM questions
          WHERE paper_id = ?
            AND id NOT IN (SELECT question_id FROM practice_logs)
        ''', [paperId])) ??
        0;
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
    return _withMaterials(rows.map(_fromRow).toList());
  }

  /// Past attempts at one question, newest first — shown while practising so
  /// "我上次是不是也错这儿" 有答案。
  Future<List<({String answer, bool correct, DateTime at})>> historyFor(
    String questionId, {
    int limit = 5,
  }) async {
    final db = await database;
    final rows = await db.query(
      'practice_logs',
      where: 'question_id = ?',
      whereArgs: [questionId],
      orderBy: 'id DESC',
      limit: limit,
    );
    return rows
        .map((r) => (
              answer: '${r['user_answer'] ?? ''}',
              correct: '${r['is_correct']}' == '1',
              at: DateTime.tryParse('${r['created_at']}') ?? DateTime.now(),
            ))
        .toList();
  }

  /// How many times each question has been answered wrong — a question missed
  /// three times deserves more attention than one missed once.
  Future<Map<String, int>> wrongCounts() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT question_id, COUNT(*) AS n
      FROM practice_logs
      WHERE is_correct = 0
      GROUP BY question_id
    ''');
    return {
      for (final r in rows) '${r['question_id']}': int.tryParse('${r['n']}') ?? 0,
    };
  }

  /// Answers per hour of day — tells the user when they actually study.
  Future<List<int>> hourlyActivity() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT CAST(strftime('%H', created_at) AS INTEGER) AS h, COUNT(*) AS n
      FROM practice_logs
      GROUP BY h
    ''');
    final out = List<int>.filled(24, 0);
    for (final r in rows) {
      final h = int.tryParse('${r['h']}') ?? 0;
      if (h >= 0 && h < 24) out[h] = int.tryParse('${r['n']}') ?? 0;
    }
    return out;
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

  /// 把「练习」这件事产生的一切抹掉，回到刚装好的样子。
  ///
  /// 原来只 delete 了 practice_logs，可弹窗上写的是「删除所有答题记录、正确率
  /// 和错题本」—— 清完之后练习历史照样列着、成就照样亮着、打卡连续天数照样在，
  /// 文案承诺大于实际。要清就清干净。
  ///
  /// 收藏、笔记、词语、申论不在此列：那是你自己写的东西，不是练习痕迹。
  Future<void> clearHistory() async {
    final db = await database;
    final batch = db.batch();
    for (final table in const [
      'practice_logs', // 答题记录，正确率和错题本都是从它算出来的
      'exam_reports', // 每场练习/模考的成绩报告
      'wrong_reasons', // 错因标记
      'daily_checkin', // 每日打卡
      'difficulty', // 自评难度
      'review_plans', // 四天专项计划
      'badges', // 成就
    ]) {
      batch.delete(table);
    }
    // 「上次没做完，继续吗」的断点快照。
    batch.delete('meta', where: 'key = ?', whereArgs: [_resumeKey]);
    await batch.commit(noResult: true);
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

  Future<void> toggleMark(String questionId, bool marked, {String? tag}) async {
    final db = await database;
    if (marked) {
      await db.insert(
        'marks',
        {
          'question_id': questionId,
          'tag': tag ?? '',
          'created_at': DateTime.now().toIso8601String(),
        },
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
    return _withMaterials(rows.map(_fromRow).toList());
  }

  /// question id -> tag, for grouping 我的收藏.
  Future<Map<String, String>> markTags() async {
    final db = await database;
    final rows = await db.query('marks', columns: ['question_id', 'tag']);
    return {
      for (final r in rows)
        '${r['question_id']}': '${r['tag'] ?? ''}',
    };
  }

  Future<void> setMarkTag(String questionId, String tag) async {
    final db = await database;
    await db.update(
      'marks',
      {'tag': tag},
      where: 'question_id = ?',
      whereArgs: [questionId],
    );
  }

  // ------------------------------------------------------------- bank health

  /// Structural audit for the bundled bank — coverage + dirty rows.
  /// Not a claim that answers match official keys; that needs human spot-check.
  Future<BankHealthReport> bankHealth() async {
    final db = await database;
    final totals = await db.rawQuery('''
      SELECT
        COUNT(*) AS questions,
        COUNT(DISTINCT paper_id) AS papers,
        MIN(CASE WHEN year > 0 THEN year END) AS year_min,
        MAX(year) AS year_max,
        SUM(CASE WHEN answer IS NULL OR TRIM(answer) = '' THEN 1 ELSE 0 END) AS no_answer,
        SUM(CASE WHEN analysis IS NULL OR TRIM(analysis) = '' THEN 1 ELSE 0 END) AS no_analysis,
        SUM(CASE WHEN length(TRIM(content)) < 8 THEN 1 ELSE 0 END) AS short_content,
        SUM(CASE WHEN has_image = 1 THEN 1 ELSE 0 END) AS with_image
      FROM questions
    ''');
    final t = totals.first;
    final byCat = await db.rawQuery(
      'SELECT category, COUNT(*) AS n FROM questions GROUP BY category ORDER BY n DESC',
    );
    final byYear = await db.rawQuery(
      'SELECT year, COUNT(DISTINCT paper_id) AS papers, COUNT(*) AS questions '
      'FROM questions WHERE year > 0 GROUP BY year ORDER BY year DESC',
    );
    final papers = await db.rawQuery(
      'SELECT paper_id, paper_title, year, COUNT(*) AS n '
      'FROM questions GROUP BY paper_id, paper_title, year '
      'ORDER BY year DESC, paper_title',
    );
    final dirtyRows = await db.rawQuery('''
      SELECT id, paper_title, year, category, answer,
             substr(content, 1, 80) AS preview
      FROM questions
      WHERE answer IS NULL OR TRIM(answer) = ''
         OR TRIM(answer) = '}'
         OR (
           length(TRIM(answer)) <= 3
           AND UPPER(TRIM(answer)) NOT IN (
             'A','B','C','D','E',
             'AB','AC','AD','AE','BC','BD','BE','CD','CE','DE',
             'ABC','ABD','ABE','ACD','ACE','ADE','BCD','BCE','BDE','CDE',
             'ABCD','ABCE','ABDE','ACDE','BCDE','ABCDE'
           )
         )
      ORDER BY year DESC, paper_title
      LIMIT 50
    ''');
    final feedback = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM feedback'),
        ) ??
        0;
    final patchRows =
        await db.query('meta', where: 'key = ?', whereArgs: ['data_patch']);
    final seedRows =
        await db.query('meta', where: 'key = ?', whereArgs: ['seed_version']);

    return BankHealthReport(
      questions: int.tryParse('${t['questions']}') ?? 0,
      papers: int.tryParse('${t['papers']}') ?? 0,
      yearMin: int.tryParse('${t['year_min']}') ?? 0,
      yearMax: int.tryParse('${t['year_max']}') ?? 0,
      noAnswer: int.tryParse('${t['no_answer']}') ?? 0,
      noAnalysis: int.tryParse('${t['no_analysis']}') ?? 0,
      shortContent: int.tryParse('${t['short_content']}') ?? 0,
      withImage: int.tryParse('${t['with_image']}') ?? 0,
      feedback: feedback,
      dataPatch: int.tryParse(
            '${patchRows.isEmpty ? 0 : patchRows.first['value']}',
          ) ??
          0,
      seedVersion: int.tryParse(
            '${seedRows.isEmpty ? 0 : seedRows.first['value']}',
          ) ??
          0,
      byCategory: {
        for (final r in byCat)
          '${r['category'] ?? ''}': int.tryParse('${r['n']}') ?? 0,
      },
      byYear: [
        for (final r in byYear)
          (
            year: int.tryParse('${r['year']}') ?? 0,
            papers: int.tryParse('${r['papers']}') ?? 0,
            questions: int.tryParse('${r['questions']}') ?? 0,
          ),
      ],
      coverage: _coverageFromPapers(papers),
      dirty: [
        for (final r in dirtyRows)
          BankDirtyItem(
            id: '${r['id']}',
            paperTitle: '${r['paper_title'] ?? ''}',
            year: int.tryParse('${r['year']}') ?? 0,
            category: '${r['category'] ?? ''}',
            answer: '${r['answer'] ?? ''}',
            preview: '${r['preview'] ?? ''}',
          ),
      ],
    );
  }

  List<BankCoverageCell> _coverageFromPapers(List<Map<String, Object?>> papers) {
    final cells = <String, BankCoverageCell>{};
    for (final r in papers) {
      final title = '${r['paper_title'] ?? ''}';
      final year = int.tryParse('${r['year']}') ?? 0;
      final n = int.tryParse('${r['n']}') ?? 0;
      final region = _regionFromTitle(title);
      final key = '$region|$year';
      final prev = cells[key];
      cells[key] = BankCoverageCell(
        region: region,
        year: year,
        papers: (prev?.papers ?? 0) + 1,
        questions: (prev?.questions ?? 0) + n,
      );
    }
    final list = cells.values.toList()
      ..sort((a, b) {
        final c = b.questions.compareTo(a.questions);
        if (c != 0) return c;
        return a.region.compareTo(b.region);
      });
    return list;
  }

  String _regionFromTitle(String title) {
    if (title.contains('国家公务员') || title.contains('国考')) return '国考';
    for (final p in const [
      '北京', '上海', '广东', '江苏', '浙江', '山东', '河南', '河北', '四川', '湖北',
      '湖南', '安徽', '福建', '江西', '陕西', '山西', '辽宁', '吉林', '黑龙江',
      '云南', '贵州', '广西', '天津', '重庆', '内蒙古', '新疆', '甘肃', '海南',
      '宁夏', '青海', '西藏',
    ]) {
      if (title.contains(p)) return p;
    }
    return '其他';
  }

  Future<Question?> questionById(String id) async {
    final db = await database;
    final rows = await db.query('questions', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return _fromRow(rows.first);
  }
}

class BankHealthReport {
  const BankHealthReport({
    required this.questions,
    required this.papers,
    required this.yearMin,
    required this.yearMax,
    required this.noAnswer,
    required this.noAnalysis,
    required this.shortContent,
    required this.withImage,
    required this.feedback,
    required this.dataPatch,
    required this.seedVersion,
    required this.byCategory,
    required this.byYear,
    required this.coverage,
    required this.dirty,
  });

  final int questions;
  final int papers;
  final int yearMin;
  final int yearMax;
  final int noAnswer;
  final int noAnalysis;
  final int shortContent;
  final int withImage;
  final int feedback;
  final int dataPatch;
  final int seedVersion;
  final Map<String, int> byCategory;
  final List<({int year, int papers, int questions})> byYear;
  final List<BankCoverageCell> coverage;
  final List<BankDirtyItem> dirty;

  int get dirtyCount => dirty.length + noAnswer + noAnalysis;
}

class BankCoverageCell {
  const BankCoverageCell({
    required this.region,
    required this.year,
    required this.papers,
    required this.questions,
  });

  final String region;
  final int year;
  final int papers;
  final int questions;
}

class BankDirtyItem {
  const BankDirtyItem({
    required this.id,
    required this.paperTitle,
    required this.year,
    required this.category,
    required this.answer,
    required this.preview,
  });

  final String id;
  final String paperTitle;
  final int year;
  final String category;
  final String answer;
  final String preview;
}
