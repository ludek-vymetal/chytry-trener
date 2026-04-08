import '../models/user_profile.dart';
import '../models/goal.dart';
import '../services/training_service.dart';
import '../core/training/training_plan_models.dart';

import '../core/training/exercises/exercise.dart';
import '../core/training/exercises/exercise_db.dart';
import '../core/training/slots/exercise_slot.dart';
import '../core/training/slots/exercise_slot_selector.dart';
import '../core/training/loads/weight_calculator.dart';

import '../core/training/sessions/training_session.dart';
import '../core/training/progression/progression_service.dart';
import '../services/training_slot_plan_service.dart';
import '../core/training/exercises/exercise_presets.dart';

class TrainingPlanService {
  // ✅ přidán parametr history + slotSelections
  static List<TrainingDayPlan> buildWeeklyPlan(
    UserProfile profile, {
    List<TrainingSession> history = const [],
    Map<String, String> slotSelections = const {},
  }) {
    final goal = profile.goal;
    if (goal == null) return [];

    // Parametry (reps/sets/rir) řízené fází a datem
    final presc = TrainingService.calculate(profile);

    // Frequency řízené dotazníkem
    final freq = profile.trainingIntake?.frequencyPerWeek ?? 3;

    final isStrengthCompetition =
        goal.type == GoalType.strength && goal.reason == GoalReason.competition;

    late final List<TrainingDayPlan> basePlan;

    if (slotSelections.isNotEmpty) {
      basePlan = _buildWeeklyPlanFromSelectedSlots(profile, slotSelections);
    } else {
      switch (goal.type) {
        case GoalType.strength:
          basePlan = isStrengthCompetition
              ? _strengthCompetitionByFrequency(profile, freq, presc)
              : _strengthByFrequency(freq, presc);
          break;

        case GoalType.physique:
          basePlan = _physiqueByFrequency(profile, freq, presc);
          break;

        case GoalType.weightLoss:
          basePlan = _weightLossByFrequency(freq, presc);
          break;

        case GoalType.endurance:
          basePlan = _enduranceSupport(presc);
          break;

        case GoalType.weightGainSupport:
          basePlan = _physiqueByFrequency(profile, freq, presc);
          break;
      }
    }

    // ✅ TADY se aplikuje progres podle historie logů
    return _applyProgression(profile, basePlan, history);
  }

  // ==========================================================
  // ✅ PROGRESSION APPLY (zvyšování váhy příště)
  // ==========================================================
  static List<TrainingDayPlan> _applyProgression(
    UserProfile profile,
    List<TrainingDayPlan> plan,
    List<TrainingSession> history,
  ) {
    return plan.map((day) {
      final newExercises = day.exercises.map((ex) {
        final next = ProgressionService.nextWeightKg(
          profile: profile,
          planned: ex,
          history: history,
        );

        if (next == null || ex.weightKg == next) return ex;

        return PlannedExercise(
          name: ex.name,
          exerciseId: ex.exerciseId,
          sets: ex.sets,
          reps: ex.reps,
          rir: ex.rir,
          note: ex.note,
          intensityPercent: ex.intensityPercent,
          weightKg: next,
          plannedSets: ex.plannedSets,
        );
      }).toList();

      return TrainingDayPlan(
        dayLabel: day.dayLabel,
        focus: day.focus,
        exercises: newExercises,
      );
    }).toList();
  }

  // ==========================================================
  // ✅ BUILD FROM SLOT SELECTIONS
  // ==========================================================
  static List<TrainingDayPlan> _buildWeeklyPlanFromSelectedSlots(
    UserProfile profile,
    Map<String, String> slotSelections,
  ) {
    final slotPlan = TrainingSlotPlanService.buildWeeklySlotPlan(profile);
    final equipment = profile.trainingIntake?.equipment ?? {'bodyweight'};

    return slotPlan.map((day) {
      final exercises = <PlannedExercise>[];

      for (int i = 0; i < day.slots.length; i++) {
        final slot = day.slots[i];
        final key = '${day.dayLabel}|$i';

        final selectedId = slotSelections[key];
        final selectedExercise = _findExerciseById(selectedId);

        final resolvedExercise =
            selectedExercise ?? _fallbackExerciseForSlot(slot, equipment);

        exercises.add(
          PlannedExercise(
            name: resolvedExercise?.name ?? _fallbackSlotLabel(slot),
            exerciseId: resolvedExercise?.id,
            sets: slot.sets,
            reps: slot.reps,
            rir: slot.rir,
          ),
        );
      }

      return TrainingDayPlan(
        dayLabel: day.dayLabel,
        focus: day.focus,
        exercises: exercises,
      );
    }).toList();
  }

