import 'package:flutter/material.dart' show TimeOfDay;
import 'package:dart_application_1/features/diet_plans/models/carb_cycling_plan.dart';
import 'package:dart_application_1/models/goal.dart';
import 'package:dart_application_1/models/user_profile.dart';


import '../../../l10n/app_localizations.dart';
import '../logic/diet_target_service.dart';

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

  /// Sacharidové vlny
  static CarbCyclingPlan calculate({
    required UserProfile profile,
    required AppLocalizations l10n,
  }) {
    final double targetCalories =
        profile.tdee * 0.9;

    final double protein =
        profile.weight * 2.2;

    final double fats =
        profile.weight * 0.8;

    final double carbsCalories =
        targetCalories -
            (protein * 4) -
            (fats * 9);

    final double avgCarbs =
        (carbsCalories / 4)
            .clamp(50.0, 400.0)
            .toDouble();

    final double weeklyBank =
        avgCarbs * 7;

    final double lowDay =
        (avgCarbs * 0.25)
            .clamp(50.0, 120.0)
            .toDouble();

    final double remainingBank =
        weeklyBank - (2 * lowDay);

    final double baseShare =
        remainingBank / 5;

    const multipliers = [
      0.65,
      0.85,
      1.0,
      1.15,
      1.35,
    ];

    final rawCarbs = [
      lowDay,
      baseShare * multipliers[0],
      lowDay,
      baseShare * multipliers[1],
      baseShare * multipliers[2],
      baseShare * multipliers[3],
      baseShare * multipliers[4],
    ];

    final dailyCarbs = rawCarbs
        .map(
          (g) =>
              (g / 5).round() * 5.0,
        )
        .toList();

    final roundedWeeklyBank =
        dailyCarbs.fold<double>(
      0.0,
      (sum, value) => sum + value,
    );

    final provisional =
        CarbCyclingPlan(
      dailyCarbs: dailyCarbs,
      protein: protein,
      fats: fats,
      weeklyBank:
          roundedWeeklyBank,
    );

    final mealPlan =
        generateWeeklyMealPlan(
      plan: provisional,
      l10n: l10n,
      planType: 'Vlny',
    );

    return provisional.copyWith(
      mealPlan: mealPlan,
    );
  }

  /// Linear
  static CarbCyclingPlan createLinearPlan({
    required UserProfile profile,
    required AppLocalizations l10n,
  }) {
    final target =
        DietTargetService.resolve(
      profile,
      l10n,
    );

    final double targetCalories =
        target.targetCalories;

    final double protein =
        profile.weight * 2.0;

    final double dailyCarbs =
        profile.goal?.phase ==
                GoalPhase.build
            ? 260.0
            : 240.0;

    final double fats =
        (targetCalories -
                (protein * 4) -
                (dailyCarbs * 4)) /
            9;

    final provisional =
        CarbCyclingPlan(
      dailyCarbs:
          List.filled(
        7,
        dailyCarbs,
      ),
      protein: protein,
      fats: fats,
      weeklyBank:
          dailyCarbs * 7,
    );

    final mealPlan =
        generateWeeklyMealPlan(
      plan: provisional,
      l10n: l10n,
      planType: 'Linear',
      noteOverride:
          '${l10n.calculation}: ${target.sourceLabel}',
    );

    return provisional.copyWith(
      mealPlan: mealPlan,
    );
  }

  static DietMealPlan generateWeeklyMealPlan({
    required CarbCyclingPlan plan,
    required AppLocalizations l10n,
    String planType = 'Vlny',
    List<String> excluded =
        const [],
    String? noteOverride,
  }) {
    final localizedDays =
        days(l10n);

    final daysList =
        List<PlannedDay>.generate(
      localizedDays.length,
      (index) {
        return generateDayPlan(
          l10n: l10n,
          dayName:
              localizedDays[index],
          carbs:
              plan.dailyCarbs[index],
          protein: plan.protein,
          fats: plan.fats,
          excluded: excluded,
        );
      },
    );

    final avgCarbs =
        plan.dailyCarbs.isEmpty
            ? 0.0
            : plan.dailyCarbs
                    .reduce(
                      (a, b) => a + b,
                    ) /
                plan.dailyCarbs.length;

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

  /// Fasting
  static DietMealPlan
      generateFastingMealPlan({
    required UserProfile profile,
    required AppLocalizations l10n,
    List<String> excluded =
        const [],
  }) {
    final target =
        DietTargetService.resolve(
      profile,
      l10n,
    );

    final targetCalories =
        target.targetCalories;

    final protein =
        profile.weight * 2.0;

    final fats =
        profile.weight * 0.8;

    final carbs =
        ((targetCalories -
                        (protein * 4) -
                        (fats * 9)) /
                    4)
                .clamp(20.0, 220.0)
                .toDouble();

    final startTime =
        profile.fastingStartTime ??
            const TimeOfDay(
              hour: 10,
              minute: 0,
            );

    final fastingDuration =
        profile.fastingDuration;

    final eatingWindow =
        24 - fastingDuration;

    final localizedDays =
        days(l10n);

    final daysList =
        List<PlannedDay>.generate(
      localizedDays.length,
      (index) {
        return generateFastingDayPlan(
          l10n: l10n,
          dayName:
              localizedDays[index],
          protein: protein,
          fats: fats,
          carbs: carbs,
          startTime: startTime,
          eatingWindowHours:
              eatingWindow,
          excluded: excluded,
        );
      },
    );

    return DietMealPlan(
      planType: 'Fasting',
      days: daysList,
      protein: protein,
      carbs: carbs,
      fats: fats,
      note:
          '${l10n.calculation}: ${target.sourceLabel}',
    );
  }

  static PlannedDay generateDayPlan({
    required AppLocalizations l10n,
    required String dayName,
    required double carbs,
    required double protein,
    required double fats,
    List<String> excluded =
        const [],
  }) {
    final meals = <PlannedMeal>[
      _breakfast(
        l10n,
        carbs * 0.25,
        protein * 0.25,
        fats * 0.20,
        excluded,
      ),
      _snack(
        l10n,
        l10n.snack,
        carbs * 0.15,
        protein * 0.15,
        fats * 0.15,
        excluded,
      ),
      _mainMeal(
        l10n,
        l10n.lunch,
        carbs * 0.30,
        protein * 0.30,
        fats * 0.30,
        excluded,
      ),
      _snack(
        l10n,
        '${l10n.snack} 2',
        carbs * 0.10,
        protein * 0.10,
        fats * 0.10,
        excluded,
      ),
      _mainMeal(
        l10n,
        l10n.dinner,
        carbs * 0.20,
        protein * 0.20,
        fats * 0.25,
        excluded,
      ),
    ];

    return PlannedDay(
      dayName: dayName,
      meals: meals,
      protein: protein,
      carbs: carbs,
      fats: fats,
    );
  }

  static PlannedDay
      generateFastingDayPlan({
    required AppLocalizations l10n,
    required String dayName,
    required double protein,
    required double carbs,
    required double fats,
    required TimeOfDay startTime,
    required int eatingWindowHours,
    List<String> excluded =
        const [],
  }) {
    final mealTimes =
        _buildMealTimes(
      startTime: startTime,
      eatingWindowHours:
          eatingWindowHours,
      count: 4,
    );

    final meals = <PlannedMeal>[
      _breakfast(
        l10n,
        carbs * 0.30,
        protein * 0.30,
        fats * 0.20,
        excluded,
        time: mealTimes[0],
        label:
            l10n.firstMeal,
      ),
      _mainMeal(
        l10n,
        l10n.lunch,
        carbs * 0.35,
        protein * 0.30,
        fats * 0.30,
        excluded,
        time: mealTimes[1],
      ),
      _snack(
        l10n,
        l10n.snack,
        carbs * 0.10,
        protein * 0.15,
        fats * 0.10,
        excluded,
        time: mealTimes[2],
      ),
      _mainMeal(
        l10n,
        l10n.lastMeal,
        carbs * 0.25,
        protein * 0.25,
        fats * 0.40,
        excluded,
        time: mealTimes[3],
      ),
    ];

    return PlannedDay(
      dayName: dayName,
      meals: meals,
      protein: protein,
      carbs: carbs,
      fats: fats,
    );
  }

  static PlannedMeal _breakfast(
    AppLocalizations l10n,
    double carbs,
    double protein,
    double fats,
    List<String> excluded, {
    String? time,
    String? label,
  }) {
    return PlannedMeal(
      label:
          label ??
              l10n.breakfast,
      name:
          l10n.oatmealProtein,
      description:
          l10n.breakfastDescription,
      protein: protein,
      carbs: carbs,
      fats: fats,
      time: time,
      ingredients: const [],
    );
  }

  static PlannedMeal _snack(
    AppLocalizations l10n,
    String label,
    double carbs,
    double protein,
    double fats,
    List<String> excluded, {
    String? time,
  }) {
    return PlannedMeal(
      label: label,
      name:
          l10n.skyrBanana,
      description:
          l10n.quickSnackDescription,
      protein: protein,
      carbs: carbs,
      fats: fats,
      time: time,
      ingredients: const [],
    );
  }

  static PlannedMeal _mainMeal(
    AppLocalizations l10n,
    String label,
    double carbs,
    double protein,
    double fats,
    List<String> excluded, {
    String? time,
  }) {
    return PlannedMeal(
      label: label,
      name:
          l10n.chickenRice,
      description:
          l10n.mainMealDescription,
      protein: protein,
      carbs: carbs,
      fats: fats,
      time: time,
      ingredients: const [],
    );
  }

  static List<String> _buildMealTimes({
    required TimeOfDay startTime,
    required int eatingWindowHours,
    required int count,
  }) {
    if (count <= 1) {
      return [
        _formatTime(startTime),
      ];
    }

    final totalMinutes =
        eatingWindowHours * 60;

    final gap =
        totalMinutes ~/ (count - 1);

    return List.generate(count,
        (index) {
      final minutes =
          (startTime.hour * 60) +
              startTime.minute +
              (gap * index);

      final normalized =
          minutes % (24 * 60);

      final hour =
          normalized ~/ 60;

      final minute =
          normalized % 60;

      return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    });
  }

  static String _formatTime(
    TimeOfDay time, {
    int addHours = 0,
  }) {
    final hour =
        (time.hour + addHours) % 24;

    return '${hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}