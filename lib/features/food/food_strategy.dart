/// Výstup pro jídlo – společný formát pro celý projekt
class FoodStrategy {
  final double calorieMultiplier; // násobek TDEE (např. 0.85, 1.08)
  final double proteinGPerKg;      // g/kg
  final double fatGPerKg;          // g/kg
  final bool preferHighCarbs;      // vytrvalost/síla

  /// diagnostika (debug + UI)
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

/// Bezpečnostní mantinely (globální pravidla)
class FoodSafetyRules {
  final double minProteinGPerKg; // >= 1.6
  final double minFatGPerKg;     // >= 0.6 (u hubnutí typicky 0.7)
  final double maxDeficitPct;    // <= 0.25

  const FoodSafetyRules({
    this.minProteinGPerKg = 1.6,
    this.minFatGPerKg = 0.6,
    this.maxDeficitPct = 0.25,
  });
}
