import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../models/coach/coach_inbody_entry.dart';
import '../../services/coach/coach_storage_service.dart';

final coachInbodyControllerProvider =
    AsyncNotifierProvider<CoachInbodyController, List<CoachInbodyEntry>>(
  CoachInbodyController.new,
);

final coachInbodyForClientProvider =
    Provider.family<AsyncValue<List<CoachInbodyEntry>>, String>((ref, clientId) {
  final all = ref.watch(coachInbodyControllerProvider);
  return all.whenData((items) {
    final filtered = items
        .where((e) => e.clientId == clientId && !e.isDeleted)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return filtered;
  });
});

class CoachInbodyController extends AsyncNotifier<List<CoachInbodyEntry>> {
  static const _uuid = Uuid();

  @override
  Future<List<CoachInbodyEntry>> build() async {
    await _ensureDeviceId();
    return _loadVisibleEntries();
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    await _ensureDeviceId();
    state = AsyncData(await _loadVisibleEntries());
  }

  Future<void> addEntry(CoachInbodyEntry entry) async {
    final deviceId = await _ensureDeviceId();
    final current = await CoachStorageService.loadInbodyAll();

    final now = DateTime.now();

    final newEntry = entry.copyWith(
      createdAt: now,
      updatedAt: now,
      deletedAt: null,
      version: 1,
      updatedByDeviceId: deviceId,
    );

    final updated = [newEntry, ...current]
      ..sort((a, b) => b.date.compareTo(a.date));

    await CoachStorageService.saveInbodyAll(updated);

    state = AsyncData(updated.where((e) => !e.isDeleted).toList());
  }

  Future<void> deleteEntry(String entryId) async {
    final deviceId = await _ensureDeviceId();
    final allStored = await CoachStorageService.loadInbodyAll();
    final now = DateTime.now();

    final updatedAll = allStored.map((e) {
      if (e.entryId != entryId) return e;

      return e.copyWith(
        updatedAt: now,
        deletedAt: now,
        version: e.version + 1,
        updatedByDeviceId: deviceId,
      );
    }).toList();

    await CoachStorageService.saveInbodyAll(updatedAll);

    final visible = updatedAll.where((e) => !e.isDeleted).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    state = AsyncData(visible);
  }

  Future<List<CoachInbodyEntry>> _loadVisibleEntries() async {
    final items = await CoachStorageService.loadInbodyAll();
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