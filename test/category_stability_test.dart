import 'package:flutter_test/flutter_test.dart';
import 'package:openexam_app/core/constants/categories.dart';
import 'package:openexam_app/core/ui/stroke_icons.dart';
import 'package:openexam_app/data/importers/doc_parser.dart';
import 'package:openexam_app/data/models/question.dart';

/// 导一本计算机书进来，分块解析每块都在独立判断分类。不收口的话，同一个科目
/// 会裂成"数据库""数据库系统""数据库技术"三张卡片 —— 用户以为自己导重复了。
void main() {
  Question q(String category) => Question(
        id: category + DateTime.now().microsecondsSinceEpoch.toString(),
        content: '题干 $category',
        options: const [
          QuestionOption(key: 'A', text: '甲'),
          QuestionOption(key: 'B', text: '乙'),
        ],
        answer: 'A',
        category: category,
      );

  List<String> categoriesOf(List<Question> list) =>
      list.map((e) => e.category).toList();

  group('分类收口', () {
    test('近义名并成一个', () {
      final list = normalizeCategories([
        q('数据库'),
        q('数据库'),
        q('数据库'),
        q('数据库系统'),
      ]);
      expect(categoriesOf(list).toSet(), {'数据库'},
          reason: '并到出现次数多的那个上');
    });

    test('并的方向看谁出现得多，不看谁的名字长', () {
      final list = normalizeCategories([
        q('数据库系统'),
        q('数据库系统'),
        q('数据库系统'),
        q('数据库'),
      ]);
      expect(categoriesOf(list).toSet(), {'数据库系统'});
    });

    test('不相干的科目绝不合并', () {
      // 这是最要紧的一条：宁可留两个近义分类，也不能把民法刑法揉一起
      final list = normalizeCategories([q('民法'), q('刑法'), q('行政法')]);
      expect(categoriesOf(list).toSet(), {'民法', '刑法', '行政法'});
    });

    test('只有一个分类时原样不动', () {
      final list = normalizeCategories([q('网络技术'), q('网络技术')]);
      expect(categoriesOf(list).toSet(), {'网络技术'});
    });

    test('没分类的题归到「未分类」，不会从模块里消失', () {
      // category 为空的话 categoryKeys() 会过滤掉，题在库里却没有任何入口
      final list = normalizeCategories([q(''), q('  '), q('数据库')]);
      expect(list.where((e) => e.category == '未分类').length, 2);
      expect(list.every((e) => e.category.trim().isNotEmpty), isTrue);
    });

    test('三个近义的一起收成一个', () {
      final list = normalizeCategories([
        q('数据库'),
        q('数据库'),
        q('数据库系统'),
        q('数据库技术'),
      ]);
      expect(categoriesOf(list).toSet().length, 1);
    });
  });

  group('内置分类按中文名也能认', () {
    tearDown(() => CategoryRegistry.updateFrom(const []));

    test('AI 写的"数据库"能拿到内置图标', () {
      // 内置的 key 是 cs_db，label 才是"数据库"。只比 key 的话永远对不上，
      // 导进来的计算机题白白拿不到配好的图标
      final meta = CategoryRegistry.metaFor('数据库');
      final builtin =
          kComputerCategories.firstWhere((e) => e.key == 'cs_db');
      expect(meta.icon, builtin.icon);
      expect(meta.short, builtin.short);
    });

    test('但 key 要保持题库里存的那个，否则查不到题', () {
      final meta = CategoryRegistry.metaFor('数据库');
      expect(meta.key, '数据库', reason: '换成 cs_db 的话按 category 查题会查空');
    });

    test('行测的中文名同样认得', () {
      expect(CategoryRegistry.metaFor('言语理解').short, '言语');
    });

    test('导入计算机题后，卡片列表里就是这些科目', () {
      CategoryRegistry.updateFrom(['数据库', '网络技术', '程序设计']);
      expect(
        CategoryRegistry.current.map((e) => e.key),
        containsAll(['数据库', '网络技术', '程序设计']),
      );
      // 内置计算机分类有专属图标，不是那个兜底的 shuffle
      final db = CategoryRegistry.current.firstWhere((e) => e.key == '数据库');
      expect(db.icon, isNot(AppIcon.shuffle));
    });
  });
}
