import 'package:flutter/material.dart' show TimeOfDay;
import 'package:dart_application_1/features/diet_plans/models/carb_cycling_plan.dart';
import 'package:dart_application_1/models/goal.dart';
import 'package:dart_application_1/models/user_profile.dart';

import '../../../data/sacharidove_vlny_bank.dart';
import '../../../models/meal.dart';
import '../logic/diet_target_service.dart';

class CarbCyclingCalculator {
  static const List<String> _days = [
    'Pondělí',
    'Úterý',
    'Středa',
    'Čtvrtek',
    'Pátek',
    'Sobota',
    'Neděle',
  ];

  /// Sacharidové vlny mají vlastní logiku.
  /// NENAPOJOVAT na centrální calorie target service.
  static CarbCyclingPlan calculate({required UserProfile profile}) {
    final double targetCalories = profile.tdee * 0.9;
    final double protein = profile.weight * 2.0;

    const double avgTarget = 239.0;
    const double weeklyBank = avgTarget * 7;
    const double lowDay = 50.0;

    final double fatCalories = targetCalories - (protein * 4) - (lowDay * 4);
    final double fats = fatCalories / 9;

    final double remainingBank = weeklyBank - (2 * lowDay);
    final double baseShare = remainingBank / 5;
    const multipliers = [0.65, 0.85, 1.0, 1.15, 1.35];

    final rawCarbs = [
      lowDay,
      baseShare * multipliers[0],
      lowDay,
      baseShare * multipliers[1],
      baseShare * multipliers[2],
      baseShare * multipliers[3],
      baseShare * multipliers[4],
    ];

    final dailyCarbs = rawCarbs.map((g) => (g / 5).round() * 5.0).toList();

    final provisional = CarbCyclingPlan(
      dailyCarbs: dailyCarbs,
      protein: protein,
      fats: fats,
      weeklyBank: weeklyBank,
    );

    final mealPlan = generateWeeklyMealPlan(
      plan: provisional,
      planType: 'Vlny',
    );

    return provisional.copyWith(mealPlan: mealPlan);
  }

  /// Linear může jet přes centrální target service.
  static CarbCyclingPlan createLinearPlan({required UserProfile profile}) {
    final target = DietTargetService.resolve(profile);
    final double targetCalories = target.targetCalories;
    final double protein = profile.weight * 2.0;

    final double dailyCarbs =
        profile.goal?.phase == GoalPhase.build ? 260.0 : 240.0;

    final double fats = (targetCalories - (protein * 4) - (dailyCarbs * 4)) / 9;

    final provisional = CarbCyclingPlan(
      dailyCarbs: List.filled(7, dailyCarbs),
      protein: protein,
      fats: fats,
      weeklyBank: dailyCarbs * 7,
    );

    final mealPlan = generateWeeklyMealPlan(
      plan: provisional,
      planType: 'Linear',
      noteOverride: 'Výpočet: ${target.sourceLabel}',
    );

    return provisional.copyWith(mealPlan: mealPlan);
  }

  static DietMealPlan generateWeeklyMealPlan({
    required CarbCyclingPlan plan,
    String planType = 'Vlny',
    List<String> excluded = const [],
    String? noteOverride,
  }) {
    final days = List<PlannedDay>.generate(_days.length, (index) {
      return generateDayPlan(
        dayName: _days[index],
        carbs: plan.dailyCarbs[index],
        protein: plan.protein,
        fats: plan.fats,
        excluded: excluded,
      );
    });

    final avgCarbs = plan.dailyCarbs.isEmpty
        ? 0.0
        : plan.dailyCarbs.reduce((a, b) => a + b) / plan.dailyCarbs.length;

    return DietMealPlan(
      planType: planType,
      days: days,
      protein: plan.protein,
      carbs: avgCarbs,
      fats: plan.fats,
      note: noteOverride ??
          (planType == 'Linear'
              ? 'Stejná struktura makroživin každý den.'
              : 'Sacharidy se cyklují podle jednotlivých dnů.'),
    );
  }

