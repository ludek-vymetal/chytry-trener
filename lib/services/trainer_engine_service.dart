import '../models/coach/coach_inbody_entry.dart';
import '../models/goal.dart';

class TrainerInsight {
  final String title;
  final String message;
  final bool isWarning;

  const TrainerInsight({
    required this.title,
    required this.message,
    this.isWarning = false,
  });
}

class TrainerEngineService {
  static List<TrainerInsight> analyze(List<CoachInbodyEntry> history, Goal? goal) {
    if (history.isEmpty) return [];
    
    final List<TrainerInsight> insights = [];
    final latest = history.first; // loadInbodyAll už je seřazené od nejnovějšího
    final previous = history.length > 1 ? history[1] : null;

    // 1. ANALÝZA KOMPOZICE (Trend svaly vs tuk)
    if (previous != null) {
      final muscleDiff = latest.smmKg - previous.smmKg;
      final fatDiff = latest.fatKg - previous.fatKg;

      if (muscleDiff > 0.2 && fatDiff < 0) {
        insights.add(const TrainerInsight(
          title: 'Perfektní rekompozice',
          message: 'Nabíráš svaly a zároveň pálíš tuk. Tohle je svatý grál fitness!',
        ));
      } else if (muscleDiff < -0.3) {
        insights.add(const TrainerInsight(
          title: 'Pozor na svalovou hmotu',
          message: 'Ztrácíš svaly. Zkus zvýšit příjem bílkovin nebo intenzitu tréninku.',
          isWarning: true,
        ));
      }
    }

    // 2. SEGMENTÁLNÍ ANALÝZA (Svalová symetrie)
    final armDiff = (latest.muscleLeftArmKg - latest.muscleRightArmKg).abs();
    

    if (armDiff > 0.4) {
      insights.add(TrainerInsight(
        title: 'Svalová asymetrie (Ruce)',
        message: 'Mezi levou a pravou paží je rozdíl ${armDiff.toStringAsFixed(1)} kg svalů. Zaměř se na unilaterální cviky.',
        isWarning: true,
      ));
    }

    // 3. VISCERÁLNÍ TUK
    if (latest.visceralFatLevel != null && latest.visceralFatLevel! > 10) {
      insights.add(const TrainerInsight(
        title: 'Zdravotní upozornění',
        message: 'Úroveň viscerálního tuku je zvýšená. Zaměř se na kvalitní spánek a omezení stresu.',
        isWarning: true,
      ));
    }

    // 4. MOTIVACE PODLE CÍLE
    if (goal != null) {
      if (goal.type == GoalType.weightLoss && latest.bodyFatPercent < 15) {
        insights.add(const TrainerInsight(
          title: 'Skvělá forma',
          message: 'Tvoje procento tuku je nízko. Možná je čas na udržovací fázi.',
        ));
      }
    }

    return insights;
  }
}