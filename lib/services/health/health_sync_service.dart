import 'dart:convert';
import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../coach/online_coaching_service.dart';

/// Jeden trénink zaznamenaný hodinkami (běh, kolo, posilovna…).
class HealthWorkout {
  final String type;
  final DateTime start;
  final int minutes;
  final int kcal;
  final int distanceM;

  const HealthWorkout({
    required this.type,
    required this.start,
    required this.minutes,
    required this.kcal,
    required this.distanceM,
  });

  /// Český název podle typu z Apple Zdraví / Health Connect.
  String get label => HealthSyncService.workoutLabel(type);

  Map<String, dynamic> toJson() => {
        't': type,
        's': start.toIso8601String(),
        'm': minutes,
        'k': kcal,
        'd': distanceM,
      };

  factory HealthWorkout.fromJson(Map<String, dynamic> j) => HealthWorkout(
        type: (j['t'] ?? 'OTHER').toString(),
        start: DateTime.tryParse((j['s'] ?? '').toString()) ?? DateTime(2000),
        minutes: (j['m'] as num?)?.toInt() ?? 0,
        kcal: (j['k'] as num?)?.toInt() ?? 0,
        distanceM: (j['d'] as num?)?.toInt() ?? 0,
      );
}

/// Souhrn jednoho dne z hodinek / telefonu.
class HealthDay {
  /// Půlnoc daného dne (místní čas).
  final DateTime date;
  final int steps;
  final int activeKcal;
  final int distanceM;

  /// Spánek v minutách – noc, která tento den RÁNO skončila.
  final int sleepMin;
  final int? restingHr;
  final double? weight;
  final List<HealthWorkout> workouts;

  const HealthDay({
    required this.date,
    this.steps = 0,
    this.activeKcal = 0,
    this.distanceM = 0,
    this.sleepMin = 0,
    this.restingHr,
    this.weight,
    this.workouts = const [],
  });

  bool get isEmpty =>
      steps == 0 &&
      activeKcal == 0 &&
      distanceM == 0 &&
      sleepMin == 0 &&
      restingHr == null &&
      weight == null &&
      workouts.isEmpty;

  static String keyOf(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String get key => keyOf(date);

  Map<String, dynamic> toJson() => {
        'd': key,
        'st': steps,
        'kc': activeKcal,
        'di': distanceM,
        'sl': sleepMin,
        if (restingHr != null) 'hr': restingHr,
        if (weight != null) 'w': weight,
        if (workouts.isNotEmpty) 'wo': [for (final w in workouts) w.toJson()],
      };

  factory HealthDay.fromJson(Map<String, dynamic> j) {
    final parts = (j['d'] ?? '').toString().split('-');
    DateTime date = DateTime(2000);
    if (parts.length == 3) {
      date = DateTime(
        int.tryParse(parts[0]) ?? 2000,
        int.tryParse(parts[1]) ?? 1,
        int.tryParse(parts[2]) ?? 1,
      );
    }
    return HealthDay(
      date: date,
      steps: (j['st'] as num?)?.toInt() ?? 0,
      activeKcal: (j['kc'] as num?)?.toInt() ?? 0,
      distanceM: (j['di'] as num?)?.toInt() ?? 0,
      sleepMin: (j['sl'] as num?)?.toInt() ?? 0,
      restingHr: (j['hr'] as num?)?.toInt(),
      weight: (j['w'] as num?)?.toDouble(),
      workouts: [
        for (final w in (j['wo'] as List?) ?? const [])
          if (w is Map) HealthWorkout.fromJson(Map<String, dynamic>.from(w)),
      ],
    );
  }
}

/// Výsledek pokusu o propojení.
enum HealthConnectResult {
  ok,

  /// Android: chybí (nebo je zastaralá) aplikace Health Connect.
  needsHealthConnect,

  /// Uživatel přístup nepovolil.
  denied,

  /// Na tomto zařízení to nejde (Windows, web…).
  unsupported,

  error,
}

/// Napojení na Apple Zdraví (iPhone) a Health Connect (Android).
///
/// Do těchto aplikací posílají data skoro všechny hodinky a náramky
/// (Apple Watch, Garmin, Samsung, Fitbit, Xiaomi, Amazfit, Polar…),
/// takže SPAL nemusí podporovat každou značku zvlášť.
///
/// Data se jen ČTOU – nic se do zdravotních aplikací nezapisuje.
/// Uloží se v telefonu a u propojeného klienta i trenérovi
/// do `coaching/{linkId}/data/activity`.
class HealthSyncService {
  HealthSyncService._();

  static const enabledKey = 'health_enabled_v1';
  static const daysKey = 'health_days_v1';
  static const lastSyncKey = 'health_last_sync_v1';
  static const stepGoalKey = 'health_step_goal_v1';
  static const promptDismissedKey = 'health_prompt_dismissed_v1';

