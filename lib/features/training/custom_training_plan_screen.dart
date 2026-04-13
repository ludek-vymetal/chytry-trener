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
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Zatím nemáš žádný vlastní plán.\n\n'
                          'Klikni na „Nový plán“ a vytvoř první.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () =>
                              _insertConstantinCutPlan(context, ref, clientId),
                          icon: const Icon(Icons.local_fire_department),
                          label: const Text('🔥 VLOŽIT 90DENNÍ VYRÝSOVÁNÍ'),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.tonalIcon(
                          onPressed: () => _insertPowerliftingMeetPrepPlan(
                            context,
                            ref,
                            clientId,
                          ),
                          icon: const Icon(Icons.fitness_center),
                          label: const Text(
                            '🏋️ VLOŽIT PŘÍPRAVU NA ZÁVODY – TROJBOJ',
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    FilledButton.icon(
                      onPressed: () =>
                          _insertConstantinCutPlan(context, ref, clientId),
                      icon: const Icon(Icons.local_fire_department),
                      label: const Text('🔥 VLOŽIT 90DENNÍ VYRÝSOVÁNÍ'),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.tonalIcon(
                      onPressed: () => _insertPowerliftingMeetPrepPlan(
                        context,
                        ref,
                        clientId,
                      ),
                      icon: const Icon(Icons.fitness_center),
                      label: const Text(
                        '🏋️ VLOŽIT PŘÍPRAVU NA ZÁVODY – TROJBOJ',
                      ),
                    ),
                    const SizedBox(height: 16),
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

  Future<void> _insertConstantinCutPlan(
    BuildContext context,
    WidgetRef ref,
    String clientId,
  ) async {
    final plans = ref.read(customTrainingPlanProvider);
    final newName = _buildUniquePlanName(
      '🔥 90denní vyrýsování',
      plans.where((p) => p.clientId == clientId).toList(),
    );

    await ref.read(customTrainingPlanProvider.notifier).createPlan(
          clientId: clientId,
          name: newName,
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
        const SnackBar(
          content: Text('Plán se nepodařilo vytvořit.'),
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
    final plans = ref.read(customTrainingPlanProvider);
    final newName = _buildUniquePlanName(
      '🏋️ Příprava na závody – silový trojboj',
      plans.where((p) => p.clientId == clientId).toList(),
    );

    await ref.read(customTrainingPlanProvider.notifier).createPlan(
          clientId: clientId,
          name: newName,
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
        const SnackBar(
          content: Text('Plán se nepodařilo vytvořit.'),
        ),
      );
      return;
    }

    final notifier = ref.read(customTrainingPlanProvider.notifier);
    final templateDays = _powerliftingMeetPrepDays();

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
            note:
                'Střídej cviky 20 minut. Pauza mezi cviky 20 s. Fáze 1.',
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

  List<CustomTrainingDay> _powerliftingMeetPrepDays() {
    return [
      CustomTrainingDay(
        name: 'Den 1 – Dřep těžce + bench objem',
        exercises: const [
          CustomTrainingExercise(
            customName: 'Dřep – závodní styl',
            sets: '6',
            reps: '2–6 dle týdne',
            rir: '1–3',
            note:
                'Hlavní lift dne. Postupně navyšuj intenzitu, technika musí zůstat čistá.',
          ),
          CustomTrainingExercise(
            customName: 'Bench press – objem',
            sets: '5',
            reps: '5–8',
            rir: '2–3',
            note: 'Střední váha, důraz na kontrolu dráhy a stabilitu.',
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
        name: 'Den 2 – Bench těžce + záda',
        exercises: const [
          CustomTrainingExercise(
            customName: 'Bench press – závodní pauza',
            sets: '6',
            reps: '2–6 dle týdne',
            rir: '1–3',
            note:
                'Hlavní bench den. Pauza na hrudníku, pevný setup, tlak do země.',
          ),
          CustomTrainingExercise(
            customName: 'Přítahy v předklonu',
            sets: '4',
            reps: '6–10',
            rir: '2',
          ),
          CustomTrainingExercise(
            customName: 'Shyby / horní kladka',
            sets: '4',
            reps: '6–10',
            rir: '2',
          ),
          CustomTrainingExercise(
            customName: 'Triceps',
            sets: '3',
            reps: '10–15',
            rir: '2–3',
          ),
        ],
      ),
      CustomTrainingDay(
        name: 'Den 3 – Mrtvý tah těžce + dřep lehce',
        exercises: const [
          CustomTrainingExercise(
            customName: 'Mrtvý tah – závodní styl',
            sets: '5',
            reps: '2–5 dle týdne',
            rir: '1–3',
            note:
                'Hlavní deadlift den. Nejezdi techniku přes hranu, prioritou je kvalita pokusu.',
          ),
          CustomTrainingExercise(
            customName: 'Dřep – lehčí technika / pauza',
            sets: '4',
            reps: '3–5',
            rir: '2–3',
            note: 'Technická práce, ne maximální zatížení.',
          ),
          CustomTrainingExercise(
            customName: 'Hamstringy',
            sets: '3',
            reps: '8–12',
            rir: '2–3',
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
        name: 'Den 4 – Bench technika + doplňky',
        exercises: const [
          CustomTrainingExercise(
            customName: 'Bench press – lehčí technika',
            sets: '5',
            reps: '4–6',
            rir: '2–3',
            note: 'Důraz na rychlost činky, setup, dráhu a leg drive.',
          ),
          CustomTrainingExercise(
            customName: 'Tlaky nad hlavu / ramena',
            sets: '3',
            reps: '6–10',
            rir: '2–3',
          ),
          CustomTrainingExercise(
            customName: 'Biceps',
            sets: '3',
            reps: '10–15',
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
      CustomTrainingDay(
        name: 'Instrukce k cyklu',
        exercises: const [
          CustomTrainingExercise(
            customName: 'Týdny 1–3',
            sets: '1',
            reps: 'Objem',
            rir: '—',
            note:
                'Drž vyšší počet opakování v rozmezí 5–6, buduj techniku a pracovní kapacitu.',
          ),
          CustomTrainingExercise(
            customName: 'Týdny 4–6',
            sets: '1',
            reps: 'Intenzifikace',
            rir: '—',
            note:
                'Postupně snižuj opakování k 3–4 a zvyšuj pracovní váhy.',
          ),
          CustomTrainingExercise(
            customName: 'Týdny 7–8',
            sets: '1',
            reps: 'Předzávodní těžké dvojky / trojky',
            rir: '—',
            note:
                'Specifičnost trojboje, nízké chyby, vysoká koncentrace, žádné zbytečné doplňky navíc.',
          ),
          CustomTrainingExercise(
            customName: 'Týden 9',
            sets: '1',
            reps: 'Deload / peak',
            rir: '—',
            note:
                'Sniž objem, nech intenzitu rozumně vysoko, dojdi čerstvý na pokusy.',
          ),
        ],
      ),
    ];
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