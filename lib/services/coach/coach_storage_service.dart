import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../models/custom_training_plan.dart';
import '../../models/shared_training_template.dart';
import '../../models/coach/coach_body_diagnostic_entry.dart';
import '../../models/coach/coach_circumference_entry.dart';
import '../../models/coach/coach_client.dart';
import '../../models/coach/coach_client_details.dart';
import '../../models/coach/coach_goal.dart';
import '../../models/coach/coach_inbody_entry.dart';
import '../../models/coach/coach_note.dart';
import '../../models/coach/coach_overrides.dart';
import 'online_coaching_service.dart';

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
  static const customTrainingPlansKey = 'coach_custom_training_plans_v1';
  static const sharedTrainingTemplatesKey =
      'coach_shared_training_templates_v1';

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
  static const _customTrainingPlansKey = customTrainingPlansKey;
  static const _sharedTrainingTemplatesKey = sharedTrainingTemplatesKey;

  static const _deviceIdKey = 'coach_device_id_v1';
  static const _lastCloudSyncAtKey = 'coach_last_cloud_sync_at_v1';
  static const _clientIdCounterKey = 'client_id_counter_v1';

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
    customTrainingPlansKey,
    sharedTrainingTemplatesKey,
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
        key == _clientIdCounterKey;

    if (!shouldScope) {
      return key;
    }

    return 'coach_${uid}_$key';
  }

  static Future<List<Map<String, dynamic>>> _loadRawList(String key) async {
    try {
      final prefs = await _prefs();
      final jsonStr = prefs.getString(_scopedKey(key));

      if (jsonStr == null || jsonStr.isEmpty) {
        return [];
      }

      final decoded = jsonDecode(jsonStr);
      if (decoded is! List) {
        debugPrint('LOAD RAW LIST -> key=$key decoded is not List');
        return [];
      }

      return decoded
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (e, st) {
      debugPrint('LOAD RAW LIST ERROR -> key=$key error=$e');
      debugPrint('$st');
      return [];
    }
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
      return existing.trim();
    }

    final newId = _uuid.v4();
    await prefs.setString(_deviceIdKey, newId);
    return newId;
  }

  static Future<String> _requireDeviceId() async {
    final existing = await loadDeviceId();
    if (existing != null && existing.trim().isNotEmpty) {
      return existing.trim();
    }

    return _ensureDeviceId();
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

      // Změna dat → zároveň synchronizace s propojenými klienty.
      OnlineCoachingService.scheduleSync();

      final deviceId = await _ensureDeviceId();
      final now = DateTime.now();

      debugPrint('UPLOAD -> coaches/$uid/snapshots/$key count=${items.length}');

      await writeCloudSnapshot(
        uid: uid,
        key: key,
        items: items,
        deviceId: deviceId,
        now: now,
      );

      await saveLastCloudSyncAt(now);

      debugPrint(
        'CLOUD SNAPSHOT OK -> uid=$uid key=$key count=${items.length} deviceId=$deviceId',
      );
    } catch (e, st) {
      debugPrint('CLOUD SNAPSHOT ERROR -> key=$key error=$e');
      debugPrint('$st');
    }
  }

  // ==========================================================
  // Cloud snapshot I/O (s dělením na části kvůli limitu 1 MiB)
  // ==========================================================

  /// Max. počet znaků v jednom dokumentu. Firestore má limit 1 MiB
  /// na dokument; znak v UTF-8 má až 3 bajty → 300k znaků ≈ max 900 KB.
  static const int _snapshotChunkChars = 300000;

  static String _chunkDocId(String key, int index) => '${key}__part_$index';

  static CollectionReference<Map<String, dynamic>> _snapshotsRef(String uid) {
    return FirebaseFirestore.instance
        .collection(cloudCoachesCollection)
        .doc(uid)
        .collection(cloudSnapshotsCollection);
  }

  /// Zapíše snapshot. Malý payload zůstává v `payloadJson` (kompatibilní se
  /// starší verzí aplikace), velký se rozdělí do dokumentů `<key>__part_N`
  /// ve stejné kolekci a hlavní dokument nese `chunkCount`.
  static Future<void> writeCloudSnapshot({
    required String uid,
    required String key,
    required List<Map<String, dynamic>> items,
    required String deviceId,
    required DateTime now,
  }) async {
    final payloadJson = jsonEncode(items);
    final ref = _snapshotsRef(uid);

    final meta = <String, dynamic>{
      'storageKey': key,
      'coachUid': uid,
      'deviceId': deviceId,
      'updatedAt': Timestamp.fromDate(now),
      'itemCount': items.length,
    };

    if (payloadJson.length <= _snapshotChunkChars) {
      await ref.doc(key).set({
        ...meta,
        'payloadJson': payloadJson,
        'chunkCount': FieldValue.delete(),
      }, SetOptions(merge: true));
      return;
    }

    final chunks = <String>[];
    for (var i = 0; i < payloadJson.length; i += _snapshotChunkChars) {
      final end = (i + _snapshotChunkChars < payloadJson.length)
          ? i + _snapshotChunkChars
          : payloadJson.length;
      chunks.add(payloadJson.substring(i, end));
    }

    // Části i hlavní dokument v jedné dávce → buď se zapíše vše, nebo nic.
    final batch = FirebaseFirestore.instance.batch();
    for (var i = 0; i < chunks.length; i++) {
      batch.set(ref.doc(_chunkDocId(key, i)), {
        'storageKey': key,
        'coachUid': uid,
        'index': i,
        'updatedAt': Timestamp.fromDate(now),
        'payloadPart': chunks[i],
      });
    }
    batch.set(ref.doc(key), {
      ...meta,
      'payloadJson': FieldValue.delete(),
      'chunkCount': chunks.length,
    }, SetOptions(merge: true));

    await batch.commit();

    debugPrint(
      'CLOUD SNAPSHOT CHUNKED -> key=$key chunks=${chunks.length} chars=${payloadJson.length}',
    );
  }

  /// Načte snapshot z cloudu. `null` = snapshot neexistuje.
  static Future<List<Map<String, dynamic>>?> readCloudSnapshot({
    required String uid,
    required String key,
  }) async {
    final ref = _snapshotsRef(uid);
    final doc = await ref.doc(key).get();

    if (!doc.exists) return null;

    final data = doc.data();
    if (data == null) return null;

    String? payloadJson;

    final chunkCount = data['chunkCount'];
    if (chunkCount is int && chunkCount > 0) {
      final parts = await Future.wait(
        List.generate(chunkCount, (i) => ref.doc(_chunkDocId(key, i)).get()),
      );

      final buffer = StringBuffer();
      for (final part in parts) {
        final text = part.data()?['payloadPart'];
        if (text is! String) {
          throw StateError('Chybí část snapshotu ${part.id}');
        }
        buffer.write(text);
      }
      payloadJson = buffer.toString();
    } else {
      final raw = data['payloadJson'];
      payloadJson = raw is String ? raw : null;
    }

    if (payloadJson == null || payloadJson.trim().isEmpty) {
      return <Map<String, dynamic>>[];
    }

    final decoded = jsonDecode(payloadJson);
    if (decoded is! List) {
      return <Map<String, dynamic>>[];
    }

    return decoded
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  // ==========================================================
  // Smazání účtu trenéra
  // ==========================================================

  /// Smaže všechna data trenéra v cloudu (coaches/{uid}/snapshots/* i
  /// dokument coaches/{uid}).
  static Future<void> deleteCloudDataForCoach(String uid) async {
    final coachRef = FirebaseFirestore.instance
        .collection(cloudCoachesCollection)
        .doc(uid);

    final snapshots = await coachRef.collection(cloudSnapshotsCollection).get();

    // Dávka má limit 500 operací.
    var batch = FirebaseFirestore.instance.batch();
    var ops = 0;
    for (final doc in snapshots.docs) {
      batch.delete(doc.reference);
      ops++;
      if (ops == 450) {
        await batch.commit();
        batch = FirebaseFirestore.instance.batch();
        ops = 0;
      }
    }
    batch.delete(coachRef);
    await batch.commit();
  }

  /// Smaže lokální data trenéra (klíče s prefixem coach_<uid>_).
  static Future<void> clearLocalDataForCoach(String uid) async {
    final prefs = await _prefs();
    final prefix = 'coach_${uid}_';
    for (final key in prefs.getKeys().toList()) {
      if (key.startsWith(prefix)) {
        await prefs.remove(key);
      }
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

  static Future<List<CustomTrainingPlan>> loadCustomTrainingPlans() async {
    final raw = await _loadRawList(_customTrainingPlansKey);
    return raw
        .where((e) => !_isTombstone(e))
        .map(CustomTrainingPlan.fromJson)
        .toList();
  }

  static Future<void> saveCustomTrainingPlans(
    List<CustomTrainingPlan> plans,
  ) async {
    final raw = await _withTombstones(
      key: _customTrainingPlansKey,
      visible: plans.map((p) => p.toJson()).toList(),
    );

    await _saveRawList(_customTrainingPlansKey, raw);

    await _safeUploadSnapshot(
      key: _customTrainingPlansKey,
      items: raw,
    );
  }

  static Future<List<SharedTrainingTemplate>>
      loadSharedTrainingTemplates() async {
    final raw = await _loadRawList(_sharedTrainingTemplatesKey);
    return raw
        .where((e) => !_isTombstone(e))
        .map(SharedTrainingTemplate.fromJson)
        .toList();
  }

  static Future<void> saveSharedTrainingTemplates(
    List<SharedTrainingTemplate> templates,
  ) async {
    final raw = await _withTombstones(
      key: _sharedTrainingTemplatesKey,
      visible: templates.map((t) => t.toJson()).toList(),
    );

    await _saveRawList(_sharedTrainingTemplatesKey, raw);

    await _safeUploadSnapshot(
      key: _sharedTrainingTemplatesKey,
      items: raw,
    );
  }

  static Future<void> _softDeleteNotesForClient(String clientId) async {
    final deviceId = await _requireDeviceId();
    final now = DateTime.now();

    final notes = await loadNotes();
    final updated = notes.map((n) {
      if (n.clientId != clientId || n.isDeleted) return n;

      return n.copyWith(
        updatedAt: now,
        deletedAt: now,
        version: n.version + 1,
        updatedByDeviceId: deviceId,
      );
    }).toList();

    await saveNotes(updated);
  }

  static Future<void> _softDeleteClientDetailsForClient(String clientId) async {
    final deviceId = await _requireDeviceId();
    final now = DateTime.now();

    final items = await loadClientDetailsAll();
    final updated = items.map((x) {
      if (x.clientId != clientId || x.isDeleted) return x;

      return x.copyWith(
        updatedAt: now,
        deletedAt: now,
        version: x.version + 1,
        updatedByDeviceId: deviceId,
      );
    }).toList();

    await saveClientDetailsAll(updated);
  }

  static Future<void> _softDeleteCircumferencesForClient(
    String clientId,
  ) async {
    final deviceId = await _requireDeviceId();
    final now = DateTime.now();

    final items = await loadCircumferencesAll();
    final updated = items.map((x) {
      if (x.clientId != clientId || x.isDeleted) return x;

      return x.copyWith(
        updatedAt: now,
        deletedAt: now,
        version: x.version + 1,
        updatedByDeviceId: deviceId,
      );
    }).toList();

    await saveCircumferencesAll(updated);
  }

  static Future<void> _softDeleteInbodyForClient(String clientId) async {
    final deviceId = await _requireDeviceId();
    final now = DateTime.now();

    final items = await loadInbodyAll();
    final updated = items.map((x) {
      if (x.clientId != clientId || x.isDeleted) return x;

      return x.copyWith(
        updatedAt: now,
        deletedAt: now,
        version: x.version + 1,
        updatedByDeviceId: deviceId,
      );
    }).toList();

    await saveInbodyAll(updated);
  }

  static Future<void> _softDeleteGoalsForClient(String clientId) async {
    final deviceId = await _requireDeviceId();
    final now = DateTime.now();

    final items = await loadGoalsAll();
    final updated = items.map((x) {
      if (x.clientId != clientId || x.isDeleted) return x;

      return x.copyWith(
        updatedAt: now,
        deletedAt: now,
        version: x.version + 1,
        updatedByDeviceId: deviceId,
      );
    }).toList();

    await saveGoalsAll(updated);
  }

  static Future<void> _softDeleteDiagnosticsForClient(String clientId) async {
    final deviceId = await _requireDeviceId();
    final now = DateTime.now();

    final items = await loadDiagnosticsAll();
    final updated = items.map((x) {
      if (x.clientId != clientId || x.isDeleted) return x;

      return x.copyWith(
        updatedAt: now,
        deletedAt: now,
        version: x.version + 1,
        updatedByDeviceId: deviceId,
      );
    }).toList();

    await saveDiagnosticsAll(updated);
  }

  static Future<void> _hardDeleteOverridesForClient(String clientId) async {
    // Měkké mazání (deletedAt), aby se smazaný záznam při synchronizaci
    // z jiného zařízení nevrátil.
    final deviceId = await _requireDeviceId();
    final now = DateTime.now();

    final items = await loadOverrides();
    final updated = items.map((x) {
      if (x.clientId != clientId || x.isDeleted) return x;

      return x.copyWith(
        updatedAt: now,
        deletedAt: now,
        version: x.version + 1,
        updatedByDeviceId: deviceId,
      );
    }).toList();

    await saveOverrides(updated);
  }

  // ==========================================================
  // Tombstones (pro modely bez vlastního deletedAt)
  // ==========================================================

  static bool _isTombstone(Map<String, dynamic> item) {
    final d = item['deletedAt'];
    return d != null && d.toString().trim().isNotEmpty;
  }

  /// Položky, které byly dřív uložené a v novém seznamu chybí, se neodstraní,
  /// ale uloží se jako "tombstone" (id + deletedAt + novější updatedAt).
  /// Díky tomu smazání při slučování s cloudem vyhraje nad starou kopií.
  static Future<List<Map<String, dynamic>>> _withTombstones({
    required String key,
    required List<Map<String, dynamic>> visible,
    String idField = 'id',
  }) async {
    final previous = await _loadRawList(key);
    final visibleIds = visible.map((e) => e[idField]?.toString()).toSet();
    final nowIso = DateTime.now().toIso8601String();

    final tombstones = <Map<String, dynamic>>[];
    for (final item in previous) {
      final id = item[idField]?.toString();
      if (id == null || visibleIds.contains(id)) continue;

      if (_isTombstone(item)) {
        tombstones.add(item);
      } else {
        tombstones.add({
          idField: id,
          'deletedAt': nowIso,
          'updatedAt': nowIso,
        });
      }
    }

    return [...visible, ...tombstones];
  }

  static Future<void> deleteNotesForClient(String clientId) async {
    await _softDeleteNotesForClient(clientId);
  }

  static Future<void> deleteClientDetails(String clientId) async {
    await _softDeleteClientDetailsForClient(clientId);
  }

  static Future<void> deleteCircumferencesForClient(String clientId) async {
    await _softDeleteCircumferencesForClient(clientId);
  }

  static Future<void> deleteInbodyForClient(String clientId) async {
    await _softDeleteInbodyForClient(clientId);
  }

  static Future<void> deleteGoalsForClient(String clientId) async {
    await _softDeleteGoalsForClient(clientId);
  }

  static Future<void> deleteDiagnosticsForClient(String clientId) async {
    await _softDeleteDiagnosticsForClient(clientId);
  }

  static Future<void> deleteOverridesForClient(String clientId) async {
    await _hardDeleteOverridesForClient(clientId);
  }

  static Future<String?> loadDeviceId() async {
    final prefs = await _prefs();
    final value = prefs.getString(_deviceIdKey);
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return value.trim();
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