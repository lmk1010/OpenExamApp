import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:openexam_app/features/plan/data/starter_packs.dart';
import 'package:openexam_app/features/plan/data/study_plan_store.dart';
import 'package:openexam_app/features/plan/domain/models/study_task.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 计划这块最招人烦的老毛病：改了今天，第二天打开原封不动。
/// 这些用例守的就是"改一次、往后都算数"。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final mon = DateTime(2026, 9, 7); // 周一
  final tue = DateTime(2026, 9, 8);
  final sat = DateTime(2026, 9, 12);
  final nextMon = DateTime(2026, 9, 14);

  Future<StudyPlanStore> freshStore([Map<String, Object> seed = const {}]) async {
    SharedPreferences.setMockInitialValues(Map<String, Object>.from(seed));
    return StudyPlanStore.create();
  }

  StudyTask? find(StudyPlanStore s, DateTime d, String id) {
    for (final t in s.planFor(d).tasks) {
      if (t.id == id) return t;
    }
    return null;
  }

  group('开局', () {
    test('新用户拿到极简三条，不是那套 6:00 起床的作息表', () async {
      final store = await freshStore();
      final plan = store.planFor(mon);
      expect(plan.tasks.map((t) => t.id),
          containsAll(['s_daily', 's_ziliao', 's_wrong']));
      expect(plan.tasks.length, 3);
      // 起始包里不该再有钉死的时间段
      for (final t in plan.tasks) {
        expect(t.subtitle ?? '', isNot(matches(RegExp(r'\d{1,2}:\d{2}'))));
      }
    });

    test('默认三条每天都在', () async {
      final store = await freshStore();
      for (final d in [mon, tue, sat, nextMon]) {
        expect(store.planFor(d).tasks.length, 3, reason: '$d');
      }
    });
  });

  group('改一条任务', () {
    test('改标题，往后每天都变（老版本只变今天）', () async {
      final store = await freshStore();
      final task = find(store, mon, 's_ziliao')!;
      await store.upsertTask(mon, task.copyWith(title: '资料分析 · 我自己的量', count: 15));

      for (final d in [mon, tue, nextMon]) {
        final t = find(store, d, 's_ziliao');
        expect(t?.title, '资料分析 · 我自己的量', reason: '$d');
        expect(t?.count, 15, reason: '$d');
      }
    });

    test('只改今天时，明天还是原样', () async {
      final store = await freshStore();
      final task = find(store, mon, 's_ziliao')!;
      await store.upsertTask(
        mon,
        task.copyWith(count: 5),
        scope: PlanEditScope.today,
      );

      expect(find(store, mon, 's_ziliao')?.count, 5);
      expect(find(store, tue, 's_ziliao')?.count, 20);
    });

    test('改重复规则：每天 → 工作日，周末就不出现了', () async {
      final store = await freshStore();
      final task = find(store, mon, 's_wrong')!;
      await store.upsertTask(
        mon,
        task.copyWith(repeat: RepeatRule.weekdays, startedOn: mon),
      );

      expect(find(store, tue, 's_wrong'), isNotNull);
      expect(find(store, sat, 's_wrong'), isNull);
    });

    test('每天 → 只这一次：只剩那一天，别的天清干净', () async {
      final store = await freshStore();
      final task = find(store, mon, 's_daily')!;
      await store.upsertTask(mon, task.copyWith(repeat: RepeatRule.once));

      expect(find(store, mon, 's_daily'), isNotNull);
      expect(find(store, tue, 's_daily'), isNull);
      // 清单里也不能再留一份，否则同一天会冒出来两条
      expect(store.activeSet!.tasks.where((t) => t.id == 's_daily'), isEmpty);
    });

    test('一次性 → 每天：不会在那天变成两条', () async {
      final store = await freshStore();
      const extra = StudyTask(
        id: 'x1',
        title: '背 20 个成语',
        action: StudyAction.check,
        repeat: RepeatRule.once,
      );
      await store.upsertTask(mon, extra);
      expect(store.planFor(mon).tasks.where((t) => t.id == 'x1').length, 1);

      await store.upsertTask(mon, extra.copyWith(repeat: RepeatRule.daily));
      expect(store.planFor(mon).tasks.where((t) => t.id == 'x1').length, 1);
      expect(find(store, tue, 'x1'), isNotNull);
    });
  });

  group('删一条任务', () {
    test('默认永久删：明天、下周都不再出现', () async {
      final store = await freshStore();
      await store.deleteTask(mon, find(store, mon, 's_wrong')!);

      for (final d in [mon, tue, nextMon]) {
        expect(find(store, d, 's_wrong'), isNull, reason: '$d');
      }
    });

    test('只跳过今天：明天照样在', () async {
      final store = await freshStore();
      await store.deleteTask(
        mon,
        find(store, mon, 's_wrong')!,
        scope: PlanEditScope.today,
      );

      expect(find(store, mon, 's_wrong'), isNull);
      expect(find(store, tue, 's_wrong'), isNotNull);
    });

    test('清空当前清单', () async {
      final store = await freshStore();
      await store.clearActiveTasks();
      expect(store.planFor(mon).tasks, isEmpty);
      expect(store.isEnabled, isTrue); // 清单还在，只是空的
    });
  });

  group('多份清单', () {
    test('新建一份切过去，原来那份原封不动', () async {
      final store = await freshStore();
      final first = store.activeSet!;
      await store.createSet('考前冲刺');

      expect(store.planFor(mon).tasks, isEmpty);
      expect(store.loadSets().length, 2);

      await store.setActiveSet(first.id);
      expect(store.planFor(mon).tasks.length, 3);
    });

    test('在一份里删任务，不影响另一份', () async {
      final store = await freshStore();
      final first = store.activeSet!;
      await store.importPack(StarterPacks.minimal);
      await store.deleteTask(mon, find(store, mon, 's_wrong')!);
      expect(find(store, mon, 's_wrong'), isNull);

      await store.setActiveSet(first.id);
      expect(find(store, mon, 's_wrong'), isNotNull);
    });

    test('关掉计划：首页不显示，清单还留着', () async {
      final store = await freshStore();
      await store.setActiveSet(StudyPlanStore.offId);
      expect(store.isEnabled, isFalse);
      expect(store.loadSets(), isNotEmpty);
    });

    test('删掉当前那份会自动切到别的', () async {
      final store = await freshStore();
      final first = store.activeSet!;
      await store.createSet('第二份');
      await store.deleteSet(store.activeSetId);
      expect(store.activeSetId, first.id);
    });

    test('删光了就等于关掉计划', () async {
      final store = await freshStore();
      await store.deleteSet(store.activeSetId);
      expect(store.activeSetId, StudyPlanStore.offId);
      expect(store.isEnabled, isFalse);
    });
  });

  group('老数据搬家', () {
    test('老的"在职晚间"用户：任务还在，重复规则推算出来', () async {
      final store = await freshStore({'study_plan_template': 'working'});
      expect(store.isEnabled, isTrue);
      // 资料分析原来周一到周五都排，搬完应该是一条"工作日"
      final ziliao = store.activeSet!.tasks.where((t) => t.id == 'e_ziliao20');
      expect(ziliao.length, 1);
      expect(ziliao.first.repeat, RepeatRule.weekdays);
      expect(find(store, mon, 'e_ziliao20'), isNotNull);
      expect(find(store, sat, 'e_ziliao20'), isNull);
    });

    test('老用户改过今天的那条，搬完变成永久生效', () async {
      final store = await freshStore({
        'study_plan_template': 'working',
        'study_plan_override_2026-09-07': jsonEncode({
          'e_ziliao20': const StudyTask(
            id: 'e_ziliao20',
            title: '资料分析 · 只做 10 题',
            action: StudyAction.practice,
            category: 'ziliao',
            count: 10,
          ).toJson(),
        }),
      });

      // 老版本里这个改动只对 9/7 生效，搬完之后每个工作日都该是它
      expect(find(store, mon, 'e_ziliao20')?.count, 10);
      expect(find(store, tue, 'e_ziliao20')?.count, 10);
      expect(find(store, nextMon, 'e_ziliao20')?.title, '资料分析 · 只做 10 题');
    });

    test('老的自定义重复任务照样搬过来', () async {
      final store = await freshStore({
        'study_plan_template': 'light',
        'study_plan_recurring': jsonEncode([
          const StudyTask(
            id: 'c_1',
            title: '看今日时政',
            action: StudyAction.check,
            custom: true,
            repeat: RepeatRule.daily,
          ).toJson(),
        ]),
      });
      expect(find(store, mon, 'c_1')?.title, '看今日时政');
      expect(find(store, sat, 'c_1'), isNotNull);
    });

    test('之前关着计划的用户，搬完还是关着', () async {
      final store = await freshStore({'study_plan_template': 'off'});
      expect(store.isEnabled, isFalse);
    });

    test('打过的勾按 id 存，搬家之后还在', () async {
      final store = await freshStore({
        'study_plan_template': 'working',
        'study_plan_done_2026-09-07': 'e_ziliao20,e_yanyu',
      });
      expect(store.loadDoneIds('2026-09-07'), {'e_ziliao20', 'e_yanyu'});
    });

    test('只搬一次，第二次打开不会把用户的修改冲掉', () async {
      SharedPreferences.setMockInitialValues({'study_plan_template': 'working'});
      final first = await StudyPlanStore.create();
      await first.clearActiveTasks();
      await first.upsertTask(
        mon,
        const StudyTask(
          id: 'only',
          title: '就这一条',
          action: StudyAction.check,
          repeat: RepeatRule.daily,
        ),
      );

      final second = await StudyPlanStore.create();
      expect(second.planFor(mon).tasks.map((t) => t.id), ['only']);
    });
  });

  group('起始包', () {
    test('横跨整周的任务摊平成一条"每天"', () async {
      final tasks = StarterPacks.minimal.expand(mon);
      expect(tasks.length, 3);
      expect(tasks.every((t) => t.repeat == RepeatRule.daily), isTrue);
    });

    test('零散几天的任务一天一条，第一条保留原 id', () {
      final tasks = StarterPacks.working.expand(mon);
      // 言语专项原来排在周一三五：摊平成三条"每周这天"，第一条留原 id
      final yanyu = tasks.where((t) => t.id.startsWith('e_yanyu')).toList();
      expect(yanyu.length, 3);
      expect(yanyu.map((t) => t.id), containsAll(['e_yanyu', 'e_yanyu_w3', 'e_yanyu_w5']));
      expect(yanyu.every((t) => t.repeat == RepeatRule.weekly), isTrue);
      expect(yanyu.map((t) => t.startedOn!.weekday).toSet(), {1, 3, 5});
      expect(tasks.map((t) => t.id).toSet().length, tasks.length,
          reason: 'id 不能撞，撞了打勾会串');
    });

    test('导入的任务都能改能删 —— 不再有"模板任务不能删"这回事', () async {
      final store = await freshStore();
      await store.importPack(StarterPacks.working);
      final before = store.planFor(mon).tasks.length;
      expect(before, greaterThan(0));
      for (final t in store.planFor(mon).tasks.toList()) {
        await store.deleteTask(mon, t);
      }
      expect(store.planFor(mon).tasks, isEmpty);
    });
  });
}
