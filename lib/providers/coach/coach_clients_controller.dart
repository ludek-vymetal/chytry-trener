import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/training/sessions/training_session.dart';
import '../../models/coach/coach_client.dart';
import '../../models/goal.dart';
import '../../models/user_profile.dart';
import '../../providers/training_session_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../services/coach/coach_metrics_service.dart';
import '../../services/coach/coach_storage_service.dart';

final coachClientsControllerProvider =
    AsyncNotifierProvider<CoachClientsController, List<CoachClientWithStats>>(
  CoachClientsController.new,
);

class CoachClientWithStats {
  final CoachClient client;
  final double compliance7d;
  final DateTime? lastSessionAt;

  const CoachClientWithStats({
    required this.client,
    required this.compliance7d,
    this.lastSessionAt,
  });
}

class CoachClientsController extends AsyncNotifier<List<CoachClientWithStats>> {
  static const _uuid = Uuid();
  static const _idCounterKey = 'client_id_counter_v1';

  @override
  Future<List<CoachClientWithStats>> build() async {
    await _ensureDeviceId();
    final clients = await CoachStorageService.loadClients();
    return _mapWithStats(clients);
  }

  Future<void> reload() async {
    state = const AsyncLoading();

    await _ensureDeviceId();

    final clients = await CoachStorageService.loadClients();
    state = AsyncData(await _mapWithStats(clients));
  }

  Future<void> addCurrentUserAsClient() async {
    final profile = ref.read(userProfileProvider);
    if (profile == null) return;

    state = const AsyncLoading();

    final deviceId = await _ensureDeviceId();
    final clients = await CoachStorageService.loadClients();

    const selfId = 'local_user';
    final exists = clients.any((c) => c.clientId == selfId);
    if (exists) {
      state = AsyncData(await _mapWithStats(clients));
      return;
    }

    final now = DateTime.now();

    final newClient = CoachClient(
      clientId: selfId,
      firstName: profile.firstName.isEmpty ? 'Můj' : profile.firstName,
      lastName: profile.lastName.isEmpty ? 'klient' : profile.lastName,
      email: profile.email.trim(),
      gender: profile.gender,
      age: profile.age,
      heightCm: profile.height,
      weightKg: profile.weight,
      isEatingDisorderSupport: _isSensitive(profile),
      linkedAt: now,
      createdAt: now,
      updatedAt: now,
      deletedAt: null,
      version: 1,
      updatedByDeviceId: deviceId,
    );

    final updated = [...clients, newClient];
    await CoachStorageService.saveClients(updated);

    state = AsyncData(await _mapWithStats(updated));
  }

  Future<void> addClientManual({
    required String firstName,
    required String lastName,
    required String email,
    required String gender,
    required int age,
    required int heightCm,
    required double weightKg,
    required bool isEatingDisorderSupport,
  }) async {
    state = const AsyncLoading();

    final deviceId = await _ensureDeviceId();
    final clients = await CoachStorageService.loadClients();

    int next = await _getNextClientNumber();
    String newId;

    while (true) {
      newId = 'C${next.toString().padLeft(4, '0')}';
      final exists = clients.any((c) => c.clientId == newId);
      if (!exists) break;

      next++;
      await CoachStorageService.saveInt(_idCounterKey, next);
    }

    final now = DateTime.now();

    final newClient = CoachClient(
      clientId: newId,
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      email: email.trim(),
      gender: gender,
      age: age,
      heightCm: heightCm,
      weightKg: weightKg,
      isEatingDisorderSupport: isEatingDisorderSupport,
      linkedAt: now,
      createdAt: now,
      updatedAt: now,
      deletedAt: null,
      version: 1,
      updatedByDeviceId: deviceId,
    );

    final updated = [...clients, newClient];
    await CoachStorageService.saveClients(updated);

    state = AsyncData(await _mapWithStats(updated));
  }

  Future<void> updateClientBasic({
    required String clientId,
    required String firstName,
    required String lastName,
    required String email,
    required String gender,
    required int age,
    required int heightCm,
    required double weightKg,
    required bool isEatingDisorderSupport,
  }) async {
    state = const AsyncLoading();

    final deviceId = await _ensureDeviceId();
    final now = DateTime.now();
    final clients = await CoachStorageService.loadClients();

    final updated = clients.map((c) {
      if (c.clientId != clientId) return c;

      return CoachClient(
        clientId: c.clientId,
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        email: email.trim(),
        gender: gender,
        age: age,
        heightCm: heightCm,
        weightKg: weightKg,
        isEatingDisorderSupport: isEatingDisorderSupport,
        linkedAt: c.linkedAt,
        createdAt: c.createdAt,
        updatedAt: now,
        deletedAt: c.deletedAt,
        version: c.version + 1,
        updatedByDeviceId: deviceId,
      );
    }).toList();

    await CoachStorageService.saveClients(updated);
    state = AsyncData(await _mapWithStats(updated));
  }

  Future<void> deleteClient(String clientId) async {
    state = const AsyncLoading();

    final clients = await CoachStorageService.loadClients();
    final updatedClients =
        clients.where((c) => c.clientId != clientId).toList();

    await CoachStorageService.saveClients(updatedClients);
    await CoachStorageService.deleteClientDetails(clientId);
    await CoachStorageService.deleteNotesForClient(clientId);
    await CoachStorageService.deleteCircumferencesForClient(clientId);
    await CoachStorageService.deleteInbodyForClient(clientId);

    state = AsyncData(await _mapWithStats(updatedClients));
  }

  Future<int> _getNextClientNumber() async {
    final current = await CoachStorageService.loadInt(_idCounterKey) ?? 0;
    final next = current + 1;
    await CoachStorageService.saveInt(_idCounterKey, next);
    return next;
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

  Future<List<CoachClientWithStats>> _mapWithStats(
    List<CoachClient> clients,
  ) async {
    final profile = ref.read(userProfileProvider);
    final history = ref.read(trainingSessionProvider);

    final now = DateTime.now();
    final freq = profile?.trainingIntake?.frequencyPerWeek ?? 3;

    final result = clients.map((c) {
      final List<TrainingSession> relevantHistory =
          c.clientId == 'local_user' ? history : <TrainingSession>[];

      final compliance7d = CoachMetricsService.complianceForDays(
        history: relevantHistory,
        now: now,
        days: 7,
        frequencyPerWeek: freq,
      );

      DateTime? lastSessionAt;
      if (relevantHistory.isNotEmpty) {
        final sorted = [...relevantHistory]
          ..sort((a, b) => b.date.compareTo(a.date));
        lastSessionAt = sorted.first.date;
      }

      return CoachClientWithStats(
        client: c,
        compliance7d: compliance7d,
        lastSessionAt: lastSessionAt,
      );
    }).toList();

    result.sort((a, b) {
      if (a.client.clientId == 'local_user') return -1;
      if (b.client.clientId == 'local_user') return 1;

      final nameA =
          '${a.client.firstName.trim()} ${a.client.lastName.trim()}'.toLowerCase();
      final nameB =
          '${b.client.firstName.trim()} ${b.client.lastName.trim()}'.toLowerCase();

      return nameA.compareTo(nameB);
    });

    return result;
  }

  bool _isSensitive(UserProfile profile) {
    final g = profile.goal;
    if (g == null) return false;

    return g.reason == GoalReason.eatingDisorderSupport ||
        g.type == GoalType.weightGainSupport;
  }
}