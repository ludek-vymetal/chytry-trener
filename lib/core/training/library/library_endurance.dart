part of 'program_library.dart';

// Běh, příprava na fyzické testy (policie, hasiči, armáda), kondice.

final List<LibraryProgram> _endurancePrograms = [
  // ------------------------------------------------------------------
  // BĚH
  // ------------------------------------------------------------------
  LibraryProgram(
    id: 'c25k',
    group: ProgramGroup.running,
    title: 'Od gauče k 5 km',
    level: 'Začátečník',
    length: '8 týdnů · 3× týdně',
    description:
        'Z chůze k souvislému běhu 30 minut. Střídání běhu a chůze, '
        'každý týden trochu víc běhu. Tempo: vždy tak, abys mohl/a mluvit.',
    category: CustomTrainingCategory.conditioning,
    days: _couchTo5k,
  ),
  LibraryProgram(
    id: 'run10k',
    group: ProgramGroup.running,
    title: 'Příprava na 10 km',
    level: 'Mírně pokročilý',
    length: '8 týdnů · 4× týdně',
    description:
        'Pro ty, kdo uběhnou 5 km. Lehké běhy, intervaly, tempový běh '
        'a dlouhý běh; 4. týden odlehčení, 8. týden závod.',
    category: CustomTrainingCategory.conditioning,
    days: _tenK,
  ),
  LibraryProgram(
    id: 'half',
    group: ProgramGroup.running,
    title: 'Půlmaraton',
    level: 'Pokročilý',
    length: '12 týdnů · 4× týdně',
    description:
        'Příprava na 21,1 km: postupné prodlužování dlouhého běhu až na '
        '18 km, tempové a intervalové tréninky, 2 týdny ladění.',
    category: CustomTrainingCategory.conditioning,
    days: _halfMarathon,
  ),
  LibraryProgram(
    id: 'runstr',
    group: ProgramGroup.running,
    title: 'Posilování pro běžce',
    level: 'Začátečník',
    length: 'dlouhodobě · 2× týdně',
    description:
        'Doplněk k běhu: síla nohou a hýždí, stabilita kotníku a kolene, '
        'střed těla. Méně zranění a úspornější krok.',
    category: CustomTrainingCategory.conditioning,
    days: () => [
      _day('Posilování A', [
        _warmup,
        _ex('Bulharský dřep', '3', '8–10 na nohu'),
        _ex('Rumunský mrtvý tah na jedné noze', '3', '8–10 na nohu'),
        _ex('Výpony na jedné noze (pomalu dolů)', '3', '12–15 na nohu'),
        _ex('Kopenhagenský plank', '3', '20–30 s na stranu', rir: '—'),
        _ex('Mrtvý brouk (dead bug)', '3', '10 na stranu'),
      ]),
      _day('Posilování B', [
        _warmup,
        _ex('Goblet dřep', '3', '10–12'),
        _ex('Hip thrust / glute bridge', '3', '10–12'),
        _ex('Výstupy na bednu', '3', '10 na nohu'),
        _ex('Nordic hamstring (s dopomocí)', '3', '4–6'),
        _ex('Boční plank', '3', '30 s na stranu', rir: '—'),
        _ex('Poskoky přes švihadlo', '3', '45 s', rir: '—'),
      ]),
    ],
  ),

  // ------------------------------------------------------------------
  // PŘÍPRAVA NA FYZICKÉ TESTY
  // ------------------------------------------------------------------
  LibraryProgram(
    id: 'police',
    group: ProgramGroup.tests,
    title: 'Policie ČR – fyzické testy',
    level: 'Všechny úrovně',
    length: '8 týdnů · 4× týdně',
    description:
        'Na 4 disciplíny přijímacích testů: člunkový běh 4 × 10 m, kliky, '
        'celomotorický test (2 min) a běh na 1 km. Kontrolní test ve 4. '
        'a 8. týdnu. Aktuální pravidla a limity si ověř na nabor.policie.gov.cz.',
    category: CustomTrainingCategory.conditioning,
    days: _police,
  ),
  LibraryProgram(
    id: 'hzs',
    group: ProgramGroup.tests,
    title: 'Hasiči HZS ČR – fyzické testy',
    level: 'Všechny úrovně',
    length: '10 týdnů · 4× týdně',
    description:
        'Kliky, shyby, sedy-lehy, zvedání nohou, běh na 2 km a plavání '
        '200 m. Síla, vytrvalost i plavání v jednom plánu. Disciplíny '
        'a limity podle skupiny a věku si ověř u HZS kraje.',
    category: CustomTrainingCategory.conditioning,
    days: _firefighter,
  ),
  LibraryProgram(
    id: 'army',
    group: ProgramGroup.tests,
    title: 'Armáda ČR – vstupní test a kondice',
    level: 'Začátečník',
    length: '6 týdnů · 3× týdně',
    description:
        'Hod medicinbalem vsedě a dřep s kettlebellem na lavici, k tomu '
        'běh a pochod se zátěží – aby sis výcvik po nástupu užil/a. '
        'Aktuální limity: doarmady.mo.gov.cz.',
    category: CustomTrainingCategory.conditioning,
    days: () => [
      _day('Den 1 – výbušná síla', [
        _warmup,
        _ex('Hod medicinbalem vsedě zády u zdi (test)', '5', '3',
            rir: '—',
            note: 'Ženy 3 kg, muži 4 kg. Nejdelší hod si zapiš.'),
        _ex('Hody medicinbalem o zeď od hrudi', '4', '8'),
        _ex('Kliky s odrazem / výbušné kliky', '4', '5–8'),
        _ex('Tlak jednoruček vleže', '3', '8–10'),
        _ex('Plank', '3', '45 s', rir: '—'),
      ]),
      _day('Den 2 – nohy a střed', [
        _warmup,
        _ex('Dřep s kettlebellem na lavici (test)', '3', 'max', rir: '1',
            note: 'Kettlebell 5 kg u hrudi, sed na lavici ve výšce kolen.'),
        _ex('Goblet dřep s těžším kettlebellem', '4', '10–12'),
        _ex('Výpady v chůzi', '3', '10 na nohu'),
        _ex('Mrtvý tah s kettlebellem', '3', '12'),
        _ex('Boční plank', '3', '30 s na stranu', rir: '—'),
      ]),
      _day('Den 3 – vytrvalost', [
        _cardio('Běh v lehkém tempu', '1', '20–35 min',
            note: 'Každý týden +3 min.'),
        _cardio('Pochod s batohem 8–12 kg', '1', '45–60 min',
            note: 'Pevné boty, začni lehčí zátěží.'),
      ]),
    ],
  ),

  // ------------------------------------------------------------------
  // KONDICE
  // ------------------------------------------------------------------
  LibraryProgram(
    id: 'circuit3',
    group: ProgramGroup.fitness,
    title: 'Funkční kondiční kruh',
    level: 'Mírně pokročilý',
    length: '6–8 týdnů · 3× týdně',
    description:
        'Kruhové tréninky s kettlebellem, vlastní vahou a veslem. '
        'Kondice, spalování a síla najednou – ideální pro rýsování.',
    category: CustomTrainingCategory.conditioning,
    days: () => [
      _day('Kruh A – 4 kola', [
        _warmup,
        _ex('Švihy s kettlebellem', '4 kola', '15'),
        _ex('Kliky', '4 kola', '10–15'),
        _ex('Goblet dřep', '4 kola', '12'),
        _ex('Přítahy TRX / kruhy', '4 kola', '10–12'),
        _cardio('Veslo', '4 kola', '250 m',
            note: 'Mezi cviky co nejméně pauzy, 90 s pauza po kole.'),
      ]),
      _day('Kruh B – EMOM 20 min', [
        _warmup,
        _cardio('EMOM: 1. min – burpees', '5', '8–12'),
        _cardio('EMOM: 2. min – výpady střídavě', '5', '16'),
        _cardio('EMOM: 3. min – horolezec', '5', '30 s'),
        _cardio('EMOM: 4. min – odpočinek / plank', '5', '30 s'),
      ]),
      _day('Kruh C – síla + finiš', [
        _warmup,
        _ex('Mrtvý tah s kettlebellem / trap bar', '4', '8'),
        _ex('Tlak kettlebellu nad hlavu', '4', '8 na ruku'),
        _ex('Farmářská chůze', '4', '40 m', rir: '—'),
        _cardio('FINIŠ: kolo / airbike sprinty', '8', '20 s sprint / 40 s volně'),
      ]),
    ],
  ),
];

