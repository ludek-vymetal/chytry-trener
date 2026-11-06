import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/training/intake/training_intake.dart';
import '../core/training/training_split.dart';
import '../models/body_circumference.dart';
import '../models/body_composition.dart';
import '../models/coach/coach_inbody_entry.dart';
import '../models/goal.dart';
import '../models/measurement.dart';
import '../models/user_profile.dart';
import '../services/coach/coach_storage_service.dart';
import '../services/macro_service.dart';
import '../services/coach/extra_backup_service.dart';

class UserProfileNotifier extends StateNotifier<UserProfile?> {
  UserProfileNotifier() : super(null) {
    unawaited(_loadFromPrefs());
  }

  static const String _legacyStorageKey = 'user_profile_storage';

  /// Čistý nový profil (po přepnutí do uživatelského režimu): při ukládání se NESLUČUJE
  /// se starým profilem uloženým v zařízení – jinak by se nový uživatel jmenoval po
  /// někom, kdo zařízení používal dřív (4.11.2026: „Dobré ráno, Lukáš“).
  bool _cistyProfil = false;

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
      await _reviewAfterLoad();
      unawaited(syncBodyCompositionFromInbody());

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

      final existingStored =
          _cistyProfil ? null : await _readProfileFromStorage(currentState.clientId);
      final safeProfile = _mergeProfiles(
        base: existingStored,
        incoming: currentState,
      );

