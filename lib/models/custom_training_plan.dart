class CustomTrainingExercise {
  /// Pokud je cvik z databáze
  final String? exerciseId;

  /// Zobrazený název cviku.
  /// Když je exerciseId null, používá se customName.
  final String customName;

  final String sets;
  final String reps;
  final String rir;
  final String? note;

  const CustomTrainingExercise({
    this.exerciseId,
    required this.customName,
    required this.sets,
    required this.reps,
    required this.rir,
    this.note,
  });

  CustomTrainingExercise copyWith({
    String? exerciseId,
    String? customName,
    String? sets,
    String? reps,
    String? rir,
    String? note,
  }) {
    return CustomTrainingExercise(
      exerciseId: exerciseId ?? this.exerciseId,
      customName: customName ?? this.customName,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      rir: rir ?? this.rir,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() => {
        'exerciseId': exerciseId,
        'customName': customName,
        'sets': sets,
        'reps': reps,
        'rir': rir,
        'note': note,
      };

  factory CustomTrainingExercise.fromJson(Map<String, dynamic> json) {
    return CustomTrainingExercise(
      exerciseId: json['exerciseId'] as String?,
      customName: (json['customName'] as String?) ?? 'Cvik',
      sets: (json['sets'] as String?) ?? '3',
      reps: (json['reps'] as String?) ?? '8–12',
      rir: (json['rir'] as String?) ?? '2',
      note: json['note'] as String?,
    );
  }
}

class CustomTrainingDay {
  final String name;
  final List<CustomTrainingExercise> exercises;

  const CustomTrainingDay({
    required this.name,
    this.exercises = const [],
  });

  CustomTrainingDay copyWith({
    String? name,
    List<CustomTrainingExercise>? exercises,
  }) {
    return CustomTrainingDay(
      name: name ?? this.name,
      exercises: exercises ?? this.exercises,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'exercises': exercises.map((e) => e.toJson()).toList(),
      };

  factory CustomTrainingDay.fromJson(Map<String, dynamic> json) {
    final rawExercises = (json['exercises'] as List?) ?? const [];
    return CustomTrainingDay(
      name: (json['name'] as String?) ?? 'Den',
      exercises: rawExercises
          .map((e) => CustomTrainingExercise.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}

class CustomTrainingPlan {
  final String id;
  final String clientId;
  final String name;
  final List<CustomTrainingDay> days;

  /// jestli je to aktivní plán klienta
  final bool isActive;

  final DateTime createdAt;
  final DateTime updatedAt;

  const CustomTrainingPlan({
    required this.id,
    required this.clientId,
    required this.name,
    required this.days,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = false,
  });

  CustomTrainingPlan copyWith({
    String? id,
    String? clientId,
    String? name,
    List<CustomTrainingDay>? days,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CustomTrainingPlan(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      name: name ?? this.name,
      days: days ?? this.days,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'clientId': clientId,
        'name': name,
        'days': days.map((d) => d.toJson()).toList(),
        'isActive': isActive,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory CustomTrainingPlan.fromJson(Map<String, dynamic> json) {
    final rawDays = (json['days'] as List?) ?? const [];

    return CustomTrainingPlan(
      id: json['id'] as String,
      clientId: json['clientId'] as String,
      name: (json['name'] as String?) ?? 'Můj plán',
      days: rawDays
          .map((d) => CustomTrainingDay.fromJson(Map<String, dynamic>.from(d as Map)))
          .toList(),
      isActive: (json['isActive'] as bool?) ?? false,
      createdAt: DateTime.parse(
        (json['createdAt'] as String?) ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        (json['updatedAt'] as String?) ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}