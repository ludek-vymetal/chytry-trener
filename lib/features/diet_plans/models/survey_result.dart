class SurveyResult {
  final bool isEligible;
  final String message;
  final int score;

  SurveyResult({
    required this.isEligible,
    required this.message,
    this.score = 0,
  });
}