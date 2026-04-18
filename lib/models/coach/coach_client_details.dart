class CoachClientDetails {
  final String clientId;

  /// sedavé | aktivní | těžká manuální
  final String activityType;

  /// např. "programátor", "skladník", ...
  final String occupation;

  /// zranění / operace / omezení
  final String injuries;

  /// alergie (např. "ořechy, mléko")
  final String allergies;

  /// intolerance (např. "laktóza, lepek")
  final String intolerances;

  /// zdravotní poznámky (tlak, záda, léky...) – česky
  final String healthNotes;

  /// průměr spánku (hodiny), např. 7.5
  final double sleepHours;

  /// kvalita spánku: "dobrá" | "průměrná" | "špatná"
  final String sleepQuality;

  /// stres: "nízký" | "střední" | "vysoký"
  final String stressLevel;

  /// orientačně kroky / den
  final int stepsPerDay;

  /// 1–2 věty: cíl, motivace
  final String motivation;

  /// co klient rád jí
  final String preferredFoods;

  /// co klient nechce / vadí mu
  final String dislikedFoods;

  // --------------------------
  // Sync metadata
  // --------------------------
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final int version;
  final String updatedByDeviceId;

  const CoachClientDetails({
    required this.clientId,
    this.activityType = 'sedavé',
    this.occupation = '',
    this.injuries = '',
    this.allergies = '',
    this.intolerances = '',
    this.healthNotes = '',
    this.sleepHours = 7.0,
    this.sleepQuality = 'průměrná',
    this.stressLevel = 'střední',
    this.stepsPerDay = 6000,
    this.motivation = '',
    this.preferredFoods = '',
    this.dislikedFoods = '',
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
    required this.version,
    required this.updatedByDeviceId,
  });

  bool get isDeleted => deletedAt != null;

  CoachClientDetails copyWith({
    String? clientId,
    String? activityType,
    String? occupation,
    String? injuries,
    String? allergies,
    String? intolerances,
    String? healthNotes,
    double? sleepHours,
    String? sleepQuality,
    String? stressLevel,
    int? stepsPerDay,
    String? motivation,
    String? preferredFoods,
    String? dislikedFoods,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
    int? version,
    String? updatedByDeviceId,
  }) {
    return CoachClientDetails(
      clientId: clientId ?? this.clientId,
      activityType: activityType ?? this.activityType,
      occupation: occupation ?? this.occupation,
      injuries: injuries ?? this.injuries,
      allergies: allergies ?? this.allergies,
      intolerances: intolerances ?? this.intolerances,
      healthNotes: healthNotes ?? this.healthNotes,
      sleepHours: sleepHours ?? this.sleepHours,
      sleepQuality: sleepQuality ?? this.sleepQuality,
      stressLevel: stressLevel ?? this.stressLevel,
      stepsPerDay: stepsPerDay ?? this.stepsPerDay,
      motivation: motivation ?? this.motivation,
      preferredFoods: preferredFoods ?? this.preferredFoods,
      dislikedFoods: dislikedFoods ?? this.dislikedFoods,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
      version: version ?? this.version,
      updatedByDeviceId: updatedByDeviceId ?? this.updatedByDeviceId,
    );
  }

  Map<String, dynamic> toJson() => {
        'clientId': clientId,
        'activityType': activityType,
        'occupation': occupation,
        'injuries': injuries,
        'allergies': allergies,
        'intolerances': intolerances,
        'healthNotes': healthNotes,
        'sleepHours': sleepHours,
        'sleepQuality': sleepQuality,
        'stressLevel': stressLevel,
        'stepsPerDay': stepsPerDay,
        'motivation': motivation,
        'preferredFoods': preferredFoods,
        'dislikedFoods': dislikedFoods,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'deletedAt': deletedAt?.toIso8601String(),
        'version': version,
        'updatedByDeviceId': updatedByDeviceId,
      };

  factory CoachClientDetails.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();

    return CoachClientDetails(
      clientId: (json['clientId'] as String?) ?? '',
      activityType: (json['activityType'] as String?) ?? 'sedavé',
      occupation: (json['occupation'] as String?) ?? '',
      injuries: (json['injuries'] as String?) ?? '',
      allergies: (json['allergies'] as String?) ?? '',
      intolerances: (json['intolerances'] as String?) ?? '',
      healthNotes: (json['healthNotes'] as String?) ?? '',
      sleepHours: (json['sleepHours'] as num?)?.toDouble() ?? 7.0,
      sleepQuality: (json['sleepQuality'] as String?) ?? 'průměrná',
      stressLevel: (json['stressLevel'] as String?) ?? 'střední',
      stepsPerDay: (json['stepsPerDay'] as num?)?.toInt() ?? 6000,
      motivation: (json['motivation'] as String?) ?? '',
      preferredFoods: (json['preferredFoods'] as String?) ?? '',
      dislikedFoods: (json['dislikedFoods'] as String?) ?? '',
      createdAt:
          DateTime.tryParse((json['createdAt'] as String?) ?? '') ?? now,
      updatedAt:
          DateTime.tryParse((json['updatedAt'] as String?) ?? '') ?? now,
      deletedAt: (json['deletedAt'] as String?) == null
          ? null
          : DateTime.tryParse(json['deletedAt'] as String),
      version: (json['version'] as num?)?.toInt() ?? 1,
      updatedByDeviceId: (json['updatedByDeviceId'] as String?) ?? 'local',
    );
  }
}