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

  Map<String, dynamic> toMap() {
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
      'ingredients': ingredients
          .map(
            (e) => {
              'name': e.name,
              'amount': e.amount,
              'unit': e.unit,
            },
          )
          .toList(),
    };
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
}