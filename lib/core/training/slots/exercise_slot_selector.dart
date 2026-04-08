import '../exercises/exercise.dart';
import '../exercises/exercise_db.dart';
import 'exercise_slot.dart';

class ExerciseSlotSelector {
  /// Vrátí všechny vhodné cviky pro daný slot
  static List<Exercise> getOptionsForSlot(
    ExerciseSlot slot, {
    Set<String>? availableEquipment,
  }) {
    return ExerciseDB.all.where((ex) {
      // 1) Pattern musí sedět
      if (ex.pattern != slot.pattern) return false;

      // 2) Modalita musí být povolená
      if (!slot.modalities.contains(ex.modality)) return false;

      // 3) Role slotu musí sedět na sval / účel cviku
      if (!_matchesRole(slot, ex)) return false;

      // 4) Kontrola vybavení (pokud je zadané)
      if (availableEquipment != null) {
        final hasEquipment =
            ex.equipment.any((e) => availableEquipment.contains(e));

        if (!hasEquipment) return false;
      }

      return true;
    }).toList();
  }

  static bool _matchesRole(ExerciseSlot slot, Exercise ex) {
    switch (slot.role) {
      case ExerciseRole.mainSquat:
        return ex.id == ExerciseIds.squat ||
            ex.id == ExerciseIds.frontSquat ||
            ex.id == ExerciseIds.pauseSquat ||
            ex.id == ExerciseIds.tempoSquat;

      case ExerciseRole.mainPress:
        return ex.id == ExerciseIds.bench ||
            ex.id == ExerciseIds.pauseBench ||
            ex.id == ExerciseIds.closeGripBench ||
            ex.id == ExerciseIds.overheadPress;

      case ExerciseRole.mainHinge:
        return ex.id == ExerciseIds.deadlift ||
            ex.id == ExerciseIds.rdl ||
            ex.id == ExerciseIds.blockPull;

      case ExerciseRole.chestPress:
        return ex.primaryMuscles.contains('chest');

      case ExerciseRole.verticalPull:
        return ex.pattern == MovementPattern.pull &&
            ex.primaryMuscles.contains('back');

      case ExerciseRole.horizontalPull:
        return ex.pattern == MovementPattern.row &&
            ex.primaryMuscles.contains('back');

      case ExerciseRole.quads:
        return ex.primaryMuscles.contains('quads');

      case ExerciseRole.hamstrings:
        return ex.primaryMuscles.contains('hamstrings');

      case ExerciseRole.glutes:
        return ex.primaryMuscles.contains('glutes');

      case ExerciseRole.shoulders:
        return ex.primaryMuscles.contains('delts') ||
            ex.primaryMuscles.contains('front_delts');

      case ExerciseRole.triceps:
        return ex.primaryMuscles.contains('triceps');

      case ExerciseRole.biceps:
        return ex.primaryMuscles.contains('biceps');

      case ExerciseRole.core:
        return ex.primaryMuscles.contains('core');

      case ExerciseRole.conditioning:
        return ex.modality == ExerciseModality.conditioning ||
            ex.modality == ExerciseModality.endurance ||
            ex.pattern == MovementPattern.locomotion;
    }
  }

  /// Najde default cvik pro slot
  static Exercise? getDefaultForSlot(
    ExerciseSlot slot, {
    Set<String>? availableEquipment,
  }) {
    final options = getOptionsForSlot(
      slot,
      availableEquipment: availableEquipment,
    );
    return options.isEmpty ? null : options.first;
  }
}