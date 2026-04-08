import '../training_set.dart';

class WeightCalculator {
  static double _roundTo(double value, double step) {
    return (value / step).round() * step;
  }

  /// výpočet pracovního weightu z Training Max (TM)
  static double weightFromTm({
    required double oneRm,
    required double intensityPercent,
    required double trainingMaxPercent,
    double roundTo = 2.5,
  }) {
    final tm = oneRm * trainingMaxPercent;
    return _roundTo(tm * intensityPercent, roundTo);
  }

  /// ✅ NOVÉ: rozcvička + pracovní série pro hlavní cvik
  static List<PlannedSet> buildWarmupAndWorkSets({
    required double oneRm,
    required double trainingMaxPercent,
    required double workIntensityPercent, // např 0.80 = 80% TM
    required int workSets,                 // např 3
    required int workReps,                 // např 5
    double roundTo = 2.5,
  }) {
    final tm = oneRm * trainingMaxPercent;
    final workWeight = _roundTo(tm * workIntensityPercent, roundTo);

    // Jednoduchý MVP protokol (bezpečný a univerzální)
    // Rozcvička: 40% x8, 55% x5, 70% x3, 80% x1 (vše z pracovního weightu)
    final warmups = [
      PlannedSet(weightKg: _roundTo(workWeight * 0.50, roundTo), reps: 8, note: 'Rozcvička'),
      PlannedSet(weightKg: _roundTo(workWeight * 0.70, roundTo), reps: 5, note: 'Rozcvička'),
      PlannedSet(weightKg: _roundTo(workWeight * 0.85, roundTo), reps: 3, note: 'Rozcvička'),
      PlannedSet(weightKg: _roundTo(workWeight * 0.95, roundTo), reps: 1, note: 'Rozcvička'),
    ];

    final work = List.generate(
      workSets,
      (_) => PlannedSet(weightKg: workWeight, reps: workReps, note: 'Pracovní'),
    );

    return [...warmups, ...work];
  }
}
