import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/coach/extra_backup_service.dart';

/// Druh termínu v kalendáři.
enum AppointmentType { training, massage, consult, other }

extension AppointmentTypeX on AppointmentType {
  String get label => switch (this) {
        AppointmentType.training => 'Trénink',
        AppointmentType.massage => 'Masáž',
        AppointmentType.consult => 'Konzultace',
        AppointmentType.other => 'Jiné',
      };

  IconData get icon => switch (this) {
        AppointmentType.training => Icons.fitness_center,
        AppointmentType.massage => Icons.spa_outlined,
        AppointmentType.consult => Icons.forum_outlined,
        AppointmentType.other => Icons.event_note,
      };

  Color get color => switch (this) {
        AppointmentType.training => const Color(0xFF0F766E),
        AppointmentType.massage => const Color(0xFF7C3AED),
        AppointmentType.consult => const Color(0xFF2563EB),
        AppointmentType.other => const Color(0xFF6B7280),
      };
}

/// Stav termínu.
enum AppointmentStatus { planned, done, cancelled }

class Appointment {
  final String id;
  final String? clientId;
  final String clientName;
  final AppointmentType type;
  final DateTime start;
  final int minutes;
  final String note;
  final AppointmentStatus status;

  const Appointment({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.type,
    required this.start,
    required this.minutes,
    required this.note,
    this.status = AppointmentStatus.planned,
  });

  DateTime get end => start.add(Duration(minutes: minutes));

  Appointment copyWith({
    String? clientId,
    String? clientName,
    AppointmentType? type,
    DateTime? start,
    int? minutes,
    String? note,
    AppointmentStatus? status,
  }) =>
      Appointment(
        id: id,
        clientId: clientId ?? this.clientId,
        clientName: clientName ?? this.clientName,
        type: type ?? this.type,
        start: start ?? this.start,
        minutes: minutes ?? this.minutes,
        note: note ?? this.note,
        status: status ?? this.status,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'clientId': clientId,
        'clientName': clientName,
        'type': type.name,
        'start': start.toIso8601String(),
        'minutes': minutes,
        'note': note,
        'status': status.name,
      };

  factory Appointment.fromJson(Map<String, dynamic> j) => Appointment(
        id: (j['id'] ?? '').toString(),
        clientId: j['clientId'] as String?,
        clientName: (j['clientName'] ?? '').toString(),
        type: AppointmentType.values.firstWhere(
          (t) => t.name == j['type'],
          orElse: () => AppointmentType.training,
        ),
        start:
            DateTime.tryParse((j['start'] ?? '').toString()) ?? DateTime.now(),
        minutes: (j['minutes'] as num?)?.toInt() ?? 60,
        note: (j['note'] ?? '').toString(),
        status: AppointmentStatus.values.firstWhere(
          (s) => s.name == j['status'],
          orElse: () => AppointmentStatus.planned,
        ),
      );
}

class AppointmentsNotifier extends StateNotifier<List<Appointment>> {
  AppointmentsNotifier() : super(const []) {
    ready = _load();
  }

  /// Dokončí se po načtení termínů ze zařízení.
  late final Future<void> ready;

  static const key = 'coach_appointments_v1';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (!mounted || raw == null || raw.isEmpty) return;
    try {
      final d = jsonDecode(raw);
      if (d is List) {
        final loaded = [
          for (final e in d)
            if (e is Map) Appointment.fromJson(Map<String, dynamic>.from(e)),
        ];
        final clean = dedupe(loaded);
        if (clean.length != loaded.length) {
          // Stejný termín zapsaný v mobilu i na PC → nechat jeden
          // (smazání duplicity se propíše i do ostatních zařízení).
          await _save(clean);
        } else {
          state = clean..sort((a, b) => a.start.compareTo(b.start));
        }
      }
    } catch (_) {}
  }

  static String _slotKey(Appointment a) {
    final who = (a.clientId != null && a.clientId!.isNotEmpty)
        ? a.clientId!
        : a.clientName.trim().toLowerCase();
    return '$who|${a.start.toIso8601String()}|${a.type.name}';
  }

  /// Který ze dvou stejných termínů ponechat (vždy stejně na všech
  /// zařízeních): termín z online rezervace, pak hotový, pak s poznámkou.
  static int _rank(Appointment a) =>
      (a.id.startsWith('bk_') ? 100 : 0) +
      (a.status == AppointmentStatus.done ? 10 : 0) +
      (a.note.trim().isNotEmpty ? 1 : 0);

  /// Odstraní duplicitní termíny (stejný klient, začátek a druh).
  /// Zrušený termín se za duplicitu nepovažuje.
  static List<Appointment> dedupe(List<Appointment> items) {
    final best = <String, Appointment>{};
    final out = <Appointment>[];
    for (final a in items) {
      if (a.status == AppointmentStatus.cancelled) {
        out.add(a);
        continue;
      }
      final k = _slotKey(a);
      final cur = best[k];
      if (cur == null) {
        best[k] = a;
        continue;
      }
      final ra = _rank(a), rc = _rank(cur);
      var keep = (ra > rc || (ra == rc && a.id.compareTo(cur.id) < 0)) ? a : cur;
      final other = identical(keep, a) ? cur : a;
      // Hotovo na kterékoli kopii → hotovo.
      if (other.status == AppointmentStatus.done &&
          keep.status != AppointmentStatus.done) {
        keep = keep.copyWith(status: AppointmentStatus.done);
      }
      if (keep.note.trim().isEmpty && other.note.trim().isNotEmpty) {
        keep = keep.copyWith(note: other.note);
      }
      best[k] = keep;
    }
    return [...best.values, ...out];
  }

  Future<void> _save(List<Appointment> next) async {
    next.sort((a, b) => a.start.compareTo(b.start));
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      key,
      await ExtraBackupService.stampList(
        prefs,
        key,
        [for (final a in next) a.toJson()],
      ),
    );
    ExtraBackupService.schedulePush();
  }

  Future<void> addAll(List<Appointment> items) {
    final ids = {for (final a in state) a.id};
    return _save(dedupe([
      ...state,
      for (final a in items)
        if (!ids.contains(a.id)) a,
    ]));
  }

  /// Je už v kalendáři stejný termín (klient + začátek + druh)?
  Appointment? findSame(Appointment a) {
    final k = _slotKey(a);
    for (final e in state) {
      if (e.id != a.id &&
          e.status != AppointmentStatus.cancelled &&
          _slotKey(e) == k) {
        return e;
      }
    }
    return null;
  }

  Future<void> update(Appointment a) =>
      _save([for (final e in state) e.id == a.id ? a : e]);

  Future<void> delete(String id) =>
      _save(state.where((e) => e.id != id).toList());
}

final appointmentsProvider =
    StateNotifierProvider<AppointmentsNotifier, List<Appointment>>(
  (ref) => AppointmentsNotifier(),
);
