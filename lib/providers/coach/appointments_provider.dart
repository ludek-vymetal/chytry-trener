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
    _load();
  }

  static const key = 'coach_appointments_v1';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return;
    try {
      final d = jsonDecode(raw);
      if (d is List) {
        state = [
          for (final e in d)
            if (e is Map) Appointment.fromJson(Map<String, dynamic>.from(e)),
        ]..sort((a, b) => a.start.compareTo(b.start));
      }
    } catch (_) {}
  }

  Future<void> _save(List<Appointment> next) async {
    next.sort((a, b) => a.start.compareTo(b.start));
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode([for (final a in next) a.toJson()]));
    ExtraBackupService.schedulePush();
  }

  Future<void> addAll(List<Appointment> items) => _save([...state, ...items]);

  Future<void> update(Appointment a) =>
      _save([for (final e in state) e.id == a.id ? a : e]);

  Future<void> delete(String id) =>
      _save(state.where((e) => e.id != id).toList());
}

final appointmentsProvider =
    StateNotifierProvider<AppointmentsNotifier, List<Appointment>>(
  (ref) => AppointmentsNotifier(),
);
