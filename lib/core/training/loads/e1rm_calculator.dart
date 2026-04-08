import '../actual_set.dart';

class E1rmCalculator {
  static double fromReps(double weight, int reps) {
    if (weight <= 0 || reps <= 0) return 0;
    if (reps == 1) return weight;

    // Epley
    return weight * (1 + reps / 30.0);
  }

  static double bestOfSession(List<ActualSet> sets) {
    double best = 0;

    for (final s in sets) {
      final weight = s.weightKg;
      if (weight == null) continue;
      if (s.reps <= 0) continue;

      final e1rm = fromReps(weight, s.reps);

      if (e1rm > best) {
        best = e1rm;
      }
    }

    return best;
  }
}