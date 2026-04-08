import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/coach/coach_goal.dart';
import '../../models/custom_training_plan.dart';
import '../../providers/user_profile_provider.dart';
import '../../providers/slot_selection_provider.dart';
import '../../providers/coach/active_client_provider.dart';
import '../../providers/coach/coach_goal_controller.dart';
import '../../providers/coach/custom_training_plan_provider.dart';
import '../../services/coach/coach_goal_profile_adapter.dart';
import '../../services/training_plan_service.dart';
import '../../services/custom_training_plan_mapper.dart';
import '../../core/training/training_plan_models.dart';
import 'training_setup_screen.dart';

class TrainingPlanScreen extends ConsumerWidget {
  const TrainingPlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final slotSelections = ref.watch(slotSelectionProvider);
    final activeClientAsync = ref.watch(activeClientIdProvider);
    final allCustomPlans = ref.watch(customTrainingPlanProvider);
    final coachGoalsAsync = ref.watch(coachGoalControllerProvider);

    if (profile == null) {
      return const Scaffold(
        body: Center(child: Text('Nejprve nastav profil.')),
      );
    }

    if (profile.trainingIntake == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Týdenní plán')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Než vygenerujeme plán, vyplň prosím krátké nastavení tréninku.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TrainingSetupScreen(),
                      ),
                    );
                  },
                  child: const Text('Otevřít nastavení'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final String? activeClientId = activeClientAsync.asData?.value;

    CustomTrainingPlan? activeCustomPlan;
    if (activeClientId != null) {
      for (final p in allCustomPlans) {
        if (p.clientId == activeClientId && p.isActive) {
          activeCustomPlan = p;
          break;
        }
      }
    }

    CoachGoal? activeCoachGoal;
    final coachGoals = coachGoalsAsync.asData?.value ?? const <CoachGoal>[];
    if (activeClientId != null) {
      for (final g in coachGoals) {
        if (g.clientId == activeClientId && !g.isDeleted) {
          activeCoachGoal = g;
          break;
        }
      }
    }

    final effectiveProfile = CoachGoalProfileAdapter.applyToProfile(
      profile: profile,
      coachGoal: activeCoachGoal,
    );

    if (activeCustomPlan == null && effectiveProfile.goal == null) {
      return const Scaffold(
        body: Center(child: Text('Nejprve nastav cíl.')),
      );
    }

    final List<TrainingDayPlan> plan = activeCustomPlan != null
        ? CustomTrainingPlanMapper.toWeeklyPlan(activeCustomPlan)
        : TrainingPlanService.buildWeeklyPlan(
            effectiveProfile,
            slotSelections: slotSelections,
          );

    final bool usingCustomPlan = activeCustomPlan != null;
    final bool usingCoachGoal = !usingCustomPlan && activeCoachGoal != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Týdenní plán')),
      body: plan.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  usingCustomPlan
                      ? 'Aktivní vlastní plán zatím neobsahuje žádné dny nebo cviky.'
                      : 'Nepodařilo se vygenerovat plán.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: plan.length,
              itemBuilder: (context, index) {
                final day = plan[index];

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (usingCustomPlan)
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Vlastní plán: ${activeCustomPlan!.name}',
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        if (usingCoachGoal)
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.deepOrange.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Coach goal: ${activeCoachGoal!.goalType}'
                              '${activeCoachGoal.goalDetail.trim().isEmpty ? '' : ' • ${activeCoachGoal.goalDetail}'}',
                              style: const TextStyle(
                                color: Colors.deepOrange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        Text(
                          '${day.dayLabel} – ${day.focus}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...day.exercises.map((e) {
                          final weightText = (e.weightKg == null)
                              ? ''
                              : '${e.weightKg!.toStringAsFixed(1)} kg';

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 5, child: Text(e.name)),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    e.sets,
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    e.reps,
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    e.rir,
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    weightText,
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 8),
                        Text(
                          usingCustomPlan
                              ? 'Formát: série | opakování / čas | RIR'
                              : 'Formát: série | opakování | RIR | kg',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}