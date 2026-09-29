import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/coach/extra_backup_service.dart';
import '../../../services/coach/online_coaching_service.dart';
import '../../../services/local_storage_service.dart';
import '../logic/meal_plan_math.dart';
import '../models/carb_cycling_plan.dart';
import '../models/saved_meal_plan.dart';

class SavedMealPlansNotifier extends StateNotifier<List<SavedMealPlan>> {
  SavedMealPlansNotifier() : super([]) {
    load();
  }

  Future<void> load() async {
    state = await LocalStorageService.loadSavedMealPlans();
  }

  Future<void> _persist(List<SavedMealPlan> next) async {
    state = next;
    await LocalStorageService.saveSavedMealPlans(next);
    // Záloha do cloudu + odeslání jídelníčku online klientovi.
    ExtraBackupService.schedulePush();
    OnlineCoachingService.scheduleSync();
  }

  /// Uloží nový jídelníček (vždy zaokrouhlený) a vrátí ho.
  Future<SavedMealPlan> saveTemplate({
    required String name,
    required DietMealPlan plan,
    required double baseWeight,
    required double baseCalories,
    required int durationDays,
    String? trainerNote,
    String? clientId,
    String? clientName,
    String? sourceId,
  }) async {
    final now = DateTime.now();
    final normalized = MealPlanMath.normalizePlan(plan);
    final note = trainerNote?.trim() ?? '';

    final item = SavedMealPlan(
      id: now.microsecondsSinceEpoch.toString(),
      name: name.trim().isEmpty ? 'Jídelníček' : name.trim(),
      planType: normalized.planType,
      baseWeight: baseWeight,
      baseCalories: baseCalories > 0
          ? baseCalories.roundToDouble()
          : MealPlanMath.planKcal(normalized).roundToDouble(),
      durationDays: durationDays,
      trainerNote: note.isEmpty ? null : note,
      createdAt: now,
      updatedAt: now,
      plan: normalized,
      clientId: (clientId ?? '').isEmpty ? null : clientId,
      clientName: (clientId ?? '').isEmpty ? null : clientName,
      sourceId: sourceId,
    );

    await _persist([item, ...state]);
    return item;
  }

  /// Uloží změny existujícího jídelníčku.
  Future<SavedMealPlan> update(SavedMealPlan item) async {
    final normalized = MealPlanMath.normalizePlan(item.plan);
    final updated = item.copyWith(
      plan: normalized,
      planType: normalized.planType,
      baseCalories: MealPlanMath.planKcal(normalized).roundToDouble(),
      updatedAt: DateTime.now(),
    );
    final exists = state.any((e) => e.id == item.id);
    await _persist(
      exists
          ? [for (final e in state) e.id == item.id ? updated : e]
          : [updated, ...state],
    );
    return updated;
  }

  Future<void> rename(String id, String name) async {
    final n = name.trim();
    if (n.isEmpty) return;
    await _persist([
      for (final e in state)
        e.id == id ? e.copyWith(name: n, updatedAt: DateTime.now()) : e,
    ]);
  }

  /// Kopie jídelníčku jako obecná šablona (bez klienta).
  Future<SavedMealPlan> duplicateAsTemplate(SavedMealPlan item,
      {String? name}) async {
    return saveTemplate(
      name: name ?? item.name,
      plan: item.plan,
      baseWeight: item.baseWeight,
      baseCalories: item.baseCalories,
      durationDays: item.durationDays,
      trainerNote: item.trainerNote,
      sourceId: item.id,
    );
  }

  Future<void> deleteTemplate(String id) async {
    await _persist(state.where((e) => e.id != id).toList());
  }
}

final savedMealPlansProvider =
    StateNotifierProvider<SavedMealPlansNotifier, List<SavedMealPlan>>(
  (ref) => SavedMealPlansNotifier(),
);

/// Jídelníčky jednoho klienta (nejnovější první).
final clientMealPlansProvider =
    Provider.family<List<SavedMealPlan>, String>((ref, clientId) {
  return [
    for (final p in ref.watch(savedMealPlansProvider))
      if (p.clientId == clientId) p,
  ];
});
