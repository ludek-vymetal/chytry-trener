import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/training/actual_set.dart';
import '../core/training/sessions/exercise_log_entry.dart';
import '../core/training/sessions/training_session.dart';
import '../core/training/training_plan_models.dart';
import '../core/training/training_set.dart';
import '../services/coach/coach_storage_service.dart';
import 'coach/active_client_provider.dart';

class TrainingSessionNotifier extends StateNotifier<List<TrainingSession>> {
  /// [clientId] = aktivní klient. `state` obsahuje jen jeho tréninky
  /// (plus starší záznamy bez clientId, aby nezmizela dřívější historie).
  TrainingSessionNotifier({this.clientId}) : super([]) {
    _load();
  }

  final String? clientId;

  /// Všechny uložené tréninky všech klientů.
  List<TrainingSession> _all = [];

  Future<void> _load() async {
    try {
      final rawItems = await CoachStorageService.loadTrainingSessionsRaw();

      final loaded = rawItems
          .map((e) => _fromJson(Map<String, dynamic>.from(e)))
          .toList();

      final merged = <String, TrainingSession>{};

      for (final session in loaded) {
        final id = _sessionKey(session);
        final existing = merged[id];

        if (existing == null) {
          merged[id] = session;
          continue;
        }

        merged[id] = _pickNewerSession(existing, session);
      }

      _all = merged.values.toList();
      _publish();
    } catch (_) {
      _all = [];
      if (mounted) state = [];
    }
  }

  /// Přepočítá viditelný seznam pro aktivního klienta.
  void _publish() {
    if (!mounted) return;
    state = _visibleFor(clientId);
  }

