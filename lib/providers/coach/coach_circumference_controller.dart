import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

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
      final filtered = items
          .where((e) => e.clientId == clientId && !e.isDeleted)
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      return filtered;
    });
  },
);

class CoachCircumferenceController
    extends AsyncNotifier<List<CoachCircumferenceEntry>> {
  static const _uuid = Uuid();

  @override
  Future<List<CoachCircumferenceEntry>> build() async {
    await _ensureDeviceId();
    final items = await _loadEntries();

    debugPrint('CONTROLLER BUILD CIRC -> ${items.length}');
    return items;
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    await _ensureDeviceId();
    final items = await _loadEntries();
    state = AsyncData(items);
  }

  Future<void> addEntry(CoachCircumferenceEntry entry) async {
    debugPrint(
      'CONTROLLER ADD CIRC START -> id=${entry.entryId} clientId=${entry.clientId} date=${entry.date.toIso8601String()} waist=${entry.waistCm}',
    );

    state = const AsyncLoading();

    final deviceId = await _ensureDeviceId();
    final current = await CoachStorageService.loadCircumferencesAll();

    debugPrint('CONTROLLER ADD CIRC CURRENT COUNT -> ${current.length}');

    final now = DateTime.now();

    final newEntry = entry.copyWith(
      createdAt: entry.createdAt,
      updatedAt: now,
      deletedAt: null,
      version: entry.version <= 0 ? 1 : entry.version,
      updatedByDeviceId: deviceId,
      clearDeletedAt: true,
    );

    final updated = <CoachCircumferenceEntry>[newEntry, ...current]
      ..sort((a, b) => b.date.compareTo(a.date));

    await CoachStorageService.saveCircumferencesAll(updated);

    state = AsyncData(updated.where((e) => !e.isDeleted).toList());

    debugPrint(
      'CONTROLLER ADD CIRC DONE -> ${updated.where((e) => !e.isDeleted).length}',
    );
  }

  Future<void> deleteEntry(String entryId) async {
    state = const AsyncLoading();

    final deviceId = await _ensureDeviceId();
    final now = DateTime.now();
    final current = await CoachStorageService.loadCircumferencesAll();

    final updatedAll = current.map((e) {
      if (e.entryId != entryId || e.isDeleted) return e;

      return e.copyWith(
        updatedAt: now,
        deletedAt: now,
        version: e.version + 1,
        updatedByDeviceId: deviceId,
      );
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    await CoachStorageService.saveCircumferencesAll(updatedAll);
    state = AsyncData(updatedAll.where((e) => !e.isDeleted).toList());
  }

  Future<List<CoachCircumferenceEntry>> _loadEntries() async {
    final items = await CoachStorageService.loadCircumferencesAll();
    items.sort((a, b) => b.date.compareTo(a.date));
    return items.where((e) => !e.isDeleted).toList();
  }

  Future<String> _ensureDeviceId() async {
    final existing = await CoachStorageService.loadDeviceId();

    if (existing != null && existing.trim().isNotEmpty) {
      return existing;
    }

    final newId = _uuid.v4();
    await CoachStorageService.saveDeviceId(newId);
    return newId;
  }
}