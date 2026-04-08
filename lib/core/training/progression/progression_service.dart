import '../../../models/user_profile.dart';
import '../actual_set.dart';
import '../sessions/training_session.dart';
import '../training_plan_models.dart';
import '../training_set.dart';
import 'progression_decision.dart';

class ProgressionService {
  /// Původní API necháváme kvůli kompatibilitě.
  static double? nextWeightKg({
    required UserProfile profile,
    required PlannedExercise planned,
    required List<TrainingSession> history,
  }) {
    final decision = decideNextWeight(
      profile: profile,
      planned: planned,
      history: history,
    );

    return decision.nextWeightKg;
  }

  /// Nové API pro recommendation layer / UI.
  static ProgressDecision decideNextWeight({
    required UserProfile profile,
    required PlannedExercise planned,
    required List<TrainingSession> history,
  }) {
    final base = planned.weightKg;
    if (base == null) {
      return const ProgressDecision(
        action: ProgressAction.noData,
        reason: 'Cvik nemá zadanou pracovní váhu.',
      );
    }

    final exerciseKey = planned.exerciseId ?? planned.name;

    final last = _findLastEntry(history, exerciseKey);
    if (last == null) {
      return ProgressDecision(
        action: ProgressAction.keep,
        currentWeightKg: base,
        nextWeightKg: base,
        reason: 'První log nebo chybí historie. Začni na plánované váze.',
      );
    }

    final plannedWork = _workSets(last.plannedSets);
    final actual = last.actualSets;

    final completed = _isCompleted(plannedWork, actual);
    if (!completed) {
      return ProgressDecision(
        action: ProgressAction.keep,
        currentWeightKg: base,
        nextWeightKg: base,
        reason: 'Minulý výkon nebyl splněn. Zopakuj stejnou váhu.',
      );
    }

    final mode = _modeForProfile(profile);
    final repRange = _parseRepRange(planned.reps);

    if (mode == _ProgMode.body ||
        mode == _ProgMode.cut ||
        mode == _ProgMode.endurance) {
      if (repRange != null) {
        final allAtTop = _allWorkSetsAtTop(repRange.$2, plannedWork, actual);
        if (!allAtTop) {
          return ProgressDecision(
            action: ProgressAction.keep,
            currentWeightKg: base,
            nextWeightKg: base,
            reason:
                'Ještě nejsi na horní hraně opakování ve všech pracovních sériích.',
          );
        }

        final inc = mode == _ProgMode.cut ? 1.25 : 2.5;
        final next = _roundToIncrement(base + inc, inc);

        return ProgressDecision(
          action: ProgressAction.increase,
          currentWeightKg: base,
          nextWeightKg: next,
          reason: 'Splněno na horní hraně rep range. Příště přidej váhu.',
        );
      }

      final inc = mode == _ProgMode.cut ? 1.25 : 2.5;
      final next = _roundToIncrement(base + inc, inc);

      return ProgressDecision(
        action: ProgressAction.increase,
        currentWeightKg: base,
        nextWeightKg: next,
        reason: 'Plán byl splněn. Příště můžeš lehce přidat.',
      );
    }

    final next = _roundToIncrement(base + 2.5, 2.5);

    return ProgressDecision(
      action: ProgressAction.increase,
      currentWeightKg: base,
      nextWeightKg: next,
      reason: 'Silový režim: pracovní série splněny, příště přidej 2.5 kg.',
    );
  }

  static _ProgMode _modeForProfile(UserProfile p) {
    final goalType = p.goal?.type.toString().toLowerCase() ?? '';
    final reason = p.goal?.reason.toString().toLowerCase() ?? '';

    if (goalType.contains('strength') || reason.contains('strength')) {
      return _ProgMode.strength;
    }
    if (goalType.contains('endurance') || reason.contains('endurance')) {
      return _ProgMode.endurance;
    }
    if (goalType.contains('cut') ||
        reason.contains('fat') ||
        reason.contains('loss')) {
      return _ProgMode.cut;
    }

    return _ProgMode.body;
  }

  static _Entry? _findLastEntry(
    List<TrainingSession> history,
    String exerciseKey,
  ) {
    _Entry? best;
    DateTime? bestDate;

    for (final s in history) {
      for (final e in s.entries) {
        if (e.exerciseKey != exerciseKey) {
          continue;
        }

        if (bestDate == null || s.date.isAfter(bestDate)) {
          bestDate = s.date;
          best = _Entry(e.plannedSets, e.actualSets);
        }
      }
    }

    return best;
  }

  static List<PlannedSet> _workSets(List<PlannedSet> plannedSets) {
    return plannedSets.where((p) {
      final n = (p.note ?? '').toLowerCase();
      return !n.contains('rozcvi');
    }).toList();
  }

  static bool _isCompleted(List<PlannedSet> plannedWork, List<ActualSet> actual) {
    if (actual.isEmpty) {
      return false;
    }

    final plannedLast = plannedWork.isNotEmpty ? plannedWork.last : null;
    final actualLast = actual.last;

    if (plannedLast == null) {
      return actualLast.weightKg != null || actualLast.reps > 0;
    }

    final pr = plannedLast.reps;
    final pw = plannedLast.weightKg;

    final ar = actualLast.reps;
    final aw = actualLast.weightKg;

    if (ar < pr) {
      return false;
    }

    if (pw != null && aw != null && aw < (pw - 0.25)) {
      return false;
    }

    return true;
  }

  static bool _allWorkSetsAtTop(
    int topReps,
    List<PlannedSet> plannedWork,
    List<ActualSet> actual,
  ) {
    final n = plannedWork.isEmpty ? actual.length : plannedWork.length;
    final m = actual.length < n ? actual.length : n;

    if (m == 0) {
      return false;
    }

    for (var i = 0; i < m; i++) {
      final r = actual[i].reps;
      if (r < topReps) {
        return false;
      }
    }

    return true;
  }

  /// Vrací (min, max) z textu typu "8-12" nebo "8–12"
  static (int, int)? _parseRepRange(String repsText) {
    final t = repsText.trim();
    final m = RegExp(r'(\d+)\s*[-–]\s*(\d+)').firstMatch(t);

    if (m == null) {
      return null;
    }

    final g1 = m.group(1);
    final g2 = m.group(2);

    if (g1 == null || g2 == null) {
      return null;
    }

    final a = int.tryParse(g1);
    final b = int.tryParse(g2);

    if (a == null || b == null) {
      return null;
    }

    return (a, b);
  }

  static double _roundToIncrement(double v, double inc) {
    final k = (v / inc).round();
    return k * inc;
  }
}

enum _ProgMode { strength, body, cut, endurance }

class _Entry {
  final List<PlannedSet> plannedSets;
  final List<ActualSet> actualSets;

  _Entry(this.plannedSets, this.actualSets);
}