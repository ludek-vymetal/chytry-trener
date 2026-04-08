import 'package:flutter/material.dart';
import '../core/training/training_split.dart';
import 'coach/coach_client.dart';
import 'goal.dart';
import 'measurement.dart';
import 'body_circumference.dart';
import '../core/training/intake/training_intake.dart';

class UserProfile {
  final String? clientId;

  final String firstName;
  final String lastName;
  final String email;

  final int age;
  final String gender;
  final int height; // cm
  final double weight; // kg
  final double tdee;

  final Goal? goal;
  final List<Measurement> measurements;
  final List<BodyCircumference> circumferences;

  final TrainingSplit? preferredSplit;
  final TrainingIntake? trainingIntake;

  final String selectedPlan;
  final bool isFasting;
  final TimeOfDay? fastingStartTime;
  final int fastingDuration;

  const UserProfile({
    this.clientId,
    this.firstName = '',
    this.lastName = '',
    this.email = '',
    this.age = 0,
    this.gender = 'other',
    this.height = 0,
    this.weight = 0.0,
    this.tdee = 2000.0,
    this.goal,
    this.measurements = const [],
    this.circumferences = const [],
    this.preferredSplit,
    this.trainingIntake,
    this.selectedPlan = 'Vlny',
    this.isFasting = false,
    this.fastingStartTime,
    this.fastingDuration = 16,
  });

  String get displayName {
    final full = '${firstName.trim()} ${lastName.trim()}'.trim();
    return full.isEmpty ? 'Klient' : full;
  }

  factory UserProfile.fromCoach(CoachClient coach) {
    return UserProfile(
      clientId: coach.clientId,
      firstName: coach.firstName,
      lastName: coach.lastName,
      email: coach.email,
      age: coach.age,
      gender: coach.gender,
      height: coach.heightCm,
      weight: coach.weightKg,
      tdee: 2000.0,
    );
  }

  UserProfile copyWith({
    String? clientId,
    String? firstName,
    String? lastName,
    String? email,
    int? age,
    String? gender,
    int? height,
    double? weight,
    double? tdee,
    Goal? goal,
    bool clearGoal = false,
    List<Measurement>? measurements,
    List<BodyCircumference>? circumferences,
    TrainingSplit? preferredSplit,
    bool clearPreferredSplit = false,
    TrainingIntake? trainingIntake,
    bool clearTrainingIntake = false,
    String? selectedPlan,
    bool? isFasting,
    TimeOfDay? fastingStartTime,
    bool clearFastingStartTime = false,
    int? fastingDuration,
  }) {
    return UserProfile(
      clientId: clientId ?? this.clientId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      tdee: tdee ?? this.tdee,
      goal: clearGoal ? null : (goal ?? this.goal),
      measurements: measurements ?? this.measurements,
      circumferences: circumferences ?? this.circumferences,
      preferredSplit: clearPreferredSplit
          ? null
          : (preferredSplit ?? this.preferredSplit),
      trainingIntake: clearTrainingIntake
          ? null
          : (trainingIntake ?? this.trainingIntake),
      selectedPlan: selectedPlan ?? this.selectedPlan,
      isFasting: isFasting ?? this.isFasting,
      fastingStartTime: clearFastingStartTime
          ? null
          : (fastingStartTime ?? this.fastingStartTime),
      fastingDuration: fastingDuration ?? this.fastingDuration,
    );
  }

