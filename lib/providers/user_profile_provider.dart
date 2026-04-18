import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/phase/phase.dart';
import '../core/phase/phase_planner_service.dart';
import '../core/phase/phase_resolver.dart';
import '../core/phase/plan_mode.dart';
import '../core/time/time_context.dart';
import '../core/training/intake/training_intake.dart';
import '../core/training/training_split.dart';
import '../models/body_circumference.dart';
import '../models/goal.dart';
import '../models/measurement.dart';
import '../models/user_profile.dart';

class UserProfileNotifier extends StateNotifier<UserProfile?> {
  UserProfileNotifier() : super(null) {
    unawaited(_loadFromPrefs());
  }

  static const String _legacyStorageKey = 'user_profile_storage';

  // ==========================================================
  // Logging
  // ==========================================================

  void _log(String message) {
    debugPrint('USER PROFILE -> $message');
  }

  // ==========================================================
  // Storage keys
  // ==========================================================

  String _storageKeyForClient(String? clientId) {
    final trimmed = clientId?.trim();

    if (trimmed == null || trimmed.isEmpty) {
      return _legacyStorageKey;
    }

    return 'user_profile_storage_$trimmed';
  }

  // ==========================================================
  // Load / Save
  // ==========================================================

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final legacyJson = prefs.getString(_legacyStorageKey);

      if (legacyJson == null || legacyJson.isEmpty) {
        _log('LOAD LEGACY MISS -> key=$_legacyStorageKey');
        return;
      }

      final jsonData = Map<String, dynamic>.from(
        json.decode(legacyJson) as Map,
      );

      state = UserProfile.fromJson(jsonData);

