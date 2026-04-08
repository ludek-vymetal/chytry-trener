import 'phase_plan.dart';
import 'phase.dart';

/// Výsledek "kde jsem právě teď"
class CurrentPhaseResult {
  final PhaseType phase;
  final PhasePlan activePlan;
  final bool accelerated;

  CurrentPhaseResult({
    required this.phase,
    required this.activePlan,
    required this.accelerated,
  });

  int get daysUntilPhaseEnd =>
      activePlan.end.difference(DateTime.now()).inDays;

  int get weeksUntilPhaseEnd => (daysUntilPhaseEnd / 7).ceil();
}

class PhaseResolver {
  /// Najde aktivní PhasePlan pro zadané datum.
  /// Pokud datum neleží v žádném segmentu (edge case), vrátí nejbližší segment.
  static CurrentPhaseResult resolveCurrentPhase({
    required List<PhasePlan> plans,
    required DateTime date,
  }) {
    final d = _normalize(date);

    if (plans.isEmpty) {
      throw Exception('PhaseResolver: prázdný PhasePlan list');
    }

    // 1) ideální případ: datum je v segmentu
    for (final p in plans) {
      if (_contains(p, d)) {
        return CurrentPhaseResult(
          phase: p.phase,
          activePlan: p,
          accelerated: p.accelerated,
        );
      }
    }

    // 2) datum před prvním segmentem → vrátíme první
    if (d.isBefore(_normalize(plans.first.start))) {
      final p = plans.first;
      return CurrentPhaseResult(
        phase: p.phase,
        activePlan: p,
        accelerated: p.accelerated,
      );
    }

    // 3) datum po posledním segmentu → vrátíme poslední
    if (d.isAfter(_normalize(plans.last.end))) {
      final p = plans.last;
      return CurrentPhaseResult(
        phase: p.phase,
        activePlan: p,
        accelerated: p.accelerated,
      );
    }

    // 4) mezera mezi segmenty (nemělo by nastat, ale pro jistotu)
    // vezmeme segment, jehož start je nejblíž minulosti
    PhasePlan closest = plans.first;
    for (final p in plans) {
      if (_normalize(p.start).isBefore(d) &&
          _normalize(p.start).isAfter(_normalize(closest.start))) {
        closest = p;
      }
    }

    return CurrentPhaseResult(
      phase: closest.phase,
      activePlan: closest,
      accelerated: closest.accelerated,
    );
  }

  /// Helper: kdy začne další fáze (nebo null pokud neexistuje)
  static DateTime? nextPhaseStart({
    required List<PhasePlan> plans,
    required DateTime date,
  }) {
    final d = _normalize(date);

    for (int i = 0; i < plans.length; i++) {
      final p = plans[i];
      if (_contains(p, d)) {
        if (i + 1 < plans.length) {
          return _normalize(plans[i + 1].start);
        }
        return null;
      }
    }
    return null;
  }

  /// Helper: jaká bude další fáze (nebo null)
  static PhaseType? nextPhaseType({
    required List<PhasePlan> plans,
    required DateTime date,
  }) {
    final next = nextPhaseStart(plans: plans, date: date);
    if (next == null) return null;

    final idx = plans.indexWhere((p) => _normalize(p.start) == next);
    if (idx == -1) return null;
    return plans[idx].phase;
  }

  // =====================================================
  // Internal helpers
  // =====================================================

  static bool _contains(PhasePlan p, DateTime d) {
    final start = _normalize(p.start);
    final end = _normalize(p.end);

    // zahrneme start, vyloučíme end
    // [start, end)
    return (d.isAtSameMomentAs(start) || d.isAfter(start)) && d.isBefore(end);
  }

  static DateTime _normalize(DateTime d) => DateTime(d.year, d.month, d.day);
}
