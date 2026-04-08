class FoodLogItem {
  final String name;
  final int grams;

  final int calories;
  final int protein;
  final int carbs;
  final int fat;

  final DateTime createdAt;

  FoodLogItem({
    required this.name,
    required this.grams,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'name': name,
        'grams': grams,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'createdAt': createdAt.toIso8601String(),
      };

  factory FoodLogItem.fromJson(Map<String, dynamic> json) {
    return FoodLogItem(
      name: (json['name'] ?? '').toString(),
      grams: (json['grams'] as num?)?.toInt() ?? 0,
      calories: (json['calories'] as num?)?.toInt() ?? 0,
      protein: (json['protein'] as num?)?.toInt() ?? 0,
      carbs: (json['carbs'] as num?)?.toInt() ?? 0,
      fat: (json['fat'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.now(),
    );
  }
}

class DailyIntake {
  final int calories;
  final int protein;
  final int carbs;
  final int fat;

  final List<FoodLogItem> items;

  const DailyIntake({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.items,
  });

  factory DailyIntake.empty() {
    return const DailyIntake(
      calories: 0,
      protein: 0,
      carbs: 0,
      fat: 0,
      items: [],
    );
  }

  DailyIntake addItem(FoodLogItem item) {
    return DailyIntake(
      calories: calories + item.calories,
      protein: protein + item.protein,
      carbs: carbs + item.carbs,
      fat: fat + item.fat,
      items: [...items, item],
    );
  }

  DailyIntake removeAt(int index) {
    if (index < 0 || index >= items.length) return this;

    final removed = items[index];
    final updatedItems = [...items]..removeAt(index);

    return DailyIntake(
      calories: calories - removed.calories,
      protein: protein - removed.protein,
      carbs: carbs - removed.carbs,
      fat: fat - removed.fat,
      items: updatedItems,
    );
  }

  Map<String, dynamic> toJson() => {
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'items': items.map((e) => e.toJson()).toList(),
      };

  factory DailyIntake.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items = (rawItems is List)
        ? rawItems
            .whereType<Map>()
            .map((e) => FoodLogItem.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <FoodLogItem>[];

    return DailyIntake(
      calories: (json['calories'] as num?)?.toInt() ?? 0,
      protein: (json['protein'] as num?)?.toInt() ?? 0,
      carbs: (json['carbs'] as num?)?.toInt() ?? 0,
      fat: (json['fat'] as num?)?.toInt() ?? 0,
      items: items,
    );
  }
}