import '../../models/goal.dart';

class CoachOverrides {
  final String overrideId;
  final String clientId;
  final double volumeMultiplier;
  final GoalPlanMode? planModeOverride;

  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final int version;
  final String updatedByDeviceId;

  const CoachOverrides({
    required this.overrideId,
    required this.clientId,
    this.volumeMultiplier = 1.0,
    this.planModeOverride,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.version = 1,
    required this.updatedByDeviceId,
  });

  bool get isDeleted => deletedAt != null;

  CoachOverrides copyWith({
    String? overrideId,
    String? clientId,
    double? volumeMultiplier,
    GoalPlanMode? planModeOverride,
    bool clearPlanModeOverride = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
    int? version,
    String? updatedByDeviceId,
  }) {
    return CoachOverrides(
      overrideId: overrideId ?? this.overrideId,
      clientId: clientId ?? this.clientId,
      volumeMultiplier: volumeMultiplier ?? this.volumeMultiplier,
      planModeOverride: clearPlanModeOverride
          ? null
          : (planModeOverride ?? this.planModeOverride),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
      version: version ?? this.version,
      updatedByDeviceId: updatedByDeviceId ?? this.updatedByDeviceId,
    );
  }

  Map<String, dynamic> toJson() => {
        'overrideId': overrideId,
        'clientId': clientId,
        'volumeMultiplier': volumeMultiplier,
        'planModeOverride': planModeOverride?.name,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'deletedAt': deletedAt?.toIso8601String(),
        'version': version,
        'updatedByDeviceId': updatedByDeviceId,
      };

  factory CoachOverrides.fromJson(Map<String, dynamic> json) => CoachOverrides(
        overrideId: (json['overrideId'] as String?) ??
            'override_${(json['clientId'] as String?) ?? 'unknown'}',
        clientId: (json['clientId'] as String?) ?? '',
        volumeMultiplier: (json['volumeMultiplier'] as num?)?.toDouble() ?? 1.0,
        planModeOverride: json['planModeOverride'] == null
            ? null
            : GoalPlanMode.values.byName(json['planModeOverride'] as String),
        createdAt: DateTime.tryParse((json['createdAt'] as String?) ?? '') ??
            DateTime.tryParse((json['updatedAt'] as String?) ?? '') ??
            DateTime.now(),
        updatedAt: DateTime.tryParse((json['updatedAt'] as String?) ?? '') ??
            DateTime.tryParse((json['createdAt'] as String?) ?? '') ??
            DateTime.now(),
        deletedAt: DateTime.tryParse((json['deletedAt'] as String?) ?? ''),
        version: (json['version'] as num?)?.toInt() ?? 1,
        updatedByDeviceId: (json['updatedByDeviceId'] as String?) ?? '',
      );
}