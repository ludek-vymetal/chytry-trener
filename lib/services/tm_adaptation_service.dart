import '../core/training/loads/e1rm_calculator.dart';
import '../core/training/sessions/training_session.dart';

class TmAdaptationService {
  static double? proposeNewTm({
    required double currentTm,
    required List<TrainingSession> recentSessions,
  }) {
    if (recentSessions.isEmpty) return null;

    final e1rms = recentSessions
        .map(
          (s) => E1rmCalculator.bestOfSession(
            s.entries.expand((e) => e.actualSets).toList(),
          ),
        )
        .where((v) => v > 0)
        .toList();

    if (e1rms.isEmpty) return null;

    final avg = e1rms.reduce((a, b) => a + b) / e1rms.length;

    final diff = avg - currentTm;
    final percent = diff / currentTm;

    if (percent > 0.08) return currentTm * 1.05;
    if (percent > 0.03) return currentTm * 1.025;
    if (percent < -0.05) return currentTm * 0.95;

    return null;
  }
}