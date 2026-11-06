// Kontrola výpočtu jídla: bazál (InBody / odhad), bílkoviny, periodizace
// a týdenní úprava podle vážení.  Spuštění:  flutter test test/nutrition_test.dart
import 'package:flutter_test/flutter_test.dart';

import 'package:dart_application_1/core/training/intake/training_intake.dart';
import 'package:dart_application_1/models/body_composition.dart';
import 'package:dart_application_1/models/energy_adjustment.dart';
import 'package:dart_application_1/models/goal.dart';
import 'package:dart_application_1/models/measurement.dart';
import 'package:dart_application_1/models/user_profile.dart';
import 'package:dart_application_1/services/macro_service.dart';
import 'package:dart_application_1/services/metabolism_service.dart';

UserProfile _muz({
  double weight = 85,
  Goal? goal,
  BodyComposition? comp,
  List<Measurement> measurements = const [],
  EnergyAdjustment? adj,
}) =>
    UserProfile(
      clientId: 'test',
      firstName: 'Test',
      age: 30,
      gender: 'male',
      height: 180,
      weight: weight,
      goal: goal,
      bodyComposition: comp,
      measurements: measurements,
      energyAdjustment: adj,
      trainingIntake: const TrainingIntake(
        frequencyPerWeek: 4,
        equipment: {'barbell'},
        experienceLevel: 'intermediate',
      ),
    );

double _tdee(UserProfile p) =>
    MetabolismService.calculateTDEE(p, MetabolismService.activityFor(p));

void main() {
  final now = DateTime.now();

  test('bazál bez InBody = Mifflin-St Jeor', () {
    final p = _muz();
    expect(MetabolismService.calculateBMR(p), closeTo(1830, 0.5));
    expect(_tdee(p), closeTo(1830 * 1.55, 0.5));
  });

  test('bazál s čerstvým InBody = změřený, po změně váhy z beztukové hmoty',
      () {
    final comp = BodyComposition(
      date: now.subtract(const Duration(days: 10)),
      weightKg: 85,
      leanMassKg: 74.8,
      bodyFatPercent: 12,
      bmrKcal: 1986,
    );
    expect(MetabolismService.calculateBMR(_muz(comp: comp)), 1986);
    // o 4 kg lehčí → Katch-McArdle z beztukové hmoty
    expect(
      MetabolismService.calculateBMR(_muz(weight: 81, comp: comp)),
      closeTo(370 + 21.6 * 74.8, 0.01),
    );
  });

  test('staré InBody (> 6 měsíců) se nepoužije', () {
    final comp = BodyComposition(
      date: now.subtract(const Duration(days: 220)),
      weightKg: 85,
      leanMassKg: 74.8,
      bodyFatPercent: 12,
      bmrKcal: 1986,
    );
    expect(MetabolismService.calculateBMR(_muz(comp: comp)), closeTo(1830, 0.5));
  });

  test('soutěž 20 týdnů před: mírný deficit, kalorie = součet maker', () {
    final goal = Goal(
      type: GoalType.physique,
      reason: GoalReason.competition,
      targetDate: now.add(const Duration(days: 20 * 7 + 3)),
    );
    final p = _muz(goal: goal);
    final t = _tdee(p);
    final m = MacroService.calculate(p, t);
    expect(m.targetCalories, lessThan(t));
    expect(m.targetCalories, greaterThan(t * 0.75));
    expect(m.targetCalories, m.protein * 4 + m.carbs * 4 + m.fat * 9);
    expect(m.protein, greaterThanOrEqualTo((85 * 2.3).floor()));
    expect(m.rationale, isNot(contains('goal_')));
  });

  test('peak před soutěží: údržba', () {
    final goal = Goal(
      type: GoalType.physique,
      reason: GoalReason.competition,
      targetDate: now.add(const Duration(days: 8)),
    );
    final p = _muz(goal: goal);
    final t = _tdee(p);
    final m = MacroService.calculate(p, t);
    expect(m.targetCalories, closeTo(t, 15));
    // v peaku se podle vážení neupravuje (voda, sacharidy)
    expect(MacroService.weeklyReview(p), isNull);
  });

  test('bílkoviny u vysokého podílu tuku z beztukové hmoty', () {
    final comp = BodyComposition(
      date: now.subtract(const Duration(days: 5)),
      weightKg: 115,
      leanMassKg: 74.75,
      bodyFatPercent: 35,
      bmrKcal: 1985,
    );
    final ref = MacroService.proteinReferenceWeight(
      _muz(weight: 115, comp: comp),
    );
    expect(ref, closeTo(74.75 / 0.85, 0.01));
  });

  test('trend váhy: lineární regrese kg/týden', () {
    final ms = [
      for (var d = 0; d <= 14; d += 2)
        Measurement(
          date: now.subtract(Duration(days: 14 - d)),
          weight: 85 - d * (0.5 / 7),
        ),
    ];
    final r = MacroService.weeklyWeightChangeKg(
      ms,
      from: now.subtract(const Duration(days: 21)),
      to: now,
    );
    expect(r, closeTo(-0.5, 0.01));
  });

  test('hubne pomaleji než plán → cíl kalorií dolů', () {
    final goal = Goal(
      type: GoalType.weightLoss,
      reason: GoalReason.health,
      startDate: now.subtract(const Duration(days: 30)),
      targetDate: now.add(const Duration(days: 120)),
    );
    final ms = [
      for (var d = 0; d <= 16; d += 2)
        Measurement(
          date: now.subtract(Duration(days: 16 - d)),
          weight: 90 - d * (0.1 / 7),
        ),
    ];
    final p = _muz(weight: 89.8, goal: goal, measurements: ms);
    final adj = MacroService.weeklyReview(p);
    expect(adj, isNotNull);
    expect(adj!.kcal, lessThan(0));
    expect(adj.kcal, greaterThanOrEqualTo(-200));

    final before = MacroService.calculate(p, _tdee(p)).targetCalories;
    final after = MacroService.calculate(
      p.copyWith(energyAdjustment: adj),
      _tdee(p),
    ).targetCalories;
    expect(after, lessThan(before));
  });

  test('podpora při PPP: úprava nikdy neubírá', () {
    final goal = Goal(
      type: GoalType.weightGainSupport,
      reason: GoalReason.eatingDisorderSupport,
      targetDate: now.add(const Duration(days: 120)),
    );
    final ms = [
      for (var d = 0; d <= 16; d += 2)
        Measurement(
          date: now.subtract(Duration(days: 16 - d)),
          weight: 55 + d * (0.6 / 7),
        ),
    ];
    final p = UserProfile(
      clientId: 't2',
      age: 22,
      gender: 'female',
      height: 168,
      weight: 56.4,
      goal: goal,
      measurements: ms,
    );
    final adj = MacroService.weeklyReview(p);
    if (adj != null) expect(adj.kcal, greaterThanOrEqualTo(0));
  });
}
