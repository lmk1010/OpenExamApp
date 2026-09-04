import 'dart:convert';
import 'dart:math';

import 'package:openexam_app/data/db/app_database.dart';
import 'package:sqflite/sqflite.dart';
import 'package:openexam_app/features/essay/domain/essay_models.dart';

/// 申论题与作答记录的本地读写。
class EssayRepository {
  const EssayRepository._();
  static const instance = EssayRepository._();

  static String newId() {
    final rand = Random().nextInt(1 << 32).toRadixString(36);
    return '${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}$rand';
  }

  Future<List<EssayPrompt>> listPrompts({EssayType? type}) async {
    final db = await AppDatabase.instance.database;
    // 顺带把练习次数和最好成绩查出来，列表页要显示
    final rows = await db.rawQuery('''
      SELECT p.*,
             (SELECT COUNT(*) FROM essay_attempts a
               WHERE a.prompt_id = p.id AND a.score IS NOT NULL) AS attempts,
             (SELECT MAX(a.score) FROM essay_attempts a
               WHERE a.prompt_id = p.id) AS best
      FROM essay_prompts p
      ${type == null ? '' : 'WHERE p.essay_type = ?'}
      ORDER BY p.created_at DESC
    ''', type == null ? null : [type.name]);

    return rows
        .map((row) => EssayPrompt.fromRow(
              row,
              attempts: (row['attempts'] as int?) ?? 0,
              best: (row['best'] as num?)?.toDouble(),
            ))
        .toList();
  }

  Future<EssayPrompt?> getPrompt(String id) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('essay_prompts', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return EssayPrompt.fromRow(rows.first);
  }

  Future<void> savePrompt(EssayPrompt prompt) async {
    final db = await AppDatabase.instance.database;
    await db.insert(
      'essay_prompts',
      prompt.toRow(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deletePrompt(String id) async {
    final db = await AppDatabase.instance.database;
    await db.delete('essay_attempts', where: 'prompt_id = ?', whereArgs: [id]);
    await db.delete('essay_prompts', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> saveAttempt(EssayAttempt attempt) async {
    final db = await AppDatabase.instance.database;
    await db.insert(
      'essay_attempts',
      attempt.toRow(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<EssayAttempt>> listAttempts({String? promptId, int limit = 50}) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'essay_attempts',
      where: promptId == null ? null : 'prompt_id = ?',
      whereArgs: promptId == null ? null : [promptId],
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return rows.map(EssayAttempt.fromRow).toList();
  }

  Future<void> deleteAttempt(String id) async {
    final db = await AppDatabase.instance.database;
    await db.delete('essay_attempts', where: 'id = ?', whereArgs: [id]);
  }

  /// 今天练哪道：优先没批改过的，其次挑分最低的那道重练。
  Future<EssayPrompt?> recommend({EssayType type = EssayType.guina}) async {
    final db = await AppDatabase.instance.database;
    final fresh = await db.rawQuery('''
      SELECT p.* FROM essay_prompts p
      WHERE p.essay_type = ?
        AND NOT EXISTS (
          SELECT 1 FROM essay_attempts a
          WHERE a.prompt_id = p.id AND a.score IS NOT NULL
        )
      ORDER BY RANDOM() LIMIT 1
    ''', [type.name]);
    if (fresh.isNotEmpty) return EssayPrompt.fromRow(fresh.first);

    final weakest = await db.rawQuery('''
      SELECT p.*, MIN(a.score) AS s FROM essay_prompts p
      JOIN essay_attempts a ON a.prompt_id = p.id AND a.score IS NOT NULL
      WHERE p.essay_type = ?
      GROUP BY p.id ORDER BY s ASC LIMIT 1
    ''', [type.name]);
    if (weakest.isNotEmpty) return EssayPrompt.fromRow(weakest.first);
    return null;
  }

  Future<int> countPrompts() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery('SELECT COUNT(*) AS c FROM essay_prompts');
    return (rows.first['c'] as int?) ?? 0;
  }

  /// 导出/备份用。
  Future<String> exportJson() async {
    final prompts = await listPrompts();
    final attempts = await listAttempts(limit: 10000);
    return jsonEncode({
      'prompts': prompts.map((p) => p.toRow()).toList(),
      'attempts': attempts.map((a) => a.toRow()).toList(),
    });
  }
}
