import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'coach_storage_service.dart';

class CoachCloudSyncReport {
  final bool success;
  final DateTime startedAt;
  final DateTime finishedAt;
  final List<String> processedKeys;
  final List<String> warnings;

  const CoachCloudSyncReport({
    required this.success,
    required this.startedAt,
    required this.finishedAt,
    required this.processedKeys,
    required this.warnings,
  });
}

class CoachCloudSyncService {
  static const Map<String, List<String>> _idCandidatesByKey = {
    CoachStorageService.clientsKey: ['clientId', 'id'],
    CoachStorageService.notesKey: ['noteId', 'id'],
    CoachStorageService.overridesKey: ['overrideId', 'clientId', 'id'],
    CoachStorageService.clientDetailsKey: ['clientId', 'id'],
    CoachStorageService.circumferencesKey: ['entryId', 'id'],
    CoachStorageService.inbodyKey: ['entryId', 'inbodyId', 'id'],
    CoachStorageService.goalsKey: ['goalId', 'id'],
    CoachStorageService.diagnosticsKey: ['entryId', 'id'],
    CoachStorageService.trainingSessionsKey: ['sessionId', 'date', 'id'],
    CoachStorageService.dailyHistoryKey: ['dateKey', 'id'],

    // NOVÉ SYNC ENTITY
    CoachStorageService.customTrainingPlansKey: ['id'],
    CoachStorageService.sharedTrainingTemplatesKey: ['id'],
  };

  static Future<CoachCloudSyncReport> safePushAllFromLocal() async {
    final startedAt = DateTime.now();
    final warnings = <String>[];
    final processedKeys = <String>[];

    final uid = CoachStorageService.currentCoachUid();
    if (uid == null) {
      final finishedAt = DateTime.now();
      return CoachCloudSyncReport(
        success: false,
        startedAt: startedAt,
        finishedAt: finishedAt,
        processedKeys: const [],
        warnings: const [
          'Coach není přihlášený, upload do cloudu byl přeskočen.',
        ],
      );
    }

    try {
      debugPrint('PUSH START -> uid=$uid');

      for (final key in CoachStorageService.syncStorageKeys) {
        try {
          final localItems = await CoachStorageService.loadRawItemsForKey(key);

          debugPrint(
            'UPLOAD -> coaches/$uid/snapshots/$key count=${localItems.length}',
          );

          await _uploadCloudSnapshotItems(
            uid: uid,
            key: key,
            items: localItems,
          );

          processedKeys.add(key);
        } catch (e, st) {
          warnings.add('Push failed: $key -> $e');
          debugPrint('PUSH ERROR -> uid=$uid key=$key error=$e');
          debugPrint('$st');
        }
      }

      final finishedAt = DateTime.now();
      await CoachStorageService.saveLastCloudSyncAt(finishedAt);

      return CoachCloudSyncReport(
        success: true,
        startedAt: startedAt,
        finishedAt: finishedAt,
        processedKeys: processedKeys,
        warnings: warnings,
      );
    } catch (e, st) {
      debugPrint('PUSH GLOBAL ERROR -> $e');
      debugPrint('$st');

      final finishedAt = DateTime.now();
      return CoachCloudSyncReport(
        success: false,
        startedAt: startedAt,
        finishedAt: finishedAt,
        processedKeys: processedKeys,
        warnings: [...warnings, e.toString()],
      );
    }
  }

