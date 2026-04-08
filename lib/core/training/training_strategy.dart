/// Popis ideálního tréninku pro danou fázi a cíl
class TrainingStrategy {
  final String label;
  final String rationale;

  /// Doporučený rozsah opakování
  final int repsMin;
  final int repsMax;

  /// Série na partii týdně
  final int setsMin;
  final int setsMax;

  /// Intenzita
  final double rirMin;
  final double rirMax;

  /// Jak měnit objem oproti normálu
  final double volumeMultiplier;

  /// Deload pravidla
  final bool allowDeload;
  final double deloadVolume;

  /// Peak/taper
  final bool isPeaking;

  const TrainingStrategy({
    required this.label,
    required this.rationale,
    required this.repsMin,
    required this.repsMax,
    required this.setsMin,
    required this.setsMax,
    required this.rirMin,
    required this.rirMax,
    required this.volumeMultiplier,
    this.allowDeload = false,
    this.deloadVolume = 0.7,
    this.isPeaking = false,
  });
}
