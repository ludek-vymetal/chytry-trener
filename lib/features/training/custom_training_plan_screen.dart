import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../core/training/exercises/exercise.dart';
import '../../core/training/exercises/exercise_db.dart';
import '../../models/custom_training_plan.dart';
import '../../models/shared_training_template.dart';
import '../../providers/coach/active_client_provider.dart';
import '../../providers/coach/custom_training_plan_provider.dart';
import '../../providers/shared_training_templates_provider.dart';
import 'training_plan_screen.dart';

class CustomTrainingPlanScreen extends ConsumerWidget {
  const CustomTrainingPlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    final activeClientAsync = ref.watch(activeClientIdProvider);
    final allPlans = ref.watch(customTrainingPlanProvider);
    final sharedTemplates = ref.watch(sharedTrainingTemplatesProvider);

    return activeClientAsync.when(
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(
          title: Text(l10n.customTraining),
        ),
        body: Center(
          child: Text('${l10n.error}: $e'),
        ),
      ),
      data: (clientId) {
        if (clientId == null || clientId.isEmpty) {
          return Scaffold(
            appBar: AppBar(
              title: Text(l10n.customTraining),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  l10n.selectActiveClientFirst,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        final clientPlans =
            allPlans.where((p) => p.clientId == clientId).toList();

        final groupedTemplates =
            _groupTemplatesByCategory(sharedTemplates);

        final groupedPlans =
            _groupPlansByCategory(clientPlans);

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.customTraining),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () =>
                _createPlanDialog(context, ref, clientId),
            icon: const Icon(Icons.add),
            label: Text(l10n.newPlan),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              FilledButton.icon(
                onPressed: () =>
                    _insertConstantinCutPlan(
                  context,
                  ref,
                  clientId,
                ),
                icon: const Icon(
                  Icons.local_fire_department,
                ),
                label: const Text(
                  '🔥 VLOŽIT 90DENNÍ VYRÝSOVÁNÍ',
                ),
              ),

              const SizedBox(height: 12),

              FilledButton.tonalIcon(
                onPressed: () =>
                    _insertPowerliftingMeetPrepPlan(
                  context,
                  ref,
                  clientId,
                ),
                icon: const Icon(Icons.fitness_center),
                label: const Text(
                  '🏋️ VLOŽIT PŘÍPRAVU NA ZÁVODY – TROJBOJ',
                ),
              ),

              const SizedBox(height: 24),

              Text(
                l10n.sharedTemplates,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge,
              ),

              const SizedBox(height: 10),

              if (sharedTemplates.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      l10n.noSharedTemplatesYet,
                    ),
                  ),
                )
              else
                ...groupedTemplates.entries.map(
                  (entry) => _TemplateCategorySection(
                    category: entry.key,
                    templates: entry.value,
                    clientId: clientId,
                  ),
                ),

              const SizedBox(height: 24),

              Text(
                l10n.clientPlans,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge,
              ),

              const SizedBox(height: 10),

              if (clientPlans.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      l10n.noCustomPlanYet,
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                ...groupedPlans.entries.map(
                  (entry) => _PlanCategorySection(
                    category: entry.key,
                    plans: entry.value,
                  ),
                ),

              const SizedBox(height: 80),
            ],
          ),
        );
      },
    );
  }
}

  Map<CustomTrainingCategory, List<SharedTrainingTemplate>>
      _groupTemplatesByCategory(List<SharedTrainingTemplate> templates) {
    final map = <CustomTrainingCategory, List<SharedTrainingTemplate>>{};

    for (final template in templates) {
      map.putIfAbsent(template.category, () => []);
      map[template.category]!.add(template);
    }

    return map;
  }

  Map<CustomTrainingCategory, List<CustomTrainingPlan>> _groupPlansByCategory(
    List<CustomTrainingPlan> plans,
  ) {
    final map = <CustomTrainingCategory, List<CustomTrainingPlan>>{};

    for (final plan in plans) {
      map.putIfAbsent(plan.category, () => []);
      map[plan.category]!.add(plan);
    }

    return map;
  }

  Future<void> _createPlanDialog(
    BuildContext context,
    WidgetRef ref,
    String clientId,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final nameCtrl = TextEditingController();
    final descriptionCtrl = TextEditingController();
    CustomTrainingCategory selectedCategory = CustomTrainingCategory.custom;

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.newPlan),
          content: SingleChildScrollView(
            child: Column(
              children: [
                DropdownButtonFormField<CustomTrainingCategory>(
                  initialValue: selectedCategory,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: l10n.category,
                  ),
                  items: CustomTrainingCategory.values.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(_categoryLabel(context, category)),
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
                    hintText: l10n.planNameHint,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionCtrl,
                  minLines: 2,
                  maxLines: 4,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: l10n.planDescription,
                    hintText: l10n.planDescriptionHint,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(l10n.create),
            ),
          ],
        ),
      ),
    );

    if (ok == true && nameCtrl.text.trim().isNotEmpty) {
      await ref.read(customTrainingPlanProvider.notifier).createPlan(
            clientId: clientId,
            name: nameCtrl.text.trim(),
            description: descriptionCtrl.text.trim().isEmpty
                ? null
                : descriptionCtrl.text.trim(),
            category: selectedCategory,
          );
    }
  }

  Future<void> _insertConstantinCutPlan(
    BuildContext context,
    WidgetRef ref,
    String clientId,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final plans = ref.read(customTrainingPlanProvider);
    final newName = _buildUniquePlanName(
      '🔥 90denní vyrýsování',
      plans.where((p) => p.clientId == clientId).toList(),
    );

    await ref.read(customTrainingPlanProvider.notifier).createPlan(
          clientId: clientId,
          name: newName,
          description: 'Shazovací plán zaměřený na spalování tuku a kondici.',
          category: CustomTrainingCategory.cut,
          type: CustomTrainingPlanType.cut90,
        );

    final updatedPlans = ref.read(customTrainingPlanProvider);
    CustomTrainingPlan? createdPlan;

    for (final plan in updatedPlans.reversed) {
      if (plan.clientId == clientId && plan.name == newName) {
        createdPlan = plan;
        break;
      }
    }

    if (createdPlan == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.planInserted),
        ),
      );
      return;
    }

    final notifier = ref.read(customTrainingPlanProvider.notifier);
    final templateDays = _constantinPlanDays();

    for (final day in templateDays) {
      await notifier.addDay(
        planId: createdPlan.id,
        dayName: day.name,
      );
    }

    for (int dayIndex = 0; dayIndex < templateDays.length; dayIndex++) {
      final day = templateDays[dayIndex];
      for (final exercise in day.exercises) {
        await notifier.addExerciseToDay(
          planId: createdPlan.id,
          dayIndex: dayIndex,
          exercise: exercise,
        );
      }
    }

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Plán "$newName" byl vložen mezi vlastní tréninky.'),
      ),
    );
  }

  Future<void> _insertPowerliftingMeetPrepPlan(
    BuildContext context,
    WidgetRef ref,
    String clientId,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final maxes = await showDialog<_PowerliftingMaxes>(
      context: context,
      builder: (_) => const _PowerliftingMaxesDialog(),
    );

    if (maxes == null) return;

    final plans = ref.read(customTrainingPlanProvider);
    final newName = _buildUniquePlanName(
      '🏋️ Příprava na závody – silový trojboj',
      plans.where((p) => p.clientId == clientId).toList(),
    );

    await ref.read(customTrainingPlanProvider.notifier).createPlan(
          clientId: clientId,
          name: newName,
          description:
              'Silový plán pro přípravu na závody v trojboji podle zadaných maximálek.',
          category: CustomTrainingCategory.powerlifting,
          type: CustomTrainingPlanType.powerliftingMeetPrep,
          meetDate: maxes.meetDate,
          maxes: CustomTrainingMaxes(
            squat1rm: maxes.squat1rm,
            bench1rm: maxes.bench1rm,
            deadlift1rm: maxes.deadlift1rm,
          ),
        );

    final updatedPlans = ref.read(customTrainingPlanProvider);
    CustomTrainingPlan? createdPlan;

    for (final plan in updatedPlans.reversed) {
      if (plan.clientId == clientId && plan.name == newName) {
        createdPlan = plan;
        break;
      }
    }

    if (createdPlan == null) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.planCreationFailed,
          ),
        ),
      );

      return;
    }

    final notifier = ref.read(customTrainingPlanProvider.notifier);
    if (!context.mounted) return;
    final templateDays = _powerliftingMeetPrepDays(context, maxes);

    for (final day in templateDays) {
      await notifier.addDay(
        planId: createdPlan.id,
        dayName: day.name,
      );
    }

    for (int dayIndex = 0; dayIndex < templateDays.length; dayIndex++) {
      final day = templateDays[dayIndex];
      for (final exercise in day.exercises) {
        await notifier.addExerciseToDay(
          planId: createdPlan.id,
          dayIndex: dayIndex,
          exercise: exercise,
        );
      }
    }

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Plán "$newName" byl vložen mezi vlastní tréninky.'),
      ),
    );
  }

  String _buildUniquePlanName(
    String baseName,
    List<CustomTrainingPlan> existingPlans,
  ) {
    final used = existingPlans.map((e) => e.name.trim().toLowerCase()).toSet();

    if (!used.contains(baseName.trim().toLowerCase())) {
      return baseName;
    }

    var i = 2;
    while (true) {
      final candidate = '$baseName ($i)';
      if (!used.contains(candidate.trim().toLowerCase())) {
        return candidate;
      }
      i++;
    }
  }

  List<CustomTrainingDay> _constantinPlanDays() {
    return [
      CustomTrainingDay(
        name: 'Pondělí – Silový trénink (Fáze 1 / týdny 1–4)',
        exercises: const [
          CustomTrainingExercise(
            customName: 'ROZCVIČKA: Dřepy s vlastní vahou',
            sets: '1',
            reps: '10',
            rir: '—',
          ),
          CustomTrainingExercise(
            customName: 'ROZCVIČKA: Kliky',
            sets: '1',
            reps: '10',
            rir: '—',
          ),
          CustomTrainingExercise(
            customName: 'ROZCVIČKA: Výpady',
            sets: '1',
            reps: '10 na každou nohu',
            rir: '—',
          ),
          CustomTrainingExercise(
            customName: 'ROZCVIČKA: Burpees',
            sets: '1',
            reps: '10',
            rir: '—',
          ),
          CustomTrainingExercise(
            customName: 'Mrtvý tah',
            sets: '5 kol',
            reps: '10–12',
            rir: '1–2',
            note:
                'Bez pauzy mezi cviky. Pauza 60 s po kole. Poslední opakování má být těžké.',
          ),
          CustomTrainingExercise(
            customName: 'Výpady + tlak na ramena (jednoručky)',
            sets: '5 kol',
            reps: '10–12 na každou nohu',
            rir: '1–2',
            note: 'Součást pondělního okruhu ve Fázi 1.',
          ),
          CustomTrainingExercise(
            customName: 'Přítahy jednoruček v planku',
            sets: '5 kol',
            reps: '10–12 na každou ruku',
            rir: '1–2',
            note: 'Součást pondělního okruhu ve Fázi 1.',
          ),
        ],
      ),
      CustomTrainingDay(
        name: 'Úterý – Kardio HIIT',
        exercises: const [
          CustomTrainingExercise(
            customName: 'HIIT: Sprint / kolo / běh',
            sets: '8–15 kol',
            reps: '20 s výkon / 10 s pauza',
            rir: '—',
            note:
                'Začni na 8 kolech a postupně se dostaň až na 15 kol podle kondice a regenerace.',
          ),
        ],
      ),
      CustomTrainingDay(
        name: 'Středa – Silový trénink (Fáze 1 / týdny 1–4)',
        exercises: const [
          CustomTrainingExercise(
            customName: 'ROZCVIČKA: Dřepy s vlastní vahou',
            sets: '1',
            reps: '10',
            rir: '—',
          ),
          CustomTrainingExercise(
            customName: 'ROZCVIČKA: Kliky',
            sets: '1',
            reps: '10',
            rir: '—',
          ),
          CustomTrainingExercise(
            customName: 'ROZCVIČKA: Výpady',
            sets: '1',
            reps: '10 na každou nohu',
            rir: '—',
          ),
          CustomTrainingExercise(
            customName: 'ROZCVIČKA: Burpees',
            sets: '1',
            reps: '10',
            rir: '—',
          ),
          CustomTrainingExercise(
            customName: 'Dřep + tlak s jednoručkami',
            sets: '20 min',
            reps: '10–12',
            rir: '1–2',
            note: 'Střídej cviky 20 minut. Pauza mezi cviky 20 s. Fáze 1.',
          ),
          CustomTrainingExercise(
            customName: 'Mrtvý tah s jednoručkami',
            sets: '20 min',
            reps: '10–12',
            rir: '1–2',
            note:
                'Střídej s předchozím cvikem. Pauza mezi cviky 20 s. Fáze 1.',
          ),
        ],
      ),
      CustomTrainingDay(
        name: 'Čtvrtek – Kardio chůze',
        exercises: const [
          CustomTrainingExercise(
            customName: 'Rychlá chůze',
            sets: '1',
            reps: '30–45 min',
            rir: '—',
            note:
                'Začni na 30 minutách a postupně se dostaň až na 45 minut.',
          ),
        ],
      ),
      CustomTrainingDay(
        name: 'Pátek – Silový trénink (Fáze 1 / týdny 1–4)',
        exercises: const [
          CustomTrainingExercise(
            customName: 'ROZCVIČKA: Dřepy s vlastní vahou',
            sets: '1',
            reps: '10',
            rir: '—',
          ),
          CustomTrainingExercise(
            customName: 'ROZCVIČKA: Kliky',
            sets: '1',
            reps: '10',
            rir: '—',
          ),
          CustomTrainingExercise(
            customName: 'ROZCVIČKA: Výpady',
            sets: '1',
            reps: '10 na každou nohu',
            rir: '—',
          ),
          CustomTrainingExercise(
            customName: 'ROZCVIČKA: Burpees',
            sets: '1',
            reps: '10',
            rir: '—',
          ),
          CustomTrainingExercise(
            customName: 'Dřep',
            sets: '20 min AMRAP',
            reps: '12',
            rir: '1–2',
            note:
                'Fáze 1 – co nejvíc kol za 20 minut. Bez zbytečných pauz mezi cviky.',
          ),
          CustomTrainingExercise(
            customName: 'Plyometrické kliky',
            sets: '20 min AMRAP',
            reps: '12',
            rir: '1–2',
            note: 'Fáze 1 – součást pátečního okruhu.',
          ),
          CustomTrainingExercise(
            customName: 'Přítahy v předklonu',
            sets: '20 min AMRAP',
            reps: '12',
            rir: '1–2',
            note: 'Fáze 1 – součást pátečního okruhu.',
          ),
          CustomTrainingExercise(
            customName: 'Výskoky na bednu',
            sets: '20 min AMRAP',
            reps: '15',
            rir: '1–2',
            note: 'Fáze 1 – součást pátečního okruhu.',
          ),
        ],
      ),
      CustomTrainingDay(
        name: 'Sobota – Kardio HIIT',
        exercises: const [
          CustomTrainingExercise(
            customName: 'HIIT: Sprint / kolo / běh',
            sets: '8–15 kol',
            reps: '20 s výkon / 10 s pauza',
            rir: '—',
            note:
                'Stejné jako úterý. Intenzivní výkon, ale pořád s kontrolou regenerace.',
          ),
        ],
      ),
      CustomTrainingDay(
        name: 'Neděle – Volno / regenerace',
        exercises: const [
          CustomTrainingExercise(
            customName: 'Volno',
            sets: '—',
            reps: 'Regenerace',
            rir: '—',
            note:
                'Lehká chůze, mobilita nebo úplné volno. Každý týden zvyš váhu, zrychli tempo nebo přidej kola.',
          ),
          CustomTrainingExercise(
            customName: 'FÁZE 2 – týdny 5–8 (instrukce)',
            sets: '1',
            reps: 'Přepni podle poznámky',
            rir: '—',
            note:
                'Pondělí: Hacken dřep 12–15 / Clean & Press 8–10 / Burpees 10–12, 5 kol, bez pauzy mezi cviky, 60 s mezi koly. '
                'Středa: Tlaky s jednoručkami na rovné lavici 10–12 / Rumunský mrtvý tah 10–12 / Výskoky na bednu 15, 5 kol. '
                'Pátek: 20 min AMRAP – Mrtvý tah s trap osou 10 / Goblet dřep 10 / Přítahy v předklonu 12 / Tlaky na ramena 10.',
          ),
          CustomTrainingExercise(
            customName: 'FÁZE 3 – týdny 9–12 (instrukce)',
            sets: '1',
            reps: 'Přepni podle poznámky',
            rir: '—',
            note:
                'Pondělí: Mrtvý tah 12–15 / Plyometrické kliky 10–12 / Přítahy v předklonu 10–12 / Burpees 10–12, 5 kol, 60 s mezi koly. '
                'Středa: intervaly – Dřep + tlak 20 s práce / 20 s pauza / 5 kol, poté Sumo mrtvý tah s přítahen k bradě 20 s práce / 20 s pauza / 5 kol. '
                'Pátek: 20 min AMRAP – Hacken dřep 15 / Přítahy jednoruček v planku 15 na ruku / Rumunský mrtvý tah 10 / Krčení ramen s jednoručkami 15.',
          ),
        ],
      ),
    ];
  }

  List<CustomTrainingDay> _powerliftingMeetPrepDays(
    BuildContext context,
    _PowerliftingMaxes maxes,
  ) {
    final l10n = AppLocalizations.of(context)!;
    // Všechny tři disciplíny se počítají z training maxu (90 % 1RM),
    // aby procenta odpovídala předepsaným opakováním a RIR.
    final squatBase = _trainingMax(maxes.squat1rm);
    final benchTm = _trainingMax(maxes.bench1rm);
    final deadliftBase = _trainingMax(maxes.deadlift1rm);

    final phaseWeeks = <_PowerWeekConfig>[
      _PowerWeekConfig(
        week: 1,
        phaseLabel: 'Objem',
        squatPct: 0.70,
        benchPct: 0.75,
        deadliftPct: 0.70,
        squatSets: '5',
        squatReps: '5',
        benchHeavySets: '5',
        benchHeavyReps: '5',
        deadliftSets: '5',
        deadliftReps: '4',
      ),
      _PowerWeekConfig(
        week: 2,
        phaseLabel: 'Objem',
        squatPct: 0.725,
        benchPct: 0.775,
        deadliftPct: 0.725,
        squatSets: '5',
        squatReps: '5',
        benchHeavySets: '5',
        benchHeavyReps: '5',
        deadliftSets: '5',
        deadliftReps: '4',
      ),
      _PowerWeekConfig(
        week: 3,
        phaseLabel: 'Objem',
        squatPct: 0.75,
        benchPct: 0.80,
        deadliftPct: 0.75,
        squatSets: '5',
        squatReps: '5',
        benchHeavySets: '5',
        benchHeavyReps: '5',
        deadliftSets: '5',
        deadliftReps: '4',
      ),
      _PowerWeekConfig(
        week: 4,
        phaseLabel: 'Objem',
        squatPct: 0.775,
        benchPct: 0.825,
        deadliftPct: 0.775,
        squatSets: '5',
        squatReps: '5',
        benchHeavySets: '5',
        benchHeavyReps: '5',
        deadliftSets: '5',
        deadliftReps: '4',
      ),
      _PowerWeekConfig(
        week: 5,
        phaseLabel: 'Síla',
        squatPct: 0.80,
        benchPct: 0.85,
        deadliftPct: 0.80,
        squatSets: '4',
        squatReps: '4',
        benchHeavySets: '4',
        benchHeavyReps: '4',
        deadliftSets: '4',
        deadliftReps: '3',
      ),
      _PowerWeekConfig(
        week: 6,
        phaseLabel: 'Síla',
        squatPct: 0.825,
        benchPct: 0.875,
        deadliftPct: 0.825,
        squatSets: '4',
        squatReps: '4',
        benchHeavySets: '4',
        benchHeavyReps: '4',
        deadliftSets: '4',
        deadliftReps: '3',
      ),
      _PowerWeekConfig(
        week: 7,
        phaseLabel: 'Síla',
        squatPct: 0.85,
        benchPct: 0.90,
        deadliftPct: 0.85,
        squatSets: '4',
        squatReps: '4',
        benchHeavySets: '4',
        benchHeavyReps: '4',
        deadliftSets: '4',
        deadliftReps: '3',
      ),
      _PowerWeekConfig(
        week: 8,
        phaseLabel: 'Síla',
        squatPct: 0.875,
        benchPct: 0.925,
        deadliftPct: 0.875,
        squatSets: '4',
        squatReps: '4',
        benchHeavySets: '4',
        benchHeavyReps: '4',
        deadliftSets: '4',
        deadliftReps: '3',
      ),
      _PowerWeekConfig(
        week: 9,
        phaseLabel: 'Intenzifikace',
        squatPct: 0.90,
        benchPct: 0.925,
        deadliftPct: 0.90,
        squatSets: '3',
        squatReps: '3',
        benchHeavySets: '3',
        benchHeavyReps: '3',
        deadliftSets: '3',
        deadliftReps: '2',
      ),
      _PowerWeekConfig(
        week: 10,
        phaseLabel: 'Intenzifikace',
        squatPct: 0.925,
        benchPct: 0.95,
        deadliftPct: 0.925,
        squatSets: '3',
        squatReps: '3',
        benchHeavySets: '3',
        benchHeavyReps: '3',
        deadliftSets: '3',
        deadliftReps: '2',
      ),
      _PowerWeekConfig(
        week: 11,
        phaseLabel: 'Peak / CNS',
        squatPct: 0.90,
        benchPct: 0.90,
        deadliftPct: 0.90,
        topSinglePct: 0.975,
        squatSets: '3 + 2 singly',
        squatReps: '2 + 1',
        benchHeavySets: '3 + 2 singly',
        benchHeavyReps: '2 + 1',
        deadliftSets: '3 + 2 singly',
        deadliftReps: '2 + 1',
      ),
      _PowerWeekConfig(
        week: 12,
        phaseLabel: 'Taper / závod',
        squatPct: 0.85,
        benchPct: 0.875,
        deadliftPct: 0.85,
        topSinglePct: 0.925,
        squatSets: '2 + 1 single',
        squatReps: '1 + 1',
        benchHeavySets: '2 + 1 single',
        benchHeavyReps: '1 + 1',
        deadliftSets: '2 + 1 single',
        deadliftReps: '1 + 1',
      ),
    ];

    // Když je závod dřív než za 12 týdnů, začneme rovnou správným týdnem
    // (první týdny vynecháme), aby peak a taper vyšly na datum závodu.
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final meetDay = DateTime(
      maxes.meetDate.year,
      maxes.meetDate.month,
      maxes.meetDate.day,
    );
    final daysToMeet = meetDay.difference(today).inDays;
    final weeksAvailable = (daysToMeet / 7).ceil().clamp(2, 12).toInt();
    final weeksToUse =
        phaseWeeks.where((w) => w.week > 12 - weeksAvailable).toList();

    final days = <CustomTrainingDay>[];

    for (final week in weeksToUse) {
      final squatMain = _weightFromMax(squatBase, week.squatPct);
      final benchMain = _weightFromTm(benchTm, week.benchPct);
      final deadliftMain = _weightFromMax(deadliftBase, week.deadliftPct);

      final squatTechPercent = week.week <= 4
          ? 0.65
          : week.week <= 8
              ? 0.70
              : week.week <= 10
                  ? 0.75
                  : 0.70;

      final benchVolumePercent =
          (week.benchPct - 0.10).clamp(0.65, 0.80).toDouble();
      final benchTechPercent =
          (week.benchPct - 0.15).clamp(0.60, 0.75).toDouble();
      final backoffPercent = week.benchPct - 0.10;

      final squatTech = _weightFromMax(squatBase, squatTechPercent);
      final benchVolume = _weightFromTm(benchTm, benchVolumePercent);
      final benchTech = _weightFromTm(benchTm, benchTechPercent);
      final benchBackoff = _weightFromTm(benchTm, backoffPercent);

      final topSingleSquat = week.topSinglePct == null
          ? null
          : _weightFromMax(squatBase, week.topSinglePct!);
      final topSingleBench = week.topSinglePct == null
          ? null
          : _weightFromTm(benchTm, week.topSinglePct!);
      final topSingleDeadlift = week.topSinglePct == null
          ? null
          : _weightFromMax(deadliftBase, week.topSinglePct!);

      final daysBeforeMeetWeekEnd = (12 - week.week) * 7;
      final weekEnd = maxes.meetDate.subtract(
        Duration(days: daysBeforeMeetWeekEnd),
      );
      final weekStart = weekEnd.subtract(const Duration(days: 6));
      final weekLabel =
          'Týden ${week.week} (${_fmtDate(weekStart)} – ${_fmtDate(weekEnd)})';

      final benchVolumeSets = week.week <= 4
          ? '5'
          : week.week <= 8
              ? '4'
              : week.week <= 10
                  ? '4'
                  : '3';

      final benchVolumeReps = week.week <= 4
          ? '6–8'
          : week.week <= 8
              ? '5–6'
              : week.week <= 10
                  ? '4–5'
                  : '3–4';

      final benchTechSets = week.week >= 11 ? '3' : '4';
      final benchTechReps = week.week >= 11 ? '3–4' : '4–6';
      final benchBackoffReps = week.week >= 11 ? '2' : week.benchHeavyReps;

      days.addAll([
        CustomTrainingDay(
          name: '$weekLabel – Den 1 – Dřep těžce + spodní část',
          exercises: [
            CustomTrainingExercise(
              customName: 'Dřep – závodní styl',
              sets: week.squatSets,
              reps: week.squatReps,
              rir: week.week >= 11 ? '1–2' : '1–3',
              weightKg: squatMain,
              note:
                  'Fáze: ${week.phaseLabel}\n'
                  '${l10n.meetDate}: ${_fmtDate(maxes.meetDate)}\n'
                  'Výchozí 1RM: ${maxes.squat1rm.toStringAsFixed(1)} kg\n'
                  'Training max: ${squatBase.toStringAsFixed(1)} kg\n'
                  'Pracovní váha: '
                  '${_formatWeightAndPercent(squatMain, week.squatPct)}'
                  '${topSingleSquat == null ? '' : '\nTop single: ${_formatWeightAndPercent(topSingleSquat, week.topSinglePct!)}'}',
            ),
            CustomTrainingExercise(
              customName: 'Dřep – lehčí technika / pauza',
              sets: week.week >= 11 ? '3' : '4',
              reps: week.week >= 11 ? '2–3' : '3–5',
              rir: '2–3',
              weightKg: squatTech,
              note:
                  'Technická práce.\n'
                  'Pracovní váha: ${_formatWeightAndPercent(squatTech, squatTechPercent)}',
            ),
            CustomTrainingExercise(
              customName: 'Rumunský mrtvý tah',
              sets: '4',
              reps: '6–8',
              rir: '2–3',
            ),
            
            
            CustomTrainingExercise(
              customName: 'Břicho / core',
              sets: '3',
              reps: '10–15 / 20–30 s',
              rir: '2–3',
            ),
          ],
        ),
        CustomTrainingDay(
          name: '$weekLabel – Den 2 – Bench těžce + backoff + doplňky',
          exercises: [
            CustomTrainingExercise(
              customName: 'Bench press – závodní pauza',
              sets: week.benchHeavySets,
              reps: week.benchHeavyReps,
              rir: week.week >= 11 ? '1–2' : '1–3',
              weightKg: benchMain,
              note:
                  'Fáze: ${week.phaseLabel}\n'
                  '${l10n.meetDate}: ${_fmtDate(maxes.meetDate)}\n'
                  'Training max: ${benchTm.toStringAsFixed(1)} kg\n'
                  'Pracovní váha: '
                  '${_formatWeightAndPercent(benchMain, week.benchPct)}'
                  '${topSingleBench == null ? '' : '\nTop single: ${_formatWeightAndPercent(topSingleBench, week.topSinglePct!)}'}',
            ),
            CustomTrainingExercise(
              customName: 'Bench press – backoff série',
              sets: '2',
              reps: benchBackoffReps,
              rir: '2',
              weightKg: benchBackoff,
              note:
                  'Backoff práce po hlavním bench dni.\n'
                  'Pracovní váha: ${_formatWeightAndPercent(benchBackoff, backoffPercent)}',
            ),
            CustomTrainingExercise(
              customName: 'Incline Bench',
              sets: '3',
              reps: '8–10',
              rir: '2–3',
              note: 'Horní hrudník a přenos do bench pressu.',
            ),
            CustomTrainingExercise(
              customName: 'Dips',
              sets: '3',
              reps: '6–10',
              rir: '2–3',
              note: 'Triceps, tlaková síla, lockout.',
            ),
            CustomTrainingExercise(
              customName: 'Triceps Pushdown',
              sets: '3',
              reps: '10–15',
              rir: '2–3',
              note: 'Lokální objem pro triceps.',
            ),
            CustomTrainingExercise(
              customName: 'Přítahy v předklonu',
              sets: '4',
              reps: '6–10',
              rir: '2',
            ),
          ],
        ),
        CustomTrainingDay(
          name: '$weekLabel – Den 3 – Mrtvý tah těžce + záda',
          exercises: [
            CustomTrainingExercise(
              customName: 'Mrtvý tah – závodní styl',
              sets: week.deadliftSets,
              reps: week.deadliftReps,
              rir: week.week >= 11 ? '1–2' : '1–3',
              weightKg: deadliftMain,
              note:
                  'Fáze: ${week.phaseLabel}\n'
                  '${l10n.meetDate}: ${_fmtDate(maxes.meetDate)}\n'
                  'Výchozí 1RM: ${maxes.deadlift1rm.toStringAsFixed(1)} kg\n'
                  'Training max: ${deadliftBase.toStringAsFixed(1)} kg\n'
                  'Pracovní váha: '
                  '${_formatWeightAndPercent(deadliftMain, week.deadliftPct)}'
                  '${topSingleDeadlift == null ? '' : '\nTop single: ${_formatWeightAndPercent(topSingleDeadlift, week.topSinglePct!)}'}',
            ),

            CustomTrainingExercise(
              customName: 'Hamstringy',
              sets: '3',
              reps: '8–12',
              rir: '2–3',
            ),
            CustomTrainingExercise(
              customName: 'Shyby / horní kladka',
              sets: '4',
              reps: '6–10',
              rir: '2',
            ),
            CustomTrainingExercise(
              customName: 'Záda / mezilopatky',
              sets: '3',
              reps: '10–15',
              rir: '2–3',
            ),
          ],
        ),
        CustomTrainingDay(
          name: '$weekLabel – Den 4 – Bench objem / technika',
          exercises: [
            CustomTrainingExercise(
              customName: 'Bench press – objem',
              sets: benchVolumeSets,
              reps: benchVolumeReps,
              rir: '2–3',
              weightKg: benchVolume,
              note:
                  'Objem, technika a bench-specific hypertrofie.\n'
                  'Pracovní váha: ${_formatWeightAndPercent(benchVolume, benchVolumePercent)}',
            ),
            CustomTrainingExercise(
              customName: 'Bench press – lehčí technika',
              sets: benchTechSets,
              reps: benchTechReps,
              rir: '2–3',
              weightKg: benchTech,
              note:
                  'Technika, rychlost osy, setup.\n'
                  'Pracovní váha: ${_formatWeightAndPercent(benchTech, benchTechPercent)}',
            ),
            CustomTrainingExercise(
              customName: 'Close-Grip Bench Press',
              sets: '3',
              reps: '6–8',
              rir: '2–3',
              weightKg: benchTech,
              note:
                  'Bench-specific doplněk se zaměřením na triceps a lockout.',
            ),
            CustomTrainingExercise(
              customName: 'Tlaky nad hlavu / ramena',
              sets: '3',
              reps: '6–10',
              rir: '2–3',
            ),
            CustomTrainingExercise(
              customName: 'Rotátory / prevence ramen',
              sets: '2–3',
              reps: '12–20',
              rir: '2–3',
            ),
          ],
        ),
      ]);
    }

    days.add(
      CustomTrainingDay(
        name: 'Instrukce k 12týdennímu cyklu',
        exercises: [
          CustomTrainingExercise(
            customName: 'Datum závodu',
            sets: '1',
            reps: _fmtDate(maxes.meetDate),
            rir: '—',
            note: 'Všechny týdny jsou rozpočítané zpětně od tohoto data.',
          ),
          CustomTrainingExercise(
            customName: 'Týdny 1–4',
            sets: '1',
            reps: 'Objem + technika',
            rir: '—',
            note:
                'Buduješ základ, stabilitu a přesnost pohybu. Vyšší objem, nižší intenzita, žádné zbytečné selhání.',
          ),
          CustomTrainingExercise(
            customName: 'Týdny 5–8',
            sets: '1',
            reps: 'Síla',
            rir: '—',
            note:
                'Zvedáš intenzitu, snižuješ počet opakování a připravuješ se na těžší specifickou práci.',
          ),
          CustomTrainingExercise(
            customName: 'Týdny 9–10',
            sets: '1',
            reps: 'Intenzifikace',
            rir: '—',
            note:
                'Těžké trojky a dvojky. Důraz na závodní provedení a kontrolu únavy.',
          ),
          CustomTrainingExercise(
            customName: 'Týden 11',
            sets: '1',
            reps: 'Peak / CNS',
            rir: '—',
            note:
                'Ano, tohle je přesně prostor pro nabuzení nervového systému. Nízký objem, vysoká intenzita, žádné zbytečné doplňky navíc.',
          ),
          CustomTrainingExercise(
            customName: 'Týden 12',
            sets: '1',
            reps: 'Taper / závod',
            rir: '—',
            note:
                'Výrazně stáhni objem. Cílem je čerstvost, jistota a rychlost na platformě.',
          ),
        ],
      ),
    );

    return days;
  }

  String _fmtDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.year}';
  }

  double _trainingMax(double oneRepMax) {
    return _roundToNearest2_5(oneRepMax * 0.90);
  }

  double _weightFromTm(double trainingMax, double percent) {
    return _roundToNearest2_5(trainingMax * percent);
  }

  double _weightFromMax(double max, double percent) {
    return _roundToNearest2_5(max * percent);
  }

  double _roundToNearest2_5(double value) {
    return (value / 2.5).round() * 2.5;
  }

  String _formatWeightAndPercent(double weight, double percent) {
    return '${(percent * 100).toStringAsFixed(percent * 100 % 1 == 0 ? 0 : 1)} % = ${weight.toStringAsFixed(1)} kg';
}


