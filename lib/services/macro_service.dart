import '../models/user_profile.dart';
import '../models/goal.dart';
import '../core/nutrition/calorie_calculator.dart';
import '../core/nutrition/hollywood_prep.dart';

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

    // Jídelníčky programů (Hollywood training, Bikini fitness, Kulatý
    // zadek) mají vlastní výpočet – platí pro celou aplikaci (přehled,
    // jídelníčky, dopočítání do zbytku dne).
    final program = _programMacros(profile, tdee);
    if (program != null) return program;

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
    final List<PhasePlan> plans =
        PhasePlannerService.buildPlan(ctx, goal: goal);

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
      minCalories: _minCaloriesFor(profile),
      currentWeightKg: weight,
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
      phaseLabel: current.activePlan.label ?? _phaseLabel(current.phase),
      planModeLabel: planModeLabel,
      weeksToTarget: weeksToTarget,
      strategyLabel: strategy.labelKey,
      rationale: strategy.labelKey,
      weightForCaloriesKg: kgForCalories,
      weightForProteinKg: kgForProtein,
    );
  }

  // ==========================================================
  // Hollywood training
  // ==========================================================

  /// Makra pro jídelníčky tréninkových programů (Hollywood training,
  /// Bikini fitness, Kulatý zadek), nebo `null`, když se nepoužijí (jiný
  /// jídelníček, chybí datum, příprava ještě nezačala / skončila, nebo
  /// klient má podporu při poruše příjmu potravy).
  static MacroTarget? _programMacros(UserProfile profile, double tdee) {
    final goal = profile.goal;
    if (goal?.reason == GoalReason.eatingDisorderSupport) return null;

    final String name;
    final PrepPhase phase;
    final String weekText;
    final int weeksLeft;

    switch (profile.selectedPlan) {
      case HollywoodPrep.planKey:
        final shootDate = profile.hollywoodShootDate;
        final shootWeek =
            shootDate == null ? null : HollywoodPrep.weekFor(shootDate);
        if (shootWeek == null) return null;
        name = HollywoodPrep.name;
        phase = HollywoodPrep.phaseFor(shootWeek);
        weekText = 'týden $shootWeek/${HollywoodPrep.totalWeeks}';
        weeksLeft = HollywoodPrep.totalWeeks - shootWeek;
        break;
      case BikiniPrep.planKey:
        final meetDate = profile.bikiniMeetDate;
        final meetWeek =
            meetDate == null ? null : BikiniPrep.weekFor(meetDate);
        if (meetWeek == null) return null;
        name = BikiniPrep.name;
        phase = BikiniPrep.phaseFor(meetWeek);
        weekText = 'týden $meetWeek/${BikiniPrep.totalWeeks}';
        weeksLeft = BikiniPrep.totalWeeks - meetWeek;
        break;
      case GlutePlan.planKey:
        name = GlutePlan.name;
        phase = GlutePlan.phase;
        weekText = 'růst hýždí';
        weeksLeft = 0;
        break;
      case StrengthPlan.planKey:
        name = StrengthPlan.name;
        phase = StrengthPlan.phase;
        weekText = 'bench press / trojboj';
        weeksLeft = 0;
        break;
      default:
        return null;
    }

    final weight = profile.weight;
    final kgForCalories = CalorieCalculator.weightForCalories(
      currentKg: weight,
      targetKg: goal?.targetWeightKg,
    );
    final kgForProtein = CalorieCalculator.weightForProtein(
      currentKg: weight,
      targetKg: goal?.targetWeightKg,
    );

    final strategy = FoodStrategy(
      calorieMultiplier: phase.calorieMultiplier,
      proteinGPerKg: phase.proteinGPerKg,
      fatGPerKg: phase.fatGPerKg,
      preferHighCarbs: phase.weeklyLossPct == null,
      labelKey: name,
      rationaleKey: name,
      weeklyLossPct: phase.weeklyLossPct,
    );

    final result = _calculateFromStrategy(
      tdee: tdee,
      minCalories: _minCaloriesFor(profile),
      currentWeightKg: weight,
      weightForCaloriesKg: kgForCalories,
      weightForProteinKg: kgForProtein,
      strategy: strategy,
    );

    final String energyText;
    if (phase.weeklyLossPct != null) {
      energyText =
          'úbytek ${phase.weeklyLossPct!.toStringAsFixed(2)} % hmotnosti týdně';
    } else if (phase.calorieMultiplier > 1.0) {
      energyText =
          'přebytek ${((phase.calorieMultiplier - 1) * 100).toStringAsFixed(1)} % nad TDEE';
    } else {
      energyText = 'příjem na údržbě, vyšší sacharidy';
    }

    return MacroTarget(
      targetCalories: result.targetCalories,
      protein: result.protein,
      carbs: result.carbs,
      fat: result.fat,
      phaseLabel: '$name – $weekText: ${phase.label}',
      planModeLabel: 'program',
      weeksToTarget: weeksLeft,
      strategyLabel: name,
      rationale: '$name – ${phase.label}, $energyText.',
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
    required double minCalories,
    required double currentWeightKg,
    required double weightForCaloriesKg,
    required double weightForProteinKg,
    required FoodStrategy strategy,
  }) {
    // Kalorie: v redukčních fázích podle cílového tempa úbytku
    // (% tělesné hmotnosti týdně), jinak násobek TDEE.
    var calories = tdee * strategy.calorieMultiplier;

    final lossPct = strategy.weeklyLossPct;
    if (lossPct != null && lossPct > 0) {
      // 1 kg tukové tkáně ≈ 7700 kcal
      final dailyDeficit = currentWeightKg * (lossPct / 100) * 7700 / 7;
      calories = tdee - dailyDeficit;

      // Max. deficit 25 % TDEE (stejné pravidlo jako FoodSafetyRules).
      final maxDeficitFloor = tdee * (1 - FoodStrategyAdapter.safety.maxDeficitPct);
      if (calories < maxDeficitFloor) calories = maxDeficitFloor;
    }

    // Bezpečnostní minimum kalorií. Pokud je samotné TDEE nižší než
    // minimum, nejdeme nad TDEE (nechceme vynucovat přebytek).
    final floor = minCalories < tdee ? minCalories : tdee;
    if (calories < floor) calories = floor;

    // Protein z cílové váhy
    var proteinG = weightForProteinKg * strategy.proteinGPerKg;

    // Tuky z “kalorické váhy” (current / průměr)
    var fatG = weightForCaloriesKg * strategy.fatGPerKg;

    // Bezpečnostní minima
    final minFatG = weightForCaloriesKg * 0.6;
    if (proteinG < weightForProteinKg * 1.6) proteinG = weightForProteinKg * 1.6;
    if (fatG < minFatG) fatG = minFatG;

    // Když se bílkoviny + tuky nevejdou do kalorií, nejdřív ubereme tuky
    // až na jejich minimum.
    final overflow = proteinG * 4 + fatG * 9 - calories;
    if (overflow > 0) {
      final reducedFat = fatG - overflow / 9;
      fatG = reducedFat < minFatG ? minFatG : reducedFat;
    }

    // Sacharidy jako zbytek
    final carbsCalories = calories - proteinG * 4 - fatG * 9;
    final carbsG = carbsCalories < 0 ? 0.0 : carbsCalories / 4;

    final protein = proteinG.round();
    final fat = fatG.round();
    final carbs = carbsG.round();

    // Cílové kalorie vždy odpovídají součtu maker (aby čísla v UI seděla).
    final macroCalories = protein * 4 + carbs * 4 + fat * 9;

    return _MacroResult(
      targetCalories: macroCalories,
      protein: protein,
      fat: fat,
      carbs: carbs,
    );
  }

  /// Minimální rozumný denní příjem (běžně doporučovaná hranice).
  static double _minCaloriesFor(UserProfile profile) {
    return profile.gender == 'male' ? 1500 : 1200;
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

    final protein = proteinG.round();
    final fat = fatG.round();
    final carbs = (carbsG < 0 ? 0 : carbsG).round();

    return MacroTarget(
      targetCalories: protein * 4 + carbs * 4 + fat * 9,
      protein: protein,
      fat: fat,
      carbs: carbs,
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
