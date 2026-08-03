import 'package:openexam_app/features/exam/domain/models/practice_summary.dart';
import 'package:openexam_app/features/exam/domain/models/question.dart';

abstract class ExamRepository {
  Future<List<Question>> fetchQuestions();

  Future<void> savePracticeSummary(PracticeSummary summary);
}
