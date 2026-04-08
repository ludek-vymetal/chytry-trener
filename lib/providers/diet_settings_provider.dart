import 'package:flutter_riverpod/flutter_riverpod.dart';

// -------------------------------------------------------------------
// 1. MODEL PRO NUTRISEND (Cílové hodnoty klienta)
// -------------------------------------------------------------------
class UserNutrisend {
  final double targetCalories;
  final double protein;
  final double fats;
  final double carbs;

  UserNutrisend({
    required this.targetCalories,
    required this.protein,
    required this.fats,
    required this.carbs,
  });
}

// -------------------------------------------------------------------
// 2. KETO NUTRISEND PROVIDER (Výpočet maker 70/25/5)
// -------------------------------------------------------------------
// Tento provider vypočítá denní cíle. Zatím tam máme fixních 2000 kcal,
// ale jakmile budeme mít váhu/výšku klienta, stačí změnit totalCalories.
final ketoNutrisendProvider = Provider<UserNutrisend>((ref) {
  // TODO: Zde se později napojí data z profilu (BMR výpočet)
  const double totalCalories = 2000.0; 

  return UserNutrisend(
    targetCalories: totalCalories,
    // Keto poměry: 70% tuky (9kcal/g), 25% bílkoviny (4kcal/g), 5% sacharidy (4kcal/g)
    fats: (totalCalories * 0.70) / 9,    
    protein: (totalCalories * 0.25) / 4, 
    carbs: (totalCalories * 0.05) / 4,   
  );
});

// -------------------------------------------------------------------
// 3. EXCLUDED INGREDIENTS (Tvoje původní logika)
// -------------------------------------------------------------------
final excludedIngredientsProvider = StateNotifierProvider<ExcludedIngredientsNotifier, List<String>>((ref) {
  return ExcludedIngredientsNotifier();
});

class ExcludedIngredientsNotifier extends StateNotifier<List<String>> {
  ExcludedIngredientsNotifier() : super([]);

  void toggleIngredient(String ingredient) {
    if (state.contains(ingredient)) {
      state = state.where((item) => item != ingredient).toList();
    } else {
      state = [...state, ingredient];
    }
  }
}