import '../../../data/keto_bank.dart';
import '../../../models/meal.dart';
import '../../../models/user_profile.dart';
import '../models/carb_cycling_plan.dart';

class KetoCalculator {
  static const List<String> _days = [
    'Pondělí',
    'Úterý',
    'Středa',
    'Čtvrtek',
    'Pátek',
    'Sobota',
    'Neděle',
  ];

  static Map<String, double> calculateMacros(UserProfile profile) {
    final double targetCalories = profile.tdee * 0.9;
    const double carbs = 30.0;
    final double protein = profile.weight * 2.0;
    final double fatCalories = targetCalories - (protein * 4) - (carbs * 4);
    final double fats = fatCalories / 9;

    return {
      'protein': protein,
      'fats': fats,
      'carbs': carbs,
    };
  }

  static DietMealPlan generateWeeklyKetoMealPlan({
    required double protein,
    required double fats,
    required double carbs,
    List<String> excludedFoods = const [],
  }) {
    final days = List<PlannedDay>.generate(_days.length, (dayIndex) {
      return PlannedDay(
        dayName: _days[dayIndex],
        protein: protein,
        carbs: carbs,
        fats: fats,
        meals: generateKetoDayPlan(
          protein,
          fats,
          carbs,
          excludedFoods: excludedFoods,
          dayIndex: dayIndex,
        ),
      );
    });

    return DietMealPlan(
      planType: 'Keto',
      days: days,
      protein: protein,
      carbs: carbs,
      fats: fats,
      note: 'Keto režim s nízkým příjmem sacharidů a plným shopping listem.',
    );
  }

  static List<List<Map<String, String>>> generateWeeklyKetoMenu(
    double p,
    double f,
    double c, {
    List<String> excludedFoods = const [],
  }) {
    final plan = generateWeeklyKetoMealPlan(
      protein: p,
      fats: f,
      carbs: c,
      excludedFoods: excludedFoods,
    );

    return plan.days
        .map(
          (day) => day.meals
              .map(
                (meal) => {
                  'label': meal.label,
                  'name': meal.name,
                  'description': meal.description,
                },
              )
              .toList(),
        )
        .toList();
  }

  static List<Map<String, String>> generateKetoMenu(
    double p,
    double f,
    double c, {
    List<String> excludedFoods = const [],
  }) {
    return generateKetoDayPlan(
      p,
      f,
      c,
      excludedFoods: excludedFoods,
      dayIndex: 0,
    ).map((e) => {
          'label': e.label,
          'name': e.name,
          'description': e.description,
        }).toList();
  }

  static List<PlannedMeal> generateKetoDayPlan(
    double p,
    double f,
    double c, {
    List<String> excludedFoods = const [],
    int dayIndex = 0,
  }) {
    return [
      _buildBreakfast(
        p * 0.25,
        f * 0.25,
        excludedFoods,
        dayIndex: dayIndex,
      ),
      _buildLightSnack(
        p * 0.15,
        f * 0.20,
        excludedFoods,
        dayIndex: dayIndex,
      ),
      _buildKetoMeal(
        'Oběd',
        p * 0.35,
        f * 0.30,
        excludedFoods,
        dayIndex: dayIndex,
      ),
      _buildKetoMeal(
        'Večeře',
        p * 0.25,
        f * 0.25,
        excludedFoods,
        dayIndex: dayIndex + 1,
      ),
    ];
  }

  static PlannedMeal _buildBreakfast(
    double targetP,
    double targetF,
    List<String> excluded, {
    int dayIndex = 0,
  }) {
    final bank = KetoBank.items;
    final eggs = _findExact('Vejce') ?? bank.first;
    final fatAddons = bank
        .where(
          (m) =>
              m.fatsPer100g > 15 &&
              m.name != 'Vejce' &&
              !excluded.contains(m.name),
        )
        .toList();

    final addon = fatAddons.isEmpty
        ? bank.last
        : fatAddons[dayIndex % fatAddons.length];

    final eggGrams = (targetP / (eggs.proteinPer100g / 100))
        .clamp(100, 250)
        .toDouble();
    final addonGrams = ((targetF / (addon.fatsPer100g / 100)) * 0.4)
        .clamp(10, 60)
        .toDouble();

    return PlannedMeal(
      label: 'Snídaně',
      name: 'Vejce + ${addon.name}',
      description:
          '${(eggGrams / 50).round()} ks vejce (${eggGrams.round()} g) + ${addonGrams.round()} g ${addon.name}',
      protein: targetP,
      carbs: 5,
      fats: targetF,
      ingredients: [
        MealIngredient(
          name: 'Vejce',
          amount: (eggGrams / 50).roundToDouble(),
          unit: 'ks',
        ),
        MealIngredient(name: addon.name, amount: addonGrams, unit: 'g'),
        const MealIngredient(name: 'Zelenina', amount: 100, unit: 'g'),
      ],
    );
  }

