import 'package:flutter_riverpod/flutter_riverpod.dart';

class ExcludedIngredientsNotifier extends StateNotifier<List<String>> {
  ExcludedIngredientsNotifier() : super([]);

  void toggleIngredient(String ingredient) {
    final normalized = ingredient.trim();
    if (state.contains(normalized)) {
      state = state.where((e) => e != normalized).toList();
    } else {
      state = [...state, normalized];
    }
  }

  void clear() {
    state = [];
  }

  void setAll(List<String> ingredients) {
    state = [...ingredients];
  }
}

final excludedIngredientsProvider =
    StateNotifierProvider<ExcludedIngredientsNotifier, List<String>>(
  (ref) => ExcludedIngredientsNotifier(),
);