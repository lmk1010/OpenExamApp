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
  /// 三件事必须点名，否则模型十次有八次会漏：跨页的半道题要丢掉、
  /// 一材多题的材料要单独放、图的位置要给坐标。
  static const _prompt = '''
把这一页里完整的选择题提取出来，输出 JSON：

{"questions":[{
  "number": 题号数字，没有就 null,
  "stem": "题干纯文字，去掉题号",
  "material": "这题上方的共用材料全文；没有就 null。同一段材料下的几道题都要原样重复填",
  "options": [{"key":"A","text":"选项文字"}],
  "answer": "A",
  "analysis": "解析全文，没有就 null",
  "figure": {"x":0.1,"y":0.2,"w":0.5,"h":0.3} 或 null
}]}

规则：
1. 题干或选项被页面截断的半道题，整道丢掉，不要猜。
2. 图形推理这类题干是图的，stem 写文字部分，图的位置写进 figure，
   坐标是相对整页的比例，0–1 之间，框住图本身不要框进文字。
3. answer 只在页面上明确给出时才填，猜不出就填 null，绝不编。
4. 这页没有完整题目就返回 {"questions":[]}。
''';

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

      final options = <QuestionOption>[];
      final rawOptions = map['options'];
      if (rawOptions is List) {
        for (var j = 0; j < rawOptions.length; j++) {
          final o = rawOptions[j];
          final key = o is Map
              ? '${o['key'] ?? String.fromCharCode(65 + j)}'
              : String.fromCharCode(65 + j);
          final text = o is Map ? '${o['text'] ?? ''}' : '$o';
          if (text.trim().isEmpty) continue;
          options.add(QuestionOption(key: key.toUpperCase(), text: text.trim()));
        }
      }

      var stem = '${map['stem'] ?? ''}'.trim();
      if (stem.isEmpty || options.length < 2) continue;

      // 图裁下来放进题干。模型给的是比例坐标，本地按像素裁。
      var stemHtml = '';
      final figure = map['figure'];
      if (figure is Map) {
        final name = 'scan_${now}_${page.index}_$i';
        final cropped = await compute(
          _crop,
          _CropJob(
            bytes: page.bytes,
            x: _num(figure['x']),
            y: _num(figure['y']),
            w: _num(figure['w']),
            h: _num(figure['h']),
          ),
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
        category: '',
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

  static double _num(Object? v) =>
      v is num ? v.toDouble() : (double.tryParse('$v') ?? 0);

  static int? _int(Object? v) =>
      v is num ? v.toInt() : int.tryParse('${v ?? ''}');

  static Uint8List? _crop(_CropJob job) {
    final src = img.decodeImage(job.bytes);
    if (src == null) return null;
    final x = (job.x * src.width).round().clamp(0, src.width - 1);
    final y = (job.y * src.height).round().clamp(0, src.height - 1);
    final w = (job.w * src.width).round().clamp(1, src.width - x);
    final h = (job.h * src.height).round().clamp(1, src.height - y);
    // 太小的框多半是模型给歪了，宁可不裁也别塞一块糊的进去
    if (w < 40 || h < 40) return null;
    return Uint8List.fromList(
      img.encodePng(img.copyCrop(src, x: x, y: y, width: w, height: h)),
    );
  }
}

class _CropJob {
  const _CropJob({
    required this.bytes,
    required this.x,
    required this.y,
    required this.w,
    required this.h,
  });

  final Uint8List bytes;
  final double x, y, w, h;
}
