import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../models/coach/coach_body_diagnostic_entry.dart';
import '../../services/coach/coach_storage_service.dart';

final coachDiagnosticControllerProvider = AsyncNotifierProvider<
    CoachDiagnosticController, List<CoachBodyDiagnosticEntry>>(
  CoachDiagnosticController.new,
);

final coachDiagnosticsForClientProvider =
    Provider.family<AsyncValue<List<CoachBodyDiagnosticEntry>>, String>(
  (ref, clientId) {
    final all = ref.watch(coachDiagnosticControllerProvider);

    return all.whenData((items) {
      final filtered = items
          .where((e) => e.clientId == clientId && !e.isDeleted)
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      return filtered;
    });
  },
);

class CoachDiagnosticController
    extends AsyncNotifier<List<CoachBodyDiagnosticEntry>> {
  static const _uuid = Uuid();

  @override
  Future<List<CoachBodyDiagnosticEntry>> build() async {
    await _ensureDeviceId();
    return _loadEntries();
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = AsyncData(await _loadEntries());
  }

  Future<void> addEntry(CoachBodyDiagnosticEntry entry) async {
    state = const AsyncLoading();

    final deviceId = await _ensureDeviceId();
    final current = await CoachStorageService.loadDiagnosticsAll();
    final now = DateTime.now();

    final newEntry = entry.copyWith(
      createdAt: entry.createdAt,
      updatedAt: now,
      deletedAt: null,
      version: 1,
      updatedByDeviceId: deviceId,
      clearDeletedAt: true,
    );

    final updated = <CoachBodyDiagnosticEntry>[newEntry, ...current]
      ..sort((a, b) => b.date.compareTo(a.date));

    await CoachStorageService.saveDiagnosticsAll(updated);

    state = AsyncData(updated.where((e) => !e.isDeleted).toList());
  }

  Future<void> deleteEntry(String entryId) async {
    state = const AsyncLoading();

    final deviceId = await _ensureDeviceId();
    final now = DateTime.now();
    final current = await CoachStorageService.loadDiagnosticsAll();

    final updatedAll = current.map((e) {
      if (e.entryId != entryId) return e;

      return e.copyWith(
        updatedAt: now,
        deletedAt: now,
        version: e.version + 1,
        updatedByDeviceId: deviceId,
      );
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    await CoachStorageService.saveDiagnosticsAll(updatedAll);

    state = AsyncData(updatedAll.where((e) => !e.isDeleted).toList());
  }

  Future<List<CoachBodyDiagnosticEntry>> _loadEntries() async {
    final items = await CoachStorageService.loadDiagnosticsAll();
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