  Map<String, dynamic> toJson() => {
        'clientId': clientId,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'age': age,
        'gender': gender,
        'height': height,
        'weight': weight,
        'tdee': tdee,
        'goal': goal == null
            ? null
            : {
                'type': goal!.type.name,
                'reason': goal!.reason.name,
                'startDate': goal!.startDate.toIso8601String(),
                'targetDate': goal!.targetDate.toIso8601String(),
                'planMode': goal!.planMode.name,
                'phase': goal!.phase?.name,
                'targetWeightKg': goal!.targetWeightKg,
                'note': goal!.note,
              },
        'measurements': measurements
            .map(
              (m) => {
                'date': m.date.toIso8601String(),
                'weight': m.weight,
              },
            )
            .toList(),
        'circumferences': circumferences
            .map(
              (c) => {
                'date': c.date.toIso8601String(),
                'neck': c.neck,
                'chest': c.chest,
                'waist': c.waist,
                'hips': c.hips,
                'biceps': c.biceps,
                'thigh': c.thigh,
              },
            )
            .toList(),
        'preferredSplit': preferredSplit?.name,
        'trainingIntake': trainingIntake == null
            ? null
            : {
                'frequencyPerWeek': trainingIntake!.frequencyPerWeek,
                'equipment': trainingIntake!.equipment.toList(),
                'experienceLevel': trainingIntake!.experienceLevel,
                'oneRMs': trainingIntake!.oneRMs,
                'trainingMaxPercent': trainingIntake!.trainingMaxPercent,
              },
        'selectedPlan': selectedPlan,
        'isFasting': isFasting,
        'fastingStartTime': fastingStartTime == null
            ? null
            : {
                'hour': fastingStartTime!.hour,
                'minute': fastingStartTime!.minute,
              },
        'fastingDuration': fastingDuration,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final rawFastingTime = json['fastingStartTime'];
    final rawGoal = json['goal'];
    final rawMeasurements = json['measurements'];
    final rawCircumferences = json['circumferences'];
    final rawTrainingIntake = json['trainingIntake'];

    Goal? parsedGoal;
    if (rawGoal is Map) {
      final map = Map<String, dynamic>.from(rawGoal);
      parsedGoal = Goal(
        type: GoalType.values.byName(
          (map['type'] as String?) ?? GoalType.physique.name,
        ),
        reason: GoalReason.values.byName(
          (map['reason'] as String?) ?? GoalReason.aesthetic.name,
        ),
        startDate: DateTime.tryParse((map['startDate'] as String?) ?? '') ??
            DateTime.now(),
        targetDate:
            DateTime.tryParse((map['targetDate'] as String?) ?? '') ??
                DateTime.now().add(const Duration(days: 90)),
        planMode: GoalPlanMode.values.byName(
          (map['planMode'] as String?) ?? GoalPlanMode.auto.name,
        ),
        phase: map['phase'] == null
            ? null
            : GoalPhase.values.byName(map['phase'] as String),
        targetWeightKg: (map['targetWeightKg'] as num?)?.toDouble(),
        note: map['note'] as String?,
      );
    }

    final parsedMeasurements = rawMeasurements is List
        ? rawMeasurements.map((item) {
            final map = Map<String, dynamic>.from(item as Map);
            return Measurement(
              date: DateTime.tryParse((map['date'] as String?) ?? '') ??
                  DateTime.now(),
              weight: (map['weight'] as num?)?.toDouble() ?? 0.0,
            );
          }).toList()
        : <Measurement>[];

    final parsedCircumferences = rawCircumferences is List
        ? rawCircumferences.map((item) {
            final map = Map<String, dynamic>.from(item as Map);
            return BodyCircumference(
              date: DateTime.tryParse((map['date'] as String?) ?? '') ??
                  DateTime.now(),
              neck: (map['neck'] as num?)?.toDouble() ?? 0.0,
              chest: (map['chest'] as num?)?.toDouble() ?? 0.0,
              waist: (map['waist'] as num?)?.toDouble() ?? 0.0,
              hips: (map['hips'] as num?)?.toDouble() ?? 0.0,
              biceps: (map['biceps'] as num?)?.toDouble() ?? 0.0,
              thigh: (map['thigh'] as num?)?.toDouble() ?? 0.0,
            );
          }).toList()
        : <BodyCircumference>[];

    TrainingIntake? parsedTrainingIntake;
    if (rawTrainingIntake is Map) {
      final map = Map<String, dynamic>.from(rawTrainingIntake);

      final rawEquipment = (map['equipment'] as List?) ?? const [];
      final rawOneRms = map['oneRMs'];

      parsedTrainingIntake = TrainingIntake(
        frequencyPerWeek: (map['frequencyPerWeek'] as num?)?.toInt() ?? 3,
        equipment: rawEquipment.map((e) => e.toString()).toSet(),
        experienceLevel: (map['experienceLevel'] as String?) ?? 'beginner',
        oneRMs: rawOneRms is Map
            ? rawOneRms.map(
                (key, value) => MapEntry(
                  key.toString(),
                  (value as num).toDouble(),
                ),
              )
            : <String, double>{},
        trainingMaxPercent:
            (map['trainingMaxPercent'] as num?)?.toDouble() ?? 0.90,
      );
    }

    TrainingSplit? parsedPreferredSplit;
    final rawPreferredSplit = json['preferredSplit'];
    if (rawPreferredSplit is String && rawPreferredSplit.isNotEmpty) {
      try {
        parsedPreferredSplit = TrainingSplit.values.byName(rawPreferredSplit);
      } catch (_) {
        parsedPreferredSplit = null;
      }
    }

    return UserProfile(
      clientId: json['clientId'] as String?,
      firstName: (json['firstName'] as String?) ?? '',
      lastName: (json['lastName'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
      age: (json['age'] as num?)?.toInt() ?? 0,
      gender: (json['gender'] as String?) ?? 'other',
      height: (json['height'] as num?)?.toInt() ?? 0,
      weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
      tdee: (json['tdee'] as num?)?.toDouble() ?? 2000.0,
      goal: parsedGoal,
      measurements: parsedMeasurements,
      circumferences: parsedCircumferences,
      preferredSplit: parsedPreferredSplit,
      trainingIntake: parsedTrainingIntake,
      selectedPlan: (json['selectedPlan'] as String?) ?? 'Vlny',
      isFasting: (json['isFasting'] as bool?) ?? false,
      fastingStartTime: rawFastingTime is Map
          ? TimeOfDay(
              hour: (rawFastingTime['hour'] as num?)?.toInt() ?? 0,
              minute: (rawFastingTime['minute'] as num?)?.toInt() ?? 0,
            )
          : null,
      fastingDuration: (json['fastingDuration'] as num?)?.toInt() ?? 16,
    );
  }
}