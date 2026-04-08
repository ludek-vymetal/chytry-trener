import 'package:flutter_riverpod/flutter_riverpod.dart';

// Definice provideru pro jídelníček
final dietPlanProvider = StateProvider<Map<String, double>>((ref) {
  // Výchozí hodnoty (např. bílkoviny, sacharidy, tuky)
  return {
    "protein": 150.0,
    "carbs": 200.0,
    "fats": 70.0,
  };
});