import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/health/health_sync_service.dart';

class HealthState {
  final bool loaded;
  final bool enabled;
  final bool syncing;
  final List<HealthDay> days;
  final DateTime? lastSync;
  final String? error;
  final int stepGoal;
  final bool promptDismissed;

  const HealthState({
    this.loaded = false,
    this.enabled = false,
    this.syncing = false,
    this.days = const [],
    this.lastSync,
    this.error,
    this.stepGoal = HealthSyncService.defaultStepGoal,
    this.promptDismissed = false,
  });

  bool get supported => HealthSyncService.supported;

  HealthState copyWith({
    bool? loaded,
    bool? enabled,
    bool? syncing,
    List<HealthDay>? days,
    DateTime? lastSync,
    String? error,
    bool clearError = false,
    int? stepGoal,
    bool? promptDismissed,
  }) =>
      HealthState(
        loaded: loaded ?? this.loaded,
        enabled: enabled ?? this.enabled,
        syncing: syncing ?? this.syncing,
        days: days ?? this.days,
        lastSync: lastSync ?? this.lastSync,
        error: clearError ? null : (error ?? this.error),
        stepGoal: stepGoal ?? this.stepGoal,
        promptDismissed: promptDismissed ?? this.promptDismissed,
      );

  HealthDay? dayFor(DateTime d) {
    final k = HealthDay.keyOf(d);
    for (final x in days) {
      if (x.key == k) return x;
    }
    return null;
  }

  HealthDay? get today => dayFor(DateTime.now());

  /// Jsou v telefonu vůbec nějaká data?
  bool get hasData => days.any((d) => !d.isEmpty);
}

/// Statistiky za posledních [n] dní (bez dnešku, který ještě běží).
class HealthStats {
  final int avgSteps;
  final int avgActiveKcal;
  final int avgSleepMin;
  final int? avgRestingHr;
  final int workouts;
  final int workoutMinutes;
  final int daysWithData;

  const HealthStats({
    required this.avgSteps,
    required this.avgActiveKcal,
    required this.avgSleepMin,
    required this.avgRestingHr,
    required this.workouts,
    required this.workoutMinutes,
    required this.daysWithData,
  });

  static HealthStats of(List<HealthDay> days, {int n = 7}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final from = today.subtract(Duration(days: n));
    final list = [
      for (final d in days)
        if (!d.date.isBefore(from) && d.date.isBefore(today)) d,
    ];
    int avg(Iterable<int> xs) {
      final v = xs.where((x) => x > 0).toList();
      if (v.isEmpty) return 0;
      return (v.reduce((a, b) => a + b) / v.length).round();
    }

    final hr = [for (final d in list) if (d.restingHr != null) d.restingHr!];
    final wo = [for (final d in list) ...d.workouts];
    return HealthStats(
      avgSteps: avg(list.map((d) => d.steps)),
      avgActiveKcal: avg(list.map((d) => d.activeKcal)),
      avgSleepMin: avg(list.map((d) => d.sleepMin)),
      avgRestingHr: hr.isEmpty ? null : avg(hr),
      workouts: wo.length,
      workoutMinutes: wo.fold(0, (a, w) => a + w.minutes),
      daysWithData: list.where((d) => !d.isEmpty).length,
    );
  }

  /// Kolik kalorií pohybem spálí klient v běžný den (medián 14 dní).
  static int typicalActiveKcal(List<HealthDay> days) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final from = today.subtract(const Duration(days: 14));
    final v = [
      for (final d in days)
        if (!d.date.isBefore(from) && d.date.isBefore(today) && d.activeKcal > 0)
          d.activeKcal,
    ]..sort();
    if (v.length < 3) return 0;
    return v[v.length ~/ 2];
  }
}

class HealthController extends StateNotifier<HealthState>
    with WidgetsBindingObserver {
  HealthController() : super(const HealthState()) {
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  /// Automaticky nejvýš jednou za 15 minut.
  static const _autoInterval = Duration(minutes: 15);

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final days = await HealthSyncService.loadLocal();
    if (!mounted) return;
    state = state.copyWith(
      loaded: true,
      enabled: HealthSyncService.supported &&
          (prefs.getBool(HealthSyncService.enabledKey) ?? false),
      days: days,
      lastSync: DateTime.tryParse(
        prefs.getString(HealthSyncService.lastSyncKey) ?? '',
      ),
      stepGoal: prefs.getInt(HealthSyncService.stepGoalKey) ??
          HealthSyncService.defaultStepGoal,
      promptDismissed:
          prefs.getBool(HealthSyncService.promptDismissedKey) ?? false,
    );
    await syncIfStale();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) syncIfStale();
  }

  Future<void> syncIfStale() async {
    if (!state.enabled || state.syncing) return;
    final last = state.lastSync;
    if (last != null && DateTime.now().difference(last) < _autoInterval) {
      return;
    }
    await sync();
  }

  /// Načte data z hodinek a pošle je trenérovi.
  Future<void> sync() async {
    if (!state.enabled || state.syncing) return;
    state = state.copyWith(syncing: true, clearError: true);
    try {
      final days = await HealthSyncService.fetch();
      await HealthSyncService.saveLocal(days);
      await HealthSyncService.pushToCoach(days);
      if (!mounted) return;
      state = state.copyWith(
        syncing: false,
        days: days,
        lastSync: DateTime.now(),
      );
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(
        syncing: false,
        error: 'Data se nepodařilo načíst. Zkus to znovu.',
      );
    }
  }

  /// Požádá o přístup a hned načte data.
  Future<HealthConnectResult> connect() async {
    final r = await HealthSyncService.connect();
    if (r == HealthConnectResult.ok) {
      state = state.copyWith(enabled: true, clearError: true);
      await sync();
    }
    return r;
  }

  Future<void> disconnect() async {
    await HealthSyncService.disconnect();
    if (!mounted) return;
    state = HealthState(
      loaded: true,
      stepGoal: state.stepGoal,
      promptDismissed: true,
    );
  }

  Future<void> setStepGoal(int goal) async {
    final g = goal.clamp(1000, 50000).toInt();
    state = state.copyWith(stepGoal: g);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(HealthSyncService.stepGoalKey, g);
  }

  Future<void> dismissPrompt() async {
    state = state.copyWith(promptDismissed: true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(HealthSyncService.promptDismissedKey, true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

/// Aktivita z hodinek (Apple Zdraví / Health Connect) – jen klient.
final healthProvider =
    StateNotifierProvider<HealthController, HealthState>(
  (ref) => HealthController(),
);
