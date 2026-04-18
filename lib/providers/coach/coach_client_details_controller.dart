import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../models/coach/coach_client_details.dart';
import '../../services/coach/coach_storage_service.dart';

final coachClientDetailsControllerProvider = AsyncNotifierProvider<
    CoachClientDetailsController, List<CoachClientDetails>>(
  CoachClientDetailsController.new,
);

final coachClientDetailsForClientProvider =
    Provider.family<AsyncValue<CoachClientDetails>, String>(
  (ref, clientId) {
    final all = ref.watch(coachClientDetailsControllerProvider);

    return all.whenData((items) {
      try {
        return items.firstWhere(
          (d) => d.clientId == clientId && !d.isDeleted,
        );
      } catch (_) {
        final now = DateTime.now();

        return CoachClientDetails(
          clientId: clientId,
          createdAt: now,
          updatedAt: now,
          deletedAt: null,
          version: 1,
          updatedByDeviceId: 'local',
        );
      }
    });
  },
);

class CoachClientDetailsController
    extends AsyncNotifier<List<CoachClientDetails>> {
  static const _uuid = Uuid();

  @override
  Future<List<CoachClientDetails>> build() async {
    await _ensureDeviceId();
    return _loadVisibleDetails();
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    await _ensureDeviceId();
    state = AsyncData(await _loadVisibleDetails());
  }

  Future<void> upsert(CoachClientDetails details) async {
    final deviceId = await _ensureDeviceId();
    final now = DateTime.now();
    final current = await CoachStorageService.loadClientDetailsAll();

    CoachClientDetails? existing;
    try {
      existing = current.firstWhere((d) => d.clientId == details.clientId);
    } catch (_) {
      existing = null;
    }

    final prepared = details.copyWith(
      createdAt: existing?.createdAt ?? details.createdAt,
      updatedAt: now,
      deletedAt: null,
      version: (existing?.version ?? 0) + 1,
      updatedByDeviceId: deviceId,
      clearDeletedAt: true,
    );

    final updated = [
      prepared,
      ...current.where((d) => d.clientId != details.clientId),
    ];

    await CoachStorageService.saveClientDetailsAll(updated);

    final visible = updated.where((d) => !d.isDeleted).toList();
    state = AsyncData(visible);
  }

  Future<void> saveDetails(CoachClientDetails details) async {
    await upsert(details);
  }

  Future<void> upsertForClient({
    required String clientId,
    String activityType = 'sedavé',
    String occupation = '',
    String injuries = '',
    String allergies = '',
    String intolerances = '',
    String healthNotes = '',
    double sleepHours = 7.0,
    String sleepQuality = 'průměrná',
    String stressLevel = 'střední',
    int stepsPerDay = 6000,
    String motivation = '',
    String preferredFoods = '',
    String dislikedFoods = '',
  }) async {
    final now = DateTime.now();

    final details = CoachClientDetails(
      clientId: clientId,
      activityType: activityType,
      occupation: occupation,
      injuries: injuries,
      allergies: allergies,
      intolerances: intolerances,
      healthNotes: healthNotes,
      sleepHours: sleepHours,
      sleepQuality: sleepQuality,
      stressLevel: stressLevel,
      stepsPerDay: stepsPerDay,
      motivation: motivation,
      preferredFoods: preferredFoods,
      dislikedFoods: dislikedFoods,
      createdAt: now,
      updatedAt: now,
      deletedAt: null,
      version: 1,
      updatedByDeviceId: 'local',
    );

    await upsert(details);
  }

  Future<void> deleteDetails(String clientId) async {
    final deviceId = await _ensureDeviceId();
    final now = DateTime.now();
    final current = await CoachStorageService.loadClientDetailsAll();

    final updatedAll = current.map((d) {
      if (d.clientId != clientId || d.isDeleted) return d;

      return d.copyWith(
        updatedAt: now,
        deletedAt: now,
        version: d.version + 1,
        updatedByDeviceId: deviceId,
      );
    }).toList();

    await CoachStorageService.saveClientDetailsAll(updatedAll);

    final visible = updatedAll.where((d) => !d.isDeleted).toList();
    state = AsyncData(visible);
  }

  Future<List<CoachClientDetails>> _loadVisibleDetails() async {
    final items = await CoachStorageService.loadClientDetailsAll();
    return items.where((d) => !d.isDeleted).toList();
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