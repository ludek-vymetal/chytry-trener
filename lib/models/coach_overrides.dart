import '../../models/goal.dart';

class CoachOverrides {
  final String clientId;

  /// 0.7..1.3
  final double volumeMultiplier;

  /// volitelné – může zpomalit/zrychlit (zatím ukládáme, později napojíme do plánování)
  final GoalPlanMode? planModeOverride;

  final DateTime updatedAt;

  const CoachOverrides({
    required this.clientId,
    this.volumeMultiplier = 1.0,
    this.planModeOverride,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'clientId': clientId,
        'volumeMultiplier': volumeMultiplier,
        'planModeOverride': planModeOverride?.name,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory CoachOverrides.fromJson(Map<String, dynamic> json) => CoachOverrides(
        clientId: json['clientId'] as String,
        volumeMultiplier: (json['volumeMultiplier'] as num?)?.toDouble() ?? 1.0,
        planModeOverride: json['planModeOverride'] == null
            ? null
            : GoalPlanMode.values.byName(json['planModeOverride'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}