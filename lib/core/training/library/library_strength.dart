part of 'program_library.dart';

// Kulturistika, postava, síla a vzpírání.

final List<LibraryProgram> _strengthPrograms = [
  // ------------------------------------------------------------------
  // KULTURISTIKA A POSTAVA
  // ------------------------------------------------------------------
  LibraryProgram(
    id: 'fb3',
    group: ProgramGroup.bodybuilding,
    title: 'Full body pro začátečníky',
    level: 'Začátečník',
    length: '8–12 týdnů · 3× týdně',
    description:
        'Celé tělo v každém tréninku, střídání A / B. Ideální první rok '
        'v posilovně – naučí techniku základních cviků a rychle přidává sílu.',
    category: CustomTrainingCategory.bodybuilding,
    days: () => [
      _day('Trénink A – celé tělo', [
        _warmup,
        _ex('Dřep s činkou', '3', '8–10',
            note: 'Když zvládneš všechny série na 10, přidej 2,5 kg.'),
        _ex('Tlak na lavici rovné', '3', '8–10'),
        _ex('Přítahy horní kladky', '3', '10–12'),
        _ex('Rumunský mrtvý tah s jednoručkami', '3', '10–12'),
        _ex('Tlak jednoruček nad hlavu vsedě', '2', '10–12'),
        _ex('Plank', '3', '30–45 s', rir: '—'),
      ]),
      _day('Trénink B – celé tělo', [
        _warmup,
        _ex('Leg press', '3', '10–12'),
        _ex('Přítahy činky v předklonu', '3', '8–10'),
        _ex('Tlak jednoruček na šikmé lavici', '3', '10–12'),
        _ex('Zakopávání na stroji', '3', '10–12'),
        _ex('Upažování s jednoručkami', '2', '12–15'),
        _ex('Zkracovačky / dead bug', '3', '10–12'),
      ]),
    ],
  ),
  LibraryProgram(
    id: 'min2',
    group: ProgramGroup.bodybuilding,
    title: 'Minimalista – 2× týdně',
    level: 'Začátečník',
    length: 'dlouhodobě · 2× týdně',
    description:
        'Pro klienty s málem času: dva celotělové tréninky, jen to '
        'nejúčinnější. Udrží a postupně zlepší sílu i postavu.',
    category: CustomTrainingCategory.recomp,
    days: () => [
      _day('Trénink 1', [
        _warmup,
        _ex('Dřep s činkou / goblet dřep', '3', '6–10'),
        _ex('Tlak na lavici', '3', '6–10'),
        _ex('Přítahy horní kladky', '3', '8–12'),
        _ex('Hip thrust', '2', '10–12'),
        _ex('Farmářská chůze', '3', '30–40 m', rir: '—'),
      ]),
      _day('Trénink 2', [
        _warmup,
        _ex('Mrtvý tah (trap bar)', '3', '5–8'),
        _ex('Tlak s činkou nad hlavu vestoje', '3', '6–10'),
        _ex('Přítahy jednoručky v opoře', '3', '10–12'),
        _ex('Výpady v chůzi', '2', '10 na nohu'),
        _ex('Pallofův tlak', '3', '10 na stranu'),
      ]),
    ],
  ),
  LibraryProgram(
    id: 'ul4',
    group: ProgramGroup.bodybuilding,
    title: 'Horní / spodní – 4× týdně',
    level: 'Mírně pokročilý',
    length: '8–12 týdnů · 4× týdně',
    description:
        'Klasický split horní a spodní polovina těla, každá partie 2× týdně. '
        'Nejlepší poměr objemu a regenerace pro růst svalů.',
    category: CustomTrainingCategory.bodybuilding,
    days: () => [
      _day('Horní A – síla', [
        _warmup,
        _ex('Tlak na lavici', '4', '5–7'),
        _ex('Přítahy činky v předklonu', '4', '6–8'),
        _ex('Tlak s činkou nad hlavu vestoje', '3', '6–8'),
        _ex('Shyby (případně s gumou)', '3', '6–10'),
        _ex('Bicepsový zdvih s EZ činkou', '2', '8–10'),
        _ex('Francouzský tlak', '2', '8–10'),
      ]),
      _day('Spodní A – síla', [
        _warmup,
        _ex('Dřep s činkou', '4', '5–7'),
        _ex('Rumunský mrtvý tah', '3', '6–8'),
        _ex('Bulharský dřep', '3', '8–10 na nohu'),
        _ex('Zakopávání na stroji', '3', '10–12'),
        _ex('Výpony vestoje', '4', '10–12'),
        _ex('Zvedání nohou ve visu', '3', '10–12'),
      ]),
      _day('Horní B – objem', [
        _warmup,
        _ex('Tlak jednoruček na šikmé lavici', '4', '8–12'),
        _ex('Přítahy horní kladky', '4', '10–12'),
        _ex('Rozpažování na kladkách', '3', '12–15'),
        _ex('Přítahy kladky vsedě', '3', '10–12'),
        _ex('Upažování s jednoručkami', '4', '12–20'),
        _ex('Bicepsový zdvih s jednoručkami', '3', '10–12'),
        _ex('Stahování kladky na triceps', '3', '10–15'),
      ]),
      _day('Spodní B – objem', [
        _warmup,
        _ex('Hack dřep / leg press', '4', '8–12'),
        _ex('Hip thrust', '3', '8–12'),
        _ex('Předkopávání na stroji', '3', '12–15'),
        _ex('Zakopávání vleže', '3', '10–12'),
        _ex('Výpony vsedě', '4', '12–15'),
        _ex('Kabelové zkracovačky', '3', '12–15'),
      ]),
    ],
  ),
  LibraryProgram(
    id: 'ppl6',
    group: ProgramGroup.bodybuilding,
    title: 'Push / Pull / Legs – 6× týdně',
    level: 'Pokročilý',
    length: '8–12 týdnů · 6× týdně',
    description:
        'Tlaky / přítahy / nohy dvakrát týdně. Vysoký objem pro pokročilé, '
        'kteří dobře regenerují (spánek 7–9 h, dostatek jídla).',
    category: CustomTrainingCategory.bodybuilding,
    days: () => [
      _day('Push 1 – hrudník, ramena, triceps', [
        _warmup,
        _ex('Tlak na lavici', '4', '6–8'),
        _ex('Tlak s činkou nad hlavu vestoje', '3', '6–8'),
        _ex('Tlak jednoruček na šikmé lavici', '3', '8–10'),
        _ex('Upažování s jednoručkami', '4', '12–15'),
        _ex('Stahování kladky na triceps', '3', '10–12'),
        _ex('Tlaky nad hlavu s lanem (triceps)', '3', '12–15'),
      ]),
      _day('Pull 1 – záda, biceps', [
        _warmup,
        _ex('Mrtvý tah', '3', '4–6'),
        _ex('Shyby nadhmatem', '4', '6–10'),
        _ex('Přítahy kladky vsedě', '3', '10–12'),
        _ex('Face pull', '3', '12–15'),
        _ex('Bicepsový zdvih s EZ činkou', '3', '8–10'),
        _ex('Kladivový zdvih', '3', '10–12'),
      ]),
      _day('Legs 1 – nohy', [
        _warmup,
        _ex('Dřep s činkou', '4', '6–8'),
        _ex('Rumunský mrtvý tah', '3', '8–10'),
        _ex('Leg press', '3', '10–12'),
        _ex('Zakopávání na stroji', '3', '10–12'),
        _ex('Výpony vestoje', '4', '10–12'),
        _ex('Zvedání nohou ve visu', '3', '10–15'),
      ]),
      _day('Push 2 – hrudník, ramena, triceps', [
        _warmup,
        _ex('Tlak jednoruček na rovné lavici', '4', '8–10'),
        _ex('Tlak na šikmé lavici na stroji', '3', '10–12'),
        _ex('Tlak jednoruček nad hlavu vsedě', '3', '8–10'),
        _ex('Rozpažování na kladkách', '3', '12–15'),
        _ex('Upažování na kladce', '3', '15–20'),
        _ex('Kliky na bradlech', '3', '8–12'),
      ]),
      _day('Pull 2 – záda, biceps', [
        _warmup,
        _ex('Přítahy činky v předklonu', '4', '6–8'),
        _ex('Přítahy horní kladky podhmatem', '3', '10–12'),
        _ex('Přítahy jednoručky v opoře', '3', '10–12'),
        _ex('Zadní ramena – rozpažování v předklonu', '3', '15–20'),
        _ex('Bicepsový zdvih na Scottově lavici', '3', '10–12'),
        _ex('Krčení ramen s jednoručkami', '3', '12–15'),
      ]),
      _day('Legs 2 – nohy', [
        _warmup,
        _ex('Hack dřep / přední dřep', '4', '8–10'),
        _ex('Hip thrust', '3', '8–12'),
        _ex('Bulharský dřep', '3', '10 na nohu'),
        _ex('Předkopávání na stroji', '3', '12–15'),
        _ex('Výpony vsedě', '4', '12–15'),
        _ex('Kabelové zkracovačky', '3', '12–15'),
      ]),
    ],
  ),
  LibraryProgram(
    id: 'split5',
    group: ProgramGroup.bodybuilding,
    title: 'Klasický 5denní split',
    level: 'Mírně pokročilý',
    length: '8–12 týdnů · 5× týdně',
    description:
        'Každý den jedna hlavní partie – hrudník, záda, ramena, nohy, ruce. '
        'Oblíbený kulturistický styl s velkým objemem na partii.',
    category: CustomTrainingCategory.bodybuilding,
    days: () => [
      _day('Hrudník', [
        _warmup,
        _ex('Tlak na lavici', '4', '6–8'),
        _ex('Tlak jednoruček na šikmé lavici', '4', '8–10'),
        _ex('Tlak na stroji na hrudník', '3', '10–12'),
        _ex('Rozpažování na kladkách', '3', '12–15'),
        _ex('Kliky na bradlech', '2', 'max – 2'),
      ]),
      _day('Záda', [
        _warmup,
        _ex('Mrtvý tah', '3', '5–6'),
        _ex('Shyby / přítahy horní kladky', '4', '8–10'),
        _ex('Přítahy činky v předklonu', '4', '8–10'),
        _ex('Přítahy kladky vsedě', '3', '10–12'),
        _ex('Přítahy s rovnými pažemi na kladce', '3', '12–15'),
      ]),
      _day('Ramena', [
        _warmup,
        _ex('Tlak s činkou nad hlavu', '4', '6–8'),
        _ex('Tlak jednoruček nad hlavu vsedě', '3', '8–10'),
        _ex('Upažování s jednoručkami', '4', '12–15'),
        _ex('Face pull', '3', '12–15'),
        _ex('Zadní ramena na stroji', '3', '15–20'),
        _ex('Krčení ramen', '3', '10–12'),
      ]),
      _day('Nohy', [
        _warmup,
        _ex('Dřep s činkou', '4', '6–8'),
        _ex('Leg press', '4', '10–12'),
        _ex('Rumunský mrtvý tah', '3', '8–10'),
        _ex('Zakopávání na stroji', '3', '10–12'),
        _ex('Předkopávání na stroji', '3', '12–15'),
        _ex('Výpony vestoje', '5', '10–15'),
      ]),
      _day('Ruce a břicho', [
        _warmup,
        _ex('Tlak na lavici úzkým úchopem', '3', '6–8'),
        _ex('Bicepsový zdvih s činkou', '3', '8–10'),
        _ex('Francouzský tlak', '3', '8–10'),
        _ex('Bicepsový zdvih s jednoručkami na šikmé lavici', '3', '10–12'),
        _ex('Stahování kladky na triceps', '3', '12–15'),
        _ex('Kladivový zdvih', '3', '10–12'),
        _ex('Zvedání nohou ve visu', '3', '10–15'),
      ]),
    ],
  ),
  LibraryProgram(
    id: 'arnold6',
    group: ProgramGroup.bodybuilding,
    title: 'Arnoldův split – 6× týdně',
    level: 'Pokročilý',
    length: '8–12 týdnů · 6× týdně',
    description:
        'Hrudník + záda, ramena + ruce, nohy – každá dvojice 2× týdně. '
        'Legendární objemový program pro zkušené, vyžaduje výbornou regeneraci.',
    category: CustomTrainingCategory.bodybuilding,
    days: () {
      final chestBack = _day('Hrudník + záda', [
        _warmup,
        _ex('Tlak na lavici', '4', '6–10'),
        _ex('Shyby široce', '4', 'max'),
        _ex('Tlak jednoruček na šikmé lavici', '3', '8–10'),
        _ex('Přítahy činky v předklonu', '3', '8–10'),
        _ex('Rozpažování s jednoručkami', '3', '10–12'),
        _ex('Přítahy kladky vsedě', '3', '10–12'),
        _ex('Přitahování jednoručky za hlavu (pullover)', '3', '10–12'),
      ]);
      final shouldersArms = _day('Ramena + ruce', [
        _warmup,
        _ex('Arnoldův tlak', '4', '8–10'),
        _ex('Upažování s jednoručkami', '4', '10–15'),
        _ex('Rozpažování v předklonu', '3', '12–15'),
        _ex('Bicepsový zdvih s činkou', '4', '8–10'),
        _ex('Tlak na lavici úzkým úchopem', '4', '8–10'),
        _ex('Koncentrovaný zdvih', '3', '10–12'),
        _ex('Stahování kladky na triceps', '3', '10–12'),
      ]);
      final legs = _day('Nohy + lýtka', [
        _warmup,
        _ex('Dřep s činkou', '5', '6–10'),
        _ex('Leg press', '4', '10–12'),
        _ex('Zakopávání vleže', '4', '10–12'),
        _ex('Rumunský mrtvý tah', '3', '8–10'),
        _ex('Výpony vestoje', '5', '10–15'),
        _ex('Zkracovačky', '4', '15–20'),
      ]);
      return [
        chestBack,
        shouldersArms,
        legs,
        chestBack.copyWith(name: 'Hrudník + záda (2)'),
        shouldersArms.copyWith(name: 'Ramena + ruce (2)'),
        legs.copyWith(name: 'Nohy + lýtka (2)'),
      ];
    },
  ),
  LibraryProgram(
    id: 'phul4',
    group: ProgramGroup.bodybuilding,
    title: 'PHUL – síla a objem 4×',
    level: 'Mírně pokročilý',
    length: '8–12 týdnů · 4× týdně',
    description:
        'Power Hypertrophy Upper Lower: 2 silové dny s těžkými základními '
        'cviky + 2 objemové dny pro růst svalů.',
    category: CustomTrainingCategory.strength,
    days: () => [
      _day('Horní – síla', [
        _warmup,
        _ex('Tlak na lavici', '4', '3–5', rir: '1–2'),
        _ex('Přítahy činky v předklonu', '4', '3–5', rir: '1–2'),
        _ex('Tlak s činkou nad hlavu vestoje', '3', '5–8'),
        _ex('Shyby se zátěží', '3', '5–8'),
        _ex('Bicepsový zdvih s činkou', '2', '6–10'),
        _ex('Francouzský tlak', '2', '6–10'),
      ]),
      _day('Spodní – síla', [
        _warmup,
        _ex('Dřep s činkou', '4', '3–5', rir: '1–2'),
        _ex('Mrtvý tah', '3', '3–5', rir: '1–2'),
        _ex('Leg press', '3', '10–15'),
        _ex('Zakopávání na stroji', '3', '6–10'),
        _ex('Výpony vestoje', '4', '6–10'),
      ]),
      _day('Horní – objem', [
        _warmup,
        _ex('Tlak jednoruček na šikmé lavici', '4', '8–12'),
        _ex('Rozpažování na kladkách', '3', '8–12'),
        _ex('Přítahy kladky vsedě', '4', '8–12'),
        _ex('Přítahy jednoručky v opoře', '3', '8–12'),
        _ex('Upažování s jednoručkami', '3', '10–15'),
        _ex('Bicepsový zdvih na šikmé lavici', '3', '8–12'),
        _ex('Stahování kladky na triceps', '3', '8–12'),
      ]),
      _day('Spodní – objem', [
        _warmup,
        _ex('Přední dřep', '4', '8–12'),
        _ex('Výpady s jednoručkami', '3', '8–12 na nohu'),
        _ex('Předkopávání na stroji', '3', '10–15'),
        _ex('Zakopávání vleže', '3', '10–15'),
        _ex('Výpony vsedě', '4', '8–12'),
      ]),
    ],
  ),
  LibraryProgram(
    id: 'women3',
    group: ProgramGroup.bodybuilding,
    title: 'Ženy – zpevnění a tvarování',
    level: 'Začátečník',
    length: '8–12 týdnů · 3× týdně',
    description:
        'Celé tělo s důrazem na hýždě, stehna, záda a pas. Bez strachu '
        'z „nabrání“ – těžší váhy tvarují postavu nejlépe.',
    category: CustomTrainingCategory.glutes,
    days: () => [
      _day('Den 1 – hýždě a záda', [
        _warmup,
        _ex('Hip thrust', '4', '8–12'),
        _ex('Goblet dřep', '3', '10–12'),
        _ex('Přítahy horní kladky', '3', '10–12'),
        _ex('Abdukce v sedu na stroji', '3', '15–20'),
        _ex('Přítahy kladky vsedě', '3', '10–12'),
        _ex('Plank', '3', '30–45 s', rir: '—'),
      ]),
      _day('Den 2 – horní tělo a střed', [
        _warmup,
        _ex('Tlak jednoruček na šikmé lavici', '3', '10–12'),
        _ex('Přítahy jednoručky v opoře', '3', '10–12'),
        _ex('Tlak jednoruček nad hlavu vsedě', '3', '10–12'),
        _ex('Upažování s jednoručkami', '3', '12–15'),
        _ex('Face pull', '3', '12–15'),
        _ex('Dead bug', '3', '10 na stranu'),
      ]),
      _day('Den 3 – nohy a hýždě', [
        _warmup,
        _ex('Rumunský mrtvý tah', '4', '8–10'),
        _ex('Bulharský dřep', '3', '10 na nohu'),
        _ex('Kopání vzad na kladce', '3', '12–15 na nohu'),
        _ex('Zakopávání na stroji', '3', '10–12'),
        _ex('Glute bridge na jedné noze', '2', '12 na nohu'),
        _cardio('Svižná chůze do kopce', '1', '15–20 min'),
      ]),
    ],
  ),
  LibraryProgram(
    id: 'home3',
    group: ProgramGroup.bodybuilding,
    title: 'Doma s jednoručkami',
    level: 'Začátečník',
    length: '8 týdnů · 3× týdně',
    description:
        'Stačí nastavitelné jednoručky, lavice nebo židle a guma. '
        'Celé tělo, postupné přidávání opakování a zátěže.',
    category: CustomTrainingCategory.recomp,
    days: () => [
      _day('Domácí trénink A', [
        _cardio('ROZCVIČKA: poskoky, kroužení pažemi, dřepy bez zátěže', '1',
            '5–8 min'),
        _ex('Goblet dřep s jednoručkou', '4', '10–15'),
        _ex('Kliky (na kolenou / klasické)', '4', 'max – 2'),
        _ex('Přítahy jednoručky v opoře o židli', '4', '10–12 na ruku'),
        _ex('Rumunský mrtvý tah s jednoručkami', '3', '12–15'),
        _ex('Tlak jednoruček nad hlavu', '3', '10–12'),
        _ex('Plank', '3', '30–60 s', rir: '—'),
      ]),
      _day('Domácí trénink B', [
        _cardio('ROZCVIČKA: poskoky, kroužení pažemi, výpady', '1',
            '5–8 min'),
        _ex('Bulharský dřep (noha na židli)', '3', '10–12 na nohu'),
        _ex('Tlak jednoruček vleže na lavici / zemi', '4', '10–12'),
        _ex('Přítahy gumy k hrudníku', '4', '12–15'),
        _ex('Hip thrust s jednoručkou', '3', '12–15'),
        _ex('Upažování s jednoručkami', '3', '12–15'),
        _ex('Bicepsový zdvih + tricepsové kliky o židli', '2', '12 + 12'),
      ]),
    ],
  ),

  // ------------------------------------------------------------------
  // SÍLA A VZPÍRÁNÍ
  // ------------------------------------------------------------------
  LibraryProgram(
    id: 'sl5x5',
    group: ProgramGroup.strength,
    title: 'Silový základ 5×5',
    level: 'Začátečník',
    length: '12 týdnů · 3× týdně',
    description:
        'Jednoduchý silový program: dřep každý trénink, střídání A / B, '
        'lineární progrese +2,5 kg (mrtvý tah +5 kg) za trénink.',
    category: CustomTrainingCategory.strength,
    days: () => [
      _day('Trénink A', [
        _warmup,
        _ex('Dřep s činkou', '5', '5', rir: '1–2',
            note: 'Začni lehce (cca 60 % max). Každý trénink +2,5 kg.'),
        _ex('Tlak na lavici', '5', '5', rir: '1–2'),
        _ex('Přítahy činky v předklonu', '5', '5', rir: '1–2'),
        _ex('Plank', '3', '45 s', rir: '—'),
      ]),
      _day('Trénink B', [
        _warmup,
        _ex('Dřep s činkou', '5', '5', rir: '1–2'),
        _ex('Tlak s činkou nad hlavu vestoje', '5', '5', rir: '1–2'),
        _ex('Mrtvý tah', '1', '5', rir: '1–2',
            note: 'Jen 1 pracovní série po rozcvičení. Každý trénink +5 kg.'),
        _ex('Shyby / přítahy horní kladky', '3', '6–10'),
      ]),
    ],
  ),
  LibraryProgram(
    id: 'oly1',
    group: ProgramGroup.strength,
    title: 'Vzpírání – základy techniky',
    level: 'Začátečník',
    length: '8 týdnů · 3× týdně',
    description:
        'Trh a nadhoz od základů: z visu, ze země, přední a trhový dřep. '
        'Nejdřív s tyčí nebo lehkou osou – technika před váhou.',
    category: CustomTrainingCategory.strength,
    days: () => [
      _day('Den 1 – trh', [
        _warmup,
        _ex('Trhová rozcvička s tyčí (Burgener)', '3', '5', rir: '—',
            note: 'Tah, vytažení do špiček, podřep pod osu – pomalu a přesně.'),
        _ex('Trh z visu nad koleny', '5', '3', rir: '3',
            note: '50–65 % maxima v trhu. Rychlost a poloha, ne váha.'),
        _ex('Trhový dřep (overhead squat)', '4', '3', rir: '3'),
        _ex('Trhový tah ze země', '3', '5', rir: '2', note: '80–90 % trhu.'),
        _ex('Dřep vzadu', '4', '5', rir: '2'),
        _ex('Plank / hollow hold', '3', '30 s', rir: '—'),
      ]),
      _day('Den 2 – přemístění a nadhoz', [
        _warmup,
        _ex('Přemístění z visu', '5', '3', rir: '3',
            note: '60–70 % maxima v přemístění.'),
        _ex('Nadhoz z hrudi (push jerk)', '5', '3', rir: '3'),
        _ex('Dřep vpředu', '4', '4', rir: '2'),
        _ex('Tlak s činkou nad hlavu vestoje', '3', '6', rir: '2'),
        _ex('Rumunský mrtvý tah', '3', '8', rir: '2'),
      ]),
      _day('Den 3 – celé pohyby', [
        _warmup,
        _ex('Trh ze země', '6', '2', rir: '3', note: '65–75 %.'),
        _ex('Přemístění a nadhoz', '6', '1+1', rir: '3', note: '65–75 %.'),
        _ex('Tah na přemístění', '3', '4', rir: '2', note: '90–100 % přemístění.'),
        _ex('Dřep vzadu', '3', '3', rir: '2'),
        _ex('Zadní vzpor / hyperextenze', '3', '10–12'),
      ]),
    ],
  ),
  LibraryProgram(
    id: 'oly2',
    group: ProgramGroup.strength,
    title: 'Vzpírání – středně pokročilí',
    level: 'Pokročilý',
    length: '8 týdnů · 4× týdně',
    description:
        'Váhy v % osobního maxima v trhu, přemístění a dřepu. Vlna objemu '
        'a intenzity, 8. týden odlehčení a test maxim.',
    category: CustomTrainingCategory.strength,
    days: () => [
      _day('Pondělí – trh + dřep', [
        _warmup,
        _ex('Trh', '6', '2', rir: '2', note: '70–80 % max trhu.'),
        _ex('Trh z bloků / z visu', '4', '2', rir: '2', note: '70 %.'),
        _ex('Dřep vzadu', '5', '4', rir: '2', note: '75–80 % max dřepu.'),
        _ex('Trhový tah', '3', '3', rir: '2', note: '95–105 % trhu.'),
      ]),
      _day('Úterý – nadhoz + síla', [
        _warmup,
        _ex('Nadhoz ze stojanu', '6', '2', rir: '2',
            note: '75–85 % max nadhozu.'),
        _ex('Dřep vpředu', '5', '3', rir: '2', note: '75–80 %.'),
        _ex('Tlak s činkou za hlavou (Sotts / push press)', '4', '5'),
        _ex('Přítahy činky v předklonu', '3', '8'),
      ]),
      _day('Čtvrtek – přemístění + komplexy', [
        _warmup,
        _ex('Přemístění', '6', '2', rir: '2', note: '70–80 %.'),
        _ex('Komplex: přemístění z visu + přemístění + nadhoz', '5', '1+1+1',
            rir: '2', note: '65–75 %.'),
        _ex('Tah na přemístění', '4', '3', rir: '2', note: '100–110 %.'),
        _ex('Rumunský mrtvý tah', '3', '6'),
      ]),
      _day('Sobota – těžký den', [
        _warmup,
        _ex('Trh – těžké singly', '5', '1', rir: '1',
            note: 'Postupně do 85–90 %. Při chybě techniky ubrat.'),
        _ex('Přemístění a nadhoz – těžké singly', '5', '1+1', rir: '1',
            note: 'Postupně do 85–90 %.'),
        _ex('Dřep vpředu', '3', '2', rir: '1', note: '85 %.'),
        _ex('Core: hollow rock / plank', '3', '30–45 s', rir: '—'),
      ]),
    ],
  ),
];
