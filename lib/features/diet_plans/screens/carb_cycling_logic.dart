import 'package:flutter/material.dart' show TimeOfDay;
import 'package:dart_application_1/features/diet_plans/models/carb_cycling_plan.dart';
import 'package:dart_application_1/models/diet_preference.dart';
import 'package:dart_application_1/models/user_profile.dart';
import 'package:dart_application_1/core/nutrition/hollywood_prep.dart';

import '../../../l10n/app_localizations.dart';
import '../logic/diet_macro_service.dart';
import '../logic/diet_target_service.dart';
import '../logic/meal_composer.dart';

class CarbCyclingCalculator {
  static List<String> days(AppLocalizations l10n) => [
        l10n.monday,
        l10n.tuesday,
        l10n.wednesday,
        l10n.thursday,
        l10n.friday,
        l10n.saturday,
        l10n.sunday,
      ];

  /// Sacharidové vlny – stejný týdenní kalorický cíl jako lineární plán,
  /// sacharidy rozložené do vln (viz [DietMacroService.carbCyclingDailyCarbs]).
  static CarbCyclingPlan calculate({
    required UserProfile profile,
    required AppLocalizations l10n,
  }) {
    final base = DietMacroService.linear(profile);
    final dailyCarbs = DietMacroService.carbCyclingDailyCarbs(base.carbs);

    final provisional = CarbCyclingPlan(
      dailyCarbs: dailyCarbs,
      protein: base.protein,
      fats: base.fats,
      weeklyBank: dailyCarbs.fold<double>(0, (a, b) => a + b),
    );

    final target = DietTargetService.resolve(profile, l10n);

    return provisional.copyWith(
      mealPlan: generateWeeklyMealPlan(
        plan: provisional,
        l10n: l10n,
        planType: 'Vlny',
        preference: profile.diet,
        budget: profile.budget,
        noteOverride:
            '${l10n.carbCyclingDescriptionShort}\n${l10n.calculation}: ${target.sourceLabel}',
      ),
    );
  }

  /// Lineární plán – každý den stejná makra z hlavního výpočtu.
  static CarbCyclingPlan createLinearPlan({
    required UserProfile profile,
    required AppLocalizations l10n,
  }) {
    final base = DietMacroService.linear(profile);
    final target = DietTargetService.resolve(profile, l10n);

    final provisional = CarbCyclingPlan(
      dailyCarbs: List.filled(7, base.carbs),
      protein: base.protein,
      fats: base.fats,
      weeklyBank: base.carbs * 7,
    );

    return provisional.copyWith(
      mealPlan: generateWeeklyMealPlan(
        plan: provisional,
        l10n: l10n,
        planType: 'Linear',
        preference: profile.diet,
        budget: profile.budget,
        noteOverride: '${l10n.calculation}: ${target.sourceLabel}',
      ),
    );
  }

  /// Hollywood training – stejná makra každý den, ale podle fáze přípravy
  /// na natáčení (viz [HollywoodPrep]). Profil musí mít
  /// `selectedPlan == HollywoodPrep.planKey` a datum natáčení.
  static CarbCyclingPlan createHollywoodPlan({
    required UserProfile profile,
    required AppLocalizations l10n,
  }) {
    final shoot = profile.hollywoodShootDate;
    final String status;
    if (shoot == null) {
      status = l10n.hollywoodNoDate;
    } else if (HollywoodPrep.weekFor(shoot) == null) {
      final start = HollywoodPrep.startDate(shoot);
      status = DateTime.now().isBefore(start)
          ? l10n.hollywoodNotStarted(_fmt(start), _fmt(shoot))
          : l10n.hollywoodFinished(_fmt(shoot));
    } else {
      status = '${DietMacroService.base(profile).rationale}\n'
          '${l10n.hollywoodShootDate}: ${_fmt(shoot)}';
    }

    return _programPlan(
      profile: profile,
      l10n: l10n,
      planKey: HollywoodPrep.planKey,
      note: '${HollywoodPrep.name}\n$status',
    );
  }

  /// Bikini fitness – makra podle fáze 16týdenní přípravy na závody
  /// (viz [BikiniPrep]). Profil musí mít `selectedPlan == BikiniPrep.planKey`
  /// a datum závodu.
  static CarbCyclingPlan createBikiniPlan({
    required UserProfile profile,
    required AppLocalizations l10n,
  }) {
    final meet = profile.bikiniMeetDate;
    final String status;
    if (meet == null) {
      status = l10n.bikiniNoDate;
    } else if (BikiniPrep.weekFor(meet) == null) {
      final start = BikiniPrep.startDate(meet);
      status = DateTime.now().isBefore(start)
          ? l10n.bikiniNotStarted(_fmt(start), _fmt(meet))
          : l10n.bikiniFinished(_fmt(meet));
    } else {
      status = '${DietMacroService.base(profile).rationale}\n'
          '${l10n.meetDate}: ${_fmt(meet)}';
    }

    return _programPlan(
      profile: profile,
      l10n: l10n,
      planKey: BikiniPrep.planKey,
      note: '${BikiniPrep.name}\n$status',
    );
  }

  /// Kulatý zadek – mírný přebytek pro růst hýždí (viz [GlutePlan]).
  /// Profil musí mít `selectedPlan == GlutePlan.planKey`.
  static CarbCyclingPlan createGlutePlan({
    required UserProfile profile,
    required AppLocalizations l10n,
  }) {
    return _programPlan(
      profile: profile,
      l10n: l10n,
      planKey: GlutePlan.planKey,
      note: '${GlutePlan.name}\n${DietMacroService.base(profile).rationale}',
    );
  }

