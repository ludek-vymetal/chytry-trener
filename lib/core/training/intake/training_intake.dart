class TrainingIntake {
  /// Kolikrát týdně uživatel reálně trénuje (2–6)
  final int frequencyPerWeek;

  /// Dostupné vybavení – jednoduché stringy:
  /// "barbell", "rack", "bench", "dumbbell", "machine", "bodyweight", "cardio"
  final Set<String> equipment;

  /// "beginner" / "intermediate" / "advanced" (zatím jednoduché)
  final String experienceLevel;

  /// 1RM map (exerciseId -> 1RM), používá se hlavně pro sílu / závody
  final Map<String, double> oneRMs;

  /// Training Max percent (default 0.90)
  final double trainingMaxPercent;

  const TrainingIntake({
    required this.frequencyPerWeek,
    required this.equipment,
    required this.experienceLevel,
    this.oneRMs = const {},
    this.trainingMaxPercent = 0.90,
  });

  bool get hasStrengthMaxes => oneRMs.isNotEmpty;

  TrainingIntake copyWith({
    int? frequencyPerWeek,
    Set<String>? equipment,
    String? experienceLevel,
    Map<String, double>? oneRMs,
    double? trainingMaxPercent,
  }) {
    return TrainingIntake(
      frequencyPerWeek: frequencyPerWeek ?? this.frequencyPerWeek,
      equipment: equipment ?? this.equipment,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      oneRMs: oneRMs ?? this.oneRMs,
      trainingMaxPercent: trainingMaxPercent ?? this.trainingMaxPercent,
    );
  }
}
