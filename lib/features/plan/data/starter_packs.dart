import 'package:openexam_app/features/plan/domain/models/plan_set.dart';
import 'package:openexam_app/features/plan/domain/models/study_task.dart';

/// 一份可以导入的起始清单。
///
/// 这些**不是**运行时结构，只是开局省事用的一把种子：导入之后每条都变成用户
/// 自己 [PlanSet] 里的普通任务，能改能删能换重复规则。以前它们是只读周模板，
/// 用户改一条只能改今天那一份拷贝，第二天又变回来 —— 这是最招人烦的地方。
class StarterPack {
  const StarterPack({
    required this.id,
    required this.name,
    required this.blurb,
    required this.tasksByWeekday,
  });

  final String id;
  final String name;
  final String blurb;

  /// 星期几 1–7 → 那天的任务。只在导入时用来推算重复规则。
  final Map<int, List<StudyTask>> tasksByWeekday;

  int get taskCount => expand(DateTime(2026)).length;

  /// 摊平成带重复规则的清单。
  ///
  /// 同一条任务（同 id）横跨哪几天，决定它变成什么规则：整周都在就是每天，
  /// 周一到周五都在就是工作日，否则按"每周这天"一天一条。[from] 用来算
  /// "每周这天"从哪个日期起跳。
  List<StudyTask> expand(DateTime from) {
    final weekdaysOf = <String, List<int>>{};
    final byId = <String, StudyTask>{};
    for (final entry in tasksByWeekday.entries) {
      for (final task in entry.value) {
        weekdaysOf.putIfAbsent(task.id, () => []).add(entry.key);
        byId.putIfAbsent(task.id, () => task);
      }
    }

    final out = <StudyTask>[];
    for (final e in weekdaysOf.entries) {
      final days = [...e.value]..sort();
      final task = byId[e.key]!;
      if (days.length == 7) {
        out.add(task.copyWith(repeat: RepeatRule.daily, startedOn: _day(from)));
        continue;
      }
      if (days.length == 5 && days.every((d) => d <= 5)) {
        out.add(task.copyWith(repeat: RepeatRule.weekdays, startedOn: _day(from)));
        continue;
      }
      // 一条任务落在零散的几天：一天生成一条，第一条留着原 id，
      // 这样老用户已经打过的勾（按 id 存）不会全部作废。
      for (var i = 0; i < days.length; i++) {
        out.add(task.copyWith(
          id: i == 0 ? task.id : '${task.id}_w${days[i]}',
          repeat: RepeatRule.weekly,
          startedOn: _onWeekday(from, days[i]),
        ));
      }
    }
    return out;
  }

  /// 导入成一份可编辑的清单。
  PlanSet toPlanSet({required String id, String? name, DateTime? from}) =>
      PlanSet(
        id: id,
        name: name ?? this.name,
        tasks: expand(from ?? DateTime.now()),
      );

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  /// [from] 当天或之后第一个星期 [weekday]。
  static DateTime _onWeekday(DateTime from, int weekday) {
    final base = _day(from);
    return base.add(Duration(days: (weekday - base.weekday + 7) % 7));
  }
}

class StarterPacks {
  /// 开局默认：只有最没争议的三条，不写时间点、不假设你一天几小时。
  ///
  /// 以前默认给的是「在职晚间」那套 —— 6:00 起床背词、23:55 收工，
  /// 对绝大多数人既做不到也不该照抄。
  static const _minimalTasks = <StudyTask>[
    StudyTask(
      id: 's_daily',
      title: '每日一练',
      action: StudyAction.daily,
    ),
    StudyTask(
      id: 's_ziliao',
      title: '资料分析 · 限时',
      action: StudyAction.practice,
      category: 'ziliao',
      count: 20,
      timed: true,
      minutes: 25,
    ),
    StudyTask(
      id: 's_wrong',
      title: '错题回炉',
      action: StudyAction.wrong,
      count: 10,
    ),
  ];

  static final minimal = StarterPack(
    id: 'minimal',
    name: '极简三条',
    blurb: '每天三条，做完就算没白过',
    tasksByWeekday: {for (var d = 1; d <= 7; d++) d: _minimalTasks},
  );

