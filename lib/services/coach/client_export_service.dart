import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../../core/training/sessions/training_session.dart';
import '../../models/coach/coach_circumference_entry.dart';
import '../../models/coach/coach_client.dart';
import '../../models/coach/coach_inbody_entry.dart';
import '../../models/custom_training_plan.dart';
import '../../models/exercise_performance.dart';
import '../local_storage_service.dart';
import '../pdf/client_report_pdf_service.dart';

class ClientArchiveExportResult {
  final Directory rootDirectory;
  final Directory clientDirectory;
  final File currentJsonFile;
  final File historyJsonFile;
  final File reportPdfFile;
  final File manifestFile;
  final File inbodyCsvFile;
  final File circumferencesCsvFile;
  final File performancesCsvFile;
  final DateTime reportFrom;
  final DateTime reportTo;

  const ClientArchiveExportResult({
    required this.rootDirectory,
    required this.clientDirectory,
    required this.currentJsonFile,
    required this.historyJsonFile,
    required this.reportPdfFile,
    required this.manifestFile,
    required this.inbodyCsvFile,
    required this.circumferencesCsvFile,
    required this.performancesCsvFile,
    required this.reportFrom,
    required this.reportTo,
  });
}

class ClientExportService {
  static Future<ClientArchiveExportResult> archiveClientExport({
    required CoachClient client,
    required dynamic details,
    required List<dynamic> notes,
    required List<CoachInbodyEntry> inbody,
    required List<CoachCircumferenceEntry> circumferences,
    required List<ExercisePerformance> performances,
    required List<CustomTrainingPlan> customPlans,
    required List<TrainingSession> sessions,
    String? archiveRootPath,
  }) async {
    final now = DateTime.now();
    final reportRange = _buildDefaultReportRange(client, now);

    final filteredInbody = _filterRange(inbody, (e) => e.date, reportRange);
    final filteredCircumferences = _filterRange(
      circumferences,
      (e) => e.date,
      reportRange,
    );
    final filteredPerformances = _filterRange(
      performances,
      (e) => e.date,
      reportRange,
    );

    final exportMap = _buildExportMap(
      client: client,
      details: details,
      notes: notes,
      inbody: inbody,
      circumferences: circumferences,
      performances: performances,
      customPlans: customPlans,
      sessions: sessions,
      exportedAt: now,
      reportFrom: reportRange.from,
      reportTo: reportRange.to,
    );

    final prettyJson = const JsonEncoder.withIndent('  ').convert(exportMap);

    final rootDirectory = await _resolveArchiveRootDirectory(
      archiveRootPath: archiveRootPath,
    );

    final clientFolderName = _buildClientFolderName(client);
    final clientDirectory = Directory(
      p.join(rootDirectory.path, clientFolderName),
    );
    final historyDirectory = Directory(p.join(clientDirectory.path, 'history'));
    final reportsDirectory = Directory(p.join(clientDirectory.path, 'reports'));

    await clientDirectory.create(recursive: true);
    await historyDirectory.create(recursive: true);
    await reportsDirectory.create(recursive: true);

    final timestamp = _timestampForFileName(now);
    final currentJsonFile = File(
      p.join(clientDirectory.path, 'client_current.json'),
    );
    final historyJsonFile = File(
      p.join(historyDirectory.path, '${timestamp}_snapshot.json'),
    );
    final reportPdfFile = File(
      p.join(reportsDirectory.path, '${timestamp}_report.pdf'),
    );
    final manifestFile = File(
      p.join(clientDirectory.path, 'archive_manifest.json'),
    );
    final inbodyCsvFile = File(
      p.join(clientDirectory.path, 'inbody.csv'),
    );
    final circumferencesCsvFile = File(
      p.join(clientDirectory.path, 'circumferences.csv'),
    );
    final performancesCsvFile = File(
      p.join(clientDirectory.path, 'performances.csv'),
    );

    await currentJsonFile.writeAsString(prettyJson, flush: true);
    await historyJsonFile.writeAsString(prettyJson, flush: true);

    final pdf = await ClientReportPdfService.generate(
      client: client,
      from: reportRange.from,
      to: reportRange.to,
      inbody: filteredInbody,
      circs: filteredCircumferences,
      performances: filteredPerformances,
    );

    final pdfBytes = await pdf.save();
    await reportPdfFile.writeAsBytes(pdfBytes, flush: true);

    await inbodyCsvFile.writeAsString(
      _buildInbodyCsv(inbody),
      flush: true,
    );
    await circumferencesCsvFile.writeAsString(
      _buildCircumferencesCsv(circumferences),
      flush: true,
    );
    await performancesCsvFile.writeAsString(
      _buildPerformancesCsv(performances),
      flush: true,
    );

    final manifestMap = _buildManifestMap(
      client: client,
      exportedAt: now,
      reportFrom: reportRange.from,
      reportTo: reportRange.to,
      currentJsonRelativePath: 'client_current.json',
      latestSnapshotRelativePath: p.join(
        'history',
        '${timestamp}_snapshot.json',
      ),
      latestReportRelativePath: p.join('reports', '${timestamp}_report.pdf'),
      inbodyCsvRelativePath: 'inbody.csv',
      circumferencesCsvRelativePath: 'circumferences.csv',
      performancesCsvRelativePath: 'performances.csv',
      notesCount: notes.length,
      inbodyCount: inbody.length,
      circumferencesCount: circumferences.length,
      performancesCount: performances.length,
      customPlansCount: customPlans.length,
      sessionsCount: sessions.length,
      hasDetails: details != null,
    );

    await manifestFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(manifestMap),
      flush: true,
    );

