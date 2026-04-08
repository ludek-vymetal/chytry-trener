class NutritionWeightBasis {
  /// Kalorie: většinou aktuální váha.
  /// Pokud je cílová hodně daleko (např. >10%), použijeme "adjusted" (průměr),
  /// aby TDEE nebylo extrémní.
  static double forCalories({
    required double currentKg,
    required double? targetKg,
  }) {
    if (targetKg == null || targetKg <= 0) return currentKg;

    final diffPct = (currentKg - targetKg).abs() / currentKg;
    if (diffPct <= 0.10) return currentKg;

    // adjusted weight (MVP)
    return (currentKg + targetKg) / 2.0;
  }

  /// Protein: dává smysl cílová váha (nebo lean mass, pokud ji jednou budeš mít).
  static double forProtein({
    required double currentKg,
    required double? targetKg,
  }) {
    if (targetKg == null || targetKg <= 0) return currentKg;
    return targetKg;
  }
}
