import 'phase.dart';

/// Jeden úsek v čase (platí pro jídlo i trénink)
class PhasePlan {
  final PhaseType phase;
  final DateTime start;
  final DateTime end;
  final bool accelerated;

  /// Konkrétní název bloku pro UI (např. "Cut II", "Síla + hypertrofie").
  final String? label;

  /// Cílové tempo úbytku v % tělesné hmotnosti za týden (jen redukční fáze).
  /// Např. 0.75 = 0,75 % váhy týdně.
  final double? weeklyLossPct;

  PhasePlan({
    required this.phase,
    required this.start,
    required this.end,
    this.accelerated = false,
    this.label,
    this.weeklyLossPct,
  });

  int get durationInDays => end.difference(start).inDays;

  int get durationInWeeks => (durationInDays / 7).ceil();

  bool isActive(DateTime date) {
    return date.isAfter(start) && date.isBefore(end);
  }
}
