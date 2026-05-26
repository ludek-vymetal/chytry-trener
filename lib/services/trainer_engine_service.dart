import '../models/coach/coach_inbody_entry.dart';
import '../models/goal.dart';

class TrainerInsight {
  final String titleKey;
  final String messageKey;

  final Map<String, String>? params;

  final bool isWarning;

  const TrainerInsight({
    required this.titleKey,
    required this.messageKey,
    this.params,
    this.isWarning = false,
  });
}

class TrainerEngineService {
  static List<TrainerInsight> analyze(
    List<CoachInbodyEntry> history,
    Goal? goal,
  ) {
    if (history.isEmpty) {
      return [];
    }

    final insights = <TrainerInsight>[];

    final latest = history.first;

    final CoachInbodyEntry? previous =
        history.length > 1 ? history[1] : null;

    // =========================================================
    // 1. REKOMPOZICE
    // =========================================================

    if (previous != null) {
      final muscleDiff =
          latest.smmKg - previous.smmKg;

      final fatDiff =
          latest.fatKg - previous.fatKg;

      // svaly nahoru + tuk dolů
      if (muscleDiff > 0.2 && fatDiff < 0) {
        insights.add(
          const TrainerInsight(
            titleKey: 'perfectRecompositionTitle',
            messageKey: 'perfectRecompositionMessage',
          ),
        );
      }

      // ztráta svalů
      else if (muscleDiff < -0.3) {
        insights.add(
          const TrainerInsight(
            titleKey: 'muscleLossWarningTitle',
            messageKey: 'muscleLossWarningMessage',
            isWarning: true,
          ),
        );
      }
    }

    // =========================================================
    // 2. ASYMETRIE
    // =========================================================

    final armDiff = (
      latest.muscleLeftArmKg -
      latest.muscleRightArmKg
    ).abs();

    if (armDiff > 0.4) {
      insights.add(
        TrainerInsight(
          titleKey: 'armAsymmetryTitle',
          messageKey: 'armAsymmetryMessage',
          isWarning: true,
          params: {
            'diff': armDiff.toStringAsFixed(1),
          },
        ),
      );
    }

    // =========================================================
    // 3. VISCERÁLNÍ TUK
    // =========================================================

    final visceral = latest.visceralFatLevel;

    if (visceral != null && visceral > 10) {
      insights.add(
        const TrainerInsight(
          titleKey: 'visceralFatWarningTitle',
          messageKey: 'visceralFatWarningMessage',
          isWarning: true,
        ),
      );
    }

    // =========================================================
    // 4. MOTIVACE PODLE CÍLE
    // =========================================================

    if (goal != null) {
      if (goal.type == GoalType.weightLoss &&
          latest.bodyFatPercent < 15) {
        insights.add(
          const TrainerInsight(
            titleKey: 'greatConditionTitle',
            messageKey: 'greatConditionMessage',
          ),
        );
      }
    }

    return insights;
  }
}