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

  final DateTime linkedAt;

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
    required this.linkedAt,
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
    DateTime? linkedAt,
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
      linkedAt: linkedAt ?? this.linkedAt,
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
        'linkedAt': linkedAt.toIso8601String(),
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
      linkedAt: linkedAt,
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
}