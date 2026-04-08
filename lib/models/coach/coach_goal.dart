class CoachGoal {
  final String clientId;

  /// sila | postava | hubnuti | vytrvalost | nabirani | podpora_prijmu
  final String goalType;

  /// detail cíle (např. "forma", "závody", "redukce tuku")
  final String goalDetail;

  /// cílová hmotnost (volitelně)
  final double? targetWeightKg;

  /// cílové % tuku pro postavu/hubnutí
  final double? targetBodyFatPercent;

  /// trenér může zapnout/vypnout BMI v hodnocení
  /// default false = pro sportovce bezpečné
  final bool useBmiInInsights;

  /// poznámky trenéra k cíli
  final String note;

  // --------------------------
  // SYNC METADATA
  // --------------------------
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final int version;
  final String updatedByDeviceId;

  const CoachGoal({
    required this.clientId,
    this.goalType = 'postava',
    this.goalDetail = '',
    this.targetWeightKg,
    this.targetBodyFatPercent,
    this.useBmiInInsights = false,
    this.note = '',
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.version = 1,
    this.updatedByDeviceId = '',
  });

  bool get isDeleted => deletedAt != null;

  CoachGoal copyWith({
    String? clientId,
    String? goalType,
    String? goalDetail,
    double? targetWeightKg,
    bool clearTargetWeightKg = false,
    double? targetBodyFatPercent,
    bool clearTargetBodyFatPercent = false,
    bool? useBmiInInsights,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
    int? version,
    String? updatedByDeviceId,
  }) {
    return CoachGoal(
      clientId: clientId ?? this.clientId,
      goalType: goalType ?? this.goalType,
      goalDetail: goalDetail ?? this.goalDetail,
      targetWeightKg: clearTargetWeightKg
          ? null
          : (targetWeightKg ?? this.targetWeightKg),
      targetBodyFatPercent: clearTargetBodyFatPercent
          ? null
          : (targetBodyFatPercent ?? this.targetBodyFatPercent),
      useBmiInInsights: useBmiInInsights ?? this.useBmiInInsights,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
      version: version ?? this.version,
      updatedByDeviceId: updatedByDeviceId ?? this.updatedByDeviceId,
    );
  }

  Map<String, dynamic> toJson() => {
        'clientId': clientId,
        'goalType': goalType,
        'goalDetail': goalDetail,
        'targetWeightKg': targetWeightKg,
        'targetBodyFatPercent': targetBodyFatPercent,
        'useBmiInInsights': useBmiInInsights,
        'note': note,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'deletedAt': deletedAt?.toIso8601String(),
        'version': version,
        'updatedByDeviceId': updatedByDeviceId,
      };

  factory CoachGoal.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();

    return CoachGoal(
      clientId: (json['clientId'] as String?) ?? '',
      goalType: (json['goalType'] as String?) ?? 'postava',
      goalDetail: (json['goalDetail'] as String?) ?? '',
      targetWeightKg: (json['targetWeightKg'] as num?)?.toDouble(),
      targetBodyFatPercent:
          (json['targetBodyFatPercent'] as num?)?.toDouble(),
      useBmiInInsights: (json['useBmiInInsights'] as bool?) ?? false,
      note: (json['note'] as String?) ?? '',
      createdAt: DateTime.tryParse((json['createdAt'] as String?) ?? '') ?? now,
      updatedAt:
          DateTime.tryParse((json['updatedAt'] as String?) ?? '') ?? now,
      deletedAt: DateTime.tryParse((json['deletedAt'] as String?) ?? ''),
      version: (json['version'] as num?)?.toInt() ?? 1,
      updatedByDeviceId: (json['updatedByDeviceId'] as String?) ?? '',
    );
  }
}