      _log(
        'LOAD LEGACY OK -> '
        'key=$_legacyStorageKey '
        'clientId=${state?.clientId} '
        'goal=${state?.goal?.type.name}/${state?.goal?.reason.name}',
      );
    } catch (e) {
      _log('LOAD LEGACY ERROR -> $e');
    }
  }

  Future<UserProfile?> _readProfileFromStorage(String? clientId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _storageKeyForClient(clientId);
      final jsonString = prefs.getString(key);

      if (jsonString == null || jsonString.isEmpty) {
        _log('LOAD MISS -> key=$key clientId=$clientId');
        return null;
      }

      final jsonData = Map<String, dynamic>.from(
        json.decode(jsonString) as Map,
      );

      final loaded = UserProfile.fromJson(jsonData);

      _log(
        'LOAD OK -> key=$key clientId=${loaded.clientId} '
        'goal=${loaded.goal?.type.name}/${loaded.goal?.reason.name}',
      );

      return loaded;
    } catch (e) {
      _log('LOAD ERROR -> clientId=$clientId error=$e');
      return null;
    }
  }

  Future<void> _saveToPrefs() async {
    final currentState = state;
    if (currentState == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _storageKeyForClient(currentState.clientId);

      final existingStored = await _readProfileFromStorage(currentState.clientId);
      final safeProfile = _mergeProfiles(
        base: existingStored,
        incoming: currentState,
      );

      final jsonString = json.encode(safeProfile.toJson());
      await prefs.setString(key, jsonString);

      state = safeProfile;

      _log(
        'SAVE OK -> key=$key clientId=${safeProfile.clientId} '
        'goal=${safeProfile.goal?.type.name}/${safeProfile.goal?.reason.name}',
      );
    } catch (e) {
      _log('SAVE ERROR -> $e');
    }
  }

  // ==========================================================
  // Merge
  // ==========================================================

  UserProfile _mergeProfiles({
    UserProfile? base,
    required UserProfile incoming,
  }) {
    if (base == null) {
      return incoming;
    }

    final incomingClientId = incoming.clientId?.trim();

    return base.copyWith(
      clientId: (incomingClientId != null && incomingClientId.isNotEmpty)
          ? incoming.clientId
          : base.clientId,
      firstName:
          incoming.firstName.isNotEmpty ? incoming.firstName : base.firstName,
      lastName:
          incoming.lastName.isNotEmpty ? incoming.lastName : base.lastName,
      email: incoming.email.isNotEmpty ? incoming.email : base.email,
      age: incoming.age != 0 ? incoming.age : base.age,
      gender: incoming.gender.isNotEmpty ? incoming.gender : base.gender,
      height: incoming.height != 0 ? incoming.height : base.height,
      weight: incoming.weight != 0.0 ? incoming.weight : base.weight,
      tdee: incoming.tdee != 0.0 ? incoming.tdee : base.tdee,
      goal: incoming.goal ?? base.goal,
      measurements: incoming.measurements.isNotEmpty
          ? incoming.measurements
          : base.measurements,
      circumferences: incoming.circumferences.isNotEmpty
          ? incoming.circumferences
          : base.circumferences,
      preferredSplit: incoming.preferredSplit ?? base.preferredSplit,
      trainingIntake: incoming.trainingIntake ?? base.trainingIntake,
      selectedPlan: incoming.selectedPlan.isNotEmpty
          ? incoming.selectedPlan
          : base.selectedPlan,
      isFasting: incoming.isFasting,
      fastingStartTime: incoming.fastingStartTime ?? base.fastingStartTime,
      fastingDuration: incoming.fastingDuration != 0
          ? incoming.fastingDuration
          : base.fastingDuration,
    );
  }

  Future<UserProfile> _buildSafeProfileForClient({
    required String? clientId,
    required UserProfile incoming,
  }) async {
    final stored = await _readProfileFromStorage(clientId);

    if (stored == null) {
      return incoming;
    }

    return _mergeProfiles(
      base: stored,
      incoming: incoming,
    );
  }

  // ==========================================================
  // Public updates
  // ==========================================================

  void setBasicInfo({
    required int age,
    required String gender,
  }) {
    final current = state ?? const UserProfile();

    state = current.copyWith(
      age: age,
      gender: gender,
    );

    unawaited(_onStateChanged());
  }

  void setBodyMetrics({
    required int height,
    required double weight,
  }) {
    final current = state ?? const UserProfile();

    state = current.copyWith(
      height: height,
      weight: weight,
    );

    unawaited(_onStateChanged());
  }

  Future<void> setProfileBasics({
    String? clientId,
    String? firstName,
    String? lastName,
    required int age,
    required String gender,
    required int heightCm,
    required double weightKg,
  }) async {
    _log(
      'SET PROFILE BASICS START -> incomingClientId=$clientId '
      'currentStateClientId=${state?.clientId}',
    );

    final loadedProfile = await _readProfileFromStorage(clientId);

    final incoming = UserProfile(
      clientId: clientId,
      firstName: firstName ?? '',
      lastName: lastName ?? '',
      age: age,
      gender: gender,
      height: heightCm,
      weight: weightKg,
    );

    state = _mergeProfiles(
      base: loadedProfile,
      incoming: incoming,
    );

    _log(
      'SET PROFILE BASICS DONE -> state.clientId=${state?.clientId} '
      'goal=${state?.goal?.type.name}/${state?.goal?.reason.name}',
    );

    await _onStateChanged();
  }

  Future<void> setFullProfile(UserProfile profile) async {
    _log(
      'SET FULL PROFILE START -> incomingClientId=${profile.clientId} '
      'incomingGoal=${profile.goal?.type.name}/${profile.goal?.reason.name} '
      'currentClientId=${state?.clientId} '
      'currentGoal=${state?.goal?.type.name}/${state?.goal?.reason.name}',
    );

    state = await _buildSafeProfileForClient(
      clientId: profile.clientId,
      incoming: profile,
    );

    _log(
      'SET FULL PROFILE DONE -> state.clientId=${state?.clientId} '
      'stateGoal=${state?.goal?.type.name}/${state?.goal?.reason.name}',
    );

    await _onStateChanged();
  }

  Future<void> updateProfile(UserProfile profile) async {
    _log(
      'UPDATE PROFILE START -> incomingClientId=${profile.clientId} '
      'incomingGoal=${profile.goal?.type.name}/${profile.goal?.reason.name} '
      'currentClientId=${state?.clientId} '
      'currentGoal=${state?.goal?.type.name}/${state?.goal?.reason.name}',
    );

    state = await _buildSafeProfileForClient(
      clientId: profile.clientId,
      incoming: profile,
    );

    _log(
      'UPDATE PROFILE DONE -> state.clientId=${state?.clientId} '
      'stateGoal=${state?.goal?.type.name}/${state?.goal?.reason.name}',
    );

    await _onStateChanged();
  }

  Future<void> switchToClient(String? clientId) async {
    _log(
      'SWITCH CLIENT START -> requestedClientId=$clientId '
      'currentClientId=${state?.clientId}',
    );

    if (clientId == null || clientId.trim().isEmpty) {
      state = const UserProfile();

      _log(
        'SWITCH CLIENT DONE -> detached clean profile '
        'clientId=${state?.clientId} '
        'goal=${state?.goal?.type.name}/${state?.goal?.reason.name}',
      );
      return;
    }

    final loaded = await _readProfileFromStorage(clientId);

    if (loaded != null) {
      state = loaded;

      _log(
        'SWITCH CLIENT DONE -> loaded clientId=${state?.clientId} '
        'goal=${state?.goal?.type.name}/${state?.goal?.reason.name}',
      );
      return;
    }

    state = UserProfile(clientId: clientId);

    _log(
      'SWITCH CLIENT DONE -> initialized empty clientId=${state?.clientId} '
      'goal=${state?.goal?.type.name}/${state?.goal?.reason.name}',
    );
  }

  void setGoal(Goal goal) {
    final current = state;
    if (current == null) {
      _log('SET GOAL FAIL -> state is null');
      return;
    }

    _log(
      'SET GOAL -> clientId=${current.clientId} '
      'type=${goal.type.name} '
      'reason=${goal.reason.name} '
      'targetDate=${goal.targetDate.toIso8601String()} '
      'planMode=${goal.planMode.name}',
    );

    state = current.copyWith(goal: goal);

    _log(
      'SET GOAL DONE -> state.clientId=${state?.clientId} '
      'state.goal=${state?.goal?.type.name}/${state?.goal?.reason.name}',
    );

    unawaited(_onStateChanged());
  }

  void addMeasurement(Measurement measurement) {
    final current = state;
    if (current == null) return;

    state = current.copyWith(
      measurements: [...current.measurements, measurement],
      weight: measurement.weight,
    );

    unawaited(_onStateChanged());
  }

  void setPreferredSplit(TrainingSplit split) {
    final current = state;
    if (current == null) return;

    state = current.copyWith(preferredSplit: split);

    unawaited(_onStateChanged());
  }

  void setTrainingIntake(TrainingIntake intake) {
    final current = state;
    if (current == null) return;

    state = current.copyWith(trainingIntake: intake);

    unawaited(_onStateChanged());
  }

  void addCircumference(BodyCircumference data) {
    final current = state;
    if (current == null) return;

    state = current.copyWith(
      circumferences: [...current.circumferences, data],
    );

    unawaited(_onStateChanged());
  }

  void updateTrainingMax(String exerciseId, double newTm) {
    final current = state;
    if (current == null) return;

    final intake = current.trainingIntake;
    if (intake == null) return;

    final updated = Map<String, double>.from(intake.oneRMs);
    updated[exerciseId] = newTm;

    state = current.copyWith(
      trainingIntake: intake.copyWith(oneRMs: updated),
    );

    unawaited(_onStateChanged());
  }

  // ==========================================================
  // State side effects
  // ==========================================================

  Future<void> _onStateChanged() async {
    _updateLegacyPhaseByDate();
    _recalculateMacros();
    await _saveToPrefs();
  }

  void _updateLegacyPhaseByDate() {
    final current = state;
    final goal = current?.goal;

    if (current == null || goal == null) return;

    final now = DateTime.now();

    final ctx = TimeContext(
      now: now,
      targetDate: goal.targetDate,
      mode: _mapGoalPlanModeToPlanMode(goal.planMode),
    );

    final plans = PhasePlannerService.buildPlan(ctx);
    if (plans.isEmpty) return;

    final resolved = PhaseResolver.resolveCurrentPhase(
      plans: plans,
      date: now,
    );

    final newLegacyPhase = _mapPhaseTypeToGoalPhase(resolved.phase);

    if (goal.phase != newLegacyPhase) {
      final updatedGoal = goal.copyWith(phase: newLegacyPhase);
      state = current.copyWith(goal: updatedGoal);
    }
  }

  GoalPhase _mapPhaseTypeToGoalPhase(PhaseType phase) {
    switch (phase) {
      case PhaseType.gaining:
        return GoalPhase.build;
      case PhaseType.cutting:
        return GoalPhase.cut;
      case PhaseType.peaking:
        return GoalPhase.cut;
      case PhaseType.maintenance:
        return GoalPhase.maintain;
    }
  }

  PlanMode _mapGoalPlanModeToPlanMode(GoalPlanMode mode) {
    switch (mode) {
      case GoalPlanMode.accelerated:
        return PlanMode.accelerated;
      case GoalPlanMode.normal:
        return PlanMode.normal;
      case GoalPlanMode.auto:
        return PlanMode.normal;
    }
  }

  void _recalculateMacros() {
    // Tady proběhne výpočet makroživin, pokud je potřeba
  }

  // ==========================================================
  // Clear
  // ==========================================================

  Future<void> clearAllData() async {
    state = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_legacyStorageKey);
  }

  Future<void> clearClientData(String clientId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKeyForClient(clientId));

    if (state?.clientId == clientId) {
      state = null;
    }
  }
}

final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, UserProfile?>(
  (ref) => UserProfileNotifier(),
);