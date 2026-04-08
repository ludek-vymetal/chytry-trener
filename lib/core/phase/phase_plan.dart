import 'phase.dart';

/// Jeden úsek v čase (platí pro jídlo i trénink)
class PhasePlan {
  final PhaseType phase;
  final DateTime start;
  final DateTime end;
  final bool accelerated;

  PhasePlan({
    required this.phase,
    required this.start,
    required this.end,
    this.accelerated = false,
  });

  int get durationInDays => end.difference(start).inDays;

  int get durationInWeeks => (durationInDays / 7).ceil();

  bool isActive(DateTime date) {
    return date.isAfter(start) && date.isBefore(end);
  }
}
