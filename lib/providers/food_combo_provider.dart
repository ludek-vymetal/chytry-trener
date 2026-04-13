import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/food_combo_seed.dart';
import '../models/food_combo.dart';
import '../services/local_storage_service.dart';

class FoodComboNotifier extends StateNotifier<List<FoodCombo>> {
  FoodComboNotifier() : super(List<FoodCombo>.from(FoodComboSeed.items)) {
    load();
  }

  final List<FoodCombo> _seedItems = List<FoodCombo>.from(FoodComboSeed.items);
  List<FoodCombo> _customItems = [];

  Future<void> load() async {
    final raw = await LocalStorageService.loadCustomFoodCombos();
    _customItems = raw.map((e) => FoodCombo.fromJson(e)).toList();
    state = _buildMergedState();
  }

  Future<void> _persistCustomOnly() async {
    await LocalStorageService.saveCustomFoodCombos(
      _customItems.map((e) => e.toJson()).toList(),
    );
  }

  List<FoodCombo> _buildMergedState() {
    return _dedupeByTitle([
      ..._seedItems,
      ..._customItems,
    ]);
  }

  Future<void> upsertCustom(FoodCombo combo) async {
    final normalized = combo.title.trim().toLowerCase();

    final idx = _customItems.indexWhere(
      (e) => e.title.trim().toLowerCase() == normalized,
    );

    if (idx >= 0) {
      final updated = [..._customItems];
      updated[idx] = combo;
      _customItems = updated;
    } else {
      _customItems = [..._customItems, combo];
    }

    state = _buildMergedState();
    await _persistCustomOnly();
  }

  Future<void> removeCustomByTitle(String title) async {
    final normalized = title.trim().toLowerCase();

    _customItems = _customItems
        .where((e) => e.title.trim().toLowerCase() != normalized)
        .toList();

    state = _buildMergedState();
    await _persistCustomOnly();
  }

  List<FoodCombo> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return state;

    return state.where((c) => c.title.toLowerCase().contains(q)).toList();
  }

  static List<FoodCombo> _dedupeByTitle(List<FoodCombo> source) {
    final map = <String, FoodCombo>{};

    for (final item in source) {
      map[item.title.trim().toLowerCase()] = item;
    }

    return map.values.toList()
      ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
  }
}

final foodComboProvider =
    StateNotifierProvider<FoodComboNotifier, List<FoodCombo>>(
  (ref) => FoodComboNotifier(),
);