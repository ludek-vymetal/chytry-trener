import '../models/user_profile.dart';
import '../models/goal.dart';
import '../services/training_service.dart';

import '../core/training/training_plan_models.dart';
import '../core/training/slots/exercise_slot.dart';
import '../core/training/exercises/exercise.dart';

class TrainingSlotPlanService {
  static List<SlotTrainingDayPlan> buildWeeklySlotPlan(UserProfile profile) {
    final goal = profile.goal;
    if (goal == null) return [];

    final p = TrainingService.calculate(profile);
    final freq = profile.trainingIntake?.frequencyPerWeek ?? 3;

    switch (goal.type) {
      case GoalType.physique:
        return _physiqueSlots(freq, p);

      case GoalType.weightGainSupport:
        return _physiqueSlots(freq, p);

      case GoalType.strength:
        return _strengthSlots(freq, p);

      case GoalType.weightLoss:
        return _weightLossSlots(freq, p);

      case GoalType.endurance:
        return _enduranceSlots(p);
    }
  }

  static List<SlotTrainingDayPlan> _physiqueSlots(
    int freq,
    TrainingPrescription p,
  ) {
    switch (freq) {
      case 2:
        return _upperLower2(p);
      case 3:
        return _fullbody3(p);
      default:
        return _upperLower4(p);
    }
  }

  static List<SlotTrainingDayPlan> _upperLower2(TrainingPrescription p) {
    return [
      SlotTrainingDayPlan(
        dayLabel: 'Den 1',
        focus: 'Upper',
        slots: [
          _slot(
            ExerciseRole.chestPress,
            MovementPattern.press,
            {ExerciseModality.strength, ExerciseModality.hypertrophy},
            '4',
            p.reps,
            p.rir,
          ),
          _slot(
            ExerciseRole.horizontalPull,
            MovementPattern.row,
            {ExerciseModality.hypertrophy, ExerciseModality.strength},
            '4',
            '8–12',
            '2',
          ),
          _slot(
            ExerciseRole.shoulders,
            MovementPattern.press,
            {ExerciseModality.hypertrophy, ExerciseModality.strength},
            '3',
            '8–12',
            '2–3',
          ),
          _slot(
            ExerciseRole.biceps,
            MovementPattern.pull,
            {ExerciseModality.hypertrophy},
            '3',
            '10–15',
            '2–3',
          ),
          _slot(
            ExerciseRole.triceps,
            MovementPattern.press,
            {ExerciseModality.hypertrophy},
            '3',
            '10–15',
            '2–3',
          ),
        ],
      ),
      SlotTrainingDayPlan(
        dayLabel: 'Den 2',
        focus: 'Lower',
        slots: [
          _slot(
            ExerciseRole.quads,
            MovementPattern.squat,
            {ExerciseModality.strength, ExerciseModality.hypertrophy},
            '4',
            p.reps,
            p.rir,
          ),
          _slot(
            ExerciseRole.hamstrings,
            MovementPattern.hinge,
            {ExerciseModality.hypertrophy, ExerciseModality.strength},
            '4',
            '8–12',
            '2–3',
          ),
          _slot(
            ExerciseRole.glutes,
            MovementPattern.squat,
            {ExerciseModality.hypertrophy},
            '3',
            '10–12',
            '2–3',
          ),
          _slot(
            ExerciseRole.core,
            MovementPattern.core,
            {ExerciseModality.conditioning},
            '3',
            '10–15 / 20–30 s',
            '2–3',
          ),
        ],
      ),
    ];
  }

