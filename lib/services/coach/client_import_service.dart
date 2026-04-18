import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../core/training/actual_set.dart';
import '../../core/training/sessions/exercise_log_entry.dart';
import '../../core/training/sessions/training_session.dart';
import '../../core/training/training_plan_models.dart';
import '../../core/training/training_set.dart';
import '../../models/coach/coach_circumference_entry.dart';
import '../../models/coach/coach_client.dart';
import '../../models/coach/coach_client_details.dart';
import '../../models/coach/coach_inbody_entry.dart';
import '../../models/coach/coach_note.dart';
import '../../models/custom_training_plan.dart';
import '../../models/exercise_performance.dart';
import '../../providers/coach/coach_circumference_controller.dart';
import '../../providers/coach/coach_client_details_controller.dart';
import '../../providers/coach/coach_clients_controller.dart';
import '../../providers/coach/coach_inbody_controller.dart';
import '../../providers/coach/coach_notes_controller.dart';
import '../../providers/coach/custom_training_plan_provider.dart';
import '../../providers/performance_provider.dart';
import '../../providers/training_session_provider.dart';
import 'coach_cloud_sync_service.dart';
import 'coach_storage_service.dart';

class ClientImportPreview {
  final String sourceLabel;
  final String sourcePath;
  final String resolvedJsonFilePath;
  final String clientDisplayName;
  final String originalClientId;
  final DateTime? exportedAt;
  final int notesCount;
  final int inbodyCount;
  final int circumferencesCount;
  final int performancesCount;
  final int customPlansCount;
  final int sessionsCount;
  final bool conflictExists;
  final String? conflictingClientDisplayName;

  const ClientImportPreview({
    required this.sourceLabel,
    required this.sourcePath,
    required this.resolvedJsonFilePath,
    required this.clientDisplayName,
    required this.originalClientId,
    required this.exportedAt,
    required this.notesCount,
    required this.inbodyCount,
    required this.circumferencesCount,
    required this.performancesCount,
    required this.customPlansCount,
    required this.sessionsCount,
    required this.conflictExists,
    required this.conflictingClientDisplayName,
  });
}

enum ClientImportMode {
  importAsNewIfConflict,
}

class ClientImportService {
  const ClientImportService();

  static const _uuid = Uuid();

  Future<ClientImportPreview> previewClientImportFromJsonString(
    String jsonString, {
    required String sourceLabel,
    required String sourcePath,
    required String resolvedJsonFilePath,
  }) async {
    final data = _decodeAndValidateExport(jsonString);

    final rawClient = data['client'];
    if (rawClient is! Map) {
      throw const FormatException('Chybí objekt "client".');
    }

    final client = CoachClient.fromJson(Map<String, dynamic>.from(rawClient));
    final meta = _asMap(data['meta']);
    final exportedAt =
        DateTime.tryParse((meta?['exportedAt'] ?? '').toString());

    final existingClients = await CoachStorageService.loadClients();
    final conflictingClient = existingClients.cast<CoachClient?>().firstWhere(
          (c) => c?.clientId == client.clientId,
          orElse: () => null,
        );

    return ClientImportPreview(
      sourceLabel: sourceLabel,
      sourcePath: sourcePath,
      resolvedJsonFilePath: resolvedJsonFilePath,
      clientDisplayName: client.displayName.trim().isEmpty
          ? 'Klient'
          : client.displayName,
      originalClientId: client.clientId,
      exportedAt: exportedAt,
      notesCount: _listLength(data['notes']),
      inbodyCount: _listLength(data['inbody']),
      circumferencesCount: _listLength(data['circumferences']),
      performancesCount: _listLength(data['performances']),
      customPlansCount: _listLength(data['customPlans']),
      sessionsCount: _listLength(data['sessions']),
      conflictExists: conflictingClient != null,
      conflictingClientDisplayName: conflictingClient?.displayName,
    );
  }