  /// Kolik dní zpět se načítá.
  static const historyDays = 30;

  static const defaultStepGoal = 8000;

  static final Health _health = Health();
  static bool _configured = false;

  /// Funguje jen v aplikaci na telefonu.
  static bool get supported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  static bool get isIOS => !kIsWeb && Platform.isIOS;

  /// Název zdravotní aplikace v telefonu.
  static String get platformAppName =>
      isIOS ? 'Apple Zdraví' : 'Health Connect';

  static List<HealthDataType> get _types => isIOS
      ? const [
          HealthDataType.STEPS,
          HealthDataType.ACTIVE_ENERGY_BURNED,
          HealthDataType.DISTANCE_WALKING_RUNNING,
          HealthDataType.SLEEP_ASLEEP,
          HealthDataType.SLEEP_LIGHT,
          HealthDataType.SLEEP_DEEP,
          HealthDataType.SLEEP_REM,
          HealthDataType.RESTING_HEART_RATE,
          HealthDataType.WEIGHT,
          HealthDataType.WORKOUT,
        ]
      : const [
          HealthDataType.STEPS,
          HealthDataType.ACTIVE_ENERGY_BURNED,
          HealthDataType.TOTAL_CALORIES_BURNED,
          HealthDataType.DISTANCE_DELTA,
          HealthDataType.SLEEP_SESSION,
          HealthDataType.RESTING_HEART_RATE,
          HealthDataType.WEIGHT,
          HealthDataType.WORKOUT,
        ];

  static Future<void> _ensureConfigured() async {
    if (_configured) return;
    await _health.configure();
    _configured = true;
  }

  // =================================================================
  // Propojení
  // =================================================================

  /// Požádá o přístup k datům. Na iPhonu se okno Apple Zdraví ukáže jen
  /// poprvé – později se oprávnění mění v aplikaci Zdraví.
  static Future<HealthConnectResult> connect() async {
    if (!supported) return HealthConnectResult.unsupported;
    try {
      await _ensureConfigured();
      if (Platform.isAndroid) {
        final status = await _health.getHealthConnectSdkStatus();
        if (status != HealthConnectSdkStatus.sdkAvailable) {
          return HealthConnectResult.needsHealthConnect;
        }
      }
      final types = _types;
      final ok = await _health.requestAuthorization(
        types,
        permissions: [for (final _ in types) HealthDataAccess.READ],
      );
      if (!ok) return HealthConnectResult.denied;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(enabledKey, true);
      return HealthConnectResult.ok;
    } catch (e) {
      debugPrint('HealthSyncService.connect: $e');
      return HealthConnectResult.error;
    }
  }

  /// Android: otevře obchod s aplikací Health Connect.
  static Future<void> installHealthConnect() async {
    if (!supported || !Platform.isAndroid) return;
    try {
      await _ensureConfigured();
      await _health.installHealthConnect();
    } catch (_) {}
  }

  /// Vypne propojení v aplikaci a smaže uložená data (i u trenéra).
  static Future<void> disconnect() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(enabledKey, false);
    await prefs.remove(daysKey);
    await prefs.remove(lastSyncKey);
    try {
      final link = await OnlineCoachingService.localClientLink();
      if (link != null) await _activityDoc(link.linkId).delete();
    } catch (_) {}
    if (supported) {
      try {
        await _ensureConfigured();
        await _health.revokePermissions();
      } catch (_) {}
    }
  }

  // =================================================================
  // Načtení dat
  // =================================================================

  static DateTime _day(DateTime d) {
    final l = d.toLocal();
    return DateTime(l.year, l.month, l.day);
  }

  static double _num(HealthDataPoint p) {
    final v = p.value;
    if (v is NumericHealthValue) return v.numericValue.toDouble();
    return 0;
  }

  /// Součet po dnech. Když stejná data posílá víc zdrojů (telefon
  /// i hodinky), vezme se jen ten s nejvyšším součtem – nesčítají se.
  static Map<String, double> _sumPerDay(
    List<HealthDataPoint> points,
    double Function(HealthDataPoint) valueOf, {
    bool byEnd = false,
  }) {
    final perSource = <String, Map<String, double>>{};
    for (final p in points) {
      final key = HealthDay.keyOf(_day(byEnd ? p.dateTo : p.dateFrom));
      final src = p.sourceId.isEmpty ? p.sourceName : p.sourceId;
      final m = perSource.putIfAbsent(key, () => {});
      m[src] = (m[src] ?? 0) + valueOf(p);
    }
    return {
      for (final e in perSource.entries)
        e.key: e.value.values.fold<double>(0, (a, b) => a > b ? a : b),
    };
  }

