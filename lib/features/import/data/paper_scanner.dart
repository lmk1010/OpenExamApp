import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:openexam_app/core/ai/ai_client.dart';
import 'package:openexam_app/data/models/question.dart';
import 'package:pdfx/pdfx.dart';

/// 一页的识别状态。
enum PageState { waiting, running, done, failed }

class ScanPage {
  ScanPage({required this.index, required this.bytes});

  final int index;

  /// 这一页的图（JPEG）。既喂给模型，也用来裁图。
  final Uint8List bytes;

  PageState state = PageState.waiting;
  String? error;
  List<Question> questions = const [];
}

/// 试卷扫描：PDF 或图片 → 每页一次视觉识别 → 结构化题目。
///
/// 一页一次调用，不整本喂。整本喂进去模型会漏题、串页，而且一旦失败
/// 整本重来；分页做的话哪页错重哪页，进度也看得见。
class PaperScanner {
  PaperScanner(this._ai);

  final AiClient _ai;

  /// 页图的长边像素。再大对识别没帮助，只是把请求撑大。
  static const _maxEdge = 1600;

  /// PDF 转成一页一张图。
  static Future<List<ScanPage>> pagesFromPdf(Uint8List pdfBytes) async {
    final doc = await PdfDocument.openData(pdfBytes);
    final out = <ScanPage>[];
    try {
      for (var i = 1; i <= doc.pagesCount; i++) {
        final page = await doc.getPage(i);
        try {
          // 按长边定分辨率，竖版横版都不会渲染过小
          final scale = _maxEdge /
              (page.width > page.height ? page.width : page.height);
          final image = await page.render(
            width: page.width * scale,
            height: page.height * scale,
            format: PdfPageImageFormat.jpeg,
            backgroundColor: '#FFFFFF',
          );
          if (image != null) {
            out.add(ScanPage(index: i, bytes: image.bytes));
          }
        } finally {
          await page.close();
        }
      }
    } finally {
      await doc.close();
    }
    return out;
  }

  /// 拍的照片 / 截图，压到同一个尺寸再走后面的流程。
  static Future<List<ScanPage>> pagesFromImages(List<Uint8List> files) async {
    final out = <ScanPage>[];
    for (var i = 0; i < files.length; i++) {
      final shrunk = await compute(_shrink, files[i]);
      out.add(ScanPage(index: i + 1, bytes: shrunk));
    }
    return out;
  }

  static Uint8List _shrink(Uint8List raw) {
    final decoded = img.decodeImage(raw);
    if (decoded == null) return raw;
    final longest =
        decoded.width > decoded.height ? decoded.width : decoded.height;
    final scaled = longest <= _maxEdge
        ? decoded
        : img.copyResize(
            decoded,
            width: decoded.width >= decoded.height ? _maxEdge : null,
            height: decoded.height > decoded.width ? _maxEdge : null,
            interpolation: img.Interpolation.average,
          );
    return Uint8List.fromList(img.encodeJpg(scaled, quality: 82));
  }

  static const _system = '你是把考试卷图片转成结构化数据的工具。只输出 JSON，不要任何解释。';

  /// 提示词把「这页有什么」问清楚，而不是让模型自由发挥。
  ///
  /// 图不让模型框，让它切横条。视觉模型给小图的精确 bbox 很不准 ——
  /// 实测框歪到题干和选项之间的空白里；但「这道题从第几行到第几行」
  /// 容错高得多，题与题之间本来就有空行。横条整段切下来，
  /// 题干图和选项图都在里面，跟看纸质卷一样。
  static const _prompt = """
把这一页里完整的选择题提取出来，输出 JSON：

{"questions":[{
  "number": 题号数字，没有就 null,
  "stem": "题干纯文字，去掉题号",
  "material": "这题上方的共用材料全文；没有就 null。同一段材料下的几道题都要原样重复填",
  "options": [{"key":"A","text":"选项文字；选项本身是图形时填 null"}],
  "answer": "A",
  "analysis": "解析全文，没有就 null",
  "category": "yanyu / shuliang / panduan / ziliao / changshi 之一，判断不出填 null",
  "hasFigure": true 或 false,
  "band": {"top":0.12,"bottom":0.33}
}]}

category 对应：yanyu 言语理解（逻辑填空、片段阅读）、shuliang 数量关系、
panduan 判断推理（图形、定义、类比、逻辑）、ziliao 资料分析、changshi 常识判断。

band 是这道题在整页上占的纵向范围（0–1 的比例），从题号那一行的上边缘，
到最后一个选项的下边缘，题干和选项都要包进去。只有 hasFigure 为 true 时
才需要 band，其余填 null。

规则：
1. 题干或选项被页面截断的半道题，整道丢掉，不要猜。
2. 题干或选项里有图形、表格、公式图的，hasFigure 填 true 并给出 band。
3. answer 只在页面上明确给出时才填，猜不出就填 null，绝不编。
4. 这页没有完整题目就返回 {"questions":[]}。
""";