      final jsonString = json.encode(safeProfile.toJson());
      await prefs.setString(key, jsonString);
      // Čas změny – podle něj se při online coachingu pozná novější profil.
      await prefs.setString(
        'profile_updated_at_${safeProfile.clientId ?? ''}',
        DateTime.now().toUtc().toIso8601String(),
      );
      ExtraBackupService.schedulePush();

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
      dietPreference: incoming.dietPreference ?? base.dietPreference,
      budgetMeals: incoming.budgetMeals ?? base.budgetMeals,
      hollywoodShootDate:
          incoming.hollywoodShootDate ?? base.hollywoodShootDate,
      bikiniMeetDate: incoming.bikiniMeetDate ?? base.bikiniMeetDate,
      bodyComposition: _newerBodyComposition(
        incoming.bodyComposition,
        base.bodyComposition,
      ),
      energyAdjustment: incoming.energyAdjustment ?? base.energyAdjustment,
    );
  }

  static BodyComposition? _newerBodyComposition(
    BodyComposition? a,
    BodyComposition? b,
  ) {
    if (a == null) return b;
    if (b == null) return a;
    return a.date.isBefore(b.date) ? b : a;
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

  void setFirstName(String firstName) {
    final current = state ?? const UserProfile();
    state = current.copyWith(firstName: firstName.trim());
    unawaited(_onStateChanged());
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
      _cistyProfil = true;

      _log(
        'SWITCH CLIENT DONE -> detached clean profile '
        'clientId=${state?.clientId} '
        'goal=${state?.goal?.type.name}/${state?.goal?.reason.name}',
      );
      return;
    }

    _cistyProfil = false;
    final loaded = await _readProfileFromStorage(clientId);

    if (loaded != null) {
      state = loaded;
      await _reviewAfterLoad();
      unawaited(syncBodyCompositionFromInbody(clientId));

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
    // Pozn.: dřív se tu goal.phase přepisovala podle kalendáře, čímž se
    // ztrácela volba uživatele (nabrat / vyrýsovat / udržet). Plánovač
    // fází teď tuto volbu čte přímo, takže se už nepřepisuje.
    _recalculateMacros();
    await _saveToPrefs();
  }

  /// Týdenní kontrola vážení: když váha jde jinak, než plán fáze
  /// předpokládá, posune se cíl kalorií (MacroService.weeklyReview).
  /// Vrací true, když se profil změnil.
  bool _recalculateMacros() {
    final p = state;
    if (p == null) return false;
    try {
      final next = MacroService.weeklyReview(p);
      if (next == null) return false;
      state = p.copyWith(energyAdjustment: next);
      _log(
        'ENERGY ADJUSTMENT -> ${next.kcal} kcal '
        '(actual=${next.actualKgPerWeek} expected=${next.expectedKgPerWeek})',
      );
      return true;
    } catch (e) {
      _log('ENERGY ADJUSTMENT ERROR -> $e');
      return false;
    }
  }

  /// Kontrola vážení po načtení profilu – uloží se jen při změně (aby se
  /// zbytečně neměnil čas úpravy profilu pro online coaching).
  Future<void> _reviewAfterLoad() async {
    if (_recalculateMacros()) await _saveToPrefs();
  }

  // ==========================================================
  // InBody → profil (složení těla, váha)
  // ==========================================================

  /// Propíše nejnovější InBody klienta (záznamy trenéra; u online klienta
  /// stažené z cloudu) do jeho profilu: složení těla pro výpočet bazálu
  /// a bílkovin, hmotnosti z měření do historie vážení a aktuální váhu,
  /// když je InBody nejnovější vážení. Funguje i pro klienta, který zrovna
  /// není otevřený (upraví jeho uložený profil).
  ///
  /// [toActive] = měření patří otevřenému profilu, i když se jeho clientId
  /// liší (vlastní aplikace člena SPAL / online klienta).
  Future<void> syncBodyCompositionFromInbody([
    String? clientId,
    bool toActive = false,
  ]) async {
    final id = (clientId ?? state?.clientId)?.trim();
    if (id == null || id.isEmpty) return;

    final List<CoachInbodyEntry> entries;
    try {
      entries = (await CoachStorageService.loadInbodyAll())
          .where((e) => e.clientId == id && !e.isDeleted && e.weightKg > 0)
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    } catch (e) {
      _log('INBODY SYNC ERROR -> $e');
      return;
    }
    if (entries.isEmpty) return;

    final active = state;
    if (active != null && (toActive || active.clientId == id)) {
      final updated = applyInbodyEntries(active, entries);
      if (updated == null) return;
      state = updated;
      await _onStateChanged();
      _log('INBODY SYNC -> active client $id updated');
      return;
    }

    final stored = await _readProfileFromStorage(id);
    if (stored == null) return;
    final updated = applyInbodyEntries(stored, entries);
    if (updated == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKeyForClient(id),
      json.encode(updated.toJson()),
    );
    await prefs.setString(
      'profile_updated_at_$id',
      DateTime.now().toUtc().toIso8601String(),
    );
    ExtraBackupService.schedulePush();
    _log('INBODY SYNC -> stored client $id updated');
  }

  /// Vrátí profil doplněný o InBody měření, nebo `null`, když není co měnit.
  /// [entries] = měření klienta, nejnovější první.
  static UserProfile? applyInbodyEntries(
    UserProfile profile,
    List<CoachInbodyEntry> entries,
  ) {
    if (entries.isEmpty) return null;
    var changed = false;

    // 1) složení těla z nejnovějšího měření s beztukovou hmotou
    BodyComposition? comp = profile.bodyComposition;
    for (final e in entries) {
      if (e.leanMassKg <= 0) continue;
      final candidate = BodyComposition(
        date: e.date,
        weightKg: e.weightKg,
        leanMassKg: e.leanMassKg,
        bodyFatPercent: e.bodyFatPercent,
        bmrKcal: e.bmr,
        smmKg: e.smmKg,
      );
      if (comp == null ||
          comp.date.isBefore(candidate.date) ||
          (comp.date.isAtSameMomentAs(candidate.date) &&
              (comp.leanMassKg != candidate.leanMassKg ||
                  comp.bmrKcal != candidate.bmrKcal))) {
        comp = candidate;
        changed = true;
      }
      break;
    }

    // 2) hmotnosti z InBody do historie vážení (1 záznam za den)
    String day(DateTime d) => '${d.year}-${d.month}-${d.day}';
    final days = profile.measurements.map((m) => day(m.date)).toSet();
    final measurements = [...profile.measurements];
    for (final e in entries) {
      if (days.add(day(e.date))) {
        measurements.add(Measurement(date: e.date, weight: e.weightKg));
        changed = true;
      }
    }
    measurements.sort((a, b) => a.date.compareTo(b.date));

    // 3) aktuální váha = nejnovější vážení
    var weight = profile.weight;
    if (measurements.isNotEmpty) {
      final last = measurements.last.weight;
      if (last > 0 && (last - weight).abs() > 0.001) {
        weight = last;
        changed = true;
      }
    }

    if (!changed) return null;
    return profile.copyWith(
      bodyComposition: comp,
      measurements: measurements,
      weight: weight,
    );
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