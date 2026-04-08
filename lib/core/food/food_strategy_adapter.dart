import '../../models/goal.dart';
import '../phase/phase.dart';
import '../phase/phase_plan.dart';
import '../phase/plan_mode.dart';
import 'food_strategy.dart';

class FoodStrategyAdapter {
  /// Globální ochranné mantinely
  static const FoodSafetyRules safety = FoodSafetyRules(
    minProteinGPerKg: 1.6,
    minFatGPerKg: 0.6,
    maxDeficitPct: 0.25,
  );

  static FoodStrategy from({
    required Goal goal,
    required PhasePlan activePhase,
    required PlanMode mode,
  }) {
    final isCompetition = goal.reason == GoalReason.competition;

    FoodStrategy base = _baseByGoalType(goal.type);
    base = _applyPhase(base, activePhase.phase, goal.type);
    base = _applyReason(base, goal.reason);

    if (mode == PlanMode.accelerated) {
      base = _applyAccelerated(base);
    }

    if (isCompetition) {
      base = _applyCompetition(base, activePhase.phase);
    }

    base = _applySafety(base);
    return base;
  }

  // ==========================================================
  // Base by GoalType
  // ==========================================================
  static FoodStrategy _baseByGoalType(GoalType type) {
    switch (type) {
      case GoalType.strength:
        return const FoodStrategy(
          calorieMultiplier: 1.10,
          proteinGPerKg: 2.0,
          fatGPerKg: 0.95,
          preferHighCarbs: true,
          label: 'Síla',
          rationale: 'Surplus + sacharidy pro CNS, protein 2.0 g/kg.',
        );

      case GoalType.physique:
        return const FoodStrategy(
          calorieMultiplier: 1.08,
          proteinGPerKg: 2.2,
          fatGPerKg: 0.9,
          preferHighCarbs: true,
          label: 'Postava',
          rationale: 'Fázová periodizace, protein 2.2 g/kg.',
        );

      case GoalType.weightGainSupport:
        // ✅ chovej se jako physique (výživově i tréninkově podobné),
        // rozdíl bude v "citlivém" UI/dotazníku (bez extrémů).
        return const FoodStrategy(
          calorieMultiplier: 1.06,
          proteinGPerKg: 2.0,
          fatGPerKg: 0.9,
          preferHighCarbs: true,
          label: 'Nabírání (podpora)',
          rationale: 'Mírný surplus, bez extrémních doporučení.',
        );

      case GoalType.weightLoss:
        return const FoodStrategy(
          calorieMultiplier: 0.82,
          proteinGPerKg: 2.4,
          fatGPerKg: 0.8,
          preferHighCarbs: false,
          label: 'Hubnutí',
          rationale: 'Deficit + vysoký protein, ochrana svalů.',
        );

      case GoalType.endurance:
        return const FoodStrategy(
          calorieMultiplier: 1.03,
          proteinGPerKg: 1.7,
          fatGPerKg: 0.85,
          preferHighCarbs: true,
          label: 'Vytrvalost',
          rationale: 'Důraz na sacharidy, protein 1.6–1.8 g/kg.',
        );
    }
  }

  // ==========================================================
  // Apply PhaseType
  // ==========================================================
  static FoodStrategy _applyPhase(
    FoodStrategy s,
    PhaseType phase,
    GoalType goalType,
  ) {
    // weightGainSupport bereme jako physique
    final effectiveGoalType =
        (goalType == GoalType.weightGainSupport) ? GoalType.physique : goalType;

    switch (phase) {
      case PhaseType.gaining:
        if (effectiveGoalType == GoalType.physique) {
          return FoodStrategy(
            calorieMultiplier: 1.08,
            proteinGPerKg: 2.2,
            fatGPerKg: 0.9,
            preferHighCarbs: true,
            label: '${s.label} – Nabírání',
            rationale: 'Nabírací fáze: mírný surplus, držíme tuky.',
          );
        }
        if (effectiveGoalType == GoalType.strength) {
          return FoodStrategy(
            calorieMultiplier: 1.12,
            proteinGPerKg: 2.0,
            fatGPerKg: 0.95,
            preferHighCarbs: true,
            label: '${s.label} – Nabírání',
            rationale: 'Síla v nabírání: surplus + sacharidy.',
          );
        }
        return FoodStrategy(
          calorieMultiplier: 1.02,
          proteinGPerKg: s.proteinGPerKg,
          fatGPerKg: s.fatGPerKg,
          preferHighCarbs: s.preferHighCarbs,
          label: '${s.label} – Nabírání',
          rationale: 'Mírný surplus / nad údržbou.',
        );

      case PhaseType.cutting:
        if (effectiveGoalType == GoalType.endurance) {
          return FoodStrategy(
            calorieMultiplier: 0.98,
            proteinGPerKg: 1.7,
            fatGPerKg: 0.8,
            preferHighCarbs: true,
            label: '${s.label} – Redukce',
            rationale: 'Vytrvalost: mírná redukce, držíme sacharidy.',
          );
        }
        return FoodStrategy(
          calorieMultiplier: 0.85,
          proteinGPerKg: _max(s.proteinGPerKg, 2.3),
          fatGPerKg: _max(s.fatGPerKg, 0.75),
          preferHighCarbs: s.preferHighCarbs,
          label: '${s.label} – Shazování',
          rationale: 'Deficit 15–20 %, protein nahoru, tuky hlídat.',
        );

      case PhaseType.peaking:
        return FoodStrategy(
          calorieMultiplier: 0.88,
          proteinGPerKg: _max(s.proteinGPerKg, 2.4),
          fatGPerKg: _max(0.7, _min(s.fatGPerKg, 0.75)),
          preferHighCarbs: true,
          label: '${s.label} – Rýsování',
          rationale: 'Finální forma: vyšší protein, řízené sacharidy.',
        );

      case PhaseType.maintenance:
        return FoodStrategy(
          calorieMultiplier: 1.0,
          proteinGPerKg: _max(s.proteinGPerKg, 2.0),
          fatGPerKg: _max(s.fatGPerKg, 0.85),
          preferHighCarbs: s.preferHighCarbs,
          label: '${s.label} – Udržení',
          rationale: 'Údržba: stabilizace výkonu a regenerace.',
        );
    }
  }

