import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../logic/custom_meal_plan_storage_service.dart';
import '../models/custom_meal_plan_models.dart';

class CustomMealPlanTemplatesNotifier
    extends StateNotifier<List<DailyMealTemplate>> {
  CustomMealPlanTemplatesNotifier() : super(const []) {
    load();
  }

  Future<void> load() async {
    final templates = await CustomMealPlanStorageService.loadDailyTemplates();
    state = templates;
  }

  Future<void> upsert(DailyMealTemplate template) async {
    final index = state.indexWhere((e) => e.id == template.id);

    final updatedTemplate = template.copyWith(updatedAt: DateTime.now());

    if (index == -1) {
      state = [updatedTemplate, ...state];
    } else {
      final next = [...state];
      next[index] = updatedTemplate;
      state = next;
    }

    await CustomMealPlanStorageService.saveDailyTemplates(state);
  }

  Future<void> remove(String id) async {
    state = state.where((e) => e.id != id).toList();
    await CustomMealPlanStorageService.saveDailyTemplates(state);
  }
}

final customMealPlanTemplatesProvider =
    StateNotifierProvider<CustomMealPlanTemplatesNotifier, List<DailyMealTemplate>>(
  (ref) => CustomMealPlanTemplatesNotifier(),
);