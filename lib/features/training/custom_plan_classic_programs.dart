part of 'custom_training_plan_screen.dart';

// Rýsování 90 dní, příprava na trojboj, pomocné výpočty, dialogy.

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

class _BenchSession {
  final String title;
  final String sets;
  final String reps;
  final double pct;

  const _BenchSession(this.title, this.sets, this.reps, this.pct);
}

class _BenchWeek {
  final int week;
  final String phase;
  final List<_BenchSession> sessions;

  const _BenchWeek(this.week, this.phase, this.sessions);
}

class _BenchMeetInput {
  final double bench1rm;
  final DateTime meetDate;

  const _BenchMeetInput({
    required this.bench1rm,
    required this.meetDate,
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



class _BenchMeetDialog extends StatefulWidget {
  const _BenchMeetDialog();

  @override
  State<_BenchMeetDialog> createState() => _BenchMeetDialogState();
}

class _BenchMeetDialogState extends State<_BenchMeetDialog> {
  final benchCtrl = TextEditingController();

  // Výchozí: závod za 12 týdnů (dnes = 1. týden).
  DateTime meetDate = DateTime.now().add(
    const Duration(days: _benchWeeks * 7 - 1),
  );

  @override
  void dispose() {
    benchCtrl.dispose();
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
              controller: benchCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: l10n.bench1rm,
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
                    const Duration(days: 730),
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
            final bench = double.tryParse(
              benchCtrl.text.trim().replaceAll(',', '.'),
            );

            if (bench == null || bench <= 0) return;

            Navigator.pop(
              context,
              _BenchMeetInput(bench1rm: bench, meetDate: meetDate),
            );
          },
          child: Text(l10n.createPlan),
        ),
      ],
    );
  }
}
