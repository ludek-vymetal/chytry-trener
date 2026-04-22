import 'custom_training_plan.dart';

class SharedTrainingTemplate {
  final String id;
  final String name;
  final List<CustomTrainingDay> days;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SharedTrainingTemplate({
    required this.id,
    required this.name,
    required this.days,
    required this.createdAt,
    required this.updatedAt,
  });

  SharedTrainingTemplate copyWith({
    String? id,
    String? name,
    List<CustomTrainingDay>? days,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SharedTrainingTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      days: days ?? this.days,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'days': days.map((d) => d.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory SharedTrainingTemplate.fromJson(Map<String, dynamic> json) {
    final rawDays = (json['days'] as List?) ?? const [];

    return SharedTrainingTemplate(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? 'Sdílená šablona',
      days: rawDays
          .map(
            (d) => CustomTrainingDay.fromJson(
              Map<String, dynamic>.from(d as Map),
            ),
          )
          .toList(),
      createdAt: DateTime.parse(
        (json['createdAt'] as String?) ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        (json['updatedAt'] as String?) ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  factory SharedTrainingTemplate.fromPlan(CustomTrainingPlan plan) {
    final now = DateTime.now();

    return SharedTrainingTemplate(
      id: 'shared_${now.microsecondsSinceEpoch}',
      name: plan.name,
      days: plan.days
          .map(
            (d) => d.copyWith(
              exercises: d.exercises.map((e) => e.copyWith()).toList(),
            ),
          )
          .toList(),
      createdAt: now,
      updatedAt: now,
    );
  }
}