  static List<SlotTrainingDayPlan> _upperLower4(TrainingPrescription p) {
    return [
      SlotTrainingDayPlan(
        dayLabel: 'Den 1',
        focus: 'Upper (těžší tlak)',
        slots: [
          _slot(
            ExerciseRole.chestPress,
            MovementPattern.press,
            {ExerciseModality.strength, ExerciseModality.hypertrophy},
            '4',
            p.reps,
            p.rir,
          ),
          _slot(
            ExerciseRole.horizontalPull,
            MovementPattern.row,
            {ExerciseModality.strength, ExerciseModality.hypertrophy},
            '4',
            '8–12',
            '2',
          ),
          _slot(
            ExerciseRole.triceps,
            MovementPattern.press,
            {ExerciseModality.hypertrophy},
            '3',
            '10–15',
            '2–3',
          ),
        ],
      ),
      SlotTrainingDayPlan(
        dayLabel: 'Den 2',
        focus: 'Lower (dřep pattern)',
        slots: [
          _slot(
            ExerciseRole.quads,
            MovementPattern.squat,
            {ExerciseModality.strength, ExerciseModality.hypertrophy},
            '4',
            p.reps,
            p.rir,
          ),
          _slot(
            ExerciseRole.hamstrings,
            MovementPattern.hinge,
            {ExerciseModality.hypertrophy, ExerciseModality.strength},
            '4',
            '8–12',
            '2–3',
          ),
          _slot(
            ExerciseRole.core,
            MovementPattern.core,
            {ExerciseModality.conditioning},
            '3',
            '10–15 / 20–30 s',
            '2–3',
          ),
        ],
      ),
      SlotTrainingDayPlan(
        dayLabel: 'Den 3',
        focus: 'Upper (objem)',
        slots: [
          _slot(
            ExerciseRole.chestPress,
            MovementPattern.press,
            {ExerciseModality.hypertrophy},
            '4',
            '8–12',
            '2–3',
          ),
          _slot(
            ExerciseRole.verticalPull,
            MovementPattern.pull,
            {ExerciseModality.hypertrophy},
            '4',
            '8–12',
            '2–3',
          ),
          _slot(
            ExerciseRole.shoulders,
            MovementPattern.press,
            {ExerciseModality.hypertrophy},
            '3',
            '12–20',
            '2–3',
          ),
        ],
      ),
      SlotTrainingDayPlan(
        dayLabel: 'Den 4',
        focus: 'Lower (tah pattern)',
        slots: [
          _slot(
            ExerciseRole.mainHinge,
            MovementPattern.hinge,
            {ExerciseModality.strength, ExerciseModality.hypertrophy},
            '4',
            '5–8',
            '2–3',
          ),
          _slot(
            ExerciseRole.glutes,
            MovementPattern.squat,
            {ExerciseModality.hypertrophy},
            '3',
            '10–12',
            '2–3',
          ),
          _slot(
            ExerciseRole.hamstrings,
            MovementPattern.hinge,
            {ExerciseModality.hypertrophy},
            '3',
            '10–15',
            '2–3',
          ),
        ],
      ),
    ];
  }

