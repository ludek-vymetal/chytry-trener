import '../models/energy_adjustment.dart';
import '../models/measurement.dart';
import '../models/user_profile.dart';
import '../models/goal.dart';
import '../core/nutrition/calorie_calculator.dart';
import '../core/nutrition/hollywood_prep.dart';

// Core time/phase engine
import '../core/time/time_context.dart';
import '../core/phase/plan_mode.dart';
import '../core/phase/phase_planner_service.dart';
import '../core/phase/phase_resolver.dart';
import '../core/phase/phase.dart';

// Food strategy layer
import '../core/food/food_strategy_adapter.dart';
import '../core/food/food_strategy.dart';

import 'metabolism_service.dart';

class MacroTarget {
  final int targetCalories;
  final int protein;
  final int carbs;
  final int fat;

  /// ✅ Debug: z jaké váhy se počítalo
  final double weightForCaloriesKg;
  final double weightForProteinKg;

  /// Popisy pro obrazovku „Jak je spočítaný tvůj cíl“ (česky, čitelné).
  final String phaseLabel;
  final String planModeLabel;
  final int weeksToTarget;
  final String strategyLabel;
  final String rationale;

  /// Úprava kalorií podle skutečného vývoje váhy (0 = žádná).
  final int adjustmentKcal;

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
    this.adjustmentKcal = 0,
  });
}

/// Kde v plánu klient právě je – společné pro výpočet maker i pro
/// týdenní kontrolu vážení.
class _PhaseContext {
  final FoodStrategy strategy;
  final String phaseLabel;
  final String planModeLabel;
  final int weeksToTarget;
  final String strategyLabel;

  /// Klíč fáze (změní se při přechodu do další fáze).
  final String phaseKey;

  /// Začátek aktuální fáze (pro vyhodnocení vážení), `null` = neznámý.
  final DateTime? phaseStart;

  /// Plánovaná změna váhy v % za týden (− úbytek, + přírůstek, 0 údržba).
  /// `null` = peak / taper – úprava podle vážení se nedělá (voda, sacharidy).
  final double? expectedPctPerWeek;

  /// Popis energetického cíle fáze.
  final String energyText;

  const _PhaseContext({
    required this.strategy,
    required this.phaseLabel,
    required this.planModeLabel,
    required this.weeksToTarget,
    required this.strategyLabel,
    required this.phaseKey,
    required this.phaseStart,
    required this.expectedPctPerWeek,
    required this.energyText,
  });
}

class MacroService {
  /// Max. změna úpravy kalorií při jedné kontrole.
  static const int _maxStepKcal = 200;

  /// Max. celková úprava kalorií podle vážení.
  static const int _maxTotalKcal = 500;

  /// Nejkratší odstup kontrol vážení (dny).
  static const int _reviewEveryDays = 10;

  // ==========================================================
  // 🧠 HLAVNÍ METODA
  // ==========================================================

  static MacroTarget calculate(UserProfile profile, double tdee) {
    final weight = profile.weight;
    final goal = profile.goal;

    final ctx = _phaseContext(profile, tdee: tdee);

    // Bez cíle (a bez programu) → údržba s rozumnými makry.
    if (ctx == null) {
      return _defaultMacros(profile, tdee);
    }

    final kgForCalories = CalorieCalculator.weightForCalories(
      currentKg: weight,
      targetKg: goal?.targetWeightKg,
    );

    final kgForProtein = proteinReferenceWeight(profile);

    final adjustment = _activeAdjustment(profile);

    final result = _calculateFromStrategy(
      tdee: tdee,
      minCalories: _minCaloriesFor(profile),
      currentWeightKg: weight,
      weightForCaloriesKg: kgForCalories,
      weightForProteinKg: kgForProtein,
      strategy: ctx.strategy,
      adjustmentKcal: adjustment,
    );

    return MacroTarget(
      targetCalories: result.targetCalories,
      protein: result.protein,
      carbs: result.carbs,
      fat: result.fat,
      phaseLabel: ctx.phaseLabel,
      planModeLabel: ctx.planModeLabel,
      weeksToTarget: ctx.weeksToTarget,
      strategyLabel: ctx.strategyLabel,
      rationale: _rationale(
        profile: profile,
        tdee: tdee,
        ctx: ctx,
        proteinRefKg: kgForProtein,
        fatRefKg: kgForCalories,
        adjustmentKcal: adjustment,
      ),
      weightForCaloriesKg: kgForCalories,
      weightForProteinKg: kgForProtein,
      adjustmentKcal: adjustment,
    );
  }