class _PowerliftingMaxes {
  final double squat1rm;
  final double bench1rm;
  final double deadlift1rm;
  final DateTime meetDate;

  const _PowerliftingMaxes({
    required this.squat1rm,
    required this.bench1rm,
    required this.deadlift1rm,
    required this.meetDate,
  });
}

class _PowerWeekConfig {
  final int week;
  final String phaseLabel;

  final double squatPct;
  final double benchPct;
  final double deadliftPct;

  final double? topSinglePct;

  final String squatSets;
  final String squatReps;

  final String benchHeavySets;
  final String benchHeavyReps;

  final String deadliftSets;
  final String deadliftReps;

  _PowerWeekConfig({
    required this.week,
    required this.phaseLabel,
    required this.squatPct,
    required this.benchPct,
    required this.deadliftPct,
    this.topSinglePct,
    required this.squatSets,
    required this.squatReps,
    required this.benchHeavySets,
    required this.benchHeavyReps,
    required this.deadliftSets,
    required this.deadliftReps,
  });
}

class _PowerliftingMaxesDialog extends StatefulWidget {
  const _PowerliftingMaxesDialog();

  @override
  State<_PowerliftingMaxesDialog> createState() =>
      _PowerliftingMaxesDialogState();
}

class _PowerliftingMaxesDialogState
    extends State<_PowerliftingMaxesDialog> {
  final squatCtrl = TextEditingController();
  final benchCtrl = TextEditingController();
  final deadliftCtrl = TextEditingController();

  DateTime meetDate = DateTime.now().add(
    const Duration(days: 84),
  );

  @override
  void dispose() {
    squatCtrl.dispose();
    benchCtrl.dispose();
    deadliftCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.enterMaxes),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: squatCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.squat1rm,
              ),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: benchCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.bench1rm,
              ),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: deadliftCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.deadlift1rm,
              ),
            ),

            const SizedBox(height: 16),

            FilledButton(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: meetDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(
                    const Duration(days: 365),
                  ),
                );

                if (!context.mounted) return;

                if (picked != null) {
                  setState(() {
                    meetDate = picked;
                  });
                }
              },
              child: Text(
                '${l10n.meetDate}: '
                '${meetDate.day}.${meetDate.month}.${meetDate.year}',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: () {
            final squat =
                double.tryParse(squatCtrl.text);
            final bench =
                double.tryParse(benchCtrl.text);
            final deadlift =
                double.tryParse(deadliftCtrl.text);

            if (squat == null ||
                bench == null ||
                deadlift == null) {
              return;
            }

            Navigator.pop(
              context,
              _PowerliftingMaxes(
                squat1rm: squat,
                bench1rm: bench,
                deadlift1rm: deadlift,
                meetDate: meetDate,
              ),
            );
          },
          child: Text(l10n.createPlan),
        ),
      ],
    );
  }
}



