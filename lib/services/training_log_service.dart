import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/training/actual_set.dart';
import '../core/training/progression/progression_decision.dart';
import '../core/training/progression/progression_service.dart';
import '../core/training/sessions/exercise_log_entry.dart';
import '../core/training/sessions/training_session.dart';
import '../core/training/training_plan_models.dart';
import '../core/training/training_set.dart';
import '../models/exercise_performance.dart';
import '../providers/coach/active_client_provider.dart';
import '../providers/coach/custom_training_plan_provider.dart';
import '../providers/performance_provider.dart';
import '../providers/training_session_provider.dart';
import '../providers/user_profile_provider.dart';

class TrainingLogService {
  static ProgressDecision? saveExerciseLog({
    required WidgetRef ref,
    required TrainingSession todayBaseSession,
    required String exerciseKey,
    required List<PlannedSet> plannedSets,
    required List<ActualSet> actualSets,
  }) {
    final date = todayBaseSession.date;
    final clientId = ref.read(activeClientIdProvider).value;

    ref.read(trainingSessionProvider.notifier).upsertEntry(
          date: date,
          baseSession: todayBaseSession,
          entry: ExerciseLogEntry(
            exerciseKey: exerciseKey,
            plannedSets: plannedSets,
            actualSets: actualSets,
          ),
        );

    ref.read(trainingSessionProvider.notifier).setCompletedIfAllLogged(
          date: date,
          baseSession: todayBaseSession,
        );

    final top = _pickTopSet(actualSets);

    if (top != null && top.weightKg != null) {
      ref.read(performanceProvider.notifier).addPerformance(
            ExercisePerformance(
              exerciseName: exerciseKey,
              date: date,
              weight: top.weightKg!,
              reps: top.reps,
              clientId: clientId,
            ),
          );

      if (clientId != null && clientId.trim().isNotEmpty) {
        ref.read(customTrainingPlanProvider.notifier).updateLastUsedWeightForActivePlan(
              clientId: clientId,
              dayName: todayBaseSession.dayPlan.focus,
              exerciseKey: exerciseKey,
              weightKg: top.weightKg!,
            );
      }
    }

    final profile = ref.read(userProfileProvider);
    if (profile == null) {
      return null;
    }

    PlannedExercise? plannedExercise;
    for (final e in todayBaseSession.dayPlan.exercises) {
      final key = e.exerciseId ?? e.name;
      if (key == exerciseKey) {
        plannedExercise = e;
        break;
      }
    }

    if (plannedExercise == null) {
      return null;
    }

    final history = ref.read(trainingSessionProvider);

    return ProgressionService.decideNextWeight(
      profile: profile,
      planned: plannedExercise,
      history: history,
    );
  }

  static ActualSet? _pickTopSet(List<ActualSet> sets) {
    ActualSet? best;
    double bestScore = -1;

    for (final s in sets) {
      final w = s.weightKg ?? 0;
      final r = s.reps;

      if (w <= 0 || r <= 0) {
        continue;
      }

      final score = w * 1000 + r;

      if (score > bestScore) {
        bestScore = score;
        best = s;
      }
    }

    return best;
  }
}