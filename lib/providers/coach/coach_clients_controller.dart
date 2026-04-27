import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../models/coach/coach_client.dart';
import '../../models/goal.dart';
import '../../models/user_profile.dart';
import '../../providers/user_profile_provider.dart';
import '../../services/coach/coach_storage_service.dart';

final coachClientsControllerProvider =
    AsyncNotifierProvider<CoachClientsController, List<CoachClientWithStats>>(
  CoachClientsController.new,
);

class CoachClientWithStats {
  final CoachClient client;
  final double compliance7d;
  final DateTime? lastSessionAt;
  final int completedDaysInLast7;
  final bool isInactive7d;

  const CoachClientWithStats({
    required this.client,
    required this.compliance7d,
    required this.lastSessionAt,
    required this.completedDaysInLast7,
    required this.isInactive7d,
  });
}

class CoachClientsController extends AsyncNotifier<List<CoachClientWithStats>> {
  static const _uuid = Uuid();
  static const _idCounterKey = 'client_id_counter_v1';

  @override
  Future<List<CoachClientWithStats>> build() async {
    await _ensureDeviceId();
    final clients = await _loadVisibleClients();
    return _mapWithStats(clients);
  }

  Future<void> reload() async {
    state = const AsyncLoading();

    await _ensureDeviceId();

    final clients = await _loadVisibleClients();
    state = AsyncData(await _mapWithStats(clients));
  }

  Future<void> addCurrentUserAsClient() async {
    final profile = ref.read(userProfileProvider);
    if (profile == null) return;

    state = const AsyncLoading();

    final deviceId = await _ensureDeviceId();
    final allClients = await CoachStorageService.loadClients();

    const selfId = 'local_user';
    final existingIndex = allClients.indexWhere((c) => c.clientId == selfId);

    final now = DateTime.now();

    if (existingIndex != -1) {
      final existing = allClients[existingIndex];

      if (!existing.isDeleted) {
        final visible = _visibleClients(allClients);
        state = AsyncData(await _mapWithStats(visible));
        return;
      }

      final restored = existing.copyWith(
        firstName: profile.firstName.isEmpty ? 'Můj' : profile.firstName,
        lastName: profile.lastName.isEmpty ? 'klient' : profile.lastName,
        email: profile.email.trim(),
        gender: profile.gender,
        age: profile.age,
        heightCm: profile.height,
        weightKg: profile.weight,
        isEatingDisorderSupport: _isSensitive(profile),
        isArchived: false,
        updatedAt: now,
        version: existing.version + 1,
        updatedByDeviceId: deviceId,
        clearDeletedAt: true,
      );

      final updated = allClients.map((c) {
        if (c.clientId != selfId) return c;
        return restored;
      }).toList();

      await CoachStorageService.saveClients(updated);
      state = AsyncData(await _mapWithStats(_visibleClients(updated)));
      return;
    }

    final newClient = CoachClient(
      clientId: selfId,
      firstName: profile.firstName.isEmpty ? 'Můj' : profile.firstName,
      lastName: profile.lastName.isEmpty ? 'klient' : profile.lastName,
      email: profile.email.trim(),
      gender: profile.gender,
      age: profile.age,
      heightCm: profile.height,
      weightKg: profile.weight,
      isEatingDisorderSupport: _isSensitive(profile),
      isArchived: false,
      linkedAt: now,
      completedDays: const [],
      lastWorkoutAt: null,
      photosDelivered: false,
      dietFollowed: false,
      communicationOk: false,
      createdAt: now,
      updatedAt: now,
      deletedAt: null,
      version: 1,
      updatedByDeviceId: deviceId,
    );

    final updated = [...allClients, newClient];
    await CoachStorageService.saveClients(updated);

    state = AsyncData(await _mapWithStats(_visibleClients(updated)));
  }

