import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../models/coach/coach_body_diagnostic_entry.dart';
import '../../models/coach/coach_circumference_entry.dart';
import '../../models/coach/coach_client.dart';
import '../../models/coach/coach_client_details.dart';
import '../../models/coach/coach_goal.dart';
import '../../models/coach/coach_inbody_entry.dart';
import '../../models/coach/coach_note.dart';
import '../../models/coach/coach_overrides.dart';

class CoachStorageService {
  static const clientsKey = 'coach_clients_v1';
  static const notesKey = 'coach_notes_v1';
  static const overridesKey = 'coach_overrides_v1';
  static const clientDetailsKey = 'coach_client_details_v1';
  static const circumferencesKey = 'coach_circumferences_v1';
  static const inbodyKey = 'coach_inbody_v1';
  static const goalsKey = 'coach_goals_v1';
  static const diagnosticsKey = 'coach_diagnostics_v1';
  static const trainingSessionsKey = 'training_session_storage_v1';
  static const dailyHistoryKey = 'daily_history_v1';

  static const _clientsKey = clientsKey;
  static const _notesKey = notesKey;
  static const _overridesKey = overridesKey;
  static const _clientDetailsKey = clientDetailsKey;
  static const _circKey = circumferencesKey;
  static const _inbodyKey = inbodyKey;
  static const _goalsKey = goalsKey;
  static const _diagnosticsKey = diagnosticsKey;
  static const _trainingSessionsKey = trainingSessionsKey;
  static const _dailyHistoryKey = dailyHistoryKey;

  static const _deviceIdKey = 'coach_device_id_v1';
  static const _lastCloudSyncAtKey = 'coach_last_cloud_sync_at_v1';

  static const cloudCoachesCollection = 'coaches';
  static const cloudSnapshotsCollection = 'snapshots';

  static const List<String> syncStorageKeys = [
    clientsKey,
    notesKey,
    overridesKey,
    clientDetailsKey,
    circumferencesKey,
    inbodyKey,
    goalsKey,
    diagnosticsKey,
    trainingSessionsKey,
    dailyHistoryKey,
  ];

  static const _uuid = Uuid();

  static Future<SharedPreferences> _prefs() async {
    return SharedPreferences.getInstance();
  }

