// lib/models/food_combo.dart

import '../data/food_bank_seed.dart';
import 'meal.dart';

enum ComboMealTime { breakfast, snack, lunch, dinner, vegan }

enum ComboTaste { savory, sweet, any }

class FoodComboItem {
  final String mealName;
  final int grams;

  const FoodComboItem({
    required this.mealName,
    required this.grams,
  });

  Meal? get meal => FoodBankSeed.byName[mealName];
}

class FoodCombo {
  final String title;
  final ComboMealTime time;
  final ComboTaste taste;
  final List<FoodComboItem> items;

  const FoodCombo({
    required this.title,
    required this.time,
    required this.taste,
    required this.items,
  });

  String get name => title;

  int get defaultGrams => items.fold<int>(0, (sum, i) => sum + i.grams);

  double get _totalCalories {
    double sum = 0;
    for (final i in items) {
      final m = i.meal;
      if (m == null) continue;
      sum += (m.caloriesPer100g * i.grams) / 100.0;
    }
    return sum;
  }

  double get _totalProtein {
    double sum = 0;
    for (final i in items) {
      final m = i.meal;
      if (m == null) continue;
      sum += (m.proteinPer100g * i.grams) / 100.0;
    }
    return sum;
  }

  double get _totalCarbs {
    double sum = 0;
    for (final i in items) {
      final m = i.meal;
      if (m == null) continue;
      sum += (m.carbsPer100g * i.grams) / 100.0;
    }
    return sum;
  }

  double get _totalFats {
    double sum = 0;
    for (final i in items) {
      final m = i.meal;
      if (m == null) continue;
      sum += (m.fatsPer100g * i.grams) / 100.0;
    }
    return sum;
  }

  double get caloriesPer100g =>
      defaultGrams == 0 ? 0 : (_totalCalories / defaultGrams) * 100.0;

  double get proteinPer100g =>
      defaultGrams == 0 ? 0 : (_totalProtein / defaultGrams) * 100.0;

  double get carbsPer100g =>
      defaultGrams == 0 ? 0 : (_totalCarbs / defaultGrams) * 100.0;

  double get fatsPer100g =>
      defaultGrams == 0 ? 0 : (_totalFats / defaultGrams) * 100.0;

  List<String> get missingItems => items
      .where((i) => i.meal == null)
      .map((i) => i.mealName)
      .toList(growable: false);
}