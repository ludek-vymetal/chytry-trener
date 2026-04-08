class FoodStrategy {
  final double calorieMultiplier;
  final double proteinGPerKg;
  final double fatGPerKg;
  final bool preferHighCarbs;

  final String label;
  final String rationale;

  const FoodStrategy({
    required this.calorieMultiplier,
    required this.proteinGPerKg,
    required this.fatGPerKg,
    required this.preferHighCarbs,
    required this.label,
    required this.rationale,
  });
}

class FoodSafetyRules {
  final double minProteinGPerKg;
  final double minFatGPerKg;
  final double maxDeficitPct;

  const FoodSafetyRules({
    this.minProteinGPerKg = 1.6,
    this.minFatGPerKg = 0.6,
    this.maxDeficitPct = 0.25,
  });
}
