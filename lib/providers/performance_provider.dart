import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/exercise_performance.dart';
import 'coach/active_client_provider.dart';

class PerformanceNotifier extends StateNotifier<List<ExercisePerformance>> {
  PerformanceNotifier() : super([]) {
    _load();
  }

  static const String _storageKey = 'exercise_performance_storage';

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);

      if (raw == null || raw.isEmpty) {
        state = [];
        return;
      }

      final decoded = json.decode(raw) as List;
      state = decoded
          .map((e) => _fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      state = [];
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = json.encode(state.map(_toJson).toList());
    await prefs.setString(_storageKey, raw);
  }

  Future<void> addPerformance(ExercisePerformance performance) async {
    state = [...state, performance];
    await _save();
  }

  Future<void> importPerformances(List<ExercisePerformance> items) async {
    if (items.isEmpty) return;
    state = [...state, ...items];
    await _save();
  }

  List<ExercisePerformance> byExercise(String exerciseName) {
    final list = state.where((e) => e.exerciseName == exerciseName).toList();
    list.sort((a, b) => a.date.compareTo(b.date));
    return list;
  }

  ExercisePerformance? personalRecord(String exerciseName) {
    final list = byExercise(exerciseName);
    if (list.isEmpty) return null;

    list.sort((a, b) => b.weight.compareTo(a.weight));
    return list.first;
  }

  Map<String, ExercisePerformance>? firstVsLast(String exerciseName) {
    final list = byExercise(exerciseName);
    if (list.length < 2) return null;

    return {
      'first': list.first,
      'last': list.last,
    };
  }

  List<ExercisePerformance> forClient(String clientId) {
    final list = state.where((e) => e.clientId == clientId).toList();
    list.sort((a, b) => a.date.compareTo(b.date));
    return list;
  }

  List<ExercisePerformance> byExerciseForClient(
    String clientId,
    String exerciseName,
  ) {
    final list = state
        .where(
          (e) =>
              e.clientId == clientId &&
              e.exerciseName.trim().toLowerCase() ==
                  exerciseName.trim().toLowerCase(),
        )
        .toList();

    list.sort((a, b) => a.date.compareTo(b.date));
    return list;
  }

  ExercisePerformance? personalRecordForClient(
    String clientId,
    String exerciseName,
  ) {
    final list = byExerciseForClient(clientId, exerciseName);
    if (list.isEmpty) return null;

    list.sort((a, b) => b.weight.compareTo(a.weight));
    return list.first;
  }

  Map<String, ExercisePerformance>? firstVsLastForClient(
    String clientId,
    String exerciseName,
  ) {
    final list = byExerciseForClient(clientId, exerciseName);
    if (list.length < 2) return null;

    return {
      'first': list.first,
      'last': list.last,
    };
  }

  List<String> exerciseNamesForClient(String clientId) {
    final names = state
        .where((e) => e.clientId == clientId)
        .map((e) => e.exerciseName.trim())
        .where((n) => n.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return names;
  }

  Map<String, dynamic> _toJson(ExercisePerformance p) {
    return {
      'exerciseName': p.exerciseName,
      'date': p.date.toIso8601String(),
      'weight': p.weight,
      'reps': p.reps,
      'clientId': p.clientId,
    };
  }

  ExercisePerformance _fromJson(Map<String, dynamic> json) {
    return ExercisePerformance(
      exerciseName: (json['exerciseName'] as String?) ?? '',
      date: DateTime.parse(
        (json['date'] as String?) ?? DateTime.now().toIso8601String(),
      ),
      weight: (json['weight'] as num?)?.toDouble() ?? 0,
      reps: (json['reps'] as num?)?.toInt() ?? 0,
      clientId: json['clientId'] as String?,
    );
  }
}

final performanceProvider =
    StateNotifierProvider<PerformanceNotifier, List<ExercisePerformance>>(
  (ref) => PerformanceNotifier(),
);

final currentClientPerformancesProvider =
    Provider<List<ExercisePerformance>>((ref) {
  final clientId = ref.watch(activeClientIdProvider).value;
  final all = ref.watch(performanceProvider);

  if (clientId == null || clientId.isEmpty) return [];

  final filtered = all.where((e) => e.clientId == clientId).toList()
    ..sort((a, b) => a.date.compareTo(b.date));

  return filtered;
});

final performancesForClientProvider =
    Provider.family<List<ExercisePerformance>, String>((ref, clientId) {
  final all = ref.watch(performanceProvider);

  final filtered = all.where((e) => e.clientId == clientId).toList()
    ..sort((a, b) => a.date.compareTo(b.date));

  return filtered;
});

final performanceExerciseNamesForClientProvider =
    Provider.family<List<String>, String>((ref, clientId) {
  final items = ref.watch(performancesForClientProvider(clientId));

  final names = items
      .map((e) => e.exerciseName.trim())
      .where((n) => n.isNotEmpty)
      .toSet()
      .toList()
    ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

  return names;
});