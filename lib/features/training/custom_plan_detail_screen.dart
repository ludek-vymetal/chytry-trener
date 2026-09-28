part of 'custom_training_plan_screen.dart';

// Detail vlastního plánu – dny, cviky, výběr cviku z databáze.

/// Detail a úpravy vlastního tréninkového plánu (dny, cviky).
class CustomPlanDetailScreen extends ConsumerWidget {
  final String planId;

  const CustomPlanDetailScreen({
    super.key,
    required this.planId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    final allPlans = ref.watch(customTrainingPlanProvider);

    CustomTrainingPlan? plan;

    for (final p in allPlans) {
      if (p.id == planId) {
        plan = p;
        break;
      }
    }

    if (plan == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.planDetail),
        ),
        body: Center(
          child: Text(l10n.planNotFound),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(plan.name),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '${l10n.category}: ${_categoryLabel(context, plan.category)}\n'
                '${l10n.description}: ${plan.description ?? l10n.noDescription}\n'
                '${l10n.numberOfDays}: ${plan.days.length}',
              ),
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () async {
                    await ref
                        .read(customTrainingPlanProvider.notifier)
                        .setActivePlan(
                          clientId: plan!.clientId,
                          planId: plan.id,
                        );

                    if (!context.mounted) return;

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const TrainingPlanScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: Text(l10n.activateAndOpen),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await ref
                        .read(
                          sharedTrainingTemplatesProvider
                              .notifier,
                        )
                        .addTemplateFromPlan(plan!);

                    if (!context.mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          l10n.planSavedAsTemplate(plan.name),
                        )
                      ),
                    );
                  },
                  icon: const Icon(Icons.share),
                  label: Text(l10n.shareAsTemplate),
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _editPlanMetaDialog(
                    context,
                    ref,
                    plan!,
                  ),
                  icon: const Icon(Icons.edit),
                  label: Text(l10n.editInfo),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => TrainingPlanPdfService.printPlan(
                    plan!,
                    categoryLabel: _categoryLabel(context, plan.category),
                    trialWatermark: !ref.read(accessProvider).cleanPdf,
                  ),
                  icon: const Icon(Icons.print_outlined),
                  label: const Text('Tisk'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => TrainingPlanPdfService.sharePlan(
                    plan!,
                    categoryLabel: _categoryLabel(context, plan.category),
                    trialWatermark: !ref.read(accessProvider).cleanPdf,
                  ),
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text('Uložit PDF'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _addDayDialog(
                    context,
                    ref,
                    plan!,
                  ),
                  icon: const Icon(Icons.add),
                  label: Text(l10n.addDay),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          if (plan.days.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(l10n.planHasNoDays),
              ),
            )
          else
            ...List.generate(
              plan.days.length,
              (dayIndex) => _DayCard(
                plan: plan!,
                dayIndex: dayIndex,
              ),
            ),

          const SizedBox(height: 12),

          OutlinedButton.icon(
            onPressed: () => _confirmDeletePlan(
              context,
              ref,
              plan!,
            ),
            icon: const Icon(Icons.delete_outline),
            label: Text(l10n.deleteWholePlan),
          ),
        ],
      ),
    );
  }

  Future<void> _editPlanMetaDialog(
    BuildContext context,
    WidgetRef ref,
    CustomTrainingPlan plan,
  ) async {
    final l10n = AppLocalizations.of(context)!;

    final nameCtrl = TextEditingController(
      text: plan.name,
    );

    final descriptionCtrl = TextEditingController(
      text: plan.description ?? '',
    );

    CustomTrainingCategory selectedCategory =
        plan.category;

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.editPlan),
          content: SingleChildScrollView(
            child: Column(
              children: [
                DropdownButtonFormField<CustomTrainingCategory>(
                  initialValue: selectedCategory,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: l10n.category,
                  ),
                  items: CustomTrainingCategory.values
                      .map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(
                        _categoryLabel(context, category)
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value == null) return;

                    setState(() {
                      selectedCategory = value;
                    });
                  },
                ),

                const SizedBox(height: 12),

                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: l10n.planName,
                  ),
                ),

                const SizedBox(height: 12),

                TextField(
                  controller: descriptionCtrl,
                  minLines: 2,
                  maxLines: 4,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: l10n.description,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, false),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, true),
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );

    if (ok == true && nameCtrl.text.trim().isNotEmpty) {
      await ref
          .read(customTrainingPlanProvider.notifier)
          .updatePlanMeta(
            planId: plan.id,
            name: nameCtrl.text.trim(),
            description:
                descriptionCtrl.text.trim().isEmpty
                    ? null
                    : descriptionCtrl.text.trim(),
            category: selectedCategory,
          );
    }
  }
}

  Future<void> _confirmDeletePlan(
  BuildContext context,
  WidgetRef ref,
  CustomTrainingPlan plan,
) async {
  final l10n = AppLocalizations.of(context)!;

  final first = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.reallyDeletePlan),
      content: Text(
        l10n.confirmDeletePlan(plan.name),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(l10n.no),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(l10n.yes),
        ),
      ],
    ),
  );

  if (first != true) return;
  if (!context.mounted) return;

  final second = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.confirmDeletion),
      content: Text(
        l10n.deletePlanWarning,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(l10n.back),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
          ),
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(l10n.deleteForever),
        ),
      ],
    ),
  );

  if (second == true) {
    await ref
        .read(customTrainingPlanProvider.notifier)
        .deletePlan(plan.id);

    if (!context.mounted) return;

    Navigator.pop(context);
  }
}

