import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/nutrition/hollywood_prep.dart';
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

              const SizedBox(height: 12),

              FilledButton.tonalIcon(
                onPressed: () =>
                    _insertHollywoodPlan(
                  context,
                  ref,
                  clientId,
                ),
                icon: const Icon(Icons.movie_filter_outlined),
                label: Text(l10n.hollywoodInsertPlan),
              ),

              const SizedBox(height: 12),

              FilledButton.tonalIcon(
                onPressed: () =>
                    _insertBikiniPlan(
                  context,
                  ref,
                  clientId,
                ),
                icon: const Icon(Icons.emoji_events_outlined),
                label: Text(l10n.bikiniInsertPlan),
              ),

              const SizedBox(height: 12),

              FilledButton.tonalIcon(
                onPressed: () =>
                    _insertGlutePlan(
                  context,
                  ref,
                  clientId,
                ),
                icon: const Icon(Icons.favorite_outline),
                label: Text(l10n.gluteInsertPlan),
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

  Future<void> _insertHollywoodPlan(
    BuildContext context,
    WidgetRef ref,
    String clientId,
  ) async {
    final l10n = AppLocalizations.of(context)!;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Výchozí: natáčení za 12 týdnů (dnes = 1. týden přípravy).
    final shootDate = await showDatePicker(
      context: context,
      initialDate: today.add(const Duration(days: 83)),
      firstDate: today,
      lastDate: today.add(const Duration(days: 730)),
      helpText: l10n.hollywoodShootDate,
    );

    if (shootDate == null) return;
    if (!context.mounted) return;

    final plans = ref.read(customTrainingPlanProvider);
    final newName = _buildUniquePlanName(
      '🎬 ${HollywoodPrep.name}',
      plans.where((p) => p.clientId == clientId).toList(),
    );

    await ref.read(customTrainingPlanProvider.notifier).createPlan(
          clientId: clientId,
          name: newName,
          description:
              'Příprava postavy na natáčení / focení ${_fmtDate(shootDate)}: '
              'nízký tuk, důraz na partie viditelné na kameře, síla se udržuje.',
          category: CustomTrainingCategory.hollywood,
          type: CustomTrainingPlanType.hollywoodPrep,
          meetDate: shootDate,
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
        SnackBar(content: Text(l10n.planCreationFailed)),
      );
      return;
    }

    final notifier = ref.read(customTrainingPlanProvider.notifier);
    final templateDays = _hollywoodPlanDays(shootDate);

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

  /// Hollywood training – 12 týdnů zpětně od data natáčení, 5 tréninků
  /// týdně. Když je natáčení dřív než za 12 týdnů, začíná se rovnou
  /// aktuálním týdnem (fáze vždy sedí na datum natáčení – stejně jako
  /// jídelníček Hollywood training).
  List<CustomTrainingDay> _hollywoodPlanDays(DateTime shootDate) {
    const weeks = [
      // Týdny 1–4: stavba – hypertrofie, mírný deficit.
      _PrepWeekConfig(
        fromWeek: 1,
        toWeek: 4,
        phase: 'Stavba',
        mainSets: '4',
        mainReps: '6–8',
        mainRir: '1–2',
        accSets: '3',
        accReps: '8–12',
        accRir: '1–2',
        rest: 'hlavní cvik 2–3 min, doplňky 90 s',
        circuitRounds: '3',
        circuitRest: '90 s',
        cardio:
            '8 000–10 000 kroků denně + 2× týdně 30 min kardio nízké intenzity (chůze do kopce, kolo).',
        supersets: false,
        dropSet: false,
      ),
      // Týdny 5–8: rýsování – supersérie, víc kardia.
      _PrepWeekConfig(
        fromWeek: 5,
        toWeek: 8,
        phase: 'Rýsování',
        mainSets: '4',
        mainReps: '6–8',
        mainRir: '1–2',
        accSets: '3',
        accReps: '10–15',
        accRir: '1',
        rest: 'hlavní cvik 2 min, supersérie 60 s',
        circuitRounds: '4',
        circuitRest: '60 s',
        cardio:
            '10 000–12 000 kroků denně + 3–4× týdně 30–40 min kardio nízké intenzity.',
        supersets: true,
        dropSet: false,
      ),
      // Týdny 9–10: finální rýsování – síla drží svaly, hustota tréninku.
      _PrepWeekConfig(
        fromWeek: 9,
        toWeek: 10,
        phase: 'Finální rýsování',
        mainSets: '3',
        mainReps: '5–8',
        mainRir: '1–2',
        accSets: '3',
        accReps: '12–15',
        accRir: '0–1',
        rest: 'hlavní cvik 2 min, supersérie 45–60 s',
        circuitRounds: '5',
        circuitRest: '45 s',
        cardio:
            '12 000+ kroků denně + 4–5× týdně 40 min kardio nízké intenzity.',
        supersets: true,
        dropSet: true,
      ),
      // Týden 11: finální rýsování s nižším objemem (únava v deficitu).
      _PrepWeekConfig(
        fromWeek: 11,
        toWeek: 11,
        phase: 'Finální rýsování',
        mainSets: '3',
        mainReps: '5–8',
        mainRir: '2',
        accSets: '2',
        accReps: '12–15',
        accRir: '1',
        rest: 'hlavní cvik 2 min, supersérie 45–60 s',
        circuitRounds: '4',
        circuitRest: '45 s',
        cardio:
            '12 000+ kroků denně + 4× týdně 40 min kardio nízké intenzity.',
        supersets: true,
        dropSet: true,
      ),
      // Týden 12: peak / natáčení – jen pumpa, žádné selhání ani nové cviky.
      _PrepWeekConfig(
        fromWeek: 12,
        toWeek: 12,
        phase: 'Peak / natáčení',
        mainSets: '2',
        mainReps: '8',
        mainRir: '3',
        accSets: '2',
        accReps: '12–15',
        accRir: '2–3',
        rest: '60 s',
        circuitRounds: '2',
        circuitRest: '90 s',
        cardio:
            '8 000–10 000 kroků denně, žádné další kardio – svaly se mají doplnit.',
        supersets: false,
        dropSet: false,
      ),
    ];

    final currentWeek = HollywoodPrep.weekFor(shootDate) ?? 1;
    final days = <CustomTrainingDay>[];

    for (var week = currentWeek; week <= HollywoodPrep.totalWeeks; week++) {
      final c = weeks.firstWhere(
        (w) => week >= w.fromWeek && week <= w.toWeek,
      );

      final weekEnd = shootDate.subtract(
        Duration(days: (HollywoodPrep.totalWeeks - week) * 7),
      );
      final weekStart = weekEnd.subtract(const Duration(days: 6));
      final weekLabel =
          'Týden $week (${_fmtDate(weekStart)} – ${_fmtDate(weekEnd)})';

      final info = 'Fáze: ${c.phase}\n'
          '${HollywoodPrep.name} – natáčení ${_fmtDate(shootDate)}\n'
          'Pauzy: ${c.rest}\n'
          'Kardio: ${c.cardio}';

      CustomTrainingExercise mainLift(String name) => CustomTrainingExercise(
            customName: name,
            sets: c.mainSets,
            reps: c.mainReps,
            rir: c.mainRir,
            note: '$info\n'
                'Hlavní cvik – drž nebo zvyšuj váhu, síla v deficitu drží svaly.',
          );

      CustomTrainingExercise acc(String name, {String? note, String? reps}) =>
          CustomTrainingExercise(
            customName: name,
            sets: c.accSets,
            reps: reps ?? c.accReps,
            rir: c.accRir,
            note: note,
          );

      final superA =
          c.supersets ? 'Supersérie A s následujícím cvikem.' : null;
      final drop = c.dropSet
          ? 'Poslední série jako drop set (−30 % váhy, do technického selhání).'
          : null;

      CustomTrainingExercise circuit(String name, String reps, {String? note}) =>
          CustomTrainingExercise(
            customName: 'Kruh: $name',
            sets: c.circuitRounds,
            reps: reps,
            rir: '2',
            note: note,
          );

      final isShootWeek = week == HollywoodPrep.totalWeeks;

      days.addAll([
        CustomTrainingDay(
          name: '$weekLabel – Den 1 – Hrudník + ramena',
          exercises: [
            mainLift('Bench press na šikmé lavici (30°)'),
            acc('Tlaky s jednoručkami na rovné lavici', note: superA),
            acc('Rozpažky na kladce zdola nahoru (horní hrudník)'),
            acc('Upažování s jednoručkami', note: drop ?? superA),
            acc('Tlak s jednoručkami nad hlavu vsedě'),
            acc('Triceps – stahování horní kladky', note: drop),
          ],
        ),
        CustomTrainingDay(
          name: '$weekLabel – Den 2 – Záda + biceps (šířka, V-tvar)',
          exercises: [
            mainLift('Shyby nadhmatem (se zátěží, jinak stahování horní kladky)'),
            acc('Přítahy jednoručky v předklonu', note: superA),
            acc('Stahování horní kladky úzkým úchopem'),
            acc('Face pull na kladce (zadní ramena, držení těla)'),
            acc('Bicepsový zdvih s EZ činkou', note: drop ?? superA),
            acc('Kladivové zdvihy s jednoručkami'),
          ],
        ),
        CustomTrainingDay(
          name: '$weekLabel – Den 3 – Nohy + břicho',
          exercises: [
            mainLift('Dřep s velkou činkou (nebo hacken dřep)'),
            acc('Rumunský mrtvý tah', note: superA),
            acc('Bulharské výpady', reps: '8–12 na nohu'),
            acc('Zakopávání na stroji', note: drop),
            acc('Výpony na lýtka ve stoje'),
            acc('Zvedání nohou ve visu', note: superA),
            acc('Plank / břišní kolečko', reps: '30–45 s / 10–12'),
          ],
        ),
        CustomTrainingDay(
          name: '$weekLabel – Den 4 – Ramena + paže (V-tvar)',
          exercises: [
            mainLift('Tlak nad hlavu s velkou činkou vestoje'),
            acc('Upažování na kladce jednoruč', note: drop ?? superA),
            acc('Zadní ramena – reverse fly na stroji'),
            acc('Kliky na bradlech', note: superA),
            acc('Bicepsový zdvih s jednoručkami na šikmé lavici'),
            acc('Francouzský tlak s EZ činkou', note: drop),
            acc('Krčení ramen s jednoručkami'),
          ],
        ),
        if (isShootWeek)
          CustomTrainingDay(
            name: '$weekLabel – Den natáčení – pump-up před záběrem',
            exercises: [
              CustomTrainingExercise(
                customName: 'Kliky',
                sets: '2–3',
                reps: '15',
                rir: '3',
                note: '$info\n'
                    '10–15 min před záběrem jen na prokrvení svalů. '
                    'Žádné selhání, žádná únava.',
              ),
              const CustomTrainingExercise(
                customName: 'Upažování s gumou',
                sets: '2',
                reps: '20',
                rir: '3',
              ),
              const CustomTrainingExercise(
                customName: 'Roztahování gumy před hrudníkem (lopatky)',
                sets: '2',
                reps: '20',
                rir: '3',
              ),
              const CustomTrainingExercise(
                customName: 'Bicepsový zdvih s gumou',
                sets: '2',
                reps: '20',
                rir: '3',
              ),
            ],
          )
        else
          CustomTrainingDay(
            name: '$weekLabel – Den 5 – Kruhový trénink + kondice',
            exercises: [
              CustomTrainingExercise(
                customName: 'Mrtvý tah (technicky, bez selhání)',
                sets: c.mainSets,
                reps: '5',
                rir: '2–3',
                note: '$info\n'
                    'Pak kruh: ${c.circuitRounds} kola, cviky bez pauzy, '
                    'mezi koly ${c.circuitRest}.',
              ),
              circuit('Kettlebell swing', '15'),
              circuit('Kliky', '12–20'),
              circuit('Obrácený přítah (TRX / nízká hrazda)', '10–15'),
              circuit('Goblet dřep', '15'),
              circuit('Farmářská chůze', '30–40 m'),
              circuit('Horolezec (mountain climbers)', '30 s'),
            ],
          ),
      ]);
    }

    days.add(
      CustomTrainingDay(
        name: 'Instrukce – ${HollywoodPrep.name}',
        exercises: [
          CustomTrainingExercise(
            customName: 'Datum natáčení / focení',
            sets: '1',
            reps: _fmtDate(shootDate),
            rir: '—',
            note:
                'Všechny týdny jsou rozpočítané zpětně od tohoto data. '
                'Jídelníček ${HollywoodPrep.name} (Jídelníčky) používá stejné '
                'datum a stejné fáze.',
          ),
          const CustomTrainingExercise(
            customName: 'Týdny 1–4',
            sets: '1',
            reps: 'Stavba',
            rir: '—',
            note:
                'Hypertrofie s mírným deficitem. Těžké hlavní cviky, doplňky '
                '8–12 opakování. Cíl: plné svaly před rýsováním.',
          ),
          const CustomTrainingExercise(
            customName: 'Týdny 5–8',
            sets: '1',
            reps: 'Rýsování',
            rir: '—',
            note:
                'Hlavní cviky stále těžké (drží svaly), doplňky v supersériích '
                '10–15 opakování, víc kroků a kardia.',
          ),
          const CustomTrainingExercise(
            customName: 'Týdny 9–11',
            sets: '1',
            reps: 'Finální rýsování',
            rir: '—',
            note:
                'Nejpřísnější fáze. Krátké pauzy, drop sety, nejvíc kardia. '
                'Síla se nemá ztrácet – když výrazně klesá, uber kardio, ne '
                'hlavní cviky. V týdnu 11 méně sérií kvůli únavě.',
          ),
          const CustomTrainingExercise(
            customName: 'Týden 12',
            sets: '1',
            reps: 'Peak / natáčení',
            rir: '—',
            note:
                'Jen lehké tréninky na pumpu, žádné selhání, žádné nové cviky '
                '(svalovka by byla vidět). Jídlo na údržbě s vyššími sacharidy '
                '– svaly se doplní a nejsou „prázdné“. V den natáčení krátký '
                'pump-up těsně před záběrem.',
          ),
        ],
      ),
    );

    return days;
  }

  /// Týden přípravy 1–[totalWeeks] počítaný zpětně od data závodu
  /// (poslední týden = 7 dní včetně dne závodu), `null` = příprava ještě
  /// nezačala nebo už skončila.
  int? _prepWeekFor(DateTime eventDate, int totalWeeks) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final event = DateTime(eventDate.year, eventDate.month, eventDate.day);
    final daysToEvent = event.difference(today).inDays;
    if (daysToEvent < 0) return null;
    final week = totalWeeks - daysToEvent ~/ 7;
    return week < 1 ? null : week;
  }

