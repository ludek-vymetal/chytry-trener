enum CustomTrainingPlanType {
  standard,
  cut90,
  powerliftingMeetPrep,
}

enum CustomTrainingCategory {
  strength,
  bulk,
  cut,
  recomp,
  conditioning,
  powerlifting,
  bodybuilding,
  custom,
}

class CustomTrainingMaxes {
  final double? squat1rm;
  final double? bench1rm;
  final double? deadlift1rm;

  const CustomTrainingMaxes({
    this.squat1rm,
    this.bench1rm,
    this.deadlift1rm,
  });

  CustomTrainingMaxes copyWith({
    double? squat1rm,
    double? bench1rm,
    double? deadlift1rm,
  }) {
    return CustomTrainingMaxes(
      squat1rm: squat1rm ?? this.squat1rm,
      bench1rm: bench1rm ?? this.bench1rm,
      deadlift1rm: deadlift1rm ?? this.deadlift1rm,
    );
  }

  bool get hasAnyValue =>
      squat1rm != null || bench1rm != null || deadlift1rm != null;

  Map<String, dynamic> toJson() => {
        'squat1rm': squat1rm,
        'bench1rm': bench1rm,
        'deadlift1rm': deadlift1rm,
      };

  factory CustomTrainingMaxes.fromJson(Map<String, dynamic> json) {
    return CustomTrainingMaxes(
      squat1rm: (json['squat1rm'] as num?)?.toDouble(),
      bench1rm: (json['bench1rm'] as num?)?.toDouble(),
      deadlift1rm: (json['deadlift1rm'] as num?)?.toDouble(),
    );
  }
}

class CustomTrainingExercise {
  final String? exerciseId;
  final String customName;
  final String sets;
  final String reps;
  final String rir;
  final double? weightKg;
  final String? note;

  const CustomTrainingExercise({
    this.exerciseId,
    required this.customName,
    required this.sets,
    required this.reps,
    required this.rir,
    this.note,
    this.weightKg,
  });

  CustomTrainingExercise copyWith({
    String? exerciseId,
    String? customName,
    String? sets,
    String? reps,
    String? rir,
    String? note,
    double? weightKg,
  }) {
    return CustomTrainingExercise(
      exerciseId: exerciseId ?? this.exerciseId,
      customName: customName ?? this.customName,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      rir: rir ?? this.rir,
      note: note ?? this.note,
      weightKg: weightKg ?? this.weightKg,
    );
  }

  Map<String, dynamic> toJson() => {
        'exerciseId': exerciseId,
        'customName': customName,
        'sets': sets,
        'reps': reps,
        'rir': rir,
        'note': note,
        'weightKg': weightKg,
      };

  factory CustomTrainingExercise.fromJson(Map<String, dynamic> json) {
    return CustomTrainingExercise(
      exerciseId: json['exerciseId'] as String?,
      customName: (json['customName'] as String?) ?? 'Cvik',
      sets: (json['sets'] as String?) ?? '3',
      reps: (json['reps'] as String?) ?? '8–12',
      rir: (json['rir'] as String?) ?? '2',
      note: json['note'] as String?,
      weightKg: (json['weightKg'] as num?)?.toDouble(),
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
          .map(
            (e) => CustomTrainingExercise.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
    );
  }
}

class CustomTrainingPlan {
  final String id;
  final String clientId;
  final String name;
  final String? description;
  final CustomTrainingCategory category;
  final List<CustomTrainingDay> days;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final CustomTrainingPlanType type;
  final DateTime? meetDate;
  final CustomTrainingMaxes? maxes;

  const CustomTrainingPlan({
    required this.id,
    required this.clientId,
    required this.name,
    this.description,
    this.category = CustomTrainingCategory.custom,
    required this.days,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = false,
    this.type = CustomTrainingPlanType.standard,
    this.meetDate,
    this.maxes,
  });

  CustomTrainingPlan copyWith({
    String? id,
    String? clientId,
    String? name,
    String? description,
    bool clearDescription = false,
    CustomTrainingCategory? category,
    List<CustomTrainingDay>? days,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    CustomTrainingPlanType? type,
    DateTime? meetDate,
    bool clearMeetDate = false,
    CustomTrainingMaxes? maxes,
    bool clearMaxes = false,
  }) {
    return CustomTrainingPlan(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      name: name ?? this.name,
      description: clearDescription ? null : (description ?? this.description),
      category: category ?? this.category,
      days: days ?? this.days,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      type: type ?? this.type,
      meetDate: clearMeetDate ? null : (meetDate ?? this.meetDate),
      maxes: clearMaxes ? null : (maxes ?? this.maxes),
    );
  }

  bool get isPowerliftingMeetPrep =>
      type == CustomTrainingPlanType.powerliftingMeetPrep;

  bool get isCutPlan => type == CustomTrainingPlanType.cut90;

  Map<String, dynamic> toJson() => {
        'id': id,
        'clientId': clientId,
        'name': name,
        'description': description,
        'category': category.name,
        'days': days.map((d) => d.toJson()).toList(),
        'isActive': isActive,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'type': type.name,
        'meetDate': meetDate?.toIso8601String(),
        'maxes': maxes?.toJson(),
      };

  factory CustomTrainingPlan.fromJson(Map<String, dynamic> json) {
    final rawDays = (json['days'] as List?) ?? const [];

    final rawType = (json['type'] as String?)?.trim();
    CustomTrainingPlanType resolvedType;
    try {
      resolvedType = rawType == null || rawType.isEmpty
          ? CustomTrainingPlanType.standard
          : CustomTrainingPlanType.values.byName(rawType);
    } catch (_) {
      resolvedType = CustomTrainingPlanType.standard;
    }

    final rawCategory = (json['category'] as String?)?.trim();
    CustomTrainingCategory resolvedCategory;
    try {
      resolvedCategory = rawCategory == null || rawCategory.isEmpty
          ? CustomTrainingCategory.custom
          : CustomTrainingCategory.values.byName(rawCategory);
    } catch (_) {
      resolvedCategory = CustomTrainingCategory.custom;
    }

    final rawMeetDate = (json['meetDate'] as String?)?.trim();
    final rawMaxes = json['maxes'];

    return CustomTrainingPlan(
      id: json['id'] as String,
      clientId: json['clientId'] as String,
      name: (json['name'] as String?) ?? 'Můj plán',
      description: json['description'] as String?,
      category: resolvedCategory,
      days: rawDays
          .map(
            (d) => CustomTrainingDay.fromJson(
              Map<String, dynamic>.from(d as Map),
            ),
          )
          .toList(),
      isActive: (json['isActive'] as bool?) ?? false,
      createdAt: DateTime.parse(
        (json['createdAt'] as String?) ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        (json['updatedAt'] as String?) ?? DateTime.now().toIso8601String(),
      ),
      type: resolvedType,
      meetDate: rawMeetDate == null || rawMeetDate.isEmpty
          ? null
          : DateTime.tryParse(rawMeetDate),
      maxes: rawMaxes is Map
          ? CustomTrainingMaxes.fromJson(Map<String, dynamic>.from(rawMaxes))
          : null,
    );
  }
}