Future<void> _addDayDialog(
  BuildContext context,
  WidgetRef ref,
  CustomTrainingPlan plan,
) async {
  final l10n = AppLocalizations.of(context)!;
  final ctrl = TextEditingController();

  final ok = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.addTrainingDay),
      content: TextField(
        controller: ctrl,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          labelText: l10n.dayName,
          hintText: l10n.dayNameHint,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(l10n.add),
        ),
      ],
    ),
  );

  if (ok == true && ctrl.text.trim().isNotEmpty) {
    await ref
        .read(customTrainingPlanProvider.notifier)
        .addDay(
          planId: plan.id,
          dayName: ctrl.text.trim(),
        );
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
    final l10n = AppLocalizations.of(context)!;
    final day = plan.days[dayIndex];

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      child: ExpansionTile(
        title: Text(day.name),
        subtitle: Text(
          '${l10n.exercises}: ${day.exercises.length}',
        ),
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
                  label: Text(l10n.addExercise),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      _confirmDeleteDay(context, ref),
                  icon: const Icon(Icons.delete_outline),
                  label: Text(l10n.deleteDay),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteDay(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final l10n = AppLocalizations.of(context)!;

    final first = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.reallyDeleteDay),
        content: Text(
          l10n.confirmDeleteDay(plan.days[dayIndex].name),
        ),
                actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, false),
            child: Text(l10n.no),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(dialogContext, true),
            child: Text(l10n.yes),
          ),
        ],
      ),
    );

    if (first != true) return;
    if (!context.mounted) return;

    final second = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.confirmDeletion),
        content: Text(
          l10n.deleteDayWarning,
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, false),
            child: Text(l10n.back),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () =>
                Navigator.pop(dialogContext, true),
            child: Text(l10n.deleteForever),
          ),
        ],
      ),
    );

    if (second == true) {
      await ref
          .read(customTrainingPlanProvider.notifier)
          .removeDay(
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
  final l10n = AppLocalizations.of(context)!;

  final choice = await showModalBottomSheet<String>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.fitness_center),
            title: Text(l10n.selectFromExerciseDatabase),
            onTap: () => Navigator.pop(sheetContext, 'db'),
          ),
          ListTile(
            leading: const Icon(Icons.edit_note),
            title: Text(l10n.enterCustomExerciseManually),
            onTap: () => Navigator.pop(sheetContext, 'custom'),
          ),
        ],
      ),
    ),
  );

  if (!context.mounted) return;

  if (choice == 'db') {
    await _addExerciseFromDatabaseDialog(
      context,
      ref,
      planId,
      dayIndex,
    );
  } else if (choice == 'custom') {
    await _addCustomExerciseDialog(
      context,
      ref,
      planId,
      dayIndex,
    );
  }
}

