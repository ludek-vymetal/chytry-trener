import '../../core/training/actual_set.dart';
import '../../core/training/sessions/exercise_log_entry.dart';
import '../../core/training/sessions/training_session.dart';
import '../../core/training/training_plan_models.dart';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/custom_training_plan.dart';
import 'online_coaching_service.dart';

/// Jedna odcvičená série.
class LoggedSet {
  final double? weightKg;
  final int? reps;
  final bool done;

  const LoggedSet({this.weightKg, this.reps, this.done = false});

  Map<String, dynamic> toJson() => {'w': weightKg, 'r': reps, 'd': done};

  factory LoggedSet.fromJson(Map<String, dynamic> j) => LoggedSet(
        weightKg: (j['w'] as num?)?.toDouble(),
        reps: (j['r'] as num?)?.toInt(),
        done: (j['d'] as bool?) ?? false,
      );
}

/// Výsledek jednoho cviku.
class ExerciseResult {
  final String name;
  final List<LoggedSet> sets;

  const ExerciseResult({required this.name, required this.sets});

  Map<String, dynamic> toJson() => {
        'name': name,
        'sets': [for (final s in sets) s.toJson()],
      };

  factory ExerciseResult.fromJson(Map<String, dynamic> j) => ExerciseResult(
        name: (j['name'] ?? '') as String,
        sets: [
          for (final s in (j['sets'] as List? ?? const []))
            LoggedSet.fromJson(Map<String, dynamic>.from(s as Map)),
        ],
      );
}

/// Trénink, který trenér klientovi „uvolnil“ na konkrétní den.
///
/// Online klient nevidí celý tréninkový plán – jen tréninky, které mu
/// trenér pošle (dnes, zítra, max. týden dopředu).
class WorkoutAssignment {
  final String id;

  /// Den tréninku (jen datum).
  final DateTime date;
  final String title;
  final List<CustomTrainingExercise> exercises;
  final String? coachNote;

  /// 'assigned' = čeká, 'done' = odesláno klientem.
  final String status;
  final List<ExerciseResult> results;
  final String? clientNote;
  final DateTime? completedAt;

  /// Odkazy na video s technikou (název cviku → URL).
  final Map<String, String> videos;

  const WorkoutAssignment({
    required this.id,
    required this.date,
    required this.title,
    required this.exercises,
    this.coachNote,
    this.status = 'assigned',
    this.results = const [],
    this.clientNote,
    this.completedAt,
    this.videos = const {},
  });

  bool get isDone => status == 'done';

  static String dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  WorkoutAssignment copyWith({
    String? status,
    List<ExerciseResult>? results,
    String? clientNote,
    DateTime? completedAt,
  }) =>
      WorkoutAssignment(
        id: id,
        date: date,
        title: title,
        exercises: exercises,
        coachNote: coachNote,
        status: status ?? this.status,
        results: results ?? this.results,
        clientNote: clientNote ?? this.clientNote,
        completedAt: completedAt ?? this.completedAt,
        videos: videos,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': dayKey(date),
        'title': title,
        'exercises': [for (final e in exercises) e.toJson()],
        'coachNote': coachNote,
        'status': status,
        'results': [for (final r in results) r.toJson()],
        'clientNote': clientNote,
        'completedAt': completedAt?.toIso8601String(),
        'videos': videos,
      };

  factory WorkoutAssignment.fromJson(Map<String, dynamic> j) =>
      WorkoutAssignment(
        id: j['id'] as String,
        date: DateTime.tryParse((j['date'] ?? '') as String) ?? DateTime.now(),
        title: (j['title'] ?? 'Trénink') as String,
        exercises: [
          for (final e in (j['exercises'] as List? ?? const []))
            CustomTrainingExercise.fromJson(Map<String, dynamic>.from(e as Map)),
        ],
        coachNote: j['coachNote'] as String?,
        status: (j['status'] ?? 'assigned') as String,
        results: [
          for (final r in (j['results'] as List? ?? const []))
            ExerciseResult.fromJson(Map<String, dynamic>.from(r as Map)),
        ],
        clientNote: j['clientNote'] as String?,
        completedAt: DateTime.tryParse((j['completedAt'] ?? '') as String),
        videos: {
          if (j['videos'] is Map)
            for (final e in (j['videos'] as Map).entries)
              e.key.toString(): e.value.toString(),
        },
      );
}