  Future<ClientImportPreview> previewClientImportFromJsonFile(
    String filePath,
  ) async {
    final file = File(filePath);

    if (!file.existsSync()) {
      throw FileSystemException(
        'Soubor pro import neexistuje.',
        filePath,
      );
    }

    final jsonString = await file.readAsString();

    return previewClientImportFromJsonString(
      jsonString,
      sourceLabel: 'JSON soubor',
      sourcePath: filePath,
      resolvedJsonFilePath: filePath,
    );
  }

  Future<ClientImportPreview> previewClientImportFromArchiveFolder(
    String folderPath,
  ) async {
    final dir = Directory(folderPath);

    if (!dir.existsSync()) {
      throw FileSystemException(
        'Archivní složka neexistuje.',
        folderPath,
      );
    }

    final manifestFile = File(p.join(dir.path, 'archive_manifest.json'));
    if (manifestFile.existsSync()) {
      final preview = await _previewFromManifestFile(
        manifestFile,
        folderPath: folderPath,
      );
      if (preview != null) {
        return preview;
      }
    }

    final resolvedJsonFile = _resolveArchiveJsonFile(dir);

    if (resolvedJsonFile == null) {
      throw const FormatException(
        'Ve složce nebyl nalezen client_current.json ani history snapshot.',
      );
    }

    final jsonString = await resolvedJsonFile.readAsString();

    return previewClientImportFromJsonString(
      jsonString,
      sourceLabel: 'Archivní složka',
      sourcePath: folderPath,
      resolvedJsonFilePath: resolvedJsonFile.path,
    );
  }

  Future<void> importClientFromJson(
    String jsonString,
    WidgetRef ref, {
    ClientImportMode mode = ClientImportMode.importAsNewIfConflict,
  }) async {
    final data = _decodeAndValidateExport(jsonString);

    final rawClient = data['client'];
    if (rawClient is! Map) {
      throw const FormatException('Chybí objekt "client".');
    }

    final now = DateTime.now();
    final importStamp = now.millisecondsSinceEpoch.toString();
    final deviceId = await _loadOrCreateDeviceId();

    final originalClient = CoachClient.fromJson(
      Map<String, dynamic>.from(rawClient),
    );

    final existingClients = await CoachStorageService.loadClients();
    final clientExists = existingClients.any(
      (c) => c.clientId == originalClient.clientId,
    );

    final finalClientId = switch (mode) {
      ClientImportMode.importAsNewIfConflict => clientExists
          ? 'import_$importStamp'
          : originalClient.clientId,
    };

    debugPrint(
      'IMPORT START -> originalClientId=${originalClient.clientId} finalClientId=$finalClientId conflict=$clientExists',
    );

   final importedClient = clientExists
    ? CoachClient(
        clientId: finalClientId,
        firstName: originalClient.firstName,
        lastName: originalClient.lastName,
        email: originalClient.email,
        gender: originalClient.gender,
        age: originalClient.age,
        heightCm: originalClient.heightCm,
        weightKg: originalClient.weightKg,
        isEatingDisorderSupport: originalClient.isEatingDisorderSupport,
        linkedAt: originalClient.linkedAt,

        completedDays: originalClient.completedDays,
        lastWorkoutAt: originalClient.lastWorkoutAt,
        photosDelivered: originalClient.photosDelivered,
        dietFollowed: originalClient.dietFollowed,
        communicationOk: originalClient.communicationOk,

        createdAt: now,
        updatedAt: now,
        deletedAt: null,
        version: 1,
        updatedByDeviceId: deviceId,
      )
    : originalClient.copyWith(
        updatedAt: now,
        version: originalClient.version <= 0 ? 1 : originalClient.version,
        updatedByDeviceId: deviceId,
      );

    await _saveClient(importedClient, existingClients);

    await _importDetails(
      data: data,
      finalClientId: finalClientId,
      ref: ref,
    );

    await _importNotes(
      data: data,
      finalClientId: finalClientId,
      needsNewIds: clientExists,
      importStamp: importStamp,
      ref: ref,
    );

    await _importInbody(
      data: data,
      finalClientId: finalClientId,
      needsNewIds: clientExists,
      importStamp: importStamp,
      ref: ref,
    );

    await _importCircumferences(
      data: data,
      finalClientId: finalClientId,
      needsNewIds: clientExists,
      importStamp: importStamp,
      ref: ref,
    );

    await _importPerformances(
      data: data,
      finalClientId: finalClientId,
      ref: ref,
    );

    await _importCustomPlans(
      data: data,
      finalClientId: finalClientId,
      needsNewIds: clientExists,
      importStamp: importStamp,
      ref: ref,
    );

    await _importSessions(
      data: data,
      ref: ref,
    );

    await _reloadClients(ref);

    // DŮLEŽITÉ:
    // Po importu explicitně pushneme všechny lokální snapshoty, které CoachStorageService umí synchronizovat.
    // Tím obejdeme situace, kdy nějaký provider/controller uložil data lokálně, ale sám nespustil upload.
    await CoachStorageService.pushAllLocalSnapshotsToCloud();

    debugPrint('IMPORT POST-PUSH DONE -> finalClientId=$finalClientId');

    // Volitelně ještě lehký pull/merge pro sjednocení lokálu po pushi.
    final syncReport = await CoachCloudSyncService.safePullMergeToLocal();
    debugPrint(
      'IMPORT FINAL SYNC -> success=${syncReport.success} processed=${syncReport.processedKeys.length} warnings=${syncReport.warnings.length}',
    );
  }

