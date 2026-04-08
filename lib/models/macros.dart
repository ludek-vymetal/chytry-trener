class Macros {
  final int calories;
  final int protein; // g
  final int carbs; // g
  final int fat; // g

  Macros({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  @override
  String toString() {
    return 'Macros(calories: $calories, protein: $protein g, carbs: $carbs g, fat: $fat g)';
  }
}