const int _bikiniWeeks = BikiniPrep.totalWeeks;

  Future<void> _insertBikiniPlan(
    BuildContext context,
    WidgetRef ref,
    String clientId,
  ) async {
    final l10n = AppLocalizations.of(context)!;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Výchozí: závod za 16 týdnů (dnes = 1. týden přípravy).
    final meetDate = await showDatePicker(
      context: context,
      initialDate: today.add(const Duration(days: _bikiniWeeks * 7 - 1)),
      firstDate: today,
      lastDate: today.add(const Duration(days: 730)),
      helpText: l10n.meetDate,
    );

    if (meetDate == null) return;
    if (!context.mounted) return;

    final plans = ref.read(customTrainingPlanProvider);
    final newName = _buildUniquePlanName(
      '👙 Příprava na závody – bikini fitness',
      plans.where((p) => p.clientId == clientId).toList(),
    );

    await ref.read(customTrainingPlanProvider.notifier).createPlan(
          clientId: clientId,
          name: newName,
          description:
              'Kompletní ${_bikiniWeeks}týdenní příprava na závody v bikini fitness '
              '(${_fmtDate(meetDate)}): hýždě a ramena, útlý pas, pózování, '
              'peak week.',
          category: CustomTrainingCategory.bikini,
          type: CustomTrainingPlanType.bikiniMeetPrep,
          meetDate: meetDate,
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
        SnackBar(content: Text(l10n.planCreationFailed)),
      );
      return;
    }

    final notifier = ref.read(customTrainingPlanProvider.notifier);
    final templateDays = _bikiniPlanDays(meetDate);

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

  /// Bikini fitness – 16 týdnů zpětně od data závodu, 5 tréninků týdně.
  ///
  /// Hodnotí se proporce: kulaté hýždě, ramena a záda (tvar X), útlý pas,
  /// nepříliš objemná stehna a celkový dojem včetně pózování. Proto:
  /// nejvíc práce na hýždě a ramena, kvadricepsy jen udržovat, žádné
  /// šikmé břišní se zátěží, pózování od začátku a každý týden víc.
  List<CustomTrainingDay> _bikiniPlanDays(DateTime meetDate) {
    const weeks = [
      // Týdny 1–6: stavba – tvar hýždí a ramen, mírný deficit.
      _PrepWeekConfig(
        fromWeek: 1,
        toWeek: 6,
        phase: 'Stavba tvaru',
        mainSets: '4',
        mainReps: '8–10',
        mainRir: '1–2',
        accSets: '3',
        accReps: '10–15',
        accRir: '1–2',
        rest: 'hlavní cvik 2 min, doplňky 60–90 s',
        circuitRounds: '3',
        circuitRest: '60 s',
        cardio:
            '8 000–10 000 kroků denně + 2× týdně 30 min kardio nízké intenzity.',
        supersets: false,
        dropSet: false,
        posing: '2× týdně 10 min – základní postoje zepředu, z boku, zezadu.',
      ),
      // Týdny 7–12: rýsování – supersérie, víc kardia.
      _PrepWeekConfig(
        fromWeek: 7,
        toWeek: 12,
        phase: 'Rýsování',
        mainSets: '4',
        mainReps: '8–10',
        mainRir: '1–2',
        accSets: '3',
        accReps: '12–15',
        accRir: '1',
        rest: 'hlavní cvik 2 min, supersérie 60 s',
        circuitRounds: '4',
        circuitRest: '45–60 s',
        cardio:
            '10 000–12 000 kroků denně + 3–4× týdně 30–40 min kardio nízké intenzity.',
        supersets: true,
        dropSet: false,
        posing:
            'Denně 15 min + 2× týdně nácvik chůze (T-walk) v botách na podpatku.',
      ),
      // Týdny 13–14: finální rýsování.
      _PrepWeekConfig(
        fromWeek: 13,
        toWeek: 14,
        phase: 'Finální rýsování',
        mainSets: '3',
        mainReps: '8–10',
        mainRir: '1–2',
        accSets: '3',
        accReps: '15',
        accRir: '0–1',
        rest: 'hlavní cvik 2 min, supersérie 45 s',
        circuitRounds: '4',
        circuitRest: '45 s',
        cardio:
            '12 000+ kroků denně + 5× týdně 40 min kardio nízké intenzity.',
        supersets: true,
        dropSet: true,
        posing:
            'Denně 20–30 min – celá rutina na podpatcích, přechody mezi pózami, úsměv.',
      ),
      // Týden 15: finální rýsování s nižším objemem (únava v deficitu).
      _PrepWeekConfig(
        fromWeek: 15,
        toWeek: 15,
        phase: 'Finální rýsování',
        mainSets: '3',
        mainReps: '8–10',
        mainRir: '2',
        accSets: '2',
        accReps: '15',
        accRir: '1',
        rest: 'hlavní cvik 2 min, supersérie 45 s',
        circuitRounds: '3',
        circuitRest: '45 s',
        cardio:
            '12 000+ kroků denně + 4× týdně 40 min kardio nízké intenzity.',
        supersets: true,
        dropSet: true,
        posing: 'Denně 30 min – celá rutina, zkouška kostýmu a bot.',
      ),
      // Týden 16: peak week / závod.
      _PrepWeekConfig(
        fromWeek: 16,
        toWeek: 16,
        phase: 'Peak week / závod',
        mainSets: '2',
        mainReps: '10',
        mainRir: '3',
        accSets: '2',
        accReps: '15',
        accRir: '2–3',
        rest: '60 s',
        circuitRounds: '2',
        circuitRest: '90 s',
        cardio:
            '8 000–10 000 kroků denně, žádné další kardio; poslední 2 dny před závodem jen lehká chůze.',
        supersets: false,
        dropSet: false,
        posing:
            'Denně celá rutina – příchod na pódium, otočky, odchod. Poslední den jen krátce.',
      ),
    ];

    final currentWeek = _prepWeekFor(meetDate, _bikiniWeeks) ?? 1;
    final days = <CustomTrainingDay>[];

    for (var week = currentWeek; week <= _bikiniWeeks; week++) {
      final c = weeks.firstWhere(
        (w) => week >= w.fromWeek && week <= w.toWeek,
      );

      final weekEnd = meetDate.subtract(
        Duration(days: (_bikiniWeeks - week) * 7),
      );
      final weekStart = weekEnd.subtract(const Duration(days: 6));
      final weekLabel =
          'Týden $week (${_fmtDate(weekStart)} – ${_fmtDate(weekEnd)})';

      final info = 'Fáze: ${c.phase}\n'
          'Bikini fitness – závod ${_fmtDate(meetDate)}\n'
          'Pauzy: ${c.rest}\n'
          'Kardio: ${c.cardio}\n'
          'Pózování: ${c.posing}';

      CustomTrainingExercise mainLift(String name) => CustomTrainingExercise(
            customName: name,
            sets: c.mainSets,
            reps: c.mainReps,
            rir: c.mainRir,
            note: '$info\n'
                'Hlavní cvik – drž nebo zvyšuj váhu, síla v deficitu drží svaly.',
          );

      CustomTrainingExercise acc(String name, {String? note, String? reps}) =>
          CustomTrainingExercise(
            customName: name,
            sets: c.accSets,
            reps: reps ?? c.accReps,
            rir: c.accRir,
            note: note,
          );

      CustomTrainingExercise circuit(String name, String reps, {String? note}) =>
          CustomTrainingExercise(
            customName: 'Kruh: $name',
            sets: c.circuitRounds,
            reps: reps,
            rir: '2',
            note: note,
          );

      final posing = CustomTrainingExercise(
        customName: 'Pózování',
        sets: '1',
        reps: 'podle fáze',
        rir: '—',
        note: c.posing,
      );

      final superA =
          c.supersets ? 'Supersérie A s následujícím cvikem.' : null;
      final drop = c.dropSet
          ? 'Poslední série jako drop set (−30 % váhy, do technického selhání).'
          : null;

      final isMeetWeek = week == _bikiniWeeks;

      days.addAll([
        CustomTrainingDay(
          name: '$weekLabel – Den 1 – Hýždě + zadní strana stehen',
          exercises: [
            mainLift('Hip thrust s velkou činkou'),
            acc('Rumunský mrtvý tah', note: superA),
            acc(
              'Bulharské výpady (trup v předklonu – důraz na hýždě)',
              reps: '10–12 na nohu',
            ),
            acc('Zakopávání na stroji', note: drop),
            acc(
              'Unožování na stroji / s gumou (střední hýžďový sval)',
              reps: '15–20',
              note: superA,
            ),
            acc('Hyperextenze s důrazem na hýždě'),
            posing,
          ],
        ),
        CustomTrainingDay(
          name: '$weekLabel – Den 2 – Ramena + záda (tvar X)',
          exercises: [
            mainLift('Tlak s jednoručkami nad hlavu vsedě'),
            acc('Upažování s jednoručkami', note: drop ?? superA),
            acc('Stahování horní kladky širokým úchopem'),
            acc('Přítahy na kladce vsedě', note: superA),
            acc('Zadní ramena – reverse fly na stroji'),
            acc('Face pull na kladce (držení těla)'),
            posing,
          ],
        ),
        CustomTrainingDay(
          name: '$weekLabel – Den 3 – Nohy + hýždě',
          exercises: [
            mainLift('Dřep s velkou činkou (široký postoj, hluboko)'),
            acc(
              'Leg press – chodidla vysoko a široko (hýždě)',
              note: superA,
            ),
            acc('Zanožování na kladce (kickback)', reps: '12–15 na nohu'),
            acc(
              'Předkopávání',
              note: 'Kvadricepsy jen udržovat – stehna nemají přibírat objem.',
            ),
            acc('Abdukce na stroji', reps: '15–20', note: drop),
            acc('Výpony na lýtka ve stoje'),
            posing,
          ],
        ),
        CustomTrainingDay(
          name: '$weekLabel – Den 4 – Horní tělo + paže',
          exercises: [
            mainLift('Shyby podhmatem (s dopomocí) / stahování kladky'),
            acc('Upažování na kladce jednoruč', note: drop ?? superA),
            acc('Tlaky s jednoručkami na šikmé lavici'),
            acc('Přítahy jednoručky v předklonu', note: superA),
            acc('Bicepsový zdvih s jednoručkami'),
            acc('Triceps – tlak kladky nad hlavou'),
            posing,
          ],
        ),
        if (isMeetWeek)
          CustomTrainingDay(
            name: '$weekLabel – Den závodu – pump-up v zákulisí',
            exercises: [
              CustomTrainingExercise(
                customName: 'Glute bridge s gumou',
                sets: '2',
                reps: '20',
                rir: '3',
                note: '$info\n'
                    '10–15 min před nástupem jen na prokrvení. '
                    'Žádné selhání, žádná únava.',
              ),
              const CustomTrainingExercise(
                customName: 'Upažování s gumou',
                sets: '2',
                reps: '20',
                rir: '3',
              ),
              const CustomTrainingExercise(
                customName: 'Stahování gumy nad hlavou (záda)',
                sets: '2',
                reps: '20',
                rir: '3',
              ),
              const CustomTrainingExercise(
                customName: 'Kliky na kolenou',
                sets: '2',
                reps: '12–15',
                rir: '3',
              ),
              const CustomTrainingExercise(
                customName: 'Pózování – celá rutina',
                sets: '1',
                reps: '1× před nástupem',
                rir: '—',
                note: 'Klid, dech, úsměv. Stáhnutý pas, otevřená ramena.',
              ),
            ],
          )
        else
          CustomTrainingDay(
            name: '$weekLabel – Den 5 – Hýždě + břicho + kondice',
            exercises: [
              CustomTrainingExercise(
                customName: 'Hip thrust s výdrží nahoře (2 s)',
                sets: c.mainSets,
                reps: '10–12',
                rir: '2',
                note: '$info\n'
                    'Pak kruh: ${c.circuitRounds} kola, cviky bez pauzy, '
                    'mezi koly ${c.circuitRest}.\n'
                    'Žádné šikmé břišní se zátěží – rozšiřují pas.',
              ),
              circuit('Unožování v kleku s gumou', '20 na nohu'),
              circuit('Chůze v podřepu s gumou', '20 kroků'),
              circuit('Kettlebell swing', '15'),
              circuit('Zvedání nohou vleže', '15'),
              circuit('Plank', '30–45 s'),
              circuit(
                'Vakuum břicha (vtažení pupku)',
                '20 s',
                note: 'Učí stáhnout pas při pózování.',
              ),
              posing,
            ],
          ),
      ]);
    }

    days.add(
      CustomTrainingDay(
        name: 'Instrukce – příprava na bikini fitness',
        exercises: [
          CustomTrainingExercise(
            customName: 'Datum závodu',
            sets: '1',
            reps: _fmtDate(meetDate),
            rir: '—',
            note:
                'Všech $_bikiniWeeks týdnů je rozpočítaných zpětně od tohoto data. '
                'Když je závod dřív, plán začíná rovnou správným týdnem. '
                'Jídelníček Bikini fitness (Jídelníčky) používá stejné datum '
                'a stejné fáze.',
          ),
          const CustomTrainingExercise(
            customName: 'Týdny 1–6',
            sets: '1',
            reps: 'Stavba tvaru',
            rir: '—',
            note:
                'Nejvíc práce na hýždě, ramena a šířku zad (tvar X). '
                'Kvadricepsy a paže jen udržovat. Mírný deficit.',
          ),
          const CustomTrainingExercise(
            customName: 'Týdny 7–12',
            sets: '1',
            reps: 'Rýsování',
            rir: '—',
            note:
                'Hlavní cviky stále těžké, doplňky v supersériích, víc kroků '
                'a kardia. Pózování denně.',
          ),
          const CustomTrainingExercise(
            customName: 'Týdny 13–15',
            sets: '1',
            reps: 'Finální rýsování',
            rir: '—',
            note:
                'Nejpřísnější fáze – drop sety, nejvíc kardia, celá rutina na '
                'podpatcích. V týdnu 15 méně sérií kvůli únavě. Když výrazně '
                'klesá síla, uber kardio, ne hlavní cviky.',
          ),
          const CustomTrainingExercise(
            customName: 'Týden 16',
            sets: '1',
            reps: 'Peak week / závod',
            rir: '—',
            note:
                'Jen lehké tréninky na pumpu, žádné selhání ani nové cviky. '
                'Poslední 2 dny bez kardia. V den závodu krátký pump-up v '
                'zákulisí a pózování.',
          ),
          const CustomTrainingExercise(
            customName: 'Pas a břicho',
            sets: '1',
            reps: 'Důležité',
            rir: '—',
            note:
                'Bikini hodnotí útlý pas. Nedělej šikmé břišní se zátěží ani '
                'těžké mrtvé tahy navíc. Vakuum břicha a plank ano.',
          ),
        ],
      ),
    );

    return days;
  }

