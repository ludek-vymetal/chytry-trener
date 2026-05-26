import '../../../l10n/app_localizations.dart';
import '../../../models/goal.dart';
import '../../../models/user_profile.dart';

class DietTargetResult {
  final double targetCalories;

  final String sourceLabel;

  final bool accelerated;

  const DietTargetResult({
    required this.targetCalories,
    required this.sourceLabel,
    required this.accelerated,
  });
}

class DietTargetService {
  static DietTargetResult resolve(
    UserProfile profile,
    AppLocalizations l10n,
  ) {
    final goal = profile.goal;

    final baseTdee = profile.tdee;

    if (goal == null) {
      return DietTargetResult(
        targetCalories: baseTdee,
        sourceLabel:
            l10n.noGoalMaintenanceMode,
        accelerated: false,
      );
    }

    final isAccelerated =
        goal.planMode ==
            GoalPlanMode.accelerated;

    switch (goal.phase) {
      case GoalPhase.cut:
        return DietTargetResult(
          targetCalories:
              baseTdee -
              (isAccelerated
                  ? 550
                  : 400),
          sourceLabel:
              isAccelerated
                  ? l10n.cutPhaseAccelerated
                  : l10n.cutPhase,
          accelerated:
              isAccelerated,
        );

      case GoalPhase.build:
        return DietTargetResult(
          targetCalories:
              baseTdee +
              (isAccelerated
                  ? 300
                  : 200),
          sourceLabel:
              isAccelerated
                  ? l10n.buildPhaseAccelerated
                  : l10n.buildPhase,
          accelerated:
              isAccelerated,
        );

      case GoalPhase.maintain:
        return DietTargetResult(
          targetCalories: baseTdee,
          sourceLabel:
              l10n.maintenancePhase,
          accelerated:
              isAccelerated,
        );

      case GoalPhase.strength:
        return DietTargetResult(
          targetCalories:
              baseTdee + 100,
          sourceLabel:
              l10n.strengthPhase,
          accelerated:
              isAccelerated,
        );

      case null:
        return _resolveFallbackByGoalType(
          profile: profile,
          accelerated:
              isAccelerated,
          l10n: l10n,
        );
    }
  }

  static DietTargetResult
      _resolveFallbackByGoalType({
    required UserProfile profile,
    required bool accelerated,
    required AppLocalizations l10n,
  }) {
    final goal = profile.goal;

    final baseTdee = profile.tdee;

    if (goal == null) {
      return DietTargetResult(
        targetCalories: baseTdee,
        sourceLabel:
            l10n.noGoalMaintenanceMode,
        accelerated: false,
      );
    }

    switch (goal.type) {
      case GoalType.weightLoss:
        return DietTargetResult(
          targetCalories:
              baseTdee -
              (accelerated
                  ? 550
                  : 400),
          sourceLabel:
              accelerated
                  ? l10n.weightLossGoalAccelerated
                  : l10n.weightLossGoal,
          accelerated:
              accelerated,
        );

      case GoalType.weightGainSupport:
        return DietTargetResult(
          targetCalories:
              baseTdee +
              (accelerated
                  ? 300
                  : 200),
          sourceLabel:
              accelerated
                  ? l10n.weightGainGoalAccelerated
                  : l10n.weightGainGoal,
          accelerated:
              accelerated,
        );

      case GoalType.strength:
        return DietTargetResult(
          targetCalories:
              baseTdee + 100,
          sourceLabel:
              l10n.strengthGoal,
          accelerated:
              accelerated,
        );

      case GoalType.endurance:
        return DietTargetResult(
          targetCalories: baseTdee,
          sourceLabel:
              l10n.enduranceGoal,
          accelerated:
              accelerated,
        );

      case GoalType.physique:
        return DietTargetResult(
          targetCalories:
              baseTdee - 250,
          sourceLabel:
              l10n.physiqueGoal,
          accelerated:
              accelerated,
        );
    }
  }
}