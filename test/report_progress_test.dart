import 'package:flutter_test/flutter_test.dart';
import 'package:openexam_app/data/models/question.dart';

/// 记录不只是成绩单，也是进度：做到哪儿存到哪儿，回头能接着做。
void main() {
  ExamReport row({
    int cursor = 0,
    Object? done,
    int answered = 0,
    int total = 20,
  }) =>
      ExamReport.fromRow({
        'id': 1,
        'title': '练习 20 题',
        'kind': 'practice',
        'total': total,
        'answered': answered,
        'correct': 0,
        'elapsed_ms': 0,
        'question_ids': '[]',
        'answers': '{}',
        'created_at': DateTime(2026, 9, 7).toIso8601String(),
        'cursor': cursor,
        if (done != null) 'done': done,
      });

  test('没做完的记着停在第几题', () {
    final r = row(cursor: 7, done: 0, answered: 8);
    expect(r.done, isFalse);
    expect(r.cursor, 7);
    expect(r.total - r.answered, 12, reason: '还剩多少题');
  });

  test('交完卷的是完成态', () {
    expect(row(cursor: 20, done: 1, answered: 20).done, isTrue);
  });

  test('老记录没有 done 这一列，当作已完成', () {
    // 加这两列之前写的行，本来就是交卷才落的
    expect(row().done, isTrue);
    expect(row().cursor, 0);
  });
}
