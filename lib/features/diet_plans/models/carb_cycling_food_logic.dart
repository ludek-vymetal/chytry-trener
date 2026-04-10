import 'carb_cycling_plan.dart';

class Food {
  final String name;
  final double p;
  final double s;
  final double t;
  final String unit;

  Food(this.name, this.p, this.s, this.t, {this.unit = "g"});
}

class MealGenerator {
  static List<Map<String, dynamic>> generateMenu(
    double targetS,
    double targetB,
    double targetT, {
    List<String> excluded = const [],
  }) {
    final breakfastCarbs = targetS * 0.25;
    final snack1Carbs = targetS * 0.15;
    final lunchCarbs = targetS * 0.30;
    final snack2Carbs = targetS * 0.10;
    final dinnerCarbs = targetS * 0.20;

    final meals = <PlannedMeal>[
      _breakfast(
        carbs: breakfastCarbs,
        protein: targetB * 0.25,
        fats: targetT * 0.20,
        excluded: excluded,
      ),
      _snack(
        label: 'Svačina',
        carbs: snack1Carbs,
        protein: targetB * 0.15,
        fats: targetT * 0.15,
        excluded: excluded,
      ),
      _mainMeal(
        label: 'Oběd',
        carbs: lunchCarbs,
        protein: targetB * 0.30,
        fats: targetT * 0.30,
        excluded: excluded,
      ),
      _snack(
        label: 'Svačina 2',
        carbs: snack2Carbs,
        protein: targetB * 0.10,
        fats: targetT * 0.10,
        excluded: excluded,
      ),
      _mainMeal(
        label: 'Večeře',
        carbs: dinnerCarbs,
        protein: targetB * 0.20,
        fats: targetT * 0.25,
        excluded: excluded,
      ),
    ];

    return meals.map((e) => e.toMap()).toList();
  }

  static Map<String, double> generateShoppingList(
    CarbCyclingPlan plan, {
    bool isKeto = false,
    List<String> excluded = const [],
  }) {
    final mealPlan = plan.mealPlan;
    if (mealPlan != null) {
      final shopping = <String, double>{};
      for (final item in mealPlan.buildShoppingList()) {
        shopping['${item.name} (${item.unit})'] = item.amount;
      }
      return shopping;
    }

    final Map<String, double> consolidatedList = {};

    for (int i = 0; i < 7; i++) {
      final currentS = plan.dailyCarbs.length > i ? plan.dailyCarbs[i] : 0.0;
      final meals = generateMenu(
        isKeto ? 30.0 : currentS,
        plan.protein,
        isKeto ? plan.fats + 40 : plan.fats,
        excluded: excluded,
      );

      for (final meal in meals) {
        final ingredients = (meal['ingredients'] as List?) ?? const [];
        for (final raw in ingredients) {
          if (raw is Map<String, dynamic>) {
            final name = (raw['name'] ?? '').toString().trim();
            final amount = (raw['amount'] as num?)?.toDouble() ?? 0;
            final unit = (raw['unit'] ?? 'g').toString();
            if (name.isEmpty || amount <= 0) continue;
            final key = '$name ($unit)';
            consolidatedList[key] = (consolidatedList[key] ?? 0) + amount;
          }
        }
      }
    }

    return consolidatedList;
  }

  static PlannedMeal _breakfast({
    required double carbs,
    required double protein,
    required double fats,
    List<String> excluded = const [],
  }) {
    final noEggs = excluded.contains('Vejce');

    if (!noEggs && carbs < 35) {
      final eggs = (protein / 6.5).clamp(2.0, 5.0).toDouble();
      return PlannedMeal(
        label: 'Snídaně',
        name: 'Míchaná vejce se zeleninou',
        description:
            '${eggs.round()} ks vejce, zelenina a lehký tukový doplněk.',
        protein: protein,
        carbs: carbs,
        fats: fats,
        ingredients: [
          MealIngredient(name: 'Vejce', amount: eggs, unit: 'ks'),
          const MealIngredient(name: 'Zelenina', amount: 150, unit: 'g'),
          const MealIngredient(name: 'Olivový olej', amount: 10, unit: 'g'),
        ],
      );
    }

    return PlannedMeal(
      label: 'Snídaně',
      name: 'Ovesná kaše s proteinem',
      description: 'Komplexní sacharidy na start dne.',
      protein: protein,
      carbs: carbs,
      fats: fats,
      ingredients: [
        MealIngredient(
          name: 'Ovesné vločky',
          amount: carbs <= 0
              ? 0
              : (carbs / 0.68).clamp(40.0, 100.0).toDouble(),
          unit: 'g',
        ),
        const MealIngredient(name: 'Protein whey', amount: 30, unit: 'g'),
        const MealIngredient(name: 'Borůvky', amount: 100, unit: 'g'),
      ],
    );
  }

  static PlannedMeal _snack({
    required String label,
    required double carbs,
    required double protein,
    required double fats,
    List<String> excluded = const [],
  }) {
    final highCarb = carbs >= 18;

    if (highCarb) {
      return PlannedMeal(
        label: label,
        name: 'Skyr s ovocem',
        description: 'Lehká svačina s vysokým podílem bílkovin.',
        protein: protein,
        carbs: carbs,
        fats: fats,
        ingredients: const [
          MealIngredient(name: 'Skyr', amount: 200, unit: 'g'),
          MealIngredient(name: 'Banán', amount: 120, unit: 'g'),
        ],
      );
    }

    return PlannedMeal(
      label: label,
      name: 'Šunka a sýr',
      description: 'Nízkosacharidová svačina.',
      protein: protein,
      carbs: carbs,
      fats: fats,
      ingredients: const [
        MealIngredient(name: 'Šunka', amount: 100, unit: 'g'),
        MealIngredient(name: 'Gouda', amount: 40, unit: 'g'),
        MealIngredient(name: 'Zelenina', amount: 100, unit: 'g'),
      ],
    );
  }

  static PlannedMeal _mainMeal({
    required String label,
    required double carbs,
    required double protein,
    required double fats,
    List<String> excluded = const [],
  }) {
    final useTurkey = excluded.contains('Hovězí maso');
    final proteinName = useTurkey ? 'Krůtí prsa' : 'Kuřecí prsa';
    final proteinGrams = (protein / 0.30).clamp(120.0, 240.0).toDouble();
    final carbGrams =
        carbs <= 10 ? 0.0 : (carbs / 0.78).clamp(50.0, 180.0).toDouble();

    final ingredients = <MealIngredient>[
      MealIngredient(name: proteinName, amount: proteinGrams, unit: 'g'),
      const MealIngredient(name: 'Zelenina', amount: 150, unit: 'g'),
      const MealIngredient(name: 'Olivový olej', amount: 10, unit: 'g'),
    ];

    var mealName = proteinName;
    var desc = '${proteinGrams.round()} g $proteinName + zelenina';

    if (carbGrams > 0) {
      ingredients.insert(
        1,
        MealIngredient(name: 'Rýže bílá (suchá)', amount: carbGrams, unit: 'g'),
      );
      mealName = '$proteinName + Rýže';
      desc =
          '${proteinGrams.round()} g $proteinName + ${carbGrams.round()} g rýže + zelenina';
    }

    return PlannedMeal(
      label: label,
      name: mealName,
      description: desc,
      protein: protein,
      carbs: carbs,
      fats: fats,
      ingredients: ingredients,
    );
  }
}