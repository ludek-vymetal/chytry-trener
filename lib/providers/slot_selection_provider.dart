import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Uloží výběr cviku pro konkrétní slot.
/// Klíč = unikátní string (třeba "Den 1|0")
/// Hodnota = exerciseId (např. "leg_press")
class SlotSelectionNotifier extends StateNotifier<Map<String, String>> {
  SlotSelectionNotifier() : super({});

  void setSelection(String key, String exerciseId) {
    state = {...state, key: exerciseId};
  }

  String? getSelection(String key) => state[key];

  void clearSelection(String key) {
    final copy = {...state};
    copy.remove(key);
    state = copy;
  }

  void clearAll() {
    state = {};
  }
}

final slotSelectionProvider =
    StateNotifierProvider<SlotSelectionNotifier, Map<String, String>>(
  (ref) => SlotSelectionNotifier(),
);