  Future<void> markWorkoutDoneToday(String clientId) async {
    state = const AsyncLoading();

    final deviceId = await _ensureDeviceId();
    final now = DateTime.now();
    final today = _normalizeDate(now);
    final allClients = await CoachStorageService.loadClients();

    final updated = allClients.map((c) {
      if (c.clientId != clientId) return c;

      final existingDays = [...c.completedDays.map(_normalizeDate)];
      final alreadyDoneToday = existingDays.any((d) => _isSameDay(d, today));

      final nextDays = alreadyDoneToday
          ? existingDays
          : [...existingDays, today]..sort((a, b) => a.compareTo(b));

      return c.copyWith(
        completedDays: nextDays,
        lastWorkoutAt: now,
        updatedAt: now,
        version: c.version + 1,
        updatedByDeviceId: deviceId,
      );
    }).toList();

    await CoachStorageService.saveClients(updated);
    state = AsyncData(await _mapWithStats(_visibleClients(updated)));
  }

  Future<void> addClientManual({
    required String firstName,
    required String lastName,
    required String email,
    required String gender,
    required int age,
    required int heightCm,
    required double weightKg,
    required bool isEatingDisorderSupport,
  }) async {
    state = const AsyncLoading();

    final deviceId = await _ensureDeviceId();
    final allClients = await CoachStorageService.loadClients();
    final newId = await _reserveNextClientId(allClients);
    final now = DateTime.now();

    final newClient = CoachClient(
      clientId: newId,
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      email: email.trim(),
      gender: gender,
      age: age,
      heightCm: heightCm,
      weightKg: weightKg,
      isEatingDisorderSupport: isEatingDisorderSupport,
      isArchived: false,
      linkedAt: now,
      completedDays: const [],
      lastWorkoutAt: null,
      photosDelivered: false,
      dietFollowed: false,
      communicationOk: false,
      createdAt: now,
      updatedAt: now,
      deletedAt: null,
      version: 1,
      updatedByDeviceId: deviceId,
    );

    final updated = [...allClients, newClient];
    await CoachStorageService.saveClients(updated);

    state = AsyncData(await _mapWithStats(_visibleClients(updated)));
  }

  Future<int> importArchivedClientsFromCsv(String csvString) async {
    state = const AsyncLoading();

    final deviceId = await _ensureDeviceId();
    final allClients = await CoachStorageService.loadClients();
    final rows = _parseCsv(csvString);

    if (rows.isEmpty) {
      state = AsyncData(await _mapWithStats(_visibleClients(allClients)));
      return 0;
    }

    final importedClients = <CoachClient>[];
    final existingKeys = allClients
        .map(
          (c) =>
              '${c.firstName.trim().toLowerCase()}|${c.lastName.trim().toLowerCase()}|${c.email.trim().toLowerCase()}',
        )
        .toSet();

    var workingClients = [...allClients];

    for (final row in rows) {
      final firstName = (_value(row, const [
        'jmeno',
        'jméno',
        'firstname',
        'firstName',
        'first_name',
      ])).trim();

      final lastName = (_value(row, const [
        'prijmeni',
        'příjmení',
        'lastname',
        'lastName',
        'last_name',
      ])).trim();

      final email = (_value(row, const [
        'email',
        'e-mail',
        'mail',
      ])).trim();

      if (firstName.isEmpty && lastName.isEmpty && email.isEmpty) {
        continue;
      }

      final duplicateKey =
          '${firstName.toLowerCase()}|${lastName.toLowerCase()}|${email.toLowerCase()}';

      if (existingKeys.contains(duplicateKey)) {
        continue;
      }

      final linkedAt = _parseDate(
            _value(row, const [
              'datum_zapisu',
              'datum zápisu',
              'datum',
              'linkedAt',
              'linked_at',
            ]),
          ) ??
          DateTime.now();

      final newId = await _reserveNextClientId(workingClients);

      final client = CoachClient(
        clientId: newId,
        firstName: firstName.isEmpty ? '—' : firstName,
        lastName: lastName.isEmpty ? '—' : lastName,
        email: email,
        gender: 'other',
        age: _intOrZero(
          _value(row, const [
            'vek',
            'věk',
            'age',
          ]),
        ),
        heightCm: _intOrZero(
          _value(row, const [
            'heightCm',
            'height',
            'vyska',
            'výška',
          ]),
        ),
        weightKg: _doubleOrZero(
          _value(row, const [
            'vaha',
            'váha',
            'weightKg',
            'weight',
          ]),
        ),
        isEatingDisorderSupport: false,
        isArchived: true,
        linkedAt: linkedAt,
        completedDays: const [],
        lastWorkoutAt: null,
        photosDelivered: false,
        dietFollowed: false,
        communicationOk: false,
        createdAt: linkedAt,
        updatedAt: DateTime.now(),
        deletedAt: null,
        version: 1,
        updatedByDeviceId: deviceId,
      );

      importedClients.add(client);
      workingClients = [...workingClients, client];
      existingKeys.add(duplicateKey);
    }

    if (importedClients.isEmpty) {
      state = AsyncData(await _mapWithStats(_visibleClients(allClients)));
      return 0;
    }

    final updated = [...allClients, ...importedClients];
    await CoachStorageService.saveClients(updated);

    state = AsyncData(await _mapWithStats(_visibleClients(updated)));
    return importedClients.length;
  }