class _TemplateCategorySection extends StatelessWidget {
  final CustomTrainingCategory category;
  final List<SharedTrainingTemplate> templates;
  final String clientId;

  const _TemplateCategorySection({
    required this.category,
    required this.templates,
    required this.clientId,
  });

  @override
  Widget build(BuildContext context) {
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          _categoryLabel(context, category),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ...templates.map(
          (template) => _SharedTemplateCard(
            template: template,
            clientId: clientId,
          ),
        ),
      ],
    );
  }
}
String _categoryLabel(
  BuildContext context,
  CustomTrainingCategory category,
) {
  final l10n = AppLocalizations.of(context)!;

  switch (category) {
    case CustomTrainingCategory.strength:
      return l10n.strengthTrainings;

    case CustomTrainingCategory.bulk:
      return l10n.bulk;

    case CustomTrainingCategory.cut:
      return l10n.cut;

    case CustomTrainingCategory.recomp:
      return l10n.recomp;

    case CustomTrainingCategory.conditioning:
      return l10n.conditioning;

    case CustomTrainingCategory.powerlifting:
      return l10n.powerlifting;

    case CustomTrainingCategory.bodybuilding:
      return l10n.bodybuilding;

    case CustomTrainingCategory.custom:
      return l10n.other;
  }
}
class _PlanCategorySection extends StatelessWidget {
  final CustomTrainingCategory category;
  final List<CustomTrainingPlan> plans;

