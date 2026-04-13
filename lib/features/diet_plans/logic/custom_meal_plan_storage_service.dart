import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/custom_meal_plan_models.dart';

class CustomMealPlanStorageService {
  static const String _dailyTemplatesKey = 'custom_daily_meal_templates_v1';

  static Future<List<DailyMealTemplate>> loadDailyTemplates() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_dailyTemplatesKey);

    if (raw == null || raw.isEmpty) {
      return [];
    }

    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return [];
    }

    return decoded
        .whereType<Map>()
        .map((e) => DailyMealTemplate.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<void> saveDailyTemplates(List<DailyMealTemplate> templates) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      templates.map((e) => e.toJson()).toList(),
    );
    await prefs.setString(_dailyTemplatesKey, encoded);
  }
}