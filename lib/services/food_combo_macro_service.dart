import '../models/food_combo.dart';
import '../models/meal.dart';

class FoodComboMacroService {
  static Meal? findMeal(List<Meal> bank, String mealName) {
    final q = mealName.trim().toLowerCase();
    try {
      return bank.firstWhere((m) => m.name.trim().toLowerCase() == q);
    } catch (_) {
      return null;
    }
  }

  static double totalCalories(FoodCombo combo, List<Meal> bank) {
    double sum = 0;
    for (final item in combo.items) {
      final meal = findMeal(bank, item.mealName);
      if (meal == null) continue;
      sum += (meal.caloriesPer100g * item.grams) / 100.0;
    }
    return sum;
  }

  static double totalProtein(FoodCombo combo, List<Meal> bank) {
    double sum = 0;
    for (final item in combo.items) {
      final meal = findMeal(bank, item.mealName);
      if (meal == null) continue;
      sum += (meal.proteinPer100g * item.grams) / 100.0;
    }
    return sum;
  }

  static double totalCarbs(FoodCombo combo, List<Meal> bank) {
    double sum = 0;
    for (final item in combo.items) {
      final meal = findMeal(bank, item.mealName);
      if (meal == null) continue;
      sum += (meal.carbsPer100g * item.grams) / 100.0;
    }
    return sum;
  }

  static double totalFats(FoodCombo combo, List<Meal> bank) {
    double sum = 0;
    for (final item in combo.items) {
      final meal = findMeal(bank, item.mealName);
      if (meal == null) continue;
      sum += (meal.fatsPer100g * item.grams) / 100.0;
    }
    return sum;
  }

  static List<String> missingItems(FoodCombo combo, List<Meal> bank) {
    return combo.items
        .where((item) => findMeal(bank, item.mealName) == null)
        .map((e) => e.mealName)
        .toList();
  }
}