  Future<void> importClientFromJsonFile(
    String filePath,
    WidgetRef ref, {
    ClientImportMode mode = ClientImportMode.importAsNewIfConflict,
  }) async {
    final file = File(filePath);

    if (!file.existsSync()) {
      throw FileSystemException(
        'Soubor pro import neexistuje.',
        filePath,
      );
    }

    final jsonString = await file.readAsString();
    await importClientFromJson(
      jsonString,
      ref,
      mode: mode,
    );
  }

  Future<void> importClientFromArchiveFolder(
    String folderPath,
    WidgetRef ref, {
    ClientImportMode mode = ClientImportMode.importAsNewIfConflict,
  }) async {
    final dir = Directory(folderPath);

    if (!dir.existsSync()) {
      throw FileSystemException(
        'Archivní složka neexistuje.',
        folderPath,
      );
    }

    final resolvedJsonFile = _resolveArchiveJsonFile(dir);

    if (resolvedJsonFile == null) {
      throw const FormatException(
        'Ve složce nebyl nalezen client_current.json ani history snapshot.',
      );
    }

    await importClientFromJsonFile(
      resolvedJsonFile.path,
      ref,
      mode: mode,
    );
  }

  Map<String, dynamic> _decodeAndValidateExport(String jsonString) {
    final dynamic decoded = json.decode(jsonString);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('JSON musí být objekt.');
    }

    final data = decoded;

    if (!_looksLikeClientExport(data)) {
      throw const FormatException(
        'JSON neodpovídá formátu exportu klienta.',
      );
    }

