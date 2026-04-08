class Measurement {
  final DateTime date;

  final double weight;
  final double? muscleMass;
  final double? fatMass;

  final double? waist;
  final double? chest;
  final double? biceps;
  final double? thigh;
  final double? neck;

  Measurement({
    required this.date,
    required this.weight,
    this.muscleMass,
    this.fatMass,
    this.waist,
    this.chest,
    this.biceps,
    this.thigh,
    this.neck,
  });

  /// 🔹 POTŘEBNÉ PRO ÚPRAVY / GRAFY / AI
  Measurement copyWith({
    DateTime? date,
    double? weight,
    double? muscleMass,
    double? fatMass,
    double? waist,
    double? chest,
    double? biceps,
    double? thigh,
    double? neck,
  }) {
    return Measurement(
      date: date ?? this.date,
      weight: weight ?? this.weight,
      muscleMass: muscleMass ?? this.muscleMass,
      fatMass: fatMass ?? this.fatMass,
      waist: waist ?? this.waist,
      chest: chest ?? this.chest,
      biceps: biceps ?? this.biceps,
      thigh: thigh ?? this.thigh,
      neck: neck ?? this.neck,
    );
  }

  @override
  String toString() {
    return 'Measurement(date: $date, weight: $weight)';
  }
}