  static Exercise? _findExerciseById(String? id) {
    if (id == null) return null;

    try {
      return ExerciseDB.all.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  static Exercise? _fallbackExerciseForSlot(
    ExerciseSlot slot,
    Set<String> equipment,
  ) {
    final options = ExerciseSlotSelector.getOptionsForSlot(
      slot,
      availableEquipment: equipment,
    );

    if (options.isEmpty) return null;
    return options.first;
  }

  static String _fallbackSlotLabel(ExerciseSlot slot) {
    switch (slot.role) {
      case ExerciseRole.mainSquat:
        return 'Dřepový cvik';
      case ExerciseRole.mainPress:
        return 'Tlakový cvik';
      case ExerciseRole.mainHinge:
        return 'Tahový cvik';
      case ExerciseRole.chestPress:
        return 'Tlak na hrudník';
      case ExerciseRole.verticalPull:
        return 'Vertikální tah';
      case ExerciseRole.horizontalPull:
        return 'Horizontální tah';
      case ExerciseRole.quads:
        return 'Kvadricepsy';
      case ExerciseRole.hamstrings:
        return 'Hamstringy';
      case ExerciseRole.glutes:
        return 'Hýždě';
      case ExerciseRole.shoulders:
        return 'Ramena';
      case ExerciseRole.triceps:
        return 'Triceps';
      case ExerciseRole.biceps:
        return 'Biceps';
      case ExerciseRole.core:
        return 'Střed těla';
      case ExerciseRole.conditioning:
        return 'Kondice';
    }

   
  }

  // ==========================================================
  // HELPERS (váhy + popisek)
  // ==========================================================

  static double? _w(UserProfile profile, String exerciseId, double intensity) {
    final intake = profile.trainingIntake;
    if (intake == null) return null;

    final oneRm = intake.oneRMs[exerciseId];
    if (oneRm == null) return null;

    return WeightCalculator.weightFromTm(
      oneRm: oneRm,
      intensityPercent: intensity,
      trainingMaxPercent: intake.trainingMaxPercent,
      roundTo: 2.5,
    );
  }

  static String _pctLabel(double p) => '${(p * 100).round()}% TM';

  static double _mainIntensity(TrainingPrescription p) {
    if (p.peakMode) return 0.88;
    if (p.weeksToTarget <= 4) return 0.85;
    return 0.80;
  }

  static String? _warmupAndWorkNote(
    UserProfile profile, {
    required String exerciseId,
    required double workIntensity,
    required int workSets,
    required String workRepsLabel,
  }) {
    final intake = profile.trainingIntake;
    if (intake == null) return null;

    final oneRm = intake.oneRMs[exerciseId];
    if (oneRm == null) return null;

    int reps;
    try {
      reps = int.parse(workRepsLabel.split('–').first);
    } catch (_) {
      reps = 5;
    }

    final sets = WeightCalculator.buildWarmupAndWorkSets(
      oneRm: oneRm,
      trainingMaxPercent: intake.trainingMaxPercent,
      workIntensityPercent: workIntensity,
      workSets: workSets,
      workReps: reps,
    );

    final warmups = sets.where((s) => s.note == 'Rozcvička');
    final works = sets.where((s) => s.note == 'Pracovní');

    String format(dynamic s) => '${s.weightKg.toStringAsFixed(1)} kg × ${s.reps}';

    final warmupText = warmups.map(format).join(', ');
    final workText = works.map(format).join(', ');

    return 'Zahřátí: $warmupText | Práce: $workText';
  }

  // ==========================================================
  // PHYSIQUE HELPERS – výběr cviků z presetů
  // ==========================================================

  static Exercise? _pickExercise(
    UserProfile profile,
    List<String> ids, {
    Set<String>? usedIds,
  }) {
    final availableEquipment = profile.trainingIntake?.equipment;

    final all = ids
        .map(_findExerciseById)
        .whereType<Exercise>()
        .where((ex) => usedIds == null || !usedIds.contains(ex.id))
        .toList();

    if (all.isEmpty) return null;

    if (availableEquipment == null || availableEquipment.isEmpty) {
      return all.first;
    }

    final equipped = all.where((ex) {
      return ex.equipment.any((eq) => availableEquipment.contains(eq));
    }).toList();

    if (equipped.isNotEmpty) return equipped.first;

    return all.first;
  }

  static String _displayExerciseName(Exercise? ex, String fallback) {
    if (ex == null) return fallback;
    return ex.displayName;
  }

  static PlannedExercise _peFromExercise(
    Exercise? ex, {
    required String fallbackName,
    required String sets,
    required String reps,
    required String rir,
    String? note,
  }) {
    return PlannedExercise(
      name: _displayExerciseName(ex, fallbackName),
      exerciseId: ex?.id,
      sets: sets,
      reps: reps,
      rir: rir,
      note: note,
    );
  }

  static List<PlannedExercise> _buildUpperDayA(
    UserProfile profile,
    TrainingPrescription p,
  ) {
    final used = <String>{};

    final chestMain = _pickExercise(profile, ExercisePresets.chestMain, usedIds: used);
    if (chestMain != null) used.add(chestMain.id);

    final chestSecondary = _pickExercise(profile, ExercisePresets.chestSecondary, usedIds: used);
    if (chestSecondary != null) used.add(chestSecondary.id);

    final chestIsolation = _pickExercise(profile, ExercisePresets.chestIsolation, usedIds: used);
    if (chestIsolation != null) used.add(chestIsolation.id);

    final backVertical = _pickExercise(profile, ExercisePresets.backVertical, usedIds: used);
    if (backVertical != null) used.add(backVertical.id);

    final backHorizontal = _pickExercise(profile, ExercisePresets.backHorizontal, usedIds: used);
    if (backHorizontal != null) used.add(backHorizontal.id);

    final shouldersLateral = _pickExercise(profile, ExercisePresets.shouldersLateral, usedIds: used);
    if (shouldersLateral != null) used.add(shouldersLateral.id);

    final tricepsIso = _pickExercise(profile, ExercisePresets.tricepsIsolation, usedIds: used);
    if (tricepsIso != null) used.add(tricepsIso.id);

    final bicepsMain = _pickExercise(profile, ExercisePresets.bicepsMain, usedIds: used);
    if (bicepsMain != null) used.add(bicepsMain.id);

    return [
      _peFromExercise(
        chestMain,
        fallbackName: 'Bench press',
        sets: '4',
        reps: p.reps,
        rir: p.rir,
      ),
      _peFromExercise(
        chestSecondary,
        fallbackName: 'Tlaky na šikmé lavici',
        sets: '4',
        reps: '8–12',
        rir: '1–2',
      ),
      _peFromExercise(
        chestIsolation,
        fallbackName: 'Rozpažky / kladky',
        sets: '3',
        reps: '12–15',
        rir: '2–3',
      ),
      _peFromExercise(
        backVertical,
        fallbackName: 'Stahování horní kladky / shyby',
        sets: '4',
        reps: '8–12',
        rir: '1–2',
      ),
      _peFromExercise(
        backHorizontal,
        fallbackName: 'Přítahy / veslo',
        sets: '4',
        reps: '8–12',
        rir: '1–2',
      ),
      _peFromExercise(
        shouldersLateral,
        fallbackName: 'Upažování',
        sets: '3',
        reps: '12–20',
        rir: '2–3',
      ),
      _peFromExercise(
        tricepsIso,
        fallbackName: 'Triceps – kladka',
        sets: '3',
        reps: '10–15',
        rir: '2–3',
      ),
      _peFromExercise(
        bicepsMain,
        fallbackName: 'Bicepsový zdvih',
        sets: '3',
        reps: '10–15',
        rir: '2–3',
      ),
    ];
  }

  static List<PlannedExercise> _buildUpperDayB(
    UserProfile profile,
    TrainingPrescription p,
  ) {
    final used = <String>{};

    final chestMain = _pickExercise(profile, ExercisePresets.chestMain, usedIds: used);
    if (chestMain != null) used.add(chestMain.id);

    final chestSecondary = _pickExercise(profile, ExercisePresets.chestSecondary, usedIds: used);
    if (chestSecondary != null) used.add(chestSecondary.id);

    final chestIsolation = _pickExercise(profile, ExercisePresets.chestIsolation, usedIds: used);
    if (chestIsolation != null) used.add(chestIsolation.id);

    final backHorizontal = _pickExercise(profile, ExercisePresets.backHorizontal, usedIds: used);
    if (backHorizontal != null) used.add(backHorizontal.id);

    final backVertical = _pickExercise(profile, ExercisePresets.backVertical, usedIds: used);
    if (backVertical != null) used.add(backVertical.id);

    final shouldersRear = _pickExercise(profile, ExercisePresets.shouldersRear, usedIds: used);
    if (shouldersRear != null) used.add(shouldersRear.id);

    final tricepsMain = _pickExercise(profile, ExercisePresets.tricepsMain, usedIds: used);
    if (tricepsMain != null) used.add(tricepsMain.id);

    final bicepsIso = _pickExercise(profile, ExercisePresets.bicepsIsolation, usedIds: used);
    if (bicepsIso != null) used.add(bicepsIso.id);

    return [
      _peFromExercise(
        chestMain,
        fallbackName: 'Bench press',
        sets: '4',
        reps: '6–10',
        rir: '1–2',
      ),
      _peFromExercise(
        chestSecondary,
        fallbackName: 'Druhý tlak na prsa',
        sets: '4',
        reps: '8–12',
        rir: '1–2',
      ),
      _peFromExercise(
        chestIsolation,
        fallbackName: 'Kladky / rozpažky',
        sets: '3',
        reps: '12–15',
        rir: '2–3',
      ),
      _peFromExercise(
        backHorizontal,
        fallbackName: 'Přítahy / veslo',
        sets: '4',
        reps: '8–12',
        rir: '1–2',
      ),
      _peFromExercise(
        backVertical,
        fallbackName: 'Shyby / kladka',
        sets: '4',
        reps: '8–12',
        rir: '1–2',
      ),
      _peFromExercise(
        shouldersRear,
        fallbackName: 'Zadní delty',
        sets: '3',
        reps: '12–20',
        rir: '2–3',
      ),
      _peFromExercise(
        tricepsMain,
        fallbackName: 'Triceps',
        sets: '3',
        reps: '8–12',
        rir: '2',
      ),
      _peFromExercise(
        bicepsIso,
        fallbackName: 'Biceps',
        sets: '3',
        reps: '10–15',
        rir: '2–3',
      ),
    ];
  }

  static List<PlannedExercise> _buildLowerDayA(
    UserProfile profile,
    TrainingPrescription p,
  ) {
    final used = <String>{};

    final quadsMain = _pickExercise(profile, ExercisePresets.quadsMain, usedIds: used);
    if (quadsMain != null) used.add(quadsMain.id);

    final quadsIso = _pickExercise(profile, ExercisePresets.quadsIsolation, usedIds: used);
    if (quadsIso != null) used.add(quadsIso.id);

    final hamMain = _pickExercise(profile, ExercisePresets.hamstringsMain, usedIds: used);
    if (hamMain != null) used.add(hamMain.id);

    final glutesMain = _pickExercise(profile, ExercisePresets.glutesMain, usedIds: used);
    if (glutesMain != null) used.add(glutesMain.id);

    final coreMain = _pickExercise(profile, ExercisePresets.coreMain, usedIds: used);
    if (coreMain != null) used.add(coreMain.id);

    return [
      _peFromExercise(
        quadsMain,
        fallbackName: 'Dřep / leg press',
        sets: '4',
        reps: p.reps,
        rir: p.rir,
      ),
      _peFromExercise(
        quadsIso,
        fallbackName: 'Předkopávání',
        sets: '3',
        reps: '10–15',
        rir: '2–3',
      ),
      _peFromExercise(
        hamMain,
        fallbackName: 'Rumunský mrtvý tah',
        sets: '4',
        reps: '6–10',
        rir: '1–2',
      ),
      _peFromExercise(
        glutesMain,
        fallbackName: 'Hip thrust / bulharské dřepy',
        sets: '3',
        reps: '8–12',
        rir: '2–3',
      ),
      _peFromExercise(
        coreMain,
        fallbackName: 'Core',
        sets: '3',
        reps: '10–15 / 20–30 s',
        rir: '2–3',
      ),
    ];
  }

  static List<PlannedExercise> _buildLowerDayB(
    UserProfile profile,
    TrainingPrescription p,
  ) {
    final used = <String>{};

    final quadsMain = _pickExercise(profile, ExercisePresets.quadsMain, usedIds: used);
    if (quadsMain != null) used.add(quadsMain.id);

    final hamIso = _pickExercise(profile, ExercisePresets.hamstringsIsolation, usedIds: used);
    if (hamIso != null) used.add(hamIso.id);

    final glutesIso = _pickExercise(profile, ExercisePresets.glutesIsolation, usedIds: used);
    if (glutesIso != null) used.add(glutesIso.id);

    final hamMain = _pickExercise(profile, ExercisePresets.hamstringsMain, usedIds: used);
    if (hamMain != null) used.add(hamMain.id);

    final coreMain = _pickExercise(profile, ExercisePresets.coreMain, usedIds: used);
    if (coreMain != null) used.add(coreMain.id);

    return [
      _peFromExercise(
        quadsMain,
        fallbackName: 'Leg press / hack-dřep',
        sets: '4',
        reps: '8–12',
        rir: '2–3',
      ),
      _peFromExercise(
        hamMain,
        fallbackName: 'RDL / stiff-leg deadlift',
        sets: '4',
        reps: '6–10',
        rir: '1–2',
      ),
      _peFromExercise(
        hamIso,
        fallbackName: 'Zakopávání',
        sets: '3',
        reps: '10–15',
        rir: '2–3',
      ),
      _peFromExercise(
        glutesIso,
        fallbackName: 'Zanožování / abdukce',
        sets: '3',
        reps: '12–20',
        rir: '2–3',
      ),
      _peFromExercise(
        coreMain,
        fallbackName: 'Core',
        sets: '3',
        reps: '10–15 / 20–30 s',
        rir: '2–3',
      ),
    ];
  }

  static List<PlannedExercise> _buildFullBodyDay(
    UserProfile profile,
    TrainingPrescription p,
  ) {
    final used = <String>{};

    final quadsMain = _pickExercise(profile, ExercisePresets.quadsMain, usedIds: used);
    if (quadsMain != null) used.add(quadsMain.id);

    final chestSecondary = _pickExercise(profile, ExercisePresets.chestSecondary, usedIds: used);
    if (chestSecondary != null) used.add(chestSecondary.id);

    final chestIsolation = _pickExercise(profile, ExercisePresets.chestIsolation, usedIds: used);
    if (chestIsolation != null) used.add(chestIsolation.id);

    final backVertical = _pickExercise(profile, ExercisePresets.backVertical, usedIds: used);
    if (backVertical != null) used.add(backVertical.id);

    final backHorizontal = _pickExercise(profile, ExercisePresets.backHorizontal, usedIds: used);
    if (backHorizontal != null) used.add(backHorizontal.id);

    final shouldersRear = _pickExercise(profile, ExercisePresets.shouldersRear, usedIds: used);
    if (shouldersRear != null) used.add(shouldersRear.id);

    final bicepsMain = _pickExercise(profile, ExercisePresets.bicepsMain, usedIds: used);
    if (bicepsMain != null) used.add(bicepsMain.id);

    final tricepsIso = _pickExercise(profile, ExercisePresets.tricepsIsolation, usedIds: used);
    if (tricepsIso != null) used.add(tricepsIso.id);

    final coreMain = _pickExercise(profile, ExercisePresets.coreMain, usedIds: used);
    if (coreMain != null) used.add(coreMain.id);

    return [
      _peFromExercise(
        quadsMain,
        fallbackName: 'Dřep / leg press',
        sets: '4',
        reps: p.reps,
        rir: p.rir,
      ),
      _peFromExercise(
        chestSecondary,
        fallbackName: 'Tlaky na šikmé lavici',
        sets: '4',
        reps: '8–12',
        rir: '1–2',
      ),
      _peFromExercise(
        chestIsolation,
        fallbackName: 'Rozpažky / kladky',
        sets: '3',
        reps: '12–15',
        rir: '2–3',
      ),
      _peFromExercise(
        backVertical,
        fallbackName: 'Kladka / shyby',
        sets: '4',
        reps: '8–12',
        rir: '1–2',
      ),
      _peFromExercise(
        backHorizontal,
        fallbackName: 'Přítahy / veslo',
        sets: '4',
        reps: '8–12',
        rir: '1–2',
      ),
      _peFromExercise(
        shouldersRear,
        fallbackName: 'Zadní delty',
        sets: '3',
        reps: '12–20',
        rir: '2–3',
      ),
      _peFromExercise(
        tricepsIso,
        fallbackName: 'Triceps',
        sets: '2–3',
        reps: '10–15',
        rir: '2–3',
      ),
      _peFromExercise(
        bicepsMain,
        fallbackName: 'Biceps',
        sets: '2–3',
        reps: '10–15',
        rir: '2–3',
      ),
      _peFromExercise(
        coreMain,
        fallbackName: 'Core',
        sets: '3',
        reps: '10–15 / 20–30 s',
        rir: '2–3',
      ),
    ];
  }

  // ==========================================================
  // PHYSIQUE – podle frekvence
  // ==========================================================
  static List<TrainingDayPlan> _physiqueByFrequency(
    UserProfile profile,
    int freq,
    TrainingPrescription p,
  ) {
    switch (freq) {
      case 2:
        return _upperLower2Day(profile, p);
      case 3:
        return _upperLowerFullbody3Day(profile, p);
      case 4:
        return _upperLower4Day(profile, p);
      case 5:
        return _ppl5Day(profile, p);
      case 6:
        return _ppl6Day(profile, p);
      default:
        return _upperLower4Day(profile, p);
    }
  }

  // ==========================================================
  // STRENGTH – podle frekvence (MVP)
  // ==========================================================
  static List<TrainingDayPlan> _strengthByFrequency(
    int freq,
    TrainingPrescription p,
  ) {
    switch (freq) {
      case 2:
        return _strengthFullbody2Day(p);
      case 3:
        return _strength3Day(p);
      case 4:
        return _strengthUpperLower4Day(p);
      case 5:
      case 6:
        return _strengthUpperLower4Day(p);
      default:
        return _strength3Day(p);
    }
  }

  // ==========================================================
  // STRENGTH + COMPETITION – podle frekvence + váhy z TM
  // ==========================================================
  static List<TrainingDayPlan> _strengthCompetitionByFrequency(
    UserProfile profile,
    int freq,
    TrainingPrescription p,
  ) {
    switch (freq) {
      case 2:
        return _strengthCompFullbody2(profile, p);
      case 3:
        return _strengthComp3Day(profile, p);
      case 4:
      case 5:
      case 6:
        return _strengthCompUpperLower4(profile, p);
      default:
        return _strengthComp3Day(profile, p);
    }
  }

  // ==========================================================
  // 🏆 COMPETITION – 3 DNY
  // ==========================================================
  static List<TrainingDayPlan> _strengthComp3Day(
    UserProfile profile,
    TrainingPrescription p,
  ) {
    final main = _mainIntensity(p);
    final mainReps = p.peakMode ? '1–2' : '3';

    return [
      TrainingDayPlan(
        dayLabel: 'Den 1',
        focus: 'Závody – A (SQ + BP)',
        exercises: [
          PlannedExercise(
            name: 'Dřep',
            exerciseId: ExerciseIds.squat,
            sets: '5',
            reps: mainReps,
            rir: p.rir,
            intensityPercent: main,
            weightKg: _w(profile, ExerciseIds.squat, main),
            note: _warmupAndWorkNote(
                  profile,
                  exerciseId: ExerciseIds.squat,
                  workIntensity: main,
                  workSets: 5,
                  workRepsLabel: mainReps,
                ) ??
                _pctLabel(main),
          ),
          PlannedExercise(
            name: 'Bench press',
            exerciseId: ExerciseIds.bench,
            sets: '5',
            reps: mainReps,
            rir: p.rir,
            intensityPercent: main,
            weightKg: _w(profile, ExerciseIds.bench, main),
            note: _warmupAndWorkNote(
                  profile,
                  exerciseId: ExerciseIds.bench,
                  workIntensity: main,
                  workSets: 5,
                  workRepsLabel: mainReps,
                ) ??
                _pctLabel(main),
          ),
          PlannedExercise(name: 'RDL', sets: '3', reps: '6–8', rir: '2–3'),
          PlannedExercise(
            name: 'Střed těla',
            sets: '3',
            reps: '10–15 / 20–30 s',
            rir: '2–3',
            note: 'plank / dead bug / pallof press',
          ),
        ],
      ),
      TrainingDayPlan(
        dayLabel: 'Den 2',
        focus: 'Závody – B (DL + doplňky)',
        exercises: [
          PlannedExercise(
            name: 'Mrtvý tah',
            exerciseId: ExerciseIds.deadlift,
            sets: '4',
            reps: mainReps,
            rir: p.rir,
            intensityPercent: p.peakMode ? 0.85 : main,
            weightKg: _w(profile, ExerciseIds.deadlift, p.peakMode ? 0.85 : main),
            note: _warmupAndWorkNote(
                  profile,
                  exerciseId: ExerciseIds.deadlift,
                  workIntensity: p.peakMode ? 0.85 : main,
                  workSets: 4,
                  workRepsLabel: mainReps,
                ) ??
                _pctLabel(p.peakMode ? 0.85 : main),
          ),
          PlannedExercise(name: 'Přítahy / shyby', sets: '4', reps: '6–10', rir: '2'),
          PlannedExercise(name: 'Military press', sets: '3', reps: '6–10', rir: '2'),
          PlannedExercise(name: 'Hamstringy', sets: '3', reps: '8–12', rir: '2–3'),
        ],
      ),
      TrainingDayPlan(
        dayLabel: 'Den 3',
        focus: 'Závody – C (technika + objem)',
        exercises: [
          PlannedExercise(
            name: 'Pause squat / Front squat',
            exerciseId: ExerciseIds.pauseSquat,
            sets: '4',
            reps: '3–5',
            rir: '2–3',
            intensityPercent: 0.75,
            weightKg: _w(profile, ExerciseIds.squat, 0.75),
            note: _warmupAndWorkNote(
                  profile,
                  exerciseId: ExerciseIds.squat,
                  workIntensity: 0.75,
                  workSets: 4,
                  workRepsLabel: '3–5',
                ) ??
                '75% TM (z dřepu)',
          ),
          PlannedExercise(
            name: 'Pause bench',
            exerciseId: ExerciseIds.pauseBench,
            sets: '4',
            reps: '3–5',
            rir: '2–3',
            intensityPercent: 0.75,
            weightKg: _w(profile, ExerciseIds.bench, 0.75),
            note: _warmupAndWorkNote(
                  profile,
                  exerciseId: ExerciseIds.bench,
                  workIntensity: 0.75,
                  workSets: 4,
                  workRepsLabel: '3–5',
                ) ??
                '75% TM (z bench)',
          ),
          PlannedExercise(name: 'Row', sets: '4', reps: '8–12', rir: '2'),
          PlannedExercise(name: 'Triceps/Biceps', sets: '3', reps: '10–15', rir: '2–3'),
        ],
      ),
    ];
  }

  // ==========================================================
  // 🏆 COMPETITION – Upper/Lower 4× týdně
  // ==========================================================
  static List<TrainingDayPlan> _strengthCompUpperLower4(
    UserProfile profile,
    TrainingPrescription p,
  ) {
    final main = _mainIntensity(p);
    final mainReps = p.peakMode ? '1–2' : '3';

    return [
      TrainingDayPlan(
        dayLabel: 'Den 1',
        focus: 'Upper (BP heavy)',
        exercises: [
          PlannedExercise(
            name: 'Bench press',
            exerciseId: ExerciseIds.bench,
            sets: '5',
            reps: mainReps,
            rir: p.rir,
            intensityPercent: main,
            weightKg: _w(profile, ExerciseIds.bench, main),
            note: _warmupAndWorkNote(
                  profile,
                  exerciseId: ExerciseIds.bench,
                  workIntensity: main,
                  workSets: 5,
                  workRepsLabel: mainReps,
                ) ??
                _pctLabel(main),
          ),
          PlannedExercise(name: 'Row', sets: '5', reps: '6–10', rir: '2'),
          PlannedExercise(name: 'Triceps', sets: '3', reps: '10–15', rir: '2–3'),
        ],
      ),
      TrainingDayPlan(
        dayLabel: 'Den 2',
        focus: 'Lower (SQ heavy)',
        exercises: [
          PlannedExercise(
            name: 'Dřep',
            exerciseId: ExerciseIds.squat,
            sets: '5',
            reps: mainReps,
            rir: p.rir,
            intensityPercent: main,
            weightKg: _w(profile, ExerciseIds.squat, main),
            note: _warmupAndWorkNote(
                  profile,
                  exerciseId: ExerciseIds.squat,
                  workIntensity: main,
                  workSets: 5,
                  workRepsLabel: mainReps,
                ) ??
                _pctLabel(main),
          ),
          PlannedExercise(name: 'RDL', sets: '4', reps: '6–10', rir: '2–3'),
          PlannedExercise(name: 'Střed těla', sets: '3', reps: '10–15 / 20–30 s', rir: '2–3'),
        ],
      ),
      TrainingDayPlan(
        dayLabel: 'Den 3',
        focus: 'Upper (tech/volume)',
        exercises: [
          PlannedExercise(
            name: 'Pause bench',
            exerciseId: ExerciseIds.pauseBench,
            sets: '4',
            reps: '3–5',
            rir: '2–3',
            intensityPercent: 0.75,
            weightKg: _w(profile, ExerciseIds.bench, 0.75),
            note: _warmupAndWorkNote(
                  profile,
                  exerciseId: ExerciseIds.bench,
                  workIntensity: 0.75,
                  workSets: 4,
                  workRepsLabel: '3–5',
                ) ??
                '75% TM (z bench)',
          ),
          PlannedExercise(name: 'Lat pulldown / shyby', sets: '4', reps: '8–12', rir: '2'),
          PlannedExercise(name: 'Ramena', sets: '3', reps: '10–15', rir: '2–3'),
        ],
      ),
      TrainingDayPlan(
        dayLabel: 'Den 4',
        focus: 'Lower (DL heavy)',
        exercises: [
          PlannedExercise(
            name: 'Mrtvý tah',
            exerciseId: ExerciseIds.deadlift,
            sets: '4',
            reps: mainReps,
            rir: p.rir,
            intensityPercent: p.peakMode ? 0.85 : main,
            weightKg: _w(profile, ExerciseIds.deadlift, p.peakMode ? 0.85 : main),
            note: _warmupAndWorkNote(
                  profile,
                  exerciseId: ExerciseIds.deadlift,
                  workIntensity: p.peakMode ? 0.85 : main,
                  workSets: 4,
                  workRepsLabel: mainReps,
                ) ??
                _pctLabel(p.peakMode ? 0.85 : main),
          ),
          PlannedExercise(name: 'Leg press', sets: '3', reps: '8–12', rir: '2–3'),
          PlannedExercise(name: 'Hamstringy', sets: '3', reps: '10–15', rir: '2–3'),
        ],
      ),
    ];
  }

  // ==========================================================
  // 🏆 COMPETITION – Fullbody 2× týdně
  // ==========================================================
  static List<TrainingDayPlan> _strengthCompFullbody2(
    UserProfile profile,
    TrainingPrescription p,
  ) {
    final main = _mainIntensity(p);
    final mainReps = p.peakMode ? '1–2' : '3';

    return [
      TrainingDayPlan(
        dayLabel: 'Den 1',
        focus: 'Fullbody A (SQ + BP)',
        exercises: [
          PlannedExercise(
            name: 'Dřep',
            exerciseId: ExerciseIds.squat,
            sets: '5',
            reps: mainReps,
            rir: p.rir,
            intensityPercent: main,
            weightKg: _w(profile, ExerciseIds.squat, main),
            note: _warmupAndWorkNote(
                  profile,
                  exerciseId: ExerciseIds.squat,
                  workIntensity: main,
                  workSets: 5,
                  workRepsLabel: mainReps,
                ) ??
                _pctLabel(main),
          ),
          PlannedExercise(
            name: 'Bench press',
            exerciseId: ExerciseIds.bench,
            sets: '5',
            reps: mainReps,
            rir: p.rir,
            intensityPercent: main,
            weightKg: _w(profile, ExerciseIds.bench, main),
            note: _warmupAndWorkNote(
                  profile,
                  exerciseId: ExerciseIds.bench,
                  workIntensity: main,
                  workSets: 5,
                  workRepsLabel: mainReps,
                ) ??
                _pctLabel(main),
          ),
          PlannedExercise(name: 'Row', sets: '4', reps: '8–12', rir: '2'),
        ],
      ),
      TrainingDayPlan(
        dayLabel: 'Den 2',
        focus: 'Fullbody B (DL + BP tech)',
        exercises: [
          PlannedExercise(
            name: 'Mrtvý tah',
            exerciseId: ExerciseIds.deadlift,
            sets: '4',
            reps: mainReps,
            rir: p.rir,
            intensityPercent: p.peakMode ? 0.85 : main,
            weightKg: _w(profile, ExerciseIds.deadlift, p.peakMode ? 0.85 : main),
            note: _warmupAndWorkNote(
                  profile,
                  exerciseId: ExerciseIds.deadlift,
                  workIntensity: p.peakMode ? 0.85 : main,
                  workSets: 4,
                  workRepsLabel: mainReps,
                ) ??
                _pctLabel(p.peakMode ? 0.85 : main),
          ),
          PlannedExercise(
            name: 'Pause bench',
            exerciseId: ExerciseIds.pauseBench,
            sets: '4',
            reps: '3–5',
            rir: '2–3',
            intensityPercent: 0.75,
            weightKg: _w(profile, ExerciseIds.bench, 0.75),
            note: _warmupAndWorkNote(
                  profile,
                  exerciseId: ExerciseIds.bench,
                  workIntensity: 0.75,
                  workSets: 4,
                  workRepsLabel: '3–5',
                ) ??
                '75% TM (z bench)',
          ),
          PlannedExercise(name: 'Hamstringy', sets: '3', reps: '10–15', rir: '2–3'),
        ],
      ),
    ];
  }

  // ==========================================================
  // WEIGHT LOSS – podle frekvence
  // ==========================================================
  static List<TrainingDayPlan> _weightLossByFrequency(
    int freq,
    TrainingPrescription p,
  ) {
    switch (freq) {
      case 2:
        return _weightLossFullbody2Day(p);
      case 3:
        return _weightLossFullbody3Day(p);
      case 4:
        return _weightLossUpperLower4Day(p);
      case 5:
      case 6:
        return _weightLossUpperLower4Day(p);
      default:
        return _weightLossFullbody3Day(p);
    }
  }

  // ==========================================================
  // STRENGTH – 3 dny (A/B/C)
  // ==========================================================
  static List<TrainingDayPlan> _strength3Day(TrainingPrescription p) {
    return [
      TrainingDayPlan(
        dayLabel: 'Den 1',
        focus: 'Síla – A (dřep / tlak)',
        exercises: [
          PlannedExercise(name: 'Dřep', sets: '5', reps: p.reps, rir: p.rir),
          PlannedExercise(name: 'Bench press', sets: '5', reps: p.reps, rir: p.rir),
          PlannedExercise(name: 'Rumunský mrtvý tah', sets: '3', reps: '6–8', rir: '2–3'),
          PlannedExercise(name: 'Střed těla', sets: '3', reps: '10–15 / 20–30 s', rir: '2–3'),
        ],
      ),
      TrainingDayPlan(
        dayLabel: 'Den 2',
        focus: 'Síla – B (tah / doplňky)',
        exercises: [
          PlannedExercise(name: 'Mrtvý tah', sets: '4', reps: p.reps, rir: p.rir),
          PlannedExercise(name: 'Shyby / přítahy', sets: '4', reps: '6–10', rir: '1–2'),
          PlannedExercise(name: 'Military press', sets: '4', reps: '4–8', rir: '1–2'),
          PlannedExercise(name: 'Hamstringy', sets: '3', reps: '8–12', rir: '2–3'),
        ],
      ),
      TrainingDayPlan(
        dayLabel: 'Den 3',
        focus: 'Síla – C (objem + technika)',
        exercises: [
          PlannedExercise(name: 'Přední dřep / tempo dřep', sets: '4', reps: '3–6', rir: '2–3'),
          PlannedExercise(name: 'Bench – pauzy', sets: '4', reps: '3–6', rir: '2–3'),
          PlannedExercise(name: 'Přítahy v předklonu', sets: '4', reps: '6–10', rir: '1–2'),
          PlannedExercise(name: 'Triceps / biceps', sets: '3', reps: '10–15', rir: '2–3'),
        ],
      ),
    ];
  }

  static List<TrainingDayPlan> _strengthFullbody2Day(TrainingPrescription p) {
    return [
      TrainingDayPlan(
        dayLabel: 'Den 1',
        focus: 'Síla – Fullbody A (SQ + BP)',
        exercises: [
          PlannedExercise(name: 'Dřep', sets: '5', reps: p.reps, rir: p.rir),
          PlannedExercise(name: 'Bench press', sets: '5', reps: p.reps, rir: p.rir),
          PlannedExercise(name: 'Přítahy', sets: '4', reps: '6–10', rir: '2'),
          PlannedExercise(name: 'Střed těla', sets: '3', reps: '10–15 / 20–30 s', rir: '2–3'),
        ],
      ),
      TrainingDayPlan(
        dayLabel: 'Den 2',
        focus: 'Síla – Fullbody B (DL + BP variant)',
        exercises: [
          PlannedExercise(name: 'Mrtvý tah', sets: '4', reps: p.reps, rir: p.rir),
          PlannedExercise(name: 'Bench (pauzy / úzký)', sets: '4', reps: '3–6', rir: '2–3'),
          PlannedExercise(name: 'Hamstringy', sets: '3', reps: '8–12', rir: '2–3'),
          PlannedExercise(name: 'Záda', sets: '3', reps: '8–12', rir: '2–3'),
        ],
      ),
    ];
  }

  static List<TrainingDayPlan> _strengthUpperLower4Day(TrainingPrescription p) {
    return [
      TrainingDayPlan(
        dayLabel: 'Den 1',
        focus: 'Upper (síla)',
        exercises: [
          PlannedExercise(name: 'Bench press', sets: '5', reps: p.reps, rir: p.rir),
          PlannedExercise(name: 'Přítahy', sets: '5', reps: '6–10', rir: '2'),
          PlannedExercise(name: 'Military press', sets: '3', reps: '4–8', rir: '2'),
          PlannedExercise(name: 'Triceps', sets: '3', reps: '10–15', rir: '2–3'),
        ],
      ),
      TrainingDayPlan(
        dayLabel: 'Den 2',
        focus: 'Lower (síla)',
        exercises: [
          PlannedExercise(name: 'Dřep', sets: '5', reps: p.reps, rir: p.rir),
          PlannedExercise(name: 'Rumunský mrtvý tah', sets: '4', reps: '6–10', rir: '2–3'),
          PlannedExercise(name: 'Střed těla', sets: '3', reps: '10–15 / 20–30 s', rir: '2–3'),
        ],
      ),
      TrainingDayPlan(
        dayLabel: 'Den 3',
        focus: 'Upper (objem/technika)',
        exercises: [
          PlannedExercise(name: 'Bench (pauzy / úzký)', sets: '4', reps: '3–6', rir: '2–3'),
          PlannedExercise(name: 'Lat pulldown / shyby', sets: '4', reps: '6–12', rir: '2'),
          PlannedExercise(name: 'Upažování', sets: '3', reps: '12–20', rir: '2–3'),
          PlannedExercise(name: 'Biceps', sets: '3', reps: '10–15', rir: '2–3'),
        ],
      ),
      TrainingDayPlan(
        dayLabel: 'Den 4',
        focus: 'Lower (tah / doplňky)',
        exercises: [
          PlannedExercise(name: 'Mrtvý tah', sets: '4', reps: p.reps, rir: p.rir),
          PlannedExercise(name: 'Přední dřep / leg press', sets: '3', reps: '6–10', rir: '2–3'),
          PlannedExercise(name: 'Hamstringy', sets: '3', reps: '8–12', rir: '2–3'),
        ],
      ),
    ];
  }

  // ==========================================================
  // PHYSIQUE – struktury podle frekvence
  // ==========================================================
  static List<TrainingDayPlan> _upperLower2Day(
    UserProfile profile,
    TrainingPrescription p,
  ) {
    return [
      TrainingDayPlan(
        dayLabel: 'Den 1',
        focus: 'Upper',
        exercises: _buildUpperDayA(profile, p),
      ),
      TrainingDayPlan(
        dayLabel: 'Den 2',
        focus: 'Lower',
        exercises: _buildLowerDayA(profile, p),
      ),
    ];
  }

  static List<TrainingDayPlan> _upperLower4Day(
    UserProfile profile,
    TrainingPrescription p,
  ) {
    return [
      TrainingDayPlan(
        dayLabel: 'Den 1',
        focus: 'Upper A',
        exercises: _buildUpperDayA(profile, p),
      ),
      TrainingDayPlan(
        dayLabel: 'Den 2',
        focus: 'Lower A',
        exercises: _buildLowerDayA(profile, p),
      ),
      TrainingDayPlan(
        dayLabel: 'Den 3',
        focus: 'Upper B',
        exercises: _buildUpperDayB(profile, p),
      ),
      TrainingDayPlan(
        dayLabel: 'Den 4',
        focus: 'Lower B',
        exercises: _buildLowerDayB(profile, p),
      ),
    ];
  }

  static List<TrainingDayPlan> _upperLowerFullbody3Day(
    UserProfile profile,
    TrainingPrescription p,
  ) {
    return [
      TrainingDayPlan(
        dayLabel: 'Den 1',
        focus: 'Upper',
        exercises: _buildUpperDayA(profile, p),
      ),
      TrainingDayPlan(
        dayLabel: 'Den 2',
        focus: 'Lower',
        exercises: _buildLowerDayA(profile, p),
      ),
      TrainingDayPlan(
        dayLabel: 'Den 3',
        focus: 'Fullbody',
        exercises: _buildFullBodyDay(profile, p),
      ),
    ];
  }

  static List<TrainingDayPlan> _ppl6Day(
    UserProfile profile,
    TrainingPrescription p,
  ) {
    return [
      TrainingDayPlan(
        dayLabel: 'Den 1',
        focus: 'Push A',
        exercises: _buildUpperDayA(profile, p),
      ),
      TrainingDayPlan(
        dayLabel: 'Den 2',
        focus: 'Pull A',
        exercises: [
          ..._buildUpperDayB(profile, p).where((e) =>
              e.name.toLowerCase().contains('přít') ||
              e.name.toLowerCase().contains('kladk') ||
              e.name.toLowerCase().contains('shyb') ||
              e.name.toLowerCase().contains('biceps') ||
              e.name.toLowerCase().contains('zadní delty') ||
              e.name.toLowerCase().contains('face')),
        ],
      ),
      TrainingDayPlan(
        dayLabel: 'Den 3',
        focus: 'Legs A',
        exercises: _buildLowerDayA(profile, p),
      ),
      TrainingDayPlan(
        dayLabel: 'Den 4',
        focus: 'Push B',
        exercises: _buildUpperDayB(profile, p),
      ),
      TrainingDayPlan(
        dayLabel: 'Den 5',
        focus: 'Pull B',
        exercises: [
          ..._buildUpperDayA(profile, p).where((e) =>
              e.name.toLowerCase().contains('přít') ||
              e.name.toLowerCase().contains('kladk') ||
              e.name.toLowerCase().contains('shyb') ||
              e.name.toLowerCase().contains('biceps')),
        ],
      ),
      TrainingDayPlan(
        dayLabel: 'Den 6',
        focus: 'Legs B',
        exercises: _buildLowerDayB(profile, p),
      ),
    ];
  }

  static List<TrainingDayPlan> _ppl5Day(
    UserProfile profile,
    TrainingPrescription p,
  ) {
    final all = _ppl6Day(profile, p);
    return all.take(5).toList();
  }

  static List<TrainingDayPlan> _weightLossFullbody2Day(TrainingPrescription p) {
    final all = _weightLossFullbody3Day(p);
    return [all[0], all[1]];
  }

  static List<TrainingDayPlan> _weightLossFullbody3Day(TrainingPrescription p) {
    return [
      TrainingDayPlan(
        dayLabel: 'Den 1',
        focus: 'Fullbody – A',
        exercises: [
          PlannedExercise(name: 'Dřep / goblet squat', sets: '4', reps: p.reps, rir: p.rir),
          PlannedExercise(name: 'Bench / kliky', sets: '4', reps: p.reps, rir: p.rir),
          PlannedExercise(name: 'Přítahy', sets: '4', reps: '8–12', rir: '1–2'),
          PlannedExercise(
            name: 'Kondice',
            sets: '—',
            reps: '15–25 min',
            rir: '—',
            note: 'Zone 2 / svižná chůze',
          ),
        ],
      ),
      TrainingDayPlan(
        dayLabel: 'Den 2',
        focus: 'Fullbody – B',
        exercises: [
          PlannedExercise(name: 'Mrtvý tah / hip hinge', sets: '3', reps: '5–8', rir: '2–3'),
          PlannedExercise(name: 'Tlak nad hlavu', sets: '4', reps: '6–10', rir: '1–2'),
          PlannedExercise(name: 'Lat pulldown', sets: '4', reps: '8–12', rir: '1–2'),
          PlannedExercise(name: 'Střed těla', sets: '3', reps: '10–15 / 20–30 s', rir: '2–3'),
        ],
      ),
      TrainingDayPlan(
        dayLabel: 'Den 3',
        focus: 'Fullbody – C',
        exercises: [
          PlannedExercise(name: 'Leg press', sets: '4', reps: '10–15', rir: '2–3'),
          PlannedExercise(name: 'Incline press', sets: '4', reps: '8–12', rir: '2–3'),
          PlannedExercise(name: 'Row', sets: '4', reps: '8–12', rir: '2–3'),
          PlannedExercise(
            name: 'Kondice',
            sets: '—',
            reps: '15–25 min',
            rir: '—',
            note: 'Zone 2 / intervaly dle chuti',
          ),
        ],
      ),
    ];
  }

  static List<TrainingDayPlan> _weightLossUpperLower4Day(TrainingPrescription p) {
    return [
      TrainingDayPlan(
        dayLabel: 'Den 1',
        focus: 'Upper',
        exercises: [
          PlannedExercise(name: 'Bench / kliky', sets: '3–4', reps: '8–12', rir: '2–3'),
          PlannedExercise(name: 'Přítahy', sets: '3–4', reps: '8–12', rir: '2–3'),
          PlannedExercise(name: 'Ramena', sets: '2–3', reps: '10–15', rir: '2–3'),
          PlannedExercise(name: 'Střed těla', sets: '2–3', reps: '10–15 / 20–30 s', rir: '2–3'),
        ],
      ),
      TrainingDayPlan(
        dayLabel: 'Den 2',
        focus: 'Lower',
        exercises: [
          PlannedExercise(name: 'Dřep / leg press', sets: '3–4', reps: '8–12', rir: '2–3'),
          PlannedExercise(name: 'Hip hinge', sets: '3–4', reps: '6–10', rir: '2–3'),
          PlannedExercise(name: 'Lýtka', sets: '3', reps: '10–20', rir: '2–3'),
        ],
      ),
      TrainingDayPlan(
        dayLabel: 'Den 3',
        focus: 'Upper + kondice',
        exercises: [
          PlannedExercise(name: 'Incline press', sets: '3', reps: '8–12', rir: '2–3'),
          PlannedExercise(name: 'Lat pulldown', sets: '3', reps: '8–12', rir: '2–3'),
          PlannedExercise(name: 'Kondice', sets: '—', reps: '15–25 min', rir: '—', note: 'Zone 2'),
        ],
      ),
      TrainingDayPlan(
        dayLabel: 'Den 4',
        focus: 'Lower + kondice',
        exercises: [
          PlannedExercise(name: 'Leg press', sets: '3', reps: '10–15', rir: '2–3'),
          PlannedExercise(name: 'Hamstring curl', sets: '3', reps: '10–15', rir: '2–3'),
          PlannedExercise(name: 'Kondice', sets: '—', reps: '15–25 min', rir: '—', note: 'Chůze / bike'),
        ],
      ),
    ];
  }

  static List<TrainingDayPlan> _enduranceSupport(TrainingPrescription p) {
    return [
      TrainingDayPlan(
        dayLabel: 'Den 1',
        focus: 'Síla jako doplněk (fullbody)',
        exercises: [
          PlannedExercise(name: 'Dřep', sets: '3', reps: '5–8', rir: '2–3'),
          PlannedExercise(name: 'Bench / kliky', sets: '3', reps: '6–10', rir: '2–3'),
          PlannedExercise(name: 'Přítahy', sets: '3', reps: '8–12', rir: '2–3'),
          PlannedExercise(name: 'Střed těla', sets: '3', reps: '10–15 / 20–30 s', rir: '2–3'),
        ],
      ),
      TrainingDayPlan(
        dayLabel: 'Den 2',
        focus: 'Stabilita + prevence',
        exercises: [
          PlannedExercise(name: 'Hip hinge', sets: '3', reps: '6–10', rir: '2–3'),
          PlannedExercise(name: 'Výpady', sets: '3', reps: '10–12', rir: '2–3'),
          PlannedExercise(name: 'Záda – kladka', sets: '3', reps: '10–15', rir: '2–3'),
          PlannedExercise(name: 'Mobilita', sets: '—', reps: '10–15 min', rir: '—'),
        ],
      ),
    ];
  }
}