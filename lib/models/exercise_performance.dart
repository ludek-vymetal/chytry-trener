class ExercisePerformance {
  final String exerciseName;
  final DateTime date;

  final double weight;
  final int reps;

  final String? clientId; // ✅ NOVÉ (nullable)

  ExercisePerformance({
    required this.exerciseName,
    required this.date,
    required this.weight,
    required this.reps,
    this.clientId, // ✅ optional → nic nerozbije
  });

  double get volume => weight * reps;

  @override
  String toString() {
    return '$exerciseName | $weight kg x $reps | $date';
  }
}