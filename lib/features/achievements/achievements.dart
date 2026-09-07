import 'package:flutter/material.dart';
import 'package:openexam_app/core/ui/stroke_icons.dart';
import 'package:openexam_app/data/db/app_database.dart';
import 'package:openexam_app/l10n/app_localizations.dart';

enum BadgeTier { bronze, silver, gold, platinum }

extension BadgeTierX on BadgeTier {
  String label(AppL l) => switch (this) {
        BadgeTier.bronze => l.tierBronze,
        BadgeTier.silver => l.tierSilver,
        BadgeTier.gold => l.tierGold,
        BadgeTier.platinum => l.tierPlatinum,
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
    required this.groupKey,
    required this.tier,
    required this.icon,
    required this.value,
    required this.target,
    this.unlockedAt,
  });

  final String id;
  final String name;
  final String desc;
  /// 给人看的分组名，跟着界面语言走。
  final String group;

  /// 分组的稳定标识。**不要拿 [group] 去查表** —— 它已经本地化了，
  /// 英文界面下拿它当 key 一个也匹配不上（徽章图就全退成默认那张）。
  final String groupKey;
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
        groupKey: groupKey,
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

  /// [l] 由调用方传进来 —— 这是纯数据层，没有 BuildContext。
  static Future<List<AchievementBadge>> evaluate(AppL l) async {
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
        name: l.badgeFirstBloodName,
        desc: l.badgeFirstBloodDesc,
        group: l.badgeGroupVolume,
        groupKey: 'volume',
        tier: BadgeTier.bronze,
        icon: AppIcon.practice,
        value: answers,
        target: 1,
      ),
      AchievementBadge(
        id: 'answers_100',
        name: l.badgeAnswers100Name,
        desc: l.badgeAnswers100Desc,
        group: l.badgeGroupVolume,
        groupKey: 'volume',
        tier: BadgeTier.bronze,
        icon: AppIcon.practice,
        value: answers,
        target: 100,
      ),
      AchievementBadge(
        id: 'answers_500',
        name: l.badgeAnswers500Name,
        desc: l.badgeAnswers500Desc,
        group: l.badgeGroupVolume,
        groupKey: 'volume',
        tier: BadgeTier.silver,
        icon: AppIcon.practice,
        value: answers,
        target: 500,
      ),
      AchievementBadge(
        id: 'answers_2000',
        name: l.badgeAnswers2000Name,
        desc: l.badgeAnswers2000Desc,
        group: l.badgeGroupVolume,
        groupKey: 'volume',
        tier: BadgeTier.gold,
        icon: AppIcon.practice,
        value: answers,
        target: 2000,
      ),
      AchievementBadge(
        id: 'streak_3',
        name: l.badgeStreak3Name,
        desc: l.badgeStreak3Desc,
        group: l.badgeGroupConsistency,
        groupKey: 'consistency',
        tier: BadgeTier.bronze,
        icon: AppIcon.timer,
        value: streak,
        target: 3,
      ),
      AchievementBadge(
        id: 'streak_7',
        name: l.badgeStreak7Name,
        desc: l.badgeStreak7Desc,
        group: l.badgeGroupConsistency,
        groupKey: 'consistency',
        tier: BadgeTier.silver,
        icon: AppIcon.timer,
        value: streak,
        target: 7,
      ),
      AchievementBadge(
        id: 'streak_30',
        name: l.badgeStreak30Name,
        desc: l.badgeStreak30Desc,
        group: l.badgeGroupConsistency,
        groupKey: 'consistency',
        tier: BadgeTier.platinum,
        icon: AppIcon.timer,
        value: streak,
        target: 30,
      ),
      AchievementBadge(
        id: 'active_20',
        name: l.badgeActive20Name,
        desc: l.badgeActive20Desc,
        group: l.badgeGroupConsistency,
        groupKey: 'consistency',
        tier: BadgeTier.silver,
        icon: AppIcon.chart,
        value: activeDays,
        target: 20,
      ),
      AchievementBadge(
        id: 'rate_70',
        name: l.badgeRate70Name,
        desc: l.badgeRate70Desc,
        group: l.badgeGroupAccuracy,
        groupKey: 'accuracy',
        tier: BadgeTier.silver,
        icon: AppIcon.chart,
        value: done >= 50 ? rate : 0,
        target: 70,
      ),
      AchievementBadge(
        id: 'rate_85',
        name: l.badgeRate85Name,
        desc: l.badgeRate85Desc,
        group: l.badgeGroupAccuracy,
        groupKey: 'accuracy',
        tier: BadgeTier.gold,
        icon: AppIcon.chart,
        value: done >= 200 ? rate : 0,
        target: 85,
      ),
      AchievementBadge(
        id: 'strong_3',
        name: l.badgeStrong3Name,
        desc: l.badgeStrong3Desc,
        group: l.badgeGroupAccuracy,
        groupKey: 'accuracy',
        tier: BadgeTier.gold,
        icon: AppIcon.logic,
        value: strongModules,
        target: 3,
      ),
      AchievementBadge(
        id: 'exam_1',
        name: l.badgeExam1Name,
        desc: l.badgeExam1Desc,
        group: l.badgeGroupExams,
        groupKey: 'exams',
        tier: BadgeTier.bronze,
        icon: AppIcon.papers,
        value: exams,
        target: 1,
      ),
      AchievementBadge(
        id: 'exam_10',
        name: l.badgeExam10Name,
        desc: l.badgeExam10Desc,
        group: l.badgeGroupExams,
        groupKey: 'exams',
        tier: BadgeTier.gold,
        icon: AppIcon.papers,
        value: exams,
        target: 10,
      ),
      AchievementBadge(
        id: 'exam_80',
        name: l.badgeExam80Name,
        desc: l.badgeExam80Desc,
        group: l.badgeGroupExams,
        groupKey: 'exams',
        tier: BadgeTier.platinum,
        icon: AppIcon.papers,
        value: bestExam,
        target: 80,
      ),
      AchievementBadge(
        id: 'clean_wrong',
        name: l.badgeCleanWrongName,
        desc: l.badgeCleanWrongDesc,
        group: l.badgeGroupGrind,
        groupKey: 'grind',
        tier: BadgeTier.gold,
        icon: AppIcon.wrongBook,
        value: answers >= 100 && wrong == 0 ? 1 : 0,
        target: 1,
      ),
      AchievementBadge(
        id: 'day_100',
        name: l.badgeDay100Name,
        desc: l.badgeDay100Desc,
        group: l.badgeGroupGrind,
        groupKey: 'grind',
        tier: BadgeTier.silver,
        icon: AppIcon.shuffle,
        value: maxDay,
        target: 100,
      ),
      AchievementBadge(
        id: 'notes_20',
        name: l.badgeNotes20Name,
        desc: l.badgeNotes20Desc,
        group: l.badgeGroupGrind,
        groupKey: 'grind',
        tier: BadgeTier.silver,
        icon: AppIcon.speech,
        value: notes,
        target: 20,
      ),
      AchievementBadge(
        id: 'marks_30',
        name: l.badgeMarks30Name,
        desc: l.badgeMarks30Desc,
        group: l.badgeGroupGrind,
        groupKey: 'grind',
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
  static Future<List<AchievementBadge>> claimNew(AppL l) async {
    final all = await evaluate(l);
    final fresh = all.where((b) => b.unlocked && b.unlockedAt == null).toList();
    for (final badge in fresh) {
      await AppDatabase.instance.unlockBadge(badge.id);
    }
    return fresh;
  }
}
