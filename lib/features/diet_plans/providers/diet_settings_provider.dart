import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider, který drží seznam surovin, které uživatel nechce
final excludedIngredientsProvider = StateProvider<List<String>>((ref) {
  return []; // Začínáme s prázdným seznamem
});