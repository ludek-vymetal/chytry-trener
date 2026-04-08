import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/meal.dart';
import '../services/local_storage_service.dart';
import '../data/food_bank_seed.dart';

class FoodBankNotifier extends StateNotifier<List<Meal>> {
  FoodBankNotifier() : super(FoodBankSeed.items) {
    load(); // načti uložené hned po startu
  }

  Future<void> load() async {
    final raw = await LocalStorageService.loadFoodBank();
    if (raw == null) return;

    final loaded = raw.map((e) => Meal.fromJson(e)).toList();

    // ✅ pokud máme něco uloženého, přepíšeme seed
    if (loaded.isNotEmpty) {
      state = loaded;
    } else {
      // ✅ pokud nic uloženého není, uložíme seed do storage
      await _persist();
    }
  }

  Future<void> _persist() async {
    await LocalStorageService.saveFoodBank(
      state.map((m) => m.toJson()).toList(),
    );
  }

  /// Najde položku v bance podle názvu (case-insensitive)
  Meal? findByName(String name) {
    final q = name.trim().toLowerCase();
    if (q.isEmpty) return null;

    try {
      return state.firstWhere((m) => m.name.trim().toLowerCase() == q);
    } catch (_) {
      return null;
    }
  }

  /// Návrhy podle části textu
  List<Meal> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];

    return state
        .where((m) => m.name.toLowerCase().contains(q))
        .take(8)
        .toList();
  }

  /// Uloží/aktualizuje položku v bance + persist
  void upsert(Meal meal) {
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

    _persist();
  }
}

final foodBankProvider =
    StateNotifierProvider<FoodBankNotifier, List<Meal>>(
  (ref) => FoodBankNotifier(),
);