  /// Fasting může jet přes centrální target service.
  static DietMealPlan generateFastingMealPlan({
    required UserProfile profile,
    List<String> excluded = const [],
  }) {
    final target = DietTargetService.resolve(profile);
    final targetCalories = target.targetCalories;
    final protein = profile.weight * 2.0;
    final fats = profile.weight * 0.8;
    final carbs = ((targetCalories - (protein * 4) - (fats * 9)) / 4)
        .clamp(20.0, 220.0)
        .toDouble();

    final startTime =
        profile.fastingStartTime ?? const TimeOfDay(hour: 10, minute: 0);
    final fastingDuration = profile.fastingDuration;
    final eatingWindow = 24 - fastingDuration;

    final days = List<PlannedDay>.generate(_days.length, (index) {
      return generateFastingDayPlan(
        dayName: _days[index],
        protein: protein,
        fats: fats,
        carbs: carbs,
        startTime: startTime,
        eatingWindowHours: eatingWindow,
        excluded: excluded,
      );
    });

    return DietMealPlan(
      planType: 'Fasting',
      days: days,
      protein: protein,
      carbs: carbs,
      fats: fats,
      note:
          'Výpočet: ${target.sourceLabel} | Okno jídla: ${_formatTime(startTime)} - ${_formatTime(startTime, addHours: eatingWindow)} | režim $fastingDuration:$eatingWindow',
    );
  }

  static PlannedDay generateDayPlan({
    required String dayName,
    required double carbs,
    required double protein,
    required double fats,
    List<String> excluded = const [],
  }) {
    final meals = <PlannedMeal>[
      _breakfast(carbs * 0.25, protein * 0.25, fats * 0.20, excluded),
      _snack('Svačina', carbs * 0.15, protein * 0.15, fats * 0.15, excluded),
      _mainMeal('Oběd', carbs * 0.30, protein * 0.30, fats * 0.30, excluded),
      _snack('Svačina 2', carbs * 0.10, protein * 0.10, fats * 0.10, excluded),
      _mainMeal('Večeře', carbs * 0.20, protein * 0.20, fats * 0.25, excluded),
    ];

    return PlannedDay(
      dayName: dayName,
      meals: meals,
      protein: protein,
      carbs: carbs,
      fats: fats,
    );
  }

