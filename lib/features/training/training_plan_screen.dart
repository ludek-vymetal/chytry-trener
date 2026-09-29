import '../common/missing_goal_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/training/training_plan_models.dart';
import '../../l10n/app_localizations.dart';
import '../../models/coach/coach_goal.dart';
import '../../models/custom_training_plan.dart';
import '../../providers/coach/active_client_provider.dart';
import '../../providers/coach/coach_goal_controller.dart';
import '../../providers/coach/custom_training_plan_provider.dart';
import '../../providers/slot_selection_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../services/coach/coach_goal_profile_adapter.dart';
import '../../services/custom_training_plan_mapper.dart';
import '../../services/training_plan_service.dart';
import 'training_setup_screen.dart';

class TrainingPlanScreen extends ConsumerWidget {
  const TrainingPlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    final profile = ref.watch(userProfileProvider);
    final slotSelections = ref.watch(slotSelectionProvider);
    final activeClientAsync = ref.watch(activeClientIdProvider);
    final allCustomPlans = ref.watch(customTrainingPlanProvider);
    final coachGoalsAsync = ref.watch(coachGoalControllerProvider);

    final colorScheme = Theme.of(context).colorScheme;

    if (profile == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Text(l10n.setupProfileFirst),
        ),
      );
    }

    if (profile.trainingIntake == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.weeklyPlan),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.trainingSetupRequiredDescription,
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
                  child: Text(l10n.openSetup),
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
      for (final plan in allCustomPlans) {
        if (plan.clientId == activeClientId && plan.isActive) {
          activeCustomPlan = plan;
          break;
        }
      }
    }

    final coachGoals =
        coachGoalsAsync.asData?.value ?? const <CoachGoal>[];

    CoachGoal? activeCoachGoal;

    if (activeClientId != null) {
      for (final goal in coachGoals) {
        if (goal.clientId == activeClientId && !goal.isDeleted) {
          activeCoachGoal = goal;
          break;
        }
      }
    }

    final effectiveProfile = CoachGoalProfileAdapter.applyToProfile(
      profile: profile,
      coachGoal: activeCoachGoal,
    );

    if (activeCustomPlan == null && effectiveProfile.goal == null) {
      return const MissingGoalScaffold();
    }

    final List<TrainingDayPlan> basePlan =
        activeCustomPlan != null
            ? CustomTrainingPlanMapper.toWeeklyPlan(
                activeCustomPlan,
              )
            : TrainingPlanService.buildWeeklyPlan(
                effectiveProfile,
                slotSelections: slotSelections,
              );

    final bool usingCustomPlan = activeCustomPlan != null;
    final bool usingCoachGoal =
        !usingCustomPlan && activeCoachGoal != null;

    final int? overrideDayIndex =
        _resolveValidOverrideDayIndex(
      activeCustomPlan,
      basePlan.length,
    );

    final displayedPlan = _buildDisplayedPlan(
      basePlan,
      overrideDayIndex,
    );

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(l10n.weeklyPlan),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: displayedPlan.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    usingCustomPlan
                        ? l10n.customPlanEmpty
                        : l10n.planGenerationFailed,
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : ListView.builder(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.only(
                  left: 12,
                  right: 12,
                  top: 12,
                  bottom:
                      MediaQuery.of(context).viewInsets.bottom +
                          120,
                ),
                itemCount: displayedPlan.length,
                itemBuilder: (context, index) {
                  final displayedDay = displayedPlan[index];
                  final day = displayedDay.day;

                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(
                      bottom: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(18),
                      side: BorderSide(
                        color:
                            displayedDay.isOverrideSelected
                                ? colorScheme.primary
                                : colorScheme.outlineVariant,
                        width:
                            displayedDay.isOverrideSelected
                                ? 1.8
                                : 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          if (usingCustomPlan &&
                              activeCustomPlan != null)
                            Builder(
                              builder: (context) {
                                final selectedPlan =
                                    activeCustomPlan!;

                                return Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Container(
                                        margin:
                                            const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        padding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration:
                                            BoxDecoration(
                                          color: Colors.green
                                              .withValues(
                                            alpha: 0.12,
                                          ),
                                          borderRadius:
                                              BorderRadius
                                                  .circular(
                                            20,
                                          ),
                                        ),
                                        child: Text(
                                          '${l10n.customPlan}: ${selectedPlan.name}',
                                          style:
                                              const TextStyle(
                                            color:
                                                Colors.green,
                                            fontWeight:
                                                FontWeight
                                                    .bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 8,
                                    ),
                                    PopupMenuButton<
                                        String>(
                                      tooltip:
                                          l10n.dayOptions,
                                      onSelected:
                                          (value) async {
                                        if (value ==
                                            'select_other_day') {
                                          await _showDayPickerSheet(
                                            context:
                                                context,
                                            ref: ref,
                                            activePlan:
                                                selectedPlan,
                                            l10n: l10n,
                                          );
                                        }

                                        if (value ==
                                            'clear_override') {
                                          await ref
                                              .read(
                                                customTrainingPlanProvider
                                                    .notifier,
                                              )
                                              .clearOverrideDayForPlan(
                                                planId:
                                                    selectedPlan.id,
                                              );
                                        }
                                      },
                                      itemBuilder:
                                          (context) => [
                                        PopupMenuItem<
                                            String>(
                                          value:
                                              'select_other_day',
                                          child: Text(
                                            l10n.selectAnotherDay,
                                          ),
                                        ),
                                        if (overrideDayIndex !=
                                            null)
                                          PopupMenuItem<
                                              String>(
                                            value:
                                                'clear_override',
                                            child: Text(
                                              l10n.returnOriginalDay,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                );
                              },
                            ),

                          if (usingCoachGoal &&
                              activeCoachGoal != null)
                            Container(
                              margin:
                                  const EdgeInsets.only(
                                bottom: 8,
                              ),
                              padding:
                                  const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.deepOrange
                                    .withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius:
                                    BorderRadius.circular(
                                  20,
                                ),
                              ),
                              child: Text(
                                activeCoachGoal
                                            .goalDetail
                                            .trim()
                                            .isEmpty
                                    ? '${l10n.coachGoal}: ${activeCoachGoal.goalType}'
                                    : '${l10n.coachGoal}: ${activeCoachGoal.goalType} • ${activeCoachGoal.goalDetail}',
                                style:
                                    const TextStyle(
                                  color:
                                      Colors.deepOrange,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                            ),

                          Text(
                            '${day.dayLabel} – ${day.focus}',
                            style: TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                              fontSize: 17,
                              color:
                                  colorScheme.onSurface,
                            ),
                          ),

                          const SizedBox(height: 12),

                          ...day.exercises.map(
                            (exercise) => Padding(
                              padding:
                                  const EdgeInsets.only(
                                bottom: 10,
                              ),
                              child: _ExerciseCard(
                                exercise: exercise,
                                colorScheme:
                                    colorScheme,
                                l10n: l10n,
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            usingCustomPlan
                                ? l10n.trainingFormatCustom
                                : l10n.trainingFormatDefault,
                            style: TextStyle(
                              color: colorScheme
                                  .onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  int? _resolveValidOverrideDayIndex(
    CustomTrainingPlan? activeCustomPlan,
    int planLength,
  ) {
    final overrideDayIndex =
        activeCustomPlan?.overrideDayIndex;

    if (overrideDayIndex == null) {
      return null;
    }

    if (overrideDayIndex < 0 ||
        overrideDayIndex >= planLength) {
      return null;
    }

    return overrideDayIndex;
  }

  int? _defaultTodayDayIndex(int length) {
    if (length <= 0) {
      return null;
    }

    final weekday = DateTime.now().weekday;

    return (weekday - 1) % length;
  }

  List<_DisplayedTrainingDay> _buildDisplayedPlan(
    List<TrainingDayPlan> plan,
    int? overrideDayIndex,
  ) {
    final items = <_DisplayedTrainingDay>[];

    for (int i = 0; i < plan.length; i++) {
      items.add(
        _DisplayedTrainingDay(
          day: plan[i],
          originalIndex: i,
          isOverrideSelected:
              overrideDayIndex == i,
        ),
      );
    }

    if (overrideDayIndex == null) {
      return items;
    }

    items.sort((a, b) {
      if (a.isOverrideSelected &&
          !b.isOverrideSelected) {
        return -1;
      }

      if (!a.isOverrideSelected &&
          b.isOverrideSelected) {
        return 1;
      }

      return a.originalIndex.compareTo(
        b.originalIndex,
      );
    });

    return items;
  }

  Future<void> _showDayPickerSheet({
    required BuildContext context,
    required WidgetRef ref,
    required CustomTrainingPlan activePlan,
    required AppLocalizations l10n,
  }) async {
    if (activePlan.days.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.planHasNoDays,
          ),
        ),
      );

      return;
    }

    final selectedIndex =
        await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final colorScheme =
            Theme.of(context).colorScheme;

        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.fromLTRB(
              16,
              8,
              16,
              16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.pickDifferentTrainingDay,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  l10n.originalDaysStaySaved,
                  style: TextStyle(
                    color: colorScheme
                        .onSurfaceVariant,
                  ),
                ),

                const SizedBox(height: 16),

                ...List.generate(
                  activePlan.days.length,
                  (index) {
                    final day =
                        activePlan.days[index];

                    final isSelected =
                        activePlan
                                .overrideDayIndex ==
                            index;

                    return ListTile(
                      contentPadding:
                          EdgeInsets.zero,
                      leading: CircleAvatar(
                        child: Text(
                          '${index + 1}',
                        ),
                      ),
                      title: Text(day.name),
                      subtitle: Text(
                        day.exercises.isEmpty
                            ? l10n.noExercises
                            : l10n.exerciseCount(
                                day.exercises.length,
                              ),
                      ),
                      trailing: isSelected
                          ? const Icon(
                              Icons
                                  .check_circle,
                            )
                          : const Icon(
                              Icons
                                  .chevron_right,
                            ),
                      onTap: () {
                        Navigator.of(context)
                            .pop(index);
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selectedIndex == null) {
      return;
    }

    final notifier = ref.read(
      customTrainingPlanProvider.notifier,
    );

    await notifier.setOverrideDayForPlan(
      planId: activePlan.id,
      dayIndex: selectedIndex,
      originalDayIndex:
          _defaultTodayDayIndex(
        activePlan.days.length,
      ),
    );
  }
}

class _DisplayedTrainingDay {
  final TrainingDayPlan day;
  final int originalIndex;
  final bool isOverrideSelected;

  const _DisplayedTrainingDay({
    required this.day,
    required this.originalIndex,
    required this.isOverrideSelected,
  });
}

class _ExerciseCard extends StatelessWidget {
  final PlannedExercise exercise;
  final ColorScheme colorScheme;
  final AppLocalizations l10n;

  const _ExerciseCard({
    required this.exercise,
    required this.colorScheme,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final hasWeight =
        exercise.weightKg != null;

    final hasNote =
        exercise.note != null &&
            exercise.note!.trim().isNotEmpty;

    final isMainLift =
        _isMainLift(exercise.name);

    final isSpecial =
        _isSpecialExercise(exercise);

    final cardBackground = isMainLift
        ? colorScheme.primaryContainer
            .withValues(alpha: 0.45)
        : isSpecial
            ? colorScheme.tertiaryContainer
                .withValues(alpha: 0.35)
            : colorScheme
                .surfaceContainerHighest
                .withValues(alpha: 0.35);

    final borderColor = isMainLift
        ? colorScheme.primary
            .withValues(alpha: 0.45)
        : isSpecial
            ? colorScheme.tertiary
                .withValues(alpha: 0.35)
            : colorScheme.outlineVariant;

    final weightText = hasWeight
        ? '${exercise.weightKg!.toStringAsFixed(1)} kg'
        : '—';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Text(
                exercise.name,
                style: TextStyle(
                  fontWeight: isMainLift
                      ? FontWeight.w800
                      : FontWeight.w600,
                  fontSize:
                      isMainLift ? 15.5 : 14.5,
                ),
              ),

              if (isMainLift)
                _MiniBadge(
                  label: l10n.mainLift,
                  background:
                      colorScheme.primary,
                  foreground:
                      colorScheme.onPrimary,
                ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _MetricBox(
                  label: l10n.sets,
                  value: exercise.sets,
                ),
              ),
              const SizedBox(width: 8),

              Expanded(
                child: _MetricBox(
                  label: l10n.reps,
                  value: exercise.reps,
                ),
              ),
              const SizedBox(width: 8),

              Expanded(
                child: _MetricBox(
                  label: l10n.rir,
                  value: exercise.rir,
                ),
              ),
              const SizedBox(width: 8),

              Expanded(
                child: _MetricBox(
                  label: l10n.weightLabel,
                  value: weightText,
                  emphasize: hasWeight,
                ),
              ),
            ],
          ),

          if (hasNote) ...[
            const SizedBox(height: 10),
            Text(
              exercise.note!,
              style: TextStyle(
                color: colorScheme
                    .onSurfaceVariant,
                fontSize: 12.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  bool _isMainLift(String name) {
    final n = name.toLowerCase();

    return n.contains('dřep') ||
        n.contains('bench') ||
        n.contains('mrtvý tah') ||
        n.contains('deadlift');
  }

  bool _isSpecialExercise(
    PlannedExercise exercise,
  ) {
    final text =
        '${exercise.name} ${exercise.note ?? ''}'
            .toLowerCase();

    return text.contains('peak') ||
        text.contains('cns') ||
        text.contains('taper');
  }
}

class _MetricBox extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasize;

  const _MetricBox({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: emphasize
            ? colorScheme.secondaryContainer
                .withValues(alpha: 0.75)
            : colorScheme.surface,
        borderRadius:
            BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: colorScheme
                  .onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize:
                  emphasize ? 14 : 13,
              fontWeight: emphasize
                  ? FontWeight.w800
                  : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;

  const _MiniBadge({
    required this.label,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius:
            BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}