  static Future<List<HealthDataPoint>> _read(
    HealthDataType type,
    DateTime from,
    DateTime to,
  ) async {
    try {
      return await _health.getHealthDataFromTypes(
        types: [type],
        startTime: from,
        endTime: to,
      );
    } catch (e) {
      debugPrint('HealthSyncService: $type – $e');
      return const [];
    }
  }

  /// Načte posledních [days] dní z Apple Zdraví / Health Connect.
  static Future<List<HealthDay>> fetch({int days = historyDays}) async {
    if (!supported) return const [];
    await _ensureConfigured();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final from = today.subtract(Duration(days: days - 1));
    // Spánek z noci před prvním dnem začíná už večer předtím.
    final sleepFrom = from.subtract(const Duration(hours: 12));

    // ---- kroky: přesný součet po dnech (bez dvojího počítání) ----
    final steps = <String, int>{};
    for (var i = 0; i < days; i++) {
      final d = from.add(Duration(days: i));
      final end = i == days - 1 ? now : DateTime(d.year, d.month, d.day + 1);
      try {
        final s = await _health.getTotalStepsInInterval(d, end);
        if (s != null && s > 0) steps[HealthDay.keyOf(d)] = s;
      } catch (_) {}
    }

    final kcal = _sumPerDay(
      await _read(HealthDataType.ACTIVE_ENERGY_BURNED, from, now),
      _num,
    );
    final distance = _sumPerDay(
      await _read(
        isIOS
            ? HealthDataType.DISTANCE_WALKING_RUNNING
            : HealthDataType.DISTANCE_DELTA,
        from,
        now,
      ),
      _num,
    );

    // ---- spánek: přiřadí se ke dni, kdy ráno skončil ----
    final sleepPoints = <HealthDataPoint>[
      if (isIOS) ...[
        ...await _read(HealthDataType.SLEEP_ASLEEP, sleepFrom, now),
        ...await _read(HealthDataType.SLEEP_LIGHT, sleepFrom, now),
        ...await _read(HealthDataType.SLEEP_DEEP, sleepFrom, now),
        ...await _read(HealthDataType.SLEEP_REM, sleepFrom, now),
      ] else
        ...await _read(HealthDataType.SLEEP_SESSION, sleepFrom, now),
    ];
    final sleep = _sumPerDay(
      sleepPoints,
      (p) => p.dateTo.difference(p.dateFrom).inMinutes.toDouble(),
      byEnd: true,
    );

    // ---- klidový tep a váha: průměr / poslední hodnota dne ----
    final hrSum = <String, double>{};
    final hrCount = <String, int>{};
    for (final p in await _read(HealthDataType.RESTING_HEART_RATE, from, now)) {
      final k = HealthDay.keyOf(_day(p.dateFrom));
      hrSum[k] = (hrSum[k] ?? 0) + _num(p);
      hrCount[k] = (hrCount[k] ?? 0) + 1;
    }
    final weight = <String, (DateTime, double)>{};
    for (final p in await _read(HealthDataType.WEIGHT, from, now)) {
      final k = HealthDay.keyOf(_day(p.dateFrom));
      final v = _num(p);
      if (v < 20 || v > 400) continue;
      final prev = weight[k];
      if (prev == null || p.dateFrom.isAfter(prev.$1)) {
        weight[k] = (p.dateFrom, v);
      }
    }

    // ---- tréninky ----
    final workouts = <String, List<HealthWorkout>>{};
    final seen = <String>{};
    for (final p in await _read(HealthDataType.WORKOUT, from, now)) {
      final v = p.value;
      if (v is! WorkoutHealthValue) continue;
      final start = p.dateFrom.toLocal();
      final minutes = p.dateTo.difference(p.dateFrom).inMinutes;
      final id = '${start.millisecondsSinceEpoch}_${v.workoutActivityType.name}';
      if (!seen.add(id) || minutes <= 0) continue;
      workouts.putIfAbsent(HealthDay.keyOf(_day(start)), () => []).add(
            HealthWorkout(
              type: v.workoutActivityType.name,
              start: start,
              minutes: minutes,
              kcal: v.totalEnergyBurned ?? 0,
              distanceM: v.totalDistance ?? 0,
            ),
          );
    }

    final result = <HealthDay>[];
    for (var i = 0; i < days; i++) {
      final d = from.add(Duration(days: i));
      final k = HealthDay.keyOf(d);
      final count = hrCount[k] ?? 0;
      result.add(
        HealthDay(
          date: d,
          steps: steps[k] ?? 0,
          activeKcal: (kcal[k] ?? 0).round(),
          distanceM: (distance[k] ?? 0).round(),
          sleepMin: (sleep[k] ?? 0).round().clamp(0, 16 * 60).toInt(),
          restingHr: count == 0 ? null : (hrSum[k]! / count).round(),
          weight: weight[k]?.$2,
          workouts: (workouts[k] ?? [])
            ..sort((a, b) => a.start.compareTo(b.start)),
        ),
      );
    }
    return result;
  }

