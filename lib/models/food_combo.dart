// lib/models/food_combo.dart

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

  FoodComboItem copyWith({
    String? mealName,
    int? grams,
  }) {
    return FoodComboItem(
      mealName: mealName ?? this.mealName,
      grams: grams ?? this.grams,
    );
  }

  Map<String, dynamic> toJson() => {
        'mealName': mealName,
        'grams': grams,
      };

  factory FoodComboItem.fromJson(Map<String, dynamic> json) {
    return FoodComboItem(
      mealName: (json['mealName'] ?? '').toString(),
      grams: (json['grams'] as num?)?.toInt() ?? 0,
    );
  }
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

  double totalCaloriesForBank(List<Meal> bank) {
    double sum = 0;
    for (final i in items) {
      final meal = _findMeal(bank, i.mealName);
      if (meal == null) continue;
      sum += (meal.caloriesPer100g * i.grams) / 100.0;
    }
    return sum;
  }

  double totalProteinForBank(List<Meal> bank) {
    double sum = 0;
    for (final i in items) {
      final meal = _findMeal(bank, i.mealName);
      if (meal == null) continue;
      sum += (meal.proteinPer100g * i.grams) / 100.0;
    }
    return sum;
  }

  double totalCarbsForBank(List<Meal> bank) {
    double sum = 0;
    for (final i in items) {
      final meal = _findMeal(bank, i.mealName);
      if (meal == null) continue;
      sum += (meal.carbsPer100g * i.grams) / 100.0;
    }
    return sum;
  }

  double totalFatsForBank(List<Meal> bank) {
    double sum = 0;
    for (final i in items) {
      final meal = _findMeal(bank, i.mealName);
      if (meal == null) continue;
      sum += (meal.fatsPer100g * i.grams) / 100.0;
    }
    return sum;
  }

  double caloriesPer100gForBank(List<Meal> bank) {
    if (defaultGrams == 0) return 0;
    return (totalCaloriesForBank(bank) / defaultGrams) * 100.0;
  }

  double proteinPer100gForBank(List<Meal> bank) {
    if (defaultGrams == 0) return 0;
    return (totalProteinForBank(bank) / defaultGrams) * 100.0;
  }

  double carbsPer100gForBank(List<Meal> bank) {
    if (defaultGrams == 0) return 0;
    return (totalCarbsForBank(bank) / defaultGrams) * 100.0;
  }

  double fatsPer100gForBank(List<Meal> bank) {
    if (defaultGrams == 0) return 0;
    return (totalFatsForBank(bank) / defaultGrams) * 100.0;
  }

  List<String> missingItemsForBank(List<Meal> bank) => items
      .where((i) => _findMeal(bank, i.mealName) == null)
      .map((i) => i.mealName)
      .toList(growable: false);

  FoodCombo copyWith({
    String? title,
    ComboMealTime? time,
    ComboTaste? taste,
    List<FoodComboItem>? items,
  }) {
    return FoodCombo(
      title: title ?? this.title,
      time: time ?? this.time,
      taste: taste ?? this.taste,
      items: items ?? this.items,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'time': time.name,
        'taste': taste.name,
        'items': items.map((e) => e.toJson()).toList(),
      };

  factory FoodCombo.fromJson(Map<String, dynamic> json) {
    return FoodCombo(
      title: (json['title'] ?? '').toString(),
      time: ComboMealTime.values.byName(
        (json['time'] as String?) ?? ComboMealTime.breakfast.name,
      ),
      taste: ComboTaste.values.byName(
        (json['taste'] as String?) ?? ComboTaste.any.name,
      ),
      items: ((json['items'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => FoodComboItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  static Meal? _findMeal(List<Meal> bank, String name) {
    final normalized = name.trim().toLowerCase();

    try {
      return bank.firstWhere(
        (m) => m.name.trim().toLowerCase() == normalized,
      );
    } catch (_) {
      return null;
    }
  }
}