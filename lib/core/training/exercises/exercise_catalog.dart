import 'exercise.dart';
import 'exercise_db.dart';

class ExerciseCatalog {
  static final Map<String, Exercise> _byId = {
    for (final e in ExerciseDB.all) e.id: e,
  };

  static Exercise? byId(String id) => _byId[id];

  static List<Exercise> all() => ExerciseDB.all;

  static List<Exercise> filterByEquipment(Set<String> availableEquipment) {
    return ExerciseDB.all
        .where((e) => e.equipment.intersection(availableEquipment).isNotEmpty)
        .toList();
  }

  static List<Exercise> substitutionsFor(String exerciseId) {
    final ex = byId(exerciseId);
    if (ex == null) return [];
    return ex.substitutions
        .map((id) => byId(id))
        .whereType<Exercise>()
        .toList();
  }
}