Future<void> _addExerciseFromDatabaseDialog(
  BuildContext context,
  WidgetRef ref,
  String planId,
  int dayIndex,
) async {
  final l10n = AppLocalizations.of(context)!;

  final Exercise? selected =
      await Navigator.push<Exercise>(
    context,
    MaterialPageRoute(
      builder: (_) =>
          const _ExerciseDatabasePickerScreen(),
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
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: l10n.sets,
              ),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: repsCtrl,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: l10n.repsOrTime,
              ),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: rirCtrl,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: l10n.rir
              ),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: noteCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: l10n.note,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.pop(dialogContext, false),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: () =>
              Navigator.pop(dialogContext, true),
          child: Text(l10n.add),
        ),
      ],
    ),
  );

  if (ok == true) {
    await ref
        .read(customTrainingPlanProvider.notifier)
        .addExerciseToDay(
          planId: planId,
          dayIndex: dayIndex,
          exercise: CustomTrainingExercise(
            exerciseId: selected.id,
            customName: selected.displayName,
            sets: setsCtrl.text.trim().isEmpty
                ? '3'
                : setsCtrl.text.trim(),
            reps: repsCtrl.text.trim().isEmpty
                ? '8–12'
                : repsCtrl.text.trim(),
            rir: rirCtrl.text.trim().isEmpty
                ? '2'
                : rirCtrl.text.trim(),
            note: noteCtrl.text.trim().isEmpty
                ? null
                : noteCtrl.text.trim(),
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
  final l10n = AppLocalizations.of(context)!;

  final nameCtrl = TextEditingController();
  final setsCtrl = TextEditingController(text: '3');
  final repsCtrl = TextEditingController(text: '8–12');
  final rirCtrl = TextEditingController(text: '2');
  final noteCtrl = TextEditingController();

  final ok = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.addCustomExercise),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: l10n.exerciseName,
                hintText: l10n.exerciseNameHint,
              ),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: setsCtrl,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: l10n.sets,
              ),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: repsCtrl,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: l10n.repsOrTime,
                hintText: l10n.repsOrTimeHint,
              ),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: rirCtrl,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: l10n.rir
              ),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: noteCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: l10n.note,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.pop(dialogContext, false),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: () =>
              Navigator.pop(dialogContext, true),
          child: Text(l10n.add),
        ),
      ],
    ),
  );

  if (ok == true &&
      nameCtrl.text.trim().isNotEmpty) {
    await ref
        .read(customTrainingPlanProvider.notifier)
        .addExerciseToDay(
          planId: planId,
          dayIndex: dayIndex,
          exercise: CustomTrainingExercise(
            exerciseId: null,
            customName: nameCtrl.text.trim(),
            sets: setsCtrl.text.trim().isEmpty
                ? '3'
                : setsCtrl.text.trim(),
            reps: repsCtrl.text.trim().isEmpty
                ? '8–12'
                : repsCtrl.text.trim(),
            rir: rirCtrl.text.trim().isEmpty
                ? '2'
                : rirCtrl.text.trim(),
            note: noteCtrl.text.trim().isEmpty
                ? null
                : noteCtrl.text.trim(),
          ),
        );
  }
}
}
// ignore: unused_element
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
          '${exercise.sets} × ${exercise.reps}'
          '${exercise.weightKg != null ? ' | ${exercise.weightKg!.toStringAsFixed(1)} kg' : ''}'
          ' | RIR ${exercise.rir}'
          '${exercise.note != null ? '\n${exercise.note}' : ''}',
        ),
        onTap: () => _editExerciseDialog(
          context,
          ref,
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () => _confirmDeleteExercise(
            context,
            ref,
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteExercise(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final l10n = AppLocalizations.of(context)!;

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteExerciseQuestion),
        content: Text(
          l10n.confirmDeleteExercise(exercise.customName),
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, false),
            child: Text(l10n.no),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () =>
                Navigator.pop(dialogContext, true),
            child: Text(l10n.yesDelete),
          ),
        ],
      ),
    );

    if (ok == true) {
      await ref
          .read(customTrainingPlanProvider.notifier)
          .removeExerciseFromDay(
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
    final l10n = AppLocalizations.of(context)!;

    final nameCtrl = TextEditingController(
      text: exercise.customName,
    );

    final setsCtrl = TextEditingController(
      text: exercise.sets,
    );

    final repsCtrl = TextEditingController(
      text: exercise.reps,
    );

    final rirCtrl = TextEditingController(
      text: exercise.rir,
    );

    final noteCtrl = TextEditingController(
      text: exercise.note ?? '',
    );

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.editExercise),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: l10n.exerciseName,
                ),
              ),

              const SizedBox(height: 10),

              TextField(
                controller: setsCtrl,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: l10n.sets,
                ),
              ),

              const SizedBox(height: 10),

              TextField(
                controller: repsCtrl,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: l10n.repsOrTime,
                ),
              ),

              const SizedBox(height: 10),

              TextField(
                controller: rirCtrl,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: l10n.rir
                ),
              ),

              const SizedBox(height: 10),

              TextField(
                controller: noteCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: l10n.note,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(dialogContext, true),
            child: Text(l10n.save),
          ),
        ],
      ),
    );

    if (ok == true &&
        nameCtrl.text.trim().isNotEmpty) {
      await ref
          .read(customTrainingPlanProvider.notifier)
          .updateExerciseInDay(
            planId: planId,
            dayIndex: dayIndex,
            exerciseIndex: exerciseIndex,
            exercise: CustomTrainingExercise(
              exerciseId: exercise.exerciseId,
              customName: nameCtrl.text.trim(),
              sets: setsCtrl.text.trim().isEmpty
                  ? '3'
                  : setsCtrl.text.trim(),
              reps: repsCtrl.text.trim().isEmpty
                  ? '8–12'
                  : repsCtrl.text.trim(),
              rir: rirCtrl.text.trim().isEmpty
                  ? '2'
                  : rirCtrl.text.trim(),
              weightKg: exercise.weightKg,
              note: noteCtrl.text.trim().isEmpty
                  ? null
                  : noteCtrl.text.trim(),
            ),
          );
    }
  }
}

