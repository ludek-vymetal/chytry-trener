class CoachClientDetails {
  final String clientId;

  /// sedavé | aktivní | těžká manuální
  final String activityType;

  /// např. "programátor", "skladník", ...
  final String occupation;

  /// zranění / operace / omezení
  final String injuries;

  /// alergie (např. "ořechy, mléko")
  final String allergies;

  /// intolerance (např. "laktóza, lepek")
  final String intolerances;

  /// zdravotní poznámky (tlak, záda, léky...) – česky
  final String healthNotes;

  // ✅ regenerace + lifestyle
  /// průměr spánku (hodiny), např. 7.5
  final double sleepHours;

  /// kvalita spánku: "dobrá" | "průměrná" | "špatná"
  final String sleepQuality;

  /// stres: "nízký" | "střední" | "vysoký"
  final String stressLevel;

  /// orientačně kroky / den
  final int stepsPerDay;

  /// 1–2 věty: cíl, motivace
  final String motivation;

  /// co klient rád jí
  final String preferredFoods;

  /// co klient nechce / vadí mu
  final String dislikedFoods;

  const CoachClientDetails({
    required this.clientId,
    this.activityType = 'sedavé',
    this.occupation = '',
    this.injuries = '',
    this.allergies = '',
    this.intolerances = '',
    this.healthNotes = '',
    this.sleepHours = 7.0,
    this.sleepQuality = 'průměrná',
    this.stressLevel = 'střední',
    this.stepsPerDay = 6000,
    this.motivation = '',
    this.preferredFoods = '',
    this.dislikedFoods = '',
  });

  CoachClientDetails copyWith({
    String? activityType,
    String? occupation,
    String? injuries,
    String? allergies,
    String? intolerances,
    String? healthNotes,
    double? sleepHours,
    String? sleepQuality,
    String? stressLevel,
    int? stepsPerDay,
    String? motivation,
    String? preferredFoods,
    String? dislikedFoods,
  }) {
    return CoachClientDetails(
      clientId: clientId,
      activityType: activityType ?? this.activityType,
      occupation: occupation ?? this.occupation,
      injuries: injuries ?? this.injuries,
      allergies: allergies ?? this.allergies,
      intolerances: intolerances ?? this.intolerances,
      healthNotes: healthNotes ?? this.healthNotes,
      sleepHours: sleepHours ?? this.sleepHours,
      sleepQuality: sleepQuality ?? this.sleepQuality,
      stressLevel: stressLevel ?? this.stressLevel,
      stepsPerDay: stepsPerDay ?? this.stepsPerDay,
      motivation: motivation ?? this.motivation,
      preferredFoods: preferredFoods ?? this.preferredFoods,
      dislikedFoods: dislikedFoods ?? this.dislikedFoods,
    );
  }

  Map<String, dynamic> toJson() => {
        'clientId': clientId,
        'activityType': activityType,
        'occupation': occupation,
        'injuries': injuries,
        'allergies': allergies,
        'intolerances': intolerances,
        'healthNotes': healthNotes,
        'sleepHours': sleepHours,
        'sleepQuality': sleepQuality,
        'stressLevel': stressLevel,
        'stepsPerDay': stepsPerDay,
        'motivation': motivation,
        'preferredFoods': preferredFoods,
        'dislikedFoods': dislikedFoods,
      };

  factory CoachClientDetails.fromJson(Map<String, dynamic> json) {
    return CoachClientDetails(
      clientId: (json['clientId'] as String?) ?? '',
      activityType: (json['activityType'] as String?) ?? 'sedavé',
      occupation: (json['occupation'] as String?) ?? '',
      injuries: (json['injuries'] as String?) ?? '',
      allergies: (json['allergies'] as String?) ?? '',
      intolerances: (json['intolerances'] as String?) ?? '',
      healthNotes: (json['healthNotes'] as String?) ?? '',
      sleepHours: (json['sleepHours'] as num?)?.toDouble() ?? 7.0,
      sleepQuality: (json['sleepQuality'] as String?) ?? 'průměrná',
      stressLevel: (json['stressLevel'] as String?) ?? 'střední',
      stepsPerDay: (json['stepsPerDay'] as num?)?.toInt() ?? 6000,
      motivation: (json['motivation'] as String?) ?? '',
      preferredFoods: (json['preferredFoods'] as String?) ?? '',
      dislikedFoods: (json['dislikedFoods'] as String?) ?? '',
    );
  }
}