  // =================================================================
  // Uložení v telefonu
  // =================================================================

  static Future<List<HealthDay>> loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(daysKey);
    if (raw == null) return const [];
    try {
      final list = jsonDecode(raw) as List;
      return [
        for (final e in list)
          if (e is Map) HealthDay.fromJson(Map<String, dynamic>.from(e)),
      ]..sort((a, b) => a.date.compareTo(b.date));
    } catch (_) {
      return const [];
    }
  }

  static Future<void> saveLocal(List<HealthDay> days) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      daysKey,
      jsonEncode([for (final d in days) d.toJson()]),
    );
    await prefs.setString(lastSyncKey, DateTime.now().toIso8601String());
  }

  // =================================================================
  // Sdílení s trenérem
  // =================================================================

  static DocumentReference<Map<String, dynamic>> _activityDoc(String linkId) =>
      FirebaseFirestore.instance
          .collection('coaching')
          .doc(linkId)
          .collection('data')
          .doc('activity');

  /// Klient: pošle souhrn trenérovi (jen když je propojený).
  static Future<void> pushToCoach(List<HealthDay> days) async {
    try {
      final link = await OnlineCoachingService.localClientLink();
      if (link == null) return;
      await _activityDoc(link.linkId).set({
        'days': [
          for (final d in days)
            if (!d.isEmpty) d.toJson(),
        ],
        'source': platformAppName,
        'updatedAt': FieldValue.serverTimestamp(),
        'uid': FirebaseAuth.instance.currentUser?.uid,
      });
    } catch (e) {
      debugPrint('HealthSyncService.pushToCoach: $e');
    }
  }

  /// Trenér: živá data klienta. `null` = klient hodinky nepropojil.
  static Stream<({List<HealthDay> days, DateTime? updatedAt, String source})?>
      watchForLink(String linkId) {
    return _activityDoc(linkId).snapshots().map((s) {
      final data = s.data();
      if (!s.exists || data == null) return null;
      final ts = data['updatedAt'];
      return (
        days: [
          for (final e in (data['days'] as List?) ?? const [])
            if (e is Map) HealthDay.fromJson(Map<String, dynamic>.from(e)),
        ]..sort((a, b) => a.date.compareTo(b.date)),
        updatedAt: ts is Timestamp ? ts.toDate() : null,
        source: (data['source'] ?? '').toString(),
      );
    });
  }

  // =================================================================
  // Popisky
  // =================================================================

  static String workoutLabel(String type) {
    final t = type.toUpperCase();
    if (t.contains('STRENGTH') || t.contains('WEIGHT')) return 'Posilování';
    if (t.contains('RUNNING') && t.contains('TREADMILL')) return 'Běh na pásu';
    if (t.contains('RUNNING')) return 'Běh';
    if (t.contains('WALKING')) return 'Chůze';
    if (t.contains('HIKING')) return 'Turistika';
    if (t.contains('BIKING') || t.contains('CYCLING')) return 'Kolo';
    if (t.contains('SWIM')) return 'Plavání';
    if (t.contains('YOGA')) return 'Jóga';
    if (t.contains('PILATES')) return 'Pilates';
    if (t.contains('HIGH_INTENSITY') || t.contains('HIIT')) return 'HIIT';
    if (t.contains('ELLIPTICAL')) return 'Eliptický trenažér';
    if (t.contains('ROWING')) return 'Veslování';
    if (t.contains('STAIR')) return 'Schody';
    if (t.contains('DANCE') || t.contains('DANCING')) return 'Tanec';
    if (t.contains('CROSS_TRAINING') || t.contains('CROSSFIT')) {
      return 'Kruhový trénink';
    }
    if (t.contains('BOXING') || t.contains('MARTIAL') || t.contains('KICK')) {
      return 'Bojové sporty';
    }
    if (t.contains('TENNIS') ||
        t.contains('SQUASH') ||
        t.contains('BADMINTON')) {
      return 'Raketové sporty';
    }
    if (t.contains('SOCCER') ||
        t.contains('FOOTBALL') ||
        t.contains('BASKETBALL') ||
        t.contains('VOLLEYBALL') ||
        t.contains('HOCKEY')) {
      return 'Míčové sporty';
    }
    if (t.contains('SKIING') || t.contains('SNOWBOARD')) return 'Lyže';
    return 'Trénink';
  }
}