  static Future<CoachCloudSyncReport> safePullMergeToLocal() async {
    final startedAt = DateTime.now();
    final warnings = <String>[];
    final processedKeys = <String>[];

    final uid = CoachStorageService.currentCoachUid();
    if (uid == null) {
      final finishedAt = DateTime.now();
      return CoachCloudSyncReport(
        success: true,
        startedAt: startedAt,
        finishedAt: finishedAt,
        processedKeys: const [],
        warnings: const ['Coach není přihlášený, cloud sync byl přeskočen.'],
      );
    }

    try {
      debugPrint('SYNC START -> uid=$uid');

      for (final key in CoachStorageService.syncStorageKeys) {
        try {
          final cloudItems = await _loadCloudSnapshotItems(uid, key);

          if (cloudItems == null) {
            warnings.add('Cloud snapshot missing for uid=$uid key=$key');
            continue;
          }

          final localItems = await CoachStorageService.loadRawItemsForKey(key);

          final mergedItems = _mergeLists(
            key: key,
            localItems: localItems,
            cloudItems: cloudItems,
          );

          await CoachStorageService.saveRawItemsForKeyLocalOnly(
            key: key,
            items: mergedItems,
          );

          processedKeys.add(key);

          debugPrint(
            'CLOUD PULL MERGE OK -> uid=$uid key=$key local=${localItems.length} cloud=${cloudItems.length} merged=${mergedItems.length}',
          );
        } catch (e, st) {
          warnings.add('Key failed: $key -> $e');
          debugPrint('CLOUD PULL MERGE ERROR -> uid=$uid key=$key error=$e');
          debugPrint('$st');
        }
      }

      final finishedAt = DateTime.now();
      await CoachStorageService.saveLastCloudSyncAt(finishedAt);

      return CoachCloudSyncReport(
        success: true,
        startedAt: startedAt,
        finishedAt: finishedAt,
        processedKeys: processedKeys,
        warnings: warnings,
      );
    } catch (e, st) {
      debugPrint('CLOUD PULL GLOBAL ERROR -> $e');
      debugPrint('$st');

      final finishedAt = DateTime.now();
      return CoachCloudSyncReport(
        success: false,
        startedAt: startedAt,
        finishedAt: finishedAt,
        processedKeys: processedKeys,
        warnings: [...warnings, e.toString()],
      );
    }
  }

  static Future<CoachCloudSyncReport> safeReconcileLocalAndCloud() async {
    final startedAt = DateTime.now();
    final warnings = <String>[];
    final processedKeys = <String>[];

    final uid = CoachStorageService.currentCoachUid();
    if (uid == null) {
      final finishedAt = DateTime.now();
      return CoachCloudSyncReport(
        success: false,
        startedAt: startedAt,
        finishedAt: finishedAt,
        processedKeys: const [],
        warnings: const [
          'Coach není přihlášený, synchronizace byla přeskočena.',
        ],
      );
    }

    try {
      debugPrint('RECONCILE START -> uid=$uid');

      for (final key in CoachStorageService.syncStorageKeys) {
        try {
          final localItems = await CoachStorageService.loadRawItemsForKey(key);
          final cloudItems = await _loadCloudSnapshotItems(uid, key);

          if (cloudItems == null) {
            await _uploadCloudSnapshotItems(
              uid: uid,
              key: key,
              items: localItems,
            );

            processedKeys.add(key);
            continue;
          }

          final mergedItems = _mergeLists(
            key: key,
            localItems: localItems,
            cloudItems: cloudItems,
          );

          await CoachStorageService.saveRawItemsForKeyLocalOnly(
            key: key,
            items: mergedItems,
          );

          await _uploadCloudSnapshotItems(
            uid: uid,
            key: key,
            items: mergedItems,
          );

          processedKeys.add(key);

          debugPrint(
            'RECONCILE OK -> uid=$uid key=$key local=${localItems.length} cloud=${cloudItems.length} merged=${mergedItems.length}',
          );
        } catch (e, st) {
          warnings.add('Reconcile failed: $key -> $e');
          debugPrint('RECONCILE ERROR -> uid=$uid key=$key error=$e');
          debugPrint('$st');
        }
      }

      final finishedAt = DateTime.now();
      await CoachStorageService.saveLastCloudSyncAt(finishedAt);

      return CoachCloudSyncReport(
        success: true,
        startedAt: startedAt,
        finishedAt: finishedAt,
        processedKeys: processedKeys,
        warnings: warnings,
      );
    } catch (e, st) {
      debugPrint('RECONCILE GLOBAL ERROR -> $e');
      debugPrint('$st');

      final finishedAt = DateTime.now();
      return CoachCloudSyncReport(
        success: false,
        startedAt: startedAt,
        finishedAt: finishedAt,
        processedKeys: processedKeys,
        warnings: [...warnings, e.toString()],
      );
    }
  }

  static Future<void> _uploadCloudSnapshotItems({
    required String uid,
    required String key,
    required List<Map<String, dynamic>> items,
  }) async {
    final deviceId = await CoachStorageService.loadDeviceId() ?? 'unknown_device';
    final now = DateTime.now();
    final payloadJson = jsonEncode(items);

    await FirebaseFirestore.instance
        .collection(CoachStorageService.cloudCoachesCollection)
        .doc(uid)
        .collection(CoachStorageService.cloudSnapshotsCollection)
        .doc(key)
        .set({
      'storageKey': key,
      'coachUid': uid,
      'deviceId': deviceId,
      'updatedAt': Timestamp.fromDate(now),
      'itemCount': items.length,
      'payloadJson': payloadJson,
    }, SetOptions(merge: true));
  }

