class CoachBodyDiagnosticEntry {
  final String entryId;
  final String clientId;
  final DateTime date;

  /// výška v době měření (pro jistotu ukládáme)
  final int heightCm;

  /// Hmotnost (kg)
  final double weightKg;

  /// SMM – množství kosterní svaloviny (kg)
  final double muscleKg;

  /// Množství tuku v těle (kg)
  final double fatKg;

  /// Procento tuku v těle (%)
  final double fatPercent;

  /// Celková voda v těle (kg)
  final double waterKg;

  /// FFM / čistá hmotnost těla (kg) – bez tuku
  final double? fatFreeMassKg;

  /// WHR – poměr pas/boky
  final double? waistHipRatio;

  /// BMR – bazální metabolismus (kcal)
  final int? bmrKcal;

  // --------------------------
  // SYNC METADATA
  // --------------------------
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final int version;
  final String updatedByDeviceId;

  const CoachBodyDiagnosticEntry({
    required this.entryId,
    required this.clientId,
    required this.date,
    required this.heightCm,
    required this.weightKg,
    required this.muscleKg,
    required this.fatKg,
    required this.fatPercent,
    required this.waterKg,
    this.fatFreeMassKg,
    this.waistHipRatio,
    this.bmrKcal,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.version = 1,
    this.updatedByDeviceId = '',
  });

  bool get isDeleted => deletedAt != null;

  CoachBodyDiagnosticEntry copyWith({
    String? entryId,
    String? clientId,
    DateTime? date,
    int? heightCm,
    double? weightKg,
    double? muscleKg,
    double? fatKg,
    double? fatPercent,
    double? waterKg,
    double? fatFreeMassKg,
    bool clearFatFreeMassKg = false,
    double? waistHipRatio,
    bool clearWaistHipRatio = false,
    int? bmrKcal,
    bool clearBmrKcal = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
    int? version,
    String? updatedByDeviceId,
  }) {
    return CoachBodyDiagnosticEntry(
      entryId: entryId ?? this.entryId,
      clientId: clientId ?? this.clientId,
      date: date ?? this.date,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      muscleKg: muscleKg ?? this.muscleKg,
      fatKg: fatKg ?? this.fatKg,
      fatPercent: fatPercent ?? this.fatPercent,
      waterKg: waterKg ?? this.waterKg,
      fatFreeMassKg: clearFatFreeMassKg
          ? null
          : (fatFreeMassKg ?? this.fatFreeMassKg),
      waistHipRatio:
          clearWaistHipRatio ? null : (waistHipRatio ?? this.waistHipRatio),
      bmrKcal: clearBmrKcal ? null : (bmrKcal ?? this.bmrKcal),
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
        'muscleKg': muscleKg,
        'fatKg': fatKg,
        'fatPercent': fatPercent,
        'waterKg': waterKg,
        'fatFreeMassKg': fatFreeMassKg,
        'waistHipRatio': waistHipRatio,
        'bmrKcal': bmrKcal,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'deletedAt': deletedAt?.toIso8601String(),
        'version': version,
        'updatedByDeviceId': updatedByDeviceId,
      };

  factory CoachBodyDiagnosticEntry.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();

    return CoachBodyDiagnosticEntry(
      entryId: (json['entryId'] as String?) ?? '',
      clientId: (json['clientId'] as String?) ?? '',
      date: DateTime.tryParse((json['date'] as String?) ?? '') ?? now,
      heightCm: (json['heightCm'] as num?)?.toInt() ?? 0,
      weightKg: (json['weightKg'] as num?)?.toDouble() ?? 0.0,
      muscleKg: (json['muscleKg'] as num?)?.toDouble() ?? 0.0,
      fatKg: (json['fatKg'] as num?)?.toDouble() ?? 0.0,
      fatPercent: (json['fatPercent'] as num?)?.toDouble() ?? 0.0,
      waterKg: (json['waterKg'] as num?)?.toDouble() ?? 0.0,
      fatFreeMassKg: (json['fatFreeMassKg'] as num?)?.toDouble(),
      waistHipRatio: (json['waistHipRatio'] as num?)?.toDouble(),
      bmrKcal: (json['bmrKcal'] as num?)?.toInt(),
      createdAt: DateTime.tryParse((json['createdAt'] as String?) ?? '') ?? now,
      updatedAt:
          DateTime.tryParse((json['updatedAt'] as String?) ?? '') ?? now,
      deletedAt: DateTime.tryParse((json['deletedAt'] as String?) ?? ''),
      version: (json['version'] as num?)?.toInt() ?? 1,
      updatedByDeviceId: (json['updatedByDeviceId'] as String?) ?? '',
    );
  }
}