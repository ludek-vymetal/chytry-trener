part of 'custom_training_plan_screen.dart';

// Letní forma – 32týdenní transformace postavy k datu (léto, dovolená,
// focení). Trénink i jídelníček mají stejné datum a stejné fáze:
//  1–8   Rekompozice (týden 8 odlehčovací)
//  9–16  Rýsování I (týden 16 odlehčovací)
//  17–18 Diet break – údržba
//  19–28 Rýsování II (týden 24 odlehčovací)
//  29–31 Finální rýsování
//  32    Peak / focení
//
// 5 tréninků týdně. Silový základ (dřep, bench, mrtvý tah) zůstává těžký –
// v deficitu drží svaly a hodí se i pro silové sportovce. Navíc
// specializace na ramena, paže a horní hrudník (V-tvar).

Future<void> _insertSummerFormPlan(
  BuildContext context,
  WidgetRef ref,
  String clientId,
) async {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  // Výchozí: cíl za 32 týdnů (dnes = 1. týden přípravy).
  final targetDate = await showDatePicker(
    context: context,
    initialDate: today.add(
      const Duration(days: SummerFormPrep.totalWeeks * 7 - 1),
    ),
    firstDate: today,
    lastDate: today.add(const Duration(days: 730)),
    helpText: 'Cílové datum formy',
  );

  if (targetDate == null) return;
  if (!context.mounted) return;

  final plans = ref.read(customTrainingPlanProvider);
  final newName = _buildUniquePlanName(
    SummerFormPrep.name,
    plans.where((p) => p.clientId == clientId).toList(),
  );

  final created = DateTime.now();
  final plan = CustomTrainingPlan(
    id: 'plan_${created.microsecondsSinceEpoch}',
    clientId: clientId,
    name: newName,
    description: 'Transformace postavy k datu ${_fmtDate(targetDate)}: '
        'rekompozice → rýsování → diet break → rýsování → peak. '
        'Síla se udržuje, důraz na ramena, paže a horní hrudník.',
    category: CustomTrainingCategory.cut,
    days: _summerFormPlanDays(targetDate),
    createdAt: created,
    updatedAt: created,
    isActive: false,
    type: CustomTrainingPlanType.summerFormPrep,
    meetDate: targetDate,
  );

  // Celý plán najednou (jedno uložení místo stovek).
  await ref.read(customTrainingPlanProvider.notifier).addImportedPlan(plan);

  // Program = trénink i jídelníček: jídelníček se nastaví klientovi
  // automaticky (stejné datum a stejné fáze).
  final dietSet = await _applyProgramDiet(
    ref,
    clientId,
    (p) => p.copyWith(
      selectedPlan: SummerFormPrep.planKey,
      summerFormDate: targetDate,
    ),
    restrictive: true,
  );

  if (!context.mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        'Plán "$newName" byl vložen mezi vlastní tréninky.'
        '${dietSet ? '\nJídelníček nastaven: ${SummerFormPrep.name}.' : ''}',
      ),
    ),
  );
}

