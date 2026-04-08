class BodyScan {
  final String id;
  final DateTime date;
  final String imagePath;
  final double? weight;
  final String goalSnapshot;

  BodyScan({
    required this.id,
    required this.date,
    required this.imagePath,
    this.weight,
    required this.goalSnapshot,
  });
}
