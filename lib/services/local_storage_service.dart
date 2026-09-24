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

  // ==========================================================
  // Historie jídla (zvlášť pro každého klienta)
  // ==========================================================
  //
  // Každý uložený den nese `clientId` (null = starší záznam z doby před
  // rozdělením podle klientů) a `entryKey` = "<clientId>|<datum>", podle
  // kterého se záznamy slučují s cloudem. Starší záznamy mají entryKey
  // rovný datu, takže se v cloudu nic nezdvojí.

  static const _metaKeys = {'dateKey', 'updatedAt', 'version', 'clientId', 'entryKey'};

  static String _entryKey(String? clientId, String dateKey) {
    return clientId == null ? dateKey : '$clientId|$dateKey';
  }

  static String? _itemClientId(Map<String, dynamic> item) {
    final raw = item['clientId'];
    if (raw is String && raw.trim().isNotEmpty) return raw.trim();
    return null;
  }

  static Map<String, dynamic> _content(Map<String, dynamic> item) {
    return Map<String, dynamic>.from(item)
      ..removeWhere((k, _) => _metaKeys.contains(k));
  }

  /// Záznam, který se pro daného klienta a den zobrazuje: vlastní záznam
  /// klienta, jinak starší neoznačený záznam.
  static Map<String, Map<String, dynamic>> _visibleByDate(
    List<Map<String, dynamic>> items,
    String? clientId,
  ) {
    final result = <String, Map<String, dynamic>>{};

    for (final item in items) {
      final dateKey = (item['dateKey'] ?? '').toString().trim();
      if (dateKey.isEmpty) continue;

      final owner = _itemClientId(item);
      if (owner == null) {
        result.putIfAbsent(dateKey, () => item);
      } else if (owner == clientId) {
        result[dateKey] = item; // vlastní záznam má přednost
      }
    }

    return result;
  }

  static Future<void> saveDailyHistory(
    Map<String, dynamic> historyJson, {
    String? clientId,
  }) async {
    final previousItems = await CoachStorageService.loadDailyHistoryRaw();
    final visible = _visibleByDate(previousItems, clientId);
    final nowIso = DateTime.now().toIso8601String();

    // Záznamy, které tímto uložením nahrazujeme (podle entryKey).
    final replaced = <String, Map<String, dynamic>>{};

    for (final entry in historyJson.entries) {
      final intakeJson = entry.value is Map<String, dynamic>
          ? Map<String, dynamic>.from(entry.value as Map<String, dynamic>)
          : <String, dynamic>{};

      final previous = visible[entry.key];

      // Beze změny → ponechat původní záznam (i s updatedAt/version),
      // jinak by při synchronizaci vždy vyhrálo zařízení, které ukládalo
      // naposledy.
      if (previous != null &&
          jsonEncode(_content(previous)) == jsonEncode(intakeJson)) {
        continue;
      }

      final ownPrevious =
          previous != null && _itemClientId(previous) == clientId
              ? previous
              : null;
      final previousVersion =
          (ownPrevious?['version'] as num?)?.toInt() ?? 0;

      final key = _entryKey(clientId, entry.key);
      replaced[key] = <String, dynamic>{
        // Bez klienta zůstává starý formát (bez entryKey), aby se záznam
        // v cloudu dál pároval podle dateKey a nevznikly duplicity.
        if (clientId != null) 'entryKey': key,
        'dateKey': entry.key,
        if (clientId != null) 'clientId': clientId,
        'updatedAt': nowIso,
        'version': previousVersion + 1,
        ...intakeJson,
      };
    }

    if (replaced.isEmpty) return;

    final items = <Map<String, dynamic>>[
      for (final item in previousItems)
        if (!replaced.containsKey(
          _entryKey(
            _itemClientId(item),
            (item['dateKey'] ?? '').toString().trim(),
          ),
        ))
          item,
      ...replaced.values,
    ];

    await CoachStorageService.saveDailyHistoryRaw(items);
  }

  static Future<Map<String, dynamic>?> loadDailyHistory({
    String? clientId,
  }) async {
    final items = await CoachStorageService.loadDailyHistoryRaw();
    if (items.isEmpty) {
      return null;
    }

    final result = <String, dynamic>{
      for (final entry in _visibleByDate(items, clientId).entries)
        entry.key: _content(entry.value),
    };

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