  // ==========================================================
  // Fáze: program (Hollywood, Bikini…) nebo periodizace podle cíle
  // ==========================================================

  static _PhaseContext? _phaseContext(
    UserProfile profile, {
    required double tdee,
    DateTime? at,
  }) {
    final now = at ?? DateTime.now();
    final program = _programContext(profile, now, tdee);
    if (program != null) return program;

    final goal = profile.goal;
    if (goal == null) return null;

    final requestedMode = _mapGoalPlanMode(goal.planMode);

    final time = TimeContext(
      now: now,
      targetDate: goal.targetDate,
      mode: requestedMode,
    );

    final plans = PhasePlannerService.buildPlan(time, goal: goal);
    final current = PhaseResolver.resolveCurrentPhase(
      plans: plans,
      date: now,
    );

    final effectiveMode =
        (time.mode == PlanMode.accelerated || current.accelerated)
            ? PlanMode.accelerated
            : PlanMode.normal;

    final strategy = FoodStrategyAdapter.from(
      goal: goal,
      activePhase: current.activePlan,
      mode: effectiveMode,
    );

    final plan = current.activePlan;
    final label = plan.label ?? _phaseLabel(current.phase);

    double? expected;
    String energyText;
    final lossPct = strategy.weeklyLossPct;
    if (current.phase == PhaseType.peaking) {
      expected = null;
      energyText = 'příjem na údržbě (peak – plnost a výkon)';
    } else if (lossPct != null && lossPct > 0) {
      expected = -lossPct;
      energyText = 'úbytek ${_pct(lossPct)} % hmotnosti týdně';
    } else if (strategy.calorieMultiplier > 1.0) {
      expected = _pctPerWeekFromMultiplier(
        strategy.calorieMultiplier,
        tdee,
        profile.weight,
      );
      energyText =
          'přebytek ${_pct((strategy.calorieMultiplier - 1) * 100)} % nad výdejem';
    } else if (strategy.calorieMultiplier < 1.0) {
      expected = _pctPerWeekFromMultiplier(
        strategy.calorieMultiplier,
        tdee,
        profile.weight,
      );
      energyText =
          'deficit ${_pct((1 - strategy.calorieMultiplier) * 100)} % pod výdejem';
    } else {
      expected = 0;
      energyText = 'příjem na údržbě';
    }

    // Podpora při PPP: nikdy nehubnout.
    if (goal.reason == GoalReason.eatingDisorderSupport &&
        expected != null &&
        expected < 0) {
      expected = 0;
    }

    return _PhaseContext(
      strategy: strategy,
      phaseLabel: label,
      planModeLabel:
          effectiveMode == PlanMode.accelerated ? 'Zrychlený' : 'Běžný',
      weeksToTarget: time.weeksToTarget,
      strategyLabel: '${_goalTypeText(goal.type)} – ${_reasonText(goal.reason)}',
      phaseKey: '${goal.type.name}|$label|${_day(plan.start)}',
      phaseStart: plan.start,
      expectedPctPerWeek: expected,
      energyText: energyText,
    );
  }

