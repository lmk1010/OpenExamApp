import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:openexam_app/data/db/app_database.dart';
import 'package:openexam_app/data/models/question.dart';

/// 把题库导出成一个能被自己导回来的 zip。
///
/// 这是「分享题库」的另一半：以前只能导入，题库只进不出 —— 用扫描试卷、
/// 文档导入辛苦攒出来的一套题，换台手机就没了，更别说发给别人。
///
/// 格式刻意跟 [QuestionImporter] 吃的完全一样（zip 里一个 questions.json
/// 加一个 images/ 目录），所以**导出的文件一定能被导入回来**。自造一套导出
/// 格式是这类功能最常见的死法：导完发现自己都读不了。
class BankExporter {
  const BankExporter._();

  /// 图片在题干、材料、选项里都可能出现，一处都不能漏 —— 漏了对方导进去
  /// 就是一道没有图的图形推理题。
  static final _imageRef = RegExp(r'oeimg://([A-Za-z0-9._-]+)');

  static Set<String> imageNamesOf(Iterable<Question> questions) {
    final names = <String>{};
    for (final q in questions) {
      final blob = StringBuffer()
        ..writeln(q.contentHtml)
        ..writeln(q.content)
        ..writeln(q.material)
        ..writeln(q.analysisHtml);
      for (final o in q.options) {
        blob.writeln(o.html);
      }
      for (final m in _imageRef.allMatches(blob.toString())) {
        names.add(m.group(1)!);
      }
    }
    return names;
  }

  /// 一份题的 JSON。带上 paper 头，导入方就能把整卷的标题和年份接回去。
  static String buildJson(
    List<Question> questions, {
    String? paperId,
    String? paperTitle,
    int? year,
  }) {
    final body = <String, Object?>{
      if (paperId != null && paperId.isNotEmpty ||
          paperTitle != null && paperTitle.isNotEmpty)
        'paper': {
          if (paperId != null && paperId.isNotEmpty) 'id': paperId,
          if (paperTitle != null && paperTitle.isNotEmpty) 'title': paperTitle,
          if (year != null && year > 0) 'year': year,
        },
      'questions': [
        for (final q in questions)
          {
            ...q.toJson(),
            // toJson 不带题号，而导入方缺了它就按数组下标重排。
            // 只导一部分题的时候（比如只导错题），下标跟原卷对不上。
            'orderNum': q.orderNum,
            if (q.subCategory.isNotEmpty) 'subCategory': q.subCategory,
          },
      ],
    };
    return const JsonEncoder.withIndent('  ').convert(body);
  }

  /// 打成 zip。图片从库里捞出来一并塞进去。
  static Future<Uint8List> buildArchive(
    List<Question> questions, {
    String? paperId,
    String? paperTitle,
    int? year,
  }) async {
    final archive = Archive();

    final json = utf8.encode(
      buildJson(questions, paperId: paperId, paperTitle: paperTitle, year: year),
    );
    archive.addFile(ArchiveFile('questions.json', json.length, json));

    for (final name in imageNamesOf(questions)) {
      final bytes = await AppDatabase.instance.image(name);
      if (bytes == null) continue;
      // 库里存的是原始字节，扩展名统一按 png 写 —— 导入方是按文件名去掉
      // 扩展名来对 oeimg:// 的，认的是名字不是格式。
      archive.addFile(
        ArchiveFile('images/$name.png', bytes.length, bytes),
      );
    }

    final zip = ZipEncoder().encode(archive);
    return Uint8List.fromList(zip);
  }

  /// 导出文件名。带上题数，收到的人不打开也知道是什么。
  static String fileName(String label, int count) {
    final now = DateTime.now();
    final stamp = '${now.year}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}';
    final safe = label
        .replaceAll(RegExp(r'[\\/:*?"<>|\s]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    final stem = safe.isEmpty ? 'bank' : safe;
    // 单位用中性的 q：这个文件是发给别人的，名字不该跟着导出者的界面语言变。
    return '$stem-${count}q-$stamp.zip';
  }
}
