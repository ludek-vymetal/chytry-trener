import 'slots/exercise_slot.dart';
import 'training_set.dart';

class PlannedExercise {
  final String name;
  final String? exerciseId;
  final String sets;
  final String reps;
  final String rir;
  final String? note;
  final double? weightKg;
  final double? intensityPercent;
  final List<PlannedSet> plannedSets;

  const PlannedExercise({
    required this.name,
    this.exerciseId,
    required this.sets,
    required this.reps,
    required this.rir,
    this.note,
    this.weightKg,
    this.intensityPercent,
    this.plannedSets = const [],
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