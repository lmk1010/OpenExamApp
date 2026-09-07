import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openexam_app/core/ui/rich_content.dart';

/// 逻辑填空的空位在题库里就是一串空格。不画线的话，题干写着"依次填入画横线
/// 部分"，屏幕上却一条线也没有 —— 用户第一眼就发现了。
void main() {
  /// 收集渲染出来的所有 span，连同它们身上的 decoration。
  List<(String, TextDecoration?)> spansOf(WidgetTester tester) {
    final out = <(String, TextDecoration?)>[];
    for (final rt in tester.widgetList<RichText>(find.byType(RichText))) {
      rt.text.visitChildren((span) {
        if (span is TextSpan && span.text != null) {
          out.add((span.text!, span.style?.decoration));
        }
        return true;
      });
    }
    return out;
  }

  Future<void> pump(WidgetTester tester, String markup) {
    return tester.pumpWidget(
      MaterialApp(home: Scaffold(body: RichContent(markup))),
    );
  }

  testWidgets('题干里的空位画上下划线', (tester) async {
    await pump(tester, '效能日益提升的        ，反映出制度越来越完善。');
    final spans = spansOf(tester);
    final underlined =
        spans.where((s) => s.$2 == TextDecoration.underline).toList();

    expect(underlined, hasLength(1));
    expect(underlined.first.$1.trim(), isEmpty, reason: '画线的应该是空位本身');
    expect(underlined.first.$1.length, greaterThanOrEqualTo(3));
  });

  testWidgets('一句里两个空，两条线', (tester) async {
    await pump(tester, '提升的        ，能够提供        的帮助。');
    expect(
      spansOf(tester).where((s) => s.$2 == TextDecoration.underline),
      hasLength(2),
    );
  });

  testWidgets('段首缩进不画线', (tester) async {
    // 中文正文段首常有两个全角空格，画上线就成了平白无故的横杠
    await pump(tester, '　　　这是正文第一段，没有空缺。');
    expect(
      spansOf(tester).where((s) => s.$2 == TextDecoration.underline),
      isEmpty,
    );
  });

  testWidgets('选项里的单个空格不算空缺', (tester) async {
    await pump(tester, '写照 托底');
    expect(
      spansOf(tester).where((s) => s.$2 == TextDecoration.underline),
      isEmpty,
    );
  });

  testWidgets('下划线写法的空缺同样画线，且不原样打印下划线', (tester) async {
    // 现在库里 2018 道逻辑填空是这种写法，只有 56 道是空格 ——
    // 以前只认空格，这批题等于没走空缺逻辑。
    await pump(tester, '却又________地决定了一个地方的发展模式。');
    final spans = spansOf(tester);
    final underlined =
        spans.where((s) => s.$2 == TextDecoration.underline).toList();

    expect(underlined, hasLength(1));
    expect(underlined.first.$1.trim(), isEmpty, reason: '画的是线，不是下划线字符');
    expect(spans.map((s) => s.$1).join(), isNot(contains('_')));
  });

  testWidgets('一句里两个下划线空，两条线，宽度一致', (tester) async {
    await pump(tester, '看似不大，却又______地决定了；外延如此____，学习才复杂。');
    final underlined = spansOf(tester)
        .where((s) => s.$2 == TextDecoration.underline)
        .toList();
    expect(underlined, hasLength(2));
    // 原文一个 6 个下划线一个 4 个，画出来必须一样长
    expect(underlined[0].$1, underlined[1].$1);
  });

  testWidgets('行首的下划线照样画线 —— 没人拿下划线做缩进', (tester) async {
    await pump(tester, '________是这段话的第一个空。');
    expect(
      spansOf(tester).where((s) => s.$2 == TextDecoration.underline),
      hasLength(1),
    );
  });

  testWidgets('单个下划线不当空缺，变量名之类的别误伤', (tester) async {
    await pump(tester, '字段 a_b 的取值。');
    expect(
      spansOf(tester).where((s) => s.$2 == TextDecoration.underline),
      isEmpty,
    );
  });
}
