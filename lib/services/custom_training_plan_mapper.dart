import '../models/custom_training_plan.dart';
import '../core/training/training_plan_models.dart';

class CustomTrainingPlanMapper {
  static List<TrainingDayPlan> toWeeklyPlan(CustomTrainingPlan plan) {
    return plan.days.asMap().entries.map((entry) {
      final index = entry.key;
      final day = entry.value;

      return TrainingDayPlan(
        dayLabel: 'Den ${index + 1}',
        focus: day.name,
        exercises: day.exercises.map((e) {
          return PlannedExercise(
            name: e.customName,
            exerciseId: e.exerciseId,
            sets: e.sets,
            reps: e.reps,
            rir: e.rir,
            note: e.note,
            weightKg: e.weightKg,
            intensityPercent: null,
            plannedSets: const [],
          );
        }).toList(),
      );
    }).toList();
  }

  static TrainingDayPlan? pickDayForDate(
    CustomTrainingPlan plan,
    DateTime date,
  ) {
    final weekly = toWeeklyPlan(plan);
    if (weekly.isEmpty) return null;

    final rawIndex = date.weekday - 1;
    final index = rawIndex % weekly.length;
    return weekly[index];
  }
}