    return ClientArchiveExportResult(
      rootDirectory: rootDirectory,
      clientDirectory: clientDirectory,
      currentJsonFile: currentJsonFile,
      historyJsonFile: historyJsonFile,
      reportPdfFile: reportPdfFile,
      manifestFile: manifestFile,
      inbodyCsvFile: inbodyCsvFile,
      circumferencesCsvFile: circumferencesCsvFile,
      performancesCsvFile: performancesCsvFile,
      reportFrom: reportRange.from,
      reportTo: reportRange.to,
    );
  }

  static Future<File> exportClientToJsonFile({
    required CoachClient client,
    required dynamic details,
    required List<dynamic> notes,
    required List<CoachInbodyEntry> inbody,
    required List<CoachCircumferenceEntry> circumferences,
    required List<ExercisePerformance> performances,
    required List<CustomTrainingPlan> customPlans,
    required List<TrainingSession> sessions,
  }) async {
    final now = DateTime.now();
    final reportRange = _buildDefaultReportRange(client, now);

    final exportMap = _buildExportMap(
      client: client,
      details: details,
      notes: notes,
      inbody: inbody,
      circumferences: circumferences,
      performances: performances,
      customPlans: customPlans,
      sessions: sessions,
      exportedAt: now,
      reportFrom: reportRange.from,
      reportTo: reportRange.to,
    );

    final prettyJson = const JsonEncoder.withIndent('  ').convert(exportMap);

    final safeName = _safeFileName(client.displayName);
    final stamp = _timestampForFileName(now);
    final tempDir = Directory.systemTemp;

    final file = File(
      p.join(tempDir.path, 'client_export_${safeName}_$stamp.json'),
    );

    await file.writeAsString(prettyJson, flush: true);
    return file;
  }

  static Future<File> exportClientJsonOnly({
    required CoachClient client,
    required dynamic details,
    required List<dynamic> notes,
    required List<CoachInbodyEntry> inbody,
    required List<CoachCircumferenceEntry> circumferences,
    required List<ExercisePerformance> performances,
    required List<CustomTrainingPlan> customPlans,
    required List<TrainingSession> sessions,
  }) async {
    return exportClientToJsonFile(
      client: client,
      details: details,
      notes: notes,
      inbody: inbody,
      circumferences: circumferences,
      performances: performances,
      customPlans: customPlans,
      sessions: sessions,
    );
  }

  static Map<String, dynamic> _buildExportMap({
    required CoachClient client,
    required dynamic details,
    required List<dynamic> notes,
    required List<CoachInbodyEntry> inbody,
    required List<CoachCircumferenceEntry> circumferences,
    required List<ExercisePerformance> performances,
    required List<CustomTrainingPlan> customPlans,
    required List<TrainingSession> sessions,
    required DateTime exportedAt,
    required DateTime reportFrom,
    required DateTime reportTo,
  }) {
    return {
      'meta': {
        'exportedAt': exportedAt.toIso8601String(),
        'format': 'fitness_client_archive_v2',
        'exportType': 'client_archive_folder',
        'reportPeriod': {
          'from': reportFrom.toIso8601String(),
          'to': reportTo.toIso8601String(),
        },
      },
      'client': client.toJson(),
      'details': _tryToJson(details),
      'notes': notes.map(_tryToJson).toList(),
      'inbody': inbody.map((e) => e.toJson()).toList(),
      'circumferences': circumferences.map((e) => e.toJson()).toList(),
      'performances': performances.map(_performanceToJson).toList(),
      'customPlans': customPlans.map((e) => e.toJson()).toList(),
      'sessions': sessions.map(_sessionToJson).toList(),
    };
  }

  static Map<String, dynamic> _buildManifestMap({
    required CoachClient client,
    required DateTime exportedAt,
    required DateTime reportFrom,
    required DateTime reportTo,
    required String currentJsonRelativePath,
    required String latestSnapshotRelativePath,
    required String latestReportRelativePath,
    required String inbodyCsvRelativePath,
    required String circumferencesCsvRelativePath,
    required String performancesCsvRelativePath,
    required int notesCount,
    required int inbodyCount,
    required int circumferencesCount,
    required int performancesCount,
    required int customPlansCount,
    required int sessionsCount,
    required bool hasDetails,
  }) {
    return {
      'manifestVersion': 1,
      'format': 'fitness_client_archive_manifest_v1',
      'exportedAt': exportedAt.toIso8601String(),
      'client': {
        'clientId': client.clientId,
        'firstName': client.firstName,
        'lastName': client.lastName,
        'displayName': client.displayName,
        'email': client.email,
        'gender': client.gender,
        'age': client.age,
        'heightCm': client.heightCm,
        'weightKg': client.weightKg,
        'isEatingDisorderSupport': client.isEatingDisorderSupport,
        'linkedAt': client.linkedAt.toIso8601String(),
      },
      'reportPeriod': {
        'from': reportFrom.toIso8601String(),
        'to': reportTo.toIso8601String(),
      },
      'files': {
        'currentJson': currentJsonRelativePath,
        'latestSnapshot': latestSnapshotRelativePath,
        'latestReport': latestReportRelativePath,
        'inbodyCsv': inbodyCsvRelativePath,
        'circumferencesCsv': circumferencesCsvRelativePath,
        'performancesCsv': performancesCsvRelativePath,
      },
      'counts': {
        'notes': notesCount,
        'inbody': inbodyCount,
        'circumferences': circumferencesCount,
        'performances': performancesCount,
        'customPlans': customPlansCount,
        'sessions': sessionsCount,
      },
      'flags': {
        'hasDetails': hasDetails,
      },
    };
  }

  static Future<Directory> _resolveArchiveRootDirectory({
    String? archiveRootPath,
  }) async {
    String? resolvedPath = archiveRootPath?.trim();

    if (resolvedPath == null || resolvedPath.isEmpty) {
      resolvedPath = await LocalStorageService.loadClientExportFolderPath();
    }

    if (resolvedPath != null && resolvedPath.trim().isNotEmpty) {
      final customDir = Directory(resolvedPath.trim());
      await customDir.create(recursive: true);
      return customDir;
    }

    final documentsDir = _tryGetDocumentsDirectory();
    if (documentsDir != null) {
      final dir = Directory(p.join(documentsDir.path, 'Klienti'));
      await dir.create(recursive: true);
      return dir;
    }

    final homeDir = _tryGetHomeDirectory();
    if (homeDir != null) {
      final dir = Directory(p.join(homeDir.path, 'Klienti'));
      await dir.create(recursive: true);
      return dir;
    }

    final fallback = Directory(p.join(Directory.current.path, 'Klienti'));
    await fallback.create(recursive: true);
    return fallback;
  }

  static Directory? _tryGetDocumentsDirectory() {
    try {
      if (Platform.isWindows) {
        final userProfile = Platform.environment['USERPROFILE'];
        if (userProfile != null && userProfile.trim().isNotEmpty) {
          final docs = Directory(p.join(userProfile, 'Documents'));
          if (docs.existsSync()) return docs;
        }
      }

      final home = Platform.environment['HOME'];
      if (home != null && home.trim().isNotEmpty) {
        final docs = Directory(p.join(home, 'Documents'));
        if (docs.existsSync()) return docs;
      }
    } catch (_) {
      // ignore
    }

    return null;
  }

  static Directory? _tryGetHomeDirectory() {
    try {
      if (Platform.isWindows) {
        final userProfile = Platform.environment['USERPROFILE'];
        if (userProfile != null && userProfile.trim().isNotEmpty) {
          final dir = Directory(userProfile);
          if (dir.existsSync()) return dir;
        }
      }

      final home = Platform.environment['HOME'];
      if (home != null && home.trim().isNotEmpty) {
        final dir = Directory(home);
        if (dir.existsSync()) return dir;
      }
    } catch (_) {
      // ignore
    }

    return null;
  }

  static _ExportDateRange _buildDefaultReportRange(
    CoachClient client,
    DateTime now,
  ) {
    final to = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final suggestedFrom = DateTime(now.year, now.month - 1, now.day);

    final from = client.linkedAt.isAfter(suggestedFrom)
        ? DateTime(
            client.linkedAt.year,
            client.linkedAt.month,
            client.linkedAt.day,
          )
        : suggestedFrom;

    return _ExportDateRange(from: from, to: to);
  }

  static List<T> _filterRange<T>(
    List<T> items,
    DateTime Function(T item) getDate,
    _ExportDateRange range,
  ) {
    final filtered = items.where((item) {
      final date = getDate(item);
      return !date.isBefore(range.from) && !date.isAfter(range.to);
    }).toList();

    filtered.sort((a, b) => getDate(a).compareTo(getDate(b)));
    return filtered;
  }

  static Map<String, dynamic>? _tryToJson(dynamic value) {
    if (value == null) return null;

    if (value is Map<String, dynamic>) return value;

    try {
      final dynamic result = value.toJson();
      if (result is Map<String, dynamic>) {
        return result;
      }
      if (result is Map) {
        return Map<String, dynamic>.from(result);
      }
    } catch (_) {
      // fallback
    }

    return {
      'value': value.toString(),
    };
  }

  static Map<String, dynamic> _performanceToJson(
    ExercisePerformance p,
  ) {
    return {
      'exerciseName': p.exerciseName,
      'date': p.date.toIso8601String(),
      'weight': p.weight,
      'reps': p.reps,
      'clientId': p.clientId,
      'volume': p.volume,
    };
  }

  static Map<String, dynamic> _sessionToJson(
    TrainingSession s,
  ) {
    return {
      'date': s.date.toIso8601String(),
      'completed': s.completed,
      'dayPlan': {
        'dayLabel': s.dayPlan.dayLabel,
        'focus': s.dayPlan.focus,
        'exercises': s.dayPlan.exercises
            .map(
              (e) => {
                'name': e.name,
                'exerciseId': e.exerciseId,
                'sets': e.sets,
                'reps': e.reps,
                'rir': e.rir,
                'note': e.note,
                'intensityPercent': e.intensityPercent,
                'weightKg': e.weightKg,
                'plannedSets': e.plannedSets
                        ?.map(
                          (ps) => {
                            'weightKg': ps.weightKg,
                            'reps': ps.reps,
                            'note': ps.note,
                          },
                        )
                        .toList() ??
                    [],
              },
            )
            .toList(),
      },
      'entries': s.entries
          .map(
            (entry) => {
              'exerciseKey': entry.exerciseKey,
              'plannedSets': entry.plannedSets
                  .map(
                    (ps) => {
                      'weightKg': ps.weightKg,
                      'reps': ps.reps,
                      'note': ps.note,
                    },
                  )
                  .toList(),
              'actualSets': entry.actualSets
                  .map(
                    (as) => {
                      'weightKg': as.weightKg,
                      'reps': as.reps,
                    },
                  )
                  .toList(),
            },
          )
          .toList(),
    };
  }

  static String _buildInbodyCsv(List<CoachInbodyEntry> inbody) {
    final sorted = [...inbody]..sort((a, b) => a.date.compareTo(b.date));

    final rows = <List<String>>[
      [
        'date',
        'weightKg',
        'skeletalMuscleMassKg',
        'percentBodyFat',
        'bmi',
      ],
      ...sorted.map(
        (e) => [
          e.date.toIso8601String(),
          _fmtDouble(e.weightKg),
          _fmtDouble(e.skeletalMuscleMassKg),
          _fmtDouble(e.percentBodyFat),
          _fmtDouble(e.bmi),
        ],
      ),
    ];

    return _rowsToCsv(rows);
  }

  static String _buildCircumferencesCsv(
    List<CoachCircumferenceEntry> circumferences,
  ) {
    final sorted = [...circumferences]..sort((a, b) => a.date.compareTo(b.date));

    final rows = <List<String>>[
      [
        'date',
        'neckCm',
        'chestCm',
        'armCm',
        'waistCm',
        'hipsCm',
        'thighCm',
        'calfCm',
      ],
      ...sorted.map(
        (e) => [
          e.date.toIso8601String(),
          _fmtDouble(e.neckCm),
          _fmtDouble(e.chestCm),
          _fmtDouble(e.armCm),
          _fmtDouble(e.waistCm),
          _fmtDouble(e.hipsCm),
          _fmtDouble(e.thighCm),
          _fmtDouble(e.calfCm),
        ],
      ),
    ];

    return _rowsToCsv(rows);
  }

  static String _buildPerformancesCsv(
    List<ExercisePerformance> performances,
  ) {
    final sorted = [...performances]..sort((a, b) => a.date.compareTo(b.date));

    final rows = <List<String>>[
      [
        'date',
        'exerciseName',
        'weight',
        'reps',
        'volume',
        'clientId',
      ],
      ...sorted.map(
        (e) => [
          e.date.toIso8601String(),
          e.exerciseName,
          _fmtDouble(e.weight),
          e.reps.toString(),
          _fmtDouble(e.volume),
          e.clientId ?? '',
        ],
      ),
    ];

    return _rowsToCsv(rows);
  }

  static String _rowsToCsv(List<List<String>> rows) {
    return rows.map((row) => row.map(_csvEscape).join(',')).join('\n');
  }

  static String _csvEscape(String value) {
    final normalized = value.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final escaped = normalized.replaceAll('"', '""');
    return '"$escaped"';
  }

  static String _fmtDouble(num? value) {
    if (value == null) return '';
    return value.toString();
  }

  static String _buildClientFolderName(CoachClient client) {
    final idPart = _safeFileName(client.clientId);
    final firstNamePart = _safeFileName(client.firstName);
    final lastNamePart = _safeFileName(client.lastName);

    final parts = <String>[
      if (idPart.isNotEmpty) idPart,
      if (firstNamePart.isNotEmpty) firstNamePart,
      if (lastNamePart.isNotEmpty) lastNamePart,
    ];

    if (parts.isEmpty) {
      return 'client';
    }

    return parts.join('_');
  }

  static String _timestampForFileName(DateTime dateTime) {
    final y = dateTime.year.toString().padLeft(4, '0');
    final m = dateTime.month.toString().padLeft(2, '0');
    final d = dateTime.day.toString().padLeft(2, '0');
    final h = dateTime.hour.toString().padLeft(2, '0');
    final min = dateTime.minute.toString().padLeft(2, '0');
    final s = dateTime.second.toString().padLeft(2, '0');

    return '$y-$m-${d}_$h-$min-$s';
  }

  static String _safeFileName(String input) {
    final transliterated = _stripDiacritics(input);

    final normalized = transliterated
        .trim()
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'[^A-Za-z0-9_\-]'), '')
        .replaceAll(RegExp(r'_+'), '_');

    return normalized.isEmpty ? 'client' : normalized;
  }

  static String _stripDiacritics(String input) {
    const map = {
      'á': 'a',
      'ä': 'a',
      'č': 'c',
      'ď': 'd',
      'é': 'e',
      'ě': 'e',
      'ë': 'e',
      'í': 'i',
      'ľ': 'l',
      'ĺ': 'l',
      'ň': 'n',
      'ó': 'o',
      'ô': 'o',
      'ö': 'o',
      'ř': 'r',
      'ŕ': 'r',
      'š': 's',
      'ť': 't',
      'ú': 'u',
      'ů': 'u',
      'ü': 'u',
      'ý': 'y',
      'ž': 'z',
      'Á': 'A',
      'Ä': 'A',
      'Č': 'C',
      'Ď': 'D',
      'É': 'E',
      'Ě': 'E',
      'Ë': 'E',
      'Í': 'I',
      'Ľ': 'L',
      'Ĺ': 'L',
      'Ň': 'N',
      'Ó': 'O',
      'Ô': 'O',
      'Ö': 'O',
      'Ř': 'R',
      'Ŕ': 'R',
      'Š': 'S',
      'Ť': 'T',
      'Ú': 'U',
      'Ů': 'U',
      'Ü': 'U',
      'Ý': 'Y',
      'Ž': 'Z',
    };

    final buffer = StringBuffer();
    for (final rune in input.runes) {
      final char = String.fromCharCode(rune);
      buffer.write(map[char] ?? char);
    }
    return buffer.toString();
  }
}

class _ExportDateRange {
  final DateTime from;
  final DateTime to;

  const _ExportDateRange({
    required this.from,
    required this.to,
  });
}