  static const working = StarterPack(
    id: 'working',
    name: '在职晚间',
    blurb: '量偏大，工作日晚上四小时那种',
    tasksByWeekday: {
      1: [
        StudyTask(
          id: 'm_wrong10',
          title: '错题回炉',
          subtitle: '可选',
          action: StudyAction.wrong,
          count: 10,
        ),
        StudyTask(
          id: 'e_ziliao20',
          title: '资料分析 · 限时',
          action: StudyAction.practice,
          category: 'ziliao',
          count: 20,
          timed: true,
          minutes: 25,
        ),
        StudyTask(
          id: 'e_yanyu',
          title: '言语专项',
          subtitle: '一次只盯一种错因',
          action: StudyAction.practice,
          category: 'yanyu',
          count: 30,
        ),
        StudyTask(
          id: 'e_shuliang',
          title: '数量关系',
          subtitle: '90 秒无思路就跳',
          action: StudyAction.practice,
          category: 'shuliang',
          count: 8,
          minutes: 30,
        ),
        StudyTask(
          id: 'e_shenlun',
          title: '申论 · 概括分析',
          subtitle: '对照答案算撞词',
          action: StudyAction.note,
        ),
      ],
      2: [
        StudyTask(
          id: 'm_calc',
          title: '资料速算口算',
          subtitle: '可选 · 只算不找数',
          action: StudyAction.note,
        ),
        StudyTask(
          id: 'e_ziliao20',
          title: '资料分析 · 限时',
          action: StudyAction.practice,
          category: 'ziliao',
          count: 20,
          timed: true,
          minutes: 25,
        ),
        StudyTask(
          id: 'e_panduan',
          title: '判断专项',
          subtitle: '一次只盯一个点',
          action: StudyAction.practice,
          category: 'panduan',
          count: 30,
        ),
        StudyTask(
          id: 'e_shuliang',
          title: '数量关系',
          subtitle: '练取舍',
          action: StudyAction.practice,
          category: 'shuliang',
          count: 8,
          minutes: 30,
        ),
        StudyTask(
          id: 'e_shenlun_edit',
          title: '申论 · 改答案',
          action: StudyAction.note,
        ),
      ],
      3: [
        StudyTask(
          id: 'm_wrong10',
          title: '错题回炉',
          subtitle: '可选',
          action: StudyAction.wrong,
          count: 10,
        ),
        StudyTask(
          id: 'e_ziliao20',
          title: '资料分析 · 限时',
          action: StudyAction.practice,
          category: 'ziliao',
          count: 20,
          timed: true,
          minutes: 25,
        ),
        StudyTask(
          id: 'e_yanyu',
          title: '言语专项',
          action: StudyAction.practice,
          category: 'yanyu',
          count: 30,
        ),
        StudyTask(
          id: 'e_shuliang',
          title: '数量关系',
          action: StudyAction.practice,
          category: 'shuliang',
          count: 8,
          minutes: 30,
        ),
        StudyTask(
          id: 'e_shenlun',
          title: '申论 · 概括分析',
          action: StudyAction.note,
        ),
      ],
      4: [
        StudyTask(
          id: 'm_shenlun_words',
          title: '申论规范词默写',
          subtitle: '可选',
          action: StudyAction.note,
        ),
        StudyTask(
          id: 'e_ziliao20',
          title: '资料分析 · 限时',
          action: StudyAction.practice,
          category: 'ziliao',
          count: 20,
          timed: true,
          minutes: 25,
        ),
        StudyTask(
          id: 'e_panduan',
          title: '判断专项',
          action: StudyAction.practice,
          category: 'panduan',
          count: 30,
        ),
        StudyTask(
          id: 'e_shuliang',
          title: '数量关系',
          action: StudyAction.practice,
          category: 'shuliang',
          count: 8,
          minutes: 30,
        ),
        StudyTask(
          id: 'e_shenlun_edit',
          title: '申论 · 改答案',
          action: StudyAction.note,
        ),
      ],
      5: [
        StudyTask(
          id: 'm_wrong10',
          title: '错题回炉',
          subtitle: '可选',
          action: StudyAction.wrong,
          count: 10,
        ),
        StudyTask(
          id: 'e_ziliao20',
          title: '资料分析 · 限时',
          action: StudyAction.practice,
          category: 'ziliao',
          count: 20,
          timed: true,
          minutes: 25,
        ),
        StudyTask(
          id: 'e_yanyu',
          title: '言语专项',
          action: StudyAction.practice,
          category: 'yanyu',
          count: 30,
        ),
        StudyTask(
          id: 'e_shuliang',
          title: '数量关系',
          action: StudyAction.practice,
          category: 'shuliang',
          count: 8,
          minutes: 30,
        ),
        StudyTask(
          id: 'e_shenlun',
          title: '申论 · 概括分析',
          action: StudyAction.note,
        ),
      ],
      6: [
        StudyTask(
          id: 'sat_mock',
          title: '全真模考 1 套',
          subtitle: '上午 · 含涂卡',
          action: StudyAction.mock,
          minutes: 120,
        ),
        StudyTask(
          id: 'sat_review',
          title: '统计与错题标签',
          subtitle: '上午复盘',
          action: StudyAction.openWrongBook,
        ),
        StudyTask(
          id: 'sat_drill',
          title: '慢题错题补练',
          subtitle: '下午',
          action: StudyAction.adaptive,
          count: 30,
        ),
        StudyTask(
          id: 'sat_note',
          title: '定下周的错因',
          subtitle: '晚上轻松收尾',
          action: StudyAction.note,
        ),
      ],
      7: [
        StudyTask(
          id: 'sun_shenlun',
          title: '申论全套限时',
          subtitle: '上午',
          action: StudyAction.note,
        ),
        StudyTask(
          id: 'sun_shenlun_review',
          title: '撞词复盘 · 改立意',
          subtitle: '下午',
          action: StudyAction.note,
        ),
        StudyTask(
          id: 'sun_weak',
          title: '补本周最弱一块',
          subtitle: '下午 · 资料 / 言语 / 判断',
          action: StudyAction.adaptive,
          count: 30,
        ),
        StudyTask(
          id: 'sun_wrong',
          title: '错题本清一轮',
          action: StudyAction.wrong,
          count: 20,
        ),
      ],
    },
  );

