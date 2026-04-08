enum GoalType {
  strength,
  physique,
  weightLoss,
  endurance,
  weightGainSupport,
}

enum GoalReason {
  competition,
  summerShape,
  health,
  performance,
  aesthetic,
  eatingDisorderSupport,
}

enum GoalPlanMode {
  auto,
  normal,
  accelerated,
}

enum GoalPhase {
  build,
  cut,
  strength,
  maintain,
}

class Goal {
  final GoalType type;
  final GoalReason reason;

  final DateTime startDate;
  final DateTime targetDate;

  final GoalPlanMode planMode;

  /// legacy
  final GoalPhase? phase;

  final double? targetWeightKg;
  final String? note;

  Goal({
    required this.type,
    required this.reason,
    required this.targetDate,
    DateTime? startDate,
    this.planMode = GoalPlanMode.auto,
    this.phase,
    this.targetWeightKg,
    this.note,
  }) : startDate = startDate ?? DateTime.now();

  Goal copyWith({
    GoalType? type,
    GoalReason? reason,
    DateTime? startDate,
    DateTime? targetDate,
    GoalPlanMode? planMode,
    GoalPhase? phase,
    double? targetWeightKg,
    String? note,
  }) {
    return Goal(
      type: type ?? this.type,
      reason: reason ?? this.reason,
      startDate: startDate ?? this.startDate,
      targetDate: targetDate ?? this.targetDate,
      planMode: planMode ?? this.planMode,
      phase: phase ?? this.phase,
      targetWeightKg: targetWeightKg ?? this.targetWeightKg,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'reason': reason.name,
        'startDate': startDate.toIso8601String(),
        'targetDate': targetDate.toIso8601String(),
        'planMode': planMode.name,
        'phase': phase?.name,
        'targetWeightKg': targetWeightKg,
        'note': note,
      };

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      type: GoalType.values.byName(
        (json['type'] as String?) ?? GoalType.physique.name,
      ),
      reason: GoalReason.values.byName(
        (json['reason'] as String?) ?? GoalReason.health.name,
      ),
      startDate: DateTime.tryParse(
            (json['startDate'] as String?) ?? '',
          ) ??
          DateTime.now(),
      targetDate: DateTime.tryParse(
            (json['targetDate'] as String?) ?? '',
          ) ??
          DateTime.now().add(const Duration(days: 90)),
      planMode: GoalPlanMode.values.byName(
        (json['planMode'] as String?) ?? GoalPlanMode.auto.name,
      ),
      phase: (json['phase'] as String?) == null
          ? null
          : GoalPhase.values.byName(json['phase'] as String),
      targetWeightKg: (json['targetWeightKg'] as num?)?.toDouble(),
      note: json['note'] as String?,
    );
  }

  @override
  String toString() {
    return 'Goal(type: $type, reason: $reason, '
        'startDate: $startDate, targetDate: $targetDate, '
        'planMode: $planMode, phase: $phase, '
        'targetWeightKg: $targetWeightKg, note: $note)';
  }
}