  List<TrainingSession> _visibleFor(String? id) {
    final visible = _all
        .where((s) => s.clientId == null || s.clientId == id)
        .toList();

    // Pokud je v jednom dni starší (neoznačený) i nový záznam klienta,
    // zobrazíme jen ten klientský.
    final taggedDays = visible
        .where((s) => s.clientId != null)
        .map((s) => _dateKey(s.date))
        .toSet();

    return visible
        .where(
          (s) => s.clientId != null || !taggedDays.contains(_dateKey(s.date)),
        )
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Tréninky konkrétního klienta (např. pro detail klienta v coach módu).
  /// Pro `local_user` zahrnuje i starší záznamy bez clientId.
  List<TrainingSession> sessionsForClient(String id) {
    return _all
        .where(
          (s) => s.clientId == id || (s.clientId == null && id == 'local_user'),
        )
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> _save() async {
    final raw = _all.map(_toJson).toList();
    await CoachStorageService.saveTrainingSessionsRaw(raw);
  }

  /// Nahradí záznam v `_all` (podle klíče) a publikuje.
  Future<void> _put(TrainingSession session) async {
    final key = _sessionKey(session);
    _all = [
      for (final s in _all)
        if (_sessionKey(s) != key) s,
      session,
    ];
    _publish();
    await _save();
  }

  Future<void> reload() async {
    await _load();
  }

  Future<void> importSessions(
    List<TrainingSession> sessions, {
    String? forClientId,
  }) async {
    if (sessions.isEmpty) return;

    final merged = <String, TrainingSession>{
      for (final session in _all) _sessionKey(session): session,
    };

    for (final incoming in sessions) {
      final session = forClientId == null
          ? incoming
          : incoming.copyWith(clientId: forClientId);
      final id = _sessionKey(session);
      final existing = merged[id];

      if (existing == null) {
        merged[id] = session;
        continue;
      }

      merged[id] = _pickNewerSession(existing, session);
    }

    _all = merged.values.toList();
    _publish();
    await _save();
  }

  TrainingSession? getByDate(DateTime date) {
    for (final s in state) {
      if (_sameDay(s.date, date)) return s;
    }
    return null;
  }

  Future<void> setCompletedIfAllLogged({
    required DateTime date,
    required TrainingSession baseSession,
  }) async {
    final existing = getByDate(date);

    if (existing == null) {
      await _put(
        baseSession.copyWith(
          version: 1,
          updatedAt: DateTime.now(),
          clientId: clientId,
        ),
      );
      return;
    }

    final plannedKeys = baseSession.dayPlan.exercises
        .map((e) => e.exerciseId ?? e.name)
        .toSet();

    final loggedKeys = existing.entries.map((e) => e.exerciseKey).toSet();

    final allLogged = plannedKeys.isEmpty
        ? false
        : plannedKeys.every((k) => loggedKeys.contains(k));

    await _put(
      existing.copyWith(
        completed: allLogged,
        updatedAt: DateTime.now(),
        version: existing.version + 1,
      ),
    );
  }

  Future<void> upsertEntry({
    required DateTime date,
    required TrainingSession baseSession,
    required ExerciseLogEntry entry,
  }) async {
    final existing = getByDate(date);

    if (existing == null) {
      await _put(
        baseSession.copyWith(
          entries: [entry],
          updatedAt: DateTime.now(),
          version: 1,
          clientId: clientId,
        ),
      );
      return;
    }

    final updatedEntries = [
      for (final e in existing.entries)
        if (e.exerciseKey != entry.exerciseKey) e,
      entry,
    ];

    await _put(
      existing.copyWith(
        entries: updatedEntries,
        updatedAt: DateTime.now(),
        version: existing.version + 1,
      ),
    );
  }

  TrainingSession _pickNewerSession(
    TrainingSession a,
    TrainingSession b,
  ) {
    if (b.version > a.version) return b;
    if (a.version > b.version) return a;

    if (b.updatedAt.isAfter(a.updatedAt)) return b;
    return a;
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _dateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Unikátní klíč záznamu. Starší záznamy (bez clientId) si drží původní
  /// tvar "YYYY-MM-DD", aby sedělo slučování s daty v cloudu.
  String _sessionKey(TrainingSession s) {
    final day = _dateKey(s.date);
    final cid = s.clientId;
    return cid == null ? day : '$cid|$day';
  }

  Map<String, dynamic> _toJson(TrainingSession s) {
    return {
      'sessionId': _sessionKey(s),
      'clientId': s.clientId,
      'date': s.date.toIso8601String(),
      'completed': s.completed,
      'updatedAt': s.updatedAt.toIso8601String(),
      'version': s.version,
      'dayPlan': {
        'dayLabel': s.dayPlan.dayLabel,
        'focus': s.dayPlan.focus,
        'exercises': s.dayPlan.exercises
            .map(
              (e) => {
                'name': e.name,
                'exerciseId': e.exerciseId,
                'sets': e.sets,
                'reps': e.reps,
                'rir': e.rir,
                'note': e.note,
                'intensityPercent': e.intensityPercent,
                'weightKg': e.weightKg,
                'plannedSets': e.plannedSets
                    .map((ps) => ps.toJson())
                    .toList(),
              },
            )
            .toList(),
      },
      'entries': s.entries
          .map(
            (entry) => {
              'exerciseKey': entry.exerciseKey,
              'plannedSets': entry.plannedSets.map((ps) => ps.toJson()).toList(),
              'actualSets': entry.actualSets
                  .map(
                    (as) => {
                      'weightKg': as.weightKg,
                      'reps': as.reps,
                      'rpe': as.rpe,
                    },
                  )
                  .toList(),
            },
          )
          .toList(),
    };
  }

  TrainingSession _fromJson(Map<String, dynamic> json) {
    final rawDayPlan = json['dayPlan'] as Map?;
    final rawExercises = (rawDayPlan?['exercises'] as List?) ?? const [];
    final rawEntries = (json['entries'] as List?) ?? const [];

    final dayPlan = TrainingDayPlan(
      dayLabel: (rawDayPlan?['dayLabel'] as String?) ?? 'Den',
      focus: (rawDayPlan?['focus'] as String?) ?? '',
      exercises: rawExercises.map((e) {
        final map = Map<String, dynamic>.from(e as Map);
        final rawPlannedSets = (map['plannedSets'] as List?) ?? const [];

        return PlannedExercise(
          name: (map['name'] as String?) ?? '',
          sets: (map['sets'] as String?) ?? '',
          reps: (map['reps'] as String?) ?? '',
          rir: (map['rir'] as String?) ?? '',
          note: map['note'] as String?,
          exerciseId: map['exerciseId'] as String?,
          intensityPercent: (map['intensityPercent'] as num?)?.toDouble(),
          weightKg: (map['weightKg'] as num?)?.toDouble(),
          plannedSets: rawPlannedSets
              .map(
                (ps) => PlannedSet.fromJson(
                  Map<String, dynamic>.from(ps as Map),
                ),
              )
              .toList(),
        );
      }).toList(),
    );

    final entries = rawEntries.map((e) {
      final map = Map<String, dynamic>.from(e as Map);
      final rawPlannedSets = (map['plannedSets'] as List?) ?? const [];
      final rawActualSets = (map['actualSets'] as List?) ?? const [];

      return ExerciseLogEntry(
        exerciseKey: (map['exerciseKey'] as String?) ?? '',
        plannedSets: rawPlannedSets
            .map(
              (ps) => PlannedSet.fromJson(
                Map<String, dynamic>.from(ps as Map),
              ),
            )
            .toList(),
        actualSets: rawActualSets.map((as) {
          final actualMap = Map<String, dynamic>.from(as as Map);
          return ActualSet(
            weightKg: (actualMap['weightKg'] as num?)?.toDouble(),
            reps: (actualMap['reps'] as num?)?.toInt() ?? 0,
            rpe: (actualMap['rpe'] as num?)?.toDouble(),
          );
        }).toList(),
      );
    }).toList();

    return TrainingSession(
      date: DateTime.parse(
        (json['date'] as String?) ?? DateTime.now().toIso8601String(),
      ),
      dayPlan: dayPlan,
      entries: entries,
      completed: (json['completed'] as bool?) ?? false,
      updatedAt: DateTime.tryParse(
            (json['updatedAt'] as String?) ?? '',
          ) ??
          DateTime.parse(
            (json['date'] as String?) ?? DateTime.now().toIso8601String(),
          ),
      version: (json['version'] as num?)?.toInt() ?? 1,
      clientId: json['clientId'] as String?,
    );
  }
}

final trainingSessionProvider =
    StateNotifierProvider<TrainingSessionNotifier, List<TrainingSession>>(
  (ref) {
    // Při změně aktivního klienta se notifier vytvoří znovu a načte
    // jen tréninky daného klienta.
    final clientId = ref.watch(activeClientIdProvider).valueOrNull;
    return TrainingSessionNotifier(clientId: clientId);
  },
);