  const _PlanCategorySection({
    required this.category,
    required this.plans,
  });

  @override
  Widget build(BuildContext context) {
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          _categoryLabel(context, category),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ...plans.map((plan) => _PlanCard(plan: plan)),
      ],
    );
  }
}

class _SharedTemplateCard extends ConsumerWidget {
  final SharedTrainingTemplate template;
  final String clientId;

  const _SharedTemplateCard({
    required this.template,
    required this.clientId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),

        title: Text(
          template.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            '${template.description ?? l10n.noDescription}\n'
            '${l10n.daysCount}: ${template.days.length}',
          ),
        ),

        isThreeLine: true,

        trailing: Wrap(
          spacing: 8,
          children: [
            FilledButton(
              onPressed: () async {
                await ref
                    .read(sharedTrainingTemplatesProvider.notifier)
                    .createPlanFromTemplate(
                      clientId: clientId,
                      template: template,
                      ref: ref,
                    );

                if (!context.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      l10n.templateInserted(template.name),
                    ),
                  ),
                );
              },
              child: Text(l10n.insert),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends ConsumerWidget {
  final CustomTrainingPlan plan;

  const _PlanCard({
    required this.plan,
  });

  Future<void> _activateAndOpen(
    BuildContext context,
    WidgetRef ref,
  ) async {
    await ref
        .read(customTrainingPlanProvider.notifier)
        .setActivePlan(
          clientId: plan.clientId,
          planId: plan.id,
        );

    if (!context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const TrainingPlanScreen(),
      ),
    );
  }

  Future<void> _openPlanDetail(
    BuildContext context,
  ) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _PlanDetailScreen(
          planId: plan.id,
        ),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),

        title: Row(
          children: [
            Expanded(
              child: Text(
                plan.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            if (plan.isActive)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius:
                      BorderRadius.circular(20),
                ),
                child: Text(
                  l10n.active,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),

        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            '${plan.description ?? l10n.noDescription}\n'
            '${l10n.daysCount}: ${plan.days.length}',
          ),
        ),

        isThreeLine: true,

        onTap: () => _openPlanDetail(context),

        trailing: Wrap(
          spacing: 8,
          children: [
            FilledButton(
              onPressed: () =>
                  _activateAndOpen(context, ref),
              child: Text(l10n.open),
            ),

            OutlinedButton(
              onPressed: () {
                ref
                    .read(
                      customTrainingPlanProvider
                          .notifier,
                    )
                    .setActivePlan(
                      clientId: plan.clientId,
                      planId: plan.id,
                    );
              },
              child: Text(l10n.activate),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanDetailScreen extends ConsumerWidget {
  final String planId;

  const _PlanDetailScreen({
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