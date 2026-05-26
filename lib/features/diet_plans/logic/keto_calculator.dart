import '../../../data/keto_bank.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/meal.dart';
import '../../../models/user_profile.dart';
import '../models/carb_cycling_plan.dart';
import 'diet_target_service.dart';

class KetoCalculator {
  static List<String> days(
    AppLocalizations l10n,
  ) {
    return [
      l10n.monday,
      l10n.tuesday,
      l10n.wednesday,
      l10n.thursday,
      l10n.friday,
      l10n.saturday,
      l10n.sunday,
    ];
  }

  static Map<String, double> calculateMacros(
    UserProfile profile,
    AppLocalizations l10n,
  ) {
    final target =
        DietTargetService.resolve(
      profile,
      l10n,
    );

    final double targetCalories =
        target.targetCalories;

    const double carbs = 30.0;

    final double protein =
        profile.weight * 2.0;

    final double fatCalories =
        targetCalories -
        (protein * 4) -
        (carbs * 4);

    final double fats =
        fatCalories / 9;

    return {
      'protein': protein,
      'fats': fats,
      'carbs': carbs,
    };
  }

  static DietMealPlan
      generateWeeklyKetoMealPlan({
    required double protein,
    required double fats,
    required double carbs,
    required AppLocalizations l10n,
    List<String> excludedFoods =
        const [],
    String? noteOverride,
  }) {
    final localizedDays = days(l10n);

    final daysList =
        List<PlannedDay>.generate(
      localizedDays.length,
      (dayIndex) {
        return PlannedDay(
          dayName:
              localizedDays[dayIndex],
          protein: protein,
          carbs: carbs,
          fats: fats,
          meals:
              generateKetoDayPlan(
            protein,
            fats,
            carbs,
            l10n: l10n,
            excludedFoods:
                excludedFoods,
            dayIndex: dayIndex,
          ),
        );
      },
    );

    return DietMealPlan(
      planType: 'Keto',
      days: daysList,
      protein: protein,
      carbs: carbs,
      fats: fats,
      note:
          noteOverride ??
              l10n.ketoLowCarbNote,
    );
  }

  static List<
          List<Map<String, String>>>
      generateWeeklyKetoMenu(
    double p,
    double f,
    double c, {
    required AppLocalizations l10n,
    List<String> excludedFoods =
        const [],
  }) {
    final plan =
        generateWeeklyKetoMealPlan(
      protein: p,
      fats: f,
      carbs: c,
      l10n: l10n,
      excludedFoods:
          excludedFoods,
    );

    return plan.days
        .map(
          (day) => day.meals
              .map(
                (meal) => {
                  'label': meal.label,
                  'name': meal.name,
                  'description':
                      meal.description,
                },
              )
              .toList(),
        )
        .toList();
  }

  static List<Map<String, String>>
      generateKetoMenu(
    double p,
    double f,
    double c, {
    required AppLocalizations l10n,
    List<String> excludedFoods =
        const [],
  }) {
    return generateKetoDayPlan(
      p,
      f,
      c,
      l10n: l10n,
      excludedFoods:
          excludedFoods,
      dayIndex: 0,
    ).map(
      (e) => {
        'label': e.label,
        'name': e.name,
        'description':
            e.description,
      },
    ).toList();
  }

  static List<PlannedMeal>
      generateKetoDayPlan(
    double p,
    double f,
    double c, {
    required AppLocalizations l10n,
    List<String> excludedFoods =
        const [],
    int dayIndex = 0,
  }) {
    return [
      _buildBreakfast(
        p * 0.25,
        f * 0.25,
        excludedFoods,
        l10n: l10n,
        dayIndex: dayIndex,
      ),
      _buildLightSnack(
        p * 0.15,
        f * 0.20,
        excludedFoods,
        l10n: l10n,
        dayIndex: dayIndex,
      ),
      _buildKetoMeal(
        l10n.lunch,
        p * 0.35,
        f * 0.30,
        excludedFoods,
        l10n: l10n,
        dayIndex: dayIndex,
      ),
      _buildKetoMeal(
        l10n.dinner,
        p * 0.25,
        f * 0.25,
        excludedFoods,
        l10n: l10n,
        dayIndex: dayIndex + 1,
      ),
    ];
  }

