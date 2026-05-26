import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/training/exercises/exercise_db.dart';
import '../../core/training/slots/exercise_slot.dart';
import '../../core/training/training_plan_models.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/slot_selection_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../services/training_slot_plan_service.dart';
import 'exercise_picker_screen.dart';

class SlotPlanDebugScreen extends ConsumerWidget {
  const SlotPlanDebugScreen({super.key});

  String _roleLabel(
    BuildContext context,
    ExerciseRole role,
  ) {
    final l10n = AppLocalizations.of(context)!;

    switch (role) {
      case ExerciseRole.mainSquat:
        return l10n.mainSquatExercise;

      case ExerciseRole.mainPress:
        return l10n.mainPressExercise;

      case ExerciseRole.mainHinge:
        return l10n.mainHingeExercise;

      case ExerciseRole.chestPress:
        return l10n.chestPress;

      case ExerciseRole.verticalPull:
        return l10n.verticalPull;

      case ExerciseRole.horizontalPull:
        return l10n.horizontalPull;

      case ExerciseRole.quads:
        return l10n.quads;

      case ExerciseRole.hamstrings:
        return l10n.hamstrings;

      case ExerciseRole.glutes:
        return l10n.glutes;

      case ExerciseRole.shoulders:
        return l10n.shoulders;

      case ExerciseRole.triceps:
        return l10n.triceps;

      case ExerciseRole.biceps:
        return l10n.biceps;

      case ExerciseRole.core:
        return l10n.core;

      case ExerciseRole.conditioning:
        return l10n.conditioning;
    }
  }

  String _patternLabel(
    BuildContext context,
    String patternName,
  ) {
    final l10n = AppLocalizations.of(context)!;

    switch (patternName) {
      case 'squat':
        return l10n.squatPattern;

      case 'hinge':
        return l10n.hingePattern;

      case 'press':
        return l10n.pressPattern;

      case 'pull':
        return l10n.verticalPullPattern;

      case 'row':
        return l10n.horizontalRowPattern;

      case 'core':
        return l10n.corePattern;

      case 'locomotion':
        return l10n.locomotionPattern;

      default:
        return patternName;
    }
  }

  String _modalityLabel(
    BuildContext context,
    String modalityName,
  ) {
    final l10n = AppLocalizations.of(context)!;

    switch (modalityName) {
      case 'strength':
        return l10n.strength;

      case 'hypertrophy':
        return l10n.hypertrophy;

      case 'endurance':
        return l10n.endurance;

      case 'conditioning':
        return l10n.conditioning;

      default:
        return modalityName;
    }
  }

  String _slotKey(
    String dayLabel,
    int slotIndex,
  ) {
    return '$dayLabel|$slotIndex';
  }

  String? _exerciseNameById(String id) {
    try {
      return ExerciseDB.all.firstWhere((e) => e.id == id).name;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final l10n = AppLocalizations.of(context)!;

    final profile = ref.watch(userProfileProvider);

    if (profile == null || profile.goal == null) {
      return Scaffold(
        body: Center(
          child: Text(
            l10n.setupProfileAndGoalFirst,
          ),
        ),
      );
    }

    if (profile.trainingIntake == null) {
      return Scaffold(
        body: Center(
          child: Text(
            l10n.trainingQuestionnaireMissing,
          ),
        ),
      );
    }

    final selectedMap = ref.watch(slotSelectionProvider);

    final equipment = profile.trainingIntake!.equipment;

    final List<SlotTrainingDayPlan> plan =
        TrainingSlotPlanService.buildWeeklySlotPlan(profile);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.exerciseSelectionTest,
        ),
      ),

      body: ListView.builder(
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
                  Text(
                    '${day.dayLabel} – ${day.focus}',

                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  ...day.slots.asMap().entries.map((entry) {
                    final slotIndex = entry.key;

                    final s = entry.value;

                    final key = _slotKey(
                      day.dayLabel,
                      slotIndex,
                    );

                    final selectedExerciseId =
                        selectedMap[key];

                    final selectedName =
                        selectedExerciseId == null
                            ? null
                            : _exerciseNameById(
                                selectedExerciseId,
                              );

                    final modalityText = s.modalities
                        .map(
                          (m) => _modalityLabel(
                            context,
                            m.name,
                          ),
                        )
                        .join(', ');

                    return Card(
                      child: ListTile(
                        title: Text(
                          _roleLabel(
                            context,
                            s.role,
                          ),
                        ),

                        subtitle: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,

                          children: [
                            const SizedBox(height: 4),

                            Text(
                              '${l10n.movementType}: '
                              '${_patternLabel(context, s.pattern.name)}',
                            ),

                            Text(
                              '${l10n.focus}: $modalityText',
                            ),

                            const SizedBox(height: 6),

                            Text(
                              '${l10n.prescription}: '
                              '${s.sets} × ${s.reps} | '
                              'RIR ${s.rir}',
                            ),

                            const SizedBox(height: 6),

                            Text(
                              selectedName == null
                                  ? l10n.noExerciseSelected
                                  : '${l10n.selectedExercise}: $selectedName',

                              style: TextStyle(
                                fontWeight:
                                    selectedName == null
                                        ? FontWeight.normal
                                        : FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        trailing: const Icon(Icons.edit),

                        onTap: () async {
                          final chosen =
                              await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ExercisePickerScreen(
                                slot: s,
                                availableEquipment:
                                    equipment,
                                preselectedExerciseId:
                                    selectedExerciseId,
                              ),
                            ),
                          );

                          if (chosen != null) {
                            ref
                                .read(
                                  slotSelectionProvider
                                      .notifier,
                                )
                                .setSelection(
                                  key,
                                  chosen.id,
                                );
                          }
                        },
                      ),
                    );
                  }),

                  const SizedBox(height: 8),

                  Text(
                    l10n.slotDebugDescription,

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