  /// Očekávaná změna váhy (% / týden) při příjmu [multiplier] × výdej:
  /// přebytek / deficit kcal × 7 dní / 7700 kcal na kg.
  static double _pctPerWeekFromMultiplier(
    double multiplier,
    double tdee,
    double weightKg,
  ) {
    if (weightKg <= 0) return 0;
    final kgPerWeek = (multiplier - 1) * tdee * 7 / 7700;
    return kgPerWeek / weightKg * 100;
  }

  /// Jídelníčky programů (Hollywood training, Bikini fitness, Kulatý
  /// zadek, Silová příprava), nebo `null`, když se nepoužijí (jiný
  /// jídelníček, chybí datum, příprava ještě nezačala / skončila, nebo
  /// klient má podporu při poruše příjmu potravy).
  static _PhaseContext? _programContext(
    UserProfile profile,
    DateTime now,
    double tdee,
  ) {
    final goal = profile.goal;
    if (goal?.reason == GoalReason.eatingDisorderSupport) return null;

    final String name;
    final PrepPhase phase;
    final String weekText;
    final int weeksLeft;
    DateTime? phaseStart;

    switch (profile.selectedPlan) {
      case HollywoodPrep.planKey:
        final shootDate = profile.hollywoodShootDate;
        final shootWeek =
            shootDate == null ? null : HollywoodPrep.weekFor(shootDate, now);
        if (shootWeek == null) return null;
        name = HollywoodPrep.name;
        phase = HollywoodPrep.phaseFor(shootWeek);
        weekText = 'týden $shootWeek/${HollywoodPrep.totalWeeks}';
        weeksLeft = HollywoodPrep.totalWeeks - shootWeek;
        phaseStart = _programPhaseStart(
          HollywoodPrep.startDate(shootDate!),
          shootWeek,
          (w) => HollywoodPrep.phaseFor(w).label,
        );
        break;
      case BikiniPrep.planKey:
        final meetDate = profile.bikiniMeetDate;
        final meetWeek =
            meetDate == null ? null : BikiniPrep.weekFor(meetDate, now);
        if (meetWeek == null) return null;
        name = BikiniPrep.name;
        phase = BikiniPrep.phaseFor(meetWeek);
        weekText = 'týden $meetWeek/${BikiniPrep.totalWeeks}';
        weeksLeft = BikiniPrep.totalWeeks - meetWeek;
        phaseStart = _programPhaseStart(
          BikiniPrep.startDate(meetDate!),
          meetWeek,
          (w) => BikiniPrep.phaseFor(w).label,
        );
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

    final strategy = FoodStrategy(
      calorieMultiplier: phase.calorieMultiplier,
      proteinGPerKg: phase.proteinGPerKg,
      fatGPerKg: phase.fatGPerKg,
      preferHighCarbs: phase.weeklyLossPct == null,
      labelKey: name,
      rationaleKey: name,
      weeklyLossPct: phase.weeklyLossPct,
    );

    final double? expected;
    final String energyText;
    if (phase.weeklyLossPct != null) {
      expected = -phase.weeklyLossPct!;
      energyText = 'úbytek ${_pct(phase.weeklyLossPct!)} % hmotnosti týdně';
    } else if (phase.calorieMultiplier > 1.0) {
      expected = _pctPerWeekFromMultiplier(
        phase.calorieMultiplier,
        tdee,
        profile.weight,
      );
      energyText =
          'přebytek ${_pct((phase.calorieMultiplier - 1) * 100)} % nad výdejem';
    } else {
      // Peak / natáčení / závod – bez úprav podle vážení.
      expected = phase.isPeak ? null : 0;
      energyText = 'příjem na údržbě, vyšší sacharidy';
    }

    return _PhaseContext(
      strategy: strategy,
      phaseLabel: '$name – $weekText: ${phase.label}',
      planModeLabel: 'Program',
      weeksToTarget: weeksLeft,
      strategyLabel: name,
      phaseKey: '${profile.selectedPlan}|${phase.label}',
      phaseStart: phaseStart,
      expectedPctPerWeek: expected,
      energyText: energyText,
    );
  }

  /// Začátek aktuální fáze programu (první týden se stejným názvem fáze).
  static DateTime _programPhaseStart(
    DateTime programStart,
    int week,
    String Function(int week) labelFor,
  ) {
    final label = labelFor(week);
    var first = week;
    while (first > 1 && labelFor(first - 1) == label) {
      first--;
    }
    return programStart.add(Duration(days: (first - 1) * 7));
  }

  // ==========================================================
  // Bílkoviny – referenční váha
  // ==========================================================

  /// Z jaké váhy se počítají bílkoviny (g/kg).
  ///
  /// * cílová váha, když je zadaná (jako dřív),
  /// * s InBody: nejvýš váha, kterou by člověk měl při „sportovním“ podílu
  ///   tuku (muži 15 %, ženy 23 %) – u vyššího podílu tuku by g/kg z celé
  ///   váhy vyšly zbytečně vysoko; u svalnatých lidí se nic nemění,
  /// * bez InBody a s BMI nad 30: upravená váha (polovina nadváhy nad
  ///   BMI 25), aby bílkoviny nevyšly přes 250 g.
  static double proteinReferenceWeight(UserProfile profile) {
    final current = profile.weight;
    var ref = CalorieCalculator.weightForProtein(
      currentKg: current,
      targetKg: profile.goal?.targetWeightKg,
    );
    if (ref <= 0) return current;

    final comp = profile.bodyComposition;
    if (comp != null && comp.isUsable()) {
      final sportBf = profile.gender == 'male' ? 0.15 : 0.23;
      final atSportBf = comp.leanMassKg / (1 - sportBf);
      if (atSportBf > 0 && atSportBf < ref) ref = atSportBf;
      return ref;
    }

    final hasTarget = (profile.goal?.targetWeightKg ?? 0) > 0;
    if (!hasTarget && profile.height > 0) {
      final h = profile.height / 100.0;
      final bmi = current / (h * h);
      if (bmi > 30) {
        final at25 = 25 * h * h;
        ref = at25 + (current - at25) / 2;
      }
    }
    return ref;
  }

  // ==========================================================
  // Týdenní kontrola vážení
  // ==========================================================

  /// Aktuální úprava kalorií podle vážení (kcal).
  static int _activeAdjustment(UserProfile profile) {
    final adj = profile.energyAdjustment;
    if (adj == null) return 0;
    var kcal = adj.kcal;
    if (profile.goal?.reason == GoalReason.eatingDisorderSupport && kcal < 0) {
      kcal = 0;
    }
    return kcal;
  }

  /// Vyhodnotí vážení za poslední 2–3 týdny aktuální fáze a vrátí novou
  /// úpravu kalorií, nebo `null`, když se nic nemění (málo dat, je moc
  /// brzo od minulé kontroly, tempo odpovídá plánu, peak).
  ///
  /// Princip: když klient hubne pomaleji, než má (nebo nabírá rychleji),
  /// skutečný výdej je nižší, než ukázal odhad → cíl se sníží. A naopak.
  /// Změna je polovina rozdílu (vážení kolísá kvůli vodě), max. ±200 kcal
  /// najednou a ±500 kcal celkem.
  static EnergyAdjustment? weeklyReview(UserProfile profile, [DateTime? at]) {
    final now = at ?? DateTime.now();
    final tdee = MetabolismService.calculateTDEE(
      profile,
      MetabolismService.activityFor(profile),
    );
    final ctx = _phaseContext(profile, tdee: tdee, at: now);
    if (ctx == null) return null;
    final expectedPct = ctx.expectedPctPerWeek;
    if (expectedPct == null) return null;
    if (profile.weight <= 0) return null;

    final previous = profile.energyAdjustment;
    if (previous != null &&
        now.difference(previous.reviewedAt).inDays < _reviewEveryDays) {
      return null;
    }

    var windowStart = now.subtract(const Duration(days: 21));
    final phaseStart = ctx.phaseStart;
    if (phaseStart != null && phaseStart.isAfter(windowStart)) {
      windowStart = phaseStart;
    }
    if (previous != null && previous.reviewedAt.isAfter(windowStart)) {
      windowStart = previous.reviewedAt;
    }

    final actual = weeklyWeightChangeKg(
      profile.measurements,
      from: windowStart,
      to: now,
    );
    if (actual == null) return null;

    final expected = profile.weight * expectedPct / 100;
    final diff = actual - expected; // + = váha jde nahoru víc, než má
    if (diff.abs() < 0.1) return null;

    var step = -diff * 7700 / 7 * 0.5;
    if (step > _maxStepKcal) step = _maxStepKcal.toDouble();
    if (step < -_maxStepKcal) step = -_maxStepKcal.toDouble();

    var total = (previous?.kcal ?? 0) + (step / 10).round() * 10;
    if (total > _maxTotalKcal) total = _maxTotalKcal;
    if (total < -_maxTotalKcal) total = -_maxTotalKcal;
    if (profile.goal?.reason == GoalReason.eatingDisorderSupport &&
        total < 0) {
      total = 0;
    }
    if (previous != null && total == previous.kcal) return null;

    return EnergyAdjustment(
      kcal: total,
      reviewedAt: now,
      phaseKey: ctx.phaseKey,
      actualKgPerWeek: actual,
      expectedKgPerWeek: expected,
    );
  }

  /// Tempo změny váhy v kg za týden (lineární trend), nebo `null`, když je
  /// v období málo vážení (min. 3 vážení rozložená aspoň na 10 dní).
  static double? weeklyWeightChangeKg(
    List<Measurement> measurements, {
    required DateTime from,
    required DateTime to,
  }) {
    final pts = measurements
        .where((m) =>
            m.weight > 0 && !m.date.isBefore(from) && !m.date.isAfter(to))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    if (pts.length < 3) return null;
    final spanDays =
        pts.last.date.difference(pts.first.date).inHours / 24.0;
    if (spanDays < 10) return null;

    final t0 = pts.first.date;
    final xs = pts.map((m) => m.date.difference(t0).inHours / 24.0).toList();
    final ys = pts.map((m) => m.weight).toList();
    final n = xs.length;
    final mx = xs.reduce((a, b) => a + b) / n;
    final my = ys.reduce((a, b) => a + b) / n;
    var sxy = 0.0;
    var sxx = 0.0;
    for (var i = 0; i < n; i++) {
      sxy += (xs[i] - mx) * (ys[i] - my);
      sxx += (xs[i] - mx) * (xs[i] - mx);
    }
    if (sxx == 0) return null;
    return sxy / sxx * 7;
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
  // Texty
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

  static String _goalTypeText(GoalType t) {
    switch (t) {
      case GoalType.strength:
        return 'Síla';
      case GoalType.physique:
        return 'Postava';
      case GoalType.weightLoss:
        return 'Hubnutí';
      case GoalType.endurance:
        return 'Vytrvalost';
      case GoalType.weightGainSupport:
        return 'Nabírání';
    }
  }

  static String _reasonText(GoalReason r) {
    switch (r) {
      case GoalReason.competition:
        return 'soutěž';
      case GoalReason.summerShape:
        return 'forma do léta';
      case GoalReason.health:
        return 'zdraví';
      case GoalReason.performance:
        return 'výkon';
      case GoalReason.aesthetic:
        return 'vzhled';
      case GoalReason.eatingDisorderSupport:
        return 'podpora při PPP';
    }
  }

  static String _pct(double v) {
    var s = v.toStringAsFixed(2);
    s = s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    return s.replaceAll('.', ',');
  }

  static String _num(double v, [int digits = 1]) =>
      v.toStringAsFixed(digits).replaceAll('.', ',');

  static String _day(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String _rationale({
    required UserProfile profile,
    required double tdee,
    required _PhaseContext ctx,
    required double proteinRefKg,
    required double fatRefKg,
    required int adjustmentKcal,
  }) {
    final (bmr, source) = MetabolismService.bmrWithSource(profile);
    final activity = MetabolismService.multiplierFor(
      MetabolismService.activityFor(profile),
    );
    final bmrText = switch (source) {
      BmrSource.measured => 'změřený InBody',
      BmrSource.leanMass => 'z beztukové hmoty z InBody',
      BmrSource.estimate => 'odhad z váhy, výšky a věku',
    };

    final b = StringBuffer()
      ..write('${ctx.phaseLabel}: ${ctx.energyText}. ')
      ..write('Výdej ${tdee.round()} kcal = bazál ${bmr.round()} kcal '
          '($bmrText) × aktivita ${_num(activity, 3)}. ')
      ..write('Bílkoviny ${_num(ctx.strategy.proteinGPerKg)} g/kg '
          '(z ${_num(proteinRefKg)} kg), tuky ${_num(ctx.strategy.fatGPerKg, 2)} g/kg, '
          'zbytek sacharidy.');

    final adj = profile.energyAdjustment;
    if (adjustmentKcal != 0 && adj != null) {
      final sign = adjustmentKcal > 0 ? '+' : '−';
      b.write(' Úprava podle vážení: $sign${adjustmentKcal.abs()} kcal');
      final a = adj.actualKgPerWeek;
      if (a != null) {
        b.write(' (při kontrole ${_num(a, 2)} kg/týden, plán '
            '${_num(adj.expectedKgPerWeek, 2)} kg/týden)');
      }
      b.write('.');
    } else if (ctx.expectedPctPerWeek != null) {
      b.write(' Podle vážení se cíl sám upraví – važ se aspoň 3× týdně '
          'ráno nalačno.');
    }
    return b.toString();
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
    int adjustmentKcal = 0,
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
      final maxDeficitFloor =
          tdee * (1 - FoodStrategyAdapter.safety.maxDeficitPct);
      if (calories < maxDeficitFloor) calories = maxDeficitFloor;
    }

    // Úprava podle skutečného vývoje váhy (odhad výdeje se zpřesní).
    // I s ní nejvýš 35 % pod odhadem výdeje.
    if (adjustmentKcal != 0) {
      calories += adjustmentKcal;
      final hardFloor = tdee * 0.65;
      if (calories < hardFloor) calories = hardFloor;
    }

    // Bezpečnostní minimum kalorií. Pokud je samotné TDEE nižší než
    // minimum, nejdeme nad TDEE (nechceme vynucovat přebytek).
    final floor = minCalories < tdee ? minCalories : tdee;
    if (calories < floor) calories = floor;

    // Protein z referenční váhy
    var proteinG = weightForProteinKg * strategy.proteinGPerKg;

    // Tuky z “kalorické váhy” (current / průměr)
    var fatG = weightForCaloriesKg * strategy.fatGPerKg;

    // Bezpečnostní minima
    final minFatG = weightForCaloriesKg * 0.6;
    if (proteinG < weightForProteinKg * 1.6) {
      proteinG = weightForProteinKg * 1.6;
    }
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

  static MacroTarget _defaultMacros(UserProfile profile, double tdee) {
    final weight = profile.weight;
    final calories = tdee;
    final proteinRef = proteinReferenceWeight(profile);

    final proteinG = proteinRef * 2.0;
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
      phaseLabel: 'Bez cíle',
      planModeLabel: '–',
      weeksToTarget: 0,
      strategyLabel: 'Údržba',
      rationale: 'Bez nastaveného cíle: příjem na úrovni odhadovaného výdeje '
          '(${tdee.round()} kcal), bílkoviny 2 g/kg, tuky 0,9 g/kg. '
          'Nastav cíl a datum, aby se jídlo i trénink řídily periodizací.',
      weightForCaloriesKg: weight,
      weightForProteinKg: proteinRef,
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