// ---------------------------------------------------------------------
// Generátory týdenních plánů
// ---------------------------------------------------------------------

/// Od gauče k 5 km – 8 týdnů × 3 běhy.
List<CustomTrainingDay> _couchTo5k() {
  const weeks = <List<String>>[
    ['8× (běh 60 s / chůze 90 s)', '8× (běh 60 s / chůze 90 s)', '8× (běh 60 s / chůze 90 s)'],
    ['6× (běh 90 s / chůze 2 min)', '6× (běh 90 s / chůze 2 min)', '6× (běh 90 s / chůze 2 min)'],
    ['2× (běh 90 s, chůze 90 s, běh 3 min, chůze 3 min)', '2× (běh 90 s, chůze 90 s, běh 3 min, chůze 3 min)', '2× (běh 90 s, chůze 90 s, běh 3 min, chůze 3 min)'],
    ['běh 3 min, chůze 90 s, běh 5 min, chůze 2,5 min, běh 3 min, chůze 90 s, běh 5 min', 'stejně jako běh 1', 'stejně jako běh 1'],
    ['3× (běh 5 min / chůze 3 min)', 'běh 8 min, chůze 5 min, běh 8 min', 'běh 20 min bez zastavení'],
    ['běh 5 min, chůze 3 min, běh 8 min, chůze 3 min, běh 5 min', '2× (běh 10 min / chůze 3 min)', 'běh 25 min bez zastavení'],
    ['běh 25 min', 'běh 25 min', 'běh 25 min'],
    ['běh 28 min', 'běh 28 min', 'běh 30 min nebo 5 km – TEST'],
  ];
  return [
    for (var w = 0; w < weeks.length; w++)
      for (var r = 0; r < 3; r++)
        _day('Týden ${w + 1} – běh ${r + 1}', [
          _cardio('ROZCVIČKA: svižná chůze', '1', '5 min'),
          _cardio('Hlavní část', '1', weeks[w][r],
              note: 'Tempo, při kterém dokážeš mluvit v krátkých větách.'),
          _cardio('Vydýchání chůzí + protažení', '1', '5 min'),
        ]),
  ];
}

