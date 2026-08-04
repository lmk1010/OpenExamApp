import 'package:flutter/material.dart';
import 'package:openexam_app/core/ui/stroke_icons.dart';
import 'package:openexam_app/data/db/app_database.dart';

enum BadgeTier { bronze, silver, gold, platinum }

extension BadgeTierX on BadgeTier {
  String get label => switch (this) {
        BadgeTier.bronze => '铜',
        BadgeTier.silver => '银',
        BadgeTier.gold => '金',
        BadgeTier.platinum => '铂金',
      };

  Color get color => switch (this) {
        BadgeTier.bronze => const Color(0xFFB0743C),
        BadgeTier.silver => const Color(0xFF8D9AAB),
        BadgeTier.gold => const Color(0xFFD9A21B),
        BadgeTier.platinum => const Color(0xFF4FA3C7),
      };
}

/// One badge definition plus how far the user is towards it.
class AchievementBadge {
  const AchievementBadge({
    required this.id,
    required this.name,
    required this.desc,
    required this.group,
    required this.tier,
    required this.icon,
    required this.value,
    required this.target,
    this.unlockedAt,
  });

  final String id;
  final String name;
  final String desc;
  final String group;
  final BadgeTier tier;
  final AppIcon icon;

  /// Current progress and the bar to clear.
  final int value;
  final int target;
  final DateTime? unlockedAt;

  bool get unlocked => value >= target;
  double get progress => target == 0 ? 0 : (value / target).clamp(0.0, 1.0);

  AchievementBadge withUnlockedAt(DateTime? at) => AchievementBadge(
        id: id,
        name: name,
        desc: desc,
        group: group,
        tier: tier,
        icon: icon,
        value: value,
        target: target,
        unlockedAt: at,
      );
}

/// Computes every badge from the local database. No server, no accounts —
/// the numbers are the same ones the rest of the app already shows.
class Achievements {
  const Achievements._();

