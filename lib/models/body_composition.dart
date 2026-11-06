/// Poslední měření složení těla (InBody / váha s analýzou) pro výpočty.
///
/// Uloží se do profilu klienta, když trenér zapíše InBody (nebo se při
/// přepnutí klienta načte nejnovější záznam). Podle něj se počítá bazální
/// metabolismus z beztukové hmoty a referenční váha pro bílkoviny – u lidí
/// s vyšším podílem tuku nebo naopak hodně svalů je to přesnější než
/// odhad jen z výšky, váhy a věku.
class BodyComposition {
  final DateTime date;
  final double weightKg;

  /// Beztuková (čistá) hmota těla v kg.
  final double leanMassKg;

  /// Podíl tuku v %.
  final double bodyFatPercent;

  /// Bazální metabolismus změřený přístrojem (kcal), 0 = neuvedeno.
  final double bmrKcal;

  /// Kosterní svalovina v kg (0 = neuvedeno).
  final double smmKg;

  const BodyComposition({
    required this.date,
    required this.weightKg,
    required this.leanMassKg,
    required this.bodyFatPercent,
    this.bmrKcal = 0,
    this.smmKg = 0,
  });

  /// Kolik dní je měření staré (vůči [now]).
  int ageInDays([DateTime? now]) =>
      (now ?? DateTime.now()).difference(date).inDays;

  /// Měření je dost čerstvé, aby se podle něj počítalo (max. 6 měsíců).
  bool isUsable([DateTime? now]) =>
      leanMassKg > 20 && ageInDays(now) <= 183 && ageInDays(now) >= -1;

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'weightKg': weightKg,
        'leanMassKg': leanMassKg,
        'bodyFatPercent': bodyFatPercent,
        'bmrKcal': bmrKcal,
        'smmKg': smmKg,
      };

  static BodyComposition? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final m = Map<String, dynamic>.from(raw);
    final date = DateTime.tryParse((m['date'] as String?) ?? '');
    final lean = (m['leanMassKg'] as num?)?.toDouble() ?? 0;
    if (date == null || lean <= 0) return null;
    return BodyComposition(
      date: date,
      weightKg: (m['weightKg'] as num?)?.toDouble() ?? 0,
      leanMassKg: lean,
      bodyFatPercent: (m['bodyFatPercent'] as num?)?.toDouble() ?? 0,
      bmrKcal: (m['bmrKcal'] as num?)?.toDouble() ?? 0,
      smmKg: (m['smmKg'] as num?)?.toDouble() ?? 0,
    );
  }
}
