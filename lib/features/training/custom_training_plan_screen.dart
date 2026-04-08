import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/custom_training_plan.dart';
import '../../providers/coach/active_client_provider.dart';
import '../../providers/coach/custom_training_plan_provider.dart';
import '../../core/training/exercises/exercise.dart';
import '../../core/training/exercises/exercise_db.dart';

class CustomTrainingPlanScreen extends ConsumerWidget {
  const CustomTrainingPlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeClientAsync = ref.watch(activeClientIdProvider);
    final allPlans = ref.watch(customTrainingPlanProvider);

    return activeClientAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Vlastní trénink')),
        body: Center(child: Text('Chyba: $e')),
      ),
      data: (clientId) {
        if (clientId == null || clientId.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Vlastní trénink')),
            body: const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Nejdřív vyber aktivního klienta v trenérském módu. '
                  'Bez aktivního klienta nejde vlastní plán uložit.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        final clientPlans =
            allPlans.where((p) => p.clientId == clientId).toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Vlastní trénink'),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _createPlanDialog(context, ref, clientId),
            icon: const Icon(Icons.add),
            label: const Text('Nový plán'),
          ),
          body: clientPlans.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Zatím nemáš žádný vlastní plán.\n\n'
                      'Klikni na „Nový plán“ a vytvoř první.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    for (final plan in clientPlans) _PlanCard(plan: plan),
                    const SizedBox(height: 80),
                  ],
                ),
        );
      },
    );
  }

  Future<void> _createPlanDialog(
    BuildContext context,
    WidgetRef ref,
    String clientId,
  ) async {
    final ctrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nový plán'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Název plánu',
            hintText: 'Např. Hrudník + triceps',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Zrušit'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Vytvořit'),
          ),
        ],
      ),
    );

    if (ok == true && ctrl.text.trim().isNotEmpty) {
      await ref.read(customTrainingPlanProvider.notifier).createPlan(
            clientId: clientId,
            name: ctrl.text.trim(),
          );
    }
  }
}

class _PlanCard extends ConsumerWidget {
  final CustomTrainingPlan plan;

  const _PlanCard({required this.plan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: ExpansionTile(
        initiallyExpanded: plan.isActive,
        title: Row(
          children: [
            Expanded(
              child: Text(
                plan.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (plan.isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Aktivní',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Text('Počet dnů: ${plan.days.length}'),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ref.read(customTrainingPlanProvider.notifier).setActivePlan(
                          clientId: plan.clientId,
                          planId: plan.id,
                        );
                  },
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Nastavit aktivní'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _addDayDialog(context, ref, plan),
                  icon: const Icon(Icons.add),
                  label: const Text('Přidat den'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (plan.days.isEmpty)
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Tento plán zatím nemá žádné dny.'),
            )
          else
            Column(
              children: [
                for (int dayIndex = 0; dayIndex < plan.days.length; dayIndex++)
                  _DayCard(
                    plan: plan,
                    dayIndex: dayIndex,
                  ),
              ],
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ref.read(customTrainingPlanProvider.notifier).duplicatePlan(
                          sourcePlanId: plan.id,
                          newName: '${plan.name} (kopie)',
                        );
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('Duplikovat'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _confirmDeletePlan(context, ref),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Smazat'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeletePlan(BuildContext context, WidgetRef ref) async {
    final first = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Opravdu odstranit plán?'),
        content: Text('Chceš odstranit plán „${plan.name}“?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Ne'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Ano'),
          ),
        ],
      ),
    );

    if (first != true) return;
    if (!context.mounted) return;

    final second = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Vážně odstranit?'),
        content: const Text(
          'Tato akce smaže celý plán včetně všech dnů a cviků. '
          'Tuhle změnu nepůjde vrátit.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Zpět'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Definitivně smazat'),
          ),
        ],
      ),
    );

    if (second == true) {
      await ref.read(customTrainingPlanProvider.notifier).deletePlan(plan.id);
    }
  }

  Future<void> _addDayDialog(
    BuildContext context,
    WidgetRef ref,
    CustomTrainingPlan plan,
  ) async {
    final ctrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Přidat tréninkový den'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Název dne',
            hintText: 'Např. Hrudník + triceps',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Zrušit'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Přidat'),
          ),
        ],
      ),
    );

    if (ok == true && ctrl.text.trim().isNotEmpty) {
      await ref.read(customTrainingPlanProvider.notifier).addDay(
            planId: plan.id,
            dayName: ctrl.text.trim(),
          );
    }
  }
}

