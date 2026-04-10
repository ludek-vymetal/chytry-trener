class CarbCyclingPlan {
  final List<double> dailyCarbs;
  final double protein;
  final double fats;
  final double weeklyBank;
  final DietMealPlan? mealPlan;

  CarbCyclingPlan({
    required this.dailyCarbs,
    required this.protein,
    required this.fats,
    required this.weeklyBank,
    this.mealPlan,
  });

  CarbCyclingPlan copyWith({
    List<double>? dailyCarbs,
    double? protein,
    double? fats,
    double? weeklyBank,
    DietMealPlan? mealPlan,
  }) {
    return CarbCyclingPlan(
      dailyCarbs: dailyCarbs ?? this.dailyCarbs,
      protein: protein ?? this.protein,
      fats: fats ?? this.fats,
      weeklyBank: weeklyBank ?? this.weeklyBank,
      mealPlan: mealPlan ?? this.mealPlan,
    );
  }

  Map<String, dynamic> toJson() => {
        'dailyCarbs': dailyCarbs,
        'protein': protein,
        'fats': fats,
        'weeklyBank': weeklyBank,
        'mealPlan': mealPlan?.toJson(),
      };

  factory CarbCyclingPlan.fromJson(Map<String, dynamic> json) {
    return CarbCyclingPlan(
      dailyCarbs: ((json['dailyCarbs'] as List?) ?? const [])
          .map((e) => (e as num).toDouble())
          .toList(),
      protein: (json['protein'] as num?)?.toDouble() ?? 0,
      fats: (json['fats'] as num?)?.toDouble() ?? 0,
      weeklyBank: (json['weeklyBank'] as num?)?.toDouble() ?? 0,
      mealPlan: json['mealPlan'] is Map<String, dynamic>
          ? DietMealPlan.fromJson(
              Map<String, dynamic>.from(json['mealPlan'] as Map),
            )
          : null,
    );
  }
}

class DietMealPlan {
  final String planType;
  final List<PlannedDay> days;
  final double protein;
  final double carbs;
  final double fats;
  final String? note;

  const DietMealPlan({
    required this.planType,
    required this.days,
    required this.protein,
    required this.carbs,
    required this.fats,
    this.note,
  });

  bool get isKeto => planType.toLowerCase() == 'keto';
  bool get isFasting => planType.toLowerCase() == 'fasting';
  bool get isLinear => planType.toLowerCase() == 'linear';

  DietMealPlan copyWith({
    String? planType,
    List<PlannedDay>? days,
    double? protein,
    double? carbs,
    double? fats,
    String? note,
  }) {
    return DietMealPlan(
      planType: planType ?? this.planType,
      days: days ?? this.days,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fats: fats ?? this.fats,
      note: note ?? this.note,
    );
  }

  List<ShoppingListItem> buildShoppingList() {
    final Map<String, ShoppingListItem> aggregated = {};

    for (final day in days) {
      for (final meal in day.meals) {
        for (final ingredient in meal.ingredients) {
          final key =
              '${ingredient.name.trim().toLowerCase()}__${ingredient.unit.trim().toLowerCase()}';

          if (aggregated.containsKey(key)) {
            final existing = aggregated[key]!;
            aggregated[key] = existing.copyWith(
              amount: existing.amount + ingredient.amount,
            );
          } else {
            aggregated[key] = ShoppingListItem(
              name: ingredient.name.trim(),
              amount: ingredient.amount,
              unit: ingredient.unit.trim(),
            );
          }
        }
      }
    }

    final result = aggregated.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return result;
  }

  Map<String, dynamic> toJson() => {
        'planType': planType,
        'days': days.map((e) => e.toJson()).toList(),
        'protein': protein,
        'carbs': carbs,
        'fats': fats,
        'note': note,
      };

  factory DietMealPlan.fromJson(Map<String, dynamic> json) {
    return DietMealPlan(
      planType: (json['planType'] ?? '').toString(),
      days: ((json['days'] as List?) ?? const [])
          .map(
            (e) => PlannedDay.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
      protein: (json['protein'] as num?)?.toDouble() ?? 0,
      carbs: (json['carbs'] as num?)?.toDouble() ?? 0,
      fats: (json['fats'] as num?)?.toDouble() ?? 0,
      note: json['note'] as String?,
    );
  }
}

class PlannedDay {
  final String dayName;
  final List<PlannedMeal> meals;
  final double protein;
  final double carbs;
  final double fats;

  const PlannedDay({
    required this.dayName,
    required this.meals,
    required this.protein,
    required this.carbs,
    required this.fats,
  });

  PlannedDay copyWith({
    String? dayName,
    List<PlannedMeal>? meals,
    double? protein,
    double? carbs,
    double? fats,
  }) {
    return PlannedDay(
      dayName: dayName ?? this.dayName,
      meals: meals ?? this.meals,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fats: fats ?? this.fats,
    );
  }