/// Letní forma – 32 týdnů zpětně od cílového data, 5 tréninků týdně.
/// Když je cíl dřív než za 32 týdnů, začíná se rovnou aktuálním týdnem
/// (fáze vždy sedí na datum – stejně jako jídelníček Letní forma).
List<CustomTrainingDay> _summerFormPlanDays(DateTime targetDate) {
  const recomp = _PrepWeekConfig(
    fromWeek: 1,
    toWeek: 7,
    phase: 'Rekompozice',
    mainSets: '4',
    mainReps: '5–6',
    mainRir: '2',
    accSets: '3',
    accReps: '8–12',
    accRir: '1–2',
    rest: 'hlavní cvik 3 min, doplňky 90 s',
    circuitRounds: '3',
    circuitRest: '90 s',
    cardio: '8 000–10 000 kroků denně, další kardio zatím není potřeba.',
    supersets: false,
    dropSet: false,
  );

  _PrepWeekConfig deload(int week, String cardio) => _PrepWeekConfig(
        fromWeek: week,
        toWeek: week,
        phase: 'Odlehčovací týden',
        mainSets: '3',
        mainReps: '5',
        mainRir: '3–4',
        accSets: '2',
        accReps: '10',
        accRir: '3',
        rest: '2 min',
        circuitRounds: '2',
        circuitRest: '90 s',
        cardio: cardio,
        supersets: false,
        dropSet: false,
      );

  _PrepWeekConfig cut2(int from, int to) => _PrepWeekConfig(
        fromWeek: from,
        toWeek: to,
        phase: 'Rýsování II',
        mainSets: '3',
        mainReps: '4–6',
        mainRir: '2',
        accSets: '3',
        accReps: '10–15',
        accRir: '0–1',
        rest: 'hlavní cvik 3 min, supersérie 60 s',
        circuitRounds: '4',
        circuitRest: '60 s',
        cardio: '10 000–12 000 kroků denně + 3× týdně 30–40 min kardio '
            'nízké intenzity (chůze do kopce, kolo).',
        supersets: true,
        dropSet: true,
      );

  final weeks = <_PrepWeekConfig>[
    recomp,
    deload(8, '8 000–10 000 kroků denně.'),
    const _PrepWeekConfig(
      fromWeek: 9,
      toWeek: 15,
      phase: 'Rýsování I',
      mainSets: '4',
      mainReps: '4–6',
      mainRir: '2',
      accSets: '3',
      accReps: '10–12',
      accRir: '1',
      rest: 'hlavní cvik 3 min, supersérie 75 s',
      circuitRounds: '3',
      circuitRest: '75 s',
      cardio: '10 000 kroků denně + 2× týdně 30 min chůze do kopce.',
      supersets: true,
      dropSet: false,
    ),
    deload(16, '10 000 kroků denně.'),
    const _PrepWeekConfig(
      fromWeek: 17,
      toWeek: 18,
      phase: 'Diet break – údržba',
      mainSets: '4',
      mainReps: '3–5',
      mainRir: '1–2',
      accSets: '4',
      accReps: '8–12',
      accRir: '1',
      rest: 'hlavní cvik 3 min, doplňky 90 s',
      circuitRounds: '3',
      circuitRest: '90 s',
      cardio: '8 000–10 000 kroků denně, bez dalšího kardia – jídlo na '
          'údržbě, síla se má vrátit nahoru.',
      supersets: false,
      dropSet: false,
    ),
    cut2(19, 23),
    deload(24, '10 000 kroků denně + 2× týdně 30 min kardio.'),
    cut2(25, 28),
    const _PrepWeekConfig(
      fromWeek: 29,
      toWeek: 31,
      phase: 'Finální rýsování',
      mainSets: '3',
      mainReps: '3–5',
      mainRir: '2',
      accSets: '2',
      accReps: '12–15',
      accRir: '0–1',
      rest: 'hlavní cvik 3 min, supersérie 45–60 s',
      circuitRounds: '4',
      circuitRest: '45 s',
      cardio: '12 000+ kroků denně + 4× týdně 40 min kardio nízké intenzity.',
      supersets: true,
      dropSet: true,
    ),
    const _PrepWeekConfig(
      fromWeek: 32,
      toWeek: 32,
      phase: 'Peak / focení',
      mainSets: '2',
      mainReps: '6',
      mainRir: '3',
      accSets: '2',
      accReps: '12–15',
      accRir: '2–3',
      rest: '60–90 s',
      circuitRounds: '2',
      circuitRest: '90 s',
      cardio: '8 000 kroků denně, žádné další kardio – svaly se mají doplnit.',
      supersets: false,
      dropSet: false,
    ),
  ];

  const total = SummerFormPrep.totalWeeks;
  final currentWeek = SummerFormPrep.weekFor(targetDate) ?? 1;
  final days = <CustomTrainingDay>[];

  for (var week = currentWeek; week <= total; week++) {
    final c = weeks.firstWhere(
      (w) => week >= w.fromWeek && week <= w.toWeek,
    );

    final weekEnd = targetDate.subtract(Duration(days: (total - week) * 7));
    final weekStart = weekEnd.subtract(const Duration(days: 6));
    final weekLabel =
        'Týden $week (${_fmtDate(weekStart)} – ${_fmtDate(weekEnd)})';

    final info = 'Fáze: ${c.phase}\n'
        '${SummerFormPrep.name} – cíl ${_fmtDate(targetDate)}\n'
        'Pauzy: ${c.rest}\n'
        'Kardio: ${c.cardio}';

    CustomTrainingExercise mainLift(String name, {String? extra}) =>
        CustomTrainingExercise(
          customName: name,
          sets: c.mainSets,
          reps: c.mainReps,
          rir: c.mainRir,
          note: '$info\n'
              'Hlavní cvik – drž nebo zvyšuj váhu, síla v deficitu drží '
              'svaly. Do selhání nikdy.'
              '${extra == null ? '' : '\n$extra'}',
        );

    CustomTrainingExercise acc(String name, {String? note, String? reps}) =>
        CustomTrainingExercise(
          customName: name,
          sets: c.accSets,
          reps: reps ?? c.accReps,
          rir: c.accRir,
          note: note,
        );

    CustomTrainingExercise circuit(String name, String reps) =>
        CustomTrainingExercise(
          customName: 'Kruh: $name',
          sets: c.circuitRounds,
          reps: reps,
          rir: '2',
        );

    final superA = c.supersets ? 'Supersérie s následujícím cvikem.' : null;
    final drop = c.dropSet
        ? 'Poslední série jako drop set (−30 % váhy, do technického selhání).'
        : null;

    final isPeakWeek = week == total;

    days.addAll([
      CustomTrainingDay(
        name: '$weekLabel – Den 1 – Tlak: hrudník, ramena, triceps',
        exercises: [
          mainLift('Bench press'),
          acc('Tlaky s jednoručkami na šikmé lavici (30°)', note: superA),
          acc('Rozpažky na kladce zdola nahoru (horní hrudník)'),
          acc('Upažování s jednoručkami', note: drop ?? superA),
          acc('Tlak s jednoručkami nad hlavu vsedě'),
          acc('Triceps – stahování kladky lanem', note: drop),
        ],
      ),
      CustomTrainingDay(
        name: '$weekLabel – Den 2 – Nohy: dřep',
        exercises: [
          mainLift('Dřep s velkou činkou'),
          acc('Leg press', note: superA),
          acc('Rumunský mrtvý tah'),
          acc('Předkopávání na stroji', note: drop),
          acc('Výpony na lýtka ve stoje'),
          acc('Zvedání nohou ve visu', reps: '10–15'),
        ],
      ),
      CustomTrainingDay(
        name: '$weekLabel – Den 3 – Tah: záda, zadní ramena, biceps',
        exercises: [
          mainLift(
            'Shyby nadhmatem (se zátěží, jinak stahování horní kladky)',
          ),
          acc('Přítahy velké činky v předklonu', note: superA),
          acc('Přítahy jednoručky v předklonu'),
          acc('Face pull na kladce (zadní ramena, držení těla)'),
          acc('Zadní ramena – reverse fly na stroji', note: drop),
          acc('Bicepsový zdvih s EZ činkou', note: drop ?? superA),
        ],
      ),
      CustomTrainingDay(
        name: '$weekLabel – Den 4 – Ramena + paže (V-tvar)',
        exercises: [
          mainLift('Tlak nad hlavu s velkou činkou vestoje'),
          acc('Upažování na kladce jednoruč', note: drop ?? superA),
          acc('Upažování v předklonu (zadní ramena)'),
          acc('Bench press úzkým úchopem', reps: '6–10'),
          acc('Bicepsový zdvih s jednoručkami na šikmé lavici', note: superA),
          acc('Francouzský tlak s EZ činkou', note: drop),
          acc('Kladivové zdvihy s jednoručkami'),
        ],
      ),
      if (isPeakWeek)
        CustomTrainingDay(
          name: '$weekLabel – Den focení – pump-up před focením',
          exercises: [
            CustomTrainingExercise(
              customName: 'Kliky',
              sets: '2–3',
              reps: '15',
              rir: '3',
              note: '$info\n'
                  '10–15 min před focením jen na prokrvení svalů. '
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
          name: '$weekLabel – Den 5 – Mrtvý tah + kondice',
          exercises: [
            mainLift(
              'Mrtvý tah',
              extra: 'Pak kruh: ${c.circuitRounds} kola, cviky bez pauzy, '
                  'mezi koly ${c.circuitRest}.',
            ),
            acc('Bulharské výpady', reps: '8–12 na nohu'),
            acc('Zakopávání vleže na stroji', note: drop),
            circuit('Kettlebell swing', '15'),
            circuit('Kliky', '12–20'),
            circuit('Obrácený přítah (TRX / nízká hrazda)', '10–15'),
            circuit('Farmářská chůze', '30–40 m'),
            circuit('Plank', '30–45 s'),
          ],
        ),
    ]);
  }

  days.add(
    CustomTrainingDay(
      name: 'Instrukce – ${SummerFormPrep.name}',
      exercises: [
        CustomTrainingExercise(
          customName: 'Cílové datum',
          sets: '1',
          reps: _fmtDate(targetDate),
          rir: '—',
          note: 'Všechny týdny jsou rozpočítané zpětně od tohoto data. '
              'Jídelníček ${SummerFormPrep.name} (Jídelníčky) používá stejné '
              'datum a stejné fáze.',
        ),
        const CustomTrainingExercise(
          customName: 'Týdny 1–8',
          sets: '1',
          reps: 'Rekompozice',
          rir: '—',
          note: 'Jen mírný deficit (0,2 % váhy týdně). Těžké hlavní cviky, '
              'doplňky 8–12 opakování, priorita ramena, paže a horní hrudník. '
              'Týden 8 odlehčovací.',
        ),
        const CustomTrainingExercise(
          customName: 'Týdny 9–16',
          sets: '1',
          reps: 'Rýsování I',
          rir: '—',
          note: 'Úbytek 0,4 % váhy týdně. Hlavní cviky stále těžké, doplňky '
              'v supersériích, přibývá kroků a kardia. Týden 16 odlehčovací.',
        ),
        const CustomTrainingExercise(
          customName: 'Týdny 17–18',
          sets: '1',
          reps: 'Diet break',
          rir: '—',
          note: 'Dva týdny jídla na údržbě. Doplní se glykogen, hormony i '
              'hlava, síla jde nahoru. Váha může stoupnout o 1–2 kg vody – '
              'to je v pořádku.',
        ),
        const CustomTrainingExercise(
          customName: 'Týdny 19–28',
          sets: '1',
          reps: 'Rýsování II',
          rir: '—',
          note: 'Úbytek 0,5 % váhy týdně, bílkoviny 2,4 g/kg. Supersérie a '
              'drop sety, 3× týdně kardio. Týden 24 odlehčovací.',
        ),
        const CustomTrainingExercise(
          customName: 'Týdny 29–31',
          sets: '1',
          reps: 'Finální rýsování',
          rir: '—',
          note: 'Nejpřísnější fáze. Když výrazně klesá síla, uber kardio, ne '
              'hlavní cviky.',
        ),
        const CustomTrainingExercise(
          customName: 'Týden 32',
          sets: '1',
          reps: 'Peak / focení',
          rir: '—',
          note: 'Jen lehké tréninky na pumpu, žádné selhání ani nové cviky. '
              'Jídlo na údržbě s vyššími sacharidy, svaly se doplní. Před '
              'focením krátký pump-up.',
        ),
        const CustomTrainingExercise(
          customName: 'Kontrola pokroku',
          sets: '1',
          reps: 'každý týden',
          rir: '—',
          note: 'Váha každé ráno (sleduj týdenní průměr), obvod pasu 1× '
              'týdně, fotky každých 14 dní, InBody vždy ráno nalačno.',
        ),
      ],
    ),
  );

  return days;
}
