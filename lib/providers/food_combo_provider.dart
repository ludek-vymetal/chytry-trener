import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/food_combo.dart';
import '../data/food_combo_seed.dart';

final foodComboProvider = Provider<List<FoodCombo>>((ref) {
  return FoodComboSeed.items;
});
