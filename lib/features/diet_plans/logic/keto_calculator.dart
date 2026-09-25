import '../../../l10n/app_localizations.dart';
import '../../../models/diet_preference.dart';
import '../../../models/user_profile.dart';
import '../models/carb_cycling_plan.dart';
import 'diet_macro_service.dart';
import 'meal_composer.dart';

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

  /// Keto makra ze stejného kalorického cíle jako zbytek aplikace
  /// (viz [DietMacroService.keto]).
  static Map<String, double> calculateMacros(
    UserProfile profile,
    AppLocalizations l10n,
  ) {
    final t = DietMacroService.keto(profile);

    return {
      'protein': t.protein,
      'fats': t.fats,
      'carbs': t.carbs,
    };
  }

  static DietMealPlan generateWeeklyKetoMealPlan({
    required double protein,
    required double fats,
    required double carbs,
    required AppLocalizations l10n,
    List<String> excludedFoods = const [],
    String? noteOverride,
    DietPreference preference = DietPreference.none,
    bool budget = false,
  }) {
    final localizedDays = days(l10n);

    final daysList = List<PlannedDay>.generate(
      localizedDays.length,
      (dayIndex) => _composeKetoDay(
        dayName: localizedDays[dayIndex],
        protein: protein,
        fats: fats,
        carbs: carbs,
        l10n: l10n,
        excludedFoods: excludedFoods,
        dayIndex: dayIndex,
        preference: preference,
        budget: budget,
      ),
    );

    return DietMealPlan(
      planType: 'Keto',
      days: daysList,
      protein: protein,
      carbs: carbs,
      fats: fats,
      note: noteOverride ?? l10n.ketoLowCarbNote,
    );
  }

  static List<List<Map<String, String>>> generateWeeklyKetoMenu(
    double p,
    double f,
    double c, {
    required AppLocalizations l10n,
    List<String> excludedFoods = const [],
  }) {
    final plan = generateWeeklyKetoMealPlan(
      protein: p,
      fats: f,
      carbs: c,
      l10n: l10n,
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
    required AppLocalizations l10n,
    List<String> excludedFoods = const [],
  }) {
    return generateKetoDayPlan(
      p,
      f,
      c,
      l10n: l10n,
      excludedFoods: excludedFoods,
      dayIndex: 0,
    )
        .map(
          (e) => {
            'label': e.label,
            'name': e.name,
            'description': e.description,
          },
        )
        .toList();
  }

  static List<PlannedMeal> generateKetoDayPlan(
    double p,
    double f,
    double c, {
    required AppLocalizations l10n,
    List<String> excludedFoods = const [],
    int dayIndex = 0,
  }) {
    return _composeKetoDay(
      dayName: days(l10n)[dayIndex % 7],
      protein: p,
      fats: f,
      carbs: c,
      l10n: l10n,
      excludedFoods: excludedFoods,
      dayIndex: dayIndex,
    ).meals;
  }

  static PlannedDay _composeKetoDay({
    required String dayName,
    required double protein,
    required double fats,
    required double carbs,
    required AppLocalizations l10n,
    required List<String> excludedFoods,
    required int dayIndex,
    DietPreference preference = DietPreference.none,
    bool budget = false,
  }) {
    return MealComposer.composeDay(
      dayName: dayName,
      slots: MealComposer.ketoSlots(
        breakfast: l10n.breakfast,
        snack: l10n.snack,
        lunch: l10n.lunch,
        dinner: l10n.dinner,
      ),
      protein: protein,
      carbs: carbs,
      fats: fats,
      style: DietStyle.keto,
      excluded: excludedFoods,
      dayIndex: dayIndex,
      preference: preference,
      budget: budget,
    );
  }

  static Map<String, double> getShoppingList(
    List<List<Map<String, String>>> weeklyMenu,
  ) {
    final Map<String, double> totals = {};

    for (final day in weeklyMenu) {
      for (final meal in day) {
        final name = meal['name'];

        if (name == null || name.trim().isEmpty) {
          continue;
        }

        totals[name] = (totals[name] ?? 0) + 1;
      }
    }

    return totals;
  }
}
