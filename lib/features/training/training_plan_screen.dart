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
    final colorScheme = Theme.of(context).colorScheme;

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

    final List<TrainingDayPlan> basePlan = activeCustomPlan != null
        ? CustomTrainingPlanMapper.toWeeklyPlan(activeCustomPlan)
        : TrainingPlanService.buildWeeklyPlan(
            effectiveProfile,
            slotSelections: slotSelections,
          );

    final bool usingCustomPlan = activeCustomPlan != null;
    final bool usingCoachGoal = !usingCustomPlan && activeCoachGoal != null;

    final int? overrideDayIndex =
        _resolveValidOverrideDayIndex(activeCustomPlan, basePlan.length);

    final List<_DisplayedTrainingDay> displayedPlan =
        _buildDisplayedPlan(basePlan, overrideDayIndex);

    return Scaffold(
      appBar: AppBar(title: const Text('Týdenní plán')),
      body: displayedPlan.isEmpty
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
              itemCount: displayedPlan.length,
              itemBuilder: (context, index) {
                final displayedDay = displayedPlan[index];
                final day = displayedDay.day;
                final isSpecialDay = _isSpecialDay(day);

                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: BorderSide(
                      color: displayedDay.isOverrideSelected
                          ? colorScheme.primary
                          : isSpecialDay
                              ? colorScheme.primary
                              : colorScheme.outlineVariant,
                      width: displayedDay.isOverrideSelected
                          ? 1.8
                          : isSpecialDay
                              ? 1.4
                              : 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (usingCustomPlan && activeCustomPlan != null)
                          Builder(
                            builder: (context) {
                              final selectedPlan = activeCustomPlan!;

                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            Colors.green.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        'Vlastní plán: ${selectedPlan.name}',
                                        style: const TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  PopupMenuButton<String>(
                                    tooltip: 'Možnosti dne',
                                    onSelected: (value) async {
                                      if (value == 'select_other_day') {
                                        await _showDayPickerSheet(
                                          context: context,
                                          ref: ref,
                                          activePlan: selectedPlan,
                                        );
                                      } else if (value == 'clear_override') {
                                        await ref
                                            .read(
                                              customTrainingPlanProvider
                                                  .notifier,
                                            )
                                            .clearOverrideDayForPlan(
                                              planId: selectedPlan.id,
                                            );
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem<String>(
                                        value: 'select_other_day',
                                        child: Text('Vybrat jiný den'),
                                      ),
                                      if (overrideDayIndex != null)
                                        const PopupMenuItem<String>(
                                          value: 'clear_override',
                                          child: Text('Vrátit původní den'),
                                        ),
                                    ],
                                  ),
                                ],
                              );
                            },
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
                        if (usingCustomPlan && overrideDayIndex != null) ...[
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer
                                  .withValues(alpha: 0.75),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              displayedDay.isOverrideSelected
                                  ? 'Dočasně zvolený den pro dnešní trénink'
                                  : 'Níže je původní pořadí plánu, ale pro dnešek máš dočasně vybraný jiný den.',
                              style: TextStyle(
                                color: colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                '${day.dayLabel} – ${day.focus}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ),
                            if (displayedDay.isOverrideSelected)
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: _DayBadge(
                                  label: 'DNES ZVOLENO',
                                  background: colorScheme.primaryContainer,
                                  foreground: colorScheme.onPrimaryContainer,
                                ),
                              ),
                            if (_isPeakDay(day))
                              Padding(
                                padding: EdgeInsets.only(
                                  left: displayedDay.isOverrideSelected ? 8 : 0,
                                ),
                                child: _DayBadge(
                                  label: 'PEAK / CNS',
                                  background: colorScheme.tertiaryContainer,
                                  foreground: colorScheme.onTertiaryContainer,
                                ),
                              ),
                            if (_isTaperDay(day))
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: _DayBadge(
                                  label: 'TAPER',
                                  background: colorScheme.secondaryContainer,
                                  foreground: colorScheme.onSecondaryContainer,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...day.exercises.map(
                          (exercise) => _ExerciseCard(
                            exercise: exercise,
                            colorScheme: colorScheme,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          usingCustomPlan
                              ? 'Formát: série | opakování / čas | RIR'
                              : 'Formát: série | opakování | RIR | kg',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
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

  int? _resolveValidOverrideDayIndex(
    CustomTrainingPlan? activeCustomPlan,
    int planLength,
  ) {
    final overrideDayIndex = activeCustomPlan?.overrideDayIndex;
    if (overrideDayIndex == null) return null;
    if (overrideDayIndex < 0 || overrideDayIndex >= planLength) return null;
    return overrideDayIndex;
  }

  int? _defaultTodayDayIndex(int length) {
    if (length <= 0) return null;
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
          isOverrideSelected: overrideDayIndex == i,
        ),
      );
    }

    if (overrideDayIndex == null) {
      return items;
    }

    items.sort((a, b) {
      if (a.isOverrideSelected && !b.isOverrideSelected) return -1;
      if (!a.isOverrideSelected && b.isOverrideSelected) return 1;
      return a.originalIndex.compareTo(b.originalIndex);
    });

    return items;
  }

  Future<void> _showDayPickerSheet({
    required BuildContext context,
    required WidgetRef ref,
    required CustomTrainingPlan activePlan,
  }) async {
    if (activePlan.days.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Plán zatím nemá žádné dny.'),
        ),
      );
      return;
    }

    final selectedIndex = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Vyber jiný den pro dnešní trénink',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Původní dny v plánu se nemažou. Přeskočený den se později nabídne k docvičení.',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                ...List.generate(activePlan.days.length, (index) {
                  final day = activePlan.days[index];
                  final isSelected = activePlan.overrideDayIndex == index;

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      child: Text('${index + 1}'),
                    ),
                    title: Text(day.name),
                    subtitle: Text(
                      day.exercises.isEmpty
                          ? 'Bez cviků'
                          : '${day.exercises.length} cviků',
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle)
                        : const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).pop(index);
                    },
                  );
                }),
                if (activePlan.overrideDayIndex != null) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop(-1);
                      },
                      child: const Text('Vrátit původní den'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );

    if (selectedIndex == null) return;

    final notifier = ref.read(customTrainingPlanProvider.notifier);

    if (selectedIndex == -1) {
      await notifier.clearOverrideDayForPlan(planId: activePlan.id);
      return;
    }

    await notifier.setOverrideDayForPlan(
      planId: activePlan.id,
      dayIndex: selectedIndex,
      originalDayIndex: _defaultTodayDayIndex(activePlan.days.length),
    );
  }

  bool _isSpecialDay(TrainingDayPlan day) {
    final text =
        '${day.dayLabel} ${day.focus} ${day.exercises.map((e) => e.note ?? '').join(' ')}'
            .toLowerCase();
    return text.contains('peak') ||
        text.contains('cns') ||
        text.contains('taper');
  }

  bool _isPeakDay(TrainingDayPlan day) {
    final text =
        '${day.dayLabel} ${day.focus} ${day.exercises.map((e) => e.note ?? '').join(' ')}'
            .toLowerCase();
    return text.contains('peak') || text.contains('cns');
  }

  bool _isTaperDay(TrainingDayPlan day) {
    final text =
        '${day.dayLabel} ${day.focus} ${day.exercises.map((e) => e.note ?? '').join(' ')}'
            .toLowerCase();
    return text.contains('taper');
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

  const _ExerciseCard({
    required this.exercise,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final hasWeight = exercise.weightKg != null;
    final hasNote = exercise.note != null && exercise.note!.trim().isNotEmpty;
    final isMainLift = _isMainLift(exercise.name);
    final isSpecial = _isSpecialExercise(exercise);

    final cardBackground = isMainLift
        ? colorScheme.primaryContainer.withValues(alpha: 0.45)
        : isSpecial
            ? colorScheme.tertiaryContainer.withValues(alpha: 0.35)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.35);

    final borderColor = isMainLift
        ? colorScheme.primary.withValues(alpha: 0.45)
        : isSpecial
            ? colorScheme.tertiary.withValues(alpha: 0.35)
            : colorScheme.outlineVariant;

    final weightText =
        hasWeight ? '${exercise.weightKg!.toStringAsFixed(1)} kg' : '—';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                exercise.name,
                style: TextStyle(
                  fontWeight: isMainLift ? FontWeight.w800 : FontWeight.w600,
                  fontSize: isMainLift ? 15.5 : 14.5,
                  color: colorScheme.onSurface,
                ),
              ),
              if (isMainLift)
                _MiniBadge(
                  label: 'HLAVNÍ LIFT',
                  background: colorScheme.primary,
                  foreground: colorScheme.onPrimary,
                ),
              if (hasWeight)
                _MiniBadge(
                  label: weightText,
                  background: colorScheme.secondaryContainer,
                  foreground: colorScheme.onSecondaryContainer,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MetricBox(
                  label: 'Série',
                  value: exercise.sets,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricBox(
                  label: 'Opakování / čas',
                  value: exercise.reps,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricBox(
                  label: 'RIR',
                  value: exercise.rir,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricBox(
                  label: 'Váha',
                  value: weightText,
                  emphasize: hasWeight,
                ),
              ),
            ],
          ),
          if (hasNote) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                exercise.note!,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 12.5,
                  height: 1.35,
                ),
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
        n.contains('deadlift') ||
        n.contains('pause bench');
  }

  bool _isSpecialExercise(PlannedExercise exercise) {
    final text = '${exercise.name} ${exercise.note ?? ''}'.toLowerCase();
    return text.contains('peak') ||
        text.contains('cns') ||
        text.contains('taper') ||
        text.contains('training max') ||
        text.contains('%');
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
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: emphasize
            ? colorScheme.secondaryContainer.withValues(alpha: 0.75)
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: emphasize
              ? colorScheme.secondary.withValues(alpha: 0.35)
              : colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: emphasize ? 14 : 13,
              fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
              color: colorScheme.onSurface,
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
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

class _DayBadge extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;

  const _DayBadge({
    required this.label,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
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