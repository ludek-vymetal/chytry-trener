import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/local_storage_service.dart';
import '../models/carb_cycling_plan.dart';
import '../models/saved_meal_plan.dart';

class SavedMealPlansNotifier extends StateNotifier<List<SavedMealPlan>> {
  SavedMealPlansNotifier() : super([]) {
    load();
  }

  Future<void> load() async {
    state = await LocalStorageService.loadSavedMealPlans();
  }

  Future<void> saveTemplate({
    required String name,
    required DietMealPlan plan,
    required double baseWeight,
    required double baseCalories,
    required int durationDays,
    String? trainerNote,
  }) async {
    final now = DateTime.now();

    final item = SavedMealPlan(
      id: now.microsecondsSinceEpoch.toString(),
      name: name.trim(),
      planType: plan.planType,
      baseWeight: baseWeight,
      baseCalories: baseCalories,
      durationDays: durationDays,
      trainerNote: trainerNote?.trim().isEmpty ?? true ? null : trainerNote?.trim(),
      createdAt: now,
      updatedAt: now,
      plan: plan,
    );

    final updated = [item, ...state];
    state = updated;
    await LocalStorageService.saveSavedMealPlans(updated);
  }

  Future<void> deleteTemplate(String id) async {
    final updated = state.where((e) => e.id != id).toList();
    state = updated;
    await LocalStorageService.saveSavedMealPlans(updated);
  }
}

final savedMealPlansProvider =
    StateNotifierProvider<SavedMealPlansNotifier, List<SavedMealPlan>>(
  (ref) => SavedMealPlansNotifier(),
);