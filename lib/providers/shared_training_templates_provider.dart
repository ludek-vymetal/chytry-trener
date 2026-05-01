import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/custom_training_plan.dart';
import '../models/shared_training_template.dart';
import '../services/coach/coach_storage_service.dart';
import 'coach/custom_training_plan_provider.dart';

class SharedTrainingTemplatesNotifier
    extends StateNotifier<List<SharedTrainingTemplate>> {
  SharedTrainingTemplatesNotifier() : super([]) {
    _load();
  }

  static const String _oldStorageKey = 'shared_training_templates_storage';

  Future<void> _load() async {
    try {
      final cloudReadyTemplates =
          await CoachStorageService.loadSharedTrainingTemplates();

      if (cloudReadyTemplates.isNotEmpty) {
        state = cloudReadyTemplates;
        return;
      }

      final migrated = await _loadOldTemplatesFromPrefs();

      if (migrated.isNotEmpty) {
        state = migrated;
        await CoachStorageService.saveSharedTrainingTemplates(state);
        await CoachStorageService.pushAllLocalSnapshotsToCloud();
        return;
      }

      state = [];
    } catch (e) {
      print('Chyba při načítání sdílených šablon: $e');
      state = [];
    }
  }

  Future<List<SharedTrainingTemplate>> _loadOldTemplatesFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_oldStorageKey);

      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final raw = json.decode(jsonString) as List;

      return raw
          .map(
            (e) => SharedTrainingTemplate.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
    } catch (e) {
      print('Chyba při migraci starých sdílených šablon: $e');
      return [];
    }
  }

  Future<void> _save() async {
    try {
      await CoachStorageService.saveSharedTrainingTemplates(state);
      await CoachStorageService.pushAllLocalSnapshotsToCloud();
    } catch (e) {
      print('Chyba při ukládání sdílených šablon: $e');
    }
  }

  Future<void> addTemplateFromPlan(CustomTrainingPlan plan) async {
    final template = SharedTrainingTemplate.fromPlan(plan);

    final alreadyExists = state.any(
      (t) => t.name.trim().toLowerCase() == template.name.trim().toLowerCase(),
    );

    if (alreadyExists) return;

    state = [...state, template];
    await _save();
  }

  Future<void> deleteTemplate(String templateId) async {
    state = state.where((t) => t.id != templateId).toList();
    await _save();
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

    await _save();
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
      description: template.description,
      category: template.category,
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
      type: CustomTrainingPlanType.standard,
      meetDate: null,
      maxes: null,
      overrideDayIndex: null,
      pendingDayIndex: null,
    );

    await customPlansNotifier.addImportedPlan(newPlan);
    await CoachStorageService.pushAllLocalSnapshotsToCloud();
  }
}

final sharedTrainingTemplatesProvider = StateNotifierProvider<
    SharedTrainingTemplatesNotifier, List<SharedTrainingTemplate>>(
  (ref) => SharedTrainingTemplatesNotifier(),
);