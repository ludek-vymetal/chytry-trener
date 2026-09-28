// Knihovna hotových tréninkových programů (kulturistika, síla, vzpírání,
// běh, příprava na fyzické testy). Čistá data – plán se z programu
// vytvoří v katalogu programů jedním klepnutím a trenér ho pak může
// libovolně upravit.

import '../../../models/custom_training_plan.dart';

part 'library_strength.dart';
part 'library_endurance.dart';

/// Skupiny v katalogu (v tomto pořadí).
class ProgramGroup {
  static const bodybuilding = 'Kulturistika a postava';
  static const strength = 'Síla a vzpírání';
  static const running = 'Běh';
  static const tests = 'Příprava na fyzické testy';
  static const fitness = 'Kondice a funkční trénink';

  static const all = [bodybuilding, strength, running, tests, fitness];
}

class LibraryProgram {
  final String id;
  final String group;
  final String title;

  /// Začátečník / Mírně pokročilý / Pokročilý.
  final String level;

  /// Např. „8 týdnů · 3× týdně“.
  final String length;
  final String description;
  final CustomTrainingCategory category;
  final List<CustomTrainingDay> Function() days;

  const LibraryProgram({
    required this.id,
    required this.group,
    required this.title,
    required this.level,
    required this.length,
    required this.description,
    required this.category,
    required this.days,
  });
}

class ProgramLibrary {
  ProgramLibrary._();

  static final List<LibraryProgram> all = [
    ..._strengthPrograms,
    ..._endurancePrograms,
  ];

  static List<LibraryProgram> inGroup(String group) =>
      all.where((p) => p.group == group).toList();
}

// ---------------------------------------------------------------------
// Pomocné funkce pro zápis programů
// ---------------------------------------------------------------------

CustomTrainingExercise _ex(
  String name,
  String sets,
  String reps, {
  String rir = '2',
  String? note,
}) =>
    CustomTrainingExercise(
      customName: name,
      sets: sets,
      reps: reps,
      rir: rir,
      note: note,
    );

/// Kardio / čas / vzdálenost – bez RIR.
CustomTrainingExercise _cardio(String name, String sets, String reps,
        {String? note}) =>
    _ex(name, sets, reps, rir: '—', note: note);

CustomTrainingDay _day(String name, List<CustomTrainingExercise> exercises) =>
    CustomTrainingDay(name: name, exercises: exercises);

final _warmup = _cardio(
  'ROZCVIČKA: kolo / veslo / rychlá chůze + mobilita',
  '1',
  '8–10 min',
  note: 'Pak 1–2 lehké rozcvičovací série prvního cviku.',
);

final _runWarmup = _cardio(
  'ROZCVIČKA: klus + běžecká abeceda',
  '1',
  '10 min',
  note: 'Liftink, skipink, zakopávání, 3× stupňovaný úsek 60 m.',
);

final _cooldown = _cardio(
  'VYKLUSÁNÍ / protažení',
  '1',
  '5–10 min',
);
