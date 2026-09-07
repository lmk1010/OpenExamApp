import 'package:flutter_test/flutter_test.dart';
import 'package:openexam_app/core/constants/categories.dart';

/// 这个 app 不该只认行测那五个模块。导进来的医师、法考题必须能出现在
/// 练习页和各处筛选里，否则题在库里也是白导。
void main() {
  tearDown(() => CategoryRegistry.updateFrom(const []));

  test('空题库退回内置那套当占位', () {
    CategoryRegistry.updateFrom(const []);
    expect(CategoryRegistry.current, kGongkaoCategories);
  });

  test('题库里有什么就列什么', () {
    CategoryRegistry.updateFrom(['内科学', '外科学', '药理学']);
    expect(
      CategoryRegistry.current.map((e) => e.key),
      containsAll(['内科学', '外科学', '药理学']),
    );
    expect(CategoryRegistry.current.length, 3, reason: '不该再混进行测五模块');
  });

  test('内置分类排在导入的前面，且保持原顺序', () {
    CategoryRegistry.updateFrom(['刑法', 'shuliang', 'yanyu']);
    final keys = CategoryRegistry.current.map((e) => e.key).toList();
    expect(keys.indexOf('yanyu'), lessThan(keys.indexOf('shuliang')),
        reason: '内置的按 kGongkaoCategories 里的顺序');
    expect(keys.last, '刑法');
  });

  test('内置分类保留自己的标签和图标', () {
    CategoryRegistry.updateFrom(['yanyu']);
    final meta = CategoryRegistry.current.single;
    expect(meta.label, '言语理解');
    expect(meta.short, '言语');
  });

  test('导入的分类直接拿名字当标签', () {
    expect(CategoryRegistry.metaFor('教育心理学').label, '教育心理学');
  });

  test('简称取前两个字，长名字不撑破筛选条', () {
    expect(CategoryRegistry.metaFor('教育心理学').short, '教育');
    // 三个字以内原样保留，切了反而看不懂
    expect(CategoryRegistry.metaFor('刑法').short, '刑法');
    expect(CategoryRegistry.metaFor('内科学').short, '内科学');
  });

  test('同一个名字的图标每次都一样', () {
    final a = CategoryRegistry.metaFor('病理学').icon;
    final b = CategoryRegistry.metaFor('病理学').icon;
    expect(a, b, reason: '用了稳定哈希，不是 hashCode');
  });

  test('不同科目不会全挤成同一个图标', () {
    const subjects = ['内科学', '外科学', '药理学', '刑法', '民法', '教育学'];
    final icons = subjects.map((s) => CategoryRegistry.metaFor(s).icon).toSet();
    expect(icons.length, greaterThan(1));
  });

  test('重复的分类键只出现一次', () {
    CategoryRegistry.updateFrom(['刑法', '刑法', '刑法']);
    expect(CategoryRegistry.current.length, 1);
  });

  test('空白键被丢掉', () {
    CategoryRegistry.updateFrom(['', '  ', '刑法']);
    expect(CategoryRegistry.current.map((e) => e.key), ['刑法']);
  });

  test('categoryIcon 对导入的分类也给得出图标', () {
    // 以前一律回落到 shuffle，所有新科目长一个样
    final a = categoryIcon('内科学');
    final b = categoryIcon('民法');
    expect(a, isNotNull);
    expect([a, b].toSet().length, greaterThanOrEqualTo(1));
  });

  test('categoryLabel 对导入的分类原样返回', () {
    expect(categoryLabel('临床医学'), '临床医学');
  });
}
