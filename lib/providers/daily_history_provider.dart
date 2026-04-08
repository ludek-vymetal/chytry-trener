import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/daily_intake.dart';
import '../services/local_storage_service.dart';

String _key(DateTime d) {
  final x = DateTime(d.year, d.month, d.day);
  return '${x.year.toString().padLeft(4, '0')}-'
      '${x.month.toString().padLeft(2, '0')}-'
      '${x.day.toString().padLeft(2, '0')}';
}

final selectedFoodDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

class DailyHistoryNotifier extends StateNotifier<Map<String, DailyIntake>> {
  DailyHistoryNotifier() : super({}) {
    _load();
  }

  Future<void> _load() async {
    try {
      final raw = await LocalStorageService.loadDailyHistory();
      if (raw == null || raw.isEmpty) {
        state = {};
        return;
      }

      final loaded = <String, DailyIntake>{};
      for (final entry in raw.entries) {
        final value = entry.value;
        if (value is Map) {
          loaded[entry.key] =
              DailyIntake.fromJson(Map<String, dynamic>.from(value));
        }
      }

      state = loaded;
    } catch (_) {
      state = {};
    }
  }

  Future<void> _save() async {
    final jsonMap = <String, dynamic>{
      for (final entry in state.entries) entry.key: entry.value.toJson(),
    };

    await LocalStorageService.saveDailyHistory(jsonMap);
  }

  Future<void> reload() async {
    await _load();
  }

  DailyIntake intakeFor(DateTime date) {
    final k = _key(date);
    return state[k] ?? DailyIntake.empty();
  }

  Future<void> addFood(DateTime date, FoodLogItem item) async {
    final k = _key(date);
    final current = state[k] ?? DailyIntake.empty();
    state = {
      ...state,
      k: current.addItem(item),
    };
    await _save();
  }

  Future<void> addItem(DateTime date, FoodLogItem item) async {
    await addFood(date, item);
  }

  Future<void> removeAt(DateTime date, int index) async {
    final k = _key(date);
    final current = state[k] ?? DailyIntake.empty();
    state = {
      ...state,
      k: current.removeAt(index),
    };
    await _save();
  }

  Future<void> resetDay(DateTime date) async {
    final k = _key(date);
    state = {
      ...state,
      k: DailyIntake.empty(),
    };
    await _save();
  }

  Future<void> copyYesterdayTo(DateTime date) async {
    final d = DateTime(date.year, date.month, date.day);
    final y = d.subtract(const Duration(days: 1));

    final todayKey = _key(d);
    final yKey = _key(y);

    final yesterday = state[yKey] ?? DailyIntake.empty();
    state = {
      ...state,
      todayKey: yesterday,
    };
    await _save();
  }
}

final dailyHistoryProvider =
    StateNotifierProvider<DailyHistoryNotifier, Map<String, DailyIntake>>(
  (ref) => DailyHistoryNotifier(),
);

extension DailyHistoryMapX on Map<String, DailyIntake> {
  DailyIntake intakeFor(DateTime date) {
    final k = _key(date);
    return this[k] ?? DailyIntake.empty();
  }
}