  static const light = StarterPack(
    id: 'light',
    name: '轻量保底',
    blurb: '每天两件事，忙也守得住',
    tasksByWeekday: {
      1: [
        StudyTask(
          id: 'l_ziliao',
          title: '资料分析 · 限时',
          action: StudyAction.practice,
          category: 'ziliao',
          count: 20,
          timed: true,
          minutes: 25,
        ),
        StudyTask(
          id: 'l_daily',
          title: '每日一练',
          action: StudyAction.daily,
        ),
      ],
      2: [
        StudyTask(
          id: 'l_ziliao',
          title: '资料分析 · 限时',
          action: StudyAction.practice,
          category: 'ziliao',
          count: 20,
          timed: true,
          minutes: 25,
        ),
        StudyTask(
          id: 'l_wrong',
          title: '错题重练',
          action: StudyAction.wrong,
          count: 20,
        ),
      ],
      3: [
        StudyTask(
          id: 'l_ziliao',
          title: '资料分析 · 限时',
          action: StudyAction.practice,
          category: 'ziliao',
          count: 20,
          timed: true,
          minutes: 25,
        ),
        StudyTask(
          id: 'l_daily',
          title: '每日一练',
          action: StudyAction.daily,
        ),
      ],
      4: [
        StudyTask(
          id: 'l_ziliao',
          title: '资料分析 · 限时',
          action: StudyAction.practice,
          category: 'ziliao',
          count: 20,
          timed: true,
          minutes: 25,
        ),
        StudyTask(
          id: 'l_wrong',
          title: '错题重练',
          action: StudyAction.wrong,
          count: 20,
        ),
      ],
      5: [
        StudyTask(
          id: 'l_ziliao',
          title: '资料分析 · 限时',
          action: StudyAction.practice,
          category: 'ziliao',
          count: 20,
          timed: true,
          minutes: 25,
        ),
        StudyTask(
          id: 'l_daily',
          title: '每日一练',
          action: StudyAction.daily,
        ),
      ],
      6: [
        StudyTask(
          id: 'l_mock',
          title: '限时模考',
          action: StudyAction.mock,
        ),
        StudyTask(
          id: 'l_wrong',
          title: '错题复盘',
          action: StudyAction.openWrongBook,
        ),
      ],
      7: [
        StudyTask(
          id: 'l_rest',
          title: '休息 · 或补最弱一块',
          action: StudyAction.adaptive,
          count: 20,
        ),
      ],
    },
  );

  static final all = <StarterPack>[minimal, light, working];

  static StarterPack? byId(String? id) {
    for (final p in all) {
      if (p.id == id) return p;
    }
    return null;
  }
}
