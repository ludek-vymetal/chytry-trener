import '../models/user_profile.dart';
import '../models/goal.dart';

import '../core/time/time_context.dart';
import '../core/phase/plan_mode.dart';

import '../core/phase/phase_planner_service.dart';
import '../core/phase/phase_resolver.dart';

import '../core/training/training_strategy.dart';
import '../core/training/training_strategy_adapter.dart';
import '../core/training/training_split.dart';

class TrainingPrescription {
  final String title;
  final String note;

  final String reps;
  final String sets;
  final String rir;

  final bool deloadRecommended;
  final bool peakMode;

  final String splitLabel;

  final int weeksToTarget;
  final int weeksUntilPhaseEnd;

  const TrainingPrescription({
    required this.title,
    required this.note,
    required this.reps,
    required this.sets,
    required this.rir,
    required this.deloadRecommended,
    required this.peakMode,
    required this.splitLabel,
    required this.weeksToTarget,
    required this.weeksUntilPhaseEnd,
  });
}

class TrainingService {
  static TrainingPrescription calculate(
    UserProfile profile,
  ) {
    final Goal? goal = profile.goal;

    if (goal == null) {
      return _default(profile);
    }

    final now = DateTime.now();

    final PlanMode baseMode =
        _mapGoalPlanModeToPlanMode(
      goal.planMode,
    );

    final ctx = TimeContext(
      now: now,
      targetDate: goal.targetDate,
      mode: baseMode,
    );

    final plans =
        PhasePlannerService.buildPlan(ctx, goal: goal);

    if (plans.isEmpty) {
      return _default(profile);
    }

    final current =
        PhaseResolver.resolveCurrentPhase(
      plans: plans,
      date: now,
    );

    final PlanMode effectiveMode =
        current.accelerated
            ? PlanMode.accelerated
            : PlanMode.normal;

    final TrainingSplit split =
        profile.preferredSplit ??
            TrainingSplit.values.first;

    final TrainingStrategy strategy =
        TrainingStrategyAdapter.from(
      goal: goal,
      activePhase: current.activePlan,
      mode: effectiveMode,
    );

    return _toPrescription(
      strategy: strategy,
      blockLabel: current.activePlan.label,
      split: split,
      goal: goal,
      weeksToTarget: ctx.weeksToTarget,
      weeksUntilPhaseEnd:
          current.weeksUntilPhaseEnd,
    );
  }

  static TrainingPrescription _toPrescription({
    required TrainingStrategy strategy,
    String? blockLabel,
    required TrainingSplit split,
    required Goal goal,
    required int weeksToTarget,
    required int weeksUntilPhaseEnd,
  }) {
    return TrainingPrescription(
      title: blockLabel == null
          ? strategy.label
          : '${strategy.label} – $blockLabel',

      note: _buildNote(
        strategy,
        goal,
      ),

      reps:
          '${strategy.repsMin}–${strategy.repsMax}',

      sets:
          '${strategy.setsMin}–${strategy.setsMax}',

      rir:
          '${strategy.rirMin}–${strategy.rirMax}',

      deloadRecommended:
          strategy.allowDeload,

      peakMode: strategy.isPeaking,

      splitLabel: _splitLabel(split),

      weeksToTarget: weeksToTarget,

      weeksUntilPhaseEnd:
          weeksUntilPhaseEnd,
    );
  }

  static String _buildNote(
    TrainingStrategy s,
    Goal goal,
  ) {
    final buffer = StringBuffer()
      ..write(s.rationale);

    if (goal.reason ==
        GoalReason.competition) {
      buffer.write(
        '\n• trainingCompetitionMode',
      );
    }

    if (goal.type ==
        GoalType.weightLoss) {
      buffer.write(
        '\n• trainingDeficitStrength',
      );
    }

    if (s.isPeaking) {
      buffer.write(
        '\n• trainingPeakMode',
      );
    }

    return buffer.toString();
  }

  static TrainingPrescription _default(
    UserProfile profile,
  ) {
    final TrainingSplit split =
        profile.preferredSplit ??
            TrainingSplit.values.first;

    return TrainingPrescription(
      title: 'trainingGeneralTitle',

      note: 'trainingGeneralNote',

      reps: '8–12',

      sets: '12–16',

      rir: '1–2',

      deloadRecommended: false,

      peakMode: false,

      splitLabel: _splitLabel(split),

      weeksToTarget: 0,

      weeksUntilPhaseEnd: 0,
    );
  }

  static PlanMode _mapGoalPlanModeToPlanMode(
    GoalPlanMode mode,
  ) {
    switch (mode) {
      case GoalPlanMode.accelerated:
        return PlanMode.accelerated;

      case GoalPlanMode.normal:
        return PlanMode.normal;

      case GoalPlanMode.auto:
        return PlanMode.normal;
    }
  }

  static String _splitLabel(
    TrainingSplit split,
  ) {
    switch (split) {
      case TrainingSplit.auto:
        return 'trainingSplitAuto';

      case TrainingSplit.fullbody:
        return 'trainingSplitFullbody';

      case TrainingSplit.upperLower:
        return 'trainingSplitUpperLower';

      case TrainingSplit.ppl:
        return 'trainingSplitPPL';

      case TrainingSplit.strength3day:
        return 'trainingSplitStrength3day';
    }
  }
}