  static PlannedMeal _buildLightSnack(
    double targetP,
    double targetF,
    List<String> excluded, {
    int dayIndex = 0,
  }) {
    final lightSources = KetoBank.items
        .where(
          (m) =>
              (m.name.contains('Gouda') ||
                  m.name.contains('Mandle') ||
                  m.name.contains('Avokádo') ||
                  m.name.contains('Slanina')) &&
              !excluded.contains(m.name),
        )
        .toList();

    final main = lightSources.isEmpty
        ? KetoBank.items.first
        : lightSources[dayIndex % lightSources.length];

    double grams = targetP / (main.proteinPer100g / 100);
    if (main.name.contains('Mandle')) {
      grams = 30;
    } else {
      grams = grams.clamp(50, 150).toDouble();
    }

    return PlannedMeal(
      label: 'Svačina',
      name: 'Lehká svačina: ${main.name}',
      description: '${grams.round()} g ${main.name} + zelenina',
      protein: targetP,
      carbs: 4,
      fats: targetF,
      ingredients: [
        MealIngredient(name: main.name, amount: grams, unit: 'g'),
        const MealIngredient(name: 'Zelenina', amount: 100, unit: 'g'),
      ],
    );
  }

  static PlannedMeal _buildKetoMeal(
    String type,
    double targetP,
    double targetF,
    List<String> excluded, {
    int dayIndex = 0,
  }) {
    final availableItems = KetoBank.items
        .where(
          (m) =>
              !excluded.contains(m.name) &&
              m.name != 'Vejce' &&
              !m.name.contains('Mandle'),
        )
        .toList();

    final pool = availableItems.isEmpty ? KetoBank.items : availableItems;
    final proteinSources = pool.where((m) => m.proteinPer100g > 15).toList();
    final fatAddons = pool.where((m) => m.fatsPer100g > 15).toList();

    final main = proteinSources.isEmpty
        ? pool.first
        : proteinSources[dayIndex % proteinSources.length];

    final addon = fatAddons.isEmpty
        ? pool.last
        : fatAddons[(dayIndex + 1) % fatAddons.length];

    final mainGrams = (targetP / (main.proteinPer100g / 100))
        .clamp(100, 250)
        .toDouble();
    final addonGrams = ((targetF / (addon.fatsPer100g / 100)) * 0.5)
        .clamp(10, 70)
        .toDouble();

    return PlannedMeal(
      label: type,
      name: '${main.name} + ${addon.name}',
      description:
          '${mainGrams.round()} g ${main.name} + ${addonGrams.round()} g ${addon.name} + zelenina',
      protein: targetP,
      carbs: 8,
      fats: targetF,
      ingredients: [
        MealIngredient(name: main.name, amount: mainGrams, unit: 'g'),
        MealIngredient(name: addon.name, amount: addonGrams, unit: 'g'),
        const MealIngredient(name: 'Zelenina', amount: 150, unit: 'g'),
      ],
    );
  }

  static Map<String, double> getShoppingList(
    List<List<Map<String, String>>> weeklyMenu,
  ) {
    final Map<String, double> totals = {};

    for (final day in weeklyMenu) {
      for (final meal in day) {
        final name = meal['name'];
        if (name == null || name.trim().isEmpty) continue;
        totals[name] = (totals[name] ?? 0) + 1;
      }
    }

    return totals;
  }

  static Meal? _findExact(String name) {
    try {
      return KetoBank.items.firstWhere(
        (m) => m.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }
}