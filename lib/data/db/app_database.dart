import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:openexam_app/core/constants/categories.dart';
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

  /// 内置题库的版本。**换了 assets/seed/openexam_seed.db.gz 就要把它 +1**，
  /// 否则老用户永远拿不到新题库。
  ///
  /// 以前 [_installSeed] 只在数据库文件不存在时跑一次，于是题库等于"装机时
  /// 快照"：后来补进种子的资料分析材料、修好的分类标签、改对的题干，装过 app
  /// 的人一个都拿不到 —— 升级 APK 也没用。用户报的"横线还是没有"就是这么来的，
  /// 那批题在新种子里早就是对的。
  static const _seedVersion = 5;

  /// 题库自己的表。换种子时这些整体来自新种子，其余表都是用户数据，要搬过来。
  ///
  /// 用"排除法"而不是列一份用户表清单：以后加了新表忘了往清单里补，
  /// 是会把用户数据搬丢的，而漏掉一张题库表最多只是白搬一次。
  static const _bankTables = {
    'questions',
    'materials',
    'images',
    'word_freq',
    'android_metadata',
    'sqlite_sequence',
  };

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    final path = p.join(dir, _dbFile);

    if (!await File(path).exists()) {
      await _installSeed(path);
      await _migrateLegacyHistory(dir, path);
    } else {
      await _refreshSeedIfStale(path);
    }

    final db = await openDatabase(path);
    await _ensureBankTables(db);
    await _ensureRuntimeTables(db);
    return db;
  }

  /// 内置题库比本机的新时，换掉题库、把用户数据原样搬过去。
  ///
  /// 全程不动 [path]，直到新库建好、数据搬完为止；中途任何一步出错就把临时
  /// 文件删掉走人，用户库保持原样 —— 宁可这次没升级成题库，也不能弄丢做题记录。
  Future<void> _refreshSeedIfStale(String path) async {
    int installed;
    try {
      final probe = await openDatabase(path, readOnly: true);
      final rows = await probe.query(
        'meta',
        where: 'key = ?',
        whereArgs: ['seed_version'],
        limit: 1,
      );
      await probe.close();
      installed = int.tryParse('${rows.isEmpty ? 0 : rows.first['value']}') ?? 0;
    } catch (_) {
      // meta 表都读不出来的库，不敢拿它做判断，更不敢动它。
      return;
    }
    if (installed >= _seedVersion) return;
    // 不打包题库的版本没什么可换的，更不能拿一个空种子去盖掉用户导进来的题。
    if (!await hasBundledBank) return;

    final fresh = '$path.new';
    final backup = '$path.bak';
    try {
      await File(fresh).delete();
    } catch (_) {
      // 上次中断留下的残骸，没有更好。
    }

    try {
      await _installSeed(fresh);
      await _carryUserData(from: path, to: fresh);

      // 换文件而不是就地改：中途断电时，要么还是老库，要么已经是新库。
      await File(path).rename(backup);
      await File(fresh).rename(path);
      try {
        await File(backup).delete();
      } catch (_) {
        // 删不掉只是占地方，不影响用。
      }
    } catch (_) {
      try {
        await File(fresh).delete();
      } catch (_) {
        // 清不掉临时文件也不该拦住启动。
      }
      // 老库原封不动，这次就先不升级题库。
    }
  }

  /// 把 [from] 里所有非题库表的数据搬进 [to]。
  Future<void> _carryUserData({required String from, required String to}) async {
    final db = await openDatabase(to);
    try {
      // 先把运行时表和后加的列在新库上补齐，再搬数据。
      //
      // 种子里的 practice_logs 没有 elapsed_ms（那列是后来 ALTER 加的），
      // 不先补就会在"取两边都有的列"这一步把逐题用时整列丢掉 ——
      // 而那正是弱点诊断算配速要用的东西。
      await _ensureRuntimeTables(db);

      // meta 里既有用户的东西（data_patch），也有题库自己的 seed_version。
      // 整表 INSERT OR REPLACE 会把老库的 seed_version 盖回去，下次启动
      // 又判定成"该升级了"，无限重装种子。先把新种子的版本记下来，搬完写回去。
      final stamp = await db.query(
        'meta',
        where: 'key = ?',
        whereArgs: ['seed_version'],
        limit: 1,
      );
      final freshVersion = stamp.isEmpty ? null : '${stamp.first['value']}';

      // 用户库里可能有新种子还没有的表（版本落后时反过来也一样），
      // 所以先按老库的定义把表建出来，再灌数据。
      await db.execute("ATTACH DATABASE ? AS old", [from]);
      final tables = await db.rawQuery(
        "SELECT name, sql FROM old.sqlite_master "
        "WHERE type = 'table' AND name NOT LIKE 'sqlite_%'",
      );
      for (final row in tables) {
        final name = '${row['name']}';
        if (_bankTables.contains(name)) continue;
        final ddl = '${row['sql'] ?? ''}';
        if (ddl.isEmpty) continue;
        // 新库里已经有的表保持新库的定义，只灌数据；没有的按老库建。
        await db.execute(
          ddl.replaceFirst(
            RegExp('CREATE TABLE', caseSensitive: false),
            'CREATE TABLE IF NOT EXISTS',
          ),
        );
        var cols = await db.rawQuery('PRAGMA table_info("$name")');
        final oldCols = await db.rawQuery('PRAGMA old.table_info("$name")');

        // 老库有、新库没有的列直接补上。上一版 app 加过而这一版没在
        // _ensureRuntimeTables 里声明的列，靠这一步兜住，不然那列就没了。
        for (final o in oldCols) {
          final col = '${o['name']}';
          if (cols.any((c) => '${c['name']}' == col)) continue;
          try {
            await db.execute('ALTER TABLE "$name" ADD COLUMN "$col" ${o['type']}');
          } catch (_) {
            // 加不上就只能放弃这一列，不该拖垮整次迁移。
          }
        }
        cols = await db.rawQuery('PRAGMA table_info("$name")');

        final shared = cols
            .map((c) => '${c['name']}')
            .where((c) => oldCols.any((o) => '${o['name']}' == c))
            .map((c) => '"$c"')
            .join(', ');
        if (shared.isEmpty) continue;
        await db.execute(
          'INSERT OR REPLACE INTO main."$name" ($shared) '
          'SELECT $shared FROM old."$name"',
        );
      }
      await db.execute('DETACH DATABASE old');

      if (freshVersion != null) {
        await db.insert(
          'meta',
          {'key': 'seed_version', 'value': freshVersion},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    } finally {
      await db.close();
    }
  }

  /// Unpacks the bundled seed. gzip decode runs off the UI isolate — the file
  /// is ~90 MB expanded.
  ///
  /// 返回有没有真的装上。**内置题库是可选的** —— App Store 那个版本不打包题库
  /// （题库是别人的真题，体积也压不进审核友好的范围），装不到就开一个空库，
  /// 用户自己导入。所以这里找不到 asset 不是错误，是一种正常的发行形态。
  Future<bool> _installSeed(String path) async {
    final ByteData data;
    try {
      data = await rootBundle.load(_seedAsset);
    } catch (_) {
      return false;
    }
    final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    final decoded = await compute(_gunzip, bytes);
    await File(path).writeAsBytes(decoded, flush: true);
    return true;
  }

  /// 这个包里带没带题库。空库版的引导文案要靠它区分「还没导入」和「导入失败」。
  static Future<bool> get hasBundledBank async {
    try {
      await rootBundle.load(_seedAsset);
      return true;
    } catch (_) {
      return false;
    }
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

  /// 题库自己的两张表。
  ///
  /// 平时它们随种子一起来，app 从不建 —— 于是不打包题库的那个版本一开库就
  /// 崩在第一条查询上。空库也得是一个结构完整的库：能打开、能导入、能刷。
  /// 字段跟 tool/build_seed.py 写出来的种子逐列对齐，改一边要改另一边。
  Future<void> _ensureBankTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS questions (
        id TEXT PRIMARY KEY,
        content TEXT NOT NULL,
        content_html TEXT,
        options TEXT NOT NULL,
        answer TEXT NOT NULL,
        category TEXT,
        sub_category TEXT,
        analysis TEXT,
        analysis_html TEXT,
        paper_id TEXT,
        paper_title TEXT,
        year INTEGER DEFAULT 0,
        difficulty INTEGER DEFAULT 2,
        source TEXT DEFAULT 'builtin',
        has_image INTEGER DEFAULT 0,
        order_num INTEGER DEFAULT 0,
        material_id TEXT DEFAULT '',
        type TEXT NOT NULL DEFAULT 'single'
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS images (
        name TEXT PRIMARY KEY,
        bytes BLOB NOT NULL
      )
    ''');
    for (final sql in const [
      'CREATE INDEX IF NOT EXISTS idx_q_cat ON questions(category)',
      'CREATE INDEX IF NOT EXISTS idx_q_source ON questions(source)',
      'CREATE INDEX IF NOT EXISTS idx_q_paper ON questions(paper_id)',
    ]) {
      try {
        await db.execute(sql);
      } catch (_) {
        // 老库上 questions 可能是只读附加表，建不了索引也不该拦住启动。
      }
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

    // 高频词表。种子库里带着（从逻辑填空的选项统计），老库没有就建个空的，
    // 页面自己会显示「这版题库还没带词频」而不是崩。
    await db.execute('''
      CREATE TABLE IF NOT EXISTS word_freq (
        word TEXT PRIMARY KEY,
        count INTEGER NOT NULL,
        sample_question_id TEXT NOT NULL DEFAULT ''
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_word_freq_count ON word_freq(count DESC)',
    );

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
        created_at TEXT NOT NULL,
        cursor INTEGER NOT NULL DEFAULT 0,
        done INTEGER NOT NULL DEFAULT 1,
        score REAL,
        max_score REAL
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
    // 不挂在任何题上的笔记。
    //
    // notes 表的主键是 question_id，天生只能记"这道题的心得"。可备考时更想
    // 随手记的往往是跟具体某道题无关的东西：一个公式、一次考试的教训、
    // 某个坑的通用解法。那些原来一个字都存不下。
    await db.execute('''
      CREATE TABLE IF NOT EXISTS memos (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL DEFAULT '',
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
    // 进度两列是后加的：以前只有交完卷才写一行，做到一半退出就什么都不剩。
    // 老库里没有这两列，补上，默认当作已完成。
    final cols = await db.rawQuery('PRAGMA table_info(exam_reports)');
    final names = cols.map((c) => '${c['name']}').toSet();
    if (!names.contains('cursor')) {
      await db.execute(
        'ALTER TABLE exam_reports ADD COLUMN cursor INTEGER NOT NULL DEFAULT 0',
      );
    }
    if (!names.contains('done')) {
      await db.execute(
        'ALTER TABLE exam_reports ADD COLUMN done INTEGER NOT NULL DEFAULT 1',
      );
    }
    // 申论按分数算，没有对错，另存两列
    if (!names.contains('score')) {
      await db.execute('ALTER TABLE exam_reports ADD COLUMN score REAL');
      await db.execute('ALTER TABLE exam_reports ADD COLUMN max_score REAL');
    }

    // AI 用量。key 是用户自己的，花的是他自己的钱 —— 花在哪、花了多少，
    // 得让他看得见，而不是只能去服务商后台猜。
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ai_usage (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        at INTEGER NOT NULL,
        feature TEXT NOT NULL,
        model TEXT NOT NULL DEFAULT '',
        input_tokens INTEGER NOT NULL DEFAULT 0,
        output_tokens INTEGER NOT NULL DEFAULT 0,
        ok INTEGER NOT NULL DEFAULT 1
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_ai_usage_at ON ai_usage(at)',
    );

    // AI 讲的那一段。同一道题会反复回看，每看一次都重新问一遍模型
    // 既慢又费钱，讲完就存下来。
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ai_explanations (
        question_id TEXT PRIMARY KEY,
        body TEXT NOT NULL,
        model TEXT NOT NULL DEFAULT '',
        created_at INTEGER NOT NULL
      )
    ''');
    // AI 写的弱点诊断。key 是诊断对象：'history' 或 'report:<id>'。
    // 存下来是因为一次诊断要几十秒也要花钱，切走再回来不该重来一遍。
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ai_diagnoses (
        key TEXT PRIMARY KEY,
        body TEXT NOT NULL,
        model TEXT NOT NULL DEFAULT '',
        created_at INTEGER NOT NULL
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

  // --------------------------------------------------------------- AI 用量

  Future<void> logAiUsage({
    required String feature,
    required String model,
    required int inputTokens,
    required int outputTokens,
    bool ok = true,
  }) async {
    final db = await database;
    await db.insert('ai_usage', {
      'at': DateTime.now().millisecondsSinceEpoch,
      'feature': feature,
      'model': model,
      'input_tokens': inputTokens,
      'output_tokens': outputTokens,
      'ok': ok ? 1 : 0,
    });
  }

  /// [since] 之后的用量，按 [groupBy] 汇总（feature 或 model）。
  Future<List<AiUsageGroup>> aiUsageBy(
    String groupBy, {
    DateTime? since,
  }) async {
    assert(groupBy == 'feature' || groupBy == 'model');
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT $groupBy AS k, COUNT(*) AS calls, '
      'SUM(input_tokens) AS i, SUM(output_tokens) AS o '
      'FROM ai_usage WHERE at >= ? GROUP BY $groupBy ORDER BY (SUM(input_tokens)+SUM(output_tokens)) DESC',
      [since?.millisecondsSinceEpoch ?? 0],
    );
    return rows
        .map((r) => AiUsageGroup(
              key: '${r['k'] ?? ''}',
              calls: int.tryParse('${r['calls']}') ?? 0,
              inputTokens: int.tryParse('${r['i']}') ?? 0,
              outputTokens: int.tryParse('${r['o']}') ?? 0,
            ))
        .toList();
  }

  /// 最近 [days] 天每天的 token 合计，缺的那天补 0 —— 折线图不能断。
  Future<List<int>> aiUsageDaily({int days = 14}) async {
    final db = await database;
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: days - 1));
    final rows = await db.rawQuery(
      'SELECT at, input_tokens, output_tokens FROM ai_usage WHERE at >= ?',
      [start.millisecondsSinceEpoch],
    );
    final out = List<int>.filled(days, 0);
    for (final r in rows) {
      final at = DateTime.fromMillisecondsSinceEpoch(
          int.tryParse('${r['at']}') ?? 0);
      final idx = DateTime(at.year, at.month, at.day).difference(start).inDays;
      if (idx < 0 || idx >= days) continue;
      out[idx] += (int.tryParse('${r['input_tokens']}') ?? 0) +
          (int.tryParse('${r['output_tokens']}') ?? 0);
    }
    return out;
  }

  Future<void> clearAiUsage() async {
    final db = await database;
    await db.delete('ai_usage');
  }

  // ----------------------------------------------------------- AI 讲解缓存

  /// 这道题 AI 讲过没有。讲过就直接拿出来，不再问模型。
  ///
  /// 连模型名和时间一起返回 —— 这段话是机器写的，得让人看得见是谁、什么时候
  /// 写的，否则日子久了根本分不清哪些是题库的解析、哪些是 AI 的。
  Future<AiExplanation?> aiDiagnosis(String key) async {
    final db = await database;
    final rows = await db.query(
      'ai_diagnoses',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final body = '${rows.first['body'] ?? ''}';
    if (body.isEmpty) return null;
    return AiExplanation(
      body: body,
      model: '${rows.first['model'] ?? ''}',
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        int.tryParse('${rows.first['created_at']}') ?? 0,
      ),
    );
  }

  Future<void> saveAiDiagnosis(String key, String body, {String model = ''}) async {
    final db = await database;
    await db.insert(
      'ai_diagnoses',
      {
        'key': key,
        'body': body,
        'model': model,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteAiDiagnosis(String key) async {
    final db = await database;
    await db.delete('ai_diagnoses', where: 'key = ?', whereArgs: [key]);
  }

  Future<AiExplanation?> aiExplanation(String questionId) async {
    final db = await database;
    final rows = await db.query(
      'ai_explanations',
      where: 'question_id = ?',
      whereArgs: [questionId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final body = '${rows.first['body'] ?? ''}';
    if (body.isEmpty) return null;
    return AiExplanation(
      body: body,
      model: '${rows.first['model'] ?? ''}',
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        int.tryParse('${rows.first['created_at']}') ?? 0,
      ),
    );
  }

  Future<void> saveAiExplanation(
    String questionId,
    String body, {
    String model = '',
  }) async {
    final db = await database;
    await db.insert(
      'ai_explanations',
      {
        'question_id': questionId,
        'body': body,
        'model': model,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteAiExplanation(String questionId) async {
    final db = await database;
    await db.delete(
      'ai_explanations',
      where: 'question_id = ?',
      whereArgs: [questionId],
    );
  }

  /// 每道题最后一次填的答案。
  ///
  /// 错题速览要显示"你当时选的是什么"—— 光看正确答案，等于没在复盘。
  Future<Map<String, String>> lastAnswers(List<String> questionIds) async {
    if (questionIds.isEmpty) return const {};
    final db = await database;
    final marks = List.filled(questionIds.length, '?').join(',');
    final rows = await db.rawQuery(
      '''
      SELECT question_id, user_answer
      FROM practice_logs
      WHERE question_id IN ($marks)
      ORDER BY id ASC
      ''',
      questionIds,
    );
    // 按 id 升序覆盖，最后留下的就是最近一次
    final out = <String, String>{};
    for (final r in rows) {
      final a = '${r['user_answer'] ?? ''}'.trim().toUpperCase();
      if (a.isEmpty) continue;
      out['${r['question_id']}'] = a;
    }
    return out;
  }

  // ------------------------------------------------------------- 题库问题排查

  /// 答案缺失或不合法的题。
  ///
  /// 这类题在练习里怎么点都是错的 —— 导入时原资料没给答案、或者答案页
  /// 单独列在别处没对上，最常见。
  Future<List<Question>> questionsMissingAnswer({int limit = 300}) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT * FROM questions
      WHERE answer IS NULL OR TRIM(answer) = ''
         OR UPPER(TRIM(answer)) NOT IN (
           'A','B','C','D','E',
           'AB','AC','AD','AE','BC','BD','BE','CD','CE','DE',
           'ABC','ABD','ABE','ACD','ACE','ADE','BCD','BCE','BDE','CDE',
           'ABCD','ABCE','ABDE','ACDE','BCDE','ABCDE'
         )
      LIMIT ?
    ''', [limit]);
    return rows.map(_fromRow).toList();
  }

  /// 选项少于两个的题。基本是解析出错留下的残骸，做不了。
  ///
  /// 选项是 JSON，SQL 里数不了个数，只能拿回来解析。但只取 id 和 options 两列
  /// —— 以前是 `query('questions', limit: 2000)`，既把题干解析全拖了一遍内存，
  /// 又只看前 2000 道，第 2001 道之后的残骸永远查不出来。
  Future<List<Question>> questionsBrokenOptions({int limit = 300}) async {
    final db = await database;
    final rows = await db.query('questions', columns: ['id', 'options']);
    final broken = <String>[];
    for (final r in rows) {
      // fromRow 缺列一律回退成空串，两列足够数选项个数。
      if (Question.fromRow(r).options.length < 2) {
        broken.add('${r['id']}');
        if (broken.length >= limit) break;
      }
    }
    if (broken.isEmpty) return const [];
    final full = await db.query(
      'questions',
      where: 'id IN (${List.filled(broken.length, '?').join(',')})',
      whereArgs: broken,
    );
    return full.map(_fromRow).toList();
  }

  /// 同一份卷子里出现了两遍的题。
  ///
  /// 原来这里按 `content` 全库分组，谁跟谁题干一样就算一组重复 —— 结果内置库
  /// 18686 道题里有 14535 道（78%）被判成重复。原因是题干根本不能单独标识一道题：
  ///
  /// * 图形推理的题干是"从所给的四个选项中，选择最合适的一个填入问号处"，
  ///   内置库 556 道共用这一句，真正的题在图里，选项也统一是 A/B/C/D；
  /// * 资料分析的题干是"能够从上述资料中推出的是"，题在材料里。
  ///
  /// 于是"全部清理"会把图形推理和资料分析各删到只剩一道。
  ///
  /// 而且把题干、图、选项、材料全比上之后仍然撞在一起的 2956 组里，2953 组是
  /// **跨卷**的 —— 联考各省共用题、国考三卷共用题，本来就该各卷都有一份，删掉
  /// 就把别的卷打出窟窿。真正的脏数据只有同一份卷里收了两遍的，内置库 3 组 6 道。
  /// 所以这里只查同卷重复，并且带上选项、
  /// 材料、图片一起比，避免再拿共用题干当身份。图片比的是 content_html —— 图
  /// 是 `oeimg://<内容哈希>` 引进来的，同图同哈希，正好当图形推理的身份。
  Future<List<List<Question>>> duplicateQuestions({int limit = 100}) async {
    final db = await database;
    final keys = await db.rawQuery('''
      SELECT paper_id, TRIM(content) AS c, content_html, options, material_id
      FROM questions
      WHERE TRIM(content) != '' AND paper_id IS NOT NULL AND paper_id != ''
      GROUP BY paper_id, TRIM(content), content_html, options, material_id
      HAVING COUNT(*) > 1
      LIMIT ?
    ''', [limit]);
    final out = <List<Question>>[];
    for (final k in keys) {
      final dupes = await db.query(
        'questions',
        where: 'paper_id = ? AND TRIM(content) = ? AND content_html = ? '
            'AND options = ? AND material_id = ?',
        whereArgs: [
          k['paper_id'],
          k['c'],
          k['content_html'],
          k['options'],
          k['material_id'],
        ],
        orderBy: 'order_num',
      );
      if (dupes.length > 1) out.add(dupes.map(_fromRow).toList());
    }
    return out;
  }

  Future<void> setQuestionAnswer(String id, String answer) async {
    final db = await database;
    await db.update(
      'questions',
      {'answer': answer.trim().toUpperCase()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteQuestion(String id) async {
    final db = await database;
    await db.delete('questions', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteQuestions(List<String> ids) async {
    if (ids.isEmpty) return;
    final db = await database;
    final batch = db.batch();
    for (final id in ids) {
      batch.delete('questions', where: 'id = ?', whereArgs: [id]);
    }
    await batch.commit(noResult: true);
  }

  /// 导出题库本身。
  ///
  /// 「备份与恢复」导的是用户数据（做题记录、笔记、错题原因），**不含题目** ——
  /// 换手机之后记录都在，题却是空的。这个补上另一半。
  Future<List<Map<String, Object?>>> exportQuestions() async {
    final db = await database;
    return db.query('questions', orderBy: 'paper_id, order_num');
  }

  /// 整库的题，按卷和题号排。导出用。
  ///
  /// 跟 [exportQuestions] 的区别是这个带材料 —— 导出的题少了材料，
  /// 对方导进去就是一堆答不了的资料分析。
  Future<List<Question>> fetchAllQuestions() async {
    final db = await database;
    final rows = await db.query('questions', orderBy: 'paper_id, order_num');
    return _withMaterials(rows.map(_fromRow).toList());
  }

  /// 清空题库。
  ///
  /// 只删题和材料，不动做题记录 —— 记录按 question_id 存，重新导入同一批题
  /// 还能对上。真要连记录一起清，那是「清除练习记录」那一项的事。
  Future<int> clearQuestions() async {
    final db = await database;
    final n = await db.delete('questions');
    await db.delete('materials');
    return n;
  }

  /// 改一个分类的名字。改成已经存在的名字，就是把两类并成一类。
  Future<int> renameCategory(String from, String to) async {
    final db = await database;
    return db.update(
      'questions',
      {'category': to.trim()},
      where: 'category = ?',
      whereArgs: [from],
    );
  }

  /// 某个分类下的题，只取归类要用的那几列 —— 整题拉出来太重。
  Future<List<({String id, String content})>> questionBriefs(
    String category, {
    int limit = 500,
  }) async {
    final db = await database;
    final rows = await db.query(
      'questions',
      columns: ['id', 'content'],
      where: 'category = ?',
      whereArgs: [category],
      limit: limit,
    );
    return [
      for (final r in rows)
        (id: '${r['id']}', content: '${r['content'] ?? ''}'),
    ];
  }

  /// 按 id 逐条改分类。AI 归类完一批就落一批。
  Future<void> setCategoryFor(Map<String, String> idToCategory) async {
    if (idToCategory.isEmpty) return;
    final db = await database;
    final batch = db.batch();
    for (final e in idToCategory.entries) {
      batch.update(
        'questions',
        {'category': e.value},
        where: 'id = ?',
        whereArgs: [e.key],
      );
    }
    await batch.commit(noResult: true);
  }

  /// 题库里实际有哪些分类。导入别的考试之后，各处筛选器靠它才知道多了什么。
  Future<List<String>> categoryKeys() async {
    final db = await database;
    final rows = await db.rawQuery(
      "SELECT category, COUNT(*) AS n FROM questions "
      "WHERE category IS NOT NULL AND category != '' "
      "GROUP BY category ORDER BY n DESC",
    );
    return rows.map((r) => '${r['category']}').toList();
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

  /// 题库里最新的年份。年份范围筛选拿它当基准。
  ///
  /// 一次查询就够，之后缓着 —— 每次抽题都跑一遍 MAX(year) 是白花的全表扫。
  int? _latestYear;

  Future<int> latestYear() async {
    final cached = _latestYear;
    if (cached != null) return cached;
    final db = await database;
    final v = Sqflite.firstIntValue(
          await db.rawQuery('SELECT MAX(year) FROM questions'),
        ) ??
        0;
    return _latestYear = v;
  }

  /// 每个年份范围里还剩多少题。挑范围的时候得先知道有没有题，
  /// 不然选完「最近一年」才发现一道都抽不出来。
  Future<Map<YearRange, int>> yearRangeCounts({String? category}) async {
    final db = await database;
    final latest = await latestYear();
    final out = <YearRange, int>{};
    for (final r in YearRange.values) {
      final where = <String>[];
      final args = <Object?>[];
      if (category != null && category.isNotEmpty && category != 'all') {
        where.add('category = ?');
        args.add(category);
      }
      final floor = r.floor(latest);
      if (floor != null) {
        where.add('year >= ?');
        args.add(floor);
      }
      final sql = StringBuffer('SELECT COUNT(*) FROM questions');
      if (where.isNotEmpty) sql.write(' WHERE ${where.join(' AND ')}');
      out[r] = Sqflite.firstIntValue(
            await db.rawQuery(sql.toString(), args),
          ) ??
          0;
    }
    return out;
  }

  Future<List<Question>> fetchPractice({
    String? category,
    String? subCategory,
    int limit = 20,
    bool shuffle = true,
    QuestionScope scope = QuestionScope.all,
    YearRange years = YearRange.all,
  }) async {
    final db = await database;
    final where = <String>[];
    final args = <Object?>[];
    if (category != null && category.isNotEmpty && category != 'all') {
      where.add('category = ?');
      args.add(category);
    }
    final floor = years.floor(await latestYear());
    if (floor != null) {
      where.add('year >= ?');
      args.add(floor);
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

  /// 这台手机里真实存在的报考地区，卷子多的排前面。
  ///
  /// 「你在哪考」的选项必须从这儿来，不能拿 [kProvinces] 直接铺 ——
  /// 那是一张认卷名用的匹配词表。空库版（App Store 那个）一张中国卷都
  /// 没有，铺出来就是问用户「国考 / 北京 / 上海」选哪个，而他手上什么
  /// 都没有。返回空表就是「这一段不该出现」。
  Future<List<String>> bankRegions() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT paper_title, COUNT(DISTINCT paper_id) AS papers
      FROM questions
      WHERE paper_title IS NOT NULL AND paper_title != ''
      GROUP BY paper_title
    ''');
    final tally = <String, int>{};
    for (final row in rows) {
      final region = regionOfPaperTitle('${row['paper_title']}');
      // 「其他」不是一个能选的报考地区，是兜底桶。
      if (region == '其他') continue;
      tally[region] = (tally[region] ?? 0) +
          (int.tryParse('${row['papers'] ?? 0}') ?? 0);
    }
    final regions = tally.keys.toList()
      ..sort((a, b) {
        // 国考排第一：它是所有人都要考的那张。
        if (a == '国考') return -1;
        if (b == '国考') return 1;
        return tally[b]!.compareTo(tally[a]!);
      });
    return regions;
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

  // ------------------------------------------------------------------ 随手记

  Future<List<Memo>> listMemos({int limit = 300}) async {
    final db = await database;
    final rows = await db.query(
      'memos',
      orderBy: 'updated_at DESC',
      limit: limit,
    );
    return rows.map(Memo.fromRow).toList();
  }

  Future<void> saveMemo(Memo memo) async {
    final db = await database;
    await db.insert(
      'memos',
      {
        'id': memo.id,
        'title': memo.title,
        'body': memo.body,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteMemo(String id) async {
    final db = await database;
    await db.delete('memos', where: 'id = ?', whereArgs: [id]);
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

  // --------------------------------------------------------------- 高频词

  /// 逻辑填空考过的词，按考的次数排。
  ///
  /// [minCount] 卡「高频」的线：≥10 次的有 416 个，够背一阵；调到 1 就是
  /// 整张词表（4000 多个），查词时用。
  Future<List<WordFreq>> topWords({int minCount = 10, int limit = 500}) async {
    final db = await database;
    final rows = await db.query(
      'word_freq',
      where: 'count >= ?',
      whereArgs: [minCount],
      orderBy: 'count DESC, word ASC',
      limit: limit,
    );
    return rows.map(WordFreq.fromRow).toList();
  }

  /// 查词。先精确后前缀再包含 —— 输「一以」要先看到「一以贯之」。
  Future<List<WordFreq>> searchWords(String query, {int limit = 60}) async {
    final q = query.trim();
    if (q.isEmpty) return const [];
    final db = await database;
    final rows = await db.rawQuery(
      '''
      SELECT * FROM word_freq
      WHERE word LIKE ?
      ORDER BY (word = ?) DESC, (word LIKE ?) DESC, count DESC
      LIMIT ?
      ''',
      ['%$q%', q, '$q%', limit],
    );
    return rows.map(WordFreq.fromRow).toList();
  }

  /// 这个词在哪些题里考过。逻辑填空的选项就是词，所以直接对选项做匹配。
  Future<List<Question>> questionsUsing(String word, {int limit = 20}) async {
    final db = await database;
    final rows = await db.query(
      'questions',
      where: "sub_category = 'xuanci' AND options LIKE ?",
      whereArgs: ['%$word%'],
      limit: limit,
    );
    return _withMaterials(rows.map(_fromRow).toList());
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
    int cursor = 0,
    bool done = true,
    double? score,
    double? maxScore,
  }) async {
    final db = await database;
    return db.insert('exam_reports', {
      'score': score,
      'max_score': maxScore,
      'title': title,
      'kind': kind,
      'total': questionIds.length,
      'answered': answers.length,
      'correct': correct,
      'elapsed_ms': elapsed.inMilliseconds,
      'question_ids': jsonEncode(questionIds),
      'answers': jsonEncode(answers),
      'created_at': DateTime.now().toIso8601String(),
      'cursor': cursor,
      'done': done ? 1 : 0,
    });
  }

  /// 边做边更新同一行。
  ///
  /// 一次练习从头到尾只占一条记录 —— 每答一题新插一行的话，记录页会被
  /// 同一组练习的二十个残影填满。
  Future<void> updateReportProgress(
    int id, {
    required Map<String, String> answers,
    required int correct,
    required Duration elapsed,
    required int cursor,
    required bool done,
  }) async {
    final db = await database;
    await db.update(
      'exam_reports',
      {
        'answered': answers.length,
        'correct': correct,
        'elapsed_ms': elapsed.inMilliseconds,
        'answers': jsonEncode(answers),
        'cursor': cursor,
        'done': done ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 最近一条没做完的，首页拿它显示"接着做"。
  Future<ExamReport?> latestUnfinished() async {
    final db = await database;
    final rows = await db.query(
      'exam_reports',
      where: 'done = 0',
      orderBy: 'id DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ExamReport.fromRow(rows.first);
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

  /// 弱点诊断的全部输入，一次查完。
  ///
  /// 页面上的结论要能在没配 AI 的时候照样出，所以这里给的是**算好的数**，
  /// 不是等着模型去数的原始记录。模型拿到的也是这一份的压缩版。
  Future<DiagnosisData> diagnosisData({int recentDays = 14}) async {
    final db = await database;
    final now = DateTime.now();
    final cut = now.subtract(Duration(days: recentDays)).toIso8601String();

    Future<DiagnosisSlice> window(String where, List<Object?> args) async {
      final row = (await db.rawQuery('''
        SELECT COUNT(*) AS n,
               SUM(CASE WHEN is_correct = 1 THEN 1 ELSE 0 END) AS c,
               AVG(CASE WHEN elapsed_ms > 0 THEN elapsed_ms END) AS ms
        FROM practice_logs WHERE $where
      ''', args))
          .first;
      return DiagnosisSlice(
        key: '',
        attempts: int.tryParse('${row['n']}') ?? 0,
        correct: int.tryParse('${row['c']}') ?? 0,
        avgSeconds: ((double.tryParse('${row['ms']}') ?? 0) / 1000).round(),
      );
    }

    final overall = await window('1 = 1', const []);
    final recent = await window('created_at >= ?', [cut]);
    final earlier = await window('created_at < ?', [cut]);

    Future<List<DiagnosisSlice>> group(String column, {int limit = 20}) async {
      final rows = await db.rawQuery('''
        SELECT q.$column AS k,
               COUNT(*) AS n,
               SUM(CASE WHEN l.is_correct = 1 THEN 1 ELSE 0 END) AS c,
               AVG(CASE WHEN l.elapsed_ms > 0 THEN l.elapsed_ms END) AS ms
        FROM practice_logs l
        JOIN questions q ON q.id = l.question_id
        WHERE q.$column IS NOT NULL AND TRIM(q.$column) != ''
        GROUP BY q.$column
        ORDER BY n DESC
        LIMIT ?
      ''', [limit]);
      return [
        for (final r in rows)
          DiagnosisSlice(
            key: '${r['k']}',
            attempts: int.tryParse('${r['n']}') ?? 0,
            correct: int.tryParse('${r['c']}') ?? 0,
            avgSeconds: ((double.tryParse('${r['ms']}') ?? 0) / 1000).round(),
          ),
      ];
    }

    final activeDays = Sqflite.firstIntValue(await db.rawQuery(
          'SELECT COUNT(DISTINCT substr(created_at, 1, 10)) FROM practice_logs',
        )) ??
        0;
    final firstRow = await db.rawQuery(
      'SELECT MIN(created_at) AS t FROM practice_logs',
    );
    final firstAt = DateTime.tryParse('${firstRow.first['t'] ?? ''}');

    final reasonRows = await db.rawQuery(
      'SELECT reason, COUNT(*) AS n FROM wrong_reasons GROUP BY reason',
    );
    final byReason = <String, int>{
      for (final r in reasonRows)
        '${r['reason']}': int.tryParse('${r['n']}') ?? 0,
    };

    // 错题本 = 最后一次作答是错的那些题。跟 fetchWrong 同一个口径。
    const stillWrong = '''
      SELECT l.question_id AS qid FROM practice_logs l
      JOIN (SELECT question_id, MAX(id) AS last_id FROM practice_logs
            GROUP BY question_id) last ON last.last_id = l.id
      WHERE l.is_correct = 0
    ''';
    final wrongTotal = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM ($stillWrong)'),
        ) ??
        0;
    final repeatWrong = Sqflite.firstIntValue(await db.rawQuery('''
          SELECT COUNT(*) FROM (
            SELECT question_id FROM practice_logs
            WHERE question_id IN ($stillWrong) AND is_correct = 0
            GROUP BY question_id HAVING COUNT(*) > 1
          )
        ''')) ??
        0;

    final topRows = await db.rawQuery('''
      SELECT q.category AS cat, q.sub_category AS sub,
             COUNT(*) AS times, q.content AS content
      FROM practice_logs l
      JOIN questions q ON q.id = l.question_id
      WHERE l.is_correct = 0 AND l.question_id IN ($stillWrong)
      GROUP BY l.question_id
      ORDER BY times DESC
      LIMIT 8
    ''');

    final reportRows = await db.rawQuery('''
      SELECT title, total, correct, elapsed_ms FROM exam_reports
      WHERE done = 1 ORDER BY created_at DESC LIMIT 5
    ''');

    return DiagnosisData(
      attempts: overall.attempts,
      correct: overall.correct,
      activeDays: activeDays,
      firstAt: firstAt,
      byCategory: await group('category'),
      bySubCategory: await group('sub_category'),
      byReason: byReason,
      recent: recent,
      earlier: earlier,
      wrongTotal: wrongTotal,
      repeatWrong: repeatWrong,
      topWrong: [
        for (final r in topRows)
          (
            category: '${r['cat'] ?? ''}',
            subCategory: '${r['sub'] ?? ''}',
            times: int.tryParse('${r['times']}') ?? 1,
            preview: '${r['content'] ?? ''}'.replaceAll('\n', ' ').trim(),
          ),
      ],
      reports: [
        for (final r in reportRows)
          (
            title: '${r['title'] ?? ''}',
            total: int.tryParse('${r['total']}') ?? 0,
            correct: int.tryParse('${r['correct']}') ?? 0,
            minutes:
                ((int.tryParse('${r['elapsed_ms']}') ?? 0) / 60000).round(),
          ),
      ],
    );
  }

  /// 一份成卷记录里，每道题分别花了多少秒、对没对。
  ///
  /// exam_reports 只存了总用时，逐题的时间在 practice_logs 里 —— 按这份记录
  /// 的时间窗口去捞，避免把同一道题以前练的那次也算进来。
  Future<Map<String, ({bool correct, int seconds})>> reportTimings(
    ExamReport report,
  ) async {
    if (report.questionIds.isEmpty) return const {};
    final db = await database;
    final end = report.createdAt.add(const Duration(minutes: 2));
    final start = report.createdAt.subtract(
      report.elapsed + const Duration(hours: 1),
    );
    final marks = List.filled(report.questionIds.length, '?').join(',');
    final rows = await db.rawQuery('''
      SELECT question_id, is_correct, elapsed_ms
      FROM practice_logs
      WHERE question_id IN ($marks) AND created_at >= ? AND created_at <= ?
      ORDER BY id
    ''', [
      ...report.questionIds,
      start.toIso8601String(),
      end.toIso8601String(),
    ]);
    final out = <String, ({bool correct, int seconds})>{};
    for (final r in rows) {
      out['${r['question_id']}'] = (
        correct: '${r['is_correct']}' == '1',
        seconds: ((int.tryParse('${r['elapsed_ms']}') ?? 0) / 1000).round(),
      );
    }
    return out;
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
              // 空标题留空串，由界面按当前语言兜底 —— 数据层没有 context。
              title: '${r['title'] ?? ''}',
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

/// 诊断用的一片统计：某个模块 / 题型做了多少、对多少、平均花多少秒。
class DiagnosisSlice {
  const DiagnosisSlice({
    required this.key,
    required this.attempts,
    required this.correct,
    required this.avgSeconds,
  });

  final String key;
  final int attempts;
  final int correct;

  /// 只统计记了用时的那些作答，没有记录时为 0。
  final int avgSeconds;

  double get accuracy => attempts == 0 ? 0 : correct / attempts;
}

/// 一次弱点诊断的全部输入。
///
/// 全部在本机算完，送给模型的只有这些聚合数字和几条错题的题干摘要 ——
/// 不是整本错题本。既省 token，也不用把做题记录整体传出去。
class DiagnosisData {
  const DiagnosisData({
    required this.attempts,
    required this.correct,
    required this.activeDays,
    required this.firstAt,
    required this.byCategory,
    required this.bySubCategory,
    required this.byReason,
    required this.recent,
    required this.earlier,
    required this.wrongTotal,
    required this.repeatWrong,
    required this.topWrong,
    required this.reports,
  });

  final int attempts;
  final int correct;

  /// 有作答记录的天数。
  final int activeDays;
  final DateTime? firstAt;

  final List<DiagnosisSlice> byCategory;
  final List<DiagnosisSlice> bySubCategory;

  /// 错因 key → 题数。key 为 '_none' 的是没标错因的。
  final Map<String, int> byReason;

  /// 近 14 天 / 更早的正确率，用来看有没有在进步。
  final DiagnosisSlice recent;
  final DiagnosisSlice earlier;

  /// 当前错题本里有多少题、其中错过两次以上的有多少。
  final int wrongTotal;
  final int repeatWrong;

  /// 错得最多的几道题：题型 + 错了几次 + 题干开头。
  final List<({String category, String subCategory, int times, String preview})>
      topWrong;

  /// 最近几次成卷记录。
  final List<({String title, int total, int correct, int minutes})> reports;

  bool get isEmpty => attempts == 0;

  double get accuracy => attempts == 0 ? 0 : correct / attempts;
}
