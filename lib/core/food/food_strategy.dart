class FoodStrategy {
  final double calorieMultiplier;
  final double proteinGPerKg;
  final double fatGPerKg;
  final bool preferHighCarbs;

  /// l10n keys
  final String labelKey;
  final String rationaleKey;

  const FoodStrategy({
    required this.calorieMultiplier,
    required this.proteinGPerKg,
    required this.fatGPerKg,
    required this.preferHighCarbs,
    required this.labelKey,
    required this.rationaleKey,
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