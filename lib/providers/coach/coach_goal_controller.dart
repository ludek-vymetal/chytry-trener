import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../models/coach/coach_goal.dart';
import '../../services/coach/coach_storage_service.dart';

final coachGoalControllerProvider =
    AsyncNotifierProvider<CoachGoalController, List<CoachGoal>>(
  CoachGoalController.new,
);

final coachGoalForClientProvider =
    Provider.family<AsyncValue<CoachGoal?>, String>((ref, clientId) {
  final all = ref.watch(coachGoalControllerProvider);
  return all.whenData((items) {
    try {
      return items.firstWhere(
        (g) => g.clientId == clientId && !g.isDeleted,
      );
    } catch (_) {
      return null;
    }
  });
});

class CoachGoalController extends AsyncNotifier<List<CoachGoal>> {
  static const _uuid = Uuid();

  @override
  Future<List<CoachGoal>> build() async {
    await _ensureDeviceId();
    return _loadGoals();
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = AsyncData(await _loadGoals());
  }

  Future<void> upsertGoal(CoachGoal goal) async {
    final deviceId = await _ensureDeviceId();
    final now = DateTime.now();
    final current = await CoachStorageService.loadGoalsAll();

    CoachGoal? existing;
    try {
      existing = current.firstWhere((g) => g.clientId == goal.clientId);
    } catch (_) {
      existing = null;
    }

    final prepared = goal.copyWith(
      createdAt: existing?.createdAt ?? goal.createdAt,
      updatedAt: now,
      deletedAt: null,
      version: (existing?.version ?? 0) + 1,
      updatedByDeviceId: deviceId,
      clearDeletedAt: true,
    );

    final updated = [
      prepared,
      ...current.where((g) => g.clientId != goal.clientId),
    ];

    await CoachStorageService.saveGoalsAll(updated);

    final visible = updated.where((g) => !g.isDeleted).toList();
    state = AsyncData(visible);
  }

  Future<void> deleteGoal(String clientId) async {
    final deviceId = await _ensureDeviceId();
    final now = DateTime.now();
    final current = await CoachStorageService.loadGoalsAll();

    final updatedAll = current.map((g) {
      if (g.clientId != clientId) return g;

      return g.copyWith(
        updatedAt: now,
        deletedAt: now,
        version: g.version + 1,
        updatedByDeviceId: deviceId,
      );
    }).toList();

    await CoachStorageService.saveGoalsAll(updatedAll);

    final visible = updatedAll.where((g) => !g.isDeleted).toList();
    state = AsyncData(visible);
  }

  Future<List<CoachGoal>> _loadGoals() async {
    final items = await CoachStorageService.loadGoalsAll();
    return items.where((g) => !g.isDeleted).toList();
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