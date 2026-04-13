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

  // -------------------------------------------------
  // Makra na 100 g
  // -------------------------------------------------

  double get caloriesPer100g =>
      defaultGrams == 0 ? 0 : (_totalCalories / defaultGrams) * 100.0;

  double get proteinPer100g =>
      defaultGrams == 0 ? 0 : (_totalProtein / defaultGrams) * 100.0;

  double get carbsPer100g =>
      defaultGrams == 0 ? 0 : (_totalCarbs / defaultGrams) * 100.0;

  double get fatsPer100g =>
      defaultGrams == 0 ? 0 : (_totalFats / defaultGrams) * 100.0;

  // -------------------------------------------------
  // Makra na celou porci
  // -------------------------------------------------

  double get totalCalories => _totalCalories;
  double get totalProtein => _totalProtein;
  double get totalCarbs => _totalCarbs;
  double get totalFats => _totalFats;

  // -------------------------------------------------
  // Doporučený poměr dne podle typu jídla
  // To je přesně ta logika snídaně 15–20 %, svačina 10 %, oběd 30 %...
  // -------------------------------------------------

  double get suggestedDailyRatio {
    switch (time) {
      case ComboMealTime.breakfast:
        return 0.20; // 20 %
      case ComboMealTime.snack:
        return 0.10; // 10 %
      case ComboMealTime.lunch:
        return 0.30; // 30 %
      case ComboMealTime.dinner:
        return 0.30; // 30 %
      case ComboMealTime.vegan:
        return 0.30; // chová se většinou jako hlavní jídlo
    }
  }

  int suggestedCaloriesForDay(double dailyCalories) {
    return (dailyCalories * suggestedDailyRatio).round();
  }

  bool fitsDailyCalories(
    double dailyCalories, {
    double tolerance = 0.25,
  }) {
    if (dailyCalories <= 0) return false;

    final target = dailyCalories * suggestedDailyRatio;
    final min = target * (1 - tolerance);
    final max = target * (1 + tolerance);

    return totalCalories >= min && totalCalories <= max;
  }

  // -------------------------------------------------
  // Přepočet porce
  // -------------------------------------------------

  FoodCombo scaled(double multiplier) {
    if (multiplier <= 0) return this;

    return FoodCombo(
      title: title,
      time: time,
      taste: taste,
      items: items
          .map(
            (item) => item.copyWith(
              grams: (item.grams * multiplier).round(),
            ),
          )
          .toList(),
    );
  }

  // -------------------------------------------------
  // Chybějící položky v bance
  // -------------------------------------------------

  List<String> get missingItems => items
      .where((i) => i.meal == null)
      .map((i) => i.mealName)
      .toList(growable: false);

  // -------------------------------------------------
  // JSON
  // -------------------------------------------------

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
        (json['time'] ?? ComboMealTime.breakfast.name).toString(),
      ),
      taste: ComboTaste.values.byName(
        (json['taste'] ?? ComboTaste.any.name).toString(),
      ),
      items: ((json['items'] as List?) ?? const [])
          .map((e) => FoodComboItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}