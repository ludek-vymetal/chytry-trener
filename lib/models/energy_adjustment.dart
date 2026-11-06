/// Průběžná úprava kalorií podle skutečného vývoje váhy (týdenní kontrola).
///
/// Výpočet výdeje je jen odhad – skutečnost ukáže až váha. Jednou za
/// 10–14 dní se porovná tempo změny váhy s plánem aktuální fáze a cíl
/// kalorií se posune (max. ±200 kcal najednou, celkem ±500 kcal).
/// Při změně fáze (např. Cut I → Cut II) se úprava vynuluje.
class EnergyAdjustment {
  /// O kolik kcal se denní cíl upravuje (+ přidat, − ubrat).
  final int kcal;

  /// Kdy proběhla poslední kontrola.
  final DateTime reviewedAt;

  /// Klíč fáze, ke které úprava patří.
  final String phaseKey;

  /// Naměřené tempo při poslední kontrole (kg / týden), `null` = málo dat.
  final double? actualKgPerWeek;

  /// Plánované tempo (kg / týden).
  final double expectedKgPerWeek;

  const EnergyAdjustment({
    required this.kcal,
    required this.reviewedAt,
    required this.phaseKey,
    required this.expectedKgPerWeek,
    this.actualKgPerWeek,
  });

  Map<String, dynamic> toJson() => {
        'kcal': kcal,
        'reviewedAt': reviewedAt.toIso8601String(),
        'phaseKey': phaseKey,
        'actualKgPerWeek': actualKgPerWeek,
        'expectedKgPerWeek': expectedKgPerWeek,
      };

  static EnergyAdjustment? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final m = Map<String, dynamic>.from(raw);
    final at = DateTime.tryParse((m['reviewedAt'] as String?) ?? '');
    if (at == null) return null;
    return EnergyAdjustment(
      kcal: (m['kcal'] as num?)?.toInt() ?? 0,
      reviewedAt: at,
      phaseKey: (m['phaseKey'] as String?) ?? '',
      actualKgPerWeek: (m['actualKgPerWeek'] as num?)?.toDouble(),
      expectedKgPerWeek: (m['expectedKgPerWeek'] as num?)?.toDouble() ?? 0,
    );
  }
}