  static String? currentCoachUid() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.trim().isEmpty) {
      return null;
    }
    return uid.trim();
  }

  static String _scopedKey(String key) {
    if (key == _deviceIdKey) return key;

    final uid = currentCoachUid();
    if (uid == null) {
      return key;
    }

    final shouldScope = syncStorageKeys.contains(key) ||
        key == _lastCloudSyncAtKey ||
        key == 'client_id_counter_v1';

    if (!shouldScope) {
      return key;
    }

    return 'coach_${uid}_$key';
  }

  static Future<List<Map<String, dynamic>>> _loadRawList(String key) async {
    final prefs = await _prefs();
    final jsonStr = prefs.getString(_scopedKey(key));

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

  static Future<void> _saveRawList(
    String key,
    List<Map<String, dynamic>> items,
  ) async {
    final prefs = await _prefs();
    final jsonStr = jsonEncode(items);
    await prefs.setString(_scopedKey(key), jsonStr);
  }

  static Future<String> _ensureDeviceId() async {
    final prefs = await _prefs();
    final existing = prefs.getString(_deviceIdKey);

    if (existing != null && existing.trim().isNotEmpty) {
      return existing;
    }

    final newId = _uuid.v4();
    await prefs.setString(_deviceIdKey, newId);
    return newId;
  }

  static Future<void> _safeUploadSnapshot({
    required String key,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final uid = currentCoachUid();
      if (uid == null) {
        debugPrint('CLOUD SNAPSHOT SKIPPED -> no signed-in coach for key=$key');
        return;
      }

      final deviceId = await _ensureDeviceId();
      final now = DateTime.now();
      final payloadJson = jsonEncode(items);

      debugPrint('UPLOAD -> coaches/$uid/snapshots/$key count=${items.length}');

      await FirebaseFirestore.instance
          .collection(cloudCoachesCollection)
          .doc(uid)
          .collection(cloudSnapshotsCollection)
          .doc(key)
          .set({
        'storageKey': key,
        'coachUid': uid,
        'deviceId': deviceId,
        'updatedAt': Timestamp.fromDate(now),
        'itemCount': items.length,
        'payloadJson': payloadJson,
      }, SetOptions(merge: true));

      await saveLastCloudSyncAt(now);

      debugPrint(
        'CLOUD SNAPSHOT OK -> uid=$uid key=$key count=${items.length} deviceId=$deviceId',
      );
    } catch (e, st) {
      debugPrint('CLOUD SNAPSHOT ERROR -> key=$key error=$e');
      debugPrint('$st');
    }
  }

  static Future<List<Map<String, dynamic>>> loadRawItemsForKey(
    String key,
  ) async {
    return _loadRawList(key);
  }

  static Future<void> saveRawItemsForKeyLocalOnly({
    required String key,
    required List<Map<String, dynamic>> items,
  }) async {
    await _saveRawList(key, items);
  }

  static Future<void> pushLocalSnapshotForKey(String key) async {
    final items = await _loadRawList(key);
    await _safeUploadSnapshot(key: key, items: items);
  }

  static Future<void> pushAllLocalSnapshotsToCloud() async {
    for (final key in syncStorageKeys) {
      try {
        final items = await _loadRawList(key);
        await _safeUploadSnapshot(key: key, items: items);
      } catch (e, st) {
        debugPrint('PUSH ALL LOCAL SNAPSHOTS ERROR -> key=$key error=$e');
        debugPrint('$st');
      }
    }
  }

  static Future<int?> loadInt(String key) async {
    final prefs = await _prefs();
    return prefs.getInt(_scopedKey(key));
  }

  static Future<void> saveInt(String key, int value) async {
    final prefs = await _prefs();
    await prefs.setInt(_scopedKey(key), value);
  }

  static Future<List<CoachClient>> loadClients() async {
    final raw = await _loadRawList(_clientsKey);
    return raw.map(CoachClient.fromJson).toList();
  }

  static Future<void> saveClients(List<CoachClient> clients) async {
    final raw = clients.map((c) => c.toJson()).toList();
    await _saveRawList(_clientsKey, raw);
    await _safeUploadSnapshot(
      key: _clientsKey,
      items: raw,
    );
  }

  static Future<List<CoachNote>> loadNotes() async {
    final raw = await _loadRawList(_notesKey);
    return raw.map(CoachNote.fromJson).toList();
  }

  static Future<void> saveNotes(List<CoachNote> notes) async {
    final raw = notes.map((n) => n.toJson()).toList();
    await _saveRawList(_notesKey, raw);
    await _safeUploadSnapshot(
      key: _notesKey,
      items: raw,
    );
  }

  static Future<List<CoachOverrides>> loadOverrides() async {
    final raw = await _loadRawList(_overridesKey);
    return raw.map(CoachOverrides.fromJson).toList();
  }

  static Future<void> saveOverrides(List<CoachOverrides> overrides) async {
    final raw = overrides.map((o) => o.toJson()).toList();
    await _saveRawList(_overridesKey, raw);
    await _safeUploadSnapshot(
      key: _overridesKey,
      items: raw,
    );
  }

  static Future<List<CoachClientDetails>> loadClientDetailsAll() async {
    final raw = await _loadRawList(_clientDetailsKey);
    return raw.map(CoachClientDetails.fromJson).toList();
  }

  static Future<void> saveClientDetailsAll(
    List<CoachClientDetails> items,
  ) async {
    final raw = items.map((x) => x.toJson()).toList();
    await _saveRawList(_clientDetailsKey, raw);
    await _safeUploadSnapshot(
      key: _clientDetailsKey,
      items: raw,
    );
  }

  static Future<List<CoachCircumferenceEntry>> loadCircumferencesAll() async {
    final raw = await _loadRawList(_circKey);
    return raw.map(CoachCircumferenceEntry.fromJson).toList();
  }

  static Future<void> saveCircumferencesAll(
    List<CoachCircumferenceEntry> items,
  ) async {
    final raw = items.map((x) => x.toJson()).toList();
    await _saveRawList(_circKey, raw);
    await _safeUploadSnapshot(
      key: _circKey,
      items: raw,
    );
  }

  static Future<List<CoachInbodyEntry>> loadInbodyAll() async {
    final raw = await _loadRawList(_inbodyKey);
    final items = raw.map(CoachInbodyEntry.fromJson).toList();
    items.sort((a, b) => b.date.compareTo(a.date));
    return items;
  }

  static Future<void> saveInbodyAll(List<CoachInbodyEntry> items) async {
    final raw = items.map((x) => x.toJson()).toList();
    await _saveRawList(_inbodyKey, raw);
    await _safeUploadSnapshot(
      key: _inbodyKey,
      items: raw,
    );
  }

  static Future<List<CoachGoal>> loadGoalsAll() async {
    final raw = await _loadRawList(_goalsKey);
    return raw.map(CoachGoal.fromJson).toList();
  }

  static Future<void> saveGoalsAll(List<CoachGoal> items) async {
    final raw = items.map((x) => x.toJson()).toList();
    await _saveRawList(_goalsKey, raw);
    await _safeUploadSnapshot(
      key: _goalsKey,
      items: raw,
    );
  }

  static Future<List<CoachBodyDiagnosticEntry>> loadDiagnosticsAll() async {
    final raw = await _loadRawList(_diagnosticsKey);
    final items = raw.map(CoachBodyDiagnosticEntry.fromJson).toList();
    items.sort((a, b) => b.date.compareTo(a.date));
    return items;
  }

  static Future<void> saveDiagnosticsAll(
    List<CoachBodyDiagnosticEntry> items,
  ) async {
    final raw = items.map((x) => x.toJson()).toList();
    await _saveRawList(_diagnosticsKey, raw);
    await _safeUploadSnapshot(
      key: _diagnosticsKey,
      items: raw,
    );
  }

  static Future<List<Map<String, dynamic>>> loadTrainingSessionsRaw() async {
    return _loadRawList(_trainingSessionsKey);
  }

  static Future<void> saveTrainingSessionsRaw(
    List<Map<String, dynamic>> items,
  ) async {
    await _saveRawList(_trainingSessionsKey, items);
    await _safeUploadSnapshot(
      key: _trainingSessionsKey,
      items: items,
    );
  }

  static Future<List<Map<String, dynamic>>> loadDailyHistoryRaw() async {
    return _loadRawList(_dailyHistoryKey);
  }

  static Future<void> saveDailyHistoryRaw(
    List<Map<String, dynamic>> items,
  ) async {
    await _saveRawList(_dailyHistoryKey, items);
    await _safeUploadSnapshot(
      key: _dailyHistoryKey,
      items: items,
    );
  }

  static Future<void> deleteNotesForClient(String clientId) async {
    final notes = await loadNotes();
    final updated = notes.where((n) => n.clientId != clientId).toList();
    await saveNotes(updated);
  }

  static Future<void> deleteClientDetails(String clientId) async {
    final items = await loadClientDetailsAll();
    final updated = items.where((x) => x.clientId != clientId).toList();
    await saveClientDetailsAll(updated);
  }

  static Future<void> deleteCircumferencesForClient(String clientId) async {
    final items = await loadCircumferencesAll();
    final updated = items.where((x) => x.clientId != clientId).toList();
    await saveCircumferencesAll(updated);
  }

  static Future<void> deleteInbodyForClient(String clientId) async {
    final items = await loadInbodyAll();
    final updated = items.where((x) => x.clientId != clientId).toList();
    await saveInbodyAll(updated);
  }

  static Future<String?> loadDeviceId() async {
    final prefs = await _prefs();
    final value = prefs.getString(_deviceIdKey);
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return value;
  }

  static Future<void> saveDeviceId(String deviceId) async {
    final prefs = await _prefs();
    await prefs.setString(_deviceIdKey, deviceId.trim());
  }

  static Future<DateTime?> loadLastCloudSyncAt() async {
    final prefs = await _prefs();
    final raw = prefs.getString(_scopedKey(_lastCloudSyncAtKey));

    if (raw == null || raw.trim().isEmpty) {
      return null;
    }

    return DateTime.tryParse(raw);
  }

  static Future<void> saveLastCloudSyncAt(DateTime value) async {
    final prefs = await _prefs();
    await prefs.setString(
      _scopedKey(_lastCloudSyncAtKey),
      value.toIso8601String(),
    );
  }

  static Future<void> clearLastCloudSyncAt() async {
    final prefs = await _prefs();
    await prefs.remove(_scopedKey(_lastCloudSyncAtKey));
  }
}