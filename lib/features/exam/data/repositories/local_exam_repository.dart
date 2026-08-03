import 'package:openexam_app/features/exam/domain/models/practice_summary.dart';
import 'package:openexam_app/features/exam/domain/models/question.dart';
import 'package:openexam_app/features/exam/domain/repositories/exam_repository.dart';

class LocalExamRepository implements ExamRepository {
  @override
  Future<List<Question>> fetchQuestions() async {
    return const [
      Question(
        id: 'demo-1',
        content: '这是一个占位题目，后续替换为 openexam 题库。',
        options: ['A', 'B', 'C', 'D'],
        answer: 'A',
        category: 'demo',
      ),
    ];
  }

  @override
  Future<void> savePracticeSummary(PracticeSummary summary) async {
    return;
  }
}
