import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:openexam_app/core/constants/categories.dart';
import 'package:openexam_app/data/db/app_database.dart';
import 'package:openexam_app/data/importers/question_importer.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// tool/pack_bank.py 打出来的题库包，App 的导入器必须读得进去。
///
/// 这是「官网下题库 → App 导入」这条链路唯一会断的地方：打包脚本是 Python
/// 写的，导入器是 Dart 写的，两边各自改一次格式就对不上了，而用户是在
/// 下载完之后才发现导不进去。
///
/// 包不在就跳过 —— dist/ 不进仓库（36MB）。要跑这条先执行
/// `python3 tool/pack_bank.py`。
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    // 自己一个库目录。这一条会往库里写两千道题，而 flutter test 各个文件
    // 并行跑、共用 .dart_tool 下同一个 openexam.db —— 不隔开的话
    // no_bank_test 那几条「空库应该是空的」会被这里写进去的题冲掉。
    final dir = Directory.systemTemp.createTempSync('openexam_pack_test');
    await databaseFactory.setDatabasesPath(dir.path);
    addTearDown(() => dir.deleteSync(recursive: true));
  });

  final pack = File('dist/banks/gongkao-national.zip');

  test('国考包能被 QuestionImporter 原样读回来', () {
    if (!pack.existsSync()) {
      markTestSkipped('先跑 python3 tool/pack_bank.py 生成 dist/banks/');
      return;
    }

    final bundle = QuestionImporter.parseArchive(pack.readAsBytesSync());

    // 题数对得上打包脚本报的数。少了就是有题在 _parseJson 里被丢了 ——
    // 它会静默丢掉没题干、选项不足两个、没答案的题。
    expect(bundle.questions.length, 1974);
    expect(bundle.warnings, isEmpty);

    // 图一张都不能少。缺了对方导进去就是一道没有图的图形推理题。
    expect(bundle.missingImages, 0);
    expect(bundle.images.length, greaterThan(200));

    // 卷子信息接得回去，不是一堆没出处的散题。
    final withPaper = bundle.questions.where((q) => q.paperTitle.isNotEmpty);
    expect(withPaper.length, bundle.questions.length);
    expect(bundle.questions.map((q) => q.paperId).toSet().length, 15);

    // 分类要能对上内置那五个模块，否则首页五座岛一张都点不出题。
    final cats = bundle.questions.map((q) => q.category).toSet();
    expect(cats, containsAll(['yanyu', 'shuliang', 'panduan', 'ziliao', 'changshi']));

    // 一材多题的材料要跟着题走。
    expect(bundle.questions.where((q) => q.material.isNotEmpty), isNotEmpty);

    // 题号不能被按下标重排。
    final orders = bundle.questions.map((q) => q.orderNum).toSet();
    expect(orders.length, greaterThan(50));
  });

  test('导进空库之后，首页那几条查询真的能查出题来', () async {
    if (!pack.existsSync()) {
      markTestSkipped('先跑 python3 tool/pack_bank.py 生成 dist/banks/');
      return;
    }

    // 走用户走的那条路：下载 zip →（文件选择器）→ 解析 → 落库。
    // 只有这里跑通，「官网下题库」才算真的通了 —— 光解析出来不算，
    // 题得能被首页、练习、题库页查得到。
    final db = AppDatabase.instance;
    final before = await db.countAll();
    final bundle = QuestionImporter.parseArchive(pack.readAsBytesSync());
    await db.importImages(bundle.images);
    final n = await db.importQuestions(bundle.questions);

    expect(n, 1974);
    expect(await db.countAll(), before + 1974);

    // 首页五座岛：分类统计得出得来，否则一排卡点不出题。
    final stats = await db.categoryStats();
    final byKey = {for (final s in stats) s.category: s.total};
    for (final k in ['yanyu', 'shuliang', 'panduan', 'ziliao', 'changshi']) {
      expect(byKey[k] ?? 0, greaterThan(0), reason: '$k 一道题都没有');
    }
    CategoryRegistry.updateFrom(await db.categoryKeys());
    expect(CategoryRegistry.current.length, greaterThanOrEqualTo(5));

    // 题库页：卷子列得出来，地区认得出来。
    final papers = await db.listPapers();
    expect(papers.length, 15);
    expect(await db.bankRegions(), contains('国考'));

    // 练习页：随手抽一组题，选项和答案都在。
    final practice = await db.fetchPractice(limit: 20, shuffle: true);
    expect(practice, hasLength(20));
    expect(practice.every((q) => q.options.length >= 2), isTrue);
    expect(practice.every((q) => q.answer.isNotEmpty), isTrue);

    // 图进库了，题里的 oeimg:// 才有东西可渲染。
    final imgs = Sqflite.firstIntValue(await (await db.database)
        .rawQuery("SELECT COUNT(*) FROM images"));
    expect(imgs, greaterThan(200));
  });
}
