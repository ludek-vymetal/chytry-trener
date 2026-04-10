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
  static DietTargetResult resolve(UserProfile profile) {
    final goal = profile.goal;
    final baseTdee = profile.tdee;

    if (goal == null) {
      return DietTargetResult(
        targetCalories: baseTdee,
        sourceLabel: 'Bez cíle – udržovací režim',
        accelerated: false,
      );
    }

    final isAccelerated = goal.planMode == GoalPlanMode.accelerated;

    switch (goal.phase) {
      case GoalPhase.cut:
        return DietTargetResult(
          targetCalories: baseTdee - (isAccelerated ? 550 : 400),
          sourceLabel:
              isAccelerated ? 'Shazovací fáze (zrychlená)' : 'Shazovací fáze',
          accelerated: isAccelerated,
        );

      case GoalPhase.build:
        return DietTargetResult(
          targetCalories: baseTdee + (isAccelerated ? 300 : 200),
          sourceLabel:
              isAccelerated ? 'Nabírací fáze (zrychlená)' : 'Nabírací fáze',
          accelerated: isAccelerated,
        );

      case GoalPhase.maintain:
        return DietTargetResult(
          targetCalories: baseTdee,
          sourceLabel: 'Udržovací fáze',
          accelerated: isAccelerated,
        );

      case GoalPhase.strength:
        return DietTargetResult(
          targetCalories: baseTdee + 100,
          sourceLabel: 'Silová fáze',
          accelerated: isAccelerated,
        );

      case null:
        return _resolveFallbackByGoalType(
          profile: profile,
          accelerated: isAccelerated,
        );
    }
  }

  static DietTargetResult _resolveFallbackByGoalType({
    required UserProfile profile,
    required bool accelerated,
  }) {
    final goal = profile.goal;
    final baseTdee = profile.tdee;

    if (goal == null) {
      return DietTargetResult(
        targetCalories: baseTdee,
        sourceLabel: 'Bez cíle – udržovací režim',
        accelerated: false,
      );
    }

    switch (goal.type) {
      case GoalType.weightLoss:
        return DietTargetResult(
          targetCalories: baseTdee - (accelerated ? 550 : 400),
          sourceLabel: accelerated
              ? 'Cíl hubnutí (zrychlený)'
              : 'Cíl hubnutí',
          accelerated: accelerated,
        );

      case GoalType.weightGainSupport:
        return DietTargetResult(
          targetCalories: baseTdee + (accelerated ? 300 : 200),
          sourceLabel: accelerated
              ? 'Cíl nabírání (zrychlený)'
              : 'Cíl nabírání',
          accelerated: accelerated,
        );

      case GoalType.strength:
        return DietTargetResult(
          targetCalories: baseTdee + 100,
          sourceLabel: 'Cíl síla',
          accelerated: accelerated,
        );

      case GoalType.endurance:
        return DietTargetResult(
          targetCalories: baseTdee,
          sourceLabel: 'Cíl vytrvalost',
          accelerated: accelerated,
        );

      case GoalType.physique:
        return DietTargetResult(
          targetCalories: baseTdee - 250,
          sourceLabel: 'Cíl postava',
          accelerated: accelerated,
        );
    }
  }
}