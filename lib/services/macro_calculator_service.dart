import '../models/goal.dart';
import '../models/user_profile.dart';

class MacroTarget {
  final int calories;
  final int protein;
  final int carbs;
  final int fat;

  MacroTarget({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });
}

class MacroService {
  /// 🔥 HLAVNÍ VÝPOČET MAKER
  static MacroTarget calculateDailyMacros(
    UserProfile profile,
    double tdee,
  ) {
    if (profile.goal == null) {
      throw Exception('Cíl není nastaven');
    }

    final goal = profile.goal!.type;
    final weight = profile.weight;

    late int calories;
    late double proteinPerKg;
    late double fatPerKg;

    switch (goal) {
      case GoalType.weightLoss:
        calories = (tdee - 500).round();
        proteinPerKg = 2.0;
        fatPerKg = 0.8;
        break;

      case GoalType.strength:
        calories = (tdee + 300).round();
        proteinPerKg = 2.2;
        fatPerKg = 1.0;
        break;

      case GoalType.physique:
        calories = tdee.round();
        proteinPerKg = 2.3;
        fatPerKg = 0.9;
        break;

      case GoalType.endurance:
        calories = tdee.round();
        proteinPerKg = 1.8;
        fatPerKg = 0.8;
        break;

      case GoalType.weightGainSupport:
        calories = (tdee + 250).round();
        proteinPerKg = 1.8;
        fatPerKg = 1.0;
        break;
    }

    final protein = (weight * proteinPerKg).round();
    final fat = (weight * fatPerKg).round();

    final proteinCalories = protein * 4;
    final fatCalories = fat * 9;

    int carbsCalories = calories - proteinCalories - fatCalories;
    if (carbsCalories < 0) carbsCalories = 0;

    final carbs = (carbsCalories / 4).round();

    return MacroTarget(
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
    );
  }
}