import 'package:flutter_test/flutter_test.dart';
import 'package:openexam_app/data/db/app_database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// 不打包题库的那个发行版（App Store）能不能正常开库。
///
/// 测试进程里 `assets/seed/openexam_seed.db.gz` 本来就不存在 —— 题库现在放在
/// `bank/`，要 `tool/bank.py link` 才会进 assets。所以这里跑的天然就是空库路径。
///
/// 只用普通 `test()`，不用 `testWidgets`：后者默认在假时钟里跑，开库是真实的
/// 磁盘 I/O，那个 future 在假时钟里永远不完成，套 `tester.runAsync` 也没用 ——
/// 卡住的是 app 在假时钟里已经发起的那次开库，runAsync 等的还是它。
void main() {
  setUpAll(() {
    // rootBundle 要绑定初始化过才能用（`_installSeed` 会去读 asset）。
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('没有种子也能开库 —— questions / images 两张表要自己建出来', () async {
    // 这两张表以前只随种子来，app 自己从不建，空库版会崩在第一条查询上。
    expect(await AppDatabase.instance.countAll(), 0);
    expect(await AppDatabase.instance.categoryStats(), isEmpty);
  });

  test('空库上那些首页要用的查询都得能跑，不能抛', () async {
    // 首页一进来就并发跑这一批。任何一条在空库上抛异常，整页就是白屏。
    expect(await AppDatabase.instance.fetchPractice(limit: 5), isEmpty);
    expect(await AppDatabase.instance.fetchWrong(limit: 5), isEmpty);
    expect(await AppDatabase.instance.listPapers(), isEmpty);
    expect(await AppDatabase.instance.categoryKeys(), isEmpty);
    expect(await AppDatabase.instance.latestYear(), 0);
  });

  test('空库上的弱点诊断给的是"还没有记录"，不是崩溃', () async {
    final data = await AppDatabase.instance.diagnosisData();
    expect(data.isEmpty, isTrue);
    expect(data.attempts, 0);
    expect(data.byCategory, isEmpty);
  });

  test('没有内置题库时不会去换种子 —— 别拿空种子盖掉用户导进来的题', () async {
    expect(await AppDatabase.hasBundledBank, isFalse);
  });

  test('空库上「你在哪考」没有选项 —— 一张中国卷都没有就别问这个问题', () async {
    // App Store 那个发行版走的就是这条路。拿 kProvinces 直接铺的话，
    // 用户第一次开 app 就被问「国考 / 北京 / 上海 选一个」，而他手上
    // 什么都没有。引导页靠这个空列表把整段藏掉。
    expect(await AppDatabase.instance.bankRegions(), isEmpty);
  });

  test('导进带地区的卷之后，选项只出真实有的那几个', () async {
    final db = await AppDatabase.instance.database;
    await db.insert('questions', {
      'id': 'r1',
      'content': '题',
      'options': '[]',
      'answer': 'A',
      'category': 'yanyu',
      'paper_id': 'p_ah',
      'paper_title': '2026 年安徽省考行测',
      'year': 2026,
    });
    await db.insert('questions', {
      'id': 'r2',
      'content': '题',
      'options': '[]',
      'answer': 'A',
      'category': 'yanyu',
      'paper_id': 'p_gk',
      'paper_title': '2026 年国家公务员考试行测',
      'year': 2026,
    });

    final regions = await AppDatabase.instance.bankRegions();
    // 国考排第一 —— 所有人都要考的那张。
    expect(regions.first, '国考');
    expect(regions, containsAll(['国考', '安徽']));
    // 没有卷的省份一个都不该冒出来。
    expect(regions, isNot(contains('北京')));
    expect(regions.length, 2);

    await db.delete('questions', where: "id IN ('r1','r2')");
  });
}
