import '../exercises/exercise.dart';

/// Role cviku v tréninku – nezávislá na konkrétním cviku
enum ExerciseRole {
  mainSquat,
  mainPress,
  mainHinge,

  chestPress,
  verticalPull,
  horizontalPull,

  quads,
  hamstrings,
  glutes,

  shoulders,
  triceps,
  biceps,

  core,
  conditioning,
}

/// Slot v plánu – místo pro cvik
class ExerciseSlot {
  final ExerciseRole role;

  /// Jaký pattern má cvik splňovat
  final MovementPattern pattern;

  /// Povolené modality
  final Set<ExerciseModality> modalities;

  /// Parametry z plánu
  final String sets;
  final String reps;
  final String rir;

  /// Vybraný cvik (může být null = uživatel ještě nevybral)
  final String? selectedExerciseId;

  const ExerciseSlot({
    required this.role,
    required this.pattern,
    required this.modalities,
    required this.sets,
    required this.reps,
    required this.rir,
    this.selectedExerciseId,
  });

  ExerciseSlot copyWith({
    String? selectedExerciseId,
  }) {
    return ExerciseSlot(
      role: role,
      pattern: pattern,
      modalities: modalities,
      sets: sets,
      reps: reps,
      rir: rir,
      selectedExerciseId: selectedExerciseId ?? this.selectedExerciseId,
    );
  }
}