class _DayCard extends ConsumerWidget {
  final CustomTrainingPlan plan;
  final int dayIndex;

  const _DayCard({
    required this.plan,
    required this.dayIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final day = plan.days[dayIndex];

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      child: ExpansionTile(
        title: Text(day.name),
        subtitle: Text('Cviků: ${day.exercises.length}'),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showAddExerciseOptions(
                    context,
                    ref,
                    plan.id,
                    dayIndex,
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Přidat cvik'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _confirmDeleteDay(context, ref),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Smazat den'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (day.exercises.isEmpty)
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Zatím bez cviků.'),
            )
          else
            Column(
              children: [
                for (int i = 0; i < day.exercises.length; i++)
                  _ExerciseTile(
                    planId: plan.id,
                    dayIndex: dayIndex,
                    exerciseIndex: i,
                    exercise: day.exercises[i],
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteDay(BuildContext context, WidgetRef ref) async {
    final first = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Opravdu odstranit den?'),
        content: Text('Chceš smazat den „${plan.days[dayIndex].name}“?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Ne'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Ano'),
          ),
        ],
      ),
    );

    if (first != true) return;
    if (!context.mounted) return;

    final second = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Vážně odstranit den?'),
        content: const Text(
          'Smažou se i všechny cviky v tomto dni. '
          'Tuhle změnu nepůjde vrátit.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Zpět'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Definitivně smazat'),
          ),
        ],
      ),
    );

    if (second == true) {
      await ref.read(customTrainingPlanProvider.notifier).removeDay(
            planId: plan.id,
            dayIndex: dayIndex,
          );
    }
  }

  Future<void> _showAddExerciseOptions(
    BuildContext context,
    WidgetRef ref,
    String planId,
    int dayIndex,
  ) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.fitness_center),
              title: const Text('Vybrat z databáze cviků'),
              onTap: () => Navigator.pop(sheetContext, 'db'),
            ),
            ListTile(
              leading: const Icon(Icons.edit_note),
              title: const Text('Zadat vlastní cvik ručně'),
              onTap: () => Navigator.pop(sheetContext, 'custom'),
            ),
          ],
        ),
      ),
    );

    if (!context.mounted) return;

    if (choice == 'db') {
      await _addExerciseFromDatabaseDialog(context, ref, planId, dayIndex);
    } else if (choice == 'custom') {
      await _addCustomExerciseDialog(context, ref, planId, dayIndex);
    }
  }

  Future<void> _addExerciseFromDatabaseDialog(
    BuildContext context,
    WidgetRef ref,
    String planId,
    int dayIndex,
  ) async {
    final Exercise? selected = await Navigator.push<Exercise>(
      context,
      MaterialPageRoute(
        builder: (_) => const _ExerciseDatabasePickerScreen(),
      ),
    );

    if (selected == null) return;
    if (!context.mounted) return;

    final setsCtrl = TextEditingController(text: '3');
    final repsCtrl = TextEditingController(text: '8–12');
    final rirCtrl = TextEditingController(text: '2');
    final noteCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(selected.displayName),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: setsCtrl,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Série',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: repsCtrl,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Opakování / čas',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: rirCtrl,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'RIR',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: noteCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Poznámka',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Zrušit'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Přidat'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await ref.read(customTrainingPlanProvider.notifier).addExerciseToDay(
            planId: planId,
            dayIndex: dayIndex,
            exercise: CustomTrainingExercise(
              exerciseId: selected.id,
              customName: selected.displayName,
              sets: setsCtrl.text.trim().isEmpty ? '3' : setsCtrl.text.trim(),
              reps: repsCtrl.text.trim().isEmpty ? '8–12' : repsCtrl.text.trim(),
              rir: rirCtrl.text.trim().isEmpty ? '2' : rirCtrl.text.trim(),
              note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
            ),
          );
    }
  }

  Future<void> _addCustomExerciseDialog(
    BuildContext context,
    WidgetRef ref,
    String planId,
    int dayIndex,
  ) async {
    final nameCtrl = TextEditingController();
    final setsCtrl = TextEditingController(text: '3');
    final repsCtrl = TextEditingController(text: '8–12');
    final rirCtrl = TextEditingController(text: '2');
    final noteCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Přidat vlastní cvik'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Název cviku',
                  hintText: 'Např. Plank na boku',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: setsCtrl,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Série',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: repsCtrl,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Opakování / čas',
                  hintText: 'Např. 3 min nebo 8–12',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: rirCtrl,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'RIR',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: noteCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Poznámka',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Zrušit'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Přidat'),
          ),
        ],
      ),
    );

    if (ok == true && nameCtrl.text.trim().isNotEmpty) {
      await ref.read(customTrainingPlanProvider.notifier).addExerciseToDay(
            planId: planId,
            dayIndex: dayIndex,
            exercise: CustomTrainingExercise(
              exerciseId: null,
              customName: nameCtrl.text.trim(),
              sets: setsCtrl.text.trim().isEmpty ? '3' : setsCtrl.text.trim(),
              reps: repsCtrl.text.trim().isEmpty ? '8–12' : repsCtrl.text.trim(),
              rir: rirCtrl.text.trim().isEmpty ? '2' : rirCtrl.text.trim(),
              note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
            ),
          );
    }
  }
}