  static PlannedMeal
      _buildBreakfast(
    double targetP,
    double targetF,
    List<String> excluded, {
    required AppLocalizations l10n,
    int dayIndex = 0,
  }) {
    final bank = KetoBank.items;

    final eggs =
        _findExact('Vejce') ??
            bank.first;

    final fatAddons = bank
        .where(
          (m) =>
              m.fatsPer100g > 15 &&
              m.name != 'Vejce' &&
              !excluded.contains(
                  m.name),
        )
        .toList();

    final addon =
        fatAddons.isEmpty
            ? bank.last
            : fatAddons[
                dayIndex %
                    fatAddons.length];

    final eggGrams =
        (targetP /
                (eggs.proteinPer100g /
                    100))
            .clamp(100, 250)
            .toDouble();

    final addonGrams =
        ((targetF /
                    (addon.fatsPer100g /
                        100)) *
                0.4)
            .clamp(10, 60)
            .toDouble();

    return PlannedMeal(
      label: l10n.breakfast,
      name:
          '${l10n.eggs} + ${addon.name}',
      description:
          '${(eggGrams / 50).round()} ${l10n.piecesEggs} (${eggGrams.round()} g) + ${addonGrams.round()} g ${addon.name}',
      protein: targetP,
      carbs: 5,
      fats: targetF,
      ingredients: [
        MealIngredient(
          name: l10n.eggs,
          amount:
              (eggGrams / 50)
                  .roundToDouble(),
          unit: l10n.pieces,
        ),
        MealIngredient(
          name: addon.name,
          amount: addonGrams,
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

  static PlannedMeal
      _buildLightSnack(
    double targetP,
    double targetF,
    List<String> excluded, {
    required AppLocalizations l10n,
    int dayIndex = 0,
  }) {
    final lightSources =
        KetoBank.items
            .where(
              (m) =>
                  (m.name.contains(
                            'Gouda',
                          ) ||
                      m.name.contains(
                            'Mandle',
                          ) ||
                      m.name.contains(
                            'Avokádo',
                          ) ||
                      m.name.contains(
                            'Slanina',
                          )) &&
                  !excluded.contains(
                    m.name,
                  ),
            )
            .toList();

    final main =
        lightSources.isEmpty
            ? KetoBank.items.first
            : lightSources[
                dayIndex %
                    lightSources.length];

    double grams =
        targetP /
            (main.proteinPer100g /
                100);

    if (main.name.contains(
      'Mandle',
    )) {
      grams = 30;
    } else {
      grams = grams
          .clamp(50, 150)
          .toDouble();
    }

    return PlannedMeal(
      label: l10n.snack,
      name:
          '${l10n.lightSnack}: ${main.name}',
      description:
          '${grams.round()} g ${main.name} + ${l10n.vegetables}',
      protein: targetP,
      carbs: 4,
      fats: targetF,
      ingredients: [
        MealIngredient(
          name: main.name,
          amount: grams,
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

  static PlannedMeal
      _buildKetoMeal(
    String type,
    double targetP,
    double targetF,
    List<String> excluded, {
    required AppLocalizations l10n,
    int dayIndex = 0,
  }) {
    final availableItems =
        KetoBank.items
            .where(
              (m) =>
                  !excluded.contains(
                    m.name,
                  ) &&
                  m.name !=
                      'Vejce' &&
                  !m.name.contains(
                    'Mandle',
                  ),
            )
            .toList();

    final pool =
        availableItems.isEmpty
            ? KetoBank.items
            : availableItems;

    final proteinSources =
        pool
            .where(
              (m) =>
                  m.proteinPer100g >
                  15,
            )
            .toList();

    final fatAddons = pool
        .where(
          (m) =>
              m.fatsPer100g > 15,
        )
        .toList();

    final main =
        proteinSources.isEmpty
            ? pool.first
            : proteinSources[
                dayIndex %
                    proteinSources.length];

    final addon =
        fatAddons.isEmpty
            ? pool.last
            : fatAddons[
                (dayIndex + 1) %
                    fatAddons.length];

    final mainGrams =
        (targetP /
                (main.proteinPer100g /
                    100))
            .clamp(100, 250)
            .toDouble();

    final addonGrams =
        ((targetF /
                    (addon.fatsPer100g /
                        100)) *
                0.5)
            .clamp(10, 70)
            .toDouble();

    return PlannedMeal(
      label: type,
      name:
          '${main.name} + ${addon.name}',
      description:
          '${mainGrams.round()} g ${main.name} + ${addonGrams.round()} g ${addon.name} + ${l10n.vegetables}',
      protein: targetP,
      carbs: 8,
      fats: targetF,
      ingredients: [
        MealIngredient(
          name: main.name,
          amount: mainGrams,
          unit: 'g',
        ),
        MealIngredient(
          name: addon.name,
          amount: addonGrams,
          unit: 'g',
        ),
        MealIngredient(
          name: l10n.vegetables,
          amount: 150,
          unit: 'g',
        ),
      ],
    );
  }

  static Map<String, double>
      getShoppingList(
    List<List<Map<String, String>>>
        weeklyMenu,
  ) {
    final Map<String, double>
        totals = {};

    for (final day
        in weeklyMenu) {
      for (final meal in day) {
        final name = meal['name'];

        if (name == null ||
            name.trim().isEmpty) {
          continue;
        }

        totals[name] =
            (totals[name] ?? 0) +
                1;
      }
    }

    return totals;
  }

  static Meal? _findExact(
    String name,
  ) {
    try {
      return KetoBank.items
          .firstWhere(
        (m) =>
            m.name
                .toLowerCase() ==
            name.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }
}