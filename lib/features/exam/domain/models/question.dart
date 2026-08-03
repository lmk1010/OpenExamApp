class Question {
  const Question({
    required this.id,
    required this.content,
    required this.options,
    required this.answer,
    required this.category,
  });

  final String id;
  final String content;
  final List<String> options;
  final String answer;
  final String category;
}