/// 10 km – 8 týdnů × 4 tréninky.
List<CustomTrainingDay> _tenK() {
  const easy = [30, 30, 35, 30, 35, 40, 40, 25];
  const quality = [
    'Intervaly 6× 400 m svižně / 90 s klus',
    'Tempový běh 15 min (pocitově 7/10)',
    'Intervaly 5× 800 m / 2 min klus',
    'Fartlek 6× 1 min svižně / 2 min klus',
    'Intervaly 4× 1 km / 2 min klus',
    'Tempový běh 25 min',
    'Intervaly 6× 800 m / 90 s klus',
    'Lehce 20 min + 4× 100 m stupňovaně',
  ];
  const long = [6, 7, 8, 6, 9, 10, 11, 0];
  return [
    for (var w = 0; w < 8; w++) ...[
      _day('Týden ${w + 1} – lehký běh', [
        _cardio('Lehký běh (konverzační tempo)', '1', '${easy[w]} min'),
        _cardio('Rovinky', '4', '80 m stupňovaně'),
      ]),
      _day('Týden ${w + 1} – kvalita', [
        _runWarmup,
        _cardio('Hlavní část', '1', quality[w]),
        _cooldown,
      ]),
      _day('Týden ${w + 1} – lehký běh + posilování', [
        _cardio('Lehký běh', '1', '${(easy[w] * 0.8).round()} min'),
        _ex('Bulharský dřep', '2', '10 na nohu'),
        _ex('Výpony na jedné noze', '2', '15 na nohu'),
        _ex('Plank', '2', '45 s', rir: '—'),
      ]),
      _day(w == 7 ? 'Týden 8 – ZÁVOD 10 km' : 'Týden ${w + 1} – dlouhý běh', [
        if (w == 7)
          _cardio('ZÁVOD / test 10 km', '1', '10 km',
              note: 'První 2 km klidně, pak závodní tempo. Poslední km naplno.')
        else
          _cardio('Dlouhý běh v pohodovém tempu', '1', '${long[w]} km'),
      ]),
    ],
  ];
}

