class Meal {
  final String name;

  final double proteinPer100g;
  final double carbsPer100g;
  final double fatsPer100g;
  final int caloriesPer100g;

  final int defaultGrams;

  const Meal({
    required this.name,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatsPer100g,
    required this.caloriesPer100g,
    this.defaultGrams = 300,
  });

  MealPortion portion(int grams) {
    final factor = grams / 100.0;
    return MealPortion(
      name: name,
      grams: grams,
      calories: (caloriesPer100g * factor).round(),
      protein: proteinPer100g * factor,
      carbs: carbsPer100g * factor,
      fats: fatsPer100g * factor,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'proteinPer100g': proteinPer100g,
        'carbsPer100g': carbsPer100g,
        'fatsPer100g': fatsPer100g,
        'caloriesPer100g': caloriesPer100g,
        'defaultGrams': defaultGrams,
      };

  factory Meal.fromJson(Map<String, dynamic> json) {
    return Meal(
      name: (json['name'] ?? '').toString(),
      proteinPer100g: (json['proteinPer100g'] as num?)?.toDouble() ?? 0.0,
      carbsPer100g: (json['carbsPer100g'] as num?)?.toDouble() ?? 0.0,
      fatsPer100g: (json['fatsPer100g'] as num?)?.toDouble() ?? 0.0,
      caloriesPer100g: (json['caloriesPer100g'] as num?)?.toInt() ?? 0,
      defaultGrams: (json['defaultGrams'] as num?)?.toInt() ?? 300,
    );
  }
}

class MealPortion {
  final String name;
  final int grams;

  final int calories;
  final double protein;
  final double carbs;
  final double fats;

  const MealPortion({
    required this.name,
    required this.grams,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
  });
}