/// Odcvičený trénink od trenéra jako běžný záznam tréninku – aby se
/// objevil v „Posledních trénincích“, docházce i skóre klienta.
TrainingSession sessionFromAssignment(WorkoutAssignment a, String clientId) {
  return TrainingSession(
    date: DateTime(a.date.year, a.date.month, a.date.day),
    dayPlan: TrainingDayPlan(
      dayLabel: a.title,
      focus: 'Online trénink od trenéra',
      exercises: [
        for (final e in a.exercises)
          PlannedExercise(
            name: e.customName,
            exerciseId: e.exerciseId,
            sets: e.sets,
            reps: e.reps,
            rir: e.rir,
            note: e.note,
            weightKg: e.weightKg,
          ),
      ],
    ),
    entries: [
      for (final r in a.results)
        if (r.sets.any((s) => s.done || s.reps != null))
          ExerciseLogEntry(
            exerciseKey: r.name,
            plannedSets: const [],
            actualSets: [
              for (final s in r.sets)
                if (s.done || s.reps != null)
                  ActualSet(weightKg: s.weightKg, reps: s.reps ?? 0),
            ],
          ),
    ],
    completed: true,
    updatedAt: a.completedAt ?? DateTime.now(),
    clientId: clientId,
  );
}

/// Posílání tréninků klientovi po jednotlivých dnech.
class WorkoutAssignmentService {
  WorkoutAssignmentService._();

  static const _sub = 'workouts';
  static const _cacheKey = 'coaching_workouts_cache_v1';

  /// Jak daleko dopředu smí trenér trénink poslat.
  static const maxDaysAhead = 7;

  static FirebaseFirestore get _db => FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> _ref(String linkId) =>
      _db.collection('coaching').doc(linkId).collection(_sub);

  static String? _linkIdForCoach(String clientId) {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null || u.isAnonymous) return null;
    return OnlineCoachingService.linkIdFor(u.uid, clientId);
  }

  // ---------------- trenér ----------------

  static Future<List<WorkoutAssignment>> listForClient(String clientId) async {
    final linkId = _linkIdForCoach(clientId);
    if (linkId == null) return const [];
    final q = await _ref(linkId).get();
    final list = [
      for (final d in q.docs) WorkoutAssignment.fromJson(d.data()),
    ]..sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  /// Živý seznam tréninků klienta – po odeslání klientem se hned
  /// objeví „odcvičeno“ (null = nepřihlášený trenér).
  static Stream<List<WorkoutAssignment>>? watchForClient(String clientId) {
    final linkId = _linkIdForCoach(clientId);
    if (linkId == null) return null;
    return _ref(linkId).snapshots().map((q) => [
          for (final d in q.docs) WorkoutAssignment.fromJson(d.data()),
        ]..sort((a, b) => b.date.compareTo(a.date)));
  }

  static Future<void> assign(
    String clientId,
    List<WorkoutAssignment> items,
  ) async {
    final linkId = _linkIdForCoach(clientId);
    if (linkId == null) {
      throw StateError('Nejsi přihlášená jako trenér.');
    }
    final batch = _db.batch();
    for (final a in items) {
      batch.set(_ref(linkId).doc(a.id), {
        ...a.toJson(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  static Future<void> delete(String clientId, String id) async {
    final linkId = _linkIdForCoach(clientId);
    if (linkId == null) return;
    await _ref(linkId).doc(id).delete();
  }

  static String newId() => 'w_${DateTime.now().microsecondsSinceEpoch}';

  // ---------------- klient ----------------

  /// Tréninky klienta (z cloudu, bez internetu z poslední kopie).
  static Future<List<WorkoutAssignment>> listMine() async {
    final link = await OnlineCoachingService.localClientLink();
    if (link == null) return const [];
    final prefs = await SharedPreferences.getInstance();
    try {
      final q = await _ref(link.linkId).get();
      final list = [
        for (final d in q.docs) WorkoutAssignment.fromJson(d.data()),
      ]..sort((a, b) => a.date.compareTo(b.date));
      await prefs.setString(
        _cacheKey,
        jsonEncode([for (final a in list) a.toJson()]),
      );
      return list;
    } catch (_) {
      final raw = prefs.getString(_cacheKey);
      if (raw == null) return const [];
      return [
        for (final e in (jsonDecode(raw) as List))
          WorkoutAssignment.fromJson(Map<String, dynamic>.from(e as Map)),
      ];
    }
  }

  /// Klient odešle odcvičený trénink trenérovi.
  static Future<void> submit(WorkoutAssignment done) async {
    final link = await OnlineCoachingService.localClientLink();
    if (link == null) throw StateError('Nejsi propojený s trenérem.');
    await _ref(link.linkId).doc(done.id).set({
      ...done.toJson(),
      'submittedAt': FieldValue.serverTimestamp(),
    });
  }
}
