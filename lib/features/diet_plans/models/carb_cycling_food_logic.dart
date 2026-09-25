import '../../../../l10n/app_localizations.dart';
import '../../../models/diet_preference.dart';
import '../logic/meal_composer.dart';
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
  /// Denní menu (5 jídel) se skutečnými gramážemi – viz [MealComposer].
  static List<Map<String, dynamic>> generateMenu(
    double targetS,
    double targetB,
    double targetT, {
    required AppLocalizations l10n,
    List<String> excluded = const [],
    int dayIndex = 0,
    DietPreference preference = DietPreference.none,
    bool budget = false,
  }) {
    final day = MealComposer.composeDay(
      dayName: '',
      slots: MealComposer.standardSlots(
        breakfast: l10n.breakfast,
        snack: l10n.snack,
        lunch: l10n.lunch,
        snack2: l10n.snack2,
        dinner: l10n.dinner,
      ),
      protein: targetB,
      carbs: targetS,
      fats: targetT,
      excluded: excluded,
      dayIndex: dayIndex,
      preference: preference,
      budget: budget,
    );

    return day.meals.map((e) => e.toMap()).toList();
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
        plan.fats,
        excluded: excluded,
        l10n: l10n,
        dayIndex: i,
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
}
