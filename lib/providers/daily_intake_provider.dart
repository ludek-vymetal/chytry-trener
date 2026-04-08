import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/daily_intake.dart';
import 'daily_history_provider.dart';

class DailyIntakeNotifier extends StateNotifier<DailyIntake> {
  final Ref ref;

  DailyIntakeNotifier(this.ref) : super(DailyIntake.empty()) {
    ref.listen<Map<String, DailyIntake>>(dailyHistoryProvider, (_, __) {
      refreshForSelectedDate();
    });

    ref.listen<DateTime>(selectedFoodDateProvider, (_, __) {
      refreshForSelectedDate();
    });

    refreshForSelectedDate();
  }

  Future<void> addFood(FoodLogItem item) async {
    final date = ref.read(selectedFoodDateProvider);
    await ref.read(dailyHistoryProvider.notifier).addFood(date, item);
    refreshForSelectedDate();
  }

  Future<void> removeFoodAt(int index) async {
    final date = ref.read(selectedFoodDateProvider);
    await ref.read(dailyHistoryProvider.notifier).removeAt(date, index);
    refreshForSelectedDate();
  }

  Future<void> resetDay() async {
    final date = ref.read(selectedFoodDateProvider);
    await ref.read(dailyHistoryProvider.notifier).resetDay(date);
    refreshForSelectedDate();
  }

  void refreshForSelectedDate() {
    final date = ref.read(selectedFoodDateProvider);
    final history = ref.read(dailyHistoryProvider);
    state = history.intakeFor(date);
  }

  void setSelectedDate(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    ref.read(selectedFoodDateProvider.notifier).state = d;
    refreshForSelectedDate();
  }
}

final dailyIntakeProvider =
    StateNotifierProvider<DailyIntakeNotifier, DailyIntake>(
  (ref) => DailyIntakeNotifier(ref),
);