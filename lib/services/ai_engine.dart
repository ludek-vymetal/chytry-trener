import '../models/meal.dart';

class AiEngine {
  static Map<String, double> calculateRemainingMacros({
    required double targetProtein,
    required double targetCarbs,
    required double targetFats,
    required List<Meal> eatenMeals,
  }) {
    double eatenProtein = 0;
    double eatenCarbs = 0;
    double eatenFats = 0;

    for (final meal in eatenMeals) {
      final factor = meal.defaultGrams / 100.0;

      eatenProtein += meal.proteinPer100g * factor;
      eatenCarbs += meal.carbsPer100g * factor;
      eatenFats += meal.fatsPer100g * factor;
    }

    return {
      'protein': targetProtein - eatenProtein,
      'carbs': targetCarbs - eatenCarbs,
      'fats': targetFats - eatenFats,
    };
  }
}