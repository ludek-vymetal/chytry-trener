import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/training/actual_set.dart';
import '../core/training/sessions/exercise_log_entry.dart';
import '../core/training/sessions/training_session.dart';
import '../core/training/training_plan_models.dart';
import '../core/training/training_set.dart';
import '../services/coach/coach_storage_service.dart';

class TrainingSessionNotifier extends StateNotifier<List<TrainingSession>> {
  TrainingSessionNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    try {
      final rawItems = await CoachStorageService.loadTrainingSessionsRaw();

      final loaded = rawItems
          .map((e) => _fromJson(Map<String, dynamic>.from(e)))
          .toList();

      final merged = <String, TrainingSession>{};

      for (final session in loaded) {
        final id = _sessionId(session.date);
        final existing = merged[id];

        if (existing == null) {
          merged[id] = session;
          continue;
        }

        merged[id] = _pickNewerSession(existing, session);
      }

      final sessions = merged.values.toList()
        ..sort((a, b) => b.date.compareTo(a.date));

      state = sessions;
    } catch (_) {
      state = [];
    }
  }

  Future<void> _save() async {
    final raw = state.map(_toJson).toList();
    await CoachStorageService.saveTrainingSessionsRaw(raw);
  }

  Future<void> reload() async {
    await _load();
  }

  Future<void> importSessions(List<TrainingSession> sessions) async {
    if (sessions.isEmpty) return;

    final merged = <String, TrainingSession>{
      for (final session in state) _sessionId(session.date): session,
    };

    for (final session in sessions) {
      final id = _sessionId(session.date);
      final existing = merged[id];

      if (existing == null) {
        merged[id] = session;
        continue;
      }

      merged[id] = _pickNewerSession(existing, session);
    }

    state = merged.values.toList()..sort((a, b) => b.date.compareTo(a.date));
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
    final idx = state.indexWhere((s) => _sameDay(s.date, date));

    if (idx == -1) {
      final newSession = baseSession.copyWith(
        version: 1,
        updatedAt: DateTime.now(),
      );

      state = [...state, newSession]..sort((a, b) => b.date.compareTo(a.date));
      await _save();
      return;
    }

    final existing = state[idx];

    final plannedKeys = baseSession.dayPlan.exercises
        .map((e) => e.exerciseId ?? e.name)
        .toSet();

    final loggedKeys = existing.entries.map((e) => e.exerciseKey).toSet();

    final allLogged = plannedKeys.isEmpty
        ? false
        : plannedKeys.every((k) => loggedKeys.contains(k));

    final updated = existing.copyWith(
      completed: allLogged,
      updatedAt: DateTime.now(),
      version: existing.version + 1,
    );

    final newState = [...state];
    newState[idx] = updated;
    newState.sort((a, b) => b.date.compareTo(a.date));
    state = newState;
    await _save();
  }

  Future<void> upsertEntry({
    required DateTime date,
    required TrainingSession baseSession,
    required ExerciseLogEntry entry,
  }) async {
    final idx = state.indexWhere((s) => _sameDay(s.date, date));

    if (idx == -1) {
      final created = baseSession.copyWith(
        entries: [entry],
        updatedAt: DateTime.now(),
        version: 1,
      );

      state = [...state, created]..sort((a, b) => b.date.compareTo(a.date));
      await _save();
      return;
    }

    final existing = state[idx];
    final updatedEntries = [
      for (final e in existing.entries)
        if (e.exerciseKey != entry.exerciseKey) e,
      entry,
    ];

    final updated = existing.copyWith(
      entries: updatedEntries,
      updatedAt: DateTime.now(),
      version: existing.version + 1,
    );

    final newState = [...state];
    newState[idx] = updated;
    newState.sort((a, b) => b.date.compareTo(a.date));
    state = newState;
    await _save();
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

  String _sessionId(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Map<String, dynamic> _toJson(TrainingSession s) {
    return {
      'sessionId': _sessionId(s.date),
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
    );
  }
}

final trainingSessionProvider =
    StateNotifierProvider<TrainingSessionNotifier, List<TrainingSession>>(
  (ref) => TrainingSessionNotifier(),
);