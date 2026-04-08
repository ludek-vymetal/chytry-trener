import '../training_set.dart';
import '../actual_set.dart';

class ExerciseLogEntry {
  final String exerciseKey;
  final List<PlannedSet> plannedSets;
  final List<ActualSet> actualSets;

  const ExerciseLogEntry({
    required this.exerciseKey,
    required this.plannedSets,
    required this.actualSets,
  });
}