  static Future<List<Map<String, dynamic>>?> _loadCloudSnapshotItems(
    String uid,
    String key,
  ) async {
    final doc = await FirebaseFirestore.instance
        .collection(CoachStorageService.cloudCoachesCollection)
        .doc(uid)
        .collection(CoachStorageService.cloudSnapshotsCollection)
        .doc(key)
        .get();

    if (!doc.exists) {
      return null;
    }

    final data = doc.data();
    if (data == null) {
      return null;
    }

    final payloadJson = data['payloadJson'];
    if (payloadJson is! String || payloadJson.trim().isEmpty) {
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

  static List<Map<String, dynamic>> _mergeLists({
    required String key,
    required List<Map<String, dynamic>> localItems,
    required List<Map<String, dynamic>> cloudItems,
  }) {
    if (localItems.isEmpty && cloudItems.isNotEmpty) {
      final result = cloudItems
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      result.sort(_compareRecordsDesc);
      return result;
    }

    if (cloudItems.isEmpty && localItems.isNotEmpty) {
      final result = localItems
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      result.sort(_compareRecordsDesc);
      return result;
    }

    final mergedById = <String, Map<String, dynamic>>{};

    for (final item in localItems) {
      final itemId = _resolveItemId(key, item);
      mergedById[itemId] = Map<String, dynamic>.from(item);
    }

    for (final cloudItem in cloudItems) {
      final itemId = _resolveItemId(key, cloudItem);
      final localItem = mergedById[itemId];

      if (localItem == null) {
        mergedById[itemId] = Map<String, dynamic>.from(cloudItem);
        continue;
      }

      mergedById[itemId] = _pickWinner(
        localItem: localItem,
        cloudItem: cloudItem,
      );
    }

    final result = mergedById.values
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    result.sort(_compareRecordsDesc);
    return result;
  }

  static Map<String, dynamic> _pickWinner({
    required Map<String, dynamic> localItem,
    required Map<String, dynamic> cloudItem,
  }) {
    final localVersion = _toInt(localItem['version']) ?? 0;
    final cloudVersion = _toInt(cloudItem['version']) ?? 0;

    if (cloudVersion > localVersion) {
      return Map<String, dynamic>.from(cloudItem);
    }

    if (localVersion > cloudVersion) {
      return Map<String, dynamic>.from(localItem);
    }

    final localUpdatedAt = _parseDate(localItem['updatedAt']);
    final cloudUpdatedAt = _parseDate(cloudItem['updatedAt']);

    if (cloudUpdatedAt != null && localUpdatedAt != null) {
      if (cloudUpdatedAt.isAfter(localUpdatedAt)) {
        return Map<String, dynamic>.from(cloudItem);
      }
      return Map<String, dynamic>.from(localItem);
    }

    if (cloudUpdatedAt != null && localUpdatedAt == null) {
      return Map<String, dynamic>.from(cloudItem);
    }

    return Map<String, dynamic>.from(localItem);
  }

  static String _resolveItemId(String key, Map<String, dynamic> item) {
    final candidates = _idCandidatesByKey[key] ?? const ['id'];

    for (final field in candidates) {
      final value = item[field];
      if (value is String && value.trim().isNotEmpty) {
        return '$field:${value.trim()}';
      }
      if (value != null) {
        return '$field:$value';
      }
    }

    return 'fallback:${jsonEncode(item)}';
  }

  static int _compareRecordsDesc(
    Map<String, dynamic> a,
    Map<String, dynamic> b,
  ) {
    final aUpdatedAt = _parseDate(a['updatedAt']);
    final bUpdatedAt = _parseDate(b['updatedAt']);

    if (aUpdatedAt != null && bUpdatedAt != null) {
      return bUpdatedAt.compareTo(aUpdatedAt);
    }

    final aCreatedAt = _parseDate(a['createdAt']);
    final bCreatedAt = _parseDate(b['createdAt']);

    if (aCreatedAt != null && bCreatedAt != null) {
      return bCreatedAt.compareTo(aCreatedAt);
    }

    return 0;
  }

  static int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value);
    }

    return null;
  }
}