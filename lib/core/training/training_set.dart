class PlannedSet {
  final int reps;
  final double? weightKg;

  /// např. "Rozcvička" / "Pracovní" / poznámka
  final String? note;

  const PlannedSet({
    required this.reps,
    this.weightKg,
    this.note,
  });

  PlannedSet copyWith({
    int? reps,
    double? weightKg,
    String? note,
  }) {
    return PlannedSet(
      reps: reps ?? this.reps,
      weightKg: weightKg ?? this.weightKg,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() => {
        'reps': reps,
        'weightKg': weightKg,
        'note': note,
      };

  factory PlannedSet.fromJson(Map<String, dynamic> json) => PlannedSet(
        reps: (json['reps'] as num?)?.toInt() ?? 0,
        weightKg: (json['weightKg'] as num?)?.toDouble(),
        note: json['note'] as String?,
      );
}
