part of 'custom_training_plan_screen.dart';

// Kulatý zadek a Ruský cyklus (bench press) – generátory plánů.

const int _gluteWeeks = 12;

  Future<void> _insertGlutePlan(
    BuildContext context,
    WidgetRef ref,
    String clientId,
  ) async {
    final l10n = AppLocalizations.of(context)!;

    final plans = ref.read(customTrainingPlanProvider);
    final newName = _buildUniquePlanName(
      l10n.gluteTitle,
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

    // Program = trénink i jídelníček: jídelníček se nastaví klientovi
    // automaticky (stejné datum a stejné fáze).
    final dietSet = await _applyProgramDiet(
      ref,
      clientId,
      (p) => p.copyWith(selectedPlan: GlutePlan.planKey),
      restrictive: false,
    );

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Plán "$newName" byl vložen mezi vlastní tréninky.'
          '${dietSet ? '\nJídelníček nastaven: ${GlutePlan.name}.' : ''}',
        ),
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

const int _benchWeeks = 12;

  Future<void> _insertBenchRussianPlan(
    BuildContext context,
    WidgetRef ref,
    String clientId,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final input = await showDialog<_BenchMeetInput>(
      context: context,
      builder: (_) => const _BenchMeetDialog(),
    );

    if (input == null) return;
    if (!context.mounted) return;

    final plans = ref.read(customTrainingPlanProvider);
    final newName = _buildUniquePlanName(
      'Ruský cyklus – bench press (závody)',
      plans.where((p) => p.clientId == clientId).toList(),
    );

    await ref.read(customTrainingPlanProvider.notifier).createPlan(
          clientId: clientId,
          name: newName,
          description:
              '${_benchWeeks}týdenní příprava na závody v bench pressu – ruský '
              'cyklus, 1RM ${input.bench1rm.toStringAsFixed(1)} kg, závod '
              '${_fmtDate(input.meetDate)}.',
          category: CustomTrainingCategory.powerlifting,
          type: CustomTrainingPlanType.benchMeetPrep,
          meetDate: input.meetDate,
          maxes: CustomTrainingMaxes(bench1rm: input.bench1rm),
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
    final templateDays = _benchRussianDays(input);

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
      (p) => p.copyWith(selectedPlan: StrengthPlan.planKey),
      restrictive: false,
    );

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Plán "$newName" byl vložen mezi vlastní tréninky.'
          '${dietSet ? '\nJídelníček nastaven: ${StrengthPlan.name}.' : ''}',
        ),
      ),
    );
  }

  /// Ruský cyklus na bench press – 12 týdnů zpětně od data závodu,
  /// 3 tréninky benche týdně. Všechny váhy se počítají z aktuálního 1RM
  /// (zaokrouhlené na 2,5 kg) a v průběhu cyklu rostou.
  ///
  ///  - Týdny 1–4: základ – objem a technika (bench s pauzou), 4. týden
  ///    odlehčení.
  ///  - Týdny 5–10: ruský cyklus – nejdřív objem na 80 % (6×2 až 6×6),
  ///    potom intenzita (5×5 @ 85 %, 4×4 @ 90 %, 3×3 @ 95 %) a těžký single.
  ///  - Týden 11: peak / CNS – těžké singly, nadmaximální výdrž, lockouty
  ///    a rychlostní bench – nervový systém se učí zvednout víc než 1RM.
  ///  - Týden 12: taper – zkouška úvodního pokusu, pak jen rychlost a závod.
  List<CustomTrainingDay> _benchRussianDays(_BenchMeetInput input) {
    final max = input.bench1rm;
    final meet = input.meetDate;

    const weeks = [
      _BenchWeek(1, 'Základ – objem', [
        _BenchSession('Objem', '5', '6', 0.70),
        _BenchSession('Technika – pauza 2 s na hrudníku', '5', '5', 0.625),
        _BenchSession('Objem', '5', '6', 0.725),
      ]),
      _BenchWeek(2, 'Základ – objem', [
        _BenchSession('Objem', '5', '5', 0.75),
        _BenchSession('Technika – pauza 2 s na hrudníku', '5', '4', 0.65),
        _BenchSession('Objem', '5', '5', 0.775),
      ]),
      _BenchWeek(3, 'Základ – síla', [
        _BenchSession('Síla', '5', '4', 0.80),
        _BenchSession('Technika – pauza 2 s na hrudníku', '5', '3', 0.675),
        _BenchSession('Síla', '4', '4', 0.825),
      ]),
      _BenchWeek(4, 'Odlehčení', [
        _BenchSession('Odlehčení', '3', '5', 0.70),
        _BenchSession('Technika – pauza 2 s na hrudníku', '3', '3', 0.625),
        _BenchSession('Odlehčení', '3', '3', 0.75),
      ]),
      _BenchWeek(5, 'Ruský cyklus – objem', [
        _BenchSession('Ruský cyklus', '6', '2', 0.80),
        _BenchSession('Ruský cyklus', '6', '3', 0.80),
        _BenchSession('Ruský cyklus', '6', '2', 0.80),
      ]),
      _BenchWeek(6, 'Ruský cyklus – objem', [
        _BenchSession('Ruský cyklus', '6', '4', 0.80),
        _BenchSession('Ruský cyklus', '6', '2', 0.80),
        _BenchSession('Ruský cyklus', '6', '5', 0.80),
      ]),
      _BenchWeek(7, 'Ruský cyklus – objem', [
        _BenchSession('Ruský cyklus', '6', '2', 0.80),
        _BenchSession('Ruský cyklus', '6', '6', 0.80),
        _BenchSession('Ruský cyklus', '6', '2', 0.80),
      ]),
      _BenchWeek(8, 'Ruský cyklus – intenzita', [
        _BenchSession('Ruský cyklus', '5', '5', 0.85),
        _BenchSession('Ruský cyklus', '6', '2', 0.80),
        _BenchSession('Ruský cyklus', '4', '4', 0.90),
      ]),
      _BenchWeek(9, 'Ruský cyklus – intenzita', [
        _BenchSession('Ruský cyklus', '6', '2', 0.80),
        _BenchSession('Ruský cyklus', '3', '3', 0.95),
        _BenchSession('Ruský cyklus', '6', '2', 0.80),
      ]),
      _BenchWeek(10, 'Ruský cyklus – intenzita', [
        _BenchSession('Ruský cyklus', '2', '2', 0.95),
        _BenchSession('Ruský cyklus – lehčí', '6', '2', 0.75),
        _BenchSession('Těžký single – jistota', '1', '1', 0.975),
      ]),
      _BenchWeek(11, 'Peak / nervový systém', [
        _BenchSession('Těžké singly (CNS)', '3', '1', 0.925),
        _BenchSession('Rychlostní bench – maximální rychlost', '8', '2', 0.55),
        _BenchSession('Top single (CNS)', '1', '1', 0.95),
      ]),
      _BenchWeek(12, 'Taper / závod', [
        _BenchSession('Zkouška úvodního pokusu', '1', '1', 0.925),
        _BenchSession('Rychlostní bench – jen prokrvení', '5', '2', 0.60),
      ]),
    ];

    // Když je závod dřív než za 12 týdnů, začneme rovnou správným týdnem,
    // aby peak a taper vyšly přesně na datum závodu.
    final currentWeek = _prepWeekFor(meet, _benchWeeks) ?? 1;
    final startWeek = currentWeek > _benchWeeks - 1 ? _benchWeeks - 1 : currentWeek;

    String kg(double pct) =>
        _formatWeightAndPercent(_weightFromMax(max, pct), pct);

    const dayNames = ['Trénink A (Po)', 'Trénink B (St)', 'Trénink C (Pá)'];

    final opener = _weightFromMax(max, 0.925);
    final second = _weightFromMax(max, 0.975);
    final third = _weightFromMax(max, 1.025);

    final days = <CustomTrainingDay>[];

    for (final w in weeks.where((w) => w.week >= startWeek)) {
      final weekEnd = meet.subtract(
        Duration(days: (_benchWeeks - w.week) * 7),
      );
      final weekStart = weekEnd.subtract(const Duration(days: 6));
      final weekLabel =
          'Týden ${w.week} (${_fmtDate(weekStart)} – ${_fmtDate(weekEnd)})';

      final isBase = w.week <= 4;
      final isRussian = w.week >= 5 && w.week <= 10;
      final isPeak = w.week == 11;
      final isTaper = w.week == 12;

      // Doplňky podle fáze: v základu objem, v ruském cyklu síla,
      // v peaku jen to nejdůležitější, v taperu nic.
      final accSets = isBase ? '4' : (isRussian ? '3' : '2');
      final accReps = isBase ? '8–10' : (isRussian ? '6–8' : '5');

      CustomTrainingExercise acc(String name, {String? reps, String? note}) =>
          CustomTrainingExercise(
            customName: name,
            sets: accSets,
            reps: reps ?? accReps,
            rir: isPeak ? '2–3' : '1–2',
            note: note,
          );

      CustomTrainingExercise computed(
        String name,
        String sets,
        String reps,
        double pct, {
        String? note,
      }) =>
          CustomTrainingExercise(
            customName: name,
            sets: sets,
            reps: reps,
            rir: '1–2',
            weightKg: _weightFromMax(max, pct),
            note: 'Pracovní váha: ${kg(pct)}${note == null ? '' : '\n$note'}',
          );

      for (var i = 0; i < w.sessions.length; i++) {
        final s = w.sessions[i];

        final mainSet = CustomTrainingExercise(
          customName: 'Bench press – ${s.title}',
          sets: s.sets,
          reps: s.reps,
          rir: s.pct >= 0.95 ? '0–1' : (s.pct >= 0.85 ? '1' : '2'),
          weightKg: _weightFromMax(max, s.pct),
          note: 'Fáze: ${w.phase}\n'
              'Závod: ${_fmtDate(meet)}\n'
              'Výchozí 1RM: ${max.toStringAsFixed(1)} kg\n'
              'Pracovní váha: ${kg(s.pct)}\n'
              'Rozcvičení: 40 % × 8, 55 % × 5, 65 % × 3, 75 % × 1 '
              '(${_weightFromMax(max, 0.40).toStringAsFixed(1)} / '
              '${_weightFromMax(max, 0.55).toStringAsFixed(1)} / '
              '${_weightFromMax(max, 0.65).toStringAsFixed(1)} / '
              '${_weightFromMax(max, 0.75).toStringAsFixed(1)} kg)\n'
              'Závodní technika: pauza na hrudníku, nohy na zemi, hýždě na '
              'lavici.',
        );

        final List<CustomTrainingExercise> extras;
        final String dayTitle;

        if (isTaper) {
          dayTitle = i == 0
              ? 'Den 1 (5 dní před závodem) – zkouška úvodního pokusu'
              : 'Den 2 (3 dny před závodem) – jen rychlost';
          extras = i == 0
              ? [
                  computed('Bench press – rychlé trojky', '3', '3', 0.70,
                      note: 'Co nejrychleji, bez únavy.'),
                ]
              : const [];
        } else if (i == 0) {
          dayTitle = '${dayNames[0]} – bench + tricepsy + záda';
          extras = [
            if (isPeak)
              computed(
                'Nadmaximální výdrž – sundání činky ze stojanu (10 s)',
                '3',
                '10 s',
                1.10,
                note: 'Jen sundat, zamknout a držet s dopomocí jistících. '
                    'Nervový systém si zvyká na váhu nad 1RM.',
              )
            else
              computed(
                'Úzký bench press (úchop na šířku ramen)',
                '4',
                isBase ? '8' : '6',
                isBase ? 0.625 : 0.70,
              ),
            acc('Veslování s velkou činkou v předklonu'),
            if (!isPeak) acc('Francouzský tlak s EZ činkou', reps: '8–12'),
            if (!isPeak) acc('Face pull na kladce', reps: '15'),
          ];
        } else if (i == 1) {
          dayTitle = '${dayNames[1]} – bench + ramena + široký sval zádový';
          extras = isPeak
              ? [acc('Shyby / stahování horní kladky')]
              : [
                  acc('Tlaky s jednoručkami na šikmé lavici', reps: '8–10'),
                  acc('Shyby / stahování horní kladky'),
                  acc('Zadní ramena – reverse fly', reps: '15'),
                  acc('Rotátory ramen s gumou', reps: '15–20'),
                ];
        } else {
          dayTitle = '${dayNames[2]} – bench + lockout + tricepsy';
          extras = [
            if (isPeak)
              computed(
                'Lockouty z bezpečnostních zarážek (posledních 10 cm)',
                '3',
                '2',
                1.05,
                note: 'Nadmaximální váha jen v horní části pohybu – '
                    'síla zamknutí a nervový systém.',
              )
            else
              computed(
                'Bench press na prknech (2 prkna)',
                isBase ? '4' : '3',
                isBase ? '5' : '3',
                isBase ? 0.80 : 0.90,
                note: 'Přetížení horní části pohybu (lockout).',
              ),
            if (!isPeak)
              acc('Kliky na bradlech se zátěží', reps: '6–10'),
            acc('Přítahy jednoručky v předklonu'),
            if (!isPeak) acc('JM press / triceps na kladce', reps: '10–12'),
          ];
        }

        days.add(
          CustomTrainingDay(
            name: '$weekLabel – $dayTitle',
            exercises: [mainSet, ...extras],
          ),
        );
      }

      if (isTaper) {
        days.add(
          CustomTrainingDay(
            name: '$weekLabel – den závodu ${_fmtDate(meet)}',
            exercises: [
              CustomTrainingExercise(
                customName: '1. pokus (úvodní)',
                sets: '1',
                reps: '1',
                rir: '2',
                weightKg: opener,
                note: '${_formatWeightAndPercent(opener, 0.925)} – musí '
                    'projít vždy, i ve špatný den.\n'
                    'Rozcvička v zákulisí: 40 % × 5, 60 % × 3, 75 % × 1, '
                    '85 % × 1 (${_weightFromMax(max, 0.40).toStringAsFixed(1)} / '
                    '${_weightFromMax(max, 0.60).toStringAsFixed(1)} / '
                    '${_weightFromMax(max, 0.75).toStringAsFixed(1)} / '
                    '${_weightFromMax(max, 0.85).toStringAsFixed(1)} kg), '
                    'poslední asi 10 min před pokusem.',
              ),
              CustomTrainingExercise(
                customName: '2. pokus',
                sets: '1',
                reps: '1',
                rir: '1',
                weightKg: second,
                note: '${_formatWeightAndPercent(second, 0.975)} – jistý '
                    'výkon kolem starého maxima.',
              ),
              CustomTrainingExercise(
                customName: '3. pokus (nový osobní rekord)',
                sets: '1',
                reps: '1',
                rir: '0',
                weightKg: third,
                note: '${_formatWeightAndPercent(third, 1.025)}.\n'
                    'Když 2. pokus šel rychle, klidně '
                    '${_weightFromMax(max, 1.05).toStringAsFixed(1)} kg (105 %). '
                    'Když šel ztěžka, jen '
                    '${_weightFromMax(max, 1.0).toStringAsFixed(1)} kg (100 %).',
              ),
            ],
          ),
        );
      }
    }

    days.add(
      CustomTrainingDay(
        name: 'Instrukce – ruský cyklus na bench press',
        exercises: [
          CustomTrainingExercise(
            customName: 'Datum závodu a výchozí maximum',
            sets: '1',
            reps: _fmtDate(meet),
            rir: '—',
            weightKg: max,
            note: 'Všechny váhy jsou spočítané z 1RM '
                '${max.toStringAsFixed(1)} kg a zaokrouhlené na 2,5 kg. '
                'Týdny jsou rozpočítané zpětně od data závodu.',
          ),
          const CustomTrainingExercise(
            customName: 'Týdny 1–4',
            sets: '1',
            reps: 'Základ',
            rir: '—',
            note:
                'Objem, technika (bench s pauzou) a síla doplňků. 4. týden '
                'odlehčení před ruským cyklem.',
          ),
          const CustomTrainingExercise(
            customName: 'Týdny 5–7',
            sets: '1',
            reps: 'Ruský cyklus – objem',
            rir: '—',
            note:
                'Stále 80 % 1RM, ale přibývají opakování v sérii (6×2 → 6×6). '
                'Lehké dny 6×2 mezi těžkými slouží k regeneraci – nepřidávej.',
          ),
          const CustomTrainingExercise(
            customName: 'Týdny 8–10',
            sets: '1',
            reps: 'Ruský cyklus – intenzita',
            rir: '—',
            note:
                'Váha roste, opakování klesají: 5×5 @ 85 %, 4×4 @ 90 %, '
                '3×3 @ 95 %, 2×2 @ 95 % a těžký single 97,5 %.',
          ),
          const CustomTrainingExercise(
            customName: 'Týden 11',
            sets: '1',
            reps: 'Peak / nervový systém',
            rir: '—',
            note:
                'Nízký objem, vysoká intenzita: těžké singly, nadmaximální '
                'výdrž 110 % ze stojanu, lockouty 105 % a rychlostní bench. '
                'Cílem je nabudit nervový systém, ne unavit svaly.',
          ),
          const CustomTrainingExercise(
            customName: 'Týden 12',
            sets: '1',
            reps: 'Taper / závod',
            rir: '—',
            note:
                'Zkouška úvodního pokusu 5 dní před závodem, 3 dny před jen '
                'rychlé dvojky, poslední 2 dny volno. Spánek, jídlo, klid.',
          ),
          const CustomTrainingExercise(
            customName: 'Jídelníček',
            sets: '1',
            reps: 'Silová příprava',
            rir: '—',
            note:
                'Jídelníček Silová příprava (Jídelníčky): údržba, bílkoviny '
                '2,0 g/kg, dost sacharidů na trénink. Když musí klient do '
                'váhové kategorie, nastav cíl a použij lineární jídelníček.',
          ),
        ],
      ),
    );

    return days;
  }