  /// 识别一页。失败不抛，写进 [ScanPage.error]，让用户单页重试。
  Future<void> scanPage(ScanPage page) async {
    page.state = PageState.running;
    page.error = null;
    final result = await _ai.completeJson(
      system: _system,
      prompt: _prompt,
      imageBase64: base64Encode(page.bytes),
      mimeType: 'image/jpeg',
    );
    if (!result.isOk || result.value == null) {
      page.state = PageState.failed;
      page.error = result.error ?? '没读出内容';
      return;
    }
    try {
      page.questions = await _toQuestions(result.value!, page);
      page.state = PageState.done;
    } catch (e) {
      page.state = PageState.failed;
      page.error = '返回的格式认不出来';
    }
  }

  Future<List<Question>> _toQuestions(
    Map<String, dynamic> json,
    ScanPage page,
  ) async {
    final raw = json['questions'];
    if (raw is! List) return const [];
    final now = DateTime.now().millisecondsSinceEpoch;
    final out = <Question>[];

    for (var i = 0; i < raw.length; i++) {
      final item = raw[i];
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);

      final hasFigure = map['hasFigure'] == true;

      final options = <QuestionOption>[];
      final rawOptions = map['options'];
      if (rawOptions is List) {
        for (var j = 0; j < rawOptions.length; j++) {
          final o = rawOptions[j];
          final key = (o is Map
                  ? '${o['key'] ?? String.fromCharCode(65 + j)}'
                  : String.fromCharCode(65 + j))
              .toUpperCase();
          final text = (o is Map ? '${o['text'] ?? ''}' : '$o').trim();
          // 图形推理的选项本身就是图，模型只能返回 null。
          // 按"文字为空就丢"处理的话，整道题会因为选项不足两个被扔掉 ——
          // 行测最大的一块就这么没了。用字母顶上，图在题干那张横条里。
          if (text.isEmpty && !hasFigure) continue;
          options.add(QuestionOption(
            key: key,
            text: text.isEmpty ? key : text,
          ));
        }
      }

      var stem = '${map['stem'] ?? ''}'.trim();
      if (stem.isEmpty || options.length < 2) continue;

      // 整道题横切一条存进题干。上下余量不对称：
      // 上边多给一点，模型给的上界常压着字，切紧会削掉半行；
      // 下边几乎不给 —— 试卷里紧挨着选项的往往就是「参考答案」，
      // 多切两行就把答案印进题图里了，做题时一眼穿帮。
      var stemHtml = '';
      final band = map['band'];
      if (hasFigure && band is Map) {
        final name = 'scan_${now}_${page.index}_$i';
        final top = _num(band['top']);
        final bottom = _num(band['bottom']);
        final cropped = await compute(
          _crop,
          _CropJob(bytes: page.bytes, top: top - 0.03, bottom: bottom + 0.005),
        );
        if (cropped != null) {
          figures[name] = cropped;
          stemHtml = '<p>$stem</p><img src="oeimg://$name">';
        }
      }

      out.add(Question(
        id: 'scan_${now}_${page.index}_$i',
        content: stem,
        contentHtml: stemHtml,
        options: options,
        answer: '${map['answer'] ?? ''}'.trim().toUpperCase(),
        category: _category('${map['category'] ?? ''}'),
        analysis: '${map['analysis'] ?? ''}'.trim(),
        material: '${map['material'] ?? ''}'.trim(),
        materialId: '',
        source: 'scanned',
        orderNum: _int(map['number']) ?? (page.index * 100 + i),
      ));
    }
    return out;
  }

  /// 裁下来的图，键是 oeimg:// 后面的名字。
  final Map<String, Uint8List> figures = {};

  /// 模型偶尔会写中文题型名或别的写法，只认我们库里那五个键。
  static String _category(String raw) {
    final v = raw.trim().toLowerCase();
    const known = {'yanyu', 'shuliang', 'panduan', 'ziliao', 'changshi'};
    if (known.contains(v)) return v;
    const cn = {
      '言语': 'yanyu', '言语理解': 'yanyu', '逻辑填空': 'yanyu', '片段阅读': 'yanyu',
      '数量': 'shuliang', '数量关系': 'shuliang',
      '判断': 'panduan', '判断推理': 'panduan', '图形推理': 'panduan',
      '资料': 'ziliao', '资料分析': 'ziliao',
      '常识': 'changshi', '常识判断': 'changshi',
    };
    return cn[raw.trim()] ?? '';
  }

  static double _num(Object? v) =>
      v is num ? v.toDouble() : (double.tryParse('$v') ?? 0);

  static int? _int(Object? v) =>
      v is num ? v.toInt() : int.tryParse('${v ?? ''}');

  /// 整页宽 + 指定纵向区间。横向不裁：题目本来就是整行排的。
  static Uint8List? _crop(_CropJob job) {
    final src = img.decodeImage(job.bytes);
    if (src == null) return null;
    final y0 = (job.top * src.height).round().clamp(0, src.height - 1);
    final y1 = (job.bottom * src.height).round().clamp(y0 + 1, src.height);
    final h = y1 - y0;
    // 太薄多半是模型给歪了，宁可不裁也别塞一条空白进去
    if (h < 60) return null;
    return Uint8List.fromList(
      img.encodeJpg(
        img.copyCrop(src, x: 0, y: y0, width: src.width, height: h),
        quality: 88,
      ),
    );
  }
}

class _CropJob {
  const _CropJob({
    required this.bytes,
    required this.top,
    required this.bottom,
  });

  final Uint8List bytes;
  final double top, bottom;
}
