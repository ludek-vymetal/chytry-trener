class CoachNote {
  final String noteId;
  final String clientId;
  final String text;

  final DateTime createdAt;
  final DateTime updatedAt;

  // --------------------------
  // Sync metadata
  // --------------------------
  final DateTime? deletedAt;
  final int version;
  final String updatedByDeviceId;

  const CoachNote({
    required this.noteId,
    required this.clientId,
    required this.text,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
    required this.version,
    required this.updatedByDeviceId,
  });

  bool get isDeleted => deletedAt != null;

  CoachNote copyWith({
    String? noteId,
    String? clientId,
    String? text,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
    int? version,
    String? updatedByDeviceId,
  }) {
    return CoachNote(
      noteId: noteId ?? this.noteId,
      clientId: clientId ?? this.clientId,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
      version: version ?? this.version,
      updatedByDeviceId: updatedByDeviceId ?? this.updatedByDeviceId,
    );
  }

  Map<String, dynamic> toJson() => {
        'noteId': noteId,
        'clientId': clientId,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'deletedAt': deletedAt?.toIso8601String(),
        'version': version,
        'updatedByDeviceId': updatedByDeviceId,
      };

  factory CoachNote.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();

    final createdAt = DateTime.tryParse(
          (json['createdAt'] as String?) ?? '',
        ) ??
        now;

    final updatedAt = DateTime.tryParse(
          (json['updatedAt'] as String?) ?? '',
        ) ??
        createdAt;

    return CoachNote(
      noteId: json['noteId'] as String,
      clientId: json['clientId'] as String,
      text: (json['text'] as String?) ?? '',
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: (json['deletedAt'] as String?) == null
          ? null
          : DateTime.tryParse(json['deletedAt'] as String),
      version: (json['version'] as num?)?.toInt() ?? 1,
      updatedByDeviceId:
          (json['updatedByDeviceId'] as String?) ?? 'local',
    );
  }
}