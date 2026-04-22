import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/custom_training_plan.dart';

class CustomTrainingPlanNotifier
    extends StateNotifier<List<CustomTrainingPlan>> {
  CustomTrainingPlanNotifier() : super([]) {
    _loadFromPrefs();
  }

  static const String _storageKey = 'custom_training_plans_storage';

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      if (jsonString == null || jsonString.isEmpty) {
        state = [];
        return;
      }

      final raw = json.decode(jsonString) as List;
      state = raw
          .map(
            (e) => CustomTrainingPlan.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
    } catch (e) {
      print('Chyba při načítání custom plánů: $e');
      state = [];
    }
  }

  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(
        state.map((e) => e.toJson()).toList(),
      );
      await prefs.setString(_storageKey, jsonString);
    } catch (e) {
      print('Chyba při ukládání custom plánů: $e');
    }
  }

  Future<void> saveExternally() async {
    await _saveToPrefs();
  }

  List<CustomTrainingPlan> getPlansForClient(String clientId) {
    return state.where((p) => p.clientId == clientId).toList();
  }

  CustomTrainingPlan? getActivePlanForClient(String clientId) {
    for (final p in state) {
      if (p.clientId == clientId && p.isActive) {
        return p;
      }
    }
    return null;
  }

  Future<void> importPlans(List<CustomTrainingPlan> plans) async {
    if (plans.isEmpty) return;
    state = [...state, ...plans];
    await _saveToPrefs();
  }

  Future<void> addImportedPlan(CustomTrainingPlan plan) async {
    state = [...state, plan];
    await _saveToPrefs();
  }

  Future<void> createPlan({
    required String clientId,
    required String name,
  }) async {
    final now = DateTime.now();

    final plan = CustomTrainingPlan(
      id: 'plan_${now.microsecondsSinceEpoch}',
      clientId: clientId,
      name: name,
      days: const [],
      createdAt: now,
      updatedAt: now,
      isActive: false,
    );

    state = [...state, plan];
    await _saveToPrefs();
  }

  Future<void> deletePlan(String planId) async {
    state = state.where((p) => p.id != planId).toList();
    await _saveToPrefs();
  }

  Future<void> deletePlansForClient(String clientId) async {
    state = state.where((p) => p.clientId != clientId).toList();
    await _saveToPrefs();
  }

  Future<void> renamePlan({
    required String planId,
    required String newName,
  }) async {
    state = state.map((p) {
      if (p.id != planId) return p;
      return p.copyWith(
        name: newName,
        updatedAt: DateTime.now(),
      );
    }).toList();

    await _saveToPrefs();
  }

  Future<void> setActivePlan({
    required String clientId,
    required String planId,
  }) async {
    state = state.map((p) {
      if (p.clientId != clientId) return p;
      return p.copyWith(
        isActive: p.id == planId,
        updatedAt: DateTime.now(),
      );
    }).toList();

    await _saveToPrefs();
  }

  Future<void> addDay({
    required String planId,
    required String dayName,
  }) async {
    state = state.map((p) {
      if (p.id != planId) return p;

      final updatedDays = [
        ...p.days,
        CustomTrainingDay(
          name: dayName,
          exercises: const [],
        ),
      ];

      return p.copyWith(
        days: updatedDays,
        updatedAt: DateTime.now(),
      );
    }).toList();

    await _saveToPrefs();
  }

  Future<void> removeDay({
    required String planId,
    required int dayIndex,
  }) async {
    state = state.map((p) {
      if (p.id != planId) return p;
      if (dayIndex < 0 || dayIndex >= p.days.length) return p;

      final updatedDays = [...p.days]..removeAt(dayIndex);

      return p.copyWith(
        days: updatedDays,
        updatedAt: DateTime.now(),
      );
    }).toList();

    await _saveToPrefs();
  }

  Future<void> addExerciseToDay({
    required String planId,
    required int dayIndex,
    required CustomTrainingExercise exercise,
  }) async {
    state = state.map((p) {
      if (p.id != planId) return p;
      if (dayIndex < 0 || dayIndex >= p.days.length) return p;

      final updatedDays = [...p.days];
      final day = updatedDays[dayIndex];

      updatedDays[dayIndex] = day.copyWith(
        exercises: [...day.exercises, exercise],
      );

      return p.copyWith(
        days: updatedDays,
        updatedAt: DateTime.now(),
      );
    }).toList();

    await _saveToPrefs();
  }

  Future<void> updateExerciseInDay({
    required String planId,
    required int dayIndex,
    required int exerciseIndex,
    required CustomTrainingExercise exercise,
  }) async {
    state = state.map((p) {
      if (p.id != planId) return p;
      if (dayIndex < 0 || dayIndex >= p.days.length) return p;

      final updatedDays = [...p.days];
      final day = updatedDays[dayIndex];

      if (exerciseIndex < 0 || exerciseIndex >= day.exercises.length) {
        return p;
      }

      final updatedExercises = [...day.exercises];
      updatedExercises[exerciseIndex] = exercise;

      updatedDays[dayIndex] = day.copyWith(
        exercises: updatedExercises,
      );

      return p.copyWith(
        days: updatedDays,
        updatedAt: DateTime.now(),
      );
    }).toList();

    await _saveToPrefs();
  }

  Future<void> removeExerciseFromDay({
    required String planId,
    required int dayIndex,
    required int exerciseIndex,
  }) async {
    state = state.map((p) {
      if (p.id != planId) return p;
      if (dayIndex < 0 || dayIndex >= p.days.length) return p;

      final updatedDays = [...p.days];
      final day = updatedDays[dayIndex];

      if (exerciseIndex < 0 || exerciseIndex >= day.exercises.length) {
        return p;
      }

      final updatedExercises = [...day.exercises]..removeAt(exerciseIndex);

      updatedDays[dayIndex] = day.copyWith(
        exercises: updatedExercises,
      );

      return p.copyWith(
        days: updatedDays,
        updatedAt: DateTime.now(),
      );
    }).toList();

    await _saveToPrefs();
  }

  Future<void> duplicatePlan({
    required String sourcePlanId,
    required String newName,
  }) async {
    CustomTrainingPlan? source;

    for (final p in state) {
      if (p.id == sourcePlanId) {
        source = p;
        break;
      }
    }

    if (source == null) return;

    final now = DateTime.now();

    final duplicated = source.copyWith(
      id: 'plan_${now.microsecondsSinceEpoch}',
      name: newName,
      isActive: false,
      createdAt: now,
      updatedAt: now,
    );

    state = [...state, duplicated];
    await _saveToPrefs();
  }

  Future<void> updateLastUsedWeightForActivePlan({
    required String clientId,
    required String dayName,
    required String exerciseKey,
    required double weightKg,
  }) async {
    final normalizedDayName = dayName.trim().toLowerCase();
    final normalizedExerciseKey = exerciseKey.trim().toLowerCase();

    bool changed = false;

    final updatedState = state.map((plan) {
      if (plan.clientId != clientId || !plan.isActive) {
        return plan;
      }

      bool planChanged = false;
      final updatedDays = [...plan.days];

      for (int dayIndex = 0; dayIndex < updatedDays.length; dayIndex++) {
        final day = updatedDays[dayIndex];

        if (day.name.trim().toLowerCase() != normalizedDayName) {
          continue;
        }

        final updatedExercises = [...day.exercises];

        for (int exerciseIndex = 0;
            exerciseIndex < updatedExercises.length;
            exerciseIndex++) {
          final exercise = updatedExercises[exerciseIndex];
          final currentKey =
              (exercise.exerciseId ?? exercise.customName).trim().toLowerCase();

          if (currentKey != normalizedExerciseKey) {
            continue;
          }

          updatedExercises[exerciseIndex] = exercise.copyWith(
            weightKg: weightKg,
          );

          updatedDays[dayIndex] = day.copyWith(
            exercises: updatedExercises,
          );

          changed = true;
          planChanged = true;
          break;
        }

        if (planChanged) {
          break;
        }
      }

      if (!planChanged) {
        return plan;
      }

      return plan.copyWith(
        days: updatedDays,
        updatedAt: DateTime.now(),
      );
    }).toList();

    if (!changed) return;

    state = updatedState;
    await _saveToPrefs();
  }
}

final customTrainingPlanProvider =
    StateNotifierProvider<CustomTrainingPlanNotifier, List<CustomTrainingPlan>>(
  (ref) => CustomTrainingPlanNotifier(),
);