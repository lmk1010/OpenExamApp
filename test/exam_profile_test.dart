import 'package:flutter_test/flutter_test.dart';
import 'package:openexam_app/features/profile/domain/exam_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 备考目标决定界面上出现哪些模块。最要紧的一条：**默认必须跟老样子一模一样**，
/// 不能让人升级完发现申论不见了。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('没设置过时是考公，四个模块全开', () async {
    await ExamProfileStore.load();
    final p = ExamProfileStore.current;
    expect(p.id, 'gongkao');
    for (final f in ExamFeature.values) {
      expect(p.has(f), isTrue, reason: '${f.label} 默认该开着');
    }
    expect(p.mockCount, 50);
    expect(p.mockMinutes, 45);
  });

  test('新建的什么专属模块都不开', () async {
    await ExamProfileStore.load();
    final p = await ExamProfileStore.create('执业医师 · 临床');
    expect(p.features, isEmpty);
    expect(ExamProfileStore.current.id, p.id, reason: '建完就切过去');
  });

  test('关掉的模块存得住', () async {
    await ExamProfileStore.load();
    await ExamProfileStore.save(
      ExamProfileStore.current.copyWith(features: const {ExamFeature.tips}),
    );
    await ExamProfileStore.load();
    expect(ExamProfileStore.current.has(ExamFeature.tips), isTrue);
    expect(ExamProfileStore.current.has(ExamFeature.essay), isFalse);
  });

  test('切换后重启还停在那一份', () async {
    await ExamProfileStore.load();
    final made = await ExamProfileStore.create('法考');
    await ExamProfileStore.load();
    expect(ExamProfileStore.current.id, made.id);
    expect(ExamProfileStore.current.name, '法考');
  });

  test('模考参数按门调，存得住', () async {
    await ExamProfileStore.load();
    await ExamProfileStore.save(
      ExamProfileStore.current.copyWith(mockCount: 150, mockMinutes: 150),
    );
    await ExamProfileStore.load();
    expect(ExamProfileStore.current.mockCount, 150);
    expect(ExamProfileStore.current.mockLimit, const Duration(minutes: 150));
  });

  test('删到一份不剩会退回考公，界面总得按某一套画', () async {
    await ExamProfileStore.load();
    await ExamProfileStore.remove('gongkao');
    expect(ExamProfileStore.all, isNotEmpty);
    expect(ExamProfileStore.current.id, 'gongkao');
  });

  test('删掉当前那份会切到别的', () async {
    await ExamProfileStore.load();
    final second = await ExamProfileStore.create('教资');
    await ExamProfileStore.remove(second.id);
    expect(ExamProfileStore.current.id, isNot(second.id));
    expect(ExamProfileStore.all.length, 1);
  });

  test('存坏了也能打开，不至于整个 app 起不来', () async {
    SharedPreferences.setMockInitialValues({'exam_profiles': '这不是 json'});
    await ExamProfileStore.load();
    expect(ExamProfileStore.current.id, 'gongkao');
  });

  test('多份并存，题库不跟着切', () async {
    await ExamProfileStore.load();
    await ExamProfileStore.create('医师');
    await ExamProfileStore.create('教资');
    expect(ExamProfileStore.all.length, 3);
    // profile 里没有任何题库字段 —— 换目标只换显示，不换题
    expect(ExamProfileStore.current.toJson().keys, isNot(contains('questions')));
  });
}
