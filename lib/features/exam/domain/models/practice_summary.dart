class PracticeSummary {
  const PracticeSummary({
    required this.total,
    required this.correct,
    required this.durationSeconds,
  });

  final int total;
  final int correct;
  final int durationSeconds;

  double get accuracy => total == 0 ? 0 : correct / total;
}
