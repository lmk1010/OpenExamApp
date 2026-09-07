import 'package:flutter_test/flutter_test.dart';
import 'package:openexam_app/features/profile/domain/exam_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 备考目标决定界面上出现哪些模块。最要紧的一条：**默认必须跟老样子一模一样**，
/// 不能让人升级完发现申论不见了。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  // 默认档从「一律考公·全开」改成了「跟着包里带没带题库走」。
  //
  // 原因：发行版默认不带题库，而考公档一开就是技巧速查（行测五模块的中文
  // 方法）、词语（中文成语辨析）、申论。英文用户装上第一眼看到的就是这些 ——
  // 界面英文、内容中文，看上去是个坏掉的 App，审核员看到的也是这个。
  test('测试环境没有内置题库，默认档不开任何中文专属模块', () async {
    await ExamProfileStore.load();
    final p = ExamProfileStore.current;
    expect(p.id, ExamProfileStore.neutral.id);
    for (final f in ExamFeature.values) {
      expect(p.has(f), isFalse, reason: '${f.label} 不该默认开着');
    }
  });

  test('导进行测题库之后，中文专属模块自己打开', () async {
    await ExamProfileStore.load();
    expect(ExamProfileStore.current.id, ExamProfileStore.neutral.id);
    await ExamProfileStore.adoptFromBank(
      const ['yanyu', 'shuliang', 'panduan', 'ziliao', 'changshi'],
    );
    final p = ExamProfileStore.current;
    expect(p.id, 'gongkao');
    for (final f in ExamFeature.values) {
      expect(p.has(f), isTrue, reason: '${f.label} 该跟着题库开起来');
    }
    expect(p.mockCount, 50);
    expect(p.mockMinutes, 45);
  });

  test('导进别的题库不该被认成行测', () async {
    await ExamProfileStore.load();
    await ExamProfileStore.adoptFromBank(const ['verbal', 'math', 'logic']);
    expect(ExamProfileStore.current.id, ExamProfileStore.neutral.id);
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

  test('删到一份不剩会退回默认档，界面总得按某一套画', () async {
    await ExamProfileStore.load();
    await ExamProfileStore.remove(ExamProfileStore.current.id);
    expect(ExamProfileStore.all, isNotEmpty);
    expect(ExamProfileStore.current.id, ExamProfileStore.neutral.id);
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
