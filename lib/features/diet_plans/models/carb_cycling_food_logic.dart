import '../../../../l10n/app_localizations.dart';
import 'carb_cycling_plan.dart';

class Food {
  final String name;
  final double p;
  final double s;
  final double t;
  final String unit;

  Food(
    this.name,
    this.p,
    this.s,
    this.t, {
    this.unit = "g",
  });
}

class MealGenerator {
  static List<Map<String, dynamic>> generateMenu(
    double targetS,
    double targetB,
    double targetT, {
    required AppLocalizations l10n,
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
        l10n: l10n,
      ),
      _snack(
        label: l10n.snack,
        carbs: snack1Carbs,
        protein: targetB * 0.15,
        fats: targetT * 0.15,
        excluded: excluded,
        l10n: l10n,
      ),
      _mainMeal(
        label: l10n.lunch,
        carbs: lunchCarbs,
        protein: targetB * 0.30,
        fats: targetT * 0.30,
        excluded: excluded,
        l10n: l10n,
      ),
      _snack(
        label: l10n.snack2,
        carbs: snack2Carbs,
        protein: targetB * 0.10,
        fats: targetT * 0.10,
        excluded: excluded,
        l10n: l10n,
      ),
      _mainMeal(
        label: l10n.dinner,
        carbs: dinnerCarbs,
        protein: targetB * 0.20,
        fats: targetT * 0.25,
        excluded: excluded,
        l10n: l10n,
      ),
    ];

    return meals.map((e) => e.toMap()).toList();
  }

  static Map<String, double> generateShoppingList(
    CarbCyclingPlan plan, {
    required AppLocalizations l10n,
    bool isKeto = false,
    List<String> excluded = const [],
  }) {
    final mealPlan = plan.mealPlan;

    if (mealPlan != null) {
      final shopping = <String, double>{};

      for (final item in mealPlan.buildShoppingList()) {
        shopping['${item.name} (${item.unit})'] =
            item.amount;
      }

      return shopping;
    }

    final Map<String, double> consolidatedList =
        {};

    for (int i = 0; i < 7; i++) {
      final currentS =
          plan.dailyCarbs.length > i
              ? plan.dailyCarbs[i]
              : 0.0;

      final meals = generateMenu(
        isKeto ? 30.0 : currentS,
        plan.protein,
        isKeto
            ? plan.fats + 40
            : plan.fats,
        excluded: excluded,
        l10n: l10n,
      );

      for (final meal in meals) {
        final ingredients =
            (meal['ingredients'] as List?) ??
                const [];

        for (final raw in ingredients) {
          if (raw is Map<String, dynamic>) {
            final name =
                (raw['name'] ?? '')
                    .toString()
                    .trim();

            final amount =
                (raw['amount'] as num?)
                        ?.toDouble() ??
                    0;

            final unit =
                (raw['unit'] ?? 'g')
                    .toString();

            if (name.isEmpty || amount <= 0) {
              continue;
            }

            final key = '$name ($unit)';

            consolidatedList[key] =
                (consolidatedList[key] ?? 0) +
                    amount;
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
    required AppLocalizations l10n,
    List<String> excluded = const [],
  }) {
    final noEggs =
        excluded.contains(l10n.eggs);

    if (!noEggs && carbs < 35) {
      final eggs =
          (protein / 6.5)
              .clamp(2.0, 5.0)
              .toDouble();

      return PlannedMeal(
        label: l10n.breakfast,
        name: l10n.scrambledEggsWithVegetables,
        description:
            '${eggs.round()} ${l10n.eggsPieces}, ${l10n.vegetables} ${l10n.andLightFatSource}',
        protein: protein,
        carbs: carbs,
        fats: fats,
        ingredients: [
          MealIngredient(
            name: l10n.eggs,
            amount: eggs,
            unit: l10n.piecesUnit,
          ),
          MealIngredient(
            name: l10n.vegetables,
            amount: 150,
            unit: 'g',
          ),
          MealIngredient(
            name: l10n.oliveOil,
            amount: 10,
            unit: 'g',
          ),
        ],
      );
    }

    return PlannedMeal(
      label: l10n.breakfast,
      name: l10n.oatmealWithProtein,
      description:
          l10n.complexCarbsForDayStart,
      protein: protein,
      carbs: carbs,
      fats: fats,
      ingredients: [
        MealIngredient(
          name: l10n.oats,
          amount:
              carbs <= 0
                  ? 0
                  : (carbs / 0.68)
                      .clamp(40.0, 100.0)
                      .toDouble(),
          unit: 'g',
        ),
        MealIngredient(
          name: l10n.wheyProtein,
          amount: 30,
          unit: 'g',
        ),
        MealIngredient(
          name: l10n.blueberries,
          amount: 100,
          unit: 'g',
        ),
      ],
    );
  }

  static PlannedMeal _snack({
    required String label,
    required double carbs,
    required double protein,
    required double fats,
    required AppLocalizations l10n,
    List<String> excluded = const [],
  }) {
    final highCarb = carbs >= 18;

    if (highCarb) {
      return PlannedMeal(
        label: label,
        name: l10n.skyrWithFruit,
        description:
            l10n.highProteinSnack,
        protein: protein,
        carbs: carbs,
        fats: fats,
        ingredients: [
          MealIngredient(
            name: l10n.skyr,
            amount: 200,
            unit: 'g',
          ),
          MealIngredient(
            name: l10n.banana,
            amount: 120,
            unit: 'g',
          ),
        ],
      );
    }

    return PlannedMeal(
      label: label,
      name: l10n.hamAndCheese,
      description:
          l10n.lowCarbSnack,
      protein: protein,
      carbs: carbs,
      fats: fats,
      ingredients: [
        MealIngredient(
          name: l10n.ham,
          amount: 100,
          unit: 'g',
        ),
        MealIngredient(
          name: l10n.gouda,
          amount: 40,
          unit: 'g',
        ),
        MealIngredient(
          name: l10n.vegetables,
          amount: 100,
          unit: 'g',
        ),
      ],
    );
  }

  static PlannedMeal _mainMeal({
    required String label,
    required double carbs,
    required double protein,
    required double fats,
    required AppLocalizations l10n,
    List<String> excluded = const [],
  }) {
    final useTurkey =
        excluded.contains(l10n.beef);

    final proteinName =
        useTurkey
            ? l10n.turkeyBreast
            : l10n.chickenBreast;

    final proteinGrams =
        (protein / 0.30)
            .clamp(120.0, 240.0)
            .toDouble();

    final carbGrams =
        carbs <= 10
            ? 0.0
            : (carbs / 0.78)
                .clamp(50.0, 180.0)
                .toDouble();

    final ingredients = <MealIngredient>[
      MealIngredient(
        name: proteinName,
        amount: proteinGrams,
        unit: 'g',
      ),
      MealIngredient(
        name: l10n.vegetables,
        amount: 150,
        unit: 'g',
      ),
      MealIngredient(
        name: l10n.oliveOil,
        amount: 10,
        unit: 'g',
      ),
    ];

    var mealName = proteinName;

    var desc =
        '${proteinGrams.round()} g $proteinName + ${l10n.vegetables.toLowerCase()}';

    if (carbGrams > 0) {
      ingredients.insert(
        1,
        MealIngredient(
          name: l10n.whiteRiceDry,
          amount: carbGrams,
          unit: 'g',
        ),
      );

      mealName =
          '$proteinName + ${l10n.rice}';

      desc =
          '${proteinGrams.round()} g $proteinName + ${carbGrams.round()} g ${l10n.rice.toLowerCase()} + ${l10n.vegetables.toLowerCase()}';
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