  Map<String, dynamic> toJson() => {
        'dayName': dayName,
        'meals': meals.map((e) => e.toJson()).toList(),
        'protein': protein,
        'carbs': carbs,
        'fats': fats,
      };

  factory PlannedDay.fromJson(Map<String, dynamic> json) {
    return PlannedDay(
      dayName: (json['dayName'] ?? '').toString(),
      meals: ((json['meals'] as List?) ?? const [])
          .map(
            (e) => PlannedMeal.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
      protein: (json['protein'] as num?)?.toDouble() ?? 0,
      carbs: (json['carbs'] as num?)?.toDouble() ?? 0,
      fats: (json['fats'] as num?)?.toDouble() ?? 0,
    );
  }
}

class PlannedMeal {
  final String label;
  final String name;
  final String description;
  final double? calories;
  final double? protein;
  final double? carbs;
  final double? fats;
  final int? grams;
  final String? time;
  final List<MealIngredient> ingredients;

  const PlannedMeal({
    required this.label,
    required this.name,
    required this.description,
    required this.ingredients,
    this.calories,
    this.protein,
    this.carbs,
    this.fats,
    this.grams,
    this.time,
  });

  PlannedMeal copyWith({
    String? label,
    String? name,
    String? description,
    double? calories,
    double? protein,
    double? carbs,
    double? fats,
    int? grams,
    String? time,
    List<MealIngredient>? ingredients,
  }) {
    return PlannedMeal(
      label: label ?? this.label,
      name: name ?? this.name,
      description: description ?? this.description,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fats: fats ?? this.fats,
      grams: grams ?? this.grams,
      time: time ?? this.time,
      ingredients: ingredients ?? this.ingredients,
    );
  }

  Map<String, dynamic> toMap() => toJson();

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'name': name,
      'description': description,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fats': fats,
      'grams': grams,
      'time': time,
      'ingredients': ingredients.map((e) => e.toJson()).toList(),
    };
  }

  factory PlannedMeal.fromJson(Map<String, dynamic> json) {
    return PlannedMeal(
      label: (json['label'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      calories: (json['calories'] as num?)?.toDouble(),
      protein: (json['protein'] as num?)?.toDouble(),
      carbs: (json['carbs'] as num?)?.toDouble(),
      fats: (json['fats'] as num?)?.toDouble(),
      grams: (json['grams'] as num?)?.toInt(),
      time: json['time'] as String?,
      ingredients: ((json['ingredients'] as List?) ?? const [])
          .map(
            (e) => MealIngredient.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
    );
  }
}

class MealIngredient {
  final String name;
  final double amount;
  final String unit;

  const MealIngredient({
    required this.name,
    required this.amount,
    this.unit = 'g',
  });

  MealIngredient copyWith({
    String? name,
    double? amount,
    String? unit,
  }) {
    return MealIngredient(
      name: name ?? this.name,
      amount: amount ?? this.amount,
      unit: unit ?? this.unit,
    );
  }

  String get formattedAmount {
    if (unit == 'ks') {
      return '${amount.round()} ks';
    }
    if (unit == 'ml') {
      return '${amount.round()} ml';
    }
    if (amount >= 1000 && unit == 'g') {
      return '${(amount / 1000).toStringAsFixed(2)} kg';
    }
    return '${amount.round()} $unit';
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'amount': amount,
        'unit': unit,
      };

  factory MealIngredient.fromJson(Map<String, dynamic> json) {
    return MealIngredient(
      name: (json['name'] ?? '').toString(),
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      unit: (json['unit'] ?? 'g').toString(),
    );
  }
}

class ShoppingListItem {
  final String name;
  final double amount;
  final String unit;

  const ShoppingListItem({
    required this.name,
    required this.amount,
    required this.unit,
  });

  ShoppingListItem copyWith({
    String? name,
    double? amount,
    String? unit,
  }) {
    return ShoppingListItem(
      name: name ?? this.name,
      amount: amount ?? this.amount,
      unit: unit ?? this.unit,
    );
  }

  String get formattedAmount {
    if (unit == 'ks') {
      return '${amount.round()} ks';
    }
    if (unit == 'ml') {
      return '${amount.round()} ml';
    }
    if (amount >= 1000 && unit == 'g') {
      return '${(amount / 1000).toStringAsFixed(2)} kg';
    }
    return '${amount.round()} $unit';
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'amount': amount,
        'unit': unit,
      };

  factory ShoppingListItem.fromJson(Map<String, dynamic> json) {
    return ShoppingListItem(
      name: (json['name'] ?? '').toString(),
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      unit: (json['unit'] ?? 'g').toString(),
    );
  }
}