const int _gluteWeeks = 12;

  Future<void> _insertGlutePlan(
    BuildContext context,
    WidgetRef ref,
    String clientId,
  ) async {
    final l10n = AppLocalizations.of(context)!;

    final plans = ref.read(customTrainingPlanProvider);
    final newName = _buildUniquePlanName(
      '🍑 ${l10n.gluteTitle}',
      plans.where((p) => p.clientId == clientId).toList(),
    );

    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, now.day);

    await ref.read(customTrainingPlanProvider.notifier).createPlan(
          clientId: clientId,
          name: newName,
          description:
              '${_gluteWeeks}týdenní program na růst a tvar hýždí: 3 tréninky '
              'hýždí + 1 horní tělo týdně, progrese a odlehčovací týden.',
          category: CustomTrainingCategory.glutes,
          type: CustomTrainingPlanType.gluteBuilder,
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
        SnackBar(content: Text(l10n.planCreationFailed)),
      );
      return;
    }

    final notifier = ref.read(customTrainingPlanProvider.notifier);
    final templateDays = _glutePlanDays(startDate);

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

  /// Kulatý zadek – 12 týdnů od dneška, 4 tréninky týdně (3× hýždě,
  /// 1× horní tělo pro proporce).
  ///
  /// Hýždě rostou z progresivního přetížení v celém rozsahu pohybu:
  /// těžký hip thrust (maximální stah nahoře), cviky v protažení (rumunský
  /// mrtvý tah, výpady, hluboký dřep) a střední hýžďový sval (unožování,
  /// abdukce) pro „kulatý“ tvar z boku. Každý 12. týden odlehčení, pak se
  /// cyklus opakuje s vyššími vahami.
  List<CustomTrainingDay> _glutePlanDays(DateTime startDate) {
    const weeks = [
      _PrepWeekConfig(
        fromWeek: 1,
        toWeek: 4,
        phase: 'Základ a technika',
        mainSets: '3',
        mainReps: '8–10',
        mainRir: '2–3',
        accSets: '3',
        accReps: '10–15',
        accRir: '2',
        rest: 'hlavní cvik 2–3 min, doplňky 60–90 s',
        circuitRounds: '2',
        circuitRest: '60 s',
        cardio:
            '7 000–10 000 kroků denně, kardio max. 2× týdně 20–30 min chůze (nebrzdí růst).',
        supersets: false,
        dropSet: false,
      ),
      _PrepWeekConfig(
        fromWeek: 5,
        toWeek: 8,
        phase: 'Objem',
        mainSets: '4',
        mainReps: '8–10',
        mainRir: '1–2',
        accSets: '4',
        accReps: '10–15',
        accRir: '1–2',
        rest: 'hlavní cvik 2–3 min, doplňky 60–90 s',
        circuitRounds: '3',
        circuitRest: '60 s',
        cardio:
            '7 000–10 000 kroků denně, kardio max. 2× týdně 20–30 min chůze.',
        supersets: false,
        dropSet: false,
      ),
      _PrepWeekConfig(
        fromWeek: 9,
        toWeek: 11,
        phase: 'Intenzita',
        mainSets: '4',
        mainReps: '6–8',
        mainRir: '1',
        accSets: '3',
        accReps: '10–15',
        accRir: '0–1',
        rest: 'hlavní cvik 3 min, doplňky 60–90 s',
        circuitRounds: '3',
        circuitRest: '45 s',
        cardio:
            '7 000–10 000 kroků denně, kardio max. 2× týdně 20–30 min chůze.',
        supersets: false,
        dropSet: true,
      ),
      _PrepWeekConfig(
        fromWeek: 12,
        toWeek: 12,
        phase: 'Odlehčení (deload)',
        mainSets: '2',
        mainReps: '8–10',
        mainRir: '3–4',
        accSets: '2',
        accReps: '12–15',
        accRir: '3',
        rest: '90 s',
        circuitRounds: '2',
        circuitRest: '60 s',
        cardio: '7 000–10 000 kroků denně.',
        supersets: false,
        dropSet: false,
      ),
    ];

    final days = <CustomTrainingDay>[];

    for (var week = 1; week <= _gluteWeeks; week++) {
      final c = weeks.firstWhere(
        (w) => week >= w.fromWeek && week <= w.toWeek,
      );

      final weekStart = startDate.add(Duration(days: (week - 1) * 7));
      final weekEnd = weekStart.add(const Duration(days: 6));
      final weekLabel =
          'Týden $week (${_fmtDate(weekStart)} – ${_fmtDate(weekEnd)})';

      final info = 'Fáze: ${c.phase}\n'
          'Pauzy: ${c.rest}\n'
          'Kardio: ${c.cardio}';

      final progression = week == _gluteWeeks
          ? 'Odlehčovací týden – o 20–30 % nižší váhy, žádné selhání.'
          : 'Progrese: když zvládneš horní hranici opakování ve všech '
              'sériích, přidej 2,5–5 kg.';

      CustomTrainingExercise mainLift(String name) => CustomTrainingExercise(
            customName: name,
            sets: c.mainSets,
            reps: c.mainReps,
            rir: c.mainRir,
            note: '$info\n$progression\n'
                'Nahoře 1 s výdrž a maximální stah hýždí, pánev podsazená.',
          );

      CustomTrainingExercise acc(String name, {String? note, String? reps}) =>
          CustomTrainingExercise(
            customName: name,
            sets: c.accSets,
            reps: reps ?? c.accReps,
            rir: c.accRir,
            note: note,
          );

      final drop = c.dropSet
          ? 'Poslední série jako drop set (−30 % váhy, do technického selhání).'
          : null;

      days.addAll([
        CustomTrainingDay(
          name: '$weekLabel – Den 1 – Hýždě těžce',
          exercises: [
            mainLift('Hip thrust s velkou činkou'),
            acc(
              'Rumunský mrtvý tah',
              reps: '8–10',
              note: 'Hýždě v protažení – pomalý spust, záda rovná.',
            ),
            acc(
              'Bulharské výpady (trup v předklonu)',
              reps: '8–12 na nohu',
            ),
            acc('Abdukce na stroji', reps: '15–20', note: drop),
            acc('Hyperextenze s důrazem na hýždě (zakulacená záda)'),
          ],
        ),
        CustomTrainingDay(
          name: '$weekLabel – Den 2 – Horní tělo (proporce)',
          exercises: [
            CustomTrainingExercise(
              customName: 'Tlak s jednoručkami nad hlavu vsedě',
              sets: c.accSets,
              reps: '8–12',
              rir: c.accRir,
              note: '$info\n'
                  'Širší ramena a záda opticky zúží pas a zvýrazní boky.',
            ),
            acc('Stahování horní kladky širokým úchopem'),
            acc('Přítahy na kladce vsedě'),
            acc('Upažování s jednoručkami', reps: '12–20'),
            acc('Kliky (na kolenou nebo klasické)', reps: '8–15'),
            acc('Face pull na kladce'),
          ],
        ),
        CustomTrainingDay(
          name: '$weekLabel – Den 3 – Hýždě objem',
          exercises: [
            mainLift('Dřep s velkou činkou (široký postoj, hluboko)'),
            acc(
              'Leg press – chodidla vysoko a široko',
              note: 'Hluboko, kolena ven – hýždě pracují v protažení.',
            ),
            acc('Zanožování na kladce (kickback)', reps: '12–15 na nohu'),
            acc(
              'Glute bridge jednonož',
              reps: '12–15 na nohu',
              note: drop,
            ),
            acc('Chůze v podřepu s gumou', reps: '20 kroků na stranu'),
          ],
        ),
        CustomTrainingDay(
          name: '$weekLabel – Den 4 – Hýždě pumpa + tvar',
          exercises: [
            CustomTrainingExercise(
              customName: 'Hip thrust s pauzou nahoře (2 s)',
              sets: c.mainSets,
              reps: '12–15',
              rir: c.accRir,
              note: '$info\n'
                  'Lehčí než v Den 1 – důraz na stah, ne na váhu.',
            ),
            acc('Sumo mrtvý tah', reps: '8–10'),
            acc('Výstupy na vysokou bednu', reps: '10–12 na nohu'),
            acc(
              'Abdukce vsedě v předklonu (horní část hýždí)',
              reps: '15–20',
              note: drop,
            ),
            acc(
              'Frog pumps (žabí mosty)',
              reps: '30',
              note: 'Na konec – pumpa do „pálení“.',
            ),
          ],
        ),
      ]);
    }

    days.add(
      const CustomTrainingDay(
        name: 'Instrukce – Kulatý zadek',
        exercises: [
          CustomTrainingExercise(
            customName: 'Týdny 1–4',
            sets: '1',
            reps: 'Základ a technika',
            rir: '—',
            note:
                'Nauč se cítit hýždě v každém cviku (mind-muscle). Série daleko '
                'od selhání, důraz na techniku a plný rozsah pohybu.',
          ),
          CustomTrainingExercise(
            customName: 'Týdny 5–8',
            sets: '1',
            reps: 'Objem',
            rir: '—',
            note:
                'Víc sérií a blíž k selhání. Každý týden přidávej váhu nebo '
                'opakování.',
          ),
          CustomTrainingExercise(
            customName: 'Týdny 9–11',
            sets: '1',
            reps: 'Intenzita',
            rir: '—',
            note:
                'Těžší hlavní cviky (6–8 opakování) a drop sety na doplňcích.',
          ),
          CustomTrainingExercise(
            customName: 'Týden 12',
            sets: '1',
            reps: 'Odlehčení',
            rir: '—',
            note:
                'Nižší váhy i počet sérií – tělo zregeneruje a svaly rostou. '
                'Pak vlož plán znovu a pokračuj s vyššími vahami.',
          ),
          CustomTrainingExercise(
            customName: 'Jídlo a regenerace',
            sets: '1',
            reps: 'Důležité',
            rir: '—',
            note:
                'Svaly nerostou v deficitu – jez na údržbě nebo v mírném '
                'přebytku (+5–10 %), bílkoviny 1,6–2,2 g/kg, spánek 7–9 h. '
                'Mezi tréninky hýždí aspoň 1 den pauza. Jídelníček Kulatý '
                'zadek (Jídelníčky) to spočítá automaticky.',
          ),
          CustomTrainingExercise(
            customName: 'Měření pokroku',
            sets: '1',
            reps: 'Každé 4 týdny',
            rir: '—',
            note:
                'Obvod hýždí (nejširší místo), fotky z boku a zezadu ve stejném '
                'světle, váhy v hip thrustu.',
          ),
        ],
      ),
    );

    return days;
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


class _PrepWeekConfig {
  final int fromWeek;
  final int toWeek;
  final String phase;

  final String mainSets;
  final String mainReps;
  final String mainRir;

  final String accSets;
  final String accReps;
  final String accRir;

  final String rest;
  final String circuitRounds;
  final String circuitRest;
  final String cardio;

  final bool supersets;
  final bool dropSet;

  /// Nácvik pózování (bikini fitness), jinak `null`.
  final String? posing;

  const _PrepWeekConfig({
    required this.fromWeek,
    required this.toWeek,
    required this.phase,
    required this.mainSets,
    required this.mainReps,
    required this.mainRir,
    required this.accSets,
    required this.accReps,
    required this.accRir,
    required this.rest,
    required this.circuitRounds,
    required this.circuitRest,
    required this.cardio,
    required this.supersets,
    required this.dropSet,
    this.posing,
  });
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

    case CustomTrainingCategory.hollywood:
      return l10n.hollywoodTitle;

    case CustomTrainingCategory.bikini:
      return l10n.bikiniTitle;

    case CustomTrainingCategory.glutes:
      return l10n.gluteTitle;

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