/// Půlmaraton – 12 týdnů × 4 tréninky.
List<CustomTrainingDay> _halfMarathon() {
  const easy = [35, 40, 40, 35, 45, 45, 50, 40, 50, 50, 40, 30];
  const quality = [
    'Tempový běh 15 min',
    'Intervaly 6× 800 m / 90 s klus',
    'Tempový běh 20 min',
    'Fartlek 8× 1 min / 1 min',
    'Intervaly 5× 1 km / 2 min klus',
    'Tempový běh 25 min',
    'Intervaly 4× 1,6 km / 2 min klus',
    'Fartlek 6× 2 min / 1 min',
    'Tempový běh 30 min (půlmaratonské tempo)',
    '3× 3 km v tempu půlmaratonu / 3 min klus',
    'Tempový běh 20 min',
    'Lehce 20 min + 4× 100 m',
  ];
  const long = [8, 9, 10, 8, 12, 13, 14, 11, 16, 18, 12, 0];
  return [
    for (var w = 0; w < 12; w++) ...[
      _day('Týden ${w + 1} – lehký běh', [
        _cardio('Lehký běh (konverzační tempo)', '1', '${easy[w]} min'),
      ]),
      _day('Týden ${w + 1} – kvalita', [
        _runWarmup,
        _cardio('Hlavní část', '1', quality[w]),
        _cooldown,
      ]),
      _day('Týden ${w + 1} – lehký běh + rovinky', [
        _cardio('Lehký běh', '1', '${(easy[w] * 0.8).round()} min'),
        _cardio('Rovinky', '6', '80 m stupňovaně'),
      ]),
      _day(w == 11 ? 'Týden 12 – ZÁVOD půlmaraton' : 'Týden ${w + 1} – dlouhý běh', [
        if (w == 11)
          _cardio('PŮLMARATON 21,1 km', '1', '21,1 km',
              note: 'Začni o 5–10 s/km pomaleji, piješ na každé občerstvovačce, '
                  'gel/sacharidy každých 30–40 min.')
        else
          _cardio('Dlouhý běh v pohodovém tempu', '1', '${long[w]} km',
              note: w >= 8
                  ? 'Vyzkoušej si pití a gely, které použiješ na závodě.'
                  : null),
      ]),
    ],
  ];
}

/// Policie ČR – 8 týdnů × 4 tréninky, kontrolní test 4. a 8. týden.
List<CustomTrainingDay> _police() {
  final days = <CustomTrainingDay>[];
  for (var w = 1; w <= 8; w++) {
    final test = w == 4 || w == 8;
    final shuttle = 6 + (w > 4 ? 2 : 0) + (w - 1) % 4; // 6–11 úseků
    final reps400 = w <= 4 ? 3 + w : 5 + (w - 4); // 4–7 / 6–9 úseků
    final burpeeRounds = 5 + (w + 1) ~/ 2; // 6–9 kol

    days.add(_day('Týden $w – rychlost a kliky', [
      _runWarmup,
      _cardio('Člunkový běh 4 × 10 m', '$shuttle', '1',
          note: 'Naplno, pauza 90 s. 1. a 2. úsek met obíhat, dál jen dotknout.'),
      _cardio('Sprint 20 m ze startu', '4', '1', note: 'Pauza 60 s.'),
      _ex('Kliky – testová technika', '4', 'max − 2',
          note: 'Hruď se lehce dotkne podložky, tělo rovné. Pauza 90 s.'),
      _ex('Kliky na lavičce (objem)', '2', '10–15'),
    ]));

    days.add(_day('Týden $w – běh na 1 km', [
      _runWarmup,
      _cardio('Úseky 400 m v cílovém tempu na 1 km', '$reps400', '400 m',
          note: 'Pauza 2 min klusem / chůzí. Tempo cca o 3–5 s rychlejší, '
              'než na kolik chceš 1 km zaběhnout.'),
      _cooldown,
    ]));

    days.add(_day('Týden $w – celomotorický test + střed těla', [
      _warmup,
      _cardio('Celomotorický pohyb (stoj – dřep – vzpor ležmo – dřep – stoj)',
          '$burpeeRounds', '30 s práce / 30 s pauza',
          note: 'Plynule a ve stejném rytmu, počítej opakování.'),
      _ex('Dřep s vlastní vahou', '3', '20'),
      _ex('Plank', '3', '45–60 s', rir: '—'),
      _ex('Horolezec', '3', '30 s', rir: '—'),
    ]));

    days.add(test
        ? _day(w == 4
            ? 'Týden 4 – KONTROLNÍ TEST'
            : 'Týden 8 – GENERÁLKA TESTŮ', [
            _runWarmup,
            _cardio('Člunkový běh 4 × 10 m', '2', 'na čas',
                note: 'Lepší pokus se počítá.'),
            _ex('Kliky – max. počet', '1', 'max', rir: '0'),
            _cardio('Celomotorický test', '1', '2 min – max. opakování'),
            _cardio('Běh na 1 km', '1', 'na čas'),
            _cardio('Výsledky si zapiš', '1', '—',
                note: 'Porovnej s bodovou tabulkou náboru a zaměř se na nejslabší disciplínu.'),
          ])
        : _day('Týden $w – aerobní základ', [
            _cardio('Lehký běh', '1', '${20 + w * 3} min'),
            _cardio('Rovinky', '4', '60 m'),
            _cardio('Mobilita kyčlí a hrudní páteře', '1', '10 min'),
          ]));
  }
  return days;
}