  Future<void> restoreArchivedClient(String clientId) async {
    state = const AsyncLoading();

    final deviceId = await _ensureDeviceId();
    final now = DateTime.now();
    final allClients = await CoachStorageService.loadClients();

    final updated = allClients.map((client) {
      if (client.clientId != clientId) return client;

      return client.copyWith(
        isArchived: false,
        updatedAt: now,
        version: client.version + 1,
        updatedByDeviceId: deviceId,
      );
    }).toList();

    await CoachStorageService.saveClients(updated);
    state = AsyncData(await _mapWithStats(_visibleClients(updated)));
  }

  Future<void> archiveClient(String clientId) async {
    state = const AsyncLoading();

    final deviceId = await _ensureDeviceId();
    final now = DateTime.now();
    final allClients = await CoachStorageService.loadClients();

    final updated = allClients.map((client) {
      if (client.clientId != clientId) return client;

      return client.copyWith(
        isArchived: true,
        updatedAt: now,
        version: client.version + 1,
        updatedByDeviceId: deviceId,
      );
    }).toList();

    await CoachStorageService.saveClients(updated);
    state = AsyncData(await _mapWithStats(_visibleClients(updated)));
  }

  Future<void> updateClientBasic({
    required String clientId,
    required String firstName,
    required String lastName,
    required String email,
    required String gender,
    required int age,
    required int heightCm,
    required double weightKg,
    required bool isEatingDisorderSupport,
  }) async {
    state = const AsyncLoading();

    final deviceId = await _ensureDeviceId();
    final now = DateTime.now();
    final allClients = await CoachStorageService.loadClients();

    final updated = allClients.map((c) {
      if (c.clientId != clientId) return c;

      return c.copyWith(
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        email: email.trim(),
        gender: gender,
        age: age,
        heightCm: heightCm,
        weightKg: weightKg,
        isEatingDisorderSupport: isEatingDisorderSupport,
        updatedAt: now,
        version: c.version + 1,
        updatedByDeviceId: deviceId,
      );
    }).toList();

    await CoachStorageService.saveClients(updated);
    state = AsyncData(await _mapWithStats(_visibleClients(updated)));
  }

  Future<void> setPhotosDelivered({
    required String clientId,
    required bool value,
  }) async {
    await _updateClientTrackingFlag(
      clientId: clientId,
      update: (client, now, deviceId) => client.copyWith(
        photosDelivered: value,
        updatedAt: now,
        version: client.version + 1,
        updatedByDeviceId: deviceId,
      ),
    );
  }

  Future<void> setDietFollowed({
    required String clientId,
    required bool value,
  }) async {
    await _updateClientTrackingFlag(
      clientId: clientId,
      update: (client, now, deviceId) => client.copyWith(
        dietFollowed: value,
        updatedAt: now,
        version: client.version + 1,
        updatedByDeviceId: deviceId,
      ),
    );
  }

  Future<void> setCommunicationOk({
    required String clientId,
    required bool value,
  }) async {
    await _updateClientTrackingFlag(
      clientId: clientId,
      update: (client, now, deviceId) => client.copyWith(
        communicationOk: value,
        updatedAt: now,
        version: client.version + 1,
        updatedByDeviceId: deviceId,
      ),
    );
  }

