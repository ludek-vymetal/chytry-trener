class CoachCircumferenceEntry {
  final String entryId;
  final String clientId;
  final DateTime date;

  final double neckCm;
  final double chestCm;
  final double waistCm;
  final double hipsCm;
  final double armCm;
  final double thighCm;
  final double calfCm;

  // --------------------------
  // Sync metadata
  // --------------------------
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final int version;
  final String updatedByDeviceId;

  const CoachCircumferenceEntry({
    required this.entryId,
    required this.clientId,
    required this.date,
    required this.neckCm,
    required this.chestCm,
    required this.waistCm,
    required this.hipsCm,
    required this.armCm,
    required this.thighCm,
    required this.calfCm,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
    required this.version,
    required this.updatedByDeviceId,
  });

  bool get isDeleted => deletedAt != null;

  CoachCircumferenceEntry copyWith({
    String? entryId,
    String? clientId,
    DateTime? date,
    double? neckCm,
    double? chestCm,
    double? waistCm,
    double? hipsCm,
    double? armCm,
    double? thighCm,
    double? calfCm,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
    int? version,
    String? updatedByDeviceId,
  }) {
    return CoachCircumferenceEntry(
      entryId: entryId ?? this.entryId,
      clientId: clientId ?? this.clientId,
      date: date ?? this.date,
      neckCm: neckCm ?? this.neckCm,
      chestCm: chestCm ?? this.chestCm,
      waistCm: waistCm ?? this.waistCm,
      hipsCm: hipsCm ?? this.hipsCm,
      armCm: armCm ?? this.armCm,
      thighCm: thighCm ?? this.thighCm,
      calfCm: calfCm ?? this.calfCm,
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
        'neckCm': neckCm,
        'chestCm': chestCm,
        'waistCm': waistCm,
        'hipsCm': hipsCm,
        'armCm': armCm,
        'thighCm': thighCm,
        'calfCm': calfCm,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'deletedAt': deletedAt?.toIso8601String(),
        'version': version,
        'updatedByDeviceId': updatedByDeviceId,
      };

  factory CoachCircumferenceEntry.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    final date = DateTime.tryParse((json['date'] as String?) ?? '') ?? now;

    return CoachCircumferenceEntry(
      entryId: (json['entryId'] as String?) ?? '',
      clientId: (json['clientId'] as String?) ?? '',
      date: date,
      neckCm: (json['neckCm'] as num?)?.toDouble() ?? 0.0,
      chestCm: (json['chestCm'] as num?)?.toDouble() ?? 0.0,
      waistCm: (json['waistCm'] as num?)?.toDouble() ?? 0.0,
      hipsCm: (json['hipsCm'] as num?)?.toDouble() ?? 0.0,
      armCm: (json['armCm'] as num?)?.toDouble() ?? 0.0,
      thighCm: (json['thighCm'] as num?)?.toDouble() ?? 0.0,
      calfCm: (json['calfCm'] as num?)?.toDouble() ?? 0.0,
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