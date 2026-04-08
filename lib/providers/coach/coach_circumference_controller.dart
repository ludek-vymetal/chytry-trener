import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/coach/coach_circumference_entry.dart';
import '../../services/coach/coach_storage_service.dart';

final coachCircumferenceControllerProvider = AsyncNotifierProvider<
    CoachCircumferenceController, List<CoachCircumferenceEntry>>(
  CoachCircumferenceController.new,
);

final coachCircumferencesForClientProvider =
    Provider.family<AsyncValue<List<CoachCircumferenceEntry>>, String>(
  (ref, clientId) {
    final asyncAll = ref.watch(coachCircumferenceControllerProvider);

    return asyncAll.whenData((items) {
      final filtered = items.where((e) => e.clientId == clientId).toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      return filtered;
    });
  },
);

class CoachCircumferenceController
    extends AsyncNotifier<List<CoachCircumferenceEntry>> {
  @override
  Future<List<CoachCircumferenceEntry>> build() async {
    final items = await _loadEntries();

    debugPrint('CONTROLLER BUILD CIRC -> ${items.length}');
    return items;
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    final items = await _loadEntries();
    state = AsyncData(items);
  }

  Future<void> addEntry(CoachCircumferenceEntry entry) async {
    debugPrint(
      'CONTROLLER ADD CIRC START -> id=${entry.entryId} clientId=${entry.clientId} date=${entry.date.toIso8601String()} waist=${entry.waistCm}',
    );

    state = const AsyncLoading();

    final current =
        state.valueOrNull ?? await CoachStorageService.loadCircumferencesAll();

    debugPrint('CONTROLLER ADD CIRC CURRENT COUNT -> ${current.length}');

    final updated = <CoachCircumferenceEntry>[entry, ...current]
      ..sort((a, b) => b.date.compareTo(a.date));

    await CoachStorageService.saveCircumferencesAll(updated);

    state = AsyncData(updated);

    debugPrint('CONTROLLER ADD CIRC DONE -> ${updated.length}');
  }

  Future<void> deleteEntry(String entryId) async {
    state = const AsyncLoading();

    final current =
        state.valueOrNull ?? await CoachStorageService.loadCircumferencesAll();

    final updated = current.where((e) => e.entryId != entryId).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    await CoachStorageService.saveCircumferencesAll(updated);
    state = AsyncData(updated);
  }

  Future<List<CoachCircumferenceEntry>> _loadEntries() async {
    final items = await CoachStorageService.loadCircumferencesAll();
    items.sort((a, b) => b.date.compareTo(a.date));
    return items;
  }
}