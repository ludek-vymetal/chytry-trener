part of 'custom_training_plan_screen.dart';

// Hollywood training a Bikini fitness – generátory plánů.

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
      HollywoodPrep.name,
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

    // Program = trénink i jídelníček: jídelníček se nastaví klientovi
    // automaticky (stejné datum a stejné fáze).
    final dietSet = await _applyProgramDiet(
      ref,
      clientId,
      (p) => p.copyWith(
        selectedPlan: HollywoodPrep.planKey,
        hollywoodShootDate: shootDate,
      ),
      restrictive: true,
    );

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Plán "$newName" byl vložen mezi vlastní tréninky.'
          '${dietSet ? '\nJídelníček nastaven: ${HollywoodPrep.name}.' : ''}',
        ),
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
      'Příprava na závody – bikini fitness',
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

    // Program = trénink i jídelníček: jídelníček se nastaví klientovi
    // automaticky (stejné datum a stejné fáze).
    final dietSet = await _applyProgramDiet(
      ref,
      clientId,
      (p) => p.copyWith(
        selectedPlan: BikiniPrep.planKey,
        bikiniMeetDate: meetDate,
      ),
      restrictive: true,
    );

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Plán "$newName" byl vložen mezi vlastní tréninky.'
          '${dietSet ? '\nJídelníček nastaven: ${BikiniPrep.name}.' : ''}',
        ),
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