  /// Jídelníček programu: stejná makra každý den (z hlavního výpočtu, který
  /// podle `selectedPlan` použije fázi programu).
  static CarbCyclingPlan _programPlan({
    required UserProfile profile,
    required AppLocalizations l10n,
    required String planKey,
    required String note,
  }) {
    final base = DietMacroService.linear(profile);

    final provisional = CarbCyclingPlan(
      dailyCarbs: List.filled(7, base.carbs),
      protein: base.protein,
      fats: base.fats,
      weeklyBank: base.carbs * 7,
    );

    return provisional.copyWith(
      mealPlan: generateWeeklyMealPlan(
        plan: provisional,
        l10n: l10n,
        planType: planKey,
        preference: profile.diet,
        budget: profile.budget,
        noteOverride: note,
      ),
    );
  }

  static String _fmt(DateTime d) => '${d.day}.${d.month}.${d.year}';

  static DietMealPlan generateWeeklyMealPlan({
    required CarbCyclingPlan plan,
    required AppLocalizations l10n,
    String planType = 'Vlny',
    List<String> excluded = const [],
    String? noteOverride,
    DietPreference preference = DietPreference.none,
    bool budget = false,
  }) {
    final localizedDays = days(l10n);

    final daysList = List<PlannedDay>.generate(
      localizedDays.length,
      (index) => generateDayPlan(
        l10n: l10n,
        dayName: localizedDays[index],
        carbs: index < plan.dailyCarbs.length ? plan.dailyCarbs[index] : 0.0,
        protein: plan.protein,
        fats: plan.fats,
        excluded: excluded,
        dayIndex: index,
        preference: preference,
        budget: budget,
      ),
    );

    final avgCarbs = plan.dailyCarbs.isEmpty
        ? 0.0
        : plan.dailyCarbs.reduce((a, b) => a + b) / plan.dailyCarbs.length;

    return DietMealPlan(
      planType: planType,
      days: daysList,
      protein: plan.protein,
      carbs: avgCarbs,
      fats: plan.fats,
      note: noteOverride ??
          (planType == 'Linear'
              ? l10n.sameMacrosDaily
              : l10n.carbCyclingDescriptionShort),
    );
  }

  /// Přerušovaný půst – stejná makra jako lineární plán, jen jídla
  /// v jídelním okně.
  static DietMealPlan generateFastingMealPlan({
    required UserProfile profile,
    required AppLocalizations l10n,
    List<String> excluded = const [],
  }) {
    final base = DietMacroService.fasting(profile);
    final target = DietTargetService.resolve(profile, l10n);

    final startTime =
        profile.fastingStartTime ?? const TimeOfDay(hour: 10, minute: 0);
    final eatingWindow = 24 - profile.fastingDuration;

    final localizedDays = days(l10n);

    final daysList = List<PlannedDay>.generate(
      localizedDays.length,
      (index) => generateFastingDayPlan(
        l10n: l10n,
        dayName: localizedDays[index],
        protein: base.protein,
        fats: base.fats,
        carbs: base.carbs,
        startTime: startTime,
        eatingWindowHours: eatingWindow,
        excluded: excluded,
        dayIndex: index,
        preference: profile.diet,
        budget: profile.budget,
      ),
    );

    return DietMealPlan(
      planType: 'Fasting',
      days: daysList,
      protein: base.protein,
      carbs: base.carbs,
      fats: base.fats,
      note: '${l10n.calculation}: ${target.sourceLabel}',
    );
  }

  static PlannedDay generateDayPlan({
    required AppLocalizations l10n,
    required String dayName,
    required double carbs,
    required double protein,
    required double fats,
    List<String> excluded = const [],
    int dayIndex = 0,
    DietPreference preference = DietPreference.none,
    bool budget = false,
  }) {
    return MealComposer.composeDay(
      dayName: dayName,
      slots: MealComposer.standardSlots(
        breakfast: l10n.breakfast,
        snack: l10n.snack,
        lunch: l10n.lunch,
        snack2: '${l10n.snack} 2',
        dinner: l10n.dinner,
      ),
      protein: protein,
      carbs: carbs,
      fats: fats,
      excluded: excluded,
      dayIndex: dayIndex,
      preference: preference,
      budget: budget,
    );
  }

  static PlannedDay generateFastingDayPlan({
    required AppLocalizations l10n,
    required String dayName,
    required double protein,
    required double carbs,
    required double fats,
    required TimeOfDay startTime,
    required int eatingWindowHours,
    List<String> excluded = const [],
    int dayIndex = 0,
    DietPreference preference = DietPreference.none,
    bool budget = false,
  }) {
    final mealTimes = _buildMealTimes(
      startTime: startTime,
      eatingWindowHours: eatingWindowHours,
      count: 4,
    );

    return MealComposer.composeDay(
      dayName: dayName,
      slots: MealComposer.fastingSlots(
        firstMeal: l10n.firstMeal,
        lunch: l10n.lunch,
        snack: l10n.snack,
        lastMeal: l10n.lastMeal,
        times: mealTimes,
      ),
      protein: protein,
      carbs: carbs,
      fats: fats,
      excluded: excluded,
      dayIndex: dayIndex,
      preference: preference,
      budget: budget,
    );
  }

  static List<String> _buildMealTimes({
    required TimeOfDay startTime,
    required int eatingWindowHours,
    required int count,
  }) {
    if (count <= 1) {
      return [_formatTime(startTime)];
    }

    final totalMinutes = eatingWindowHours * 60;
    final gap = totalMinutes ~/ (count - 1);

    return List.generate(count, (index) {
      final minutes = (startTime.hour * 60) + startTime.minute + (gap * index);
      final normalized = minutes % (24 * 60);
      final hour = normalized ~/ 60;
      final minute = normalized % 60;

      return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    });
  }

  static String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