  static PlannedDay generateFastingDayPlan({
    required String dayName,
    required double protein,
    required double carbs,
    required double fats,
    required TimeOfDay startTime,
    required int eatingWindowHours,
    List<String> excluded = const [],
  }) {
    final mealTimes = _buildMealTimes(
      startTime: startTime,
      eatingWindowHours: eatingWindowHours,
      count: 4,
    );

    final meals = <PlannedMeal>[
      _breakfast(
        carbs * 0.30,
        protein * 0.30,
        fats * 0.20,
        excluded,
        time: mealTimes[0],
        label: 'První jídlo',
      ),
      _mainMeal(
        'Oběd',
        carbs * 0.35,
        protein * 0.30,
        fats * 0.30,
        excluded,
        time: mealTimes[1],
      ),
      _snack(
        'Svačina',
        carbs * 0.10,
        protein * 0.15,
        fats * 0.10,
        excluded,
        time: mealTimes[2],
      ),
      _mainMeal(
        'Poslední jídlo',
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

  static List<Map<String, dynamic>> generateDailyMenu({
    required double carbs,
    required double protein,
    required double fats,
    bool isKeto = false,
  }) {
    final day = generateDayPlan(
      dayName: 'Dnes',
      carbs: isKeto ? carbs.clamp(0, 30).toDouble() : carbs,
      protein: protein,
      fats: fats,
    );
    return day.meals.map((e) => e.toMap()).toList();
  }

  static PlannedMeal _breakfast(
    double carbs,
    double protein,
    double fats,
    List<String> excluded, {
    String? time,
    String label = 'Snídaně',
  }) {
    final noEggs = excluded.contains('Vejce');

    if (!noEggs && carbs < 35) {
      final eggCount = (protein / 6.5).clamp(2.0, 5.0).toDouble();
      return PlannedMeal(
        label: label,
        name: 'Míchaná vejce se zeleninou',
        description:
            '${eggCount.round()} ks vejce + zelenina + malé množství tuku',
        protein: protein,
        carbs: carbs,
        fats: fats,
        time: time,
        ingredients: [
          MealIngredient(name: 'Vejce', amount: eggCount, unit: 'ks'),
          const MealIngredient(name: 'Zelenina', amount: 150, unit: 'g'),
          const MealIngredient(name: 'Olivový olej', amount: 10, unit: 'g'),
        ],
      );
    }

    final oats = (carbs / 0.68).clamp(40.0, 100.0).toDouble();
    return PlannedMeal(
      label: label,
      name: 'Ovesná kaše s proteinem',
      description: '${oats.round()} g vloček + protein + ovoce',
      protein: protein,
      carbs: carbs,
      fats: fats,
      grams: oats.round(),
      time: time,
      ingredients: [
        MealIngredient(name: 'Ovesné vločky', amount: oats, unit: 'g'),
        const MealIngredient(name: 'Protein whey', amount: 30, unit: 'g'),
        const MealIngredient(name: 'Borůvky', amount: 100, unit: 'g'),
      ],
    );
  }

  static PlannedMeal _snack(
    String label,
    double carbs,
    double protein,
    double fats,
    List<String> excluded, {
    String? time,
  }) {
    if (carbs >= 18) {
      return PlannedMeal(
        label: label,
        name: 'Skyr s banánem',
        description: 'Rychlá svačina pro doplnění bílkovin a sacharidů.',
        protein: protein,
        carbs: carbs,
        fats: fats,
        time: time,
        ingredients: const [
          MealIngredient(name: 'Skyr', amount: 200, unit: 'g'),
          MealIngredient(name: 'Banán', amount: 120, unit: 'g'),
        ],
      );
    }

    return PlannedMeal(
      label: label,
      name: 'Šunka a sýr se zeleninou',
      description: 'Nízkosacharidová svačina.',
      protein: protein,
      carbs: carbs,
      fats: fats,
      time: time,
      ingredients: const [
        MealIngredient(name: 'Šunka', amount: 100, unit: 'g'),
        MealIngredient(name: 'Gouda', amount: 40, unit: 'g'),
        MealIngredient(name: 'Zelenina', amount: 100, unit: 'g'),
      ],
    );
  }

  static PlannedMeal _mainMeal(
    String label,
    double carbs,
    double protein,
    double fats,
    List<String> excluded, {
    String? time,
  }) {
    final proteinSource = excluded.contains('Hovězí maso')
        ? _pickMeal(['Krůtí prsa', 'Kuřecí prsa'])
        : _pickMeal(['Kuřecí prsa', 'Krůtí prsa', 'Hovězí libové']);

    final carbSource = carbs <= 10
        ? null
        : _pickMeal([
            'Rýže bílá (suchá)',
            'Brambory',
            'Batáty',
            'Těstoviny (suché)',
            'Ovesné vločky',
          ]);

    final proteinGrams =
        (proteinSource == null || proteinSource.proteinPer100g <= 0)
            ? 150.0
            : (protein / (proteinSource.proteinPer100g / 100))
                .clamp(120.0, 240.0)
                .toDouble();

    final carbGrams = carbSource == null || carbSource.carbsPer100g <= 0
        ? 0.0
        : (carbs / (carbSource.carbsPer100g / 100))
            .clamp(60.0, 220.0)
            .toDouble();

    final ingredients = <MealIngredient>[
      MealIngredient(
        name: proteinSource?.name ?? 'Kuřecí prsa',
        amount: proteinGrams,
        unit: 'g',
      ),
      if (carbSource != null)
        MealIngredient(
          name: carbSource.name,
          amount: carbGrams,
          unit: 'g',
        ),
      const MealIngredient(name: 'Zelenina', amount: 150, unit: 'g'),
      const MealIngredient(name: 'Olivový olej', amount: 10, unit: 'g'),
    ];

    final name = carbSource != null
        ? '${proteinSource?.name ?? 'Kuřecí prsa'} + ${carbSource.name}'
        : (proteinSource?.name ?? 'Kuřecí prsa');

    final desc = carbSource != null
        ? '${proteinGrams.round()} g ${proteinSource?.name ?? 'Kuřecí prsa'} + ${carbGrams.round()} g ${carbSource.name} + zelenina'
        : '${proteinGrams.round()} g ${proteinSource?.name ?? 'Kuřecí prsa'} + zelenina';

    return PlannedMeal(
      label: label,
      name: name,
      description: desc,
      protein: protein,
      carbs: carbs,
      fats: fats,
      grams: proteinGrams.round(),
      time: time,
      ingredients: ingredients,
    );
  }

  static Meal? _pickMeal(List<String> preferredNames) {
    for (final name in preferredNames) {
      try {
        return SacharidoveVlnyBank.items.firstWhere(
          (m) => m.name.toLowerCase() == name.toLowerCase(),
        );
      } catch (_) {
        continue;
      }
    }
    return SacharidoveVlnyBank.items.isEmpty
        ? null
        : SacharidoveVlnyBank.items.first;
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

  static String _formatTime(TimeOfDay time, {int addHours = 0}) {
    final hour = (time.hour + addHours) % 24;
    return '${hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}