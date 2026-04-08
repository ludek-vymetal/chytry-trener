class CalorieCalculator {

  /// 🔁 Jakou váhu použít pro VÝPOČET KALORIÍ
  static double weightForCalories({
    required double currentKg,
    required double? targetKg,
  }) {
    if (targetKg == null || targetKg <= 0) return currentKg;

    final diffPct = (currentKg - targetKg).abs() / currentKg;

    // malý rozdíl -> počítáme z aktuální
    if (diffPct <= 0.10) return currentKg;

    // velký rozdíl -> kompromis (průměr)
    return (currentKg + targetKg) / 2.0;
  }

  /// 🔁 Jakou váhu použít pro BÍLKOVINY
  static double weightForProtein({
    required double currentKg,
    required double? targetKg,
  }) {
    if (targetKg == null || targetKg <= 0) return currentKg;

    // protein vždy na cílovou
    return targetKg;
  }
}
