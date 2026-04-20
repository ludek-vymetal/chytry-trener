import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/diet_plans/models/saved_meal_plan.dart';
import 'coach/coach_storage_service.dart';

class LocalStorageService {
  static const _foodBankKey = 'food_bank_v1';
  static const _clientExportFolderPathKey = 'client_export_folder_path_v1';
  static const _savedMealPlansKey = 'saved_meal_plans_v1';
  static const _customFoodCombosKey = 'custom_food_combos_v1';

  static String _scopedExportFolderKey() {
    final uid = FirebaseAuth.instance.currentUser?.uid.trim();
    if (uid == null || uid.isEmpty) {
      return _clientExportFolderPathKey;
    }
    return 'coach_${uid}_$_clientExportFolderPathKey';
  }

  static Future<void> saveFoodBank(List<Map<String, dynamic>> meals) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(meals);
    await prefs.setString(_foodBankKey, jsonStr);
  }

  static Future<List<Map<String, dynamic>>?> loadFoodBank() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_foodBankKey);
    if (jsonStr == null || jsonStr.isEmpty) return null;

    final decoded = jsonDecode(jsonStr);
    if (decoded is! List) return null;

    return decoded
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  static Future<void> saveDailyHistory(Map<String, dynamic> historyJson) async {
    final items = historyJson.entries.map((entry) {
      final intakeJson = entry.value is Map<String, dynamic>
          ? Map<String, dynamic>.from(entry.value as Map<String, dynamic>)
          : <String, dynamic>{};

      return <String, dynamic>{
        'dateKey': entry.key,
        'updatedAt': DateTime.now().toIso8601String(),
        'version': 1,
        ...intakeJson,
      };
    }).toList();

    await CoachStorageService.saveDailyHistoryRaw(items);
  }

  static Future<Map<String, dynamic>?> loadDailyHistory() async {
    final items = await CoachStorageService.loadDailyHistoryRaw();
    if (items.isEmpty) {
      return null;
    }

    final result = <String, dynamic>{};

    for (final item in items) {
      final dateKey = (item['dateKey'] ?? '').toString().trim();
      if (dateKey.isEmpty) continue;

      final map = Map<String, dynamic>.from(item)
        ..remove('dateKey')
        ..remove('updatedAt')
        ..remove('version');

      result[dateKey] = map;
    }

    return result.isEmpty ? null : result;
  }

  static Future<void> saveClientExportFolderPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    final normalized = path.trim();

    if (normalized.isEmpty) {
      await prefs.remove(_scopedExportFolderKey());
      return;
    }

    await prefs.setString(_scopedExportFolderKey(), normalized);
  }

  static Future<String?> loadClientExportFolderPath() async {
    final prefs = await SharedPreferences.getInstance();

    final scopedPath = prefs.getString(_scopedExportFolderKey())?.trim();
    if (scopedPath != null && scopedPath.isNotEmpty) {
      return scopedPath;
    }

    final legacyPath = prefs.getString(_clientExportFolderPathKey)?.trim();
    if (legacyPath != null && legacyPath.isNotEmpty) {
      return legacyPath;
    }

    return null;
  }

  static Future<void> clearClientExportFolderPath() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_scopedExportFolderKey());
  }

  static Future<List<SavedMealPlan>> loadSavedMealPlans() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_savedMealPlansKey);

    if (jsonStr == null || jsonStr.isEmpty) {
      return [];
    }

    final decoded = jsonDecode(jsonStr);
    if (decoded is! List) {
      return [];
    }

    return decoded
        .whereType<Map>()
        .map((e) => SavedMealPlan.fromJson(Map<String, dynamic>.from(e)))
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  static Future<void> saveSavedMealPlans(List<SavedMealPlan> plans) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(plans.map((e) => e.toJson()).toList());
    await prefs.setString(_savedMealPlansKey, jsonStr);
  }

  static Future<List<Map<String, dynamic>>> loadCustomFoodCombos() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_customFoodCombosKey);

    if (jsonStr == null || jsonStr.isEmpty) {
      return [];
    }

    final decoded = jsonDecode(jsonStr);
    if (decoded is! List) {
      return [];
    }

    return decoded
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  static Future<void> saveCustomFoodCombos(
    List<Map<String, dynamic>> combos,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(combos);
    await prefs.setString(_customFoodCombosKey, jsonStr);
  }
}