import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:openexam_app/data/importers/question_importer.dart';

/// tool/pack_bank.py 打出来的题库包，App 的导入器必须读得进去。
///
/// 这是「官网下题库 → App 导入」这条链路唯一会断的地方：打包脚本是 Python
/// 写的，导入器是 Dart 写的，两边各自改一次格式就对不上了，而用户是在
/// 下载完之后才发现导不进去。
///
/// 包不在就跳过 —— dist/ 不进仓库（36MB）。要跑这条先执行
/// `python3 tool/pack_bank.py`。
void main() {
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
}
