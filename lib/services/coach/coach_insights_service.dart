import '../../models/coach/coach_body_diagnostic_entry.dart';

class CoachInsightsService {
  static List<String> buildInsights({
    required String gender,
    required CoachBodyDiagnosticEntry latest,
    CoachBodyDiagnosticEntry? previous,
  }) {
    final out = <String>[];

    // ==================================================
    // 1) BODY FAT
    // ==================================================

    final fat = latest.fatPercent;

    if (gender == 'male') {
      if (fat <= 9) {
        out.add('coachInsightVeryLowFat');
      } else if (fat <= 14) {
        out.add('coachInsightExcellentShape');
      } else if (fat <= 18) {
        out.add('coachInsightHealthyAthletic');
      } else if (fat <= 24) {
        out.add('coachInsightFatReduction');
      } else {
        out.add('coachInsightHighFat');
      }
    } else {
      if (fat <= 16) {
        out.add('coachInsightVeryLowFat');
      } else if (fat <= 21) {
        out.add('coachInsightExcellentShape');
      } else if (fat <= 26) {
        out.add('coachInsightHealthyAthletic');
      } else if (fat <= 33) {
        out.add('coachInsightFatReduction');
      } else {
        out.add('coachInsightHighFat');
      }
    }

    // ==================================================
    // 2) HOW MUCH FAT TO LOSE
    // ==================================================

    final targetFat =
        gender == 'female' ? 24.0 : 15.0;

    final targetFatKg =
        latest.weightKg * (targetFat / 100);

    final fatToLose =
        latest.fatKg - targetFatKg;

    if (fatToLose > 0.7) {
      out.add(
        'coachInsightLoseFat:${fatToLose.toStringAsFixed(1)}',
      );
    } else if (fatToLose < -0.7) {
      out.add('coachInsightVeryLean');
    }

    // ==================================================
    // 3) WATER
    // ==================================================

    final waterRatio =
        latest.waterKg / latest.weightKg;

    if (waterRatio > 0.65) {
      out.add('coachInsightWaterRetention');
    } else if (waterRatio < 0.45) {
      out.add('coachInsightLowWater');
    }

    // ==================================================
    // 4) PROGRESS
    // ==================================================

    if (previous != null) {
      final dFat =
          latest.fatKg - previous.fatKg;

      final dMuscle =
          latest.muscleKg -
          previous.muscleKg;

      if (dFat < -0.3) {
        out.add('coachInsightFatDown');
      }

      if (dFat > 0.3) {
        out.add('coachInsightFatUp');
      }

      if (dMuscle > 0.2) {
        out.add('coachInsightMuscleUp');
      }

      if (dMuscle < -0.2) {
        out.add('coachInsightMuscleDown');
      }
    }

    return out;
  }
}