import 'package:flutter_test/flutter_test.dart';
import 'package:openexam_app/features/backup/prefs_backup.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('学习计划和考试日期进备份', () async {
    SharedPreferences.setMockInitialValues({
      'study_plan_sets': '[{"id":"set_1","name":"我的计划","tasks":[]}]',
      'study_plan_active': 'set_1',
      'study_plan_done_2026-09-07': 'a,b',
      'exam_date': '2026-10-17',
      'daily_goal': 60,
    });
    final out = await PrefsBackup.export();
    expect(out['study_plan_sets'], contains('我的计划'));
    expect(out['study_plan_active'], 'set_1');
    expect(out['study_plan_done_2026-09-07'], 'a,b');
    expect(out['exam_date'], '2026-10-17');
    expect(out['daily_goal'], 60);
  });

  test('API Key 绝不进备份 —— 备份文件是用户会随手转发的', () async {
    SharedPreferences.setMockInitialValues({
      'ai_api_key': 'sk-secret',
      'ai_provider': 'deepseek',
      'ai_model': 'deepseek-chat',
      'exam_date': '2026-10-17',
    });
    final out = await PrefsBackup.export();
    expect(out.containsKey('ai_api_key'), isFalse);
    expect(out.containsKey('ai_provider'), isFalse);
    expect(out.containsKey('ai_model'), isFalse);
    expect(out['exam_date'], '2026-10-17');
    expect(out.values.join(), isNot(contains('sk-secret')));
  });

  test('恢复能把计划写回去', () async {
    final restored = await PrefsBackup.import({
      'study_plan_sets': '[{"id":"set_1"}]',
      'exam_date': '2026-10-17',
      'daily_goal': 60,
      'nav_rail_hidden': true,
      'font_scale': 1.2,
    });
    expect(restored, 5);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('exam_date'), '2026-10-17');
    expect(prefs.getInt('daily_goal'), 60);
    expect(prefs.getBool('nav_rail_hidden'), isTrue);
    expect(prefs.getDouble('font_scale'), 1.2);
  });

  test('恢复时不认白名单外的键 —— 备份文件是外部输入', () async {
    final restored = await PrefsBackup.import({
      'ai_api_key': 'sk-injected',
      'exam_date': '2026-10-17',
    });
    expect(restored, 1);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('ai_api_key'), isNull);
  });

  test('老备份没有 settings 这一节，不该清空现有计划', () async {
    SharedPreferences.setMockInitialValues({'exam_date': '2026-10-17'});
    expect(await PrefsBackup.import(null), 0);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('exam_date'), '2026-10-17');
  });
}
