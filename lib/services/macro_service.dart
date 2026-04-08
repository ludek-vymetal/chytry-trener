import '../models/user_profile.dart';
import '../models/goal.dart';
import '../core/nutrition/calorie_calculator.dart';

// Core time/phase engine
import '../core/time/time_context.dart';
import '../core/phase/plan_mode.dart';
import '../core/phase/phase_plan.dart';
import '../core/phase/phase_planner_service.dart';
import '../core/phase/phase_resolver.dart';
import '../core/phase/phase.dart';

// Food strategy layer
import '../core/food/food_strategy_adapter.dart';
import '../core/food/food_strategy.dart';

class MacroTarget {
  final int targetCalories;
  final int protein;
  final int carbs;
  final int fat;

  /// ✅ Debug: z jaké váhy se počítalo
  final double weightForCaloriesKg;
  final double weightForProteinKg;

  /// 🧪 Debug informace
  final String phaseLabel;
  final String planModeLabel;
  final int weeksToTarget;
  final String strategyLabel;
  final String rationale;

  MacroTarget({
    required this.targetCalories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.phaseLabel,
    required this.planModeLabel,
    required this.weeksToTarget,
    required this.strategyLabel,
    required this.rationale,
    required this.weightForCaloriesKg,
    required this.weightForProteinKg,
  });
}

class MacroService {
  // ==========================================================
  // 🧠 HLAVNÍ METODA (core engine + food strategy)
  // ==========================================================

  static MacroTarget calculate(UserProfile profile, double tdee) {
    final weight = profile.weight;
    final goal = profile.goal;

    // 0) Bez cíle → neutrální default
    if (goal == null) {
      return _defaultMacros(weight, tdee);
    }

    final now = DateTime.now();

    // 1) MAP: GoalPlanMode -> PlanMode (core)
    final requestedMode = _mapGoalPlanMode(goal.planMode);

    // 2) TIME CONTEXT
    final ctx = TimeContext(
      now: now,
      targetDate: goal.targetDate,
      mode: requestedMode,
    );

    final weeksToTarget = ctx.weeksToTarget;

    // 3) PHASE PLAN
    final List<PhasePlan> plans = PhasePlannerService.buildPlan(ctx);

    // 4) CURRENT PHASE
    final current = PhaseResolver.resolveCurrentPhase(
      plans: plans,
      date: now,
    );

    // 5) EFFECTIVE MODE
    final effectiveMode =
        (ctx.mode == PlanMode.accelerated || current.accelerated)
            ? PlanMode.accelerated
            : PlanMode.normal;

    final planModeLabel = effectiveMode.name;

    // 6) FOOD STRATEGY
    final FoodStrategy strategy = FoodStrategyAdapter.from(
      goal: goal,
      activePhase: current.activePlan,
      mode: effectiveMode,
    );

    // 7) MACRO MATH (podle cílové váhy)
    final targetWeight = goal.targetWeightKg;

    final kgForCalories = CalorieCalculator.weightForCalories(
      currentKg: weight,
      targetKg: targetWeight,
    );

    final kgForProtein = CalorieCalculator.weightForProtein(
      currentKg: weight,
      targetKg: targetWeight,
    );

    final result = _calculateFromStrategy(
      tdee: tdee,
      weightForCaloriesKg: kgForCalories,
      weightForProteinKg: kgForProtein,
      strategy: strategy,
    );

    // 8) FINAL RESULT WITH DEBUG
    return MacroTarget(
      targetCalories: result.targetCalories,
      protein: result.protein,
      carbs: result.carbs,
      fat: result.fat,
      phaseLabel: _phaseLabel(current.phase),
      planModeLabel: planModeLabel,
      weeksToTarget: weeksToTarget,
      strategyLabel: strategy.label,
      rationale: strategy.rationale,
      weightForCaloriesKg: kgForCalories,
      weightForProteinKg: kgForProtein,
    );
  }

  // ==========================================================
  // MAP: GoalPlanMode -> PlanMode
  // ==========================================================

  static PlanMode _mapGoalPlanMode(GoalPlanMode mode) {
    switch (mode) {
      case GoalPlanMode.auto:
        return PlanMode.normal;
      case GoalPlanMode.normal:
        return PlanMode.normal;
      case GoalPlanMode.accelerated:
        return PlanMode.accelerated;
    }
  }

  // ==========================================================
  // Label pro PhaseType
  // ==========================================================

  static String _phaseLabel(PhaseType phase) {
    switch (phase) {
      case PhaseType.gaining:
        return 'Nabírání';
      case PhaseType.cutting:
        return 'Shazování';
      case PhaseType.peaking:
        return 'Rýsování';
      case PhaseType.maintenance:
        return 'Údržba';
    }
  }

  // ==========================================================
  // 🧮 Výpočet makro gramů z FoodStrategy
  // ==========================================================

  static _MacroResult _calculateFromStrategy({
    required double tdee,
    required double weightForCaloriesKg,
    required double weightForProteinKg,
    required FoodStrategy strategy,
  }) {
    // Kalorie (multiplier zvolí strategy)
    final calories = tdee * strategy.calorieMultiplier;

    // Protein z cílové váhy
    var proteinG = weightForProteinKg * strategy.proteinGPerKg;

    // Tuky z “kalorické váhy” (current / průměr)
    var fatG = weightForCaloriesKg * strategy.fatGPerKg;

    // Bezpečnostní minima
    if (proteinG < weightForProteinKg * 1.6) proteinG = weightForProteinKg * 1.6;
    if (fatG < weightForCaloriesKg * 0.6) fatG = weightForCaloriesKg * 0.6;

    final proteinCalories = proteinG * 4;
    final fatCalories = fatG * 9;

    // Sacharidy jako zbytek
    final carbsCalories = calories - proteinCalories - fatCalories;
    final carbsG = carbsCalories / 4;

    final safeCarbs = carbsG < 0 ? 0.0 : carbsG;

    return _MacroResult(
      targetCalories: calories.round(),
      protein: proteinG.round(),
      fat: fatG.round(),
      carbs: safeCarbs.round(),
    );
  }

  // ==========================================================
  // Default bez cíle
  // ==========================================================

  static MacroTarget _defaultMacros(double weight, double tdee) {
    final calories = tdee;

    final proteinG = weight * 2.0;
    final fatG = weight * 0.9;

    final proteinCalories = proteinG * 4;
    final fatCalories = fatG * 9;
    final carbsCalories = calories - proteinCalories - fatCalories;
    final carbsG = carbsCalories / 4;

    return MacroTarget(
      targetCalories: calories.round(),
      protein: proteinG.round(),
      fat: fatG.round(),
      carbs: (carbsG < 0 ? 0 : carbsG).round(),
      phaseLabel: 'N/A',
      planModeLabel: 'default',
      weeksToTarget: 0,
      strategyLabel: 'Default',
      rationale: 'Bez cíle: údržba + rozumné makro poměry.',
      weightForCaloriesKg: weight,
      weightForProteinKg: weight,
    );
  }
}

// ----------------------------------------------------------
// interní výsledek bez debug polí
// ----------------------------------------------------------

class _MacroResult {
  final int targetCalories;
  final int protein;
  final int carbs;
  final int fat;

  _MacroResult({
    required this.targetCalories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });
}