  static List<SlotTrainingDayPlan> _fullbody3(TrainingPrescription p) {
    return [
      SlotTrainingDayPlan(
        dayLabel: 'Den 1',
        focus: 'Fullbody A',
        slots: [
          _slot(
            ExerciseRole.quads,
            MovementPattern.squat,
            {ExerciseModality.strength, ExerciseModality.hypertrophy},
            '4',
            p.reps,
            p.rir,
          ),
          _slot(
            ExerciseRole.chestPress,
            MovementPattern.press,
            {ExerciseModality.strength, ExerciseModality.hypertrophy},
            '4',
            p.reps,
            p.rir,
          ),
          _slot(
            ExerciseRole.horizontalPull,
            MovementPattern.row,
            {ExerciseModality.hypertrophy},
            '4',
            '8–12',
            '2',
          ),
          _slot(
            ExerciseRole.core,
            MovementPattern.core,
            {ExerciseModality.conditioning},
            '3',
            '10–15 / 20–30 s',
            '2–3',
          ),
        ],
      ),
      SlotTrainingDayPlan(
        dayLabel: 'Den 2',
        focus: 'Fullbody B',
        slots: [
          _slot(
            ExerciseRole.mainHinge,
            MovementPattern.hinge,
            {ExerciseModality.hypertrophy, ExerciseModality.strength},
            '4',
            '6–10',
            '2–3',
          ),
          _slot(
            ExerciseRole.shoulders,
            MovementPattern.press,
            {ExerciseModality.hypertrophy},
            '3',
            '8–12',
            '2',
          ),
          _slot(
            ExerciseRole.verticalPull,
            MovementPattern.pull,
            {ExerciseModality.hypertrophy},
            '4',
            '8–12',
            '2',
          ),
          _slot(
            ExerciseRole.biceps,
            MovementPattern.pull,
            {ExerciseModality.hypertrophy},
            '3',
            '10–15',
            '2–3',
          ),
        ],
      ),
      SlotTrainingDayPlan(
        dayLabel: 'Den 3',
        focus: 'Fullbody C',
        slots: [
          _slot(
            ExerciseRole.glutes,
            MovementPattern.squat,
            {ExerciseModality.hypertrophy},
            '4',
            '10–15',
            '2–3',
          ),
          _slot(
            ExerciseRole.chestPress,
            MovementPattern.press,
            {ExerciseModality.hypertrophy},
            '4',
            '8–12',
            '2–3',
          ),
          _slot(
            ExerciseRole.horizontalPull,
            MovementPattern.row,
            {ExerciseModality.hypertrophy},
            '4',
            '8–12',
            '2–3',
          ),
          _slot(
            ExerciseRole.shoulders,
            MovementPattern.press,
            {ExerciseModality.hypertrophy},
            '3',
            '12–20',
            '2–3',
          ),
        ],
      ),
    ];
  }

  static List<SlotTrainingDayPlan> _strengthSlots(
    int freq,
    TrainingPrescription p,
  ) {
    if (freq <= 3) return _fullbody3(p);
    return _upperLower4(p);
  }

  static List<SlotTrainingDayPlan> _weightLossSlots(
    int freq,
    TrainingPrescription p,
  ) {
    return _fullbody3(p);
  }

  static List<SlotTrainingDayPlan> _enduranceSlots(TrainingPrescription p) {
    return [
      SlotTrainingDayPlan(
        dayLabel: 'Den 1',
        focus: 'Síla doplněk',
        slots: [
          _slot(
            ExerciseRole.quads,
            MovementPattern.squat,
            {ExerciseModality.strength, ExerciseModality.hypertrophy},
            '3',
            '5–8',
            '2–3',
          ),
          _slot(
            ExerciseRole.chestPress,
            MovementPattern.press,
            {ExerciseModality.hypertrophy},
            '3',
            '6–10',
            '2–3',
          ),
          _slot(
            ExerciseRole.horizontalPull,
            MovementPattern.row,
            {ExerciseModality.hypertrophy},
            '3',
            '8–12',
            '2–3',
          ),
          _slot(
            ExerciseRole.core,
            MovementPattern.core,
            {ExerciseModality.conditioning},
            '3',
            '10–15 / 20–30 s',
            '2–3',
          ),
        ],
      ),
      SlotTrainingDayPlan(
        dayLabel: 'Den 2',
        focus: 'Prevence',
        slots: [
          _slot(
            ExerciseRole.mainHinge,
            MovementPattern.hinge,
            {ExerciseModality.hypertrophy},
            '3',
            '6–10',
            '2–3',
          ),
          _slot(
            ExerciseRole.glutes,
            MovementPattern.squat,
            {ExerciseModality.hypertrophy},
            '3',
            '10–12',
            '2–3',
          ),
          _slot(
            ExerciseRole.core,
            MovementPattern.core,
            {ExerciseModality.conditioning},
            '3',
            '10–15 / 20–30 s',
            '2–3',
          ),
        ],
      ),
    ];
  }

  static ExerciseSlot _slot(
    ExerciseRole role,
    MovementPattern pattern,
    Set<ExerciseModality> modalities,
    String sets,
    String reps,
    String rir,
  ) {
    return ExerciseSlot(
      role: role,
      pattern: pattern,
      modalities: modalities,
      sets: sets,
      reps: reps,
      rir: rir,
    );
  }
}