/// Hasiči – 10 týdnů × 4 tréninky (základ → rozvoj → ladění + test).
List<CustomTrainingDay> _firefighter() {
  final days = <CustomTrainingDay>[];
  for (var w = 1; w <= 10; w++) {
    final phase = w <= 4 ? 'základ' : (w <= 8 ? 'rozvoj' : 'ladění');
    final test = w == 5 || w == 10;
    final pullSets = w <= 4 ? 4 : 5;
    final swim50 = w <= 4 ? 4 + w : (w <= 8 ? 6 + (w - 4) : 4);

    days.add(_day('Týden $w – síla horní ($phase)', [
      _warmup,
      w <= 3
          ? _ex('Shyby – negativní (pomalé spouštění 3–5 s)', '$pullSets', '3–5',
              note: 'Nebo shyby s gumou. Cíl: čisté shyby bez švihu.')
          : _ex('Shyby nadhmatem', '$pullSets', 'max − 1',
              note: 'Brada nad hrazdu, dolů do natažených paží.'),
      _ex('Kliky', '4', 'max − 2', note: 'Pauza 90 s.'),
      _ex('Přítahy činky v předklonu', '3', '8–10'),
      _ex('Tlak s činkou nad hlavu vestoje', '3', '8'),
      _ex('Sedy-lehy', '3', '60 s', rir: '—',
          note: 'Testové tempo – rovnoměrně, počítej opakování.'),
      _ex('Zvedání nohou vleže / ve visu', '3', '12–20'),
    ]));

    days.add(_day('Týden $w – běh na 2 km', [
      _runWarmup,
      _cardio(
        'Hlavní část',
        '1',
        w <= 4
            ? '${3 + w}× 400 m svižně / 90 s klus'
            : (w <= 8 ? '${w - 1}× 600 m v tempu 2 km / 2 min klus' : '3× 500 m závodně / 3 min klus'),
      ),
      _cooldown,
    ]));

    days.add(_day('Týden $w – plavání + střed', [
      _cardio('ROZPLAVÁNÍ volným způsobem', '1', '200 m'),
      _cardio('Úseky 50 m', '$swim50', '50 m',
          note: 'Pauza 30–45 s. Plynulé dýchání, kraul nebo prsa.'),
      _cardio(w <= 4 ? 'Souvisle' : 'Souvisle v testovém tempu', '1',
          w <= 4 ? '100–150 m' : '200 m'),
      _ex('Plank', '3', '45–60 s', rir: '—'),
      _ex('Superman / zadní vzpor', '3', '12–15'),
    ]));

    days.add(test
        ? _day(w == 5 ? 'Týden 5 – KONTROLNÍ TEST' : 'Týden 10 – GENERÁLKA TESTŮ', [
            _warmup,
            _ex('Shyby – max.', '1', 'max', rir: '0'),
            _ex('Kliky – max.', '1', 'max', rir: '0'),
            _ex('Sedy-lehy – 2 min', '1', 'max', rir: '0'),
            _ex('Zvedání nohou – 2 min', '1', 'max', rir: '0'),
            _cardio('Běh 2 km', '1', 'na čas'),
            _cardio('Plavání 200 m (samostatný den)', '1', 'na čas',
                note: 'Výsledky porovnej s bodovou tabulkou své skupiny a věku.'),
          ])
        : _day('Týden $w – kruhový trénink', [
            _warmup,
            _ex('Farmářská chůze s těžkými jednoručkami', '4', '40 m',
                rir: '—', note: 'Simuluje nošení vybavení.'),
            _ex('Výstupy na bednu se zátěží', '4', '10 na nohu'),
            _ex('Tahání saní / přetahování lana', '4', '20 m', rir: '—'),
            _ex('Burpees', '4', '10'),
            _cardio('Lehký běh', '1', '15–20 min'),
          ]));
  }
  return days;
}
