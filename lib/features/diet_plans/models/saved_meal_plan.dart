import 'carb_cycling_plan.dart';

/// Uložený jídelníček. Každý uložený jídelníček je zároveň šablona:
/// dá se kdykoli přepočítat a použít pro jiného klienta.
///
/// * [clientId] == null → obecná šablona v knihovně,
/// * [clientId] != null → jídelníček konkrétního klienta (i ten jde
///   použít jako šablona pro další klienty).
class SavedMealPlan {
  final String id;
  final String name;
  final String planType;
  final double baseWeight;
  final double baseCalories;
  final int durationDays;
  final String? trainerNote;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DietMealPlan plan;

  /// Klient, pro kterého je jídelníček připravený (null = šablona).
  final String? clientId;
  final String? clientName;

  /// Z jaké šablony jídelníček vznikl (pro přehled).
  final String? sourceId;

  const SavedMealPlan({
    required this.id,
    required this.name,
    required this.planType,
    required this.baseWeight,
    required this.baseCalories,
    required this.durationDays,
    required this.createdAt,
    required this.updatedAt,
    required this.plan,
    this.trainerNote,
    this.clientId,
    this.clientName,
    this.sourceId,
  });

  bool get isTemplate => clientId == null || clientId!.isEmpty;

  DateTime get recommendedNextCheckDate =>
      createdAt.add(const Duration(days: 30));

  SavedMealPlan copyWith({
    String? id,
    String? name,
    String? planType,
    double? baseWeight,
    double? baseCalories,
    int? durationDays,
    String? trainerNote,
    DateTime? createdAt,
    DateTime? updatedAt,
    DietMealPlan? plan,
    String? clientId,
    String? clientName,
    bool clearClient = false,
    String? sourceId,
  }) {
    return SavedMealPlan(
      id: id ?? this.id,
      name: name ?? this.name,
      planType: planType ?? this.planType,
      baseWeight: baseWeight ?? this.baseWeight,
      baseCalories: baseCalories ?? this.baseCalories,
      durationDays: durationDays ?? this.durationDays,
      trainerNote: trainerNote ?? this.trainerNote,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      plan: plan ?? this.plan,
      clientId: clearClient ? null : (clientId ?? this.clientId),
      clientName: clearClient ? null : (clientName ?? this.clientName),
      sourceId: sourceId ?? this.sourceId,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'planType': planType,
        'baseWeight': baseWeight,
        'baseCalories': baseCalories,
        'durationDays': durationDays,
        'trainerNote': trainerNote,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'plan': plan.toJson(),
        'clientId': clientId,
        'clientName': clientName,
        'sourceId': sourceId,
      };

  factory SavedMealPlan.fromJson(Map<String, dynamic> json) {
    String? str(Object? v) {
      final s = v?.toString().trim();
      return (s == null || s.isEmpty) ? null : s;
    }

    return SavedMealPlan(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      planType: (json['planType'] ?? '').toString(),
      baseWeight: (json['baseWeight'] as num?)?.toDouble() ?? 0,
      baseCalories: (json['baseCalories'] as num?)?.toDouble() ?? 0,
      durationDays: (json['durationDays'] as num?)?.toInt() ?? 7,
      trainerNote: json['trainerNote'] as String?,
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.now(),
      updatedAt: DateTime.tryParse((json['updatedAt'] ?? '').toString()) ??
          DateTime.now(),
      plan: DietMealPlan.fromJson(
        Map<String, dynamic>.from(json['plan'] as Map),
      ),
      clientId: str(json['clientId']),
      clientName: str(json['clientName']),
      sourceId: str(json['sourceId']),
    );
  }
}
