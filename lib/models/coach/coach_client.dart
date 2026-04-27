class CoachClient {
  final String clientId;

  final String firstName;
  final String lastName;
  final String email;

  /// 'male' | 'female' | 'other'
  final String gender;

  final int age;
  final int heightCm;
  final double weightKg;

  /// bezpečnostní flag pro UI guardrails
  final bool isEatingDisorderSupport;

  /// Archivní / spící klient.
  final bool isArchived;

  final DateTime linkedAt;

  // --------------------------
  // Simple compliance tracking
  // --------------------------
  final List<DateTime> completedDays;
  final DateTime? lastWorkoutAt;
  final bool photosDelivered;
  final bool dietFollowed;
  final bool communicationOk;

  // --------------------------
  // Sync metadata
  // --------------------------
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final int version;
  final String updatedByDeviceId;

  const CoachClient({
    required this.clientId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.gender,
    required this.age,
    required this.heightCm,
    required this.weightKg,
    required this.isEatingDisorderSupport,
    this.isArchived = false,
    required this.linkedAt,
    required this.completedDays,
    required this.lastWorkoutAt,
    required this.photosDelivered,
    required this.dietFollowed,
    required this.communicationOk,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
    required this.version,
    required this.updatedByDeviceId,
  });

  String get displayName => '$firstName $lastName';

  bool get isDeleted => deletedAt != null;

  CoachClient copyWith({
    String? clientId,
    String? firstName,
    String? lastName,
    String? email,
    String? gender,
    int? age,
    int? heightCm,
    double? weightKg,
    bool? isEatingDisorderSupport,
    bool? isArchived,
    DateTime? linkedAt,
    List<DateTime>? completedDays,
    DateTime? lastWorkoutAt,
    bool clearLastWorkoutAt = false,
    bool? photosDelivered,
    bool? dietFollowed,
    bool? communicationOk,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
    int? version,
    String? updatedByDeviceId,
  }) {
    return CoachClient(
      clientId: clientId ?? this.clientId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      isEatingDisorderSupport:
          isEatingDisorderSupport ?? this.isEatingDisorderSupport,
      isArchived: isArchived ?? this.isArchived,
      linkedAt: linkedAt ?? this.linkedAt,
      completedDays: completedDays ?? this.completedDays,
      lastWorkoutAt:
          clearLastWorkoutAt ? null : (lastWorkoutAt ?? this.lastWorkoutAt),
      photosDelivered: photosDelivered ?? this.photosDelivered,
      dietFollowed: dietFollowed ?? this.dietFollowed,
      communicationOk: communicationOk ?? this.communicationOk,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
      version: version ?? this.version,
      updatedByDeviceId: updatedByDeviceId ?? this.updatedByDeviceId,
    );
  }

  Map<String, dynamic> toJson() => {
        'clientId': clientId,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'gender': gender,
        'age': age,
        'heightCm': heightCm,
        'weightKg': weightKg,
        'isEatingDisorderSupport': isEatingDisorderSupport,
        'isArchived': isArchived,
        'linkedAt': linkedAt.toIso8601String(),
        'completedDays': completedDays
            .map((date) => _normalizeDate(date).toIso8601String())
            .toList(),
        'lastWorkoutAt': lastWorkoutAt?.toIso8601String(),
        'photosDelivered': photosDelivered,
        'dietFollowed': dietFollowed,
        'communicationOk': communicationOk,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'deletedAt': deletedAt?.toIso8601String(),
        'version': version,
        'updatedByDeviceId': updatedByDeviceId,
      };

  factory CoachClient.fromJson(Map<String, dynamic> json) {
    final fallbackNow = DateTime.now();

    final linkedAt = DateTime.tryParse(
          (json['linkedAt'] as String?) ?? '',
        ) ??
        fallbackNow;

    final rawCompletedDays = (json['completedDays'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .map(DateTime.tryParse)
        .whereType<DateTime>()
        .map(_normalizeDate)
        .toList();

    final uniqueCompletedDays = <DateTime>[];
    final seen = <String>{};

    for (final day in rawCompletedDays) {
      final key = _dayKey(day);
      if (seen.add(key)) {
        uniqueCompletedDays.add(day);
      }
    }

    return CoachClient(
      clientId: json['clientId'] as String,
      firstName: (json['firstName'] as String?) ?? '—',
      lastName: (json['lastName'] as String?) ?? '—',
      email: (json['email'] as String?) ?? '',
      gender: (json['gender'] as String?) ?? 'other',
      age: (json['age'] as num?)?.toInt() ?? 0,
      heightCm: (json['heightCm'] as num?)?.toInt() ?? 0,
      weightKg: (json['weightKg'] as num?)?.toDouble() ?? 0.0,
      isEatingDisorderSupport:
          (json['isEatingDisorderSupport'] as bool?) ?? false,
      isArchived: (json['isArchived'] as bool?) ?? false,
      linkedAt: linkedAt,
      completedDays: uniqueCompletedDays,
      lastWorkoutAt: (json['lastWorkoutAt'] as String?) == null
          ? null
          : DateTime.tryParse(json['lastWorkoutAt'] as String),
      photosDelivered: (json['photosDelivered'] as bool?) ?? false,
      dietFollowed: (json['dietFollowed'] as bool?) ?? false,
      communicationOk: (json['communicationOk'] as bool?) ?? false,
      createdAt: DateTime.tryParse(
            (json['createdAt'] as String?) ?? '',
          ) ??
          linkedAt,
      updatedAt: DateTime.tryParse(
            (json['updatedAt'] as String?) ?? '',
          ) ??
          linkedAt,
      deletedAt: (json['deletedAt'] as String?) == null
          ? null
          : DateTime.tryParse(json['deletedAt'] as String),
      version: (json['version'] as num?)?.toInt() ?? 1,
      updatedByDeviceId: (json['updatedByDeviceId'] as String?) ?? 'local',
    );
  }

  static DateTime _normalizeDate(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  static String _dayKey(DateTime value) {
    final normalized = _normalizeDate(value);
    return normalized.toIso8601String();
  }
}