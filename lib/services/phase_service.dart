import '../l10n/app_localizations.dart';
import '../models/goal.dart';
import '../models/user_profile.dart';

import '../core/phase/phase_planner_service.dart';
import '../core/phase/phase_resolver.dart';
import '../core/phase/plan_mode.dart';

import '../core/time/time_context.dart';

import '../core/training/training_split.dart';
import '../core/training/training_strategy.dart';
import '../core/training/training_strategy_adapter.dart';

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
  static TrainingPrescription calculate(
    UserProfile profile,
    AppLocalizations l10n,
  ) {
    if (profile.goal == null) {
      return _default(profile, l10n);
    }

    final goal = profile.goal!;

    final ctx = TimeContext(
      now: DateTime.now(),
      targetDate: goal.targetDate,
      mode: PlanMode.normal,
    );

    final plans =
        PhasePlannerService.buildPlan(ctx, goal: goal);

    final current =
        PhaseResolver.resolveCurrentPhase(
      plans: plans,
      date: ctx.now,
    );

    final mode = current.accelerated
        ? PlanMode.accelerated
        : PlanMode.normal;

    final strategy =
        TrainingStrategyAdapter.from(
      goal: goal,
      activePhase: current.activePlan,
      mode: mode,
    );

    return _toPrescription(
      strategy: strategy,
      split:
          profile.preferredSplit ??
              TrainingSplit.auto,
      goal: goal,
      weeksToTarget: ctx.weeksToTarget,
      weeksUntilPhaseEnd:
          current.weeksUntilPhaseEnd,
      l10n: l10n,
    );
  }

  static TrainingPrescription _toPrescription({
    required TrainingStrategy strategy,
    required TrainingSplit split,
    required Goal goal,
    required int weeksToTarget,
    required int weeksUntilPhaseEnd,
    required AppLocalizations l10n,
  }) {
    return TrainingPrescription(
      title: strategy.label,

      note: _buildNote(
        strategy,
        goal,
        l10n,
      ),

      reps:
          '${strategy.repsMin}–${strategy.repsMax}',

      sets:
          '${strategy.setsMin}–${strategy.setsMax} ${l10n.perMuscleWeekly}',

      rir:
          '${strategy.rirMin}–${strategy.rirMax}',

      deloadRecommended:
          strategy.allowDeload,

      peakMode: strategy.isPeaking,

      splitLabel: _splitLabel(
        split,
        l10n,
      ),

      weeksToTarget: weeksToTarget,

      weeksUntilPhaseEnd:
          weeksUntilPhaseEnd,
    );
  }

  static String _buildNote(
    TrainingStrategy s,
    Goal goal,
    AppLocalizations l10n,
  ) {
    final buffer = StringBuffer();

    buffer.write(s.rationale);

    if (goal.reason ==
        GoalReason.competition) {
      buffer.write(
        '\n• ${l10n.competitionModeNote}',
      );
    }

    if (goal.type ==
        GoalType.weightLoss) {
      buffer.write(
        '\n• ${l10n.weightLossStrengthNote}',
      );
    }

    if (s.isPeaking) {
      buffer.write(
        '\n• ${l10n.peakModeShortNote}',
      );
    }

    return buffer.toString();
  }

  static TrainingPrescription _default(
    UserProfile profile,
    AppLocalizations l10n,
  ) {
    return TrainingPrescription(
      title: l10n.generalTraining,

      note:
          l10n.setupGoalAndDateForPeriodization,

      reps: '8–12',

      sets: '12–16',

      rir: '1–2',

      deloadRecommended: false,

      peakMode: false,

      splitLabel:
          profile.preferredSplit != null
              ? _splitLabel(
                  profile.preferredSplit!,
                  l10n,
                )
              : l10n.automatic,

      weeksToTarget: 0,

      weeksUntilPhaseEnd: 0,
    );
  }

  static String _splitLabel(
    TrainingSplit split,
    AppLocalizations l10n,
  ) {
    switch (split) {
      case TrainingSplit.auto:
        return l10n.automatic;

      case TrainingSplit.fullbody:
        return l10n.fullbody3x;

      case TrainingSplit.upperLower:
        return l10n.upperLower4x;

      case TrainingSplit.ppl:
        return l10n.pushPullLegs6x;

      case TrainingSplit.strength3day:
        return l10n.strength3days;
    }
  }
}