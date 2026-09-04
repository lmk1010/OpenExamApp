import 'package:openexam_app/features/plan/domain/models/study_task.dart';

/// Built-in week templates. Tasks are keyed by weekday so the same rhythm
/// repeats every week until the user switches template or adds custom items.
class PlanTemplate {
  const PlanTemplate({
    required this.id,
    required this.title,
    required this.blurb,
    required this.focusByWeekday,
    required this.tasksByWeekday,
  });

  final String id;
  final String title;
  final String blurb;

  /// Weekday 1–7 → one-line focus for that day.
  final Map<int, String> focusByWeekday;

  /// Weekday 1–7 → ordered checklist.
  final Map<int, List<StudyTask>> tasksByWeekday;
}

class PlanTemplates {
  static const workingId = 'working';
  static const lightId = 'light';
  static const offId = 'off';

  static const working = PlanTemplate(
    id: workingId,
    title: '在职晚间',
    blurb: '工作日 4 小时：资料天天练 + 言判轮换 + 数量取舍；周末套卷验节奏',
    focusByWeekday: {
      1: '资料提速 · 言语固化 · 申论撞词',
      2: '资料提速 · 判断固化 · 申论改词',
      3: '资料提速 · 言语固化 · 申论撞词',
      4: '资料提速 · 判断固化 · 申论改词',
      5: '资料提速 · 言语固化 · 申论撞词',
      6: '全真套卷日 · 深度复盘',
      7: '申论整套 · 补本周最弱',
    },
    tasksByWeekday: {
      1: [
        StudyTask(
          id: 'm_wrong10',
          title: '错题回炉',
          subtitle: '6:00–7:30 · 可选',
          action: StudyAction.wrong,
          count: 10,
        ),
        StudyTask(
          id: 'e_ziliao20',
          title: '资料分析 · 限时',
          subtitle: '20:10–21:20',
          action: StudyAction.practice,
          category: 'ziliao',
          count: 20,
          timed: true,
          minutes: 25,
        ),
        StudyTask(
          id: 'e_yanyu',
          title: '言语专项',
          subtitle: '21:30–22:40 · 一次只盯一种错因',
          action: StudyAction.practice,
          category: 'yanyu',
          count: 30,
        ),
        StudyTask(
          id: 'e_shuliang',
          title: '数量关系',
          subtitle: '22:40–23:10 · 90 秒无思路就跳',
          action: StudyAction.practice,
          category: 'shuliang',
          count: 8,
          minutes: 30,
        ),
        StudyTask(
          id: 'e_shenlun',
          title: '申论 · 概括分析',
          subtitle: '23:10–23:55 · 对照答案算撞词',
          action: StudyAction.note,
        ),
      ],
      2: [
        StudyTask(
          id: 'm_calc',
          title: '资料速算口算',
          subtitle: '6:00–7:30 · 可选 · 只算不找数',
          action: StudyAction.note,
        ),
        StudyTask(
          id: 'e_ziliao20',
          title: '资料分析 · 限时',
          subtitle: '20:10–21:20',
          action: StudyAction.practice,
          category: 'ziliao',
          count: 20,
          timed: true,
          minutes: 25,
        ),
        StudyTask(
          id: 'e_panduan',
          title: '判断专项',
          subtitle: '21:30–22:40 · 一次只盯一个点',
          action: StudyAction.practice,
          category: 'panduan',
          count: 30,
        ),
        StudyTask(
          id: 'e_shuliang',
          title: '数量关系',
          subtitle: '22:40–23:10 · 练取舍',
          action: StudyAction.practice,
          category: 'shuliang',
          count: 8,
          minutes: 30,
        ),
        StudyTask(
          id: 'e_shenlun_edit',
          title: '申论 · 改答案',
          subtitle: '23:10–23:55',
          action: StudyAction.note,
        ),
      ],
      3: [
        StudyTask(
          id: 'm_wrong10',
          title: '错题回炉',
          subtitle: '6:00–7:30 · 可选',
          action: StudyAction.wrong,
          count: 10,
        ),
        StudyTask(
          id: 'e_ziliao20',
          title: '资料分析 · 限时',
          subtitle: '20:10–21:20',
          action: StudyAction.practice,
          category: 'ziliao',
          count: 20,
          timed: true,
          minutes: 25,
        ),
        StudyTask(
          id: 'e_yanyu',
          title: '言语专项',
          subtitle: '21:30–22:40',
          action: StudyAction.practice,
          category: 'yanyu',
          count: 30,
        ),
        StudyTask(
          id: 'e_shuliang',
          title: '数量关系',
          subtitle: '22:40–23:10',
          action: StudyAction.practice,
          category: 'shuliang',
          count: 8,
          minutes: 30,
        ),
        StudyTask(
          id: 'e_shenlun',
          title: '申论 · 概括分析',
          subtitle: '23:10–23:55',
          action: StudyAction.note,
        ),
      ],
      4: [
        StudyTask(
          id: 'm_shenlun_words',
          title: '申论规范词默写',
          subtitle: '6:00–7:30 · 可选',
          action: StudyAction.note,
        ),
        StudyTask(
          id: 'e_ziliao20',
          title: '资料分析 · 限时',
          subtitle: '20:10–21:20',
          action: StudyAction.practice,
          category: 'ziliao',
          count: 20,
          timed: true,
          minutes: 25,
        ),
        StudyTask(
          id: 'e_panduan',
          title: '判断专项',
          subtitle: '21:30–22:40',
          action: StudyAction.practice,
          category: 'panduan',
          count: 30,
        ),
        StudyTask(
          id: 'e_shuliang',
          title: '数量关系',
          subtitle: '22:40–23:10',
          action: StudyAction.practice,
          category: 'shuliang',
          count: 8,
          minutes: 30,
        ),
        StudyTask(
          id: 'e_shenlun_edit',
          title: '申论 · 改答案',
          subtitle: '23:10–23:55',
          action: StudyAction.note,
        ),
      ],
      5: [
        StudyTask(
          id: 'm_wrong10',
          title: '错题回炉',
          subtitle: '6:00–7:30 · 可选',
          action: StudyAction.wrong,
          count: 10,
        ),
        StudyTask(
          id: 'e_ziliao20',
          title: '资料分析 · 限时',
          subtitle: '20:10–21:20',
          action: StudyAction.practice,
          category: 'ziliao',
          count: 20,
          timed: true,
          minutes: 25,
        ),
        StudyTask(
          id: 'e_yanyu',
          title: '言语专项',
          subtitle: '21:30–22:40',
          action: StudyAction.practice,
          category: 'yanyu',
          count: 30,
        ),
        StudyTask(
          id: 'e_shuliang',
          title: '数量关系',
          subtitle: '22:40–23:10',
          action: StudyAction.practice,
          category: 'shuliang',
          count: 8,
          minutes: 30,
        ),
        StudyTask(
          id: 'e_shenlun',
          title: '申论 · 概括分析',
          subtitle: '23:10–23:55',
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

  static const light = PlanTemplate(
    id: lightId,
    title: '轻量保底',
    blurb: '忙的时候只守底线：资料 + 每日一练 + 错题，周末再拉一套',
    focusByWeekday: {
      1: '底线日：资料 + 每日一练',
      2: '底线日：资料 + 错题',
      3: '底线日：资料 + 每日一练',
      4: '底线日：资料 + 错题',
      5: '底线日：资料 + 每日一练',
      6: '轻量套卷日',
      7: '休息或补洞',
    },
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

  static List<PlanTemplate> get all => const [working, light];

  static PlanTemplate? byId(String? id) {
    if (id == null || id == offId) return null;
    for (final t in all) {
      if (t.id == id) return t;
    }
    return null;
  }
}
