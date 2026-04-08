class CoachInbodyEntry {
  final String entryId;
  final String clientId;
  final DateTime date;

  /// výška klienta v době měření (kvůli BMI a historii)
  final int heightCm;

  // -------------------------
  // Tělesná kompozice (podle fotky)
  // -------------------------
  final double weightKg; // Hmotnost
  final double smmKg; // SMM (množství kosterní svaloviny)
  final double fatKg; // Množství tuku v těle (kg)
  final double waterKg; // Celková voda v těle (kg ~ l)
  final double leanMassKg; // Čistá hmota těla (kg)

  // -------------------------
  // Diagnóza obezity (podle fotky)
  // -------------------------
  final double bmi; // BMI
  final double bodyFatPercent; // % tuku v těle
  final double whr; // poměr pas/boky
  final double bmr; // bazální metabolismus (kcal)

  // -------------------------
  // Segmentální svaly (kg) (podle fotky)
  // -------------------------
  final double muscleLeftArmKg;
  final double muscleRightArmKg;
  final double muscleTrunkKg;
  final double muscleLeftLegKg;
  final double muscleRightLegKg;

  // -------------------------
  // Segmentální tuk (kg) (podle fotky)
  // -------------------------
  final double fatLeftArmKg;
  final double fatRightArmKg;
  final double fatTrunkKg;
  final double fatLeftLegKg;
  final double fatRightLegKg;

  // OPTIONAL (u některých reportů není, ale UI někde může čekat)
  final double? visceralFatLevel;
  final double? inbodyScore;

  // --------------------------
  // Sync metadata
  // --------------------------
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final int version;
  final String updatedByDeviceId;

  const CoachInbodyEntry({
    required this.entryId,
    required this.clientId,
    required this.date,
    required this.heightCm,
    required this.weightKg,
    required this.smmKg,
    required this.fatKg,
    required this.waterKg,
    required this.leanMassKg,
    required this.bmi,
    required this.bodyFatPercent,
    required this.whr,
    required this.bmr,
    required this.muscleLeftArmKg,
    required this.muscleRightArmKg,
    required this.muscleTrunkKg,
    required this.muscleLeftLegKg,
    required this.muscleRightLegKg,
    required this.fatLeftArmKg,
    required this.fatRightArmKg,
    required this.fatTrunkKg,
    required this.fatLeftLegKg,
    required this.fatRightLegKg,
    this.visceralFatLevel,
    this.inbodyScore,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
    required this.version,
    required this.updatedByDeviceId,
  });

  // -------------------------------------------------
  // ✅ ALIASY kvůli starému UI / staršímu kódu
  // -------------------------------------------------
  double get skeletalMuscleMassKg => smmKg;
  double get bodyFatMassKg => fatKg;
  double get percentBodyFat => bodyFatPercent;
  double get totalBodyWaterL => waterKg;

  double? get bmrKcal => bmr;

  bool get isDeleted => deletedAt != null;

  CoachInbodyEntry copyWith({
    String? entryId,
    String? clientId,
    DateTime? date,
    int? heightCm,
    double? weightKg,
    double? smmKg,
    double? fatKg,
    double? waterKg,
    double? leanMassKg,
    double? bmi,
    double? bodyFatPercent,
    double? whr,
    double? bmr,
    double? muscleLeftArmKg,
    double? muscleRightArmKg,
    double? muscleTrunkKg,
    double? muscleLeftLegKg,
    double? muscleRightLegKg,
    double? fatLeftArmKg,
    double? fatRightArmKg,
    double? fatTrunkKg,
    double? fatLeftLegKg,
    double? fatRightLegKg,
    double? visceralFatLevel,
    double? inbodyScore,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
    int? version,
    String? updatedByDeviceId,
  }) {
    return CoachInbodyEntry(
      entryId: entryId ?? this.entryId,
      clientId: clientId ?? this.clientId,
      date: date ?? this.date,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      smmKg: smmKg ?? this.smmKg,
      fatKg: fatKg ?? this.fatKg,
      waterKg: waterKg ?? this.waterKg,
      leanMassKg: leanMassKg ?? this.leanMassKg,
      bmi: bmi ?? this.bmi,
      bodyFatPercent: bodyFatPercent ?? this.bodyFatPercent,
      whr: whr ?? this.whr,
      bmr: bmr ?? this.bmr,
      muscleLeftArmKg: muscleLeftArmKg ?? this.muscleLeftArmKg,
      muscleRightArmKg: muscleRightArmKg ?? this.muscleRightArmKg,
      muscleTrunkKg: muscleTrunkKg ?? this.muscleTrunkKg,
      muscleLeftLegKg: muscleLeftLegKg ?? this.muscleLeftLegKg,
      muscleRightLegKg: muscleRightLegKg ?? this.muscleRightLegKg,
      fatLeftArmKg: fatLeftArmKg ?? this.fatLeftArmKg,
      fatRightArmKg: fatRightArmKg ?? this.fatRightArmKg,
      fatTrunkKg: fatTrunkKg ?? this.fatTrunkKg,
      fatLeftLegKg: fatLeftLegKg ?? this.fatLeftLegKg,
      fatRightLegKg: fatRightLegKg ?? this.fatRightLegKg,
      visceralFatLevel: visceralFatLevel ?? this.visceralFatLevel,
      inbodyScore: inbodyScore ?? this.inbodyScore,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
      version: version ?? this.version,
      updatedByDeviceId: updatedByDeviceId ?? this.updatedByDeviceId,
    );
  }

  Map<String, dynamic> toJson() => {
        'entryId': entryId,
        'clientId': clientId,
        'date': date.toIso8601String(),
        'heightCm': heightCm,
        'weightKg': weightKg,
        'smmKg': smmKg,
        'fatKg': fatKg,
        'waterKg': waterKg,
        'leanMassKg': leanMassKg,
        'bmi': bmi,
        'bodyFatPercent': bodyFatPercent,
        'whr': whr,
        'bmr': bmr,
        'muscleLeftArmKg': muscleLeftArmKg,
        'muscleRightArmKg': muscleRightArmKg,
        'muscleTrunkKg': muscleTrunkKg,
        'muscleLeftLegKg': muscleLeftLegKg,
        'muscleRightLegKg': muscleRightLegKg,
        'fatLeftArmKg': fatLeftArmKg,
        'fatRightArmKg': fatRightArmKg,
        'fatTrunkKg': fatTrunkKg,
        'fatLeftLegKg': fatLeftLegKg,
        'fatRightLegKg': fatRightLegKg,
        'visceralFatLevel': visceralFatLevel,
        'inbodyScore': inbodyScore,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'deletedAt': deletedAt?.toIso8601String(),
        'version': version,
        'updatedByDeviceId': updatedByDeviceId,
      };

  factory CoachInbodyEntry.fromJson(Map<String, dynamic> json) {
    double d(String k, [double fallback = 0.0]) =>
        (json[k] as num?)?.toDouble() ?? fallback;

    final now = DateTime.now();

    // zpětná kompatibilita
    final smm = d('smmKg', d('muscleKg', d('skeletalMuscleMassKg')));
    final fat = d('fatKg', d('bodyFatMassKg'));
    final pbf = d('bodyFatPercent', d('percentBodyFat'));
    final water = d('waterKg', d('totalBodyWaterL'));
    final bmr = d('bmr', d('bmrKcal'));

    final date = DateTime.tryParse((json['date'] as String?) ?? '') ?? now;

    return CoachInbodyEntry(
      entryId: json['entryId'] as String,
      clientId: json['clientId'] as String,
      date: date,
      heightCm: (json['heightCm'] as num?)?.toInt() ?? 0,
      weightKg: d('weightKg'),
      smmKg: smm,
      fatKg: fat,
      waterKg: water,
      leanMassKg: d('leanMassKg'),
      bmi: d('bmi'),
      bodyFatPercent: pbf,
      whr: d('whr'),
      bmr: bmr,
      muscleLeftArmKg: d('muscleLeftArmKg', d('smmLeftArmKg')),
      muscleRightArmKg: d('muscleRightArmKg', d('smmRightArmKg')),
      muscleTrunkKg: d('muscleTrunkKg', d('smmTrunkKg')),
      muscleLeftLegKg: d('muscleLeftLegKg', d('smmLeftLegKg')),
      muscleRightLegKg: d('muscleRightLegKg', d('smmRightLegKg')),
      fatLeftArmKg: d('fatLeftArmKg'),
      fatRightArmKg: d('fatRightArmKg'),
      fatTrunkKg: d('fatTrunkKg'),
      fatLeftLegKg: d('fatLeftLegKg'),
      fatRightLegKg: d('fatRightLegKg'),
      visceralFatLevel: (json['visceralFatLevel'] as num?)?.toDouble(),
      inbodyScore: (json['inbodyScore'] as num?)?.toDouble(),
      createdAt:
          DateTime.tryParse((json['createdAt'] as String?) ?? '') ?? date,
      updatedAt:
          DateTime.tryParse((json['updatedAt'] as String?) ?? '') ?? date,
      deletedAt: (json['deletedAt'] as String?) == null
          ? null
          : DateTime.tryParse(json['deletedAt'] as String),
      version: (json['version'] as num?)?.toInt() ?? 1,
      updatedByDeviceId: (json['updatedByDeviceId'] as String?) ?? 'local',
    );
  }
}