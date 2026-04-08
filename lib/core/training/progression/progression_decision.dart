enum ProgressAction {
  increase,
  keep,
  noData,
}

class ProgressDecision {
  final ProgressAction action;
  final double? currentWeightKg;
  final double? nextWeightKg;
  final String reason;

  const ProgressDecision({
    required this.action,
    required this.reason,
    this.currentWeightKg,
    this.nextWeightKg,
  });

  bool get hasRecommendation =>
      nextWeightKg != null && currentWeightKg != null;

  double? get deltaKg {
    if (nextWeightKg == null || currentWeightKg == null) {
      return null;
    }
    return nextWeightKg! - currentWeightKg!;
  }
}