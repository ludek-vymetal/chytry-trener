import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/coach/coach_client.dart';
import '../../models/coach/coach_goal.dart';
import '../../models/custom_training_plan.dart';
import '../../models/daily_intake.dart';
import '../../models/user_profile.dart';
import '../coach/coach_storage_service.dart';
import '../local_storage_service.dart';
import '../macro_service.dart';
import '../metabolism_service.dart';

/// Jeden odtrénovaný den (zjednodušený záznam pro souhrn).
class ReportSession {
  final DateTime date;
  final String dayLabel;
  final bool completed;
  final int exercisesLogged;
  final int sets;
  final double volumeKg;

  const ReportSession({
    required this.date,
    required this.dayLabel,
    required this.completed,
    required this.exercisesLogged,
    required this.sets,
    required this.volumeKg,
  });
}

/// Jeden zapsaný den jídla.
class ReportFoodDay {
  final DateTime date;
  final DailyIntake intake;

  const ReportFoodDay(this.date, this.intake);
}

/// Doplňková data klienta pro PDF souhrn (profil, trénink, strava, cíl).
/// Čte se přímo z úložiště, takže funguje pro kteréhokoli klienta –
/// nejen pro toho, který je právě aktivní.
class ClientReportExtras {
  final UserProfile? profile;
  final MacroTarget? macros;
  final CustomTrainingPlan? activePlan;
  final CoachGoal? coachGoal;
  final List<ReportSession> sessions;
  final List<ReportFoodDay> foodDays;

  const ClientReportExtras({
    required this.profile,
    required this.macros,
    required this.activePlan,
    required this.coachGoal,
    required this.sessions,
    required this.foodDays,
  });

  static bool _inRange(DateTime d, DateTime from, DateTime to) =>
      !d.isBefore(DateTime(from.year, from.month, from.day)) &&
      !d.isAfter(DateTime(to.year, to.month, to.day, 23, 59, 59));

  static Future<ClientReportExtras> load({
    required CoachClient client,
    required DateTime from,
    required DateTime to,
  }) async {
    final id = client.clientId;

    // Profil klienta (cíl, jídelníček, makra)
    UserProfile? profile;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('user_profile_storage_$id');
      if (raw != null && raw.isNotEmpty) {
        profile = UserProfile.fromJson(
          Map<String, dynamic>.from(json.decode(raw) as Map),
        );
      }
    } catch (_) {
      profile = null;
    }

    MacroTarget? macros;
    final p = profile;
    if (p != null && p.weight > 0 && p.height > 0 && p.goal != null) {
      try {
        final tdee = MetabolismService.calculateTDEE(
          p,
          MetabolismService.activityFor(p),
        );
        macros = MacroService.calculate(p, tdee);
      } catch (_) {
        macros = null;
      }
    }

    // Aktivní tréninkový plán
    CustomTrainingPlan? activePlan;
    try {
      final plans = await CoachStorageService.loadCustomTrainingPlans();
      final mine = plans.where((x) => x.clientId == id).toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      final active = mine.where((x) => x.isActive);
      activePlan = active.isNotEmpty
          ? active.first
          : (mine.isNotEmpty ? mine.first : null);
    } catch (_) {
      activePlan = null;
    }

    // Cíl nastavený trenérem
    CoachGoal? coachGoal;
    try {
      final goals = await CoachStorageService.loadGoalsAll();
      final mine = goals.where((g) => g.clientId == id && !g.isDeleted);
      coachGoal = mine.isNotEmpty ? mine.first : null;
    } catch (_) {
      coachGoal = null;
    }

    // Tréninky
    final sessions = <ReportSession>[];
    try {
      final raw = await CoachStorageService.loadTrainingSessionsRaw();
      final byDay = <String, ReportSession>{};
      for (final s in raw) {
        if (s['clientId'] != id) continue;
        if (s['deletedAt'] != null) continue;
        final date = DateTime.tryParse((s['date'] ?? '').toString());
        if (date == null || !_inRange(date, from, to)) continue;

        final dayPlan = s['dayPlan'];
        final label = dayPlan is Map
            ? (dayPlan['dayLabel'] ?? '').toString()
            : '';
        var exercises = 0;
        var sets = 0;
        var volume = 0.0;
        final entries = s['entries'];
        if (entries is List) {
          for (final e in entries.whereType<Map>()) {
            final actual = e['actualSets'];
            if (actual is! List || actual.isEmpty) continue;
            exercises++;
            for (final a in actual.whereType<Map>()) {
              sets++;
              final w = (a['weightKg'] as num?)?.toDouble() ?? 0;
              final r = (a['reps'] as num?)?.toInt() ?? 0;
              volume += w * r;
            }
          }
        }
        final session = ReportSession(
          date: date,
          dayLabel: label,
          completed: s['completed'] == true,
          exercisesLogged: exercises,
          sets: sets,
          volumeKg: volume,
        );
        final key = '${date.year}-${date.month}-${date.day}';
        final prev = byDay[key];
        if (prev == null || session.sets >= prev.sets) byDay[key] = session;
      }
      sessions.addAll(byDay.values);
      sessions.sort((a, b) => a.date.compareTo(b.date));
    } catch (_) {
      sessions.clear();
    }

    // Strava
    final foodDays = <ReportFoodDay>[];
    try {
      final history = await LocalStorageService.loadDailyHistory(clientId: id);
      if (history != null) {
        for (final entry in history.entries) {
          final date = DateTime.tryParse(entry.key);
          if (date == null || !_inRange(date, from, to)) continue;
          final value = entry.value;
          if (value is! Map) continue;
          final intake = DailyIntake.fromJson(Map<String, dynamic>.from(value));
          if (intake.calories <= 0 && intake.items.isEmpty) continue;
          foodDays.add(ReportFoodDay(date, intake));
        }
        foodDays.sort((a, b) => a.date.compareTo(b.date));
      }
    } catch (_) {
      foodDays.clear();
    }

    return ClientReportExtras(
      profile: profile,
      macros: macros,
      activePlan: activePlan,
      coachGoal: coachGoal,
      sessions: sessions,
      foodDays: foodDays,
    );
  }
}
