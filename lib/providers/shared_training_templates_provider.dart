import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/custom_training_plan.dart';
import '../models/shared_training_template.dart';
import 'coach/custom_training_plan_provider.dart';

class SharedTrainingTemplatesNotifier
    extends StateNotifier<List<SharedTrainingTemplate>> {
  SharedTrainingTemplatesNotifier() : super([]) {
    _loadFromPrefs();
  }

  static const String _storageKey = 'shared_training_templates_storage';

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
            (e) => SharedTrainingTemplate.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
    } catch (e) {
      print('Chyba při načítání sdílených šablon: $e');
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
      print('Chyba při ukládání sdílených šablon: $e');
    }
  }

  Future<void> addTemplateFromPlan(CustomTrainingPlan plan) async {
    final template = SharedTrainingTemplate.fromPlan(plan);

    final alreadyExists = state.any(
      (t) => t.name.trim().toLowerCase() == template.name.trim().toLowerCase(),
    );

    if (alreadyExists) {
      return;
    }

    state = [...state, template];
    await _saveToPrefs();
  }

  Future<void> deleteTemplate(String templateId) async {
    state = state.where((t) => t.id != templateId).toList();
    await _saveToPrefs();
  }

  Future<void> renameTemplate({
    required String templateId,
    required String newName,
  }) async {
    state = state.map((t) {
      if (t.id != templateId) return t;
      return t.copyWith(
        name: newName,
        updatedAt: DateTime.now(),
      );
    }).toList();

    await _saveToPrefs();
  }

  Future<void> createPlanFromTemplate({
    required String clientId,
    required SharedTrainingTemplate template,
    required WidgetRef ref,
  }) async {
    final customPlansNotifier = ref.read(customTrainingPlanProvider.notifier);

    final now = DateTime.now();
    final planId = 'plan_${now.microsecondsSinceEpoch}';

    final newPlan = CustomTrainingPlan(
      id: planId,
      clientId: clientId,
      name: template.name,
      days: template.days
          .map(
            (d) => d.copyWith(
              exercises: d.exercises.map((e) => e.copyWith()).toList(),
            ),
          )
          .toList(),
      createdAt: now,
      updatedAt: now,
      isActive: false,
    );

    await customPlansNotifier.addImportedPlan(newPlan);
  }
}

final sharedTrainingTemplatesProvider = StateNotifierProvider<
    SharedTrainingTemplatesNotifier, List<SharedTrainingTemplate>>(
  (ref) => SharedTrainingTemplatesNotifier(),
);