class _ExerciseDatabasePickerScreen
    extends StatefulWidget {
  const _ExerciseDatabasePickerScreen();

  @override
  State<_ExerciseDatabasePickerScreen>
      createState() =>
          _ExerciseDatabasePickerScreenState();
}

class _ExerciseDatabasePickerScreenState
    extends State<_ExerciseDatabasePickerScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final filtered = ExerciseDB.all.where((e) {
      if (_query.trim().isEmpty) return true;

      final q = _query.trim().toLowerCase();

      return e.name.toLowerCase().contains(q) ||
          e.displayName.toLowerCase().contains(q) ||
          (e.czName?.toLowerCase().contains(q) ??
              false);
    }).toList();

   return Scaffold(
  appBar: AppBar(
    title: Text(
      l10n.selectExerciseFromDatabase,
    ),
  ),
  body: Column(
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(
          12,
          12,
          12,
          8,
        ),
        child: TextField(
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            labelText: l10n.searchExercise,
          ),
          onChanged: (v) {
            setState(() {
              _query = v;
            });
          },
        ),
      ),

      Expanded(
        child: filtered.isEmpty
            ? Center(
                child: Text(
                  l10n.noExerciseFound,
                ),
              )
            : ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (_, index) {
                  final ex = filtered[index];

                  return Card(
                    child: ListTile(
                      title: Text(ex.displayName),
                      subtitle: Text(
                        'Anglicky: ${ex.name}\n'
                        'Vybavení: ${ex.equipment.join(', ')}',
                      ),
                                     onTap: () => Navigator.pop(
                      context,
                      ex,
                    ),
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
