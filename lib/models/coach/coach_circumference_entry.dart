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
  });

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
      };

  factory CoachCircumferenceEntry.fromJson(Map<String, dynamic> json) {
    return CoachCircumferenceEntry(
      entryId: json['entryId'] as String,
      clientId: json['clientId'] as String,
      date: DateTime.parse(json['date'] as String),
      neckCm: (json['neckCm'] as num?)?.toDouble() ?? 0.0,
      chestCm: (json['chestCm'] as num?)?.toDouble() ?? 0.0,
      waistCm: (json['waistCm'] as num?)?.toDouble() ?? 0.0,
      hipsCm: (json['hipsCm'] as num?)?.toDouble() ?? 0.0,
      armCm: (json['armCm'] as num?)?.toDouble() ?? 0.0,
      thighCm: (json['thighCm'] as num?)?.toDouble() ?? 0.0,
      calfCm: (json['calfCm'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
