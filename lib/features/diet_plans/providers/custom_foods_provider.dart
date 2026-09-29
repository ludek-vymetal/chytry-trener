import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/coach/extra_backup_service.dart';
import '../logic/custom_food_store.dart';
import '../logic/food_catalog.dart';
import '../logic/meal_plan_math.dart';

class CustomFoodsNotifier extends StateNotifier<List<NutritionFood>> {
  CustomFoodsNotifier() : super(const []) {
    _load();
  }

  Future<void> _load() async {
    state = await CustomFoodStore.load();
    MealPlanMath.resetIndex();
  }

  Future<void> _set(List<NutritionFood> next) async {
    state = await CustomFoodStore.save(next);
    MealPlanMath.resetIndex();
    ExtraBackupService.schedulePush();
  }

  Future<void> add(NutritionFood food) => _set([...state, food]);

  Future<void> remove(String id) =>
      _set(state.where((f) => f.id != id).toList());
}

/// Vlastní potraviny trenéra. Sleduje se v app.dart, aby se načetly
/// hned při startu.
final customFoodsProvider =
    StateNotifierProvider<CustomFoodsNotifier, List<NutritionFood>>(
  (ref) => CustomFoodsNotifier(),
);
