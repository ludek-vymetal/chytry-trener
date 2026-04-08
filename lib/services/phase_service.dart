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

  TrainingPrescription({
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
    if (profile.goal == null) {
      return _default(profile);
    }

    final goal = profile.goal!;

    final ctx = TimeContext(
      now: DateTime.now(),
      targetDate: goal.targetDate,
      mode: PlanMode.normal,
    );

    final plans = PhasePlannerService.buildPlan(ctx);

    final current = PhaseResolver.resolveCurrentPhase(
      plans: plans,
      date: ctx.now,
    );

    final mode =
        current.accelerated ? PlanMode.accelerated : PlanMode.normal;

    final strategy = TrainingStrategyAdapter.from(
      goal: goal,
      activePhase: current.activePlan,
      mode: mode,
    );

    return _toPrescription(
      strategy: strategy,
      split: profile.preferredSplit ?? TrainingSplit.auto,
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
      splitLabel: _splitLabel(split), // ✅ FIX
      weeksToTarget: weeksToTarget,
      weeksUntilPhaseEnd: weeksUntilPhaseEnd,
    );
  }

  static String _buildNote(TrainingStrategy s, Goal goal) {
    final buffer = StringBuffer();

    buffer.write(s.rationale);

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
    return TrainingPrescription(
      title: 'Obecný trénink',
      note: 'Nastav si nejprve cíl a datum, aby šla periodizace.',
      reps: '8–12',
      sets: '12–16',
      rir: '1–2',
      deloadRecommended: false,
      peakMode: false,
      splitLabel: profile.preferredSplit != null
          ? _splitLabel(profile.preferredSplit!)
          : 'Automaticky', // ✅ FIX
      weeksToTarget: 0,
      weeksUntilPhaseEnd: 0,
    );
  }

  // ✅ FIX: místo .label používáme vlastní mapper
  static String _splitLabel(TrainingSplit split) {
    switch (split) {
      case TrainingSplit.auto:
        return 'Automaticky';
      case TrainingSplit.fullbody:
        return 'Fullbody 3×';
      case TrainingSplit.upperLower:
        return 'Upper / Lower 4×';
      case TrainingSplit.ppl:
        return 'Push Pull Legs 6×';
      case TrainingSplit.strength3day:
        return 'Síla 3 dny';
    }
  }
}