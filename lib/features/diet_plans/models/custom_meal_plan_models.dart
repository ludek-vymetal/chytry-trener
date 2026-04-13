enum CustomMealSlot {
  breakfast,
  snack1,
  lunch,
  snack2,
  dinner,
}

class CustomMealEntry {
  final CustomMealSlot slot;
  final String? comboTitle;
  final double portionMultiplier;

  const CustomMealEntry({
    required this.slot,
    this.comboTitle,
    this.portionMultiplier = 1.0,
  });

  CustomMealEntry copyWith({
    CustomMealSlot? slot,
    String? comboTitle,
    bool clearComboTitle = false,
    double? portionMultiplier,
  }) {
    return CustomMealEntry(
      slot: slot ?? this.slot,
      comboTitle: clearComboTitle ? null : (comboTitle ?? this.comboTitle),
      portionMultiplier: portionMultiplier ?? this.portionMultiplier,
    );
  }

  Map<String, dynamic> toJson() => {
        'slot': slot.name,
        'comboTitle': comboTitle,
        'portionMultiplier': portionMultiplier,
      };

  factory CustomMealEntry.fromJson(Map<String, dynamic> json) {
    return CustomMealEntry(
      slot: CustomMealSlot.values.byName(
        (json['slot'] as String?) ?? CustomMealSlot.breakfast.name,
      ),
      comboTitle: json['comboTitle'] as String?,
      portionMultiplier: (json['portionMultiplier'] as num?)?.toDouble() ?? 1.0,
    );
  }
}

class DailyMealTemplate {
  final String id;
  final String title;
  final String note;
  final String phaseLabel;
  final String? clientId;
  final String? clientName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<CustomMealEntry> entries;

  const DailyMealTemplate({
    required this.id,
    required this.title,
    required this.note,
    required this.phaseLabel,
    required this.createdAt,
    required this.updatedAt,
    required this.entries,
    this.clientId,
    this.clientName,
  });

  DailyMealTemplate copyWith({
    String? id,
    String? title,
    String? note,
    String? phaseLabel,
    String? clientId,
    bool clearClientId = false,
    String? clientName,
    bool clearClientName = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<CustomMealEntry>? entries,
  }) {
    return DailyMealTemplate(
      id: id ?? this.id,
      title: title ?? this.title,
      note: note ?? this.note,
      phaseLabel: phaseLabel ?? this.phaseLabel,
      clientId: clearClientId ? null : (clientId ?? this.clientId),
      clientName: clearClientName ? null : (clientName ?? this.clientName),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      entries: entries ?? this.entries,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'note': note,
        'phaseLabel': phaseLabel,
        'clientId': clientId,
        'clientName': clientName,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'entries': entries.map((e) => e.toJson()).toList(),
      };

  factory DailyMealTemplate.fromJson(Map<String, dynamic> json) {
    final rawEntries = (json['entries'] as List?) ?? const [];

    return DailyMealTemplate(
      id: (json['id'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      note: (json['note'] as String?) ?? '',
      phaseLabel: (json['phaseLabel'] as String?) ?? 'Bez fáze',
      clientId: json['clientId'] as String?,
      clientName: json['clientName'] as String?,
      createdAt: DateTime.tryParse((json['createdAt'] as String?) ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse((json['updatedAt'] as String?) ?? '') ??
          DateTime.now(),
      entries: rawEntries
          .whereType<Map>()
          .map((e) => CustomMealEntry.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  static DailyMealTemplate empty({
    String? clientId,
    String? clientName,
    String phaseLabel = 'Bez fáze',
  }) {
    final now = DateTime.now();

    return DailyMealTemplate(
      id: now.microsecondsSinceEpoch.toString(),
      title: '',
      note: '',
      phaseLabel: phaseLabel,
      clientId: clientId,
      clientName: clientName,
      createdAt: now,
      updatedAt: now,
      entries: const [
        CustomMealEntry(slot: CustomMealSlot.breakfast),
        CustomMealEntry(slot: CustomMealSlot.snack1),
        CustomMealEntry(slot: CustomMealSlot.lunch),
        CustomMealEntry(slot: CustomMealSlot.snack2),
        CustomMealEntry(slot: CustomMealSlot.dinner),
      ],
    );
  }
}