  static Future<List<AchievementBadge>> evaluate() async {
    final db = AppDatabase.instance;
    final answers = await db.countAnswers();
    final stats = await db.categoryStats();
    final week = await db.dailyActivity(days: 60);
    final reports = await db.listReports(limit: 200);
    final marks = await db.countMarked();
    final notes = await db.countNotes();
    final wrong = await db.countWrong();
    final unlocked = await db.unlockedBadges();

    var streak = 0;
    for (var i = week.length - 1; i >= 0; i--) {
      if (week[i] == 0) break;
      streak++;
    }
    final activeDays = week.where((n) => n > 0).length;
    final done = stats.fold<int>(0, (a, s) => a + s.done);
    final correct = stats.fold<int>(0, (a, s) => a + s.correct);
    final rate = done == 0 ? 0 : (correct * 100 / done).round();
    final exams = reports.where((r) => r.isExam).length;
    final bestExam = reports.isEmpty
        ? 0
        : reports.map((r) => r.rate).reduce((a, b) => a > b ? a : b);
    final strongModules =
        stats.where((s) => s.done >= 20 && s.accuracy >= 0.8).length;
    final maxDay = week.isEmpty ? 0 : week.reduce((a, b) => a > b ? a : b);

    final list = <AchievementBadge>[
      AchievementBadge(
        id: 'first_blood',
        name: '开张',
        desc: '完成第一道题',
        group: '题量',
        tier: BadgeTier.bronze,
        icon: AppIcon.practice,
        value: answers,
        target: 1,
      ),
      AchievementBadge(
        id: 'answers_100',
        name: '百题',
        desc: '累计答题 100 道',
        group: '题量',
        tier: BadgeTier.bronze,
        icon: AppIcon.practice,
        value: answers,
        target: 100,
      ),
      AchievementBadge(
        id: 'answers_500',
        name: '五百题',
        desc: '累计答题 500 道',
        group: '题量',
        tier: BadgeTier.silver,
        icon: AppIcon.practice,
        value: answers,
        target: 500,
      ),
      AchievementBadge(
        id: 'answers_2000',
        name: '两千题',
        desc: '累计答题 2000 道',
        group: '题量',
        tier: BadgeTier.gold,
        icon: AppIcon.practice,
        value: answers,
        target: 2000,
      ),
      AchievementBadge(
        id: 'streak_3',
        name: '三天',
        desc: '连续练习 3 天',
        group: '坚持',
        tier: BadgeTier.bronze,
        icon: AppIcon.timer,
        value: streak,
        target: 3,
      ),
      AchievementBadge(
        id: 'streak_7',
        name: '一周不断',
        desc: '连续练习 7 天',
        group: '坚持',
        tier: BadgeTier.silver,
        icon: AppIcon.timer,
        value: streak,
        target: 7,
      ),
      AchievementBadge(
        id: 'streak_30',
        name: '一月不断',
        desc: '连续练习 30 天',
        group: '坚持',
        tier: BadgeTier.platinum,
        icon: AppIcon.timer,
        value: streak,
        target: 30,
      ),
      AchievementBadge(
        id: 'active_20',
        name: '常客',
        desc: '累计练习 20 天',
        group: '坚持',
        tier: BadgeTier.silver,
        icon: AppIcon.chart,
        value: activeDays,
        target: 20,
      ),
      AchievementBadge(
        id: 'rate_70',
        name: '及格线',
        desc: '总正确率达到 70%（至少 50 题）',
        group: '精度',
        tier: BadgeTier.silver,
        icon: AppIcon.chart,
        value: done >= 50 ? rate : 0,
        target: 70,
      ),
      AchievementBadge(
        id: 'rate_85',
        name: '稳',
        desc: '总正确率达到 85%（至少 200 题）',
        group: '精度',
        tier: BadgeTier.gold,
        icon: AppIcon.chart,
        value: done >= 200 ? rate : 0,
        target: 85,
      ),
      AchievementBadge(
        id: 'strong_3',
        name: '三科过硬',
        desc: '三个模块正确率达到 80%（每个至少 20 题）',
        group: '精度',
        tier: BadgeTier.gold,
        icon: AppIcon.logic,
        value: strongModules,
        target: 3,
      ),
      AchievementBadge(
        id: 'exam_1',
        name: '首战',
        desc: '完成第一次限时模考',
        group: '考场',
        tier: BadgeTier.bronze,
        icon: AppIcon.papers,
        value: exams,
        target: 1,
      ),
      AchievementBadge(
        id: 'exam_10',
        name: '身经十战',
        desc: '完成 10 次限时模考',
        group: '考场',
        tier: BadgeTier.gold,
        icon: AppIcon.papers,
        value: exams,
        target: 10,
      ),
      AchievementBadge(
        id: 'exam_80',
        name: '高分卷',
        desc: '任意一次模考正确率达到 80%',
        group: '考场',
        tier: BadgeTier.platinum,
        icon: AppIcon.papers,
        value: bestExam,
        target: 80,
      ),
      AchievementBadge(
        id: 'clean_wrong',
        name: '清空错题',
        desc: '把错题本清到 0（至少错过 20 题）',
        group: '攻坚',
        tier: BadgeTier.gold,
        icon: AppIcon.wrongBook,
        value: answers >= 100 && wrong == 0 ? 1 : 0,
        target: 1,
      ),
      AchievementBadge(
        id: 'day_100',
        name: '单日百题',
        desc: '一天内做满 100 题',
        group: '攻坚',
        tier: BadgeTier.silver,
        icon: AppIcon.shuffle,
        value: maxDay,
        target: 100,
      ),
      AchievementBadge(
        id: 'notes_20',
        name: '会总结',
        desc: '写下 20 条题目笔记',
        group: '攻坚',
        tier: BadgeTier.silver,
        icon: AppIcon.speech,
        value: notes,
        target: 20,
      ),
      AchievementBadge(
        id: 'marks_30',
        name: '会收集',
        desc: '收藏 30 道题',
        group: '攻坚',
        tier: BadgeTier.bronze,
        icon: AppIcon.wrongBook,
        value: marks,
        target: 30,
      ),
    ];

    return [for (final b in list) b.withUnlockedAt(unlocked[b.id])];
  }

  /// Records anything newly cleared and returns those badges, so the caller can
  /// celebrate exactly once.
  static Future<List<AchievementBadge>> claimNew() async {
    final all = await evaluate();
    final fresh = all.where((b) => b.unlocked && b.unlockedAt == null).toList();
    for (final badge in fresh) {
      await AppDatabase.instance.unlockBadge(badge.id);
    }
    return fresh;
  }
}
