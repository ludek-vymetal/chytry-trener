import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/meal.dart';
import '../services/local_storage_service.dart';
import '../data/food_bank_seed.dart';

class FoodBankNotifier extends StateNotifier<List<Meal>> {
  FoodBankNotifier() : super(FoodBankSeed.items) {
    load();
  }

  Future<void> load() async {
    final raw = await LocalStorageService.loadFoodBank();
    if (raw == null) return;

    final loaded = raw.map((e) => Meal.fromJson(e)).toList();

    if (loaded.isNotEmpty) {
      state = loaded;
    } else {
      await _persist();
    }
  }

  Future<void> _persist() async {
    await LocalStorageService.saveFoodBank(
      state.map((m) => m.toJson()).toList(),
    );
  }

  Meal? findByName(String name) {
    final q = name.trim().toLowerCase();
    if (q.isEmpty) return null;

    try {
      return state.firstWhere((m) => m.name.trim().toLowerCase() == q);
    } catch (_) {
      return null;
    }
  }

  List<Meal> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];

    return state
        .where((m) => m.name.toLowerCase().contains(q))
        .take(8)
        .toList();
  }

  Future<void> upsert(Meal meal) async {
    final q = meal.name.trim().toLowerCase();
    final existingIndex =
        state.indexWhere((m) => m.name.trim().toLowerCase() == q);

    if (existingIndex >= 0) {
      final updated = [...state];
      updated[existingIndex] = meal;
      state = updated;
    } else {
      state = [meal, ...state];
    }

    await _persist();
  }
}

final foodBankProvider =
    StateNotifierProvider<FoodBankNotifier, List<Meal>>(
  (ref) => FoodBankNotifier(),
);