    return data;
  }

  Future<ClientImportPreview?> _previewFromManifestFile(
    File manifestFile, {
    required String folderPath,
  }) async {
    try {
      final decoded = json.decode(await manifestFile.readAsString());
      if (decoded is! Map<String, dynamic>) return null;

      final clientMap = _asMap(decoded['client']);
      final countsMap = _asMap(decoded['counts']);

      if (clientMap == null) return null;

      final originalClientId = (clientMap['clientId'] ?? '').toString().trim();
      final firstName = (clientMap['firstName'] ?? '').toString().trim();
      final lastName = (clientMap['lastName'] ?? '').toString().trim();
      final displayName = (clientMap['displayName'] ?? '').toString().trim();

      final exportedAt =
          DateTime.tryParse((decoded['exportedAt'] ?? '').toString());

      final existingClients = await CoachStorageService.loadClients();
      final conflictingClient = existingClients.cast<CoachClient?>().firstWhere(
            (c) => c?.clientId == originalClientId,
            orElse: () => null,
          );

      final resolvedJsonFile = _resolveArchiveJsonFile(Directory(folderPath));

      final finalDisplayName = displayName.isNotEmpty
          ? displayName
          : ('$firstName $lastName').trim().isEmpty
              ? 'Klient'
              : ('$firstName $lastName').trim();

      return ClientImportPreview(
        sourceLabel: 'Archivní složka',
        sourcePath: folderPath,
        resolvedJsonFilePath: resolvedJsonFile?.path ?? '',
        clientDisplayName: finalDisplayName,
        originalClientId: originalClientId,
        exportedAt: exportedAt,
        notesCount: _intValue(countsMap?['notes']),
        inbodyCount: _intValue(countsMap?['inbody']),
        circumferencesCount: _intValue(countsMap?['circumferences']),
        performancesCount: _intValue(countsMap?['performances']),
        customPlansCount: _intValue(countsMap?['customPlans']),
        sessionsCount: _intValue(countsMap?['sessions']),
        conflictExists: conflictingClient != null,
        conflictingClientDisplayName: conflictingClient?.displayName,
      );
    } catch (_) {
      return null;
    }
  }

  File? _resolveArchiveJsonFile(Directory dir) {
    final currentFile = File(p.join(dir.path, 'client_current.json'));
    if (currentFile.existsSync()) {
      return currentFile;
    }

    final historyDir = Directory(p.join(dir.path, 'history'));
    if (!historyDir.existsSync()) {
      return null;
    }

    final snapshotFiles = historyDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.toLowerCase().endsWith('_snapshot.json'))
        .toList()
      ..sort(
        (a, b) => b.statSync().modified.compareTo(a.statSync().modified),
      );

    if (snapshotFiles.isEmpty) {
      return null;
    }

    return snapshotFiles.first;
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  int _intValue(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  int _listLength(dynamic value) {
    if (value is List) return value.length;
    return 0;
  }

  bool _looksLikeClientExport(Map<String, dynamic> data) {
    return data.containsKey('client') &&
        data.containsKey('details') &&
        data.containsKey('notes') &&
        data.containsKey('inbody') &&
        data.containsKey('circumferences') &&
        data.containsKey('performances') &&
        data.containsKey('customPlans') &&
        data.containsKey('sessions');
  }

  Future<String> _loadOrCreateDeviceId() async {
    final existing = await CoachStorageService.loadDeviceId();
    if (existing != null && existing.trim().isNotEmpty) {
      return existing;
    }

    final newId = _uuid.v4();
    await CoachStorageService.saveDeviceId(newId);
    return newId;
  }

  Future<void> _saveClient(
    CoachClient importedClient,
    List<CoachClient> existingClients,
  ) async {
    final updatedClients = [...existingClients, importedClient];
    await CoachStorageService.saveClients(updatedClients);
  }

  Future<void> _importDetails({
    required Map<String, dynamic> data,
    required String finalClientId,
    required WidgetRef ref,
  }) async {
    final raw = data['details'];
    if (raw == null) return;
    if (raw is! Map) return;

    final detailsMap = Map<String, dynamic>.from(raw);
    detailsMap['clientId'] = finalClientId;

    final details = CoachClientDetails.fromJson(detailsMap);

    await ref
        .read(coachClientDetailsControllerProvider.notifier)
        .upsert(details);

    debugPrint('IMPORT DETAILS OK -> clientId=$finalClientId');
  }

  Future<void> _importNotes({
    required Map<String, dynamic> data,
    required String finalClientId,
    required bool needsNewIds,
    required String importStamp,
    required WidgetRef ref,
  }) async {
    final raw = data['notes'];
    if (raw is! List) return;

    final existing = await CoachStorageService.loadNotes();
    final imported = <CoachNote>[];

    for (int i = 0; i < raw.length; i++) {
      final item = raw[i];
      if (item is! Map) continue;

      final map = Map<String, dynamic>.from(item);
      map['clientId'] = finalClientId;

      if (needsNewIds) {
        map['noteId'] = 'import_note_${importStamp}_$i';
      }

      imported.add(CoachNote.fromJson(map));
    }

    await CoachStorageService.saveNotes([...imported, ...existing]);
    await ref.read(coachNotesControllerProvider.notifier).refresh();

    debugPrint('IMPORT NOTES OK -> clientId=$finalClientId count=${imported.length}');
  }

  Future<void> _importInbody({
    required Map<String, dynamic> data,
    required String finalClientId,
    required bool needsNewIds,
    required String importStamp,
    required WidgetRef ref,
  }) async {
    final raw = data['inbody'];
    if (raw is! List) return;

    int count = 0;

    for (int i = 0; i < raw.length; i++) {
      final item = raw[i];
      if (item is! Map) continue;

      final map = Map<String, dynamic>.from(item);
      map['clientId'] = finalClientId;

      if (needsNewIds) {
        map['entryId'] = 'import_inbody_${importStamp}_$i';
      }

      final entry = CoachInbodyEntry.fromJson(map);

      await ref.read(coachInbodyControllerProvider.notifier).addEntry(entry);
      count++;
    }

    debugPrint('IMPORT INBODY OK -> clientId=$finalClientId count=$count');
  }

  Future<void> _importCircumferences({
    required Map<String, dynamic> data,
    required String finalClientId,
    required bool needsNewIds,
    required String importStamp,
    required WidgetRef ref,
  }) async {
    final raw = data['circumferences'];
    if (raw is! List) return;

    int count = 0;

    for (int i = 0; i < raw.length; i++) {
      final item = raw[i];
      if (item is! Map) continue;

      final map = Map<String, dynamic>.from(item);
      map['clientId'] = finalClientId;

      if (needsNewIds) {
        map['entryId'] = 'import_circ_${importStamp}_$i';
      }

      final entry = CoachCircumferenceEntry.fromJson(map);

      await ref
          .read(coachCircumferenceControllerProvider.notifier)
          .addEntry(entry);
      count++;
    }

    debugPrint('IMPORT CIRC OK -> clientId=$finalClientId count=$count');
  }

  Future<void> _importPerformances({
    required Map<String, dynamic> data,
    required String finalClientId,
    required WidgetRef ref,
  }) async {
    final raw = data['performances'];
    if (raw is! List) return;

    final performances = <ExercisePerformance>[];

    for (final item in raw) {
      if (item is! Map) continue;

      final map = Map<String, dynamic>.from(item);

      performances.add(
        ExercisePerformance(
          exerciseName: (map['exerciseName'] as String?) ?? '',
          date: DateTime.parse(
            (map['date'] as String?) ?? DateTime.now().toIso8601String(),
          ),
          weight: (map['weight'] as num?)?.toDouble() ?? 0,
          reps: (map['reps'] as num?)?.toInt() ?? 0,
          clientId: finalClientId,
        ),
      );
    }

    if (performances.isEmpty) return;

    await ref
        .read(performanceProvider.notifier)
        .importPerformances(performances);

    debugPrint(
      'IMPORT PERFORMANCE OK -> clientId=$finalClientId count=${performances.length}',
    );
  }

  Future<void> _importCustomPlans({
    required Map<String, dynamic> data,
    required String finalClientId,
    required bool needsNewIds,
    required String importStamp,
    required WidgetRef ref,
  }) async {
    final raw = data['customPlans'];
    if (raw is! List) return;

    final plans = <CustomTrainingPlan>[];

    for (int i = 0; i < raw.length; i++) {
      final item = raw[i];
      if (item is! Map) continue;

      final map = Map<String, dynamic>.from(item);
      map['clientId'] = finalClientId;

      if (needsNewIds) {
        map['id'] = 'import_plan_${importStamp}_$i';
      }

      plans.add(CustomTrainingPlan.fromJson(map));
    }

    if (plans.isEmpty) return;

    await ref.read(customTrainingPlanProvider.notifier).importPlans(plans);

    debugPrint(
      'IMPORT CUSTOM PLANS OK -> clientId=$finalClientId count=${plans.length}',
    );
  }

  Future<void> _importSessions({
    required Map<String, dynamic> data,
    required WidgetRef ref,
  }) async {
    final raw = data['sessions'];
    if (raw is! List) return;

    final sessions = <TrainingSession>[];

    for (final item in raw) {
      if (item is! Map) continue;
      sessions.add(_sessionFromJson(Map<String, dynamic>.from(item)));
    }

    if (sessions.isEmpty) return;

    await ref.read(trainingSessionProvider.notifier).importSessions(sessions);

    debugPrint('IMPORT SESSIONS OK -> count=${sessions.length}');
  }

  TrainingSession _sessionFromJson(Map<String, dynamic> json) {
    final rawDayPlan = json['dayPlan'] as Map?;
    final rawExercises = (rawDayPlan?['exercises'] as List?) ?? const [];
    final rawEntries = (json['entries'] as List?) ?? const [];

    final dayPlan = TrainingDayPlan(
      dayLabel: (rawDayPlan?['dayLabel'] as String?) ?? 'Den',
      focus: (rawDayPlan?['focus'] as String?) ?? '',
      exercises: rawExercises.map((e) {
        final map = Map<String, dynamic>.from(e as Map);

        final rawPlannedSets = (map['plannedSets'] as List?) ?? const [];

        return PlannedExercise(
          name: (map['name'] as String?) ?? '',
          exerciseId: map['exerciseId'] as String?,
          sets: (map['sets'] as String?) ?? '',
          reps: (map['reps'] as String?) ?? '',
          rir: (map['rir'] as String?) ?? '',
          note: map['note'] as String?,
          intensityPercent: (map['intensityPercent'] as num?)?.toDouble(),
          weightKg: (map['weightKg'] as num?)?.toDouble(),
          plannedSets: rawPlannedSets
              .map(
                (ps) => PlannedSet.fromJson(
                  Map<String, dynamic>.from(ps as Map),
                ),
              )
              .toList(),
        );
      }).toList(),
    );

    final entries = rawEntries.map((e) {
      final map = Map<String, dynamic>.from(e as Map);
      final rawPlannedSets = (map['plannedSets'] as List?) ?? const [];
      final rawActualSets = (map['actualSets'] as List?) ?? const [];

      return ExerciseLogEntry(
        exerciseKey: (map['exerciseKey'] as String?) ?? '',
        plannedSets: rawPlannedSets
            .map(
              (ps) => PlannedSet.fromJson(
                Map<String, dynamic>.from(ps as Map),
              ),
            )
            .toList(),
        actualSets: rawActualSets
            .map((asItem) {
              final actualMap = Map<String, dynamic>.from(asItem as Map);
              return ActualSet(
                weightKg: (actualMap['weightKg'] as num?)?.toDouble(),
                reps: (actualMap['reps'] as num?)?.toInt() ?? 0,
                rpe: (actualMap['rpe'] as num?)?.toDouble(),
              );
            })
            .toList(),
      );
    }).toList();

    return TrainingSession(
      date: DateTime.parse(
        (json['date'] as String?) ?? DateTime.now().toIso8601String(),
      ),
      completed: (json['completed'] as bool?) ?? false,
      dayPlan: dayPlan,
      entries: entries,
    );
  }

  Future<void> _reloadClients(WidgetRef ref) async {
    await ref.read(coachClientsControllerProvider.notifier).reload();
  }
}