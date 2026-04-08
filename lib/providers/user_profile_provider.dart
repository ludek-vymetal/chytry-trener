import 'dart:convert';

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
    _loadFromPrefs();
  }

  static const String _legacyStorageKey = 'user_profile_storage';

  String _storageKeyForClient(String? clientId) {
    if (clientId == null || clientId.trim().isEmpty) {
      return _legacyStorageKey;
    }
    return 'user_profile_storage_${clientId.trim()}';
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final legacyJson = prefs.getString(_legacyStorageKey);
      if (legacyJson != null && legacyJson.isNotEmpty) {
        final Map<String, dynamic> jsonData =
            Map<String, dynamic>.from(json.decode(legacyJson) as Map);

        state = UserProfile.fromJson(jsonData);

        print(
          'USER PROFILE LOADED (LEGACY) -> '
          'key=$_legacyStorageKey '
          'clientId=${state?.clientId} '
          'goal=${state?.goal?.type.name}/${state?.goal?.reason.name}',
        );
      }
    } catch (e) {
      print('Chyba při načítání UserProfile z SharedPreferences: $e');
    }
  }

  Future<UserProfile?> _readProfileFromStorage(String? clientId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _storageKeyForClient(clientId);

      final jsonString = prefs.getString(key);
      if (jsonString == null || jsonString.isEmpty) {
        print('USER PROFILE LOAD MISS -> key=$key clientId=$clientId');
        return null;
      }

      final Map<String, dynamic> jsonData =
          Map<String, dynamic>.from(json.decode(jsonString) as Map);

      final loaded = UserProfile.fromJson(jsonData);

      print(
        'USER PROFILE LOADED -> key=$key clientId=${loaded.clientId} '
        'goal=${loaded.goal?.type.name}/${loaded.goal?.reason.name}',
      );

      return loaded;
    } catch (e) {
      print('USER PROFILE LOAD ERROR -> clientId=$clientId error=$e');
      return null;
    }
  }

  Future<void> _saveToPrefs() async {
    if (state == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final currentState = state!;
      final key = _storageKeyForClient(currentState.clientId);

      final existingStored = await _readProfileFromStorage(currentState.clientId);
      final safeProfile = _mergeProfiles(
        base: existingStored,
        incoming: currentState,
      );

      final jsonString = json.encode(safeProfile.toJson());
      await prefs.setString(key, jsonString);

      state = safeProfile;

      print(
        'USER PROFILE SAVED -> key=$key clientId=${safeProfile.clientId} '
        'goal=${safeProfile.goal?.type.name}/${safeProfile.goal?.reason.name}',
      );
    } catch (e) {
      print('Chyba při ukládání UserProfile do SharedPreferences: $e');
    }
  }

  UserProfile _mergeProfiles({
    UserProfile? base,
    required UserProfile incoming,
  }) {
    if (base == null) {
      return incoming;
    }

    return base.copyWith(
      clientId: (incoming.clientId != null && incoming.clientId!.trim().isNotEmpty)
          ? incoming.clientId
          : base.clientId,
      firstName:
          incoming.firstName.isNotEmpty ? incoming.firstName : base.firstName,
      lastName: incoming.lastName.isNotEmpty ? incoming.lastName : base.lastName,
      email: incoming.email.isNotEmpty ? incoming.email : base.email,
      age: incoming.age != 0 ? incoming.age : base.age,
      gender: incoming.gender.isNotEmpty ? incoming.gender : base.gender,
      height: incoming.height != 0 ? incoming.height : base.height,
      weight: incoming.weight != 0.0 ? incoming.weight : base.weight,
      tdee: incoming.tdee != 0.0 ? incoming.tdee : base.tdee,

      goal: incoming.goal ?? base.goal,

      measurements:
          incoming.measurements.isNotEmpty ? incoming.measurements : base.measurements,
      circumferences: incoming.circumferences.isNotEmpty
          ? incoming.circumferences
          : base.circumferences,

      preferredSplit: incoming.preferredSplit ?? base.preferredSplit,
      trainingIntake: incoming.trainingIntake ?? base.trainingIntake,

      selectedPlan:
          incoming.selectedPlan.isNotEmpty ? incoming.selectedPlan : base.selectedPlan,

      isFasting: incoming.isFasting,
      fastingStartTime: incoming.fastingStartTime ?? base.fastingStartTime,
      fastingDuration:
          incoming.fastingDuration != 0 ? incoming.fastingDuration : base.fastingDuration,
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

  void setBasicInfo({
    required int age,
    required String gender,
  }) {
    final current = state ?? const UserProfile();
    state = current.copyWith(
      age: age,
      gender: gender,
    );
    _onStateChanged();
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
    _onStateChanged();
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
    print(
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

    print(
      'SET PROFILE BASICS DONE -> state.clientId=${state!.clientId} '
      'goal=${state!.goal?.type.name}/${state!.goal?.reason.name}',
    );

    await _onStateChanged();
  }

  Future<void> setFullProfile(UserProfile profile) async {
    print(
      'SET FULL PROFILE START -> incomingClientId=${profile.clientId} '
      'incomingGoal=${profile.goal?.type.name}/${profile.goal?.reason.name} '
      'currentClientId=${state?.clientId} '
      'currentGoal=${state?.goal?.type.name}/${state?.goal?.reason.name}',
    );

    state = await _buildSafeProfileForClient(
      clientId: profile.clientId,
      incoming: profile,
    );

    print(
      'SET FULL PROFILE DONE -> state.clientId=${state?.clientId} '
      'stateGoal=${state?.goal?.type.name}/${state?.goal?.reason.name}',
    );

    await _onStateChanged();
  }

  Future<void> updateProfile(UserProfile profile) async {
    print(
      'UPDATE PROFILE START -> incomingClientId=${profile.clientId} '
      'incomingGoal=${profile.goal?.type.name}/${profile.goal?.reason.name} '
      'currentClientId=${state?.clientId} '
      'currentGoal=${state?.goal?.type.name}/${state?.goal?.reason.name}',
    );

    state = await _buildSafeProfileForClient(
      clientId: profile.clientId,
      incoming: profile,
    );

    print(
      'UPDATE PROFILE DONE -> state.clientId=${state?.clientId} '
      'stateGoal=${state?.goal?.type.name}/${state?.goal?.reason.name}',
    );

    await _onStateChanged();
  }

  Future<void> switchToClient(String? clientId) async {
    print(
      'SWITCH CLIENT START -> requestedClientId=$clientId '
      'currentClientId=${state?.clientId}',
    );

    // KLÍČOVÝ FIX:
    // null / empty už NESMÍ načítat legacy profil, ale musí vytvořit čistý odpojený stav
    if (clientId == null || clientId.trim().isEmpty) {
      state = const UserProfile();

      print(
        'SWITCH CLIENT DONE -> detached clean profile '
        'clientId=${state?.clientId} '
        'goal=${state?.goal?.type.name}/${state?.goal?.reason.name}',
      );
      return;
    }

    final loaded = await _readProfileFromStorage(clientId);

    if (loaded != null) {
      state = loaded;
      print(
        'SWITCH CLIENT DONE -> loaded clientId=${state?.clientId} '
        'goal=${state?.goal?.type.name}/${state?.goal?.reason.name}',
      );
      return;
    }

    state = UserProfile(clientId: clientId);

    print(
      'SWITCH CLIENT DONE -> initialized empty clientId=${state?.clientId} '
      'goal=${state?.goal?.type.name}/${state?.goal?.reason.name}',
    );
  }

  void setGoal(Goal goal) {
    if (state == null) {
      print('SET GOAL FAIL -> state is null');
      return;
    }

    print(
      'SET GOAL -> clientId=${state!.clientId} '
      'type=${goal.type.name} '
      'reason=${goal.reason.name} '
      'targetDate=${goal.targetDate.toIso8601String()} '
      'planMode=${goal.planMode.name}',
    );

    state = state!.copyWith(goal: goal);

    print(
      'SET GOAL DONE -> state.clientId=${state!.clientId} '
      'state.goal=${state!.goal?.type.name}/${state!.goal?.reason.name}',
    );

    _onStateChanged();
  }

  void addMeasurement(Measurement measurement) {
    if (state == null) return;
    state = state!.copyWith(
      measurements: [...state!.measurements, measurement],
      weight: measurement.weight,
    );
    _onStateChanged();
  }

  void setPreferredSplit(TrainingSplit split) {
    if (state == null) return;
    state = state!.copyWith(preferredSplit: split);
    _onStateChanged();
  }

  void setTrainingIntake(TrainingIntake intake) {
    if (state == null) return;
    state = state!.copyWith(trainingIntake: intake);
    _onStateChanged();
  }

  void addCircumference(BodyCircumference data) {
    if (state == null) return;
    state = state!.copyWith(
      circumferences: [...state!.circumferences, data],
    );
    _onStateChanged();
  }

  void updateTrainingMax(String exerciseId, double newTm) {
    if (state == null) return;
    final intake = state!.trainingIntake;
    if (intake == null) return;

    final updated = Map<String, double>.from(intake.oneRMs);
    updated[exerciseId] = newTm;

    state = state!.copyWith(
      trainingIntake: intake.copyWith(oneRMs: updated),
    );
    _onStateChanged();
  }

  Future<void> _onStateChanged() async {
    _updateLegacyPhaseByDate();
    _recalculateMacros();
    await _saveToPrefs();
  }

  void _updateLegacyPhaseByDate() {
    if (state == null || state!.goal == null) return;

    final goal = state!.goal!;
    final now = DateTime.now();

    final ctx = TimeContext(
      now: now,
      targetDate: goal.targetDate,
      mode: _mapGoalPlanModeToPlanMode(goal.planMode),
    );

    final plans = PhasePlannerService.buildPlan(ctx);
    if (plans.isEmpty) return;

    final current = PhaseResolver.resolveCurrentPhase(
      plans: plans,
      date: now,
    );

    final newLegacyPhase = _mapPhaseTypeToGoalPhase(current.phase);

    if (goal.phase != newLegacyPhase) {
      final updatedGoal = goal.copyWith(phase: newLegacyPhase);
      state = state!.copyWith(goal: updatedGoal);
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