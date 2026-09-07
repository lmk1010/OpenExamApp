import 'package:flutter_test/flutter_test.dart';
import 'package:openexam_app/features/profile/domain/exam_profile.dart';

/// 全新安装该给哪一份备考档案。
///
/// 这条以前是写死的「考公·全开」。发行版默认不带题库之后，那个默认会让英文
/// 用户第一眼看到技巧速查（行测五模块的中文方法）、词语（中文成语辨析）、
/// 申论 —— 界面是英文的，内容全是中文。审核员看到的也是这个。
void main() {
  test('五个模块对上三个就算行测 —— 有的卷不考数量', () {
    expect(
      ExamProfileStore.looksGongkao(['yanyu', 'panduan', 'ziliao']),
      isTrue,
    );
    expect(
      ExamProfileStore.looksGongkao(
        ['yanyu', 'shuliang', 'panduan', 'ziliao', 'changshi'],
      ),
      isTrue,
    );
  });

  test('对上两个不算 —— 别把碰巧有两个同名分类的题库认成行测', () {
    expect(ExamProfileStore.looksGongkao(['yanyu', 'panduan']), isFalse);
  });

  test('英文题库不该被认成行测', () {
    expect(
      ExamProfileStore.looksGongkao(['verbal', 'quantitative', 'logic']),
      isFalse,
    );
  });

  test('空题库不该被认成行测', () {
    expect(ExamProfileStore.looksGongkao(const []), isFalse);
  });

  test('中性档不开任何中文专属模块', () {
    expect(ExamProfileStore.neutral.features, isEmpty);
    for (final f in ExamFeature.values) {
      expect(ExamProfileStore.neutral.has(f), isFalse, reason: '$f');
    }
  });

  test('考公档该开的还得全开 —— 老用户升级上来不能少东西', () {
    for (final f in ExamFeature.values) {
      expect(ExamProfile.gongkao.has(f), isTrue, reason: '$f');
    }
  });
}
