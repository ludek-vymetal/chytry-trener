import '../../models/coach/coach_body_diagnostic_entry.dart';

class CoachInsightsService {

  static List<String> buildInsights({
    required String gender,
    required CoachBodyDiagnosticEntry latest,
    CoachBodyDiagnosticEntry? previous,
  }) {
    final out = <String>[];

    // =========================
    // 1) HODNOCENÍ TUKU
    // =========================

    final fat = latest.fatPercent;

    if (gender == 'male') {
      if (fat <= 9) {
        out.add('Velmi nízký tuk – závodní nebo krátkodobá forma.');
      } else if (fat <= 14) {
        out.add('Výborná forma.');
      } else if (fat <= 18) {
        out.add('Zdravá sportovní forma.');
      } else if (fat <= 24) {
        out.add('Je prostor pro redukci tuku.');
      } else {
        out.add('Vysoký podíl tuku – priorita bude hubnutí.');
      }
    } else {
      if (fat <= 16) {
        out.add('Velmi nízký tuk – závodní nebo krátkodobá forma.');
      } else if (fat <= 21) {
        out.add('Výborná forma.');
      } else if (fat <= 26) {
        out.add('Zdravá sportovní forma.');
      } else if (fat <= 33) {
        out.add('Je prostor pro redukci tuku.');
      } else {
        out.add('Vysoký podíl tuku – priorita bude hubnutí.');
      }
    }

    // =========================
    // 2) KOLIK TUKU SHODIT
    // =========================

    final targetFat = gender == 'female' ? 24.0 : 15.0;
    final targetFatKg = latest.weightKg * (targetFat / 100);
    final fatToLose = latest.fatKg - targetFatKg;

    if (fatToLose > 0.7) {
      out.add('Pro ideální formu by bylo vhodné zhubnout asi ${fatToLose.toStringAsFixed(1)} kg tuku.');
    } else if (fatToLose < -0.7) {
      out.add('Tuku je velmi málo – zaměříme se spíše na výkon a svaly.');
    }

    // =========================
    // 3) VODA
    // =========================

    final waterRatio = latest.waterKg / latest.weightKg;

    if (waterRatio > 0.65) {
      out.add('Tělo může zadržovat více vody (stres, sůl, regenerace).');
    } else if (waterRatio < 0.45) {
      out.add('Nízký podíl vody – zaměř se na pitný režim a regeneraci.');
    }

    // =========================
    // 4) VÝVOJ OPROTI MINULE
    // =========================

    if (previous != null) {
      final dFat = latest.fatKg - previous.fatKg;
      final dMuscle = latest.muscleKg - previous.muscleKg;

      if (dFat < -0.3) out.add('Tuk klesá – pokračuj.');
      if (dFat > 0.3) out.add('Tuk roste – upravíme stravu.');

      if (dMuscle > 0.2) out.add('Svaly rostou – trénink funguje.');
      if (dMuscle < -0.2) out.add('Svaly klesají – přidáme bílkoviny nebo snížíme deficit.');
    }

    return out;
  }
}
