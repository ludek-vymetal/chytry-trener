import 'slots/exercise_slot.dart';
import 'training_set.dart';

class PlannedExercise {
  final String name;
  final String sets;
  final String reps;
  final String rir;
  final String? note;

  /// 🔥 napojení na ExerciseDB
  final String? exerciseId;

  /// intensityPercent = např. 0.80 (80% TM)
  final double? intensityPercent;

  /// dopočítaná / zadaná váha
  final double? weightKg;

  /// ✅ konkrétní série (rozcvičení + pracovní)
  final List<PlannedSet>? plannedSets;

  const PlannedExercise({
    required this.name,
    required this.sets,
    required this.reps,
    required this.rir,
    this.note,
    this.exerciseId,
    this.intensityPercent,
    this.weightKg,
    this.plannedSets,
  });
}

class TrainingDayPlan {
  final String dayLabel;
  final String focus;
  final List<PlannedExercise> exercises;

  const TrainingDayPlan({
    required this.dayLabel,
    required this.focus,
    required this.exercises,
  });
}

class SlotTrainingDayPlan {
  final String dayLabel;
  final String focus;

  final List<ExerciseSlot> slots;

  const SlotTrainingDayPlan({
    required this.dayLabel,
    required this.focus,
    required this.slots,
  });
}
