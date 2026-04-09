import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/training/progression/progression_decision.dart';
import '../../core/training/progression/progression_service.dart';
import '../../core/training/sessions/training_session.dart';
import '../../models/custom_training_plan.dart';
import '../../providers/coach/active_client_provider.dart';
import '../../providers/coach/custom_training_plan_provider.dart';
import '../../providers/slot_selection_provider.dart';
import '../../providers/training_session_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../services/custom_training_plan_mapper.dart';
import '../../services/today_training_service.dart';
import 'log_training_screen.dart' as bulk;
import 'training_log_screen.dart' as per_ex;
import 'training_setup_screen.dart';

class TodayTrainingScreen extends ConsumerWidget {
  const TodayTrainingScreen({super.key});

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<int?> _pickExerciseIndex(BuildContext context, List<String> names) {
    return showModalBottomSheet<int>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView.builder(
            itemCount: names.length,
            itemBuilder: (_, i) => ListTile(
              title: Text(names[i]),
              onTap: () => Navigator.pop(sheetContext, i),
            ),
          ),
        );
      },
    );
  }

  String _decisionMessage(ProgressDecision decision) {
    final next = decision.nextWeightKg;
    final delta = decision.deltaKg;

    switch (decision.action) {
      case ProgressAction.increase:
        if (next != null && delta != null) {
          return '${decision.reason} Příště: ${next.toStringAsFixed(1)} kg (${delta > 0 ? '+' : ''}${delta.toStringAsFixed(1)} kg)';
        }
        return decision.reason;

      case ProgressAction.keep:
        if (next != null) {
          return '${decision.reason} Příště drž ${next.toStringAsFixed(1)} kg.';
        }
        return decision.reason;

      case ProgressAction.noData:
        return decision.reason;
    }
  }

  String _inlineRecommendationText(ProgressDecision decision) {
    final next = decision.nextWeightKg;
    final delta = decision.deltaKg;

    switch (decision.action) {
      case ProgressAction.increase:
        if (next != null && delta != null) {
          return '➡️ Příště: ${next.toStringAsFixed(1)} kg (${delta > 0 ? '+' : ''}${delta.toStringAsFixed(1)} kg)';
        }
        return '➡️ ${decision.reason}';

      case ProgressAction.keep:
        if (next != null) {
          return '➡️ Příště drž ${next.toStringAsFixed(1)} kg';
        }
        return '➡️ ${decision.reason}';

      case ProgressAction.noData:
        return '➡️ ${decision.reason}';
    }
  }

  Color _recommendationColor(BuildContext context, ProgressDecision decision) {
    final colorScheme = Theme.of(context).colorScheme;

    switch (decision.action) {
      case ProgressAction.increase:
        return colorScheme.primary;
      case ProgressAction.keep:
        return colorScheme.tertiary;
      case ProgressAction.noData:
        return colorScheme.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final profile = ref.watch(userProfileProvider);
    final slotSelections = ref.watch(slotSelectionProvider);
    final activeClientAsync = ref.watch(activeClientIdProvider);
    final allCustomPlans = ref.watch(customTrainingPlanProvider);

    if (profile == null || profile.goal == null) {
      return const Scaffold(
        body: Center(child: Text('Nejprve nastav profil a cíl.')),
      );
    }

    if (profile.trainingIntake == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Dnešní trénink')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Než vygenerujeme dnešní trénink, vyplň prosím krátké nastavení.',
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
                      child: const Text('Otevřít nastavení tréninku'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final history = ref.watch(trainingSessionProvider);
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

    final today = DateTime.now();

    TrainingSession? session;

    if (activeCustomPlan != null) {
      final customDay =
          CustomTrainingPlanMapper.pickDayForDate(activeCustomPlan, today);

      if (customDay != null) {
        session = TrainingSession(
          date: today,
          dayPlan: customDay,
          entries: const [],
          completed: false,
        );
      }
    } else {
      session = TodayTrainingService.buildTodaySession(
        profile,
        today,
        history: history,
        slotSelections: slotSelections,
      );
    }

    if (session == null) {
      return const Scaffold(
        body: Center(child: Text('Nepodařilo se vygenerovat dnešní trénink.')),
      );
    }

    final todaySession = session;
    final day = todaySession.dayPlan;

    final sessions = ref.watch(trainingSessionProvider);
    TrainingSession? storedSession;
    for (final s in sessions) {
      if (_sameDay(s.date, todaySession.date)) {
        storedSession = s;
        break;
      }
    }

    final usingCustomPlan = activeCustomPlan != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Dnešní trénink')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
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
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Vlastní plán: ${activeCustomPlan.name}',
                        style: TextStyle(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  Text(
                    '${day.dayLabel} – ${day.focus}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Datum: ${todaySession.date.day}.${todaySession.date.month}.${todaySession.date.year}',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          ...day.exercises.asMap().entries.map((entry) {
            final i = entry.key;
            final e = entry.value;

            final exerciseKey = e.exerciseId ?? e.name;

            final isLogged =
                storedSession?.entries.any((x) => x.exerciseKey == exerciseKey) ??
                    false;

            final weightText =
                e.weightKg == null ? null : '${e.weightKg!.toStringAsFixed(1)} kg';

            final decision = ProgressionService.decideNextWeight(
              profile: profile,
              planned: e,
              history: history,
            );

            return Card(
              child: ListTile(
                title: Text(
                  e.name,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${e.sets} × ${e.reps} | RIR ${e.rir}',
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _inlineRecommendationText(decision),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _recommendationColor(context, decision),
                      ),
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (weightText != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: Text(
                          weightText,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                    if (isLogged)
                      Icon(Icons.check_circle, color: colorScheme.primary)
                    else
                      TextButton(
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final navigator = Navigator.of(context);
                          final ex = todaySession.dayPlan.exercises[i];

                          final result = await navigator.push(
                            MaterialPageRoute(
                              builder: (_) => per_ex.TrainingLogScreen(
                                todaySession: todaySession,
                                exercise: ex,
                              ),
                            ),
                          );

                          if (!context.mounted) return;

                          if (result is ProgressDecision) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(_decisionMessage(result)),
                                backgroundColor: colorScheme.primary,
                              ),
                            );
                          } else if (result == true) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: const Text('Výkon uložen.'),
                                backgroundColor: colorScheme.primary,
                              ),
                            );
                          }
                        },
                        child: const Text('Log'),
                      ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
          Text(
            usingCustomPlan
                ? 'Formát: série × opakování / čas | RIR'
                : 'Formát: série × opakování | RIR | kg',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: day.exercises.isEmpty
                  ? null
                  : () async {
                      final navigator = Navigator.of(context);

                      final idx = await _pickExerciseIndex(
                        context,
                        day.exercises.map((e) => e.name).toList(),
                      );
                      if (idx == null) return;
                      if (!context.mounted) return;

                      final selected = day.exercises[idx];

                      await navigator.push(
                        MaterialPageRoute(
                          builder: (_) => bulk.BulkLogTrainingScreen(
                            todaySession: todaySession,
                            exercise: selected,
                          ),
                        ),
                      );
                    },
              child: const Text('Zapsat výkon'),
            ),
          ),
        ],
      ),
    );
  }
}