  Future<void> deleteClient(String clientId) async {
    state = const AsyncLoading();

    final deviceId = await _ensureDeviceId();
    final now = DateTime.now();
    final allClients = await CoachStorageService.loadClients();

    final updatedClients = allClients.map((c) {
      if (c.clientId != clientId) return c;

      return c.copyWith(
        updatedAt: now,
        deletedAt: now,
        version: c.version + 1,
        updatedByDeviceId: deviceId,
      );
    }).toList();

    await CoachStorageService.saveClients(updatedClients);

    await CoachStorageService.deleteClientDetails(clientId);
    await CoachStorageService.deleteNotesForClient(clientId);
    await CoachStorageService.deleteCircumferencesForClient(clientId);
    await CoachStorageService.deleteInbodyForClient(clientId);
    await CoachStorageService.deleteGoalsForClient(clientId);
    await CoachStorageService.deleteDiagnosticsForClient(clientId);
    await CoachStorageService.deleteOverridesForClient(clientId);

    state = AsyncData(await _mapWithStats(_visibleClients(updatedClients)));
  }

  Future<void> _updateClientTrackingFlag({
    required String clientId,
    required CoachClient Function(
      CoachClient client,
      DateTime now,
      String deviceId,
    ) update,
  }) async {
    state = const AsyncLoading();

    final deviceId = await _ensureDeviceId();
    final now = DateTime.now();
    final allClients = await CoachStorageService.loadClients();

    final updated = allClients.map((client) {
      if (client.clientId != clientId) return client;
      return update(client, now, deviceId);
    }).toList();

    await CoachStorageService.saveClients(updated);
    state = AsyncData(await _mapWithStats(_visibleClients(updated)));
  }

  Future<int> _getNextClientNumber() async {
    final current = await CoachStorageService.loadInt(_idCounterKey) ?? 0;
    final next = current + 1;
    await CoachStorageService.saveInt(_idCounterKey, next);
    return next;
  }

  Future<String> _reserveNextClientId(List<CoachClient> allClients) async {
    int next = await _getNextClientNumber();

    while (true) {
      final newId = 'C${next.toString().padLeft(4, '0')}';
      final exists = allClients.any((c) => c.clientId == newId);

      if (!exists) {
        await CoachStorageService.saveInt(_idCounterKey, next);
        return newId;
      }

      next++;
      await CoachStorageService.saveInt(_idCounterKey, next);
    }
  }

  Future<String> _ensureDeviceId() async {
    final existing = await CoachStorageService.loadDeviceId();
    if (existing != null && existing.trim().isNotEmpty) {
      return existing;
    }

    final newId = _uuid.v4();
    await CoachStorageService.saveDeviceId(newId);
    return newId;
  }

  Future<List<CoachClient>> _loadVisibleClients() async {
    final clients = await CoachStorageService.loadClients();
    return _visibleClients(clients);
  }

  List<CoachClient> _visibleClients(List<CoachClient> clients) {
    return clients.where((c) => !c.isDeleted).toList();
  }

  Future<List<CoachClientWithStats>> _mapWithStats(
    List<CoachClient> clients,
  ) async {
    final now = DateTime.now();

    final result = clients.map((c) {
      final completedDaysInLast7 = _countCompletedDaysInLast7(
        c.completedDays,
        now,
      );

      final compliance7d = completedDaysInLast7 / 7.0;
      final lastSessionAt = c.lastWorkoutAt;
      final isInactive7d = lastSessionAt == null
          ? true
          : now.difference(lastSessionAt).inDays > 7;

      return CoachClientWithStats(
        client: c,
        compliance7d: compliance7d,
        lastSessionAt: lastSessionAt,
        completedDaysInLast7: completedDaysInLast7,
        isInactive7d: isInactive7d,
      );
    }).toList();

    result.sort((a, b) {
      if (a.client.clientId == 'local_user') return -1;
      if (b.client.clientId == 'local_user') return 1;

      if (a.client.isArchived != b.client.isArchived) {
        return a.client.isArchived ? 1 : -1;
      }

      if (a.isInactive7d != b.isInactive7d) {
        return a.isInactive7d ? -1 : 1;
      }

      final nameA =
          '${a.client.firstName.trim()} ${a.client.lastName.trim()}'.toLowerCase();
      final nameB =
          '${b.client.firstName.trim()} ${b.client.lastName.trim()}'.toLowerCase();

      return nameA.compareTo(nameB);
    });

    return result;
  }

