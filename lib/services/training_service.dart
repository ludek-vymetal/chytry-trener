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
  static TrainingPrescription calculate(UserProfile profile) {
    final Goal? goal = profile.goal;
    if (goal == null) return _default(profile);

    final DateTime now = DateTime.now();

    // ✅ GoalPlanMode -> PlanMode
    final PlanMode baseMode = _mapGoalPlanModeToPlanMode(goal.planMode);

    final ctx = TimeContext(
      now: now,
      targetDate: goal.targetDate,
      mode: baseMode,
    );

    final plans = PhasePlannerService.buildPlan(ctx);
    if (plans.isEmpty) return _default(profile);

    final current = PhaseResolver.resolveCurrentPhase(
      plans: plans,
      date: now,
    );

    // ✅ Planner může vynutit accelerated
    final PlanMode effectiveMode =
        current.accelerated ? PlanMode.accelerated : PlanMode.normal;

    // ✅ split fallback: bezpečný (pokud enum nemá "fullBody", použijeme první hodnotu)
    final TrainingSplit split = profile.preferredSplit ?? TrainingSplit.values.first;

    final TrainingStrategy strategy = TrainingStrategyAdapter.from(
      goal: goal,
      activePhase: current.activePlan,
      mode: effectiveMode,
    );

    return _toPrescription(
      strategy: strategy,
      split: split,
      goal: goal,
      weeksToTarget: ctx.weeksToTarget,
      weeksUntilPhaseEnd: current.weeksUntilPhaseEnd,
    );
  }

  static TrainingPrescription _toPrescription({
    required TrainingStrategy strategy,
    required TrainingSplit split,
    required Goal goal,
    required int weeksToTarget,
    required int weeksUntilPhaseEnd,
  }) {
    return TrainingPrescription(
      title: strategy.label,
      note: _buildNote(strategy, goal),
      reps: '${strategy.repsMin}–${strategy.repsMax}',
      sets: '${strategy.setsMin}–${strategy.setsMax} / partii týdně',
      rir: '${strategy.rirMin}–${strategy.rirMax}',
      deloadRecommended: strategy.allowDeload,
      peakMode: strategy.isPeaking,
      splitLabel: split.label,
      weeksToTarget: weeksToTarget,
      weeksUntilPhaseEnd: weeksUntilPhaseEnd,
    );
  }

  static String _buildNote(TrainingStrategy s, Goal goal) {
    final buffer = StringBuffer()..write(s.rationale);

    if (goal.reason == GoalReason.competition) {
      buffer.write('\n• Režim pro závody – priorita výkon/forma.');
    }

    if (goal.type == GoalType.weightLoss) {
      buffer.write('\n• V deficitu nehoníme PR – držíme sílu.');
    }

    if (s.isPeaking) {
      buffer.write('\n• Peak: technika > objem, delší pauzy.');
    }

    return buffer.toString();
  }

  static TrainingPrescription _default(UserProfile profile) {
    final TrainingSplit split = profile.preferredSplit ?? TrainingSplit.values.first;

    return TrainingPrescription(
      title: 'Obecný trénink',
      note: 'Nastav si nejprve cíl a datum, aby šla periodizace.',
      reps: '8–12',
      sets: '12–16',
      rir: '1–2',
      deloadRecommended: false,
      peakMode: false,
      splitLabel: split.label,
      weeksToTarget: 0,
      weeksUntilPhaseEnd: 0,
    );
  }

  static PlanMode _mapGoalPlanModeToPlanMode(GoalPlanMode mode) {
    switch (mode) {
      case GoalPlanMode.accelerated:
        return PlanMode.accelerated;
      case GoalPlanMode.normal:
        return PlanMode.normal;
      case GoalPlanMode.auto:
        // auto = planner případně sám přepne do accelerated
        return PlanMode.normal;
    }
  }
}