  // ==========================================================
  // Apply GoalReason
  // ==========================================================
  static FoodStrategy _applyReason(FoodStrategy s, GoalReason reason) {
    switch (reason) {
      case GoalReason.summerShape:
        return FoodStrategy(
          calorieMultiplier: s.calorieMultiplier,
          proteinGPerKg: _max(s.proteinGPerKg, 2.2),
          fatGPerKg: s.fatGPerKg,
          preferHighCarbs: s.preferHighCarbs,
          label: s.label,
          rationale: '${s.rationale} (Léto: priorita forma).',
        );

      case GoalReason.competition:
        return FoodStrategy(
          calorieMultiplier: s.calorieMultiplier,
          proteinGPerKg: _max(s.proteinGPerKg, 2.3),
          fatGPerKg: s.fatGPerKg,
          preferHighCarbs: true,
          label: s.label,
          rationale: '${s.rationale} (Závody: precizní příprava).',
        );

      // ✅ NOVÉ: podpůrný režim (bez deficitu, bez “tvrdých” doporučení)
      case GoalReason.eatingDisorderSupport:
        return FoodStrategy(
          calorieMultiplier: _max(s.calorieMultiplier, 1.00),
          proteinGPerKg: _max(s.proteinGPerKg, 1.8),
          fatGPerKg: _max(s.fatGPerKg, 0.9),
          preferHighCarbs: true,
          label: '${s.label} – Podpora',
          rationale: '${s.rationale} (Podpora: bez deficitu a bez extrémů).',
        );

      case GoalReason.health:
      case GoalReason.performance:
      case GoalReason.aesthetic:
        return s;
    }
  }

  // ==========================================================
  // Accelerated / Competition tuning
  // ==========================================================
  static FoodStrategy _applyAccelerated(FoodStrategy s) {
    final mult = _max(0.78, _min(s.calorieMultiplier, 0.88));

    return FoodStrategy(
      calorieMultiplier: mult,
      proteinGPerKg: _max(s.proteinGPerKg, 2.4),
      fatGPerKg: _max(s.fatGPerKg, 0.7),
      preferHighCarbs: s.preferHighCarbs,
      label: '${s.label} (Zrychleně)',
      rationale: '${s.rationale} Zrychlený režim: vyšší deficit + vyšší protein.',
    );
  }

  static FoodStrategy _applyCompetition(FoodStrategy s, PhaseType phase) {
    if (phase == PhaseType.peaking) {
      return FoodStrategy(
        calorieMultiplier: _min(s.calorieMultiplier, 0.90),
        proteinGPerKg: _max(s.proteinGPerKg, 2.5),
        fatGPerKg: _max(0.65, _min(s.fatGPerKg, 0.75)),
        preferHighCarbs: true,
        label: '${s.label} (Závody)',
        rationale: '${s.rationale} Závody: peaking fáze – protein max.',
      );
    }
    return s;
  }

  // ==========================================================
  // Safety
  // ==========================================================
  static FoodStrategy _applySafety(FoodStrategy s) {
    final protein = _max(s.proteinGPerKg, safety.minProteinGPerKg);
    final fat = _max(s.fatGPerKg, safety.minFatGPerKg);

    final minMultiplier = 1.0 - safety.maxDeficitPct;
    final mult = _max(s.calorieMultiplier, minMultiplier);

    return FoodStrategy(
      calorieMultiplier: mult,
      proteinGPerKg: protein,
      fatGPerKg: fat,
      preferHighCarbs: s.preferHighCarbs,
      label: s.label,
      rationale: s.rationale,
    );
  }

  static double _min(double a, double b) => a < b ? a : b;
  static double _max(double a, double b) => a > b ? a : b;
}