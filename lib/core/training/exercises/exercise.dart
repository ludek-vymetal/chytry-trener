enum MovementPattern {
  squat,
  hinge,
  press,
  pull,
  row,
  carry,
  core,
  locomotion,
}

enum ExerciseModality {
  strength,
  hypertrophy,
  conditioning,
  endurance,
}

class Exercise {
  final String id;
  final String name;

  /// České / srozumitelnější zobrazení pro uživatele
  /// Např. "Bench press (tlaky na prsa na rovné lavici)"
  final String? czName;

  final MovementPattern pattern;
  final ExerciseModality modality;

  /// jednoduché stringy:
  /// "barbell", "rack", "bench", "dumbbell", "machine", "bodyweight", "cardio"
  final Set<String> equipment;

  final List<String> primaryMuscles;

  /// list exerciseIds, které jsou rozumné náhrady
  final List<String> substitutions;

  /// jaké metriky dává smysl logovat
  final bool supportsLoadKg;
  final bool supportsReps;
  final bool supportsDuration;
  final bool supportsDistance;

  const Exercise({
    required this.id,
    required this.name,
    this.czName,
    required this.pattern,
    required this.modality,
    required this.equipment,
    required this.primaryMuscles,
    required this.substitutions,
    required this.supportsLoadKg,
    required this.supportsReps,
    required this.supportsDuration,
    required this.supportsDistance,
  });

  String get displayName => czName ?? name;
}