  int _countCompletedDaysInLast7(List<DateTime> completedDays, DateTime now) {
    final today = _normalizeDate(now);
    final minDate = today.subtract(const Duration(days: 6));

    final unique = <String>{};
    for (final raw in completedDays) {
      final day = _normalizeDate(raw);
      if (day.isBefore(minDate) || day.isAfter(today)) {
        continue;
      }
      unique.add(day.toIso8601String());
    }

    return unique.length;
  }

  List<Map<String, String>> _parseCsv(String csvString) {
    final lines = csvString
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    if (lines.isEmpty) return [];

    final delimiter = _detectDelimiter(lines.first);
    final headers = _splitCsvLine(lines.first, delimiter)
        .map(_normalizeHeader)
        .toList();

    final rows = <Map<String, String>>[];

    for (int i = 1; i < lines.length; i++) {
      final values = _splitCsvLine(lines[i], delimiter);
      final row = <String, String>{};

      for (int j = 0; j < headers.length; j++) {
        final key = headers[j];
        if (key.isEmpty) continue;

        row[key] = j < values.length ? values[j].trim() : '';
      }

      rows.add(row);
    }

    return rows;
  }

  String _detectDelimiter(String headerLine) {
    final commaCount = ','.allMatches(headerLine).length;
    final semicolonCount = ';'.allMatches(headerLine).length;

    return semicolonCount > commaCount ? ';' : ',';
  }

  List<String> _splitCsvLine(String line, String delimiter) {
    final values = <String>[];
    final buffer = StringBuffer();
    var insideQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final char = line[i];

      if (char == '"') {
        final isEscapedQuote =
            insideQuotes && i + 1 < line.length && line[i + 1] == '"';

        if (isEscapedQuote) {
          buffer.write('"');
          i++;
        } else {
          insideQuotes = !insideQuotes;
        }

        continue;
      }

      if (char == delimiter && !insideQuotes) {
        values.add(buffer.toString());
        buffer.clear();
        continue;
      }

      buffer.write(char);
    }

    values.add(buffer.toString());
    return values;
  }

  String _normalizeHeader(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('"', '')
        .replaceAll('á', 'a')
        .replaceAll('č', 'c')
        .replaceAll('ď', 'd')
        .replaceAll('é', 'e')
        .replaceAll('ě', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ň', 'n')
        .replaceAll('ó', 'o')
        .replaceAll('ř', 'r')
        .replaceAll('š', 's')
        .replaceAll('ť', 't')
        .replaceAll('ú', 'u')
        .replaceAll('ů', 'u')
        .replaceAll('ý', 'y')
        .replaceAll('ž', 'z');
  }

  String _value(Map<String, String> row, List<String> keys) {
    for (final key in keys) {
      final normalizedKey = _normalizeHeader(key);

      if (row.containsKey(normalizedKey)) {
        return row[normalizedKey] ?? '';
      }
    }

    return '';
  }

  int _intOrZero(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 0;

    return int.tryParse(trimmed) ?? 0;
  }

  double _doubleOrZero(String value) {
    final trimmed = value.trim().replaceAll(',', '.');
    if (trimmed.isEmpty) return 0.0;

    return double.tryParse(trimmed) ?? 0.0;
  }

  DateTime? _parseDate(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;

    final isoDate = DateTime.tryParse(trimmed);
    if (isoDate != null) return isoDate;

    final parts = trimmed.split('.');
    if (parts.length == 3) {
      final day = int.tryParse(parts[0].trim());
      final month = int.tryParse(parts[1].trim());
      final year = int.tryParse(parts[2].trim());

      if (day != null && month != null && year != null) {
        return DateTime(year, month, day);
      }
    }

    return null;
  }

  static DateTime _normalizeDate(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    final na = _normalizeDate(a);
    final nb = _normalizeDate(b);
    return na.year == nb.year && na.month == nb.month && na.day == nb.day;
  }

  bool _isSensitive(UserProfile profile) {
    final g = profile.goal;
    if (g == null) return false;

    return g.reason == GoalReason.eatingDisorderSupport ||
        g.type == GoalType.weightGainSupport;
  }
}