class _ExerciseTile extends ConsumerWidget {
  final String planId;
  final int dayIndex;
  final int exerciseIndex;
  final CustomTrainingExercise exercise;

  const _ExerciseTile({
    required this.planId,
    required this.dayIndex,
    required this.exerciseIndex,
    required this.exercise,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(exercise.customName),
        subtitle: Text(
          '${exercise.sets} × ${exercise.reps} | RIR ${exercise.rir}'
          '${exercise.note != null ? '\n${exercise.note}' : ''}',
        ),
        onTap: () => _editExerciseDialog(context, ref),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () => _confirmDeleteExercise(context, ref),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteExercise(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Odstranit cvik?'),
        content: Text('Chceš odstranit cvik „${exercise.customName}“?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Ne'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Ano, smazat'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await ref.read(customTrainingPlanProvider.notifier).removeExerciseFromDay(
            planId: planId,
            dayIndex: dayIndex,
            exerciseIndex: exerciseIndex,
          );
    }
  }

  Future<void> _editExerciseDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final nameCtrl = TextEditingController(text: exercise.customName);
    final setsCtrl = TextEditingController(text: exercise.sets);
    final repsCtrl = TextEditingController(text: exercise.reps);
    final rirCtrl = TextEditingController(text: exercise.rir);
    final noteCtrl = TextEditingController(text: exercise.note ?? '');

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Upravit cvik'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Název cviku',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: setsCtrl,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Série',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: repsCtrl,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Opakování / čas',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: rirCtrl,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'RIR',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: noteCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Poznámka',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Zrušit'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Uložit'),
          ),
        ],
      ),
    );

    if (ok == true && nameCtrl.text.trim().isNotEmpty) {
      await ref.read(customTrainingPlanProvider.notifier).updateExerciseInDay(
            planId: planId,
            dayIndex: dayIndex,
            exerciseIndex: exerciseIndex,
            exercise: CustomTrainingExercise(
              exerciseId: exercise.exerciseId,
              customName: nameCtrl.text.trim(),
              sets: setsCtrl.text.trim().isEmpty ? '3' : setsCtrl.text.trim(),
              reps: repsCtrl.text.trim().isEmpty ? '8–12' : repsCtrl.text.trim(),
              rir: rirCtrl.text.trim().isEmpty ? '2' : rirCtrl.text.trim(),
              note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
            ),
          );
    }
  }
}

class _ExerciseDatabasePickerScreen extends StatefulWidget {
  const _ExerciseDatabasePickerScreen();

  @override
  State<_ExerciseDatabasePickerScreen> createState() =>
      _ExerciseDatabasePickerScreenState();
}

class _ExerciseDatabasePickerScreenState
    extends State<_ExerciseDatabasePickerScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = ExerciseDB.all.where((e) {
      if (_query.trim().isEmpty) return true;
      final q = _query.trim().toLowerCase();
      return e.name.toLowerCase().contains(q) ||
          e.displayName.toLowerCase().contains(q) ||
          (e.czName?.toLowerCase().contains(q) ?? false);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vyber cvik z databáze'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: TextField(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Hledat cvik',
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text('Nenalezen žádný cvik.'),
                  )
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (_, index) {
                      final ex = filtered[index];
                      return Card(
                        child: ListTile(
                          title: Text(ex.displayName),
                          subtitle: Text(
                            'Anglicky: ${ex.name}\nVybavení: ${ex.equipment.join(', ')}',
                          ),
                          onTap: () => Navigator.pop(context, ex),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}