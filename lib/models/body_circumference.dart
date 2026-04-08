class BodyCircumference {
  final DateTime date;

  final double waist;
  final double hips;      // ❗ POVINNÉ
  final double chest;
  final double biceps;
  final double thigh;
  final double neck;

  BodyCircumference({
    required this.date,
    required this.waist,
    required this.hips,
    required this.chest,
    required this.biceps,
    required this.thigh,
    required this.neck,
  });
}
