import 'carb_cycling_plan.dart';

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
  });

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
      };

  factory SavedMealPlan.fromJson(Map<String, dynamic> json) {
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
    );
  }
}